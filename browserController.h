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

@class MPR2DController,NSCFDate;
@class BurnerWindowController,ViewerController;
@class BonjourPublisher,BonjourBrowser;
@class AnonymizerWindowController,QueryController;
@class LogWindowController,PreviewView;
@class MyOutlineView,DCMView,DCMPix;
@class StructuredReportController,BrowserMatrix;
@class PluginManagerController,WaitRendering, Wait;

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
	NSManagedObjectModel			*managedObjectModel, *userManagedObjectModel;
    NSManagedObjectContext			*managedObjectContext, *userManagedObjectContext;
	NSPersistentStoreCoordinator	*persistentStoreCoordinator, *userPersistentStoreCoordinator;
	
	NSDateFormatter			*DateTimeFormat, *DateOfBirthFormat, *TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
	
	NSRect					visibleScreenRect[ 40];
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
	
	BurnerWindowController		*burnerWindowController;
	LogWindowController			*logWindowController;
	
	NSNumberFormatter		*numFmt;
    
    DCMPix                  *curPreviewPix;
    
    NSTimer                 *timer, *IncomingTimer, *matrixDisplayIcons, *refreshTimer, *databaseCleanerTimer, *bonjourTimer, *deleteQueueTimer, *autoroutingQueueTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
	long					previousBonjourIndex;
	
    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert;
    
	BOOL					setDCMDone, mountedVolume, needDBRefresh, dontLoadSelectionSource;
	
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
	
	NSRecursiveLock					*checkIncomingLock;
	NSLock							*checkBonjourUpToDateThreadLock;
	NSTimeInterval					lastSaved;
	NSPredicate						*testPredicate;
	
    BOOL							showAllImages, DatabaseIsEdited, isNetworkLogsActive, displayEmptyDatabase;
	NSConditionLock					*queueLock;
	
	IBOutlet NSScrollView			*thumbnailsScrollView;
	
	NSPredicate						*_fetchPredicate, *_filterPredicate;
	NSString						*_filterPredicateDescription;
	
	NSString						*fixedDocumentsDirectory, *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption;
	
	char							cfixedDocumentsDirectory[ 4096], cfixedIncomingDirectory[ 4096];
	
	NSTimeInterval					databaseLastModification;
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
	
	BOOL							avoidRecursive;
	
	IBOutlet PluginManagerController *pluginManagerController;
	NSTimeInterval					lastCheckIncoming;
	
	WaitRendering					*waitOpeningWindow;
	Wait							*waitCompressionWindow;
	BOOL							waitCompressionAbort;
	
	BOOL							checkForMountedFiles;
	
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionSelectedFiles;
	NSMutableArray					*cachedFilesForDatabaseOutlineSelectionCorrespondingObjects;
	NSIndexSet						*cachedFilesForDatabaseOutlineSelectionIndex;
	
	NSArray							*mountedVolumes;
}

@property(readonly) NSDateFormatter *DateTimeFormat, *DateOfBirthFormat, *TimeFormat, *TimeWithSecondsFormat, *DateTimeWithSecondsFormat;
@property(readonly) NSRecursiveLock *checkIncomingLock;
@property(readonly) NSManagedObjectContext *userManagedObjectContext;
@property(readonly) NSManagedObjectModel *userManagedObjectModel;
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

@property(retain) NSString *searchString, *CDpassword, *pathToEncryptedFile, *passwordForExportEncryption, *temporaryNotificationEmail, *customTextNotificationEmail;
@property(retain) NSPredicate *fetchPredicate, *testPredicate;
@property(readonly) NSPredicate *filterPredicate;
@property(readonly) NSString *filterPredicateDescription;

@property BOOL rtstructProgressBar;
@property float rtstructProgressPercent;

@property(readonly) PluginManagerController *pluginManagerController;

+ (int) compressionForModality: (NSString*) mod quality:(int*) quality resolution: (int) resolution;
+ (BrowserController*) currentBrowser;
+ (NSMutableString*) replaceNotAdmitted: (NSMutableString*)name;
+ (NSArray*) statesArray;
+ (void) updateActivity;
+ (BOOL) isHardDiskFull;
+ (NSData*) produceJPEGThumbnail:(NSImage*) image;
+ (int) DefaultFolderSizeForDB;
+ (void) computeDATABASEINDEXforDatabase:(NSString*) path;
+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password;
+ (void) encryptFiles: (NSArray*) srcFiles inZIPFile: (NSString*) destFile password: (NSString*) password;
- (IBAction) createDatabaseFolder:(id) sender;
- (void) openDatabasePath: (NSString*) path;
- (BOOL) shouldTerminate: (id) sender;
- (void) databaseOpenStudy: (NSManagedObject*) item;
- (IBAction) databaseDoublePressed:(id)sender;
- (void) setDBDate;
- (void) emptyDeleteQueueNow: (id) sender;
- (void) setDockIcon;
- (void) showEntireDatabase;
- (void) subSelectFilesAndFoldersToAdd: (NSArray*) filenames;
- (void)matrixNewIcon:(long) index: (NSManagedObject*)curFile;
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
- (NSManagedObjectContext *) localManagedObjectContext;
- (NSManagedObjectContext *) defaultManagerObjectContext;
- (NSString *) localDocumentsDirectory;
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
- (long) saveDatabase: (NSString*)path context: (NSManagedObjectContext*) context;
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
- (void) proceedDeleteObjects: (NSArray*) objectsToDelete;
- (void) delObjects:(NSMutableArray*) objectsToDelete;
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
- (NSArray*) exportDICOMFileInt:(NSString*) location files:(NSMutableArray*) filesToExport objects:(NSMutableArray*) dicomFiles2Export;
- (void) processOpenViewerDICOMFromArray:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer: (ViewerController*) viewer;
- (void) setDatabaseValue:(id) object item:(id) item forKey:(NSString*) key;
- (void) setupToolbar;
- (void) addAlbumsFile: (NSString*) file;
- (BOOL) sendFilesToCurrentBonjourDB: (NSArray*) files;
- (NSString*) getDatabaseFolderFor: (NSString*) path;
- (NSString*) getDatabaseIndexFileFor: (NSString*) path;
- (IBAction) copyToDBFolder: (id) sender;
- (void) setCurrentBonjourService:(int) index;
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
- (void) burnDICOM:(id) sender;
- (IBAction) anonymizeDICOM:(id) sender;
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
- (void) resetListenerTimer;
- (IBAction) smartAlbumHelpButton:(id) sender;
- (IBAction) regenerateAutoComments:(id) sender;
- (DCMPix *)previewPix:(int)i;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray;
- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject;
- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder;
- (void) createDBContextualMenu;
- (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination;
- (int) askForZIPPassword: (NSString*) file destination: (NSString*) destination;
- (IBAction) reparseIn3D:(id) sender;
- (IBAction) reparseIn4D:(id) sender;

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

- (NSArray*) KeyImages: (id) sender;
- (NSArray*) ROIImages: (id) sender;
- (NSArray*) ROIsAndKeyImages: (id) sender;
- (NSArray*) ROIsAndKeyImages: (id) sender sameSeries: (BOOL*) sameSeries;

- (void) refreshColumns;
- (void) outlineViewRefresh;
- (void) matrixInit:(long) noOfImages;
- (IBAction) albumButtons: (id)sender;
- (NSArray*) albumArray;
- (void) refreshSmartAlbums;
- (void) refreshAlbums;
- (void) waitForRunningProcesses;
- (void) checkResponder;

- (NSArray*) imagesPathArray: (NSManagedObject*) item;

- (void) autoCleanDatabaseFreeSpace:(id) sender;
- (void) autoCleanDatabaseDate:(id) sender;

- (void) refreshDatabase:(id) sender;
- (void) syncReportsIfNecessary;
- (void) syncReportsIfNecessary: (int) index;
- (void) removeAllMounted;
- (void) removeMountedImages: (NSString*) sNewDrive;

//bonjour
- (void) getDICOMROIFiles:(NSArray*) files;
- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;
- (void) setServiceName:(NSString*) title;
- (NSString*) serviceName;
- (IBAction)toggleBonjourSharing:(id) sender;
- (void) setBonjourSharingEnabled:(BOOL) boo;
- (void) bonjourWillPublish;
- (void) bonjourDidStop;
- (IBAction) bonjourServiceClicked:(id)sender;
- (NSString*) getLocalDCMPath: (NSManagedObject*) obj :(long) no;
- (void) displayBonjourServices;
- (NSString*) askPassword;
- (void) resetToLocalDatabase;
- (void) switchToDefaultDBIfNeeded;
- (void) createContextualMenu;
- (void) checkIncomingThread:(id) sender;
- (void) checkIncoming:(id) sender;
- (void) checkIncomingNow:(id) sender;
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
//- (IBAction)srReports: (id)sender;

- (IBAction) rebuildThumbnails:(id) sender;

- (NSArray *)databaseSelection;

- (void) importCommentsAndStatusFromDictionary:(NSDictionary*) d;
- (NSDictionary*) dictionaryWithCommentsAndStatus:(NSManagedObject *)s;
- (void) importReport:(NSString*) path UID: (NSString*) uid;

- (void) newFilesGUIUpdateRun:(int) state;
- (void) newFilesGUIUpdateRun: (int) state viewersListToReload: (NSMutableArray*) cReload viewersListToRebuild: (NSMutableArray*) cRebuild;
- (void) newFilesGUIUpdate:(id) sender;

- (IBAction) decompressSelectedFiles:(id) sender;
- (IBAction) compressSelectedFiles:(id) sender;
- (void) decompressArrayOfFiles: (NSArray*) array work:(NSNumber*) work;
- (void) decompressThread: (NSNumber*) typeOfWork;

- (void) compressDICOMJPEG:(NSArray*) array;
- (void) decompressDICOMJPEG: (NSArray*) array;

- (void) refreshMatrix:(id) sender;
- (void)updateReportToolbarIcon:(NSNotification *)note;
- (void) decompressWaitIncrementation: (NSNumber*) n;
- (void) initAnimationSlider;

- (long) saveUserDatabase;

+ (NSString*) DateTimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) TimeWithSecondsFormat:(NSDate*) t;
+ (NSString*) DateOfBirthFormat:(NSDate*) d;
+ (NSString*) DateTimeFormat:(NSDate*) d;
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

@end
