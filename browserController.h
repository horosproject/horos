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

@class DicomDatabase;

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

extern NSString* O2AlbumDragType;

@interface NSString (BrowserController)
-(NSMutableString*)filenameString;
@end

/** \brief Window controller for Browser
*
*   This is a large class with a lot of functions.
*   Along with managing the Browser Window it manages all the view in the browser
*	and manges the database
*/

@interface BrowserController : NSWindowController
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5)
<NSTableViewDelegate, NSDrawerDelegate, NSMatrixDelegate, NSToolbarDelegate, NSMenuDelegate>   //NSObject
#endif
{
//	NSManagedObjectModel			*managedObjectModel;//, *userManagedObjectModel;
//    NSManagedObjectContext			*managedObjectContext;//, *userManagedObjectContext;
//	NSPersistentStoreCoordinator	*userPersistentStoreCoordinator;
//	NSMutableDictionary				*persistentStoreCoordinatorDictionary;
	DicomDatabase*					_database;
	NSMutableDictionary				*databaseIndexDictionary;
	
	NSDateFormatter			*TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
	
	NSRect					visibleScreenRect[ 40];
//	NSString				*currentDatabasePath;
//	BOOL					isCurrentDatabaseBonjour;
//	NSManagedObjectContext	*bonjourManagedObjectContext;
	NSString				*transferSyntax;
    NSArray                 *dirArray;
    NSToolbar               *toolbar;
	
	NSMutableArray			*sendQueue;
	NSMutableDictionary		*reportFilesToCheck;
	
    NSMutableArray          *previewPix, *previewPixThumbnails;
		
	NSMutableDictionary		*activeSends;
	NSMutableArray			*sendLog;
	NSMutableDictionary		*activeReceives;
	NSMutableArray			*receiveLog;
	
	LogWindowController			*logWindowController;
	
    DCMPix                  *curPreviewPix;
    
    NSTimer                 *timer, /**IncomingTimer,*/ /**matrixDisplayIcons,*/ *refreshTimer, *databaseCleanerTimer/*, *bonjourTimer*/, *deleteQueueTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
	long					previousBonjourIndex;
	
//    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert, *splitAlbums, *splitDrawer;
    CGFloat _splitViewVertDividerRatio;
    
	BOOL					setDCMDone, dontUpdatePreviewPane;
	
	NSMutableArray*         _albumNoOfStudiesCache;
    NSArray*                _cachedAlbums;
    NSManagedObjectContext* _cachedAlbumsContext;
	
 //   volatile BOOL			bonjourDownloading;
	
	NSArray							*outlineViewArray, *originalOutlineViewArray;
	NSArray							*matrixViewArray;
	
	NSString						*_searchString;
	
	IBOutlet NSTextField			*databaseDescription;
	IBOutlet MyOutlineView          *databaseOutline;
	NSMenu							*columnsMenu;
	IBOutlet BrowserMatrix			*oMatrix;
	IBOutlet NSTableView			*albumTable;
	
	IBOutlet NSBox					*bonjourSourcesBox;
	
	IBOutlet NSArrayController*		_sourcesArrayController;
	IBOutlet NSTableView*			_sourcesTableView;
	id								_sourcesHelper;
	BonjourPublisher				*bonjourPublisher;
	BonjourBrowser					*bonjourBrowser;
	
	IBOutlet NSSlider				*animationSlider;
	IBOutlet NSButton				*animationCheck;
    IBOutlet NSSplitView*           _bottomSplit;
    
    IBOutlet PreviewView			*imageView;
	
	int								subFrom, subTo, subInterval, subMax;
	
	IBOutlet NSWindow				*subOpenWindow;
	IBOutlet NSMatrix				*subOpenMatrix3D, *subOpenMatrix4D, *supOpenButtons;
	
	IBOutlet NSWindow				*subSeriesWindow;
	IBOutlet NSButton				*subSeriesOKButton;
	IBOutlet NSTextField			*memoryMessage;
	IBOutlet NSImageView			*leftIcon, *rightIcon;
	IBOutlet NSBox					*warningBox;
	
	IBOutlet NSWindow				*bonjourPasswordWindow;
	IBOutlet NSTextField			*password;
	
	IBOutlet NSWindow				*newAlbum;
	IBOutlet NSTextField			*newAlbumName;
	
	IBOutlet NSWindow				*editSmartAlbum;
	IBOutlet NSTextField			*editSmartAlbumName, *editSmartAlbumQuery;
	
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
	
//	NSRecursiveLock					/**checkIncomingLock,*/ *checkBonjourUpToDateThreadLock;
	NSPredicate						*testPredicate;
	
    BOOL							showAllImages, DatabaseIsEdited, isNetworkLogsActive;//, displayEmptyDatabase;
	NSConditionLock					*queueLock;
	
	IBOutlet NSScrollView			*thumbnailsScrollView;
	
	NSPredicate						*_fetchPredicate, *_filterPredicate;
	NSString						*_filterPredicateDescription;
	
	NSString						/**fixedDocumentsDirectory,*/ *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption;
	
//	char							cfixedDocumentsDirectory[ 4096], cfixedIncomingDirectory[ 4096], cfixedTempNoIndexDirectory[ 4096], cfixedIncomingNoIndexDirectory[ 4096];
	
//	NSTimeInterval					databaseLastModification;
	NSUInteger						previousFlags;
//	StructuredReportController		*structuredReportController;
	
	NSMutableArray					*deleteQueueArray;
	NSRecursiveLock					*deleteQueue, *deleteInProgress;
	
	NSConditionLock					*processorsLock;
//	NSRecursiveLock					*decompressArrayLock, *decompressThreadRunning;
//	NSMutableArray					*decompressArray;
	
	NSMutableString					*pressedKeys;
	
	IBOutlet NSView					*reportTemplatesView;
	IBOutlet NSImageView			*reportTemplatesImageView;
	IBOutlet NSPopUpButton			*reportTemplatesListPopUpButton;
	int								reportToolbarItemType;
	
	IBOutlet NSWindow				*addStudiesToUserWindow;
	IBOutlet NSWindow				*notificationEmailWindow;
	IBOutlet NSArrayController		*notificationEmailArrayController;
	NSString						*temporaryNotificationEmail, *customTextNotificationEmail;
	
//	NSConditionLock					*newFilesConditionLock;
//	NSMutableArray					*viewersListToReload, *viewersListToRebuild;
	
//	volatile BOOL					newFilesInIncoming;
	NSImage							*notFoundImage;
	
	BOOL							ROIsAndKeyImagesButtonAvailable;
	
	BOOL							rtstructProgressBar;
	float							rtstructProgressPercent;
	
	BOOL							avoidRecursive, openSubSeriesFlag, openReparsedSeriesFlag;
	
	IBOutlet PluginManagerController *pluginManagerController;
//	NSTimeInterval					lastCheckIncoming;
	
	WaitRendering					*waitOpeningWindow;
//	Wait							*waitCompressionWindow;
	BOOL							waitCompressionAbort;
	
//	BOOL							checkForMountedFiles;
	
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionSelectedFiles;
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionCorrespondingObjects;
	NSIndexSet						*cachedFilesForDatabaseOutlineSelectionIndex;
	
    BOOL                            _computingNumberOfStudiesForAlbums;
    
//	NSArray							*mountedVolumes;
	
	IBOutlet NSTableView* _activityTableView;//AtableView;
//	IBOutlet NSImageView* AcpuActiView, *AhddActiView, *AnetActiView;
//	IBOutlet NSTextField* AstatusLabel;
//	NSThread* AupdateStatsThread;
	id _activityHelper;
    
    IBOutlet NSSplitView *bannerSplit;
    IBOutlet NSButton *banner;
    
    NSTimeInterval _timeIntervalOfLastLoadIconsDisplayIcons;
    
    BOOL subSeriesWindowIsOn;
}

@property(retain,nonatomic) DicomDatabase* database;
@property(readonly) NSArrayController* sources;

@property(readonly) NSDateFormatter *DateTimeFormat __deprecated, *DateOfBirthFormat __deprecated, *TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
/*@property(readonly) NSRecursiveLock *checkIncomingLock;*/
@property(readonly) NSArray *matrixViewArray;
@property(readonly) NSMatrix *oMatrix;
//@property(readonly) long COLUMN /*currentBonjourService*/;
@property(readonly) BOOL is2DViewer, isCurrentDatabaseBonjour;
@property(readonly) MyOutlineView *databaseOutline;
@property(readonly) NSTableView *albumTable;
@property(readonly) NSString *currentDatabasePath __deprecated, *localDatabasePath __deprecated, *documentsDirectory __deprecated, *fixedDocumentsDirectory __deprecated;

//@property(readonly) NSTableView* AtableView;
//@property(readonly) NSImageView* AcpuActiView, *AhddActiView, *AnetActiView;
//@property(readonly) NSTextField* AstatusLabel;

//@property volatile BOOL bonjourDownloading;
@property(readonly) NSBox *bonjourSourcesBox;
@property(readonly) BonjourBrowser *bonjourBrowser;
@property(readonly) const char *cfixedDocumentsDirectory __deprecated, *cfixedIncomingDirectory __deprecated, *cfixedTempNoIndexDirectory __deprecated, *cfixedIncomingNoIndexDirectory __deprecated;

@property(retain) NSString *searchString, *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption, *temporaryNotificationEmail, *customTextNotificationEmail;
@property(retain) NSPredicate *fetchPredicate, *testPredicate;
@property(readonly) NSPredicate *filterPredicate;
@property(readonly) NSString *filterPredicateDescription;

@property BOOL rtstructProgressBar;
@property float rtstructProgressPercent;
@property (nonatomic) NSTimeInterval databaseLastModification __deprecated;
//@property(readonly) NSMutableArray *viewersListToReload, *viewersListToRebuild;
//@property(readonly) NSConditionLock* newFilesConditionLock;
@property(readonly) NSMutableDictionary *databaseIndexDictionary;
@property(readonly) PluginManagerController *pluginManagerController;

+(void)initializeBrowserControllerClass;

+ (int) compressionForModality: (NSString*) mod quality:(int*) quality resolution: (int) resolution;
+ (BrowserController*) currentBrowser;
+ (NSMutableString*) replaceNotAdmitted: (NSString*)name;
+ (NSArray*) statesArray;
+ (void) updateActivity;
+ (BOOL) isHardDiskFull __deprecated;
+ (NSData*) produceJPEGThumbnail:(NSImage*) image;
+ (int) DefaultFolderSizeForDB;
+ (long) computeDATABASEINDEXforDatabase:(NSString*) path __deprecated;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource showGUI: (BOOL) showGUI;
+ (void) encryptFiles: (NSArray*) srcFiles inZIPFile: (NSString*) destFile password: (NSString*) password;
- (IBAction) createDatabaseFolder:(id) sender;
- (IBAction) addAlbum:(id)sender;
- (IBAction) deleteAlbum: (id)sender;
- (IBAction) saveAlbums:(id) sender;
- (IBAction) addAlbums:(id) sender;
- (IBAction) defaultAlbums: (id) sender;
- (IBAction) clickBanner:(id) sender;
- (IBAction)drawerToggle: (id)sender;
- (void) openDatabasePath: (NSString*) path __deprecated;
- (NSArray*) albums;
+ (NSArray*) albumsInContext:(NSManagedObjectContext*)context __deprecated;
- (BOOL) shouldTerminate: (id) sender;
- (void) databaseOpenStudy: (NSManagedObject*) item;
- (IBAction) databaseDoublePressed:(id)sender;
- (void) setDBDate;
- (void) emptyDeleteQueueNow: (id) sender;
- (void) saveDeleteQueue;
- (void)drawerToggle: (id)sender;
- (void) showEntireDatabase;
- (void) subSelectFilesAndFoldersToAdd: (NSArray*) filenames;
- (void)matrixNewIcon:(long) index: (NSManagedObject*)curFile;
- (NSPredicate*) smartAlbumPredicate:(NSManagedObject*) album;
- (NSPredicate*) smartAlbumPredicateString:(NSString*) string;
- (void) emptyDeleteQueueThread;
- (void) emptyDeleteQueue:(id) sender;
- (BOOL)isUsingExternalViewer: (NSManagedObject*) item;
- (void) addFileToDeleteQueue:(NSString*) file;
- (NSString*) getNewFileDatabasePath: (NSString*) extension __deprecated;
- (NSString*) getNewFileDatabasePath: (NSString*) extension dbFolder: (NSString*) dbFolder __deprecated;
- (NSManagedObjectModel *) managedObjectModel __deprecated;

- (NSManagedObject*) findStudyUID: (NSString*) uid;
- (NSManagedObject*) findSeriesUID: (NSString*) uid;

- (NSManagedObjectContext *) localManagedObjectContext __deprecated;
- (NSManagedObjectContext *) localManagedObjectContextIndependentContext: (BOOL) independentContext __deprecated;

- (NSManagedObjectContext *) managedObjectContext __deprecated;
- (NSManagedObjectContext *) managedObjectContextIndependentContext:(BOOL) independentContext __deprecated;
- (NSManagedObjectContext *) managedObjectContextIndependentContext:(BOOL) independentContext path: (NSString *) path __deprecated;

- (NSManagedObjectContext *) defaultManagerObjectContext __deprecated;
- (NSManagedObjectContext *) defaultManagerObjectContextIndependentContext: (BOOL) independentContext __deprecated;

- (BOOL) isBonjour: (NSManagedObjectContext*) c __deprecated;
- (NSString *) localDocumentsDirectory __deprecated;
- (void) alternateButtonPressed: (NSNotification*)n;
- (NSArray*) childrenArray: (NSManagedObject*) item;
- (NSArray*) childrenArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject;
- (NSArray*) imagesArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages;
- (void) setNetworkLogs;
- (BOOL) isNetworkLogsActive;
- (void) ReadDicomCDRom:(id) sender __deprecated;
- (NSString*) INCOMINGPATH __deprecated;
- (NSString*) TEMPPATH __deprecated;
- (IBAction) matrixDoublePressed:(id)sender;
- (void) addURLToDatabaseEnd:(id) sender;
- (void) addURLToDatabase:(id) sender;
- (NSArray*) addURLToDatabaseFiles:(NSArray*) URLs;
- (BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand;
- (BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection;
- (void) selectServer: (NSArray*) files;
//- (void) loadDICOMFromiPod __deprecated;
- (long) saveDatabase __deprecated;
- (long) saveDatabase:(NSString*) path __deprecated;
- (long) saveDatabase: (NSString*)path context: (NSManagedObjectContext*) context __deprecated;
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
- (void) loadDatabase:(NSString*) path __deprecated;
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
- (void) sendFilesToCurrentBonjourDB: (NSArray*) files __deprecated;
- (NSString*) getDatabaseFolderFor: (NSString*) path __deprecated;
- (NSString*) getDatabaseIndexFileFor: (NSString*) path __deprecated;
- (IBAction) copyToDBFolder: (id) sender;
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
//- (void) setDraggedItems:(NSArray*) pbItems;
- (IBAction)setTimeIntervalType: (id)sender;
- (IBAction) endCustomInterval:(id) sender;
- (IBAction) customIntervalNow:(id) sender;
- (IBAction) saveDBListAs:(id) sender;
- (IBAction) openDatabase:(id) sender;
- (void) checkReportsDICOMSRConsistency __deprecated;
- (void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour __deprecated;
- (void) openDatabaseIn: (NSString*)a Bonjour: (BOOL)isBonjour refresh: (BOOL) refresh __deprecated;
- (void) browserPrepareForClose;
- (IBAction) endReBuildDatabase:(id) sender;
- (IBAction) ReBuildDatabaseSheet: (id)sender;
- (void) previewSliderAction:(id) sender;
- (void) addHelpMenu;
+ (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory __deprecated;
+ (BOOL)isItCD:(NSString*) path;
- (void)storeSCPComplete:(id)sender;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingDicomFile;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;
- (void)setToolbarReportIconForItem: (NSToolbarItem *)item;
- (void)executeAutorouting: (NSArray *)newImages rules: (NSArray*) autoroutingRules manually: (BOOL) manually __deprecated;
- (void)executeAutorouting: (NSArray *)newImages rules: (NSArray*) autoroutingRules manually: (BOOL) manually generatedByOsiriX: (BOOL) generatedByOsiriX __deprecated;
- (void) addFiles: (NSArray*) files withRule:(NSDictionary*) routingRule __deprecated;
- (void) resetListenerTimer __deprecated;
- (IBAction) albumTableDoublePressed: (id)sender;
- (IBAction) smartAlbumHelpButton:(id) sender;
- (IBAction) regenerateAutoComments:(id) sender;
- (DCMPix *)previewPix:(int)i;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray __deprecated;
- (void) addFilesAndFolderToDatabase:(NSArray*) filenames __deprecated;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles __deprecated;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject __deprecated;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder __deprecated;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  safeRebuild:(BOOL) safeRebuild produceAddedFiles:(BOOL) produceAddedFiles __deprecated;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder __deprecated;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder __deprecated;
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder generatedByOsiriX:(BOOL)generatedByOsiriX __deprecated;
+(NSArray*) addFiles:(NSArray*) newFilesArray toContext: (NSManagedObjectContext*) context toDatabase: (BrowserController*) browserController onlyDICOM: (BOOL) onlyDICOM  notifyAddedFiles: (BOOL) notifyAddedFiles parseExistingObject: (BOOL) parseExistingObject dbFolder: (NSString*) dbFolder generatedByOsiriX: (BOOL) generatedByOsiriX mountedVolume: (BOOL) mountedVolume __deprecated;
+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination;
+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination showGUI: (BOOL) showGUI;
- (int) askForZIPPassword: (NSString*) file destination: (NSString*) destination;
- (IBAction) reparseIn3D:(id) sender;
- (IBAction) reparseIn4D:(id) sender;
- (void)selectStudyWithObjectID:(NSManagedObjectID*)oid;
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
- (NSArray*) albumArray;
- (void) refreshAlbums;
- (void) waitForRunningProcesses;
- (void) checkResponder;

- (NSArray*) imagesPathArray: (NSManagedObject*) item;

- (void) autoCleanDatabaseFreeSpace:(id) sender __deprecated;
- (void) autoCleanDatabaseDate:(id) sender __deprecated;

- (void) refreshDatabase:(id) sender;
- (void) syncReportsIfNecessary;

//- (void) removeAllMounted __deprecated;
//- (void) removeMountedImages: (NSString*) sNewDrive __deprecated;

//bonjour
-(NSManagedObjectContext*)bonjourManagedObjectContext __deprecated;
- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key __deprecated;
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
- (void) switchToDefaultDBIfNeeded __deprecated;
- (void) checkIncomingThread:(id) sender __deprecated;
- (void) checkIncoming:(id) sender __deprecated;
- (void) checkIncomingNow:(id) sender __deprecated;
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

+ (NSString*) defaultDocumentsDirectory  __deprecated;
- (NSString *)documentsDirectoryFor:(int) mode url:(NSString*) url  __deprecated;
// - (NSString *)setFixedDocumentsDirectory  __deprecated; // this is commented out but still available, so it causes compilation errors
- (IBAction)showLogWindow: (id)sender;
- (void) resetLogWindowController;

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path __deprecated;

- (void)setFilterPredicate:(NSPredicate *)predicate description:(NSString*) desc;
- (NSPredicate *)createFilterPredicate;
- (NSString *)createFilterDescription;


- (IBAction) deleteReport: (id) sender;
- (IBAction) convertReportToPDF: (id)sender;
- (IBAction) convertReportToDICOMSR: (id)sender;

- (IBAction) rebuildThumbnails:(id) sender;

- (NSArray *)databaseSelection;


//- (void) newFilesGUIUpdateRun:(int) state __deprecated;
//- (void) newFilesGUIUpdateRun: (int) state viewersListToReload: (NSMutableArray*) cReload viewersListToRebuild: (NSMutableArray*) cRebuild  __deprecated;
//- (void) newFilesGUIUpdate:(id) sender __deprecated;

- (void) refreshMatrix:(id) sender;
- (void)updateReportToolbarIcon:(NSNotification *)note;

#ifndef OSIRIX_LIGHT
- (IBAction) paste: (id)sender;
- (IBAction) pasteImageForSourceFile: (NSString*) sourceFile;
- (void) decompressDICOMJPEG: (NSArray*) array __deprecated;
//- (void) decompressWaitIncrementation: (NSNumber*) n;
- (void) compressDICOMJPEG:(NSArray*) array __deprecated;
//- (void) decompressThread: (NSNumber*) typeOfWork __deprecated;
- (void) decompressArrayOfFiles: (NSArray*) array work:(NSNumber*) work __deprecated;
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

- (int) findObject:(NSString*) request table:(NSString*) table execute: (NSString*) execute elements:(NSString**) elements __deprecated;

// - (void) executeSend :(NSArray*) samePatientArray server:(NSDictionary*) server dictionary:(NSDictionary*) dict __deprecated;

- (void)writeMovie:(NSArray*)imagesArray name:(NSString*)fileName;
- (void) buildThumbnail:(NSManagedObject*) series;

/******Notifactions posted by browserController***********
OsirixNewStudySelectedNotification with userinfo key @"Selected Study" posted when a newStudy is selected in the browser
@"Close All Viewers" posted when close open windows if option key pressed.	
@"DCMImageTilingHasChanged" when image tiling has changed
OsirixAddToDBNotification posted when files are added to the DB
*/

+(NSInteger)_scrollerStyle:(NSScroller*)scroller;

#pragma mark Deprecated

@property(readonly) NSManagedObjectContext *userManagedObjectContext __deprecated;
@property(readonly) NSManagedObjectModel *userManagedObjectModel __deprecated;

-(long)saveUserDatabase __deprecated;
-(WebPortalUser*)userWithName:(NSString*)name __deprecated;



@end

#import "BrowserController+Sources.h"
