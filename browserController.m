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

#import "DicomDatabase.h"
#import "DicomDatabase+Routing.h"
#import "DicomDatabase+DCMTK.h"
#import "DicomDatabase+Scan.h"
#import "RemoteDicomDatabase.h"
#import "SRAnnotation.h"
#import <DiscRecording/DRDevice.h>
#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "DicomSeries.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DCMPix.h"
#import "SRAnnotation.h"
#import "AppController.h"
#import "dicomData.h"
#import "BrowserController.h"
#import "viewerController.h"
#import "PluginFilter.h"
#import "ReportPluginFilter.h"
#import "dicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "NSSplitViewSave.h"
#import "Papyrus3/Papyrus3.h"
#import "DicomDirParser.h"
#import "MutableArrayCategory.h"
#import "SmartWindowController.h"
#import "QueryFilter.h"
#import "ImageAndTextCell.h"
#import "Wait.h"
#import "WaitRendering.h"
#import "BurnerWindowController.h"
#import "DCMTransferSyntax.h"
#import "DCMAttributeTag.h"
#import "DCMPixelDataAttribute.h"
#import "DCMCalendarDate.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "LogWindowController.h"
#import "stringAdditions.h"
#import "SendController.h"
#import "Reports.h"
#import "LogManager.h"
#import "DCMTKStoreSCU.h"
#import <QTKit/QTKit.h>
#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "WindowLayoutManager.h"
#import "QTExportHTMLSummary.h"
#import "BrowserControllerDCMTKCategory.h"
#import "BrowserMatrix.h"
#import "DicomStudy.h"
#import "DicomAlbum.h"
#import "PluginManager.h"
#import "N2OpenGLViewWithSplitsWindow.h"
#import "XMLController.h"
#import "WebPortalConnection.h"
#import "Notifications.h"
#import "NSAppleScript+HandlerCalls.h"
#import "CSMailMailClient.h"
#import "NSImage+OsiriX.h"
#import "NSString+N2.h"
#import "NSView+N2.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "NSUserDefaultsController+N2.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "BrowserController+Activity.h"
#import "NSError+OsiriX.h"
#import "NSImage+N2.h"
#import "NSFileManager+N2.h"
#import "N2Debug.h"
#import "NSThread+N2.h"
#import "ThreadModalForWindowController.h"
#import "NSUserDefaults+OsiriX.h"
#import "WADODownload.h"
#import "NSManagedObject+N2.h"
#import "DICOMExport.h"

#ifndef OSIRIX_LIGHT
#import "Anonymization.h"
#import "AnonymizationSavePanelController.h"
#import "AnonymizationViewController.h"
#import "NSFileManager+N2.h"
#endif

#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "WebPortalDatabase.h"

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>

static BrowserController *browserWindow = nil;
NSString* O2AlbumDragType = @"Osirix Album drag";
static BOOL loadingIsOver = NO;//, isAutoCleanDatabaseRunning = NO;
static NSMenu *contextual = nil;
static NSMenu *contextualRT = nil;  // Alternate menus for RT objects (which often don't have images)
static int DicomDirScanDepth = 0;
static int DefaultFolderSizeForDB = 0; // TODO: change
static NSTimeInterval lastHardDiskCheck = 0;
static unsigned long long lastFreeSpace = 0;
static NSTimeInterval lastFreeSpaceLogTime = 0;
//static NSArray *cachedAlbumsArray = nil;
//static NSManagedObjectContext *cachedAlbumsManagedObjectContext = nil;

extern int delayedTileWindows;
extern BOOL NEEDTOREBUILD;//, COMPLETEREBUILD;

#pragma deprecated(asciiString)
NSString* asciiString(NSString* str)
{
	return [str ASCIIString];
}

void restartSTORESCP()
{
//	// Only on server mode
//	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
//	{
//		@try
//		{
//			[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/RESTARTOSIRIXSTORESCP" error: nil];
//			[[NSString stringWithString:@"RESTART"] writeToFile: @"/tmp/RESTARTOSIRIXSTORESCP" atomically: YES];
//			
//			NSLog( @"*********** restartSTORESCP ************");
//		}
//		@catch (NSException * e)
//		{
//			NSLog( @"******* exception in restartSTORESCP() : %@", e);
//		}
//	}
}

@implementation NSString (BrowserController)

-(NSMutableString*)filenameString
{
	NSMutableString* str = [NSMutableString stringWithString:[self ASCIIString]];
	
	NSMutableString* outString = [BrowserController replaceNotAdmitted:str];
	
	if( [outString length] == 0)
		outString = [NSMutableString stringWithString: @"AAA"];
	
	return outString;
}

@end

@interface BrowserController ()

- (void)setDBWindowTitle;
-(void)reduceCoreDataFootPrint;

@end

/*@interface NSImage (ProportionalScaling)
- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize; // Moved to NSImage+N2
@end*/

@implementation BrowserController

+(void)initializeBrowserControllerClass {
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixCanActivateDefaultDatabaseOnlyDefaultsKey options:NSKeyValueObservingOptionInitial context:BrowserController.class];
}

+(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (context == BrowserController.class) {
		if ([keyPath isEqualToString:valuesKeyPath(OsirixCanActivateDefaultDatabaseOnlyDefaultsKey)]) {
			if ([NSUserDefaults canActivateAnyLocalDatabase])
				[DicomDatabase setActiveLocalDatabase:[[self currentBrowser] database]];
		}
	}
}

static NSString* 	DatabaseToolbarIdentifier			= @"DicomDatabase Toolbar Identifier";
static NSString*	ImportToolbarItemIdentifier			= @"Import.icns";
static NSString*	iDiskSendToolbarItemIdentifier		= @"iDiskSend.icns";
static NSString*	QTSaveToolbarItemIdentifier			= @"QTExport.icns";
static NSString*	iDiskGetToolbarItemIdentifier		= @"iDiskGet.icns";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	AnonymizerToolbarItemIdentifier		= @"Anonymizer.icns";
static NSString*	QueryToolbarItemIdentifier			= @"QueryRetrieve.icns";
static NSString*	SendToolbarItemIdentifier			= @"Send.icns";
static NSString*	ViewerToolbarItemIdentifier			= @"Viewer.icns";
static NSString*	CDRomToolbarItemIdentifier			= @"cd.icns";
static NSString*	MovieToolbarItemIdentifier			= @"Movie.icns";
static NSString*	TrashToolbarItemIdentifier			= @"trash.icns";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	BurnerToolbarItemIdentifier			= @"Burner.tif";
static NSString*	ToggleDrawerToolbarItemIdentifier   = @"StartupDisk.tif";
static NSString*	SearchToolbarItemIdentifier			= @"Search";
static NSString*	TimeIntervalToolbarItemIdentifier	= @"TimeInterval";
static NSString*	XMLToolbarItemIdentifier			= @"XML.icns";
static NSString*	MailToolbarItemIdentifier			= @"Mail.icns";
static NSString*	OpenKeyImagesAndROIsToolbarItemIdentifier	= @"ROIsAndKeys.tif";
static NSString*	OpenKeyImagesToolbarItemIdentifier	= @"Keys.tif";
static NSString*	OpenROIsToolbarItemIdentifier	= @"ROIs.tif";
static NSString*	ViewersToolbarItemIdentifier	= @"windows.tif";
static NSString*	WebServerSingleNotification	= @"Safari.tif";
static NSString*	AddStudiesToUserItemIdentifier	= @"NSUserAccounts";

static NSTimeInterval gLastActivity = 0;//, gLastCoreDataReset = 0;
//static BOOL DICOMDIRCDMODE = NO;
static BOOL dontShowOpenSubSeries = NO;

static NSArray*	statesArray = nil;

static NSNumberFormatter* decimalNumberFormatter = NULL;
static volatile BOOL waitForRunningProcess = NO;
static volatile BOOL computeNumberOfStudiesForAlbums = NO;

+(void)initialize {
	decimalNumberFormatter = [[NSNumberFormatter alloc] init];
	[decimalNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
//	[decimalNumberFormatter setLocale: [NSLocale currentLocale]];
//	[decimalNumberFormatter setFormat:@"0"];
//	[decimalNumberFormatter setHasThousandSeparators: YES];
}

@class DCMTKStudyQueryNode;

@synthesize database = _database;
@synthesize sources = _sourcesArrayController;

@synthesize /*checkIncomingLock, */CDpassword, passwordForExportEncryption, databaseIndexDictionary;
@synthesize TimeFormat, TimeWithSecondsFormat, temporaryNotificationEmail, customTextNotificationEmail;
@synthesize DateTimeWithSecondsFormat, matrixViewArray, oMatrix, testPredicate;
@synthesize COLUMN, databaseOutline, albumTable;
//@synthesize currentDatabasePath;
//@synthesize ![database isLocal], bonjourDownloading
@synthesize bonjourSourcesBox;
@synthesize bonjourBrowser, pathToEncryptedFile;
@synthesize searchString = _searchString, fetchPredicate = _fetchPredicate;
@synthesize filterPredicate = _filterPredicate, filterPredicateDescription = _filterPredicateDescription;
@synthesize rtstructProgressBar, rtstructProgressPercent, pluginManagerController;//, userManagedObjectContext, userManagedObjectModel;
//@synthesize viewersListToReload, viewersListToRebuild;//, newFilesConditionLock; //, databaseLastModification;
//@synthesize AtableView/*, AcpuActiView, AhddActiView, AnetActiView, AstatusLabel*/;

+ (BOOL) tryLock:(id) c during:(NSTimeInterval) sec
{
	if( c == nil) return YES;
	
	BOOL locked = NO;
	NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate] + sec;
	
	while( ti - [NSDate timeIntervalSinceReferenceDate] > 0)
	{
		if( [c tryLock])
		{
			[c unlock];
			return YES;
		}
		
		[NSThread sleepForTimeInterval: 0.1];
//		[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]];		
	}
	
	NSLog( @"******* tryLockDuring failed for this lock: %@ (%f sec)", c, sec);
	
	return NO;
}

+ (BrowserController*) currentBrowser { return browserWindow; }
+ (NSArray*) statesArray { return statesArray; }
+ (void) updateActivity
{
	gLastActivity = [NSDate timeIntervalSinceReferenceDate];
}

+ (int) DefaultFolderSizeForDB
{
	if( DefaultFolderSizeForDB == 0)
	{
		DefaultFolderSizeForDB = [[NSUserDefaults standardUserDefaults] integerForKey: @"DefaultFolderSizeForDB"];
		if( DefaultFolderSizeForDB == 0)
		{
			DefaultFolderSizeForDB = 10000;
			[[NSUserDefaults standardUserDefaults] setInteger: DefaultFolderSizeForDB forKey: @"DefaultFolderSizeForDB"];
		}
	}
	
	return DefaultFolderSizeForDB;
}

+ (NSArray*) albumsInContext:(NSManagedObjectContext*)context { // __deprecated
	return [DicomDatabase albumsInContext:context];
}

-(NSArray*)albums { // __deprecated
	return [_database albums];
}

static NSConditionLock *threadLock = nil;

- (void) vImageThread: (NSDictionary*) d
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	
	if( [[d objectForKey: @"what"] isEqualToString: @"FTo16U"])
	{
		vImage_Buffer src = *(vImage_Buffer*) [[d objectForKey: @"src"] pointerValue];
		vImage_Buffer dst = *(vImage_Buffer*) [[d objectForKey: @"dst"] pointerValue];
		
		src.height = dst.height = [[d objectForKey: @"to"] intValue] - [[d objectForKey: @"from"] intValue];
		src.data = (char*) src.data + [[d objectForKey: @"from"] intValue] * src.rowBytes;
		dst.data = (char*) dst.data + [[d objectForKey: @"from"] intValue] * dst.rowBytes;
		
		vImageConvert_FTo16U(	&src,
							 &dst,
							 [[d objectForKey: @"offset"] floatValue],
							 [[d objectForKey: @"scale"] floatValue],
							 kvImageDoNotTile);
	}
	else if( [[d objectForKey: @"what"] isEqualToString: @"16UToF"])
	{
		vImage_Buffer src = *(vImage_Buffer*) [[d objectForKey: @"src"] pointerValue];
		vImage_Buffer dst = *(vImage_Buffer*) [[d objectForKey: @"dst"] pointerValue];
		
		src.height = dst.height = [[d objectForKey: @"to"] intValue] - [[d objectForKey: @"from"] intValue];
		src.data = (char*) src.data + [[d objectForKey: @"from"] intValue] * src.rowBytes;
		dst.data = (char*) dst.data + [[d objectForKey: @"from"] intValue] * dst.rowBytes;
		
		vImageConvert_16UToF(&src,
							 &dst,
							 [[d objectForKey: @"offset"] floatValue],
							 [[d objectForKey: @"scale"] floatValue],
							 kvImageDoNotTile);
	}
	else NSLog( @"****** unknown vImageThread what: %@", [d objectForKey: @"what"]);
	
	[threadLock lock];
	[threadLock unlockWithCondition: [threadLock condition]-1];
	
	[p release];
}


+ (void) multiThreadedImageConvert: (NSString*) what :(vImage_Buffer*) src :(vImage_Buffer *) dst :(float) offset :(float) scale
{
	int mpprocessors = MPProcessors();
	
	if( threadLock == nil)
		threadLock = [[NSConditionLock alloc] initWithCondition: 0];
	
	[threadLock lockWhenCondition: 0];
	[threadLock unlockWithCondition: mpprocessors];
	
	NSMutableDictionary *baseDict = [NSMutableDictionary dictionary];
	
	[baseDict setObject: [NSValue valueWithPointer: src] forKey: @"src"];
	[baseDict setObject: [NSValue valueWithPointer: dst] forKey: @"dst"];
	
	[baseDict setObject: [NSNumber numberWithFloat: scale] forKey: @"scale"];
	[baseDict setObject: [NSNumber numberWithFloat: offset] forKey: @"offset"];
	
	[baseDict setObject: what forKey: @"what"];
	
	int no2 = src->height;
	
	for( int i = 0; i < mpprocessors; i++)
	{
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: baseDict];
		
		int from = (i * no2) / mpprocessors;
		int to = ((i+1) * no2) / mpprocessors;
		
		[d setObject: [NSNumber numberWithInt: from] forKey: @"from"];
		[d setObject: [NSNumber numberWithInt: to] forKey: @"to"];
		
		[NSThread detachNewThreadSelector: @selector( vImageThread:) toTarget: browserWindow withObject: d];
	}
	
	[threadLock lockWhenCondition: 0];
	[threadLock unlock];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Add DICOM Database functions

- (NSString*)getNewFileDatabasePath:(NSString*)extension { // __deprecated
	return [_database uniquePathForNewDataFileWithExtension:extension];
}

- (NSString*)getNewFileDatabasePath:(NSString*)extension dbFolder:(NSString*)dbFolder { // __deprecated
	return [[DicomDatabase databaseAtPath:dbFolder] uniquePathForNewDataFileWithExtension:extension];
}

- (void)reloadViewers:(NSMutableArray*)vl
{
	// Reload series if needed
	for( ViewerController *vc in vl)
	{
		if( [[vc window] isVisible] && [[vc imageView] mouseDragging] == NO)
		{
			[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [[[vc fileList] objectAtIndex: 0] valueForKey:@"series"]]] movie: NO viewer : vc keyImagesOnly: NO tryToFlipData: YES];
		}
	}
	
	#ifndef OSIRIX_LIGHT
	if( [QueryController currentQueryController])
		[[QueryController currentQueryController] refresh: self];
	else if( [QueryController currentAutoQueryController])
		[[QueryController currentAutoQueryController] refresh: self];
	#endif
}

- (void) rebuildViewers: (NSMutableArray*) vlToRebuild
{	
	// Refresh preview matrix if needed
	for( ViewerController *vc in vlToRebuild)
	{
		if( [[vc window] isVisible] && [[vc imageView] mouseDragging] == NO)
		{
			[vc buildMatrixPreview: NO];
		}
	}
}

#pragma deprecated (addFilesToDatabase:)
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray { // __deprecated
	return [_database addFilesAtPaths:newFilesArray];
}

#pragma deprecated (addFilesToDatabase::)
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray :(BOOL)onlyDICOM { // __deprecated
	return [_database addFilesAtPaths:newFilesArray postNotifications:YES dicomOnly:onlyDICOM rereadExistingItems:NO];
}

#pragma deprecated (addFilesToDatabase:onlyDICOM:produceAddedFiles:)
-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles { // __deprecated
	return [_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:NO];
}

#pragma deprecated (addFilesToDatabase:onlyDICOM:produceAddedFiles:parseExistingObject:)
-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject { // __deprecated
	return [_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject];
}

#pragma deprecated (checkForExistingReport:dbFolder:)
- (void) checkForExistingReport: (NSManagedObject*) study dbFolder: (NSString*) dbFolder {
	[[DicomDatabase databaseForContext:[study managedObjectContext]] checkForExistingReportForStudy:study];
}

#pragma mark-

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && browserController) db = [browserController database];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) N2LogError(@"couldn't identify database");
	return [db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject];
}

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder generatedByOsiriX:(BOOL)generatedByOsiriX { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && browserController) db = [browserController database];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) N2LogError(@"couldn't identify database");
	return [db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject generatedByOsiriX:generatedByOsiriX];
}

#pragma deprecated
+(NSArray*) addFiles:(NSArray*) newFilesArray toContext: (NSManagedObjectContext*) context toDatabase: (BrowserController*) browserController onlyDICOM: (BOOL) onlyDICOM  notifyAddedFiles: (BOOL) notifyAddedFiles parseExistingObject: (BOOL) parseExistingObject dbFolder: (NSString*) dbFolder generatedByOsiriX: (BOOL) generatedByOsiriX mountedVolume: (BOOL) mountedVolume { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && browserController) db = [browserController database];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) N2LogError(@"couldn't identify database");
	return [db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject generatedByOsiriX:generatedByOsiriX mountedVolume:mountedVolume];
}

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) N2LogError(@"couldn't identify database");
	return [db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject];
}

#pragma deprecated
-(NSArray*)subAddFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM produceAddedFiles:(BOOL)produceAddedFiles parseExistingObject:(BOOL)parseExistingObject context:(NSManagedObjectContext*)context dbFolder:(NSString*)dbFolder { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) db = _database;
	return [db addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject];
}

#pragma deprecated
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM safeRebuild:(BOOL)safeRebuild produceAddedFiles:(BOOL)produceAddedFiles { // __deprecated // notice: the "safeRebuild" seemed to be already ignored before the DicomDatabase transition
    return [_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:NO];
}

#pragma deprecated
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM produceAddedFiles:(BOOL)produceAddedFiles parseExistingObject:(BOOL)parseExistingObject context:(NSManagedObjectContext*)context dbFolder:(NSString*)dbFolder { // __deprecated
	DicomDatabase* db = [DicomDatabase databaseForContext:context];
	if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
	if (!db) db = _database;
    return [_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject];
}

#pragma mark-

- (void)newFilesGUIUpdateRun:(int)state viewersListToReload:(NSMutableArray*)cReload viewersListToRebuild:(NSMutableArray*)cRebuild { // __deprecated
}

- (void) newFilesGUIUpdateRun:(int) state { // __deprecated
}

- (void) newFilesGUIUpdate:(id) sender { // __deprecated
}

- (void) asyncWADODownload:(NSString*) filename
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *urlToDownloads = [NSMutableArray array];
	
	@try
	{
		for( NSString *url in [[NSString stringWithContentsOfFile: filename] componentsSeparatedByString: @"\r"])
		{
			if( url.length)
				[urlToDownloads addObject: [NSURL URLWithString: url]];
		}
	}
	@catch ( NSException *e) {
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	WADODownload *downloader = [[WADODownload alloc] init];
	
	[downloader WADODownload: urlToDownloads];
	
	[downloader release];
	
	[[NSFileManager defaultManager] removeItemAtPath: filename error: nil];
	
	[pool release];
}

- (void) addFilesAndFolderToDatabase:(NSArray*) filenames
{
    NSFileManager       *defaultManager = [NSFileManager defaultManager];
	NSMutableArray		*filesArray;
	BOOL				isDirectory = NO;
	
	filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	for( NSString *filename in filenames)
	{
		@try
		{
			if( [[filename lastPathComponent] characterAtIndex: 0] != '.')
			{
				if([defaultManager fileExistsAtPath: filename isDirectory:&isDirectory])     // A directory
				{
					if( isDirectory == YES && [[filename pathExtension] isEqualToString: @"pages"] == NO && [[filename pathExtension] isEqualToString: @"app"] == NO)
					{
						NSString    *pathname;
						NSString	*folderSkip = nil;
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath: filename];
						
						while (pathname = [enumer nextObject])
						{
							@try
							{
								NSString * itemPath = [filename stringByAppendingPathComponent: pathname];
								id fileType = [[enumer fileAttributes] objectForKey:NSFileType];
								
								if ([fileType isEqual:NSFileTypeRegular])
								{
									BOOL skip = NO;
									
									if( folderSkip && [pathname length] >= [folderSkip length])
										if( [[pathname substringToIndex: [folderSkip length]] isEqualToString: folderSkip])
											skip = YES;
									
									if( skip == NO)
									{
										folderSkip = nil;
										
										if( [[itemPath lastPathComponent] characterAtIndex: 0] != '.')
										{
											if( [[itemPath pathExtension] isEqualToString: @"dcmURLs"])
											{
												NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( asyncWADODownload:) object: filename] autorelease];
												t.name = NSLocalizedString( @"WADO Retrieve...", nil);
												t.supportsCancel = YES;
												t.status = [itemPath lastPathComponent];
												[[ThreadsManager defaultManager] addThreadAndStart: t];
											}
											else if( [[itemPath pathExtension] isEqualToString: @"zip"] || [[itemPath pathExtension] isEqualToString: @"osirixzip"])
											{
												NSString *unzipPath = [@"/tmp" stringByAppendingPathComponent: @"unzip_folder"];
												
												[[NSFileManager defaultManager] removeItemAtPath: unzipPath error: nil];
												[[NSFileManager defaultManager] createDirectoryAtPath: unzipPath attributes: nil];
												
												[self askForZIPPassword: itemPath destination: unzipPath];
												
												static int uniqueZipFolder = 1;
												NSString *uniqueFolder = [NSString stringWithFormat: @"unzip_folder_A%d", uniqueZipFolder++];
												[[NSFileManager defaultManager] moveItemAtPath: unzipPath toPath: [[self INCOMINGPATH] stringByAppendingPathComponent: uniqueFolder] error: nil];
											}
											else if( [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES || [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR."] == YES)
												[self addDICOMDIR: itemPath : filesArray];
											
											else [filesArray addObject:itemPath];
										}
									}
								}
								else if( [[pathname pathExtension] isEqualToString:@"app"])
								{
									folderSkip = pathname;
								}
							}
							@catch( NSException *e)
							{
								NSLog( @"******** addFilesAndFolderToDatabase 2 exception : %@", e);
								[AppController printStackTrace: e];
							}
						}
					}
					else    // A file
					{
						if( [[filename pathExtension] isEqualToString: @"dcmURLs"])
						{
							NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( asyncWADODownload:) object: filename] autorelease];
							t.name = NSLocalizedString( @"WADO Retrieve...", nil);
							t.supportsCancel = YES;
							t.status = [filename lastPathComponent];
							[[ThreadsManager defaultManager] addThreadAndStart: t];
						}
						else if( [[filename pathExtension] isEqualToString: @"zip"] || [[filename pathExtension] isEqualToString: @"osirixzip"])
						{
							NSString *unzipPath = [@"/tmp" stringByAppendingPathComponent: @"unzip_folder"];
							
							[[NSFileManager defaultManager] removeItemAtPath: unzipPath error: nil];
							[[NSFileManager defaultManager] createDirectoryAtPath: unzipPath attributes: nil];
							
							[self askForZIPPassword: filename destination: unzipPath];
							
							static int uniqueZipFolder = 1;
							NSString *uniqueFolder = [NSString stringWithFormat: @"unzip_folder_B%d", uniqueZipFolder++];
							[[NSFileManager defaultManager] moveItemAtPath: unzipPath toPath: [[self INCOMINGPATH] stringByAppendingPathComponent: uniqueFolder] error: nil];
						}
						else if( [[[filename lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES || [[[filename lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR."] == YES)
							[self addDICOMDIR: filename :filesArray];
						else if( [[filename pathExtension] isEqualToString: @"app"])
						{
						}
						else [filesArray addObject: filename];
					}
				}
			}
		}
		@catch (NSException* e)
		{
			N2LogExceptionWithStackTrace(e);
		}
	}
	
	[self copyFilesIntoDatabaseIfNeeded: filesArray options: [NSDictionary dictionaryWithObjectsAndKeys: [[NSUserDefaults standardUserDefaults] objectForKey: @"onlyDICOM"], @"onlyDICOM", [NSNumber numberWithBool: YES], @"async", [NSNumber numberWithBool: YES], @"addToAlbum",  [NSNumber numberWithBool: YES], @"selectStudy", nil]];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Autorouting functions

- (void) testAutorouting
{
	// Test the routing filters
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		NSArray	*autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
		
		for ( NSDictionary *routingRule in autoroutingRules)
		{			
			@try
			{
				if( [[routingRule objectForKey:@"filterType"] intValue] == 0)
					[self smartAlbumPredicateString: [routingRule objectForKey: @"filter"]];
			}
			
			@catch( NSException *ne)
			{
				NSRunAlertPanel( NSLocalizedString(@"Routing Filter Error", nil),  [NSString stringWithFormat: NSLocalizedString(@"Syntax error in this routing filter: %@\r\r%@\r\rSee Routing Preferences.", nil), [routingRule objectForKey:@"name"], [routingRule objectForKey:@"filter"]], nil, nil, nil);
				[AppController printStackTrace: ne];
			}
		}
	}
	#endif
}

- (void) applyRoutingRule: (id) sender // For manually applying a routing rule, from the DB contextual menu 
{
	BOOL matrixThumbnails = NO;

	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		matrixThumbnails = YES;
		NSLog( @"applyRoutingRule from matrix");
	}
	
	NSMutableArray *objects = [NSMutableArray array];
	NSMutableArray *files;
	
	if( matrixThumbnails)
		files = [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
	else
		files = [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
	
	if( [sender representedObject]) // Only selected rule
	{
		[self executeAutorouting: objects rules: [NSArray arrayWithObject: [sender representedObject]] manually: YES];
	}
	else // All rules
	{
		[self executeAutorouting: objects rules: nil manually: YES];
	}
}

- (void)addFiles:(NSArray*)images withRule:(NSDictionary*)routingRule { // __deprecated
	[_database addImages:images toSendQueueForRoutingRule:routingRule];
}

-(void)executeAutorouting:(NSArray*)newImages rules:(NSArray*)autoroutingRules manually:(BOOL)manually { // __deprecated
	[self executeAutorouting: newImages rules: autoroutingRules manually: manually generatedByOsiriX: NO];
}

-(void)executeAutorouting:(NSArray*)newImages rules:(NSArray*)autoroutingRules manually:(BOOL)manually generatedByOsiriX:(BOOL)generatedByOsiriX { // __deprecated // notice: the generatedByOsiriX is supposed to be specified in all DicomImage instances, so I decided to ignore it when trasitioning to DicomDatabase
	if (manually || [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
		[_database applyRoutingRules:autoroutingRules toImages:newImages];
}


#pragma mark-
#pragma mark Database functions

- (IBAction) regenerateAutoComments:(id) sender;
{
	if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Regenerate Auto Comments", nil),
											 NSLocalizedString(@"Are you sure you want to regenerate the comments field? It will delete the existing comments of all studies and series.", nil),
											 NSLocalizedString(@"OK",nil),
											 NSLocalizedString(@"Cancel",nil),
											 nil) == NSAlertDefaultReturn)
	{
		Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Regenerate Auto Comments...", nil)];
			
		[splash showWindow:self];
		
		[splash setCancel: YES];
		
		NSManagedObjectContext *context = self.managedObjectContext;
		
		[context lock];
		
		// Find all studies
		NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		
		NSError *error = nil;
		NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
		
		for( DicomStudy *s in studiesArray)
			[s setPrimitiveValue: 0L forKey: @"comment"];
		
		// Find all series
		dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		error = nil;
		
		NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
		
		[[splash progress] setMaxValue: [seriesArray count]];
		
		for( NSManagedObject *series in seriesArray)
		{
			@try
			{
				NSManagedObject *o = [[series valueForKey:@"images"] anyObject];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"])
				{			
					DicomFile	*dcm = [[DicomFile alloc] init: [o valueForKey:@"completePath"]];
					
					if( dcm)
					{
						if( [dcm elementForKey:@"commentsAutoFill"])
						{
							[series setPrimitiveValue: [dcm elementForKey: @"commentsAutoFill"] forKey:@"comment"];
							
							NSManagedObject *study = [series valueForKey: @"study"];
							
							if( [study valueForKey:@"comment"] == nil || [[study valueForKey:@"comment"] isEqualToString:@""])
								[study setPrimitiveValue: [dcm elementForKey: @"commentsAutoFill"] forKey:@"comment"];
						}
						else [series setPrimitiveValue: 0L forKey:@"comment"];
					}
					
					[dcm release];
				}
				else [series setPrimitiveValue: 0L forKey:@"comment"];
			}
			@catch ( NSException *e)
			{
				NSLog( @"********* regenerateAutoComments exception : %@", e);
				[AppController printStackTrace: e];
			}
			
			[splash incrementBy:1];
		}
		[context unlock];
		
		[self outlineViewRefresh];
		
		[splash close];
		[splash release];
	}
}

- (NSTimeInterval) databaseLastModification { // __deprecated
	return _database.timeOfLastModification;
}

-(void)setDatabaseLastModification:(NSTimeInterval)t {
	_database.timeOfLastModification = t;
}

- (NSManagedObjectModel*)managedObjectModel { // __deprecated
    return self.database.managedObjectModel;
}

- (void)defaultAlbums:(id)sender {
	[self.database addDefaultAlbums];
	[self refreshAlbums];
}

// ------------------

- (NSManagedObjectContext*)localManagedObjectContextIndependentContext:(BOOL)independentContext { // __deprecated
	return [[DicomDatabase activeLocalDatabase] independentContext:independentContext];
}

- (NSManagedObjectContext*)localManagedObjectContext { // __deprecated
	return [self localManagedObjectContextIndependentContext:NO];
}

// ------------------

- (NSManagedObjectContext*)defaultManagerObjectContext { // __deprecated
	return [self defaultManagerObjectContextIndependentContext:NO];
}

- (NSManagedObjectContext*)defaultManagerObjectContextIndependentContext:(BOOL)independentContext { // __deprecated
	return [[DicomDatabase defaultDatabase] independentContext:independentContext];
}

// ------------------

- (NSManagedObjectContext*)managedObjectContext { // __deprecated
	return [self managedObjectContextIndependentContext:NO];
}

- (NSManagedObjectContext*)managedObjectContextIndependentContext:(BOOL)independentContext { // __deprecated
	return [self managedObjectContextIndependentContext:independentContext path:_database.baseDirPath]; 
}

- (NSManagedObjectContext*)managedObjectContextIndependentContext:(BOOL)independentContext path:(NSString*)path { // __deprecated
	if (!path)
		return nil;
	
    if ([path isEqualToString:_database.baseDirPath])
		return [_database independentContext:independentContext];

	return [[DicomDatabase databaseAtPath:path] independentContext:independentContext];
}

// ------------------

- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files
{
	DicomDirParser *parsed = [[DicomDirParser alloc] init: dicomdir];
	
	[parsed parseArray: files];
	
	[parsed release];
}

-(NSArray*) addURLToDatabaseFiles:(NSArray*) URLs
{
	NSMutableArray	*localFiles = [NSMutableArray array];
	
	// FIRST DOWNLOAD FILES TO LOCAL DATABASE
	
	for( NSURL *url in URLs)
	{
		NSData *data = [NSData dataWithContentsOfURL: url];
		
		if( data)
		{
			NSString *dstPath = [self getNewFileDatabasePath:@"dcm"];		
			[data writeToFile:dstPath  atomically:YES];
			[localFiles addObject:dstPath];
		}
	}
	
	// THEN, LOAD THEM
	[self addFilesAndFolderToDatabase: localFiles];
	
	return localFiles;
}

- (void)addURLToDatabaseEnd: (id)sender
{
	if( [sender tag] == 1)
	{
		[[NSUserDefaults standardUserDefaults] setObject: [urlString stringValue] forKey: @"LASTURL"];
		NSArray *result = [self addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString: [urlString stringValue]]]];
		
		if( [result count] == 0)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"URL Error",nil), NSLocalizedString(@"I'm not able to download this file.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
		else
		{
			[urlWindow orderOut:sender];
			[NSApp endSheet: urlWindow returnCode:[sender tag]];
		}
	}
	else
	{
		[urlWindow orderOut:sender];
		[NSApp endSheet: urlWindow returnCode:[sender tag]];
	}
}

- (void)addURLToDatabase: (id)sender
{
	[urlString setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey: @"LASTURL"]];
	[NSApp beginSheet: urlWindow modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void) subSelectFilesAndFoldersToAdd: (NSArray*) filenames
{
	if( [filenames count] == 1 && [[[filenames objectAtIndex: 0] pathExtension] isEqualToString: @"sql"])  // It's a database file!
	{
		[self openDatabaseIn: [filenames objectAtIndex: 0] Bonjour:NO];
	}
	else
	{
		NSMutableArray *filenamesWithoutPlugins = [NSMutableArray arrayWithArray: filenames];
		NSMutableArray *pluginsArray = [NSMutableArray array];
		
		for( int i = 0; i < [filenames count]; i++)
		{
			NSString *aPath = [filenames objectAtIndex:i];
			if([[aPath pathExtension] isEqualToString:@"osirixplugin"])
				[pluginsArray addObject:aPath];
		}
		
		[filenamesWithoutPlugins removeObjectsInArray: pluginsArray];
		
		[self addFilesAndFolderToDatabase: filenamesWithoutPlugins];
		
		if( [pluginsArray count] > 0)
		{
			[[AppController sharedAppController] installPlugins: pluginsArray];
		}
	}
}

- (IBAction)selectFilesAndFoldersToAdd: (id)sender
{
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
    
	[self.window makeKeyAndOrderFront:sender];
	
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    
    int result = [oPanel runModalForDirectory:nil file:nil types:nil];
    
    if (result == NSOKButton)
	{
		[self subSelectFilesAndFoldersToAdd: [oPanel filenames]];
	}
}

-(void)_observeDatabaseAddNotification:(NSNotification*)notification {
	if (![NSThread isMainThread])
		[self performSelectorOnMainThread:@selector(_observeDatabaseAddNotification:) withObject:notification waitUntilDone:NO];
	else {
		[self outlineViewRefresh];
		[self refreshAlbums];
	}
}

-(void)_observeDatabaseObjectsMayFaultNotification:(NSNotification*)notification {
	NSLog(@"ToDo: [BrowserController _observeDatabaseObjectsMayFaultNotification:]");
}

-(void)resetToLocalDatabase {
	[self setDatabase:[DicomDatabase activeLocalDatabase]];
}

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)key {
	if ([key isEqual:@"database"])
		return NO;
	return [super automaticallyNotifiesObserversForKey:key];
}

-(void)setDatabase:(DicomDatabase*)db {
	[[db retain] autorelease]; // avoid multithreaded release
	
	if (_database != db) {
		@try {
			[self willChangeValueForKey:@"database"];
			
			[self waitForRunningProcesses];
			[reportFilesToCheck removeAllObjects];

			if (_database)
				[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_database];
			
	//		if (refresh) { // TODO: here
	//			NSArray *albumArray = self.albumArray;
	//			if( [albumArray count] > albumTable.selectedRow && albumTable.selectedRow >= 0)
	//				albumName = [[[[albumArray objectAtIndex: albumTable.selectedRow] valueForKey:@"name"] copy] autorelease];
	//			
	//			if( [databaseOutline selectedRow] >= 0)
	//			{
	//				if( [[[databaseOutline itemAtRow:[databaseOutline selectedRow]] valueForKey: @"type"] isEqualToString: @"Study"])
	//					selectedItem = [[databaseOutline itemAtRow:[databaseOutline selectedRow]] valueForKey: @"studyInstanceUID"];
	//				
	//				if( [[[databaseOutline itemAtRow:[databaseOutline selectedRow]] valueForKey: @"type"] isEqualToString: @"Series"])
	//					selectedItem = [[[databaseOutline itemAtRow:[databaseOutline selectedRow]] valueForKey: @"study"] valueForKey: @"studyInstanceUID"];
	//				
	//				selectedItem = [[selectedItem copy] autorelease];
	//			}
	//			timeInt = timeIntervalType;
	//		}
			
			[_database save:nil];
	//		[self willChangeValueForKey:@"database"];
			[_database release]; _database = nil;
	//		[self didChangeValueForKey:@"database"];
			
			[DCMPix purgeCachedDictionaries];
			[DCMView purgeStringTextureCache];
			
			[outlineViewArray release];
			outlineViewArray = nil;
			
			[cachedFilesForDatabaseOutlineSelectionSelectedFiles release]; cachedFilesForDatabaseOutlineSelectionSelectedFiles = nil;
			[cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release]; cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = nil;
			[cachedFilesForDatabaseOutlineSelectionIndex release]; cachedFilesForDatabaseOutlineSelectionIndex = nil;
			
			[[LogManager currentLogManager] checkLogs: nil];
			[self resetLogWindowController];
			
			[[AppController sharedAppController] closeAllViewers: self];
			
			[self outlineViewRefresh];
			[self refreshMatrix:self];
			
//			[self willChangeValueForKey:@"database"];
			_database = [db retain];
//			[self didChangeValueForKey:@"database"];
			if ([NSUserDefaults canActivateAnyLocalDatabase] && [db isLocal] && ![db isReadOnly])
				[DicomDatabase setActiveLocalDatabase:db];
			if (db) [self selectCurrentDatabaseSource];

			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeDatabaseAddNotification:) name:_O2AddToDBAnywayNotification object:_database];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeDatabaseObjectsMayFaultNotification:) name:OsirixDatabaseObjectsMayFaultNotification object:_database];

		
			[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
			
			NSString	*DBVersion;//, *DBFolderLocation, *curPath = [self.documentsDirectory stringByDeletingLastPathComponent];
			
//			DBVersion = [NSString stringWithContentsOfFile:[database modelVersionFilePath]];
			//DBFolderLocation = [NSString stringWithContentsOfFile:[database.basePath stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
//			
//			if (![database isLocal])
//			{
//				[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
//				[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
//				
//				DBFolderLocation = [self.documentsDirectory stringByDeletingLastPathComponent];
//			}
//			
//			if( DBFolderLocation == nil)
//				DBFolderLocation = curPath;
//			
//			BOOL isDirectory;
//			if( [[NSFileManager defaultManager] fileExistsAtPath: DBFolderLocation isDirectory: &isDirectory])
//			{
//				if( isDirectory == NO)
//					DBFolderLocation = curPath;
//			}
//			else DBFolderLocation = curPath;
//			
//			if( [DBFolderLocation isEqualToString: curPath] == NO)
//			{
//				NSLog( @"Update DATABASELOCATIONURL to :%@ from %@", DBFolderLocation, curPath);
//				[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"DATABASELOCATION"];
//				[[NSUserDefaults standardUserDefaults] setObject: DBFolderLocation forKey: @"DATABASELOCATIONURL"];
//			}
			
//			if ([database isLocal])
//			{
//				if( [self.documentsDirectory isEqualToString: [path stringByDeletingLastPathComponent]] == NO)
//					[[self.documentsDirectory stringByDeletingLastPathComponent] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] atomically:YES encoding : NSUTF8StringEncoding error: nil];
//				else
//					[[NSFileManager defaultManager] removeFileAtPath: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] handler: nil];
				
				// is this DB on the sources list?
//				long i = [self findDBPath:[database sqlFilePath] dbFolder:[database dataDirPath]];
//				if( i == -1)
//				{
//					NSLog( @"DB Not found -> we add it");
//					
//					NSArray	*dbArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
//					
//					if( dbArray == nil) dbArray = [NSArray array];
//					
//					if( [[database.sqlFilePath lastPathComponent] isEqualToString: @"Database.sql"])	// We will add the folder, since it is the default sql file for a DB folder
//					{
//						NSString	*name = [[NSFileManager defaultManager] displayNameAtPath: database.baseDirPath];
//						
//						dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: database.basePath, @"Path", [name stringByAppendingString:@" DB"], @"Description", nil]];			
//					}
//					else
//					{
//						dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: database.basePath, @"Path", [[[database.basePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" DB"], @"Description", nil]];
//					}
//					
//					if( DICOMDIRCDMODE == NO)
//						[[NSUserDefaults standardUserDefaults] setObject: dbArray forKey: @"localDatabasePaths"];
//					
//					[[NSNotificationCenter defaultCenter] postNotificationName:OsirixServerArrayChangedNotification object:nil];
//					
//					// Select it
//					i = [self findDBPath:[database sqlFilePath] dbFolder:[database dataDirPath]];
//				}
				
			//	if// (i != [_sourcesTableView selectedRow])
//				{
//					if( i == -1 && DICOMDIRCDMODE != YES) NSLog( @"**** NOT FOUND??? WHY? we added it... no?");
//					dontLoadSelectionSource = YES;
//					[_sourcesTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
//					dontLoadSelectionSource = NO;
//				}
//			}
			
			//if (DICOMDIRCDMODE)
//				DBVersion = nil;
//			else if (DBVersion == nil) 
//				DBVersion = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
			
//			NSLog(@"Opening DB: %@ Version: %@ DB Folder: %@", path, DBVersion, DBFolderLocation);
			
//			if( DBVersion && [DBVersion isEqualToString: DATABASEVERSION] == NO)
//			{
//				[self updateDatabaseModel: path :DBVersion];
//				
//				[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"recomputePatientUID"];
//			}
			
//			if( managedObjectContext)
//			{
//				[self resetLogWindowController];
//				[[LogManager currentLogManager] resetLogs];
//			}
			
//			[database lock];
//			[database unlock];
//			[managedObjectContext reset];
//			[managedObjectContext release];
//			managedObjectContext = nil;
			
//			while( computeNumberOfStudiesForAlbums)
//				[NSThread sleepForTimeInterval: 0.1];
			
			@synchronized(albumNoOfStudiesCache) {
				[albumNoOfStudiesCache removeAllObjects];
			}
			
			//[self setFixedDocumentsDirectory];
			[[_database managedObjectContext] lock];
			@try {
				
//				if( NEEDTOREBUILD)
//					[self ReBuildDatabase:self];
//				else
//					[self outlineViewRefresh];
				
			//	NSString *pathTemp = [[self documentsDirectory] stringByAppendingString:@"/Loading"];
//				
//				if ([[NSFileManager defaultManager] fileExistsAtPath:pathTemp])
//					[[NSFileManager defaultManager] removeFileAtPath:pathTemp handler: nil];
				
//				[AppController createNoIndexDirectoryIfNecessary: [[self documentsDirectory] stringByAppendingPathComponent: DATAbaseDirPath]];
//				[AppController createNoIndexDirectoryIfNecessary: [self INCOMINGPATH]];
//				[AppController createNoIndexDirectoryIfNecessary: [[self documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/"]];
//				[AppController createNoIndexDirectoryIfNecessary: [[self localDocumentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/"]];
				
				[self setDBWindowTitle];
				
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixServerArrayChangedNotification object:nil];
				
				[databaseOutline reloadData];
				[albumTable reloadData];
				
				[self setNetworkLogs];
				
				
				[self outlineViewRefresh];
				[self refreshMatrix: self];
				[self refreshAlbums];
				
	#ifndef OSIRIX_LIGHT
				if( [QueryController currentQueryController])
					[[QueryController currentQueryController] refresh: self];
				else if( [QueryController currentAutoQueryController])
					[[QueryController currentAutoQueryController] refresh: self];
	#endif
				

			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			} @finally {
				[[_database managedObjectContext] unlock];
			}
			
			[[LogManager currentLogManager] resetLogs];
				
			//	NSData *str = [DicomImage sopInstanceUIDEncodeString: @"1.2.826.0.1.3680043.2.1143.8797283371159.20060125163148762.58"];
			//	
			//	NSManagedObjectContext	*context = self. managedObjectContext;
			//	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			//	[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Image"]];
			//		
			//	[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
			//	
			//	[context lock];
			//	
			//	NSError *error = nil;
			//	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
			//	if( [studiesArray count])
			//	{
			//		NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: str] customSelector: @selector( isEqualToSopInstanceUID:)];
			//		
			//		studiesArray = [studiesArray filteredArrayUsingPredicate: predicate];
			//		
			//		NSData *d = [[studiesArray lastObject] valueForKey: @"compressedSopInstanceUID"];
			//		
			//		NSLog( @"%@", sopInstanceUIDDecode( [d bytes], [d length]));
			//	}
			//
			//	[context unlock];
			
//			if (refresh) {  // TODO: here
//				if( albumName)
//				{
//					for( NSManagedObject *a in self.albumArray)
//					{
//						if( [[a valueForKey: @"name"] isEqualToString: albumName])
//							[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [self.albumArray indexOfObject: a]] byExtendingSelection: NO];
//					}
//				}
//				
//				timeIntervalType = timeInt;
//				[timeIntervalPopup selectItemWithTag: 0];
//				
//				[self setSearchString: nil];
//				
//				for( NSManagedObject *obj in outlineViewArray)
//				{
//					if( [[obj valueForKey: @"studyInstanceUID"] isEqualToString: selectedItem])
//						[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: obj]] byExtendingSelection: NO];
//				}
//				
//				[self refreshMatrix: self];
//				
//				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
//			}*/
		} @catch (...) {
			@throw;
		} @finally {
			[self didChangeValueForKey:@"database"];
		}
	}
}

-(void)openDatabaseIn:(NSString*)a Bonjour:(BOOL)isBonjour { // __deprecated
	[self openDatabaseIn:a Bonjour:isBonjour refresh:NO];
}

-(void)openDatabaseIn:(NSString*)a Bonjour:(BOOL)isBonjour refresh:(BOOL)refresh { // __deprecated
	if (isBonjour) [NSException raise:NSGenericException format:@"TODO do something smart :P"]; // TODO: hmmm
	DicomDatabase* db = isBonjour? nil : [DicomDatabase databaseAtPath:a];
	[self setDatabase:db];
}

#pragma deprecated (openDatabaseInBonjour:)
-(void)openDatabaseInBonjour:(NSString*)path { // deprecated 
	[self openDatabaseIn:path Bonjour:YES refresh:YES];
}

-(IBAction)openDatabase:(id)sender {
	NSOpenPanel* oPanel	= [NSOpenPanel openPanel];
	if ([oPanel runModalForDirectory:_database.sqlFilePath file:nil types:[NSArray arrayWithObject:@"sql"]] == NSFileHandlingPanelOKButton) {
		if ([oPanel filename] && ![_database.sqlFilePath isEqualToString:[oPanel filename]]) {
			[self openDatabaseIn: [oPanel filename] Bonjour:NO];
		}
	}
}

- (IBAction)createDatabase: (id)sender { // deprecated
	N2LogDeprecatedCall();
//	if( ![database isLocal])
//	{
//		NSRunInformationalAlertPanel( NSLocalizedString(@"Database", nil), NSLocalizedString(@"Cannot create a SQL Index file for a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}
//	
//	NSSavePanel		*sPanel		= [NSSavePanel savePanel];
//	
//	[sPanel setRequiredFileType:@"sql"];
//	
//	if ([sPanel runModalForDirectory:[self documentsDirectory] file:NSLocalizedString(@"Database.sql", nil)] == NSFileHandlingPanelOKButton)
//	{
//		if( [currentDatabasePath isEqualToString: [sPanel filename]] == NO && [sPanel filename] != nil)
//		{
//			[self waitForRunningProcesses];
//			
//			[database save:NULL];
//			
//			[currentDatabasePath release];
//			currentDatabasePath = [[sPanel filename] retain];
//			
//			[self loadDatabase: currentDatabaseDirPath];
//			[database save:NULL];
//		}
//	}*/
}

-(IBAction) createDatabaseFolder:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];
	
	[oPanel setCanChooseDirectories: YES];
	[oPanel setCanChooseFiles: NO];
	
	if( [sender tag] == 1)
	{
		[oPanel setPrompt: NSLocalizedString(@"Create", nil)];
		[oPanel setTitle: NSLocalizedString(@"Create a Database Folder", nil)];
	}
	else
	{
		[oPanel setPrompt: NSLocalizedString(@"Open", nil)];
		[oPanel setTitle: NSLocalizedString(@"Open a Database Folder", nil)];
	}
	
	if ([oPanel runModalForDirectory:[self documentsDirectory] file:nil types:nil] == NSFileHandlingPanelOKButton)
	{
		NSString	*location = [oPanel filename];
		
		if( [[location lastPathComponent] isEqualToString:@"OsiriX Data"])
			location = [location stringByDeletingLastPathComponent];
		
		if( [[location lastPathComponent] isEqualToString:@"DATABASE.noindex"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"OsiriX Data"])
			location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
		
		[self openDatabasePath: location];
	}
}

- (void)showEntireDatabase
{
	timeIntervalType = 0;
	[timeIntervalPopup selectItemWithTag: 0];
	
	[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
	self.searchString = @"";
}

- (void)setDBWindowTitle {
	[self.window setTitle: _database? [_database name] : @""];
//	if (![database isLocal]) [self.window setTitle: [NSString stringWithFormat: NSLocalizedString(@"Bonjour Database (%@)", nil), [currentDatabasePath lastPathComponent]]];
//	else [self.window setTitle: [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), currentDatabaseDirPath]];
	[self.window setRepresentedFilename: _database? _database.baseDirPath : @""];
}

- (NSString*)getDatabaseFolderFor: (NSString*)path { // __deprecated
	BOOL isDirectory;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory == NO)
		{
			// It is a SQL file
			
			if( [[path pathExtension] isEqualToString:@"sql"] == NO) NSLog( @"**** No SQL extension ???");
			
			NSString	*db = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
			
			if( db == nil)
			{
				NSString	*p = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DATABASE.noindex"];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: p])
				{
					db = [[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]; 
				}
				else
				{
					db = [self.documentsDirectory stringByDeletingLastPathComponent];
				}
			}
			
			return db;
		}
		else
		{
			return path;
		}
	}
	
	return nil;
}

- (NSString*)getDatabaseIndexFileFor: (NSString*)path {  // __deprecated
	BOOL isDirectory;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory)
		{
			// Default SQL file
			NSString	*index = [[path stringByAppendingPathComponent:@"OsiriX Data"] stringByAppendingPathComponent:@"Database.sql"];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: index])
			{
				return index;
			}
			
			return nil;
		}
		else
		{
			return path;
		}
	}
	
	return nil;
}

-(BOOL)isBonjour:(NSManagedObjectContext*)c { // __deprecated
	return ![[DicomDatabase databaseForContext:c] isLocal];
}

-(void)loadDatabase:(NSString*)path { // __deprecated
	[self setDatabase:[DicomDatabase databaseAtPath:path]];
}

-(long)saveDatabase:(NSString*)path context:(NSManagedObjectContext*)context { // __deprecated
	NSError* err = nil;
	[[DicomDatabase databaseForContext:context] save:&err];
	return [err code];

//	long retError = 0;
//	
//	if( [[AppController sharedAppController] isSessionInactive])
//	{
//		NSLog( @"---- Session is not active : db will not be saved");
//		return retError;
//	}
//	
//	if( DICOMDIRCDMODE == NO)
//	{
//		NSError *error = nil;
//		
//		[context lock];
//		
//		@try
//		{
//			[context save: &error];
//			
//			if (error)
//			{
//				NSLog( @"****** error saving DB: %@", [[error userInfo] description]);
//				NSLog( @"****** saveDatabase ERROR: %@", [error localizedDescription]);
//				retError = -1L;
//			}
//			
//			if( path == nil)
//				path = currentDatabasePath;
//			
//			[[NSString stringWithString:DATABASEVERSION] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"] atomically:YES];
//			
//			[[NSUserDefaults standardUserDefaults] setObject:DATABASEVERSION forKey: @"DATABASEVERSION"];
//		}
//		@catch (NSException * e) {NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);[AppController printStackTrace: e];}
//		
//		[context unlock];
//	}
//	
//	return retError;*/
}

// TODO: #pragma we know saveDatabase:context: is deprecated
-(long)saveDatabase { // __deprecated
	return [self saveDatabase:nil context:self.managedObjectContext];
}

// TODO: #pragma we know saveDatabase:context: is deprecated
-(long)saveDatabase:(NSString*)path { // __deprecated
	return [self saveDatabase:path context:self.managedObjectContext];
}

- (void) selectThisStudy: (id)study
{
	[self outlineViewRefresh];
	
	[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: study]] byExtendingSelection: NO];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}


- (IBAction) copyToDBFolder: (id) sender
{
	BOOL matrixThumbnails = NO;
	
	if (![_database isLocal]) return;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		matrixThumbnails = YES;
		NSLog( @"copyToDBFolder from matrix");
	}
	
	NSMutableArray *objects = [NSMutableArray array];
	NSMutableArray *files;
	
	if( matrixThumbnails)
		files = [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
	else
		files = [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
	
	Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying linked files into Database...", nil) :YES];
		
	[splash showWindow:self];
	[[splash progress] setMaxValue:[objects count]];
	[splash setCancel: YES];
		
	[_database lock];
	
	[files removeDuplicatedStringsInSyncWithThisArray: objects];
	
	@try
	{
		for( NSManagedObject *im in objects)
		{
			if( [[im valueForKey: @"inDatabaseFolder"] boolValue] == NO)
			{
				NSString *srcPath = [im valueForKey:@"completePath"];
				NSString *extension = [srcPath pathExtension];
				
				if( [[im valueForKey: @"fileType"] hasPrefix: @"DICOM"])
					extension = [NSString stringWithString:@"dcm"];
				
				if( [extension isEqualToString:@""])
					extension = [NSString stringWithString:@"dcm"]; 
				
				NSString *dstPath = [self getNewFileDatabasePath:extension];
				
				if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil])
				{
					[[im valueForKey:@"series"] setValue: [NSNumber numberWithBool: NO] forKey:@"mountedVolume"];
					
					for( NSManagedObject *c in [[im valueForKeyPath: @"series.images"] allObjects]) // For multi frame files
					{
						if( [[c valueForKey:@"completePath"] isEqualToString: srcPath])
						{
							[c setValue: [NSNumber numberWithBool: YES] forKey:@"inDatabaseFolder"];
							[c setValue: [dstPath lastPathComponent] forKey:@"path"];
							[c setValue: [NSNumber numberWithBool: NO] forKey:@"mountedVolume"];
						}
					}
				}
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted])
				break;
		}
	}
	@catch ( NSException *e)
	{
		NSLog( @"******** copy to DB exception: %@", e);
		[AppController printStackTrace: e];
	} @finally {
		[_database unlock];
	}
	[splash close];
	[splash release];
}

- (void) copyFilesIntoDatabaseIfNeeded: (NSMutableArray*) filesInput options: (NSDictionary*) options
{
	if (![_database isLocal]) return;
	if( [filesInput count] == 0) return;
	
	BOOL COPYDATABASE = [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYDATABASE"];
	int COPYDATABASEMODE = [[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASEMODE"];
	
	if( [options objectForKey: @"COPYDATABASE"])
		COPYDATABASE = [[options objectForKey: @"COPYDATABASE"] boolValue];
		
	if( [options objectForKey: @"COPYDATABASEMODE"])
		COPYDATABASEMODE = [[options objectForKey: @"COPYDATABASEMODE"] integerValue];
	
//	if( DICOMDIRCDMODE)
//		COPYDATABASE = NO;
	
	NSMutableArray *newFilesToCopyList = [NSMutableArray arrayWithCapacity: [filesInput count]];
	NSString *INpath = [_database dataDirPath];
	
	for( NSString *file in filesInput)
	{
		if( [[file commonPrefixWithString: INpath options: NSLiteralSearch] isEqualToString:INpath] == NO)
			[newFilesToCopyList addObject: file];
	}
	
	BOOL copyFiles = NO;
	
	if( COPYDATABASE && [newFilesToCopyList count])
	{
		copyFiles = YES;
		
		switch (COPYDATABASEMODE)
		{
			case always:
				break;
				
			case notMainDrive:
			{
				NSArray *pathFilesComponent = [[filesInput objectAtIndex:0] pathComponents];
				
				if( [[[pathFilesComponent objectAtIndex: 1] uppercaseString] isEqualToString:@"VOLUMES"])
					NSLog(@"not the main drive!");
				else
					copyFiles = NO;
			}
			break;
				
			case cdOnly:
			{
				NSLog( @"%@", [filesInput objectAtIndex:0]);
				
				if( [BrowserController isItCD: [filesInput objectAtIndex:0]] == NO)
					copyFiles = NO;
			}
			break;
				
			case ask:
				switch (NSRunInformationalAlertPanel(
													 NSLocalizedString(@"OsiriX Database",@"OsiriX Database"),
													 NSLocalizedString(@"Should I copy these files in OsiriX Database folder, or only copy links to these files?",@"Should I copy these files in OsiriX Database folder, or only copy links to these files?"),
													 NSLocalizedString(@"Copy Files",@"Copy Files"),
													 NSLocalizedString(@"Cancel",@"Cancel"),
													 NSLocalizedString(@"Copy Links",@"Copy Links")))
													{
					case NSAlertDefaultReturn:
					break;
					
					case NSAlertOtherReturn:
						copyFiles = NO;
					break;
					
					case NSAlertAlternateReturn:
						[filesInput removeAllObjects];		// zero the array before it is returned.
						return;
					break;
				}
			break;
		}
	}
	
	NSMutableArray  *filesOutput = [NSMutableArray array];
	
	if( copyFiles)
	{
		NSString *OUTpath = [_database dataDirPath];
		
		[AppController createNoIndexDirectoryIfNecessary: OUTpath];
		
		if( [[options objectForKey: @"async"] boolValue])
		{
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: filesInput, @"filesInput", [NSNumber numberWithBool: YES], @"copyFiles", nil];
			[dict addEntriesFromDictionary: options];
			
			NSThread *t = [[[NSThread alloc] initWithTarget:_database selector:@selector(copyFilesThread:) object: dict] autorelease];
			if( [[options objectForKey: @"mountedVolume"] boolValue]) t.name = NSLocalizedString( @"Copying and indexing files from CD/DVD...", nil);
			else t.name = NSLocalizedString( @"Copying and indexing files...", nil);
			t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [filesInput count]];
			t.supportsCancel = YES;
			[[ThreadsManager defaultManager] addThreadAndStart: t];
		}
		else
		{
			Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying into Database...", nil)];
			
			[splash showWindow:self];
			[[splash progress] setMaxValue:[filesInput count]];
			[splash setCancel: YES];
			
			for( NSString *srcPath in filesInput)
			{
				NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
				
				NSString *extension = [srcPath pathExtension];
				
				@try
				{
					if( [[[srcPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
					{
						DicomFile *curFile = [[DicomFile alloc] init: srcPath];
						
						if( curFile)
						{
							if( [[[curFile dicomElements] objectForKey: @"fileType"] hasPrefix: @"DICOM"])
								extension = [NSString stringWithString:@"dcm"];
							
							[curFile release];
							
							if( [extension isEqualToString:@""])
								extension = [NSString stringWithString:@"dcm"]; 
							
							if( [extension length] > 4 || [extension length] < 3)
								extension = [NSString stringWithString:@"dcm"];
							
							NSString *dstPath = [self getNewFileDatabasePath:extension];
							
							if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil] == YES)
							{
								[filesOutput addObject:dstPath];
							}
							
							if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
							{
								[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
							}
						}
						else NSLog( @"**** DicomFile *curFile = nil");
					}
				}
				@catch (NSException * e)
				{
					NSLog( @"copyFilesIntoDatabaseIfNeeded exception: %@", e);
					[AppController printStackTrace: e];
				}
				[splash incrementBy:1];
				
				[pool release];
				
				if( [splash aborted])
					break;
			}
			
			[splash close];
			[splash release];
		}
	}
	else
	{
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: filesInput, @"filesInput", [NSNumber numberWithBool: NO], @"copyFiles", nil];
		[dict addEntriesFromDictionary: options];
		
		NSThread *t = [[[NSThread alloc] initWithTarget:_database selector:@selector( copyFilesThread:) object: dict] autorelease];
		
		if( [[options objectForKey: @"mountedVolume"] boolValue]) t.name = NSLocalizedString( @"Indexing files from CD/DVD...", nil);
		else t.name = NSLocalizedString( @"Indexing files...", nil);
		t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [filesInput count]];
		t.supportsCancel = YES;
		[[ThreadsManager defaultManager] addThreadAndStart: t];
			
		filesOutput = filesInput;
	}
	
	return;
}

-(void)rebuildDatabaseThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		DicomDatabase* database = [io objectAtIndex:0];
		BOOL complete = [[io objectAtIndex:1] boolValue];
		[database rebuild:complete];
		[self performSelectorOnMainThread:@selector(setDatabase:) withObject:database waitUntilDone:NO];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(NSThread*)initiateRebuildDatabase:(BOOL)complete {
	DicomDatabase* database = [[self.database retain] autorelease];
	[self setDatabase:nil];
	
	NSArray* io = [NSMutableArray arrayWithObjects: database, [NSNumber numberWithBool:complete], nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(rebuildDatabaseThread:) object:io];
	thread.name = NSLocalizedString(@"Rebuilding database...", nil);
	
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return [thread autorelease];
}

- (IBAction)endReBuildDatabase:(id)sender
{
	[NSApp endSheet: rebuildWindow];
	[rebuildWindow orderOut: self];
	
	[self waitForRunningProcesses];
	
	if ([sender tag]) {
		switch ([rebuildType selectedTag]) {
			case 0:
				[self initiateRebuildDatabase:YES];
				break;
				
			case 1:
				[self initiateRebuildDatabase:NO];
				break;
		}
	}
}

-(IBAction)ReBuildDatabase:(id)sender { // __deprecated
	[self initiateRebuildDatabase:NO];
}

- (IBAction) ReBuildDatabaseSheet: (id)sender
{
	if (![_database rebuildAllowed])
		[NSException raise:NSGenericException format:@"Current database rebuild not allowed, this shouldn't be executed."];
	
	// Wait if there is something in the delete queue
	[self emptyDeleteQueueNow: self];
	//
	
	// Wait if there is something in the autorouting queue
//	[autoroutingInProgress lock];
//	[autoroutingInProgress unlock];
	
//	[self emptyAutoroutingQueue:self];
	
//	[autoroutingInProgress lock];
//	[autoroutingInProgress unlock];
	
	long totalFiles = 0;
	NSString	*aPath = [_database dataDirPath];
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for(NSString *name in dirContent)
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: name];
		totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
	}
	
	[noOfFilesToRebuild setIntValue: totalFiles];
	
	long durationFor1000;
	
	NSRect frame = [rebuildWindow frame];
	BOOL warningWasHidden = [warning isHidden];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"TOOLKITPARSER3"] == 0) {
		durationFor1000 = 18;
		[warning setHidden:NO];
		frame.size.height = 333;
		[rebuildWindow setContentSize:frame.size];
	} else {
		durationFor1000 = 9;
		[warning setHidden:YES];
		frame.size.height = 333-[warning bounds].size.height-8;
		[rebuildWindow setContentSize:frame.size];
	}
	
	long totalSeconds = totalFiles * durationFor1000 / 1000;
	[estimatedTime setStringValue:[NSString timeString:totalSeconds maxUnits:2]];
	
	[[AppController sharedAppController] closeAllViewers: self];
	
	[NSApp beginSheet: rebuildWindow
	   modalForWindow: self.window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

-(void)rebuildSqlThread:(DicomDatabase*)database {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		[database rebuildSqlFile];
		[self performSelectorOnMainThread:@selector(setDatabase:) withObject:database waitUntilDone:NO];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(NSThread*)initiateRebuildSql {
	DicomDatabase* database = [[self.database retain] autorelease];
	[self setDatabase:nil];
	
	NSArray* io = [NSMutableArray arrayWithObjects: database, nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(rebuildSqlThread:) object:database];
	thread.name = NSLocalizedString(@"Rebuilding database index...", nil);
	
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return [thread autorelease];
}

-(void)_rebuildSqlSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[NSApp endSheet:sheet];
	if (returnCode == NSAlertDefaultReturn)
		[self initiateRebuildSql];
}

-(IBAction)rebuildSQLFile:(id)sender {
	if (![_database rebuildAllowed])
		[NSException raise:NSGenericException format:@"Current database rebuild not allowed, this shouldn't be executed."];
	NSBeginInformationalAlertSheet(nil, nil, NSLocalizedString(@"Cancel", nil), nil, self.window, self, @selector(_rebuildSqlSheetDidEnd:returnCode:contextInfo:), nil, nil, NSLocalizedString(@"Are you sure you want to rebuild this database's SQL index? This operation can take several minutes.", nil));
}

- (void) reduceCoreDataFootPrint
{
	NSLog(@"In %s", __PRETTY_FUNCTION__);

	if( [_database tryLock])
	{
		@try
		{
			[[AppController sharedAppController] closeAllViewers: self];
			
			[reportFilesToCheck removeAllObjects];
			
			[[LogManager currentLogManager] checkLogs: nil];
			[self resetLogWindowController];
			[[LogManager currentLogManager] resetLogs];

//			displayEmptyDatabase = YES;
//			[self outlineViewRefresh];
//			[self refreshMatrix: self];
			
			DicomDatabase* db = [_database retain];
			[self setDatabase:nil];

			[db reduceCoreDataFootPrint];
			
			[self setDatabase:[db autorelease]];
		}
		@catch (NSException * e) 
		{
			N2LogExceptionWithStackTrace(e);
		}
		@finally {
			[_database unlock];
		}
		
		[DCMPix purgeCachedDictionaries];
		[DCMView purgeStringTextureCache];
	}
}

- (void) autoCleanDatabaseDate: (id)sender { // __deprecated
	[_database cleanOldStuff];
}

+ (BOOL) isHardDiskFull { // __deprecated
	return [[DicomDatabase activeLocalDatabase] isFileSystemFreeSizeLimitReached];
}
    
- (void) autoCleanDatabaseFreeSpace: (id)sender { // __deprecated
	[_database initiateCleanUnlessAlreadyCleaning];
}

#pragma mark-
#pragma mark Web Portal Database // deprecated, use WebPortal.defaultWebPortal

-(long)saveUserDatabase { // __deprecated
#ifndef OSIRIX_LIGHT
	[[[WebPortal defaultWebPortal] database] save:NULL];
#endif
	return 0;
}

-(NSManagedObjectModel*)userManagedObjectModel { // __deprecated
#ifndef OSIRIX_LIGHT
	return [[[WebPortal defaultWebPortal] database] managedObjectModel];
#else
	return NULL;
#endif
}

-(NSManagedObjectContext*)userManagedObjectContext { // __deprecated
#ifndef OSIRIX_LIGHT
	return [[[WebPortal defaultWebPortal] database] managedObjectContext];
#else
	return NULL;
#endif
}

-(WebPortalUser*)userWithName:(NSString*)name { // __deprecated
#ifndef OSIRIX_LIGHT
	return [[[WebPortal defaultWebPortal] database] userWithName:name];
#else
	return NULL;
#endif
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark OutlineView Search & Time Interval Functions

- (IBAction)search: (id)sender
{
	[self outlineViewRefresh];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (IBAction)setSearchType: (id)sender
{

	if( searchType == 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"HIDEPATIENTNAME"])
		[searchField setTextColor: [NSColor whiteColor]];
	else
		[searchField setTextColor: [NSColor blackColor]];

	for( long i = 0; i < [[sender menu] numberOfItems]; i++) [[[sender menu] itemAtIndex: i] setState: NSOffState];
	
	[[[sender menu] itemWithTag: [sender tag]] setState: NSOnState];
	[toolbarSearchItem setLabel: [NSString stringWithFormat: NSLocalizedString(@"Search by %@", nil), [sender title]]];
	searchType = [sender tag];
	//create new Filter Predicate when changing searchType ans set searchString to nil;
	[self setSearchString:nil];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (IBAction)customIntervalNow:(id) sender
{
	if( [sender tag] == 0)	{
		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	}
	
	if( [sender tag] == 1)	{
		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	}
}

- (IBAction)endCustomInterval: (id)sender
{
	if( [sender tag] == 1)	{
		[timeIntervalStart release];		timeIntervalStart = [[customStart dateValue] retain];
		[timeIntervalEnd release];			timeIntervalEnd = [[customEnd dateValue] retain];
	}
	
	[NSApp endSheet: customTimeIntervalWindow];
	[customTimeIntervalWindow orderOut: self];
	
	NSLog(@"from: %@ to: %@", [timeIntervalStart description], [timeIntervalEnd description]);
	
	[self outlineViewRefresh];
}

- (void) computeTimeInterval
{
	switch( timeIntervalType)
	{
		case 0:	// None
			[timeIntervalStart release];		timeIntervalStart = nil;
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 1:	// 1 hour
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 2:	// 6 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*6] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 3:	// 12 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*12] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 7:	// 24 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*24] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 8:	// 48 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*48] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
			break;
			
		case 4:	{ // Today
			
			NSCalendarDate *now = [NSCalendarDate calendarDate];
			NSCalendarDate *start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
			
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [start timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
		}
			break;
			
		case 5:
		{	// One week
			
			NSCalendarDate *now		= [NSCalendarDate calendarDate];
			NSCalendarDate *oneWeek = [now dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0];
			
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [oneWeek timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
		}
			break;
			
		case 6:	{ // One month
			
			NSCalendarDate *now		= [NSCalendarDate calendarDate];
			NSCalendarDate *oneWeek = [now dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
			
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [oneWeek timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = nil;
		}
			break;
			
		case 100:	// Custom
			
			break;
	}
}

- (IBAction) setTimeIntervalType: (id)sender
{
	timeIntervalType = [[sender selectedItem] tag];
	
	if( [[sender selectedItem] tag] == 100)
	{
		[customEnd2 setLocale: [NSLocale currentLocale]];
		[customStart2 setLocale: [NSLocale currentLocale]];
		[customEnd setLocale: [NSLocale currentLocale]];
		[customStart setLocale: [NSLocale currentLocale]];
		
		[NSApp beginSheet: customTimeIntervalWindow
		   modalForWindow: self.window
			modalDelegate: nil
		   didEndSelector: nil
			  contextInfo: nil];
	}
	else
	{
		[self computeTimeInterval];
		
		[self outlineViewRefresh];
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark OutlineView functions

- (NSPredicate*) smartAlbumPredicateString:(NSString*) string
{
	if( string == nil || [string length] == 0)
		return [NSPredicate predicateWithValue: YES];
	
	NSMutableString *pred = [NSMutableString stringWithString: string];
	
	// DATES
	
	// Today:
	NSCalendarDate	*now = [NSCalendarDate calendarDate];
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
	
	NSDictionary	*sub = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*1] timeIntervalSinceReferenceDate]],			@"$LASTHOUR",
							[NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*6] timeIntervalSinceReferenceDate]],			@"$LAST6HOURS",
							[NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*12] timeIntervalSinceReferenceDate]],			@"$LAST12HOURS",
							[NSString stringWithFormat:@"%lf", [start timeIntervalSinceReferenceDate]],										@"$TODAY",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24] timeIntervalSinceReferenceDate]],			@"$YESTERDAY",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*2] timeIntervalSinceReferenceDate]],		@"$2DAYS",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*7] timeIntervalSinceReferenceDate]],		@"$WEEK",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31] timeIntervalSinceReferenceDate]],		@"$MONTH",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31*2] timeIntervalSinceReferenceDate]],	@"$2MONTHS",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31*3] timeIntervalSinceReferenceDate]],	@"$3MONTHS",
							[NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*365] timeIntervalSinceReferenceDate]],		@"$YEAR",
							nil];
	
	NSEnumerator *enumerator = [sub keyEnumerator];
	NSString *key;
	
	while ((key = [enumerator nextObject]))
	{
		[pred replaceOccurrencesOfString:key withString: [sub valueForKey: key]	options: NSCaseInsensitiveSearch range:pred.range];
	}
	
	NSPredicate *predicate;
	
	if( [string isEqualToString:@""]) predicate = [NSPredicate predicateWithValue: YES];
	else
	{
		predicate = [NSPredicate predicateWithFormat: pred];
	}
	return predicate;
}

- (NSPredicate*)smartAlbumPredicate: (NSManagedObject*)album
{
	NSPredicate	*pred = nil;
	
	@try
	{
		pred = [self smartAlbumPredicateString: [album valueForKey:@"predicateString"]];
	}
	
	@catch( NSException *ne)
	{
		pred = [NSPredicate predicateWithValue: NO];
		
		NSLog( @"filter error %@ : %@", [ne name] ,[ne reason]);
		
		[AppController printStackTrace: ne];
	}
	
	return pred;
}

- (NSString*) outlineViewRefresh		// This function creates the 'root' array for the outlineView
{
	if( databaseOutline == nil) return nil;
	if( loadingIsOver == NO) return nil;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
	{
		if( [[self window] isVisible] == NO) return nil;
	}
	
	if( [NSThread isMainThread] == NO)
		NSLog( @"******* We HAVE TO be in main thread !");
	
	NSError				*error =nil;
	NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
	NSPredicate			*predicate = nil, *subPredicate = nil;
	NSString			*description = [NSString string];
	NSIndexSet			*selectedRowIndexes =  [databaseOutline selectedRowIndexes];
	NSMutableArray		*previousObjects = [NSMutableArray array];
	NSArray				*albumArrayContent = nil;
	BOOL				filtered = NO;
	NSString			*exception = nil;
	
	NSInteger index = [selectedRowIndexes firstIndex];
	while (index != NSNotFound)
	{
		if( [databaseOutline itemAtRow: index])
			[previousObjects addObject: [databaseOutline itemAtRow: index]];
		index = [selectedRowIndexes indexGreaterThanIndex:index];
	}
	
	[request setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
	
	predicate = [NSPredicate predicateWithValue:YES];
	
//	if( displayEmptyDatabase) // TODO: shu
//		predicate = [NSPredicate predicateWithValue:NO];
	
	if (![_database isLocal] && [_sourcesTableView selectedRow] > 0)
	{
		int rowIndex = [_sourcesTableView selectedRow];
		
		NSDictionary *dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
		
		if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [[dict valueForKey:@"service"] name]];
		else description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [dict valueForKey:@"Description"]];
		
	}
	else description = [description stringByAppendingString:NSLocalizedString(@"Local Database / ", nil)];
	
	// ********************
	// ALBUMS
	// ********************
	
	if( albumTable.selectedRow > 0)
	{
		NSArray	*albumArray = self.albumArray;
		
		if( [albumArray count] > albumTable.selectedRow)
		{
			NSManagedObject	*album = [albumArray objectAtIndex: albumTable.selectedRow];
			NSString		*albumName = [album valueForKey:@"name"];
			
			if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
			{
				subPredicate = [self smartAlbumPredicate: album];
				description = [description stringByAppendingFormat:NSLocalizedString(@"Smart Album selected: %@", nil), albumName];
				predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, nil]];
			}
			else
			{
				albumArrayContent = [[album valueForKey:@"studies"] allObjects];
				description = [description stringByAppendingFormat:NSLocalizedString(@"Album selected: %@", nil), albumName];
			}
		}
	}
	else description = [description stringByAppendingString: NSLocalizedString(@"No album selected", nil)];
	
	// ********************
	// TIME INTERVAL
	// ********************
	
	[self computeTimeInterval];
	
	if( timeIntervalStart != nil || timeIntervalEnd != nil)
	{
		if( timeIntervalStart != nil && timeIntervalEnd != nil)
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat: NSLocalizedString(@" / Time Interval: from: %@ to: %@", nil),[[NSUserDefaults dateTimeFormatter] stringFromDate: timeIntervalStart],  [[NSUserDefaults dateTimeFormatter] stringFromDate: timeIntervalEnd] ];
		}
		else
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat:NSLocalizedString(@" / Time Interval: since: %@", nil), [[NSUserDefaults dateTimeFormatter] stringFromDate: timeIntervalStart]];
		}
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, nil]];
		filtered = YES;
	}
	
	// ********************
	// SEARCH FIELD
	// ********************
	
	if( self.filterPredicate)
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, self.filterPredicate, nil]];
		description = [description stringByAppendingString: self.filterPredicateDescription];
		filtered = YES;
	}
	
	if( testPredicate)
		predicate = testPredicate;
	
	[request setPredicate: predicate];
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	error = nil;
	[outlineViewArray release];
	
	@try
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useSoundexForName"] && (searchType == 7 || searchType == 0) && [_searchString length] > 0)
		{
			if( albumArrayContent) outlineViewArray = [albumArrayContent filteredArrayUsingPredicate: predicate];
			else
			{
				[request setPredicate: [NSPredicate predicateWithValue: YES]];
				outlineViewArray = [context executeFetchRequest: request error: &error];
				outlineViewArray = [outlineViewArray filteredArrayUsingPredicate: predicate];
			}
		}
		else
		{
			if( albumArrayContent) outlineViewArray = [albumArrayContent filteredArrayUsingPredicate: predicate];
			else outlineViewArray = [context executeFetchRequest:request error: &error];
		}
		
		if( error)
			NSLog( @"**** executeFetchRequest: %@", error);
		
		@synchronized( albumNoOfStudiesCache) {
			if ([albumNoOfStudiesCache count] > albumTable.selectedRow && filtered == NO)
				[albumNoOfStudiesCache replaceObjectAtIndex:albumTable.selectedRow withObject:[decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:[outlineViewArray count]]]];
		}
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"OutlineRefresh exception: %@", [ne description]);
		[AppController printStackTrace: ne];
		
		[request setPredicate: [NSPredicate predicateWithValue: NO]];
		outlineViewArray = [context executeFetchRequest:request error:&error];
		
		exception = [ne description];
	}
	
	if( albumTable.selectedRow > 0) filtered = YES;
	
	NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey: @"date" ascending:NO] autorelease];
	NSArray * sortDescriptors;
	if( [databaseOutline sortDescriptors] == nil || [[databaseOutline sortDescriptors] count] == 0)
	{
		// By default sort by name
		NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		sortDescriptors = [NSArray arrayWithObjects: sort, sortdate, nil];
	}
	else if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"])
	{
		sortDescriptors = [NSArray arrayWithObjects: [[databaseOutline sortDescriptors] objectAtIndex: 0], sortdate, nil];
	}
	else sortDescriptors = [databaseOutline sortDescriptors];
	
	if( filtered == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogether"] && [outlineViewArray count] > 0)
	{
		@try
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogetherAndGrouped"])
			{
				outlineViewArray = [outlineViewArray sortedArrayUsingDescriptors: sortDescriptors];
				
				NSMutableArray *copyOutlineViewArray = [NSMutableArray arrayWithArray: outlineViewArray];
				int studyIndex = 0;
				
				for( id obj in outlineViewArray)
				{
					[request setPredicate: [NSPredicate predicateWithFormat: @"(patientID == %@) AND (studyInstanceUID != %@)", [obj valueForKey:@"patientID"], [obj valueForKey:@"studyInstanceUID"]]];
					
					for( id patientStudy in [[context executeFetchRequest: request error: &error] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease]]])
					{
						if( [copyOutlineViewArray containsObject: patientStudy] == NO && patientStudy != nil)
						{
							studyIndex++;
							[copyOutlineViewArray insertObject: patientStudy atIndex: studyIndex];
						}
					}
					
					studyIndex++;
				}
				
				[originalOutlineViewArray release];
				originalOutlineViewArray = [outlineViewArray retain];
				outlineViewArray = copyOutlineViewArray;
			}
			else
			{
				NSMutableArray	*patientPredicateArray = [NSMutableArray array];
				
				for( id obj in outlineViewArray)
				{
					[patientPredicateArray addObject: [NSPredicate predicateWithFormat:  @"(patientID == %@)", [obj valueForKey:@"patientID"]]];
				}
				
				[request setPredicate: [NSCompoundPredicate orPredicateWithSubpredicates: patientPredicateArray]];
				error = nil;
				[originalOutlineViewArray release];
				originalOutlineViewArray = [outlineViewArray retain];
				outlineViewArray = [[context executeFetchRequest:request error:&error] sortedArrayUsingDescriptors: sortDescriptors];
			}
		}
		@catch( NSException *ne)
		{
			NSLog( @"********** OutlineRefresh exception: %@", [ne description]);
			[AppController printStackTrace: ne];
		}
	}
	else
	{
		[originalOutlineViewArray release];
		originalOutlineViewArray = nil;
		
		outlineViewArray = [outlineViewArray sortedArrayUsingDescriptors: sortDescriptors];
	}
	
	long images = 0;
	for( id obj in outlineViewArray)
	{
		images += [[obj valueForKey:@"noFiles"] intValue];
	}
	
	description = [description stringByAppendingFormat: NSLocalizedString(@" / Result = %@ studies (%@ images)", nil), [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt: [outlineViewArray count]]], [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:images]]];
	
	outlineViewArray = [outlineViewArray retain];
	
	[context unlock];
	[context release];
	
	[databaseOutline reloadData];
	
	@try
	{
		for( id obj in outlineViewArray)
		{
			if( [[obj valueForKey:@"expanded"] boolValue]) [databaseOutline expandItem: obj];
		}
	}
	@catch( NSException *ne)
	{
		NSLog( @"********** OutlineRefresh exception: %@", [ne description]);
		[AppController printStackTrace: ne];
	}
	
	
	if( [previousObjects count] > 0)
	{
		BOOL extend = NO;
		for( id obj in previousObjects)
		{
			[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: obj]] byExtendingSelection: extend];
			extend = YES;
		}
	}
	
	if( [outlineViewArray count] > 0)
		[[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: nil];
	
	[databaseDescription setStringValue: description];
	
	return exception;
}

- (void) searchDeadProcesses
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try
	{
		// Test for deadlock processes lock_process pid in tmp folder
		for( NSString *s in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: @"/tmp" error: nil]) 
		{
			if( [s hasPrefix: @"lock_process-"])
			{
				int timeIntervalSinceNow = [[[[NSFileManager defaultManager] attributesOfItemAtPath: [@"/tmp/" stringByAppendingPathComponent: s] error: nil] fileCreationDate] timeIntervalSinceNow];
				
				if( timeIntervalSinceNow < -60*60*1)
				{
					NSLog( @"****** dead process found lock_process %@", s);
					NSLog( @"****** dead process timeIntervalSinceNow %d", timeIntervalSinceNow);
					
					int pid = [[s stringByReplacingOccurrencesOfString: @"lock_process-" withString: @""] intValue];
					
					if( pid)
					{
						NSLog( @"****** kill pid %@", s);
						kill( pid, 15);
						
						char dir[ 1024];
						sprintf( dir, "%s-%d", "/tmp/lock_process", pid);
						unlink( dir);
					}
				}
			}
		 }
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
			 
	[pool release];
}


-(void)refreshBonjourSource: (id) sender {
	if ([_database isKindOfClass:RemoteDicomDatabase.class])
		[(RemoteDicomDatabase*)_database initiateUpdate];
}

- (void) reloadAlbumTableData
{
	[albumTable reloadData];
}

- (void) computeNumberOfStudiesForAlbums
{
	NSAutoreleasePool* pool = nil;
	if (![NSThread isMainThread])
		pool = [[NSAutoreleasePool alloc] init];
	
//	@synchronized( [BrowserController currentBrowser])
//	{
//		cachedAlbumsManagedObjectContext = nil;
//	}
	
	DicomDatabase* database = [self.database independentDatabase];
	if (database) @try {
		if(/* displayEmptyDatabase == NO &&-*/ computeNumberOfStudiesForAlbums == NO) {
			computeNumberOfStudiesForAlbums = YES;
			
//			NSManagedObjectContext* context = [database independentContext];
			NSMutableArray* NoOfStudies = [NSMutableArray array];
			NSError *error = nil;
			
			NSArray *studiesArray = nil;
			@try {
				studiesArray = [database objectsForEntity:database.studyEntity];
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			}
			
			[NoOfStudies addObject: [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]];
			
			NSArray *albums = [database albums];
			
			for( int rowIndex = 0 ; rowIndex < [albums count]; rowIndex++)
			{
				NSManagedObject	*object = [albums objectAtIndex: rowIndex];
				
				if( [[object valueForKey:@"smartAlbum"] boolValue] == YES)
				{
					@try {
						NSArray *studiesArray = [database objectsForEntity:database.studyEntity predicate:[self smartAlbumPredicate:object]];
						[NoOfStudies addObject: [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]];
					} @catch( NSException *e) {
						N2LogExceptionWithStackTrace(e);
						[NoOfStudies addObject: @"err"];
					}
				}
				else
					[NoOfStudies addObject: [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:[[object valueForKey:@"studies"] count]]]];
			}
			
			@synchronized(albumNoOfStudiesCache) {
				[albumNoOfStudiesCache removeAllObjects];
				[albumNoOfStudiesCache addObjectsFromArray: NoOfStudies];
			}
			
			[self performSelectorOnMainThread: @selector(reloadAlbumTableData) withObject: nil waitUntilDone: NO];
			
			computeNumberOfStudiesForAlbums = NO;
		}
		else
			[self performSelectorOnMainThread: @selector(delayedRefreshAlbums) withObject: nil waitUntilDone: NO];
	}
	@catch (NSException * e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[database release];
		[pool release];
	}
}

- (void)delayedRefreshAlbums {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(computeNumberOfStudiesForAlbums) object:nil];
	[self performSelector:@selector(computeNumberOfStudiesForAlbums) withObject:nil afterDelay:20];
}

- (void)refreshAlbums {
	//@synchronized (self) {
	//	cachedAlbumsManagedObjectContext = nil;
	//}

	[NSThread detachNewThreadSelector: @selector(computeNumberOfStudiesForAlbums) toTarget:self withObject: nil];
}

- (void)refreshDatabase: (id)sender
{
	if( [[AppController sharedAppController] isSessionInactive] || waitForRunningProcess) return;
	if( _database == nil) return;
//	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	if( [databaseOutline editedRow] != -1) return;
	
	NSArray *albumArray = self.albumArray;
	
	if( albumTable.selectedRow >= [albumArray count]) return;
	
	if( [[[albumArray objectAtIndex: albumTable.selectedRow] valueForKey:@"smartAlbum"] boolValue] == YES)
	{
		@try
		{
			[self outlineViewRefresh];
			[self refreshAlbums];
		}
		@catch (NSException * e)
		{
			NSLog( @"refreshDatabase exception");
			NSLog( @"%@", [e description]);
			[AppController printStackTrace: e];
		}
	}
	else
	{
		//For filters depending on time....
		[self refreshAlbums];
		[databaseOutline reloadData];
	}
	
	#ifndef OSIRIX_LIGHT
	if( [QueryController currentQueryController])
		[[QueryController currentQueryController] refresh: self];
	else if( [QueryController currentAutoQueryController])
		[[QueryController currentAutoQueryController] refresh: self];
	#endif
}

- (NSArray*) sortDescriptorsForImages
{
	int sortSeriesBySliceLocation = [[NSUserDefaults standardUserDefaults] integerForKey: @"sortSeriesBySliceLocation"];

	NSSortDescriptor *sortInstance = nil, *sortLocation = nil, *sortDate = nil;

	sortDate = [[[NSSortDescriptor alloc] initWithKey: @"date" ascending: (sortSeriesBySliceLocation > 0) ? YES : NO] autorelease];
	sortInstance = [[[NSSortDescriptor alloc] initWithKey: @"instanceNumber" ascending: YES] autorelease];
	sortLocation = [[[NSSortDescriptor alloc] initWithKey: @"sliceLocation" ascending: (sortSeriesBySliceLocation > 0) ? YES : NO] autorelease];

	NSArray *sortDescriptors = nil;

	if( sortSeriesBySliceLocation == 0)
		sortDescriptors = [NSArray arrayWithObjects: sortInstance, sortLocation, nil];
	else
	{
		if( sortSeriesBySliceLocation == 2 || sortSeriesBySliceLocation == -2)
			sortDescriptors = [NSArray arrayWithObjects: sortDate, sortLocation, sortInstance, nil];
		else
			sortDescriptors = [NSArray arrayWithObjects: sortLocation, sortInstance, nil];
	}
	
	return sortDescriptors;
}

- (NSArray*) childrenArray: (NSManagedObject*)item onlyImages: (BOOL)onlyImages
{
	if( [item isFault] || [item isDeleted])
	{
		NSLog( @"******** isFault - childrenArray");
		return nil;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		[_database lock];
		
		NSArray *sortedArray = nil;
		
		@try
		{
			sortedArray = [[[item valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: [self sortDescriptorsForImages]];
		}
		
		@catch (NSException * e)
		{
			NSLog( @"***** children Array%@", [e description]);
			[AppController printStackTrace: e];
		}

		[_database unlock];

		return sortedArray;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
	{
		[_database lock];
		
		NSArray *sortedArray = nil;
		@try
		{
			// Sort series with "id" & date
			NSSortDescriptor * sortid = [[[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)] autorelease];
			NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
			NSArray * sortDescriptors = nil;
			
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
			else if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
			else sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
			
			if( onlyImages) sortedArray = [[item valueForKey:@"imageSeries"] sortedArrayUsingDescriptors: sortDescriptors];
			else sortedArray = [[[item valueForKey:@"series"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
			
			if( onlyImages == NO)
			{
				// Put the ROI, Comments, Reports, ... at the end of the array
				NSMutableArray *resortedArray = [NSMutableArray arrayWithArray: sortedArray];
				NSMutableArray *SRArray = [NSMutableArray array];
				
				for( int i = 0 ; i < [resortedArray count]; i++)
				{
					if( [DCMAbstractSyntaxUID isStructuredReport: [[resortedArray objectAtIndex: i] valueForKey:@"seriesSOPClassUID"]])
						[SRArray addObject: [resortedArray objectAtIndex: i]];
				}
				
				[resortedArray removeObjectsInArray: SRArray];
				[resortedArray addObjectsFromArray: SRArray];
				
				sortedArray = resortedArray;
			}
		}
		@catch (NSException * e)
		{
			NSLog( @"%@", [e description]);
			[AppController printStackTrace: e];
		}
		
		[_database unlock];
		
		return sortedArray;
	}
	
	return nil;
}

- (NSArray*) childrenArray: (NSManagedObject*) item
{
	return [self childrenArray: item onlyImages: YES];
}

- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages
{
	NSArray			*childrenArray = [self childrenArray: item onlyImages:onlyImages];
	NSMutableArray	*imagesPathArray = nil;
	
	[_database lock];
	
	@try
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
		{
			imagesPathArray = [NSMutableArray arrayWithArray: childrenArray];
		}
		else if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			imagesPathArray = [NSMutableArray arrayWithCapacity: [childrenArray count]];
			
			BOOL first = YES;
			
			for( id i in childrenArray)
			{
				int whichObject = preferredObject;
				
				if( preferredObject == oFirstForFirst)
				{
					if( first == NO) preferredObject = oAny;
				}
				
				first = NO;
				
				if( preferredObject != oMiddle)
				{
					if( [i primitiveValueForKey:@"thumbnail"] == nil)
						whichObject = oMiddle;
				}
				
				switch( whichObject)
				{			
					case oAny:
					{
						NSManagedObject	*obj = [[i valueForKey:@"images"] anyObject];
						if( obj) [imagesPathArray addObject: obj];
					}
					break;
					
					case oMiddle:
					{
						NSArray	*seriesArray = [self childrenArray: i onlyImages:onlyImages];
						
						// Get the middle image of the series
						if( [seriesArray count] > 0)
						{
							if( [seriesArray count] > 1)
								[imagesPathArray addObject: [seriesArray objectAtIndex: -1 + [seriesArray count]/2]];
							else
								[imagesPathArray addObject: [seriesArray objectAtIndex: [seriesArray count]/2]];
						}
					}
					
					break;
					
					case oFirstForFirst:
					{
						NSArray	*seriesArray = [self childrenArray: i onlyImages:onlyImages];
					
						// Get the middle image of the series
						if( [seriesArray count] > 0)
							[imagesPathArray addObject: [seriesArray objectAtIndex: 0]];
					}
					break;
				}
			}
		}
	}
	
	@catch (NSException *e)
	{
		NSLog(@"imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages: %@", e);
		[AppController printStackTrace: e];
	}
	
	[_database unlock];
	
	return imagesPathArray;
}

- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject
{
	return [self imagesArray: item preferredObject: oAny onlyImages:YES]; 
}

- (NSArray*) imagesArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages
{
	return [self imagesArray: item preferredObject: oAny onlyImages: onlyImages];
}

- (NSArray*) imagesArray: (NSManagedObject*) item
{
	return [self imagesArray: item preferredObject: oAny];
}

- (NSArray*) imagesPathArray: (NSManagedObject*) item
{
	return [[self imagesArray: item] valueForKey: @"completePath"];
}

//- (void) deleteEmptyFoldersForDatabaseOutlineSelection
//{
//	NSIndexSet *rowEnumerator = [databaseOutline selectedRowIndexes];
//	NSManagedObject *curObj;
//	NSManagedObjectContext *context = self.managedObjectContext;
//	
//	[[[BrowserController currentBrowser] managedObjectContext] lock];
//	
//	NSUInteger row = [rowEnumerator firstIndex];
//    while (row != NSNotFound)
//    {
//		curObj = [databaseOutline itemAtRow: row];
//		
//		if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
//		{
//			if( [[curObj valueForKey:@"images"] count] == 0)
//				[context deleteObject: curObj];
//		}
//		
//		if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
//		{
//			if( [[curObj valueForKey:@"imageSeries"] count] == 0)
//				[context deleteObject: curObj];
//		}
//		
//		row = [rowEnumerator indexGreaterThanIndex: row];
//    }
//	
//	[[[BrowserController currentBrowser] managedObjectContext] unlock];
//}

- (NSManagedObject *)firstObjectForDatabaseOutlineSelection
{
	NSManagedObject *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
		aFile = [[aFile valueForKey:@"series"] anyObject];
	
	if( [[aFile valueForKey:@"type"] isEqualToString:@"Series"])
		aFile = [[aFile valueForKey:@"images"] anyObject];
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
	
	return aFile;
}

#define BONJOURPACKETS 50

- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages
{
	NSMutableArray *selectedFiles = [NSMutableArray array];
	NSIndexSet *rowEnumerator = [databaseOutline selectedRowIndexes];
	
	if( cachedFilesForDatabaseOutlineSelectionIndex && [[databaseOutline selectedRowIndexes] isEqualToIndexSet: cachedFilesForDatabaseOutlineSelectionIndex] && onlyImages == YES)
	{
		[selectedFiles addObjectsFromArray: cachedFilesForDatabaseOutlineSelectionSelectedFiles];
		
		if( correspondingManagedObjects)
			[correspondingManagedObjects addObjectsFromArray: cachedFilesForDatabaseOutlineSelectionCorrespondingObjects];
		
		return selectedFiles;
	}
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	if( correspondingManagedObjects == nil) correspondingManagedObjects = [NSMutableArray array];
	
	[context retain];
	[context lock];
	
	@try
	{
		NSUInteger row = [rowEnumerator firstIndex];
		while (row != NSNotFound)
		{
			NSManagedObject *curObj = [databaseOutline itemAtRow: row];
			
			if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
			{
				NSArray	*imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
				
				[correspondingManagedObjects addObjectsFromArray: imagesArray];
			}
			
			if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
			{
				NSArray	*seriesArray = [self childrenArray: curObj onlyImages: onlyImages];
				
				int totImage = 0;
				
				for( NSManagedObject *obj in seriesArray)
				{
					NSArray	*imagesArray = [self imagesArray: obj onlyImages: onlyImages];
					
					totImage += [imagesArray count];
					
					[correspondingManagedObjects addObjectsFromArray: imagesArray];
				}
				
				if( onlyImages == NO && totImage == 0)							// We don't want empty studies
					[context deleteObject: curObj];
			}
			row = [rowEnumerator indexGreaterThanIndex: row];
		}
		
		[correspondingManagedObjects removeDuplicatedObjects];
		
		if (![_database isLocal])
		{
			Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Downloading files...", nil)];
			[splash showWindow:self];
			[splash setCancel: YES];
			
			[[splash progress] setMaxValue: [correspondingManagedObjects count]];
			
			for( NSManagedObject *obj in correspondingManagedObjects)
			{
				if( [splash aborted] == NO)
				{
					NSString *p = [self getLocalDCMPath: obj :BONJOURPACKETS];
					
					[selectedFiles addObject: p];
					
					[splash incrementBy: 1];
				}
			}
						
			if( [splash aborted])
			{
				[selectedFiles removeAllObjects];
				[correspondingManagedObjects removeAllObjects];
			}
			
			[splash close];
			[splash release];
		}
		else
		{
			[selectedFiles addObjectsFromArray: [correspondingManagedObjects valueForKey: @"completePath"]];
		}
		
		if( [correspondingManagedObjects count] != [selectedFiles count])
			NSLog(@"****** WARNING [correspondingManagedObjects count] != [selectedFiles count]");
	}
	@catch (NSException * e)
	{
		NSLog( @"Exception in filesForDatabaseMatrixSelection: %@", e);
		[AppController printStackTrace: e];
	}
	
	[context release];
	[context unlock];
	
	if( onlyImages)
	{
		[cachedFilesForDatabaseOutlineSelectionSelectedFiles release];
		[cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release];
		[cachedFilesForDatabaseOutlineSelectionIndex release];
		
		cachedFilesForDatabaseOutlineSelectionIndex = [[NSIndexSet alloc] initWithIndexSet: [databaseOutline selectedRowIndexes]];
		cachedFilesForDatabaseOutlineSelectionSelectedFiles = [[NSMutableArray alloc] initWithArray:selectedFiles];
		cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = [[NSMutableArray alloc] initWithArray:correspondingManagedObjects];
	}
	
	return selectedFiles;
}

- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects
{
	return [self filesForDatabaseOutlineSelection:correspondingManagedObjects onlyImages: YES];
}

- (void) resetROIsAndKeysButton
{
	ROIsAndKeyImagesButtonAvailable = YES;
		
//	NSMutableArray *i = [NSMutableArray arrayWithArray: [[toolbar items] valueForKey: @"itemIdentifier"]];
//	if( [i containsString: OpenKeyImagesAndROIsToolbarItemIdentifier] && [database isLocal])
//	{
//		if( [[databaseOutline selectedRowIndexes] count] >= 5)	//[[self window] firstResponder] == databaseOutline && 
//			ROIsAndKeyImagesButtonAvailable = YES;
//		else
//		{
//			NSEvent *event = [[NSApplication sharedApplication] currentEvent];
//			
//			if([event modifierFlags] & NSAlternateKeyMask)
//			{
//				if( [[self KeyImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
//				else ROIsAndKeyImagesButtonAvailable = YES;
//			}
//			else if([event modifierFlags] & NSShiftKeyMask)
//			{
//				if( [[self ROIImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
//				else ROIsAndKeyImagesButtonAvailable = YES;
//			}
//			else
//			{
//				if( [[self ROIsAndKeyImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
//				else ROIsAndKeyImagesButtonAvailable = YES;
//			}
//		}
//	}
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
//	NSLog(@"outlineViewSelectionDidChange");
	
//	@synchronized( [BrowserController currentBrowser])
//	{
//		cachedAlbumsManagedObjectContext = nil;
//	}
	
	if( loadingIsOver == NO) return;
	
	@try
	{
		[cachedFilesForDatabaseOutlineSelectionSelectedFiles release]; cachedFilesForDatabaseOutlineSelectionSelectedFiles = nil;
		[cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release]; cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = nil;
		[cachedFilesForDatabaseOutlineSelectionIndex release]; cachedFilesForDatabaseOutlineSelectionIndex = nil;
		
		NSIndexSet *index = [databaseOutline selectedRowIndexes];
		NSManagedObject *item = [databaseOutline itemAtRow:[index firstIndex]];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
		{
			if( previousItem)
				[databaseOutline setNeedsDisplay: YES];
		}
		
		if( item)
		{
			/**********
			 post notification of new selected item. Can be used by plugins to update RIS connection
			 **********/
			NSManagedObject *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
			
			NSDictionary *userInfo = nil;
			if( studySelected)
			{
				userInfo = [NSDictionary dictionaryWithObject:studySelected forKey: @"Selected Study"];
				[[NSNotificationCenter defaultCenter] postNotificationName:OsirixNewStudySelectedNotification object:self userInfo:(NSDictionary *)userInfo];
			}
			
			BOOL refreshMatrix = YES;
			long nowFiles = [[item valueForKey:@"noFiles"] intValue];
			
			if( previousItem == item)
			{
				if( nowFiles == previousNoOfFiles)
					refreshMatrix = NO;
			}
			else 
				DatabaseIsEdited = NO;
			
			previousNoOfFiles = nowFiles;
			
			if( refreshMatrix)
			{
				[[self managedObjectContext] lock];
				
				[animationSlider setEnabled:NO];
				[animationSlider setMaxValue:0];
				[animationSlider setNumberOfTickMarks:1];
				[animationSlider setIntValue:0];
				
				[matrixViewArray release];
				
				if ([[item valueForKey:@"type"] isEqualToString:@"Series"] && 
					[[[item valueForKey:@"images"] allObjects] count] == 1 && 
					[[[[[item valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1)
					matrixViewArray = [[NSArray arrayWithObject:item] retain];
				else
					matrixViewArray = [[self childrenArray: item] retain];
				
				long cellId = 0;
				
				if( previousItem == item) cellId = [[oMatrix selectedCell] tag];
				else [oMatrix selectCellWithTag: 0];
				
				[self matrixInit: matrixViewArray.count];
				
				BOOL imageLevel = NO;
				NSArray	*files = [self imagesArray: item preferredObject:oFirstForFirst];
				if( [files count] > 1)
				{
					if( [[files objectAtIndex: 0] valueForKey:@"series"] == [[files objectAtIndex: 1] valueForKey:@"series"]) imageLevel = YES;
				}
				
				if( imageLevel == NO)
				{
					for( NSManagedObject *obj in files)
					{
						NSImage *thumbnail = [[[NSImage alloc] initWithData: [obj valueForKeyPath:@"series.thumbnail"]] autorelease];
	//					NSImage *thumbnail = decompressJPEG2000( [[obj valueForKeyPath:@"series.thumbnail"] bytes], [[obj valueForKeyPath:@"series.thumbnail"] length]);
						if( thumbnail == nil) thumbnail = notFoundImage;
						
						[previewPixThumbnails addObject: thumbnail];
					}
				}
				else
				{
					for( unsigned int i = 0; i < [files count];i++) [previewPixThumbnails addObject: notFoundImage];
				}
				
				[[self managedObjectContext] unlock];
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: files, @"files", [files valueForKey:@"completePath"], @"filesPaths",[NSNumber numberWithBool: imageLevel], @"imageLevel", previewPixThumbnails, @"previewPixThumbnails", previewPix, @"previewPix", nil];
				[NSThread detachNewThreadSelector: @selector( matrixLoadIcons:) toTarget: self withObject: dict];
				
				if( previousItem == item)
					[oMatrix selectCellWithTag: cellId];
			}
			
			if( previousItem != item)
			{
				[previousItem release];
				previousItem = [item retain];
			}
			
			[self resetROIsAndKeysButton];
		}
		else
		{
			[oMatrix selectCellWithTag: 0];
			[self matrixInit: 0];
			
			[previousItem release];
			previousItem = nil;
			
			ROIsAndKeyImagesButtonAvailable = NO;
		}
		
	}
	@catch (NSException * e)
	{ NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
}

- (void) refreshMatrix:(id) sender
{
	[previousItem release];
	previousItem = nil;	// This will force the matrix update
	
	BOOL firstResponderMatrix = NO;
	
	if( [[self window] firstResponder] == oMatrix)
	{
		[[self window] makeFirstResponder: databaseOutline];
		firstResponderMatrix = YES;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: nil];
	
	[imageView display];
	
	if( firstResponderMatrix)
		[[self window] makeFirstResponder: oMatrix];
}

- (void) mergeSeriesExecute:(NSArray*) seriesArray
{
	NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Merge Series", nil), NSLocalizedString(@"Are you sure you want to merge the selected series? It cannot be cancelled.\r\rWARNING! If you merge multiple patients, the Patient Name and ID will be identical.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	
	if( result == NSAlertDefaultReturn)
	{
		NSManagedObjectContext	*context = self.managedObjectContext;

		[context retain];
		[context lock];
		
		if( [seriesArray count])
		{
			// The destination series
			NSManagedObject	*destSeries = [seriesArray objectAtIndex: 0];
			
			for( NSInteger x = 0; x < [seriesArray count] ; x++)
			{
				NSManagedObject	*series = [seriesArray objectAtIndex: x];
				
				if( [[series valueForKey:@"type"] isEqualToString: @"Series"] == NO)
					series = [[series valueForKey:@"series"] anyObject];
				
				if( [[series valueForKey:@"type"] isEqualToString: @"Series"])
				{
					NSManagedObject *image = [[series valueForKey: @"images"] anyObject];
				
					if( [[image valueForKey:@"extension"] isEqualToString:@"dcm"])
						destSeries = series;
				}
			}
			
			if( [[destSeries valueForKey:@"type"] isEqualToString: @"Series"] == NO) destSeries = [destSeries valueForKey:@"Series"];
			
			NSLog(@"MERGING SERIES: %@", destSeries);
			DicomStudy *study = [destSeries valueForKey:@"study"];
			
			for( NSManagedObject *series in seriesArray)
			{
				if( series != destSeries)
				{
					if( [[series valueForKey:@"type"] isEqualToString:@"Series"])
					{
						NSArray *images = [[series valueForKey: @"images"] allObjects];
				
						for( id i in images)
							[i setValue: destSeries forKey: @"series"];
						
						[context deleteObject: series];
					}
				}
			}
			
			[destSeries setValue:[NSNumber numberWithInt:0] forKey:@"numberOfImages"];
			
			[_database save:NULL];
			
			[self outlineViewRefresh];
			
			[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: study]] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			
			[self refreshMatrix: self];
		}
		
		[context unlock];
		[context release];
	}
}

- (IBAction) mergeSeries:(id) sender
{
	NSArray				*cells = [oMatrix selectedCells];
	NSMutableArray		*seriesArray = [NSMutableArray array];
	
	for( NSCell *cell in cells)
	{
		if( [cell isEnabled] == YES)
		{
			NSManagedObject	*series = [matrixViewArray objectAtIndex: [cell tag]];
		
			[seriesArray addObject: series];
		}
	}
	
	[self mergeSeriesExecute: seriesArray];
}

- (IBAction) unifyStudies:(id) sender
{
	NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Unify Patient Identity", nil), NSLocalizedString(@"Are you sure you want to unify the patient identity of the selected studies? It cannot be cancelled. (The DICOM files will not be modified, only the DB fields.)\r\rWARNING! The Patient Name and ID will be identical for all these studies to the last selected study.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	
	if( result == NSAlertDefaultReturn)
	{
		NSManagedObjectContext	*context = self.managedObjectContext;
		
		[context retain];
		[context lock];
		
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		NSManagedObject	*destStudy = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
		
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
		
		NSLog(@"UNIFY STUDIES: %@", destStudy);
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++)
		{
			NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*study = [databaseOutline itemAtRow: row];
			
			if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
			
			if( study != destStudy)
			{
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
				{
					[study setValue: [destStudy valueForKey:@"patientID"] forKey: @"patientID"];
					[study setValue: [destStudy valueForKey:@"patientUID"]  forKey: @"patientUID"];
					[study setValue: [destStudy valueForKey:@"name"]  forKey: @"name"];
				}
			}
		}
		
		[_database save:NULL];
		
		[self outlineViewRefresh];
		
		[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: destStudy]] byExtendingSelection: NO];
		[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		
		[self refreshMatrix: self];
		
		[context unlock];
		[context release];
	}
}

- (IBAction) mergeStudies:(id) sender
{
	// Is it only series??
	NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
	BOOL	onlySeries = YES;
	NSMutableArray	*seriesArray = [NSMutableArray array];
	
	for( NSInteger x = 0; x < [selectedRows count] ; x++)
	{
		NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
		NSManagedObject	*series = [databaseOutline itemAtRow: row];
		if( [[series valueForKey:@"type"] isEqualToString: @"Series"] == NO) onlySeries = NO;
		
		[seriesArray addObject: series];
	}
	
	if( onlySeries)
	{
		[self mergeSeriesExecute: seriesArray];
		return;
	}
	
	NSString *nameAndStudy = [[databaseOutline itemAtRow: [databaseOutline selectedRow]] valueForKey: @"name"];
	nameAndStudy = [nameAndStudy stringByAppendingFormat:@"-%@", [[databaseOutline itemAtRow: [databaseOutline selectedRow]] valueForKey: @"studyName"]];
	
	NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Merge Studies", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to merge the selected studies to %@. It cannot be cancelled.\r\rWARNING! If you merge multiple different patients, the Patient Name and ID will be identical.", nil), nameAndStudy], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	
	if( result == NSAlertDefaultReturn)
	{
		NSManagedObjectContext	*context = self.managedObjectContext;
		
		[context retain];
		[context lock];
		
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		// The destination study : prefer DICOM study
		NSManagedObject	*destStudy = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
		
		if( [[[[[[destStudy valueForKey:@"series"] anyObject] valueForKey: @"images"] anyObject] valueForKey:@"extension"] isEqualToString:@"dcm"] == NO)
		{
			for( NSInteger x = 0; x < [selectedRows count] ; x++)
			{
				NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
				
				NSManagedObject	*study = [databaseOutline itemAtRow: row];
				
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
				
				NSManagedObject *image = [[[[study valueForKey:@"series"] anyObject] valueForKey: @"images"] anyObject];
				
				if( [[image valueForKey:@"extension"] isEqualToString:@"dcm"])
					destStudy = study;
			}
		}
		
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO)
			destStudy = [destStudy valueForKey:@"study"];
		
		NSLog(@"MERGING STUDIES: %@", destStudy);
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++)
		{
			NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*study = [databaseOutline itemAtRow: row];
			
			if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
			
			if( study != destStudy)
			{
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
				{
					NSArray *series = [[study valueForKey: @"series"] allObjects];
					
					for( id s in series)
						[s setValue: destStudy forKey: @"study"];
					
					[context deleteObject: study];
				}
			}
		}
		
		[destStudy setValue:[NSNumber numberWithInt:0] forKey:@"numberOfImages"];
		
		[_database save:NULL];
		
		[self outlineViewRefresh];
		
		[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: destStudy]] byExtendingSelection: NO];
		[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		
		[self refreshMatrix: self];
		
		[context unlock];
		[context release];
	}
}

- (void) proceedDeleteObjects: (NSArray*) objectsToDelete
{
	NSManagedObjectContext *context = self.managedObjectContext;
	NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
	NSMutableArray *seriesArray = [NSMutableArray array], *studiesArray = [NSMutableArray array];
	
	[reportFilesToCheck removeAllObjects];
	
	[context lock];
	
	@try
	{
		NSManagedObject	*study = nil, *series = nil;
		
		NSLog(@"objects to delete : %d", [objectsToDelete count]);
		
		for ( NSManagedObject *obj in objectsToDelete)
		{
			if( [obj valueForKey:@"series"] != series)
			{
				// ********* SERIES
				
				series = [obj valueForKey:@"series"];
				
				if([seriesArray containsObject: series] == NO)
				{
					if( series)
						[seriesArray addObject: series];
					
					// Is a viewer containing this series opened? -> close it
					for( ViewerController *vc in viewersList)
					{
						if( series == [[[vc fileList] objectAtIndex: 0] valueForKey:@"series"])
							[[vc window] close];
					}
				}
				
				// ********* STUDY
				
				if( [series valueForKey:@"study"] != study)
				{
					study = [series valueForKey:@"study"];
					
					if([studiesArray containsObject: study] == NO)
					{
						if( study)
							[studiesArray addObject: study];
						
						// Is a viewer containing this series opened? -> close it
						for( ViewerController *vc in viewersList)
						{
							if( study == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
								[vc buildMatrixPreview];
						}
					}
				}
			}
			
			[context deleteObject: obj];
		}
	}
	@catch ( NSException *e)
	{
		NSLog( @"******** proceedDeleteObjects exception : %@", e);
		[AppController printStackTrace: e];
	}
	
	WaitRendering *wait = nil;
	
	if( [NSThread isMainThread])
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
	[wait showWindow:self];
	
	@try
	{
		[context save: nil];
	}
	@catch( NSException *e)
	{	NSLog( @"context save: nil: %@", e); [AppController printStackTrace: e];}
	
	@try
	{
		// Remove series without images !
		for( NSManagedObject *series in seriesArray)
		{
			@try
			{
				if( [series isDeleted] == NO && [series isFault] == NO && [[series valueForKey:@"images"] count] == 0)
				{
					[context deleteObject: series];
				}
				else if( [series isDeleted] == NO && [series isFault] == NO)
				{
					[series setValue: [NSNumber numberWithInt:0] forKey:@"numberOfImages"];
					[series setValue: nil forKey:@"thumbnail"];	
				}
			}
			@catch( NSException *e)
			{
				NSLog( @"context deleteObject: series: %@", e);
				[AppController printStackTrace: e];
			}
		}
		
		@try
		{	
			[context save: nil];
		}
		@catch( NSException *e)
		{	NSLog( @"context save: nil: %@", e); [AppController printStackTrace: e];}
			
		// Remove studies without series !
		for( NSManagedObject *study in studiesArray)
		{
			@try
			{
				if( [study isDeleted] == NO && [study isFault] == NO && [[study valueForKey:@"imageSeries"] count] == 0)
				{
					NSLog( @"Delete Study: %@ - %@", [study valueForKey:@"name"], [study valueForKey:@"patientID"]);
					
					[context deleteObject: study];
				}
				else if( [study isDeleted] == NO && [study isFault] == NO)
				{
					[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
				}
			}
			@catch( NSException *e)
			{	NSLog( @"context deleteObject: study: %@", e); [AppController printStackTrace: e];}
		}
		
		[previousItem release];
		previousItem = nil;
		
		[self saveDatabase];
		
		[self outlineViewRefresh];
		[self refreshAlbums];
	}
	
	@catch( NSException *ne)
	{
		NSLog( @"Exception during delItem");
		NSLog( @"%@", [ne description]);
		[AppController printStackTrace: ne];
	}
	
	[wait close];
	[wait release];
		
	[context unlock];
}

- (void) delObjects:(NSMutableArray*) objectsToDelete
{
	NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
	int result;
	NSMutableArray *studiesArray = [NSMutableArray array] , *seriesArray = [NSMutableArray array];
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	if( [databaseOutline selectedRow] >= 0)
	{
		[context lock];
		// Are some images locked?
		NSArray	*lockedImages = [objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"series.study.lockedStudy == YES"]];
		
		if( [lockedImages count] == [objectsToDelete count] && [lockedImages count] > 0)
		{
			NSRunAlertPanel( NSLocalizedString(@"Locked Studies", nil),  NSLocalizedString(@"These images are stored in locked studies. First, unlock these studies to delete them.", nil), nil, nil, nil);
		}
		else
		{
			BOOL cancelled = NO;
			
			if( [lockedImages count])
			{
				[objectsToDelete removeObjectsInArray: lockedImages];
				
				NSRunInformationalAlertPanel(NSLocalizedString(@"Locked Studies", nil), NSLocalizedString(@"Some images are stored in locked studies. Only unlocked images will be deleted.", nil), NSLocalizedString(@"OK",nil), nil, nil);
			}
			
			// Are some images in albums?
			if( albumTable.selectedRow == 0)
			{
				@try
				{
					NSArray	*albumedImages = [objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"series.study.albums.@count > 0"]];
					
					if( [albumedImages count])
					{
						result = NSRunInformationalAlertPanel(NSLocalizedString(@"Images in Albums", nil), NSLocalizedString(@"Some or all of these images are stored in albums. Do you really want to delete these images, stored in albums?\r\rDelete all images or only those not stored in an album?", nil), NSLocalizedString(@"All",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Only if not stored in an album",nil));
						
						if( result == NSAlertOtherReturn)
						{
							[objectsToDelete removeObjectsInArray: albumedImages];
						}
						
						if( result == NSAlertAlternateReturn)
							cancelled = YES;
					}
				}
				
				@catch (NSException *e)
				{
					NSLog(@"series.study.albums.@count exception: %@", e);
					[AppController printStackTrace: e];
				}
			}
			
			if( cancelled == NO)
			{
				NSLog( @"locked images: %d", [lockedImages count]);
				
				// Try to find images that aren't stored in the local database
				
				NSMutableArray	*nonLocalImagesPath = [NSMutableArray array];
				
				WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing Delete...", nil)];
				[wait showWindow:self];
				
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
				
				[wait close];
				[wait release];
				
				NSLog(@"non-local images : %d", [nonLocalImagesPath count]);
				
				if( [nonLocalImagesPath  count] > 0)
				{
					result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", nil), NSLocalizedString(@"Some of the selected images are not stored in the Database folder. Do you want to only remove the links of these images from the database or also delete the original files?", nil), NSLocalizedString(@"Remove the links",nil),  NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Delete the files",nil));
				}
				else result = NSAlertDefaultReturn;
				
				wait = [[WaitRendering alloc] init: NSLocalizedString(@"Deleting...", nil)];
				[wait showWindow:self];
				
				@try
				{
					if( result == NSAlertAlternateReturn)
					{
						NSLog( @"Cancel");
					}
					else
					{
						if( result == NSAlertDefaultReturn || result == NSAlertOtherReturn)
							[self proceedDeleteObjects: objectsToDelete];
						
						if( result == NSAlertOtherReturn)
						{
							for( NSString *path in nonLocalImagesPath)
							{
								[[NSFileManager defaultManager] removeFileAtPath: path handler:nil];
								
								if( [[path pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
								{
									[[NSFileManager defaultManager] removeFileAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
								}
								
								NSString *currentDirectory = [[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
								NSArray *dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:currentDirectory];
								
								//Is this directory empty?? If yes, delete it!
								
								if( [dirContent count] == 0) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
								if( [dirContent count] == 1)
								{
									if( [[[dirContent objectAtIndex: 0] uppercaseString] hasSuffix:@".DS_STORE"]) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
								}
							}
						}
						
						[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [selectedRows firstIndex]] byExtendingSelection:NO];
					}
						
					}
				@catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
				[wait close];
				[wait release];
			}
		}
		
		[context unlock];
	}
}

- (IBAction)delItem: (id)sender
{
	NSInteger				result;
	NSManagedObjectContext	*context = self.managedObjectContext;
	BOOL					matrixThumbnails = YES;
	int						animState = [animationCheck state];
	
//	if( DICOMDIRCDMODE)
//	{
//		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}*/
	
	[self checkResponder];
	
	if( sender == nil)
	{
		matrixThumbnails = NO;
	}
	else
	{
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
			matrixThumbnails = YES;
		
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [databaseOutline menu]) || [[self window] firstResponder] == databaseOutline)
			matrixThumbnails = NO;
	}
	
	NSString *level = nil;
	
	if( matrixThumbnails)
		level = NSLocalizedString( @"Selected Thumbnails", nil);
	else
		level = NSLocalizedString( @"Selected Lines", nil);
	
	[animationCheck setState: NSOffState];
	
	[context retain];
	[context lock];
	
	NSArray *albumArray = self.albumArray;
	
	if( albumTable.selectedRow > 0 && matrixThumbnails == NO)
	{
		NSManagedObject	*album = [albumArray objectAtIndex: albumTable.selectedRow];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == NO)
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", nil), [NSString stringWithFormat: NSLocalizedString(@"Do you want to only remove the selected images from the current album or delete them from the database? (%@)", nil), level], NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Remove from current album",nil));
		else
		{
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to delete the selected images? (%@)", nil), level], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}
	}
	else
	{
		result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to delete the selected images? (%@)", nil), level], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	}
	
	if( result == NSAlertOtherReturn)	// REMOVE FROM CURRENT ALBUMS, BUT DONT DELETE IT FROM THE DATABASE
	{
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			NSMutableArray *studiesToRemove = [NSMutableArray array];
			DicomAlbum* album = [albumArray objectAtIndex: albumTable.selectedRow];
			
			for( NSInteger x = 0; x < [selectedRows count] ; x++)
			{
				NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
				
				DicomStudy *study = [databaseOutline itemAtRow: row];
				
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
				{
					[studiesToRemove addObject: study];
					
					NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];
					[studies removeObject: study];
					[study archiveAnnotationsAsDICOMSR];
				}
			}
			
			if (![_database isLocal])
			{
				// Do it remotely
				[(RemoteDicomDatabase*)_database removeStudies:studiesToRemove fromAlbum:album];
			}
			
			[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [selectedRows firstIndex]] byExtendingSelection:NO];
		}
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
		[wait showWindow:self];
		
		@try
		{
			[_database save:NULL];
			
			[self outlineViewRefresh];
			[self refreshAlbums];
		}
		@catch( NSException *ne)
		{
			NSLog( @"Exception Updating database...");
			NSLog( @"%@", [ne description]);
			[AppController printStackTrace: ne];
		}
		
		[wait close];
		[wait release];
	}
	else if (![_database isLocal])
	{
		NSRunAlertPanel( NSLocalizedString(@"Bonjour Database", nil),  NSLocalizedString(@"You cannot modify a Bonjour shared database.", nil), nil, nil, nil);
		
		[context release];
		[context unlock];
		
		[animationCheck setState: animState];
		
		return;
	}
	
	if( result == NSAlertDefaultReturn)	// REMOVE AND DELETE IT FROM THE DATABASE
	{
		NSMutableArray *objectsToDelete = [NSMutableArray array];
		
		if( matrixThumbnails)
		{
			[self filesForDatabaseMatrixSelection: objectsToDelete onlyImages: NO];
		}
		else
		{
			[self filesForDatabaseOutlineSelection: objectsToDelete onlyImages: NO];
		}
		
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			[self delObjects: objectsToDelete];
		}
		
		#ifndef OSIRIX_LIGHT
		if( [QueryController currentQueryController])
			[[QueryController currentQueryController] refresh: self];
		else if( [QueryController currentAutoQueryController])
			[[QueryController currentAutoQueryController] refresh: self];
		#endif
	}
	
	[context unlock];
	[context release];
	
	[animationCheck setState: animState];
	
	self.databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
	
	[self refreshMatrix: self];
	
#ifndef OSIRIX_LIGHT
	[[QueryController currentQueryController] executeRefresh: self];
	[[QueryController currentAutoQueryController] executeRefresh: self];
#endif
}

- (void)buildColumnsMenu
{
	[columnsMenu release];
	columnsMenu = [[NSMenu alloc] initWithTitle:@"columns"];
	
	
	NSArray	*columnIdentifiers = [[databaseOutline tableColumns] valueForKey:@"identifier"];
	
	for( NSTableColumn *col in [databaseOutline allColumns])
	{
		NSMenuItem	*item = [columnsMenu insertItemWithTitle:[[col headerCell] stringValue] action:@selector(columnsMenuAction:) keyEquivalent:@"" atIndex: [columnsMenu numberOfItems]];
		[item setRepresentedObject: [col identifier]];
		
		NSInteger index = [columnIdentifiers indexOfObject: [col identifier]];
		
		if( [[col identifier] isEqualToString:@"name"])
		{
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"HIDEPATIENTNAME"])
				[item setState: NSOffState];
			else
				[item setState: NSOnState];
		}
		else
		{
			if( index != NSNotFound) [item setState: NSOnState];
			else [item setState: NSOffState];
		}
	}
	
	[[databaseOutline headerView] setMenu: columnsMenu];
}

- (void) columnsMenuAction: (id)sender
{
	[sender setState: ![sender state]];
	
	if( [[sender representedObject] isEqualToString:@"name"]) [[NSUserDefaults standardUserDefaults] setBool:![sender state] forKey:@"HIDEPATIENTNAME"];
	else
	{
		NSArray				*titleArray = [[columnsMenu itemArray] valueForKey:@"title"];
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithCapacity: 0];
		
		for( int i = 0; i < [titleArray count]; i++)
  		{
  			NSString*	key = [titleArray objectAtIndex: i];
  
  			if( [key length] > 0)
  				[dict setValue: [NSNumber numberWithInt: [[[columnsMenu itemArray] objectAtIndex: i] state]] forKey: key];
  		}
		
		[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"COLUMNSDATABASE"];
		
		[[AppController sharedAppController] runPreferencesUpdateCheck: nil];
	}
}

- (void)refreshColumns
{
	NSDictionary	*columnsDatabase	= [[NSUserDefaults standardUserDefaults] objectForKey: @"COLUMNSDATABASE"];
	NSEnumerator	*enumerator			= [columnsDatabase keyEnumerator];
	NSString		*key;
	
	[_database lock];
	@try {
		while( key = [enumerator nextObject])
		{
			NSInteger index = [[[[databaseOutline allColumns] valueForKey:@"headerCell"] valueForKey:@"title"] indexOfObject: key];
			
			if( index != NSNotFound)
			{
				NSString	*identifier = [[[databaseOutline allColumns] objectAtIndex: index] identifier];
				
				if( [databaseOutline isColumnWithIdentifierVisible: identifier] != [[columnsDatabase valueForKey: key] intValue])
				{
					if( [[columnsDatabase valueForKey: key] intValue] == NO && [databaseOutline columnWithIdentifier: identifier] == [databaseOutline selectedColumn])
						[databaseOutline selectColumn: 0 byExtendingSelection: NO];
				
					[databaseOutline setColumnWithIdentifier:identifier visible: [[columnsDatabase valueForKey: key] intValue]];
					
					if( [[columnsDatabase valueForKey: key] intValue] == NSOnState)
					{
						[databaseOutline scrollColumnToVisible: [databaseOutline columnWithIdentifier: identifier]];
					}
				}
			}
		}
		
		[self buildColumnsMenu];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_database unlock];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (_database == nil) return nil;
		
	id returnVal = nil;
	
	[_database lock];
	
	@try
	{
		if( item == nil)
		{
			returnVal = [outlineViewArray objectAtIndex: index];
		}
		else
		{
			returnVal = [[self childrenArray: item] objectAtIndex: index];
		}
	}
	@catch (NSException * e)
	{
		NSLog( @"%@", [e description]);
		[AppController printStackTrace: e];
	}

	[_database unlock];
	
	return returnVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL returnVal = NO;
	
	[_database lock];
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = NO;
	else returnVal = YES;
	
	[_database unlock];
	
	return returnVal;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( _database == nil) return 0;
	
	int returnVal = 0;
	
	[_database lock];
	
	if (!item)
	{
		returnVal = [outlineViewArray count];
	}
	else
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Image"]) returnVal = 0;
		if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = [[item valueForKey:@"noFiles"] intValue];
		//if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"series"] count];
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"imageSeries"] count];
	}
	
	[_database unlock];
	
	return returnVal;
}

- (id)intOutlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// *********************************************
	//	PLUGINS
	// *********************************************
	
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 3 && [[tableColumn identifier] isEqualToString:@"reportURL"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSBundle *plugin = [[PluginManager reportPlugins] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
			
			if( plugin)
			{
				PluginFilter* filter = [[plugin principalClass] filter];
				return [filter reportDateForStudy: item];
				//return [filter report: item action: @"dateReport"];
			}
			return nil;
		}
		return nil;
	}
	else if( [[tableColumn identifier] isEqualToString:@"reportURL"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			if( [item valueForKey:@"reportURL"])
			{
				DicomStudy *study = (DicomStudy*) item;
				DicomImage *report = [study reportImage];
				
				if( [report valueForKey: @"date"])
					return [report valueForKey: @"date"];
				else
					return nil;
			}
			else return nil;
		}
		else return nil;
	}
	
	if( [[tableColumn identifier] isEqualToString:@"stateText"])
	{
		if( [[item valueForKey:@"stateText"] intValue] == 0) return nil;
		else return [item valueForKey:@"stateText"];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"lockedStudy"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"] == NO) return nil;
	}
	
	if( [[tableColumn identifier] isEqualToString:@"modality"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
			return [item valueForKey:@"modalities"];
		else
			return [item valueForKey:@"modality"];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"name"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSString	*name;
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"HIDEPATIENTNAME"])
				name = [NSString stringWithString: NSLocalizedString( @"Name hidden", nil)];
			else
				name = [item valueForKey:@"name"];
			
			//return [NSString stringWithFormat:@"%@ (%d series)", name, [[item valueForKey:@"series"] count]];
			if ([item isFault])
				return nil;
			return [NSString stringWithFormat: NSLocalizedString( @"%@ (%d series)", @"patient name, number of series: for example, helmut la moumoute (4 series)"), name, [[item valueForKey:@"imageSeries"] count]];
		}
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"] == NO)
	{
		if( [[tableColumn identifier] isEqualToString:@"dateOfBirth"])			return @"";
		if( [[tableColumn identifier] isEqualToString:@"referringPhysician"])	return @"";
		if( [[tableColumn identifier] isEqualToString:@"performingPhysician"])	return @"";
		if( [[tableColumn identifier] isEqualToString:@"institutionName"])		return @"";
		if( [[tableColumn identifier] isEqualToString:@"studyName"])			return [item valueForKey:@"seriesDescription"];
		if( [[tableColumn identifier] isEqualToString:@"patientID"])			return @"";
		if( [[tableColumn identifier] isEqualToString:@"yearOld"])				return @"";
		if( [[tableColumn identifier] isEqualToString:@"accessionNumber"])		return @"";
	}
	
	return [item valueForKey: [tableColumn identifier]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if( _database == nil) return nil;
	
	[_database lock];
	
	id returnVal = nil;
	
	@try
	{
		if( [item isFault] == NO)
			returnVal = [self intOutlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
	}
	
	@catch (NSException * e)
	{
		NSLog( @"%@", [e description]);
	}

	[_database unlock];
	
	return returnVal;
}

- (void) setDatabaseValue:(id) object item:(id) item forKey:(NSString*) key
{
	DatabaseIsEdited = NO;
	
	[_database lock];
	
	if (![_database isLocal])
		[(RemoteDicomDatabase*)_database object:item setValue:object forKey:key];
	
	if( [key isEqualToString:@"stateText"])
	{
		if( [object intValue] >= 0) [item setValue:object forKey:key];
	}
	else if( [key isEqualToString:@"lockedStudy"])
	{
		if( [[item valueForKey:@"type"] isEqualToString:@"Study"]) [item setValue:[NSNumber numberWithBool: [object intValue]] forKey: @"lockedStudy"];
	}
	else [item setValue:object forKey:key];
	
	[refreshTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.5]];
	
	[_database unlock];
	
	[_database save:NULL];
	
	#ifndef OSIRIX_LIGHT
	if( [QueryController currentQueryController])
		[[QueryController currentQueryController] refresh: self];
	else if( [QueryController currentAutoQueryController])
		[[QueryController currentAutoQueryController] refresh: self];
	#endif
	
	[databaseOutline reloadData];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	[self setDatabaseValue: object item: item forKey: [tableColumn identifier]];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self outlineViewRefresh];
	
	if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
	{
		[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
	}
	
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}



-(NSString*)outlineView:(NSOutlineView*)outlineView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
	if ([item isFault])
		return nil;
	
	if ([[tableColumn identifier] isEqualToString:@"name"]) {
		NSDate* now = [NSDate date];
		NSDate* today0 = [NSDate dateWithTimeIntervalSinceReferenceDate:floor([now timeIntervalSinceReferenceDate]/(60*60*24))*(60*60*24)];
		NSDate* acqDate = [item valueForKey:@"date"];
		NSTimeInterval acqInterval = [now timeIntervalSinceDate:acqDate];
		NSTimeInterval addInterval = [now timeIntervalSinceDate:[item valueForKey:@"dateAdded"]];
		
		if (acqInterval <= 60*10) return NSLocalizedString(@"Acquired within the last 10 minutes", nil);
		else if (acqInterval <= 60*60) return NSLocalizedString(@"Acquired within the last hour", nil);
		else if (acqInterval <= 4*60*60) return NSLocalizedString(@"Acquired within the last 4 hours", nil); 
		else if ([acqDate timeIntervalSinceDate:today0] >= 0) return NSLocalizedString(@"Acquired today", nil); // today
		else if (addInterval <= 60) return NSLocalizedString(@"Added within the last 60 seconds", nil);
	}
	
	return nil;
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (id)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
	if( [item isFault])
		return;
	
	[cell setHighlighted: NO];
	
	if( [cell isKindOfClass: [ImageAndTextCell class]])
	{
		[(ImageAndTextCell*) cell setImage: nil];
		[(ImageAndTextCell*) cell setLastImage: nil];
	}
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context lock];
	
	@try 
	{
		if ([[item valueForKey:@"type"] isEqualToString: @"Study"])
		{
			if( [[tableColumn identifier] isEqualToString:@"lockedStudy"]) [cell setTransparent: NO];
			
			if( originalOutlineViewArray)
			{
				if( [originalOutlineViewArray containsObject: item]) [cell setFont: [NSFont boldSystemFontOfSize:12]];
				else [cell setFont: [NSFont systemFontOfSize:12]];
			}
			else [cell setFont: [NSFont boldSystemFontOfSize:12]];
			
			if( [[tableColumn identifier] isEqualToString:@"name"])
			{
				BOOL	icon = NO;
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"] && [[self window] firstResponder] == outlineView)
				{
					if( [[[previousItem entity] name] isEqual:@"Study"])
					{
						NSString *uid = [item valueForKey: @"patientUID"];
						
						if( item != previousItem && [uid length] > 1 && [uid isEqualToString: [previousItem valueForKey: @"patientUID"]])
						{
							[cell setDrawsBackground: YES];
							[cell setBackgroundColor: [NSColor lightGrayColor]];	//secondarySelectedControlColor]];
						}
						else
							[cell setDrawsBackground: NO];
					}
					else
						[cell setDrawsBackground: NO];
				}
				else
					[cell setDrawsBackground: NO];
				
				if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -24*60*60)	// 24 hours
				{
					NSCalendarDate	*now = [NSCalendarDate calendarDate];
					NSCalendarDate	*start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
					NSDate			*today = [NSDate dateWithTimeIntervalSinceNow: [start timeIntervalSinceDate: now]];
					
					icon = YES;
					if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -60*10) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Realised1.tif"]];													// 10 min
					else if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -60*60) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Realised2.tif"]];												// 1 hour
					else if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -4*60*60) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Realised3.tif"]];											// 4 hours
					else if( [[item valueForKey:@"date"] timeIntervalSinceReferenceDate] > [today timeIntervalSinceReferenceDate]) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Realised4.tif"]];	// today
					else icon = NO;
				}
				
				if( icon == NO)
				{
					if( [[item valueForKey:@"dateAdded"] timeIntervalSinceNow] > -60) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Receiving.tif"]];
				}
				
				NSManagedObject *studySelected = [[[item entity] name] isEqual:@"Study"] ? item : [item valueForKey:@"study"];
			}
			
			if( [[tableColumn identifier] isEqualToString: @"reportURL"])
			{
				if( (![_database isLocal] && [item valueForKey:@"reportURL"] != nil) || [[NSFileManager defaultManager] fileExistsAtPath: [item valueForKey:@"reportURL"]] == YES)
				{
					NSImage	*reportIcon = [NSImage imageNamed:@"Report.icns"];
					[reportIcon setSize: NSMakeSize(16, 16)];
					
					[(ImageAndTextCell*) cell setImage: reportIcon];
				}
				else if( [[item valueForKey: @"reportURL"] hasPrefix: @"http://"] || [[item valueForKey: @"reportURL"] hasPrefix: @"https://"])
				{
					NSImage	*reportIcon = [[NSWorkspace sharedWorkspace] iconForFileType: @"download"];
					
					if( reportIcon == nil) reportIcon = [NSImage imageNamed:@"Report.icns"];
					
					[reportIcon setSize: NSMakeSize(16, 16)];
					
					[(ImageAndTextCell*) cell setImage: reportIcon];
				}
				else
				{
					if( [item valueForKey:@"reportURL"] != nil)
						[item setValue: nil forKey: @"reportURL"];
				}
			}
		}
		else
		{
			if( [[tableColumn identifier] isEqualToString:@"lockedStudy"]) [cell setTransparent: YES];
			
			[cell setFont: [NSFont boldSystemFontOfSize:10]];
		}
		[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	[context unlock];
	
	// doesn't work with NSPopupButtonCell	
	//	if ([outlineView isEqual:databaseOutline])
	//	{
	//		//[cell setBackgroundColor:[NSColor lightGrayColor]];
	//		//	[cell setDrawsBackground: YES];
	//		
	//		//[[tableColumn dataCell] setBackgroundColor:[NSColor greenColor]];
	//		[[tableColumn dataCell] setDrawsBackground: NO];
	//	}
}

//- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
//{
//	if ([outlineView isEqual:databaseOutline])
//	{
//		[cell setBackgroundColor:[NSColor greenColor]];
//		//	[cell setDrawsBackground: YES];
//		
//		//[[tableColumn dataCell] setBackgroundColor:[NSColor greenColor]];
//		//[[tableColumn dataCell] setDrawsBackground: NO];
//	}
//}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn
{

}

- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	NSArray *r = nil;
	
	if( avoidRecursive == NO)
	{
		avoidRecursive = YES;
		
		@try 
		{
			if( [[[dropDestination path] lastPathComponent] isEqualToString:@".Trash"])
			{
				[self delItem:  nil];
			}
			else
			{
				NSMutableArray *dicomFiles2Export = [NSMutableArray array];
				NSMutableArray *filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: NO];
				
				NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: [dropDestination path], @"location", filesToExport, @"filesToExport", dicomFiles2Export, @"dicomFiles2Export", nil];
		
				NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( exportDICOMFileInt: ) object: d] autorelease];
				t.name = NSLocalizedString( @"Exporting...", nil);
				t.supportsCancel = YES;
				t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [filesToExport count]];
				
				[[ThreadsManager defaultManager] addThreadAndStart: t];
				
				NSTimeInterval fourSeconds = [NSDate timeIntervalSinceReferenceDate] + 4.0;
				while( [[d objectForKey: @"result"] count] == 0 && [NSDate timeIntervalSinceReferenceDate] < fourSeconds)
					[NSThread sleepForTimeInterval: 0.1];
				
				@synchronized( d)
				{
					if( [[d objectForKey: @"result"] count])
						r = [NSArray arrayWithArray: [d objectForKey: @"result"]];
				}
			}
		}
		@catch (NSException * e)
		{
		}
		avoidRecursive = NO;
	}
	
	if( r == nil)
		r = [NSArray array];
	
	return r;
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)pbItems toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes: [NSArray arrayWithObjects: @"BrowserController.database.context.XIDs", O2AlbumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType, nil] owner:self];
	
	[pboard setPropertyList:nil forType:O2AlbumDragType];
	
    [pboard setPropertyList:[NSArray arrayWithObject:@"dcm"] forType:NSFilesPromisePboardType];
	
	[pboard setPropertyList:[NSPropertyListSerialization dataFromPropertyList:[pbItems valueForKey:@"XID"] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL] forType:@"BrowserController.database.context.XIDs"];
	
//	[draggedItems release];
//	draggedItems = [pbItems retain];
	return YES;
}

/*- (void) setDraggedItems:(NSArray*) pbItems
{
	[draggedItems release];
	draggedItems = [pbItems retain];
}*/

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	[_database lock];
	
	if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
	{
		for( id item in [self databaseSelection])
			[databaseOutline collapseItem: item]; 
	}
	
	NSManagedObject	*object = [[notification userInfo] objectForKey:@"NSObject"];
	
	[object setValue:[NSNumber numberWithBool: NO] forKey:@"expanded"];
	
	NSManagedObject	*image = nil;
	
	if( [matrixViewArray count] > 0)
	{
		image = [matrixViewArray objectAtIndex: 0];
		if( [[image valueForKey:@"type"] isEqualToString:@"Image"]) [self findAndSelectFile: nil image: image shouldExpand :NO];
	}
	
	[_database unlock];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
	[_database lock];
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
	{
		for( id item in [self databaseSelection])
			[databaseOutline expandItem: item];
	}
	
	NSManagedObject	*object = [[notification userInfo] objectForKey:@"NSObject"];
	[object setValue:[NSNumber numberWithBool: YES] forKey:@"expanded"];
	
	[_database unlock];
}

- (BOOL)isUsingExternalViewer: (NSManagedObject*) item
{
	BOOL r = NO;
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		[_database lock];
		
		NSArray *images = [self childrenArray: item onlyImages: NO];
		
		DicomImage *im = nil;
		
		if( [images count] > [animationSlider intValue])
			im = [images objectAtIndex: [animationSlider intValue]];
		else
			im = [[item valueForKey: @"images"] anyObject];
		
//		// ZIP files with XML descriptor
//		if([[item valueForKey:@"noFiles"] intValue] == 1)
//		{
//			if([[im valueForKey:@"fileType"] isEqualToString:@"XMLDESCRIPTOR"] )
//			{
//				NSLog(@"******** XMLDESCRIPTOR ********");
//				
//				NSSavePanel *savePanel = [NSSavePanel savePanel];
//				[savePanel setCanSelectHiddenExtension:YES];
//				[savePanel setRequiredFileType:@"zip"];
//				
//				NSString *filePath = [im valueForKey: @"completePath"];
//				NSString *fileName = [filePath lastPathComponent];
//				
//				if([savePanel runModalForDirectory:nil file:fileName] == NSFileHandlingPanelOKButton)
//				{
//					// write the file to the specified location on the disk
//					NSFileManager *fileManager = [NSFileManager defaultManager];
//					// zip
//					NSString *newFilePath = [[savePanel URL] path];
//					if ([fileManager fileExistsAtPath:filePath])
//						[fileManager copyPath:filePath toPath:newFilePath handler:nil];
//					// xml
//					NSMutableString *xmlFilePath = [NSMutableString stringWithCapacity:[filePath length]];
//					[xmlFilePath appendString: [filePath substringToIndex:[filePath length]-[[filePath pathExtension] length]]];
//					[xmlFilePath appendString: @"xml"];
//					NSLog(@"xmlFilePath : %@", xmlFilePath);
//					
//					NSMutableString *newXmlFilePath = [NSMutableString stringWithCapacity:[newFilePath length]];
//					[newXmlFilePath appendString: [newFilePath substringToIndex:[newFilePath length]-[[newFilePath pathExtension] length]]];
//					[newXmlFilePath appendString: @"xml"];
//					NSLog(@"newXmlFilePath : %@", newXmlFilePath);
//					
//					if ([fileManager fileExistsAtPath:xmlFilePath])
//						[fileManager copyPath:xmlFilePath toPath:newXmlFilePath handler:nil];
//				}
//				
//				r = YES;
//			}
//		}
		
		if ([[im valueForKey:@"fileType"] isEqualToString:@"DICOMMPEG2"])
		{
			NSString *filePath = [im valueForKey: @"completePath"];
			
			if( [[NSWorkspace sharedWorkspace] openFile: filePath withApplication:@"VLC" andDeactivate: YES] == NO)
			{
				NSRunAlertPanel( NSLocalizedString( @"MPEG-2 File", nil), NSLocalizedString( @"MPEG-2 DICOM files require the VLC application. Available for free here: http://www.videolan.org/vlc/", nil), nil, nil, nil);
			}
			[NSThread sleepForTimeInterval: 1];
			
			r = YES;
		}
		
		#ifndef OSIRIX_LIGHT
		
		if( ([[[im valueForKey:@"modality"] lowercaseString] isEqualToString:@"pdf"] || [DCMAbstractSyntaxUID isPDF: [im valueForKeyPath: @"series.seriesSOPClassUID"]] || [DCMAbstractSyntaxUID isStructuredReport: [im valueForKeyPath: @"series.seriesSOPClassUID"]]) && [[NSUserDefaults standardUserDefaults] boolForKey: @"openPDFwithPreview"])
		{
			NSString *path = nil;
			
			if( [DCMAbstractSyntaxUID isPDF: [im valueForKeyPath: @"series.seriesSOPClassUID"]])
			{
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [im valueForKey: @"completePath"] decodingPixelData:NO];
				
				if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
				{
					NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
					
					NSString *filename = [dcmObject attributeValueWithName:@"DocumentTitle"];
					if( [filename length] <= 0)
						filename = @"PDFFile.pdf";
					
					if( [[[filename pathExtension] lowercaseString] isEqualToString: @"pdf"] == NO)
						filename = [filename stringByAppendingPathExtension: @"pdf"];
					
					path = [[[self documentsDirectory] stringByAppendingPathComponent: @"/TEMP.noindex/"] stringByAppendingPathComponent: filename];
					[[NSFileManager defaultManager] removeItemAtPath: path error: nil];
					[pdfData writeToFile: path atomically: YES];
				}
			}
			else if( [DCMAbstractSyntaxUID isStructuredReport: [im valueForKeyPath: @"series.seriesSOPClassUID"]])
			{
				if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
					[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
				
				NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[im valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"xml"];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
				{
					NSTask *aTask = [[[NSTask alloc] init] autorelease];		
					[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
					[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
					[aTask setArguments: [NSArray arrayWithObjects: @"+X1", [im valueForKey: @"completePath"], htmlpath, nil]];		
					[aTask launch];
					[aTask waitUntilExit];		
					[aTask interrupt];
				}
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
				{
					NSTask *aTask = [[[NSTask alloc] init] autorelease];
					[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
					[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
					[aTask launch];
					[aTask waitUntilExit];		
					[aTask interrupt];
				}
				
				path = [htmlpath stringByAppendingPathExtension: @"pdf"];
			}
			else path = [im valueForKey: @"completePath"];
			
			if( path && [[NSWorkspace sharedWorkspace] openFile: path withApplication: nil andDeactivate: YES] == NO)
				r = NO;
			else
				r = YES;
			
			[NSThread sleepForTimeInterval: 1];
		}
		
		#endif
		
		[_database unlock];
	}
	
	return r;
}

- (void) databaseOpenStudy: (NSManagedObject*) item
{	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		if( [self isUsingExternalViewer: item] == NO)
		{
			// DICOM & others
			[self viewerDICOMInt :NO  dcmFile: [NSArray arrayWithObject:item] viewer:nil];
			
		}
	}
	else	// STUDY - Hanging Protocols - Windows State
	{
		// files with XML descriptor, do nothing
		
		[_database lock];
		
		NSSet *imagesSet = [item valueForKeyPath: @"series.images.fileType"];
		NSArray *imagesArray = [[[imagesSet allObjects] objectAtIndex:0] allObjects];
		
		[_database unlock];
		
		if([imagesArray count] == 1)
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
				return;
		}
		
		BOOL windowsStateApplied = NO;
		
		if( [item valueForKey:@"windowsState"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"])
		{
			NSArray *viewers = [NSPropertyListSerialization propertyListFromData: [item valueForKey:@"windowsState"] mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
			
			NSMutableArray *seriesToOpen =  [NSMutableArray array];
			NSMutableArray *viewersToLoad = [NSMutableArray array];
			
			[ViewerController closeAllWindows];
			
			for( NSDictionary *dict in viewers)
			{
				NSString *studyUID = [dict valueForKey:@"studyInstanceUID"];
				NSString *seriesUID = [dict valueForKey:@"seriesInstanceUID"];
				
				NSArray	 *series4D = [seriesUID componentsSeparatedByString:@"\\**\\"];
				// Find the corresponding study & 4D series
				
				@try
				{
					NSError					*error = nil;
					NSManagedObjectContext	*context = self.managedObjectContext;
					
					[context lock];
					
					NSMutableArray *seriesForThisViewer =  nil;
					
					@try 
					{
						for( NSString *curSeriesUID in series4D)
						{
							NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
							[request setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Series"]];
							[request setPredicate: [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", studyUID, curSeriesUID]];
							
							NSArray	*seriesArray = [context executeFetchRequest:request error:&error];
							
							if( [seriesArray count] != 1)
							{
								NSLog( @"****** number of series corresponding to these UID (%@) is not unique?: %d", curSeriesUID, [seriesArray count]);
							}
							else
							{
								if( [[[seriesArray objectAtIndex: 0] valueForKeyPath:@"study.patientUID"] isEqualToString: [item valueForKey: @"patientUID"]])
								{
									if( seriesForThisViewer == nil)
									{
										seriesForThisViewer = [NSMutableArray array];
										
										[seriesToOpen addObject: seriesForThisViewer];
										[viewersToLoad addObject: dict];
									}
									
									[seriesForThisViewer addObject: [seriesArray objectAtIndex: 0]];
								}
								else
									NSLog(@"%@ versus %@", [[seriesArray objectAtIndex: 0] valueForKeyPath:@"study.patientUID"], [item valueForKey: @"patientUID"]);
							}
						}
					}
					@catch (NSException * e) 
					{
						NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
						[AppController printStackTrace: e];
					}
					
					[context unlock];
				}
				@catch (NSException *e)
				{
					NSLog( @"**** databaseOpenStudy exception: %@", e);
					[AppController printStackTrace: e];
				}
			}
			
			if( [seriesToOpen count] > 0 && [viewersToLoad count] == [seriesToOpen count])
			{
				if( waitOpeningWindow == nil) waitOpeningWindow  = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
				[waitOpeningWindow showWindow:self];
				
				[AppController sharedAppController].checkAllWindowsAreVisibleIsOff = YES;
				
				for( int i = 0 ; i < [seriesToOpen count]; i++)
				{
					NSMutableArray * toOpenArray = [NSMutableArray array];
					
					NSDictionary *dict = [viewersToLoad objectAtIndex: i];
					
					for( NSManagedObject* curFile in [seriesToOpen objectAtIndex: i])
					{
						NSArray *loadList = [self childrenArray: curFile];
						if( loadList) [toOpenArray addObject: loadList];
					}
					
					if( [[dict valueForKey: @"4DData"] boolValue])
						[self processOpenViewerDICOMFromArray: toOpenArray movie: YES viewer: nil];
					else
						[self processOpenViewerDICOMFromArray: toOpenArray movie: NO viewer: nil];
				}
				
				NSArray	*displayedViewers = [ViewerController getDisplayed2DViewers];
				
				for( int i = 0 ; i < [viewersToLoad count]; i++)
				{
					NSDictionary		*dict = [viewersToLoad objectAtIndex: i];
					
					if( i < [displayedViewers count])
					{
						ViewerController	*v = [displayedViewers objectAtIndex: i];
						
						NSRect r;
						NSScanner* s = [NSScanner scannerWithString: [dict valueForKey:@"window position"]];
						
						float a;
						[s scanFloat: &a];	r.origin.x = a;		[s scanFloat: &a];	r.origin.y = a;
						[s scanFloat: &a];	r.size.width = a;	[s scanFloat: &a];	r.size.height = a;
						
						int index = [[dict valueForKey:@"index"] intValue];
						int rows = [[dict valueForKey:@"rows"] intValue];
						int columns = [[dict valueForKey:@"columns"] intValue];
						float wl = [[dict valueForKey:@"wl"] floatValue];
						float ww = [[dict valueForKey:@"ww"] floatValue];
						float x = [[dict valueForKey:@"x"] floatValue];
						float y = [[dict valueForKey:@"y"] floatValue];
						float rotation = [[dict valueForKey:@"rotation"] floatValue];
						float scale = [[dict valueForKey:@"scale"] floatValue];
						
						[v setWindowFrame: r showWindow: NO];
						[v setImageRows: rows columns: columns];
						
						[v setImageIndex: index];
						
						if( [[[v imageView] curDCM] SUVConverted]) [v setWL: wl*[v factorPET2SUV] WW: ww*[v factorPET2SUV]];
						else [v setWL: wl WW: ww];
						
						[v setScaleValue: scale];
						[v setRotation: rotation];
						[v setOrigin: NSMakePoint( x, y)];
					}
				}
				
				[AppController sharedAppController].checkAllWindowsAreVisibleIsOff = NO;
				[[AppController sharedAppController] checkAllWindowsAreVisible: self];
				
				if( [displayedViewers count] > 0)
					[[[displayedViewers objectAtIndex: 0] window] makeKeyAndOrderFront: self];
				
				[waitOpeningWindow close];
				[waitOpeningWindow release];
				waitOpeningWindow = nil;
				
				windowsStateApplied = YES;
			}
		}
		
		if( windowsStateApplied == NO)
		{
			[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:[item valueForKey:@"modality"] description:[item valueForKey:@"studyName"]];
			
			NSDictionary *currentHangingProtocol = [[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol];
			
			NSMutableArray *children = [NSMutableArray arrayWithArray: [self childrenArray: item]];
			
			//Remove the series that are already displayed
			int alreadyDisplayed = 0;
			for( DicomSeries *s in [ViewerController getDisplayedSeries])
			{
				for( int e = 0; e < [children count]; e++)
				{
					if( [[s valueForKey: @"seriesInstanceUID"] isEqualToString: [[children objectAtIndex: e] valueForKey: @"seriesInstanceUID"]])
						alreadyDisplayed++;
				}
			}
			
			if( alreadyDisplayed == 0)
			{
				if ([[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue] >= [[item valueForKey:@"imageSeries"] count])
				{
					[self viewerDICOMInt :NO  dcmFile:[self childrenArray: item] viewer:nil];
				}
				else
				{
					unsigned count = [[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue];
					if( count < 1) count = 1;
					
					NSMutableArray *children =  [NSMutableArray array];
					
					for ( int i = 0; i < count; i++)
						[children addObject:[[self childrenArray: item] objectAtIndex:i]];
					
					[self viewerDICOMInt :NO  dcmFile:children viewer:nil];
				}
			}
			else
			{
				for( ViewerController *v in [ViewerController getDisplayed2DViewers])
					[[v window] makeKeyAndOrderFront: self];
			}
		}
	}
}

- (IBAction) databasePressed:(id)sender
{
	[self resetROIsAndKeysButton];
}

- (IBAction)databaseDoublePressed:(id)sender
{
	if( [sender clickedRow] != -1)
	{			
		NSManagedObject		*item;
		
		if( [databaseOutline clickedRow] != -1) item = [databaseOutline itemAtRow:[databaseOutline clickedRow]];
		else item = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		[self databaseOpenStudy: item];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString:@"comment"] || [[tableColumn identifier] isEqualToString:@"comment2"] || [[tableColumn identifier] isEqualToString:@"comment3"] || [[tableColumn identifier] isEqualToString:@"comment4"])
	{
		DatabaseIsEdited = YES;
		return YES;
	}
	else
	{
		DatabaseIsEdited = NO;
		return NO;
	}
}

- (IBAction) displayImagesOfSeries: (id) sender
{
	NSMutableArray *dicomFiles = [NSMutableArray array];
	NSMutableArray *files;
	
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		if( [matrixViewArray count] > [[oMatrix selectedCell] tag])
		{
			NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]];
			
			if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
			{ 
				files = [self filesForDatabaseMatrixSelection: dicomFiles];
				
				if( [databaseOutline isItemExpanded: [curObj valueForKeyPath:@"series.study"]])
					[databaseOutline collapseItem: [curObj valueForKeyPath:@"series.study"]];
				
				//	[self findAndSelectFile:nil image:[dicomFiles objectAtIndex: 0] shouldExpand:NO];
			}
			else
			{
				files = [self filesForDatabaseMatrixSelection: dicomFiles];
				[self findAndSelectFile:nil image:[dicomFiles objectAtIndex: 0] shouldExpand:YES];
			}
		}
	}
}

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand
{
	return [self findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: NO];
}

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection
{
	if( curImage == nil)
	{
		BOOL isDirectory;
		
		if([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])     // A directory
		{
			DicomFile			*curFile = nil;
			
			@try
			{
				if( isDirectory == YES)
				{
					BOOL		go = YES;
					NSString    *pathname;
					NSString    *aPath = path;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					while( (pathname = [enumer nextObject]) && go == YES)
					{
						NSString * itemPath = [aPath stringByAppendingPathComponent:pathname];
						id fileType = [[enumer fileAttributes] objectForKey:NSFileType];
						
						if ([fileType isEqual:NSFileTypeRegular])
						{
							
							if( [[itemPath lastPathComponent] characterAtIndex: 0] != '.')
								curFile = [[DicomFile alloc] init: itemPath];
							
							if( curFile) go = NO;
						}
					}
				}
				else curFile = [[DicomFile alloc] init: path];
			}
			@catch ( NSException *e)
			{
				NSLog( @"findAndSelectFile exception: %@", e);
				[AppController printStackTrace: e];
				curFile = nil;
			}
			
			//We have first to find the image object from the path
			
			NSError				*error = nil;
			long				index;
			
			if( curFile)
			{
				NSManagedObject	*study, *seriesTable;
				NSManagedObjectContext *context = self.managedObjectContext;
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				[context lock];
				
				@try 
				{
					error = nil;
					NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
					
					index = [[studiesArray  valueForKey:@"studyInstanceUID"] indexOfObject:[curFile elementForKey: @"studyID"]];
					if( index != NSNotFound)
					{
						study = [studiesArray objectAtIndex: index];
						NSArray		*seriesArray = [[study valueForKey:@"series"] allObjects];
						index = [[seriesArray valueForKey:@"seriesInstanceUID"] indexOfObject:[curFile elementForKey: @"seriesID"]];
						if( index != NSNotFound)
						{
							seriesTable = [seriesArray objectAtIndex: index];
							NSArray		*imagesArray = [[seriesTable valueForKey:@"images"] allObjects] ;
							index = [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curFile elementForKey: @"SOPUID"]];
							if( index != NSNotFound) curImage = [imagesArray objectAtIndex: index];
						}
					}
				}
				@catch (NSException * e) 
				{
					NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
					[AppController printStackTrace: e];
				}
				
				[curFile release];
				
				[context unlock];
			}
		}
	}
	
	NSManagedObject	*study = [curImage valueForKeyPath:@"series.study"];
	
	NSInteger index = [outlineViewArray indexOfObject: study];
	
	if( index != NSNotFound)
	{
		if( expand || [databaseOutline isItemExpanded: study])
		{
			[databaseOutline expandItem: study];
			
			if( [databaseOutline rowForItem: [curImage valueForKey:@"series"]] != [databaseOutline selectedRow])
			{
				[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: [curImage valueForKey:@"series"]]] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		else
		{
			if( [databaseOutline rowForItem: study] != [databaseOutline selectedRow])
			{
				[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: study]] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		
		// Now... try to find the series in the matrix
		if( [databaseOutline isItemExpanded: study] == NO)
		{
			NSArray	*seriesArray = [self childrenArray: study];
			
			[self outlineViewSelectionDidChange: nil];
			
			[self matrixDisplayIcons: self];	//Display the icons, if necessary
			
			NSInteger seriesPosition = [seriesArray indexOfObject: [curImage valueForKey:@"series"]];
			
			if( seriesPosition != NSNotFound)
			{
				if( [[oMatrix selectedCell] tag] != seriesPosition)
				{
					// Select the right thumbnail matrix
					[oMatrix selectCellAtRow: seriesPosition/COLUMN column: seriesPosition%COLUMN];
					[self matrixPressed: oMatrix];
				}
				
				return YES;
			}
		}
		else return YES;
	}
	
	return NO;
}

- (NSInteger) displayStudy: (DicomStudy*) study object:(NSManagedObject*) element command:(NSString*) execute
{
	NSInteger index = [outlineViewArray indexOfObject: study];
	
	if( index == NSNotFound)	// Try again with all studies displayed. This study has to be here ! We found it in the DB
	{
		[self showEntireDatabase];
		index = [outlineViewArray indexOfObject: study];
	}
	
	if( index != NSNotFound)
	{
		if( [databaseOutline rowForItem: study] != [databaseOutline selectedRow])
		{
			[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: study]] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		}
		
		if( [execute isEqualToString: @"Open"])
		{
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			BOOL found = NO;
			
			if( [[element valueForKey: @"type"] isEqualToString: @"Study"])
			{
				// Is a viewer containing this study opened? -> select it
				for( ViewerController *vc in viewersList)
				{
					if(element == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
					{
						[[vc window] makeKeyAndOrderFront: self];
						found = YES;
					}
				}
			}
			else if( [[element valueForKey: @"type"] isEqualToString: @"Series"])
			{
				// Is a viewer containing this series opened? -> select it
				for( ViewerController *vc in viewersList)
				{
					if(element == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series"])
					{
						[[vc window] makeKeyAndOrderFront: self];
						found = YES;
					}
				}
			}
			else if( [[element valueForKey: @"type"] isEqualToString: @"Image"])
			{
				// Is a viewer containing this image opened? -> select it
				for( ViewerController *vc in viewersList)
				{
					for( NSManagedObject *im in [vc fileList])
					{
						if( element == im)
						{
							[[vc window] makeKeyAndOrderFront: self];
							found = YES;
							
							[vc setImage: im];
						}
					}
				}
			}
			
			if( found == NO)
			{
				if( [[element valueForKey: @"type"] isEqualToString: @"Series"])
				{
					[self findAndSelectFile:nil image: [[element valueForKey: @"images"] anyObject] shouldExpand:NO];
					[self databaseOpenStudy: element];
				}
				else if( [[element valueForKey: @"type"] isEqualToString: @"Image"])
				{
					[self findAndSelectFile:nil image: element shouldExpand:NO];
					[self databaseOpenStudy: [element valueForKey: @"series"]];
					
					// Is a viewer containing this image opened? -> select it
					for( ViewerController *vc in [ViewerController getDisplayed2DViewers])
					{
						for( NSManagedObject *im in [vc fileList])
						{
							if( element == im)
							{
								[[vc window] makeKeyAndOrderFront: self];
								found = YES;
								
								[vc setImage: im];
							}
						}
					}
				}
				else [browserWindow viewerDICOM: self]; // Study
			}
		}
	}
	
	return index;
}

- (int) findObject:(NSString*) request table:(NSString*) table execute: (NSString*) execute elements:(NSString**) elements
{
	if( elements)
		*elements = nil;
			
	if( !request) return -32;
	if( !table) return -33;
	if( !execute) return -34;
	
	NSError				*error = nil;
	
	NSManagedObject			*element = nil;
	NSArray					*array = nil;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[self checkIncoming: self];
	// We cannot call checkIncomingNow, because we currently have the lock for context, and IF a separate checkIncoming thread has started, he is currently waiting for the context lock, and we will wait for the checkIncomingLock...
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey: table]];
	[dbRequest setPredicate: [NSPredicate predicateWithFormat: request]];
	
	[context retain];
	[context lock];
	
	@try
	{
		error = nil;
		array = [context executeFetchRequest:dbRequest error:&error];
		
		if( error)
		{
			[context unlock];
			[context release];
			
			return [error code];
		}
		
		if( [array count])
		{
			element = [array objectAtIndex: 0];	// We select the first object
			
			if( [execute isEqualToString: @"Delete"] == NO)
			{
				NSManagedObject	*study = nil;
				
				if( [[element valueForKey: @"type"] isEqualToString: @"Image"]) study = [element valueForKeyPath: @"series.study"];
				else if( [[element valueForKey: @"type"] isEqualToString: @"Series"]) study = [element valueForKey: @"study"];
				else if( [[element valueForKey: @"type"] isEqualToString: @"Study"]) study = element;
				
				if( [[study valueForKey: @"imageSeries"] count] == 0)
					element = nil;
			}
		}
	}
	
	@catch (NSException * e)
	{
		NSLog( @"******* BrowserController findObject Exception");
		NSLog( @"%@", [e description]);
		[AppController printStackTrace: e];
	}

	[context unlock];
	[context release];
	
	
	if( element)
	{		
		if( [execute isEqualToString: @"Select"] || [execute isEqualToString: @"Open"])		// These 2 functions apply only to the first found element
		{
			DicomStudy *study = nil;
			
			if( [[element valueForKey: @"type"] isEqualToString: @"Image"]) study = [element valueForKeyPath: @"series.study"];
			else if( [[element valueForKey: @"type"] isEqualToString: @"Series"]) study = [element valueForKey: @"study"];
			else if( [[element valueForKey: @"type"] isEqualToString: @"Study"]) study = (DicomStudy*)element;
			else NSLog( @"DB selectObject : Unknown table");
			
			NSInteger index = [self displayStudy: study object: element command: execute];
			
			if( index == NSNotFound)
				return -1;
		}
		
		// Generate an answer containing the elements
		NSMutableString *a = [NSMutableString stringWithString: @"<value><array><data>"];
		
		for( NSManagedObject *obj in array)
		{
			NSMutableString *c = [NSMutableString stringWithString: @"<value><struct>"];
			
			NSArray *allKeys = [[[[self.managedObjectModel entitiesByName] objectForKey: table] attributesByName] allKeys];
			
			for (NSString *keyname in allKeys)
			{
				@try
				{
					if( [[obj valueForKey: keyname] isKindOfClass:[NSString class]] ||
					[[obj valueForKey: keyname] isKindOfClass:[NSDate class]] ||
					[[obj valueForKey: keyname] isKindOfClass:[NSNumber class]])
					{
						NSString *value = [[obj valueForKey: keyname] description];
						value = [(NSString*)CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)value, NULL)  autorelease];
						[c appendFormat: @"<member><name>%@</name><value>%@</value></member>", keyname, value];
					}
				}
				
				@catch (NSException * e)
				{
					NSLog( @"findObject exception: %@", e);
					[AppController printStackTrace: e];
				}
			}
			
			[c appendString: @"</struct></value>"];
			
			[a appendString: c];
		}
		
		[a appendString: @"</data></array></value>"];
		
		if( elements)
			*elements = a;
		
		if( [execute isEqualToString: @"Delete"])
		{
			[context retain];
			[context lock];
			
			@try
			{
				
				for( NSManagedObject *curElement in array)
				{
					NSManagedObject	*study = nil;
					
					if( [[curElement valueForKey: @"type"] isEqualToString: @"Image"]) study = [curElement valueForKeyPath: @"series.study"];
					else if( [[curElement valueForKey: @"type"] isEqualToString: @"Series"]) study = [curElement valueForKey: @"study"];
					else if( [[curElement valueForKey: @"type"] isEqualToString: @"Study"]) study = curElement;
					else NSLog( @"DB selectObject : Unknown table");
					
					if( study)
						[context deleteObject: study];
				}
				
				[_database save:NULL];
			}
			
			@catch (NSException * e)
			{
				NSLog( @"******* BrowserController findObject Exception - Delete");
				NSLog( @"%@", [e description]);
				[AppController printStackTrace: e];
			}
			
			[context unlock];
			[context release];
		}
		
		return 0;
	}
	
	return -1;
}

-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	BOOL					applyToAllViewers = [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"];
	BOOL					copyPatientsSettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDisplayImagesOfSamePatient"];
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"onlyDisplayImagesOfSamePatient"];
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		applyToAllViewers = !applyToAllViewers;
	
	if(  applyToAllViewers)
	{
		// If multiple viewer are opened, apply it to the entire list
		for( NSWindow *win in winList)
		{
			if( [[win windowController] isKindOfClass:[ViewerController class]] && [[win windowController] windowWillClose] == NO)
			{
				[viewersList addObject: [win windowController]];
			}
		}
		viewer = [viewersList objectAtIndex: 0];
		curImage = [[viewer fileList] objectAtIndex: 0];
	}
	else
	{
		[viewersList addObject: viewer];
	}
	
	NSManagedObject		*study = [curImage valueForKeyPath:@"series.study"];
	
	NSInteger index = [outlineViewArray indexOfObject: study];
	
	if( index != NSNotFound)
	{
		BOOL				found = NO;
		NSManagedObject		*nextStudy;
		do
		{
			index += direction;
			if( index >= 0 && index < [outlineViewArray count])
			{
				nextStudy = [outlineViewArray objectAtIndex: index];
				
				if( [[nextStudy valueForKey:@"patientID"] isEqualToString:[study valueForKey:@"patientID"]] == NO || [[nextStudy valueForKey:@"name"] isEqualToString:[study valueForKey:@"name"]] == NO)
				{
					found = YES;
				}
			}
			else
			{
				NSBeep();
				return;
			}
			
		}while( found == NO);
		
		NSManagedObject	*series =  [[self childrenArray:nextStudy] objectAtIndex:0];
		
		[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
		
		[self loadNextSeries:[[self childrenArray: series] objectAtIndex: 0] :0 :viewer :YES keyImagesOnly:keyImages];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDidLoadNewObjectNotification object:study userInfo:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool: copyPatientsSettings forKey: @"onlyDisplayImagesOfSamePatient"];
}

-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	NSManagedObjectModel	*model = self.managedObjectModel;
	NSManagedObjectContext	*context = self.managedObjectContext;
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	BOOL					applyToAllViewers = [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"];
	
	int previousNumberOf2DViewers = [[ViewerController getDisplayed2DViewers] count];
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		applyToAllViewers = !applyToAllViewers;
	
	if( [viewer FullScreenON]) [viewersList addObject: viewer];
	else
	{
		// If multiple viewer are opened, apply it to the entire list
		if( applyToAllViewers)
		{
			for( NSWindow *win in winList)
			{
				if( [[win windowController] isKindOfClass:[ViewerController class]] && [[win windowController] windowWillClose] == NO)
					[viewersList addObject: [win windowController]];
			}
			viewer = [viewersList objectAtIndex: 0];
			curImage = [[viewer fileList] objectAtIndex: 0];
		}
		else
		{
			[viewersList addObject: viewer];
		}
	}
	
	// FIND ALL STUDIES of this patient
	NSManagedObject		*study = [curImage valueForKeyPath:@"series.study"];
	NSManagedObject		*currentSeries = [curImage valueForKey:@"series"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(patientID == %@)", [study valueForKey:@"patientID"]];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: predicate];
	
	[context retain];
	[context lock];
	
	@try
	{
		NSError	*error = nil;
		NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
		
		if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
		{
			NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
			NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
			[sort release];
			
			studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
			
			NSArray	*seriesArray = [NSArray array];
			
			for(NSManagedObject	*curStudy in studiesArray)
				seriesArray = [seriesArray arrayByAddingObjectsFromArray: [self childrenArray: curStudy]];
			
			NSInteger index = [seriesArray indexOfObject: currentSeries];
			
			if( index != NSNotFound)
			{
				if( direction == 0)	// Called from loadNextPatient
				{
					if( firstViewer == NO) direction = 1;
				}
				
				index += direction*[viewersList count];
				if( index < 0 && index + [viewersList count] == 0)
					NSBeep();
				else 
				{
					if( index < 0) index = 0;
					if( index < [seriesArray count])
					{
						if( index + [viewersList count] > [seriesArray count])
						{
							index = [seriesArray count] - [viewersList count];
							if( index < 0) index = 0;
						}
						
						for( ViewerController *vc in viewersList)
						{
							if( index >= 0 && index < [seriesArray count])
							{
								[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [seriesArray objectAtIndex: index]]] movie: NO viewer:vc keyImagesOnly: keyImages];
							}
							else
							{
								// Close the viewer
								[[vc window] performClose: self];
							}
							
							index++;
						}
					}
					else NSBeep();
				}
			}
		}
	}
	@catch ( NSException *e)
	{
		NSLog( @"***** loadNextSeries exception : %@", e);
		[AppController printStackTrace: e];
	}
		
	[context unlock];
	[context release];
	
	[viewersList release];
	
	if( previousNumberOf2DViewers != [[ViewerController getDisplayed2DViewers] count])
	{
		if( delayedTileWindows)
		{
			delayedTileWindows = NO;
			[NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
		}
		
		[[AppController sharedAppController] tileWindows: nil];
	}
}

- (ViewerController*) loadSeries:(NSManagedObject *) series :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	return [self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages tryToFlipData: YES];
}

- (NSString*) exportDBListOnlySelected:(BOOL) onlySelected
{
	NSIndexSet *rowIndex;
	
	if( onlySelected) rowIndex = [databaseOutline selectedRowIndexes];
	else rowIndex = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, [databaseOutline numberOfRows])];
	
	NSMutableString	*string = [NSMutableString string];
	NSNumber *row;
	NSArray	*columns = [[databaseOutline tableColumns] valueForKey:@"identifier"];
	NSArray	*descriptions = [[databaseOutline tableColumns] valueForKey:@"headerCell"];
	int r;
	
	for( NSInteger x = 0; x < rowIndex.count; x++)
	{
		if( x == 0) r = rowIndex.firstIndex;
		else r = [rowIndex indexGreaterThanIndex: r];
		
		NSManagedObject   *aFile = [databaseOutline itemAtRow: r];
		
		if( aFile && [[[aFile entity] name] isEqual:@"Study"])
		{
			if( [string length])
				[string appendString: @"\r"];
			else
			{
				int i = 0;
				for( NSCell *s in descriptions)
				{
					[string appendString: [s stringValue]];
					i++;
					if( i !=  [columns count])
						[string appendFormat: @"%c", NSTabCharacter];
				}
				[string appendString: @"\r"];
			}
			
			int i = 0;
			for( NSString *identifier in columns)
			{
				if( [[aFile valueForKey: identifier] description])
					[string appendString: [[aFile valueForKey: identifier] description]];
				i++;
				if( i !=  [columns count])
					[string appendFormat: @"%c", NSTabCharacter];
			}
		}	
	}
	
	return string;
}

#ifndef OSIRIX_LIGHT

- (IBAction) pasteImageForSourceFile: (NSString*) sourceFile
{
	// If the clipboard contains an image -> generate a SC DICOM file corresponding to the selected patient
	if( [[NSPasteboard generalPasteboard] dataForType: NSTIFFPboardType])
	{
		NSImage *image = [[[NSImage alloc] initWithData: [[NSPasteboard generalPasteboard] dataForType: NSTIFFPboardType]] autorelease];
		
		if( sourceFile)
		{
			if( [[NSFileManager defaultManager] fileExistsAtPath: sourceFile] == NO)
				sourceFile = nil;
		}
		
		if( sourceFile == nil)
		{
			NSMutableArray *images = [NSMutableArray array];
			
			if( [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: images];
			else [self filesForDatabaseOutlineSelection: images];
			
			if( [images count])
				sourceFile = [[images objectAtIndex: 0] valueForKey:@"completePath"];
		}
		
		DICOMExport *e = [[[DICOMExport alloc] init] autorelease];
		
		[e setSeriesDescription: [NSString stringWithFormat: NSLocalizedString( @"Clipboard - %@", nil), [BrowserController DateTimeWithSecondsFormat: [NSDate date]]]];
		[e setSeriesNumber: 66532 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
		
		NSBitmapImageRep *rep = (NSBitmapImageRep*) [image bestRepresentationForDevice:nil];
		
		if ([rep isMemberOfClass: [NSBitmapImageRep class]])
		{
			[e setSourceFile: sourceFile];
			
			int bpp = [rep bitsPerPixel] / [rep samplesPerPixel];
			int spp = [rep samplesPerPixel];
			
			if( [rep bitsPerPixel] == 32 && spp == 3)
			{
				bpp = 8;
				spp = 4;
			}
			
			[e setPixelData: [rep bitmapData] samplesPerPixel: spp bitsPerSample: bpp width:[rep pixelsWide] height:[rep pixelsHigh]];
			
			if( [rep isPlanar])
				NSLog( @"********** BrowserController Paste : Planar is not yet supported....");
			else
			{
				NSString *f = [e writeDCMFile: nil];
				
				if( f)
				{
					[BrowserController addFiles: [NSArray arrayWithObject: f]
									  toContext: [self managedObjectContext]
									 toDatabase: self
									  onlyDICOM: YES 
							   notifyAddedFiles: YES
							parseExistingObject: YES
									   dbFolder: [self documentsDirectory]
							  generatedByOsiriX: YES];
				
					return;
				}
			}
		}
	}
	
	NSBeep();
}


- (IBAction) paste: (id)sender
{
	[self pasteImageForSourceFile: nil];
}
	 
#endif

- (IBAction) copy: (id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	NSString *string;
	
	if( [[databaseOutline selectedRowIndexes] count] == 1)
		string = [[databaseOutline itemAtRow: [databaseOutline selectedRowIndexes].firstIndex] valueForKey: @"name"];
	else 
		string = [self exportDBListOnlySelected: YES];
	
	[pb setString: string forType:NSStringPboardType];
}

- (IBAction) saveDBListAs:(id) sender
{
	NSString *list = [self exportDBListOnlySelected: NO];
	
	NSSavePanel *sPanel	= [NSSavePanel savePanel];
		
	[sPanel setRequiredFileType:@"txt"];
	
	if ([sPanel runModalForDirectory: nil file:NSLocalizedString(@"OsiriX Database List", nil)] == NSFileHandlingPanelOKButton)
	{
		[list writeToFile: [sPanel filename] atomically: YES];
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Thumbnails Matrix & Preview functions

static BOOL withReset = NO;

- (DCMPix *)previewPix:(int)i
{
	return [previewPix objectAtIndex:i];
}

- (void) initAnimationSlider
{
	BOOL	animate = NO;
	long	noOfImages = 0;
	
	NSButtonCell    *cell = [oMatrix selectedCell];
	
	if( cell)
	{
		if( [cell tag] >= [matrixViewArray count])
		{
			[oMatrix selectCellWithTag: 0];
			cell = [oMatrix selectedCell];
		}
		
		NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		if ([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && 
				 [[[aFile valueForKey:@"images"] allObjects] count] == 1 && 
				 [[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1)
		{
			noOfImages = [[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
			animate = YES;
		}
		else if([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && [[[aFile valueForKey:@"images"] allObjects] count] > 1)
		{
			noOfImages = [[[aFile valueForKey:@"images"] allObjects] count];
			animate = YES;
		}
		else if([[aFile valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSArray *images = [self imagesArray: [matrixViewArray objectAtIndex: [cell tag]]];
			
			if( [images count])
			{
				if( [images count] > 1) noOfImages = [images count];
				else noOfImages = [[[images objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
				
				if( [images count] > 1)
				{
					animate = YES;
				}
				else if( noOfImages > 1)	// It's a multi-frame single image
				{
					animate = YES;
				}
			}
		}
		
		if( animate == NO)
		{
			[animationSlider setEnabled:NO];
			[animationSlider setMaxValue:0];
			[animationSlider setNumberOfTickMarks:1];
			[animationSlider setIntValue:0];
		}
		else if( [animationSlider isEnabled] == NO)
		{
			[animationSlider setEnabled:YES];
			[animationSlider setMaxValue: noOfImages-1];
			[animationSlider setNumberOfTickMarks: noOfImages];
			[animationSlider setIntValue:0];	//noOfImages/2
		}
	}
	else
	{
		[animationSlider setEnabled:NO];
		[animationSlider setMaxValue:0];
		[animationSlider setNumberOfTickMarks:1];
		[animationSlider setIntValue:0];
	}
	
	withReset = YES;
	[self previewSliderAction: animationSlider];
	withReset = NO;
}

- (DCMPix*) getDCMPixFromViewerIfAvailable: (NSString*) pathToFind frameNumber: (int) frameNumber
{
	DCMPix *returnPix = nil;
	
	//Is this image already displayed on the front most 2D viewers? -> take the dcmpix from there
	for( ViewerController *v in [ViewerController get2DViewers])
	{
		if( ![v windowWillClose])
		{
			NSArray *vFileList = nil;
			NSArray *vPixList = nil;
			NSData *volumeData = nil;
			
			@synchronized( [v imageView])
			{
				// We need to temporarly retain all these objects, because this function is called on a separated thread (matrixLoadIcons)
				vFileList = [[v fileList] copy];
				vPixList = [[v pixList] copy];
				volumeData = [[v volumeData] retain];
			}
			
			@try
			{
				NSUInteger i = NSNotFound;
				
				if( frameNumber == 0)
					i = [[vFileList valueForKey: @"completePath"] indexOfObject: pathToFind];
				else
				{
					for( int x = 0 ; x < vFileList.count; x++)
					{
						DicomImage *image = [vFileList objectAtIndex: x];
						
						if( [image.completePath isEqualToString: pathToFind] && [image.frameID intValue] == frameNumber)
						{
							i = x;
							break;
						}
					}
				}
				
				if( i != NSNotFound)
				{
					DCMPix *dcmPix = [vPixList objectAtIndex: i];
					
					[dcmPix.checking lock];
					
					[dcmPix CheckLoad];
					
					if( [dcmPix isLoaded])
					{
						DCMPix *dcmPixCopy = [[vPixList objectAtIndex: i] copy];
						
						float *fImage = (float*) malloc( dcmPix.pheight*dcmPix.pwidth*sizeof( float));
						if( fImage)
						{
							memcpy( fImage, dcmPix.fImage, dcmPix.pheight*dcmPix.pwidth*sizeof( float));
							[dcmPixCopy setfImage: fImage];
							[dcmPixCopy freefImageWhenDone: YES];
						
							returnPix = [dcmPixCopy autorelease];
						}
						else
							[dcmPixCopy release];
					}
					[dcmPix.checking unlock];
				}
			}
			@catch (NSException * e) 
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
				[AppController printStackTrace: e];
			}
			[volumeData release];
			[vFileList release];
			[vPixList release];
		}
	}
	
	return returnPix;
}

- (void) previewSliderAction:(id) sender
{
	BOOL	animate = NO;
	long	noOfImages = 0;
	
    NSButtonCell *cell = [oMatrix selectedCell];
    if( cell && dontUpdatePreviewPane == NO)
	{
		if( [cell isEnabled])
		{
			if( [cell tag] >= [matrixViewArray count]) return;
			
			NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
			if ([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && 
					 [[[aFile valueForKey:@"images"] allObjects] count] == 1 && 
					 [[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1) // multi frame image that is directly selected
			{
				NSManagedObject* image = [[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0];
				
				noOfImages = [[image valueForKey:@"numberOfFrames"] intValue];
				animate = YES;
				
				DCMPix *dcmPix = nil;
				
				//Is this image already displayed on the front most 2D viewers? -> take the dcmpix from there
				dcmPix = [[self getDCMPixFromViewerIfAvailable: [image valueForKey:@"completePath"] frameNumber: [animationSlider intValue]] retain];
				
				if( dcmPix == nil)
					dcmPix = [[DCMPix alloc] initWithPath: [image valueForKey:@"completePath"] :[animationSlider intValue] :noOfImages :nil :[animationSlider intValue] :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj:image];
				
				if( dcmPix)
				{
					float   wl, ww;
					
					[imageView getWLWW:&wl :&ww];
					
					[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
					
					[dcmPix release];
					
					[imageView setIndex:[cell tag]];
				}
			}
			else if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"] || ([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && [[[aFile valueForKey:@"images"] allObjects] count] > 1))
			{
				NSArray *images;
				
				if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
					images = [self imagesArray: [matrixViewArray objectAtIndex: [cell tag]]];
				else
				{
					images = [self imagesArray: aFile];
					if( sender)
						[oMatrix selectCellWithTag: [animationSlider intValue]];
				}
					
				if( [images count])
				{ 
					if( [images count] > 1) noOfImages = [images count];
					else noOfImages = [[[images objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
					
					if( [images count] > 1 || noOfImages == 1)
					{
						animate = YES;
						
						if( [animationSlider intValue] >= [images count]) return;
						
						NSManagedObject *imageObj = [images objectAtIndex: [animationSlider intValue]];
						
						if( [[[imageView curDCM] sourceFile] isEqualToString: [[images objectAtIndex: [animationSlider intValue]] valueForKey:@"completePath"]] == NO || [[imageObj valueForKey: @"frameID"] intValue] != [[[imageView imageObj] valueForKey: @"frameID"] intValue])
						{
							DCMPix *dcmPix = nil;
							
							dcmPix = [[self getDCMPixFromViewerIfAvailable: [imageObj valueForKey:@"completePath"] frameNumber: [[imageObj valueForKey: @"frameID"] intValue]] retain];
							
							if( dcmPix == nil)
								dcmPix = [[DCMPix alloc] initWithPath: [imageObj valueForKey:@"completePath"] :[animationSlider intValue] :[images count] :nil :[[imageObj valueForKey: @"frameID"] intValue] :[[imageObj valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: imageObj];
							
							if( dcmPix)
							{
								float   wl, ww;
								
								[imageView getWLWW:&wl :&ww];
								
								DCMPix *previousDcmPix = [[previewPix objectAtIndex: [cell tag]] retain];	// To allow the cached system in DCMPix to avoid reloading
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
								
								@try
								{
									for( DCMPix *p in previewPix)
									{
										if( p != dcmPix)
										{
											[p kill8bitsImage];
											[p revert: NO];
										}
									}
								}
								@catch (NSException *e) {}
								
								[previousDcmPix release];
							}
						}
					}
					else if( noOfImages > 1)	// It's a multi-frame single image
					{
						animate = YES;
						
						if( [[[imageView curDCM] sourceFile] isEqualToString: [[images objectAtIndex:0] valueForKey:@"completePath"]] == NO
						   || [[imageView curDCM] frameNo] != [animationSlider intValue]
						   || [[imageView curDCM] serieNo] != [[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue])
						{
							DCMPix *dcmPix = nil;
							
							dcmPix = [[self getDCMPixFromViewerIfAvailable: [[images objectAtIndex: 0] valueForKey:@"completePath"] frameNumber: [animationSlider intValue]] retain];
							
							if( dcmPix == nil)
								dcmPix = [[DCMPix alloc] initWithPath: [[images objectAtIndex: 0] valueForKey:@"completePath"] :[animationSlider intValue] :noOfImages :nil :[animationSlider intValue] :[[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj:[images objectAtIndex: 0]];
							
							if( dcmPix)
							{
								float   wl, ww;
								
								[imageView getWLWW:&wl :&ww];
								
								DCMPix *previousDcmPix = [[previewPix objectAtIndex: [cell tag]] retain];	// To allow the cached system in DCMPix to avoid reloading
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
								
								@try
								{
									for( DCMPix *p in previewPix)
									{
										if( p != dcmPix)
										{
											[p kill8bitsImage];
											[p revert: NO];
										}
									}
								}
								@catch (NSException *e) {}
								
								[previousDcmPix release];
							}
						}
					}
				}
			}
		}
    }
}

- (void)previewPerformAnimation: (id)sender
{
	if( [[AppController sharedAppController] isSessionInactive] || waitForRunningProcess)
		return;
	
    // Wait loading all images !!!
	if( _database == nil) return;
//	if( bonjourDownloading) return;
	if( animationCheck.state == NSOffState) return;
	
    if( self.window.isKeyWindow == NO) return;
    if( animationSlider.isEnabled == NO) return;
	
	int	pos = animationSlider.intValue;
	pos++;
	if( pos > animationSlider.maxValue) pos = 0;
	
	[animationSlider setIntValue: pos];
	[self previewSliderAction: nil];
}

- (void)scrollWheel: (NSEvent *)theEvent
{
	float reverseScrollWheel;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Scroll Wheel Reversed"])
		reverseScrollWheel = -1.0;
	else
		reverseScrollWheel = 1.0;
	
	float change = reverseScrollWheel * [theEvent deltaY];
	
	if( [theEvent deltaY] == 0)
		return;
	
	int	pos = [animationSlider intValue];
	
	if( change > 0)
	{
		change = 1;
		pos += change;
	}
	else
	{
		change = -1;
		pos += change;
	}
	
	if( pos > [animationSlider maxValue]) pos = 0;
	if( pos < 0) pos = [animationSlider maxValue];
	
	[animationSlider setIntValue: pos];
	[self previewSliderAction: animationSlider];
}

- (IBAction) matrixPressed: (id)sender
{
    id theCell = [sender selectedCell];
    int index;
    
	[self.window makeFirstResponder: oMatrix];
	
	if( [theCell tag] >= 0)
	{
		NSManagedObject *dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		if( [[dcmFile valueForKey:@"type"] isEqualToString: @"Series"] && [[[dcmFile valueForKey:@"images"] allObjects] count] > 1)
		{
			[animationSlider setIntValue: [theCell tag]];
			[self previewSliderAction: nil];
			
			// ******************************
			
			return;
		}
	}
	
	
	[animationSlider setEnabled:NO];
	[animationSlider setMaxValue:0];
	[animationSlider setNumberOfTickMarks:1];
	[animationSlider setIntValue:0];
	
    if( [theCell tag] >= 0)
	{
		NSManagedObject *dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		if( [[dcmFile valueForKey:@"type"] isEqualToString: @"Study"] == NO)
		{
			index = [theCell tag];
			[imageView setIndex: index];
		}
		
		[self initAnimationSlider];
    }
	
	[self resetROIsAndKeysButton];
}

- (IBAction) matrixDoublePressed:(id)sender
{
    id  theCell = [oMatrix selectedCell];
    
    if( [theCell tag] >= 0)
	{
		[self viewerDICOM: [[oMatrix menu] itemAtIndex:0]];
    }
}

-(void) matrixInit:(long) noOfImages
{	
	setDCMDone = NO;
	loadPreviewIndex = 0;
	
	[previewPix release];
	[previewPixThumbnails release];
	
	previewPix = [[NSMutableArray alloc] initWithCapacity:0];
	previewPixThumbnails = [[NSMutableArray alloc] initWithCapacity:0];
	
	if( COLUMN == 0) NSLog(@"COLUMN = 0, ERROR");
	
	int row = ceil((float) noOfImages/(float) COLUMN);
	
	[oMatrix renewRows:row columns: COLUMN];
	
	for( long i=0; i < row*COLUMN; i++)
	{
		NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
		cell.tag = i;
		[cell setTransparent: YES];
		[cell setEnabled: NO];
		[cell setFont:[NSFont systemFontOfSize:9]];
		cell.title = NSLocalizedString(@"loading...", nil);
		cell.image = nil;
		cell.bezelStyle = NSShadowlessSquareBezelStyle;
	}
	
	for( long i=0; i<noOfImages; i++)
	{
		[[oMatrix cellWithTag: i] setTransparent:NO];
	}
	
	[oMatrix sizeToCells];
	
	[imageView setPixels:nil files:nil rois:nil firstImage:0 level:0 reset:YES];
	
	[self matrixDisplayIcons: self];
}

- (void) matrixNewIcon:(long) index: (NSManagedObject*)curFile
{	
//	if( shouldDie == NO)
	{
		long		i = index;
		
		if( curFile == nil)
		{
			[oMatrix setNeedsDisplay:YES];
			return;
		}
		
		if( i >= [previewPix count]) return;
		if( i >= [previewPixThumbnails count]) return;
		
		NSImage *img = nil;
		
		img = [previewPixThumbnails objectAtIndex: i];
		if( img == nil) NSLog( @"Error: [previewPixThumbnails objectAtIndex: i] == nil");
		
		[_database lock];
		
		@try
		{
			NSString	*modality, *seriesSOPClassUID, *fileType;
			
			if( [[curFile valueForKey:@"type"] isEqualToString:@"Image"])
			{
				modality = [curFile valueForKey: @"modality"];
				seriesSOPClassUID = [curFile valueForKeyPath: @"series.seriesSOPClassUID"];
				fileType = [curFile valueForKey: @"fileType"];
			}
			else	// Series
			{
				seriesSOPClassUID = [curFile valueForKey: @"seriesSOPClassUID"];
				
				DicomImage *im = [[curFile valueForKey:@"images"] anyObject];
				modality = [im valueForKey: @"modality"];
				fileType = [im valueForKey: @"fileType"];
				
				if( img != notFoundImage)
				{
					if( [curFile valueForKey:@"thumbnail"] == nil)
					{
						if( [[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"])
						{
							NSData *data = [BrowserController produceJPEGThumbnail: img];
							[curFile setValue: data forKey:@"thumbnail"];
						}
					}
				}
			}
			
			if ( img || [modality  hasPrefix: @"RT"])
			{
				NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
				[cell setTransparent:NO];
				[cell setEnabled:YES];
				[cell setLineBreakMode: NSLineBreakByCharWrapping];
				[cell setFont:[NSFont systemFontOfSize:9]];
				[cell setImagePosition: NSImageBelow];
				[cell setAction: @selector(matrixPressed:)];
				
				if ( [modality isEqualToString: @"RTSTRUCT"])
				{
					[[contextualRT itemAtIndex: 0] setAction:@selector(createROIsFromRTSTRUCT:)];
					[cell setMenu: contextualRT];
				}
				else
					[cell setMenu: contextual];
				
				NSString *name = [curFile valueForKey:@"name"];
				
				if( name.length > 18)
				{
					[cell setFont:[NSFont systemFontOfSize: 8.5]];
					name = [name stringByTruncatingToLength: 36]; // 2 lines
				}
				
				if ( [modality hasPrefix: @"RT"])
				{
					[cell setTitle: [NSString stringWithFormat: @"%@\r%@", name, modality]];
				}
				else if ([fileType isEqualToString: @"DICOMMPEG2"])
				{
					long count = [[curFile valueForKey:@"noFiles"] intValue];
					[cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"MPEG-2 Series\r%@\r%d Images", nil), name, count]];
					img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"mpeg2"]];
				}
				else if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"])
				{
					long count = [[curFile valueForKey:@"noFiles"] intValue];
					
					if( count == 1)
					{
						long frames = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
						
						if( frames > 1) [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Frames", nil), name, frames]];
						else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Image", nil), name, count]];
					}
					else
					{
						if( count == 0)
						{
							count = [[curFile valueForKey: @"rawNoFiles"] intValue];
							if( count == 1 && [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue] > 1)
								count = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
								
							[cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Objects", nil), name, count]];
						}
						else
							[cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Images", nil), name, count]];
					}
					
//					if( [[curFile valueForKey: @"keySeries"] boolValue])
//					{
//						[cell setBordered: NO];
//						[cell setBackgroundColor: [NSColor yellowColor]];
//					}
//					else
//					{
//						[cell setBordered: YES];
//						[cell setBackgroundColor: [NSColor whiteColor]];
//					}

				}
				else if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"])
				{
					if( [[curFile valueForKey: @"sliceLocation"] floatValue])
						[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d\r%.2f", nil), i+1, [[curFile valueForKey: @"sliceLocation"] floatValue]]];
					else
						[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d", nil), i+1]];
					
//					if( [[curFile valueForKey: @"isKeyImage"] boolValue])
//					{
//						[cell setBordered: NO];
//						[cell setBackgroundColor: [NSColor yellowColor]];
//					}
//					else
//					{
//						[cell setBordered: YES];
//						[cell setBackgroundColor: [NSColor whiteColor]];
//					}
				}
				
				[cell setButtonType:NSPushOnPushOffButton];
				
				[cell setImage: img];
				
				if( setDCMDone == NO)
				{
					NSIndexSet  *index = [databaseOutline selectedRowIndexes];
					if( [index count] >= 1)
					{
						NSManagedObject* aFile = [databaseOutline itemAtRow:[index firstIndex]];
						
						[imageView setPixels:previewPix files:[self imagesArray: aFile preferredObject: oAny] rois:nil firstImage:[[oMatrix selectedCell] tag] level:'i' reset:YES];
						[imageView setStringID:@"previewDatabase"];
						setDCMDone = YES;
					}
				}
			}		
			else
			{  // Show Error Button
				NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
				[cell setImage: nil];
				[oMatrix setToolTip: NSLocalizedString(@"File not readable", nil) forCell:cell];
				[cell setTitle: NSLocalizedString(@"File not readable", nil)];			
				[cell setFont:[NSFont systemFontOfSize:9]];
				[cell setTransparent:NO];
				[cell setEnabled:NO];
				[cell setButtonType:NSPushOnPushOffButton];
				[cell setBezelStyle:NSShadowlessSquareBezelStyle];
				[cell setTag:i];
			}
		}
		
		@catch( NSException *ne)
		{
			NSLog(@"matrixNewIcon exception: %@", [ne description]);
			[AppController printStackTrace: ne];
		}
		
		[_database unlock];
	}
	[oMatrix setNeedsDisplay:YES];
}

#ifndef OSIRIX_LIGHT
- (void) pdfPreview:(id)sender
{
    [self matrixPressed:sender];
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"open pdf with Preview");
	//check if the folder PDF exists in OsiriX document folder
	NSString *pathToPDF = [[self documentsDirectory] stringByAppendingPathComponent:@"/PDF/"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:pathToPDF]))
		[[NSFileManager defaultManager] createDirectoryAtPath:pathToPDF attributes:nil];
	
	//pathToPDF = /PDF/yyyymmdd.hhmmss.pdf
	NSDateFormatter *datetimeFormatter = [[[NSDateFormatter alloc]initWithDateFormat:@"%Y%m%d.%H%M%S" allowNaturalLanguage:NO] autorelease];
	pathToPDF = [pathToPDF stringByAppendingPathComponent: [datetimeFormatter stringFromDate:[NSDate date]]];
	pathToPDF = [pathToPDF stringByAppendingPathExtension:@"pdf"];
	NSLog( @"%@", pathToPDF);
	
	//creating file and opening it with preview
	NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[sender selectedCell] tag]];
	NSLog( @"%@", [curObj valueForKey: @"type"]);
	
	[_database lock];
	
	@try 
	{
		if( [[curObj valueForKey:@"type"] isEqualToString: @"Series"] == YES) curObj = [[self childrenArray: curObj] objectAtIndex: 0];
	
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	[_database unlock];
	
	NSLog( @"%@", [curObj valueForKey: @"completePath"]);	
	
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[curObj valueForKey: @"completePath"] decodingPixelData:NO];
	NSData *encapsulatedPDF = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if( [fileManager createFileAtPath:pathToPDF contents:encapsulatedPDF attributes:nil]) [[NSWorkspace sharedWorkspace] openFile:pathToPDF withApplication: nil andDeactivate: YES];
	else NSLog( @"couldn't open pdf");
	[NSThread sleepForTimeInterval: 1];
	[pool release];	
}
#endif

- (void)matrixDisplayIcons:(id) sender
{
//	if( bonjourDownloading) return;
	if( _database == nil) return;
	if( [[AppController sharedAppController] isSessionInactive] || waitForRunningProcess) return;
	
	@try
	{
		if( [previewPix count])
		{
			if( loadPreviewIndex < [previewPix count])
			{
				long i;
				for( i = loadPreviewIndex; i < [previewPix count]; i++)
				{
					NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
					
					if( [cell isEnabled] == NO)
					{
						if( i < [previewPix count])
						{
							if( [previewPix objectAtIndex: i] != nil)
							{
								if( i < [matrixViewArray count])
								{
									[self matrixNewIcon:i :[matrixViewArray objectAtIndex: i]];
								}
							}
						}
					}
				}
				
				if( [oMatrix selectedCell] == 0)
				{
					if( [matrixViewArray count] > 0)
						[oMatrix selectCellWithTag: 0];
				}
				
				if( loadPreviewIndex == 0)
					[self initAnimationSlider];
				
				loadPreviewIndex = i;
			}
		}
		else [self initAnimationSlider];
	}
	
	@catch( NSException *ne)
	{
		NSLog( @"matrixDisplayIcons exception: %@", [ne description]);
		[AppController printStackTrace: ne];
	}
}

+(NSData*)produceJPEGThumbnail:(NSImage*)image {
	return [image JPEGRepresentationWithQuality:0.3];
}

- (void) buildThumbnail:(DicomSeries*)series
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[series thumbnail];
	
	[pool release];
}

- (IBAction) buildAllThumbnails:(id) sender
{
	if( [DCMPix isRunOsiriXInProtectedModeActivated]) return;
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"] == NO) return;
	
	NSManagedObjectContext *context = self.managedObjectContext;
	NSManagedObjectModel *model = self.managedObjectModel;
	
	NSString *recoveryPath = [[self documentsDirectory] stringByAppendingPathComponent:@"/ThumbnailPath"];
	if( [[NSFileManager defaultManager] fileExistsAtPath: recoveryPath])
	{
	//	displayEmptyDatabase = YES;
		[self outlineViewRefresh];
		[self refreshMatrix: self];
		NSString *uri = [NSString stringWithContentsOfFile: recoveryPath];
		
		[[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
		
		NSManagedObject *studyObject = nil;
		
		@try
		{
			studyObject = [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]]];
		}
		
		@catch( NSException *ne)
		{
			NSLog(@"buildAllThumbnails exception: %@", [ne description]);
			[AppController printStackTrace: ne];
		}
		
		if( studyObject)
		{
			int r = NSRunAlertPanel( NSLocalizedString(@"Corrupted files", nil), [NSString stringWithFormat:NSLocalizedString(@"A corrupted study crashed OsiriX:\r\r%@ / %@\r\rThis file will be deleted.\r\rYou can run OsiriX in Protected Mode (shift + option keys at startup) if you have more crashes.\r\rShould I delete this corrupted study? (Highly recommended)", nil), [studyObject valueForKey:@"name"], [studyObject valueForKey:@"studyName"], nil], NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
			if( r == NSAlertDefaultReturn)
			{
				[context lock];
				
				@try
				{
					[context deleteObject: studyObject];
					[_database save:NULL];
				}
					
				@catch( NSException *ne)
				{
					NSLog(@"buildAllThumbnails exception: %@", [ne description]);
					[AppController printStackTrace: ne];
				}
				
				[context unlock];
				
				[self outlineViewRefresh];
				[self refreshMatrix: self];
			}
		}
		
	//	displayEmptyDatabase = NO;
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
	{
		if( [_database tryLock])
		{	
			if( [context tryLock])
			{
				DatabaseIsEdited = YES;
				
				@try
				{
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
					[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"thumbnail == NIL"]];
					[dbRequest setFetchLimit: 60];
					
					NSError	*error = nil;
					NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
					
					int maxSeries = [seriesArray count];
					
					if( maxSeries > 60) maxSeries = 60;	// We will continue next time...
					
					for( int i = 0; i < maxSeries; i++)
					{
						[self buildThumbnail: [seriesArray objectAtIndex: i]];
					}
					
					[_database save:NULL];
				}
				
				@catch( NSException *ne)
				{
					NSLog(@"buildAllThumbnails exception: %@", [ne description]);
					[AppController printStackTrace: ne];
				}
				
				[context unlock];
			}
			[_database unlock];
		}
	}
	
	DatabaseIsEdited = NO;
}

- (IBAction) resetWindowsState:(id)sender
{
	NSInteger				x, row;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context lock];
	
	@try 
	{
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
	
		if( [databaseOutline selectedRow] >= 0)
		{
			for( x = 0; x < [selectedRows count] ; x++)
			{
				if( x == 0) row = [selectedRows firstIndex];
				else row = [selectedRows indexGreaterThanIndex: row];
				
				NSManagedObject	*object = [databaseOutline itemAtRow: row];
				
				if( [[object valueForKey:@"type"] isEqualToString: @"Study"])
				{
					[[self childrenArray: object] setValue:nil forKey:@"rotationAngle"];
					[[self childrenArray: object] setValue:nil forKey:@"scale"];
					[[self childrenArray: object] setValue:nil forKey:@"windowLevel"];
					[[self childrenArray: object] setValue:nil forKey:@"windowWidth"];
					[[self childrenArray: object] setValue:nil forKey:@"xFlipped"];
					[[self childrenArray: object] setValue:nil forKey:@"yFlipped"];
					[[self childrenArray: object] setValue:nil forKey:@"xOffset"];
					[[self childrenArray: object] setValue:nil forKey:@"yOffset"];
					[[self childrenArray: object] setValue:nil forKey:@"displayStyle"];
					
					[object setValue:nil forKey:@"windowsState"];
				}
				else if( [[object valueForKey:@"type"] isEqualToString: @"Series"])
				{
					[object setValue:nil forKey:@"rotationAngle"];
					[object setValue:nil forKey:@"scale"];
					[object setValue:nil forKey:@"windowLevel"];
					[object setValue:nil forKey:@"windowWidth"];
					[object setValue:nil forKey:@"xFlipped"];
					[object setValue:nil forKey:@"yFlipped"];
					[object setValue:nil forKey:@"xOffset"];
					[object setValue:nil forKey:@"yOffset"];
					[object setValue:nil forKey:@"displayStyle"];
					
					[object setValue:nil forKeyPath:@"study.windowsState"];
				}
			}
		}
		
		[_database save:NULL];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	[context unlock];
}

-(IBAction)rebuildThumbnails:(id)sender {
	[_database lock];
	@try {
		NSIndexSet* selectedRows = [databaseOutline selectedRowIndexes];
		NSInteger row;
		
		if ([databaseOutline selectedRow] >= 0)
			for (NSInteger x = 0; x < selectedRows.count; x++) {
				if (x == 0) row = selectedRows.firstIndex;
				else row = [selectedRows indexGreaterThanIndex:row];
				
				NSManagedObject* object = [databaseOutline itemAtRow:row];
				
				if ([[object valueForKey:@"type"] isEqualToString:@"Study"])
					[[self childrenArray:object] setValue:nil forKey:@"thumbnail"];
				if ([[object valueForKey:@"type"] isEqualToString:@"Series"])
					[object setValue:nil forKey:@"thumbnail"];
			}
		
		[_database save:NULL];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_database unlock];
	}
	
	[self refreshMatrix: self];
}

- (void)matrixLoadIcons: (NSDictionary*)dict
{
	NSAutoreleasePool               *pool = [[NSAutoreleasePool alloc] init];
	long							subGroupCount = 1, position = 0;
	NSArray							*files = [dict valueForKey: @"files"];
	NSArray							*filesPaths = [dict valueForKey: @"filesPaths"];
	NSMutableArray					*ipreviewPixThumbnails = [dict valueForKey: @"previewPixThumbnails"];
	NSMutableArray					*ipreviewPix = [dict valueForKey: @"previewPix"];
	
	@try
	{
		for( int i = 0; i < filesPaths.count; i++)
		{
			NSImage	*thumbnail = nil;
			
			thumbnail = [ipreviewPixThumbnails objectAtIndex: i];
			
			int frame = 0;
			if( [[[files objectAtIndex: i] valueForKey: @"numberOfFrames"] intValue] > 1) frame = [[[files objectAtIndex: i] valueForKey:@"numberOfFrames"] intValue]/2;
			
			if( [[files objectAtIndex: i] valueForKey: @"frameID"]) frame = [[[files objectAtIndex: i] valueForKey:@"frameID"] intValue];
			
			DCMPix *dcmPix = [[self getDCMPixFromViewerIfAvailable: [filesPaths objectAtIndex:i] frameNumber: frame] retain];
			
			if( dcmPix == nil)
				dcmPix = [[DCMPix alloc] initWithPath: [filesPaths objectAtIndex:i] :position :subGroupCount :nil :frame :0 isBonjour:![_database isLocal] imageObj: [files objectAtIndex: i]];
			
			if( dcmPix)
			{
				if( thumbnail == notFoundImage)
				{
					if( [DCMAbstractSyntaxUID isStructuredReport: [[files objectAtIndex: i] valueForKeyPath: @"series.seriesSOPClassUID"]])
					{
						[ipreviewPixThumbnails replaceObjectAtIndex: i withObject: [NSImage imageNamed: @"pdf.tif"]];
					}
					else
					{
						thumbnail = [dcmPix generateThumbnailImageWithWW: [[[files objectAtIndex: i] valueForKeyPath: @"series.windowWidth"] floatValue] WL: [[[files objectAtIndex: i] valueForKeyPath: @"series.windowLevel"] floatValue]];
						[dcmPix revert: NO];	// <- Kill the raw data
						
						if( thumbnail == nil || dcmPix.notAbleToLoadImage == YES) thumbnail = notFoundImage;
						
						[ipreviewPixThumbnails replaceObjectAtIndex: i withObject: thumbnail];
					}
				}
				
				[ipreviewPix addObject: dcmPix];
				[dcmPix release];
				
				if(previewPix != ipreviewPix || ipreviewPixThumbnails != previewPixThumbnails)
					i = [filesPaths count];
			}
			else
			{
				dcmPix = [[DCMPix alloc] myinitEmpty];
				[ipreviewPix addObject: dcmPix];
				[ipreviewPixThumbnails replaceObjectAtIndex: i withObject: notFoundImage];
				[dcmPix release];
			}
		}
		
		if(previewPix != ipreviewPix || ipreviewPixThumbnails != previewPixThumbnails)
			[self performSelectorOnMainThread:@selector( matrixDisplayIcons:) withObject:nil waitUntilDone: NO];
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"matrixLoadIcons exception: %@", ne.description);
		[AppController printStackTrace: ne];
	}
	
    [pool release];
}

- (CGFloat)splitView: (NSSplitView *)sender constrainSplitPosition: (CGFloat)proposedPosition ofSubviewAt: (NSInteger)offset
{
    if( [sender isVertical] == YES)
	{
        NSSize size = oMatrix.cellSize;
        NSSize space = oMatrix.intercellSpacing;
		
        int pos = proposedPosition;
		
		pos += size.width/2;
		pos -= 17;
		
        pos /= (size.width + space.width*2);
		if( pos <= 0) pos = 1;
		
        pos *= (size.width + space.width*2);
		pos += 17;
		
        return pos;
    }
	
    return proposedPosition;
}

- (void) windowDidChangeScreen:(NSNotification *)aNotification
{
	NSLog(@"windowDidChangeScreen");
	
	// Did the user change the window resolution?
	
	BOOL screenChanged = NO, dbScreenChanged = NO;
	
	float ratioX = 1, ratioY = 1;
	
	for( int i = 0 ; i < [[NSScreen screens] count] ; i++)
	{
		NSScreen *s = [[NSScreen screens] objectAtIndex: i];
		
		if( NSEqualRects( [s visibleFrame], visibleScreenRect[ i]) == NO)
		{
			screenChanged = YES;
			
			if( [[self window] screen] == s)
			{
				NSLog( @"%@", NSStringFromRect( [[self window] frame]));
				NSLog( @"%@", NSStringFromRect( visibleScreenRect[ i]));
				
				dbScreenChanged = YES;
			}
			
			ratioX = visibleScreenRect[ i].size.width / [s visibleFrame].size.width;
			ratioY = visibleScreenRect[ i].size.height / [s visibleFrame].size.height;
			
			visibleScreenRect[ i] = [s visibleFrame];
		}
	}
	
	if( dbScreenChanged)
	{
		[[self window] zoom: self];
	}
	
	if( screenChanged)
	{
		for( ViewerController *v in [ViewerController getDisplayed2DViewers])
		{
			NSRect r = [[v window] frame];
			
			r.origin.x /= ratioX;
			r.origin.y /= ratioY;
			
			r.size.width /= ratioX;
			r.size.height /= ratioY;
			
			[[v window] setFrame: r display: NO];
		}
		
		if( delayedTileWindows)
			[NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
		delayedTileWindows = YES;
		[[AppController sharedAppController] performSelector: @selector(tileWindows:) withObject:nil afterDelay: 0.1];
	}
}

- (void)ViewFrameDidChange: (NSNotification*)note
{
	if( [[splitViewVert subviews] count] > 1)
	{
		if( [note object] == [[splitViewVert subviews] objectAtIndex: 1])	// 1
		{
			NSSize size = oMatrix.cellSize;
			NSSize space = oMatrix.intercellSpacing;
			NSRect frame = [[splitViewVert.subviews objectAtIndex: 0] frame];
			
			int width = frame.size.width;
			int cellsize = (size.width + space.width*2);
			
			width += cellsize/2;
			width /=  cellsize;
			width *=  cellsize;
			
			width += 17;
			
			while( splitViewVert.frame.size.width - width - splitViewVert.dividerThickness <= 200 && width > 0) width -= cellsize;
			
			frame.size.width = width;
			[[splitViewVert.subviews objectAtIndex: 0] setFrame: frame];
			
			frame = [[[splitViewVert subviews] objectAtIndex: 1] frame];
			frame.size.width = [splitViewVert frame].size.width - width - [splitViewVert dividerThickness];
			
			[[splitViewVert.subviews objectAtIndex: 1] setFrame: frame];
			
			[splitViewVert adjustSubviews];
		}
	}
}

-(void)splitViewWillResizeSubviews:(NSNotification *)notification
{
	N2OpenGLViewWithSplitsWindow *window = (N2OpenGLViewWithSplitsWindow*)self.window;
	
	if( [window respondsToSelector:@selector( disableUpdatesUntilFlush)])
		[window disableUpdatesUntilFlush];
}

- (void)splitViewDidResizeSubviews: (NSNotification *)aNotification
{
    NSSize size = oMatrix.cellSize;
    NSSize space = oMatrix.intercellSpacing;
    NSRect frame = oMatrix.enclosingScrollView.frame;
    
    int newColumn = frame.size.width / (size.width + space.width*2);
    if( newColumn <= 0) newColumn = 1;
	
    if( newColumn != COLUMN)
	{
        int	row;
        int	selectedCellTag = [oMatrix.selectedCell tag];
		
        COLUMN = newColumn;
        if( COLUMN == 0)
			{ COLUMN = 1; NSLog(@"ERROR COLUMN = 0");}
        
		row = ceil((float)[matrixViewArray count]/(float) newColumn);
		//	row = ceil((float)[[oMatrix cells] count]/(float)newColumn);
		//	minrow = 1 + (frame.size.height / (size.height + space.height*2));
		//	if( row < minrow) row = minrow;
		
        [oMatrix renewRows:row columns:newColumn];
        [oMatrix sizeToCells];
        
		
        for( int i = [previewPix count]; i<row*COLUMN; i++)
		{
            NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
            [cell setTransparent:YES];
            [cell setEnabled:NO];
        }
		
		[oMatrix selectCellWithTag: selectedCellTag];
    }
}

- (BOOL)splitView: (NSSplitView *)sender canCollapseSubview: (NSView *)subview
{
	if ([sender isEqual:splitViewVert]) return NO;
	else return YES;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset
{	
	if ([sender isEqual: splitViewHorz])
	{
		return oMatrix.cellSize.height;
	}
	else
	{
		return oMatrix.cellSize.width;
	}
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)offset
{
	if ([sender isEqual:splitViewVert])
	{
		return [sender bounds].size.width-200;
	}
	else if ([sender isEqual: splitViewHorz])
	{
		return [sender bounds].size.height- (2*[oMatrix cellSize].height);
	}
	else
	{
		return oMatrix.cellSize.width;
	}
}

- (NSManagedObject *)firstObjectForDatabaseMatrixSelection
{
	NSArray				*cells = [oMatrix selectedCells];
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	if( cells != nil && aFile != nil) 
	{
		
		for( NSCell *cell in cells)
		{
			if( [cell isEnabled] == YES)
			{
				NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [cell tag]];
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
				{
					return curObj;
				}
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
				{
					return [[curObj valueForKey:@"images"] anyObject];
				}
			}
		}
	}
	return nil;
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages
{
	NSMutableArray		*selectedFiles = [NSMutableArray array];
	NSArray				*cells = [oMatrix selectedCells];
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	if( correspondingManagedObjects == nil) correspondingManagedObjects = [NSMutableArray array];
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	
	@try
	{	
		if( cells != nil && aFile != nil)
		{
			for( NSCell *cell in cells)
			{
				if( [cell isEnabled] == YES)
				{
					NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [cell tag]];
					
					if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
					{
						[correspondingManagedObjects addObject: curObj];
					}
					
					if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
					{
						NSArray *imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
						
						[correspondingManagedObjects addObjectsFromArray: imagesArray];
					}
				}
			}
		}
		
		[correspondingManagedObjects removeDuplicatedObjects];
		
		if (![_database isLocal])
		{
			Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Downloading files...", nil)];
			[splash showWindow:self];
			[splash setCancel: YES];
		
			[[splash progress] setMaxValue: [correspondingManagedObjects count]];
			
			for( NSManagedObject *img in correspondingManagedObjects)
			{
				if( [splash aborted] == NO)
				{
					[selectedFiles addObject: [self getLocalDCMPath: img :50]];
					
					[splash incrementBy: 1];
				}
			}
			
			if( [splash aborted])
			{
				[selectedFiles removeAllObjects];
				[correspondingManagedObjects removeAllObjects];
			}
			
			[splash close];
			[splash release];
		}
		else
		{
			[selectedFiles addObjectsFromArray: [correspondingManagedObjects valueForKey: @"completePath"]];
		}
		
		if( [correspondingManagedObjects count] != [selectedFiles count])
			NSLog(@"****** WARNING [correspondingManagedObjects count] != [selectedFiles count]");
	}
	@catch (NSException * e)
	{
		NSLog( @"Exception in filesForDatabaseMatrixSelection: %@", e);
		[AppController printStackTrace: e];
	}
	
	[context release];
	[context unlock];
	
	return selectedFiles;
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects
{
	return [self filesForDatabaseMatrixSelection: correspondingManagedObjects onlyImages: YES];
}

- (void) saveAlbums:(id) sender
{
	NSMutableArray *albums = [NSMutableArray array];
	
	[self.managedObjectContext lock];
	
	@try 
	{
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		NSError *error = nil;
		NSArray *albumArray = [self.managedObjectContext executeFetchRequest:dbRequest error:&error];
		
		if( [albumArray count])
		{
			NSManagedObject *album;
			for( album in albumArray)
			{
				[albums addObject: [NSDictionary dictionaryWithObjectsAndKeys:	[album valueForKey: @"name"], @"name", 
																				[album valueForKey: @"predicateString"], @"predicateString", 
																				[album valueForKey: @"smartAlbum"], @"smartAlbum",
																				nil ]];
			}
			
			NSSavePanel *sPanel	= [NSSavePanel savePanel];
			
			[sPanel setRequiredFileType:@"albums"];
			
			if ([sPanel runModalForDirectory: nil file:NSLocalizedString(@"DatabaseAlbums.albums", nil)] == NSFileHandlingPanelOKButton)
			{
				[albums writeToFile: [sPanel filename] atomically: YES];
			}
		}
		else NSRunInformationalAlertPanel(NSLocalizedString(@"Save Albums", nil), NSLocalizedString(@"There are no albums to save.", nil), NSLocalizedString(@"OK",nil), nil, nil);
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
		
	[self.managedObjectContext unlock];
}

- (void) addAlbumsFile: (NSString*) file
{
	NSArray *albums = [NSArray arrayWithContentsOfFile: file];
		
		[self.managedObjectContext lock];
	
		@try 
		{
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
			NSError *error = nil;
			NSMutableArray *albumArray = [NSMutableArray arrayWithArray: [self.managedObjectContext executeFetchRequest: dbRequest error: &error]];
			
			for( NSDictionary *dict in albums)
			{
				if( [[albumArray valueForKey: @"name"] containsString: [dict valueForKey: @"name"]] == NO)
				{
					NSManagedObject	*a = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: self.managedObjectContext];
					
					[a setValue: [dict valueForKey: @"name"] forKey:@"name"];
					
					if( [dict valueForKey: @"smartAlbum"])
						[a setValue: [dict valueForKey: @"smartAlbum"] forKey:@"smartAlbum"];
					else
						[a setValue: [NSNumber numberWithBool: NO]  forKey:@"smartAlbum"];
						
					[a setValue: [dict valueForKey: @"predicateString"] forKey:@"predicateString"];
				}
			}
			
			[self refreshAlbums];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			[AppController printStackTrace: e];
		}
		
		[self.managedObjectContext unlock];
		
		[self outlineViewRefresh];
}

- (void) addAlbums:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];
	
	if ([oPanel runModalForDirectory: nil file:nil types:[NSArray arrayWithObject:@"albums"]] == NSFileHandlingPanelOKButton)
	{
		[self addAlbumsFile: [oPanel filename]];
	}
}

- (void) createContextualMenu // MATRIX contextual menu
{
	NSMenuItem		*item;
	
	NSMenu *albumContextual	= [[[NSMenu alloc] initWithTitle: NSLocalizedString(@"Albums", nil)] autorelease];
	
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Save Albums", nil) action:@selector( saveAlbums:) keyEquivalent:@""] autorelease];
	[item setTarget: self]; // required because the drawner is the first responder
	[albumContextual addItem:item];
	
	[albumContextual addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Import Albums", nil) action:@selector( addAlbums:) keyEquivalent:@""] autorelease];
	[item setTarget: self]; // required because the drawner is the first responder
	[albumContextual addItem:item];
	
	[albumContextual addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Create Default Albums", nil) action:@selector( defaultAlbums:) keyEquivalent:@""] autorelease];
	[item setTarget: self]; // required because the drawner is the first responder
	[albumContextual addItem:item];
	
	[albumTable setMenu: albumContextual];
	
	// ****************
	
	if ( contextual == nil) contextual	= [[NSMenu alloc] initWithTitle: NSLocalizedString(@"Tools", nil)];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Images", nil) action:@selector(viewerDICOM:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Images in 4D", nil) action:@selector(MovieViewerDICOM:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Sub-Selection", nil) action:@selector(viewerSubSeriesDICOM:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Key Images", nil) action:@selector(viewerDICOMKeyImages:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open ROIs Images", nil) action:@selector(viewerDICOMROIsImages:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open ROIs and Key Images", nil) action:@selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Merged Selection", nil) action:@selector(viewerDICOMMergeSelection:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Reveal In Finder", nil) action:@selector(revealInFinder:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to DICOM Network Node", nil) action:@selector(export2PACS:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to Quicktime", nil) action:@selector(exportQuicktime:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to JPEG", nil) action:@selector(exportJPEG:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to TIFF", nil) action:@selector(exportTIFF:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to DICOM File(s)", nil) action:@selector(exportDICOMFile:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to iDisk", nil) action:@selector(sendiDisk:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Compress DICOM files", nil) action:@selector(compressSelectedFiles:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Decompress DICOM files", nil) action:@selector(decompressSelectedFiles:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Toggle Images/Series Displaying", nil) action:@selector(displayImagesOfSeries:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Merge Selected Series", nil) action:@selector(mergeSeries:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Delete", nil) action:@selector(delItem:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [NSMenuItem separatorItem]];
	
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Query Selected Patient from Q&R Window...", nil) action:@selector(querySelectedStudy:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Burn", nil) action:@selector(burnDICOM:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Anonymize", nil) action:@selector(anonymizeDICOM:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Rebuild Selected Thumbnails", nil) action:@selector(rebuildThumbnails:) keyEquivalent:@""] autorelease]];
	[contextual addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Copy Linked Files to Database Folder", nil) action:@selector(copyToDBFolder:) keyEquivalent:@""] autorelease]];
	[oMatrix setMenu: contextual];
	
	// Create alternate contextual menu for RT objects
	
	if( contextualRT == nil) contextualRT = [contextual copy];
	
	item = [[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Create ROIs from RTSTRUCT", nil)  action:@selector(createROIsFromRTSTRUCT:) keyEquivalent:@""];
	[contextualRT insertItem: item atIndex: 0];
	[item release];
	
	[contextualRT insertItem: [NSMenuItem separatorItem] atIndex: 1];
	
	// Now remove non-applicable items - usually related to images (most RT objects don't have embedded images)
	
	NSInteger indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Images in 4D", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Key Images", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Sub-Selection", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs Images", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs and Key Images", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to Quicktime", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to JPEG", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to TIFF", nil)];
	if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
}

-(void) annotMenu:(id) sender
{
	[imageView annotMenu: sender];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Albums functions

- (IBAction) addSmartAlbum: (id)sender
{
	SmartWindowController *smartWindowController = [[SmartWindowController alloc] init];
	NSWindow *sheet = [smartWindowController window];
	
    [NSApp beginSheet: sheet
	   modalForWindow: self.window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	[smartWindowController addSubview: nil];
	
    int result = [NSApp runModalForWindow:sheet];
	[sheet makeFirstResponder: nil];
	
    // Sheet is up here.
    [NSApp endSheet: sheet];
    [sheet orderOut: self];
	[smartWindowController close];
	
	NSMutableArray *criteria = [smartWindowController criteria];
	if( [criteria count] > 0 && result == NSRunStoppedResponse)
	{
		NSError *error = nil;
		NSString *name;
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		NSManagedObjectContext *context = self.managedObjectContext;
		
		[context lock];
		
		@try 
		{
			error = nil;
			NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
			
			int i = 2;
			name = [smartWindowController albumTitle];
			while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
			{
				name = [NSString stringWithFormat:@"%@ #%d", [smartWindowController albumTitle], i++];
			}
			
			NSManagedObject	*album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
			[album setValue:name forKey:@"name"];
			[album setValue:[NSNumber numberWithBool:YES] forKey:@"smartAlbum"];
			
			NSString *format = [smartWindowController sqlQueryString];
						
			[album setValue:format forKey:@"predicateString"];
			
			[_database save:NULL];
			
			[self refreshAlbums];
			
			[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [self.albumArray indexOfObject: album]] byExtendingSelection: NO];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			[AppController printStackTrace: e];
		}
		
		[context unlock];
		
		[self outlineViewRefresh];
		
		if( [smartWindowController editSqlQuery])
			[self albumTableDoublePressed: self];
	}
	
	[smartWindowController release];
}

- (IBAction) albumButtons: (id)sender
{
	switch( [sender selectedSegment])
	{
		case 0:
		{ // Add album
			
			[NSApp beginSheet: newAlbum
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow: newAlbum];
			[newAlbum makeFirstResponder: nil];
			
			[NSApp endSheet: newAlbum];
			[newAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse)
			{
				NSString			*name;
				long				i = 2;
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				NSManagedObjectContext *context = self.managedObjectContext;
				
				[context lock];
				
				@try 
				{
					NSError *error = nil;
					NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
					
					name = [newAlbumName stringValue];
					while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
					{
						name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
					}
					
					NSManagedObject	*album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
					[album setValue:name forKey:@"name"];
					
					[_database save:NULL];
					
					[self refreshAlbums];
				}
				@catch (NSException * e) 
				{
					NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
					[AppController printStackTrace: e];
				}
				
				[context unlock];
				
				[self outlineViewRefresh];
			}
		}
		break;
			
		case 1:
		{ // Add smart album
			
			[self addSmartAlbum: self];
		}
		break;
			
		case 2:	// Remove
			if( albumTable.selectedRow > 0)
			{
				if (NSRunInformationalAlertPanelRelativeToWindow(NSLocalizedString(@"Delete an album", nil),
																 NSLocalizedString(@"Are you sure you want to delete this album?", nil),
																 NSLocalizedString(@"OK",nil),
																 NSLocalizedString(@"Cancel",nil),
																 nil, self.window) == NSAlertDefaultReturn)
				{
					NSManagedObjectContext	*context = self.managedObjectContext;
					
					[context lock];
					
					@try 
					{
						if( albumTable.selectedRow > 0)	// We cannot delete the first item !
						{
							[context deleteObject: [self.albumArray  objectAtIndex: albumTable.selectedRow]];
						}
						
						[_database save:NULL];
						
						[self refreshAlbums];
					}
					@catch (NSException * e) 
					{
						NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
						[AppController printStackTrace: e];
					}
					
					[context unlock];
					
					[self outlineViewRefresh];
				}
			}
		break;
	}
}

static BOOL needToRezoom;

-(void)drawerWillClose:(NSNotification*)notification {
	needToRezoom = self.window.isZoomed;
}

-(void)drawerDidClose:(NSNotification*)notification {
	if (needToRezoom)
		[self.window zoom:self];
	else if ([[NSUserDefaultsController sharedUserDefaultsController] boolForKey:@"BrowserDidResizeForDrawer"]) {
		NSRect windowFrame = self.window.frame;
		windowFrame.origin.x -= albumDrawer.contentSize.width;
		windowFrame.size.width += albumDrawer.contentSize.width;
		[self.window setFrame:windowFrame display:YES animate:YES];
	}
}

-(void)drawerWillOpen:(NSNotification*)notification {
	needToRezoom = self.window.isZoomed;
}

-(void)drawerDidOpen:(NSNotification*)notification {
	if (needToRezoom)
		[self.window zoom:self];
	else {
		NSRect screenBounds = NSZeroRect;
		for (NSScreen* screen in [NSScreen screens])
			screenBounds = NSUnionRect(screenBounds, [screen frame]);
		NSRect drawerFrame = albumDrawer.contentView.window.frame;
		NSRect intersectedFrame = NSIntersectionRect(drawerFrame, screenBounds);
		
		#define DrawerMinVisibleRatio .5
		BOOL adapt = (intersectedFrame.size.width*intersectedFrame.size.height)/(drawerFrame.size.width*drawerFrame.size.height) < DrawerMinVisibleRatio;
		[[NSUserDefaultsController sharedUserDefaultsController] setBool:adapt forKey:@"BrowserDidResizeForDrawer"];
		if (adapt) {
			NSRect windowFrame = self.window.frame;
			windowFrame.origin.x += albumDrawer.contentSize.width;
			windowFrame.size.width -= albumDrawer.contentSize.width;
			[self.window setFrame:windowFrame display:YES animate:YES];
		}
	}
}

- (IBAction)smartAlbumHelpButton: (id)sender
{
	if( [sender tag] == 0)
	{
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"] withApplication: nil andDeactivate: YES];
		[NSThread sleepForTimeInterval: 1];
	}
	
	if( [sender tag] == 1)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];

	if( [sender tag] == 2)
	{
		[[self window] makeFirstResponder: nil];
		
		@try
		{
			self.testPredicate = [[BrowserController currentBrowser] smartAlbumPredicateString: [editSmartAlbumQuery stringValue]];
			
			NSString *exception = [self outlineViewRefresh];
			self.testPredicate = nil;
			
			if( exception) NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil), [NSString stringWithFormat: NSLocalizedString(@"This filter is NOT working: %@", nil), exception], NSLocalizedString(@"OK",nil), nil, nil);
			else NSRunInformationalAlertPanel( NSLocalizedString(@"It works !",nil), NSLocalizedString(@"This filter works: the result is now displayed in the Database Window.", nil), NSLocalizedString(@"OK",nil), nil, nil);
		}
		@catch (NSException * e)
		{
			[AppController printStackTrace: e];
			NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil), [NSString stringWithFormat: NSLocalizedString(@"This filter is NOT working: %@", nil), e], NSLocalizedString(@"OK",nil), nil, nil);
		}
	}
}

- (IBAction) albumTableDoublePressed: (id)sender
{
	if( albumTable.selectedRow > 0 && [_database isLocal])
	{
		NSManagedObject	*album = [self.albumArray objectAtIndex: albumTable.selectedRow];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
		{
			[editSmartAlbumName setStringValue: [album valueForKey:@"name"]];
			[editSmartAlbumQuery setStringValue: [album valueForKey:@"predicateString"]];
			
			[NSApp beginSheet: editSmartAlbum
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow: editSmartAlbum];
			[editSmartAlbum makeFirstResponder: nil];
			
			[NSApp endSheet: editSmartAlbum];
			[editSmartAlbum orderOut: self];
			
			self.testPredicate = nil;
			[self outlineViewRefresh];
			
			if( result == NSRunStoppedResponse)
			{
				NSError				*error = nil;
				NSString			*name;
				long				i = 2;
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				NSManagedObjectContext *context = self.managedObjectContext;
				
				[context retain];
				[context lock];
				error = nil;
				
				@try 
				{
					NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
				
					if( [[editSmartAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO)
					{
						name = [editSmartAlbumName stringValue];
						while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
						{
							name = [NSString stringWithFormat:@"%@ #%d", [editSmartAlbumName stringValue], i++];
						}
						
						[album setValue:name forKey:@"name"];
					}
					
					[album setValue:[editSmartAlbumQuery stringValue] forKey:@"predicateString"];
					
					[_database save:NULL];
					
					[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [self.albumArray indexOfObject:album]] byExtendingSelection: NO];
					
					[self outlineViewRefresh];
					
					[self refreshAlbums];
				}
				@catch (NSException * e) 
				{
					NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
					[AppController printStackTrace: e];
				}
				
				[context unlock];
				[context release];
			}
		}
		else
		{
			[newAlbumName setStringValue: [album valueForKey:@"name"]];
			
			[NSApp beginSheet: newAlbum
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow: newAlbum];
			[newAlbum makeFirstResponder: nil];
			
			[NSApp endSheet: newAlbum];
			[newAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse)
			{
				int i = 2;
				
				if( [[newAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO)
				{
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
					NSManagedObjectContext *context = self.managedObjectContext;
					
					[context retain];
					[context lock];
					NSError *error = nil;
					
					@try 
					{
						NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
					
						NSString *name = newAlbumName.stringValue;
						while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
						{
							name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
						}
						
						[album setValue:name forKey:@"name"];
						
//						@synchronized( [BrowserController currentBrowser])
//						{
//							cachedAlbumsManagedObjectContext = nil;
//						}
						
						[_database save:NULL];
						
						[albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: [self.albumArray indexOfObject:album]] byExtendingSelection: NO];
						
						[albumTable reloadData];
					}
					@catch (NSException * e) 
					{
						NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
						[AppController printStackTrace: e];
					}
					
					[context unlock];
					[context release];
				}
			}
		}
	}
}
- (NSArray*) albumArray
{
	NSArray *albumsArray = [_database albums];
	
	return [[NSArray arrayWithObject: [NSDictionary dictionaryWithObject: NSLocalizedString(@"Database", nil) forKey:@"name"]] arrayByAddingObjectsFromArray: albumsArray];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Albums TableView functions

//NSTableView delegate and datasource
- (NSInteger)numberOfRowsInTableView: (NSTableView *)aTableView
{	
	if ([aTableView isEqual:albumTable])
	{
		//if( displayEmptyDatabase) return 0;
		return [self.albumArray count];
	}
	return 0;
}

- (id)tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex
{
	if ([aTableView isEqual:albumTable])
	{
		//if( displayEmptyDatabase) return nil;
		
		if([[aTableColumn identifier] isEqualToString:@"no"])
		{
			NSString *noOfStudies = nil;
			
			@synchronized( albumNoOfStudiesCache) {
				if( albumNoOfStudiesCache == nil || rowIndex >= [albumNoOfStudiesCache count] || [[albumNoOfStudiesCache objectAtIndex: rowIndex] isEqualToString:@""] == YES) {
					[self refreshAlbums];
					// It will be computed in a separate thread, and then displayed later.
					noOfStudies = @"#";
				}
				else
					noOfStudies = [[[albumNoOfStudiesCache objectAtIndex: rowIndex] copy] autorelease];
			}
			
			return noOfStudies;
		}
		else
		{
			NSArray *albumsArray = self.albumArray;
			
			if( rowIndex >= 0 && rowIndex < albumsArray.count)
			{
				NSManagedObject	*object = [albumsArray  objectAtIndex: rowIndex];
				return [object valueForKey:@"name"];
			}
			else
				return NSLocalizedString( @"n/a", nil);
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if( [aCell isKindOfClass: [ImageAndTextCell class]])
	{
		[(ImageAndTextCell*) aCell setLastImage: nil];
		[(ImageAndTextCell*) aCell setLastImageAlternate: nil];
	}
	
	if ([aTableView isEqual:albumTable])
	{
		//if( displayEmptyDatabase) return;
		
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 11];
		else txtFont = [NSFont systemFontOfSize:11];			
		
		[aCell setFont:txtFont];
		[aCell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
		if( [[aTableColumn identifier] isEqualToString:@"Source"])
		{
			NSArray *albumArray = self.albumArray;
			
			if ( albumArray.count > rowIndex && [[[albumArray objectAtIndex: rowIndex] valueForKey:@"smartAlbum"] boolValue])
			{
				if (![_database isLocal])
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_sharedSmartAlbum.tif"]];
				}
				else
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_smartAlbum.tif"]];
				}
			}
			else
			{
				if (![_database isLocal])
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_sharedAlbum.tif"]];
				}
				else
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_album.tif"]];
				}
			}
		}
	}
}

- (void)sendDICOMFilesToOsiriXNode: (NSDictionary*)todo
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	NSLog( @"sendDICOMFilesToOsiriXNode started");
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [NSUserDefaults defaultAETitle] 
															  calledAET: [todo objectForKey:@"AETitle"] 
															   hostname: [todo objectForKey:@"Address"] 
																   port: [[todo objectForKey:@"Port"] intValue] 
															filesToSend: [todo valueForKey: @"Files"]
														 transferSyntax: [[todo objectForKey:@"TransferSyntax"] intValue] 
															compression: 1.0
														extraParameters: nil];
	
	@try
	{
		[storeSCU run:self];
	}
	
	@catch (NSException *ne)
	{
		NSLog( @"Bonjour DICOM Send FAILED");
		NSLog( @"%@", ne.name);
		NSLog( @"%@", ne.reason);
		[AppController printStackTrace: ne];
	}
	
	[storeSCU release];
	storeSCU = nil;
	
	NSLog( @"sendDICOMFilesToOsiriXNode ended");
	
	[pool release];
}

- (NSManagedObject*) findStudyUID: (NSString*) uid
{
	NSArray						*studyArray = nil;
	NSError						*error = nil;
	NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", uid];
	
	[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Study"]];
	[request setPredicate: predicate];
	
	[context retain];
	[context lock];
	
	@try
	{
		studyArray = [context executeFetchRequest:request error:&error];
	}
	@catch (NSException * e)
	{
		NSLog( @"**** findStudyUID exception: %@", [e description]);
		[AppController printStackTrace: e];
	}
	
	[context unlock];
	[context release];
	
	if( [studyArray count]) return [studyArray objectAtIndex: 0];
	else return nil;
}

- (NSManagedObject*) findSeriesUID: (NSString*) uid
{
	NSArray						*seriesArray = nil;
	NSError						*error = nil;
	NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
	NSManagedObjectContext		*context = [[BrowserController currentBrowser] managedObjectContext];
	NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", uid];
	
	[request setEntity: [[[[BrowserController currentBrowser] managedObjectModel] entitiesByName] objectForKey:@"Series"]];
	[request setPredicate: predicate];
	
	[context retain];
	[context lock];
	
	@try
	{
		seriesArray = [context executeFetchRequest:request error:&error];
	}
	@catch (NSException * e)
	{
		NSLog( @"**** findSeriesUID exception: %@", [e description]);
		[AppController printStackTrace: e];
	}
	
	[context unlock];
	[context release];
	
	if( [seriesArray count]) return [seriesArray objectAtIndex: 0];
	else return nil;
}

- (void) sendFilesToCurrentBonjourDB: (NSArray*) files
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![_database isLocal])
		[(RemoteDicomDatabase*)_database uploadFilesAtPaths:files generatedByOsiriX:NO];
	
	[pool release];
}

- (void) sendFilesToCurrentBonjourGeneratedByOsiriXDB: (NSArray*) files
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (![_database isLocal])
		[(RemoteDicomDatabase*)_database uploadFilesAtPaths:files generatedByOsiriX:YES];
	
	[pool release];
}

- (void) copyToDB: (NSDictionary*) d
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *dbFolder = [d objectForKey: @"dbFolder"];
	NSMutableArray *dstFiles = [NSMutableArray array];
	NSManagedObjectContext *sqlContext = [d objectForKey: @"sqlContext"];
	
	int t = 0;
	for( NSString *srcPath in [d objectForKey: @"packArray"])
	{
		NSString *dstPath;
		BOOL isDicomFile = [DicomFile isDICOMFile:srcPath];
		
		if( isDicomFile) dstPath = [self getNewFileDatabasePath:@"dcm" dbFolder: [dbFolder stringByAppendingPathComponent: @"OsiriX Data"]];
		else dstPath = [self getNewFileDatabasePath: [[srcPath pathExtension] lowercaseString] dbFolder: [dbFolder stringByAppendingPathComponent: @"OsiriX Data"]];
		
		if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil])
			[dstFiles addObject: dstPath];
		
		if( [NSThread currentThread].isCancelled)
			break;
			
		[NSThread currentThread].progress = (float) ++t / (float) [[d objectForKey: @"packArray"] count];
		[NSThread currentThread].status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [[d objectForKey: @"packArray"] count]-t];
	}
	
	// Then we add the files to the sql file
	[NSThread currentThread].status = NSLocalizedString( @"Indexing the files...", nil);
	[self addFilesToDatabase: dstFiles onlyDICOM: NO produceAddedFiles:YES parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
						
	[pool release];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	if ([tableView isEqual:albumTable])
	{
		NSArray	*albumArray = self.albumArray;
		
		if (row >= [albumArray count] || row  == 0)
			return NO;
		
		//can't add to smart Album
		if ([[[albumArray objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue]) return NO;
		
		DicomAlbum* album = [albumArray objectAtIndex: row];
		
		NSPasteboard* pb = [info draggingPasteboard];
		NSArray* xids = [NSPropertyListSerialization propertyListFromData:[pb propertyListForType:@"BrowserController.database.context.XIDs"] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
		NSMutableArray* items = [NSMutableArray array];
		for (NSString* xid in xids)
			[items addObject:[_database objectWithID:[NSManagedObject UidForXid:xid]]];
		
		if (items)
		{
			NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];
			
			for( NSManagedObject *object in items)
			{
				if( [[object valueForKey:@"type"] isEqualToString:@"Study"])
				{
					[studies addObject: object];
					[(DicomStudy*) object archiveAnnotationsAsDICOMSR];
				}
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Series"])
				{
					[studies addObject: [object valueForKey:@"study"]];
					[[object valueForKey:@"study"] archiveAnnotationsAsDICOMSR];
				}
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Image"])
				{
					[studies addObject: [object valueForKeyPath:@"series.study"]];
					[[object valueForKeyPath:@"series.study"] archiveAnnotationsAsDICOMSR];
				}
			}
			
			[_database save:NULL];
			
			[self refreshAlbums];
			
			[tableView reloadData];
			
			if (![_database isLocal])
			{
				// Do it remotely
				NSMutableArray *studiesToAdd = [NSMutableArray array];
				
				for( NSManagedObject *object in items)
				{
					if( [[object valueForKey:@"type"] isEqualToString:@"Study"])
						[studiesToAdd addObject: object];
					
					if( [[object valueForKey:@"type"] isEqualToString:@"Series"])
						[studiesToAdd addObject: [object valueForKey:@"study"]];
						
					if( [[object valueForKey:@"type"] isEqualToString:@"Image"])
						[studiesToAdd addObject: [object valueForKeyPath:@"series.study"]];
				}
				
				[(RemoteDicomDatabase*)_database addStudies:studiesToAdd toAlbum:album];
			}
		}
		
		return YES;
	}
	
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([tableView isEqual:albumTable])
	{
		NSArray	*array = self.albumArray;
		
		if ((row >= [array count]) || [[[array objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue] || row == 0) return NSDragOperationNone;
		
		[albumTable setDropRow:row dropOperation:NSTableViewDropOn];
		
		return NSDragOperationLink;
	}
	
	return NSDragOperationNone;
}

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification
{
	if( [[aNotification object] isEqual: albumTable])
	{
		// Clear search field
		[self setSearchString: nil];
		
		[self refreshAlbums];
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Open 2D/4D Viewer functions

- (BOOL)computeEnoughMemory: (NSArray*)toOpenArray: (unsigned long*)requiredMem
{
	BOOL enoughMemory = YES;
	unsigned long long mem = 0, memBlock = 0;
	unsigned char* testPtr[ 800];
	
	for( int x = 0; x < [toOpenArray count]; x++)
	{
		testPtr[ x] = nil;
	}
	
	for( int x = 0; x < [toOpenArray count]; x++)
	{
		memBlock = 0;				
		NSArray* loadList = [toOpenArray objectAtIndex: x];
		
		if( [loadList count])
		{
			NSManagedObject*  curFile = [loadList objectAtIndex: 0];
			
			if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
			{
				mem += ([[curFile valueForKey:@"width"] intValue] +1) * ([[curFile valueForKey:@"height"] intValue]+1) * [[curFile valueForKey:@"numberOfFrames"] intValue];
				memBlock += ([[curFile valueForKey:@"width"] intValue]) * ([[curFile valueForKey:@"height"] intValue]) * [[curFile valueForKey:@"numberOfFrames"] intValue];
			}
			else
			{
				for( curFile in loadList)
				{
					mem += ([[curFile valueForKey:@"width"] intValue] +1) * ([[curFile valueForKey:@"height"] intValue] +1);
					memBlock += ([[curFile valueForKey:@"width"] intValue]) * ([[curFile valueForKey:@"height"] intValue]);
				}
			}
			
			memBlock *= sizeof(float);
			memBlock += 4L * 1024L * 1024L;
			
			#if __LP64__
			#else
			unsigned long long max4GB = 3.5 * 1024;
			
			max4GB *= 1024 * 1024;
			
			if( memBlock >= max4GB)
			{
				memBlock = 0;	// 4-GB Limit
				NSLog(@"4-GB Memory limit for 32-bit application...");
			}
			#endif
			
			if( memBlock > 0)
				testPtr[ x] = malloc( memBlock * 1.5); // * 1.5 for 3D post-processing viewers
			else
				testPtr[ x] = nil;
				
			if( testPtr[ x] == nil)
			{
				enoughMemory = NO;
				
				NSLog(@"Failed to allocate memory for: %llu Mb", (memBlock) / (1024 * 1024));
			}
		}
		
	} //end for
	
	for( int x = 0; x < [toOpenArray count]; x++)
	{
		if( testPtr[ x]) free( testPtr[ x]);
	}
	
	mem /= 1024;
	mem /= 1024;
	
	if( requiredMem) *requiredMem = mem;
	
	return enoughMemory;
}

- (ViewerController*) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages
{
	return [self openViewerFromImages:toOpenArray movie:movieViewer viewer:viewer keyImagesOnly:keyImages tryToFlipData: NO];
}

- (ViewerController*) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages tryToFlipData:(BOOL) tryToFlipData
{
	unsigned long		*memBlockSize = calloc( [toOpenArray count], sizeof (unsigned long));
	
	BOOL				multiFrame = NO, preFlippedData = NO;
	float				*fVolumePtr = nil;
	NSData				*volumeData = nil;
	NSMutableArray		*viewerPix[ MAX4D];
	ViewerController	*movieController = nil;
	ViewerController	*createdViewer = viewer;
	
	@try
	{
		// NS_DURING (1) keyImages
		
		NSMutableArray *keyImagesToOpenArray = [NSMutableArray array];
		
		for( NSArray *loadList in toOpenArray)
		{
			NSMutableArray *keyImagesArray = [NSMutableArray array];
			
			for( NSManagedObject *image in loadList)
			{					
				if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
					[keyImagesArray addObject: image];
			}
			
			if( [keyImagesArray count] > 0)
				[keyImagesToOpenArray addObject: keyImagesArray];
		}
			
		if ( keyImages)
		{	
			if( [keyImagesToOpenArray count] > 0) toOpenArray = keyImagesToOpenArray;
			else
			{
				if( NSRunInformationalAlertPanel( NSLocalizedString( @"Key Images", nil), NSLocalizedString(@"No key images in these images.", nil), NSLocalizedString(@"All Images",nil), NSLocalizedString(@"Cancel",nil), nil) == NSAlertAlternateReturn)
					return nil;
			}
		}
		
		BOOL savedAUTOHIDEMATRIX = [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTOHIDEMATRIX"];
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"AUTOHIDEMATRIX"];
		
		if( dontShowOpenSubSeries == NO)
		{
			if (([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask) || ([self computeEnoughMemory: toOpenArray : nil] == NO) || openSubSeriesFlag == YES)
			{
				toOpenArray = [self openSubSeries: toOpenArray];
			}
		}
		
		// NS_DURING (2) Compute Required Memory
		
		BOOL	enoughMemory = NO;
		long	subSampling = 1;
		unsigned long mem = 0;
		
		while( enoughMemory == NO)
		{
			BOOL memTestFailed = NO;
			unsigned char **testPtr = calloc( [toOpenArray count], sizeof( unsigned char*));
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++)
			{
				unsigned long memBlock = 0;
				NSArray *loadList = [toOpenArray objectAtIndex: x];
				
				if( [loadList count])
				{
					DicomImage*  curFile = [loadList objectAtIndex: 0];
					[curFile setValue:[NSDate date] forKeyPath:@"series.dateOpened"];
					[curFile setValue:[NSDate date] forKeyPath:@"series.study.dateOpened"];
					
					if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
					{
						multiFrame = YES;
						long h = [[curFile height] intValue];
						long w = [[curFile width] intValue];
						mem += (w+1) * (h+1) * [[curFile valueForKey:@"numberOfFrames"] intValue];
						memBlock += w * h * [[curFile valueForKey:@"numberOfFrames"] intValue];
					}
					else
					{
						for( curFile in loadList)
						{
							long h = [[curFile height] intValue];
							long w = [[curFile width] intValue];
							
							if( w*h < 256*256)
							{
								w = 256;
								h = 256;
							}
							
							mem += (w+1) * (h+1);
							memBlock += w * h;
						}
					}
					
					if ( memBlock < 256 * 256) memBlock = 256 * 256;  // This is the size of array created when when an image doesn't exist, a 256 square graduated gray scale.
					
					testPtr[ x] = malloc( (memBlock * sizeof(float)) + 4096);
					if( testPtr[ x] == nil)
					{
						// Try to find the memory...
						
						[DCMView purgeStringTextureCache];
						@try
						{
							for( DCMPix *p in previewPix)
							{
								[p kill8bitsImage];
								[p revert: NO];
							}
						}
						@catch (NSException *e) {}
						
						testPtr[ x] = malloc( (memBlock * sizeof(float)) + 4096);
						if( testPtr[ x] == nil)
						{
							memTestFailed = YES;
							
							NSLog(@"Failed to allocate memory for: %lu Mb", (memBlock * sizeof(float)) / (1024 * 1024));
						}
					}
					memBlockSize[ x] = memBlock;
				}
				
			} //end for
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++)
			{
				if( testPtr[ x]) free( testPtr[ x]);
			}
			
			free( testPtr);
			
			// TEST MEMORY : IF NOT ENOUGH -> REDUCE SAMPLING
			
			if( memTestFailed)
			{
				NSLog(@"Test memory failed -> sub-sampling");
				
				NSMutableArray *newArray = [NSMutableArray array];
				
				subSampling *= 2;
				
				for( NSArray *loadList in toOpenArray)
				{					
					NSMutableArray *imagesArray = [NSMutableArray array];
					
					for( int i = 0; i < [loadList count]; i++)
					{
						NSManagedObject	*image = [loadList objectAtIndex: i];
						
						if( i % 2 == 0)	[imagesArray addObject: image];
					}
					
					if( [imagesArray count] > 0)
						[newArray addObject: imagesArray];
				}
				
				toOpenArray = newArray;
			}
			else enoughMemory = YES;
		} //end while
		
		int result = NSAlertDefaultReturn;
		
		if( subSampling != 1)
		{
			for( NSWindow *win in [NSApp windows])
			{
				if( [win isMiniaturized])
				{
					[win deminiaturize:self];
				}
			}
			
			result = NSRunInformationalAlertPanel( NSLocalizedString(@"Not enough memory", nil),  [NSString stringWithFormat: NSLocalizedString(@"Your computer doesn't have enough RAM to load this series, but I can load a subset of the series: 1 on %d images.", nil), subSampling], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}
		
		// NS_DURING (3) Load Images (memory allocation)
		
		BOOL notEnoughMemory = NO;
		
		if( result == NSAlertDefaultReturn && toOpenArray != nil)
		{
			if( movieViewer == NO)
			{
				//				NSLog(@"I will try to allocate: %d Mb", (mem * sizeof(float)) / (1024 * 1024));
				//				
				//				fVolumePtr = malloc(mem * sizeof(float));
				//				if( fVolumePtr == nil)
				//				{
				//					NSArray	*winList = [NSApp windows];
				//					for( i = 0; i < [winList count]; i++)
				//					{
				//						if([[winList objectAtIndex:i] isMiniaturized])
				//						{
				//							[[winList objectAtIndex:i] deminiaturize:self];
				//						}
				//					}
				//					
				//					NSRunCriticalAlertPanel( NSLocalizedString(@"Not enough memory",@"Not enough memory"),  NSLocalizedString(@"Your computer doesn't have enough RAM to load this series",@"Your computer doesn't have enough RAM to load this series"), NSLocalizedString(@"OK",nil), nil, nil);
				//					notEnoughMemory = YES;
				//				}
				//
				//				free( fVolumePtr);	// We will allocate each block independently !
				//				fVolumePtr = nil;	
			}
			else
			{
				char **memBlockTestPtr = calloc( [toOpenArray count], sizeof( char*));
				
				NSLog(@"4D Viewer TOTAL: %lu Mb", (mem * sizeof(float)) / (1024 * 1024));
				for( unsigned long x = 0; x < [toOpenArray count]; x++)
				{
					memBlockTestPtr[ x] = malloc(memBlockSize[ x] * sizeof(float));
					NSLog(@"4D Viewer: I will try to allocate: %lu Mb", (memBlockSize[ x]* sizeof(float)) / (1024 * 1024));
					
					if( memBlockTestPtr[ x] == nil) notEnoughMemory = YES;
				}
				
				for( unsigned long x = 0; x < [toOpenArray count]; x++)
				{
					if( memBlockTestPtr[ x] != nil) free( memBlockTestPtr[ x]);
				}
				
				if( notEnoughMemory)
				{
					if( NSRunCriticalAlertPanel( NSLocalizedString(@"Not enough memory",@"Not enough memory"),  NSLocalizedString(@"Your computer doesn't have enough RAM to load this series.\r\rUpgrade to OsiriX 64-bit to solve this issue.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
					[[AppController sharedAppController] osirix64bit: self];
				}
				
				free( memBlockTestPtr);
				fVolumePtr = nil;
			}
		}
		else notEnoughMemory = YES;
		
		// NS_DURING (4) Load Images loop
		
		if( notEnoughMemory == NO)
		{
			// Pre-Flip data ?
			
			NSMutableArray *resortedToOpenArray = [NSMutableArray array], *isFlippedData = [NSMutableArray array];
			
			for( NSArray *a in toOpenArray)
			{
				BOOL flipped = NO;
				
				if( multiFrame == NO && tryToFlipData == YES && [a count] > 2)
				{
					@try 
					{
						DicomImage *o = nil;
						o = [a objectAtIndex: 1];
						DCMPix *p1 = [[DCMPix alloc] initWithPath: [o valueForKey:@"completePath"] :0 :1 :nil :[[o valueForKey:@"frameID"] intValue] :[[o valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: o];
						o = [a objectAtIndex: 2];
						DCMPix *p2 = [[DCMPix alloc] initWithPath: [o valueForKey:@"completePath"] :0 :1 :nil :[[o valueForKey:@"frameID"] intValue] :[[o valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: o];
					
						if( p1 && p2 && [ViewerController computeIntervalForDCMPix: p1 And: p2] < 0)
						{
							//Inverse the array
							a = [[a reverseObjectEnumerator] allObjects];	//[a sortedArrayUsingDescriptors: [self sortDescriptorsForImages]];
							
							preFlippedData = YES;
							flipped = YES;
						}
						
						[p1 release];
						[p2 release];
					}
					@catch (NSException * e) 
					{
						NSLog( @"***** exception in %s: %@ / Pre-Flip Data", __PRETTY_FUNCTION__, e);
						[AppController printStackTrace: e];
					}
				}
				
				[resortedToOpenArray addObject: a];
				[isFlippedData addObject: [NSNumber numberWithBool: flipped]];
			}
			
			if( preFlippedData)
				toOpenArray = resortedToOpenArray;
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++)
			{
				fVolumePtr = malloc( memBlockSize[ x] * sizeof(float));
				unsigned long mem = 0;
				
				if( fVolumePtr)
				{
					volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:memBlockSize[ x]*sizeof( float) freeWhenDone:YES];
					NSArray *loadList = [toOpenArray objectAtIndex: x];
					
					if( [loadList count])
						[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality: [[loadList objectAtIndex: 0] valueForKeyPath:@"series.study.modality"] description:[[loadList objectAtIndex: 0] valueForKeyPath:@"series.study.studyName"]];
					
					// Why viewerPix[0] (fixed value) within the loop? Because it's not a 4D volume !
					viewerPix[0] = [[NSMutableArray alloc] initWithCapacity:0];
					NSMutableArray *correspondingObjects = [[NSMutableArray alloc] initWithCapacity:0];
					
					if( [loadList count] == 1 && [[[loadList objectAtIndex: 0] valueForKey:@"numberOfFrames"] intValue] > 1)
					{
						multiFrame = YES;							
						NSManagedObject*  curFile = [loadList objectAtIndex: 0];
						
						for( unsigned long i = 0; i < [[curFile valueForKey:@"numberOfFrames"] intValue]; i++)
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: 0];								
							DCMPix*	dcmPix = [[DCMPix alloc] initWithPath: [curFile valueForKey:@"completePath"] :i :[[curFile valueForKey:@"numberOfFrames"] intValue] :fVolumePtr+mem :i :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj:curFile];
							
							if( dcmPix)
							{
								mem += ([[curFile valueForKey:@"width"] intValue]) * ([[curFile valueForKey:@"height"] intValue]);
								
								[viewerPix[0] addObject: dcmPix];
								[correspondingObjects addObject: curFile];
								[dcmPix release];
							}
						} //end for
					}
					else
					{
						//multiframe==NO
						for( unsigned long i = 0; i < [loadList count]; i++)
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: i];
							DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [curFile valueForKey:@"completePath"] :i :[loadList count] :fVolumePtr+mem :[[curFile valueForKey:@"frameID"] intValue] :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj:curFile];
							
							if( dcmPix)
							{
								mem += ([[curFile valueForKey:@"width"] intValue]) * ([[curFile valueForKey:@"height"] intValue]);
								
								[viewerPix[0] addObject: dcmPix];
								[correspondingObjects addObject: curFile];
								[dcmPix release];
							}
							else
							{
								NSLog( @"not readable: %@", [curFile valueForKey:@"completePath"]);
							}
						}
					}
					
					if( [viewerPix[0] count] != [loadList count] && multiFrame == NO)
					{
						for( unsigned int i = 0; i < [viewerPix[0] count]; i++)
						{
							[[viewerPix[0] objectAtIndex: i] setID: i];
							[[viewerPix[0] objectAtIndex: i] setTot: [viewerPix[0] count]];
						}
						if( [viewerPix[0] count] == 0)
							NSRunCriticalAlertPanel( NSLocalizedString(@"Files not available (readable)", nil), NSLocalizedString(@"No files available (readable) in this series.", nil), NSLocalizedString(@"Continue",nil), nil, nil);
						else
							NSRunCriticalAlertPanel( NSLocalizedString(@"Not all files available (readable)", nil),  [NSString stringWithFormat: NSLocalizedString(@"Not all files are available (readable) in this series.\r%d file(s) are missing.", nil), [loadList count] - [viewerPix[0] count]], NSLocalizedString(@"Continue",nil), nil, nil);
					}
					//opening images refered to in viewerPix[0] in the adequate viewer
					
					int copySyncro = [DCMView syncro];
					[DCMView setSyncro: syncroOFF];
					BOOL copyCOPYSETTINGS = [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"];
					[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"COPYSETTINGS"];
					
					if( [viewerPix[0] count] > 0)
					{
						if( movieViewer == NO)
						{
							if( multiFrame == YES)
							{
								NSMutableArray  *filesAr = [[NSMutableArray alloc] initWithCapacity: [viewerPix[0] count]];
								
								if( [correspondingObjects count])
								{
									for( unsigned int i = 0; i < [viewerPix[0] count]; i++)
										[filesAr addObject: [correspondingObjects objectAtIndex:0]];
								}
								
								if( viewer)
								{
									//reuse of existing viewer
									[viewer changeImageData:viewerPix[0] :filesAr :volumeData :NO];
									[viewer startLoadImageThread];
								}
								else
								{
									//creation of new viewer
									createdViewer = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles:filesAr withVolume:volumeData];
									[createdViewer showWindowTransition];
									[createdViewer startLoadImageThread];
								}		
								
								[filesAr release];
							}
							else
							{
								//multiframe == NO
								if( viewer)
								{
									//reuse of existing viewer 
									[viewer changeImageData:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData :NO ];
									[viewer startLoadImageThread];
									
									if( [[isFlippedData objectAtIndex: x] boolValue])
										[viewer flipDataSeries: self];
								}
								else
								{
									//creation of new viewer
									createdViewer = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles: [NSMutableArray arrayWithArray: correspondingObjects] withVolume:volumeData];
									[createdViewer showWindowTransition];
									[createdViewer startLoadImageThread];
									
									if( [[isFlippedData objectAtIndex: x] boolValue])
										[createdViewer flipDataSeries: self];
								}
							}
						}
						else
						{
							//movieViewer==YES
							if( movieController == nil)
								movieController = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles:[NSMutableArray arrayWithArray:correspondingObjects] withVolume:volumeData];
							else
								[movieController addMovieSerie:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData];
						}
						[volumeData release];
					}
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"])
					{
						// @"COPYSETTINGS" was activated in a sub function, keep it activated: for example, when fusion is activated during opening
					}
					else [[NSUserDefaults standardUserDefaults] setBool: copyCOPYSETTINGS forKey:@"COPYSETTINGS"];
					
					[DCMView setSyncro: copySyncro];
					
					[viewerPix[0] release];
					[correspondingObjects release];
				}
			} //end for
		}
		
		// NS_DURING (5) movieController activation
		
		if( movieController)
		{
			NSLog(@"openViewerFromImages-movieController activation");
			[movieController showWindowTransition];
			[movieController startLoadImageThread];
		}
		
		[[NSUserDefaults standardUserDefaults] setBool: savedAUTOHIDEMATRIX forKey:@"AUTOHIDEMATRIX"];		
	}
	@catch( NSException *e)
	{
		NSLog(@"Exception opening Viewer: %@", e);
		[AppController printStackTrace: e];
		NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), [NSString stringWithFormat: NSLocalizedString(@"Opening Error : %@\r\r%@", nil), e, [AppController printStackTrace: e]] , nil, nil, nil);
	}
	
	free( memBlockSize);
	
	if( movieController) createdViewer = movieController;
	
	return createdViewer;
}

- (IBAction) selectSubSeriesAndOpen:(id) sender
{
	[NSApp stopModalWithCode: 2];
}

- (IBAction) selectAll3DSeries:(id) sender
{
	[NSApp stopModalWithCode: 6];
}

- (IBAction) reparseIn3D:(id) sender
{
	[NSApp stopModalWithCode: 10];
}

- (IBAction) reparseIn4D:(id) sender
{
	[NSApp stopModalWithCode: 11];
}

- (IBAction) selectAll4DSeries:(id) sender
{
	if( [subOpenMatrix4D isEnabled] == YES)
		[NSApp stopModalWithCode: 7];
}

- (void) processOpenViewerDICOMFromArray:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer: (ViewerController*) viewer
{
	long numberImages;
	BOOL movieError = NO, tryToFlipData = NO;
	
	if( [toOpenArray count] > 2)
	{
		if( waitOpeningWindow == nil) waitOpeningWindow = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
	}
	[waitOpeningWindow showWindow:self];

	numberImages = 0;
	if( movieViewer == YES) // First check if all series contain same amount of images
	{
		if( [toOpenArray count] == 1)	// Just one thumbnail is selected, check if multiples lines are selected
		{
			NSArray			*singleSeries = [toOpenArray objectAtIndex: 0];
			NSMutableArray	*splittedSeries = [NSMutableArray array];
			
			float interval, previousinterval = 0;
			
			[splittedSeries addObject: [NSMutableArray array]];
			
			if( [singleSeries count] > 1)
			{
				[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
				
				interval = [[[singleSeries objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: 1] valueForKey:@"sliceLocation"] floatValue];
				
				if( interval == 0)	// 4D - 3D
				{
					int pos3Dindex = 1;
					for( int x = 1; x < [singleSeries count]; x++)
					{
						interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
						
						if( interval != 0)
							pos3Dindex = 0;
						
						if( [splittedSeries count] <= pos3Dindex) [splittedSeries addObject: [NSMutableArray array]];
						
						[[splittedSeries objectAtIndex: pos3Dindex] addObject: [singleSeries objectAtIndex: x]];
						
						pos3Dindex++;
					}
				}
				else	// 3D - 4D
				{				
					for( int x = 1; x < [singleSeries count]; x++)
					{
						interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
						
						if( (interval < 0 && previousinterval > 0) || (interval > 0 && previousinterval < 0))
						{
							[splittedSeries addObject: [NSMutableArray array]];
							//NSLog(@"split at: %d", x);
							
							previousinterval = 0;
						}
						else if( previousinterval)
						{
							if( fabs(interval/previousinterval) > 2.0f || fabs(interval/previousinterval) < 0.5f)
							{
								[splittedSeries addObject: [NSMutableArray array]];
								//NSLog(@"split at: %d", x);
								previousinterval = 0;
							}
							else previousinterval = interval;
						}
						else previousinterval = interval;
						
						[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: x]];
					}
				}
			}
			
			toOpenArray = splittedSeries;
		}
		
		if( [toOpenArray count] == 1)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"To see an animated series, you have to select multiple series of the same area at different times: e.g. a cardiac CT", nil), NSLocalizedString(@"OK",nil), nil, nil);
			movieError = YES;
		}
		else if( [toOpenArray count] >= MAX4D)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), [NSString stringWithFormat: NSLocalizedString(@"4D Player is limited to a maximum number of %d series.", nil), MAX4D], NSLocalizedString(@"OK",nil), nil, nil);
			movieError = YES;
		}
		else
		{
			numberImages = -1;
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++)
			{
				if( numberImages == -1)
				{
					numberImages = [[toOpenArray objectAtIndex: x] count];
				}
				else if( [[toOpenArray objectAtIndex: x] count] != numberImages)
				{
					NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"),  NSLocalizedString(@"In the current version, all series must contain the same number of images.",@"In the current version, all series must contain the same number of images."), NSLocalizedString(@"OK",nil), nil, nil);
					movieError = YES;
					x = [toOpenArray count];
				}
			}
		}
	}
	else
	{
		tryToFlipData = YES;
		
		if( [toOpenArray count] == 1)	// Just one thumbnail is selected
		{
			if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
			{
				NSArray			*singleSeries = [[toOpenArray objectAtIndex: 0] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: @"instanceNumber" ascending: YES] autorelease]]];
				NSMutableArray	*splittedSeries = [NSMutableArray array];
				NSMutableArray  *intervalArray = [NSMutableArray array];
				
				float interval, previousinterval = 0;
				
				[splittedSeries addObject: [NSMutableArray array]];
				
				if( [singleSeries count] > 1)
				{
					[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
					
					if( [[[singleSeries lastObject] valueForKey: @"numberOfFrames"] intValue] > 1)
					{
						for( id o in singleSeries)	//We need to extract the *true* sliceLocation
						{
							DCMPix *p = [[DCMPix alloc] initWithPath:[o valueForKey:@"completePath"] :0 :1 :nil :[[o valueForKey:@"frameID"] intValue] :[[o valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: o];
							
							[intervalArray addObject: [NSNumber numberWithFloat: [p sliceLocation]]];
							
							[p release];
						}
					}
					else
					{
						for( id o in singleSeries)
							[intervalArray addObject: [NSNumber numberWithFloat: [[o valueForKey:@"sliceLocation"] floatValue]]];
					}
					
					interval = [[intervalArray objectAtIndex: 0] floatValue] - [[intervalArray objectAtIndex: 1] floatValue];
					
					if( interval == 0)
					{ // 4D - 3D
						int pos3Dindex = 1;
						for( int x = 1; x < [singleSeries count]; x++)
						{
							interval = [[intervalArray objectAtIndex: x -1] floatValue] - [[intervalArray objectAtIndex: x] floatValue];
							
							if( interval != 0) pos3Dindex = 0;
							
							if( [splittedSeries count] <= pos3Dindex) [splittedSeries addObject: [NSMutableArray array]];
							
							[[splittedSeries objectAtIndex: pos3Dindex] addObject: [singleSeries objectAtIndex: x]];
							
							pos3Dindex++;
						}
					}
					else
					{	// 3D - 4D
						BOOL	fixedRepetition = YES;
						int		repetition = 0, previousPos = 0;
						float	previousLocation;
						
						previousLocation = [[intervalArray objectAtIndex: 0] floatValue];
						
						for( int x = 1; x < [singleSeries count]; x++)
						{
							if( [[intervalArray objectAtIndex: x] floatValue] - previousLocation == 0)
							{
								if( repetition)
									if( repetition != x - previousPos)
										fixedRepetition = NO;
								
								repetition = x - previousPos;
								previousPos = x;
							}
						}
						
						if( fixedRepetition && repetition != 0)
						{
							NSLog( @"repetition = %d", repetition);
							
							for( int x = 1; x < [singleSeries count]; x++)
							{
								if( x % repetition == 0)
								{
									[splittedSeries addObject: [NSMutableArray array]];
									//NSLog(@"split at: %d", x);
								}
								
								[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: x]];
							}
						}
						else
						{
							for( int x = 1; x < [singleSeries count]; x++)
							{
								interval = [[intervalArray objectAtIndex: x -1] floatValue] - [[intervalArray objectAtIndex: x] floatValue];
								
								if( [[splittedSeries lastObject] count] > 2)
								{
									if( (interval < 0 && previousinterval > 0) || (interval > 0 && previousinterval < 0))
									{
										[splittedSeries addObject: [NSMutableArray array]];
										//NSLog(@"split at: %d", x);
										previousinterval = 0;
									}
									else if( previousinterval)
									{
										if( fabs(interval/previousinterval) > 1.2f || fabs(interval/previousinterval) < 0.8f)
										{
											[splittedSeries addObject: [NSMutableArray array]];
											//NSLog(@"split at: %d", x);
											previousinterval = 0;
										}
										else previousinterval = interval;
									}
									else previousinterval = interval;
								}
								else previousinterval = interval;
								
								[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: x]];
							}
						}
					}
				}
				
				if( [splittedSeries count] > 1)
				{
					[waitOpeningWindow close];
					[waitOpeningWindow release];
					waitOpeningWindow = nil;
					
					[subOpenMatrix3D renewRows: 1 columns: [splittedSeries count]];
					[subOpenMatrix3D sizeToCells];
					[subOpenMatrix3D setTarget:self];
					[subOpenMatrix3D setAction: @selector( selectSubSeriesAndOpen:)];
					
					[subOpenMatrix4D renewRows: 1 columns: [[splittedSeries objectAtIndex: 0] count]];
					[subOpenMatrix4D sizeToCells];
					[subOpenMatrix4D setTarget:self];
					[subOpenMatrix4D setAction: @selector( selectSubSeriesAndOpen:)];
					
					[[supOpenButtons cellWithTag: 3] setEnabled: YES];
					
					BOOL areData4D = YES;
					
					NSArray *array0 = [splittedSeries objectAtIndex: 0];
					
					for( NSArray *array in splittedSeries)
					{
						if( [array0 count] != [array count])
						{
							[[supOpenButtons cellWithTag: 3] setEnabled: NO];
							areData4D = NO;
						}
					}
					
					for( int i = 0 ; i < [splittedSeries count]; i++)
					{
						NSManagedObject	*oob = [[splittedSeries objectAtIndex:i] objectAtIndex: [[splittedSeries objectAtIndex:i] count] / 2];
						
						DCMPix *dcmPix  = [[DCMPix alloc] initWithPath:[oob valueForKey:@"completePath"] :0 :1 :nil :[[oob valueForKey:@"frameID"] intValue] :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: oob];
						
						if( dcmPix)
						{
							NSImage	 *img = [dcmPix generateThumbnailImageWithWW:[[oob valueForKeyPath: @"series.windowWidth"] floatValue] WL: [[oob valueForKeyPath: @"series.windowLevel"] floatValue]];
							
							NSButtonCell *cell = [subOpenMatrix3D cellAtRow:0 column: i];
							[cell setTransparent:NO];
							[cell setEnabled:YES];
							[cell setFont:[NSFont systemFontOfSize:10]];
							[cell setImagePosition: NSImageBelow];
							[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d/%d Images", nil), i+1, [[splittedSeries objectAtIndex:i] count]]];
							[cell setImage: img];
							[dcmPix release];
						}
					}
					
					if( areData4D)
					{
						for( int i = 0 ; i < [[splittedSeries objectAtIndex: 0] count]; i++)
						{
							NSManagedObject	*oob = [[splittedSeries objectAtIndex: 0] objectAtIndex: i];
							
							DCMPix *dcmPix  = [[DCMPix alloc] initWithPath:[oob valueForKey:@"completePath"] :0 :1 :nil :[[oob valueForKey:@"frameID"] intValue] :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: oob];
							
							if( dcmPix)
							{
								NSImage	 *img = [dcmPix generateThumbnailImageWithWW:[[oob valueForKeyPath: @"series.windowWidth"] floatValue] WL:[[oob valueForKeyPath: @"series.windowLevel"] floatValue]];
								
								NSButtonCell *cell = [subOpenMatrix4D cellAtRow:0 column: i];
								[cell setTransparent:NO];
								[cell setEnabled:YES];
								[cell setFont:[NSFont systemFontOfSize:10]];
								[cell setImagePosition: NSImageBelow];
								[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d/%d Images", nil), i+1, [splittedSeries count]]];
								[cell setImage: img];
								[dcmPix release];
							}
						}
					}
					else
					{
						[subOpenMatrix4D renewRows: 0 columns: 0];
						[subOpenMatrix4D sizeToCells];
						[subOpenMatrix4D setEnabled: NO];
					}
					
					[NSApp beginSheet: subOpenWindow
					   modalForWindow:	[NSApp mainWindow]
						modalDelegate: nil
					   didEndSelector: nil
						  contextInfo: nil];
					
					int result = [NSApp runModalForWindow: subOpenWindow];
					[subOpenWindow makeFirstResponder: nil];
					
					if( result == 2)
					{
						[supOpenButtons selectCellWithTag: 2];
						
						if( [subOpenMatrix3D selectedColumn] < 0)
						{
							if( [subOpenMatrix4D selectedColumn] < 0) result = 0;
							else result = 5;
						}
					}
					else if( result == 6)
					{
						NSLog( @"Open all 3D");
					}
					else if( result == 7)
					{
						NSLog( @"Open all 4D");
					}
					else if( result == 10)
					{
						NSLog( @"Reparse in 3D");
						
						// Create the new series
						
						NSManagedObjectContext *context = [self managedObjectContext];
						
						[context lock];
						
						@try
						{					
							int reparseIndex = 1;
							
							DicomSeries *originalSeries = [[[splittedSeries lastObject] lastObject] valueForKey: @"Series"];
							
							for( NSArray *array in splittedSeries)
							{
								DicomSeries *newSeries = [NSEntityDescription insertNewObjectForEntityForName: @"Series" inManagedObjectContext: context];
								
								for ( NSString *name in [[[NSEntityDescription entityForName: @"Series" inManagedObjectContext: context] attributesByName] allKeys]) // Duplicate values
								{
									id value = nil;
									
									if( [name isEqualToString: @"seriesInstanceUID"])
										value = [[originalSeries valueForKey: name] stringByAppendingFormat: @"RP-%d", reparseIndex++];
									else
										value = [originalSeries valueForKey: name];
										
									if( value)
										[newSeries setValue: value forKey: name];
								}
								
								[newSeries setValue: [originalSeries valueForKey: @"study"] forKey: @"study"];
								
								// Add the images
								for( DicomImage *image in array)
								{
									DicomImage *newImage = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: context];
								
									for ( NSString *name in [[[NSEntityDescription entityForName: @"Image" inManagedObjectContext: context] attributesByName] allKeys]) // Duplicate values
									{
										[newImage setValue: [image valueForKey: name] forKey: name];
									}
									
									[image setValue: newSeries forKey: @"series"];
								}
								
								[newSeries setValue: [NSNumber numberWithInt: 0] forKey: @"numberOfImages"];
								[newSeries setValue: nil forKey:@"thumbnail"];
							}
								
							[context deleteObject: originalSeries];
							
							[context save: nil];
						}
						@catch (NSException * e)
						{
							NSLog( @"***** exception during reparsing : %@", e);
							[AppController printStackTrace: e];
						}
						
						[context unlock];
						
						[self refreshDatabase: self];
						[self refreshMatrix: self];
						
						result = 0;
					}
					else if( result == 11)
					{
						NSLog( @"Reparse in 4D");
						
						// Create the new series
						
						NSManagedObjectContext *context = [self managedObjectContext];
						
						[context lock];
						
						@try
						{					
							int reparseIndex = 1;
							
							DicomSeries *originalSeries = [[[splittedSeries lastObject] lastObject] valueForKey: @"Series"];
							
							for( int i = 0; i < [[splittedSeries objectAtIndex: 0] count]; i++)
							{
								NSMutableArray	*array4D = [NSMutableArray array];
								
								for ( NSArray *array in splittedSeries)
									[array4D addObject: [array objectAtIndex: i]];
								
								DicomSeries *newSeries = [NSEntityDescription insertNewObjectForEntityForName: @"Series" inManagedObjectContext: context];
								
								for ( NSString *name in [[[NSEntityDescription entityForName: @"Series" inManagedObjectContext: context] attributesByName] allKeys]) // Duplicate values
								{
									id value = nil;
									
									if( [name isEqualToString: @"seriesInstanceUID"])
										value = [[originalSeries valueForKey: name] stringByAppendingFormat: @"RP-%d", reparseIndex++];
									else
										value = [originalSeries valueForKey: name];
										
									if( value)
										[newSeries setValue: value forKey: name];
								}
								
								[newSeries setValue: [originalSeries valueForKey: @"study"] forKey: @"study"];
								
								// Add the images
								for( DicomImage *image in array4D)
								{
									DicomImage *newImage = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: context];
								
									for ( NSString *name in [[[NSEntityDescription entityForName: @"Image" inManagedObjectContext: context] attributesByName] allKeys]) // Duplicate values
									{
										[newImage setValue: [image valueForKey: name] forKey: name];
									}
									
									[image setValue: newSeries forKey: @"series"];
								}
								
								[newSeries setValue: [NSNumber numberWithInt: 0] forKey: @"numberOfImages"];
								[newSeries setValue: nil forKey:@"thumbnail"];
							}
							
							[context deleteObject: originalSeries];
							
							[context save: nil];
						}
						@catch (NSException * e)
						{
							NSLog( @"***** exception during reparsing : %@", e);
							[AppController printStackTrace: e];
						}
						
						[context unlock];
						
						[self refreshDatabase: self];
						[self refreshMatrix: self];
						
						result = 0;
					}
					else
					{
						result = [supOpenButtons selectedTag];
					}
					
					[NSApp endSheet: subOpenWindow];
					[subOpenWindow orderOut: self];
					
					switch( result)
					{
						case 0:	// Cancel
							movieError = YES;
							break;
							
						case 1: // Entire
							
							break;
							
						case 2: // selected 3D
							toOpenArray = [NSMutableArray arrayWithObject: [splittedSeries objectAtIndex: [subOpenMatrix3D selectedColumn]]];
							break;
							
						case 3:	// 4D Viewer
							toOpenArray = splittedSeries;
							movieViewer = YES;
							break;
							
						case 5: // selected 4D
						{
							NSMutableArray	*array4D = [NSMutableArray array];
							
							for( NSArray *array in splittedSeries)
							{
								[array4D addObject: [array objectAtIndex: [subOpenMatrix4D selectedColumn]]];
							}
							
							toOpenArray = [NSMutableArray arrayWithObject: array4D];
						}
						break;
							
						case 6:
							
							if( waitOpeningWindow == nil) waitOpeningWindow = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
							[waitOpeningWindow showWindow:self];
							
							for( NSArray *array in splittedSeries)
							{
								toOpenArray = [NSMutableArray arrayWithObject: array];
								[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
							}
							toOpenArray = 0;
						break;
							
						case 7:
						{
								BOOL openAllWindows = YES;
								
								if( [[splittedSeries objectAtIndex: 0] count] > 25)
								{
									openAllWindows = NO;
									
									if( NSRunInformationalAlertPanel( NSLocalizedString(@"Series Opening", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to open %d windows? It's a lot of windows for this screen...", nil), [[splittedSeries objectAtIndex: 0] count]], NSLocalizedString(@"Yes", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
										openAllWindows = YES;
								}
								
								if( openAllWindows)
								{
									if( waitOpeningWindow == nil) waitOpeningWindow = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
									[waitOpeningWindow showWindow:self];
									
									for( int i = 0; i < [[splittedSeries objectAtIndex: 0] count]; i++)
									{
										NSMutableArray	*array4D = [NSMutableArray array];
										
										for ( NSArray *array in splittedSeries)
										{
											[array4D addObject: [array objectAtIndex: i]];
										}
										
										toOpenArray = [NSMutableArray arrayWithObject: array4D];
										
										[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
									}
								}
								toOpenArray = nil;
						}
						break;
					}
				}
			}
		}
	}
	
	if( movieError == NO && toOpenArray != nil)
		[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO tryToFlipData: tryToFlipData];
		
	[waitOpeningWindow close];
	[waitOpeningWindow release];
	waitOpeningWindow = nil;
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer
{
	return [self viewerDICOMInt:  movieViewer dcmFile: selectedLines viewer: viewer tileWindows: YES];
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer tileWindows: (BOOL) tileWindows
{
	if( [selectedLines count] == 0) return;
	
	[_database lock];
	
	@try
	{
		NSManagedObject		*selectedLine = [selectedLines objectAtIndex: 0];
		NSInteger			row, column;
		NSMutableArray		*selectedFilesList;
		NSArray				*loadList;
			
		NSArray				*cells = [oMatrix selectedCells];
		
		if( [cells count] == 0 && [[oMatrix cells] count] > 0)
		{
			cells = [NSArray arrayWithObject: [[oMatrix cells] objectAtIndex: 0]];
		}
		
		//////////////////////////////////////
		// Open selected images only !!!
		//////////////////////////////////////
		
		if( [cells count] > 1 && [[selectedLine valueForKey:@"type"] isEqualToString: @"Series"])
		{
			NSArray  *curList = [self childrenArray: selectedLine];
			
			selectedFilesList = [[NSMutableArray alloc] initWithCapacity:0];
			
			for( NSCell* c in cells)
			{
				NSManagedObject*  curImage = [curList objectAtIndex: [c tag]];
				[selectedFilesList addObject: curImage];
			}
			
			[self openViewerFromImages :[NSArray arrayWithObject: selectedFilesList] movie: movieViewer viewer :viewer keyImagesOnly:NO];
			
			[selectedFilesList release];
		}
		else
		{
			//////////////////////////////////////
			// Open series !!!
			//////////////////////////////////////
			
			//////////////////////////////////////
			// Prepare an array that contains arrays of series
			//////////////////////////////////////
			
			NSMutableArray	*toOpenArray = [NSMutableArray array];
			
			int x = 0;
			if( [cells count] == 1 && [selectedLines count] > 1)	// Just one thumbnail is selected, but multiples lines are selected
			{
				for( NSManagedObject* curFile in selectedLines)
				{
					x++;
					loadList = nil;
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Study"])
					{
						// Find the first series of images! DONT TAKE A ROI SERIES !
						if( [[curFile valueForKey:@"imageSeries"] count])
						{
							curFile = [[curFile valueForKey:@"imageSeries"] objectAtIndex: 0];
							loadList = [self childrenArray: curFile];
						}
					}
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"])
					{
						loadList = [self childrenArray: curFile];
					}
					
					if( loadList) [toOpenArray addObject: loadList];
				}
			}
			else
			{
				for( NSButtonCell *cell in cells)
				{
					x++;
					if( [oMatrix getRow: &row column: &column ofCell: cell] == NO)
					{
						row = 0;
						column = 0;
					}
					
					loadList = nil;
					
					NSManagedObject*  curFile = [matrixViewArray objectAtIndex: [cell tag]];
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"]) loadList = [self childrenArray: selectedLine onlyImages: YES];
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"]) loadList = [self childrenArray: curFile onlyImages: YES];
					
					if( loadList) [toOpenArray addObject: loadList];
				}
			}
			
			[self processOpenViewerDICOMFromArray: toOpenArray movie: movieViewer viewer: viewer];
		}
		
		if( tileWindows)
		{
			NSArray *viewers = [ViewerController getDisplayed2DViewers];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
			{
				[[AppController sharedAppController] tileWindows: nil];
				
				if( [viewers count] > 1)
				{
					ViewerController *kV = nil;
					
					for( ViewerController *v in viewers)
					{
						[[v imageView] scaleToFit];
						[[v imageView] setOriginX:0 Y:0];
						
						if( [[v window] isKeyWindow]) kV = v;
					}
					
					[kV propagateSettings];
				}
			}
			else
				[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"viewerDICOMInt exception: %@", e);
		[AppController printStackTrace: e];
		NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), [NSString stringWithFormat: NSLocalizedString(@"Opening Error : %@\r\r%@", nil), e, [AppController printStackTrace: e]] , nil, nil, nil);
	}
	
	[_database unlock];
}

- (void) viewerSubSeriesDICOM: (id)sender
{
	openSubSeriesFlag = YES;
	[self viewerDICOM: sender];
	openSubSeriesFlag = NO;
}

- (void) viewerDICOM: (id)sender
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) 
		[self viewerDICOMMergeSelection: sender];
	else
	{
		if( [[self window] firstResponder] == databaseOutline)
			[self newViewerDICOM: nil];
		else
			[self newViewerDICOM: sender];
	}
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void)newViewerDICOM: (id)sender
{
	NSManagedObject	*item = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
	
	[_database lock];
	
	@try 
	{
		if (sender == Nil && [[oMatrix selectedCells] count] == 1 && [[item valueForKey:@"type"] isEqualToString:@"Study"] == YES)
		{
			NSArray *array = [self databaseSelection];
			
			BOOL savedValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"];
			
			if( [array count] > 1 && savedValue == YES) [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"automaticWorkspaceLoad"];
			
			for( id obj in array)
			{
				[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: obj]] byExtendingSelection: NO];
				[self databaseOpenStudy: obj];
			}
			
			if( [array count] > 1 && savedValue == YES) [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"automaticWorkspaceLoad"];
		}
		else
		{
			if( [matrixViewArray count] > [[oMatrix selectedCell] tag] && [self isUsingExternalViewer: [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]]] == NO)
			{
				//To avoid loading the dcmpix in previewSliderAction
				dontUpdatePreviewPane = YES;
				[self viewerDICOMInt: NO dcmFile: [self databaseSelection] viewer: nil];
				dontUpdatePreviewPane = NO;
				
				[self previewSliderAction: nil];
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	[_database unlock];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDidLoadNewObjectNotification object:item userInfo:nil];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void)viewerDICOMMergeSelection: (id)sender
{
	NSMutableArray	*images = [NSMutableArray array];
	
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: images];
	else [self filesForDatabaseOutlineSelection: images];
	
	[self openViewerFromImages :[NSArray arrayWithObject:images] movie: 0 viewer :nil keyImagesOnly:NO];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
	else
		[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];;
}

- (void) viewerDICOMROIsImages:(id) sender
{
	NSArray *roisImagesArray = [self ROIImages: sender];
	
	if( [roisImagesArray count])
	{
		dontShowOpenSubSeries = YES;
		[self openViewerFromImages :[NSArray arrayWithObject: roisImagesArray] movie: 0 viewer :nil keyImagesOnly:NO];
		dontShowOpenSubSeries = NO;
		
		if(	[[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
			[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
		else
			[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
	}
	else
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"ROIs Images", nil), NSLocalizedString(@"No images containing ROIs are found in this selection.", nil), NSLocalizedString(@"OK",nil), nil, nil);
	}
	
#ifndef OSIRIX_LIGHT
	BOOL escKey = CGEventSourceKeyState( kCGEventSourceStateCombinedSessionState, 53);
	
	if( escKey) //Open the images, and export them
	{
		if( [[ViewerController getDisplayed2DViewers] count])
		{
			ViewerController *v = [[ViewerController getDisplayed2DViewers] objectAtIndex: 0];
			
			[v exportAllImages: @"ROIs images"];
			
			[[v window] close];
		}
	}
#endif
}

- (void) viewerDICOMKeyImages:(id) sender
{
	NSMutableArray	*selectedItems = [NSMutableArray array];
	
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];
	
	dontShowOpenSubSeries = YES;
	[self openViewerFromImages :[NSArray arrayWithObject:selectedItems] movie: 0 viewer :nil keyImagesOnly:YES];
	dontShowOpenSubSeries = NO;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
	else
		[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
	
#ifndef OSIRIX_LIGHT
	BOOL escKey = CGEventSourceKeyState( kCGEventSourceStateCombinedSessionState, 53);
	
	if( escKey) //Open the images, and export them
	{
		if( [[ViewerController getDisplayed2DViewers] count])
		{
			ViewerController *v = [[ViewerController getDisplayed2DViewers] objectAtIndex: 0];
			
			[v exportAllImages: @"Key images"];
			
			[[v window] close];
		}
	}
#endif
}

- (void) MovieViewerDICOM:(id) sender
{
	NSInteger				index;
	NSMutableArray			*selectedItems = [NSMutableArray array];
	
	NSIndexSet				*selectedRowIndexes = [databaseOutline selectedRowIndexes];
	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
		if ([selectedRowIndexes containsIndex:index]) [selectedItems addObject: [databaseOutline itemAtRow:index]];
	}
	
	[self viewerDICOMInt:YES dcmFile: selectedItems viewer:nil];
}

static NSArray*	openSubSeriesArray = nil;

- (NSArray*)produceNewArray: (NSArray*)toOpenArray
{
	NSMutableArray *newArray = [NSMutableArray array];
	
	int from = subFrom-1, to = subTo, interval = subInterval;
	
	if( interval < 1) interval = 1;
	
	int max = 0;
	
	for( NSArray *loadList in toOpenArray)
	{		
		if( max < [loadList count]) max = [loadList count];
		
		if( from >= to) from = to-1;
		if( from < 0) from = 0;
		if( to < 0) to = 0;
	}
	
	if( from > max) from = max;
	if( to > max) to = max;
	
	for( NSArray *loadList in toOpenArray)
	{
		from = subFrom-1;
		to = subTo;
		
		if( from >= [loadList count]) from = [loadList count];
		if( to >= [loadList count]) to = [loadList count];
		
		NSMutableArray *imagesArray = [NSMutableArray array];
		
		for( int i = from; i < to; i++)
		{
			NSManagedObject	*image = [loadList objectAtIndex: i];
			
			if( i % interval == 0) [imagesArray addObject: image];
		}
		
		[imagesArray sortUsingDescriptors: [self sortDescriptorsForImages]];
		
		if( [imagesArray count] > 0)
			[newArray addObject: imagesArray];
	}
	
	return newArray;
}

- (IBAction) checkMemory:(id) sender
{
	unsigned long mem;
	
	if( [self computeEnoughMemory: [self produceNewArray: openSubSeriesArray] :&mem])
	{
		[notEnoughMem setHidden: YES];
		[enoughMem setHidden: NO];
		[subSeriesOKButton setEnabled: YES];
		
		[memoryMessage setStringValue: [NSString stringWithFormat: NSLocalizedString( @"Enough Memory ! (%d MB needed)", nil),  mem * sizeof(float)]];
	}
	else
	{
		[notEnoughMem setHidden: NO];
		[enoughMem setHidden: YES];
		[subSeriesOKButton setEnabled: NO];
		
		[memoryMessage setStringValue: [NSString stringWithFormat: NSLocalizedString( @"Not Enough Memory ! (%d MB needed)", nil), mem* sizeof(float)]];
	}
}

- (void) setSubInterval: (id)sender
{
	subInterval = [sender intValue];
	
	[self checkMemory: self];
}

- (void) setSubFrom: (id)sender
{
	subFrom = [sender intValue];
	
	if( _database == nil) return;
//	if( bonjourDownloading) return;
	
	[animationSlider setIntValue: subFrom-1];
	
	BOOL copyDontUpdatePreviewPane = dontUpdatePreviewPane;
	
	dontUpdatePreviewPane = NO;
	[self previewSliderAction: nil];
	dontUpdatePreviewPane = copyDontUpdatePreviewPane;
	
	[self checkMemory: self];
}

- (void)setSubTo: (id)sender
{
	subTo = [sender intValue];
	
	if( _database == nil) return;
//	if( bonjourDownloading) return;
	
	[animationSlider setIntValue: subTo-1];
	
	
	BOOL copyDontUpdatePreviewPane = dontUpdatePreviewPane;
	
	dontUpdatePreviewPane = NO;
	[self previewSliderAction: nil];
	dontUpdatePreviewPane = copyDontUpdatePreviewPane;
	
	[self checkMemory: self];
}

- (NSArray*)openSubSeries: (NSArray*)toOpenArray
{
	[[waitOpeningWindow window] orderOut: self];
	
	int copySortSeriesBySliceLocation = [[NSUserDefaults standardUserDefaults] integerForKey: @"sortSeriesBySliceLocation"];
	
	openSubSeriesArray = [toOpenArray retain];
	
	if( [[NSApp mainWindow] level] > NSModalPanelWindowLevel){ NSBeep(); return nil;}		// To avoid the problem of displaying this sheet when the user is in fullscreen mode
	if( [[NSApp keyWindow] level] > NSModalPanelWindowLevel) { NSBeep(); return nil;}		// To avoid the problem of displaying this sheet when the user is in fullscreen mode
	
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subTo"];
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subMax"];
	
	[self setValue:[NSNumber numberWithInt:1] forKey:@"subFrom"];
	[self setValue:[NSNumber numberWithInt:1] forKey:@"subInterval"];
	
	[NSApp beginSheet: subSeriesWindow
	   modalForWindow: [NSApp mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	[self checkMemory: self];
	
	int result = [NSApp runModalForWindow: subSeriesWindow];
	[subSeriesWindow makeFirstResponder: nil];
	
	[NSApp endSheet: subSeriesWindow];
	[subSeriesWindow orderOut: self];
	
	[[waitOpeningWindow window] orderBack: self];
	
	NSArray *returnedArray = nil;
	
	if( result == NSRunStoppedResponse)
		returnedArray = [self produceNewArray: toOpenArray];
	
	[openSubSeriesArray release];
	
	[[NSUserDefaults standardUserDefaults] setInteger: copySortSeriesBySliceLocation forKey: @"sortSeriesBySliceLocation"];
	
	return returnedArray;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark GUI functions

- (void) checkResponder
{

}

+ (unsigned int)_currentModifierFlags
{
    unsigned int flags = 0;
    UInt32 currentKeyModifiers = GetCurrentKeyModifiers();
    if (currentKeyModifiers & cmdKey)
        flags |= NSCommandKeyMask;
    if (currentKeyModifiers & shiftKey)
        flags |= NSShiftKeyMask;
    if (currentKeyModifiers & optionKey)
        flags |= NSAlternateKeyMask;
    if (currentKeyModifiers & controlKey)
        flags |= NSControlKeyMask;
	
    return flags;
}

// For the DB: fullscreen is equivalent to 'go to the search field'

- (IBAction) switchSoundex: (id)sender
{
	[self setSearchString: _searchString];
}

- (IBAction) searchField: (id)sender
{
	// Is the item available in the toolbar?
	NSArray	*visibleItems = [toolbar visibleItems];
	
	for( id toolbarItem in visibleItems)
	{
		if( [[toolbarItem itemIdentifier] isEqualToString: SearchToolbarItemIdentifier])
		{
			[self.window makeFirstResponder: searchField];
			return;
		}
	}
	
	NSRunCriticalAlertPanel(NSLocalizedString(@"Search", nil), NSLocalizedString(@"The search field is currently not displayed in the toolbar. Customize your toolbar to add it.", nil), NSLocalizedString(@"OK", nil), nil, nil);
}

//- (void) autoTest:(id) sender
//{
//	if( autotestdone == NO)
//	{
//		autotestdone = YES;
//		// AUTO TEST
//		[self matrixDoublePressed: nil];
//		[[[ViewerController getDisplayed2DViewers] lastObject] checkEverythingLoaded];
//		[[[ViewerController getDisplayed2DViewers] lastObject] VRViewer: nil];
//	}
//}

+ (long) computeDATABASEINDEXforDatabase:(NSString*)path { // __deprecated
	return [[DicomDatabase databaseAtPath:path] computeDataFileIndex];
}

- (id)initWithWindow: (NSWindow *)window
{
	//displayEmptyDatabase = YES;
	
	[AppController initialize];
	
	for( int i = 0 ; i < [[NSScreen screens] count] ; i++)
	{
		visibleScreenRect[ i] = [[[NSScreen screens] objectAtIndex: i] visibleFrame];
	}
	
	self = [super initWithWindow: window];
	if( self)
	{
		// Remove identical local sources
		
		NSArray *dbArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
		NSMutableArray *filteredArray = [NSMutableArray arrayWithCapacity: [dbArray count]];
		
		for( NSDictionary *dict in dbArray)
		{
			BOOL duplicated = NO;
			
			for( NSDictionary *c in filteredArray)
			{
				if( c != dict)
				{
					if( [[dict valueForKey:@"Path"] isEqualToString: [c valueForKey: @"Path"]])
						duplicated = YES;
				}
			}
			
			if( duplicated == NO)
				[filteredArray addObject: dict];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject: filteredArray forKey: @"localDatabasePaths"];
		
		if( [BrowserController _currentModifierFlags] & NSShiftKeyMask && [BrowserController _currentModifierFlags] & NSAlternateKeyMask)
		{
			NSLog( @"WARNING ---- Protected Mode Activated");
			[DCMPix setRunOsiriXInProtectedMode: YES];
		}
		
		if( [DCMPix isRunOsiriXInProtectedModeActivated])
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"Protected Mode", nil), NSLocalizedString(@"OsiriX is now running in Protected Mode (shift + option keys at startup): no images are displayed, allowing you to delete crashing or corrupted images/studies.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		
		albumNoOfStudiesCache = [[NSMutableArray alloc] init];
//		newFilesConditionLock = [[NSConditionLock alloc] initWithCondition: 0];
//		viewersListToRebuild = [[NSMutableArray alloc] initWithCapacity: 0];
//		viewersListToReload = [[NSMutableArray alloc] initWithCapacity: 0];
	//	persistentStoreCoordinatorDictionary = [[NSMutableDictionary alloc] initWithCapacity: 0];
		databaseIndexDictionary = [[NSMutableDictionary alloc] initWithCapacity: 0];
		
		notFoundImage = [[NSImage imageNamed:@"FileNotFound.tif"] retain];
		
		reportFilesToCheck = [[NSMutableDictionary dictionary] retain];
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		
//		checkBonjourUpToDateThreadLock = [[NSRecursiveLock alloc] init];
//		checkIncomingLock = [[NSRecursiveLock alloc] init];
	//	decompressArrayLock = [[NSRecursiveLock alloc] init];
	//	decompressThreadRunning = [[NSRecursiveLock alloc] init];
		processorsLock = [[NSConditionLock alloc] initWithCondition: 1];
	//	decompressArray = [[NSMutableArray alloc] initWithCapacity: 0];
		
		DatabaseIsEdited = NO;
		
		previousBonjourIndex = -1;
		toolbarSearchItem = nil;
	//	managedObjectModel = nil;
	//	managedObjectContext = nil;
		
		_filterPredicateDescription = nil;
		_filterPredicate = nil;
		_fetchPredicate = nil;
		
		matrixViewArray = nil;
		
		previousNoOfFiles = 0;
		previousItem = nil;
		
		searchType = 7;
		timeIntervalType = 0;
		timeIntervalStart = timeIntervalEnd = nil;
		
		outlineViewArray = [[NSArray array] retain];
		browserWindow = self;
		
		COLUMN = 4;
		
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		self.database = [DicomDatabase activeLocalDatabase];
//		currentDatabasePath = [[[self documentsDirectory] stringByAppendingPathComponent:DATAFILEPATH] retain];
//		
//		NSString *dicomdir = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/DICOMDIR"];
//		NSString *dicomdirPath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/DICOMDIRPATH"];
//		
//		if ([[NSFileManager defaultManager] fileExistsAtPath:dicomdir])
//		{
//			DICOMDIRCDMODE = YES;
//			
//			[currentDatabasePath release];
//			currentDatabasePath = [[NSString stringWithString: @"/tmp/OsiriXTemporaryDatabase"] retain];
//			[[NSFileManager defaultManager] removeFileAtPath: currentDatabasePath handler: nil];
//			
//			[self loadDatabase: currentDatabasePath];
//			
//			NSMutableArray *filesArray = [NSMutableArray array];
//			[self addDICOMDIR:dicomdir: filesArray];
//			[self addFilesAndFolderToDatabase: filesArray];
//		}
//		else  if ([[NSFileManager defaultManager] fileExistsAtPath: dicomdirPath])
//		{
//			DICOMDIRCDMODE = YES;
//			
//			[currentDatabasePath release];
//			currentDatabasePath = [[NSString stringWithString: @"/tmp/OsiriXTemporaryDatabase"] retain];
//			[[NSFileManager defaultManager] removeFileAtPath: currentDatabasePath handler: nil];
//			
//			[self loadDatabase: currentDatabasePath];
//			
//			NSMutableArray *filesArray = [NSMutableArray array];
//			[self addDICOMDIR: [NSString stringWithContentsOfFile: dicomdirPath] :filesArray];
//			[self addFilesAndFolderToDatabase: filesArray];
//		}
//		else 
//			[self loadDatabase: currentDatabasePath];
//		
//		[self setFixedDocumentsDirectory];
//		[self setNetworkLogs];
		
		// NSString *str = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
		
//		shouldDie = NO;
//		bonjourDownloading = NO;
		
		previewPix = [[NSMutableArray alloc] initWithCapacity:0];
		
		timer = [[NSTimer scheduledTimerWithTimeInterval: 0.15 target:self selector:@selector(previewPerformAnimation:) userInfo:self repeats:YES] retain];
		if( [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] < 1)
			[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"LISTENERCHECKINTERVAL"];
		
//		IncomingTimer = [[NSTimer timerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] target:self selector:@selector(checkIncoming:) userInfo:self repeats:YES] retain];
//		
//		[[NSRunLoop currentRunLoop] addTimer: IncomingTimer forMode: NSModalPanelRunLoopMode];
//		[[NSRunLoop currentRunLoop] addTimer: IncomingTimer forMode: NSDefaultRunLoopMode];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
			refreshTimer = [[NSTimer scheduledTimerWithTimeInterval: 5*60 target:self selector:@selector(refreshDatabase:) userInfo:self repeats:YES] retain]; //
		
//		bonjourTimer = [[NSTimer scheduledTimerWithTimeInterval: 120 target:self selector:@selector(checkBonjourUpToDate:) userInfo:self repeats:YES] retain];	//120
//		databaseCleanerTimer = [[NSTimer scheduledTimerWithTimeInterval: 15*60 + 2.5 target:self selector:@selector(autoCleanDatabaseDate:) userInfo:self repeats:YES] retain]; // 20*60 + 2.5
		deleteQueueTimer = [[NSTimer scheduledTimerWithTimeInterval: 10 target:self selector:@selector(emptyDeleteQueue:) userInfo:self repeats:YES] retain]; // 10
//		autoroutingQueueTimer = [[NSTimer scheduledTimerWithTimeInterval: 30 target:self selector:@selector(emptyAutoroutingQueue:) userInfo:self repeats:YES] retain]; // 35
		
		
		loadPreviewIndex = 0;
		matrixDisplayIcons = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(matrixDisplayIcons:) userInfo:self repeats:YES] retain];
		
//		[[NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(newFilesGUIUpdate:) userInfo:self repeats:YES] retain]; // TODO: hmmm
		
		/* notifications from workspace */
//		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeMount:) name:NSWorkspaceDidMountNotification object:nil];
//		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
//		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(willVolumeUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowHasChanged:) name:NSWindowDidBecomeMainNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:OsirixReportModeChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionIsChangingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtstructNotification:) name:OsirixRTStructNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AlternateButtonPressed:) name:OsirixAlternateButtonPressedNotification object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:OsirixCloseViewerNotification object:nil];
				
//		[[NSNotificationCenter defaultCenter] addObserver: self
//												selector: @selector(listChangedTest:)
//												name: OsirixServerArrayChangedNotification
//												object: nil];
		
//		[[NSTimer scheduledTimerWithTimeInterval: 5 target:self selector:@selector(autoTest:) userInfo:self repeats:NO] retain];
		
	//	displayEmptyDatabase = NO;
	}
	return self;
}
//
//- (void) listChangedTest:(NSNotification*) n
//{
//	NSLog(@"********* NOTIF, %d", dontLoadSelectionSource);
//}

- (void) setDBDate
{
	[TimeFormat release];
	TimeFormat = [[NSDateFormatter alloc] init];
	[TimeFormat setTimeStyle: NSDateFormatterShortStyle];
	
	[TimeWithSecondsFormat release];
	TimeWithSecondsFormat = [[NSDateFormatter alloc] init];
	[TimeWithSecondsFormat setTimeStyle: NSDateFormatterMediumStyle];
	
	[DateTimeWithSecondsFormat release];
	DateTimeWithSecondsFormat = [[NSDateFormatter alloc] init];
	[DateTimeWithSecondsFormat setDateStyle: NSDateFormatterShortStyle];
	[DateTimeWithSecondsFormat setTimeStyle: NSDateFormatterMediumStyle];
	
//	[DateTimeFormat release];
//	DateTimeFormat = [[NSDateFormatter alloc] init];
//	[DateTimeFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateFormat2"]];
	
//	[DateOfBirthFormat release];
//	DateOfBirthFormat = [[NSDateFormatter alloc] init];
//	[DateOfBirthFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat2"]];
	
	[[[databaseOutline tableColumnWithIdentifier: @"dateOpened"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
	[[[databaseOutline tableColumnWithIdentifier: @"date"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
	[[[databaseOutline tableColumnWithIdentifier: @"dateAdded"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
	
	[[[databaseOutline tableColumnWithIdentifier: @"dateOfBirth"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
	[[[databaseOutline tableColumnWithIdentifier: @"reportURL"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
}

+ (NSString*) DateTimeWithSecondsFormat:(NSDate*) t
{
	NSString *s = nil;
	
	@synchronized( [[BrowserController currentBrowser] DateTimeWithSecondsFormat])
	{
		s = [[[BrowserController currentBrowser] DateTimeWithSecondsFormat] stringFromDate: t];  
	}
	
	return s;
}

+ (NSString*) TimeWithSecondsFormat:(NSDate*) t
{
	NSString *s = nil;
	
	@synchronized( [[BrowserController currentBrowser] TimeWithSecondsFormat])
	{
		s = [[[BrowserController currentBrowser] TimeWithSecondsFormat] stringFromDate: t];
	}
	
	return s;
}

+ (NSString*) TimeFormat:(NSDate*) t
{
	NSString *s = nil;
	
	@synchronized( [[BrowserController currentBrowser] TimeFormat])
	{
		s = [[[BrowserController currentBrowser] TimeFormat] stringFromDate: t];
	}
	return s;
}

- (NSDateFormatter*)DateOfBirthFormat { // __deprecated
	return  [NSUserDefaults dateFormatter];
}

+ (NSString*)DateOfBirthFormat:(NSDate*)d { // __deprecated
	return  [[NSUserDefaults dateFormatter] stringFromDate:d];
}

- (NSDateFormatter*)DateTimeFormat { // __deprecated
	return [NSUserDefaults dateTimeFormatter];
}

+ (NSString*)DateTimeFormat:(NSDate*)d { // __deprecated
	return [[NSUserDefaults dateTimeFormatter] stringFromDate:d];
}

- (void) createDBContextualMenu // DATABASE contextual menu
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Tools"] autorelease];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Display only this patient", nil) action: @selector(searchForCurrentPatient:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Images", nil) action: @selector(viewerDICOM:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Images in 4D", nil) action: @selector(MovieViewerDICOM:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Sub-Selection", nil)  action:@selector(viewerSubSeriesDICOM:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Key Images", nil) action: @selector(viewerDICOMKeyImages:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open ROIs Images", nil) action: @selector(viewerDICOMROIsImages:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open ROIs and Key Images", nil) action: @selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Open Merged Selection", nil) action: @selector(viewerDICOMMergeSelection:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Reveal In Finder", nil) action: @selector(revealInFinder:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to DICOM Network Node", nil) action: @selector(export2PACS:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to Quicktime", nil) action: @selector(exportQuicktime:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to JPEG", nil) action: @selector(exportJPEG:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to TIFF", nil) action: @selector(exportTIFF:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to DICOM File(s)", nil) action: @selector(exportDICOMFile:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to iDisk", nil) action: @selector(sendiDisk:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Export to Email", nil)  action:@selector(sendMail:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Add selected study(s) to user(s)", nil)  action:@selector( addStudiesToUser:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Send an email notification to user(s)", nil)  action:@selector( sendEmailNotification:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Compress DICOM files", nil)  action:@selector(compressSelectedFiles:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Decompress DICOM files", nil)  action:@selector(decompressSelectedFiles:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Lock Studies", nil)  action:@selector(lockStudies:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Unlock Studies", nil)  action:@selector(unlockStudies:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Report", nil) action: @selector(generateReport:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Merge Selected Studies", nil) action: @selector(mergeStudies:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Unify patient identity", nil) action: @selector(unifyStudies:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Delete", nil) action: @selector(delItem:) keyEquivalent:@""] autorelease]];
	[menu addItem: [NSMenuItem separatorItem]];
	
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Query Selected Patient from Q&R Window...", nil) action: @selector(querySelectedStudy:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Burn", nil) action: @selector(burnDICOM:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Anonymize", nil) action: @selector(anonymizeDICOM:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Rebuild Selected Thumbnails", nil)  action:@selector(rebuildThumbnails:) keyEquivalent:@""] autorelease]];
	[menu addItem: [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Copy Linked Files to Database Folder", nil)  action:@selector(copyToDBFolder:) keyEquivalent:@""] autorelease]];

	 NSArray	*autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
	
	if( [autoroutingRules count])
	{
		[menu addItem: [NSMenuItem separatorItem]];
		
		NSMenu *submenu = nil;
		
		if( [autoroutingRules count] > 0)
		{
			submenu = [[[NSMenu alloc] initWithTitle: NSLocalizedString(@"Apply this Routing Rule to Selection", nil)] autorelease];
			
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"All routing rules", nil)  action:@selector( applyRoutingRule:) keyEquivalent:@""] autorelease];
			[submenu addItem: item];
			[submenu addItem: [NSMenuItem separatorItem]];
			
			for( NSDictionary *routingRule in autoroutingRules)
			{
				NSString *s = [routingRule valueForKey: @"description"];
				
				if( [s length] > 0)
					item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %@", [routingRule valueForKey: @"name"], s] action: @selector( applyRoutingRule:) keyEquivalent:@""] autorelease];
				else
					item = [[[NSMenuItem alloc] initWithTitle: [routingRule valueForKey: @"name"] action: @selector( applyRoutingRule:) keyEquivalent:@""] autorelease];
				
				[item setRepresentedObject: routingRule];
				
				if( [routingRule valueForKey:@"activated"] == nil || [[routingRule valueForKey:@"activated"] boolValue])
					[item setEnabled: NO];
				else
					[item setEnabled: NO];
				
				[submenu addItem: item];
			}
		
			item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Apply this Routing Rule to Selection", nil)  action: nil keyEquivalent:@""] autorelease];
			[item setSubmenu: submenu];
			[menu addItem: item];
		}
	}
	
	[databaseOutline setMenu: menu];
}

-(void) awakeFromNib
{
//	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
// 
//	dispatch_apply(count, queue,
//	^(size_t i)
//	{
//		printf("%u\n",i);
//	});

	WaitRendering *wait = [[AppController sharedAppController] splashScreen];
	
//	waitCompressionWindow  = [[Wait alloc] initWithString: NSLocalizedString( @"File Conversion", nil) :NO];
//	[waitCompressionWindow setCancel:YES];
		
	
	[wait showWindow:self];
	
	@try
	{
		NSTableColumn		*tableColumn = nil;
		NSPopUpButtonCell	*buttonCell = nil;
		
		[albumDrawer setPreferredEdge: NSMinXEdge];
		
		// thumbnails : no background color
		[thumbnailsScrollView setDrawsBackground:NO];
		[[thumbnailsScrollView contentView] setDrawsBackground:NO];
		
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"NSWindow Frame DBWindow"] == nil) // No position for the window -> fullscreen
			[[self window] zoom: self];
		
		//	[self splitViewDidResizeSubviews:nil];
		[self.window setFrameAutosaveName:@"DBWindow"];
		
		[self awakeSources];
		[albumDrawer setDelegate:self];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(drawerFrameDidChange:) name:NSViewFrameDidChangeNotification object:albumDrawer.contentView];
		[oMatrix setDelegate:self];
		[oMatrix setSelectionByRect: NO];
		[oMatrix setDoubleAction:@selector(matrixDoublePressed:)];
		[oMatrix setFocusRingType: NSFocusRingTypeExterior];
		[oMatrix renewRows:0 columns: 0];
		[oMatrix sizeToCells];
		
		[imageView setTheMatrix:oMatrix];
		
		// Bug for segmentedControls...
		NSRect f = [segmentedAlbumButton frame];
		f.size.height = 25;
		[segmentedAlbumButton setFrame: f];
		
		[databaseOutline setAction:@selector(databasePressed:)];
		[databaseOutline setDoubleAction:@selector(databaseDoublePressed:)];
		[databaseOutline registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
		[databaseOutline setAllowsMultipleSelection:YES];
		[databaseOutline setAutosaveName: nil];
		[databaseOutline setAutosaveTableColumns: NO];
		[databaseOutline setAllowsTypeSelect: NO];
		
		[self setupToolbar];
		
		[toolbar setVisible:YES];
//		[self showDatabase: self];
		
		// NSMenu for DatabaseOutline
		[self createDBContextualMenu];
		
		[self addHelpMenu];
		
		ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
		[cell setEditable:YES];
		[[albumTable tableColumnWithIdentifier:@"Source"] setDataCell:cell];
		[albumTable setDelegate:self];
		[albumTable registerForDraggedTypes:[NSArray arrayWithObject:O2AlbumDragType]];
		[albumTable setDoubleAction:@selector(albumTableDoublePressed:)];
		
		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		
		statesArray = [[NSArray arrayWithObjects:NSLocalizedString(@"empty", nil), NSLocalizedString(@"unread", nil), NSLocalizedString(@"reviewed", nil), NSLocalizedString(@"dictated", nil), nil] retain];
		
		
		ImageAndTextCell *cellName = [[[ImageAndTextCell alloc] init] autorelease];
		[[databaseOutline tableColumnWithIdentifier:@"name"] setDataCell:cellName];
		
		ImageAndTextCell *cellReport = [[[ImageAndTextCell alloc] init] autorelease];
		[[databaseOutline tableColumnWithIdentifier:@"reportURL"] setDataCell:cellReport];
		
		// Set International dates for columns
		[self setDBDate];
		
		tableColumn = [databaseOutline tableColumnWithIdentifier: @"stateText"];
		buttonCell = [[[NSPopUpButtonCell alloc] initTextCell: @"" pullsDown:NO] autorelease];
		[buttonCell setEditable: YES];
		[buttonCell setBordered: NO];
		[buttonCell addItemsWithTitles: statesArray];
		[tableColumn setDataCell:buttonCell];
		
		[databaseOutline setInitialState];
		
		
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseColumns2"])
			[databaseOutline restoreColumnState: [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseColumns2"]];
		
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"])
		{
			NSDictionary	*sort = [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"];
			{
				if( [databaseOutline isColumnWithIdentifierVisible: [sort objectForKey:@"key"]])
				{
					NSSortDescriptor *prototype = [[databaseOutline tableColumnWithIdentifier: [sort objectForKey:@"key"]] sortDescriptorPrototype];
					
					[databaseOutline setSortDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:[sort objectForKey:@"key"] ascending:[[sort objectForKey:@"order"] boolValue]  selector: [prototype selector]] autorelease]]];
				}
				else
					[databaseOutline setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
			}
		}
		else
			[databaseOutline setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease]]];
		
		[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
		[databaseOutline scrollRowToVisible: 0];
		[self buildColumnsMenu];
		
		[animationCheck setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"AutoPlayAnimation"]];
		
		activeSends = [[NSMutableDictionary dictionary] retain];
		sendLog = [[NSMutableArray array] retain];
		activeReceives = [[NSMutableDictionary dictionary] retain];
		receiveLog = [[NSMutableArray array] retain];
		
		//	sendQueue = [[NSMutableArray alloc] init];
		//	queueLock = [[NSConditionLock alloc] initWithCondition: QueueEmpty];
		//	[NSThread detachNewThreadSelector:@selector(runSendQueue:) toTarget:self withObject:nil];
		
		// bonjour
		bonjourPublisher = [[BonjourPublisher alloc] initWithBrowserController:self];
		bonjourBrowser = [[BonjourBrowser alloc] initWithBrowserController:self bonjourPublisher:bonjourPublisher];
		[self displayBonjourServices];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:bonjourPublisher];
		
		
		[splitViewVert restoreDefault:@"SPLITVERT2"];
		[splitViewHorz restoreDefault:@"SPLITHORZ2"];
		[splitAlbums restoreDefault:@"SPLITALBUMS"];
		
//		[self autoCleanDatabaseDate: self];
		
		[self splitViewDidResizeSubviews: nil];
		
		
		// database : gray background
		//	[databaseOutline setUsesAlternatingRowBackgroundColors:NO];
		//	[databaseOutline setBackgroundColor:[NSColor lightGrayColor]];
		//	[databaseOutline setGridColor:[NSColor darkGrayColor]];
		//	[databaseOutline setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
		
		[self createContextualMenu];
		// opens a port for interapplication communication	
		[[NSConnection defaultConnection] registerName:@"OsiriX"];
		[[NSConnection defaultConnection] setRootObject:self];
		//start timer for monitoring incoming logs on main thread
		[LogManager currentLogManager];
		
		// SCAN FOR AN IPOD!
		//[self loadDICOMFromiPod]; now we do this in AppController+Mount
	}
	
	@catch( NSException *ne)
	{
		N2LogExceptionWithStackTrace(ne);
		[@"" writeToFile:_database.loadingFilePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		
		NSString *message = [NSString stringWithFormat: NSLocalizedString(@"A problem occured during start-up of OsiriX:\r\r%@\r\r%@",nil), [ne description], [AppController printStackTrace: ne]];
		
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error",nil), message, NSLocalizedString( @"OK",nil), nil, nil);
		
		exit( 0);
	}
	
	[wait close];
	
	[self testAutorouting];
	
	[self setDBWindowTitle];
	
	NSSize size = NSSizeFromString( [[NSUserDefaults standardUserDefaults] objectForKey: @"drawerSize"]);
	if( size.width > 0)
		[albumDrawer setContentSize: size];
	
	if( [[[NSUserDefaults standardUserDefaults] objectForKey: @"drawerState"] intValue] == NSDrawerOpenState && [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
		[albumDrawer openOnEdge:NSMinXEdge];
	else
		[albumDrawer close];
	
	loadingIsOver = YES;
	
	[self outlineViewRefresh];
	
	[self awakeActivity];
	[self.window makeKeyAndOrderFront: self];
	
	[self refreshMatrix: self];
	
	#ifndef OSIRIX_LIGHT
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"restartAutoQueryAndRetrieve"] == YES && [[NSUserDefaults standardUserDefaults] objectForKey: @"savedAutoDICOMQuerySettings"] != nil)
	{
		[[AppController sharedAppController] growlTitle: NSLocalizedString( @"Auto-Query", nil) description: NSLocalizedString( @"DICOM Auto-Query is restarting...", nil)  name:@"autoquery"];
		NSLog( @"-------- automatically restart DICOM AUTO-QUERY --------");
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Restarting Auto Query/Retrieve...", nil)];
		[wait showWindow:self]; 
		[[QueryController alloc] initAutoQuery: YES];
		[[QueryController currentAutoQueryController] switchAutoRetrieving: self];
		[NSThread sleepForTimeInterval: 0.5];
		[wait close];
		[wait release];
	}
	else 
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"autoRetrieving"];
	#endif
	
//	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MOUNT"])
//		[self ReadDicomCDRom: nil];
	
//	NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
//	[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"LogEntry"]];
//	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
//	
//	NSError *error = nil;
//	NSArray *logArray = [self.managedObjectContext executeFetchRequest:dbRequest error: &error];
//	
//	if( error)
//		NSLog( @"%@", error);
//	NSLog( @"%@", logArray);
//	
//	for( id log in logArray)
//	{
//		NSLog( @"%@", [log valueForKey: @"type"]);
//	}
//	
//	for( id log in logArray) [self.managedObjectContext deleteObject: log];
}

-(void)dealloc {
	[self deallocActivity];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey];
	[self deallocSources];
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
		keyPath = [keyPath substringFromIndex:7];
		if ([keyPath isEqual:OsirixBonjourSharingActiveFlagDefaultsKey]) {
			[self switchToDefaultDBIfNeeded];
			return;
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)customize:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

- (IBAction)showhide:(id)sender
{
    [toolbar setVisible:![toolbar isVisible]];
}

- (void)waitForRunningProcesses
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if( waitForRunningProcess == YES)
		return;
	
	waitForRunningProcess = YES;
	
	WaitRendering *wait = nil;
	
	if( [NSThread isMainThread] && [[self window] isVisible])
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Wait for running processes...", nil)];
	
	@try
	{
		// ----------
		
		BOOL hideListenerError_copy = [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"];
		
		[[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"copyHideListenerError"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"hideListenerError"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[[NSFileManager defaultManager] createFileAtPath: @"/tmp/kill_all_storescu" contents: [NSData data] attributes: nil];
		
//		for( NSInteger x = 0, row; x < [[ThreadsManager defaultManager] threadsCount]; x++)  
//			[[[ThreadsManager defaultManager] objectInThreadsAtIndex: x] cancel];
		
		NSTimeInterval ti = [NSDate timeIntervalSinceReferenceDate] + 240;
//		while( ti - [NSDate timeIntervalSinceReferenceDate] > 0 && [[ThreadsManager defaultManager] threadsCount] > 0)
//		{
//			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
//			
//			if( wait && [[wait window] isVisible] == NO)
//				[wait showWindow:self];
//		}
		
		unlink( "/tmp/kill_all_storescu");
		[[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"hideListenerError"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"copyHideListenerError"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		// ----------
		
//		[BrowserController tryLock:checkIncomingLock during: 120];
		[BrowserController tryLock:_database during: 120];
//		[BrowserController tryLock:checkBonjourUpToDateThreadLock during: 60];
		
		while( [SendController sendControllerObjects] > 0)
		{
			//[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]];
			[NSThread sleepForTimeInterval: 0.1];
			
			if( wait && [[wait window] isVisible] == NO)
				[wait showWindow:self];
		}
	//	[BrowserController tryLock: decompressThreadRunning during: 120];
		[BrowserController tryLock: deleteInProgress during: 600];
		
		[self emptyDeleteQueueThread];
		
		[BrowserController tryLock: deleteInProgress during: 600];
	//	[BrowserController tryLock: autoroutingInProgress during: 120];
		
	//	[self emptyAutoroutingQueue:self];
		
	//	[BrowserController tryLock: autoroutingInProgress during: 120];
		
		[self syncReportsIfNecessary];
		
		[BrowserController tryLock:_database during: 120];
	}
	@catch (NSException * e)
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	waitForRunningProcess = NO;
	
	[wait close];
	[wait release];
	
	[pool release];
}

- (void) browserPrepareForClose
{
//	[IncomingTimer invalidate];
	
	NSLog( @"browserPrepareForClose");
	
	[[DicomStudy dbModifyLock] lock];
	[[DicomStudy dbModifyLock] unlock];
	
	[self saveUserDatabase];
	[_database save:NULL];
	[self saveUserDatabase];
	
	[self waitForRunningProcesses];

	[_database save:NULL];
	
	self.database = nil;
	
//	[self removeAllMounted];
	
//	newFilesInIncoming = NO;
	
    [splitViewVert saveDefault:@"SPLITVERT2"];
    [splitViewHorz saveDefault:@"SPLITHORZ2"];
	[splitAlbums saveDefault:@"SPLITALBUMS"];
	
	if( [[databaseOutline sortDescriptors] count] >= 1)
	{
		NSDictionary	*sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[databaseOutline sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[databaseOutline sortDescriptors] objectAtIndex: 0] key], @"key", nil];
		[[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"databaseSortDescriptor"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:[databaseOutline columnState] forKey: @"databaseColumns2"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt: [albumDrawer state]] forKey: @"drawerState"];
	[[NSUserDefaults standardUserDefaults] setObject: NSStringFromSize( [albumDrawer contentSize]) forKey: @"drawerSize"];
	
    [self.window setDelegate:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool: [animationCheck state] forKey: @"AutoPlayAnimation"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/OsiriXTemporaryDatabase" handler: nil];
	[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/dicomsr_osirix" handler: nil];
}

-(void)shouldTerminateCallback:(NSTimer*) tt
{
	if(/* newFilesInIncoming || */[[ThreadsManager defaultManager] threadsCount] > 0)
	{
	}
	else 
		[[NSApplication sharedApplication] stopModalWithCode: NSAlertAlternateReturn];
}

- (BOOL)shouldTerminate: (id)sender
{
	[_database save:NULL];
	
	if(/* newFilesInIncoming ||*/ [[ThreadsManager defaultManager] threadsCount] > 0)
	{
		if( NSDrawerClosedState == [albumDrawer state])
			[self drawerToggle: self];
		
		NSAlert* w = [NSAlert alertWithMessageText: NSLocalizedString( @"Background Threads", NULL)
									 defaultButton: NSLocalizedString( @"Cancel", NULL) 
								   alternateButton: NSLocalizedString( @"Quit", NULL)
									   otherButton: NULL
						 informativeTextWithFormat: NSLocalizedString( @"Background threads are currently running. Are you sure you want to quit now? These threads will be cancelled.", NULL)];
		
		NSTimer *t = [NSTimer timerWithTimeInterval: 0.3 target:self selector:@selector( shouldTerminateCallback:) userInfo: w repeats:YES];
		
		[[NSRunLoop currentRunLoop] addTimer: t forMode:NSModalPanelRunLoopMode];
		
		NSInteger r = [w runModal];
		
		[t invalidate];
		
		if( /*newFilesInIncoming ||*/ [[ThreadsManager defaultManager] threadsCount] > 0)
		{
			if( r == NSAlertDefaultReturn)
				return NO;
		}
	}
	
	if( [SendController sendControllerObjects] > 0)
	{
		if( NSDrawerClosedState == [albumDrawer state])
			[self drawerToggle: self];
		
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Sending - STORE", nil), NSLocalizedString(@"Files are currently being sent to a DICOM node. Are you sure you want to quit now? The sending will be stopped.", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Quit", nil), nil) == NSAlertDefaultReturn) return NO;
	}
	
	return YES;
}

- (void)showDatabase: (id)sender
{
    [self.window makeKeyAndOrderFront:sender];
	[self outlineViewRefresh];
}

- (void)keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	
    if (c == NSDeleteFunctionKey || c == NSDeleteCharacter || c == NSBackspaceCharacter || c == NSDeleteCharFunctionKey)
        [self delItem: [[self window] firstResponder]];
    
	else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter)
        [self viewerDICOM: [[self window] firstResponder]];
		
	else if(c == ' ')
		[animationCheck setState: ![animationCheck state]];
	
    else
	{
		[pressedKeys appendString: [event characters]];
		
		NSLog(@"%@", pressedKeys);
		
		NSArray		*result = [outlineViewArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", [NSString stringWithFormat:@"%@", pressedKeys]]];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys selector:@selector(setString:) object:@""];
		[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
		
		if( [result count])
		{
			[databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: [result objectAtIndex: 0]]] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: databaseOutline.selectedRow];
		}
		else NSBeep();
    }
}

- (IBAction) unlockStudies: (id) sender
{
	NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
	
	for( NSInteger x = 0, row; x < selectedRows.count; x++)
	{
		if( x == 0) row = selectedRows.firstIndex;
		else row = [selectedRows indexGreaterThanIndex: row];
		
		NSManagedObject	*object = [databaseOutline itemAtRow: row];
		
		if( [[object valueForKey:@"type"] isEqualToString: @"Study"] && [[object valueForKey: @"lockedStudy"] boolValue])
			[object setValue: [NSNumber numberWithBool: NO] forKey: @"lockedStudy"];
	}
	
	[self refreshDatabase: self];
}

- (IBAction) lockStudies: (id) sender
{
	NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
	
	for( NSInteger x = 0, row; x < selectedRows.count; x++)
	{
		if( x == 0) row = selectedRows.firstIndex;
		else row = [selectedRows indexGreaterThanIndex: row];
		
		NSManagedObject	*object = [databaseOutline itemAtRow: row];
		
		if( [[object valueForKey:@"type"] isEqualToString: @"Study"] && [[object valueForKey: @"lockedStudy"] boolValue] == NO)
			[object setValue: [NSNumber numberWithBool: YES] forKey: @"lockedStudy"];
	}
	
	[self refreshDatabase: self];
}

- (BOOL) validateMenuItem: (NSMenuItem*) menuItem
{
	#ifdef EXPORTTOOLBARITEM
	return YES;
	#endif

	if( [[databaseOutline selectedRowIndexes] count] < 1) // No Database Selection
	{
		if(	[menuItem action] == @selector( rebuildThumbnails:) ||
			[menuItem action] == @selector( searchForCurrentPatient:) || 
			[menuItem action] == @selector( viewerDICOM:) || 
			[menuItem action] == @selector( MovieViewerDICOM:) || 
			[menuItem action] == @selector( viewerDICOMMergeSelection:) || 
			[menuItem action] == @selector( revealInFinder:) || 
			[menuItem action] == @selector( export2PACS:) || 
			[menuItem action] == @selector( exportQuicktime:) || 
			[menuItem action] == @selector( exportJPEG:) || 
			[menuItem action] == @selector( exportTIFF:) || 
			[menuItem action] == @selector( exportDICOMFile:) || 
			[menuItem action] == @selector( sendiDisk:) || 
			[menuItem action] == @selector( sendMail:) || 
			[menuItem action] == @selector( addStudiesToUser:) || 
			[menuItem action] == @selector( sendEmailNotification:) || 
			[menuItem action] == @selector( compressSelectedFiles:) || 
			[menuItem action] == @selector( decompressSelectedFiles:) || 
			[menuItem action] == @selector( generateReport:) || 
			[menuItem action] == @selector( deleteReport:) || 
			[menuItem action] == @selector( delItem:) || 
			[menuItem action] == @selector( querySelectedStudy:) || 
			[menuItem action] == @selector( burnDICOM:) || 
			[menuItem action] == @selector( anonymizeDICOM:) || 
			[menuItem action] == @selector( viewXML:) || 
			[menuItem action] == @selector( applyRoutingRule:)
			)
		return NO;
	}

	if( menuItem.menu == imageTileMenu)
	{
		return [[[NSApp mainWindow] windowController] isKindOfClass:[ViewerController class]];
	}
	else if( [menuItem action] == @selector( unifyStudies:))
	{
		if (![_database isLocal]) return NO;
		
		if( [[databaseOutline selectedRowIndexes] count] <= 1) return NO;
		
		return YES;
	}
	else if( [menuItem action] == @selector( viewerDICOMROIsImages:))
	{
		if ([_database isLocal])
		{
			if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self ROIImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( viewerKeyImagesAndROIsImages:))
	{
		if ([_database isLocal])
		{
			if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self ROIsAndKeyImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( viewerDICOMKeyImages:))
	{
		if ([_database isLocal])
		{
			if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self KeyImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( createROIsFromRTSTRUCT:))
	{
		if (![_database isLocal]) return NO;
	}
	else if( [menuItem action] == @selector( compressSelectedFiles:))
	{
//		if( [decompressThreadRunning tryLock] == NO)
//			return NO;
//		else
//			[decompressThreadRunning unlock];
//		if (![_database isLocal]) return NO;
	}
	else if( [menuItem action] == @selector( decompressSelectedFiles:))
	{
//		if( [decompressThreadRunning tryLock] == NO)
//			return NO;
//		else
//			[decompressThreadRunning unlock];
//		if (![_database isLocal]) return NO;
	}
	else if( [menuItem action] == @selector( copyToDBFolder:))
	{
		if (![_database isLocal]) return NO;
		
		if( [[databaseOutline selectedRowIndexes] count] < 10)
		{
			BOOL matrixThumbnails;
			
			if( menuItem.menu == contextual) matrixThumbnails = YES;
			else matrixThumbnails = NO;
			
			NSMutableArray *files, *objects = [NSMutableArray array];
			
			if( matrixThumbnails)
				files = [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
			else
				files = [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
			
			[files removeDuplicatedStringsInSyncWithThisArray: objects];
			
			for( NSManagedObject *im in objects)
			{
				if( [[im valueForKey: @"inDatabaseFolder"] boolValue] == NO)
					return YES;
			}
			
			return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( lockStudies:))
	{
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		for( NSInteger x = 0, row; x < selectedRows.count; x++)
		{
			if( x == 0) row = selectedRows.firstIndex;
			else row = [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*object = [databaseOutline itemAtRow: row];
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Study"] && [[object valueForKey: @"lockedStudy"] boolValue] == NO)
				return YES;
		}
		
		return NO;
	}
	else if( [menuItem action] == @selector( unlockStudies:))
	{
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		for( NSInteger x = 0, row; x < selectedRows.count; x++)
		{
			if( x == 0) row = selectedRows.firstIndex;
			else row = [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*object = [databaseOutline itemAtRow: row];
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Study"] && [[object valueForKey: @"lockedStudy"] boolValue])
				return YES;
		}
		
		return NO;
	}
	else if( [menuItem action] == @selector( delItem:))
	{
		if (![_database isLocal]) return NO;
		
		BOOL matrixThumbnails = YES;
		
		if( menuItem.menu == [oMatrix menu] || [[self window] firstResponder] == oMatrix)
			matrixThumbnails = YES;
			
		if( menuItem.menu == [databaseOutline menu] || [[self window] firstResponder] == databaseOutline)
			matrixThumbnails = NO;
		
		if( matrixThumbnails)
			[menuItem setTitle: NSLocalizedString( @"Delete Selected Series Thumbnails", nil)];
		else
			[menuItem setTitle: NSLocalizedString( @"Delete Selected Lines", nil)];
	}
	else if( [menuItem action] == @selector( mergeStudies:))
	{
		if (![_database isLocal]) return NO;
		
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		BOOL	onlySeries = YES;
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++)
		{
			NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			NSManagedObject	*series = [databaseOutline itemAtRow: row];
			if( [[series valueForKey:@"type"] isEqualToString: @"Series"] == NO) onlySeries = NO;
		}
		
		if( onlySeries && [selectedRows count])
			[menuItem setTitle: NSLocalizedString( @"Merge Selected Series", nil)];
		else
			[menuItem setTitle: NSLocalizedString( @"Merge Selected Studies", nil)];
		
		if( [selectedRows count] > 1) return YES;
		else return NO;
	}
	else if( [menuItem action] == @selector( mergeSeries:))
	{
		if (![_database isLocal]) return NO;
		
		if( [[oMatrix selectedCells] count] > 1) return YES;
		else return NO;
	}
	else if( [menuItem action] == @selector( annotMenu:))
	{
		if( [menuItem tag] == [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"]) [menuItem setState: NSOnState];
		else [menuItem setState: NSOffState];
	}
	return YES;
}

- (BOOL)is2DViewer
{ return NO; }

- (IBAction)customizeViewerToolBar:(id)sender
{
    [toolbar runCustomizationPalette:sender];
}

- (void)addHelpMenu
{
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *helpItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Help", nil) action:nil keyEquivalent:@""];
	NSMenu *helpMenu = [[NSMenu allocWithZone: [NSMenu menuZone]] initWithTitle: NSLocalizedString(@"Help", nil)];
	[helpItem setSubmenu:helpMenu];
	[helpMenu addItemWithTitle: NSLocalizedString(@"Email Project Lead", nil) action: @selector(sendEmail:) keyEquivalent: @""];
	[helpMenu addItemWithTitle: NSLocalizedString(@"OsiriX Web site", nil) action: @selector(openOsirixWebPage:) keyEquivalent: @""];	
	[helpMenu addItemWithTitle: NSLocalizedString(@"OsiriX Discussion Group", nil) action: @selector(openOsirixDiscussion:) keyEquivalent: @""];
	[helpMenu addItem: [NSMenuItem separatorItem]];
	[helpMenu addItemWithTitle: NSLocalizedString(@"OsiriX Help", nil) action: @selector(help:) keyEquivalent: @""];
	[helpMenu release];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark DICOM Network & Files functions

- (void) resetListenerTimer { // __deprecated
	[DicomDatabase syncImportFilesFromIncomingDirTimerWithUserDefaults];
}

- (void) emptyDeleteQueueThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[deleteInProgress lock];
	[deleteQueue lock];
	NSArray	*copyArray = [NSArray arrayWithArray: deleteQueueArray];
	[deleteQueueArray removeAllObjects];
	[deleteQueue unlock];
	
	if( copyArray.count)
	{
		NSMutableArray *folders = [NSMutableArray array];
		
		NSLog(@"delete Queue start: %d objects", [copyArray count]);
		
		int f = 0;
		NSString *lastFolder = nil;
		for( NSString *file in copyArray)
		{
			unlink( [file UTF8String]);		// <- this is faster
			
			if( [lastFolder isEqualToString: [file stringByDeletingLastPathComponent]] == NO)
			{
				[folders addObject: [file stringByDeletingLastPathComponent]];
				lastFolder = [file stringByDeletingLastPathComponent];
			}
			
			[NSThread currentThread].progress = (float) f++ / (float) [copyArray count];
			[NSThread currentThread].status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [copyArray count]-f];
		}
		
		[deleteInProgress unlock];
		
		[folders removeDuplicatedStrings];
		
		[_database lock];
		
		@try 
		{
			for( NSString *f in folders)
			{
				NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: f traverseLink: NO];
				
				if( [[fileAttributes objectForKey: NSFileType] isEqualToString: NSFileTypeDirectory]) 
				{
					if( [[fileAttributes objectForKey: NSFileReferenceCount] intValue] < 4)	// check if this folder is empty, and delete it if necessary
					{
						int numberOfValidFiles = 0;
						for( NSString *s in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: f error: nil])
						{
							if( [[s lastPathComponent] characterAtIndex: 0] != '.')
								numberOfValidFiles++;
						}
						
						if( numberOfValidFiles == 0 && [[f lastPathComponent] isEqualToString: @"ROIs"] == NO)
						{
							NSLog( @"delete Queue: delete folder: %@", f);
							[[NSFileManager defaultManager] removeFileAtPath: f handler: nil];
							
						}
					}
				}
				
			}
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			[AppController printStackTrace: e];
		}
		
		[_database unlock];
		
		NSLog(@"delete Queue end");
	}
	else [deleteInProgress unlock];
	
	[pool release];
}

- (void) emptyDeleteQueueNow: (id) sender
{
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[self emptyDeleteQueueThread];
	
	[deleteInProgress lock];
	[deleteInProgress unlock];
}

- (void) emptyDeleteQueue: (id)sender
{
	if( [[AppController sharedAppController] isSessionInactive] || waitForRunningProcess) return;
	
	// Check for the errors generated by the Q&R DICOM functions -- see dcmqrsrv.mm
	
	NSString *str = [NSString stringWithContentsOfFile: @"/tmp/error_message"];
	if( str)
	{
		[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/error_message" handler: nil];
		
		NSString *alertSuppress = @"hideListenerError";
		if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
		{
			NSAlert* alert = [[NSAlert new] autorelease];
			[alert setMessageText: NSLocalizedString( @"DICOM Network Error", nil)];
			[alert setInformativeText: str];
			[alert setShowsSuppressionButton:YES ];
			[alert addButtonWithTitle: NSLocalizedString(@"OK", nil)];
			
			if ([[alert suppressionButton] state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:alertSuppress];
		}
		else
			NSLog( @"*** DICOM Network Error (not displayed - hideListenerError): %@", str);
	}
	
	//////////////////////////////////////////////////
	
	if( deleteQueueArray != nil && deleteQueue != nil)
	{
		if( [deleteQueueArray count] > 0)
		{
			if( [deleteInProgress tryLock])
			{
				[deleteInProgress unlock];
				
				NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( emptyDeleteQueueThread) object:  nil] autorelease];
				t.name = NSLocalizedString( @"Deleting files...", nil);
				t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [deleteQueueArray count]];
				t.progress = 0;
				[[ThreadsManager defaultManager] addThreadAndStart: t];
			}
		}
	}
}

- (void)addFileToDeleteQueue: (NSString*)file
{
	if( deleteQueueArray == nil) deleteQueueArray = [[NSMutableArray array] retain];
	if( deleteQueue == nil) deleteQueue = [[NSLock alloc] init];
	if( deleteInProgress == nil) deleteInProgress = [[NSLock alloc] init];
	
	[deleteQueue lock];
	if( file)
		[deleteQueueArray addObject: file];
	[deleteQueue unlock];
}

+ (NSString*)_findFirstDicomdirOnCDMedia: (NSString*)startDirectory { // __deprecated
	return [DicomDatabase _findDicomdirIn:[startDirectory stringsByAppendingPaths:[[[NSFileManager defaultManager] enumeratorAtPath:startDirectory filesOnly:YES] allObjects]]];
}

+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination
{
	return [BrowserController unzipFile:  file withPassword:  pass destination:  destination showGUI: YES];
}

+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination showGUI: (BOOL) showGUI
{
	[[NSFileManager defaultManager] removeFileAtPath: destination handler: nil];
	
	NSTask *t;
	NSArray *args;
	WaitRendering *wait = nil;
	
	if( [NSThread isMainThread] && showGUI == YES)
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Decompressing the files...", nil)];
		[wait showWindow:self];
	}
	
	t = [[[NSTask alloc] init] autorelease];
	
	@try
	{
		[t setLaunchPath: @"/usr/bin/unzip"];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/"] == NO)
			[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/" attributes: nil];
			
		[t setCurrentDirectoryPath: @"/tmp/"];
		if( pass)
			args = [NSArray arrayWithObjects: @"-qq", @"-o", @"-d", destination, @"-P", pass, file, nil];
		else
			args = [NSArray arrayWithObjects: @"-qq", @"-o", @"-d", destination, file, nil];
		[t setArguments: args];
		[t launch];
		[t waitUntilExit];
	}
	@catch ( NSException *e)
	{
		NSLog( @"***** unzipFile exception: %@", e);
		[AppController printStackTrace: e];
	}
	
	[wait close];
	[wait release];
	
	BOOL fileExist = NO;
	
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: destination];
	NSString *item = nil;
	while( item = [dirEnum nextObject])
	{
		BOOL isDirectory;
		if( [[NSFileManager defaultManager] fileExistsAtPath: [destination stringByAppendingPathComponent: item] isDirectory: &isDirectory])
		{
			if( isDirectory == NO && [[[[NSFileManager defaultManager] attributesOfItemAtPath: [destination stringByAppendingPathComponent: item] error: nil] valueForKey: NSFileSize] longLongValue] > 0)
			{
				fileExist = YES;
				break;
			}
		}
	}
	
	if( fileExist)
	{
		// Is it on writable media? Ask if the user want to delete the original file?
		
		if( [NSThread isMainThread] && [[NSFileManager defaultManager] isWritableFileAtPath: file] && showGUI == YES)
		{
			if ([[NSUserDefaults standardUserDefaults] boolForKey: @"HideZIPSuppressionMessage"] == NO)
			{
				NSAlert* alert = [[NSAlert new] autorelease];
				[alert setMessageText: NSLocalizedString(@"Delete ZIP file", nil)];
				[alert setInformativeText: NSLocalizedString(@"The ZIP file was successfully decompressed and the images successfully incorporated in OsiriX database. Should I delete the ZIP file?", nil)];
				[alert setShowsSuppressionButton: YES];
				[alert addButtonWithTitle: NSLocalizedString( @"OK", nil)];
				[alert addButtonWithTitle: NSLocalizedString( @"Cancel", nil)];
				int result = [alert runModal];
				
				if( result == NSAlertFirstButtonReturn)
					[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"deleteZIPfile"];
				else
					[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"deleteZIPfile"];
				
				if ([[alert suppressionButton] state] == NSOnState)
					[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"HideZIPSuppressionMessage"];
			}
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"deleteZIPfile"]) 
				[[NSFileManager defaultManager] removeItemAtPath: file error: nil];
		}
		return YES;
	}
	
	return NO;
}

- (int) askForZIPPassword: (NSString*) file destination: (NSString*) destination
{
	// first, try without password
	int result = 0;
	
	if( [BrowserController unzipFile: file withPassword: nil destination: destination] == NO)
	{
		self.pathToEncryptedFile = [NSString stringWithFormat: NSLocalizedString( @"File: %@", nil), file];
		self.CDpassword = @"";
		do
		{
			[NSApp beginSheet: CDpasswordWindow
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			result = [NSApp runModalForWindow: CDpasswordWindow];
			[CDpasswordWindow makeFirstResponder: nil];
			
			[NSApp endSheet: CDpasswordWindow];
			[CDpasswordWindow orderOut: self];
		}
		while( result == NSRunStoppedResponse && [BrowserController unzipFile: file withPassword: self.CDpassword destination: destination] == NO);
	}
	else
		result = NSRunStoppedResponse;
	
	return result;
}

-(void) ReadDicomCDRom:(id) sender
{
	if (![_database isLocal])
	{
		if( sender)
			NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"Switch to a local database to load a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
		return;
	}
	
//	if( DICOMDIRCDMODE)
//	{
//		if( sender)
//			NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}
	
	NSArray	*removeableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	BOOL found = NO;
	
	for( NSString *mediaPath in removeableMedia)
	{
		BOOL		isWritable, isUnmountable, isRemovable, hasDICOMDIR = NO;
		NSString	*description, *type;
		
		[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath: mediaPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&type];
		
		if( isRemovable == YES)
		{
			WaitRendering *wait = nil;
			if( [NSThread isMainThread])
			{
				wait = [[WaitRendering alloc] init: NSLocalizedString(@"Parsing CD/DVD content...", nil)];
				[wait showWindow:self];
			}
			@try
			{
				// has EncryptedDICOM.zip ?
				{
					NSString *aPath = mediaPath;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					if( enumer == nil)
						aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
					
					for( NSString *p in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: aPath error: nil])
					{
						if( [[p lastPathComponent] isEqualToString: @"encryptedDICOM.zip"] || [[p lastPathComponent] isEqualToString:@"DICOM.zip"]) // See BurnerWindowController / Disc Burning
						{
							int result = [self askForZIPPassword: [aPath stringByAppendingPathComponent: p] destination: @"/tmp/zippedFile/"];
							
							if( result == NSRunStoppedResponse)
							{
								mediaPath = @"/tmp/zippedFile/";
								break;
							}
							else return;
						}
					}
				}
				
				// hasDICOMDIR ?
				{
					NSString *aPath = mediaPath;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					if( enumer == nil)
						aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
					
					DicomDirScanDepth = 0;
					aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath];
					
					if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
						hasDICOMDIR = YES;
				}
				
				if( hasDICOMDIR == YES)
				{
					// ADD ALL FILES OF THIS VOLUME TO THE DATABASE!
					NSMutableArray  *filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
					
					found = YES;
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseDICOMDIRFileCD"])
					{
						NSString *aPath = mediaPath;
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == nil)
						{
							aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
							enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						}
						
						// DICOMDIR should be located at the root level
						DicomDirScanDepth = 0;
						aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath];
						
						if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
						{
							int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"STILLMOVIEMODE"];
							
							@try
							{
								[self addDICOMDIR: aPath :filesArray];
							}
							
							@catch (NSException *e)
							{
								NSLog( @"%@", e.description);
								[AppController printStackTrace: e];
							}
							
							
							switch ( mode)
							{
								case 0: // ALL FILES
									
									break;
									
								case 1: //EXCEPT STILL
									for( int i = 0; i < [filesArray count]; i++)
									{
										if( [[[filesArray objectAtIndex:i] lastPathComponent] isEqualToString:@"STILL"] == YES)
										{
											[filesArray removeObjectAtIndex:i];
											i--;
										}
									}
									break;
									
									case 2: //EXCEPT MOVIE
									for( int i = 0; i < [filesArray count]; i++)
									{
										if( [[[filesArray objectAtIndex:i] lastPathComponent] isEqualToString:@"MOVIE"] == YES)
										{
											[filesArray removeObjectAtIndex:i];
											i--;
										}
									}
									break;
							}
						}
						else
						{
							if( sender)
							{
								NSInteger response = NSRunCriticalAlertPanel(NSLocalizedString(@"DICOMDIR",nil), NSLocalizedString(@"No DICOMDIR file has been found on this CD/DVD. I will try to scan the entire CD/DVD for DICOM files.",nil), NSLocalizedString( @"OK",nil), NSLocalizedString( @"Cancel",nil), nil);
								
								if( response != NSAlertDefaultReturn)
									sender = nil;
							}
						}
					}
					
					if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseDICOMDIRFileCD"] == NO || (sender != nil && [filesArray count] == 0))
					{
						NSString *pathname;
						NSString *aPath = mediaPath;
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == nil)
						{
							aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
							enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						}
						
						while (pathname = [enumer nextObject])
						{
							NSString * itemPath = [aPath stringByAppendingPathComponent:pathname];
							id fileType = [[enumer fileAttributes] objectForKey:NSFileType];
							
							if ([fileType isEqual:NSFileTypeRegular])
							{
								BOOL	addFile = YES;
								
								switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"STILLMOVIEMODE"])
								{
								case 0: // ALL FILES
									
									break;
									
								case 1: //EXCEPT STILL
									if( [[itemPath lastPathComponent] isEqualToString:@"STILL"] == YES) addFile = NO;
									break;
									
									case 2: //EXCEPT MOVIE
									if( [[itemPath lastPathComponent] isEqualToString:@"MOVIE"] == YES) addFile = NO;
									break;
								}
								
								if( [[itemPath lastPathComponent] isEqualToString:@"DICOMDIR"] == YES || [[itemPath lastPathComponent] isEqualToString:@"DICOMDIR."] == YES)
									addFile = NO;
								
								if( [[[itemPath lastPathComponent] uppercaseString] hasSuffix:@".DS_STORE"] == YES)
									addFile = NO;
								
								if( [[itemPath lastPathComponent] length] > 0 && [[itemPath lastPathComponent] characterAtIndex: 0] == '.')
									addFile = NO;
								
								for( NSString *s in [itemPath pathComponents])
								{
									NSString *e = [s pathExtension];
									
									if( [e length] > 4 || [e length] < 3)
										e = [NSString stringWithString:@"dcm"];
									
									if( [e holdsIntegerValue] || [e isEqualToString:@""] || [[e lowercaseString] isEqualToString:@"dcm"] || [[e lowercaseString] isEqualToString:@"img"] || [[e lowercaseString] isEqualToString:@"im"]  || [[e lowercaseString] isEqualToString:@"dicom"])
									{
									}
									else
										addFile = NO;
								}
								
								if( addFile)
									[filesArray addObject:itemPath];
								else
									NSLog(@"skip this file: %@", [itemPath lastPathComponent]);
							}
						}
						
					}
					
					[_database cleanForFreeSpace];
					
					[self copyFilesIntoDatabaseIfNeeded: filesArray options: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], @"addToAlbum", [NSNumber numberWithBool: YES], @"async", [NSNumber numberWithBool: YES], @"selectStudy", [NSNumber numberWithBool: YES], @"onlyDICOM", [NSNumber numberWithBool: YES], @"ejectCDDVD", [NSNumber numberWithBool: YES], @"mountedVolume", nil]];
					
					[_database cleanForFreeSpace];
				}
			}
			@catch (NSException * e)
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
				[AppController printStackTrace: e];
			}
			[wait close];
			[wait release];
		}
	}
	
	if( found == NO && sender)
	{
		if( [[DRDevice devices] count])
		{
			DRDevice	*device = [[DRDevice devices] objectAtIndex: 0];
			
			// Is the bay close? open it for the user
			if( [[[device status] valueForKey: DRDeviceIsTrayOpenKey] boolValue] == YES)
			{
				[device closeTray];
				[[AppController sharedAppController] growlTitle: NSLocalizedString( @"CD/DVD", nil) description: NSLocalizedString(@"Please wait. CD/DVD is loading...", nil) name:@"newfiles"];
				return;
			}
			else
			{
				if( [[[device status] valueForKey: DRDeviceIsBusyKey] boolValue] == NO && [[[device status] valueForKey: DRDeviceMediaStateKey] isEqualToString:DRDeviceMediaStateNone])
					[device openTray];
				else
				{
					[[AppController sharedAppController] growlTitle: NSLocalizedString( @"CD/DVD", nil) description: NSLocalizedString(@"Cannot find a valid DICOM CD/DVD format.", nil) name:@"newfiles"];
					return;
				}
			}
		}
		
		NSRunCriticalAlertPanel(NSLocalizedString(@"No CD or DVD has been found...", nil),NSLocalizedString(@"Please insert a DICOM CD or DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

+(BOOL) isItCD:(NSString*) path
{
	NSArray *pathFilesComponent = [path pathComponents];
	
	if( [pathFilesComponent count] > 2 && [[[pathFilesComponent objectAtIndex: 1] uppercaseString] isEqualToString:@"VOLUMES"])
	{
		NSArray	*removeableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
		
		for( NSString *mediaPath in removeableMedia)
		{
			if( [[mediaPath commonPrefixWithString: path options: NSCaseInsensitiveSearch] isEqualToString: mediaPath])
			{
				BOOL		isWritable, isUnmountable, isRemovable, hasDICOMDIR = NO;
				NSString	*description, *type;
				
				[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath: mediaPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&type];
				
				if( isRemovable == YES)
				{
					// has encryptedDICOM.zip ?
					{
						NSString *aPath = mediaPath;
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == nil)
							aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
						
						for( NSString *p in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: aPath error: nil])
						{
							if( [[p lastPathComponent] isEqualToString: @"encryptedDICOM.zip"]) // See BurnerWindowController
							{
								return YES;
							}
						}
					}
					
					// hasDICOMDIR ?
					{
						NSString *aPath = mediaPath;
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == nil)
							aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
						
						DicomDirScanDepth = 0;
						aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath];
						
						if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
							hasDICOMDIR = YES;
							
						if(  hasDICOMDIR == YES)
							return YES;
					}
				}
			}
		}
	}
	return NO;
}
	
- (void)listenerAnonymizeFiles: (NSArray*)files
{
	#ifndef OSIRIX_LIGHT
	NSArray				*array = [NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"**anonymized**", [DCMAttributeTag tagWithName:@"PatientID"], @"00000",nil];
	NSMutableArray		*tags = [NSMutableArray array];
	
	[tags addObject:array];
	
	for( NSString *file in files)
	{
		NSString *destPath = [file stringByAppendingString:@"temp"];
		
		@try
		{
			[DCMObject anonymizeContentsOfFile: file  tags:tags  writingToFile:destPath];
		}
		@catch (NSException * e)
		{
			NSLog( @"**** listenerAnonymizeFiles : %@", e);
			[AppController printStackTrace: e];
		}
		
		[[NSFileManager defaultManager] removeFileAtPath: file handler: nil];
		[[NSFileManager defaultManager] movePath:destPath toPath: file handler: nil];
	}
#endif
}
	
#pragma deprecated (pathResolved:)
- (NSString*) pathResolved:(NSString*) inPath {
	return [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath];
}

#pragma deprecated (isAliasPath:)
- (BOOL) isAliasPath:(NSString *)inPath {
	return [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath] != nil;
}

#pragma deprecated (resolveAliasPath:)
- (NSString*) resolveAliasPath:(NSString*)inPath {
	NSString* resolved = [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath];
	return resolved ? resolved : inPath;
}

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path { // __deprecated
	NSString *folder = path;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSString* temp = [self pathResolved:path];
		if (!temp)
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		else
		{ 
			folder = temp;
		}
	}
	/* 
	 if it exists see if it is a file or symbolic link
	 if it is a file, create a folder else leave it
	 */
	else
	{	
		NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		
		if (![[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) 
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];		
		
		attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO];
		
		//get absolute path if link
		if( [[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink]) 
			folder = [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath:path];
		
		if( [self pathResolved: path]) 
			folder = [self pathResolved: path];
	}
	return folder;
}

- (IBAction)revealInFinder: (id)sender
{
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
	}
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
	if( [filesToExport count])
	{
		[[NSWorkspace sharedWorkspace] selectFile:[filesToExport objectAtIndex: 0] inFileViewerRootedAtPath:nil];
	}
}

static volatile int numberOfThreadsForJPEG = 0;

- (BOOL) waitForAProcessor
{
	int processors =  MPProcessors();
	
//	processors--;
	if( processors < 1)
		processors = 1;
	
	[processorsLock lockWhenCondition: 1];
	BOOL result = numberOfThreadsForJPEG >= processors;
	if( result == NO)
	{
		numberOfThreadsForJPEG++;
		if( numberOfThreadsForJPEG >= processors)
		{
			[processorsLock unlockWithCondition: 0];
		}
		else
		{
			[processorsLock unlockWithCondition: 1];
		}
	}
	else
	{
		NSLog( @"waitForAProcessor ?? We should not be here...");
		[processorsLock unlockWithCondition: 0];
	}
	
	return result;
}

// Always modify this function in sync with compressionForModality in Decompress.mm / BrowserController.m
+ (int) compressionForModality: (NSString*) mod quality:(int*) quality resolution: (int) resolution
{
	NSArray *array;
	if( resolution < [[NSUserDefaults standardUserDefaults] integerForKey: @"CompressionResolutionLimit"])
		array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"];
	else
		array = [[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"];
	
	if( [mod isEqualToString: @"SR"]) // No compression for DICOM SR
		return compression_none;
	
	for( NSDictionary *dict in array)
	{
		if( [[dict valueForKey: @"modality"] isEqualToString: mod])
		{
			int compression = compression_none;
			if( [[dict valueForKey: @"compression"] intValue] == compression_sameAsDefault)
				dict = [array objectAtIndex: 0];
			
			compression = [[dict valueForKey: @"compression"] intValue];
			
			if( quality)
			{
				if( compression == compression_JPEG2000)
					*quality = [[dict valueForKey: @"quality"] intValue];
				else
					*quality = 0;
			}
			
			return compression;
		}
	}
	
	if( [array count] == 0)
		return compression_none;
	
	if( quality)
		*quality = [[[array objectAtIndex: 0] valueForKey: @"quality"] intValue];
	
	return [[[array objectAtIndex: 0] valueForKey: @"compression"] intValue];
}

#ifndef OSIRIX_LIGHT

#pragma deprecated(decompressDICOMJPEGinINCOMING:)
- (void)decompressDICOMJPEGinINCOMING:(NSArray*)array { // __deprecated
	[self decompressDICOMList:array to:_database.incomingDirPath];
}

- (void)decompressDICOMJPEG:(NSArray*)array { // __deprecated
	[self decompressDICOMList:array to:nil];
}

- (void)compressDICOMJPEGinINCOMING:(NSArray*)array { // __deprecated
	[self compressDICOMWithJPEG:array to:_database.incomingDirPath];
}

- (void)compressDICOMJPEG:(NSArray*)array { // __deprecated
	[self compressDICOMWithJPEG:array];
}

- (void)decompressArrayOfFiles:(NSArray*)array work:(NSNumber*)work { // __deprecated
	switch ([work charValue]) {
		case 'C':
			[_database initiateCompressFilesAtPaths:array];
			break;
		case 'X':
			[_database initiateCompressFilesAtPaths:array intoDirAtPath:[_database incomingDirPath]];
			break;
		case 'D':
			[_database initiateDecompressFilesAtPaths:array];
			break;
		case 'I':
			[_database initiateDecompressFilesAtPaths:array intoDirAtPath:[_database incomingDirPath]];
			break;
	}
}

- (IBAction) compressSelectedFiles: (id)sender
{
	if( /*bonjourDownloading == NO &&*/ [_database isLocal])
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
		
		[self checkResponder];
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		{
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
		
		[filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];
		
		NSMutableArray *result = [NSMutableArray array];
		
		for( int i = 0 ; i < [filesToExport count] ; i++)
		{
			if( [[[dicomFiles2Export objectAtIndex:i] valueForKey:@"fileType"] hasPrefix:@"DICOM"])
				[result addObject: [filesToExport objectAtIndex: i]];
		}
		
		[DCMPix purgeCachedDictionaries];
		
		[_database initiateCompressFilesAtPaths:result];
	}
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", nil), NSLocalizedString(@"Cannot compress images in a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
}

- (IBAction)decompressSelectedFiles: (id)sender
{
	if( /*bonjourDownloading == NO &&*/ [_database isLocal])
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
		
		[self checkResponder];
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		{
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
		
		[filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];
		
		NSMutableArray *result = [NSMutableArray array];
		
		for( int i = 0 ; i < [filesToExport count] ; i++)
		{
			if( [[[dicomFiles2Export objectAtIndex:i] valueForKey:@"fileType"] hasPrefix:@"DICOM"])
				[result addObject: [filesToExport objectAtIndex: i]];
		}
		
		[DCMPix purgeCachedDictionaries];
		
		[_database initiateDecompressFilesAtPaths:result];
	}
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", nil), NSLocalizedString(@"Cannot decompress images in a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
}

#endif

- (void)checkIncomingThread: (id)sender { // __deprecated
	[[DicomDatabase activeLocalDatabase] importFilesFromIncomingDir];
}

- (void) checkIncomingNow: (id) sender { // __deprecated
//	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
	[[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
}

- (void)checkIncoming: (id)sender { // __deprecated
//	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
	[[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
}

+ (void) createEmptyMovie:(NSMutableDictionary*)dict
{
	QTMovie* e = [QTMovie movie];
	[dict setObject:e forKey:@"movie"];
	
	[e detachFromCurrentThread];
}

- (void) createEmptyMovie:(NSMutableDictionary*)dict {
	return [BrowserController createEmptyMovie:dict];
}


+ (void) movieWithFile:(NSMutableDictionary*)dict
{
	QTMovie* e = [QTMovie movieWithFile:[dict objectForKey:@"file"] error:nil];
	[dict setObject:e forKey:@"movie"];
	
	[e detachFromCurrentThread];
}

- (void) movieWithFile:(NSMutableDictionary*)dict {
	return [BrowserController movieWithFile:dict];
}

+ (void)writeMovieToPath:(NSString*)fileName images:(NSArray*)imagesArray
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if (![NSThread isMainThread])
		 [QTMovie enterQTKitOnThread];

	@try
	{
		
		NSString* tempFileName = [fileName stringByAppendingString:@"temp"];
		QTMovie *mMovie = nil;
		
		if (![NSThread isMainThread])
		{
			NSMutableDictionary* dict = [NSMutableDictionary dictionary];
			[self performSelectorOnMainThread: @selector(createEmptyMovie:) withObject: dict waitUntilDone: YES];
			QTMovie *empty = [dict objectForKey:@"movie"];
			
			[empty attachToCurrentThread];
			[empty writeToFile:tempFileName withAttributes:NULL];
			[empty detachFromCurrentThread];
			
			dict = [NSMutableDictionary dictionaryWithObject:tempFileName forKey:@"file"];
			[self performSelectorOnMainThread:@selector(movieWithFile:) withObject:dict waitUntilDone:YES];
			mMovie = [dict objectForKey:@"movie"];
			[mMovie attachToCurrentThread];
		}
		else
		{
			// Life is so much simplier in a single thread application...
			[[QTMovie movie] writeToFile:tempFileName withAttributes:NULL];
			mMovie = [QTMovie movieWithFile:[fileName stringByAppendingString:@"temp"] error:nil];
		}
		
		[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
		
		if( [[NSUserDefaults standardUserDefaults] integerForKey: @"quicktimeExportRateValue"] <= 0)
			[[NSUserDefaults standardUserDefaults] setInteger: 10 forKey: @"quicktimeExportRateValue"];
		
		long long rateValue = [[NSUserDefaults standardUserDefaults] integerForKey: @"quicktimeExportRateValue"];
		long long timeValue = 600 / rateValue;
		long timeScale = 600;
		
		QTTime curTime = QTMakeTime(timeValue, timeScale);
		
		NSMutableDictionary *myDict = [NSMutableDictionary dictionaryWithObject: @"jpeg" forKey: QTAddImageCodecType];
		
		for ( id img in imagesArray)
		{
			NSAutoreleasePool *a = [[NSAutoreleasePool alloc] init];
			
			[mMovie addImage: img forDuration:curTime withAttributes: myDict];
			
			[a release];
		}
		
		[mMovie writeToFile: fileName withAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten]];
		[[NSFileManager defaultManager] removeFileAtPath:[fileName stringByAppendingString:@"temp"] handler: nil];

		if(![[NSThread currentThread] isMainThread])
		{
			[mMovie detachFromCurrentThread];
		}
	}
	@catch( NSException *e)
	{
		NSLog( @"****** writeMovie exception: %@", e);
		[AppController printStackTrace: e];
	}
	
	@finally
	{
		if (![NSThread isMainThread])
			[QTMovie exitQTKitOnThread];
		[pool release];
	}
}

- (void)writeMovie:(NSArray*)imagesArray name:(NSString*)fileName {
	[BrowserController writeMovieToPath:fileName images:imagesArray];
}

+(void)setPath:(NSString*)path relativeTo:(NSString*)dirPath forSeriesId:(int)seriesId kind:(NSString*)kind toSeriesPaths:(NSMutableDictionary*)seriesPaths {
	
	if (seriesId == -1)
		NSLog(@"SeriesId %d", seriesId);
	
	if (seriesPaths) {
		NSNumber* seriesIdK = [NSNumber numberWithInt:seriesId];
		
		path = [path stringByReplacingCharactersInRange:dirPath.range withString:@""];
		if ([path characterAtIndex:0] == '/')
			path = [path stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
		
		NSMutableDictionary* pathsForSeries = [seriesPaths objectForKey:seriesIdK];
		if (!pathsForSeries) {
			pathsForSeries = [NSMutableDictionary dictionary];
			[seriesPaths setObject:pathsForSeries forKey:seriesIdK];
		}
		
		[pathsForSeries setObject:path forKey:kind];
	}
}

+(void) exportQuicktime:(NSArray*)dicomFiles2Export :(NSString*)path :(BOOL)html :(BrowserController*)browser :(NSMutableDictionary*)seriesPaths
{
	Wait                *splash = nil;
	NSMutableArray		*imagesArray = [NSMutableArray array], *imagesArrayObjects = [NSMutableArray array];
	NSString			*tempPath, *previousPath = nil;
	long				previousSeries = -1;
	NSString			*previousStudy = @"", *previousPatientUID = @"", *previousSeriesInstanceUID = @"";
	BOOL				createHTML = html;
	
	NSMutableDictionary *htmlExportDictionary = [NSMutableDictionary dictionary];
	
	if([NSThread isMainThread])
		splash = [[Wait alloc] initWithString: NSLocalizedString(@"Export...", nil) :YES];
	
	[splash setCancel: YES];
	[splash showWindow: browser];
	[[splash progress] setMaxValue:[dicomFiles2Export count]];
	
	NSManagedObjectContext* managedObjectContext = NULL;
	if (dicomFiles2Export.count)
		managedObjectContext = [[dicomFiles2Export objectAtIndex:0] managedObjectContext];
	
	[managedObjectContext lock];
	
	@try
	{
		int uniqueSeriesID = 0;
		BOOL first = YES;
		BOOL cineRateSet = NO;
		
		[[NSUserDefaults standardUserDefaults] setInteger: 10 forKey: @"quicktimeExportRateValue"];
		
		for( DicomImage *curImage in dicomFiles2Export)
		{
			NSString *patientDirName = [curImage.series.study.name filenameString];
			
			tempPath = [path stringByAppendingPathComponent: patientDirName];
			
			NSMutableArray *htmlExportSeriesArray;
			if(![htmlExportDictionary objectForKey:curImage.series.study.name])
			{
				htmlExportSeriesArray = [NSMutableArray array];
				[htmlExportSeriesArray addObject:[curImage valueForKey: @"series"]];
				[htmlExportDictionary setObject:htmlExportSeriesArray forKey:[curImage valueForKeyPath: @"series.study.name"]];
			}
			else
			{
				htmlExportSeriesArray = [htmlExportDictionary objectForKey:[curImage valueForKeyPath: @"series.study.name"]];
				[htmlExportSeriesArray addObject:[curImage valueForKey: @"series"]];
			}
			
			// Find the PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( first)
				{
					if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
					{
						[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
					}
					else break;
				}
			}
			first = NO;
			
			tempPath = [tempPath stringByAppendingPathComponent: [[NSMutableString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]] filenameString]];
			if( [[curImage valueForKeyPath: @"series.study.id"] isEqualToString: previousStudy] == NO || [[curImage valueForKeyPath: @"series.study.patientUID"] isEqualToString: previousPatientUID] == NO)
			{
				previousPatientUID = [curImage valueForKeyPath: @"series.study.patientUID"];
				previousStudy = [curImage valueForKeyPath: @"series.study.id"];
				previousSeries = -1;
				uniqueSeriesID = 0;
				previousSeriesInstanceUID = @"";
			}
			
			// Find the STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
				[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			NSMutableString *seriesStr = [NSMutableString stringWithString:[curImage.series.name filenameString]];
			[BrowserController replaceNotAdmitted: seriesStr];
			
			tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
			tempPath = [tempPath stringByAppendingFormat: @"_%@", [curImage valueForKeyPath: @"series.id"]];
			
			
			if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue] || [[curImage valueForKeyPath: @"series.seriesInstanceUID"] isEqualToString: previousSeriesInstanceUID] == NO)
			{
				previousSeriesInstanceUID = [curImage valueForKeyPath: @"series.seriesInstanceUID"];
				uniqueSeriesID++;
				
				// DONT FORGET TO MODIFY THE SAME FUNCTIONS AT THE END OF THIS LOOP !
				
				if( [imagesArray count])
				{
					id tempID = [[imagesArray lastObject] bestRepresentationForDevice:nil];
						
					if( [tempID isKindOfClass: [NSPDFImageRep class]])
					{
						NSString* fullPath = [previousPath stringByAppendingPathExtension: @"pdf"];
						[[tempID PDFRepresentation] writeToFile:fullPath atomically: YES];
						[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"pdf" toSeriesPaths:seriesPaths];
						[imagesArray removeAllObjects];
						[imagesArrayObjects removeAllObjects];
					}
				}
				
				if( [imagesArray count] > 1)
				{
					int width, height;
					[QTExportHTMLSummary getMovieWidth: &width height: &height imagesArray: imagesArrayObjects];
					
					for( int index = 0 ; index < [imagesArray count]; index++)
					{
						NSImage *im = [imagesArray objectAtIndex: index];
						
						if( width != 0 && height != 0)
						{
							if( (int) [im size].width != width || height != (int) [im size].height)
							{
								NSImage *newImage = [im imageByScalingProportionallyToSize:NSMakeSize( width, height)];
								[imagesArray replaceObjectAtIndex: index withObject: newImage];
							}
						}
					}
					
					NSString* fullPath = [previousPath stringByAppendingPathExtension: @"mov"];
					[BrowserController writeMovieToPath:fullPath images:imagesArray];
					[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"mov" toSeriesPaths:seriesPaths];
				}
				else if( [imagesArray count] == 1)
				{
					NSArray *representations = [[imagesArray objectAtIndex: 0] representations];
					NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
					NSString* fullPath = [previousPath stringByAppendingPathExtension: @"jpg"];
					[bitmapData writeToFile:fullPath atomically:YES];
					[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"jpg" toSeriesPaths:seriesPaths];
				}
				
				//
				if(createHTML)
				{
					NSImage	*thumbnail = [[[NSImage alloc] initWithData: [curImage valueForKeyPath: @"series.thumbnail"]] autorelease];
					
					@try
					{
						if( thumbnail == nil)
						{
							if (browser)
							{
								[browser buildThumbnail: [curImage valueForKey: @"series"]];
								thumbnail = [[[NSImage alloc] initWithData: [curImage valueForKeyPath: @"series.thumbnail"]] autorelease];
							} else {
								// TODO: write thumb on TMP, assign thumbnail to its filecontents, delete tmp file
							}
						}
					}
					@catch ( NSException *e)
					{
						NSLog( @"********* Failed to generate the thumbnail : %@", e);
						[AppController printStackTrace: e];
					}
					
					if(!thumbnail)
						thumbnail = [[[NSImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Empty.tif"]] autorelease];
					
					if( thumbnail)
					{
						NSData *bitmapData = nil;
						NSArray *representations = [thumbnail representations];
						bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
						NSString* fullPath = [[tempPath stringByAppendingFormat: @"_%d", uniqueSeriesID] stringByAppendingString:@"_thumb.jpg"];
						[bitmapData writeToFile:fullPath atomically:YES];
						[BrowserController setPath:fullPath relativeTo:path forSeriesId:[[curImage valueForKeyPath:@"series.id"] intValue] kind:@"thumb" toSeriesPaths:seriesPaths];
					}
				}
				
				[imagesArrayObjects removeAllObjects];
				[imagesArray removeAllObjects];
				previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
			}
			
			tempPath = [tempPath stringByAppendingFormat: @"_%d", uniqueSeriesID];
			previousPath = [NSString stringWithString: tempPath];
			
			#ifndef OSIRIX_LIGHT
			if( [DCMAbstractSyntaxUID isPDF: [curImage valueForKeyPath: @"series.seriesSOPClassUID"]])
			{
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [curImage valueForKey: @"completePath"] decodingPixelData:NO];
				
				@try
				{
					if ([[dcmObject attributeValueWithName:@"SOPClassUID"] isEqualToString:[DCMAbstractSyntaxUID pdfStorageClassUID]])
					{
						NSData *pdfData = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
						
						if( pdfData)
						{
							NSImage *im = [[[NSImage alloc] initWithData: pdfData] autorelease];
							
							if( im)
							{
								[imagesArray addObject: im];
								[imagesArrayObjects addObject: curImage];
							}
						}
					}
				}
				@catch (NSException * e)
				{
					NSLog( @"******* pdfData exportQuicktime exception: %@", e);
					[AppController printStackTrace: e];
				}
			}
			else if( [DCMAbstractSyntaxUID isStructuredReport: [curImage valueForKeyPath: @"series.seriesSOPClassUID"]])
			{
				if( [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/dicomsr_osirix/"] == NO)
					[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/dicomsr_osirix/" attributes: nil];
			
				NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[curImage valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"xml"];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
				{
					NSTask *aTask = [[[NSTask alloc] init] autorelease];		
					[aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
					[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
					[aTask setArguments: [NSArray arrayWithObjects: @"+X1", [curImage valueForKey: @"completePath"], htmlpath, nil]];		
					[aTask launch];
					[aTask waitUntilExit];		
					[aTask interrupt];
				}
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
				{
					NSTask *aTask = [[[NSTask alloc] init] autorelease];
					[aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
					[aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];		
					[aTask launch];
					[aTask waitUntilExit];		
					[aTask interrupt];
				}
				
				NSImage *im = [[[NSImage alloc] initWithData: [NSData dataWithContentsOfFile: [htmlpath stringByAppendingPathExtension: @"pdf"]]] autorelease];
				
				if( im)
				{
					[imagesArray addObject: im];
					[imagesArrayObjects addObject: curImage];
				}
			}
			else
			#endif
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				@try
				{
					int frame = 0;
					
					if( [curImage valueForKey:@"frameID"])
						frame = [[curImage valueForKey:@"frameID"] intValue];
					
					DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [curImage valueForKey:@"completePathResolved"] :0 :1 :nil :frame :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:browser.isCurrentDatabaseBonjour imageObj:curImage];
					
					if( dcmPix)
					{
						float curWW = 0;
						float curWL = 0;
						
						if( [[curImage valueForKey:@"series"] valueForKey:@"windowWidth"])
						{
							curWW = [[[curImage valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
							curWL = [[[curImage valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
						}
						
						if( curWW != 0 && curWW !=curWL)
							[dcmPix checkImageAvailble :curWW :curWL];
						else
							[dcmPix checkImageAvailble :[dcmPix savedWW] :[dcmPix savedWL]];

						NSImage *im = [dcmPix image];
						
						if( im)
						{
							[imagesArray addObject: im];
							[imagesArrayObjects addObject: curImage];
							
							if( cineRateSet == NO && [dcmPix cineRate])
							{
								[[NSUserDefaults standardUserDefaults] setInteger: [dcmPix cineRate] forKey:@"quicktimeExportRateValue"];
							}
						}
						
						[dcmPix release];
					}
				}
				@catch( NSException *e)
				{
					NSLog( @"*** exportQuicktimeInt Loop: %@", e);
					[AppController printStackTrace: e];
				}
				[pool release];
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted]) break;
		}
		
		if( [imagesArray count])
		{
			id tempID = [[imagesArray lastObject] bestRepresentationForDevice:nil];
				
			if( [tempID isKindOfClass: [NSPDFImageRep class]])
			{
				NSString* fullPath = [previousPath stringByAppendingPathExtension: @"pdf"];
				[[tempID PDFRepresentation] writeToFile:fullPath atomically: YES];
				[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"pdf" toSeriesPaths:seriesPaths];
				[imagesArray removeAllObjects];
				[imagesArrayObjects removeAllObjects];
			}
		}
		
		if( [imagesArray count] > 1)
		{
			int width, height;
			[QTExportHTMLSummary getMovieWidth: &width height: &height imagesArray: imagesArrayObjects];
			
			for( int index = 0 ; index < [imagesArray count]; index++)
			{
				NSImage *im = [imagesArray objectAtIndex: index];
				
				if( width != 0 && height != 0)
				{
					if( (int) [im size].width != width || height != (int) [im size].height)
					{
						NSImage *newImage = [im imageByScalingProportionallyToSize:NSMakeSize( width, height)];
						[imagesArray replaceObjectAtIndex: index withObject: newImage];
					}
				}
			}
			
			NSString* fullPath = [previousPath stringByAppendingPathExtension:@"mov"];
			[BrowserController writeMovieToPath:fullPath images:imagesArray];
			[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"mov" toSeriesPaths:seriesPaths];
		}
		else if( [imagesArray count] == 1)
		{
			NSArray *representations = [[imagesArray objectAtIndex: 0] representations];
			NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			NSString* fullPath = [previousPath stringByAppendingPathExtension: @"jpg"];
			[bitmapData writeToFile:fullPath atomically:YES];
			[BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"jpg" toSeriesPaths:seriesPaths];
		}
		
		if(createHTML)
		{
			QTExportHTMLSummary *htmlExport = [[QTExportHTMLSummary alloc] init];
			[htmlExport setPatientsDictionary:htmlExportDictionary];
			[htmlExport setPath:path];
			[htmlExport createHTMLfiles];
			[htmlExport release];
		}
	}
	
	@catch (NSException * e)
	{
		NSLog( @"******** %@", [e description]);
		[AppController printStackTrace: e];
	}
	
	@finally {
		[managedObjectContext unlock];
		
		[splash close];
		[splash release];
	}
}
	
-(void) exportQuicktimeInt:(NSArray*) dicomFiles2Export :(NSString*) path :(BOOL) html
{
	[BrowserController exportQuicktime:dicomFiles2Export :path :html :self :NULL];
}

- (void)exportQuicktime: (id)sender
{
	NSOpenPanel *sPanel	= [NSOpenPanel openPanel];
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages: YES];
	else
		filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: YES];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the Quicktime files:",nil)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",nil)];
	[sPanel setTitle: NSLocalizedString(@"Export",nil)];
	[sPanel setCanCreateDirectories:YES];
	
	[sPanel setAccessoryView:exportQuicktimeView];
	
	if ([sPanel runModalForDirectory:nil file:nil types:nil] == NSFileHandlingPanelOKButton)
	{
		[self exportQuicktimeInt: dicomFiles2Export :[[sPanel filenames] objectAtIndex:0] :[exportHTMLButton state]];
	}
}

- (void) exportImageAs:(NSString*) format sender:(id) sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	long				previousSeries = -1;
	long				serieCount		= 0;
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array], *renameArray = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		NSLog(@"Files from contextual menu: %d", [filesToExport count]);
	}
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the image files:",nil)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",nil)];
	[sPanel setTitle: NSLocalizedString(@"Export",nil)];
	[sPanel setCanCreateDirectories:YES];
	
	if ([sPanel runModalForDirectory:nil file:nil types:nil] == NSFileHandlingPanelOKButton)
	{
		NSString *dest, *path = [[sPanel filenames] objectAtIndex:0];
		Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", nil) :YES];
		
		[splash setCancel:YES];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToExport count]];
		
		for( int i = 0; i < [filesToExport count]; i++)
		{
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSString *extension = format;
			
			NSString *tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
			
			// Find the PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( i == 0)
				{
					if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
					{
						[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
					}
					else break;
				}
			}
			
			tempPath = [tempPath stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]]]];
			
			// Find the STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			NSMutableString *seriesStr = [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.name"]];
			[BrowserController replaceNotAdmitted:seriesStr];
			tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
			tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
			
			// Find the SERIES folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			long imageNo = [[curImage valueForKey:@"instanceNumber"] intValue];
			
			if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue])
			{
				previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
				serieCount++;
			}
			
			dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension];
			
			int t = 2;
			while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
			{
				dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, t, extension];
				t++;
			}
			
			if( t != 2)
			{
				[renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension], @"oldName", [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, 1, extension], @"newName", nil]];
			}
			
			DCMPix* dcmPix = [[DCMPix alloc] initWithPath: [curImage valueForKey:@"completePathResolved"] :0 :1 :nil :[[curImage valueForKey:@"frameID"] intValue] :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj:curImage];
			
			if( dcmPix)
			{
				float curWW = 0;
				float curWL = 0;
				
				if( [[curImage valueForKey:@"series"] valueForKey:@"windowWidth"])
				{
					curWW = [[[curImage valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
					curWL = [[[curImage valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
				}
				
				if( curWW != 0 && curWW !=curWL)
					[dcmPix checkImageAvailble :curWW :curWL];
				else
					[dcmPix checkImageAvailble :[dcmPix savedWW] :[dcmPix savedWL]];
				
				if( [format isEqualToString:@"jpg"])
				{
					NSArray *representations = [[dcmPix image] representations];
					NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
					[bitmapData writeToFile:dest atomically:YES];
				}
				else
				{
					[[[dcmPix image] TIFFRepresentation] writeToFile:dest atomically:YES];
				}
				
				[dcmPix release];
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted]) 
				i = [filesToExport count];
		}
		
		for( NSDictionary *d in renameArray)
			[[NSFileManager defaultManager] moveItemAtPath: [d objectForKey: @"oldName"] toPath: [d objectForKey: @"newName"] error: nil];
		
		//close progress window	
		[splash close];
		[splash release];
	}
}

- (void)exportJPEG: (id)sender
{
	[self exportImageAs: @"jpg" sender: sender];
}

- (void)exportTIFF: (id)sender
{
	[self exportImageAs: @"tif" sender: sender];
}

#ifndef OSIRIX_LIGHT

- (IBAction) addStudiesToUser: (id) sender
{
	[notificationEmailArrayController setSelectionIndexes: [NSIndexSet indexSet]];
	
	[NSApp beginSheet: addStudiesToUserWindow
		   modalForWindow: self.window
			modalDelegate: nil
		   didEndSelector: nil
			  contextInfo: nil];
		
	int result = [NSApp runModalForWindow: addStudiesToUserWindow];
	[addStudiesToUserWindow makeFirstResponder: nil];
	
	if( result == NSRunStoppedResponse)
	{
		if( [[notificationEmailArrayController selectedObjects] count] == 0)
		{
			NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), NSLocalizedString( @"No user(s) selected, no studies will be added.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
		}
		else
		{
			[self.userManagedObjectContext lock];
			
			// Add them to select users
			
			@try 
			{
				for( NSManagedObject *user in [notificationEmailArrayController selectedObjects])
				{
					NSArray *studiesArrayStudyInstanceUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
					NSArray *studiesArrayPatientUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
					
					for( NSManagedObject *study in [self databaseSelection])
					{
						if( [[study valueForKey: @"type"] isEqualToString:@"Series"])
							study = [study valueForKey:@"study"];
							
						if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
						{
							NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: self.userManagedObjectContext];
						
							[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
							[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
							
							[studyLink setValue: user forKey: @"user"];
							
							@try
							{
								[self.userManagedObjectContext save: nil];
							}
							@catch (NSException * e)
							{
								NSLog( @"********** [self.userManagedObjectContext save: nil]");
								[AppController printStackTrace: e];
							}
							
							studiesArrayStudyInstanceUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
							studiesArrayPatientUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
							
							[[WebPortal defaultWebPortal] updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser: [user valueForKey: @"name"] ip: nil];
						}
					}
				}
			}
			@catch (NSException * e) 
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
				[AppController printStackTrace: e];
			}
			[self.userManagedObjectContext unlock];
		}
	}
	
	[NSApp endSheet: addStudiesToUserWindow];
	[addStudiesToUserWindow orderOut: self];
}

-(IBAction)sendEmailNotification:(id)sender {
#ifndef OSIRIX_LIGHT
	self.temporaryNotificationEmail = @"";
	self.customTextNotificationEmail = @"";
	
	[notificationEmailArrayController setSelectionIndexes: [NSIndexSet indexSet]];
	
	[NSApp beginSheet: notificationEmailWindow
		   modalForWindow: self.window
			modalDelegate: nil
		   didEndSelector: nil
			  contextInfo: nil];
	
	int result;
	restart:
	{
		result = [NSApp runModalForWindow: notificationEmailWindow];
	}
	
	[notificationEmailWindow makeFirstResponder: nil];
	
	if( result == NSRunStoppedResponse)
	{
		if( [[notificationEmailArrayController selectedObjects] count] == 0 && [temporaryNotificationEmail length] <= 3)
		{
			NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), NSLocalizedString( @"Select one or more users.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
			goto restart;
		}
		else
		{
			[self.userManagedObjectContext lock];
			
			@try
			{
				NSArray *destinationUsers = [notificationEmailArrayController selectedObjects];
				
				if( [temporaryNotificationEmail length] > 3)
				{
					// First, create a temporary user
					
					if( [temporaryNotificationEmail rangeOfString: @"@"].location == NSNotFound)
					{
						NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), NSLocalizedString( @"Is the user email correct? the @ character is not found.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
						goto restart;
					}
					else
					{
						NSString *name = [temporaryNotificationEmail substringToIndex: [temporaryNotificationEmail rangeOfString: @"@"].location];
						
						if( [name length] < 2)
						{
							NSRunCriticalAlertPanel( NSLocalizedString( @"Error", nil), NSLocalizedString( @"Name needs to be at least 2 characters.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
							goto restart;
						}
						else
						{
							NSManagedObject *user = [[WebPortal defaultWebPortal] newUserWithEmail:temporaryNotificationEmail];
							destinationUsers = [destinationUsers arrayByAddingObject: user];
						}
					}
				}
				
				@try
				{
					// Add them to select users AND send a notification email
					if( [destinationUsers count] > 0)
					{
						for( NSManagedObject *user in destinationUsers)
						{
							NSArray *studiesArrayStudyInstanceUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
							NSArray *studiesArrayPatientUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
							
							for( NSManagedObject *study in [self databaseSelection])
							{
								if( [[study valueForKey: @"type"] isEqualToString:@"Series"])
									study = [study valueForKey:@"study"];
								
								if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID indexOfObject: [study valueForKey: @"patientUID"]]  == NSNotFound)
								{
									NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: self.userManagedObjectContext];
									
									[studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
									[studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
									[studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
									
									[studyLink setValue: user forKey: @"user"];
									
									@try
									{
										[self.userManagedObjectContext save: nil];
									}
									@catch (NSException * e)
									{
										NSLog( @"************ [self.userManagedObjectContext save: nil]");
										[AppController printStackTrace: e];
									}
									
									studiesArrayStudyInstanceUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
									studiesArrayPatientUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
									
									[[WebPortal defaultWebPortal] updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser: [user valueForKey: @"name"] ip: nil];
								}
							}
						}
						
						[[WebPortal defaultWebPortal] sendNotificationsEmailsTo: destinationUsers aboutStudies: [self databaseSelection] predicate: nil replyTo: nil customText: self.customTextNotificationEmail];
					}
				}
				@catch( NSException *e)
				{
					NSLog( @"***** sendEmailNotification exception: %@", e);
					[AppController printStackTrace: e];
				}
			}
			@catch( NSException *e)
			{
				NSLog( @"***** sendEmailNotification exception: %@", e);
				[AppController printStackTrace: e];
			}
			
			[self.userManagedObjectContext unlock];
		}
	}
	
	[NSApp endSheet: notificationEmailWindow];
	[notificationEmailWindow orderOut: self];
#endif
}

-(IBAction)sendMail:(id)sender {
#ifndef OSIRIX_LIGHT
	if( [AppController hasMacOSXSnowLeopard])
	{
		#define kScriptName (@"Mail")
		#define kScriptType (@"scpt")
		#define kHandlerName (@"mail_images")
		#define noScriptErr 0
		
		/* Locate the script within the bundle */
		NSString *scriptPath = [[NSBundle mainBundle] pathForResource: kScriptName ofType: kScriptType];
		NSURL *scriptURL = [NSURL fileURLWithPath: scriptPath];

		NSDictionary *errorInfo = nil;
		
		/* Here I am using "initWithContentsOfURL:" to load a pre-compiled script, rather than using "initWithSource:" to load a text file with AppleScript source.  The main reason for this is that the latter technique seems to give rise to inexplicable -1708 (errAEEventNotHandled) errors on Jaguar. */
		NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL: scriptURL error: &errorInfo];
		
		/* See if there were any errors loading the script */
		if (!script || errorInfo)
			NSLog(@"%@", errorInfo);
		
		/* We have to construct an AppleEvent descriptor to contain the arguments for our handler call.  Remember that this list is 1, rather than 0, based. */
		NSAppleEventDescriptor *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
		[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"subject"] atIndex: 1];
		[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"defaultaddress@mac.com"] atIndex: 2];
		
		NSAppleEventDescriptor *listFiles = [NSAppleEventDescriptor listDescriptor];
		NSAppleEventDescriptor *listCaptions = [NSAppleEventDescriptor listDescriptor];
		NSAppleEventDescriptor *listComments = [NSAppleEventDescriptor listDescriptor];
		
		[[NSUserDefaults standardUserDefaults] setValue: @"" forKey:@"defaultZIPPasswordForEmail"];
		
		redoZIPpassword:
		
		[NSApp beginSheet: ZIPpasswordWindow
		   modalForWindow: self.window
			modalDelegate: nil
		   didEndSelector: nil
			  contextInfo: nil];
		
		int result = [NSApp runModalForWindow: ZIPpasswordWindow];
		[ZIPpasswordWindow makeFirstResponder: nil];
		
		[NSApp endSheet: ZIPpasswordWindow];
		[ZIPpasswordWindow orderOut: self];
		
		if( result == NSRunStoppedResponse)
		{
			if( [(NSString*) [[NSUserDefaults standardUserDefaults] valueForKey: @"defaultZIPPasswordForEmail"] length] < 8)
			{
				NSBeep();
				goto redoZIPpassword;
			}
			
			NSMutableArray *dicomFiles2Export = [NSMutableArray array];
			NSMutableArray *filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: NO];
			
			[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/zipFilesForMail" error: nil];
			[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/zipFilesForMail" attributes: nil];
			
			BOOL encrypt = [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptForExport"];
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"encryptForExport"];
			
			self.passwordForExportEncryption = [[NSUserDefaults standardUserDefaults] valueForKey: @"defaultZIPPasswordForEmail"];
			
			NSArray *r = [self exportDICOMFileInt: @"/tmp/zipFilesForMail/" files: filesToExport objects: dicomFiles2Export];
			
			[[NSUserDefaults standardUserDefaults] setBool: encrypt forKey: @"encryptForExport"];
			
			if( [r count] > 0)
			{
				int f = 0;
				NSString *root = @"/tmp/zipFilesForMail";
				NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil];
				for( int x = 0; x < [files count] ; x++)
				{
					if( [[[files objectAtIndex: x] pathExtension] isEqualToString: @"zip"])
					{
						[listFiles insertDescriptor: [NSAppleEventDescriptor descriptorWithString: [root stringByAppendingPathComponent: [files objectAtIndex: x]]] atIndex:1+f];
						[listCaptions insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @""] atIndex:1+f];
						[listComments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @""] atIndex:1+f];
						f++;
					}
				}
				
				[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithInt32: f] atIndex: 3];
				[arguments insertDescriptor: listFiles atIndex: 4];
				[arguments insertDescriptor: listCaptions atIndex: 5];
				[arguments insertDescriptor: listComments atIndex: 6];
				
				[arguments insertDescriptor: [NSAppleEventDescriptor descriptorWithString: @"Cancel"] atIndex: 7];

				errorInfo = nil;

				/* Call the handler using the method in our special category */
				NSAppleEventDescriptor *result = [script callHandler: kHandlerName withArguments: arguments errorInfo: &errorInfo];
				
				int scriptResult = [result int32Value];

				/* Check for errors in running the handler */
				if (errorInfo)
				{
					NSLog(@"%@", errorInfo);
				}
				/* Check the handler's return value */
				else if (scriptResult != noScriptErr)
				{
					NSRunAlertPanel(NSLocalizedString(@"Script Failure", @"Title on script failure window."), [NSString stringWithFormat: @"%@ %d", NSLocalizedString(@"The script failed:", @"Message on script failure window."), scriptResult], NSLocalizedString(@"OK", @""), nil, nil);
				}
			}
		}
		
		[script release];
		[arguments release];
	}
	else if( [NSThread isMainThread]) NSRunCriticalAlertPanel( NSLocalizedString( @"Unsupported", nil), NSLocalizedString( @"This function requires MacOS 10.6 or higher.", nil), NSLocalizedString( @"OK", nil) , nil, nil);
#endif
}

#endif

+ (NSMutableString*) replaceNotAdmitted: (NSString*)name
{
	NSMutableString* mstr;
	if ([name isKindOfClass:[NSMutableString class]])
		mstr = (NSMutableString*) name;
	else
		mstr = [[name mutableCopy] autorelease];
		
	[mstr replaceOccurrencesOfString:@" " withString:@"_" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"." withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"," withString:@"" options:0 range:mstr.range]; 
	[mstr replaceOccurrencesOfString:@"^" withString:@"" options:0 range:mstr.range]; 
	[mstr replaceOccurrencesOfString:@"/" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"\\" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"|" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"-" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@":" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"*" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"<" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@">" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"?" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"#" withString:@"" options:0 range:mstr.range];
	[mstr replaceOccurrencesOfString:@"%" withString:@"" options:0 range:mstr.range];
	
	return mstr;
}

#ifndef OSIRIX_LIGHT
- (void) importReport:(NSString*) path UID: (NSString*) uid
{
	if( [[NSFileManager defaultManager] fileExistsAtPath: path])
	{
		NSManagedObjectContext *context = self.managedObjectContext;
		
		[context lock];
		
		@try
		{
			NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
			[dbRequest setPredicate: [NSPredicate predicateWithFormat:  @"studyInstanceUID == %@", uid]];
			
			NSError *error = nil;
			NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
			
			if( [studiesArray count])
			{
				DicomStudy *s = [studiesArray lastObject];
				
				NSString *reportURL = nil;
				
				if( [[path pathExtension] length])
					reportURL = [NSString stringWithFormat: @"%@/REPORTS/%@.%@", [self documentsDirectory], [Reports getUniqueFilename: s], [path pathExtension]];
				else
					reportURL = [NSString stringWithFormat: @"%@/REPORTS/%@", [self documentsDirectory], [Reports getUniqueFilename: s]];
					
				[[NSFileManager defaultManager] removeFileAtPath: reportURL handler: nil];
				[[NSFileManager defaultManager] copyPath: path toPath: reportURL handler: nil];
				[s setValue: reportURL forKey: @"reportURL"];
			}
		}
		
		@catch (NSException * e)
		{
			NSLog( @"importCommentsAndStatusFromDictionary exception: %@", e);
			[AppController printStackTrace: e];
		}
		
		[context unlock];
	}
}
#endif

- (NSArray*) exportDICOMFileInt: (NSString*) location files: (NSMutableArray*) filesToExport objects: (NSMutableArray*) dicomFiles2Export
{
	return [self exportDICOMFileInt: [NSMutableDictionary dictionaryWithObjectsAndKeys: location, @"location", filesToExport, @"filesToExport", dicomFiles2Export, @"dicomFiles2Export", nil]];
}

- (void) runInformationAlertPanel:(NSMutableDictionary*) dict
{
	int a = NSRunInformationalAlertPanel( [dict objectForKey: @"title"], [dict objectForKey: @"message"], [dict objectForKey: @"button1"], [dict objectForKey: @"button2"], [dict objectForKey: @"button3"]);
	
	[dict setObject: [NSNumber numberWithInt: a] forKey: @"result"];
}

- (NSArray*) exportDICOMFileInt: (NSMutableDictionary*) parameters
{
	NSAutoreleasePool *pool = nil;
	
	if( [NSThread isMainThread] == NO) // This is IMPORTANT for the result ! A thread cannot return a 'autorelease' object without a pool.... DO NOT MODIFY !
		pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *result = [NSMutableArray array];
	
	@synchronized( parameters)
	{
		[parameters setObject: result forKey: @"result"];
	}
	
	@try 
	{
		NSString *location = [parameters objectForKey: @"location"];
		NSMutableArray *filesToExport = [parameters objectForKey: @"filesToExport"];
		NSMutableArray *dicomFiles2Export = [parameters objectForKey: @"dicomFiles2Export"];
		
		[filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];

		NSString			*dest, *path = location;
		Wait                *splash = nil;
		BOOL				addDICOMDIR = [[NSUserDefaults standardUserDefaults] boolForKey:@"AddDICOMDIRForExport"];
		long				previousSeries = -1, serieCount = 0;
		
		if( [NSThread isMainThread])
			splash = [[Wait alloc] initWithString:NSLocalizedString( @"Exporting...", nil) :YES];
		
		NSMutableArray		*files2Compress = [NSMutableArray array];
		DicomStudy			*previousStudy = nil;
		BOOL				exportAborted = NO;
		NSMutableArray		*renameArray = [NSMutableArray array];
		
		[splash setCancel:YES];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToExport count]];
		
		[[DicomStudy dbModifyLock] lock];
		
		@try
		{
			for( int i = 0; i < [filesToExport count]; i++)
			{
				NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
				NSString		*extension = [[filesToExport objectAtIndex:i] pathExtension];
				
				if( [curImage valueForKey: @"fileType"])
				{
					if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"])
						extension = [NSString stringWithString:@"dcm"];
				}
				
				if([extension isEqualToString:@""])
					extension = [NSString stringWithString:@"dcm"]; 
				
				NSString *tempPath;
				// if creating DICOMDIR. Limit length to 8 char
				if (!addDICOMDIR)  
					tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.study.name"]]]];
				else
				{
					NSMutableString *name;
					
					if( [curImage valueForKeyPath: @"series.study.name"] == nil)
						name = [NSMutableString stringWithString: @"unnamed"];
					else if ([(NSString*) [curImage valueForKeyPath: @"series.study.name"] length] > 8)
						name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
					else
						name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
					
					NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
					name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
					
					[BrowserController replaceNotAdmitted: name];
					
					tempPath = [path stringByAppendingPathComponent:name];
				}
				
				@synchronized( parameters)
				{
					[result addObject: [tempPath lastPathComponent]];
				}
				
				// Find the DICOM-PATIENT folder
				if ( ![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
				{
					[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
				}
				else
				{
					if( i == 0)
					{
						NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:	NSLocalizedString(@"Export", nil), @"title",
																												[NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@), or merge the existing content with the new files?", nil), [tempPath lastPathComponent]], @"message",
																												NSLocalizedString(@"Replace", nil), @"button1",
																												NSLocalizedString(@"Cancel", nil), @"button2",
																												NSLocalizedString(@"Merge", nil), @"button3",
																												nil];
						
						[self performSelectorOnMainThread: @selector( runInformationAlertPanel:) withObject: options waitUntilDone: YES]; // YES : because we are waiting the result
						
						int a;
						if( [options objectForKey: @"result"])
							a = [[options objectForKey: @"result"] intValue];
						else a = NSAlertAlternateReturn; // Cancel
						
						if( a == NSAlertDefaultReturn)
						{
							[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
							[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
						}
						else if( a == NSAlertOtherReturn)
						{
							// Merge
						}
						else break;
					}
				}
				
				NSString *studyPath = nil;
				
				if( [folderTree selectedTag] == 0)
				{
					NSString *studyId = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.study.id"]]];
					NSString *studyName = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.study.studyName"]]];
					
					if( studyId == nil || [studyId length] == 0)
						studyId = [NSString stringWithString: @"0"];
					
					if( studyName == nil || [studyName length] == 0)
						studyName = [NSString stringWithString: @"unnamed"];
					
					if (!addDICOMDIR)
						tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", studyName, studyId]];
					else
					{				
						NSMutableString *name;
						if ([(NSString*)studyId length] > 8)
							name = [NSMutableString stringWithString:[[studyId substringToIndex:7] uppercaseString]];
						else
							name = [NSMutableString stringWithString:[studyId uppercaseString]];
						
						NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
						name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
						
						[BrowserController replaceNotAdmitted: name];
						tempPath = [tempPath stringByAppendingPathComponent:name];
					}
					
					// Find the DICOM-STUDY folder
					if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
					
					studyPath = tempPath;
					
					NSNumber *seriesId = [curImage valueForKeyPath: @"series.id"];
					NSString *seriesName = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.name"]]];
					
					if( seriesId == nil)
						seriesId = [NSNumber numberWithInt: 0];
					
					if( seriesName == nil || [seriesName length] == 0)
						seriesName = [NSString stringWithString: @"unnamed"];
					
					if ( !addDICOMDIR)
					{
						NSMutableString *seriesStr = [NSMutableString stringWithString: seriesName];
						
						[BrowserController replaceNotAdmitted:seriesStr];
						
						tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
						tempPath = [tempPath stringByAppendingFormat:@"_%@", seriesId];
					}
					else
					{
						NSMutableString *name;
						//				if ([[curImage valueForKeyPath: @"series.name"] length] > 8)
						//					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.name"] substringToIndex:7] uppercaseString]];
						//				else
						//					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.name"] uppercaseString]];
						
						name = [NSMutableString stringWithString: [[seriesId stringValue] uppercaseString]];
						
						NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
						name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
						
						[BrowserController replaceNotAdmitted: name];
						tempPath = [tempPath stringByAppendingPathComponent:name];
					}
					
					// Find the DICOM-SERIE folder
					if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
				}
				else studyPath = tempPath;
				
				if( previousStudy != [curImage valueForKeyPath: @"series.study"])
				{
					previousStudy = [curImage valueForKeyPath: @"series.study"];
				}
				
				long imageNo = [[curImage valueForKey:@"instanceNumber"] intValue];
				
				if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue])
				{
					previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
					serieCount++;
				}
				if (!addDICOMDIR)
					dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension];
				else
					dest = [NSString stringWithFormat:@"%@/%4.4d%4.4d", tempPath, serieCount, imageNo];
				
				int t = 2;
				while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
				{
					if (!addDICOMDIR)
						dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, t, extension];
					else
						dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, t];
					t++;
				}
				
				if( t != 2)
				{
					if (!addDICOMDIR)
						[renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension], @"oldName", [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, 1, extension], @"newName", nil]];
					else
						[renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/%4.4d%4.4d", tempPath, serieCount, imageNo], @"oldName", [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, 1], @"newName", nil]];
				}
				
				NSError *error = nil;
				if( [[NSFileManager defaultManager] copyItemAtPath:[filesToExport objectAtIndex:i] toPath:dest error: &error] == NO)
				{
					NSLog( @"***** %@", error);
					NSLog( @"***** src = %@", [filesToExport objectAtIndex:i]);
					NSLog( @"***** dst = %@", dest);
				}
				
				if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"])
				{
					switch( [compressionMatrix selectedTag])
					{
						case 1:
							[files2Compress addObject: dest];
							break;
							
						case 2:
							[files2Compress addObject: dest];
							break;
					}
				}
				
				if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
				{
					[[NSFileManager defaultManager] copyPath:[[[filesToExport objectAtIndex:i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dest stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
				}
				
				[splash incrementBy:1];
				
				[NSThread currentThread].progress = (float) i / (float) [filesToExport count];
				[NSThread currentThread].status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [filesToExport count]-i];
				
				if( [splash aborted] || [NSThread currentThread].isCancelled)
				{
					i = [filesToExport count];
					exportAborted = YES;
				}
			}
		}
		@catch (NSException * e)
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			[AppController printStackTrace: e];
		}
		
		[[DicomStudy dbModifyLock] unlock];
		
		for( NSDictionary *d in renameArray)
			[[NSFileManager defaultManager] moveItemAtPath: [d objectForKey: @"oldName"] toPath: [d objectForKey: @"newName"] error: nil];
		
		//close progress window	
		[splash close];
		[splash release];
		
		if( [files2Compress count] > 0 && exportAborted == NO)
		{
	//		[waitCompressionWindow showWindow:self];
	//		[[waitCompressionWindow progress] setMaxValue: [files2Compress count]];
			
			#ifndef OSIRIX_LIGHT
			switch( [compressionMatrix selectedTag])
			{
				case 1:
					[self decompressArrayOfFiles: files2Compress work: [NSNumber numberWithChar: 'C']];
					break;
					
				case 2:
					[self decompressArrayOfFiles: files2Compress work: [NSNumber numberWithChar: 'D']];
					break;
			}
			#endif
			
	//		[waitCompressionWindow close];
		}
		
		// add DICOMDIR
		//NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",path];
		
		// ANR - I had to create this loop, otherwise, if I export a folder on the desktop, the dcmkdir will scan all files and folders available on the desktop.... not only the exported folder.
		
		if (addDICOMDIR && exportAborted == NO)
		{
			for( int i = 0; i < [filesToExport count]; i++)
			{
				NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
				NSMutableString *name;
				
				if ([(NSString*)[curImage valueForKeyPath: @"series.study.name"] length] > 8)
					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
				else
					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
				
				NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
				
				[BrowserController replaceNotAdmitted: name];
				
				NSString *tempPath = [path stringByAppendingPathComponent:name];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [tempPath stringByAppendingPathComponent:@"DICOMDIR"]] == NO)
				{
					if( [AppController hasMacOSXSnowLeopard] == NO)
					{
						NSRunCriticalAlertPanel( NSLocalizedString( @"DICOMDIR", nil), NSLocalizedString( @"DICOMDIR creation requires MacOS 10.6 or higher. DICOMDIR file will NOT be generated.", nil), NSLocalizedString( @"OK", nil), nil, nil);
					}
					else
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
						NSTask *theTask;
						NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+I",@"+id", tempPath,  nil];
						
						theTask = [[NSTask alloc] init];
						[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
						[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmmkdir"]];
						[theTask setCurrentDirectoryPath:tempPath];
						[theTask setArguments:theArguments];		
						
						[theTask launch];
						[theTask waitUntilExit];
						[theTask release];
						
						[pool release];
					}
				}
			}
		}
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptForExport"] == YES && exportAborted == NO)
		{
            for( int i = 0; i < [filesToExport count]; i++)
            {
                NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
				NSMutableString *name;
				NSString *tempPath;
				
				if( !addDICOMDIR)  
					tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.study.name"]]]];
				else
				{
					if ([(NSString*)[curImage valueForKeyPath: @"series.study.name"] length] > 8)
						name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
					else
						name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
                    
					NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
					name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
                    
					[BrowserController replaceNotAdmitted: name];
                    
					tempPath = [path stringByAppendingPathComponent:name];
				}
                
                [[NSFileManager defaultManager] removeItemAtPath: [tempPath stringByAppendingPathExtension: @"zip"] error: nil];
            }
            
			for( int i = 0; i < [filesToExport count]; i++)
			{
				NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
				NSMutableString *name;
				NSString *tempPath;
				
				if( !addDICOMDIR)  
					tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.study.name"]]]];
				else
				{
					if ([(NSString*)[curImage valueForKeyPath: @"series.study.name"] length] > 8)
						name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
					else
						name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
				
					NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
					name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
				
					[BrowserController replaceNotAdmitted: name];
				
					tempPath = [path stringByAppendingPathComponent:name];
				}
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [tempPath stringByAppendingPathExtension: @"zip"]] == NO)
				{
					[BrowserController encryptFileOrFolder: tempPath inZIPFile: [tempPath stringByAppendingPathExtension: @"zip"] password: passwordForExportEncryption];
				}
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		#ifdef OSIRIX_VIEWER
		[AppController printStackTrace: e];
		#endif
	}
	
	self.passwordForExportEncryption = @"";
	
	[pool release];
	
	if( [NSThread isMainThread])
		return result;
	else
		return nil;
}

+ (void) encryptFiles: (NSArray*) srcFiles inZIPFile: (NSString*) destFile password: (NSString*) password
{
	NSTask *t;
	NSArray *args;
	
	if( [AppController hasMacOSXSnowLeopard] == NO && [NSThread isMainThread] && [password length] > 0)
	{
		password = nil;
		NSRunCriticalAlertPanel(NSLocalizedString(@"ZIP Encryption", nil), NSLocalizedString(@"ZIP encryption requires MacOS 10.6 or higher. The ZIP file will be generated, but NOT encrypted with a password.", nil), NSLocalizedString(@"OK",nil),nil, nil);
		return;
	}
	
	if( destFile)
		[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
	
	WaitRendering *wait = nil;
	if( [NSThread isMainThread])
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Compressing the files...", nil)];
		[wait showWindow:self];
	}
	
	@try
	{
		#define CHUNKZIP 1000
		
		int total = [srcFiles count];
		
		for( int i = 0; i < total;)
		{
			int no;
			
			if( i + CHUNKZIP >= total) no = total - i; 
			else no = CHUNKZIP;
			
			NSRange range = NSMakeRange( i, no);
			
			id *objs = (id*) malloc( no * sizeof( id));
			if( objs)
			{
				[srcFiles getObjects: objs range: range];
				
				NSArray *subArray = [NSArray arrayWithObjects: objs count: no];
				
				t = [[[NSTask alloc] init] autorelease];
				[t setLaunchPath: @"/usr/bin/zip"];
				
				if( [password length] > 0)
					args = [NSArray arrayWithObjects: @"-q", @"-j", @"-e", @"-P", password, destFile, nil];
				else
					args = [NSArray arrayWithObjects: @"-q", @"-j", destFile, nil];
					
				args = [args arrayByAddingObjectsFromArray: subArray];
				
				[t setArguments: args];
				[t launch];
				while( [t isRunning]) [NSThread sleepForTimeInterval: 0.01];
				
				free( objs);
			}
			
			i += no;
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"**** encryptFileOrFolder exception: %@", e);
		[AppController printStackTrace: e];
	}
	
	[wait close];
	[wait release];
}

+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password 
{
	return [BrowserController encryptFileOrFolder: srcFolder inZIPFile: destFile password: password deleteSource: YES showGUI: YES];
}

+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource
{
	return [BrowserController encryptFileOrFolder: srcFolder inZIPFile: destFile password: password deleteSource: deleteSource showGUI: YES];
}

+ (void) encryptFileOrFolder: (NSString*) srcFolder inZIPFile: (NSString*) destFile password: (NSString*) password deleteSource: (BOOL) deleteSource showGUI: (BOOL) showGUI
{
	NSTask *t;
	NSArray *args;
	
	if( [AppController hasMacOSXSnowLeopard] == NO && [NSThread isMainThread] && [password length] > 0)
	{
		password = nil;
		NSRunCriticalAlertPanel(NSLocalizedString(@"ZIP Encryption", nil), NSLocalizedString(@"ZIP encryption requires MacOS 10.6 or higher. The ZIP file will be generated, but NOT encrypted with a password.", nil), NSLocalizedString(@"OK",nil),nil, nil);
		return;
	}
	
	if( destFile)
		[[NSFileManager defaultManager] removeItemAtPath: destFile error: nil];
	
	WaitRendering *wait = nil;
	if( [NSThread isMainThread] && showGUI == YES)
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Compressing the files...", nil)];
		[wait showWindow:self];
	}
	
	@try
	{
		t = [[[NSTask alloc] init] autorelease];
		[t setLaunchPath: @"/usr/bin/zip"];
		
		BOOL isDirectory;
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: srcFolder isDirectory: &isDirectory])
		{
			[t setCurrentDirectoryPath: [srcFolder stringByDeletingLastPathComponent]];
	
			if( [password length] > 0)
				args = [NSArray arrayWithObjects: @"-q", @"-r", @"-e", @"-P", password, destFile, [srcFolder lastPathComponent], nil];
			else
				args = [NSArray arrayWithObjects: @"-q", @"-r", destFile, [srcFolder lastPathComponent], nil];
			
			[t setArguments: args];
			[t launch];
			[t waitUntilExit];
			
			if( [t terminationStatus] == 0 && deleteSource == YES)
			{
				if( srcFolder)
					[[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
			}
		}
	}
	@catch (NSException *e)
	{
		NSLog( @"**** encryptFileOrFolder exception: %@", e);
		[AppController printStackTrace: e];
	}
	
	[wait close];
	[wait release];
}

- (void) exportDICOMFile: (id)sender
{
	NSOpenPanel *sPanel = [NSOpenPanel openPanel];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the DICOM files:",nil)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",nil)];
	[sPanel setTitle: NSLocalizedString(@"Export",nil)];
	[sPanel setCanCreateDirectories:YES];
	[sPanel setAccessoryView:exportAccessoryView];
	self.passwordForExportEncryption = @"";
	
	[compressionMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"Compression Mode for Export"]];
	
	if ([sPanel runModalForDirectory: nil file: nil types: nil] == NSFileHandlingPanelOKButton)
	{
		[sPanel makeFirstResponder: nil];
		
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing the files...", nil)];
		[wait showWindow: self];
		
		[self checkResponder];
		if( ([sender isKindOfClass: [NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages: NO];
		else
			filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: NO];
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AddROIsForExport"] == NO)
		{
			NSPredicate *predicate = nil;
			
			@try
			{
				predicate = [NSPredicate predicateWithFormat: @"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX ROI SR", @"5002"];
				dicomFiles2Export = [[[dicomFiles2Export filteredArrayUsingPredicate: predicate] mutableCopy] autorelease];
				
				predicate = [NSPredicate predicateWithFormat: @"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX Report SR", @"5003"];
				dicomFiles2Export = [[[dicomFiles2Export filteredArrayUsingPredicate: predicate] mutableCopy] autorelease];
				
				predicate = [NSPredicate predicateWithFormat: @"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX Annotations SR", @"5004"];
				dicomFiles2Export = [[[dicomFiles2Export filteredArrayUsingPredicate: predicate] mutableCopy] autorelease];
			}
			@catch (NSException *e)
			{
				NSLog( @"**** exportDICOMFile exception: %@", e);
				[AppController printStackTrace: e];
			}
			
			filesToExport = [[[dicomFiles2Export valueForKey: @"completePath"] mutableCopy] autorelease];
		}
		
		[wait close];
		[wait release];
		
		NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: [[sPanel filenames] objectAtIndex:0], @"location", filesToExport, @"filesToExport", dicomFiles2Export, @"dicomFiles2Export", nil];
		
		NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( exportDICOMFileInt: ) object: d] autorelease];
		t.name = NSLocalizedString( @"Exporting...", nil);
		t.supportsCancel = YES;
		t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [filesToExport count]];
		
		[[ThreadsManager defaultManager] addThreadAndStart: t];
		
		[[NSUserDefaults standardUserDefaults] setInteger:[compressionMatrix selectedTag] forKey:@"Compression Mode for Export"];
	}
}

#ifndef OSIRIX_LIGHT
- (void)burnDICOM: (id)sender
{
	for( NSWindow *win in [NSApp windows])
	{
		if( [[win windowController] isKindOfClass:[BurnerWindowController class]])
		{
			NSRunInformationalAlertPanel( NSLocalizedString(@"Burn", nil), NSLocalizedString(@"A burn session is already opened. Close it to burn a new study.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			[win makeKeyAndOrderFront:self];
			return;
		}
	}
	
	NSMutableArray *managedObjects = [NSMutableArray array];
	NSMutableArray *filesToBurn;
	//Burn additional Files. Not just images. Add SRs
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) filesToBurn = [self filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];
	else filesToBurn = [self filesForDatabaseOutlineSelection: managedObjects onlyImages:NO];
	
	BurnerWindowController *burnerWindowController = [[BurnerWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects];
	
	[burnerWindowController showWindow:self];
}
#endif

#ifndef OSIRIX_LIGHT
- (IBAction)anonymizeDICOM:(id)sender
{
	NSMutableArray *dicomFiles2Anonymize = [NSMutableArray array];
	NSMutableArray *filesToAnonymize;
	
	[self checkResponder];
	
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		filesToAnonymize = [[self filesForDatabaseMatrixSelection: dicomFiles2Anonymize] retain];
	else
		filesToAnonymize = [[self filesForDatabaseOutlineSelection: dicomFiles2Anonymize] retain];
	
	[filesToAnonymize removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Anonymize];
	
	for( int i = 0 ; i < dicomFiles2Anonymize.count; i++)
	{
		if( [[[dicomFiles2Anonymize objectAtIndex: i] fileType] isEqualToString: @"DICOM"] == NO)
		{
			[dicomFiles2Anonymize removeObjectAtIndex: i];
			[filesToAnonymize removeObjectAtIndex: i];
			
			i--;
		}
	}
	
	if( dicomFiles2Anonymize.count == 0)
	{
		NSRunAlertPanel( NSLocalizedString(@"Anonymize Error", nil), NSLocalizedString(@"No DICOM files in this selection.", nil), nil, nil, nil);
	}
	else
	{
		NSArray* ref = [NSArray arrayWithObjects: filesToAnonymize, dicomFiles2Anonymize, NULL];
		[Anonymization showSavePanelForDefaultsKey:@"AnonymizationFields" modalForWindow:self.window modalDelegate:self didEndSelector:@selector(anonymizationSavePanelDidEnd:) representedObject:ref];
	}
	
//	AnonymizerWindowController	*anonymizerController = [[AnonymizerWindowController alloc] init];
//	
//	[anonymizerController setFilesToAnonymize:paths :dicomFiles2Anonymize];
//	[anonymizerController showWindow:self];
//	[anonymizerController anonymize:self];
//	
//	if( [anonymizerController cancelled] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"replaceAnonymize"] == YES && !![_database isLocal])
//	{
//		// Delete the non-anonymized
//		[self delItem: sender];
//		
//		// Add the anonymized files
//		[self addFilesAndFolderToDatabase: [anonymizerController producedFiles]];
//	}
//	
//	[anonymizerController release];*/
	
	[filesToAnonymize release];
}

-(void)anonymizationSavePanelDidEnd:(AnonymizationSavePanelController*)aspc
{
	NSArray* imagePaths = [aspc.representedObject objectAtIndex:0];
	NSArray* imageObjs = [aspc.representedObject objectAtIndex:1];
	
	switch (aspc.end)
	{
		case AnonymizationSavePanelSaveAs:
		{
			[Anonymization anonymizeFiles:imagePaths dicomImages: imageObjs toPath:aspc.outputDir withTags:aspc.anonymizationViewController.tagsValues];
		}
		break;
		
		case AnonymizationSavePanelAdd:
		case AnonymizationSavePanelReplace:
		{
			NSString* tempDir = [[NSFileManager defaultManager] tmpFilePathInTmp];
			NSDictionary* anonymizedFiles = [Anonymization anonymizeFiles:imagePaths dicomImages: imageObjs toPath:tempDir withTags:aspc.anonymizationViewController.tagsValues];
			
			// remove old files?
			if (aspc.end == AnonymizationSavePanelReplace)
				[self delItem:self]; // this assumes the selection hasn't changed since the user clicked the Anonymize button
			
			BOOL COPYDATABASE = [[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASE"];
			int COPYDATABASEMODE = [[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASEMODE"];
	
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"COPYDATABASE"];
			[[NSUserDefaults standardUserDefaults] setInteger: always forKey: @"COPYDATABASEMODE"];

			// add new files
			[self addFilesAndFolderToDatabase:anonymizedFiles.allValues];
			
			[[NSUserDefaults standardUserDefaults] setBool: COPYDATABASE forKey: @"COPYDATABASE"];
			[[NSUserDefaults standardUserDefaults] setInteger: COPYDATABASEMODE forKey: @"COPYDATABASEMODE"];
		}
		break;
	}
}

#endif

- (void) unmountPath:(NSString*) path
{
	[_sourcesTableView display];
	
	int attempts = 0;
	BOOL success = NO;
	while( success == NO)
	{
		success = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:  path];
		if( success == NO)
		{
			attempts++;
			if( attempts < 5)
			{
				[NSThread sleepForTimeInterval: 1.0];
			}
			else success = YES;
		}
	}
	
	[path release];
	
	[_sourcesTableView display];
	[_sourcesTableView setNeedsDisplay];
	
	if( attempts == 5)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Failed", nil), NSLocalizedString(@"Unable to unmount this disk. This disk is probably in used by another application.", nil), NSLocalizedString(@"OK",nil),nil, nil);
	}
}

- (void)AlternateButtonPressed: (NSNotification*)n
{
	int i = [_sourcesTableView selectedRow];
	if( i > 0)
	{
		NSString *path = [[[[bonjourBrowser services] objectAtIndex: i-1] valueForKey:@"Path"] retain];
	
		[self resetToLocalDatabase];
		
		[self performSelector:@selector(unmountPath:) withObject:path afterDelay:0.2];
	}
}

/*- (void)loadDICOMFromiPod
{
	if( mountedVolumes == nil)
		mountedVolumes = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] copy];
	
	NSString *defaultPath = documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]);
	
	for ( NSString *path in mountedVolumes)
	{
		NSString *iPodControlPath = [path stringByAppendingPathComponent:@"iPod_Control"];
		BOOL isItAnIpod = [[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath];
		BOOL isThereAnOsiriXDataAtTheRoot = [[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:@"OsiriX Data"]];
		
		if( isItAnIpod || isThereAnOsiriXDataAtTheRoot)
		{
			if( [path isEqualToString: defaultPath] == NO && [[path stringByAppendingPathComponent:@"OsiriX Data"] isEqualToString: defaultPath] == NO)
			{
				NSString *volumeName = [path lastPathComponent];
				
				//NSLog(@"Got a volume named %@", volumeName);
							
				// Find the OsiriX Data folder at root
				if (![[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:@"OsiriX Data"]]) [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:@"OsiriX Data"] attributes:nil];
				
				// Is this iPod already in the list?
				BOOL found = NO;
				for( NSDictionary *service in [bonjourBrowser services])
				{
					
					if( [[service valueForKey:@"type"] isEqualToString:@"localPath"])
					{
						if( [[service valueForKey:@"Path"] isEqualToString: path]) found = YES;
					}
				}
				
				if( found == NO)
				{
					int z = self.currentBonjourService;
					NSDictionary	*selectedDict = nil;
					if( z >= 0 && z < [bonjourBrowser.services count]) selectedDict = [[bonjourBrowser.services objectAtIndex: z] retain];
					
					NSMutableDictionary	*dict = [NSMutableDictionary dictionary];
					
					NSString	*name = nil;
					
					if( isItAnIpod) name = volumeName;
					else name = [[[NSFileManager defaultManager] displayNameAtPath: volumeName] stringByAppendingString:@" DB"];
					
					[dict setValue:path forKey:@"Path"];
					[dict setValue:name forKey:@"Description"];
					[dict setValue:@"localPath" forKey:@"type"];
					
					[[bonjourBrowser services] addObject: dict];
					[bonjourBrowser arrangeServices];
					[self displayBonjourServices];
					
					if( selectedDict)
					{
						NSInteger index = [[bonjourBrowser services] indexOfObject: selectedDict];
						
						if( index == NSNotFound)
							[self resetToLocalDatabase];
						else
							self.currentBonjourService = index;
						
						[selectedDict release];
					}
					[self displayBonjourServices];
				}
			}
		}
	}
}*/

#ifndef OSIRIX_LIGHT
- (void)loadDICOMFromiDisk: (id)sender
{
	if (![_database isLocal]) return;
	
	int delete = 0;

	if( NSRunInformationalAlertPanel( NSLocalizedString(@"iDisk", nil), NSLocalizedString(@"Should I delete the files on the iDisk after the copy?", nil), NSLocalizedString(@"Delete the files", nil), NSLocalizedString(@"Leave them", nil), nil) == NSAlertDefaultReturn)
	{
		delete = 1;
	}
	else
	{
		delete = 0;
	}
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Receiving files from iDisk", nil)];
	[wait setCancel: YES];
	[wait showWindow:self];
	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects: @"getFilesFromiDisk", [NSString stringWithFormat:@"%d", delete], nil]];
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
	[theTask launch];
	
	[wait start];
	
	while( [theTask isRunning] && [wait run])
		[NSThread sleepForTimeInterval: 0.1];
	
	if( [wait run])
		[theTask waitUntilExit];
	else
		[theTask interrupt];
	
	[wait end];
	
	[theTask release];
	
	NSArray	*filesArray = [NSArray arrayWithContentsOfFile: @"/tmp/files2load"];
	
	if( [filesArray count])
	{
		NSString *incomingFolder = [self INCOMINGPATH];
		
		for( NSString *path in filesArray)
		{
			[[NSFileManager defaultManager] movePath: path toPath: [incomingFolder stringByAppendingPathComponent: [path lastPathComponent]] handler: nil];
		}
	}
	
	[wait close];
	[wait release];
}

//- (void) cThread
//{
//	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
//	
//	NSString *src = @"/Volumes/pacs/OsiriX Data/DATABASE.noindex/";
//	NSString *dst = @"/Users/admin/Documents/OsiriX Data/INCOMING.noindex/WD";
//	
//	
//	
//	
//	int d = [[NSUserDefaults standardUserDefaults] integerForKey: @"rebuild"];
//	NSLog( @"cThread start : %d", d);
//	
//	for( int i = d; i < 70000; i++)
//	{
//		NSAutoreleasePool *z = [[NSAutoreleasePool alloc] init];
//			
//		NSString *path = [src stringByAppendingFormat: @"%d", i * 1000];
//		
//		if( [[NSFileManager defaultManager] fileExistsAtPath: path])
//		{
//			NSLog( @"%@ - IN", path);
//			
//			[[NSFileManager defaultManager] copyItemAtPath: path toPath: [dst stringByAppendingFormat: @"%d", i] error: nil];
//			
//			NSLog( @"%@ - OUT", path);
//		}
//		
//		[z release];
//	}
//	[p release];
//}

- (IBAction)sendiDisk: (id)sender
{
//	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)// TODO: whats this?
//	{
//		[self reduceCoreDataFootPrint];
//		
//		[managedObjectContext release];
//		managedObjectContext = nil;
//		
//		[self managedObjectContext];
//		
//		[self outlineViewRefresh];
//		[self refreshMatrix: self];
//		
//		return;
//	}
//
//	
//	[NSThread detachNewThreadSelector: @selector( cThread) toTarget: self withObject:nil];
//	
//	return;
//	
//	
//	
	int success;
	
	// Zip the files, and copy them!
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages: NO];
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: NO];
	
	[filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];
	
	if( filesToExport)
	{
		[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/zipFilesForIdisk" error: nil];
		[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/zipFilesForIdisk" attributes: nil];
		
		BOOL encrypt = [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptForExport"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"encryptForExport"];
		self.passwordForExportEncryption = @"";
		
		NSArray *r = [self exportDICOMFileInt: @"/tmp/zipFilesForIdisk/" files: filesToExport objects: dicomFiles2Export];
		
		[[NSUserDefaults standardUserDefaults] setBool: encrypt forKey: @"encryptForExport"];
		
		if( [r count] > 0)
		{
			NSString *path = nil;
			NSString *root = @"/tmp/zipFilesForIdisk";
			NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: root error: nil];
			for( int x = 0; x < [files count]; x++)
			{
				if( [[[files objectAtIndex: x] pathExtension] isEqualToString: @"zip"])
				{
					path = [root stringByAppendingPathComponent: [files objectAtIndex: x]];
					
					[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/files2send" handler: nil];
					[path writeToFile: @"/tmp/files2send" atomically: YES];
					
					NSTask *theTask = [[NSTask alloc] init];
					
					long long fileSize = [[[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink: YES] objectForKey:NSFileSize] longLongValue];
					
					fileSize /= 1024;
					fileSize /= 1024;
					
					WaitRendering *wait = [[WaitRendering alloc] init: [NSString stringWithFormat: NSLocalizedString(@"Sending zip file (%d MB) to iDisk", nil), fileSize]];
					[wait showWindow:self];
					[wait setCancel: YES];
					
					[theTask setArguments: [NSArray arrayWithObjects: @"sendFilesToiDisk", @"/tmp/files2send", nil]];
					[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
					[theTask launch];
					
					[wait start];
					
					while( [theTask isRunning] && [wait run])
						[NSThread sleepForTimeInterval: 0.1];
					
					if( [wait run])
						[theTask waitUntilExit];
					else
						[theTask interrupt];
					
					[wait end];
					
					[theTask release];
					
					[wait close];
					[wait release];
				}
			}
			
			[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/zipFilesForIdisk" handler: nil];
		}
	}
}

#endif

- (void) selectServer: (NSArray*)objects
{
	if( [objects count] > 0) [SendController sendFiles: objects];
	else NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No files are selected...",nil),NSLocalizedString( @"OK",nil), nil, nil);
}

- (void)export2PACS: (id)sender
{
	[self.window makeKeyAndOrderFront:sender];
	
	NSMutableArray	*objects = [NSMutableArray array];
	NSMutableArray  *files;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		files = [self filesForDatabaseMatrixSelection:objects onlyImages: NO];
	else
		files = [self filesForDatabaseOutlineSelection:objects onlyImages: NO];
	
	[files removeDuplicatedStringsInSyncWithThisArray: objects];
	
	[self selectServer: objects];
}

#ifndef OSIRIX_LIGHT
- (IBAction)querySelectedStudy: (id)sender
{
//	if( DICOMDIRCDMODE)
//	{
//		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}
	
	[self.window makeKeyAndOrderFront:sender];
	
    if( [QueryController currentQueryController] == nil) [[QueryController alloc] initAutoQuery : NO];
	else [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
	
    [[QueryController currentQueryController] showWindow:self];
	
	// *****
	
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];			
	NSManagedObject		*studySelected;
	
	if (item)
	{	
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		[[QueryController currentQueryController] queryPatientID: [studySelected valueForKey:@"patientID"]];
	}
}

- (void)queryDICOM: (id) sender
{
//	if( DICOMDIRCDMODE)
//	{
//		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}

	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)	// Query selected patient
		[self querySelectedStudy: self];
	else
	{
//		[self.window makeKeyAndOrderFront:sender];
		
		if( [sender tag] == 0 && [QueryController currentQueryController] == nil) [[QueryController alloc] initAutoQuery: NO];
		else if( [sender tag] == 1 && [QueryController currentAutoQueryController] == nil) [[QueryController alloc] initAutoQuery: YES];
		else [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		
		if( [sender tag] == 0)
			[[QueryController currentQueryController] showWindow:self];
			
		if( [sender tag] == 1)
			[[QueryController currentAutoQueryController] showWindow:self];
	}
}
#endif



/*

-(void)volumeMount: (NSNotification *)notification
{
	if( [[AppController sharedAppController] isSessionInactive] || waitForRunningProcess)
		return;
	
	NSLog(@"volume mounted");
	
	[self loadDICOMFromiPod];
	
	if (![_database isLocal]) return;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"MOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	
	NSLog( @"%@", sNewDrive);
	
	if( [BrowserController isItCD: sNewDrive] == YES)
	{
		[self ReadDicomCDRom: self];
	}
	
	[mountedVolumes release];
	mountedVolumes = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] copy];
	
	[self displayBonjourServices];
}

- (void)removeAllMounted
{
	if (![_database isLocal]) return;
	
	[self removeMountedImages: nil];
}

- (void)willVolumeUnmount: (NSNotification *)notification
{
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	
	[DCMPix purgeCachedDictionaries]; // <- This is very important to 'unlink' all opened files, otherwise MacOS will display the famous 'The disk is in use and could not be ejected'
	
	// Is it an iPod?
	if ([[NSFileManager defaultManager] fileExistsAtPath: [sNewDrive stringByAppendingPathComponent:@"iPod_Control"]])
	{
		// Is it currently selected? -> switch back to default DB path
		int row = [_sourcesTableView selectedRow];
		if( row > 0)
		{
			if( [[[[bonjourBrowser services] objectAtIndex: row-1] valueForKey:@"Path"] isEqualToString: sNewDrive])
				[self resetToLocalDatabase];
		}
		
		// Remove it from the Source list
		
		int z = self.currentBonjourService;
		NSDictionary	*selectedDict = nil;
		if( z >= 0) selectedDict = [[[bonjourBrowser services] objectAtIndex: z] retain];
		
		for( int x = 0; x < [[bonjourBrowser services] count]; x++)
		{
			NSDictionary	*c = [[bonjourBrowser services] objectAtIndex: x];
			
			if( [[c valueForKey:@"type"] isEqualToString:@"localPath"])
			{
				if( [[c valueForKey:@"Path"] isEqualToString: sNewDrive])
				{
					[[bonjourBrowser services] removeObjectAtIndex: x];
					x--;
				}
			}
		}
		
		if( selectedDict)
		{
			NSInteger index = [[bonjourBrowser services] indexOfObject: selectedDict];
			
			if( index == NSNotFound)
				[self resetToLocalDatabase];
			else
				[self setCurrentBonjourService: index];
			
			[selectedDict release];
		}
		
		[mountedVolumes release];
		mountedVolumes = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] copy];
	
		[self displayBonjourServices];
	}
	
	checkForMountedFiles = YES;
	
//	if( [BrowserController isItCD: sNewDrive] == YES)
//		checkForMountedFiles = YES;
//	else
//		checkForMountedFiles = NO;
}

- (void) removeMountedImages: (NSString*) sNewDrive
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"someImagesAreMounted"] == NO)
		return;
	
	// FIND ALL images that ARE NOT local, and REMOVE non-available images
	NSManagedObjectContext *context = self.managedObjectContext;
	NSManagedObjectModel *model = self.managedObjectModel;
	BOOL needsUpdate = NO;
	
	NSRange range;
	range.location = 0;
	range.length = [sNewDrive length];
	
	if( [context tryLock])
	{
		[context retain];
		
		DatabaseIsEdited = YES;
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		NSError	*error = nil;
		NSArray *seriesArray = [[context executeFetchRequest:dbRequest error:&error] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
		
		if( [seriesArray count] > 0)
		{
			[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"someImagesAreMounted"];
			
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			@try
			{
				// Find unavailable files
				for( int i = 0; i < [seriesArray count]; i++)
				{
					NSManagedObject	*image = [[[seriesArray objectAtIndex:i] valueForKey:@"images"] anyObject];
					if( sNewDrive == nil || [[image  valueForKey:@"completePath"] compare: sNewDrive options: NSCaseInsensitiveSearch range: range] == 0)
					{
						NSManagedObject	*study = [[seriesArray objectAtIndex:i] valueForKey:@"study"];
						
						needsUpdate = YES;
						
						// Is a viewer containing this study opened? -> close it
						for( ViewerController *vc in viewersList)
						{
							if( study == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
							{
								[[vc window] close];
							}
						}
						
						BOOL completeStudyIsMounted = YES;
						
						for( NSManagedObject *s in [[study valueForKey:@"series"] allObjects])
						{
							if( [[s valueForKey:@"mountedVolume"] boolValue] == NO)
							{
								completeStudyIsMounted = NO;
							}
						}
						
						if( completeStudyIsMounted)
							[context deleteObject: study];
						else
							[context deleteObject: [seriesArray objectAtIndex:i]];
					}
				}
			}
			@catch( NSException *ne)
			{
				NSLog( @"Unmount exception");
				NSLog( @"%@", [ne description]);
				[AppController printStackTrace: ne];
			}
			
			if( needsUpdate)
				[_database save:NULL];
			
			[self outlineViewRefresh];
			[self refreshMatrix: self];
		}
		
		[context unlock];
		[context release];
		
		DatabaseIsEdited = NO;
	}
}

- (void)volumeUnmount: (NSNotification *)notification
{
	BOOL		needsUpdate = NO;
	
	if (![_database isLocal]) return;
	if( checkForMountedFiles == NO) return;
	
	NSLog(@"volume unmounted");
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"UNMOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];	//uppercaseString];
	NSLog( @"%@", sNewDrive);
	
	[self removeMountedImages: sNewDrive];
	
	[mountedVolumes release];
	mountedVolumes = [[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths] copy];
	
	[self displayBonjourServices];
}

*/





- (void)storeSCPComplete: (id)sender
{
	//release storescp when done
	[sender release];
}

#ifndef OSIRIX_LIGHT
- (IBAction)importRawData:(id)sender
{
	[[rdPatientForm cellWithTag:0] setStringValue: @"Raw Data"]; //Patient Name
	[[rdPatientForm cellWithTag:1] setStringValue: @"RD0001"];	//Patient ID
	[[rdPatientForm cellWithTag:2] setStringValue: @"Raw Data Secondary Capture"]; //Study Descripition
	
	[[rdPixelForm cellWithTag:0] setObjectValue:[NSNumber numberWithInt:512]];		//rows
	[[rdPixelForm cellWithTag:1] setObjectValue:[NSNumber numberWithInt:512]];		//columns
	[[rdPixelForm cellWithTag:2] setObjectValue:[NSNumber numberWithInt:1]];		//slices
	
	[[rdVoxelForm cellWithTag:0] setObjectValue:[NSNumber numberWithInt:1]];		//voxel width
	[[rdVoxelForm cellWithTag:1] setObjectValue:[NSNumber numberWithInt:1]];		//voxel height
	[[rdVoxelForm cellWithTag:2] setObjectValue:[NSNumber numberWithInt:1]];		//voxel depth
	
	[[rdOffsetForm cellWithTag:0] setObjectValue:[NSNumber numberWithInt:0]];		//offset
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAccessoryView:rdAccessory];
	[openPanel setPrompt:NSLocalizedString(@"Import", nil)];
	[openPanel setTitle:NSLocalizedString(@"Import Raw Data", nil)];
	
	[openPanel setMessage:NSLocalizedString(@"Choose file containing raw data:", nil)];
	
	if ([openPanel runModalForTypes:nil] == NSOKButton)
	{
		NSData *data = [NSData dataWithContentsOfFile:[openPanel filename]];
		if (data)
		{
			NSString *patientName = [[rdPatientForm cellWithTag:0] stringValue];
			NSString *patientID = [[rdPatientForm cellWithTag:1] stringValue];
			NSString *studyDescription = [[rdPatientForm cellWithTag:2] stringValue];
			
			NSNumber *rows = [[rdPixelForm cellWithTag:0] objectValue];
			NSNumber *columns = [[rdPixelForm cellWithTag:1] objectValue];
			NSNumber *slices = [[rdPixelForm cellWithTag:2] objectValue];
			
			NSNumber *width = [[rdVoxelForm cellWithTag:0] objectValue];
			NSNumber *height = [[rdVoxelForm cellWithTag:1] objectValue];
			NSNumber *depth = [[rdVoxelForm cellWithTag:2] objectValue];
			
			NSNumber *offset = [[rdOffsetForm cellWithTag:0] objectValue];
			
			int pixelType = [(NSCell *)[rdPixelTypeMatrix selectedCell] tag];
			
			NSUInteger spp;
			NSUInteger highBit = 7;
			NSUInteger bitsAllocated = 8;
			NSUInteger numberBytes;
			BOOL isSigned = YES;
			BOOL isLittleEndian = YES;
			NSString *photometricInterpretation = @"MONOCHROME2";
			switch (pixelType)
			{
				case 0:  spp = 3;
					numberBytes = 1;
					photometricInterpretation = @"RGB";
					break;
				case 1: spp = 1;
					numberBytes = 1;
					break;
				case 2:	spp = 1;
					numberBytes = 2;
					highBit = 15;
					bitsAllocated = 16;
					isSigned = NO;
					break;
				case 3:	spp = 1;
					numberBytes = 2;
					highBit = 15;
					bitsAllocated = 16;
					break;
				case 4:	spp = 1;
					numberBytes = 2;
					highBit = 15;
					bitsAllocated = 16;
					isSigned = NO;
					isLittleEndian = NO;
					break;
				case 5:	spp = 1;
					numberBytes = 2;
					highBit = 15;
					bitsAllocated = 16;
					isSigned = YES;
					isLittleEndian = NO;
					break;
				default:	spp = 1;
					numberBytes = 2;
			}
			
			NSUInteger subDataLength = spp  * numberBytes * [rows unsignedIntegerValue] * [columns unsignedIntegerValue];	
			
			if ([data length] >= subDataLength * [slices unsignedIntegerValue]  + [offset unsignedIntegerValue])
			{
				NSUInteger s = [slices unsignedIntegerValue];
				
				//tmpObject for StudyUID andd SeriesUID	
						
				DCMObject *tmpObject = [DCMObject secondaryCaptureObjectWithBitDepth:numberBytes * 8  samplesPerPixel:spp numberOfFrames:1];
				NSString *studyUID = [tmpObject attributeValueWithName:@"StudyInstanceUID"];
				NSString *seriesUID = [tmpObject attributeValueWithName:@"SeriesInstanceUID"];
				int studyID = [[NSUserDefaults standardUserDefaults] integerForKey:@"SCStudyID"];
				DCMCalendarDate *studyDate = [DCMCalendarDate date];
				DCMCalendarDate *seriesDate = [DCMCalendarDate date];
				[[NSUserDefaults standardUserDefaults] setInteger:(++studyID) forKey:@"SCStudyID"];
				for(NSUInteger i = 0; i < s; i++)
				{
					DCMObject *dcmObject = [DCMObject secondaryCaptureObjectWithBitDepth:numberBytes * 8  samplesPerPixel:spp numberOfFrames:1];
					DCMCalendarDate *aquisitionDate = [DCMCalendarDate date];
					//add attributes
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyUID] forName:@"StudyInstanceUID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:seriesUID] forName:@"SeriesInstanceUID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:patientName] forName:@"PatientsName"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:patientID] forName:@"PatientID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyDescription] forName:@"StudyDescription"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", i]] forName:@"InstanceNumber"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", studyID]] forName:@"StudyID"];
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyDate] forName:@"StudyDate"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyDate] forName:@"StudyTime"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:seriesDate] forName:@"SeriesDate"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:seriesDate] forName:@"SeriesTime"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:aquisitionDate] forName:@"AcquisitionDate"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:aquisitionDate] forName:@"AcquisitionTime"];
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"101"] forName:@"SeriesNumber"];
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:rows] forName:@"Rows"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:columns] forName:@"Columns"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:spp]] forName:@"SamplesperPixel"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%f", [width floatValue]], [NSString stringWithFormat:@"%f",  [height floatValue]], nil] forName:@"PixelSpacing"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%f", [depth floatValue]]] forName:@"SliceThickness"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:photometricInterpretation] forName:@"PhotometricInterpretation"];
					
					float slicePosition = i * [depth floatValue]; 
					NSMutableArray *positionArray = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%f", 0.0], [NSString stringWithFormat:@"%f", 0.0], [NSString stringWithFormat:@"%f", slicePosition], nil];
					NSMutableArray *orientationArray = [NSMutableArray arrayWithObjects:[NSString stringWithFormat:@"%f", 1.0], [NSString stringWithFormat:@"%f", 0.0], [NSString stringWithFormat:@"%f", 0.0], [NSString stringWithFormat:@"%f", 0.0], [NSString stringWithFormat:@"%f", 1.0], [NSString stringWithFormat:@"%f", 0.0], nil];
					
					[dcmObject setAttributeValues:positionArray forName:@"ImagePositionPatient"];
					[dcmObject setAttributeValues:orientationArray forName:@"ImageOrientationPatient"];
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithBool:isSigned]] forName:@"PixelRepresentation"];
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:highBit]] forName:@"HighBit"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsAllocated"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsStored"];
					
					//add Pixel data
					NSString *vr = @"OW";
					if (numberBytes < 2)
						vr = @"OB";
					
					NSRange range = NSMakeRange([offset unsignedIntegerValue] + subDataLength * i, subDataLength);
					
					NSMutableData *subdata = [NSMutableData dataWithData:[data subdataWithRange:range]];
					
					DCMTransferSyntax *ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
					if (isLittleEndian == NO)
					{
						if( isSigned == NO)
						{
							unsigned short *ptr = (unsigned short*) [subdata mutableBytes];
							NSUInteger l = subDataLength/2;
							while( l-- > 0)
								ptr[ l] = EndianU16_BtoL( ptr[ l]);
						}
						else
						{
							short *ptr = ( short*) [subdata mutableBytes];
							NSUInteger l = subDataLength/2;
							while( l-- > 0)
								ptr[ l] = EndianS16_BtoL( ptr[ l]);
						}
					}
					
					DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"PixelData"];
					DCMPixelDataAttribute *attr = [[[DCMPixelDataAttribute alloc] initWithAttributeTag:tag 
																									vr:vr 
																								length:numberBytes
																								  data:nil 
																				  specificCharacterSet:nil
																						transferSyntax:ts 
																							 dcmObject:dcmObject
																							decodeData:NO] autorelease];
					
					[attr addFrame:subdata];
					[dcmObject setAttribute:attr];
					
					NSString *tempFilename = [[self INCOMINGPATH] stringByAppendingPathComponent: [NSString stringWithFormat:@"%d.dcm", i]];
					[dcmObject writeToFile:tempFilename withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
				} 
			}
			else
				NSLog(@"Not enough data");
		}
	}
}

- (IBAction) viewXML:(id) sender
{
    XMLController * xmlController = [[XMLController alloc] initWithImage: [self firstObjectForDatabaseMatrixSelection] windowName:[NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@", nil), [[self firstObjectForDatabaseMatrixSelection] valueForKey:@"completePath"]] viewer: nil];
    
    [xmlController showWindow:self];
}
#endif

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark RTSTRUCT

#ifndef OSIRIX_LIGHT
- (void)createROIsFromRTSTRUCT: (id)sender
{
	NSMutableArray *filesArray = [NSMutableArray array];
	NSMutableArray *filePaths = [self filesForDatabaseMatrixSelection: filesArray];
	
	for ( int i = 0; i < [filesArray count]; i++)
	{
		NSString *modality = [[filesArray objectAtIndex: i] valueForKey: @"modality"];
		if ( [modality isEqualToString: @"RTSTRUCT"])
		{
			DCMObject *dcmObj = [DCMObject objectWithContentsOfFile: [filePaths objectAtIndex: i ] decodingPixelData: NO];
			DCMPix *pix = [previewPix objectAtIndex: 0];  // Should only be one DCMPix associated w/ an RTSTRUCT
			
			[pix createROIsFromRTSTRUCT: dcmObj];
		}
	}
}
#endif

- (void)rtstructNotification: (NSNotification *)note
{
	BOOL visible = [[[note userInfo] objectForKey: @"RTSTRUCTProgressBar"] boolValue];
	if ( visible) [self setRtstructProgressPercent: [[[note userInfo] objectForKey: @"RTSTRUCTProgressPercent"] floatValue]];
	[self setRtstructProgressBar: visible];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark Report functions

//- (IBAction)srReports: (id)sende
//{
//	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
//	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
//
//	NSManagedObject *studySelected;
//	
//	if (item)
//	{
//		if ([[[item entity] name] isEqual:@"Study"])
//			studySelected = item;
//		else
//			studySelected = [item valueForKey:@"study"];
//		
//		if (structuredReportController)
//			[structuredReportController release];
//		
//		structuredReportController = [[StructuredReportController alloc] initWithStudy:studySelected];
//	}
//}

- (void) checkReportsDICOMSRConsistency { // __deprecated
	[_database checkReportsConsistencyWithDICOMSR];
}

- (void) syncReportsIfNecessary
{
	NSEnumerator *enumerator = [reportFilesToCheck keyEnumerator];
	NSString *key;
	
	while( (key = [enumerator nextObject]))
	{
		NSMutableDictionary *d = [reportFilesToCheck objectForKey: key];
		NSDate *previousDate = [d objectForKey: @"date"];
		DicomStudy *study = [d objectForKey: @"study"];
		
		if( [study isFault] == NO)
		{
			NSString *file = [study valueForKey: @"reportURL"];
			BOOL isDirectory;
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: file isDirectory: &isDirectory])
			{
				NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath: file error: nil];
				
				if( [previousDate timeIntervalSinceDate: [fattrs objectForKey: NSFileModificationDate]] < 0)
				{
					NSLog( @"Report -> File Modified -> Sync %@ : \r %@ versus %@", key, [previousDate description], [[fattrs objectForKey:NSFileModificationDate] description]);
					
					[d setObject: [fattrs objectForKey: NSFileModificationDate] forKey: @"date"];
					
					[study archiveReportAsDICOMSR];
					
					NSLog( @"Report -> New Content Date: %@", [[study reportImage] valueForKey: @"date"]);
				}
			}
		}
	}
}

- (IBAction)deleteReport: (id)sender
{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item)
	{
		NSManagedObject *studySelected;
		
//		[checkBonjourUpToDateThreadLock lock];
		
		@try 
		{			
			if ([[[item entity] name] isEqual:@"Study"])
				studySelected = item;
			else
				studySelected = [item valueForKey:@"study"];
			
			long result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete report", nil), NSLocalizedString(@"Are you sure you want to delete the selected report?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
			
			if( result == NSAlertDefaultReturn)
			{
				if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 3)
				{
					NSBundle *plugin = [[PluginManager reportPlugins] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
					
					if( plugin)
					{
						PluginFilter* filter = [[plugin principalClass] filter];
						[filter deleteReportForStudy: studySelected];
						//[filter report: studySelected action: @"deleteReport"];
					}
					else
					{
						NSRunAlertPanel( NSLocalizedString(@"Report Error", nil), NSLocalizedString(@"Report Plugin not available.", nil), nil, nil, nil);
						return;
					}
				}
				else if( [studySelected valueForKey:@"reportURL"] != nil)
				{
					if( [[studySelected valueForKey:@"reportURL"] lastPathComponent])
						[reportFilesToCheck removeObjectForKey: [[studySelected valueForKey:@"reportURL"] lastPathComponent]];
					
					
					if( [studySelected valueForKey:@"reportURL"] && [[NSFileManager defaultManager] fileExistsAtPath: [studySelected valueForKey:@"reportURL"]])
						[[NSFileManager defaultManager] removeFileAtPath: [studySelected valueForKey:@"reportURL"] handler: nil];
					
					if (![_database isLocal])
						[(RemoteDicomDatabase*)_database object:studySelected setValue:nil forKey:@"reportURL"];
					
					[studySelected setValue: nil forKey:@"reportURL"];
					
					[databaseOutline reloadData];
				}
				[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDeletedReportNotification object:nil userInfo:nil];
			}
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			[AppController printStackTrace: e];
		}
		
//		[checkBonjourUpToDateThreadLock unlock];
		[self performSelector: @selector( updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
	}
}

#ifndef OSIRIX_LIGHT
- (IBAction) generateReport: (id)sender
{
	NSIndexSet *index = [databaseOutline selectedRowIndexes];
	NSManagedObject *item = [databaseOutline itemAtRow:[index firstIndex]];
	int reportsMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue];
	
	if( item)
	{
		if( reportsMode == 0 && [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"] == nil) // Would absolutePathForAppBundleWithIdentifier be better here? (DDP)
		{
			NSRunAlertPanel( NSLocalizedString(@"Report Error", nil), NSLocalizedString(@"Microsoft Word is required to open/generate '.doc' reports. You can change it to TextEdit in the Preferences.", nil), nil, nil, nil);
			return;
		}
		
		DicomStudy *studySelected = nil;
		
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = (DicomStudy*) item;
		else
			studySelected = [item valueForKey:@"study"];
		
		if( [[item valueForKey: @"reportURL"] hasPrefix: @"http://"] || [[item valueForKey: @"reportURL"] hasPrefix: @"https://"])
		{
			[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: [item valueForKey: @"reportURL"]]];
		}
		else
		{
			// *********************************************
			//	PLUGINS
			// *********************************************
			
			if( reportsMode == 3)
			{
				NSBundle *plugin = [[PluginManager reportPlugins] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
				
				if( plugin)
				{
//					[checkBonjourUpToDateThreadLock lock];
					
					@try 
					{
						NSLog(@"generate report with plugin");
						PluginFilter* filter = [[plugin principalClass] filter];
						[filter createReportForStudy: studySelected];
						NSLog(@"end generate report with plugin");
						//[filter report: studySelected action: @"openReport"];
					}
					@catch (NSException * e) 
					{
						NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
						[AppController printStackTrace: e];
					}
					
//					[checkBonjourUpToDateThreadLock unlock];
				}
				else
				{
					NSRunAlertPanel( NSLocalizedString(@"Report Error", nil), NSLocalizedString(@"Report Plugin not available.", nil), nil, nil, nil);
					return;
				}
			}
			else
			// *********************************************
			// REPORTS GENERATED AND HANDLED BY OSIRIX
			// *********************************************
			{
//				[checkBonjourUpToDateThreadLock lock];
				
				@try
				{
					NSString *localReportFile = [studySelected valueForKey: @"reportURL"];
					
					if( ![_database isLocal] && localReportFile)
					{
						DicomImage *reportSR = [studySelected reportImage];
						
						if( reportSR)
						{
							// Not modified on the 'bonjour client side'?
							if( [[reportSR valueForKey:@"inDatabaseFolder"] boolValue])
							{
								// The report was maybe changed on the server -> delete the report file
								if( localReportFile)
									[[NSFileManager defaultManager] removeItemAtPath: localReportFile error: nil];
								
								// The report was maybe changed on the server -> delete the DICOM SR file
								if( [reportSR valueForKey: @"completePath"])
									[[NSFileManager defaultManager] removeItemAtPath: [reportSR valueForKey: @"completePath"] error: nil];
							}
							
							NSString *reportPath = [DicomDatabase extractReportSR: [reportSR completePathResolved] contentDate: [reportSR valueForKey: @"date"]];
							
							if( reportPath)
							{
								if( [reportPath length] > 8 && ([reportPath hasPrefix: @"http://"] || [reportPath hasPrefix: @"https://"]))
								{
									NSLog( @"**** generateReport: We should not be here....");
								}
								else // It's a file!
								{
									if( localReportFile)
									{
										[[NSFileManager defaultManager] removeItemAtPath: localReportFile error: nil];
										[[NSFileManager defaultManager] moveItemAtPath: reportPath toPath: localReportFile error: nil];
									}
								}
							}
						}
					}
					
					// Is there a Report URL ? If yes, open it; If no, create a new one
					if( localReportFile)
					{
						if( [[NSFileManager defaultManager] fileExistsAtPath: localReportFile])
						{
							if (reportsMode != 3)
							{
								[[NSWorkspace sharedWorkspace] openFile: localReportFile withApplication: nil andDeactivate:YES];
								[NSThread sleepForTimeInterval: 1];
							}
						}
						else
						{
							NSLog( @"***** reportURL contains a path, but file doesnt exist.");
							
							if( NSRunInformationalAlertPanel( NSLocalizedString(@"Report", nil),
											 NSLocalizedString(@"Report file is not found... Should I create a new one?", nil),
											 NSLocalizedString(@"OK",nil),
											 NSLocalizedString(@"Cancel",nil),
											 nil) == NSAlertDefaultReturn)
												localReportFile = nil;
						}
					}
					
					if( localReportFile == nil)
					{
						NSLog( @"New report for : %@", [studySelected valueForKey: @"name"]);
						
						if (reportsMode != 3)
						{
							Reports	*report = [[Reports alloc] init];
							if([[sender class] isEqualTo:[reportTemplatesListPopUpButton class]])[report setTemplateName:[[sender selectedItem] title]];
							
							if (![_database isLocal])
								[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/TEMP.noindex/", [self documentsDirectory]] type:reportsMode];
							else
								[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/REPORTS/", [self documentsDirectory]] type:reportsMode];
							
							localReportFile = [studySelected valueForKey: @"reportURL"];
							
							[report release];
						}
					}
					
					if( [[NSFileManager defaultManager] fileExistsAtPath: localReportFile])
					{
						NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:localReportFile traverseLink:YES];
						NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: studySelected, @"study", [fattrs objectForKey:NSFileModificationDate], @"date", nil];
						
						[reportFilesToCheck setObject: d forKey: [localReportFile lastPathComponent]];
					}
				}
				@catch (NSException * e)
				{
					NSLog( @"Generate Report: %@", [e description]);
					[AppController printStackTrace: e];
				}
				
//				[checkBonjourUpToDateThreadLock unlock];
			}
		}
	}
	
	[self performSelector: @selector( updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];	
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixReportModeChangedNotification object: nil userInfo: nil];
}
#endif

- (NSImage*) reportIcon
{
	NSString *iconName = @"Report.icns";
	switch( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue])
	{
		case 0: 
		 // M$ Word
			iconName = @"ReportWord.icns";
			reportToolbarItemType = 0;
		break;
		case 1: 
		 // TextEdit (RTF)
			
			iconName = @"ReportRTF.icns";
			reportToolbarItemType = 1;
		break;
		case 2:
		 // Pages.app
			
			iconName = @"ReportPages.icns";
			reportToolbarItemType = 2;
		break;
		case 5:
		//	OpenOffice.app
		//	iconName = @"ReportOO.icns";
			reportToolbarItemType = 3;
		break;
		default:
			reportToolbarItemType = 3;
		break;
	}
	return [NSImage imageNamed:iconName];
}

- (void)updateReportToolbarIcon: (NSNotification *)note
{
	int previousReportType = reportToolbarItemType;
	
	[self setToolbarReportIconForItem: nil];
	
	if( reportToolbarItemType != previousReportType)
	{
		NSToolbarItem *item;
		NSArray *toolbarItems = [toolbar items];
		
		[AppController checkForPreferencesUpdate: NO];
		
		for( int i=0; i<[toolbarItems count]; i++)
		{
			item = [toolbarItems objectAtIndex:i];
			if ([[item itemIdentifier] isEqualToString:ReportToolbarItemIdentifier])
			{
				[toolbar removeItemAtIndex:i];
				[toolbar insertItemWithItemIdentifier:ReportToolbarItemIdentifier atIndex:i];
			}
		}
		
		[AppController checkForPreferencesUpdate: YES];
	}
}


- (void)setToolbarReportIconForItem: (NSToolbarItem *)item
{
	@try
	{
		#ifndef OSIRIX_LIGHT
		NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];
		
		NSIndexSet *index = [databaseOutline selectedRowIndexes];
		NSManagedObject	*selectedItem = [databaseOutline itemAtRow:[index firstIndex]];
		NSManagedObject *studySelected;
		if ([[[selectedItem entity] name] isEqual:@"Study"])
			studySelected = selectedItem;
		else
			studySelected = [selectedItem valueForKey:@"study"];
		
		if([pagesTemplatesArray count] > 1 && [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 2 && [studySelected valueForKey:@"reportURL"] == nil)
		{
			[item setView: reportTemplatesView];
			[item setMinSize: NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
			[item setMaxSize: NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
			
			reportToolbarItemType = -1;
		}
		else
		{
			NSImage *icon = nil;
			
			if( [studySelected valueForKey: @"reportURL"])
			{
				if( [[studySelected valueForKey: @"reportURL"] hasPrefix: @"http://"] || [[studySelected valueForKey: @"reportURL"] hasPrefix: @"https://"])
				{
					icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"download"]; // Safari document
				
					if( icon)
						reportToolbarItemType = [NSDate timeIntervalSinceReferenceDate];	// To force the update
				}
				else if( [[NSFileManager defaultManager] fileExistsAtPath: [studySelected valueForKey: @"reportURL"]])
				{
					icon = [[NSWorkspace sharedWorkspace] iconForFile: [studySelected valueForKey: @"reportURL"]];
					
					if( icon)
						reportToolbarItemType = [NSDate timeIntervalSinceReferenceDate];	// To force the update
				}
			}
			
			if( icon == nil)
				icon = [self reportIcon];	// Keep this line! Because item can be nil! see updateReportToolbarIcon function
			
			[item setImage: icon];
		}
		#else
		[item setImage: [NSImage imageNamed: @"Report.icns"]];
		#endif
	}
	@catch (NSException * e)
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
}


- (void)reportToolbarItemWillPopUp: (NSNotification *)notif
{
	#ifndef OSIRIX_LIGHT
	if([[notif object] isEqualTo:reportTemplatesListPopUpButton])
	{
		NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];
		[reportTemplatesListPopUpButton removeAllItems];
		[reportTemplatesListPopUpButton addItemWithTitle:@""];
		[reportTemplatesListPopUpButton addItemsWithTitles:pagesTemplatesArray];
		[reportTemplatesListPopUpButton setAction:@selector(generateReport:)];
	}
	#endif
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Toolbar functions

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void)windowDidResignKey:(NSNotification *)notification
{
	DatabaseIsEdited = NO;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self flagsChanged: 0L];
	
	if( albumNoOfStudiesCache.count == 0)
		[self refreshAlbums];
}

- (void) flagsChanged:(NSEvent *)event
{
	if( previousFlags == [event modifierFlags])
		return;
	
	for( NSToolbarItem *toolbarItem in [toolbar items])
	{
		if( [[toolbarItem itemIdentifier] isEqualToString: OpenKeyImagesAndROIsToolbarItemIdentifier])
		{
			if([event modifierFlags] & NSAlternateKeyMask)
			{
				[toolbarItem setImage: [NSImage imageNamed: OpenKeyImagesToolbarItemIdentifier]];
				[toolbarItem setAction: @selector(viewerDICOMKeyImages:)];
				
				[toolbarItem setLabel: NSLocalizedString(@"Keys", nil)];
				[toolbarItem setPaletteLabel: NSLocalizedString(@"Keys", nil)];
				[toolbarItem setToolTip: NSLocalizedString(@"View all Key Images", nil)];
			}
			else if([event modifierFlags] & NSShiftKeyMask)
			{
				[toolbarItem setImage: [NSImage imageNamed: OpenROIsToolbarItemIdentifier]];
				[toolbarItem setAction: @selector(viewerDICOMROIsImages:)];
				
				[toolbarItem setLabel: NSLocalizedString(@"ROIs", nil)];
				[toolbarItem setPaletteLabel: NSLocalizedString(@"ROIs", nil)];
				[toolbarItem setToolTip: NSLocalizedString(@"View all ROIs Images", nil)];
			}
			else
			{
				[toolbarItem setImage: [NSImage imageNamed: OpenKeyImagesAndROIsToolbarItemIdentifier]];
				[toolbarItem setAction: @selector(viewerKeyImagesAndROIsImages:)];
				
				[toolbarItem setLabel: NSLocalizedString(@"ROIs & Keys", nil)];
				[toolbarItem setPaletteLabel: NSLocalizedString(@"ROIs & Keys", nil)];
				[toolbarItem setToolTip: NSLocalizedString(@"View all Key Images and ROIs", nil)];
			}
		}
	}
	
	[self outlineViewSelectionDidChange: nil];
	
	previousFlags = [event modifierFlags];
}

- (void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: DatabaseToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [self.window setToolbar: toolbar];
	[self.window setShowsToolbarButton:NO];
	[[self.window toolbar] setVisible: YES];
    
	//    [self.window makeKeyAndOrderFront:nil];
	
	#ifdef EXPORTTOOLBARITEM
	dd
	NSLog(@"************** WARNING EXPORTTOOLBARITEM ACTIVATED");
	for( id s in [self toolbarAllowedItemIdentifiers: toolbar])
	{
		@try
		{
			id item = [self toolbar: toolbar itemForItemIdentifier: s willBeInsertedIntoToolbar: YES];
			
			
			NSImage *im = [item image];
			
			if( im == nil)
			{
				@try
				{
					if( [item respondsToSelector:@selector( setRecursiveEnabled:)])
						[item setRecursiveEnabled: YES];
					else if( [[item view] respondsToSelector:@selector( setRecursiveEnabled:)])
						[[item view] setRecursiveEnabled: YES];
					else if( item)
						NSLog( @"%@", item);
						
					im = [[item view] screenshotByCreatingPDF];
				}
				@catch (NSException * e)
				{
					NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
				}
			}
			
			if( im)
			{
				NSBitmapImageRep *bits = [[[NSBitmapImageRep alloc] initWithData:[im TIFFRepresentation]] autorelease];
				
				NSString *path = [NSString stringWithFormat: @"/tmp/sc/%@.png", [[[[item label] stringByReplacingOccurrencesOfString: @"&" withString:@"And"] stringByReplacingOccurrencesOfString: @" " withString:@""] stringByReplacingOccurrencesOfString: @"/" withString:@"-"]];
				[[bits representationUsingType: NSPNGFileType properties: nil] writeToFile:path  atomically: NO];
			}
		}
		@catch (NSException * e)
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
	}
	#endif
}

- (void)drawerToggle: (id)sender
{
    NSDrawerState state = [albumDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state)
        [albumDrawer close];
	else
        [albumDrawer openOnEdge:NSMinXEdge];
}

-(void)drawerFrameDidChange:(NSNotification*)n { // drawer view frame changed, and NSSegmentedView segments don't adapt to the view's new width
	CGFloat w = (segmentedAlbumButton.frame.size.width-4)/segmentedAlbumButton.segmentCount;
	for (NSInteger i = 0; i < segmentedAlbumButton.segmentCount; ++i)
		[segmentedAlbumButton setWidth:w forSegment:i];
	[segmentedAlbumButton setNeedsDisplay:YES];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	if ([itemIdent isEqualToString: ImportToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Import",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Import",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Import a DICOM file or folder",@"Import a DICOM file or folder")];
		[toolbarItem setImage: [NSImage imageNamed: ImportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectFilesAndFoldersToAdd:)];
    }
	else if ([itemIdent isEqualToString: QTSaveToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Movie Export", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Movie Export", nil)];
		[toolbarItem setImage: [NSImage imageNamed: QTSaveToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( exportQuicktime:)];
    }
	else if ([itemIdent isEqualToString: WebServerSingleNotification])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Notification", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Notification", nil)];
		[toolbarItem setImage: [NSImage imageNamed: WebServerSingleNotification]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( sendEmailNotification:)];
	}
	else if ([itemIdent isEqualToString: AddStudiesToUserItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Add Studies", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Add Studies", nil)];
		[toolbarItem setImage: [NSImage imageNamed: AddStudiesToUserItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( addStudiesToUser:)];
	}
	else if ([itemIdent isEqualToString: MailToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Email", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Email", nil)];
		[toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector( sendMail:)];
	}
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export selected study/series to a DICOM folder",@"Export selected study/series to a DICOM folder")];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
    } 
	else if ([itemIdent isEqualToString: ViewersToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Viewers",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Viewers",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Bring Viewers windows to the front", nil)];
		[toolbarItem setImage: [NSImage imageNamed: ViewersToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(tileWindows:)];
    } 
	else if ([itemIdent isEqualToString: AnonymizerToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Anonymize",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Anonymize",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Anonymize selected study/series to a DICOM folder",@"Anonymize selected study/series to a DICOM folder")];
		[toolbarItem setImage: [NSImage imageNamed: AnonymizerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(anonymizeDICOM:)];
    } 
    else if ([itemIdent isEqualToString: QueryToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Query",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Query",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Query and retrieve a DICOM study from a DICOM node\rShift + click to query selected patient.",nil)];
		[toolbarItem setImage: [NSImage imageNamed: QueryToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(queryDICOM:)];
		[toolbarItem setTag: 0];
    }
    else if ([itemIdent isEqualToString: SendToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to a DICOM node",@"Send selected study/series to a DICOM node")];
		[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(export2PACS:)];
    }
	else if ([itemIdent isEqualToString: iDiskGetToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"iDisk Get",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"iDisk Get",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load DICOM files from iDisk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iDiskGetToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(loadDICOMFromiDisk:)];
	}
	else if ([itemIdent isEqualToString: iDiskSendToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"iDisk Send",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"iDisk Send",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to your iDisk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iDiskSendToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendiDisk:)];
	}
    else if ([itemIdent isEqualToString: ViewerToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"2D Viewer",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"2D Viewer",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"View selected study/series",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ViewerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(viewerDICOM:)];
    } 
	else if ([itemIdent isEqualToString: CDRomToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"CD-Rom",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"CD-Rom",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load images from current DICOM CD-Rom",nil)];
		[toolbarItem setImage: [NSImage imageNamed: CDRomToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(ReadDicomCDRom:)];
    }
	else if ([itemIdent isEqualToString: MovieToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"4D Viewer",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"4D Viewer",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load multiple series into an animated 4D series",nil)];
		[toolbarItem setImage: [NSImage imageNamed: MovieToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(MovieViewerDICOM:)];
    } 
	else if ([itemIdent isEqualToString: TrashToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Delete",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Delete",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Delete selected images from the database",nil)];
		[toolbarItem setImage: [NSImage imageNamed: TrashToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(delItem:)];
    }
	else if ([itemIdent isEqualToString: ReportToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Report",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Report",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Create/Open a report for selected study",nil)];
		[self setToolbarReportIconForItem: toolbarItem];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(generateReport:)];
    }
	else if ([itemIdent isEqualToString: OpenKeyImagesAndROIsToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"ROIs & Keys", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"ROIs & Keys", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"View all Key Images and ROIs", nil)];
		[toolbarItem setImage: [NSImage imageNamed: OpenKeyImagesAndROIsToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(viewerKeyImagesAndROIsImages:)];
    }
	else if ([itemIdent isEqualToString: XMLToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Meta-Data", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Meta-Data", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"View meta-data of this image", nil)];
		[toolbarItem setImage: [NSImage imageNamed: XMLToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(viewXML:)];
    } 
	else if ([itemIdent isEqualToString: BurnerToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Burn",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Burn",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Burn a DICOM-compatible CD or DVD",@"Burn a DICOM-compatible CD or DVD")];
		[toolbarItem setImage: [NSImage imageNamed: BurnerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(burnDICOM:)];
    } 
	else if ([itemIdent isEqualToString: ToggleDrawerToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Albums & Sources",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Albums & Sources",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Toggle Albums & Sources drawer",nil)];
		[toolbarItem setImage: [NSImage imageNamed:  ToggleDrawerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(drawerToggle:)];
    } 
	else if ([itemIdent isEqualToString: SearchToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Search by All Fields", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Search", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Search", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: searchView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([searchView frame])-150, NSHeight([searchView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
    }
	else if ([itemIdent isEqualToString: TimeIntervalToolbarItemIdentifier])
	{
		[toolbarItem setLabel: NSLocalizedString(@"Time Interval", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Time Interval", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Time Interval", nil)];
		
		// Use a custom view, a text field, for the search item 
		[toolbarItem setView: timeIntervalView];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([timeIntervalView frame]), NSHeight([timeIntervalView frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([timeIntervalView frame]), NSHeight([timeIntervalView frame]))];
    } 
	else
	{
		// Is it a plugin menu item?
		if( [[PluginManager pluginsDict] objectForKey: itemIdent] != nil)
		{
			NSBundle *bundle = [[PluginManager pluginsDict] objectForKey: itemIdent];
			NSDictionary *info = [bundle infoDictionary];
			
			[toolbarItem setLabel: itemIdent];
			[toolbarItem setPaletteLabel: itemIdent];
			NSDictionary* toolTips = [info objectForKey: @"ToolbarToolTips"];
			if( toolTips)
				[toolbarItem setToolTip: [toolTips objectForKey: itemIdent]];
			else
				[toolbarItem setToolTip: itemIdent];
			
			//			NSLog( @"ICON:");
			//			NSLog( [info objectForKey:@"ToolbarIcon"]);
			
			NSImage	*image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"ToolbarIcon"]]] autorelease];
			if( !image) image = [[NSWorkspace sharedWorkspace] iconForFile: [bundle bundlePath]];
			[toolbarItem setImage: image];
			
			[toolbarItem setTarget: self];
			[toolbarItem setAction: @selector(executeFilterFromToolbar:)];
		}
		else
		{
			[toolbarItem release];
			toolbarItem = nil;
		}
	}
	
	return [toolbarItem autorelease];
}


- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
			ViewersToolbarItemIdentifier,
			ImportToolbarItemIdentifier,
			ExportToolbarItemIdentifier,
			CDRomToolbarItemIdentifier,
			MailToolbarItemIdentifier,
			WebServerSingleNotification,
			AddStudiesToUserItemIdentifier,
			QTSaveToolbarItemIdentifier,
			QueryToolbarItemIdentifier,
			SendToolbarItemIdentifier,
			AnonymizerToolbarItemIdentifier,
			BurnerToolbarItemIdentifier,
			XMLToolbarItemIdentifier,
			TrashToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			ViewerToolbarItemIdentifier,
			OpenKeyImagesAndROIsToolbarItemIdentifier,
			MovieToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			ToggleDrawerToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			ReportToolbarItemIdentifier,
			SearchToolbarItemIdentifier,
			TimeIntervalToolbarItemIdentifier,
			nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{	
	NSArray	*array;
	
	array = [NSArray arrayWithObjects:
			 ViewersToolbarItemIdentifier,
			 SearchToolbarItemIdentifier,
			 TimeIntervalToolbarItemIdentifier,
			 NSToolbarCustomizeToolbarItemIdentifier,
			 NSToolbarFlexibleSpaceItemIdentifier,
			 NSToolbarSpaceItemIdentifier,
			 NSToolbarSeparatorItemIdentifier,
			 ImportToolbarItemIdentifier,
			 CDRomToolbarItemIdentifier,
			 MailToolbarItemIdentifier,
			 WebServerSingleNotification,
			 AddStudiesToUserItemIdentifier,
			 QTSaveToolbarItemIdentifier,
			 QueryToolbarItemIdentifier,
			 ExportToolbarItemIdentifier,
			 AnonymizerToolbarItemIdentifier,
			 SendToolbarItemIdentifier,
			 iDiskSendToolbarItemIdentifier,
			 iDiskGetToolbarItemIdentifier,
			 ViewerToolbarItemIdentifier,
			 OpenKeyImagesAndROIsToolbarItemIdentifier,
			 MovieToolbarItemIdentifier,
			 BurnerToolbarItemIdentifier,
			 XMLToolbarItemIdentifier,
			 TrashToolbarItemIdentifier,
			 ReportToolbarItemIdentifier,
			 ToggleDrawerToolbarItemIdentifier,
			 nil];
	
	NSArray*		allPlugins = [[PluginManager pluginsDict] allKeys];
	NSMutableSet*	pluginsItems = [NSMutableSet setWithCapacity: [allPlugins count]];
	
	for( NSString *plugin in allPlugins)
	{
		if ([plugin isEqualToString: @"(-"])
			continue;
		
		NSBundle		*bundle = [[PluginManager pluginsDict] objectForKey: plugin];
		NSDictionary	*info = [bundle infoDictionary];
		
		if( [[info objectForKey: @"pluginType"] isEqualToString: @"Database"] == YES)
		{
			id allowToolbarIcon = [info objectForKey: @"allowToolbarIcon"];
			if( allowToolbarIcon)
			{
				if( [allowToolbarIcon boolValue] == YES)
				{
					NSArray* toolbarNames = [info objectForKey: @"ToolbarNames"];
					if( toolbarNames)
					{
						if( [toolbarNames containsObject: plugin])
							[pluginsItems addObject: plugin];
					}
					else
						[pluginsItems addObject: plugin];
				}
			}
		}
	}
	
	if( [pluginsItems count])
		array = [array arrayByAddingObjectsFromArray: [pluginsItems allObjects]];
	
    return array;
}

- (void)toolbarWillAddItem:(NSNotification *) notif
{
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
	
	NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
	
	if( [[addedItem itemIdentifier] isEqualToString:SearchToolbarItemIdentifier])
	{
		[toolbarSearchItem release];
		toolbarSearchItem = [addedItem retain];
	}
}  

- (void)toolbarDidRemoveItem: (NSNotification *)notif
{
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
	if( [[removedItem itemIdentifier] isEqualToString:SearchToolbarItemIdentifier])
	{
		[toolbarSearchItem release];
		toolbarSearchItem = nil;
	}
}

- (NSArray*) ROIsAndKeyImages: (id) sender sameSeries: (BOOL*) sameSeries
{
	NSMutableArray *selectedItems = [NSMutableArray array];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];
	
	NSMutableArray *roisImagesArray = [NSMutableArray array];
	
	if( [selectedItems count] > 0)
	{
		DicomStudy *study = nil;
		NSArray *roisArray = nil;
		
		for( DicomImage *image in selectedItems)
		{
			if( study != image.series.study)
			{
				study = image.series.study;
				roisArray = [[[study roiSRSeries] valueForKey: @"images"] allObjects];
			}
			
			@try
			{
				DicomImage *roiImage = [study roiForImage: image inArray: roisArray];
				
				if( roiImage && ( [roiImage valueForKey: @"scale"] == nil || [[roiImage valueForKey: @"scale"] intValue] > 0)) // @"scale" contains the number of ROI objects
					[roisImagesArray addObject: image];
				else if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
					[roisImagesArray addObject: image];
			}
			@catch (NSException * e) 
			{
				NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
			}
		}
		
		if( sameSeries)
		{
			NSManagedObject *series = [[roisImagesArray lastObject] valueForKey: @"series"];
			
			*sameSeries = YES;
			for( DicomImage *image in roisImagesArray)
			{
				if( [image valueForKey: @"series"] != series)
				{
					*sameSeries = NO;
					break;
				}
			}
		}
	}
	
	return roisImagesArray;
}

- (NSArray*) ROIsAndKeyImages: (id) sender
{
	return [self ROIsAndKeyImages: sender sameSeries: nil];
}

- (IBAction) viewerKeyImagesAndROIsImages:(id) sender
{
	BOOL sameSeries;
	NSArray *roisImagesArray = [self ROIsAndKeyImages: sender sameSeries: &sameSeries];
	
	if( [roisImagesArray count])
	{
		
		NSMutableArray *copySettings = [NSMutableArray array];
		
		if( sameSeries == NO)
		{
			for( DicomImage *im in roisImagesArray)
			{
				NSMutableDictionary *d = [NSMutableDictionary dictionary];
				
				[d setObject: im forKey:@"im"];
				
				if( [im valueForKeyPath: @"series.windowWidth"])
					[d setObject: [im valueForKeyPath: @"series.windowWidth"] forKey:@"windowWidth"];
				
				if( [im valueForKeyPath: @"series.windowLevel"])
					[d setObject: [im valueForKeyPath: @"series.windowLevel"] forKey:@"windowLevel"];
				
				if( [im valueForKeyPath: @"series.rotationAngle"])
					[d setObject: [im valueForKeyPath: @"series.rotationAngle"] forKey:@"rotationAngle"];
				
				if( [im valueForKeyPath: @"series.yFlipped"])
					[d setObject: [im valueForKeyPath: @"series.yFlipped"] forKey:@"yFlipped"];
				
				if( [im valueForKeyPath: @"series.xFlipped"])
					[d setObject: [im valueForKeyPath: @"series.xFlipped"] forKey:@"xFlipped"];
				
				if( [im valueForKeyPath: @"series.xOffset"])
					[d setObject: [im valueForKeyPath: @"series.xOffset"] forKey:@"xOffset"];
				
				if( [im valueForKeyPath: @"series.yOffset"])
					[d setObject: [im valueForKeyPath: @"series.yOffset"] forKey:@"yOffset"];
				
				if( [im valueForKeyPath: @"series.displayStyle"])
					[d setObject: [im valueForKeyPath: @"series.displayStyle"] forKey:@"displayStyle"];
				
				if( [im valueForKeyPath: @"series.scale"])
					[d setObject: [im valueForKeyPath: @"series.scale"] forKey:@"scale"];
				
				[copySettings addObject: d];
			}
		}
		dontShowOpenSubSeries = YES;
		ViewerController *v = [self openViewerFromImages: [NSArray arrayWithObject: roisImagesArray] movie: 0 viewer :nil keyImagesOnly:NO];
		dontShowOpenSubSeries = NO;
		
		if( sameSeries == NO)
		{
			[[v imageView] setCOPYSETTINGSINSERIES: NO];
			
			for( NSDictionary *d in copySettings)
			{
				NSManagedObject *im = [d objectForKey: @"im"];
				
				if( [im valueForKey: @"windowWidth"])
					[im setValue: [d valueForKey: @"windowWidth"] forKey:@"windowWidth"];
				
				if( [im valueForKey: @"windowLevel"])
					[im setValue: [d valueForKey: @"windowLevel"] forKey:@"windowLevel"];
				
				if( [im valueForKey: @"rotationAngle"])
					[im setValue: [d valueForKey: @"rotationAngle"] forKey:@"rotationAngle"];
				
				if( [im valueForKey: @"yFlipped"])
					[im setValue: [d valueForKey: @"yFlipped"] forKey:@"yFlipped"];
				
				if( [im valueForKey: @"xFlipped"])
					[im setValue: [d valueForKey: @"xFlipped"] forKey:@"xFlipped"];
				
				if( [im valueForKey: @"xOffset"])
					[im setValue: [d valueForKey: @"xOffset"] forKey:@"xOffset"];
				
				if( [im valueForKey: @"yOffset"])
					[im setValue: [d valueForKey: @"yOffset"] forKey:@"yOffset"];
				
				if( [[d valueForKey: @"displayStyle"] intValue] == 3)
					[im setValue: [NSNumber numberWithFloat: [[im valueForKeyPath: @"series.scale"] floatValue] * sqrt( [[v imageView] frame].size.height * [[v imageView] frame].size.width)] forKey:@"scale"];
				else if( [[d valueForKey: @"displayStyle"] intValue] == 2)
					[im setValue: [NSNumber numberWithFloat: [[im valueForKeyPath: @"series.scale"] floatValue] * [[v imageView] frame].size.width] forKey:@"scale"];
				else
				{
					if( [d valueForKey: @"scale"])
						[im setValue: [d valueForKey: @"scale"] forKey:@"scale"];
				}
			}
		}
			
		if(	[[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
			[NSApp sendAction: @selector(tileWindows:) to:nil from: self];
		else
			[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
		
#ifndef OSIRIX_LIGHT
		BOOL escKey = CGEventSourceKeyState( kCGEventSourceStateCombinedSessionState, 53);
		
		if( escKey) //Open the images, and export them
		{
			if( [[ViewerController getDisplayed2DViewers] count])
			{
				ViewerController *v = [[ViewerController getDisplayed2DViewers] objectAtIndex: 0];
				
				[v exportAllImages: @"Key And ROIs images"];
				
				[[v window] close];
			}
		}
#endif
	}
	else
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"ROIs Images", nil), NSLocalizedString(@"No images containing ROIs or Key Images are found in this selection.", nil), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (NSArray*) ROIImages: (id) sender sameSeries:(BOOL*) sameSeries
{
	NSMutableArray *selectedItems = [NSMutableArray array];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];
	
	NSMutableArray *roisImagesArray = [NSMutableArray array];

	if( [selectedItems count] > 0)
	{
		for( DicomImage *image in selectedItems)
		{
			NSString *str = [image.series.study roiPathForImage: image];
			
			if( str && [[NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: str]] count] > 0)
				[roisImagesArray addObject: image];
		}
		
		if( sameSeries)
		{
			NSManagedObject *series = [[roisImagesArray lastObject] valueForKey: @"series"];
			
			*sameSeries = YES;
			for( DicomImage *image in roisImagesArray)
			{
				if( [image valueForKey: @"series"] != series)
				{
					*sameSeries = NO;
					break;
				}
			}
		}
	}
	
	return roisImagesArray;
}

- (NSArray*) ROIImages: (id) sender
{
	return [self ROIImages: sender sameSeries: nil];
}

- (NSArray*) KeyImages: (id) sender
{
	NSMutableArray *selectedItems = [NSMutableArray array];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];
	
	NSMutableArray *keyImagesArray = [NSMutableArray array];
	
	for( NSManagedObject *image in selectedItems)
	{					
		if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
			[keyImagesArray addObject: image];
	}
	
	return keyImagesArray;
}

- (void) tileWindows: (id) sender
{
	if( delayedTileWindows)
	{
		delayedTileWindows = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
	}
	
	[[AppController sharedAppController] tileWindows: nil];
}

- (BOOL)validateToolbarItem: (NSToolbarItem *)toolbarItem
{
	#ifdef EXPORTTOOLBARITEM
	return YES;
	#endif
	
	if( [[databaseOutline selectedRowIndexes] count] < 1) // No Database Selection
	{
		if(	[toolbarItem action] == @selector( rebuildThumbnails:) ||
			[toolbarItem action] == @selector( searchForCurrentPatient:) || 
			[toolbarItem action] == @selector( viewerDICOM:) || 
		    [toolbarItem action] == @selector( viewerSubSeriesDICOM:) || 
			[toolbarItem action] == @selector( MovieViewerDICOM:) || 
			[toolbarItem action] == @selector( viewerDICOMMergeSelection:) || 
			[toolbarItem action] == @selector( revealInFinder:) || 
			[toolbarItem action] == @selector( export2PACS:) || 
			[toolbarItem action] == @selector( exportQuicktime:) || 
			[toolbarItem action] == @selector( exportJPEG:) || 
			[toolbarItem action] == @selector( exportTIFF:) || 
			[toolbarItem action] == @selector( exportDICOMFile:) || 
			[toolbarItem action] == @selector( sendiDisk:) || 
			[toolbarItem action] == @selector( sendMail:) || 
			[toolbarItem action] == @selector( addStudiesToUser:) || 
			[toolbarItem action] == @selector( sendEmailNotification:) || 
			[toolbarItem action] == @selector( compressSelectedFiles:) || 
			[toolbarItem action] == @selector( decompressSelectedFiles:) || 
			[toolbarItem action] == @selector( generateReport:) || 
			[toolbarItem action] == @selector( deleteReport:) || 
			[toolbarItem action] == @selector( delItem:) || 
			[toolbarItem action] == @selector( querySelectedStudy:) || 
			[toolbarItem action] == @selector( burnDICOM:) || 
			[toolbarItem action] == @selector( viewXML:) || 
			[toolbarItem action] == @selector( anonymizeDICOM:) || 
			[toolbarItem action] == @selector( applyRoutingRule:)
			)
		return NO;
	}
	
	if (![_database isLocal])
	{
		if ([[toolbarItem itemIdentifier] isEqualToString: ImportToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: iDiskSendToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: iDiskGetToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: CDRomToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: TrashToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: QueryToolbarItemIdentifier]) return NO;
	}
	
	if ([[toolbarItem itemIdentifier] isEqualToString: OpenKeyImagesAndROIsToolbarItemIdentifier])
	{
		return YES;	//ROIsAndKeyImagesButtonAvailable;
	}
	
	if ([[toolbarItem itemIdentifier] isEqualToString: ViewersToolbarItemIdentifier])
	{
		if( [ViewerController numberOf2DViewer] >= 1) return YES;
		else return NO;
	}
	
	if( [[toolbarItem itemIdentifier] isEqualToString: WebServerSingleNotification])
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpWebServer"]  == NO || [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"] == NO)
		{
			return NO;
		}
	}
	
	if( [[toolbarItem itemIdentifier] isEqualToString: AddStudiesToUserItemIdentifier])
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpWebServer"]  == NO || [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"] == NO)
		{
			return NO;
		}
	}
	
    return YES;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Bonjour

- (void)setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key { // __deprecated
	[(RemoteDicomDatabase*)_database object:obj setValue:value forKey:key];
}

-(NSString*)askPassword
{
	[password setStringValue:@""];
	
	[NSApp beginSheet:	bonjourPasswordWindow
	   modalForWindow: self.window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	int result = [NSApp runModalForWindow:bonjourPasswordWindow];
	[bonjourPasswordWindow makeFirstResponder: nil];
	
	[NSApp endSheet: bonjourPasswordWindow];
	[bonjourPasswordWindow orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		return [password stringValue];
	}
	
	return nil;
}

- (NSString*)getLocalDCMPath: (NSManagedObject*)obj : (long)no
{
	if (![_database isLocal]) return [(RemoteDicomDatabase*)_database fetchDataForImage:(DicomImage*)obj maxFiles:no];
	else return [obj valueForKey:@"completePath"];
}

- (void)displayBonjourServices
{
	[_sourcesTableView reloadData];
}

- (void) switchToDefaultDBIfNeeded
{
	NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
	
	if( [[self documentsDirectory] isEqualToString: defaultPath] == NO)
		[self resetToLocalDatabase];
}

- (void)openDatabasePath: (NSString*)path { // __deprecated
	NSThread* thread = [NSThread currentThread];
	[thread setName:NSLocalizedString(@"Opening database...", nil)];
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	
	@try {
		DicomDatabase* db = [DicomDatabase databaseAtPath:path];
		[self setDatabase:db];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
		NSRunAlertPanel(NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot read this file/folder.", nil), nil, nil, nil);
		[self resetToLocalDatabase]; // TODO: is this necessary?
	}
	
	[tmc invalidate];
	
	
//	BOOL isDirectory;
//
//	if( DICOMDIRCDMODE)
//	{
//		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}
//
//	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
//	{
//		displayEmptyDatabase = YES;
//		[self outlineViewRefresh];
//		[self refreshMatrix: self];
//		
//		if( isDirectory)
//		{
//			[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey:@"DATABASELOCATION"];
//			[[NSUserDefaults standardUserDefaults] setObject: path forKey:@"DATABASELOCATIONURL"];
//			
//			[self openDatabaseIn: [[self documentsDirectory] stringByAppendingPathComponent:@"/Database.sql"] Bonjour: NO];
//		}
//		else
//		{
//			if( [currentDatabasePath isEqualToString: path] == NO)
//			{
//				[self openDatabaseIn: path Bonjour:NO];
//			}
//		}
//		
//		displayEmptyDatabase = NO;
//	}
//	else
//	{
//		NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot read this file/folder.", nil), nil, nil, nil);
//		[self resetToLocalDatabase];
//	}
}

-(NSInteger)indexOfDatabase:(DicomDatabase*)database {
	for (NSDictionary* service in [bonjourBrowser services]) {
		NSString* type = [service valueForKey:@"type"];
		
		if ([type isEqualToString:@"localPath"]) {
			NSString* servicePath = [service valueForKey:@"Path"];
		} else {
			NSString* serviceAddress = [service valueForKey:@""];
		}
		
	}
	
	return -1;
}



- (IBAction)bonjourServiceClickedProceed: (id)sender
{
	if( [_sourcesTableView selectedRow] == -1) return;
	
//	if( DICOMDIRCDMODE)
//	{
//		dontLoadSelectionSource = YES;
//		[_sourcesTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
//		dontLoadSelectionSource = NO;
//		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
//		return;
//	}
	
	
//	[database save:NULL];
	
    int index = [_sourcesTableView selectedRow]-1;
	
	if( index >= 0)
	{
		NSDictionary *object = [[bonjourBrowser services] objectAtIndex: index];
		
		// DICOM DESTINATION
		if( [[object valueForKey: @"type"] isEqualToString:@"dicomDestination"])
		{
			NSRunAlertPanel( NSLocalizedString(@"DICOM Destination", nil), NSLocalizedString(@"It is a DICOM destination node: you cannot browse its content. You can only drag & drop studies on them.", nil), nil, nil, nil);
			
			[_sourcesTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: previousBonjourIndex+1] byExtendingSelection:NO];
		}
		// LOCAL PATH - DATABASE
		/*else if( [[object valueForKey: @"type"] isEqualToString:@"localPath"])
		{
			[self initiateSetDatabaseAtPath:[object valueForKey:@"Path"] name:[object valueForKey:@"Description"]];
			[self setDatabase:[DicomDatabase databaseAtPath:[object valueForKey:@"Path"] name:[object valueForKey:@"Description"]]];
		}
		else	// NETWORK - DATABASE - bonjour / fixedIP
		{
			int port = [[object valueForKey:@"OsiriXPort"] intValue];
			if (!port) port = 8780;
			
			[self initiateSetRemoteDatabaseWithAddress:[object valueForKey:@"Address"] port:port name:[object valueForKey:@"Description"]];
			
//			displayEmptyDatabase = YES;
//			[self outlineViewRefresh];
//			[self refreshMatrix: self];
//			
//			NSString *path = [bonjourBrowser getDatabaseFile: index showWaitingWindow: YES];
//						
//			if( path == nil || [path isEqualToString: @"aborted"])
//			{
//				if( [path isEqualToString: @"aborted"]) NSLog( @"Transfer aborted");
//				else NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot connect to the database.", nil), nil, nil, nil);
//				
//				[self resetToLocalDatabase];
//			}
//			else
//			{
//				NSLog(@"Bonjour DB = %@", path);
//				
//				[segmentedAlbumButton setEnabled: NO];
//				
//				[self openDatabaseIn: path Bonjour: YES];
//				displayEmptyDatabase = NO;
//			}
		}*/
	}
	else // LOCAL DEFAULT DATABASE
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		[self setDatabase:[DicomDatabase defaultDatabase]];
	}
	
	
	previousBonjourIndex = [_sourcesTableView selectedRow]-1;
	
}

- (IBAction)bonjourServiceClicked:(id)sender {	
	[self performSelector:@selector(bonjourServiceClickedProceed:) withObject:sender afterDelay:0];
}

- (NSString*) localDatabasePath { // deprecated
	return [[DicomDatabase activeLocalDatabase] sqlFilePath];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Plugins

- (void)executeFilterFromString: (NSString*)name
{
	long result;
    id filter = [[PluginManager plugins] objectForKey:name];
	
	if (filter==nil)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
		return;
	}
	
	result = [filter prepareFilter: nil];
	[filter filterImage:name];
	NSLog(@"executeFilter %@", [filter description]);
	if( result)	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
		return;
	}
}

- (void)executeFilterDB: (id)sender
{
	[self executeFilterFromString:[sender title]];
}

- (void)executeFilterFromToolbar: (id)sender
{
	[self executeFilterFromString:[sender label]];
}

- (void)setNetworkLogs
{
	isNetworkLogsActive = [[NSUserDefaults standardUserDefaults] boolForKey: @"NETWORKLOGS"];
}

- (BOOL)isNetworkLogsActive
{
	return isNetworkLogsActive;
}

#pragma deprecated (setFixedDocumentsDirectory)
- (NSString *)setFixedDocumentsDirectory { // __deprecated
	NSLog(@"%s IS NOT AVAILABLE ANYMORE, moved to DicomDatabase.. This message should never appear!", __PRETTY_FUNCTION__);
	return nil;

//	[fixedDocumentsDirectory release];
//	fixedDocumentsDirectory = [[self documentsDirectory] retain];
//	
//	if( fixedDocumentsDirectory == nil)
//	{
//		NSRunAlertPanel( NSLocalizedString(@"Database Location Error", nil), NSLocalizedString(@"Cannot locate Database path.", nil), nil, nil, nil);
//		exit(0);
//	}
//	
//	strcpy( cfixedDocumentsDirectory, [fixedDocumentsDirectory UTF8String]);
//	
//	if( [[NSUserDefaults standardUserDefaults] boolForKey: OsirixCanActivateDefaultDatabaseOnlyDefaultsKey])
//	{
//		NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
//		
//		strcpy( cfixedIncomingDirectory, [defaultPath UTF8String]);
//	}
//	else strcpy( cfixedIncomingDirectory, [fixedDocumentsDirectory UTF8String]);
//	
//	NSString *r;
//	
//	r = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath: [NSString stringWithFormat:@"%s/%s", cfixedIncomingDirectory, "TEMP.noindex"] error: nil];
//	if( r == nil)
//		r = [NSString stringWithFormat:@"%s/%s", cfixedIncomingDirectory, "TEMP.noindex"];
//	strcpy( cfixedTempNoIndexDirectory, [r UTF8String]);
//	
//	r = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath: [NSString stringWithFormat:@"%s/%s", cfixedIncomingDirectory, "INCOMING.noindex"] error: nil];
//	if( r == nil)
//	{
//		r = [NSString stringWithFormat:@"%s/%s", cfixedIncomingDirectory, "INCOMING.noindex"];
//		r = [self folderPathResolvingAliasAndSymLink: r];
//	}
//	strcpy( cfixedIncomingNoIndexDirectory, [r UTF8String]);
//	
//	return fixedDocumentsDirectory;
}

- (NSString *) localDocumentsDirectory { // __deprecated
	return [[DicomDatabase activeLocalDatabase] baseDirPath];
}

- (NSString *) fixedDocumentsDirectory { // __deprecated
	return [[DicomDatabase activeLocalDatabase] baseDirPath];
}

- (const char *) cfixedDocumentsDirectory // __deprecated
{ return [[DicomDatabase activeLocalDatabase] baseDirPathC]; }

- (const char *) cfixedIncomingDirectory // __deprecated
{ return [[DicomDatabase activeLocalDatabase] incomingDirPathC]; }

- (const char *) cfixedTempNoIndexDirectory // __deprecated
{ return [[DicomDatabase activeLocalDatabase] tempDirPathC]; }

- (const char *) cfixedIncomingNoIndexDirectory // __deprecated
{ return [[DicomDatabase activeLocalDatabase] incomingDirPathC]; }

- (NSString*)INCOMINGPATH { // __deprecated
	return [_database incomingDirPath];
}

+ (NSString *) defaultDocumentsDirectory { // __deprecated
	NSString *dir = documentsDirectory();
	return [[DicomDatabase defaultDatabase] baseDirPath];
}

- (NSString*)documentsDirectory { // __deprecated
	return [_database baseDirPath];
}

- (NSString *) documentsDirectoryFor:(int) mode url:(NSString*) url
{
	NSString *dir = documentsDirectoryFor( mode, url);
	return dir;
}

- (IBAction)showLogWindow: (id)sender
{
	if(!logWindowController)
		logWindowController = [[LogWindowController alloc] init];
    [logWindowController showWindow:self];
}

- (void) resetLogWindowController
{
	[logWindowController close];
	[logWindowController release];
	logWindowController = nil;
}

- (NSString *) searchString
{
    return _searchString;
}

- (void)setSearchString: (NSString *)searchString
{
	if( searchType == 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"HIDEPATIENTNAME"])
		[searchField setTextColor: [NSColor whiteColor]];
	else
		[searchField setTextColor: [NSColor blackColor]];
	
	[_searchString release];
	_searchString = [searchString retain];
	
	[self setFilterPredicate:[self createFilterPredicate] description:[self createFilterDescription]];
	[self outlineViewRefresh];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (IBAction)searchForCurrentPatient: (id)sender
{
	if( [databaseOutline selectedRow] != -1)
	{
		NSManagedObject *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		if( aFile)
		{
			if([[aFile valueForKey:@"type"] isEqualToString:@"Study"])
				[self setSearchString: [aFile valueForKey:@"name"]];
			else
				[self setSearchString: [aFile valueForKeyPath:@"study.name"]];
		}
	}
}

- (void)setFilterPredicate: (NSPredicate *)predicate description: (NSString*)desc
{
	[_filterPredicate release];
	_filterPredicate = [predicate retain];
	
	[_filterPredicateDescription release];
	_filterPredicateDescription = [desc retain];
}

- (NSString *)createFilterDescription
{
	NSString *description = nil;
	
	if ( [_searchString length] > 0)
	{
		switch(searchType) 
		{
		case 7:			// All fields 
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: All fields = %@", nil), _searchString];
			break;
			
		case 0:			// Patient Name
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Patient's name = %@", nil), _searchString];
			break;
			
		case 1:			// Patient ID
			description = [[NSString alloc] initWithFormat:@" / Search: Patient's ID = %@", _searchString];
			break;
			
		case 2:			// Study/Series ID
			description = [[NSString alloc] initWithFormat:@" / Search: Study's ID = %@", _searchString];
			break;
			
		case 3:			// Comments
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Comments = %@", nil), _searchString];
			break;
			
		case 4:			// Study Description
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Study Description = %@", nil), _searchString];
			break;
			
		case 5:			// Modality
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Modality = %@", nil), _searchString];
			break;
			
		case 6:			// Accession Number 
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Accession Number = %@", nil), _searchString];
			break;
		
		case 8:			// Comments
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Comments 2 = %@", nil), _searchString];
			break;
			
		case 9:			// Comments
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Comments 3 = %@", nil), _searchString];
			break;
			
		case 10:			// Comments
			description = [[NSString alloc] initWithFormat: NSLocalizedString(@" / Search: Comments 4 = %@", nil), _searchString];
			break;
			
		case 100:		
			// Advanced
			break;
		}
		
	}
	return [description autorelease];
}

- (NSPredicate *)createFilterPredicate
{
	NSPredicate *predicate = nil;
	NSString *s = nil;
	
	if ([_searchString length] > 0)
	{
		switch (searchType)
		{
			case 7:			// All Fields
				s = [NSString stringWithFormat:@"%@", _searchString];
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useSoundexForName"] && [s length] > 0) 
					predicate = [NSPredicate predicateWithFormat: @"(soundex CONTAINS[cd] %@) OR (name CONTAINS[cd] %@) OR (patientID CONTAINS[cd] %@) OR (id CONTAINS[cd] %@) OR (comment CONTAINS[cd] %@) OR (comment2 CONTAINS[cd] %@) OR (comment3 CONTAINS[cd] %@) OR (comment4 CONTAINS[cd] %@) OR (studyName CONTAINS[cd] %@) OR (ANY series.modality CONTAINS[cd] %@) OR (accessionNumber CONTAINS[cd] %@)", [DicomStudy soundex: s], s, s, s, s, s, s, s, s, s, s];
				else
					predicate = [NSPredicate predicateWithFormat: @"(name CONTAINS[cd] %@) OR (patientID CONTAINS[cd] %@) OR (id CONTAINS[cd] %@) OR (comment CONTAINS[cd] %@) OR (comment2 CONTAINS[cd] %@) OR (comment3 CONTAINS[cd] %@) OR (comment4 CONTAINS[cd] %@) OR (studyName CONTAINS[cd] %@) OR (ANY series.modality CONTAINS[cd] %@) OR (accessionNumber CONTAINS[cd] %@)", s, s, s, s, s, s, s, s, s, s];
			break;
			
			case 0:			// Patient Name
				if( [[NSUserDefaults standardUserDefaults] boolForKey: @"useSoundexForName"] && [_searchString length] > 0)
					predicate = [NSPredicate predicateWithFormat: @"(soundex CONTAINS[cd] %@) OR (name CONTAINS[cd] %@)", [DicomStudy soundex: _searchString], s];
				else
					predicate = [NSPredicate predicateWithFormat: @"name CONTAINS[cd] %@", _searchString];
			break;
			
			case 1:			// Patient ID
				predicate = [NSPredicate predicateWithFormat: @"patientID CONTAINS[cd] %@", _searchString];
			break;
			
			case 2:			// Study/Series ID
				predicate = [NSPredicate predicateWithFormat: @"id CONTAINS[cd] %@", _searchString];
			break;
			
			case 3:			// Comments
				predicate = [NSPredicate predicateWithFormat: @"comment CONTAINS[cd] %@", _searchString];
			break;
			
			case 4:			// Study Description
				predicate = [NSPredicate predicateWithFormat: @"studyName CONTAINS[cd] %@", _searchString];
			break;
			
			case 5:			// Modality
				predicate = [NSPredicate predicateWithFormat: @"ANY series.modality CONTAINS[cd] %@", _searchString];
			break;
			
			case 6:			// Accession Number 
				predicate = [NSPredicate predicateWithFormat: @"accessionNumber CONTAINS[cd] %@", _searchString];
			break;
			
			case 8:			// Comments
				predicate = [NSPredicate predicateWithFormat: @"comment2 CONTAINS[cd] %@", _searchString];
			break;
			
			case 9:			// Comments
				predicate = [NSPredicate predicateWithFormat: @"comment3 CONTAINS[cd] %@", _searchString];
			break;
			
			case 10:			// Comments
				predicate = [NSPredicate predicateWithFormat: @"comment4 CONTAINS[cd] %@", _searchString];
			break;
			
			case 100:		// Advanced
			break;
		}
	}
	return predicate;
}

- (NSArray *) databaseSelection
{
	NSMutableArray		*selectedItems			= [NSMutableArray array];
	NSIndexSet			*selectedRowIndexes		= [databaseOutline selectedRowIndexes];
	
	for ( NSInteger index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
		if ([selectedRowIndexes containsIndex:index])
		{
			[selectedItems addObject: [databaseOutline itemAtRow:index]];
		}
	}
	return selectedItems;
}

// Comparisons
// Finding Comparisons
- (NSArray *)relatedStudiesForStudy: (id)study
{
	NSManagedObjectModel	*model = self.managedObjectModel;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	// FIND ALL STUDIES of this patient
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientID == %@)", [study valueForKey:@"patientID"]];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	dbRequest.entity = [model.entitiesByName objectForKey:@"Study"];
	dbRequest.predicate = predicate;
	
	[context lock];
	
	NSError	*error = nil;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	@try 
	{
		if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
		{
			NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
			NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
			[sort release];
			NSMutableArray* s = [[[studiesArray sortedArrayUsingDescriptors: sortDescriptors] mutableCopy] autorelease];
			// remove original study from array
			[s removeObject:study];
			
			studiesArray = [NSArray arrayWithArray: s];
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		[AppController printStackTrace: e];
	}
	
	[context unlock];
	
	return studiesArray;
}

-(BOOL)isCurrentDatabaseBonjour {
	return ![_database isLocal];
}

-(NSString*)currentDatabasePath {
	return [_database baseDirPath];
}

-(NSManagedObjectContext*)bonjourManagedObjectContext {
	if (![_database isLocal])
		return [_database managedObjectContext];
	return nil;
}

@end
