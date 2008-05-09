/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>
/*
#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "AnonymizerWindowController.h"
*/

@class MPR2DController;
@class NSCFDate;
@class BurnerWindowController;
@class ViewerController;
@class BonjourPublisher;
@class BonjourBrowser;
@class AnonymizerWindowController;
@class QueryController;
@class LogWindowController;
@class PreviewView;
@class MyOutlineView;
@class DCMView;
@class DCMPix;
@class StructuredReportController;
@class BrowserMatrix;
@class PluginManagerController;

enum RootTypes{PatientRootType, StudyRootType, RandomRootType};
enum simpleSearchType {PatientNameSearch, PatientIDSearch};
enum queueStatus{QueueHasData, QueueEmpty};
enum dbObjectSelection {oAny,oMiddle,oFirstForFirst};

/** \brief Window controller for Browser
*
*   This is a large class with a lot of functions.
*   Along with managing the Browser Window it manages all the view in the browser
*	and manges the database
*/

@interface BrowserController : NSWindowController   //NSObject
{
	NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext;
	NSPersistentStoreCoordinator	*persistentStoreCoordinator;
	
	NSDateFormatter			*DateTimeFormat, *DateOfBirthFormat, *TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
	
	
	NSString				*currentDatabasePath;
	BOOL					isCurrentDatabaseBonjour;
	NSString				*transferSyntax;
    NSArray                 *dirArray;
    NSToolbar               *toolbar;
	
	NSMutableArray			*sendQueue;
	NSMutableDictionary		*bonjourReportFilesToCheck;
	
    NSMutableArray          *previewPix, *previewPixThumbnails;
	
	NSMutableArray			*draggedItems;
		
	NSMutableDictionary		*activeSends;
	NSMutableArray			*sendLog;
	NSMutableDictionary		*activeReceives;
	NSMutableArray			*receiveLog;
	
	AnonymizerWindowController	*anonymizerController;
	BurnerWindowController		*burnerWindowController;
	LogWindowController			*logWindowController;
	
	NSNumberFormatter		*numFmt;
    
//	NSData					*notFoundDataThumbnail;
	
    DCMPix                  *curPreviewPix;
    
    NSTimer                 *timer, *IncomingTimer, *matrixDisplayIcons, *refreshTimer, *databaseCleanerTimer, *bonjourTimer, *deleteQueueTimer, *autoroutingQueueTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
	long					previousBonjourIndex;
	
    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert;
    
	BOOL					setDCMDone, mountedVolume, needDBRefresh, dontLoadSelectionSource;
	
	NSMutableArray			*albumNoOfStudiesCache;
	
    volatile BOOL           shouldDie, bonjourDownloading;
	
	NSArray							*outlineViewArray, *originalOutlineViewArray;
	NSArray							*matrixViewArray;
	
	NSString						*_searchString;
	
	IBOutlet NSTextField			*databaseDescription;
	IBOutlet MyOutlineView          *databaseOutline;
	NSMenu							*columnsMenu;
	IBOutlet BrowserMatrix			*oMatrix;
	IBOutlet NSTableView			*albumTable;
	IBOutlet NSSegmentedControl		*segmentedAlbumButton;
	
	IBOutlet NSSplitView			*sourcesSplitView;
	IBOutlet NSBox					*bonjourSourcesBox;
	
	IBOutlet NSTextField			*bonjourServiceName, *bonjourPassword;
	IBOutlet NSTableView			*bonjourServicesList;
	IBOutlet NSButton				*bonjourSharingCheck, *bonjourPasswordCheck;
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
//	IBOutlet NSPredicateEditor		*editSmartAlbumPredicate;
	
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
	IBOutlet NSWindow				*urlWindow;
	IBOutlet NSTextField			*urlString;
	
	IBOutlet NSForm					*rdPatientForm;
	IBOutlet NSForm					*rdPixelForm;
	IBOutlet NSForm					*rdVoxelForm;
	IBOutlet NSForm					*rdOffsetForm;
	IBOutlet NSMatrix				*rdPixelTypeMatrix;
	IBOutlet NSView					*rdAccessory;
	
	IBOutlet NSView					*exportQuicktimeView;
	IBOutlet NSButton				*exportHTMLButton;
	
	IBOutlet NSView					*exportAccessoryView;
	IBOutlet NSButton				*addDICOMDIRButton;
	IBOutlet NSMatrix				*compressionMatrix;
    IBOutlet NSMatrix				*folderTree;
	
	NSRecursiveLock					*checkIncomingLock;
	NSLock							*checkBonjourUpToDateThreadLock;
	NSTimeInterval					lastSaved;
	
    BOOL							showAllImages, DatabaseIsEdited, isNetworkLogsActive, displayEmptyDatabase;
	NSConditionLock					*queueLock;
	
	IBOutlet NSScrollView			*thumbnailsScrollView;
	
	NSPredicate						*_fetchPredicate;
	NSPredicate						*_filterPredicate;
	NSString						*_filterPredicateDescription;
	
	NSString						*fixedDocumentsDirectory;
	
	char							cfixedDocumentsDirectory[ 1024], cfixedIncomingDirectory[ 1024];
	
	NSTimeInterval					databaseLastModification;
	
	StructuredReportController		*structuredReportController;
	
	NSMutableArray					*deleteQueueArray;
	NSLock							*deleteQueue, *deleteInProgress;
	
	NSMutableArray					*autoroutingQueueArray;
	NSLock							*autoroutingQueue, *autoroutingInProgress, *matrixLoadIconsLock;
	
	NSConditionLock					*processorsLock;
	NSLock							*decompressArrayLock, *decompressThreadRunning;
	NSMutableArray					*decompressArray;
	
	NSMutableString					*pressedKeys;
	
	IBOutlet NSView					*reportTemplatesView;
	IBOutlet NSImageView			*reportTemplatesImageView;
	IBOutlet NSPopUpButton			*reportTemplatesListPopUpButton;
	
	NSConditionLock					*newFilesConditionLock;
	NSMutableArray					*viewersListToReload, *viewersListToRebuild;
	
	NSImage							*notFoundImage;
	
	volatile BOOL					newFilesInIncoming;
	NSImage							*standardOsiriXIcon;
	NSImage							*downloadingOsiriXIcon;
	NSImage							*currentIcon;
	
	BOOL							rtstructProgressBar;  // make visible
	float							rtstructProgressPercent;
	
	int								DicomDirScanDepth;
	
	IBOutlet PluginManagerController *pluginManagerController;
}

@property(readonly) NSDateFormatter *DateTimeFormat;
@property(readonly) NSDateFormatter *DateOfBirthFormat;
@property(readonly) NSDateFormatter *TimeFormat;
@property(readonly) NSDateFormatter *TimeWithSecondsFormat;
@property(readonly) NSDateFormatter *DateTimeWithSecondsFormat;

@property(readonly) NSArray *matrixViewArray;
@property(readonly) NSMatrix *oMatrix;
@property(readonly) long COLUMN;
@property(readonly) BOOL is2DViewer;
@property(readonly) MyOutlineView *databaseOutline;
@property(readonly) NSTableView *albumTable;
@property(readonly) BOOL isCurrentDatabaseBonjour;
@property(readonly) NSString *currentDatabasePath;
@property(readonly) NSString *localDatabasePath;
@property(readonly) NSString *bonjourPassword;
@property(readonly) long currentBonjourService;

@property volatile BOOL bonjourDownloading;
@property(readonly) NSBox *bonjourSourcesBox;
@property(readonly) NSTextField *bonjourServiceName;
@property(readonly) NSTextField *bonjourPasswordTextField;
@property(readonly) NSButton *bonjourSharingCheck;
@property(readonly) NSButton *bonjourPasswordCheck;
@property(readonly) BonjourBrowser *bonjourBrowser;

@property(readonly) NSString *documentsDirectory;
@property(readonly) NSString *fixedDocumentsDirectory;
@property(readonly) char *cfixedDocumentsDirectory, *cfixedIncomingDirectory;

@property(retain) NSString *searchString;
@property(retain) NSPredicate *fetchPredicate;
@property(readonly) NSPredicate *filterPredicate;
@property(readonly) NSString *filterPredicateDescription;

@property BOOL rtstructProgressBar;
@property float rtstructProgressPercent;

@property(readonly) PluginManagerController *pluginManagerController;

+ (BrowserController*) currentBrowser;
+ (void) replaceNotAdmitted:(NSMutableString*) name;
+ (NSArray*) statesArray;
+ (void) updateActivity;
+ (NSData*) produceJPEGThumbnail:(NSImage*) image;
- (IBAction) createDatabaseFolder:(id) sender;
- (void) openDatabasePath: (NSString*) path;
- (BOOL) shouldTerminate: (id) sender;
- (void) databaseOpenStudy: (NSManagedObject*) item;
- (IBAction) databaseDoublePressed:(id)sender;
- (void) setDBDate;
- (void) setDockIcon;
- (void) showEntireDatabase;
- (IBAction) querySelectedStudy:(id) sender;
- (NSPredicate*) smartAlbumPredicate:(NSManagedObject*) album;
- (NSPredicate*) smartAlbumPredicateString:(NSString*) string;
- (void) emptyDeleteQueueThread;
- (void) emptyDeleteQueue:(id) sender;
- (void) addFileToDeleteQueue:(NSString*) file;
- (NSString*) getNewFileDatabasePath: (NSString*) extension;
- (NSString*) getNewFileDatabasePath: (NSString*) extension dbFolder: (NSString*) dbFolder;
- (NSManagedObjectModel *) managedObjectModel;
- (NSManagedObjectContext *) managedObjectContext;
- (NSManagedObjectContext *) defaultManagerObjectContext;
- (NSArray*) childrenArray: (NSManagedObject*) item;
- (NSArray*) childrenArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject;
- (NSArray*) imagesArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages;
- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages;
- (NSManagedObjectContext *) managedObjectContextLoadIfNecessary:(BOOL) loadIfNecessary;
- (void) setNetworkLogs;
- (BOOL) isNetworkLogsActive;
- (NSTimeInterval) databaseLastModification;
- (IBAction) matrixDoublePressed:(id)sender;
- (void) addURLToDatabaseEnd:(id) sender;
- (void) addURLToDatabase:(id) sender;
- (NSArray*) addURLToDatabaseFiles:(NSArray*) URLs;
-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand;
-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection;
- (IBAction) sendiDisk:(id) sender;
- (void) selectServer: (NSArray*) files;
- (void) loadDICOMFromiPod;
- (long) saveDatabase:(NSString*) path;
- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files;
-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput;
-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput async: (BOOL) async;
- (NSMutableArray*)copyFilesIntoDatabaseIfNeeded: (NSMutableArray*)filesInput async: (BOOL)async COPYDATABASE: (BOOL) COPYDATABASE COPYDATABASEMODE:(int) COPYDATABASEMODE;
-(ViewerController*) loadSeries :(NSManagedObject *)curFile :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
- (ViewerController*) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages;
- (void) export2PACS:(id) sender;
- (void) queryDICOM:(id) sender;
-(void) exportQuicktimeInt:(NSArray*) dicomFiles2Export :(NSString*) path :(BOOL) html;
- (IBAction) delItem:(id) sender;
- (void) delItemMatrix: (NSManagedObject*) obj;
- (IBAction) selectFilesAndFoldersToAdd:(id) sender;
- (void) showDatabase:(id)sender;
-(IBAction) matrixPressed:(id)sender;
-(void) loadDatabase:(NSString*) path;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer tileWindows: (BOOL) tileWindows;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;
- (NSArray*) exportDICOMFileInt:(NSString*) location files:(NSArray*) filesToExport objects:(NSArray*) dicomFiles2Export;
- (void) processOpenViewerDICOMFromArray:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer: (ViewerController*) viewer;

- (void) setupToolbar;

- (NSString*) getDatabaseFolderFor: (NSString*) path;
- (NSString*) getDatabaseIndexFileFor: (NSString*) path;
- (IBAction) copyToDBFolder: (id) sender;
- (void) setCurrentBonjourService:(int) index;
- (IBAction)customize:(id)sender;
- (IBAction)showhide:(id)sender;
- (IBAction) selectAll3DSeries:(id) sender;
- (IBAction) selectAll4DSeries:(id) sender;
- (void) exportDICOMFile:(id) sender;
- (void) viewerDICOM:(id) sender;
- (void)newViewerDICOM:(id) sender;
- (void) viewerDICOMKeyImages:(id) sender;
- (void) viewerDICOMMergeSelection:(id) sender;
- (void) burnDICOM:(id) sender;
- (IBAction) anonymizeDICOM:(id) sender;
- (IBAction)addSmartAlbum: (id)sender;
- (IBAction)search: (id)sender;
- (IBAction)setSearchType: (id)sender;
- (void) setDraggedItems:(NSArray*) pbItems;
- (IBAction)setTimeIntervalType: (id)sender;
- (IBAction) endCustomInterval:(id) sender;
- (IBAction) customIntervalNow:(id) sender;
- (IBAction) openDatabase:(id) sender;
- (IBAction) createDatabase:(id) sender;
- (void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour;
- (void) browserPrepareForClose;
- (IBAction) endReBuildDatabase:(id) sender;
- (IBAction) ReBuildDatabase:(id) sender;
- (IBAction) ReBuildDatabaseSheet: (id)sender;
- (void) previewSliderAction:(id) sender;
- (void) addHelpMenu;
- (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory found:(BOOL) found;
+ (BOOL)isItCD:(NSString*) path;
- (void)storeSCPComplete:(id)sender;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingDicomFile;
- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects;
- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages;

- (void) resetListenerTimer;
- (IBAction) smartAlbumHelpButton:(id) sender;

- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray;
- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder;

//- (short) createAnonymizedFile:(NSString*) srcFile :(NSString*) dstFile;

//- (void)runSendQueue:(id)object;
//- (void)addToQueue:(NSArray *)array;

-(void) previewPerformAnimation:(id) sender;
-(void) matrixDisplayIcons:(id) sender;
//- (void)reloadSendLog:(id)sender;
- (void) pdfPreview:(id)sender;
- (IBAction)importRawData:(id)sender;
- (void) setBurnerWindowControllerToNIL;
- (BOOL) checkBurner;

- (void) refreshColumns;
- (void) outlineViewRefresh;
- (void) matrixInit:(long) noOfImages;
- (IBAction) albumButtons: (id)sender;
- (NSArray*) albumArray;
- (void) refreshSmartAlbums;
- (void) refreshAlbums;
- (void) waitForRunningProcesses;

- (NSArray*) imagesPathArray: (NSManagedObject*) item;

- (void) autoCleanDatabaseFreeSpace:(id) sender;
- (void) autoCleanDatabaseDate:(id) sender;

- (void) refreshDatabase:(id) sender;
- (void) syncReportsIfNecessary: (int) index;
- (void) removeAllMounted;

//bonjour
- (void) getDICOMROIFiles:(NSArray*) files;
- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;
- (void)setServiceName:(NSString*) title;
- (IBAction)toggleBonjourSharing:(id) sender;
- (void) setBonjourSharingEnabled:(BOOL) boo;
- (void) bonjourWillPublish;
- (void) bonjourDidStop;
- (IBAction) bonjourServiceClicked:(id)sender;
- (NSString*) getLocalDCMPath: (NSManagedObject*) obj :(long) no;
- (void) displayBonjourServices;
- (NSString*) askPassword;
- (void) resetToLocalDatabase;
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

- (NSString *)documentsDirectoryFor:(int) mode url:(NSString*) url;
- (NSString *)setFixedDocumentsDirectory;
- (IBAction)showLogWindow: (id)sender;
- (void) resetLogWindowController;

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path;

- (void)setFilterPredicate:(NSPredicate *)predicate description:(NSString*) desc;
- (NSPredicate *)createFilterPredicate;
- (NSString *)createFilterDescription;

- (IBAction) generateReport: (id) sender;
- (IBAction) deleteReport: (id) sender;
- (IBAction)srReports: (id)sender;

- (IBAction) rebuildThumbnails:(id) sender;

- (NSArray *)databaseSelection;

- (void) newFilesGUIUpdateRun:(int) state;
- (void) newFilesGUIUpdateRun: (int) state viewersListToReload: (NSMutableArray*) cReload viewersListToRebuild: (NSMutableArray*) cRebuild;
- (void) newFilesGUIUpdate:(id) sender;

- (IBAction) decompressSelectedFiles:(id) sender;
- (IBAction) compressSelectedFiles:(id) sender;
- (void) decompressArrayOfFiles: (NSArray*) array work:(NSNumber*) work;
- (void) decompressThread: (NSNumber*) typeOfWork;

-(void) compressDICOMJPEG:(NSString*) compressedPath;
-(void) decompressDICOMJPEG:(NSString*) compressedPath;

- (void) refreshMatrix:(id) sender;
- (void)updateReportToolbarIcon:(NSNotification *)note;

- (void) initAnimationSlider;

+ (NSString*) DateTimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) TimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) DateOfBirthFormat:(NSDate*) d;
+ (NSString*) DateTimeFormat:(NSDate*) d;
+ (NSString*) TimeFormat:(NSDate*) t;

- (int) findObject:(NSString*) request table:(NSString*) table execute: (NSString*) execute elements:(NSString**) elements;

- (void) executeSend :(NSArray*) samePatientArray server:(NSDictionary*) server;

- (void)writeMovie:(NSArray*)imagesArray name:(NSString*)fileName;
- (void) buildThumbnail:(NSManagedObject*) series;

/******Notifactions posted by browserController***********
@"NewStudySelectedNotification" with userinfo key @"Selected Study" posted when a newStudy is selected in the browser
@"Close All Viewers" posted when close open windows if option key pressed.	
@"DCMImageTilingHasChanged" when image tiling has changed
OsirixAddToDBNotification posted when files are added to the DB
*/

@end
