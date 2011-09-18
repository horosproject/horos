/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>
#include <Accelerate/Accelerate.h>

@class MPR2DController,NSCFDate, DicomStudy;
@class ViewerController;
@class BonjourPublisher,BonjourBrowser;
@class AnonymizerWindowController,QueryController;
@class LogWindowController,PreviewView;
@class MyOutlineView,DCMView,DCMPix;
@class StructuredReportController,BrowserMatrix;
@class PluginManagerController,WaitRendering, Wait, ActivityWindowController;
@class WebPortalUser;

enum RootTypes{PatientRootType, StudyRootType, RandomRootType};
enum simpleSearchType {PatientNameSearch, PatientIDSearch};
enum queueStatus{QueueHasData, QueueEmpty};
enum dbObjectSelection {oAny,oMiddle,oFirstForFirst};

@interface NSString (BrowserController)
-(NSMutableString*)filenameString;
@end

/** \brief Window controller for Browser
*
*   This is a large class with a lot of functions.
*   Along with managing the Browser Window it manages all the view in the browser
*	and manges the database
*/

@interface BrowserController : NSWindowController <NSTableViewDelegate, NSDrawerDelegate, NSMatrixDelegate, NSToolbarDelegate>   //NSObject
{
	NSManagedObjectModel			*managedObjectModel;//, *userManagedObjectModel;
    NSManagedObjectContext			*managedObjectContext;//, *userManagedObjectContext;
//	NSPersistentStoreCoordinator	*userPersistentStoreCoordinator;
	NSMutableDictionary				*persistentStoreCoordinatorDictionary;
	NSMutableDictionary				*databaseIndexDictionary;
	
	NSDateFormatter			*TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
	
	NSRect					visibleScreenRect[ 40];
	NSString				*currentDatabasePath;
	BOOL					isCurrentDatabaseBonjour;
	NSManagedObjectContext	*bonjourManagedObjectContext;
	NSString				*transferSyntax;
    NSArray                 *dirArray;
    NSToolbar               *toolbar;
	
	NSMutableArray			*sendQueue;
	NSMutableDictionary		*reportFilesToCheck;
	
    NSMutableArray          *previewPix, *previewPixThumbnails;
	
	NSMutableArray			*draggedItems;
		
	NSMutableDictionary		*activeSends;
	NSMutableArray			*sendLog;
	NSMutableDictionary		*activeReceives;
	NSMutableArray			*receiveLog;
	
	LogWindowController			*logWindowController;
	
    DCMPix                  *curPreviewPix;
    
    NSTimer                 *timer, *IncomingTimer, *matrixDisplayIcons, *refreshTimer, *databaseCleanerTimer, *bonjourTimer, *deleteQueueTimer, *autoroutingQueueTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
	long					previousBonjourIndex;
	
    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert, *splitAlbums;
    
	BOOL					setDCMDone, dontLoadSelectionSource, dontUpdatePreviewPane;
	
	NSMutableArray			*albumNoOfStudiesCache;
	
    volatile BOOL			bonjourDownloading;
	
	NSArray							*outlineViewArray, *originalOutlineViewArray;
	NSArray							*matrixViewArray;
	
	NSString						*_searchString;
	
	IBOutlet NSTextField			*databaseDescription;
	IBOutlet MyOutlineView          *databaseOutline;
	NSMenu							*columnsMenu;
	IBOutlet BrowserMatrix			*oMatrix;
	IBOutlet NSTableView			*albumTable;
	IBOutlet NSSegmentedControl		*segmentedAlbumButton;
	
	IBOutlet NSBox					*bonjourSourcesBox;
	
	IBOutlet NSTableView			*bonjourServicesList;
	BonjourPublisher				*bonjourPublisher;
	BonjourBrowser					*bonjourBrowser;
	
	IBOutlet NSSlider				*animationSlider;
	IBOutlet NSButton				*animationCheck;
    
    IBOutlet PreviewView			*imageView;
	
	int								subFrom, subTo, subInterval, subMax;
	
	IBOutlet NSWindow				*subOpenWindow;
	IBOutlet NSMatrix				*subOpenMatrix3D, *subOpenMatrix4D, *supOpenButtons;
	
	IBOutlet NSWindow				*subSeriesWindow;
	IBOutlet NSButton				*subSeriesOKButton;
	IBOutlet NSTextField			*memoryMessage;
	IBOutlet NSBox					*enoughMem, *notEnoughMem;
	
	IBOutlet NSWindow				*bonjourPasswordWindow;
	IBOutlet NSTextField			*password;
	
	IBOutlet NSWindow				*newAlbum;
	IBOutlet NSTextField			*newAlbumName;
	
	IBOutlet NSWindow				*editSmartAlbum;
	IBOutlet NSTextField			*editSmartAlbumName, *editSmartAlbumQuery;
	
	IBOutlet NSDrawer				*albumDrawer;
	
	IBOutlet NSWindow				*rebuildWindow;
	IBOutlet NSMatrix				*rebuildType;
	IBOutlet NSTextField			*estimatedTime, *noOfFilesToRebuild, *warning;
	
	IBOutlet NSPopUpButton			*timeIntervalPopup;
	IBOutlet NSWindow				*customTimeIntervalWindow;
	IBOutlet NSDatePicker			*customStart, *customEnd, *customStart2, *customEnd2;
	IBOutlet NSView					*timeIntervalView;
	int								timeIntervalType;
	NSDate							*timeIntervalStart, * timeIntervalEnd;
	
	IBOutlet NSView					*searchView;
	IBOutlet NSSearchField			*searchField;
	NSToolbarItem					*toolbarSearchItem;
	int								searchType;
	
	IBOutlet NSWindow				*mainWindow;
	IBOutlet NSMenu					*imageTileMenu;
	IBOutlet NSWindow				*urlWindow, *CDpasswordWindow, *ZIPpasswordWindow;
	IBOutlet NSTextField			*urlString;
	
	IBOutlet NSForm					*rdPatientForm, *rdPixelForm, *rdVoxelForm, *rdOffsetForm;
	IBOutlet NSMatrix				*rdPixelTypeMatrix;
	IBOutlet NSView					*rdAccessory;
	
	IBOutlet NSView					*exportQuicktimeView;
	IBOutlet NSButton				*exportHTMLButton;
	
	IBOutlet NSView					*exportAccessoryView;
	IBOutlet NSMatrix				*compressionMatrix, *folderTree;
	
	NSRecursiveLock					*checkIncomingLock, *checkBonjourUpToDateThreadLock;
	NSPredicate						*testPredicate;
	
    BOOL							showAllImages, DatabaseIsEdited, isNetworkLogsActive, displayEmptyDatabase;
	NSConditionLock					*queueLock;
	
	IBOutlet NSScrollView			*thumbnailsScrollView;
	
	NSPredicate						*_fetchPredicate, *_filterPredicate;
	NSString						*_filterPredicateDescription;
	
	NSString						*fixedDocumentsDirectory, *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption;
	
	char							cfixedDocumentsDirectory[ 4096], cfixedIncomingDirectory[ 4096], cfixedTempNoIndexDirectory[ 4096], cfixedIncomingNoIndexDirectory[ 4096];
	
	NSTimeInterval					databaseLastModification, lastCheckForDirectory;
	NSUInteger						previousFlags;
//	StructuredReportController		*structuredReportController;
	
	NSMutableArray					*deleteQueueArray;
	NSRecursiveLock					*deleteQueue, *deleteInProgress;
	
	NSMutableArray					*autoroutingQueueArray;
	NSLock							*autoroutingQueue, *autoroutingInProgress;
	NSMutableDictionary				*autoroutingPreviousStudies;
	
	NSConditionLock					*processorsLock;
	NSRecursiveLock					*decompressArrayLock, *decompressThreadRunning;
	NSMutableArray					*decompressArray;
	
	NSMutableString					*pressedKeys;
	
	IBOutlet NSView					*reportTemplatesView;
	IBOutlet NSImageView			*reportTemplatesImageView;
	IBOutlet NSPopUpButton			*reportTemplatesListPopUpButton;
	int								reportToolbarItemType;
	
	IBOutlet NSWindow				*addStudiesToUserWindow;
	IBOutlet NSWindow				*notificationEmailWindow;
	IBOutlet NSArrayController		*notificationEmailArrayController;
	NSString						*temporaryNotificationEmail, *customTextNotificationEmail;
	
	NSConditionLock					*newFilesConditionLock;
	NSMutableArray					*viewersListToReload, *viewersListToRebuild;
	
	volatile BOOL					newFilesInIncoming;
	NSImage							*notFoundImage, *standardOsiriXIcon, *downloadingOsiriXIcon, *currentIcon;
	
	BOOL							ROIsAndKeyImagesButtonAvailable;
	
	BOOL							rtstructProgressBar;
	float							rtstructProgressPercent;
	
	BOOL							avoidRecursive, openSubSeriesFlag;
	
	IBOutlet PluginManagerController *pluginManagerController;
	NSTimeInterval					lastCheckIncoming;
	
	WaitRendering					*waitOpeningWindow;
//	Wait							*waitCompressionWindow;
	BOOL							waitCompressionAbort;
	
	BOOL							checkForMountedFiles;
	
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionSelectedFiles;
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionCorrespondingObjects;
	NSIndexSet						*cachedFilesForDatabaseOutlineSelectionIndex;
	
	NSArray							*mountedVolumes;
	
	IBOutlet NSTableView* AtableView;
//	IBOutlet NSImageView* AcpuActiView, *AhddActiView, *AnetActiView;
//	IBOutlet NSTextField* AstatusLabel;
	NSMutableArray* _activityCells;
	NSThread* AupdateStatsThread;
	NSObject* activityObserver;
}

@property(readonly) NSManagedObjectContext *bonjourManagedObjectContext;

@property(readonly) NSDateFormatter *DateTimeFormat __deprecated, *DateOfBirthFormat __deprecated, *TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
@property(readonly) NSRecursiveLock *checkIncomingLock;
@property(readonly) NSArray *matrixViewArray;
@property(readonly) NSMatrix *oMatrix;
@property(readonly) long COLUMN, currentBonjourService;
@property(readonly) BOOL is2DViewer, isCurrentDatabaseBonjour;
@property(readonly) MyOutlineView *databaseOutline;
@property(readonly) NSTableView *albumTable;
@property(readonly) NSString *currentDatabasePath, *localDatabasePath, *documentsDirectory, *fixedDocumentsDirectory;

@property(readonly) NSTableView* AtableView;
//@property(readonly) NSImageView* AcpuActiView, *AhddActiView, *AnetActiView;
//@property(readonly) NSTextField* AstatusLabel;

@property volatile BOOL bonjourDownloading;
@property(readonly) NSBox *bonjourSourcesBox;
@property(readonly) BonjourBrowser *bonjourBrowser;
@property(readonly) char *cfixedDocumentsDirectory, *cfixedIncomingDirectory, *cfixedTempNoIndexDirectory, *cfixedIncomingNoIndexDirectory;

@property(retain) NSString *searchString, *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption, *temporaryNotificationEmail, *customTextNotificationEmail;
@property(retain) NSPredicate *fetchPredicate, *testPredicate;
@property(readonly) NSPredicate *filterPredicate;
@property(readonly) NSString *filterPredicateDescription;

@property BOOL rtstructProgressBar;
@property float rtstructProgressPercent;
@property (nonatomic) NSTimeInterval databaseLastModification;
@property(readonly) NSMutableArray *viewersListToReload, *viewersListToRebuild;
@property(readonly) NSConditionLock* newFilesConditionLock;
@property(readonly) NSMutableDictionary *databaseIndexDictionary;
@property(readonly) PluginManagerController *pluginManagerController;

+ (int) compressionForModality: (NSString*) mod quality:(int*) quality resolution: (int) resolution;
+ (BrowserController*) currentBrowser;
+ (NSMutableString*) replaceNotAdmitted: (NSString*)name;
+ (NSArray*) statesArray;
+ (void) updateActivity;
+ (BOOL) isHardDiskFull;
+ (NSData*) produceJPEGThumbnail:(NSImage*) image;
+ (int) DefaultFolderSizeForDB;
+ (long) computeDATABASEINDEXforDatabase:(NSString*) path;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource showGUI: (BOOL) showGUI;
+ (void) encryptFiles: (NSArray*) srcFiles inZIPFile: (NSString*) destFile password: (NSString*) password;
- (IBAction) createDatabaseFolder:(id) sender;
- (void) openDatabasePath: (NSString*) path;
- (NSArray*) albums;
+ (NSArray*) albumsInContext:(NSManagedObjectContext*)context;
- (BOOL) shouldTerminate: (id) sender;
- (void) databaseOpenStudy: (NSManagedObject*) item;
- (IBAction) databaseDoublePressed:(id)sender;
- (void) setDBDate;
- (void) emptyDeleteQueueNow: (id) sender;
- (void) saveDeleteQueue;
- (void) setDockIcon;
- (void)drawerToggle: (id)sender;
- (void) showEntireDatabase;
- (void) subSelectFilesAndFoldersToAdd: (NSArray*) filenames;
- (void)matrixNewIcon:(long) index: (NSManagedObject*)curFile;
- (NSPredicate*) smartAlbumPredicate:(NSManagedObject*) album;
- (NSPredicate*) smartAlbumPredicateString:(NSString*) string;
- (void) emptyDeleteQueueThread;
- (void) emptyDeleteQueue:(id) sender;
- (void) addFileToDeleteQueue:(NSString*) file;
- (NSString*) getNewFileDatabasePath: (NSString*) extension;
- (NSString*) getNewFileDatabasePath: (NSString*) extension dbFolder: (NSString*) dbFolder;
- (NSManagedObjectModel *) managedObjectModel;

- (NSManagedObjectContext *) localManagedObjectContext;
- (NSManagedObjectContext *) localManagedObjectContextIndependentContext: (BOOL) independentContext;

- (NSManagedObjectContext *) managedObjectContext;
- (NSManagedObjectContext *) managedObjectContextIndependentContext:(BOOL) independentContext;
- (NSManagedObjectContext *) managedObjectContextIndependentContext:(BOOL) independentContext path: (NSString *) path;

- (NSManagedObjectContext *) defaultManagerObjectContext;
- (NSManagedObjectContext *) defaultManagerObjectContextIndependentContext: (BOOL) independentContext;

- (BOOL) isBonjour: (NSManagedObjectContext*) c;
- (NSString *) localDocumentsDirectory;
- (NSArray*) childrenArray: (NSManagedObject*) item;
- (NSArray*) childrenArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject;
- (NSArray*) imagesArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages;
- (void) setNetworkLogs;
- (BOOL) isNetworkLogsActive;
- (void) ReadDicomCDRom:(id) sender;
- (NSString*) INCOMINGPATH;
- (IBAction) matrixDoublePressed:(id)sender;
- (void) addURLToDatabaseEnd:(id) sender;
- (void) addURLToDatabase:(id) sender;
- (BOOL) addURLToDatabaseFiles:(NSArray*) URLs;
- (BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand;
- (BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection;
- (void) selectServer: (NSArray*) files;
- (void) loadDICOMFromiPod;
- (void) loadDICOMFromiPod: path;
- (long) saveDatabase;
- (long) saveDatabase:(NSString*) path;
- (long) saveDatabase: (NSString*)path context: (NSManagedObjectContext*) context;
- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files;
- (void) copyFilesIntoDatabaseIfNeeded: (NSMutableArray*)filesInput options: (NSDictionary*) options;
- (ViewerController*) loadSeries :(NSManagedObject *)curFile :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
- (void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
- (void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
- (ViewerController*) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages;
- (ViewerController*) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages tryToFlipData:(BOOL) tryToFlipData;
- (void) export2PACS:(id) sender;
+ (void)setPath:(NSString*)path relativeTo:(NSString*)dirPath forSeriesId:(int)seriesId kind:(NSString*)kind toSeriesPaths:(NSMutableDictionary*)seriesPaths; // used by +exportQuicktime
+ (void) exportQuicktime:(NSArray*)dicomFiles2Export :(NSString*)path :(BOOL)html :(BrowserController*)browser :(NSMutableDictionary*)seriesPaths;
- (void) exportQuicktimeInt:(NSArray*) dicomFiles2Export :(NSString*) path :(BOOL) html;
+ (void) multiThreadedImageConvert: (NSString*) what :(vImage_Buffer*) src :(vImage_Buffer *) dst :(float) offset :(float) scale;
- (IBAction) delItem:(id) sender;
- (void) proceedDeleteObjects: (NSArray*) objectsToDelete;
- (void) delObjects:(NSMutableArray*) objectsToDelete;
- (IBAction) selectFilesAndFoldersToAdd:(id) sender;
- (void) showDatabase:(id)sender;
- (NSInteger) displayStudy: (DicomStudy*) study object:(NSManagedObject*) element command:(NSString*) execute;
- (IBAction) matrixPressed:(id)sender;
- (void) loadDatabase:(NSString*) path;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer tileWindows: (BOOL) tileWindows;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;
- (NSArray*) exportDICOMFileInt:(NSString*) location files:(NSMutableArray*) filesToExport objects:(NSMutableArray*) dicomFiles2Export;
- (NSArray*) exportDICOMFileInt: (NSDictionary*) parameters;
- (void) processOpenViewerDICOMFromArray:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer: (ViewerController*) viewer;
- (void) setDatabaseValue:(id) object item:(id) item forKey:(NSString*) key;
- (void) setupToolbar;
- (void) addAlbumsFile: (NSString*) file;
- (void) sendFilesToCurrentBonjourDB: (NSArray*) files;
- (NSString*) getDatabaseFolderFor: (NSString*) path;
- (NSString*) getDatabaseIndexFileFor: (NSString*) path;
- (IBAction) copyToDBFolder: (id) sender;
- (void) setCurrentBonjourService:(long) index;
- (IBAction)customize:(id)sender;
- (IBAction)showhide:(id)sender;
- (IBAction) selectAll3DSeries:(id) sender;
- (IBAction) selectAll4DSeries:(id) sender;
- (IBAction) switchSoundex: (id)sender;
- (void) exportDICOMFile:(id) sender;
- (void) viewerDICOM:(id) sender;
- (void)newViewerDICOM:(id) sender;
- (void) viewerDICOMKeyImages:(id) sender;
- (void) viewerDICOMMergeSelection:(id) sender;
- (IBAction)addSmartAlbum: (id)sender;
- (IBAction)search: (id)sender;
- (IBAction)setSearchType: (id)sender;
- (void) setDraggedItems:(NSArray*) pbItems;
- (IBAction)setTimeIntervalType: (id)sender;
- (IBAction) endCustomInterval:(id) sender;
- (IBAction) customIntervalNow:(id) sender;
- (IBAction) saveDBListAs:(id) sender;
- (IBAction) openDatabase:(id) sender;
- (IBAction) createDatabase:(id) sender;
- (void) checkReportsDICOMSRConsistency;
- (void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour;
- (void) openDatabaseIn: (NSString*)a Bonjour: (BOOL)isBonjour refresh: (BOOL) refresh;
- (void) browserPrepareForClose;
- (IBAction) endReBuildDatabase:(id) sender;
- (IBAction) ReBuildDatabase:(id) sender;
- (IBAction) ReBuildDatabaseSheet: (id)sender;
- (void) previewSliderAction:(id) sender;
- (void) addHelpMenu;
+ (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory;
+ (BOOL)isItCD:(NSString*) path;
- (void)storeSCPComplete:(id)sender;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingDicomFile;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;
- (void)setToolbarReportIconForItem: (NSToolbarItem *)item;
- (void) executeAutorouting: (NSArray *)newImages rules: (NSArray*) autoroutingRules manually: (BOOL) manually;
- (void) executeAutorouting: (NSArray *)newImages rules: (NSArray*) autoroutingRules manually: (BOOL) manually generatedByOsiriX: (BOOL) generatedByOsiriX;
- (void) addFiles: (NSArray*) files withRule:(NSDictionary*) routingRule;
- (void) resetListenerTimer;
- (IBAction) albumTableDoublePressed: (id)sender;
- (IBAction) smartAlbumHelpButton:(id) sender;
- (IBAction) regenerateAutoComments:(id) sender;
- (DCMPix *)previewPix:(int)i;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray;
- (void) addFilesAndFolderToDatabase:(NSArray*) filenames;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  safeRebuild:(BOOL) safeRebuild produceAddedFiles:(BOOL) produceAddedFiles;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder generatedByOsiriX:(BOOL)generatedByOsiriX;
+(NSArray*) addFiles:(NSArray*) newFilesArray toContext: (NSManagedObjectContext*) context toDatabase: (BrowserController*) browserController onlyDICOM: (BOOL) onlyDICOM  notifyAddedFiles: (BOOL) notifyAddedFiles parseExistingObject: (BOOL) parseExistingObject dbFolder: (NSString*) dbFolder generatedByOsiriX: (BOOL) generatedByOsiriX mountedVolume: (BOOL) mountedVolume;
- (void) createDBContextualMenu;
+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination;
+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination showGUI: (BOOL) showGUI;
- (int) askForZIPPassword: (NSString*) file destination: (NSString*) destination;
- (IBAction) reparseIn3D:(id) sender;
- (IBAction) reparseIn4D:(id) sender;
- (void) selectThisStudy: (id)study;

//- (short) createAnonymizedFile:(NSString*) srcFile :(NSString*) dstFile;

//- (void)runSendQueue:(id)object;
//- (void)addToQueue:(NSArray *)array;

-(void) previewPerformAnimation:(id) sender;
-(void) matrixDisplayIcons:(id) sender;
//- (void)reloadSendLog:(id)sender;

- (NSArray*) KeyImages: (id) sender;
- (NSArray*) ROIImages: (id) sender;
- (NSArray*) ROIsAndKeyImages: (id) sender;
- (NSArray*) ROIsAndKeyImages: (id) sender sameSeries: (BOOL*) sameSeries;

- (void) refreshColumns;
- (NSString*) outlineViewRefresh;
- (void) matrixInit:(long) noOfImages;
- (IBAction) albumButtons: (id)sender;
- (NSArray*) albumArray;
- (void) refreshAlbums;
- (void) waitForRunningProcesses;
- (void) checkResponder;

- (NSArray*) imagesPathArray: (NSManagedObject*) item;

- (void) autoCleanDatabaseFreeSpace:(id) sender;
- (void) autoCleanDatabaseDate:(id) sender;

- (void) refreshDatabase:(id) sender;
- (void) syncReportsIfNecessary;
- (void) removeAllMounted;
- (void) removeMountedImages: (NSString*) sNewDrive;

//bonjour
- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;
//- (void) setServiceName:(NSString*) title;
//- (NSString*) serviceName;
//- (IBAction)toggleBonjourSharing:(id) sender;
//- (void) setBonjourSharingEnabled:(BOOL) boo;
//- (void) bonjourWillPublish;
//- (void) bonjourDidStop;
- (IBAction) bonjourServiceClicked:(id)sender;
- (NSString*) getLocalDCMPath: (NSManagedObject*) obj :(long) no;
- (void) displayBonjourServices;
- (NSString*) askPassword;
- (void) resetToLocalDatabase;
- (void) switchToDefaultDBIfNeeded;
- (void) createContextualMenu;
- (void) checkIncomingThread:(id) sender;
- (void) checkIncoming:(id) sender;
- (NSArray*) openSubSeries: (NSArray*) toOpenArray;
- (IBAction) checkMemory:(id) sender;
- (IBAction) buildAllThumbnails:(id) sender;
- (IBAction) mergeStudies:(id) sender;

// Finding Comparisons
- (NSArray *)relatedStudiesForStudy:(id)study;

//DB plugins
- (void)executeFilterDB:(id)sender;

+ (NSString*) defaultDocumentsDirectory;
- (NSString *)documentsDirectoryFor:(int) mode url:(NSString*) url;
- (NSString *)setFixedDocumentsDirectory;
- (IBAction)showLogWindow: (id)sender;
- (void) resetLogWindowController;

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path;

- (void)setFilterPredicate:(NSPredicate *)predicate description:(NSString*) desc;
- (NSPredicate *)createFilterPredicate;
- (NSString *)createFilterDescription;


- (IBAction) deleteReport: (id) sender;
//- (IBAction)srReports: (id)sender;

- (IBAction) rebuildThumbnails:(id) sender;

- (NSArray *)databaseSelection;


- (void) newFilesGUIUpdateRun:(int) state;
- (void) newFilesGUIUpdateRun: (int) state viewersListToReload: (NSMutableArray*) cReload viewersListToRebuild: (NSMutableArray*) cRebuild;
- (void) newFilesGUIUpdate:(id) sender;

- (void) refreshMatrix:(id) sender;
- (void)updateReportToolbarIcon:(NSNotification *)note;

#ifndef OSIRIX_LIGHT
- (IBAction) paste: (id)sender;
- (IBAction) pasteImageForSourceFile: (NSString*) sourceFile;
- (void) decompressDICOMJPEG: (NSArray*) array;
//- (void) decompressWaitIncrementation: (NSNumber*) n;
- (void) compressDICOMJPEG:(NSArray*) array;
- (void) decompressThread: (NSNumber*) typeOfWork;
- (void) decompressArrayOfFiles: (NSArray*) array work:(NSNumber*) work;
- (IBAction) compressSelectedFiles:(id) sender;
- (IBAction) decompressSelectedFiles:(id) sender;
- (void) importReport:(NSString*) path UID: (NSString*) uid;
- (IBAction) generateReport: (id) sender;
- (IBAction)importRawData:(id)sender;
- (void) pdfPreview:(id)sender;
- (void) burnDICOM:(id) sender;
- (IBAction) anonymizeDICOM:(id) sender;
- (void) queryDICOM:(id) sender;
- (IBAction) sendiDisk:(id) sender;
- (IBAction) querySelectedStudy:(id) sender;
#endif

- (void) initAnimationSlider;


- (void) setSearchString: (NSString *)searchString;

+ (NSString*) DateTimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) TimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) DateOfBirthFormat:(NSDate*) d __deprecated;
+ (NSString*) DateTimeFormat:(NSDate*) d __deprecated;
+ (NSString*) TimeFormat:(NSDate*) t;

- (int) findObject:(NSString*) request table:(NSString*) table execute: (NSString*) execute elements:(NSString**) elements;

- (void) executeSend :(NSArray*) samePatientArray server:(NSDictionary*) server dictionary:(NSDictionary*) dict;

- (void)writeMovie:(NSArray*)imagesArray name:(NSString*)fileName;
- (void) buildThumbnail:(NSManagedObject*) series;

/******Notifactions posted by browserController***********
OsirixNewStudySelectedNotification with userinfo key @"Selected Study" posted when a newStudy is selected in the browser
@"Close All Viewers" posted when close open windows if option key pressed.	
@"DCMImageTilingHasChanged" when image tiling has changed
OsirixAddToDBNotification posted when files are added to the DB
*/

#pragma mark Deprecated

@property(readonly) NSManagedObjectContext *userManagedObjectContext __deprecated;
@property(readonly) NSManagedObjectModel *userManagedObjectModel __deprecated;

-(long)saveUserDatabase __deprecated;
-(WebPortalUser*)userWithName:(NSString*)name __deprecated;



@end
