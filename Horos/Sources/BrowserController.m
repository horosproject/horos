/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#include <objc/runtime.h>

#include "options.h"

#import "ToolbarPanel.h"
#import "DicomDatabase.h"
#import "DicomDatabase+Routing.h"
#import "DicomDatabase+Clean.h"
#import "DicomDatabase+DCMTK.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
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
#import "NSWindow+N2.h"
#import "DicomStudy.h"
#import "DicomStudy+Report.h"
#import "DCMPix.h"
#import "SRAnnotation.h"
#import "AppController.h"
#import "DicomData.h"
#import "BrowserController.h"
#import "ViewerController.h"
#import "PluginFilter.h"
#import "ReportPluginFilter.h"
#import "DicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "NSSplitViewSave.h"
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
#import "DCM.h"
#import "DCMObject.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCMNetServiceDelegate.h"
#import "LogWindowController.h"
#import "stringAdditions.h"
#import "SendController.h"
#import "Reports.h"
#import "LogManager.h"
#import "DCMTKStoreSCU.h"
#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "WindowLayoutManager.h"
#import "QTExportHTMLSummary.h"
#import "BrowserControllerDCMTKCategory.h"
#import "BrowserMatrix.h"
#import "DicomAlbum.h"
#import "PluginManager.h"
#import "PluginManagerController.h"
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
#import "PrettyCell.h"
#import "ComparativeCell.h"
#import "N2Stuff.h"
#import "NSNotificationCenter+N2.h"
#import "NSFullScreenWindow.h"
#import "CustomIntervalPanel.h"
#import "QuicktimeExport.h"
#import "DICOMToNSString.h"
#import "XMLControllerDCMTKCategory.h"
#import "WADOXML.h"
#import "DicomDir.h"
#import "CPRVolumeData.h"
#import "O2HMigrationAssistant.h"
#import "ICloudDriveDetector.h"
#import "NSException+N2.h"

#import "homephone/HorosHomePhone.h"

#import "url.h"

#ifndef OSIRIX_LIGHT
#import "Anonymization.h"
#import "AnonymizationSavePanelController.h"
#import "AnonymizationViewController.h"
#import "NSFileManager+N2.h"
#endif

#import "WebPortal.h"
#import "WebPortal+Email+Log.h"
#import "WebPortalDatabase.h"

#define DISTANTSTUDYFONT @"Helvetica-BoldOblique"

//#define DATABASEVERSION @"2.5"

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>

static BrowserController *browserWindow = nil;
NSString * const O2AlbumDragType = @"Osirix Album drag";
NSString * const O2DatabaseXIDsDragType = @"BrowserController.database.context.XIDs";
NSString * const O2PasteboardTypeDatabaseObjectXIDs = @"com.opensource.osirix.database.xids";
static BOOL loadingIsOver = NO;//, isAutoCleanDatabaseRunning = NO;
static NSMenu *contextual = nil;
static NSMenu *contextualRT = nil;  // Alternate menus for RT objects (which often don't have images)
static int DicomDirScanDepth = 0;
static int DefaultFolderSizeForDB = 0;
static NSString *smartAlbumDistantArraySync = @"smartAlbumDistantArraySync";

extern int delayedTileWindows;
extern BOOL NEEDTOREBUILD;//, COMPLETEREBUILD;

#pragma deprecated(asciiString)
NSString* asciiString(NSString* str)
{
    return [str ASCIIString];
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

-(void)setDBWindowTitle;
-(void)previewMatrixScrollViewFrameDidChange:(NSNotification*)note;
-(void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize;
-(void)splitViewDidResizeSubviews:(NSNotification*)notification;
-(NSArray*)albumsInDatabase;
-(void)initContextualMenus;
-(void)observeScrollerStyleDidChangeNotification:(NSNotification*)n;
-(void)removeAlbumObject:(DicomAlbum*)album;

-(void)saveLoadAlbumsSortDescriptors;

@end

@interface BrowserControllerClassHelper : NSObject
@end

@implementation BrowserControllerClassHelper

static NSString* BrowserControllerClassHelperContext = @"BrowserControllerClassHelperContext";

-(id)init {
    if ((self = [super init])) {
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixCanActivateDefaultDatabaseOnlyDefaultsKey options:NSKeyValueObservingOptionInitial context:BrowserControllerClassHelperContext];
    }
    
    return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context == BrowserControllerClassHelperContext)
    {
        if ([keyPath isEqualToString:valuesKeyPath(OsirixCanActivateDefaultDatabaseOnlyDefaultsKey)])
        {
            if ([NSUserDefaults canActivateAnyLocalDatabase])
                [DicomDatabase setActiveLocalDatabase:[[BrowserController currentBrowser] database]];
        }
    }
}

- (void) dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver: self forValuesKey: OsirixCanActivateDefaultDatabaseOnlyDefaultsKey];
    
    [super dealloc];
}

@end

@implementation BrowserController

+(void)initializeBrowserControllerClass
{
    static BrowserControllerClassHelper* helper = nil;
    if (!helper) helper = [[BrowserControllerClassHelper alloc] init];
}

static NSString* 	DatabaseToolbarIdentifier			= @"DicomDatabase Toolbar Identifier";
static NSString*	ImportToolbarItemIdentifier			= @"Import.pdf";
static NSString*	QTSaveToolbarItemIdentifier			= @"QTExport.pdf";
static NSString*	ExportToolbarItemIdentifier			= @"Export.pdf";
static NSString*	ExportROIAndKeyImagesToolbarItemIdentifier	= @"ExportROIAndKeyImages.tif";
static NSString*	AnonymizerToolbarItemIdentifier		= @"Anonymizer.pdf";
static NSString*	QueryToolbarItemIdentifier			= @"QueryRetrieve.pdf";
static NSString*	SendToolbarItemIdentifier			= @"Send.pdf";
static NSString*	ViewerToolbarItemIdentifier			= @"Viewer.pdf";
//static NSString*	CDRomToolbarItemIdentifier			= @"cd.icns";
static NSString*	MovieToolbarItemIdentifier			= @"Movie.pdf";
static NSString*	TrashToolbarItemIdentifier			= @"trash.icns";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	BurnerToolbarItemIdentifier			= @"Burner.icns";
static NSString*	ToggleDrawerToolbarItemIdentifier   = @"StartupDisk.tif";
static NSString*	SearchToolbarItemIdentifier			= @"Search";
static NSString*	TimeIntervalToolbarItemIdentifier	= @"TimeInterval";
static NSString*    ModalityFilterToolbarItemIdentifier = @"ModalityFilter";
static NSString*	XMLToolbarItemIdentifier			= @"XML.icns";
static NSString*	MailToolbarItemIdentifier			= @"Mail.icns";
static NSString*	OpenKeyImagesAndROIsToolbarItemIdentifier	= @"ROIsAndKeys.tif";
static NSString*	OpenKeyImagesToolbarItemIdentifier	= @"Keys.tif";
static NSString*	OpenROIsToolbarItemIdentifier	= @"ROIs.tif";
static NSString*	ViewersToolbarItemIdentifier	= @"windows.tif";
static NSString*	WebServerSingleNotification	= @"Safari.tif";
static NSString*	AddStudiesToUserItemIdentifier	= @"NSUserAccounts";
static NSString*    ResetSplitViewsItemIdentifier = @"Reset.pdf";
static NSString*    HorosMigrationAssistantIdentifier = @"O2HMigrationAssistant.png";

static NSTimeInterval gLastActivity = 0;
static BOOL dontShowOpenSubSeries = NO;
static BOOL gHorizontalHistory = NO;

static NSArray*	statesArray = nil;

static NSNumberFormatter* decimalNumberFormatter = NULL;
static volatile BOOL waitForRunningProcess = NO;

+(void)initialize
{
    decimalNumberFormatter = [[NSNumberFormatter alloc] init];
    [decimalNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    //	[decimalNumberFormatter setLocale: [NSLocale currentLocale]];
    //	[decimalNumberFormatter setFormat:@"0"];
    //	[decimalNumberFormatter setHasThousandSeparators: YES];
}

- (void) setTableViewRowHeight
{
    int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"];
    
    if( mode == -1) //Small
    {
        [albumTable setRowHeight: 13];
        [_sourcesTableView setRowHeight: 13];
        [databaseOutline setRowHeight: 13];
        if( gHorizontalHistory)
            [comparativeTable setRowHeight: 13];
        else
            [comparativeTable setRowHeight: 24];
        [_activityTableView setRowHeight: 34];
        [oMatrix setCellSize: NSMakeSize( 105 * 0.8, 113 * 0.8)];
    }
    
    if( mode == 0) // Regular
    {
        [albumTable setRowHeight: 17];
        [_sourcesTableView setRowHeight: 17];
        [databaseOutline setRowHeight: 17];
        if( gHorizontalHistory)
            [comparativeTable setRowHeight: 16];
        else
            [comparativeTable setRowHeight: 29];
        [_activityTableView setRowHeight: 38];
        [oMatrix setCellSize: NSMakeSize( 105, 113)];
    }
    
    if( mode == 1) // Large
    {
        [albumTable setRowHeight: 25];
        [_sourcesTableView setRowHeight: 25];
        [databaseOutline setRowHeight: 22];
        if( gHorizontalHistory)
            [comparativeTable setRowHeight: 21];
        else
            [comparativeTable setRowHeight: 43];
        [_activityTableView setRowHeight: 48];
        [oMatrix setCellSize: NSMakeSize( 105 * 1.3, 113 * 1.3)];
    }
}

- (float) fontSize: (NSString*) type
{
    int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"];
    
    if( mode == -1) //Small
    {
        if( [type isEqualToString: @"threadNameSize"])
            return 9;
        
        if( [type isEqualToString: @"threadNameStatus"])
            return 8;
        
        if( [type isEqualToString: @"comparativeLineSpace"])
            return 12;
        
        if( [type isEqualToString: @"threadCellLineSpace"])
            return 10;
        
        if( [type isEqualToString: @"dbFont"])
            return 10;
        
        if( [type isEqualToString: @"dbComparativeFont"])
            return 9;
        
        if( [type isEqualToString: @"dbAlbumFont"])
            return 9;
        
        if( [type isEqualToString: @"dbSourceFont"])
            return 9;
        
        if( [type isEqualToString: @"dbSeriesFont"])
            return 8;
        
        if( [type isEqualToString: @"dbMatrixFont"])
            return 8;
        
        if( [type isEqualToString: @"dbSmallMatrixFont"])
            return 7.5;
        
        if( [type isEqualToString: @"viewerSmallCellFont"])
            return 7;
        
        if( [type isEqualToString: @"viewerNumberFont"])
            return 11;
    }
    
    if( mode == 0) // Regular
    {
        if( [type isEqualToString: @"threadNameSize"])
            return [NSFont systemFontSizeForControlSize:NSSmallControlSize];
        
        if( [type isEqualToString: @"threadNameStatus"])
            return [NSFont systemFontSizeForControlSize:NSMiniControlSize];
        
        if( [type isEqualToString: @"comparativeLineSpace"])
            return 14;
        
        if( [type isEqualToString: @"threadCellLineSpace"])
            return 13;
        
        if( [type isEqualToString: @"dbFont"])
            return 12;
        
        if( [type isEqualToString: @"dbComparativeFont"])
            return 11;
        
        if( [type isEqualToString: @"dbAlbumFont"])
            return 11;
        
        if( [type isEqualToString: @"dbSourceFont"])
            return 11;
        
        if( [type isEqualToString: @"dbSeriesFont"])
            return 10;
        
        if( [type isEqualToString: @"dbMatrixFont"])
            return 9;
        
        if( [type isEqualToString: @"dbSmallMatrixFont"])
            return 8.5;
        
        if( [type isEqualToString: @"viewerSmallCellFont"])
            return 7.8;
        
        if( [type isEqualToString: @"viewerNumberFont"])
            return 15;
    }
    
    if( mode == 1) // Large
    {
        if( [type isEqualToString: @"threadNameSize"])
            return 13;
        
        if( [type isEqualToString: @"threadNameStatus"])
            return 11;
        
        if( [type isEqualToString: @"comparativeLineSpace"])
            return 20;
        
        if( [type isEqualToString: @"threadCellLineSpace"])
            return 19;
        
        if( [type isEqualToString: @"dbFont"])
            return 15;
        
        if( [type isEqualToString: @"dbComparativeFont"])
            return 13.5;
        
        if( [type isEqualToString: @"dbAlbumFont"])
            return 14;
        
        if( [type isEqualToString: @"dbSourceFont"])
            return 14;
        
        if( [type isEqualToString: @"dbSeriesFont"])
            return 13;
        
        if( [type isEqualToString: @"dbMatrixFont"])
            return 13;
        
        if( [type isEqualToString: @"dbSmallMatrixFont"])
            return 12;
        
        if( [type isEqualToString: @"viewerSmallCellFont"])
            return 11;
        
        if( [type isEqualToString: @"viewerNumberFont"])
            return 20;
    }
    
    N2LogStackTrace( @"********* fontSize not found for type: %@", type);
    
    return 12;
}

@synthesize database = _database;
@synthesize sources = _sourcesArrayController;

@synthesize CDpassword, passwordForExportEncryption, databaseIndexDictionary;
@synthesize TimeFormat, TimeWithSecondsFormat, temporaryNotificationEmail, customTextNotificationEmail;
@synthesize DateTimeWithSecondsFormat, matrixViewArray, oMatrix, testPredicate;
@synthesize databaseOutline, albumTable, comparativePatientUID, distantStudyMessage;
@synthesize bonjourSourcesBox, timeIntervalType, smartAlbumDistantName, selectedAlbumName;
@synthesize bonjourBrowser, pathToEncryptedFile, comparativeStudies, distantTimeIntervalStart, distantTimeIntervalEnd;
@synthesize searchString = _searchString, fetchPredicate = _fetchPredicate, distantSearchType, distantSearchString;
@synthesize filterPredicate = _filterPredicate, filterPredicateDescription = _filterPredicateDescription;
@synthesize pluginManagerController, modalityFilter;

+ (BOOL) tryLock:(id) c during:(NSTimeInterval) sec
{
    if( c == nil)
        return YES;
    
    if( [c lockBeforeDate: [NSDate dateWithTimeIntervalSinceNow: sec]])
    {
        [c unlock];
        return YES;
    }
    
    NSLog( @"******* tryLockDuring failed for this lock: %@ (%f sec)", c, sec);
    
    return NO;
}

+ (BOOL) horizontalHistory { return gHorizontalHistory;}
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

-(NSArray*)albumsInDatabase
{
    NSArray* r = [NSArray array];
    
    if( _database.managedObjectContext == nil)
        return r;
    
    @try
    {
        @synchronized (self)
        {
            if (_cachedAlbums && _cachedAlbumsContext && _cachedAlbumsContext == _database.managedObjectContext)
                return [[_cachedAlbums copy] autorelease];
        }
        
        r = [_database albums];
        
        @synchronized (self) {
            [_cachedAlbums release];
            _cachedAlbums = [r retain];
            [_cachedAlbumsIDs release];
            _cachedAlbumsIDs = [[_cachedAlbums valueForKey: @"objectID"] retain];
            _cachedAlbumsContext = _database.managedObjectContext;
        }
    }
    @catch (NSException *e) {
        N2LogException(e);
    }
    
    return [[r copy] autorelease];
}

-(NSArray*)albums
{
    return [self albumsInDatabase];
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
    int mpprocessors = [[NSProcessInfo processInfo] processorCount];
    
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
        
        [NSThread detachNewThreadSelector: @selector(vImageThread:) toTarget: browserWindow withObject: d];
    }
    
    [threadLock lockWhenCondition: 0];
    [threadLock unlock];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Add DICOM Database functions

- (NSString*)getNewFileDatabasePath:(NSString*)extension // __deprecated
{
    return [_database uniquePathForNewDataFileWithExtension:extension];
}

- (NSString*)getNewFileDatabasePath:(NSString*)extension dbFolder:(NSString*)dbFolder // __deprecated
{
    return [[DicomDatabase databaseAtPath:dbFolder] uniquePathForNewDataFileWithExtension:extension];
}

- (void) rebuildViewers: (NSMutableArray*) vlToRebuild
{
    // Refresh preview matrix if needed
    for( ViewerController *vc in vlToRebuild)
    {
        if( [vc windowWillClose] == NO && [[vc window] isVisible] && [[vc imageView] mouseDragging] == NO)
        {
            [vc buildMatrixPreview: NO];
        }
    }
}

#pragma deprecated (addFilesToDatabase:)
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    if( [NSThread isMainThread] == NO) N2LogStackTrace( @"********* We should be on MAIN thread for accessing objects from _database object");
    return [_database objectsWithIDs:[_database addFilesAtPaths:newFilesArray]];
}

#pragma deprecated (addFilesToDatabase::)
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray :(BOOL)onlyDICOM // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    if( [NSThread isMainThread] == NO) N2LogStackTrace( @"********* We should be on MAIN thread for accessing objects from _database object");
    return [_database objectsWithIDs:[_database addFilesAtPaths:newFilesArray postNotifications:YES dicomOnly:onlyDICOM rereadExistingItems:NO]];
}

#pragma deprecated (addFilesToDatabase:onlyDICOM:produceAddedFiles:)
-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    if( [NSThread isMainThread] == NO) N2LogStackTrace( @"********* We should be on MAIN thread for accessing objects from _database object");
    return [_database objectsWithIDs:[_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:NO]];
}

#pragma deprecated (addFilesToDatabase:onlyDICOM:produceAddedFiles:parseExistingObject:)
-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM  produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    if( [NSThread isMainThread] == NO) N2LogStackTrace( @"********* We should be on MAIN thread for accessing objects from _database object");
    return [_database objectsWithIDs:[_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject]];
}

#pragma deprecated (checkForExistingReport:dbFolder:)
- (void) checkForExistingReport: (NSManagedObject*) study dbFolder: (NSString*) dbFolder
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:study.managedObjectContext];
    [db checkForExistingReportForStudy:study];
}

#pragma mark-

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && browserController) db = [browserController database];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db && (context || dbFolder)) db = [[[DicomDatabase alloc] initWithPath:dbFolder context:context] autorelease];
    if (!db) N2LogError(@"couldn't identify database");
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject]];
}

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context toDatabase:(BrowserController*)browserController onlyDICOM:(BOOL)onlyDICOM notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder generatedByOsiriX:(BOOL)generatedByOsiriX // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && browserController) db = [browserController database];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db && (context || dbFolder)) db = [[[DicomDatabase alloc] initWithPath:dbFolder context:context] autorelease];
    if (!db) N2LogError(@"couldn't identify database");
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject generatedByOsiriX:generatedByOsiriX]];
}

#pragma deprecated
+(NSArray*) addFiles:(NSArray*) newFilesArray toContext: (NSManagedObjectContext*) context toDatabase: (BrowserController*) browserController onlyDICOM: (BOOL) onlyDICOM  notifyAddedFiles: (BOOL) notifyAddedFiles parseExistingObject: (BOOL) parseExistingObject dbFolder: (NSString*) dbFolder generatedByOsiriX: (BOOL) generatedByOsiriX mountedVolume: (BOOL) mountedVolume // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && browserController) db = [browserController database];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db && (context || dbFolder)) db = [[[DicomDatabase alloc] initWithPath:dbFolder context:context] autorelease];
    if (!db) N2LogError(@"couldn't identify database");
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject generatedByOsiriX:generatedByOsiriX]];
}

#pragma deprecated
+(NSArray*)addFiles:(NSArray*)newFilesArray toContext:(NSManagedObjectContext*)context onlyDICOM:(BOOL)onlyDICOM  notifyAddedFiles:(BOOL)notifyAddedFiles parseExistingObject:(BOOL)parseExistingObject dbFolder:(NSString*)dbFolder // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db && (context || dbFolder)) db = [[[DicomDatabase alloc] initWithPath:dbFolder context:context] autorelease];
    if (!db) N2LogError(@"couldn't identify database");
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:notifyAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject]];
}

#pragma deprecated
-(NSArray*)subAddFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM produceAddedFiles:(BOOL)produceAddedFiles parseExistingObject:(BOOL)parseExistingObject context:(NSManagedObjectContext*)context dbFolder:(NSString*)dbFolder // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db) db = _database;
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject]];
}

#pragma deprecated
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM safeRebuild:(BOOL)safeRebuild produceAddedFiles:(BOOL)produceAddedFiles { // __deprecated // notice: the "safeRebuild" seemed to be already ignored before the DicomDatabase transition
    
    N2LogStackTrace( @"****** deprecated function");
    if( [NSThread isMainThread] == NO) N2LogStackTrace( @"********* We should be on MAIN thread for accessing objects from _database object");
    return [_database objectsWithIDs:[_database addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:NO]];
}

#pragma deprecated
-(NSArray*)addFilesToDatabase:(NSArray*)newFilesArray onlyDICOM:(BOOL)onlyDICOM produceAddedFiles:(BOOL)produceAddedFiles parseExistingObject:(BOOL)parseExistingObject context:(NSManagedObjectContext*)context dbFolder:(NSString*)dbFolder // __deprecated
{
    N2LogStackTrace( @"****** deprecated function");
    DicomDatabase* db = [DicomDatabase databaseForContext:context];
    if (!db && dbFolder) db = [DicomDatabase databaseAtPath:dbFolder];
    if (!db) db = _database;
    return [db objectsWithIDs:[db addFilesAtPaths:newFilesArray postNotifications:produceAddedFiles dicomOnly:onlyDICOM rereadExistingItems:parseExistingObject]];
}

#pragma mark-


+ (void) asyncWADOXMLDownloadURL:(NSURL*) url
{
    WADOXML *w = [[[WADOXML alloc] init] autorelease];
    
    [w parseURL: url];
    
    NSThread* t = [[[NSThread alloc] initWithTarget:[[[WADODownload alloc] init] autorelease] selector:@selector(WADODownload:) object: w.getWADOUrls] autorelease];
    t.name = NSLocalizedString( @"WADO Retrieve...", nil);
    t.supportsCancel = YES;
    t.status = [url lastPathComponent];
    [[ThreadsManager defaultManager] addThreadAndStart: t];
}

- (void) asyncWADODownload:(NSString*) filename
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableArray *urlToDownloads = [NSMutableArray array];
    
    @try
    {
        NSArray *urlsR = [[NSString stringWithContentsOfFile:filename usedEncoding:NULL error:NULL] componentsSeparatedByString: @"\r"];
        NSArray *urlsN = [[NSString stringWithContentsOfFile:filename usedEncoding:NULL error:NULL] componentsSeparatedByString: @"\n"];
        
        if( urlsR.count >= urlsN.count)
        {
            for( NSString *url in urlsR)
            {
                if( url.length)
                    [urlToDownloads addObject: [NSURL URLWithString: url]];
            }
        }
        else
        {
            for( NSString *url in urlsN)
            {
                if( url.length)
                    [urlToDownloads addObject: [NSURL URLWithString: url]];
            }
        }
    }
    @catch ( NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    WADODownload *downloader = [[[WADODownload alloc] init] autorelease];
    [downloader WADODownload: urlToDownloads];
    
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
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        @try
        {
            if( [[filename lastPathComponent] characterAtIndex: 0] != '.')
            {
                if([defaultManager fileExistsAtPath: filename isDirectory:&isDirectory])     // A directory
                {
                    if( isDirectory && [[filename pathExtension] isEqualToString: @"pages"] == NO && [[filename pathExtension] isEqualToString: @"app"] == NO)
                    {
                        NSString    *pathname;
                        NSString	*folderSkip = nil;
                        NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath: filename];
                        
                        while (pathname = [enumer nextObject])
                        {
                            NSAutoreleasePool *p = [NSAutoreleasePool new];
                            
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
                                                NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(asyncWADODownload:) object: filename] autorelease];
                                                t.name = NSLocalizedString( @"WADO Retrieve...", nil);
                                                t.supportsCancel = YES;
                                                t.status = [itemPath lastPathComponent];
                                                [[ThreadsManager defaultManager] addThreadAndStart: t];
                                            }
                                            else if( [[itemPath pathExtension] isEqualToString: @"zip"] || [[itemPath pathExtension] isEqualToString: @"osirixzip"])
                                            {
                                                NSString *unzipPath = [@"/tmp" stringByAppendingPathComponent: @"unzip_folder"];
                                                
                                                [[NSFileManager defaultManager] removeItemAtPath: unzipPath error: nil];
                                                [[NSFileManager defaultManager] createDirectoryAtPath: unzipPath withIntermediateDirectories:YES attributes:nil error:NULL];
                                                
                                                [self askForZIPPassword: itemPath destination: unzipPath];
                                                
                                                static int uniqueZipFolder = 1;
                                                NSString *uniqueFolder = [NSString stringWithFormat: @"unzip_folder_A%d", uniqueZipFolder++];
                                                [[NSFileManager defaultManager] moveItemAtPath: unzipPath toPath: [self.database.incomingDirPath stringByAppendingPathComponent: uniqueFolder] error: nil];
                                            }
                                            else if( [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] || [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR."])
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
                                N2LogExceptionWithStackTrace(e/*, @"addFilesAndFolderToDatabase 2"*/);
                            }
                            
                            [p release];
                        }
                    }
                    else    // A file
                    {
                        if( [[filename pathExtension] isEqualToString: @"xml"]) // Is it a WADO xml file? (like used for Weasis)
                        {
                            [BrowserController asyncWADOXMLDownloadURL: [NSURL fileURLWithPath: filename]];
                        }
                        else if( [[filename pathExtension] isEqualToString: @"dcmURLs"])
                        {
                            NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(asyncWADODownload:) object: filename] autorelease];
                            t.name = NSLocalizedString( @"WADO Retrieve...", nil);
                            t.supportsCancel = YES;
                            t.status = [filename lastPathComponent];
                            [[ThreadsManager defaultManager] addThreadAndStart: t];
                        }
                        else if( [[filename pathExtension] isEqualToString: @"zip"] || [[filename pathExtension] isEqualToString: @"osirixzip"])
                        {
                            NSString *unzipPath = [@"/tmp" stringByAppendingPathComponent: @"unzip_folder"];
                            
                            [[NSFileManager defaultManager] removeItemAtPath: unzipPath error: nil];
                            [[NSFileManager defaultManager] createDirectoryAtPath: unzipPath withIntermediateDirectories:YES attributes:nil error:NULL];
                            
                            [self askForZIPPassword: filename destination: unzipPath];
                            
                            static int uniqueZipFolder = 1;
                            NSString *uniqueFolder = [NSString stringWithFormat: @"unzip_folder_B%d", uniqueZipFolder++];
                            [[NSFileManager defaultManager] moveItemAtPath: unzipPath toPath: [self.database.incomingDirPath stringByAppendingPathComponent: uniqueFolder] error: nil];
                        }
                        else if( [[[filename lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] || [[[filename lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR."])
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
        
        [pool release];
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
        
        NSManagedObjectContext *context = self.database.managedObjectContext;
        
        [context lock];
        
        // Take a study for the test
        NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
        [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
        [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
        [dbRequest setFetchLimit: 1];
        
        NSError *error = nil;
        NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
        
        if( studiesArray.count > 0)
        {
            NSArray *images = [[[studiesArray objectAtIndex: 0] images] allObjects];
            
            for( NSDictionary *routingRule in autoroutingRules)
            {
                @try
                {
                    if( [[routingRule objectForKey:@"filterType"] intValue] == 0)
                    {
                        NSPredicate *predicate = [self smartAlbumPredicateString: [routingRule objectForKey: @"filter"]];
                        
                        // Test it on the first study...
                        [images filteredArrayUsingPredicate: predicate];
                    }
                }
                
                @catch( NSException *ne)
                {
                    NSRunAlertPanel( NSLocalizedString(@"Routing Filter Error", nil), NSLocalizedString(@"Syntax error in this routing filter: %@\r\r%@\r\r%@", nil), nil, nil, nil, [routingRule objectForKey:@"name"], [routingRule objectForKey:@"filter"], [ne description]);
                    
                    [ne printStackTrace];
                }
            }
        }
        
        [context unlock];
    }
#endif
}

- (DicomStudy*) selectedStudy
{
    NSMutableArray *objects = [NSMutableArray array];
    
    [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
    
    DicomImage *im = objects.lastObject;
    
    if( im == nil)
    {
        [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
        im = objects.lastObject;
    }
    return im.series.study;
}

- (void) applyRoutingRule: (id) sender // For manually applying a routing rule, from the DB contextual menu
{
    BOOL matrixThumbnails = NO;
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
    {
        matrixThumbnails = YES;
        NSLog( @"applyRoutingRule from matrix");
    }
    
    NSMutableArray *objects = [NSMutableArray array];
    
    if( matrixThumbnails)
        [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
    else
        [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
    
    if( [sender representedObject]) // Only selected rule
    {
        [_database applyRoutingRules: [NSArray arrayWithObject: [sender representedObject]] toImages: objects];
    }
    else // All rules
    {
        [_database applyRoutingRules: nil toImages: objects];
    }
}

- (void)addFiles:(NSArray*)images withRule:(NSDictionary*)routingRule // __deprecated
{
    [_database addImages:images toSendQueueForRoutingRule:routingRule];
}

#pragma mark-
#pragma mark Database functions

- (void) regenerateAutoCommentsThread: (NSDictionary*) arrays
{
    @autoreleasepool
    {
        NSManagedObjectContext *context = self.database.independentContext;
        
        NSArray *studiesArray = [arrays objectForKey: @"studyArrayIDs"];
        
        NSString *commentField = [[NSUserDefaults standardUserDefaults] stringForKey: @"commentFieldForAutoFill"];
        
        BOOL studyLevel = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILLStudyLevel"];
        BOOL seriesLevel = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILLSeriesLevel"];
        BOOL commentsAutoFill = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"];
        
        int x = 0;
        for( NSManagedObjectID *studyID in studiesArray)
        {
            DicomStudy *s = (DicomStudy*) [context objectWithID: studyID];
            
            [s willChangeValueForKey: commentField];
            [s setPrimitiveValue: 0L forKey: commentField];
            [s didChangeValueForKey: commentField];
        }
        
        for( NSManagedObjectID *studyID in studiesArray)
        {
            DicomStudy *s = (DicomStudy*) [context objectWithID: studyID];
            @try
            {
                [s willChangeValueForKey: commentField];
                
                if( studyLevel == YES && seriesLevel == NO && commentsAutoFill == YES)
                {
                    for( DicomSeries *series in s.imageSeries)
                    {
                        if( [DCMAbstractSyntaxUID isImageStorage: series.seriesSOPClassUID] && [DCMAbstractSyntaxUID isPDF: series.seriesSOPClassUID] == NO)
                        {
                            NSManagedObject *o = [[series valueForKey:@"images"] anyObject];
                            
                            @autoreleasepool
                            {
                                DicomFile *dcm = [[DicomFile alloc] init: [o valueForKey:@"completePath"]];
                                
                                if( dcm)
                                {
                                    if( [[dcm elementForKey:@"commentsAutoFill"] length] > [[s valueForKey: commentField] length])
                                        [s setPrimitiveValue: [dcm elementForKey: @"commentsAutoFill"] forKey: commentField];
                                    else
                                        [s setPrimitiveValue: nil forKey: commentField];
                                    
                                    [dcm release];
                                }
                                
                                float p = (float) (x++) / (float) studiesArray.count;
                                [[NSThread currentThread] setProgress: p];
                                
                                if( x % 100 == 0)
                                    [context save: nil];
                            }
                            
                            break;
                        }
                    }
                }
                else
                    [s setPrimitiveValue: 0L forKey: commentField];
            }
            @catch (NSException *exception) {
                N2LogException( exception);
            }
            @finally {
                [s didChangeValueForKey: commentField];
            }
            
            if( [[NSThread currentThread] isCancelled])
                break;
        }
        
        NSArray *seriesArray = [arrays objectForKey: @"seriesArrayIDs"];
        
        int i = 0;
        for( NSManagedObjectID *seriesID in seriesArray)
        {
            @autoreleasepool
            {
                @try
                {
                    DicomSeries *series = (DicomSeries*) [context objectWithID: seriesID];
                    
                    if( [DCMAbstractSyntaxUID isImageStorage: series.seriesSOPClassUID] && [DCMAbstractSyntaxUID isPDF: series.seriesSOPClassUID] == NO)
                    {
                        NSManagedObject *o = [[series valueForKey:@"images"] anyObject];
                        
                        if( commentsAutoFill && seriesLevel)
                        {
                            DicomFile *dcm = [[DicomFile alloc] init: [o valueForKey:@"completePath"]];
                            
                            if( dcm)
                            {
                                if( [dcm elementForKey:@"commentsAutoFill"])
                                {
                                    [series willChangeValueForKey: commentField];
                                    [series setPrimitiveValue: [dcm elementForKey: @"commentsAutoFill"] forKey: commentField];
                                    [series didChangeValueForKey: commentField];
                                    
                                    if( studyLevel)
                                    {
                                        NSManagedObject *study = [series valueForKey: @"study"];
                                        
                                        if( [study valueForKey: commentField] == nil || [[study valueForKey: commentField] isEqualToString:@""])
                                        {
                                            [study willChangeValueForKey: commentField];
                                            [study setPrimitiveValue: [dcm elementForKey: @"commentsAutoFill"] forKey: commentField];
                                            [study didChangeValueForKey: commentField];
                                        }
                                    }
                                }
                                else
                                {
                                    [series willChangeValueForKey: commentField];
                                    [series setPrimitiveValue: 0L forKey: commentField];
                                    [series didChangeValueForKey: commentField];
                                }
                                [dcm release];
                            }
                        }
                        else
                        {
                            [series willChangeValueForKey: commentField];
                            [series setPrimitiveValue: 0L forKey: commentField];
                            [series didChangeValueForKey: commentField];
                        }
                    }
                }
                @catch ( NSException *e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
            }
            
            float p = (float) (i++) / (float) seriesArray.count;
            [[NSThread currentThread] setProgress: p];
            
            if( i % 100 == 0)
                [context save: nil];
            
            if( [[NSThread currentThread] isCancelled])
                break;
        }
        
        [context save: nil];
        
        [self performSelectorOnMainThread: @selector( outlineViewRefresh)  withObject: nil waitUntilDone: NO];
    }
}

- (IBAction) regenerateAutoComments:(id) sender;
{
    if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Regenerate Auto Comments", nil),
                                     NSLocalizedString(@"Are you sure you want to regenerate the comments field? It will delete the existing comments of studies and series.", nil),
                                     NSLocalizedString(@"OK",nil),
                                     NSLocalizedString(@"Cancel",nil),
                                     nil) == NSAlertDefaultReturn)
    {
        NSArray *studiesArray = nil;
        
        if( sender == nil) // Apply to all studies
        {
            // Find all studies
            NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
            [dbRequest setResultType: NSManagedObjectIDResultType];
            [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
            [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
            
            NSError *error = nil;
            
            studiesArray = [self.database.managedObjectContext executeFetchRequest:dbRequest error:&error];
        }
        else
        {
            //            NSMutableArray *objects = [NSMutableArray array];
            NSMutableArray *selectedStudies = [NSMutableArray array];
            
            NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
            if( [databaseOutline selectedRow] >= 0)
            {
                for( int x = 0; x < [selectedRows count] ; x++)
                {
                    NSUInteger row = 0;
                    if( x == 0) row = [selectedRows firstIndex];
                    else row = [selectedRows indexGreaterThanIndex: row];
                    
                    id object = [databaseOutline itemAtRow: row];
                    
                    if( [object isKindOfClass:[DicomStudy class]])
                        [selectedStudies addObject: object];
                    
                    if( [object isKindOfClass:[DicomSeries class]])
                        [selectedStudies addObject: [object valueForKey: @"study"]];
                }
            }
            
            studiesArray = [selectedStudies valueForKey: @"objectID"];
        }
        
        NSArray *seriesArray = nil;
        
        if( sender == nil) // Apply to all studies
        {
            // Find all series
            NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
            [dbRequest setResultType: NSManagedObjectIDResultType];
            [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Series"]];
            [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
            
            NSError *error = nil;
            
            seriesArray = [self.database.managedObjectContext executeFetchRequest:dbRequest error:&error];
        }
        else
        {
            //            NSMutableArray *objects = [NSMutableArray array];
            NSMutableArray *selectedSeries = [NSMutableArray array];
            
            NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
            if( [databaseOutline selectedRow] >= 0)
            {
                for( int x = 0; x < [selectedRows count] ; x++)
                {
                    NSUInteger row = 0;
                    if( x == 0) row = [selectedRows firstIndex];
                    else row = [selectedRows indexGreaterThanIndex: row];
                    
                    NSManagedObject	*object = [databaseOutline itemAtRow: row];
                    
                    if( [object isKindOfClass: [DicomStudy class]])
                        [selectedSeries addObjectsFromArray: [[object valueForKey: @"series"] allObjects]];
                    
                    if( [object isKindOfClass: [DicomSeries class]])
                        [selectedSeries addObject: object];
                }
            }
            
            seriesArray = [selectedSeries valueForKey: @"objectID"];
        }
        
        NSThread *t = nil;
        t = [[[NSThread alloc] initWithTarget: self selector:@selector(regenerateAutoCommentsThread:) object: [NSDictionary dictionaryWithObjectsAndKeys: studiesArray, @"studyArrayIDs", seriesArray, @"seriesArrayIDs", nil]] autorelease];
        
        t.name = NSLocalizedString( @"Regenerate Auto Comments...", nil);
        t.status = N2LocalizedSingularPluralCount( [studiesArray count], NSLocalizedString(@"study", nil), NSLocalizedString(@"studies", nil));
        t.supportsCancel = YES;
        [[ThreadsManager defaultManager] addThreadAndStart: t];
    }
}

- (NSTimeInterval) databaseLastModification // __deprecated
{
    return _database.timeOfLastModification;
}

-(void)setDatabaseLastModification:(NSTimeInterval)t
{
    _database.timeOfLastModification = t;
}

- (NSManagedObjectModel*)managedObjectModel // __deprecated
{
    return self.database.managedObjectModel;
}

- (void)defaultAlbums:(id)sender
{
    [self.database addDefaultAlbums];
    
    @synchronized (self)
    {
        _cachedAlbumsContext = nil;
    }
    
    [self albumsInDatabase];
    
    [self refreshAlbums];
}

// ------------------

- (NSManagedObjectContext*)localManagedObjectContextIndependentContext:(BOOL)independentContext // __deprecated
{
    return [[DicomDatabase activeLocalDatabase] independentContext:independentContext];
}

- (NSManagedObjectContext*)localManagedObjectContext // __deprecated
{
    return [self localManagedObjectContextIndependentContext:NO];
}

// ------------------

- (NSManagedObjectContext*)defaultManagerObjectContext // __deprecated
{
    return [self defaultManagerObjectContextIndependentContext:NO];
}

- (NSManagedObjectContext*)defaultManagerObjectContextIndependentContext:(BOOL)independentContext // __deprecated
{
    return [[DicomDatabase defaultDatabase] independentContext:independentContext];
}

// ------------------

- (NSManagedObjectContext*)managedObjectContext // __deprecated
{
    return [self managedObjectContextIndependentContext:NO];
}

- (NSManagedObjectContext*)managedObjectContextIndependentContext:(BOOL)independentContext // __deprecated
{
    return [self managedObjectContextIndependentContext:independentContext path:_database.baseDirPath];
}

- (NSManagedObjectContext*)managedObjectContextIndependentContext:(BOOL)independentContext path:(NSString*)path // __deprecated
{
    if (!path)
        return nil;
    
    if ([path isEqualToString:_database.baseDirPath])
        return [_database independentContext:independentContext];
    
    N2LogStackTrace( @"******* __deprecated BrowserController managedObjectContextIndependentContext : unknown DicomDatabase");
    
    return [[DicomDatabase existingDatabaseAtPath:path] independentContext:independentContext];
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
            NSString *dstPath = [self.database uniquePathForNewDataFileWithExtension:@"dcm"];
            [data writeToFile:dstPath  atomically:YES];
            [localFiles addObject:dstPath];
        }
    }
    
    // THEN, LOAD THEM
    [self.database addFilesAtPaths:localFiles];
    
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
        [self setDatabase:[DicomDatabase databaseAtPath:filenames.firstObject]];
    }
    else
    {
        NSMutableArray *filenamesWithoutPlugins = [NSMutableArray arrayWithArray: filenames];
        NSMutableArray *pluginsArray = [NSMutableArray array];
        
        for( int i = 0; i < [filenames count]; i++)
        {
            NSString *aPath = [filenames objectAtIndex:i];
            if ([[aPath pathExtension] isEqualToString:@"horosplugin"] || [[aPath pathExtension] isEqualToString:@"osirixplugin"])
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
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self subSelectFilesAndFoldersToAdd:[oPanel.URLs valueForKeyPath:@"path"]];
    }];
}

- (void) checkIfLocalStudyHasMoreOrSameNumberOfImagesOfADistantStudy: (NSArray*) studiesToCheck
{
    if( studiesToCheck == nil) // Take current selected study
    {
        NSManagedObject *item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
        DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
        
        if( studySelected)
            studiesToCheck = [NSArray arrayWithObject: studySelected];
    }
    
#ifndef OSIRIX_LIGHT
    //If PACS On-Demand is activated, check if a local study has more or same number of images of a distant study
    NSMutableArray *patientStudies = [NSMutableArray array];
    
    for( DicomStudy *study in studiesToCheck)
    {
        if( study != (DicomStudy*) [NSNull null] && [patientStudies containsObject: study] == NO && self.comparativePatientUID && [self.comparativePatientUID compare: study.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
            [patientStudies addObject: study];
    }
    
    if( patientStudies.count && self.comparativeStudies.count)
    {
        NSMutableArray *copyComparativeStudies = [NSMutableArray arrayWithArray: self.comparativeStudies];
        BOOL modifications = NO;
        
        for( id distantStudy in [NSArray arrayWithArray: copyComparativeStudies])
        {
            if( [distantStudy isKindOfClass: [DCMTKStudyQueryNode class]])
            {
                DicomStudy *localStudy = nil;
                
                for( DicomStudy *localAddedStudy in patientStudies)
                {
                    if( [localAddedStudy.studyInstanceUID isEqualToString: [distantStudy valueForKey: @"studyInstanceUID"]])
                        localStudy = localAddedStudy;
                }
                
                if( localStudy && [[localStudy rawNoFiles] intValue] >= [[distantStudy noFiles] intValue])
                {
                    modifications = YES;
                    [copyComparativeStudies replaceObjectAtIndex: [copyComparativeStudies indexOfObject: distantStudy] withObject: localStudy];
                }
            }
        }
        
        if( modifications)
            [self refreshComparativeStudies: copyComparativeStudies];
    }
#endif
}

-(void)_observeDatabaseAddNotification:(NSNotification*)notification
{
    if( self.database == nil)
        return;
    
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(_observeDatabaseAddNotification:) withObject:notification waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    else
    {
        [ROIsAndKeyImagesCache release]; ROIsAndKeyImagesCache = nil;
        [ROIsImagesCache release]; ROIsImagesCache = nil;
        [KeyImagesCache release]; KeyImagesCache = nil;
        
        [lastROIsAndKeyImagesSelectedFiles release]; lastROIsAndKeyImagesSelectedFiles = nil;
        [lastROIsImagesSelectedFiles release]; lastROIsImagesSelectedFiles = nil;
        [lastKeyImagesSelectedFiles release]; lastKeyImagesSelectedFiles = nil;
        
        [self outlineViewRefresh];
        [self refreshAlbums];
        
        [self checkIfLocalStudyHasMoreOrSameNumberOfImagesOfADistantStudy: [[notification.userInfo valueForKey: OsirixAddToDBNotificationImagesArray] valueForKeyPath: @"series.study"]];
    }
}

-(void)_refreshDatabaseDisplay
{
    [self outlineViewRefresh];
    [self refreshAlbums];
}

-(void)_observeDatabaseDidChangeContextNotification:(NSNotification*)notification
{
    if (![NSThread isMainThread])
        [self performSelectorOnMainThread:@selector(_observeDatabaseDidChangeContextNotification:) withObject:notification waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    else
    {
        [self outlineViewRefresh];
        [self refreshAlbums];
    }
}

-(void)_observeDatabaseInvalidateAlbumsCacheNotification:(NSNotification*)notification
{
    @synchronized (self)
    {
        _cachedAlbumsContext = nil;
    }
}

-(void)resetToLocalDatabase
{
    [self setDatabase:[DicomDatabase activeLocalDatabase]];
}

+(BOOL)automaticallyNotifiesObserversForKey:(NSString*)key
{
    if ([key isEqualToString:@"database"])
        return NO;
    return [super automaticallyNotifiesObserversForKey:key];
}

-(void) willChangeContext
{
    [self waitForRunningProcesses];
    
    @synchronized( previewPixThumbnails)
    {
        [matrixLoadIconsThread cancel];
        [matrixLoadIconsThread release];
        matrixLoadIconsThread = nil;
    }
    
    self.comparativePatientUID = nil;
    self.comparativeStudies = nil;
    
    @synchronized( smartAlbumDistantArraySync)
    {
        [smartAlbumDistantArray release];
        smartAlbumDistantArray = nil;
    }
    
    [outlineViewArray release];
    outlineViewArray = nil;
    
    [cachedFilesForDatabaseOutlineSelectionSelectedFiles release]; cachedFilesForDatabaseOutlineSelectionSelectedFiles = nil;
    [cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release]; cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = nil;
    [cachedFilesForDatabaseOutlineSelectionTreeObjects release]; cachedFilesForDatabaseOutlineSelectionTreeObjects = nil;
    [cachedFilesForDatabaseOutlineSelectionIndex release]; cachedFilesForDatabaseOutlineSelectionIndex = nil;
    
    [ROIsAndKeyImagesCache release]; ROIsAndKeyImagesCache = nil;
    [ROIsImagesCache release]; ROIsImagesCache = nil;
    [KeyImagesCache release]; KeyImagesCache = nil;
    
    [lastROIsAndKeyImagesSelectedFiles release]; lastROIsAndKeyImagesSelectedFiles = nil;
    [lastROIsImagesSelectedFiles release]; lastROIsImagesSelectedFiles = nil;
    [lastKeyImagesSelectedFiles release]; lastKeyImagesSelectedFiles = nil;
    
    @synchronized (self)
    {
        _cachedAlbumsContext = nil;
    }
    
    [databaseOutline reloadData];
    [albumTable reloadData];
    [comparativeTable reloadData];
}

-(void)setDatabase:(DicomDatabase*)db
{
    [[db retain] autorelease]; // avoid multithreaded release
    
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"setDatabase MUST be performed on MAIN thread");
    
    if (_database != db)
    {
        @try
        {
            [[LogManager currentLogManager] resetLogs];
            
            [self willChangeValueForKey:@"database"];
            
            [self saveLoadAlbumsSortDescriptors];
            
            [self waitForRunningProcesses];
            
            [_database save:nil];
            [_database autorelease]; _database = nil;
            
            [self willChangeContext];
            
            [reportFilesToCheck removeAllObjects];
            
            if (_database)
                [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_database];
            
            [self.window display];
            
            [DCMPix purgeCachedDictionaries];
            [DCMView purgeStringTextureCache];
            
            [self resetLogWindowController];
            
            [[AppController sharedAppController] closeAllViewers: self];
            
            @try
            {
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"clearSearchAndTimeIntervalWhenSelectingAlbum"])
                    [self showEntireDatabase];
            }
            @catch (...) {
            }
            
            _database = [db retain];
            [_database renewManagedObjectContext]; // We want to be sure to use our 'clean' managedobjectcontext (not used in any other threads)
            
            if ([NSUserDefaults canActivateAnyLocalDatabase] && [db isLocal] && ![db isReadOnly])
                [DicomDatabase setActiveLocalDatabase:db];
            if (db)
                [self selectCurrentDatabaseSource];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeDatabaseAddNotification:) name:_O2AddToDBAnywayNotification object:_database];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeDatabaseDidChangeContextNotification:) name:OsirixDicomDatabaseDidChangeContextNotification object:_database];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_observeDatabaseInvalidateAlbumsCacheNotification:) name:O2DatabaseInvalidateAlbumsCacheNotification object:_database];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newStudiesRefreshComparativeStudies:) name:OsirixAddNewStudiesDBNotification object:_database];
            
            [albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
            [self saveLoadAlbumsSortDescriptors];
            
            @synchronized(_albumNoOfStudiesCache)
            {
                [_albumNoOfStudiesCache removeAllObjects];
                [_distantAlbumNoOfStudiesCache removeAllObjects];
            }
            
            [[_database managedObjectContext] lock];
            @try
            {
                [databaseOutline reloadData];
                [albumTable reloadData];
                [comparativeTable reloadData];
                
                [self.window display];
                [self setDBWindowTitle];
                [self refreshPACSOnDemandResults: self];
                
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
            }
            @catch (NSException* e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            @finally
            {
                [[_database managedObjectContext] unlock];
            }
            
            [[LogManager currentLogManager] resetLogs];
        }
        @catch (...)
        {
            @throw;
        }
        @finally
        {
            [self didChangeValueForKey:@"database"];
        }
    }
}

-(void)openDatabaseIn:(NSString*)a Bonjour:(BOOL)isBonjour // __deprecated
{
    [self openDatabaseIn:a Bonjour:isBonjour refresh:NO];
}

-(void)openDatabaseIn:(NSString*)a Bonjour:(BOOL)isBonjour refresh:(BOOL)refresh // __deprecated
{
    if (isBonjour) [NSException raise:NSGenericException format:@"TODO do something smart :P"]; // TODO: hmmm
    DicomDatabase* db = isBonjour? nil : [DicomDatabase databaseAtPath:a];
    [self setDatabase:db];
}


- (void)openDatabaseInBonjour:(NSString*)path __deprecated {
    [self openDatabaseIn:path Bonjour:YES refresh:YES];
}

-(IBAction)openDatabase:(id)sender
{
    NSOpenPanel* oPanel	= [NSOpenPanel openPanel];
    oPanel.allowedFileTypes = @[@"sql"];
    oPanel.directoryURL = [NSURL fileURLWithPath:_database.sqlFilePath];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        if (oPanel.URL && ![_database.sqlFilePath isEqualToString:oPanel.URL.path])
        {
            self.database = [DicomDatabase databaseAtPath:oPanel.URL.path];
        }
    }];
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
    
    oPanel.directoryURL = [NSURL fileURLWithPath:[self.database.baseDirPath stringByDeletingLastPathComponent]];
    
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        NSString *location = oPanel.URL.path;
        
        if( [[location lastPathComponent] isEqualToString:@"Horos Data"])
            location = [location stringByDeletingLastPathComponent];
        
        if( [[location lastPathComponent] isEqualToString:@"DATABASE.noindex"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"Horos Data"])
            location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        
        [self openDatabasePath: location];
    }];
}

- (void)showEntireDatabase
{
    self.timeIntervalType = 0;
    self.modalityFilter = nil;
    
    [albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
    self.searchString = @"";
}

- (void)setDBWindowTitle
{
    [self.window setTitle: _database? [_database name] : @""];
    
    if( [_database.baseDirPath hasPrefix: @"/tmp/"] || _database.isLocal == NO)
    {
        if( _database.sourcePath.length)
            [self.window setRepresentedFilename: _database.sourcePath];
        else
            [self.window setRepresentedFilename: @""];
    }else
        [self.window setRepresentedFilename: _database? _database.baseDirPath : @""];
}

- (NSString*)getDatabaseFolderFor: (NSString*)path // __deprecated
{
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
            NSString	*index = [[path stringByAppendingPathComponent:@"Horos Data"] stringByAppendingPathComponent:@"Database.sql"];
            
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

-(BOOL)isBonjour:(NSManagedObjectContext*)c // __deprecated
{
    DicomDatabase* db = [DicomDatabase databaseForContext:c];
    return ![db isLocal];
}

-(void)loadDatabase:(NSString*)path // __deprecated
{
    [self setDatabase:[DicomDatabase databaseAtPath:path]];
}

-(long)saveDatabase:(NSString*)path context:(NSManagedObjectContext*)context // __deprecated
{
    NSError* err = nil;
    DicomDatabase* database = [DicomDatabase databaseForContext:context];
    [database save:&err];
    return [err code];
}

// TODO: #pragma we know saveDatabase:context: is deprecated
-(long)saveDatabase // __deprecated
{
    return [self saveDatabase:nil context:self.database.managedObjectContext];
}

// TODO: #pragma we know saveDatabase:context: is deprecated
-(long)saveDatabase:(NSString*)path // __deprecated
{
    return [self saveDatabase:path context:self.database.managedObjectContext];
}

-(void)selectStudyWithObjectID:(NSManagedObjectID*)oid
{
    NSManagedObject* s = [self.database objectWithID:oid];
    DicomStudy *study = nil;
    
    if( [s isKindOfClass: [DicomStudy class]])
        study = (DicomStudy*) s;
    
    if( [s isKindOfClass: [DicomSeries class]])
        study = [s valueForKey: @"study"];
    
    if( [s isKindOfClass: [DicomImage class]])
        study = [s valueForKeyPath: @"series.study"];
    
    if( study)
        [self selectThisStudy: study];
}

- (BOOL) selectThisStudy: (NSManagedObject*)study
{
    if( self.database == nil)
        return NO;
    
    if( study == nil)
        return NO;
    
    @try {
        NSManagedObject *item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
        DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
        
        if( [[study valueForKey: @"studyInstanceUID"] isEqualToString: [studySelected valueForKey: @"studyInstanceUID"]])
            return YES;
        
        if( [study isKindOfClass: [DicomStudy class]])
        {
            NSPersistentStoreCoordinator *sps = study.managedObjectContext.persistentStoreCoordinator;
            NSPersistentStoreCoordinator *dps = self.database.managedObjectContext.persistentStoreCoordinator;
            
            if( sps != nil)
            {
                if( sps != dps) // another database is selected, select the destination DB
                {
                    DicomDatabase *db = [DicomDatabase databaseForContext: [study managedObjectContext]];
                    
                    if( db)
                        [self setDatabase: db];
                    else
                        return NO;
                }
            }
            else return NO;
        }
        
        [self outlineViewRefresh];
        
        NSUInteger studyIndex = [[outlineViewArray valueForKey: @"studyInstanceUID"] indexOfObject: [study valueForKey: @"studyInstanceUID"]]; // We can have DicomStudy OR DCMTKQueryStudyNode... : search with studyInstanceUID
        NSInteger rowIndex = -1;
        
        if( studyIndex != NSNotFound)
            rowIndex = [databaseOutline rowForItem: [outlineViewArray objectAtIndex: studyIndex]];
        
        if( studyIndex == NSNotFound && (albumTable.selectedRow > 0 || self.searchString.length > 0 || self.timeIntervalType != 0))
        {
            if( [study isKindOfClass: [DicomStudy class]]) // It's a local study: we HAVE to find it ! Select the entire DB
            {
                [self showEntireDatabase];
                [self outlineViewRefresh];
                
                NSUInteger studyIndex = [[outlineViewArray valueForKey: @"studyInstanceUID"] indexOfObject: [study valueForKey: @"studyInstanceUID"]]; // We can have DicomStudy OR DCMTKQueryStudyNode... : search with studyInstanceUID
                if( studyIndex != NSNotFound)
                    rowIndex = [databaseOutline rowForItem: [outlineViewArray objectAtIndex: studyIndex]];
            }
        }
        
        if (rowIndex != -1)
        {
            [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: rowIndex] byExtendingSelection: NO];
            [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
            
            return YES;
        }
    }
    @catch ( NSException *e) {
        N2LogException( e);
    }
    
    return NO;
}

- (void) copyFilesThread: (NSDictionary*) dict
{
    [self.database performSelector:@selector(copyFilesThread:) withObject:dict];
}

- (IBAction) copyToDBFolder: (id) sender
{
    BOOL matrixThumbnails = NO;
    
    if (![_database isLocal]) return;
    
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
    
    //	[_database lock];
    
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
                    extension = @"dcm";
                
                if( [extension isEqualToString:@""])
                    extension = @"dcm";
                
                NSString *dstPath = [self.database uniquePathForNewDataFileWithExtension:extension];
                
                if( [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:NULL])
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
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        //		[_database unlock];
    }
    [splash close];
    [splash autorelease];
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
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    for( NSString *file in filesInput)
    {
        if( [[file commonPrefixWithString: INpath options: NSLiteralSearch] isEqualToString:INpath] == NO)
            [newFilesToCopyList addObject: file];
    }
    [pool release];
    
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
                                                     NSLocalizedString(@"Horos Database", nil),
                                                     NSLocalizedString(@"Should I copy these files in Horos Database folder, or only copy links to these files?", nil),
                                                     NSLocalizedString(@"Copy Files", nil),
                                                     NSLocalizedString(@"Cancel", nil),
                                                     NSLocalizedString(@"Copy Links", nil)))
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
    
    NSMutableArray *filesOutput = [NSMutableArray array];
    
    if( copyFiles)
    {
        NSString *OUTpath = [_database dataDirPath];
        
        [[NSFileManager defaultManager] confirmNoIndexDirectoryAtPath:OUTpath];
        
        if( [[options objectForKey: @"async"] boolValue])
        {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: filesInput, @"filesInput", [NSNumber numberWithBool: YES], @"copyFiles", [NSNumber numberWithBool: [[options objectForKey: @"mountedVolume"] boolValue]], @"mountedVolume", nil];
            [dict addEntriesFromDictionary: options];
            
            NSThread *t = nil;
            if( [NSThread isMainThread] == NO)
                t = [[[NSThread alloc] initWithTarget:_database.independentDatabase selector:@selector(copyFilesThread:) object: dict] autorelease];
            else
                t = [[[NSThread alloc] initWithTarget:_database selector:@selector(copyFilesThread:) object: dict] autorelease];
            
            if( [[options objectForKey: @"mountedVolume"] boolValue]) t.name = NSLocalizedString( @"Copying and indexing files from CD/DVD...", nil);
            else t.name = NSLocalizedString( @"Copying and indexing files...", nil);
            t.status = N2LocalizedSingularPluralCount( [filesInput count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
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
                                extension = @"dcm";
                            
                            if( [extension isEqualToString:@""])
                                extension = @"dcm";
                            
                            if( [extension length] > 4 || [extension length] < 3)
                                extension = @"dcm";
                            
                            NSString *dstPath = [self.database uniquePathForNewDataFileWithExtension:extension];
                            
                            if( [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:NULL] == YES)
                            {
                                [filesOutput addObject:dstPath];
                            }
                            
                            if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
                            {
                                [[NSFileManager defaultManager] copyItemAtPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] error:NULL];
                            }
                            
                            [curFile release];
                            curFile = nil;
                        }
                        else NSLog( @"**** DicomFile *curFile = nil");
                    }
                }
                @catch (NSException * e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
                @finally {
                    [pool release];
                }
                [splash incrementBy:1];
                
                if( [splash aborted])
                    break;
            }
            
            [splash close];
            [splash autorelease];
        }
    }
    else
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: filesInput, @"filesInput", [NSNumber numberWithBool: NO], @"copyFiles", [NSNumber numberWithBool: [[options objectForKey: @"mountedVolume"] boolValue]], @"mountedVolume", nil];
        
        
        [dict addEntriesFromDictionary: options];
        
        NSThread *t = [[[NSThread alloc] initWithTarget:_database selector:@selector(copyFilesThread:) object: dict] autorelease];
        
        if( [[options objectForKey: @"mountedVolume"] boolValue]) t.name = NSLocalizedString( @"Indexing files from CD/DVD...", nil);
        else t.name = NSLocalizedString( @"Indexing files...", nil);
        t.status = N2LocalizedSingularPluralCount( [filesInput count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
        t.supportsCancel = YES;
        [[ThreadsManager defaultManager] addThreadAndStart: t];
        
        filesOutput = filesInput;
    }
    
    return;
}

-(void)rebuildDatabaseThread:(NSArray*)io
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try
    {
        if( self.database != nil)
            NSLog( @"****** WARNING we should not be here if self.database != nil");
        
        DicomDatabase* database = [io objectAtIndex:0];
        BOOL complete = [[io objectAtIndex:1] boolValue];
        [database.independentDatabase rebuild:complete];
        [self performSelectorOnMainThread:@selector(setDatabase:) withObject:database waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [pool release];
    }
}

-(NSThread*)initiateRebuildDatabase:(BOOL)complete
{
    DicomDatabase* database = [[self.database retain] autorelease];
    
    [self setDatabase:nil];
    
    NSArray* io = [NSMutableArray arrayWithObjects: database, [NSNumber numberWithBool:complete], nil];
    
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(rebuildDatabaseThread:) object:io];
    thread.name = NSLocalizedString(@"Rebuilding database...", nil);
    
    [thread startModalForWindow:self.window];
    [thread start];
    
    return [thread autorelease];
}

- (IBAction)endReBuildDatabase:(id)sender
{
    [NSApp endSheet: rebuildWindow];
    [rebuildWindow orderOut: self];
    
    if ([sender tag])
    {
        for (NSThread* t in [[ThreadsManager defaultManager] threads])
            [t cancel];
        
        [self waitForRunningProcesses];
        
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        while ([[[ThreadsManager defaultManager] threads] count] && [NSDate timeIntervalSinceReferenceDate]-t < 10) { // give declared background threads 10 secs to cancel
            for (NSThread* thread in [[ThreadsManager defaultManager] threads])
                if (![thread isCancelled])
                    [thread cancel];
            [NSThread sleepForTimeInterval:0.05];
        }
        
        switch ([rebuildType selectedTag])
        {
            case 0:
                [self initiateRebuildDatabase:YES];
                break;
                
            case 1:
                [self initiateRebuildDatabase:NO];
                break;
        }
    }
}

- (IBAction) ReBuildDatabaseSheet: (id)sender
{
    if (![_database rebuildAllowed])
        [NSException raise:NSGenericException format:@"Current database rebuild not allowed, this shouldn't be executed."];
    
    long totalFiles = 0;
    NSString	*aPath = [_database dataDirPath];
    NSArray	*dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:aPath error:NULL];
    for(NSString *name in dirContent)
    {
        NSString * itemPath = [aPath stringByAppendingPathComponent: name];
        totalFiles += [[[[NSFileManager defaultManager] attributesOfItemAtPath:itemPath error:NULL] objectForKey: NSFileReferenceCount] intValue];
    }
    
    [noOfFilesToRebuild setIntValue: totalFiles];
    
    long durationFor1000 = 9;
    
    long totalSeconds = totalFiles * durationFor1000 / 1000;
    [estimatedTime setStringValue:[NSString timeString:totalSeconds maxUnits:2]];
    
    [[AppController sharedAppController] closeAllViewers: self];
    
    [NSApp beginSheet: rebuildWindow
       modalForWindow: self.window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
}

-(void)rebuildSqlThread:(DicomDatabase*)database
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try
    {
        [database rebuildSqlFile];
        [self performSelectorOnMainThread:@selector(setDatabase:) withObject:database waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [pool release];
    }
}

-(NSThread*)initiateRebuildSql
{
    DicomDatabase* database = [[self.database retain] autorelease];
    [self setDatabase:nil];
    [self outlineViewRefresh];
    
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(rebuildSqlThread:) object:database];
    thread.name = NSLocalizedString(@"Rebuilding database index...", nil);
    
    [thread start];
    [thread startModalForWindow:self.window];
    
    return [thread autorelease];
}

-(void)_rebuildSqlSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [NSApp endSheet:sheet];
    [sheet orderOut:self];
    if (returnCode == NSAlertDefaultReturn)
        [self initiateRebuildSql];
}

-(IBAction)rebuildSQLFile:(id)sender
{
    if (![_database rebuildAllowed])
        [NSException raise:NSGenericException format:@"Current database rebuild not allowed, this shouldn't be executed."];
    NSBeginInformationalAlertSheet(nil, nil, NSLocalizedString(@"Cancel", nil), nil, self.window, self, @selector(_rebuildSqlSheetDidEnd:returnCode:contextInfo:), nil, nil, NSLocalizedString(@"Are you sure you want to rebuild this database's SQL index? This operation can take several minutes.", nil));
}

- (void) autoCleanDatabaseDate: (id)sender // __deprecated
{
    [_database cleanOldStuff];
}

+ (BOOL) isHardDiskFull // __deprecated
{
    return [[DicomDatabase activeLocalDatabase] isFileSystemFreeSizeLimitReached];
}

- (void) autoCleanDatabaseFreeSpaceWarning: (NSString*) message
{
    NSRunCriticalAlertPanel( NSLocalizedString(@"Warning", nil),  @"%@", NSLocalizedString(@"OK",nil), nil, nil, message);
}

- (void) autoCleanDatabaseFreeSpace: (id)sender // __deprecated
{
    [_database initiateCleanUnlessAlreadyCleaning];
}

#pragma mark-
#pragma mark Web Portal Database // deprecated, use WebPortal.defaultWebPortal

-(long)saveUserDatabase // __deprecated
{
#ifndef OSIRIX_LIGHT
    [[[WebPortal defaultWebPortal] database] save:NULL];
#endif
    return 0;
}

-(NSManagedObjectModel*)userManagedObjectModel // __deprecated
{
#ifndef OSIRIX_LIGHT
    return [[[WebPortal defaultWebPortal] database] managedObjectModel];
#else
    return NULL;
#endif
}

-(NSManagedObjectContext*)userManagedObjectContext // __deprecated
{
#ifndef OSIRIX_LIGHT
    return [[[WebPortal defaultWebPortal] database] managedObjectContext];
#else
    return NULL;
#endif
}

-(WebPortalUser*)userWithName:(NSString*)name // __deprecated
{
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
    
    for( long i = 0; i < [[sender menu] numberOfItems]; i++)
        [[[sender menu] itemAtIndex: i] setState: NSOffState];
    
    [[searchField cell] setPlaceholderString: [[[sender menu] itemWithTag: [sender tag]] title]];
    
    [[[sender menu] itemWithTag: [sender tag]] setState: NSOnState];
    [toolbarSearchItem setLabel: [NSString stringWithFormat: NSLocalizedString(@"Search by %@", nil), [sender title]]];
    searchType = [sender tag];
    
    //create new Filter Predicate when changing searchType ans set searchString to nil;
    [self setSearchString:nil];
    [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
    
    if( _searchString.length > 2 || (_searchString.length >= 2 && searchType == 5))
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
        
        [NSThread detachNewThreadSelector: @selector(searchForSearchField:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: searchType], @"searchType", _searchString, @"searchString", [NSNumber numberWithInt: albumTable.selectedRow], @"selectedAlbumIndex", nil]];
    }
    else if( timeIntervalStart || timeIntervalEnd)
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
        
        if( albumTable.selectedRow == 0)
            [NSThread detachNewThreadSelector: @selector(searchForTimeIntervalFromTo:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: timeIntervalStart, @"from", timeIntervalEnd, @"to", nil]];
    }
    else
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger: [sender tag] forKey:@"searchType"];
}

- (void) computeTimeInterval
{
    switch( self.timeIntervalType)
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
            [timeIntervalStart release];
            [timeIntervalEnd release];
            timeIntervalStart = [[CustomIntervalPanel sharedCustomIntervalPanel].fromDate copy];
            timeIntervalEnd = [[CustomIntervalPanel sharedCustomIntervalPanel].toDate copy];
            break;
    }
    
    if( timeIntervalStart || timeIntervalEnd)
    {
        if( [timeIntervalStart isEqualToDate: self.distantTimeIntervalStart] == NO || (timeIntervalEnd != nil && [timeIntervalEnd isEqualToDate: self.distantTimeIntervalEnd] == NO))
        {
            @synchronized( self)
            {
                [distantSearchThread cancel];
                [distantSearchThread release];
                distantSearchThread = nil;
            }
            
            if( albumTable.selectedRow == 0)
                [NSThread detachNewThreadSelector: @selector(searchForTimeIntervalFromTo:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: timeIntervalStart, @"from", timeIntervalEnd, @"to", nil]];
        }
    }
    else if( _searchString.length > 2 || (_searchString.length >= 2 && searchType == 5))
        [self setSearchString: _searchString];
    else
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
    }
}

- (void) setTimeIntervalType: (int) t
{
    [self willChangeValueForKey: @"timeIntervalType"];
    timeIntervalType = t;
    [self didChangeValueForKey: @"timeIntervalType"];
    
    if( t == 100)
        [[[CustomIntervalPanel sharedCustomIntervalPanel] window] makeKeyAndOrderFront: self];
    
    [self computeTimeInterval];
    [self outlineViewRefresh];
}

- (void) setModalityFilter:(NSString *) m
{
    if( m == nil)
        m = [[modalityFilterMenu itemAtIndex: 0] title];
    
    [self willChangeValueForKey: @"modalityFilter"];
    modalityFilter = m;
    [self didChangeValueForKey: @"modalityFilter"];
    
    self.distantTimeIntervalStart = nil;
    self.distantTimeIntervalEnd = nil;
    [self computeTimeInterval]; // Yes, this is normal : modality filter is only available if a time interval is selected for PACS On-Demand
    [self outlineViewRefresh];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark OutlineView functions

- (NSPredicate*) smartAlbumPredicateString:(NSString*) string
{
    if( string == nil || [string length] == 0)
        return [NSPredicate predicateWithValue: YES];
    
    NSMutableString *pred = [NSMutableString stringWithString: string];
    
    NSCalendarDate	*now = [NSCalendarDate calendarDate];
    NSDate	*start = [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]] timeIntervalSinceReferenceDate]];
    
    NSDictionary	*sub = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithFormat:@"%lf", [[now dateByAddingTimeInterval: -60*60*1] timeIntervalSinceReferenceDate]],			@"$LASTHOUR",
                            [NSString stringWithFormat:@"%lf", [[now dateByAddingTimeInterval: -60*60*6] timeIntervalSinceReferenceDate]],			@"$LAST6HOURS",
                            [NSString stringWithFormat:@"%lf", [[now dateByAddingTimeInterval: -60*60*12] timeIntervalSinceReferenceDate]],			@"$LAST12HOURS",
                            [NSString stringWithFormat:@"%lf", [start timeIntervalSinceReferenceDate]],										@"$TODAY",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24] timeIntervalSinceReferenceDate]],			@"$YESTERDAY",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*2] timeIntervalSinceReferenceDate]],		@"$2DAYS",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*7] timeIntervalSinceReferenceDate]],		@"$WEEK",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*31] timeIntervalSinceReferenceDate]],		@"$MONTH",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*31*2] timeIntervalSinceReferenceDate]],	@"$2MONTHS",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*31*3] timeIntervalSinceReferenceDate]],	@"$3MONTHS",
                            [NSString stringWithFormat:@"%lf", [[start dateByAddingTimeInterval: -60*60*24*365] timeIntervalSinceReferenceDate]],		@"$YEAR",
                            nil];
    
    NSEnumerator *enumerator = [sub keyEnumerator];
    NSString *key;
    
    while ((key = [enumerator nextObject]))
    {
        [pred replaceOccurrencesOfString:key withString: [sub valueForKey: key]	options: NSCaseInsensitiveSearch range:pred.range];
    }
    
    NSPredicate *predicate;
    
    if( [string isEqualToString:@""])
        predicate = [NSPredicate predicateWithValue: YES];
    else
        predicate = [NSPredicate predicateWithFormat: pred];
    
    predicate = [predicate predicateWithSubstitutionVariables: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                [now dateByAddingTimeInterval: -60*60*1],			@"NSDATE_LASTHOUR",
                                                                [now dateByAddingTimeInterval: -60*60*6],			@"NSDATE_LAST6HOURS",
                                                                [now dateByAddingTimeInterval: -60*60*12],			@"NSDATE_LAST12HOURS",
                                                                start,                                              @"NSDATE_TODAY",
                                                                [start dateByAddingTimeInterval: -60*60*24],        @"NSDATE_YESTERDAY",
                                                                [start dateByAddingTimeInterval: -60*60*24*2],		@"NSDATE_2DAYS",
                                                                [start dateByAddingTimeInterval: -60*60*24*7],		@"NSDATE_WEEK",
                                                                [start dateByAddingTimeInterval: -60*60*24*31],		@"NSDATE_MONTH",
                                                                [start dateByAddingTimeInterval: -60*60*24*31*2],	@"NSDATE_2MONTHS",
                                                                [start dateByAddingTimeInterval: -60*60*24*31*3],	@"NSDATE_3MONTHS",
                                                                [start dateByAddingTimeInterval: -60*60*24*365],    @"NSDATE_YEAR",
                                                                nil]];
    
    return predicate;
}

- (IBAction)selectNoAlbums:(id)sender
{
    BOOL copyClearSearchAndTimeIntervalWhenSelectingAlbum = [[NSUserDefaults standardUserDefaults] boolForKey: @"clearSearchAndTimeIntervalWhenSelectingAlbum"];
    
    [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"clearSearchAndTimeIntervalWhenSelectingAlbum"];
    
    [albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
    
    [[NSUserDefaults standardUserDefaults] setBool: copyClearSearchAndTimeIntervalWhenSelectingAlbum forKey: @"clearSearchAndTimeIntervalWhenSelectingAlbum"];
}

- (void) selectAlbumWithName: (NSString*) name
{
    for( DicomAlbum *album in _database.albums)
    {
        if( [album.name isEqualToString: name])
        {
            if( [self.albumArray indexOfObject:album] != NSNotFound)
                [albumTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.albumArray indexOfObject:album]] byExtendingSelection:NO];
        }
    }
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
        N2LogExceptionWithStackTrace(ne/*, @"filter error"*/);
    }
    
    return pred;
}

- (void) refreshEntireDBResult
{
    if( distantEntireDBResultCount > outlineViewArray.count || localEntireDBResultCount > outlineViewArray.count)
    {
        [searchInEntireDBResult setTitle: N2LocalizedSingularPluralCount( ((distantEntireDBResultCount > localEntireDBResultCount) ? distantEntireDBResultCount : localEntireDBResultCount), NSLocalizedString(@"result in entire DB", @"Try to keep this string **short**"), NSLocalizedString(@"results in entire DB", @"Try to keep this string **short**"))];
        
        [searchInEntireDBResult setHidden: NO];
    }
    else
        [searchInEntireDBResult setHidden: YES];
}

- (NSString*) outlineViewRefresh		// This function creates the 'root' array for the outlineView
{
    @synchronized (self)
    {
        _cachedAlbumsContext = nil;
    }
    
    if( databaseOutline == nil) return nil;
    if( loadingIsOver == NO) return nil;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
    {
        if( [[self window] isVisible] == NO) return nil;
    }
    
    if( [NSThread isMainThread] == NO)
        NSLog( @"******* We HAVE TO be in main thread !");
    
    NSError				*error =nil;
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
    
    //	if( displayEmptyDatabase)
    //		predicate = [NSPredicate predicateWithValue:NO];
    
    if( [_sourcesTableView selectedRow] >= 0)
    {
        DataNodeIdentifier* bs = [self sourceIdentifierAtRow: [_sourcesTableView selectedRow]];
        
        if( bs)
            description = [description stringByAppendingFormat:NSLocalizedString(@"%@: %@ / ", nil), [_database isLocal] ? NSLocalizedString( @"Local Database: ", nil) : NSLocalizedString( @"Distant Database: ", nil), [bs description]];
    }
    
    // ********************
    // ALBUMS
    // ********************
    NSString *smartAlbumName = nil;
    
    if( albumTable.selectedRow > 0)
    {
        NSArray	*albumArray = self.albumArray;
        
        if( [albumArray count] > albumTable.selectedRow)
        {
            NSManagedObject	*album = [albumArray objectAtIndex: albumTable.selectedRow];
            
            if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
            {
                smartAlbumName = [album valueForKey:@"name"];
                albumArrayContent = [_database objectsForEntity: _database.studyEntity predicate:[self smartAlbumPredicate: album]];
                description = [description stringByAppendingFormat:NSLocalizedString(@"Smart Album selected: %@", nil), smartAlbumName];
            }
            else
            {
                albumArrayContent = [[album valueForKey:@"studies"] allObjects];
                description = [description stringByAppendingFormat:NSLocalizedString(@"Album selected: %@", nil), [album valueForKey:@"name"]];
            }
        }
    }
    else description = [description stringByAppendingString: NSLocalizedString(@"No album selected", nil)];
    
    // ********************
    // TIME INTERVAL
    // ********************
    
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
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: subPredicate, predicate, nil]];
        filtered = YES;
    }
    
    // ********************
    // MODALITY FILTER
    // ********************
    
    if( [modalityFilterMenu indexOfSelectedItem] > 0 && self.modalityFilter.length)
    {
        subPredicate = [NSPredicate predicateWithFormat: @"modality CONTAINS %@", self.modalityFilter];
        
        description = [description stringByAppendingFormat: NSLocalizedString(@" / Modality: %@", nil), self.modalityFilter];
        
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: subPredicate, predicate, nil]];
        filtered = YES;
    }
    
    // ********************
    // SEARCH FIELD
    // ********************
    
    if( self.filterPredicate)
    {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: self.filterPredicate, predicate, nil]];
        description = [description stringByAppendingString: self.filterPredicateDescription];
        filtered = YES;
    }
    
    if( testPredicate)
        predicate = testPredicate;
    
    if( predicate == nil)
        predicate = [NSPredicate predicateWithValue: YES];
    
    //	[_database lock];
    error = nil;
    [outlineViewArray release];
    outlineViewArray = nil;
    @try
    {
        @try
        {
            [searchInEntireDBResult setHidden: YES];
            
            if( albumArrayContent)
            {
                outlineViewArray = [albumArrayContent filteredArrayUsingPredicate:predicate];
                
                if( self.filterPredicate)
                {
                    // Entire DB Result
                    
                    distantEntireDBResultCount = 0;
                    localEntireDBResultCount = [[[_database objectsForEntity:_database.studyEntity predicate:nil error:&error] filteredArrayUsingPredicate: self.filterPredicate] count];
                    
                    [self refreshEntireDBResult];
                }
            }
            else
                outlineViewArray = [[_database objectsForEntity:_database.studyEntity predicate:nil error:&error] filteredArrayUsingPredicate:predicate];
        }
        @catch( NSException *ne)
        {
            outlineViewArray = [NSArray array];
            N2LogExceptionWithStackTrace(ne);
        }
        
        if( error)
            NSLog( @"**** executeFetchRequest: %@", error);
        
        // Smart Album Distant Studies, if available
        @synchronized( self)
        {
            BOOL useDistantArray = NO;
            
            if( smartAlbumDistantArray && smartAlbumName && [self.smartAlbumDistantName isEqualToString: smartAlbumName])
                useDistantArray = YES;
            else if( timeIntervalStart != nil || timeIntervalEnd != nil || self.filterPredicate) // No smart album selected, but time interval or search field
            {
                if( timeIntervalStart != nil || timeIntervalEnd != nil) // Search for the time interval, then apply the search field, if necessary
                {
                    if( [self.distantTimeIntervalStart isEqualToDate: timeIntervalStart] && (timeIntervalEnd == nil || [self.distantTimeIntervalEnd isEqualToDate: timeIntervalEnd]))
                        useDistantArray = YES;
                }
                
                if( self.distantSearchType == searchType && [self.distantSearchString isEqualToString: _searchString])
                    useDistantArray = YES;
            }
            
            if( useDistantArray)
            {
                NSMutableArray *distantStudies = [NSMutableArray array];
                
                NSArray *filteredAlbumDistantStudies = nil;
                @synchronized( smartAlbumDistantArraySync)
                {
                    filteredAlbumDistantStudies = [smartAlbumDistantArray filteredArrayUsingPredicate: predicate];
                }
                
                // Merge local and distant studies
#ifndef OSIRIX_LIGHT
                
                // Autoretrieve?
                NSMutableArray *studyToAutoretrieve = [NSMutableArray array];
                BOOL autoretrieve = NO;
                
                if( autoretrievingPACSOnDemandSmartAlbum == NO)
                {
                    for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"])
                    {
                        if( [[d valueForKey: @"autoretrieve"] boolValue] && [smartAlbumName isEqualToString: [d valueForKey: @"name"]])
                            autoretrieve = YES;
                    }
                }
                
                NSMutableArray *localStudyInstanceUIDs = [outlineViewArray valueForKey: @"studyInstanceUID"];
                for( DCMTKStudyQueryNode *distantStudy in filteredAlbumDistantStudies)
                {
                    if( [localStudyInstanceUIDs containsObject: [distantStudy studyInstanceUID]] == NO)
                    {
                        [distantStudies addObject: distantStudy];
                        
                        if( autoretrieve)
                            [studyToAutoretrieve addObject: distantStudy];
                    }
                    else if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preferStudyWithMoreImages"])
                    {
                        BOOL inTheRetrieveQueue = NO;
                        
                        //Is this study in the retrieve queue? Display the local study
                        @synchronized( comparativeRetrieveQueue)
                        {
                            inTheRetrieveQueue = [[comparativeRetrieveQueue valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]];
                        }
                        
                        if( inTheRetrieveQueue == NO)
                        {
                            NSUInteger index = [localStudyInstanceUIDs indexOfObject: [distantStudy studyInstanceUID]];
                            
                            if( index != NSNotFound && [[[outlineViewArray objectAtIndex: index] rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
                            {
                                if( autoretrieve || [[NSUserDefaults standardUserDefaults] boolForKey: @"automaticallyRetrievePartialStudies"])
                                    [studyToAutoretrieve addObject: distantStudy];
                                else
                                {
                                    NSMutableArray *mutableCopy = [[outlineViewArray mutableCopy] autorelease];
                                    [mutableCopy replaceObjectAtIndex: index withObject: distantStudy];
                                    outlineViewArray = mutableCopy;
                                }
                            }
                        }
                    }
                }
                
                @synchronized (_albumNoOfStudiesCache)
                {
                    if( smartAlbumName && filtered == NO && [smartAlbumDistantName isEqualToString: smartAlbumName]) // filtered == NO, we want only if ALL studies are displayed (not limited by Search String or Time Interval, for example
                        [_distantAlbumNoOfStudiesCache setObject: distantStudies forKey: smartAlbumName];
                }
                
                if( autoretrievingPACSOnDemandSmartAlbum == NO && studyToAutoretrieve.count)
                {
                    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(autoretrievePACSOnDemandSmartAlbum:) object: studyToAutoretrieve] autorelease];
                    t.name = NSLocalizedString( @"Auto-Retrieving...", nil);
                    t.supportsCancel = YES;
                    [[ThreadsManager defaultManager] addThreadAndStart: t];
                }
                
#endif
                
                if( [distantStudies count])
                    outlineViewArray = [outlineViewArray arrayByAddingObjectsFromArray: distantStudies];
            }
        }
        
        @synchronized (_albumNoOfStudiesCache)
        {
            if ([_albumNoOfStudiesCache count] > albumTable.selectedRow && filtered == NO)
            {
                [_albumNoOfStudiesCache replaceObjectAtIndex:albumTable.selectedRow withObject:[decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:[outlineViewArray count]]]];
                [albumTable reloadData];
            }
        }
    }
    @catch( NSException *ne)
    {
        N2LogExceptionWithStackTrace(ne);
        
        outlineViewArray = [NSArray array];
        
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
    
    if( filtered == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogether"] && outlineViewArray.count > 0 && outlineViewArray.count < 500)
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
                    @try {
                        NSPredicate* predicate = [NSPredicate predicateWithFormat: @"(patientID == %@) AND (studyInstanceUID != %@)", [obj valueForKey:@"patientID"], [obj valueForKey:@"studyInstanceUID"]];
                        
                        NSMutableArray *oulineViewArrayStudyInstanceUIDs = [[[copyOutlineViewArray valueForKey: @"studyInstanceUID"] mutableCopy] autorelease];
                        
                        for( id patientStudy in [[_database objectsForEntity:_database.studyEntity predicate:predicate] sortedArrayUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]]])
                        {
                            if( [oulineViewArrayStudyInstanceUIDs containsObject: [patientStudy valueForKey: @"studyInstanceUID"]] == NO && patientStudy != nil)
                            {
                                studyIndex++;
                                [copyOutlineViewArray insertObject: patientStudy atIndex: studyIndex];
                                [oulineViewArrayStudyInstanceUIDs insertObject: [patientStudy valueForKey: @"studyInstanceUID"] atIndex: studyIndex];
                            }
                        }
                    } @catch (NSException* e) { // object has become unavailable, who cares, we just won't be showing it anymore
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
                for (id obj in outlineViewArray)
                    [patientPredicateArray addObject: [NSPredicate predicateWithFormat:@"(patientUID BEGINSWITH[cd] %@)", [obj valueForKey:@"patientUID"]]];
                predicate = [NSCompoundPredicate orPredicateWithSubpredicates: patientPredicateArray];
                [originalOutlineViewArray release];
                originalOutlineViewArray = [outlineViewArray retain];
                outlineViewArray = [[_database objectsForEntity:_database.studyEntity predicate:predicate] sortedArrayUsingDescriptors:sortDescriptors];
            }
        }
        @catch( NSException *ne)
        {
            N2LogExceptionWithStackTrace(ne);
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
    
    //	[_database unlock];
    
    [databaseOutline reloadData];
    [comparativeTable reloadData];
    
    @try
    {
        for( id obj in outlineViewArray)
        {
            if( [[obj valueForKey:@"expanded"] boolValue]) [databaseOutline expandItem: obj];
        }
    }
    @catch( NSException *ne)
    {
        N2LogExceptionWithStackTrace(ne);
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
        N2LogExceptionWithStackTrace(e);
    }
			 
    [pool release];
}


-(void)refreshBonjourSource: (id) sender
{
    if ([_database isKindOfClass:[RemoteDicomDatabase class]])
        [(RemoteDicomDatabase*)_database initiateUpdate];
}

- (void) autoretrievePACSOnDemandSmartAlbum:(NSArray*) studies
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    autoretrievingPACSOnDemandSmartAlbum = YES;
    {
#ifndef OSIRIX_LIGHT
        [studies setValue:[NSNumber numberWithBool:YES] forKey:@"isAutoRetrieve"];
        [QueryController retrieveStudies: studies showErrors: NO checkForPreviousAutoRetrieve: YES];
#endif
    }
    autoretrievingPACSOnDemandSmartAlbum = NO;
    [pool release];
}

- (void)_computeNumberOfStudiesForAlbumsThread
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try
    {
        if (_computingNumberOfStudiesForAlbums)
        {
            [self performSelectorOnMainThread:@selector(delayedRefreshAlbums) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
            return;
        }
        
        _computingNumberOfStudiesForAlbums = YES;
        
        [NSThread currentThread].name = NSLocalizedString( @"Compute Albums...", nil);
        [[ThreadsManager defaultManager] addThreadAndStart: [NSThread currentThread]];
        
        DicomDatabase* idatabase = [self.database independentDatabase];
        if (!idatabase)
        {
            _computingNumberOfStudiesForAlbums = NO;
            [self performSelectorOnMainThread:@selector(delayedRefreshAlbums) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
            return;
        }
        
        @try
        {
            NSMutableArray* NoOfStudies = [NSMutableArray array];
            
            // compute number of studies in database
            NSInteger count = -1;
            @try
            {
                count = [idatabase countObjectsForEntity:idatabase.studyEntity];
            }
            @catch (NSException* e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            [NoOfStudies addObject: count >= 0 ? [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:count]] : @"#"];
            
            // compute every album's studies count
            
            DicomDatabase *currentDatabase = _database;
            
            NSArray* albumObjectIDs;
            @synchronized (self)
            {
                albumObjectIDs = [NSArray arrayWithArray: _cachedAlbumsIDs];
            }
            
            NSTimeInterval lastTime = [NSDate timeIntervalSinceReferenceDate];
            
            
            BOOL recomputeDistantStudies = NO;
            
            if( [NSDate timeIntervalSinceReferenceDate] - lastComputeAlbumsForDistantStudies > 120)
                recomputeDistantStudies = YES;
            
            for (NSManagedObjectID* albumObjectID in albumObjectIDs)
            {
                if( currentDatabase != _database) // We switched the main database...
                {
                    [self performSelectorOnMainThread:@selector(delayedRefreshAlbums) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                    break;
                }
                
                DicomAlbum* ialbum = [idatabase objectWithID:albumObjectID];
                
                [NSThread currentThread].status = ialbum.name;
                
                count = -1;
                if( ialbum.smartAlbum.boolValue == YES)
                {
                    @try
                    {
                        NSArray *localStudies = [[idatabase objectsForEntity:idatabase.studyEntity predicate:[self smartAlbumPredicate:ialbum]] valueForKey: @"studyInstanceUID"];
                        
                        count = 0;
                        
                        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForSmartAlbumStudiesOnDICOMNodes"])
                        {
                            NSMutableArray *studyToAutoretrieve = [NSMutableArray array];
                            BOOL autoretrieve = NO;
                            
                            if( autoretrievingPACSOnDemandSmartAlbum == NO)
                            {
                                for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"])
                                {
                                    if( [[d valueForKey: @"autoretrieve"] boolValue] && [ialbum.name isEqualToString: [d valueForKey: @"name"]])
                                        autoretrieve = YES;
                                }
                            }
                            
                            // Merge local and distant studies
                            NSArray *distantStudies = nil;
                            @synchronized(_albumNoOfStudiesCache)
                            {
                                distantStudies = [[[_distantAlbumNoOfStudiesCache objectForKey: ialbum.name] copy] autorelease];
                            }
                            
                            if( recomputeDistantStudies || distantStudies == nil)
                            {
                                distantStudies = [self distantStudiesForSmartAlbum: ialbum.name];
                                
                                if( distantStudies)
                                {
                                    @synchronized(_albumNoOfStudiesCache)
                                    {
                                        if( currentDatabase == _database) // Did we switch the main database...
                                            [_distantAlbumNoOfStudiesCache setObject: distantStudies forKey: ialbum.name];
                                    }
                                }
                                
                                lastComputeAlbumsForDistantStudies = [NSDate timeIntervalSinceReferenceDate];
                            }
                            
                            for( DCMTKStudyQueryNode *distantStudy in distantStudies)
                            {
                                if( [localStudies containsObject: [distantStudy studyInstanceUID]] == NO)
                                {
                                    count++;
                                    
                                    if( autoretrieve)
                                        [studyToAutoretrieve addObject: distantStudy];
                                }
                            }
                            
                            if( autoretrievingPACSOnDemandSmartAlbum == NO && studyToAutoretrieve.count)
                            {
                                NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(autoretrievePACSOnDemandSmartAlbum:) object: studyToAutoretrieve] autorelease];
                                t.name = NSLocalizedString( @"Auto-Retrieving Album...", nil);
                                t.supportsCancel = YES;
                                [[ThreadsManager defaultManager] addThreadAndStart: t];
                            }
                        }
                        
                        count += localStudies.count;
                    }
                    @catch (NSException* e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
                else count = ialbum.studies.count;
                
                
                [NoOfStudies addObject: count >= 0 ? [decimalNumberFormatter stringForObjectValue:[NSNumber numberWithInt:count]] : @"#"];
                
                if( [NSDate timeIntervalSinceReferenceDate] - lastTime >= 1)
                {
                    lastTime = [NSDate timeIntervalSinceReferenceDate];
                    @synchronized(_albumNoOfStudiesCache)
                    {
                        int max = _albumNoOfStudiesCache.count;
                        if( max > NoOfStudies.count)
                            max = NoOfStudies.count;
                        [_albumNoOfStudiesCache replaceObjectsInRange: NSMakeRange( 0, max) withObjectsFromArray: NoOfStudies];
                    }
                    [albumTable performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                }
                
                if( [[NSThread currentThread] isCancelled])
                    break;
            }
            
            @synchronized (_albumNoOfStudiesCache)
            {
                [_albumNoOfStudiesCache removeAllObjects];
                if (currentDatabase == _database) // Did we switch the main database...
                    [_albumNoOfStudiesCache addObjectsFromArray:NoOfStudies];
            }
            
            [albumTable performSelectorOnMainThread: @selector(reloadData) withObject: nil waitUntilDone: NO  modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        @finally
        {
            _computingNumberOfStudiesForAlbums = NO;
        }
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

- (void)delayedRefreshAlbums
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshAlbums) object:nil];
    [self performSelector:@selector(refreshAlbums) withObject:nil afterDelay:20];
}

- (void)refreshAlbums
{
    if( _database)
    {
        if( _computingNumberOfStudiesForAlbums)
            [self delayedRefreshAlbums];
        else
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO || [self.window isVisible]) // Server Mode: dont refresh albums
                [NSThread detachNewThreadSelector:@selector(_computeNumberOfStudiesForAlbumsThread) toTarget:self withObject: nil];
        }
    }
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
            N2LogExceptionWithStackTrace(e);
        }
    }
    else
    {
        //For filters depending on time....
        [self refreshAlbums];
        [databaseOutline reloadData];
        [comparativeTable reloadData];
    }
    
#ifndef OSIRIX_LIGHT
    if( [QueryController currentQueryController])
        [[QueryController currentQueryController] refresh: self];
    else if( [QueryController currentAutoQueryController])
        [[QueryController currentAutoQueryController] refresh: self];
#endif
}

- (NSArray*) childrenArray: (id)item onlyImages: (BOOL)onlyImages
{
#ifndef OSIRIX_LIGHT
    if( [item isDistant])
        return [NSArray array];
#endif
    
    if( [item isDeleted])
    {
        if( [item isDeleted])
            NSLog( @"----- isDeleted - childrenArray : we have to refresh the outlineView...");
        
        if( [item isDeleted] || item == nil)
            return [NSArray array];
    }
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
    {
        //		[_database lock];
        
        NSArray *sortedArray = [item sortedImages];
        
        //		[_database unlock];
        
        return sortedArray;
    }
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
    {
        //		[_database lock];
        
        NSArray *sortedArray = nil;
        @try
        {
            if( onlyImages) sortedArray = [item valueForKey:@"imageSeries"];
            else
            {
                sortedArray = [item valueForKey:@"allSeries"];
                
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
            N2LogExceptionWithStackTrace(e);
        }
        
        //		[_database unlock];
        
        return sortedArray;
    }
    
    return nil;
}

- (NSArray*) childrenArray: (id) item
{
    return [self childrenArray: item onlyImages: YES];
}

- (NSArray*) imagesArray: (id) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages
{
    NSArray			*childrenArray = [self childrenArray: item onlyImages:onlyImages];
    NSMutableArray	*imagesPathArray = nil;
    
    if( childrenArray == nil)
        return nil;
    
    //	[_database lock];
    
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
        N2LogExceptionWithStackTrace(e);
    }
    
    //	[_database unlock];
    
    return imagesPathArray;
}

- (NSArray*) imagesArray: (id) item preferredObject: (int) preferredObject
{
    return [self imagesArray: item preferredObject: oAny onlyImages:YES];
}

- (NSArray*) imagesArray: (id) item onlyImages:(BOOL) onlyImages
{
    return [self imagesArray: item preferredObject: oAny onlyImages: onlyImages];
}

- (NSArray*) imagesArray: (id) item
{
    return [self imagesArray: item preferredObject: oAny];
}

- (NSArray*) imagesPathArray: (id) item
{
    return [[self imagesArray: item] valueForKey: @"completePath"];
}

- (NSManagedObject *)firstObjectForDatabaseOutlineSelection
{
    NSManagedObject *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
    
    //	[_database lock];
    
    if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
        aFile = [[aFile valueForKey:@"series"] anyObject];
    
    if( [[aFile valueForKey:@"type"] isEqualToString:@"Series"])
        aFile = [[aFile valueForKey:@"images"] anyObject];
    
    //	[_database unlock];
    
    return aFile;
}

#define BONJOURPACKETS 50

- (NSMutableArray*)filesForDatabaseOutlineSelection:(NSMutableArray*)correspondingManagedObjects treeObjects:(NSMutableSet*)treeManagedObjects onlyImages:(BOOL)onlyImages
{
    NSMutableArray *selectedFiles = [NSMutableArray array];
    NSIndexSet *rowEnumerator = [databaseOutline selectedRowIndexes];
    
    if( cachedFilesForDatabaseOutlineSelectionIndex && [[databaseOutline selectedRowIndexes] isEqualToIndexSet: cachedFilesForDatabaseOutlineSelectionIndex] && onlyImages == YES)
    {
        [selectedFiles addObjectsFromArray: cachedFilesForDatabaseOutlineSelectionSelectedFiles];
        
        if( correspondingManagedObjects)
            [correspondingManagedObjects addObjectsFromArray: cachedFilesForDatabaseOutlineSelectionCorrespondingObjects];
        if( treeManagedObjects)
            [treeManagedObjects addObjectsFromArray: cachedFilesForDatabaseOutlineSelectionTreeObjects.allObjects];
        
        return selectedFiles;
    }
    
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
    if( correspondingManagedObjects == nil) correspondingManagedObjects = [NSMutableArray array];
    if( treeManagedObjects == nil) treeManagedObjects = [NSMutableSet set];
    
    [context retain];
    [context lock];
    
    @try
    {
        for (NSUInteger row = [rowEnumerator firstIndex]; row != NSNotFound; row = [rowEnumerator indexGreaterThanIndex: row])
        {
            NSManagedObject *curObj = [databaseOutline itemAtRow: row];
            
            if( [curObj isKindOfClass: [NSManagedObject class]]) // not a distant study
            {
                if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
                {
                    @autoreleasepool {
                        NSArray	*imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
                        
                        [correspondingManagedObjects addObjectsFromArray: imagesArray];
                    }
                }
                
                if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
                {
                    @autoreleasepool {
                        NSArray	*seriesArray = [self childrenArray: curObj onlyImages: onlyImages];
                        
                        int totImage = 0;
                        DicomSeries* dontDelete = nil;
                        
                        for (DicomSeries* obj in seriesArray)
                        {
                            NSArray	*imagesArray = [self imagesArray: obj onlyImages: onlyImages];
                            
                            totImage += [imagesArray count];
                            
                            [correspondingManagedObjects addObjectsFromArray: imagesArray];
                            
                            if ([obj.name isEqualToString:@"OsiriX No Autodeletion"] && obj.id.intValue == 5005)
                                dontDelete = obj;
                        }
                        
                        if (totImage && dontDelete) // there are images, remove the "OsiriX No Autodeletion" series
                            [context deleteObject:dontDelete];
                        
                        if (onlyImages == NO && totImage == 0 && dontDelete == nil) // We don't want empty studies, unless the "OsiriX No Autodeletion" series is there...
                            [context deleteObject: curObj];
                    }
                }
                
                if (![curObj isDeleted])
                    [treeManagedObjects addObject:curObj];
            }
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
                    @autoreleasepool
                    {
                        NSString *p = [self getLocalDCMPath: obj :BONJOURPACKETS];
                        
                        [selectedFiles addObject: p];
                        
                        [splash incrementBy: 1];
                    }
                }
            }
            
            if( [splash aborted])
            {
                [selectedFiles removeAllObjects];
                [correspondingManagedObjects removeAllObjects];
            }
            
            [splash close];
            [splash autorelease];
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
        N2LogExceptionWithStackTrace(e);
    }
    
    [context save: nil];
    [context release];
    [context unlock];
    
    if( onlyImages)
    {
        [cachedFilesForDatabaseOutlineSelectionSelectedFiles release];
        [cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release];
        [cachedFilesForDatabaseOutlineSelectionTreeObjects release];
        [cachedFilesForDatabaseOutlineSelectionIndex release];
        
        cachedFilesForDatabaseOutlineSelectionIndex = [[NSIndexSet alloc] initWithIndexSet: [databaseOutline selectedRowIndexes]];
        cachedFilesForDatabaseOutlineSelectionSelectedFiles = [[NSMutableArray alloc] initWithArray:selectedFiles];
        cachedFilesForDatabaseOutlineSelectionTreeObjects = [[NSMutableSet alloc] initWithSet:treeManagedObjects];
        cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = [[NSMutableArray alloc] initWithArray:correspondingManagedObjects];
    }
    
    return selectedFiles;
}

- (NSMutableArray*)filesForDatabaseOutlineSelection:(NSMutableArray*)correspondingManagedObjects onlyImages:(BOOL)onlyImages {
    return [self filesForDatabaseOutlineSelection:correspondingManagedObjects treeObjects:nil onlyImages:onlyImages];
}

- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects
{
    return [self filesForDatabaseOutlineSelection:correspondingManagedObjects onlyImages: YES];
}

- (void) resetROIsAndKeysButton
{
    ROIsAndKeyImagesButtonAvailable = NO;
    
    NSMutableArray *i = [NSMutableArray arrayWithArray: [[toolbar items] valueForKey: @"itemIdentifier"]];
    if( [i containsObject: OpenKeyImagesAndROIsToolbarItemIdentifier] && [_database isLocal])
    {
        if( [[databaseOutline selectedRowIndexes] count] >= 5)	//[[self window] firstResponder] == databaseOutline &&
            ROIsAndKeyImagesButtonAvailable = YES;
        else
        {
            NSEvent *event = [[NSApplication sharedApplication] currentEvent];
            
            if([event modifierFlags] & NSAlternateKeyMask)
            {
                if( [[self KeyImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
                else ROIsAndKeyImagesButtonAvailable = YES;
            }
            else if([event modifierFlags] & NSShiftKeyMask)
            {
                if( [[self ROIImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
                else ROIsAndKeyImagesButtonAvailable = YES;
            }
            else
            {
                if( [[self ROIsAndKeyImages: nil] count] == 0) ROIsAndKeyImagesButtonAvailable = NO;
                else ROIsAndKeyImagesButtonAvailable = YES;
            }
        }
    }
}

+ (NSArray*) comparativeServers
{
    NSMutableArray* servers = [NSMutableArray array];
    NSArray* sources = [DCMNetServiceDelegate DICOMServersList];
    NSMutableArray* comparativeNodesDescription = [NSMutableArray array];
    NSMutableArray* comparativeNodesAddress = [NSMutableArray array];
    for( NSDictionary *si in [[NSUserDefaults standardUserDefaults] arrayForKey: @"comparativeSearchDICOMNodes"])
    {
        if( [[si valueForKey: @"server"] valueForKey: @"Description"])
            [comparativeNodesDescription addObject: [[si valueForKey: @"server"] valueForKey: @"Description"]];
        
        if( [[si valueForKey: @"server"] valueForKey: @"Address"])
            [comparativeNodesAddress addObject: [[si valueForKey: @"server"] valueForKey: @"Address"]];
    }
    
    if( comparativeNodesDescription.count != comparativeNodesAddress.count)
        NSLog( @"**** comparativeNodesDescription.count != comparativeNodesAddress.count");
    else
    {
        for( int x = 0; x < comparativeNodesDescription.count; x++)
        {
            NSString *description = [comparativeNodesDescription objectAtIndex: x];
            NSString *address = [comparativeNodesAddress objectAtIndex: x];
            
            for (NSDictionary* si in sources)
            {
                if( [description isEqualToString: [si objectForKey:@"Description"]] && [address isEqualToString: [si objectForKey:@"Address"]])
                    [servers addObject: si];
            }
        }
    }
    
    return servers;
}

+ (NSString*) stringForSearchType:(int) curSearchType
{
    switch( curSearchType)
    {
        case 7:			// All fields -> Use only the Patient Name for distant nodes
        case 0:			// Patient Name
            return NSLocalizedString( @"Patient Name", nil);
            break;
            
        case 1:			// Patient ID
            return NSLocalizedString( @"Patient ID", nil);
            break;
            
        case 2:			// Study ID
            return NSLocalizedString( @"Study ID", nil);
            break;
            
        case 3:			// Comments
            return NSLocalizedString( @"Comments", nil);
            break;
            
        case 4:			// Study Description
            return NSLocalizedString( @"Study Description", nil);
            break;
            
        case 5:			// Modality
            return NSLocalizedString( @"Modality", nil);
            break;
            
        case 6:			// Accession Number
            return NSLocalizedString( @"AccessionNumber", nil);
            break;
    }
    
    return @"";
}

- (NSArray*) distantStudiesForSearchString: (NSString*) curSearchString type:(int) curSearchType
{
#ifndef OSIRIX_LIGHT
    if( !searchForComparativeStudiesLock)
        searchForComparativeStudiesLock = [NSRecursiveLock new];
    
    [searchForComparativeStudiesLock lock];
    
    @try
    {
        NSArray *servers = [BrowserController comparativeServers];
        
        // Distant studies
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        switch( curSearchType)
        {
            case 7:			// All fields -> Use only the Patient Name for distant nodes
            case 0:			// Patient Name
                curSearchString = [curSearchString stringByReplacingOccurrencesOfString: @", " withString: @" "];
                curSearchString = [curSearchString stringByReplacingOccurrencesOfString: @"," withString: @" "];
                
                [d setObject: [curSearchString stringByAppendingString:@"*"] forKey: @"PatientsName"];
                break;
                
            case 1:			// Patient ID
                [d setObject: curSearchString forKey: @"PatientID"];
                break;
                
            case 2:			// Study ID
                [d setObject: curSearchString forKey: @"StudyID"];
                break;
                
            case 3:			// Comments
                [d setObject: [curSearchString stringByAppendingString:@"*"] forKey: @"Comments"];
                break;
                
            case 4:			// Study Description
                [d setObject: [curSearchString stringByAppendingString:@"*"] forKey: @"StudyDescription"];
                break;
                
            case 5:			// Modality
                [d setObject: [NSArray arrayWithObject: curSearchString] forKey: @"modality"];
                break;
                
            case 6:			// Accession Number
                [d setObject: curSearchString forKey: @"AccessionNumber"];
                break;
        }
        
        // Modality Filter?
        if( [modalityFilterMenu indexOfSelectedItem] > 0 && self.modalityFilter.length)
            [d setObject: [NSArray arrayWithObject: self.modalityFilter] forKey: @"modality"];
        
        NSArray *result = [QueryController queryStudiesForFilters: d servers: servers showErrors: NO];
        
        if(( curSearchType == 0 || curSearchType == 7) && [[curSearchString componentsSeparatedByString: @" "] count] > 1) // For patient name, if several components, try with ^ separator, and add missing results
        {
            NSString *s = [curSearchString stringByAppendingString:@"*"];
            
            // replace last occurence // fan siu hung
            s = [s stringByReplacingCharactersInRange: [s rangeOfString: @" " options: NSBackwardsSearch] withString: @"^"];
            
            [d setObject: s forKey: @"PatientsName"];
            
            NSArray *subResult = [QueryController queryStudiesForFilters: d servers: servers showErrors: NO];
            
            NSArray *resultUIDs = [result valueForKey: @"uid"];
            
            for( DCMTKQueryNode *n in subResult)
            {
                if( [resultUIDs containsObject: n.uid] == NO)
                    result = [result arrayByAddingObject: n];
            }
        }
        
        return result;
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [searchForComparativeStudiesLock unlock];
    }
#endif
    return nil;
}

- (void) searchForSearchField: (NSDictionary*) dict
{
    if( self.database == nil)
        return;
    
    if( self.database.isReadOnly || !self.database.isLocal)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] == NO)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"PACSOnDemandForSearchField"] == NO)
        return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    int selectedAlbumIndex = [[dict objectForKey: @"selectedAlbumIndex"] intValue];
    int curSearchType = [[dict objectForKey: @"searchType"] intValue];
    NSString *curSearchString = [dict objectForKey: @"searchString"];
    
    [NSThread currentThread].name = NSLocalizedString( @"Search For Search Field...", nil);
    
    if( curSearchType == searchType && [curSearchString isEqualToString: _searchString]) // There was maybe other locks in the queue...
    {
        NSLog( @"Search For %@: %@", [BrowserController stringForSearchType: curSearchType], curSearchString);
        
        if( [curSearchString length] > 2 || (_searchString.length >= 2 && searchType == 5))
        {
            if( !searchForComparativeStudiesLock)
                searchForComparativeStudiesLock = [NSRecursiveLock new];
            
            @synchronized( smartAlbumDistantArraySync)
            {
                if( smartAlbumDistantSearchArray == nil)
                    smartAlbumDistantSearchArray = [[NSMutableArray alloc] init];
                
                [smartAlbumDistantSearchArray addObject: [NSThread currentThread]];
                distantSearchThread = [[NSThread currentThread] retain];
            }
            
            [searchForComparativeStudiesLock lock];
            
            if( curSearchType == searchType && [curSearchString isEqualToString: _searchString] && [[NSThread currentThread] isCancelled] == NO) // There was maybe other locks in the queue...
            {
                id lastObjectInQueue = nil;
                
                @synchronized( smartAlbumDistantArraySync)
                {
                    lastObjectInQueue = [smartAlbumDistantSearchArray lastObject];
                }
                
                if( [NSThread currentThread] == lastObjectInQueue)
                {
                    [NSThread currentThread].name = [NSString stringWithFormat: NSLocalizedString( @"Search %@: %@", nil), [BrowserController stringForSearchType: curSearchType], curSearchString];
                    [[ThreadsManager defaultManager] addThreadAndStart: [NSThread currentThread]];
                    
                    @try
                    {
                        NSArray *array = [self distantStudiesForSearchString: curSearchString type: curSearchType];
                        
                        if( selectedAlbumIndex == 0)
                        {
                            @synchronized( smartAlbumDistantArraySync)
                            {
                                [smartAlbumDistantArray release];
                                smartAlbumDistantArray = [array retain];
                            }
                        }
                        else distantEntireDBResultCount = array.count;
                        
                        self.distantSearchString = curSearchString;
                        self.distantSearchType = curSearchType;
                        
                        if( curSearchType == searchType && [curSearchString isEqualToString: _searchString]) // There were maybe other locks in the queue...
                        {
                            if( selectedAlbumIndex == 0)
                                [self performSelectorOnMainThread: @selector(_refreshDatabaseDisplay) withObject: nil waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                            else
                                [self performSelectorOnMainThread: @selector(refreshEntireDBResult) withObject: nil waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                        }
                    }
                    @catch (NSException* e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
            }
            
            @synchronized( smartAlbumDistantArraySync)
            {
                [smartAlbumDistantSearchArray removeObject: [NSThread currentThread]];
            }
            
            [searchForComparativeStudiesLock unlock];
        }
    }
    
    [pool release];
}

- (NSArray*) distantStudiesForIntervalFrom: (NSDate*) from to:(NSDate*) to
{
#ifndef OSIRIX_LIGHT
    if( !searchForComparativeStudiesLock)
        searchForComparativeStudiesLock = [NSRecursiveLock new];
    
    [searchForComparativeStudiesLock lock];
    
    @try
    {
        NSArray *servers = [BrowserController comparativeServers];
        
        // Distant studies
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        if( from && to)
            [d setObject: [NSNumber numberWithInt: between] forKey: @"date"];
        else if( from)
            [d setObject: [NSNumber numberWithInt: after] forKey: @"date"];
        
        [d setObject: from forKey: @"fromDate"];
        
        if( to)
            [d setObject: to forKey: @"toDate"];
        
        // Modality Filter?
        if( [modalityFilterMenu indexOfSelectedItem] > 0 && self.modalityFilter.length)
            [d setObject: [NSArray arrayWithObject: self.modalityFilter] forKey: @"modality"];
        
        return [QueryController queryStudiesForFilters: d servers: servers showErrors: NO];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [searchForComparativeStudiesLock unlock];
    }
#endif
    return nil;
}

- (void) searchForTimeIntervalFromTo: (NSDictionary*) dict
{
    if( self.database == nil)
        return;
    
    if( self.database.isReadOnly)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] == NO)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"PACSOnDemandForSearchField"] == NO)
        return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSDate* from = [dict objectForKey: @"from"];
    NSDate* to = [dict objectForKey: @"to"];
    
    [NSThread currentThread].name = @"Search For Time Interval Studies";
    
    if( [from isEqualToDate: timeIntervalStart] && (to == nil || [to isEqualToDate: timeIntervalEnd])) // There was maybe other locks in the queue...
    {
        NSLog( @"Search time interval: %@ to %@", from, to);
        
        {
            if( !searchForComparativeStudiesLock)
                searchForComparativeStudiesLock = [NSRecursiveLock new];
            
            @synchronized( smartAlbumDistantArraySync)
            {
                if( smartAlbumDistantSearchArray == nil)
                    smartAlbumDistantSearchArray = [[NSMutableArray alloc] init];
                
                [smartAlbumDistantSearchArray addObject: [NSThread currentThread]];
                distantSearchThread = [[NSThread currentThread] retain];
            }
            
            [searchForComparativeStudiesLock lock];
            
            if( [from isEqualToDate: timeIntervalStart] && (to == nil || [to isEqualToDate: timeIntervalEnd]) && [[NSThread currentThread] isCancelled] == NO) // There was maybe other locks in the queue...
            {
                id lastObjectInQueue = nil;
                
                @synchronized( smartAlbumDistantArraySync)
                {
                    lastObjectInQueue = [smartAlbumDistantSearchArray lastObject];
                }
                
                if( [NSThread currentThread] == lastObjectInQueue)
                {
                    [NSThread currentThread].name = NSLocalizedString( @"Search Time Interval...", nil);
                    [[ThreadsManager defaultManager] addThreadAndStart: [NSThread currentThread]];
                    
                    @try
                    {
                        NSArray *array = [self distantStudiesForIntervalFrom: from to: to];
                        @synchronized( smartAlbumDistantArraySync)
                        {
                            [smartAlbumDistantArray release];
                            smartAlbumDistantArray = [array retain];
                        }
                        
                        self.distantTimeIntervalStart = from;
                        self.distantTimeIntervalEnd = to;
                        
                        if( [from isEqualToDate: timeIntervalStart] && (to == nil || [to isEqualToDate: timeIntervalEnd])) // There was maybe other locks in the queue...
                            [self performSelectorOnMainThread: @selector(_refreshDatabaseDisplay) withObject: nil waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                    }
                    @catch (NSException* e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
            }
            
            @synchronized( smartAlbumDistantArraySync)
            {
                [smartAlbumDistantSearchArray removeObject: [NSThread currentThread]];
            }
            
            [searchForComparativeStudiesLock unlock];
        }
    }
    
    [pool release];
}

- (NSArray*) distantStudiesForSmartAlbum: (NSString*) albumName
{
    if( self.database.isReadOnly || !self.database.isLocal)
        return [NSArray array];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] == NO)
        return [NSArray array];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForSmartAlbumStudiesOnDICOMNodes"] == NO)
        return [NSArray array];
    
#ifndef OSIRIX_LIGHT
    if( !searchForComparativeStudiesLock)
        searchForComparativeStudiesLock = [NSRecursiveLock new];
    
    [searchForComparativeStudiesLock lock];
    
    @try
    {
        NSArray *servers = [BrowserController comparativeServers];
        
        // Distant studies
        // In current versions, two filters exist: modality & date
        for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"])
        {
            if( [[d valueForKey: @"activated"] boolValue] && [albumName isEqualToString: [d valueForKey: @"name"]])
            {
                return [QueryController queryStudiesForFilters: d servers: servers showErrors: NO];
            }
        }
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [searchForComparativeStudiesLock unlock];
    }
#endif
    return nil;
}

- (void) searchForSmartAlbumDistantStudies: (NSString*) albumName
{
    if( self.database == nil)
        return;
    
    if( self.database.isReadOnly || !self.database.isLocal)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] == NO)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForSmartAlbumStudiesOnDICOMNodes"] == NO)
        return;
    
    if( albumName.length == 0)
        return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [NSThread currentThread].name = @"Search For Smart Album Distant Studies";
    
    if( [albumName isEqualToString: self.selectedAlbumName]) // There was maybe other locks in the queue...
    {
        NSLog( @"Search album: %@", albumName);
        
        lastRefreshSmartAlbumDistantStudies = [NSDate timeIntervalSinceReferenceDate];
        
        {
            if( !searchForComparativeStudiesLock)
                searchForComparativeStudiesLock = [NSRecursiveLock new];
            
            @synchronized( smartAlbumDistantArraySync)
            {
                if( smartAlbumDistantSearchArray == nil)
                    smartAlbumDistantSearchArray = [[NSMutableArray alloc] init];
                
                for( NSThread *t in smartAlbumDistantSearchArray)
                    [t setIsCancelled: YES];
                
                [smartAlbumDistantSearchArray addObject: [NSThread currentThread]];
            }
            
            [searchForComparativeStudiesLock lock];
            
            if( [albumName isEqualToString: self.selectedAlbumName] && [[NSThread currentThread] isCancelled] == NO) // There was maybe other locks in the queue...
            {
                id lastObjectInQueue = nil;
                
                @synchronized( smartAlbumDistantArraySync)
                {
                    lastObjectInQueue = [smartAlbumDistantSearchArray lastObject];
                }
                
                if( [NSThread currentThread] == lastObjectInQueue)
                {
                    [NSThread currentThread].name = [NSString stringWithFormat: NSLocalizedString( @"Search Smart Album...", nil), albumName];
                    [[ThreadsManager defaultManager] addThreadAndStart: [NSThread currentThread]];
                    
                    @try
                    {
                        NSArray *array = [self distantStudiesForSmartAlbum: albumName];
                        
                        @synchronized( smartAlbumDistantArraySync)
                        {
                            [smartAlbumDistantArray release];
                            smartAlbumDistantArray = [array retain];
                        }
                        
                        self.smartAlbumDistantName = albumName;
                        
                        if( [albumName isEqualToString: self.selectedAlbumName])
                            [self performSelectorOnMainThread: @selector(_refreshDatabaseDisplay) withObject: nil waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                    }
                    @catch (NSException* e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
            }
            
            @synchronized( smartAlbumDistantArraySync)
            {
                [smartAlbumDistantSearchArray removeObject: [NSThread currentThread]];
            }
            
            [searchForComparativeStudiesLock unlock];
        }
    }
    
    [pool release];
}

- (NSArray*) subSearchForComparativeStudies: (id) studySelectedID
{
    @try
    {
        NSMutableArray *mergedStudies = nil;
        
        //[NSNotificationCenter.defaultCenter postNotificationOnMainThreadName:O2SearchForComparativeStudiesStartedNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys: studySelectedID, @"study", nil]];
        
        DicomDatabase *idatabase = [NSThread isMainThread] ? self.database : self.database.independentDatabase;
        
        DicomStudy *studySelected = nil;
        
        if( [studySelectedID isKindOfClass: [NSManagedObjectID class]])
            studySelected = [idatabase objectWithID: studySelectedID];
        else
            studySelected = studySelectedID; //DCMTKStudyQueryNode
        
        if( studySelected.patientUID.length == 0)
            return nil;
        
        [NSThread currentThread].name = @"Search For Comparative Studies";
        
        if( self.comparativePatientUID && [self.comparativePatientUID compare: studySelected.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame) // There was maybe other locks in the queue... Keep only the displayed patientUID
        {
            lastRefreshComparativeStudies = [NSDate timeIntervalSinceReferenceDate];
            
            @try
            {
                // Local studies
                NSArray *localStudies = nil;
                [idatabase lock];
                @try
                {
                    localStudies = [idatabase objectsForEntity: idatabase.studyEntity predicate: [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@)", studySelected.patientUID]];
                }
                @catch (NSException* e)
                {
                    NSLog( @"*** Comparative Studies exception: %@", e);
                }
                [idatabase unlock];
                
                mergedStudies = [NSMutableArray arrayWithArray: localStudies];
                [mergedStudies sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: NO]]];
                
                if( self.comparativePatientUID && [self.comparativePatientUID compare: studySelected.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
                    [self performSelectorOnMainThread: @selector(refreshComparativeStudies:) withObject: mergedStudies waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]]; // Already display the local studies, we will display the merged studies later
            }
            @catch (NSException* e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"] && !self.database.isReadOnly && self.database.isLocal)
            {
                if( !searchForComparativeStudiesLock)
                    searchForComparativeStudiesLock = [NSRecursiveLock new];
                
                @synchronized( smartAlbumDistantArraySync)
                {
                    if( comparativeStudySearchArray == nil)
                        comparativeStudySearchArray = [[NSMutableArray alloc] init];
                    
                    for( NSThread *t in comparativeStudySearchArray)
                        [t setIsCancelled: YES];
                    
                    [comparativeStudySearchArray addObject: [NSThread currentThread]];
                }
                
                [searchForComparativeStudiesLock lock];
                if( self.comparativePatientUID && [self.comparativePatientUID compare: studySelected.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame && [[NSThread currentThread] isCancelled] == NO) // There was maybe other locks in the queue... Keep only the displayed patientUID
                {
                    id lastObjectInQueue = nil;
                    
                    @synchronized( smartAlbumDistantArraySync)
                    {
                        lastObjectInQueue = [comparativeStudySearchArray lastObject];
                    }
                    
                    if( [NSThread currentThread] == lastObjectInQueue)
                    {
                        [NSThread currentThread].name = [NSString stringWithFormat: NSLocalizedString( @"Search History: %@", nil), studySelected.name];
                        [[ThreadsManager defaultManager] addThreadAndStart: [NSThread currentThread]];
                        
                        @try
                        {
                            NSArray *distantStudies = nil;
                            
                            BOOL usePatientID = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientIDForUID"];
                            BOOL usePatientBirthDate = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientBirthDateForUID"];
                            BOOL usePatientName = [[NSUserDefaults standardUserDefaults] boolForKey: @"UsePatientNameForUID"];
                            
                            // Servers
                            NSArray *servers = [BrowserController comparativeServers];
                            
                            if( servers.count)
                            {
                                // Distant studies
#ifndef OSIRIX_LIGHT
                                distantStudies = [QueryController queryStudiesForPatient: studySelected usePatientID: usePatientID usePatientName: usePatientName usePatientBirthDate: usePatientBirthDate servers: servers showErrors: NO];
                                
                                // Merge local and distant studies
                                NSMutableArray *studyToAutoretrieve = [NSMutableArray array];
                                for( DCMTKStudyQueryNode *distantStudy in distantStudies)
                                {
                                    if( [[mergedStudies valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]] == NO)
                                    {
                                        [mergedStudies addObject: distantStudy];
                                    }
                                    else if( [[NSUserDefaults standardUserDefaults] boolForKey: @"preferStudyWithMoreImages"])
                                    {
                                        BOOL inTheRetrieveQueue = NO;
                                        
                                        //Is this study in the retrieve queue? Display the local study
                                        @synchronized( comparativeRetrieveQueue)
                                        {
                                            inTheRetrieveQueue = [[comparativeRetrieveQueue valueForKey: @"studyInstanceUID"] containsObject: [distantStudy studyInstanceUID]];
                                        }
                                        
                                        if( inTheRetrieveQueue == NO)
                                        {
                                            NSUInteger index = [[mergedStudies valueForKey: @"studyInstanceUID"] indexOfObject: [distantStudy studyInstanceUID]];
                                            
                                            if( index != NSNotFound && [[[mergedStudies objectAtIndex: index] rawNoFiles] intValue] < [[distantStudy noFiles] intValue])
                                            {
                                                [mergedStudies replaceObjectAtIndex: index withObject: distantStudy];
                                                
                                                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"automaticallyRetrievePartialStudies"])
                                                    [studyToAutoretrieve addObject: distantStudy];
                                            }
                                        }
                                    }
                                }
                                
                                if( studyToAutoretrieve.count)
                                {
                                    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(autoretrievePACSOnDemandSmartAlbum:) object: studyToAutoretrieve] autorelease];
                                    t.name = NSLocalizedString( @"Auto-Retrieving...", nil);
                                    t.supportsCancel = YES;
                                    [[ThreadsManager defaultManager] addThreadAndStart: t];
                                }
#endif
                            }
                            
                            [mergedStudies sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: NO]]];
                            
                            if( self.comparativePatientUID && [self.comparativePatientUID compare: studySelected.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
                            {
                                [self performSelectorOnMainThread: @selector(refreshComparativeStudiesAndCheck:) withObject: mergedStudies waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                            }
                        }
                        @catch (NSException* e)
                        {
                            N2LogExceptionWithStackTrace(e);
                        }
                    }
                }
                
                @synchronized( smartAlbumDistantArraySync)
                {
                    [comparativeStudySearchArray removeObject: [NSThread currentThread]];
                }
                
                [searchForComparativeStudiesLock unlock];
            }
        }
        
        return mergedStudies;
    }
    @catch (NSException *e) {
        N2LogException( e);
    }
}

- (void) searchForComparativeStudies: (id) studySelectedID
{
    if( self.database == nil)
        return;
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    [self subSearchForComparativeStudies: studySelectedID];
    
    [pool release];
}

- (IBAction) refreshPACSOnDemandResults:(id) sender
{
    self.comparativePatientUID = nil;
    self.comparativeStudies = nil;
    
    @synchronized( smartAlbumDistantArraySync)
    {
        [smartAlbumDistantArray release];
        smartAlbumDistantArray = nil;
    }
    
    self.smartAlbumDistantName = nil;
    
    [previousItem release];
    previousItem = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: NSTableViewSelectionDidChangeNotification object:albumTable userInfo: nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification object:databaseOutline userInfo: nil];
}

- (void) refreshComparativeStudiesAndCheck:(NSArray *)newStudies
{
    [self refreshComparativeStudies: newStudies];
    [self checkIfLocalStudyHasMoreOrSameNumberOfImagesOfADistantStudy: nil];
}

- (void) refreshComparativeStudies: (NSArray*) newStudies
{
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"***** We must be on MAIN thread");
    
    if( _database == nil)
        return;
    
    NSManagedObject *item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
    DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
    
    if( item)
    {
        dontSelectStudyFromComparativeStudies = YES;
        
        NSMutableArray *mainContextStudies = [NSMutableArray array];
        for( id study in newStudies)
        {
            if( [study isKindOfClass: [DicomStudy class]])
            {
                id obj = [self.database objectWithID: [study objectID]];
                if( obj)
                    [mainContextStudies addObject: obj];
            }
            else
                [mainContextStudies addObject: study];
        }
        
        self.comparativeStudies = mainContextStudies;
        [comparativeTable reloadData];
        
        if( studySelected.name)
            [[[comparativeTable tableColumnWithIdentifier:@"Cell"] headerCell] setStringValue: studySelected.name];
        
        NSUInteger index = [[self.comparativeStudies valueForKey: @"studyInstanceUID"] indexOfObject: [studySelected valueForKey: @"studyInstanceUID"]];
        
        dontSelectStudyFromComparativeStudies = NO;
        
        if( index != NSNotFound)
            [comparativeTable selectRowIndexes: [NSIndexSet indexSetWithIndex: index] byExtendingSelection: NO];
        else
            [comparativeTable selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
        
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
            [v comparativeRefresh: self.comparativePatientUID];
        
        [comparativeTable scrollRowToVisible: [comparativeTable selectedRow]];
    }
    else
    {
        self.comparativeStudies = nil;
        [comparativeTable reloadData];
    }
}

- (void) refreshComparativeStudiesIfNeeded:(id) timer
{
    if( timer == nil)
        lastRefreshComparativeStudies = 0;
    
    if( [NSDate timeIntervalSinceReferenceDate] - lastRefreshComparativeStudies > 3 * 60) // 3 min
    {
        NSManagedObject *item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
        DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
        
        id object = nil;
        if( [studySelected isKindOfClass: [DicomStudy class]])
            object = [studySelected objectID];
        else
            object = studySelected; // DCMTKStudyQueryNode
        
        if( object)
            [NSThread detachNewThreadSelector: @selector(searchForComparativeStudies:) toTarget:self withObject: object];
        
        [self computeTimeInterval];
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForSmartAlbumStudiesOnDICOMNodes"] && albumTable.selectedRow > 0)
    {
        NSArray	*albumArray = self.albumArray;
        
        if( [albumArray count] > albumTable.selectedRow)
        {
            DicomAlbum *album = [albumArray objectAtIndex: albumTable.selectedRow];
            
            if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
            {
                if( [NSDate timeIntervalSinceReferenceDate] - lastRefreshSmartAlbumDistantStudies > 3 * 60) // 3 min
                    [NSThread detachNewThreadSelector: @selector(searchForSmartAlbumDistantStudies:) toTarget:self withObject: album.name];
            }
        }
    }
    
    if( comparativeStudyWaited) // Select it ! And open it if needed...
    {
        if( [NSDate timeIntervalSinceReferenceDate] - comparativeStudyWaitedTime < 10) // Only try during 10 secs
        {
            [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
            
            NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
            [request setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
            [request setPredicate: [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", [comparativeStudyWaited studyInstanceUID]]];
            
            NSError *error = nil;
            NSArray *studyArray = nil;
            @try {
                studyArray = [self.database.managedObjectContext executeFetchRequest:request error:&error];
            }
            @catch (NSException *e) {
                N2LogExceptionWithStackTrace(e);
            }
            
            if( [studyArray count] > 0)
            {
                DicomStudy *study = [studyArray objectAtIndex: 0];
                NSArray *seriesArray = [self childrenArray: study];
                
                if( [seriesArray count])
                {
                    BOOL success = NO;
                    
                    if( comparativeStudyWaitedToSelect)
                    {
                        if( [self selectThisStudy: study] == YES)
                            success = YES;
                        
                        if( success)
                        {
                            [comparativeStudyWaited release];
                            comparativeStudyWaited = nil;
                            
                            if( comparativeStudyWaitedToOpen && comparativeStudyWaitedViewer)
                            {
                                if( comparativeStudyWaitedViewer.window.isVisible)
                                    [comparativeStudyWaitedViewer loadSelectedSeries: study rightClick: NO];
                            }
                            else if( comparativeStudyWaitedToOpen)
                                [self databaseOpenStudy: study];
                            
                            if( [[self window] firstResponder] != searchField && [[self window] firstResponder] != searchField.currentEditor)
                                [[self window] makeFirstResponder: databaseOutline];
                            
                            [comparativeStudyWaitedViewer release];
                            comparativeStudyWaitedViewer = nil;
                        }
                    }
                    else
                    {
                        [comparativeStudyWaited release];
                        comparativeStudyWaited = nil;
                        
                        [comparativeStudyWaitedViewer release];
                        comparativeStudyWaitedViewer = nil;
                    }
                }
            }
        }
        else
        {
            [comparativeStudyWaited release];
            comparativeStudyWaited = nil;
            
            [comparativeStudyWaitedViewer release];
            comparativeStudyWaitedViewer = nil;
        }
    }
}

- (void)_newStudiesRefreshComparativeStudies: (NSNotification *)aNotification
{
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"***** We must be on MAIN thread");
    
    if( _database == nil)
        return;
    
    NSArray *newStudies = [aNotification.userInfo objectForKey: OsirixAddToDBNotificationImagesArray];
    
    for( DicomStudy *newStudy in newStudies)
    {
        if( self.comparativePatientUID && [self.comparativePatientUID compare: newStudy.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
        {
            NSMutableArray *copy = [NSMutableArray arrayWithArray: self.comparativeStudies];
            
            id selectedStudy = nil;
            if( [comparativeTable selectedRow] >= 0)
                selectedStudy = [copy objectAtIndex: [comparativeTable selectedRow]];
            
            BOOL found = NO;
#ifndef OSIRIX_LIGHT
            for( DCMTKStudyQueryNode *study in self.comparativeStudies)
            {
                if( [study.studyInstanceUID isEqualToString: newStudy.studyInstanceUID])
                {
                    found = YES;
                    if( [study isKindOfClass: [DCMTKStudyQueryNode class]])
                    {
                        NSUInteger index = [copy indexOfObject: study];
                        if( index != NSNotFound)
                            [copy replaceObjectAtIndex: index withObject: newStudy];
                    }
                }
            }
#endif
            
            if( found == NO)
            {
                [copy addObject: newStudy];
                [copy sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"date" ascending: NO]]];
            }
            
            self.comparativeStudies = copy;
            
            [comparativeTable reloadData];
            
            if( selectedStudy)
            {
                NSUInteger index = [[copy valueForKey: @"studyInstanceUID"] indexOfObject: [selectedStudy valueForKey: @"studyInstanceUID"]];
                
                if( index != NSNotFound)
                    [comparativeTable selectRowIndexes: [NSIndexSet indexSetWithIndex: index] byExtendingSelection: NO];
            }
        }
    }
}

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"***** We must be on MAIN thread");
    
    @synchronized (self)
    {
        _cachedAlbumsContext = nil;
    }
    
    if( loadingIsOver == NO) return;
    
    @try
    {
        [cachedFilesForDatabaseOutlineSelectionSelectedFiles release]; cachedFilesForDatabaseOutlineSelectionSelectedFiles = nil;
        [cachedFilesForDatabaseOutlineSelectionCorrespondingObjects release]; cachedFilesForDatabaseOutlineSelectionCorrespondingObjects = nil;
        [cachedFilesForDatabaseOutlineSelectionTreeObjects release]; cachedFilesForDatabaseOutlineSelectionTreeObjects = nil;
        [cachedFilesForDatabaseOutlineSelectionIndex release]; cachedFilesForDatabaseOutlineSelectionIndex = nil;
        
        NSIndexSet *index = [databaseOutline selectedRowIndexes];
        id item = [databaseOutline itemAtRow:[index firstIndex]];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"])
        {
            if( previousItem)
                [databaseOutline setNeedsDisplay: YES];
        }
        
        if( item)
        {
            if( [item isDistant])
            {
                // Check to see if already in retrieving mode, if not download it
                // [self retrieveComparativeStudy: item select: YES open: NO]; -- Only when double-clicking
            }
            else
            {
                /**********
                 post notification of new selected item. Can be used by plugins to update RIS connection
                 **********/
                DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
                
                NSDictionary *userInfo = nil;
                if( studySelected)
                {
                    userInfo = [NSDictionary dictionaryWithObject:studySelected forKey: @"Selected Study"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixNewStudySelectedNotification object:self userInfo:(NSDictionary *)userInfo];
                }
            }
            
            BOOL refreshMatrix = YES;
            long nowFiles = [[item valueForKey:@"noFiles"] intValue];
            
            if( item == previousItem || ([previousItem isKindOfClass: [NSManagedObject class]] && [item isKindOfClass: [NSManagedObject class]] && [[previousItem objectID] isEqual: [item objectID]]))
            {
                if( nowFiles == previousNoOfFiles)
                    refreshMatrix = NO;
            }
            else
                DatabaseIsEdited = NO;
            
            previousNoOfFiles = nowFiles;
            
            if( refreshMatrix)
            {
                NSArray *files = nil;
                NSMutableArray *selectedRowColumns = [NSMutableArray array], *selectedCellsIDs = [NSMutableArray array];
                BOOL imageLevel = NO;
                
                [self.database lock];
                @try {
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
                    
                    if( item == previousItem || ([previousItem isKindOfClass: [NSManagedObject class]] && [item isKindOfClass: [NSManagedObject class]] && [[previousItem objectID] isEqual: [item objectID]]))
                    {
                        for( NSButtonCell *cell in oMatrix.cells)
                        {
                            NSInteger row, column;
                            if( cell.state == NSOnState && cell.isTransparent == NO && [oMatrix getRow: &row column: &column ofCell: cell])
                            {
                                if (cell.representedObject)
                                {
                                    [selectedCellsIDs addObject: [cell representedObject]]; // For NSMainThread situation
                                    [selectedRowColumns addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInteger: row], @"row", [NSNumber numberWithInteger: column], @"column", nil]]; //For background thread situation
                                }
                            }
                        }
                    }
                    else
                        [oMatrix selectCellWithTag: 0];
                    
                    [self matrixInit: matrixViewArray.count];
                    
                    files = [self imagesArray: item preferredObject:oFirstForFirst];
                    imageLevel = [item isKindOfClass:[DicomSeries class]];
                    
                    @synchronized( previewPixThumbnails)
                    {
                        for (unsigned int i = 0; i < [files count]; i++) [previewPixThumbnails addObject:notFoundImage];
                    }
                } @catch (NSException* e) {
                    N2LogExceptionWithStackTrace(e);
                } @finally {
                    [self.database unlock];
                }
                
                BOOL separateThread = YES;
                if( imageLevel == NO) // If series level, and less than 5 thumbnails to compute: do it on main thread: faster, and no-blinking icons...
                {
                    int thumbnailsToGenerate = 0;
                    for( DicomImage* im in files)
                    {
                        if( [im.series primitiveValueForKey:@"thumbnail"] == nil)
                            thumbnailsToGenerate++;
                    }
                    
                    if( thumbnailsToGenerate < 5)
                        separateThread = NO;
                }
                
                @synchronized( previewPixThumbnails)
                {
                    [matrixLoadIconsThread cancel];
                    [matrixLoadIconsThread release];
                    matrixLoadIconsThread = nil;
                    
                    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: _database, @"DicomDatabase", [files valueForKey:@"objectID"], @"objectIDs", [NSNumber numberWithBool: imageLevel], @"imageLevel", previewPix, @"Context", _database, @"DicomDatabase", nil];
                    if( separateThread)
                    {
                        matrixLoadIconsThread = [[NSThread alloc] initWithTarget: self selector: @selector(matrixLoadIcons:) object: dict];
                        [matrixLoadIconsThread start];
                        
                        if( item == previousItem || ([previousItem isKindOfClass: [NSManagedObject class]] && [item isKindOfClass: [NSManagedObject class]] && [[previousItem objectID] isEqual: [item objectID]]))
                        {
                            for( NSCell *cell in [oMatrix cells])
                            {
                                [cell setState: NSOffState];
                                [cell setHighlighted: NO];
                            }
                            
                            for( NSDictionary *d in selectedRowColumns)
                            {
                                NSCell *cell = [oMatrix cellAtRow: [[d objectForKey: @"row"] intValue] column: [[d objectForKey: @"column"] intValue]];
                                [cell setState: NSOnState];
                                [cell setHighlighted: YES];
                            }
                        }
                    }
                    else
                    {
                        [self matrixLoadIcons: dict];
                        if( item == previousItem || ([previousItem isKindOfClass: [NSManagedObject class]] && [item isKindOfClass: [NSManagedObject class]] && [[previousItem objectID] isEqual: [item objectID]]))
                        {
                            [oMatrix deselectAllCells];
                            BOOL first = YES;
                            for( NSCell *cell in [oMatrix cells])
                            {
                                if( [selectedCellsIDs containsObject: [cell representedObject]])
                                {
                                    if( first) {
                                        [oMatrix selectCell: cell];
                                        first = NO;
                                    }
                                    else {
                                        [cell setHighlighted: YES];
                                        [cell setState: NSOnState];
                                    }
                                }
                            }
                            
                            [self matrixPressed: oMatrix];
                        }
                    }
                }
            }
            
            if( previousItem != item)
            {
                [previousItem release];
                previousItem = [item retain];
                
                // COMPARATIVE STUDIES
                id studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
                
                if( [[studySelected valueForKey: @"patientUID"] compare: self.comparativePatientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
                {
                    self.comparativePatientUID = [studySelected valueForKey: @"patientUID"];
                    self.comparativeStudies = nil;
                    [comparativeTable reloadData];
                    [[[comparativeTable tableColumnWithIdentifier:@"Cell"] headerCell] setStringValue: NSLocalizedString( @"History", nil)];
                    
                    id object = nil;
                    if( [studySelected isKindOfClass: [DicomStudy class]])
                        object = [studySelected objectID];
                    else
                        object = studySelected; // DCMTKStudyQueryNode
                    
                    [NSThread detachNewThreadSelector: @selector(searchForComparativeStudies:) toTarget:self withObject: object];
                }
                else
                {
                    NSUInteger index = [[self.comparativeStudies valueForKey: @"studyInstanceUID"] indexOfObject: [studySelected valueForKey: @"studyInstanceUID"]];
                    if( index != NSNotFound)
                    {
                        [comparativeTable selectRowIndexes: [NSIndexSet indexSetWithIndex: index] byExtendingSelection: NO];
                        [comparativeTable scrollRowToVisible: [comparativeTable selectedRow]];
                    }
                }
            }
            
            if( [item isDistant])
                self.distantStudyMessage = NSLocalizedString( @"Double-click on the Study line to retrieve the images", nil);
            else
                self.distantStudyMessage = @"";
            
            [self resetROIsAndKeysButton];
        }
        else
        {
            [oMatrix selectCellWithTag: 0];
            [self matrixInit: 0];
            
            [previousItem release];
            previousItem = nil;
            
            ROIsAndKeyImagesButtonAvailable = NO;
            
            self.distantStudyMessage = @"";
            self.comparativePatientUID = nil;
            self.comparativeStudies = nil;
            [comparativeTable reloadData];
            [[[comparativeTable tableColumnWithIdentifier:@"Cell"] headerCell] setStringValue: NSLocalizedString( @"History", nil)];
        }
        
        [self splitView:splitViewVert resizeSubviewsWithOldSize:[splitViewVert bounds].size];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
}

- (void) selectDatabaseOutline
{
    [[self window] makeFirstResponder: databaseOutline];
}

- (void) refreshMatrix:(id) sender
{
    [previousItem release];
    previousItem = nil;	// This will force the matrix update
    
    BOOL firstResponderMatrix = NO;
    
    if( [[self window] firstResponder] == oMatrix && [[self window] firstResponder] != searchField && [[self window] firstResponder] != searchField.currentEditor)
    {
        [[self window] makeFirstResponder: databaseOutline];
        firstResponderMatrix = YES;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: nil];
    
    [imageView display];
    
    if( firstResponderMatrix && [[self window] firstResponder] != searchField && [[self window] firstResponder] != searchField.currentEditor)
        [[self window] makeFirstResponder: oMatrix];
}

- (void) mergeSeriesExecute:(NSArray*) seriesArray
{
    NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Merge Series", nil), NSLocalizedString(@"Are you sure you want to merge the selected series? It cannot be cancelled.\r\rWARNING! If you merge multiple patients, the Patient Name and ID will be identical.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
    
    if( result == NSAlertDefaultReturn)
    {
        NSManagedObjectContext	*context = self.database.managedObjectContext;
        
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
            
            // TODO: when merging multiframe series, we should reevaluate the instanceNumbers in order to have a well-sorted [DicomSeries sortedImages] array
            
            [destSeries setValue:[NSNumber numberWithInt:0] forKey:@"numberOfImages"];
            
            [_database save:NULL];
            
            [self outlineViewRefresh];
            
            [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: study]] byExtendingSelection: NO];
            [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
            
            [self refreshMatrix: self];
        }
        
        [context unlock];
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

#ifndef OSIRIX_LIGHT
- (IBAction) unifyStudies:(id) sender
{
    [ViewerController closeAllWindows];
    
    DicomStudy *destStudy = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
    if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
    
    NSInteger result = NSRunInformationalAlertPanel( [NSString stringWithFormat: NSLocalizedString(@"Unify Patient Identity to: %@", nil), destStudy.name], [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to unify the patient identity of the selected studies? It cannot be cancelled. You can choose to modify the database fields only, or also change the DICOM files headers with the new values.\r\rWARNING! The Patient Name and ID will be identical for all these studies to the last selected study (%@ - %@).\r\rThe original Patient Name and Patient ID will be saved in the OtherPatientNames and OtherPatientIDs DICOM fields.", nil), destStudy.name, destStudy.patientID], NSLocalizedString(@"Database & DICOM",nil), NSLocalizedString(@"Database only",nil), NSLocalizedString(@"Cancel",nil), nil);
    
    if( result == NSAlertDefaultReturn || result == NSAlertAlternateReturn)
    {
        NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
        
        if( result == NSAlertDefaultReturn)
        {
            // Now modify the DICOM files
            for( NSInteger x = 0; x < [selectedRows count] ; x++)
            {
                NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
                
                DicomStudy *study = [databaseOutline itemAtRow: row];
                
                if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
                
                if( study != destStudy)
                {
                    if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
                    {
                        NSInteger confirm = NSRunInformationalAlertPanel(NSLocalizedString(@"Unify Patient Identity", nil), NSLocalizedString(@"Do you confirm to DEFINITIVELY change this patient identity:\r\r%@ / %@ / %@\r\rto this new identity:\r\r%@ / %@ ?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, study.name, study.patientID, study.studyName, destStudy.name, destStudy.patientID);
                        
                        if( confirm == NSAlertDefaultReturn)
                        {
                            WaitRendering *wait = [[[WaitRendering alloc] init: NSLocalizedString(@"Updating files...", nil)] autorelease];
                            [wait showWindow:self];
                            
                            NSMutableArray *params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--ignore-errors", nil];
                            
                            DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [[[destStudy paths] allObjects] objectAtIndex: 0] decodingPixelData: NO];
                            
                            NSString *originalPatientName = [dcmObject attributeValueWithName:@"PatientsName"];
                            NSString *originalBirthDate = [dcmObject attributeValueWithName:@"PatientsBirthDate"];
                            
                            NSString *existingOtherPatientNames = [dcmObject attributeValueWithName:@"OtherPatientIDs"];
                            NSString *existingOtherPatientIDs = [dcmObject attributeValueWithName:@"OtherPatientNames"];
                            
                            if( existingOtherPatientNames == nil)
                                existingOtherPatientNames = @"";
                            
                            if( existingOtherPatientIDs == nil)
                                existingOtherPatientIDs = @"";
                            
                            if( existingOtherPatientNames.length)
                                existingOtherPatientNames = [existingOtherPatientNames stringByAppendingString: @" - "];
                            
                            if( existingOtherPatientIDs.length)
                                existingOtherPatientIDs = [existingOtherPatientIDs stringByAppendingString: @" - "];
                            
                            existingOtherPatientNames = [existingOtherPatientNames stringByAppendingString: study.name];
                            existingOtherPatientIDs = [existingOtherPatientIDs stringByAppendingString: study.patientID];
                            
                            if( originalPatientName)
                            {
                                //                                NSString *logLine = [NSString stringWithFormat: @"---- Patient Unify: %@ %@ -> %@ %@", study.name, study.patientID, destStudy.name, destStudy.patientID, nil];
                                
                                [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0020)", destStudy.patientID], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0010)", originalPatientName], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0030)", originalBirthDate], nil]];
                                [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,1000)", existingOtherPatientIDs], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,1001)", existingOtherPatientNames], nil]];
                                
                                
                                NSArray* tagAndValues = [NSArray arrayWithObjects:
                                                                                    [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0020)"],(destStudy.patientID?destStudy.patientID:@""),nil],
                                                                                    [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0010)"],(originalPatientName?originalPatientName:@""),nil],
                                                                                    [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0030)"],(originalBirthDate?originalBirthDate:@""),nil],
                                                                                    [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,1000)"],(existingOtherPatientIDs?existingOtherPatientIDs:@""),nil],
                                                                                    [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,1001)"],(existingOtherPatientNames?existingOtherPatientNames:@""),nil],
                                nil];
                                
                                
                                NSMutableArray *files = [NSMutableArray arrayWithArray:[[study paths] allObjects]];
                                
                                if (files)
                                {
                                    [files removeDuplicatedStrings];
                                    
                                    [params addObjectsFromArray: files];
                                    
                                    @try
                                    {
                                        //NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: [files lastObject]] objectAtIndex: 0]];
                                        //[XMLController modifyDicom: params encoding: encoding];
                                        
                                        [XMLController modifyDicom:tagAndValues dicomFiles:files];
                                        
                                        for( id loopItem in files)
                                        {
                                            [[NSFileManager defaultManager] removeItemAtPath:[loopItem stringByAppendingString:@".bak"] error:NULL];
                                        }
                                    }
                                    @catch (NSException * e)
                                    {
                                        NSLog(@"**** DicomStudy setComment: %@", e);
                                    }
                                }
                                
                                [wait close];
                            }
                            else
                            {
                                [wait close];
                                
                                NSRunCriticalAlertPanel( NSLocalizedString(@"Unify Patient Identity", nil), NSLocalizedString( @"Failed to change the DICOM files", nil), NSLocalizedString(@"OK",nil), nil, nil);
                            }
                        }
                        else return;
                    }
                }
            }
        }
        
        for( NSInteger x = 0; x < [selectedRows count] ; x++)
        {
            NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
            
            DicomStudy *study = [databaseOutline itemAtRow: row];
            if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
            
            if( study != destStudy)
            {
                if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
                {
                    NSInteger confirm = NSAlertDefaultReturn;
                    
                    if( result == NSAlertAlternateReturn)
                        confirm = NSRunInformationalAlertPanel(NSLocalizedString(@"Unify Patient Identity", nil), NSLocalizedString(@"Do you confirm to DEFINITIVELY change this patient identity:\r\r%@ / %@ / %@\r\rto this new identity:\r\r%@ / %@ ?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, study.name, study.patientID, study.studyName, destStudy.name, destStudy.patientID);
                    
                    if( confirm == NSAlertDefaultReturn)
                    {
                        [study setValue: destStudy.patientID forKey: @"patientID"];
                        [study setValue: [destStudy valueForKey:@"patientUID"]  forKey: @"patientUID"];
                        [study setValue: destStudy.name  forKey: @"name"];
                        
                        NSLog( @"---- Patient Unify: %@ %@ -> %@ %@", [study valueForKey:@"accessionNumber"], study.patientID, [destStudy valueForKey:@"accessionNumber"], destStudy.patientID);
                    }
                }
            }
        }
        
        [_database save: nil];
        
        [self outlineViewRefresh];
        
        [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: destStudy]] byExtendingSelection: NO];
        [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
        
        [self refreshMatrix: self];
        
        [self refreshPACSOnDemandResults: self];
    }
}

- (IBAction) mergeStudies:(id) sender
{
    [ViewerController closeAllWindows];
    
    // Is it only series??
    NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
    BOOL	onlySeries = YES;
    NSMutableArray	*seriesArray = [NSMutableArray array];
    
    NSInteger row = 0;
    for( NSInteger x = 0; x < [selectedRows count] ; x++)
    {
        row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
        NSManagedObject	*series = [databaseOutline itemAtRow: row];
        if( [[series valueForKey:@"type"] isEqualToString: @"Series"] == NO) onlySeries = NO;
        
        [seriesArray addObject: series];
    }
    
    if( onlySeries)
    {
        [self mergeSeriesExecute: seriesArray];
        return;
    }
    
    // The destination study : prefer DICOM study
    DicomStudy	*destStudy = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
    if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
    
    NSString *nameAndStudy = [NSString stringWithFormat: @"%@ / %@", destStudy.name, destStudy.studyName];
    
    NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Merge Studies", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to merge the selected studies to: \r\r%@\r\rIt cannot be cancelled.\r\rWARNING! If you merge multiple different patients, the Patient Name, ID and Study Description will be identical.\r\rYou can choose to modify the database fields only, or also change the DICOM files headers with the new values.", nil), nameAndStudy], NSLocalizedString(@"Database & DICOM",nil), NSLocalizedString(@"Database only",nil), NSLocalizedString(@"Cancel",nil), nil);
    
    if( result == NSAlertDefaultReturn || result == NSAlertAlternateReturn)
    {
        NSManagedObjectContext	*context = self.database.managedObjectContext;
        
        NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
        
        if( result == NSAlertDefaultReturn)
        {
            // Now modify the DICOM files
            for( NSInteger x = 0; x < [selectedRows count] ; x++)
            {
                NSInteger row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
                
                DicomStudy *study = [databaseOutline itemAtRow: row];
                if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
                
                if( study != destStudy)
                {
                    if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
                    {
                        NSInteger confirm = NSRunInformationalAlertPanel(NSLocalizedString(@"Merge Studies", nil), NSLocalizedString(@"Do you confirm to DEFINITIVELY change this study identity to this new identity:\r\r%@ / %@ ?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, destStudy.name, destStudy.studyName);
                        
                        if( confirm == NSAlertDefaultReturn)
                        {
                            NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--ignore-errors", nil];
                            
                            DCMObject *dcmObject = [DCMObject objectWithContentsOfFile: [[[destStudy paths] allObjects] objectAtIndex: 0] decodingPixelData: NO];
                            
                            NSString *originalPatientName = [dcmObject attributeValueWithName:@"PatientsName"];
                            NSString *originalBirthDate = [dcmObject attributeValueWithName:@"PatientsBirthDate"];
                            NSString *originalStudyID = [dcmObject attributeValueWithName:@"StudyID"];
                            NSString *originalStudyInstanceUID = [dcmObject attributeValueWithName:@"StudyInstanceUID"];
                            NSString *originalStudyDescription = [dcmObject attributeValueWithName:@"StudyDescription"];
                            
                            NSString *existingOtherPatientNames = [dcmObject attributeValueWithName:@"OtherPatientIDs"];
                            NSString *existingOtherPatientIDs = [dcmObject attributeValueWithName:@"OtherPatientNames"];
                            
                            if( existingOtherPatientNames == nil)
                                existingOtherPatientNames = @"";
                            
                            if( existingOtherPatientIDs == nil)
                                existingOtherPatientIDs = @"";
                            
                            if( existingOtherPatientNames.length)
                                existingOtherPatientNames = [existingOtherPatientNames stringByAppendingString: @" - "];
                            
                            if( existingOtherPatientIDs.length)
                                existingOtherPatientIDs = [existingOtherPatientIDs stringByAppendingString: @" - "];
                            
                            existingOtherPatientNames = [existingOtherPatientNames stringByAppendingString: study.name];
                            existingOtherPatientIDs = [existingOtherPatientIDs stringByAppendingString: study.patientID];
                            
                            if( originalPatientName)
                            {
                                //                                NSString *logLine = [NSString stringWithFormat: @"---- Study Unify: %@ %@ -> %@ %@", study.name, study.patientID, destStudy.name, destStudy.patientID, nil];
                                
                                NSMutableArray* tagAndValues = [NSMutableArray array];
                                
                                if( [destStudy.patientID isEqualToString: study.patientID] == NO || [destStudy.name isEqualToString: study.name] == NO)
                                {
                                    [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0020)", destStudy.patientID], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0010)", originalPatientName], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,0030)", originalBirthDate], nil]];
                                    [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,1000)", existingOtherPatientIDs], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0010,1001)", existingOtherPatientNames], nil]];
                                    
                                    [tagAndValues addObjectsFromArray:[NSArray arrayWithObjects:
                                                                                                [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0020)"],(destStudy.patientID?destStudy.patientID:@""),nil],
                                                                                                [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0010)"],(originalPatientName?originalPatientName:@""),nil],
                                                                                                [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,0030)"],(originalBirthDate?originalBirthDate:@""),nil],
                                                                                                [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,1000)"],(existingOtherPatientIDs?existingOtherPatientIDs:@""),nil],
                                                                                                [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0010,1001)"],(existingOtherPatientNames?existingOtherPatientNames:@""),nil],
                                                                                                nil]];
                                }
                                
                                [params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", @"(0020,0010)", originalStudyID], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0020,000D)", originalStudyInstanceUID], @"-i", [NSString stringWithFormat: @"%@=%@", @"(0008,1030)", originalStudyDescription], nil]];
                                
                                [tagAndValues addObjectsFromArray:[NSArray arrayWithObjects:
                                                                                            [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0020,0010)"],(originalStudyID?originalStudyID:@""),nil],
                                                                                            [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0020,000D)"],(originalStudyInstanceUID?originalStudyInstanceUID:@""),nil],
                                                                                            [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:@"(0008,1030)"],(originalStudyDescription?originalStudyDescription:@""),nil],
                                                                                            nil]];
                                
                                NSMutableArray *files = [NSMutableArray arrayWithArray: [[study paths] allObjects]];
                                
                                if( files)
                                {
                                    [files removeDuplicatedStrings];
                                    
                                    [params addObjectsFromArray: files];
                                    
                                    @try
                                    {
                                        //NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: [files lastObject]] objectAtIndex: 0]];
                                        //[XMLController modifyDicom: params encoding: encoding];
                                        
                                        [XMLController modifyDicom:tagAndValues dicomFiles:files];
                                        
                                        for( id loopItem in files)
                                        {
                                            [[NSFileManager defaultManager] removeItemAtPath: [loopItem stringByAppendingString:@".bak"] error:NULL];
                                        }
                                    }
                                    @catch (NSException * e)
                                    {
                                        NSLog(@"**** DicomStudy setComment: %@", e);
                                    }
                                }
                            }
                            else
                                NSRunCriticalAlertPanel( NSLocalizedString(@"Unify Study Identity", nil), NSLocalizedString( @"Failed to change the DICOM files", nil), NSLocalizedString(@"OK",nil), nil, nil);
                        }
                        else return;
                    }
                }
            }
        }
        
        NSLog(@"MERGING STUDIES: %@", destStudy);
        
        NSInteger row = 0;
        for( NSInteger x = 0; x < [selectedRows count] ; x++)
        {
            row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
            
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
    }
}
#endif

- (void) proceedDeleteObjects: (NSArray*) objectsToDelete tree:(NSSet*)treeObjs
{
    if( [NSThread isMainThread] == NO)
        N2LogStackTrace( @"************ This is a MAIN thread only function");
    
    DicomDatabase* database = [_database retain];
    BOOL refreshComparative = NO;
    
    NSMutableSet *seriesSet = [NSMutableSet set], *studiesSet = [NSMutableSet set];
    
    [reportFilesToCheck removeAllObjects];
    
    [database lock];
    
    @try
    {
        NSManagedObject	*study = nil, *series = nil;
        
        NSLog(@"objects to delete : %d", (int) [objectsToDelete count]);
        
        for( NSManagedObject *obj in objectsToDelete)
        {
            @autoreleasepool
            {
                // ********* SERIES
                if( [obj valueForKey:@"series"] != series)
                {
                    series = [obj valueForKey:@"series"];
                    
                    if([seriesSet containsObject: series] == NO)
                    {
                        if( series)
                            [seriesSet addObject: series];
                        
                        // Is a viewer containing this series opened? -> close it
                        for( ViewerController *vc in [ViewerController getDisplayed2DViewers])
                        {
                            if( series == [[[vc fileList] objectAtIndex: 0] valueForKey:@"series"])
                                [[vc window] close];
                        }
                    }
                    
                    // ********* STUDY
                    if( [series valueForKey:@"study"] != study)
                    {
                        study = [series valueForKey:@"study"];
                        
                        if([studiesSet containsObject: study] == NO)
                        {
                            if( study)
                                [studiesSet addObject: study];
                            
                            // Is a viewer containing this series opened? -> close it
                            for( ViewerController *vc in [ViewerController getDisplayed2DViewers])
                            {
                                if( study == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
                                    [vc buildMatrixPreview];
                            }
                        }
                    }
                }
            }
        }
        
        for ( NSManagedObject *obj in objectsToDelete)
            [database.managedObjectContext deleteObject:obj];
        
    }
    @catch ( NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    for (NSManagedObject* o in treeObjs)
        if ([o isKindOfClass:[DicomSeries class]])
            [studiesSet addObject:[o valueForKey: @"study"]];
        else if ([o isKindOfClass:[DicomStudy class]])
            [studiesSet addObject:o];
    
    @try
    {
        // Remove series without images !
        for (DicomSeries* series in seriesSet)
        {
            @autoreleasepool
            {
                @try
                {
                    if ([series isDeleted] == NO)
                    {
                        if ([series.images count] == 0)
                        {
                            [database.managedObjectContext deleteObject:series];
                        }
                        else
                        {
                            series.numberOfImages = [NSNumber numberWithInt:0];
                            series.thumbnail = nil;
                        }
                    }
                }
                @catch (NSException* e)
                {
                    N2LogExceptionWithStackTrace(e/*, @"context deleteObject: series"*/);
                }
            }
        }
        
        // Remove studies without series !
        for( DicomStudy *study in studiesSet)
        {
            @autoreleasepool
            {
                @try
                {
                    if( self.comparativePatientUID && [self.comparativePatientUID compare: study.patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
                        refreshComparative = YES;
                    
                    if( [study isDeleted] == NO)
                    {
                        if( [study.imageSeries count] == 0)
                        {
                            NSLog( @"Delete Study: %@ - %@", study.patientID, study.studyInstanceUID);
                            
                            [database.managedObjectContext deleteObject:study];
                        }
                        else
                        {
                            [study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
                            [study setValue:[study valueForKey: @"modalities"] forKey:@"modality"];
                        }
                    }
                }
                @catch( NSException *e)
                {
                    N2LogExceptionWithStackTrace(e/*, @"context deleteObject: study"*/);
                }
            }
        }
        
        [previousItem release];
        previousItem = nil;
    }
    @catch( NSException *ne)
    {
        N2LogExceptionWithStackTrace(ne);
    }
    
    for( DicomStudy *study in studiesSet)
        [study noFiles];
    [database save];
    [database unlock];
    [database release];
    
    [self outlineViewRefresh];
    [self refreshAlbums];
    
    if( refreshComparative)
    {
        NSManagedObject *item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
        DicomStudy *studySelected = [[item valueForKey: @"type"] isEqualToString: @"Study"] ? item : [item valueForKey: @"study"];
        
        id object = nil;
        if( [studySelected isKindOfClass: [DicomStudy class]])
            object = [studySelected objectID];
        else
            object = studySelected;
        
        [NSThread detachNewThreadSelector: @selector(searchForComparativeStudies:) toTarget:self withObject: object];
    }
}

- (void) proceedDeleteObjects:(NSArray*)objectsToDelete
{
    [self proceedDeleteObjects:objectsToDelete tree:nil];
}

- (void) delObjects:(NSMutableArray*) objectsToDelete tree:(NSMutableSet*)treeObjs
{
    int result;
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
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
                [e printStackTrace];
            }
        }
        
        if( cancelled == NO)
        {
            NSLog( @"locked images: %d", (int) [lockedImages count]);
            
            // Try to find images that aren't stored in the local database
            
            NSMutableArray	*nonLocalImagesPath = [NSMutableArray array];
            
            WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Deleting...", nil)];
            [wait showWindow:self];
            
            nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
            
            if( [nonLocalImagesPath  count] > 0)
            {
                [wait.window orderOut: self];
                
                NSLog(@"non-local images : %d", (int) [nonLocalImagesPath count]);
                
                result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", nil), NSLocalizedString(@"Some of the selected images are not stored in the Database folder. Do you want to only remove the links of these images from the database or also delete the original files?", nil), NSLocalizedString(@"Remove the links",nil),  NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Delete the files",nil));
                
                [wait.window makeKeyAndOrderFront: self];
            }
            else result = NSAlertDefaultReturn;
            
            @try
            {
                if( result == NSAlertAlternateReturn)
                {
                    NSLog( @"Cancel");
                }
                else
                {
                    if( result == NSAlertDefaultReturn || result == NSAlertOtherReturn)
                        [self proceedDeleteObjects:objectsToDelete tree:treeObjs];
                    
                    if( result == NSAlertOtherReturn)
                    {
                        for( NSString *path in nonLocalImagesPath)
                        {
                            [[NSFileManager defaultManager] removeItemAtPath: path error:NULL];
                            
                            if( [[path pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
                            {
                                [[NSFileManager defaultManager] removeItemAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] error:NULL];
                            }
                            
                            NSString *currentDirectory = [[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
                            NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentDirectory error:NULL];
                            
                            //Is this directory empty?? If yes, delete it!
                            
                            if( [dirContent count] == 0) [[NSFileManager defaultManager] removeItemAtPath:currentDirectory error:NULL];
                            if( [dirContent count] == 1)
                            {
                                if( [[[dirContent objectAtIndex: 0] uppercaseString] hasSuffix:@".DS_STORE"]) [[NSFileManager defaultManager] removeItemAtPath:currentDirectory error:NULL];
                            }
                        }
                    }
                }
            }
            @catch (NSException * e) { NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e); }
            [wait close];
            [wait autorelease];
            wait = nil;
        }
    }
    
    [context unlock];
    
    [self refreshMatrix: self];
    
#ifndef OSIRIX_LIGHT
    [[QueryController currentQueryController] executeRefresh: self];
    [[QueryController currentAutoQueryController] executeRefresh: self];
#endif
}

- (void) delObjects:(NSMutableArray*) objectsToDelete {
    [self delObjects:objectsToDelete tree:nil];
}

- (IBAction)delItem: (id)sender
{
    if (self.database.isReadOnly)
        return;
    
    NSInteger				result;
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    BOOL					matrixThumbnails = YES;
    int						animState = [animationCheck state];
    
    //	if( DICOMDIRCDMODE)
    //	{
    //		NSRunInformationalAlertPanel(NSLocalizedString(@"OsiriX CD/DVD", nil), NSLocalizedString(@"OsiriX is running in read-only mode, from a CD/DVD.", nil), NSLocalizedString(@"OK",nil), nil, nil);
    //		return;
    //	}*/
    
    
    if( sender == nil)
    {
        matrixThumbnails = NO;
    }
    else
    {
        if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
            matrixThumbnails = YES;
        
        if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [databaseOutline menu]) || [[self window] firstResponder] == databaseOutline || [[self window] firstResponder] == comparativeTable)
            matrixThumbnails = NO;
    }
    
    if( matrixThumbnails == NO && [databaseOutline selectedRow] == -1)
        return;
    
    NSString *level = nil;
    
    if( matrixThumbnails)
        level = NSLocalizedString( @"Selected Thumbnails", nil);
    else
        level = NSLocalizedString( @"Selected Lines", nil);
    
    if( matrixThumbnails == NO)
    {
        BOOL onlyDistantStudy = YES;
        
        if( [[databaseOutline selectedRowIndexes] count] > 0)
        {
            NSUInteger idx = databaseOutline.selectedRowIndexes.firstIndex;
            
            while (idx != NSNotFound)
            {
                id object = [databaseOutline itemAtRow: idx];
                
                if( [object isDistant] == NO)
                {
                    onlyDistantStudy = NO;
                    break;
                }
                
                idx = [databaseOutline.selectedRowIndexes indexGreaterThanIndex: idx];
            }
        }
        
        if( onlyDistantStudy)
        {
            NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), NSLocalizedString(@"These studies are not stored locally, you cannot delete them", nil), NSLocalizedString(@"OK",nil), nil, nil);
            return;
        }
    }
    
    [animationCheck setState: NSOffState];
    
    NSArray *albumArray = self.albumArray;
    
    if( albumTable.selectedRow > 0 && matrixThumbnails == NO)
    {
        NSManagedObject	*album = [albumArray objectAtIndex: albumTable.selectedRow];
        
        if( [[album valueForKey:@"smartAlbum"] boolValue] == NO)
            result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", nil), NSLocalizedString(@"Do you want to only remove the selected images from the current album or delete them from the database? (%@)", nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Remove from current album",nil), level);
        else
        {
            result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), NSLocalizedString(@"Are you sure you want to delete the selected images? (%@)", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, level);
        }
    }
    else
    {
        result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", nil), NSLocalizedString(@"Are you sure you want to delete the selected images? (%@)", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, level);
    }
    
    [context retain];
    [context lock];
    
    if( result == NSAlertOtherReturn)	// REMOVE FROM CURRENT ALBUMS, BUT DONT DELETE IT FROM THE DATABASE
    {
        NSIndexSet* selectedRows = [databaseOutline selectedRowIndexes];
        if (selectedRows.count)
        {
            NSMutableArray* studiesToRemove = [NSMutableArray array];
            DicomAlbum* album = [albumArray objectAtIndex:albumTable.selectedRow];
            
            for (NSInteger x = 0; x < selectedRows.count; ++x) {
                NSInteger row = (x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex:row];
                DicomStudy* study = [databaseOutline itemAtRow: row];
                
                if ([study isKindOfClass:[DicomStudy class]])
                    if ([album.studies containsObject:study] && ![studiesToRemove containsObject:study])
                        [studiesToRemove addObject:study];
            }
            
            NSMutableSet* albumStudies = [album mutableSetValueForKey: @"studies"];
            for (DicomStudy* study in studiesToRemove) {
                [albumStudies removeObject:study];
                [study archiveAnnotationsAsDICOMSR];
            }
            
            if (![_database isLocal]) // notify the remote database about the removal of the selected studies from the current album
                [(RemoteDicomDatabase*)_database removeStudies:studiesToRemove fromAlbum:album];
            
            [databaseOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:[selectedRows firstIndex]] byExtendingSelection:NO];
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
            N2LogExceptionWithStackTrace(ne);
        }
        
        [wait close];
        [wait autorelease];
        
        [self refreshMatrix: self];
        
#ifndef OSIRIX_LIGHT
        [[QueryController currentQueryController] executeRefresh: self];
        [[QueryController currentAutoQueryController] executeRefresh: self];
#endif
    }
    else if (![_database isLocal])
    {
        [context release];
        [context unlock];
        
        NSRunAlertPanel( NSLocalizedString(@"Distant Database", nil),  NSLocalizedString(@"You cannot modify a Distant Database.", nil), nil, nil, nil);
        
        [animationCheck setState: animState];
        
        return;
    }
    
    if( result == NSAlertDefaultReturn)	// REMOVE AND DELETE IT FROM THE DATABASE
    {
        NSMutableArray *objectsToDelete = [NSMutableArray array];
        NSMutableSet *objectsToDeleteTree = [NSMutableSet set];
        
        if( matrixThumbnails)
            [self filesForDatabaseMatrixSelection: objectsToDelete onlyImages: NO];
        else
            [self filesForDatabaseOutlineSelection: objectsToDelete treeObjects:objectsToDeleteTree onlyImages: NO];
        
        if( [databaseOutline selectedRow] >= 0)
        {
            NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
            
            [self delObjects:objectsToDelete tree:objectsToDeleteTree];
            
            [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [selectedRows firstIndex]] byExtendingSelection:NO];
        }
    }
    
    [context unlock];
    [context release];
    
    [animationCheck setState: animState];
}

- (void)buildColumnsMenu
{
    [columnsMenu release];
    columnsMenu = [[NSMenu alloc] initWithTitle:@""];
    [columnsMenu setDelegate:self];
    
    NSMutableArray* cols = [NSMutableArray array];
    for (NSTableColumn* col in [databaseOutline tableColumns])
        [cols addObject:[NSArray arrayWithObjects: col, [[col headerCell] stringValue], nil]];
    [cols sortUsingComparator: ^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 objectAtIndex:1] compare:[obj2 objectAtIndex:1]];
    }];
    
    for (NSArray* a in cols)
    {
        NSTableColumn* col = [a objectAtIndex:0];
        NSMenuItem* item = [columnsMenu addItemWithTitle:[[col headerCell] stringValue] action:@selector(columnsMenuAction:) keyEquivalent:@""];
        [item setRepresentedObject:[col identifier]];
    }
    
    [[databaseOutline headerView] setMenu:columnsMenu];
}

-(void)columnsMenuWillOpen {
    NSArray* cols = [databaseOutline tableColumns];
    NSArray* columnIdentifiers = [cols valueForKey:@"identifier"];
    for (NSMenuItem* mi in [columnsMenu itemArray]) {
        id ro = [mi representedObject];
        
        if ([ro isEqualToString:@"name"])
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HIDEPATIENTNAME"])
                [mi setState: NSOffState];
            else [mi setState: NSOnState];
        }
        else
        {
            NSInteger index = [columnIdentifiers indexOfObject:ro];
            if (index != NSNotFound && ![[cols objectAtIndex:index] isHidden])
                [mi setState: NSOnState];
            else [mi setState: NSOffState];
        }
    }
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
        
        [self refreshColumns];
    }
}

- (void)refreshColumns
{
    NSDictionary	*columnsDatabase	= [[NSUserDefaults standardUserDefaults] objectForKey: @"COLUMNSDATABASE"];
    NSEnumerator	*enumerator			= [columnsDatabase keyEnumerator];
    NSString		*key;
    
    //	[_database lock];
    @try
    {
        while( key = [enumerator nextObject])
        {
            NSInteger index = [[[[databaseOutline tableColumns] valueForKey:@"headerCell"] valueForKey:@"title"] indexOfObject: key];
            
            if( index != NSNotFound)
            {
                NSString	*identifier = [[[databaseOutline tableColumns] objectAtIndex: index] identifier];
                
                if( [databaseOutline isColumnWithIdentifierVisible: identifier] != [[columnsDatabase valueForKey: key] intValue])
                {
                    if( [[columnsDatabase valueForKey: key] intValue] == NO && [databaseOutline columnWithIdentifier: identifier] == [databaseOutline selectedColumn])
                        [databaseOutline selectColumnIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
                    
                    [databaseOutline setColumnWithIdentifier:identifier visible: [[columnsDatabase valueForKey: key] intValue]];
                    
                    if( [[columnsDatabase valueForKey: key] intValue] == NSOnState)
                    {
                        [databaseOutline scrollColumnToVisible: [databaseOutline columnWithIdentifier: identifier]];
                    }
                }
            }
        }
        
        [self buildColumnsMenu];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        //		[_database unlock];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (_database == nil) return nil;
    
    id returnVal = nil;
    
    //	[_database lock];
    
    @try
    {
        if( item == nil)
        {
            returnVal = [outlineViewArray objectAtIndex: index];
        }
        else
        {
#ifndef  OSIRIX_LIGHT
            if( [item isKindOfClass: [DCMTKStudyQueryNode class]])
                returnVal = [[item children]  objectAtIndex: index];
            else
#endif
                returnVal = [[self childrenArray: item] objectAtIndex: index];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    //	[_database unlock];
    
    return returnVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    BOOL returnVal = NO;
    
    //	[_database lock];
    
    if( [item isDistant])
    {
#ifndef OSIRIX_LIGHT
        if( [item isKindOfClass: [DCMTKStudyQueryNode class]])
            return YES;
        else
            return NO;
#endif
    }
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
        returnVal = NO;
    else returnVal = YES;
    
    //	[_database unlock];
    
    return returnVal;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if( _database == nil) return 0;
    
    int returnVal = 0;
    
    //	[_database lock];
    
    if (!item)
    {
        returnVal = [outlineViewArray count];
    }
    else
    {
#ifndef OSIRIX_LIGHT
        if( [item isDistant])
        {
            @try
            {
                if( [item isKindOfClass: [DCMTKStudyQueryNode class]])
                {
                    NSArray *children = [item children];
                    
                    if( children.count > 0 && [[children lastObject] isKindOfClass: [DCMTKStudyQueryNode class]] == NO && [[children lastObject] isKindOfClass: [DCMTKSeriesQueryNode class]] == NO)
                        [item purgeChildren];
                    
                    if (![item children])
                    {
                        [item queryWithValues:nil];
                        
                        if( [item children] == nil) // It failed... put an empty children...
                            [item setChildren: [NSMutableArray array]];
                    }
                }
                return  (item == nil) ? 0 : [[item children] count];
            }
            @catch (NSException * e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            
            return 0;
        }
        else
#endif
            if ([[item valueForKey:@"type"] isEqualToString:@"Image"]) returnVal = 0;
            else if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = [[item valueForKey:@"noFiles"] intValue];
        //else if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"series"] count];
            else if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"imageSeries"] count];
    }
    
    //	[_database unlock];
    
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
                
                [PluginManager startProtectForCrashWithFilter: filter];
                
                id returnValue = [filter reportDateForStudy: item];
                
                [PluginManager endProtectForCrash];
                
                return returnValue;
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
        if( [[item valueForKey:@"stateText"] intValue] == 0)
            return nil;
        else
            return [item valueForKey:@"stateText"];
    }
    
    if( [[tableColumn identifier] isEqualToString:@"lockedStudy"])
    {
        if ([[item valueForKey:@"type"] isEqualToString:@"Study"] == NO) return nil;
    }
    
    if( [[tableColumn identifier] isEqualToString:@"modality"])
    {
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
            
            if( [item isDistant])
                return name;
            
            return name; // [NSString stringWithFormat: NSLocalizedString( @"%@ (%d series)", nil), name, [[item valueForKey:@"imageSeries"] count]];
        }
    }
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Study"] == NO)
    {
        if( [[tableColumn identifier] isEqualToString:@"dateOfBirth"])			return @"";
        if( [[tableColumn identifier] isEqualToString:@"referringPhysician"])	return @"";
        if( [[tableColumn identifier] isEqualToString:@"performingPhysician"])	return @"";
        if( [[tableColumn identifier] isEqualToString:@"institutionName"])		return @"";
        if( [[tableColumn identifier] isEqualToString:@"patientID"])			return @"";
        if( [[tableColumn identifier] isEqualToString:@"yearOld"])				return @"";
        if( [[tableColumn identifier] isEqualToString:@"accessionNumber"])		return @"";
        if( [[tableColumn identifier] isEqualToString:@"noSeries"])             return @"";
    }
    
    if( [[tableColumn identifier] isEqualToString:@"yearOld"])
    {
        switch ( [[NSUserDefaults standardUserDefaults] integerForKey: @"yearOldDatabaseDisplay"])
        {
            case 0:
                return [item valueForKey: @"yearOld"];
                break;
                
            case 1:
                return [item valueForKey: @"yearOldAcquisition"];
                break;
                
            case 2:
            default:
            {
                NSString *yearOld = [item valueForKey: @"yearOld"];
                NSString *yearOldAcquisition = [item valueForKey: @"yearOldAcquisition"];
                
                if( [yearOld isEqualToString: yearOldAcquisition])
                    return yearOld;
                else
                {
                    if( [yearOld hasSuffix: NSLocalizedString( @" y", @"y = year")] && [yearOldAcquisition hasSuffix: NSLocalizedString( @" y", @"y = year")])
                        return [NSString stringWithFormat: @"%@/%@%@", [yearOld substringToIndex: yearOld.length-[NSLocalizedString( @" y", @"y = year") length]], [yearOldAcquisition substringToIndex: yearOldAcquisition.length-[NSLocalizedString( @" y", @"y = year") length]], NSLocalizedString( @" y", @"y = year")];
                    else
                        return [NSString stringWithFormat: @"%@/%@", yearOld, yearOldAcquisition];
                }
            }
                break;
        }
        
    }
    
    if( [[tableColumn identifier] isEqualToString:@"noSeries"])
    {
        if( [item valueForKey:@"imageSeries"])
            return [NSString stringWithFormat: @"%d", (int) [[item valueForKey:@"imageSeries"] count]];
        else
            return @"";
    }
    
    id value = nil;
    BOOL accessed = NO;
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Series"] && [[tableColumn identifier] isEqualToString:@"studyName"])
    {
        if( [item isDistant])
            value = [item valueForKey:@"seriesDescription"];
        else
            value = [item valueForKey:@"seriesDescription"];
        accessed = YES;
    }
    
    if (!accessed)
        value = [item valueForKey:[tableColumn identifier]];
    
    if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
    {   // only Series
        if ([[tableColumn identifier] isEqualToString:@"name"] || [[tableColumn identifier] isEqualToString:@"studyName"] || [[tableColumn identifier] isEqualToString:@"modality"])    // only name & description & modality
        {
            if (!value || ([value isKindOfClass:[NSString class]] && [(NSString*)value length] == 0))
                return NSLocalizedString(@"unknown", nil);
        }
    }
    return value;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (_database == nil)
        return nil;
    [item retain];
    //	[_database lock];
    @try {
        return [self intOutlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        //        [_database unlock];
        [item release];
    }
    
    return nil;
}

- (void) setDatabaseValue:(id) object item:(id) item forKey:(NSString*) key
{
    if( [item isDistant])
        return;
    
    DatabaseIsEdited = NO;
    
    //	[_database lock];
    @try {
        if (![_database isLocal])
            [(RemoteDicomDatabase*)_database object:item setValue:object forKey:key];
        
        if( [key isEqualToString:@"stateText"])
        {
            for( id managedObject in [self databaseSelection])
            {
                if( [object intValue] >= 0)
                    [managedObject setValue:object forKey:key];
            }
        }
        else if( [key isEqualToString:@"lockedStudy"])
        {
            for( id managedObject in [self databaseSelection])
            {
                if( [[managedObject valueForKey:@"type"] isEqualToString:@"Study"])
                    [managedObject setValue:[NSNumber numberWithBool: [object intValue]] forKey: @"lockedStudy"];
            }
        }
        else
        {
            for( id managedObject in [self databaseSelection])
            {
                [managedObject setValue:object forKey:key];
            }
        }
        
        [refreshTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        //        [_database unlock];
    }
    
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
    if( [item isDistant])
        return;
    
    if ([self.database isReadOnly])
        return;
    
    [self setDatabaseValue: object item: item forKey: [tableColumn identifier]];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self outlineViewRefresh];
    
    if( [[databaseOutline sortDescriptors] count] > 0 && [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
        [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection: NO];
    
    [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

-(NSString*)outlineView:(NSOutlineView*)outlineView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation
{
    if ([item isDistant])
        return NSLocalizedString( @"Double-Click to retrieve", nil);;
    
    @try
    {
        if ([[tableColumn identifier] isEqualToString:@"name"])
        {
            NSRect imageFrame = NSMakeRect(rect->origin.x, rect->origin.y, rect->size.height, rect->size.height);
            if (NSPointInRect(mouseLocation, imageFrame))
            {
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
        }
    } @catch (NSException* e) {
    }
    
    return nil;
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (id)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
    [cell setHighlighted: NO];
    
    if( [cell isKindOfClass: [ImageAndTextCell class]])
    {
        [(ImageAndTextCell*) cell setImage: nil];
        [(ImageAndTextCell*) cell setLastImage: nil];
    }
    
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
    [context lock];
    
    @try
    {
        if ([[item valueForKey:@"type"] isEqualToString: @"Study"])
        {
            if( [[tableColumn identifier] isEqualToString:@"lockedStudy"])
                [cell setTransparent: NO];
            
            if( [item isDistant])
            {
                [cell setFont: [NSFont fontWithName: DISTANTSTUDYFONT size: [self fontSize: @"dbFont"]]];
                //                [cell setTextColor: [NSColor grayColor]];
            }
            else if( originalOutlineViewArray)
            {
                if( [originalOutlineViewArray containsObject: item]) [cell setFont: [NSFont boldSystemFontOfSize: [self fontSize: @"dbFont"]]];
                else [cell setFont: [NSFont systemFontOfSize: [self fontSize: @"dbFont"]]];
            }
            else [cell setFont: [NSFont boldSystemFontOfSize: [self fontSize: @"dbFont"]]];
            
            if( [[tableColumn identifier] isEqualToString:@"name"])
            {
                BOOL	icon = NO;
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"displaySamePatientWithColorBackground"] && [[self window] firstResponder] == outlineView)
                {
                    if( [[previousItem valueForKey: @"type"] isEqualToString:@"Study"])
                    {
                        NSString *uid = [item valueForKey: @"patientUID"];
                        
                        if( previousItem != item && [uid length] > 1 && [uid compare: [previousItem valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
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
                    if( [item valueForKey:@"dateAdded"] && [[item valueForKey:@"dateAdded"] timeIntervalSinceNow] > -60) [(ImageAndTextCell*) cell setImage:[NSImage imageNamed:@"Receiving.tif"]];
                }
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
            if( [[tableColumn identifier] isEqualToString:@"lockedStudy"])
                [cell setTransparent: YES];
            
            [cell setFont: [NSFont boldSystemFontOfSize: [self fontSize: @"dbSeriesFont"]]];
        }
        [cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
        
        // gray "unknown" values
        
        if ([cell respondsToSelector:@selector(setTextColor:)])
        {
            BOOL gray = NO;
            if ([[item valueForKey:@"type"] isEqualToString:@"Series"])                                                                                                                         // only Series
                if ([[tableColumn identifier] isEqualToString:@"name"] || [[tableColumn identifier] isEqualToString:@"studyName"] || [[tableColumn identifier] isEqualToString:@"modality"])    // only name & description & modality
                {
                    id value = nil;
                    BOOL accessed = NO;
                    
                    if ([[item valueForKey:@"type"] isEqualToString:@"Series"] && [[tableColumn identifier] isEqualToString:@"studyName"])
                    {
                        value = [item valueForKey:@"seriesDescription"];
                        accessed = YES;
                    }
                    
                    if (!accessed)
                        value = [item valueForKey:[tableColumn identifier]];
                    
                    if (!value || ([value isKindOfClass:[NSString class]] && [(NSString*)value length] == 0))
                        gray = YES;
                }
            [cell setTextColor: gray? [NSColor grayColor] : [NSColor blackColor]];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [context unlock];
    
}

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
                
                NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: [dropDestination path], @"location", filesToExport, @"filesToExport", [dicomFiles2Export valueForKey: @"objectID"], @"dicomFiles2Export", nil];
                
                NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(exportDICOMFileInt: ) object: d] autorelease];
                t.name = NSLocalizedString( @"Exporting...", nil);
                t.supportsCancel = YES;
                t.status = N2LocalizedSingularPluralCount( [filesToExport count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                
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

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray *)pbItems toPasteboard:(NSPasteboard *)pboard
{
    for( id item in pbItems)
    {
        if( [item isDistant])
            return NO;
    }

    [pboard declareTypes:@[NSFilesPromisePboardType, NSPasteboardTypeString] owner:self];
    [pboard setPropertyList:@[@"dcm"] forType:NSFilesPromisePboardType];
    
    id plist = [NSPropertyListSerialization dataFromPropertyList:[pbItems valueForKey:@"XID"] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
    for (NSString *pasteboardType in BrowserController.DatabaseObjectXIDsPasteboardTypes)
        [pboard setPropertyList:plist forType:pasteboardType];
    
    
    return YES;
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
    //	[_database lock];
    
    id object = [[notification userInfo] objectForKey:@"NSObject"];
    
    if( [object isDistant] == NO)
        [object setValue:[NSNumber numberWithBool: NO] forKey:@"expanded"];
    
    DicomImage	*image = nil;
    
    if( [matrixViewArray count] > 0)
    {
        image = [matrixViewArray objectAtIndex: 0];
        if( [[image valueForKey:@"type"] isEqualToString:@"Image"]) [self findAndSelectFile: nil image: image shouldExpand :NO];
    }
    
    //	[_database unlock];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    //	[_database lock];
    
    id object = [[notification userInfo] objectForKey:@"NSObject"];
    
    if( [object isDistant] == NO)
        [object setValue:[NSNumber numberWithBool:YES] forKey:@"expanded"];
    
    //	[_database unlock];
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
        
        if ([[im valueForKey:@"fileType"] isEqualToString:@"DICOMMPEG2"])
        {
            NSString *filePath = [im valueForKey: @"completePath"];
            
            if( [[NSWorkspace sharedWorkspace] openFile:filePath withApplication:@"VLC" andDeactivate: YES] == NO)
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
                    
                    path = [self.database.tempDirPath stringByAppendingPathComponent:filename];
                    [[NSFileManager defaultManager] removeItemAtPath: path error: nil];
                    [pdfData writeToFile: path atomically: YES];
                }
            }
            else if( [DCMAbstractSyntaxUID isStructuredReport: [im valueForKeyPath: @"series.seriesSOPClassUID"]])
            {
                [[NSFileManager defaultManager] confirmDirectoryAtPath:@"/tmp/dicomsr_osirix"];
                
                NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[im valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"xml"];
                
                if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
                {
                    NSTask *aTask = [[[NSTask alloc] init] autorelease];
                    [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
                    [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
                    [aTask setArguments: [NSArray arrayWithObjects: @"+X1", @"--unknown-relationship", @"--ignore-constraints", @"--ignore-item-errors", @"--skip-invalid-items", [im completePathResolved], htmlpath, nil]];
                    [aTask launch];
                    while( [aTask isRunning])
                        [NSThread sleepForTimeInterval: 0.1];
                    
                    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                    [aTask interrupt];
                }
                
                if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
                {
                    if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]])
                    {
                        NSTask *aTask = [[[NSTask alloc] init] autorelease];
                        [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
                        [aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];
                        [aTask launch];
                        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
                        while( [aTask isRunning] && [NSDate timeIntervalSinceReferenceDate] - start < 10)
                            [NSThread sleepForTimeInterval: 0.1];
                        
                        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                        [aTask interrupt];
                    }
                }
                
                path = [htmlpath stringByAppendingPathExtension: @"pdf"];
            }
            else path = [im valueForKey: @"completePath"];
            
            if( path && [[NSWorkspace sharedWorkspace] openFile:path withApplication: nil andDeactivate: YES] == NO)
                r = NO;
            else
                r = YES;
            
            [NSThread sleepForTimeInterval: 1];
        }
        
        // RTSTRUCT
        if( [[[im valueForKey:@"modality"] lowercaseString] isEqualToString:@"rtstruct"])
        {
            if( NSRunInformationalAlertPanel(NSLocalizedString(@"RTSTRUCT", nil),
                                             NSLocalizedString(@"This series contains RTSTRUCT ROIs. Should I generate the corresponding ROIs on the images series?", nil),
                                             NSLocalizedString(@"OK",nil),
                                             NSLocalizedString(@"Cancel",nil),
                                             nil) == NSAlertDefaultReturn)
            {
                DCMObject *dcmObj = [DCMObject objectWithContentsOfFile: im.completePathResolved decodingPixelData: NO];
                
                DCMPix *pix = nil;
                @synchronized( previewPixThumbnails)
                {
                    pix = [previewPix objectAtIndex: 0];  // Should only be one DCMPix associated w/ an RTSTRUCT
                }
                
                [pix createROIsFromRTSTRUCT: dcmObj];
                
                r = YES;
            }
        }
        
#endif
        
        [_database unlock];
    }
    
    return r;
}

- (void) databaseOpenStudy:(DicomStudy*) currentStudy withProtocol:(NSDictionary*) currentHangingProtocol
{
    BOOL restoreNOAutotiling = NO;
    int WINDOWSIZEVIEWERCopy = 0;
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"] != YES)
    {
        restoreNOAutotiling = YES;
        WINDOWSIZEVIEWERCopy = [[NSUserDefaults standardUserDefaults] integerForKey: @"WINDOWSIZEVIEWER"];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"AUTOTILING"];
    }
    
    NSMutableArray *children = [NSMutableArray arrayWithArray: [self childrenArray: currentStudy]];
    
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
        if( [currentHangingProtocol valueForKey: @"Sync"])
        {
            if( [[currentHangingProtocol valueForKey: @"Sync"] boolValue])
                [DCMView setSyncro: syncroLOC];
            else
                [DCMView setSyncro: syncroOFF];
        }
        
        if( [currentHangingProtocol valueForKey: @"Propagate"])
        {
            [[NSUserDefaults standardUserDefaults] setBool: [[currentHangingProtocol valueForKey: @"Propagate"] boolValue] forKey:@"COPYSETTINGS"];
        }
        
        NSMutableArray *seriesArray = nil;
        
        if( [[currentStudy imageSeriesContainingPixels: YES] count])
            seriesArray = [NSMutableArray arrayWithArray: [currentStudy imageSeriesContainingPixels: YES]];
        else
            seriesArray = [NSMutableArray arrayWithArray: [currentStudy imageSeries]];
        
        // Sort series according to SeriesOrder, if available
        if( [currentHangingProtocol valueForKey: @"SeriesOrder"])
        {
            NSMutableArray *newSeriesArray = [NSMutableArray array];
            
            NSNumber* caseSensitivityValue = [currentHangingProtocol valueForKey: @"SeriesOrderIgnoreCase"];
            BOOL ignoreCase = [caseSensitivityValue boolValue];
            
            for( NSString *term in [[currentHangingProtocol valueForKey: @"SeriesOrder"] componentsSeparatedByString: @","])
            {
                term = [term stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                int index = -1;
                for( int i = 0; i < seriesArray.count; i++)
                {
                    DicomSeries *s = [seriesArray objectAtIndex: i];
                    
                    if (ignoreCase)
                    {
                        NSRange rangeValue = [s.description rangeOfString:term options:NSCaseInsensitiveSearch];
                        
                        if (rangeValue.length > 0)
                        {
                            index = i;
                        }
                    }
                    else
                    {
                        if( [s.description contains: term])
                        {
                            index = i;
                        }
                    }
                }
                
                if( index != -1)
                {
                    [newSeriesArray addObject: [seriesArray objectAtIndex: index]];
                    [seriesArray removeObjectAtIndex: index];
                }
            }
            [newSeriesArray addObjectsFromArray: seriesArray];
            
            seriesArray = newSeriesArray;
        }
        
        // Prepare the series to be displayed
        NSMutableArray *comparatives = [NSMutableArray array];
        if( [[currentHangingProtocol valueForKey: @"Comparative"] boolValue])
        {
            // Find the previous studies
            int numberOfComparative = [[currentHangingProtocol valueForKey:@"NumberOfComparativeToDisplay"] intValue];
            
            //PreviousStudySameModality , PreviousStudySameDescription
            
            for( id s in [NSArray arrayWithArray: [self subSearchForComparativeStudies: currentStudy]])
            {
                id comparativeStudy = nil;
                
#ifndef OSIRIX_LIGHT
                if( [s isKindOfClass: [DCMTKStudyQueryNode class]])
                {
                    DCMTKStudyQueryNode *study = s;
                    
                    if( ![[study studyInstanceUID] isEqualToString: [currentStudy valueForKey: @"studyInstanceUID"]])
                    {
                        comparativeStudy = study;
                        
                        if( [[currentHangingProtocol valueForKey:@"PreviousStudySameModality"] boolValue])
                        {
                            if( [[study modality] isEqualToString: [currentStudy valueForKey: @"modality"]] == NO)
                                comparativeStudy = nil;
                        }
                        
                        if( [[currentHangingProtocol valueForKey:@"PreviousStudySameDescription"] boolValue])
                        {
                            if( [[currentHangingProtocol objectForKey: @"isDefaultProtocolForModality"] boolValue])
                            {
                                if( [[study studyName] isEqualToString: [currentStudy valueForKey: @"studyName"]] == NO)
                                    comparativeStudy = nil;
                            }
                            else
                            {
                                NSRange searchRange = [[study studyName] rangeOfString: [currentHangingProtocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
                                if (searchRange.location == NSNotFound)
                                    comparativeStudy = nil;
                            }
                        }
                        
                        if( comparativeStudy)
                            [self retrieveComparativeStudy: comparativeStudy select: NO open: NO showGUI: NO];
                    }
                }
#endif
                
                if( [s isKindOfClass: [DicomStudy class]])
                {
                    DicomStudy *study = s;
                    
                    if( ![[study studyInstanceUID] isEqualToString: [currentStudy valueForKey: @"studyInstanceUID"]])
                    {
                        comparativeStudy = study;
                        
                        if( [[currentHangingProtocol valueForKey:@"PreviousStudySameModality"] boolValue])
                        {
                            if( [[study modality] isEqualToString: [currentStudy valueForKey: @"modality"]] == NO)
                                comparativeStudy = nil;
                        }
                        
                        if( [[currentHangingProtocol valueForKey:@"PreviousStudySameDescription"] boolValue])
                        {
                            if( [[currentHangingProtocol objectForKey: @"isDefaultProtocolForModality"] boolValue])
                            {
                                if( [[study studyName] isEqualToString: [currentStudy valueForKey: @"studyName"]] == NO)
                                    comparativeStudy = nil;
                            }
                            else
                            {
                                NSRange searchRange = [[study studyName] rangeOfString: [currentHangingProtocol objectForKey: @"Study Description"] options: NSCaseInsensitiveSearch | NSLiteralSearch];
                                if (searchRange.location == NSNotFound)
                                    comparativeStudy = nil;
                            }
                        }
                    }
                }
                
                if( comparativeStudy)
                    [comparatives addObject: comparativeStudy];
                
                if( comparatives.count >= numberOfComparative)
                    break;
            }
            
#ifndef OSIRIX_LIGHT
            // Wait until all distant studies are retrieved
            WaitRendering *w = nil;
            NSTimeInterval timeout = [NSDate timeIntervalSinceReferenceDate];
            BOOL distantStudies = NO;
            do
            {
                distantStudies = NO;
                
                int copy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ListenerCompressionSettings"];
                [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"ListenerCompressionSettings"]; //No time for decompression....
                
                for( int i = 0; i < comparatives.count; i++)
                {
                    if( [[comparatives objectAtIndex: i] isKindOfClass: [DCMTKStudyQueryNode class]])
                    {
                        //                        [NSThread sleepForTimeInterval: 0.3];
                        //                        [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
                        
                        [self.database importFilesFromIncomingDir];
                        
                        NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
                        [r setPredicate: [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", [[comparatives objectAtIndex: i] studyInstanceUID]]];
                        
                        NSArray *studyArray = nil;
                        @try
                        {
                            // We need to receive the 'messages' for the new db objects from the background thread
                            [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.5]];
                            
                            studyArray = [self.database.managedObjectContext executeFetchRequest: r error: nil];
                        }
                        @catch (NSException *e) { N2LogExceptionWithStackTrace(e);}
                        
                        if( [[[studyArray lastObject] imageSeriesContainingPixels: YES] count]) // We want images !
                            [comparatives replaceObjectAtIndex: i withObject: [studyArray lastObject]];
                        else
                            distantStudies = YES;
                    }
                }
                
                [[NSUserDefaults standardUserDefaults] setInteger: copy forKey: @"ListenerCompressionSettings"];
                
                if( distantStudies && w == nil)
                {
                    w = [[[WaitRendering alloc] init: NSLocalizedString(@"Retrieving...", nil)] autorelease];
                    [w showWindow: self];
                }
            }
#define TIMEOUT 30
            while( distantStudies && [NSDate timeIntervalSinceReferenceDate] - timeout < TIMEOUT);
            
            [w close];
#endif
            for( int i = 0; i < comparatives.count; i++)
            {
                if( [[comparatives objectAtIndex: i] isKindOfClass: [DicomStudy class]] == NO)
                {
                    [comparatives removeObjectAtIndex: i];
                    i--;
                }
            }
        }
        
        // Expand comparatives study according to NumberOfSeriesPerComparative
        if( [[currentHangingProtocol valueForKey: @"NumberOfSeriesPerComparative"] integerValue] > 1)
        {
            int n = [[currentHangingProtocol valueForKey: @"NumberOfSeriesPerComparative"] integerValue];
            
            NSMutableArray *newComparatives = [NSMutableArray array];
            for( DicomStudy *study in comparatives)
            {
                NSMutableArray *series = [NSMutableArray arrayWithArray: [study imageSeriesContainingPixels: YES]];
                
                // Sort series according to SeriesOrder, if available
                if( [currentHangingProtocol valueForKey: @"SeriesOrder"])
                {
                    NSMutableArray *newSeriesArray = [NSMutableArray array];
                    
                    NSNumber* caseSensitivityValue = [currentHangingProtocol valueForKey: @"SeriesOrderIgnoreCase"];
                    BOOL ignoreCase = [caseSensitivityValue boolValue];
                    
                    for( NSString *term in [[currentHangingProtocol valueForKey: @"SeriesOrder"] componentsSeparatedByString: @","])
                    {
                        term = [term stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        
                        int index = -1;
                        for( int i = 0; i < series.count; i++)
                        {
                            DicomSeries *s = [series objectAtIndex: i];
                            
                            if (ignoreCase)
                            {
                                NSRange rangeValue = [s.description rangeOfString:term options:NSCaseInsensitiveSearch];
                                
                                if (rangeValue.length > 0)
                                {
                                    index = i;
                                }
                            }
                            else
                            {
                                if( [s.description contains: term])
                                {
                                    index = i;
                                }
                            }
                        }
                        
                        if( index != -1)
                        {
                            [newSeriesArray addObject: [series objectAtIndex: index]];
                            [series removeObjectAtIndex: index];
                        }
                    }
                    [newSeriesArray addObjectsFromArray: series];
                    
                    series = newSeriesArray;
                }
                
                if( series.count > n)
                    [newComparatives addObjectsFromArray: [series subarrayWithRange: NSMakeRange( 0, n)]];
                else
                    [newComparatives addObjectsFromArray: series];
            }
            
            comparatives = newComparatives;
        }
        
        // Prepare the series
        int total = [WindowLayoutManager windowsRowsForHangingProtocol: currentHangingProtocol] * [WindowLayoutManager windowsColumnsForHangingProtocol: currentHangingProtocol] * [[[AppController sharedAppController] viewerScreens] count];
        
        if( seriesArray.count > total)
            [seriesArray removeObjectsInRange: NSMakeRange( total, seriesArray.count-total)];
        
        if( seriesArray.count + comparatives.count > total)
        {
            while( seriesArray.count + comparatives.count > total && seriesArray.count > 1)
                [seriesArray removeLastObject];
            
            while( seriesArray.count + comparatives.count > total && comparatives.count > 0)
                [comparatives removeLastObject];
        }
        
        if( [[currentHangingProtocol objectForKey: @"RepeatSeriesIfNotEnoughSeries"] boolValue])
        {
            if( seriesArray.count + comparatives.count < total)
            {
                int i = 0;
                while( seriesArray.count + comparatives.count < total && seriesArray.count)
                    [seriesArray addObject: [seriesArray objectAtIndex: i++]];
            }
        }
        
        [seriesArray addObjectsFromArray: comparatives];
        
        
        // Go to the series level, if we are at study level (comparatives)
        for( int i = 0; i < seriesArray.count; i++)
        {
            if( [[seriesArray objectAtIndex: i] isKindOfClass: [DicomStudy class]])
            {
                DicomStudy *s = [seriesArray objectAtIndex: i];
                
                if( [[s imageSeriesContainingPixels: YES] count])
                {
                    [seriesArray replaceObjectAtIndex: i withObject: [[s imageSeriesContainingPixels: YES] objectAtIndex: 0]];
                }
                else if( [[s imageSeries] count])
                {
                    [seriesArray replaceObjectAtIndex: i withObject: [[s imageSeries] objectAtIndex: 0]];
                }
                else
                {
                    NSLog( @"---- no imageSeries in this study?: %@", s);
                }
            }
        }
        
        [self viewerDICOMInt: NO  dcmFile: seriesArray viewer: nil tileWindows: YES protocol: currentHangingProtocol];
    }
    else
    {
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
            [[v window] makeKeyAndOrderFront: self];
    }
    
    // Apply WL/WW
    for( ViewerController *v in [ViewerController getDisplayed2DViewers])
    {
        NSDictionary *p = [WindowLayoutManager hangingProtocolForModality: v.modality description: v.currentStudy.studyName];
        
        if( p)
        {
            if( [[p valueForKey: @"WL"] intValue] == 0 && [[p valueForKey: @"WW"] intValue] == 0) // Default
            {
            }
            
            else if( [[p valueForKey: @"WL"] intValue] == 1 && [[p valueForKey: @"WW"] intValue] == 1) // Full
            {
                [v.imageView setWLWW: 0 : 0];
            }
            
            else if( [p valueForKey: @"WL"] && [p valueForKey: @"WW"])
            {
                [v.imageView setWLWW: [[p valueForKey: @"WL"] floatValue] :[[p valueForKey: @"WW"] floatValue]];
            }
        }
    }
    
    if( restoreNOAutotiling)
    {
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"AUTOTILING"];
        [[NSUserDefaults standardUserDefaults] setInteger: WINDOWSIZEVIEWERCopy forKey: @"WINDOWSIZEVIEWER"];
    }
}

- (void) displayWaitWindowIfNecessary
{
    if( waitOpeningWindow == nil) waitOpeningWindow  = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
    [waitOpeningWindow showWindow:self];
}

- (void) closeWaitWindowIfNecessary
{
    [waitOpeningWindow close];
    [waitOpeningWindow autorelease];
    waitOpeningWindow = nil;
}

- (void) databaseOpenStudy: (NSManagedObject*) item
{
#ifndef  OSIRIX_LIGHT
    if( [item isKindOfClass: [DCMTKStudyQueryNode class]])
    {
        // Check to see if already in retrieving mode, if not download it
        [self retrieveComparativeStudy: (DCMTKStudyQueryNode*) item select: YES open: YES];
        
        return;
    }
#endif
    
    NSArray *cells = [oMatrix selectedCells];
    if( [cells count] > 1)
    {
        for( NSCell *c in oMatrix.cells)
            [c setHighlighted: NO];
        
        [oMatrix selectCell: [cells objectAtIndex: 0]];
    }
    
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
        DicomStudy *currentStudy = (DicomStudy*) item;
        
        [self checkIfLocalStudyHasMoreOrSameNumberOfImagesOfADistantStudy: [NSArray arrayWithObject: currentStudy]];
        
        [[AppController sharedAppController] addStudyToRecentStudiesMenu: currentStudy.objectID];
        
        BOOL windowsStateApplied = NO;
        
        if( [currentStudy valueForKey:@"windowsState"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"])
        {
            NSArray *viewers = [NSPropertyListSerialization propertyListFromData: [currentStudy valueForKey:@"windowsState"] mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
            
            // Check if this windowsState contains at least this study...
            
            BOOL studyUIDFound = NO;
            for( NSDictionary *dict in viewers)
            {
                if( [currentStudy.studyInstanceUID isEqualToString: [dict valueForKey:@"studyInstanceUID"]])
                    studyUIDFound = YES;
            }
            
            if( studyUIDFound)
            {
                NSMutableArray *seriesToOpen =  [NSMutableArray array];
                NSMutableArray *viewersToLoad = [NSMutableArray array];
                
                [ViewerController closeAllWindows];
                
                NSNumber *propagateSettings = nil;
                NSNumber *syncSettings = nil;
                NSNumber *SYNCSERIES = nil;
                NSNumber *syncButtonBehaviorIsBetweenStudies = nil;
                
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForComparativeStudiesOnDICOMNodes"])
                {
                    [self displayWaitWindowIfNecessary];
                    
                    // Check if all studies are available, available on PACS-On-Demand ?
                    for( NSDictionary *dict in viewers)
                    {
                        NSString *studyUID = [dict valueForKey:@"studyInstanceUID"];
                        
                        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
                        [request setPredicate: [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyUID]];
                        
                        NSManagedObjectContext	*context = self.database.managedObjectContext;
                        NSArray	*studiesArray = [context executeFetchRequest:request error: nil];
                        
                        if( [studiesArray count] == 0)
                        {
#ifndef OSIRIX_LIGHT
                            NSArray *servers = [BrowserController comparativeServers];
                            
                            DCMTKStudyQueryNode *distantStudy = [[QueryController queryStudiesForFilters: [NSDictionary dictionaryWithObject: studyUID forKey: @"StudyInstanceUID"] servers: servers showErrors: NO] lastObject];
                            
                            if( distantStudy)
                            {
                                int copy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ListenerCompressionSettings"];
                                [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"ListenerCompressionSettings"]; //No time for decompression....
                                
                                [QueryController retrieveStudies: [NSArray arrayWithObject: distantStudy] showErrors: NO checkForPreviousAutoRetrieve: YES];
                                
                                int lastNumberOfImages = 0, currentNumberOfImages = 0;
                                NSTimeInterval dateStart = [NSDate timeIntervalSinceReferenceDate];
                                
                                do
                                {
                                    [NSThread sleepForTimeInterval: 0.1];
                                    
                                    lastNumberOfImages = [[[studiesArray lastObject] images] count];
                                    
                                    [[DicomDatabase activeLocalDatabase] importFilesFromIncomingDir];
                                    
                                    // And find the study locally
                                    NSFetchRequest *r = [NSFetchRequest fetchRequestWithEntityName: @"Study"];
                                    [r setPredicate: [NSPredicate predicateWithFormat:@"studyInstanceUID == %@", studyUID]];
                                    
                                    @try
                                    {
                                        studiesArray = [context executeFetchRequest: r error: nil];
                                    }
                                    @catch (NSException *e) { N2LogExceptionWithStackTrace(e);}
                                    
                                    currentNumberOfImages = [[[studiesArray lastObject] images] count];
                                }
                                while( ([studiesArray count] == 0 || lastNumberOfImages != currentNumberOfImages) && [NSDate timeIntervalSinceReferenceDate] - dateStart < 20);
                                
                                [[NSUserDefaults standardUserDefaults] setInteger: copy forKey: @"ListenerCompressionSettings"];
                            }
#endif
                        }
                    }
                    
                    [self closeWaitWindowIfNecessary];
                }
                
                for( NSDictionary *dict in viewers)
                {
                    NSString *studyUID = [dict valueForKey:@"studyInstanceUID"];
                    NSString *seriesUID = [dict valueForKey:@"seriesInstanceUID"];
                    NSString *seriesDICOMUID = [dict valueForKey:@"seriesDICOMUID"];
                    
                    propagateSettings = [dict valueForKey: @"propagateSettings"];
                    syncSettings = [dict valueForKey: @"syncSettings"];
                    SYNCSERIES = [dict valueForKey: @"SYNCSERIES"];
                    syncButtonBehaviorIsBetweenStudies = [dict valueForKey: @"SyncButtonBehaviorIsBetweenStudies"];
                    
                    NSArray	 *series4D = [seriesUID componentsSeparatedByString:@"\\**\\"];
                    // Find the corresponding study & 4D series
                    
                    @try
                    {
                        NSError *error = nil;
                        NSManagedObjectContext *context = self.database.managedObjectContext;
                        
                        [context lock];
                        
                        NSMutableArray *seriesForThisViewer =  nil;
                        
                        @try
                        {
                            for( NSString *curSeriesUID in series4D)
                            {
                                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: @"Series"];
                                [request setPredicate: [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesInstanceUID == %@", studyUID, curSeriesUID]];
                                
                                NSArray	*seriesArray = [context executeFetchRequest:request error:&error];
                                
                                //Try the DICOMSeriesUID
                                if( seriesArray.count == 0 && seriesDICOMUID.length)
                                {
                                    request = [NSFetchRequest fetchRequestWithEntityName: @"Series"];
                                    [request setPredicate: [NSPredicate predicateWithFormat:@"study.studyInstanceUID == %@ AND seriesDICOMUID == %@", studyUID, seriesDICOMUID]];
                                    seriesArray = [context executeFetchRequest:request error:&error];
                                }
                                
                                if( [seriesArray count] == 1)
                                {
                                    if( [[[seriesArray objectAtIndex: 0] valueForKeyPath:@"study.patientUID"] compare: [currentStudy valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
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
                                        NSLog(@"%@ versus %@", [[seriesArray objectAtIndex: 0] valueForKeyPath:@"study.patientUID"], [currentStudy valueForKey: @"patientUID"]);
                                }
                                else if( [seriesArray count] > 1)
                                    NSLog( @"****** number of series corresponding to these UID (%@) is not unique?: %d", curSeriesUID, (int) [seriesArray count]);
                            }
                        }
                        @catch (NSException * e)
                        {
                            N2LogExceptionWithStackTrace(e);
                        }
                        
                        [context unlock];
                    }
                    @catch (NSException *e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
                
                if( [seriesToOpen count] > 0 && [viewersToLoad count] == [seriesToOpen count])
                {
                    if( syncSettings)
                    {
                        if( [syncSettings boolValue])
                            [DCMView setSyncro: syncroLOC];
                        else
                            [DCMView setSyncro: syncroOFF];
                    }
                    
                    if( propagateSettings)
                        [[NSUserDefaults standardUserDefaults] setBool: [propagateSettings boolValue] forKey:@"COPYSETTINGS"];
                    
                    [self displayWaitWindowIfNecessary];
                    
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
                    BOOL validWindowsPosition = YES;
                    for( int i = 0 ; i < [viewersToLoad count]; i++)
                    {
                        NSDictionary *dict = [viewersToLoad objectAtIndex: i];
                        
                        if( i < [displayedViewers count])
                        {
                            ViewerController *v = [displayedViewers objectAtIndex: i];
                            
                            NSRect r;
                            NSScanner* s = [NSScanner scannerWithString: [dict valueForKey:@"window position"]];
                            
                            float scaleRatio = 1, a;
                            [s scanFloat: &a];	r.origin.x = a;		[s scanFloat: &a];	r.origin.y = a;
                            [s scanFloat: &a];	r.size.width = a;	[s scanFloat: &a];	r.size.height = a;
                            
                            NSUInteger screenIndex = [[dict valueForKey:@"screenIndex"] unsignedIntegerValue];
                            NSRect savedScreenRect = NSRectFromString( [dict valueForKey:@"screen"]);
                            if( savedScreenRect.size.width > 0 && savedScreenRect.size.height > 0)
                            {
                                if( screenIndex < NSScreen.screens.count)
                                {
                                    float widthRatio = 1, heightRatio = 1;
                                    NSRect curScreenVisibleRect = [AppController usefullRectForScreen: [[NSScreen screens] objectAtIndex: screenIndex]];
                                    
                                    widthRatio = curScreenVisibleRect.size.width / savedScreenRect.size.width;
                                    heightRatio = curScreenVisibleRect.size.height / savedScreenRect.size.height;
                                    
                                    r.size.width *= widthRatio;
                                    r.size.height *= heightRatio;
                                    
                                    r.origin.x = ((r.origin.x - savedScreenRect.origin.x) * widthRatio) + curScreenVisibleRect.origin.x;
                                    r.origin.y = ((r.origin.y - savedScreenRect.origin.y) * heightRatio) + curScreenVisibleRect.origin.y;
                                    
                                    if( widthRatio < 1 || heightRatio < 1)
                                        scaleRatio = widthRatio < heightRatio ? widthRatio : heightRatio;
                                    
                                    if( widthRatio > 1 || heightRatio > 1)
                                        scaleRatio = widthRatio > heightRatio ? widthRatio : heightRatio;
                                    
                                    // Test if the window is completely contained in the screen, otherwise, we will TileWindows.
                                    if( NSEqualRects(NSIntersectionRect( curScreenVisibleRect, r), r) == NO)
                                    {
                                        r = NSIntersectionRect( curScreenVisibleRect, r);
                                        validWindowsPosition = NO;
                                    }
                                }
                                else
                                    validWindowsPosition = NO;
                            }
                            else
                                validWindowsPosition = NO;
                            
                            int index = [[dict valueForKey:@"index"] intValue];
                            int rows = [[dict valueForKey:@"rows"] intValue];
                            int columns = [[dict valueForKey:@"columns"] intValue];
                            float wl = [[dict valueForKey:@"wl"] floatValue];
                            float ww = [[dict valueForKey:@"ww"] floatValue];
                            float x = [[dict valueForKey:@"x"] floatValue];
                            float y = [[dict valueForKey:@"y"] floatValue];
                            float rotation = [[dict valueForKey:@"rotation"] floatValue];
                            float scale = [[dict valueForKey:@"scale"] floatValue] * scaleRatio*scaleRatio;
                            
                            [v setWindowFrame: r showWindow: NO];
                            [v setImageRows: rows columns: columns];
                            
                            [v setImageIndex: index];
                            
                            if( [[[v imageView] curDCM] SUVConverted]) [v setWL: wl*[v factorPET2SUV] WW: ww*[v factorPET2SUV]];
                            else [v setWL: wl WW: ww];
                            
                            [v setScaleValue: scale];
                            [v setRotation: rotation];
                            [v setOrigin: NSMakePoint( x, y)];
                            
                            if( [[dict valueForKey: @"SyncButtonBehaviorIsBetweenStudies"] boolValue])
                            {
                                v.imageView.syncRelativeDiff = [[dict valueForKey: @"syncRelativeDiff"] floatValue];
                            }
                            
                            if( [dict valueForKey: @"LastWindowsTilingRowsColumns"])
                                [[NSUserDefaults standardUserDefaults] setObject: [dict valueForKey: @"LastWindowsTilingRowsColumns"] forKey: @"LastWindowsTilingRowsColumns"];
                        }
                    }
                    
                    [AppController sharedAppController].checkAllWindowsAreVisibleIsOff = NO;
                    [[AppController sharedAppController] checkAllWindowsAreVisible: self];
                    
                    if( validWindowsPosition)
                    {
                        for( int i = 0 ; i < [viewersToLoad count]; i++)
                        {
                            if( i < [displayedViewers count])
                            {
                                ViewerController *v = [displayedViewers objectAtIndex: i];
                                
                                if( v.window.screen == nil)
                                    validWindowsPosition = NO;
                                else
                                    // Test if the window is completely contained in the screen, otherwise, we will TileWindows.
                                    if( NSEqualRects(NSIntersectionRect( v.window.screen.visibleFrame, v.window.frame), v.window.frame) == NO)
                                        validWindowsPosition = NO;
                            }
                        }
                        
                    }
                    
                    if( validWindowsPosition == NO)
                    {
                        NSDictionary *d = nil;
                        NSString *rw = [[NSUserDefaults standardUserDefaults] stringForKey: @"LastWindowsTilingRowsColumns"];
                        if( rw)
                        {
                            if( rw.length == 2)
                            {
                                d = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [[rw substringWithRange: NSMakeRange( 0, 1)] intValue]], @"rows", [NSNumber numberWithInt: [[rw substringWithRange: NSMakeRange( 1, 1)] intValue]], @"columns", nil];
                            }
                        }
                        [[AppController sharedAppController] tileWindows: d];
                    }
                    if( [displayedViewers count] > 0)
                        [[[displayedViewers objectAtIndex: 0] window] makeKeyAndOrderFront: self];
                    
                    [self closeWaitWindowIfNecessary];
                    
                    //windowsStateApplied = YES; // Hanging Protocol has to prevail over window state when opening studies
                    
                    for( ViewerController *v in [[displayedViewers reverseObjectEnumerator] allObjects])
                    {
                        [v buildMatrixPreview: YES];
                    }
                    
                    if( [syncButtonBehaviorIsBetweenStudies boolValue] && [SYNCSERIES boolValue])
                        [ViewerController activateSYNCSERIESBetweenStudies];
                    
                    [ToolbarPanelController checkForValidToolbar];
                    
                    [[displayedViewers lastObject] redrawToolbar];
                }
            }
        }
        
        if( windowsStateApplied == NO)
        {
            [[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:[currentStudy valueForKey:@"modality"]
                                                                                      description:[currentStudy valueForKey:@"studyName"]];
            
            NSDictionary *currentHangingProtocol = [[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol];
            
            [self databaseOpenStudy:currentStudy withProtocol:currentHangingProtocol];
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
        id item;
        if ([databaseOutline clickedRow] != -1)
            item = [databaseOutline itemAtRow:[databaseOutline clickedRow]];
        else
            item = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
        
        if ([[item numberOfImages] intValue] != 0)
        {
#ifndef OSIRIX_LIGHT
            if( [item isDistant])
            {
                id study = item;
                
                if( [item isKindOfClass: [DCMTKSeriesQueryNode class]])
                    study = [item study];
                
                // Check to see if already in retrieving mode, if not download it
                [self retrieveComparativeStudy: study select: YES open: NO];
            }
            else
#endif
            {
                [self databaseOpenStudy: item];
            }
        }
        else
        {
#ifndef OSIRIX_LIGHT
            [self querySelectedStudy:self];
#endif
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([self.database isReadOnly])
        return NO;
    
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([self.database isReadOnly])
        return NO;
    
    return YES;
}

- (IBAction) displayImagesOfSeries: (id) sender
{
    NSMutableArray *dicomFiles = [NSMutableArray array];
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
    {
        if( [matrixViewArray count] > [[oMatrix selectedCell] tag])
        {
            NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]];
            
            if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
            {
                [self filesForDatabaseMatrixSelection: dicomFiles];
                
                if( [databaseOutline isItemExpanded: [curObj valueForKeyPath:@"series.study"]])
                    [databaseOutline collapseItem: [curObj valueForKeyPath:@"series.study"]];
                
                //	[self findAndSelectFile:nil image:[dicomFiles objectAtIndex: 0] shouldExpand:NO];
            }
            else
            {
                [self filesForDatabaseMatrixSelection: dicomFiles];
                [self findAndSelectFile:nil image:[dicomFiles objectAtIndex: 0] shouldExpand:YES];
            }
        }
    }
}

-(BOOL) findAndSelectFile: (NSString*) path image: (DicomImage*) curImage shouldExpand: (BOOL) expand
{
    return [self findAndSelectFile: (NSString*) path image: (DicomImage*) curImage shouldExpand: (BOOL) expand extendingSelection: NO];
}

-(BOOL) findAndSelectFile: (NSString*) path image: (DicomImage*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection
{
    if( curImage == nil)
    {
        BOOL isDirectory;
        
        if([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])     // A directory
        {
            DicomFile *curFile = nil;
            
            @try
            {
                if( isDirectory == YES)
                {
                    BOOL go = YES;
                    NSString *pathname, *aPath = path;
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
                N2LogExceptionWithStackTrace(e);
                curFile = nil;
            }
            
            //We have first to find the image object from the path
            
            NSError *error = nil;
            NSUInteger index;
            
            if( curFile)
            {
                NSManagedObject	*study, *seriesTable;
                NSManagedObjectContext *context = self.database.managedObjectContext;
                
                NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
                [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
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
                    N2LogExceptionWithStackTrace(e);
                }
                
                [curFile release];
                
                [context unlock];
            }
        }
    }
    
    NSManagedObject	*study = curImage.series.study;
    
    NSInteger index = [outlineViewArray indexOfObject: study];
    
    if( index != NSNotFound)
    {
        if( expand) // || [databaseOutline isItemExpanded: study])
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
            
            if( [[oMatrix selectedCell] representedObject] == [curImage.series objectID])
                return YES;
            
            for( NSCell *cell in oMatrix.cells)
            {
                if( [cell representedObject] == [curImage.series objectID])
                {
                    [oMatrix selectCell: cell];
                    [self matrixPressed: oMatrix];
                    return YES;
                }
            }
            
            NSArray	*seriesArray = [self childrenArray: study];
            
            [self outlineViewSelectionDidChange: nil];
            
            [self matrixDisplayIcons: self];	//Display the icons, if necessary
            
            NSInteger seriesPosition = [seriesArray indexOfObject: [curImage valueForKey:@"series"]];
            
            if( seriesPosition != NSNotFound)
            {
                if( [[oMatrix selectedCell] tag] != seriesPosition)
                {
                    // Select the right thumbnail matrix
                    NSInteger rows, cols; [oMatrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                    [oMatrix selectCellAtRow: seriesPosition/cols column: seriesPosition%cols];
                    [self matrixPressed: oMatrix];
                }
                
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL) displayStudy: (DicomStudy*) study object:(NSManagedObject*) element command:(NSString*) execute
{
    if( [self selectThisStudy: study])
    {
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
                    [self findAndSelectFile:nil image: (DicomImage*) element shouldExpand:NO];
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
                else [browserWindow databaseOpenStudy: element];
                //				else [browserWindow viewerDICOM: self]; // Study
            }
        }
        
        return YES;
    }
    
    return NO;
}

- (int) findObject:(NSString*) request table:(NSString*) table execute: (NSString*) execute elements:(NSString**) elements { // __deprecated
    if( elements)
        *elements = nil;
    
    if( !request) return -32;
    if( !table) return -33;
    if( !execute) return -34;
    
    NSError				*error = nil;
    
    NSManagedObject			*element = nil;
    NSArray					*array = nil;
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
    [self checkIncoming: self];
    // We cannot call checkIncomingNow, because we currently have the lock for context, and IF a separate checkIncoming thread has started, he is currently waiting for the context lock, and we will wait for the checkIncomingLock...
    
    NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
    [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey: table]];
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
        N2LogExceptionWithStackTrace(e);
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
            
            BOOL succeed = [self displayStudy: study object: element command: execute];
            
            if( succeed == NO)
                return -1;
        }
        
        // Generate an answer containing the elements
        NSMutableString *a = [NSMutableString stringWithString: @"<value><array><data>"];
        
        for( NSManagedObject *obj in array)
        {
            NSMutableString *c = [NSMutableString stringWithString: @"<value><struct>"];
            
            NSArray *allKeys = [[[[self.database.managedObjectModel entitiesByName] objectForKey: table] attributesByName] allKeys];
            
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
                    N2LogExceptionWithStackTrace(e);
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
                N2LogExceptionWithStackTrace(e);
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
    BOOL copyPatientsSettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDisplayImagesOfSamePatient"];
    
    NSDisableScreenUpdates();
    
    [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"onlyDisplayImagesOfSamePatient"];
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
    }
    
    if( [ViewerController get2DViewers].count)
    {
        // Save workspace
        [viewer saveWindowsState: self];
        
        // If multiple viewer are opened, apply it to the entire list
        for( ViewerController *v in [ViewerController get2DViewers])
            [[v window] orderOut: self];
        
        for( ViewerController *v in [ViewerController get2DViewers])
            [v close];
    }
    
    if( delayedTileWindows)
    {
        delayedTileWindows = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:[AppController sharedAppController] selector:@selector(tileWindows:) object:nil];
    }
    
    DicomStudy* study = [curImage valueForKeyPath:@"series.study"];
    
    NSArray *studiesList = originalOutlineViewArray;
    
    if( studiesList == nil)
        studiesList = outlineViewArray;
    
    NSInteger index = [studiesList indexOfObject: study];
    
    if( index != NSNotFound)
    {
        BOOL found = NO;
        DicomStudy *nextStudy = nil;
        do
        {
            index += direction;
            if( index >= 0 && index < [studiesList count])
            {
                nextStudy = [studiesList objectAtIndex: index];
                
                if( [nextStudy.patientUID compare:study.patientUID options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch|NSWidthInsensitiveSearch] != NSOrderedSame) // skip empty studies
                {
                    if( [nextStudy isDistant])
                    {
                        [self retrieveComparativeStudy: (DCMTKStudyQueryNode*) nextStudy select: YES open: YES];
                        found = YES;
                    }
                    
                    if( [nextStudy isDistant] == NO && nextStudy.images.count)
                        found = YES;
                }
            }
            else
            {
                NSBeep();
                break;
            }
            
        }while( found == NO);
        
        if( [nextStudy isDistant] == NO)
        {
            if( found)
            {
                [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: [databaseOutline rowForItem: nextStudy]] byExtendingSelection: NO];
                [self databaseOpenStudy: nextStudy];
            }
        }
        
        //		NSManagedObject	*series =  [[self childrenArray:nextStudy] objectAtIndex:0];
        //
        //		[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
        //
        //		[self loadNextSeries:[[self childrenArray: series] objectAtIndex: 0] :0 :viewer :YES keyImagesOnly:keyImages];
    }
    
    NSEnableScreenUpdates();
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixDidLoadNewObjectNotification object:study userInfo:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool: copyPatientsSettings forKey: @"onlyDisplayImagesOfSamePatient"];
}

-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
    NSManagedObjectModel	*model = self.database.managedObjectModel;
    NSManagedObjectContext	*context = self.database.managedObjectContext;
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
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(patientUID BEGINSWITH[cd] %@)", [study valueForKey:@"patientUID"]];
    NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
    [dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
    [dbRequest setPredicate: predicate];
    
    [context retain];
    [context lock];
    
    NSMutableArray *viewersArray = [NSMutableArray array];
    
    @try
    {
        NSError	*error = nil;
        NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
        NSArray	*seriesArray = [NSArray array];
        
        
        if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
        {
            NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
            NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
            [sort release];
            
            studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
            
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
                                [viewersArray addObject: [self childrenArray: [seriesArray objectAtIndex: index]]];
                                
                            }
                            else
                            {
                                [viewersArray addObject: [NSNull null]];
                                
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
    @catch ( NSException *e) {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        [context unlock];
        [context release];
    }
    
    if( viewersArray.count == viewersList.count)
    {
        int i = 0;
        for( ViewerController *vc in viewersList)
        {
            if( [viewersArray objectAtIndex: i] != [NSNull null])
                [self openViewerFromImages: [NSArray arrayWithObject: [viewersArray objectAtIndex: i]] movie: NO viewer:vc keyImagesOnly: keyImages];
            
            i++;
        }
    }
    
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
    BOOL movie4D = NO;
    
    if( [[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSControlKeyMask)
        movie4D = YES;
    
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        openReparsedSeriesFlag = YES;
        [self processOpenViewerDICOMFromArray: [NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer: viewer];
        openReparsedSeriesFlag = NO;
    }
    else
        return [self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: movie4D viewer :viewer keyImagesOnly:keyImages tryToFlipData: YES];
    
    return nil;
}

- (NSString*) exportDBListOnlySelected:(BOOL) onlySelected
{
    NSIndexSet *rowIndex;
    
    if( onlySelected) rowIndex = [databaseOutline selectedRowIndexes];
    else rowIndex = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange( 0, [databaseOutline numberOfRows])];
    
    NSMutableString	*string = [NSMutableString string];
    NSArray	*columns = [[databaseOutline tableColumns] valueForKey:@"identifier"];
    NSArray	*descriptions = [[databaseOutline tableColumns] valueForKey:@"headerCell"];
    int r;
    
    for( NSInteger x = 0; x < rowIndex.count; x++)
    {
        if( x == 0) r = rowIndex.firstIndex;
        else r = [rowIndex indexGreaterThanIndex: r];
        
        NSManagedObject *aFile = [databaseOutline itemAtRow: r];
        
        if( aFile && [[aFile valueForKey: @"type"] isEqualToString:@"Study"])
        {
            if( [string length])
                [string appendString: @"\r"];
            else // Header
            {
                int i = 0;
                for( NSCell *s in descriptions)
                {
                    @try
                    {
                        [string appendString: [s stringValue]];
                        i++;
                        if( i !=  [columns count])
                            [string appendFormat: @"%c", NSTabCharacter];
                    }
                    @catch ( NSException *e) {
                        N2LogException( e);
                    }
                }
                [string appendString: @"\r"];
            }
            
            int i = 0;
            for( NSString *identifier in columns)
            {
                @try
                {
                    if( [[aFile valueForKey: identifier] description])
                    {
                        NSCell *c = [[databaseOutline.tableColumns objectAtIndex: i] dataCell];
                        
                        if( c.formatter)
                            [string appendString: [c.formatter stringForObjectValue: [aFile valueForKey: identifier]]];
                        else
                            [string appendString: [[aFile valueForKey: identifier] description]];
                    }
                    i++;
                    
                    if( i !=  [columns count])
                        [string appendFormat: @"%c", NSTabCharacter];
                }
                @catch ( NSException *e) {
                    N2LogException( e);
                }
            }
        }
    }
    
    return string;
}

#ifndef OSIRIX_LIGHT

- (IBAction) pasteImageForSourceFile: (NSString*) sourceFile
{
    // If the clipboard contains an image -> generate a SC DICOM file corresponding to the selected patient
    if( [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypeTIFF])
    {
        NSImage *image = [[[NSImage alloc] initWithData: [[NSPasteboard generalPasteboard] dataForType: NSPasteboardTypeTIFF]] autorelease];
        
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
        
        NSBitmapImageRep *rep = (NSBitmapImageRep*) [image bestRepresentationForRect:NSMakeRect(0, 0, image.size.width, image.size.height) context:nil hints:nil];
        
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
                    [_database addFilesAtPaths: [NSArray arrayWithObject: f]
                             postNotifications: YES
                                     dicomOnly: YES
                           rereadExistingItems: YES
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
    
    [pb declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:self];
    
    NSString *string;
    
    if( [[databaseOutline selectedRowIndexes] count] == 1)
        string = [[databaseOutline itemAtRow: [databaseOutline selectedRowIndexes].firstIndex] valueForKey: @"name"];
    else
        string = [self exportDBListOnlySelected: YES];
    
    [pb setString: string forType:NSPasteboardTypeString];
}

- (IBAction) saveDBListAs:(id) sender
{
    NSString *list = [self exportDBListOnlySelected: NO];
    
    NSSavePanel *sPanel	= [NSSavePanel savePanel];
    [sPanel setAllowedFileTypes:@[@"txt"]];
    sPanel.nameFieldStringValue = NSLocalizedString(@"Horos Database List", nil);
    
    [sPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [list writeToURL:sPanel.URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    }];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Thumbnails Matrix & Preview functions

static BOOL withReset = NO;

- (DCMPix *)previewPix:(int)i
{
    @synchronized( previewPixThumbnails)
    {
        return [previewPix objectAtIndex:i];
    }
    
    return nil;
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
        
        
//        [cell setLineBreakMode: NSLineBreakByCharWrapping];
//        [cell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
//        
//        [cell setImagePosition: NSImageBelow];
//        [cell setTransparent:NO];
//        [cell setEnabled:YES];
//        
//        [cell setButtonType:NSPushOnPushOffButton];
//        [cell setBezelStyle:NSShadowlessSquareBezelStyle];
//        [cell setShowsStateBy:NSPushInCellMask];
//        [cell setHighlightsBy:NSContentsCellMask];
//        [cell setImageScaling:NSImageScaleProportionallyDown];
//        [cell setBordered:YES];
        
        
        
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
            //            id item = [matrixViewArray objectAtIndex: [cell tag]];
            
            NSArray *images = matrixViewArray.count? [self imagesArray: [matrixViewArray objectAtIndex: [cell tag]]] : nil;
            
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
            if( images == nil)
            {
                [self outlineViewRefresh];
                [self refreshMatrix: self];
                return;
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
    if( [NSThread isMainThread] == NO)
        return nil;
    
    DCMPix *returnPix = nil;
    
    //Is this image already displayed on the front most 2D viewers? -> take the dcmpix from there
    for( ViewerController *v in [ViewerController get2DViewers])
    {
        [v retain];
        
        if( ![v windowWillClose])
        {
            NSArray *vFileList = nil;
            NSArray *vPixList = nil;
            NSData *volumeData = nil;
            
            @try {
                // We need to temporarly retain all these objects
                vFileList = [[v fileList] copy];
                vPixList = [[v pixList] copy];
                volumeData = [[v volumeData] retain];
            }
            @catch (NSException * e) {
                N2LogExceptionWithStackTrace(e);
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
                N2LogExceptionWithStackTrace(e);
            }
            [volumeData release];
            [vFileList release];
            [vPixList release];
        }
        
        [v release];
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
                    
                    @synchronized( previewPixThumbnails)
                    {
                        [previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
                    }
                    
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
                        
                        DicomImage *imageObj = [images objectAtIndex: [animationSlider intValue]];
                        
                        if( [[[imageView curDCM] srcFile] isEqualToString: [[images objectAtIndex: [animationSlider intValue]] valueForKey:@"completePath"]] == NO || [[imageObj valueForKey: @"frameID"] intValue] != [[imageView curDCM] frameNo])
                        {
                            DCMPix *dcmPix = nil;
                            
                            dcmPix = [[self getDCMPixFromViewerIfAvailable: [imageObj valueForKey:@"completePath"] frameNumber: [[imageObj valueForKey: @"frameID"] intValue]] retain];
                            
                            if( dcmPix == nil)
                                dcmPix = [[DCMPix alloc] initWithPath: [imageObj valueForKey:@"completePath"] :[animationSlider intValue] :[images count] :nil :[[imageObj valueForKey: @"frameID"] intValue] :[[imageObj valueForKeyPath:@"series.id"] intValue] isBonjour:![_database isLocal] imageObj: imageObj];
                            
                            if( dcmPix)
                            {
                                float   wl, ww;
                                
                                [imageView getWLWW:&wl :&ww];
                                
                                @synchronized( previewPixThumbnails)
                                {
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
                    else if( noOfImages > 1)	// It's a multi-frame single image
                    {
                        animate = YES;
                        
                        if( [[[imageView curDCM] srcFile] isEqualToString: [[images objectAtIndex:0] valueForKey:@"completePath"]] == NO
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
                                
                                @synchronized( previewPixThumbnails)
                                {
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
}

//- (void) test:(id) s
//{
//    NSLog( @"--");
//
//    [NSThread sleepForTimeInterval: 2];
//}
//
//- (void) createThread
//{
//    NSAutoreleasePool *n = [NSAutoreleasePool new];
//
//    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector( test:) object: nil] autorelease];
//    t.name = NSLocalizedString( @"Test very small thread...", nil);
//    t.supportsCancel = YES;
//    [[ThreadsManager defaultManager] addThreadAndStart: t];
//
//    [n release];
//}

- (void)previewPerformAnimation: (id)sender
{
    //[NSThread detachNewThreadSelector: @selector( createThread) toTarget: self withObject: nil];
    
    //[self outlineViewRefresh];
    
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
        
//        if (dcmFile)
//        {
//            [theCell setLineBreakMode: NSLineBreakByCharWrapping];
//            [theCell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
//            
////            [theCell setRepresentedObject: [dcmFile objectID]];
//            
//            [theCell setImagePosition: NSImageBelow];
//            [theCell setTransparent:NO];
//            [theCell setEnabled:YES];
//            
//            [theCell setButtonType:NSPushOnPushOffButton];
//            [theCell setBezelStyle:NSShadowlessSquareBezelStyle];
//            //[theCell setShowsStateBy:NSPushInCellMask];
//            [theCell setHighlightsBy:NSContentsCellMask];
//            [theCell setImageScaling:NSImageScaleProportionallyDown];
//            [theCell setBordered:YES];
//        }
        
        
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
        
        if (dcmFile)
        {
//            [theCell setLineBreakMode: NSLineBreakByCharWrapping];
//            [theCell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
//            
//            [theCell setRepresentedObject: [dcmFile objectID]];
//            
//            [theCell setImagePosition: NSImageBelow];
//            [theCell setTransparent:NO];
//            [theCell setEnabled:YES];
//            
//            [theCell setButtonType:NSPushOnPushOffButton];
//            [theCell setBezelStyle:NSShadowlessSquareBezelStyle];
//            [theCell setShowsStateBy:NSPushInCellMask];
//            [theCell setHighlightsBy:NSContentsCellMask];
//            [theCell setImageScaling:NSImageScaleProportionallyDown];
//            [theCell setBordered:YES];
        }
        
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
    @synchronized( previewPixThumbnails)
    {
        [previewPix release]; previewPix = nil;
        previewPix = [[NSMutableArray alloc] init];
        
        [previewPixThumbnails removeAllObjects];
    }
    
    @synchronized( self)
    {
        setDCMDone = NO;
        loadPreviewIndex = 0;
        
        [self previewMatrixScrollViewFrameDidChange: nil];
        
        NSInteger rows, columns;
        [oMatrix getNumberOfRows:&rows columns:&columns];  if( columns < 1) columns = 1;
        
        for( long i=0; i < rows*columns; i++)
        {
            NSButtonCell* cell = [oMatrix cellAtRow:i/columns column:i%columns];
            cell.tag = i;
            [cell setTransparent:(i>=noOfImages)];
            [cell setEnabled:NO];
            [cell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
            [cell setImagePosition: NSImageBelow];
            cell.title = NSLocalizedString(@"loading...", nil);
            cell.image = nil;
            cell.bezelStyle = NSShadowlessSquareBezelStyle;
        }
        
        [imageView setPixels:nil files:nil rois:nil firstImage:0 level:0 reset:YES];
    }
}

- (void) matrixNewIcon:(long) index :(NSManagedObject*)curFile
{
    //	if( shouldDie == NO)
    {
        long i = index;
        NSImage *img = nil;
        
        if( curFile == nil)
        {
            [oMatrix setNeedsDisplay:YES];
            return;
        }
        
        @synchronized( previewPixThumbnails)
        {
            if( i >= [previewPix count]) return;
            if( i >= [previewPixThumbnails count]) return;
            
            img = [[previewPixThumbnails objectAtIndex: i] retain];
            if( img == nil) NSLog( @"Error: [previewPixThumbnails objectAtIndex: i] == nil");
        }
        
        //        [_database lock];
        @try
        {
            NSString *modality, *seriesSOPClassUID, *fileType;
            
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
            
            if( img || [modality  hasPrefix: @"RT"])
            {
                NSInteger rows, cols; [oMatrix getNumberOfRows:&rows columns:&cols]; if( cols < 1) cols = 1;
                NSButtonCell* cell = [oMatrix cellAtRow:i/cols column:i%cols];
                
                [cell setLineBreakMode: NSLineBreakByCharWrapping];
                [cell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
                
                [cell setRepresentedObject: [curFile objectID]];

                [cell setImagePosition: NSImageBelow];
                [cell setTransparent:NO];
                [cell setEnabled:YES];

                [cell setButtonType:NSPushOnPushOffButton];
                [cell setBezelStyle:NSShadowlessSquareBezelStyle];
//                [cell setShowsStateBy:NSPushInCellMask];
//                [cell setHighlightsBy:NSContentsCellMask];
                [cell setImageScaling:NSImageScaleProportionallyDown];
                [cell setBordered:YES];
                
                [cell setAction: @selector(matrixPressed:)];
                
                if ( [modality isEqualToString: @"RTSTRUCT"])
                {
                    [[contextualRT itemAtIndex: 0] setAction:@selector(createROIsFromRTSTRUCT:)];
                    [cell setMenu: contextualRT];
                }
                else
                    [cell setMenu: contextual];
                
                NSString *name = [curFile valueForKey:@"name"];
                
                if( name == nil)
                    name = @"";
                
                if( name.length > 18)
                {
                    [cell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbSmallMatrixFont"]]];
                    name = [name stringByTruncatingToLength: 36]; // 2 lines
                }
                
                if( name.length == 0)
                    name = modality;
                
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
                    int count = [[curFile valueForKey:@"noFiles"] intValue];
                    NSString *singleType = nil, *pluralType = nil;
                    
                    if( [DCMAbstractSyntaxUID isStructuredReport: seriesSOPClassUID] || [DCMAbstractSyntaxUID isPDF: seriesSOPClassUID])
                    {
                        if( count <= 1 && [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue] >= 1)
                            count = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
                        
                        singleType = NSLocalizedString(@"Page", nil);
                        pluralType = NSLocalizedString(@"Pages", nil);
                    }
                    else if( count == 1 && [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue] > 1)
                    {
                        count = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
                        singleType = NSLocalizedString(@"Frame", nil);
                        pluralType = NSLocalizedString(@"Frames", nil);
                    }
                    else if( count == 0)
                    {
                        count = [[curFile valueForKey: @"rawNoFiles"] intValue];
                        if( count <= 1 && [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue] >= 1)
                            count = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
                        
                        singleType = NSLocalizedString(@"Object", nil);
                        pluralType = NSLocalizedString(@"Objects", nil);
                    }
                    else
                    {
                        singleType = NSLocalizedString(@"Image", nil);
                        pluralType = NSLocalizedString(@"Images", nil);
                    }
                    
                    [cell setTitle:[NSString stringWithFormat: @"%@\r%@", name, N2LocalizedSingularPluralCount(count, singleType, pluralType)]];
                }
                else if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"])
                {
                    if( [DCMAbstractSyntaxUID isStructuredReport: seriesSOPClassUID] || [DCMAbstractSyntaxUID isPDF: seriesSOPClassUID])
                        [cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Page %d", nil), i+1]];
                    else if( [[curFile valueForKey: @"sliceLocation"] floatValue])
                        [cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d\r%.2f", nil), i+1, [[curFile valueForKey: @"sliceLocation"] floatValue]]];
                    else
                        [cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d", nil), i+1]];
                }
                
                [cell setButtonType:NSPushOnPushOffButton];
                
                if( [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue])
                {
                    NSImage *ii = [img imageInverted];
                    
                    [img release];
                    img = [ii retain];
                }
                
                [cell setHighlightsBy:NSNoCellMask]; // don't show highlight
                switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
                {
                    case -1:
                        [cell setImage: [img imageByScalingProportionallyUsingNSImage: 0.6]];
//                        [cell setAlternateImage: [img imageByScalingProportionallyUsingNSImage: 0.6]];
                        break;
                    case 0:
                        [cell setImage: img];
//                        [cell setAlternateImage:img];
                        break;
                    case 1:
                        [cell setImage: [img imageByScalingProportionallyUsingNSImage: 1.3]];
//                        [cell setAlternateImage:[img imageByScalingProportionallyUsingNSImage: 1.3]];
                        break;
                }
                
                if( setDCMDone == NO)
                {
                    NSIndexSet  *index = [databaseOutline selectedRowIndexes];
                    if( [index count] >= 1)
                    {
                        NSManagedObject* aFile = [databaseOutline itemAtRow:[index firstIndex]];
                        
                        @synchronized( previewPixThumbnails)
                        {
                            [imageView setPixels:previewPix files:[self imagesArray: aFile preferredObject: oAny] rois:nil firstImage:[[oMatrix selectedCell] tag] level:'i' reset:YES];
                        }
                        
                        [imageView setStringID:@"previewDatabase"];
                        setDCMDone = YES;
                    }
                }
            }
            else
            {  // Show Error Button
                NSInteger rows, cols; [oMatrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                NSButtonCell* cell = [oMatrix cellAtRow:i/cols column:i%cols];
                
                [cell setLineBreakMode: NSLineBreakByCharWrapping];
                [cell setFont:[NSFont systemFontOfSize: [self fontSize: @"dbMatrixFont"]]];
                
                [cell setRepresentedObject: nil];
                
                [cell setImagePosition: NSImageBelow];
                [cell setTransparent:NO];
                [cell setEnabled:NO];
                
                [cell setButtonType:NSPushOnPushOffButton];
                [cell setBezelStyle:NSShadowlessSquareBezelStyle];
//                [cell setShowsStateBy:NSPushInCellMask];
//                [cell setHighlightsBy:NSContentsCellMask];
                [cell setImageScaling:NSImageScaleProportionallyDown];
                [cell setBordered:YES];
                
                [oMatrix setToolTip: NSLocalizedString(@"File not readable", nil) forCell:cell];
                [cell setTitle: NSLocalizedString(@"File not readable", nil)];
                [cell setImage:nil];
                [cell setTag:i];
            }
        }
        @catch( NSException *ne)
        {
            if (![[ne name] isEqualToString:NSObjectInaccessibleException])
                N2LogExceptionWithStackTrace(ne);
        }
        @finally
        {
            //            [_database unlock];
        }
        
        [img release];
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
    NSString *pathToPDF = [[self.database baseDirPath] stringByAppendingPathComponent:@"PDF"];
    if (!([[NSFileManager defaultManager] fileExistsAtPath:pathToPDF]))
        [[NSFileManager defaultManager] createDirectoryAtPath:pathToPDF withIntermediateDirectories:YES attributes:nil error:NULL];
    
    //pathToPDF = /PDF/yyyymmdd.hhmmss.pdf
    NSDateFormatter *datetimeFormatter = [[[NSDateFormatter alloc]initWithDateFormat:@"%Y%m%d.%H%M%S" allowNaturalLanguage:NO] autorelease];
    pathToPDF = [pathToPDF stringByAppendingPathComponent: [datetimeFormatter stringFromDate:[NSDate date]]];
    pathToPDF = [pathToPDF stringByAppendingPathExtension:@"pdf"];
    NSLog( @"%@", pathToPDF);
    
    //creating file and opening it with preview
    NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [[sender selectedCell] tag]];
    NSLog( @"%@", [curObj valueForKey: @"type"]);
    
    //	[_database lock];
    
    @try
    {
        if( [[curObj valueForKey:@"type"] isEqualToString: @"Series"])
            curObj = [[self childrenArray: curObj] objectAtIndex: 0];
        
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    //	[_database unlock];
    
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
        @synchronized( previewPixThumbnails)
        {
            if ([previewPix count] && loadPreviewIndex < [previewPix count])
            {
                long i;
                for( i = 0; i < [previewPix count]; i++)
                {
                    NSInteger rows, cols; [oMatrix getNumberOfRows:&rows columns:&cols];  if( cols < 1) cols = 1;
                    NSButtonCell* cell = [oMatrix cellAtRow:i/cols column:i%cols];
                    
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
    }
    
    @catch( NSException *ne)
    {
        N2LogExceptionWithStackTrace(ne);
    }
}

+(NSData*)produceJPEGThumbnail:(NSImage*)image
{
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
    
    NSManagedObjectContext *context = self.database.managedObjectContext;
    NSManagedObjectModel *model = self.database.managedObjectModel;
    
    NSString *recoveryPath = [[[[BrowserController currentBrowser] database] baseDirPath] stringByAppendingPathComponent:@"ThumbnailPath"];
    if( [[NSFileManager defaultManager] fileExistsAtPath: recoveryPath])
    {
        //	displayEmptyDatabase = YES;
        [self outlineViewRefresh];
        [self refreshMatrix: self];
        NSString *uri = [NSString stringWithContentsOfFile:recoveryPath usedEncoding:NULL error:NULL];
        
        [[NSFileManager defaultManager] removeItemAtPath: recoveryPath error:NULL];
        
        NSManagedObject *studyObject = nil;
        
        @try
        {
            studyObject = [context existingObjectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]] error: nil];
        }
        
        @catch( NSException *ne)
        {
            N2LogExceptionWithStackTrace(ne);
        }
        
        if( studyObject)
        {
            int r;
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"])
                r = NSAlertDefaultReturn;
            else
                r = NSRunAlertPanel( NSLocalizedString(@"Corrupted files", nil), NSLocalizedString(@"A corrupted study crashed OsiriX:\r\r%@ / %@\r\rThis file will be deleted.\r\rYou can run OsiriX in Protected Mode (shift + option keys at startup) if you have more crashes.\r\rShould I delete this corrupted study? (Highly recommended)", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil, [studyObject valueForKey:@"name"], [studyObject valueForKey:@"studyName"]);
            
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
                    N2LogExceptionWithStackTrace(ne);
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
                    N2LogExceptionWithStackTrace(ne);
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
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
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
        N2LogExceptionWithStackTrace(e);
    }
    
    [context unlock];
}

-(IBAction)retrieveSelectedPODStudies:(id) sender
{
    @try
    {
        NSIndexSet* selectedRows = [databaseOutline selectedRowIndexes];
        NSInteger row;
        
        if( [databaseOutline selectedRow] >= 0)
        {
            for (NSInteger x = 0; x < selectedRows.count; x++)
            {
                if (x == 0) row = selectedRows.firstIndex;
                else row = [selectedRows indexGreaterThanIndex:row];
                
                id object = [databaseOutline itemAtRow:row];
                
                if( [object isDistant])
                {
                    // Check to see if already in retrieving mode, if not download it
                    [self retrieveComparativeStudy: object select: NO open: NO showGUI: NO];
                }
            }
        }
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
}

-(IBAction)rebuildThumbnails:(id)sender
{
    //	[_database lock];
    @try
    {
        NSIndexSet* selectedRows = [databaseOutline selectedRowIndexes];
        NSInteger row;
        
        if ([databaseOutline selectedRow] >= 0)
            for (NSInteger x = 0; x < selectedRows.count; x++)
            {
                if (x == 0) row = selectedRows.firstIndex;
                else row = [selectedRows indexGreaterThanIndex:row];
                
                NSManagedObject* object = [databaseOutline itemAtRow:row];
                
                if ([[object valueForKey:@"type"] isEqualToString:@"Study"])
                    [[self childrenArray:object] setValue:nil forKey:@"thumbnail"];
                if ([[object valueForKey:@"type"] isEqualToString:@"Series"])
                    [object setValue:nil forKey:@"thumbnail"];
            }
        
        [_database save:NULL];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        //		[_database unlock];
    }
    
    [self refreshMatrix: self];
}

- (void)matrixLoadIcons: (NSDictionary*)dict
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    if( [NSThread isMainThread] == NO)
        [NSThread currentThread].name = @"matrixLoadIcons";
    
    @try
    {
        NSArray* objectIDs = [dict valueForKey: @"objectIDs"];
        BOOL imageLevel = [[dict valueForKey:@"imageLevel"] boolValue];
        DicomDatabase *idatabase = [dict valueForKey:@"DicomDatabase"];
        id context = [dict valueForKey:@"Context"];
        
        if( [NSThread isMainThread] == NO)
            idatabase = [idatabase independentDatabase]; // INDEPENDANT CONTEXT !
        
        NSMutableArray *tempPreviewPixThumbnails = nil;
        NSMutableArray *tempPreviewPix = nil;
        
        @synchronized( previewPixThumbnails)
        {
            if( [[NSThread currentThread] isCancelled])
                return;
            
            tempPreviewPixThumbnails = [[previewPixThumbnails mutableCopy] autorelease];
            tempPreviewPix = [[previewPix mutableCopy] autorelease];
        }
        
        for (int i = 0; i < objectIDs.count; i++)
        {
            @try
            {
                if( [[NSThread currentThread] isCancelled])
                    break;
                
                if( i != 0)
                {
                    // only do it on a delayed basis
                    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
                    if (now-_timeIntervalOfLastLoadIconsDisplayIcons > 0.5)
                    {
                        _timeIntervalOfLastLoadIconsDisplayIcons = now;
                        @synchronized( previewPixThumbnails)
                        {
                            if( [[NSThread currentThread] isCancelled] == NO)
                            {
                                if( previewPix == context)
                                {
                                    [previewPixThumbnails removeAllObjects];
                                    [previewPixThumbnails addObjectsFromArray: tempPreviewPixThumbnails];
                                    
                                    [previewPix removeAllObjects];
                                    [previewPix addObjectsFromArray: tempPreviewPix];
                                }
                            }
                        }
                        
                        if( [NSThread isMainThread] == NO && [[NSThread currentThread] isCancelled] == NO)
                            [self performSelectorOnMainThread:@selector(matrixDisplayIcons:) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
                    }
                }
                
                DicomImage* image = [idatabase objectWithID:[objectIDs objectAtIndex:i]];
                if (!image) break; // the objects don't exist anymore, the selection has very likely changed after this call
                
                int frame = 0;
                if (image.numberOfFrames.intValue > 1)
                    frame = image.numberOfFrames.intValue/2;
                if (image.frameID) frame = image.frameID.intValue;
                
                DCMPix* dcmPix = [self getDCMPixFromViewerIfAvailable:image.completePath frameNumber: frame];
                if (dcmPix == nil)
                    dcmPix = [[[DCMPix alloc] initWithPath:image.completePath :0 :1 :nil :frame :0 isBonjour:![idatabase isLocal] imageObj: image] autorelease];
                
                if (!imageLevel)
                {
                    NSData* dbThmb = image.series.thumbnail;
                    if (dbThmb)
                    {
                        NSImageRep* rep = [[[NSBitmapImageRep alloc] initWithData:dbThmb] autorelease];
                        NSImage* dbIma = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
                        [dbIma addRepresentation:rep];
                        
                        DCMPix *pix = (dcmPix? dcmPix : [[[DCMPix alloc] myinitEmpty] autorelease]);
                        
                        [tempPreviewPixThumbnails replaceObjectAtIndex: i withObject: dbIma];
                        [tempPreviewPix addObject: pix];
                        continue;
                    }
                }
                
                if (dcmPix)
                {
                    if ([DCMAbstractSyntaxUID isStructuredReport:image.series.seriesSOPClassUID] || [DCMAbstractSyntaxUID isPDF:image.series.seriesSOPClassUID])
                    {
                        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"txt"];
                        
                        NSImage *thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( THUMBNAILSIZE, THUMBNAILSIZE)] autorelease];
                        
                        [thumbnail lockFocus];
                        [icon drawInRect: NSMakeRect( 0, 0, THUMBNAILSIZE, THUMBNAILSIZE) fromRect: [icon alignmentRect] operation: NSCompositeCopy fraction: 1.0];
                        [thumbnail unlockFocus];
                        
                        [tempPreviewPixThumbnails replaceObjectAtIndex: i withObject: thumbnail];
                        [tempPreviewPix addObject: dcmPix];
                    }
                    else
                    {
                        NSImage* thumbnail = [dcmPix generateThumbnailImageWithWW:image.series.windowWidth.floatValue WL:image.series.windowLevel.floatValue];
                        [dcmPix revert:NO];	// <- Kill the raw data
                        if (thumbnail == nil || dcmPix.notAbleToLoadImage == YES) thumbnail = notFoundImage;
                        
                        [tempPreviewPixThumbnails replaceObjectAtIndex: i withObject: thumbnail];
                        [tempPreviewPix addObject: dcmPix];
                    }
                    continue;
                }
            }
            @catch (NSException* e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            // successful iterations don't execute this (they continue to the next iteration), this is in case no image has been provided by this iteration (exception, no file, ...)
            
            [tempPreviewPixThumbnails replaceObjectAtIndex: i withObject: notFoundImage];
            [tempPreviewPix addObject: [[[DCMPix alloc] myinitEmpty] autorelease]];
        }
        
        
        @synchronized( previewPixThumbnails)
        {
            if( [[NSThread currentThread] isCancelled] == NO)
            {
                if( previewPix == context)
                {
                    [previewPixThumbnails removeAllObjects];
                    [previewPixThumbnails addObjectsFromArray: tempPreviewPixThumbnails];
                    
                    [previewPix removeAllObjects];
                    [previewPix addObjectsFromArray: tempPreviewPix];
                }
            }
            
            if( [NSThread isMainThread] == NO)
                [self performSelectorOnMainThread:@selector(matrixDisplayIcons:) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
            else
                [self matrixDisplayIcons: nil];
        }
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [pool release];
    }
}

+(NSInteger)_scrollerStyle:(NSScroller*)scroller {
    if ([scroller respondsToSelector:@selector(scrollerStyle)]) {
        NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[scroller methodSignatureForSelector:@selector(scrollerStyle)]];
        [inv setSelector:@selector(scrollerStyle)];
        [inv invokeWithTarget:scroller];
        NSInteger r; [inv getReturnValue:&r];
        return r;
    }
    
    return 0; // NSScrollerStyleLegacy is 0
}

- (CGFloat)splitView:(NSSplitView*)sender
constrainSplitPosition:(CGFloat)proposedPosition
         ofSubviewAt:(NSInteger)offset
{
    //    if( starting)
    //        return proposedPosition;
    
    if (sender == splitViewVert)
    {
        _splitViewVertDividerRatio = proposedPosition/sender.bounds.size.width;
        
        CGFloat rcs = oMatrix.cellSize.width+oMatrix.intercellSpacing.width;
        
        CGFloat scrollbarWidth = 0;
        if ([thumbnailsScrollView isKindOfClass:[NSScrollView class]])
        {
            NSScroller* scroller = [thumbnailsScrollView verticalScroller];
            if ([[self class] _scrollerStyle:scroller] != 1)
                if ([thumbnailsScrollView hasVerticalScroller] && ![scroller isHidden])
                    scrollbarWidth = [scroller frame].size.width;
        }
        
        proposedPosition -= scrollbarWidth;
        
        int hcells = MAX(roundf((proposedPosition+oMatrix.intercellSpacing.width)/rcs), 1);
        proposedPosition = rcs*hcells-oMatrix.intercellSpacing.width;
        proposedPosition = MIN(proposedPosition, [sender maxPossiblePositionOfDividerAtIndex:offset]);
        
        proposedPosition += (scrollbarWidth?scrollbarWidth+3:2);
        
        return proposedPosition;
    }
    
    if (sender == splitDrawer)
    {
        proposedPosition = MAX(proposedPosition, [sender minPossiblePositionOfDividerAtIndex:offset]);
        proposedPosition = MIN(proposedPosition, [sender maxPossiblePositionOfDividerAtIndex:offset]);
    }
    
    if (sender == splitComparative)
    {
        proposedPosition = MAX(proposedPosition, [sender minPossiblePositionOfDividerAtIndex:offset]);
        proposedPosition = MIN(proposedPosition, [sender maxPossiblePositionOfDividerAtIndex:offset]);
    }
    
    if ([sender isEqual: bannerSplit])
    {
        return [sender frame].size.height - (banner.image.size.height+3);
    }
    
    if ([sender isEqual: splitAlbums])
    {
        proposedPosition = MAX(proposedPosition, [sender minPossiblePositionOfDividerAtIndex:offset]);
        proposedPosition = MIN(proposedPosition, [sender maxPossiblePositionOfDividerAtIndex:offset]);
    }
    
    return proposedPosition;
}

-(void)observeScrollerStyleDidChangeNotification:(NSNotification*)n {
    NSRect frame = [thumbnailsScrollView.superview bounds];
    if ([[self class] _scrollerStyle:thumbnailsScrollView.verticalScroller] == 1) { // overlay
        frame.origin.x += 2; frame.size.width -= 2;
        [thumbnailsScrollView setFrame:frame];
    } else {
        frame.origin.x += 2; frame.size.width -= 3;
        [thumbnailsScrollView setFrame:frame];
    }
    [splitViewVert resizeSubviewsWithOldSize:[splitViewVert bounds].size];
}

- (void) windowDidChangeScreen:(NSNotification *)aNotification
{
        NSLog(@"windowDidChangeScreen");
        
        @try {
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
                        NSLog( @"[[self window] frame]: %@", NSStringFromRect( [[self window] frame]));
                        NSLog( @"visibleScreenRect[ i]: %@", NSStringFromRect( visibleScreenRect[ i]));
                        
                        dbScreenChanged = YES;
                    }
                    
                    ratioX = visibleScreenRect[ i].size.width / [s visibleFrame].size.width;
                    ratioY = visibleScreenRect[ i].size.height / [s visibleFrame].size.height;
                    
                    visibleScreenRect[ i] = [s visibleFrame];
                }
            }
            
            if( dbScreenChanged)
            {
                //[[self window] zoom: self];
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
        @catch (NSException *exception) {
            N2LogException( exception);
            [[AppController sharedAppController] closeAllViewers: self];
        }
}

-(void)previewMatrixScrollViewFrameDidChange:(NSNotification*)note
{
    if( matrixViewArray.count == 0)
        return;
    
    NSInteger selectedCellTag = [oMatrix.selectedCell tag];
    
    CGFloat rcs = oMatrix.cellSize.width+oMatrix.intercellSpacing.width;
    
    NSSize size = thumbnailsScrollView.bounds.size;
    size.width += oMatrix.intercellSpacing.width;
    
    if( rcs > 0)
    {
        NSInteger hcells = (NSInteger)roundf(size.width/rcs);
        
        if( hcells > 0)
        {
            NSInteger vcells = ceilf(1.0*matrixViewArray.count/hcells); //MAX(1, (NSInteger)ceilf(1.0*matrixViewArray.count/hcells));
            
            if( vcells < 1)
                vcells = 1;
            
            if( vcells > 0 && hcells > 0)
            {
                [oMatrix renewRows:vcells columns:hcells];
                
                @synchronized( previewPixThumbnails)
                {
                    for (int i = [previewPix count]; i < hcells*vcells; ++i)
                    {
                        NSButtonCell* cell = [oMatrix cellAtRow:i/hcells column:i%hcells];
                        [cell setTransparent:YES];
                        [cell setEnabled:NO];
                    }
                }
                
                [oMatrix sizeToCells];
                [oMatrix selectCellWithTag:selectedCellTag];
            }
        }
    }
}

#pragma mark - NSSplitViewDelegate

-(void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
    //    if( starting)
    //        return;
    
    if (sender == splitDrawer)
    {
        NSView* left = [[sender subviews] objectAtIndex:0];
        NSView* right = [[sender subviews] objectAtIndex:1];
        
        NSRect splitFrame = [sender frame];
        CGFloat dividerThickness = [sender dividerThickness];
        CGFloat availableWidth = splitFrame.size.width - dividerThickness;
        
        NSRect leftFrame = [left frame];
        NSRect rightFrame = [right frame];
        
        leftFrame.size.height = splitFrame.size.height;
        [left setFrame:leftFrame];
        
        if ([splitDrawer isSubviewCollapsed: [[splitDrawer subviews] objectAtIndex:0]] || [left isHidden])
            leftFrame.size.width = 0;
        
        rightFrame.origin.x = leftFrame.origin.x + leftFrame.size.width + dividerThickness;
        rightFrame.size.height = splitFrame.size.height;
        rightFrame.size.width = availableWidth - leftFrame.size.width;
        [right setFrame:rightFrame];
        
        return;
    }
    
    if (sender == splitComparative)
    {
#define MINIMUMSIZEFORCOMPARATIVEDRAWER_HORZ 50
        if( gHorizontalHistory)
        {
            NSView* top = [[sender subviews] objectAtIndex:0];
            NSView* bottom = [[sender subviews] objectAtIndex:1];
            
            NSRect splitFrame = [sender frame];
            CGFloat dividerThickness = [sender dividerThickness];
            CGFloat availableHeight = splitFrame.size.height - dividerThickness;
            
            NSRect topFrame = [top frame];
            NSRect bottomFrame = [bottom frame];
            
            topFrame.origin.x = 0;
            bottomFrame.origin.x = 0;
            
            topFrame.size.height += oldSize.height - splitFrame.size.height;
            bottomFrame.size.height -= oldSize.height - splitFrame.size.height;
            
            if ([splitComparative isSubviewCollapsed: [[splitComparative subviews] objectAtIndex:0]] || [top isHidden])
                bottomFrame.size.height = availableHeight;
            else if( topFrame.size.height < MINIMUMSIZEFORCOMPARATIVEDRAWER_HORZ || availableHeight - bottomFrame.size.height < MINIMUMSIZEFORCOMPARATIVEDRAWER_HORZ)
                bottomFrame.size.height = availableHeight - MINIMUMSIZEFORCOMPARATIVEDRAWER_HORZ;
            
            if( bottomFrame.size.height > availableHeight)
                bottomFrame.size.height = availableHeight;
            
            topFrame.size.width = splitFrame.size.width;
            topFrame.size.height = availableHeight - bottomFrame.size.height;
            
            bottomFrame.size.width = splitFrame.size.width;
            bottomFrame.size.height = availableHeight - topFrame.size.height;
            bottomFrame.origin.y = topFrame.origin.y + topFrame.size.height + dividerThickness;
            
            topFrame.size.height = availableHeight - bottomFrame.size.height;
            
            [top setFrame:topFrame];
            [bottom setFrame:bottomFrame];
        }
        else
        {
#define MINIMUMSIZEFORCOMPARATIVEDRAWER 192
            NSView* left = [[sender subviews] objectAtIndex:0];
            NSView* right = [[sender subviews] objectAtIndex:1];
            
            NSRect splitFrame = [sender frame];
            CGFloat dividerThickness = [sender dividerThickness];
            CGFloat availableWidth = splitFrame.size.width - dividerThickness;
            
            NSRect leftFrame = [left frame];
            NSRect rightFrame = [right frame];
            
            leftFrame.size.width -= oldSize.width - splitFrame.size.width;
            rightFrame.size.width += oldSize.width - splitFrame.size.width;
            
            if ([splitComparative isSubviewCollapsed: [[splitComparative subviews] objectAtIndex:1]] || [right isHidden])
                leftFrame.size.width = availableWidth;
            else if( rightFrame.size.width < MINIMUMSIZEFORCOMPARATIVEDRAWER || availableWidth - leftFrame.size.width < MINIMUMSIZEFORCOMPARATIVEDRAWER)
                leftFrame.size.width = availableWidth - MINIMUMSIZEFORCOMPARATIVEDRAWER;
            
            if( leftFrame.size.width > availableWidth)
                leftFrame.size.width = availableWidth;
            
            rightFrame.size.height = splitFrame.size.height;
            rightFrame.origin.x = leftFrame.origin.x + leftFrame.size.width + dividerThickness;
            rightFrame.size.width = availableWidth - leftFrame.size.width;
            if( rightFrame.size.width >= 192)
                rightFrame.size.width = 192;
            
            leftFrame.size.height = splitFrame.size.height;
            leftFrame.size.width = availableWidth - rightFrame.size.width;
            
            rightFrame.origin.x = leftFrame.origin.x + leftFrame.size.width + dividerThickness;
            rightFrame.size.width = availableWidth - leftFrame.size.width;
            
            [right setFrame:rightFrame];
            [left setFrame:leftFrame];
        }
        return;
    }
    
    if (sender == splitViewVert)
    {
        if (!_splitViewVertDividerRatio)
            _splitViewVertDividerRatio = [[[sender subviews] objectAtIndex:0] bounds].size.width/oldSize.width;
        
        CGFloat dividerPosition = [sender bounds].size.width*_splitViewVertDividerRatio;
        CGFloat save = _splitViewVertDividerRatio;
        dividerPosition = [self splitView:sender constrainSplitPosition:dividerPosition ofSubviewAt:0];
        _splitViewVertDividerRatio = save;
        
        NSRect splitFrame = [sender frame];
        
        [[[sender subviews] objectAtIndex:0] setFrame:NSMakeRect(0, 0, dividerPosition, splitFrame.size.height)];
        [[[sender subviews] objectAtIndex:1] setFrame:NSMakeRect(dividerPosition+sender.dividerThickness, 0, splitFrame.size.width-dividerPosition-sender.dividerThickness, splitFrame.size.height)];
        
        return;
    }
    
    if (sender == _bottomSplit)
    {
        [self splitViewDidResizeSubviews:[NSNotification notificationWithName:NSSplitViewDidResizeSubviewsNotification object:splitViewVert]];
        return;
    }
    
    [sender adjustSubviews];
}

-(void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    //    if( starting)
    //        return;
    
    N2OpenGLViewWithSplitsWindow *window = (N2OpenGLViewWithSplitsWindow*)self.window;
    
    if( [window respondsToSelector:@selector(disableUpdatesUntilFlush)])
        [window disableUpdatesUntilFlush];
}

- (void)splitViewDidResizeSubviews: (NSNotification *)notification
{
    //    if( starting)
    //        return;
    
    if ([notification object] == splitViewVert)
    {
        NSView* theView = [[splitViewVert subviews] objectAtIndex:0];
        NSRect theRect = [theView.window.contentView convertRect:theView.bounds fromView:theView];
        CGFloat dividerPosition = theRect.origin.x+theRect.size.width;
        NSRect splitFrame = [_bottomSplit frame];
        [[[_bottomSplit subviews] objectAtIndex:0] setFrame:NSMakeRect(0, 0, dividerPosition, splitFrame.size.height)];
        [[[_bottomSplit subviews] objectAtIndex:1] setFrame:NSMakeRect(dividerPosition+_bottomSplit.dividerThickness, 0, splitFrame.size.width-dividerPosition-_bottomSplit.dividerThickness, splitFrame.size.height)];
        
        [animationSlider setFrameSize:NSMakeSize(splitFrame.size.width-dividerPosition-_bottomSplit.dividerThickness-animationCheck.frame.size.width-10, animationSlider.frame.size.height)]; // for some weird reason, we need this..
    }
#ifdef WITH_BANNER
    else
        if ([notification object] == bannerSplit)
        {
            static BOOL noReentry = 1;
            if( noReentry)
            {
                noReentry = 0;
                CGFloat position = bannerSplit.frame.size.height - (banner.image.size.height + 3);
                [bannerSplit setPosition: position ofDividerAtIndex: 0];
                noReentry = 1;
            }
        }
#endif // WITH_BANNER
}

- (BOOL)splitView: (NSSplitView *)sender canCollapseSubview: (NSView *)subview
{
    if (sender == splitViewVert)
        return NO;
    
    if (sender == splitAlbums)
        return NO;
    
    if (sender == splitDrawer && subview == [[splitDrawer subviews] objectAtIndex:1])
        return NO;
    
    if (sender == splitComparative)
    {
        if( gHorizontalHistory)
        {
            if( subview == [[splitComparative subviews] objectAtIndex: 1])
                return NO;
        }
        else
        {
            if( subview == [[splitComparative subviews] objectAtIndex: 0])
                return NO;
        }
    }
    if (sender == _bottomSplit)
        return NO;
    
    return YES;
}

- (IBAction)comparativeToggle:(id)sender
{
    if( gHorizontalHistory)
    {
        NSView* top = [[splitComparative subviews] objectAtIndex:0];
        BOOL shouldExpand = [top isHidden] || [splitComparative isSubviewCollapsed:[[splitComparative subviews] objectAtIndex:0]];
        
        [top setHidden:!shouldExpand];
    }
    else
    {
        NSView* right = [[splitComparative subviews] objectAtIndex:1];
        BOOL shouldExpand = [right isHidden] || [splitComparative isSubviewCollapsed:[[splitComparative subviews] objectAtIndex:1]];
        
        [right setHidden:!shouldExpand];
    }
    
    [splitComparative resizeSubviewsWithOldSize:splitComparative.bounds.size];
}

- (IBAction)drawerToggle: (id)sender
{
    NSView* left = [[splitDrawer subviews] objectAtIndex:0];
    BOOL shouldExpand = [left isHidden] || [splitDrawer isSubviewCollapsed:[[splitDrawer subviews] objectAtIndex:0]];
    
    [left setHidden:!shouldExpand];
    
    [splitDrawer resizeSubviewsWithOldSize:splitDrawer.bounds.size];
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate: (CGFloat)proposedMin ofSubviewAt: (NSInteger)offset
{
    if (sender == splitViewHorz)
        return oMatrix.cellSize.height;
    
    if (sender == splitViewVert)
        return oMatrix.cellSize.width;
    
    if (sender == splitDrawer)
        return MINIMUMSIZEFORCOMPARATIVEDRAWER;
    
    if (sender == splitAlbums)
    {
        if( offset == 0) return 20;
        else
            return [[[sender subviews] objectAtIndex: offset - 1] frame].origin.y + [[[sender subviews] objectAtIndex: offset - 1] frame].size.height + 20;
    }
    
    if( sender == splitComparative)
    {
        if( gHorizontalHistory)
            return MINIMUMSIZEFORCOMPARATIVEDRAWER_HORZ;
        else
            return [sender bounds].size.width-192;
    }
    
    if ([sender isEqual: bannerSplit])
    {
        return [sender frame].size.height - (banner.image.size.height+3);
    }
    
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate: (CGFloat)proposedMax ofSubviewAt: (NSInteger)offset
{
    if (sender == splitViewVert)
        return [sender bounds].size.width-200;
    
    if (sender == splitViewHorz)
        return [sender bounds].size.height- (2*[oMatrix cellSize].height);
    
    if (sender == splitDrawer)
        return 192;
    
    if (sender == splitComparative)
    {
        if( gHorizontalHistory)
        {
            return [sender bounds].size.height-150;
        }
        else
            return [sender bounds].size.width-MINIMUMSIZEFORCOMPARATIVEDRAWER;
    }
    
    if (sender == bannerSplit)
    {
        return [sender frame].size.height - (banner.image.size.height+3);
    }
    
    if (sender == splitAlbums)
    {
        if( offset == [[sender subviews] count]) return [sender bounds].size.width-20;
        else
            return [[[sender subviews] objectAtIndex: offset + 1] frame].origin.y + [[[sender subviews] objectAtIndex: offset + 1] frame].size.height - 20;
    }
    
    return proposedMax;
}

- (DicomImage *)firstObjectForDatabaseMatrixSelection
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
                    return (DicomImage*) curObj;
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
    
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
    [context retain];
    [context lock];
    
    @try
    {
        if( cells != nil && aFile != nil)
        {
            for( NSCell *cell in cells)
            {
                @autoreleasepool
                {
                    if( [cell isEnabled] == YES)
                    {
                        NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [cell tag]];
                        
                        if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
                            [correspondingManagedObjects addObject: curObj];
                        
                        if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
                            [correspondingManagedObjects addObjectsFromArray: [self imagesArray: curObj onlyImages: onlyImages]];
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
                @autoreleasepool
                {
                    if( [splash aborted] == NO)
                    {
                        [selectedFiles addObject: [self getLocalDCMPath: img :BONJOURPACKETS]];
                        
                        [splash incrementBy: 1];
                    }
                }
            }
            
            if( [splash aborted])
            {
                [selectedFiles removeAllObjects];
                [correspondingManagedObjects removeAllObjects];
            }
            
            [splash close];
            [splash autorelease];
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
        N2LogExceptionWithStackTrace(e);
    }
    
    [context release];
    [context unlock];
    
    return selectedFiles;
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects
{
    return [self filesForDatabaseMatrixSelection: correspondingManagedObjects onlyImages: YES];
}

- (IBAction) saveAlbums:(id) sender
{
    NSSavePanel *sPanel	= [NSSavePanel savePanel];
    [sPanel setAllowedFileTypes:@[@"albums"]];
    sPanel.nameFieldStringValue = NSLocalizedString(@"DatabaseAlbums.albums", nil);
    
    [sPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self.database saveAlbumsToPath:sPanel.URL.path];
    }];
}

- (void) addAlbumsFile: (NSString*) file
{
    [self.database loadAlbumsFromPath: file];
    
    [self refreshAlbums];
    
    [self outlineViewRefresh];
}

- (IBAction) addAlbums:(id) sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    oPanel.allowedFileTypes = @[@"albums"];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [self addAlbumsFile:oPanel.URL.path];
    }];
}

- (void) initContextualMenus // MATRIX contextual menu
{
    NSMenuItem		*item;
    
    // ****************
    
    if ( contextual == nil) contextual	= [[NSMenu alloc] initWithTitle: NSLocalizedString(@"Tools", nil)];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Open Images", nil) action:@selector(viewerDICOM:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open Images in 4D", nil) action:@selector(MovieViewerDICOM:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open Sub-Selection", nil) action:@selector(viewerSubSeriesDICOM:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open Reparsed series", nil) action:@selector(viewerReparsedSeries:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open Key Images", nil) action:@selector(viewerDICOMKeyImages:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open ROIs Images", nil) action:@selector(viewerDICOMROIsImages:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open ROIs and Key Images", nil) action:@selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Open Merged Selection", nil) action:@selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Reveal In Finder", nil) action:@selector(revealInFinder:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Export to DICOM Network Node", nil) action:@selector(export2PACS:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Export to Movie", nil) action:@selector(exportQuicktime:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Export to JPEG", nil) action:@selector(exportJPEG:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Export to TIFF", nil) action:@selector(exportTIFF:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Export to DICOM File(s)", nil) action:@selector(exportDICOMFile:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Export ROI and Key Images as a DICOM Series", nil) action:@selector(exportROIAndKeyImagesAsDICOMSeries:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Compress DICOM files", nil) action:@selector(compressSelectedFiles:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Decompress DICOM files", nil) action:@selector(decompressSelectedFiles:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Toggle Images/Series Displaying", nil) action:@selector(displayImagesOfSeries:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Merge Selected Series", nil) action:@selector(mergeSeries:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Delete", nil) action:@selector(delItem:) keyEquivalent:@""];
    [contextual addItem: [NSMenuItem separatorItem]];
    
    [contextual addItemWithTitle: NSLocalizedString(@"Query Selected Patient from Q&R Window...", nil) action:@selector(querySelectedStudy:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Burn", nil) action:@selector(burnDICOM:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Anonymize", nil) action:@selector(anonymizeDICOM:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Rebuild Selected Thumbnails", nil) action:@selector(rebuildThumbnails:) keyEquivalent:@""];
    [contextual addItemWithTitle: NSLocalizedString(@"Copy Linked Files to Database Folder", nil) action:@selector(copyToDBFolder:) keyEquivalent:@""];
    [oMatrix setMenu: contextual];
    
    // Create alternate contextual menu for RT objects
    
    if( contextualRT == nil) contextualRT = [contextual copy];
    
    item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Create ROIs from RTSTRUCT", nil)  action:@selector(createROIsFromRTSTRUCT:) keyEquivalent:@""] autorelease];
    [contextualRT insertItem: item atIndex: 0];
    
    [contextualRT insertItem: [NSMenuItem separatorItem] atIndex: 1];
    
    // Now remove non-applicable items - usually related to images (most RT objects don't have embedded images)
    
    NSInteger indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Images in 4D", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Key Images", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Sub-Selection", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Reparsed Series", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs Images", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs and Key Images", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to Movie", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to JPEG", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to TIFF", nil)];
    if ( indx >= 0) [contextualRT removeItemAtIndex: indx];
    
    // init albums contextual menu
    
    NSMenu* acm = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    [acm setDelegate:self];
    [albumTable setMenu:acm];
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
    SmartWindowController* swc = [[SmartWindowController alloc] initWithDatabase:self.database];
    
    [NSApp beginSheet:swc.window
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(smartAlbumSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
    
    /*[smartWindowController addSubview: nil];
     
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
     [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Album"]];
     [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
     NSManagedObjectContext *context = self.database.managedObjectContext;
     
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
     
     [album setValue: [smartWindowController sqlQueryString] forKey:@"predicateString"];
     [_database save:NULL];
     
     // Distant DICOM node filter
     if( [[[smartWindowController onDemandFilter] allKeys] count] > 0)
     {
     NSMutableArray *savedSmartAlbums = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"smartAlbumStudiesDICOMNodes"] mutableCopy] autorelease];
     
     NSUInteger idx = [[savedSmartAlbums valueForKey: @"name"] indexOfObject: name];
     
     if( idx != NSNotFound)
     [savedSmartAlbums removeObjectAtIndex: idx];
     
     NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool: NO], @"activated", name, @"name", nil];
     
     [dict addEntriesFromDictionary: [smartWindowController onDemandFilter]];
     
     [savedSmartAlbums addObject: dict];
     
     [[NSUserDefaults standardUserDefaults] setObject: savedSmartAlbums forKey: @"smartAlbumStudiesDICOMNodes"];
     }
     
     [self refreshAlbums];
     
     NSInteger index = [self.albumArray indexOfObject:album];
     if (index != NSNotFound)
     [albumTable selectRowIndexes: [NSIndexSet indexSetWithIndex:index] byExtendingSelection: NO];
     }
     @catch (NSException * e)
     {
     N2LogExceptionWithStackTrace(e);
     }
     
     [context unlock];
     
     [self outlineViewRefresh];
     
     if( [smartWindowController editSqlQuery])
     [self albumTableDoublePressed: self];
     }
     
     [smartWindowController release];*/
}

- (void)smartAlbumSheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
    [sheet orderOut:self];
    
    if (returnCode == NSRunStoppedResponse) {
        DicomAlbum* album = nil;
        if ([(id)contextInfo isKindOfClass:[DicomAlbum class]])
            album = [(id)contextInfo autorelease];
        
        if (!album)
            album = [self.database newObjectForEntity:self.database.albumEntity];
        
        SmartWindowController* swc = sheet.windowController;
        
        album.name = swc.name;
        album.smartAlbum = [NSNumber numberWithBool:YES];
        album.predicateString = [swc.predicate predicateFormat];
        [self.database save];
        
        [albumTable reloadData];
        
        if( [self.albumArray indexOfObject:album] != NSNotFound)
            [albumTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.albumArray indexOfObject:album]] byExtendingSelection:NO];
        
        @synchronized (self) {
            _cachedAlbumsContext = nil;
        }
        
        NSInteger index = [self.albumArray indexOfObject:album];
        if (index != NSNotFound)
            [albumTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        
        [self outlineViewRefresh];
        
        [self refreshAlbums];
    }
    
    [sheet.windowController release];
}

- (IBAction) addAlbum:(id)sender
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
        NSString *name;
        int i = 2;
        
        NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
        [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Album"]];
        [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
        
        NSManagedObjectContext *context = self.database.managedObjectContext;
        
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
            
            [_database save];
            
            [self refreshAlbums];
        }
        @catch (NSException * e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
            [e printStackTrace];
        }
        
        [context unlock];
        
        [self outlineViewRefresh];
    }
}

- (IBAction) deleteAlbum: (id)sender
{
    if( albumTable.selectedRow > 0)
    {
        DicomAlbum* album = [self.albumArray objectAtIndex:albumTable.selectedRow];
        
        [self removeAlbumObject:album];
    }
}

-(void)removeAlbum:(id)sender // contextual menu action
{
    NSInteger row = [albumTable clickedRow];
    if (!row) return;
    
    DicomAlbum* album = [self.albumArray objectAtIndex:row];
    
    [self removeAlbumObject:album];
}

-(void)removeAlbumObject:(DicomAlbum*)album {
    if ((album.smartAlbum.boolValue == NO && album.studies.count == 0) ||
        NSRunInformationalAlertPanel(NSLocalizedString(@"Delete Album", nil),
                                     NSLocalizedString(@"Are you sure you want to delete the album named %@?", nil),
                                     NSLocalizedString(@"OK",nil),
                                     NSLocalizedString(@"Cancel",nil),
                                     nil,
                                     album.name) == NSAlertDefaultReturn)
    {
        [self.database lock];
        @try
        {
            [self.database.managedObjectContext deleteObject:album];
            
            @synchronized (self) {
                _cachedAlbumsContext = nil;
            }
            @synchronized(_albumNoOfStudiesCache) {
                [_albumNoOfStudiesCache removeAllObjects];
                [_distantAlbumNoOfStudiesCache removeAllObjects];
                [albumTable reloadData];
            }
            
            [self.database save:NULL];
            [self refreshAlbums];
            [self outlineViewRefresh];
        }
        @catch (NSException* e)
        {
            N2LogException(e);
        }
        @finally
        {
            [self.database unlock];
        }
    }
}

- (IBAction) albumTableDoublePressed: (id)sender
{
    if( albumTable.selectedRow > 0 && [_database isLocal])
    {
        DicomAlbum* album = [self.albumArray objectAtIndex:albumTable.selectedRow];
        
        if ([[album valueForKey:@"smartAlbum"] boolValue] == YES)
        {
            SmartWindowController* swc = [[SmartWindowController alloc] initWithDatabase:self.database];
            swc.name = album.name;
            swc.predicate = [NSPredicate predicateWithFormat:album.predicateString];
            swc.album = album;
            
            [NSApp beginSheet:swc.window
               modalForWindow:self.window
                modalDelegate:self
               didEndSelector:@selector(smartAlbumSheetDidEnd:returnCode:contextInfo:)
                  contextInfo:[album retain]];
            
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
                    [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Album"]];
                    [dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
                    NSManagedObjectContext *context = self.database.managedObjectContext;
                    
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
                        N2LogExceptionWithStackTrace(e);
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
    if( !_database) return [NSArray array];
    if( !_database.managedObjectContext) return [NSArray array];
    
    return [[NSArray arrayWithObject:[NSDictionary dictionaryWithObject: NSLocalizedString(@"Database", nil) forKey:@"name"]] arrayByAddingObjectsFromArray:[self albumsInDatabase]];
}

- (NSManagedObjectID*) currentAlbumID: (DicomDatabase*) d
{
    if( d == nil)
        d = [NSThread isMainThread] ? _database : _database.independentDatabase;
    
    NSString *albumName = self.selectedAlbumName;
    
    if( albumName)
        return [[[d objectsForEntity: d.albumEntity predicate: [NSPredicate predicateWithFormat: @"name == %@", albumName]] lastObject] objectID];
    
    return nil;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Albums TableView functions

//NSTableView delegate and datasource
- (NSInteger)numberOfRowsInTableView: (NSTableView *)aTableView
{
    if ([aTableView isEqual:albumTable] && _database)
    {
        return [self.albumArray count];
    }
    
    if ([aTableView isEqual: comparativeTable] && _database)
    {
        return [comparativeStudies count];
    }
    
    return 0;
}

- (id)tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex
{
    return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(NSButtonCell*)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    @try
    {
        if ([aTableView isEqual:albumTable])
        {
            NSFont *txtFont;
            PrettyCell *cell = (PrettyCell*) aCell;
            
            if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: [self fontSize: @"dbAlbumFont"]];
            else txtFont = [NSFont systemFontOfSize: [self fontSize: @"dbAlbumFont"]];
            
            [cell setFont:txtFont];
            
            NSArray* albumArray = self.albumArray;
            
            if (albumArray.count > rowIndex && [[[albumArray objectAtIndex:rowIndex] valueForKey:@"smartAlbum"] boolValue])
                if (![_database isLocal])
                    [cell setImage:[NSImage imageNamed:@"small_sharedSmartAlbum.tif"]];
                else [cell setImage:[NSImage imageNamed:@"small_smartAlbum.tif"]];
                else
                    if (![_database isLocal])
                        [cell setImage:[NSImage imageNamed:@"small_sharedAlbum.tif"]];
                    else [cell setImage:[NSImage imageNamed:@"small_album.tif"]];
            
            [cell setTitle:nil];
            if (rowIndex >= 0 && rowIndex < albumArray.count)
                [cell setTitle:[[albumArray objectAtIndex:rowIndex] valueForKey:@"name"]];
            
            NSString *noOfStudies = nil;
            @synchronized (_albumNoOfStudiesCache)
            {
                if (_albumNoOfStudiesCache == nil ||
                    rowIndex >= [_albumNoOfStudiesCache count] ||
                    [[_albumNoOfStudiesCache objectAtIndex: rowIndex] isEqualToString:@""])
                {
                    [self refreshAlbums];
                    // It will be computed in a separate thread, and then displayed later.
                    noOfStudies = @"#";
                }
                else
                    noOfStudies = [[[_albumNoOfStudiesCache objectAtIndex: rowIndex] copy] autorelease];
            }
            
            [cell setRightText:noOfStudies];
        }
        
        if ([aTableView isEqual: comparativeTable])
        {
            ComparativeCell *cell = (ComparativeCell*) aCell;
            
            if (rowIndex >= 0 && rowIndex < comparativeStudies.count && _database)
            {
                NSFont *txtFont;
                BOOL local = NO;
                
                id study = [comparativeStudies objectAtIndex: rowIndex];
                
                if( [study isKindOfClass: [DicomStudy class]])
                    local = YES;
                
                if( local) txtFont = [NSFont boldSystemFontOfSize: [self fontSize: @"dbComparativeFont"]];
                else txtFont = [NSFont fontWithName: DISTANTSTUDYFONT size: [self fontSize: @"dbComparativeFont"]];
                
                [cell setFont:txtFont];
                cell.title = @"DUMMY"; // avoid NIL values here
                
                cell.leftTextFirstLine = [study studyName];
                cell.rightTextFirstLine = [study modality];
                cell.leftTextSecondLine = [[NSUserDefaults dateFormatter] stringFromDate: [study date]];
                cell.rightTextSecondLine = N2LocalizedSingularPluralCount(abs([[study numberOfImages] intValue]), NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil));
            }
            else
            {
                cell.title = @"";
                cell.leftTextFirstLine = @"";
                cell.rightTextFirstLine = @"";
                cell.leftTextSecondLine = @"";
                cell.rightTextSecondLine =@"";
            }
        }
        
        
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
}

- (NSManagedObject*) findStudyUID: (NSString*) uid
{
    NSArray						*studyArray = nil;
    NSError						*error = nil;
    NSFetchRequest				*request = [[[NSFetchRequest alloc] init] autorelease];
    NSManagedObjectContext		*context = BrowserController.currentBrowser.database.managedObjectContext;
    NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(studyInstanceUID == %@)", uid];
    
    [request setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
    [request setPredicate: predicate];
    
    [context retain];
    [context lock];
    
    @try
    {
        studyArray = [context executeFetchRequest:request error:&error];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
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
    NSManagedObjectContext		*context = BrowserController.currentBrowser.database.managedObjectContext;
    NSPredicate					*predicate = [NSPredicate predicateWithFormat: @"(seriesDICOMUID == %@)", uid];
    
    [request setEntity: [[BrowserController.currentBrowser.database.managedObjectModel entitiesByName] objectForKey:@"Series"]];
    [request setPredicate: predicate];
    
    [context retain];
    [context lock];
    
    @try
    {
        seriesArray = [context executeFetchRequest:request error:&error];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
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
        [(RemoteDicomDatabase*)_database uploadFilesAtPaths:files imageObjects:nil generatedByOsiriX:NO];
    
    [pool release];
}

- (void) sendFilesToCurrentBonjourGeneratedByOsiriXDB: (NSArray*) files
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (![_database isLocal])
        [(RemoteDicomDatabase*)_database uploadFilesAtPaths:files imageObjects:nil generatedByOsiriX:YES];
    
    [pool release];
}

+ (NSArray<NSString *> *)DatabaseObjectXIDsPasteboardTypes {
    return @[O2PasteboardTypeDatabaseObjectXIDs,
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
             O2DatabaseXIDsDragType
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
             ];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if ([tableView isEqual:albumTable])
    {
        NSArray* albumArray = self.albumArray;
        
        if (row >= [albumArray count] || row  == 0) // can't add to database
            return NO;
        if ([[[albumArray objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue]) // // can't add to smart album -- this should not be happening: validateDrop avoids it...
            return NO;
        
        DicomAlbum* album = [albumArray objectAtIndex:row];
        
        NSPasteboard* pb = [info draggingPasteboard];
        NSArray* xids = [NSPropertyListSerialization propertyListFromData:[pb propertyListForType:[pb availableTypeFromArray:BrowserController.DatabaseObjectXIDsPasteboardTypes]] mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
        NSMutableArray* items = [NSMutableArray array];
        for (NSString* xid in xids)
            [items addObject:[_database objectWithID:[NSManagedObject UidForXid:xid]]];
        
        NSMutableArray* studies = [NSMutableArray array];
        for (NSManagedObject* object in items)
        {
            if ([object isKindOfClass:[DicomStudy class]])
                [studies addObject:object];
            if ([object isKindOfClass:[DicomSeries class]])
                [studies addObject:[(DicomSeries*)object study]];
            if ([object isKindOfClass:[DicomImage class]])
                [studies addObject:[[(DicomImage*)object series] study]];
        }
        
        if ([studies count])
        {
            [_database addStudies:studies toAlbum:album];
            [_database save];
            [self refreshAlbums];
            return YES;
        }
    }
    
    return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if( operation != NSTableViewDropOn)
        return NSDragOperationNone;
    
    if ([tableView isEqual:albumTable])
    {
        NSArray* array = self.albumArray;
        
        if ((row >= [array count]) || [[[array objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue] || row == 0) return NSDragOperationNone;
        
        [albumTable setDropRow:row dropOperation:NSTableViewDropOn];
        
        return NSDragOperationLink;
    }
    
    return NSDragOperationNone;
}

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if( tv == comparativeTable)
    {
        if( [[comparativeStudies objectAtIndex: row] isDistant])
            return NSLocalizedString( @"Double-Click to retrieve", nil);
    }
    
    return nil;
}

-(NSString*)databaseAlbumSortDescriptorsPlistPath {
    return [_database.dataBaseDirPath stringByAppendingPathComponent:@"AlbumSortDescriptors.plist"];
}

-(void)saveSortDescriptors:(DicomAlbum*)album {
    // save the sortDescriptor
    if (_database && album) {
        NSArray* albums = self.albumArray;
        
        NSArray* albumSortDescriptors = [databaseOutline sortDescriptors];
        
        NSMutableDictionary* plist = [NSMutableDictionary dictionaryWithContentsOfFile:self.databaseAlbumSortDescriptorsPlistPath];
        if (!plist) plist = [NSMutableDictionary dictionary];
        
        NSArray* livingAlbumsXIDs = [albums valueForKeyPath:@"XID"];
        for (NSString* key in plist.allKeys)
            if (![key isEqualToString:@"Database"] && ![livingAlbumsXIDs containsObject:key])
                [plist removeObjectForKey:key];
        
        NSString* key = nil;
        if ([album isKindOfClass:[DicomAlbum class]])
            key = album.XID;
        else key = @"Database";
        
        NSMutableArray* cols = [NSMutableArray array];
        for (NSTableColumn* column in [databaseOutline tableColumns])
            if (![column isHidden]) {
                NSArray* col = [NSArray arrayWithObjects: column.identifier, [NSNumber numberWithInteger:column.width], nil];
                [cols addObject:col];
            }
        
        [plist setObject:[NSArray arrayWithObjects: [NSKeyedArchiver archivedDataWithRootObject:albumSortDescriptors], cols, nil] forKey:key];
        
        [plist writeToFile:self.databaseAlbumSortDescriptorsPlistPath atomically:YES];
    }
}

-(void)loadSortDescriptors:(DicomAlbum*)album
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSCommandKeyMask)
        return;
    
    if (_database && album)
    {
        // load the sortDescriptor
        
        NSString* key = nil;
        if ([album isKindOfClass:[DicomAlbum class]])
            key = album.XID;
        else key = @"Database";
        
        NSDictionary* plist = [NSDictionary dictionaryWithContentsOfFile:self.databaseAlbumSortDescriptorsPlistPath];
        
        NSArray* a = [plist objectForKey:key];
        if (a) {
            [databaseOutline setSortDescriptors:[NSKeyedUnarchiver unarchiveObjectWithData:[a objectAtIndex:0]]];
            NSArray* cols = [a objectAtIndex:1];
            
            NSArray* tableColumns = [databaseOutline tableColumns];
            NSMutableArray* unvisitedColumns = [[tableColumns mutableCopy] autorelease];
            NSInteger index = 0;
            for (NSArray* col in cols) {
                NSTableColumn* column = nil;
                for (NSTableColumn* icolumn in tableColumns)
                    if ([icolumn.identifier isEqualToString:[col objectAtIndex:0]]) {
                        column = icolumn;
                        break;
                    }
                if (column) {
                    [unvisitedColumns removeObject:column];
                    if ([databaseOutline columnWithIdentifier:column.identifier] == -1)
                        [databaseOutline addTableColumn:column];
                    [column setHidden:NO];
                    [column setWidth:[[col objectAtIndex:1] integerValue]];
                    [databaseOutline moveColumn:[databaseOutline columnWithIdentifier:column.identifier] toColumn:index++];
                } else {
                    DLog(@"Warning: invalid column identifier %@", col);
                }
            }
            for (NSTableColumn* column in unvisitedColumns)
                [column setHidden:YES];
        }
    }
}

-(DicomAlbum*)_albumWithID:(id)theId {
    if ([theId isKindOfClass:[NSManagedObjectID class]])
        return [_database objectWithID:theId];
    if (theId)
        return (id)[NSDictionary dictionary];
    return nil;
}

-(void)saveLoadAlbumsSortDescriptors
{
    if (!databaseOutline)
        return;
    
    static id previousSelectedAlbumId = nil;
    static void* previousDatabase = nil;
    if (_database != previousDatabase)
    {
        [previousSelectedAlbumId release];
        previousSelectedAlbumId = nil;
    }
    previousDatabase = _database;
    
    NSArray* albums = self.albumArray;
    if (albums.count == 0)
        return;
    
    if (previousSelectedAlbumId)
        [self saveSortDescriptors:[self _albumWithID:previousSelectedAlbumId]];
    
    DicomAlbum* selectedAlbum = nil;
    
    NSInteger selection = albumTable.selectedRow;
    if( selection >= 0)
    {
        selectedAlbum = [albums objectAtIndex:selection];
        if ([selectedAlbum isEqual:previousSelectedAlbumId])
            return;
    }
    
    [previousSelectedAlbumId release];
    if (!_database)
        previousSelectedAlbumId = nil;
    else previousSelectedAlbumId = [selectedAlbum isKindOfClass:[DicomAlbum class]]? [selectedAlbum.objectID retain] : [[NSDictionary dictionary] retain];
    
    if (previousSelectedAlbumId)
        [self loadSortDescriptors:[self _albumWithID:previousSelectedAlbumId]];
}

- (void) comparativeRetrieve:(DCMTKStudyQueryNode*) study
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    if( comparativeRetrieveQueue == nil)
        comparativeRetrieveQueue = [[NSMutableArray alloc] init];
    
#define MAX_CONCURRENT_comparativeRetrieve 5
    static dispatch_semaphore_t sid = 0;
    if (!sid)
        sid = dispatch_semaphore_create(MAX_CONCURRENT_comparativeRetrieve);
    
    dispatch_semaphore_wait(sid, DISPATCH_TIME_FOREVER);
    
    if( [[NSThread currentThread] isCancelled] == NO)
    {
        @synchronized( comparativeRetrieveQueue)
        {
            [comparativeRetrieveQueue addObject: study];
        }
        
        int copy = [[NSUserDefaults standardUserDefaults] integerForKey: @"ListenerCompressionSettings"];
        [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"ListenerCompressionSettings"]; //No time for decompression....
        
#ifndef OSIRIX_LIGHT
        [QueryController retrieveStudies: [NSArray arrayWithObject: study] showErrors: NO checkForPreviousAutoRetrieve: NO];
#endif
        
        DicomDatabase *idb = [[DicomDatabase activeLocalDatabase] independentDatabase];
        
        [idb importFilesFromIncomingDir];
        
        //Files in the decompress/compress thread?
        if( [idb waitForCompressThread])
            [idb importFilesFromIncomingDir];
        
        [[NSUserDefaults standardUserDefaults] setInteger: copy forKey: @"ListenerCompressionSettings"];
        
        @synchronized( comparativeRetrieveQueue)
        {
            [comparativeRetrieveQueue removeObject: study];
        }
    }
    dispatch_semaphore_signal(sid);
    
    [pool release];
}

- (void) retrieveComparativeStudy: (DCMTKStudyQueryNode*) study select: (BOOL) select open: (BOOL) open
{
    [self retrieveComparativeStudy: study select: select open: open showGUI: YES];
}

- (void) retrieveComparativeStudy: (DCMTKStudyQueryNode*) study select: (BOOL) select open: (BOOL) open showGUI: (BOOL) showGUI
{
    [self retrieveComparativeStudy: study select: select open: open showGUI: showGUI viewer: nil];
}

- (void) retrieveComparativeStudy: (DCMTKStudyQueryNode*) study select: (BOOL) select open: (BOOL) open showGUI: (BOOL) showGUI viewer: (ViewerController*) viewer
{
    BOOL retrieveStudy = YES;
    
    @synchronized( comparativeRetrieveQueue)
    {
        if( [comparativeRetrieveQueue containsObject: study])
            retrieveStudy = NO;
    }
    
    if( retrieveStudy)
    {
        WaitRendering *w = nil;
        
        if( showGUI)
            w = [[[WaitRendering alloc] init: NSLocalizedString(@"Retrieving...", nil)] autorelease];
        [w showWindow: self];
        
        NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(comparativeRetrieve:) object: study] autorelease];
        t.name = NSLocalizedString( @"Retrieving images...", nil);
        t.status = N2LocalizedSingularPluralCount( 1, NSLocalizedString(@"study", nil), NSLocalizedString(@"studies", nil));
        t.supportsCancel = YES;
        [[ThreadsManager defaultManager] addThreadAndStart: t];
        
        if( showGUI)
            [NSThread sleepForTimeInterval: 0.5];
        [w close];
    }
    
    // see refreshComparativeStudiesIfNeeded timer
    if( open || select)
    {
        comparativeStudyWaitedToOpen = open;
        comparativeStudyWaitedToSelect = select;
        [comparativeStudyWaited release];
        comparativeStudyWaited = [study retain];
        comparativeStudyWaitedTime = [NSDate timeIntervalSinceReferenceDate];
        
        [comparativeStudyWaitedViewer release];
        comparativeStudyWaitedViewer = [viewer retain];
    }
}

- (void) doubleClickComparativeStudy: (id) sender
{
    [self checkIfLocalStudyHasMoreOrSameNumberOfImagesOfADistantStudy: nil];
    
    id study = [comparativeStudies objectAtIndex: comparativeTable.selectedRow];
    
    if( study)
    {
        if( [study isDistant])
        {
            // Check to see if already in retrieving mode, if not download it
            [self retrieveComparativeStudy: study select: YES open: NO];
        }
        else
        {
            [self selectThisStudy: study];
            [[self window] makeFirstResponder: databaseOutline];
            [self databaseOpenStudy: study];
        }
    }
}

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
    @try
    {
        if (aNotification.object == albumTable)
        {
            NSArray	*albumArray = self.albumArray;
            
            self.selectedAlbumName = nil;
            
            if( [albumArray count] > albumTable.selectedRow)
                self.selectedAlbumName = [[albumArray objectAtIndex: albumTable.selectedRow] valueForKey: @"name"];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"clearSearchAndTimeIntervalWhenSelectingAlbum"])
            {
                // Clear search field
                [self setSearchString: nil];
                
                // Clear the time interval
                if( [[[CustomIntervalPanel sharedCustomIntervalPanel] window] isVisible] == NO)
                    [self setTimeIntervalType: 0];
                
                [self setModalityFilter: nil];
            }
            else
                [self setSearchString: self.searchString];
            
            [self refreshAlbums];
            
            // Distant Smart Albums
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"searchForSmartAlbumStudiesOnDICOMNodes"] && albumTable.selectedRow > 0)
            {
                if( [albumArray count] > albumTable.selectedRow)
                {
                    DicomAlbum *album = [albumArray objectAtIndex: albumTable.selectedRow];
                    
                    if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
                    {
                        [NSThread detachNewThreadSelector: @selector(searchForSmartAlbumDistantStudies:) toTarget:self withObject: album.name];
                    }
                }
            }
            
            // outlineview sortdescriptors
            
            [self saveLoadAlbumsSortDescriptors];
        }
        
        if (aNotification.object == comparativeTable)
        {
            if( comparativeTable.selectedRow >= 0 && comparativeTable.selectedRow < comparativeStudies.count)
            {
                id study = [comparativeStudies objectAtIndex: comparativeTable.selectedRow];
                
                if( study && dontSelectStudyFromComparativeStudies == NO)
                {
                    //                    #ifndef OSIRIX_LIGHT
                    //                    if( [study isDistant]) // distant study -> download it, and select it
                    //                    {
                    //                        [self retrieveComparativeStudy: study select: YES open: NO]; -- Only when double-clicking
                    //                    }
                    //                    else // local study -> select it
                    //                    #endif
                    {
                        if( [self selectThisStudy: study] && [[self window] firstResponder] != searchField && [[self window] firstResponder] != searchField.currentEditor)
                            [[self window] makeFirstResponder: databaseOutline];
                    }
                }
            }
        }
    }
    @catch (NSException *e)
    {
        NSLog( @"tableViewSelectionDidChange exception: %@", e);
        [AppController printStackTrace: e];
    }
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Open 2D/4D Viewer functions

- (BOOL)computeEnoughMemory: (NSArray*)toOpenArray :(unsigned long*)requiredMem
{
    NSThread* thread = [NSThread currentThread];
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
                [thread enterOperation];
                thread.status = NSLocalizedString(@"Evaluating amount of memory needed...", nil);
                
                NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
                for (NSUInteger i = 0; i < loadList.count; ++i)
                {
                    if( [NSDate timeIntervalSinceReferenceDate] - start > 0.5 || i == loadList.count-1) {
                        thread.progress = 1.0*i/loadList.count;
                        start = [NSDate timeIntervalSinceReferenceDate];
                    }
                    
                    curFile = [loadList objectAtIndex:i];
                    mem += ([[curFile valueForKey:@"width"] intValue] +1) * ([[curFile valueForKey:@"height"] intValue] +1);
                    memBlock += ([[curFile valueForKey:@"width"] intValue]) * ([[curFile valueForKey:@"height"] intValue]);
                }
                [thread exitOperation];
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
    DicomStudy          *previousStudy = viewer.currentStudy;
    
    ThreadModalForWindowController* wait = nil;
    [[NSThread currentThread] enterOperation];
    if ([self.database hasPotentiallySlowDataAccess]) {
        NSThread.currentThread.name = NSLocalizedString(@"Loading series data...", nil);
        NSThread.currentThread.status = NSLocalizedString(@"Evaluating amount of memory needed...", nil);
        wait = [[ThreadModalForWindowController alloc] initWithThread:[NSThread currentThread] window:nil];
    }
    
    @try
    {
        //  (1) keyImages
        if( keyImages)
        {
            NSMutableArray *keyImagesToOpenArray = [NSMutableArray array];
            
            @try
            {
                for( NSArray *loadList in toOpenArray)
                {
                    NSMutableArray *keyImagesArray = [NSMutableArray array];
                    
                    for( NSManagedObject *image in loadList)
                    {
                        if( [image isKindOfClass: [DicomImage class]])
                            if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
                                [keyImagesArray addObject: image];
                    }
                    
                    if( [keyImagesArray count] > 0)
                        [keyImagesToOpenArray addObject: keyImagesArray];
                }
            }
            @catch (NSException *e)
            {
                N2LogException( e);
            }
            
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
                if (!toOpenArray) return nil;
            }
        }
        
        for( NSArray * r in toOpenArray)
        {
            if( r.count)
            {
                if( [r.lastObject isKindOfClass: [DicomImage class]] == NO)
                {
                    NSRunInformationalAlertPanel( NSLocalizedString( @"Loading", nil), NSLocalizedString(@"Failed to load the series.", nil), NSLocalizedString(@"All Images",nil), NSLocalizedString(@"OK",nil), nil);
                    return nil;
                }
            }
        }
        
        //  (2) Compute Required Memory
        
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
                            @synchronized( previewPixThumbnails)
                            {
                                for( DCMPix *p in previewPix)
                                {
                                    [p kill8bitsImage];
                                    [p revert: NO];
                                }
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
            
            result = NSRunInformationalAlertPanel( NSLocalizedString(@"32-bit", nil), NSLocalizedString(@"This 32-bit version cannot load this series, but I can load a subset of the series: 1 on %d images.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil, subSampling);
        }
        
        //  (3) Load Images (memory allocation)
        
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
                    if( NSRunCriticalAlertPanel( NSLocalizedString(@"32-bit", nil),  NSLocalizedString(@"Cannot load this series.\r\rUpgrade to OsiriX 64-bit or OsiriX MD to solve this issue.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"OsiriX 64-bit", nil), nil) == NSAlertAlternateReturn)
                        [[AppController sharedAppController] osirix64bit: self];
                }
                
                free( memBlockTestPtr);
                fVolumePtr = nil;
            }
        }
        else notEnoughMemory = YES;
        
        //  (4) Load Images loop
        
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
                            a = [[a reverseObjectEnumerator] allObjects];
                            
                            preFlippedData = YES;
                            flipped = YES;
                        }
                        
                        [p1 release];
                        [p2 release];
                    }
                    @catch (NSException * e)
                    {
                        N2LogExceptionWithStackTrace(e/*, @"pre-flip data"*/);
                    }
                }
                
                [resortedToOpenArray addObject: a];
                [isFlippedData addObject: [NSNumber numberWithBool: flipped]];
            }
            
            if( preFlippedData)
                toOpenArray = resortedToOpenArray;
            
            //            NSMutableArray *viewerToStartLoadingThread = [NSMutableArray array];
            
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
                            NSRunCriticalAlertPanel( NSLocalizedString(@"Not all files available (readable)", nil), NSLocalizedString(@"Not all files are available (readable) in this series.\r%@ are missing.", nil), NSLocalizedString(@"Continue",nil), nil, nil, N2LocalizedSingularPluralCount( [loadList count] - [viewerPix[0] count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil)));
                    }
                    //opening images refered to in viewerPix[0] in the adequate viewer
                    
                    [DCMView setDontListenToSyncMessage: YES];
                    
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
                                    //[viewerToStartLoadingThread addObject: createdViewer];
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
                                    //[viewerToStartLoadingThread addObject: createdViewer];
                                    
                                    if( [[isFlippedData objectAtIndex: x] boolValue])
                                        [createdViewer flipDataSeries: self];
                                }
                            }
                        }
                        else
                        {
                            //movieViewer==YES
                            if( movieController == nil)
                            {
                                if( viewer)
                                {
                                    [viewer changeImageData:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData :NO];
                                    
                                    movieController = viewer;
                                }
                                else
                                {
                                    movieController = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles:[NSMutableArray arrayWithArray:correspondingObjects] withVolume:volumeData];
                                }
                            }
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
                    
                    [DCMView setDontListenToSyncMessage: NO];
                    
                    [viewerPix[0] release];
                    [correspondingObjects release];
                }
            } //end for
            
            //            [self performSelector: @selector( startLoadingThreads:) withObject: viewerToStartLoadingThread afterDelay: 0.01];
        }
        
        //  (5) movieController activation
        
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
        N2LogExceptionWithStackTrace(e);
        NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), NSLocalizedString(@"Opening Error : %@\r\r%@", nil), nil, nil, nil, e, [AppController printStackTrace: e]);
    }
    @finally {
        [wait invalidate];
        [wait autorelease];
        [[NSThread currentThread] exitOperation];
    }
    
    free( memBlockSize);
    
    if( movieController) createdViewer = movieController;
    
    [self.database save]; //To save 'dateOpened' field, and allow independentContext to see it
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
    {
        if( viewer && [[NSUserDefaults standardUserDefaults] boolForKey: @"tileWindowsOrderByStudyDate"])
        {
            if( [previousStudy.studyInstanceUID isEqualToString: viewer.currentStudy.studyInstanceUID] == NO)
            {
                // Keep current row/column
                NSDictionary *d = nil;
                
                NSString *rw = [[NSUserDefaults standardUserDefaults] stringForKey: @"LastWindowsTilingRowsColumns"];
                if( rw)
                {
                    if( rw.length == 2)
                    {
                        d = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [[rw substringWithRange: NSMakeRange( 0, 1)] intValue]], @"rows", [NSNumber numberWithInt: [[rw substringWithRange: NSMakeRange( 1, 1)] intValue]], @"columns", nil];
                    }
                }
                
                [[AppController sharedAppController] tileWindows: d];
            }
        }
    }
    
    return createdViewer;
}

//- (void) startLoadingThreads: (NSArray*) viewerToStartLoadingThread
//{
//    for( ViewerController *v in viewerToStartLoadingThread)
//        [v startLoadImageThread];
//}

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
        [self displayWaitWindowIfNecessary];
    
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
        else if( [toOpenArray count] > MAX4D)
        {
            NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"4D Player is limited to a maximum number of %d series.", nil), NSLocalizedString(@"OK",nil), nil, nil, MAX4D);
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
            if( ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) || openReparsedSeriesFlag)
            {
                NSArray			*singleSeries = [[toOpenArray objectAtIndex: 0] sortedArrayUsingDescriptors: [NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey: @"instanceNumber" ascending: YES], [NSSortDescriptor sortDescriptorWithKey: @"frameID" ascending: YES], nil]];
                NSMutableArray	*splittedSeries = [NSMutableArray array];
                NSMutableArray  *intervalArray = [NSMutableArray array];
                
                float interval, previousinterval = 0;
                
                [splittedSeries addObject: [NSMutableArray array]];
                
                if( [singleSeries count] > 1)
                {
                    [[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
                    
                    //					if( [[[singleSeries lastObject] valueForKey: @"numberOfFrames"] intValue] > 1)
                    //					{
                    //						for( id o in singleSeries)	//We need to extract the *true* sliceLocation
                    //						{
                    //							DCMPix *p = [[DCMPix alloc] initWithPath:[o valueForKey:@"completePath"] :0 :1 :nil :[[o valueForKey:@"frameID"] intValue] :[[o valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: o];
                    //
                    //							[intervalArray addObject: [NSNumber numberWithFloat: [p sliceLocation]]];
                    //
                    //							[p release];
                    //						}
                    //					}
                    //					else
                    //					{
                    for( id o in singleSeries)
                        [intervalArray addObject: [NSNumber numberWithFloat: [[o valueForKey:@"sliceLocation"] floatValue]]];
                    //					}
                    
                    interval = [[intervalArray objectAtIndex: 0] floatValue] - [[intervalArray objectAtIndex: 1] floatValue];
                    
                    if( interval == 0)
                    { // 4D - 3D
                        int pos3Dindex = 1;
                        
                        for( int x = 1; x < [singleSeries count]; x++)
                        {
                            float interval4D = [[intervalArray objectAtIndex: x -1] floatValue] - [[intervalArray objectAtIndex: x] floatValue];
                            if( interval4D != 0) pos3Dindex = 0;
                            
                            if( [splittedSeries count] <= pos3Dindex) [splittedSeries addObject: [NSMutableArray array]];
                            
                            [[splittedSeries objectAtIndex: pos3Dindex] addObject: [singleSeries objectAtIndex: x]];
                            
                            pos3Dindex++;
                        }
                        
                        if( pos3Dindex == [singleSeries count]) // No 3D-4D.... Try something else...
                        {
                            [intervalArray removeAllObjects];
                            
                            // Let's try the comment field Cardiac Magnitude, Phase, Flow
                            for( id o in singleSeries)
                            {
                                [intervalArray addObject: [NSNumber numberWithFloat: [[o valueForKey:@"comment"] floatValue]]];
                                
                                if( [[o valueForKey:@"comment"] floatValue] != 0)
                                    interval = 1; // To enter in the: if( interval != 0)
                            }
                            
                            if( interval)
                            {
                                splittedSeries = [NSMutableArray array];
                                [splittedSeries addObject: [NSMutableArray array]];
                                [[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
                            }
                        }
                    }
                    
                    if( interval != 0)
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
                    [self closeWaitWindowIfNecessary];
                    
                    [subOpenMatrix3D renewRows: 1 columns: [splittedSeries count]];
                    [subOpenMatrix3D sizeToCells];
                    [subOpenMatrix3D setTarget:self];
                    [subOpenMatrix3D setAction: @selector(selectSubSeriesAndOpen:)];
                    
                    [subOpenMatrix4D renewRows: 1 columns: [[splittedSeries objectAtIndex: 0] count]];
                    [subOpenMatrix4D sizeToCells];
                    [subOpenMatrix4D setTarget:self];
                    [subOpenMatrix4D setAction: @selector(selectSubSeriesAndOpen:)];
                    
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
                            [cell setAlternateImage:img];
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
                                [cell setAlternateImage:img];
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
                       modalForWindow: [NSApp mainWindow]
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
                        
                        [_database lock];
                        
                        @try
                        {
                            int reparseIndex = 1;
                            
                            DicomSeries *originalSeries = [[[splittedSeries lastObject] lastObject] valueForKey: @"Series"];
                            
                            for( NSArray *array in splittedSeries)
                            {
                                DicomSeries *newSeries = [NSEntityDescription insertNewObjectForEntityForName: @"Series" inManagedObjectContext:_database.managedObjectContext];
                                
                                for ( NSString *name in [[[NSEntityDescription entityForName: @"Series" inManagedObjectContext:_database.managedObjectContext] attributesByName] allKeys]) // Duplicate values
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
                                    DicomImage *newImage = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext:_database.managedObjectContext];
                                    
                                    for ( NSString *name in [[[NSEntityDescription entityForName: @"Image" inManagedObjectContext:_database.managedObjectContext] attributesByName] allKeys]) // Duplicate values
                                    {
                                        [newImage setValue: [image valueForKey: name] forKey: name];
                                    }
                                    
                                    [image setValue: newSeries forKey: @"series"];
                                }
                                
                                [newSeries setValue: [NSNumber numberWithInt: 0] forKey: @"numberOfImages"];
                                [newSeries setValue: nil forKey:@"thumbnail"];
                            }
                            
                            [_database.managedObjectContext deleteObject:originalSeries];
                            
                            [_database save: nil];
                        }
                        @catch (NSException * e)
                        {
                            N2LogExceptionWithStackTrace(e/*, @"reparsing"*/);
                        }
                        @finally {
                            [_database unlock];
                        }
                        
                        [self refreshDatabase: self];
                        [self refreshMatrix: self];
                        
                        result = 0;
                    }
                    else if( result == 11)
                    {
                        NSLog( @"Reparse in 4D");
                        
                        // Create the new series
                        
                        [_database lock];
                        
                        @try
                        {
                            int reparseIndex = 1;
                            
                            DicomSeries *originalSeries = [[[splittedSeries lastObject] lastObject] valueForKey: @"Series"];
                            
                            for( int i = 0; i < [[splittedSeries objectAtIndex: 0] count]; i++)
                            {
                                NSMutableArray	*array4D = [NSMutableArray array];
                                
                                for ( NSArray *array in splittedSeries)
                                    [array4D addObject: [array objectAtIndex: i]];
                                
                                DicomSeries *newSeries = [NSEntityDescription insertNewObjectForEntityForName: @"Series" inManagedObjectContext:_database.managedObjectContext];
                                
                                for ( NSString *name in [[[NSEntityDescription entityForName: @"Series" inManagedObjectContext:_database.managedObjectContext] attributesByName] allKeys]) // Duplicate values
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
                                    DicomImage *newImage = [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext:_database.managedObjectContext];
                                    
                                    for ( NSString *name in [[[NSEntityDescription entityForName: @"Image" inManagedObjectContext:_database.managedObjectContext] attributesByName] allKeys]) // Duplicate values
                                    {
                                        [newImage setValue: [image valueForKey: name] forKey: name];
                                    }
                                    
                                    [image setValue: newSeries forKey: @"series"];
                                }
                                
                                [newSeries setValue: [NSNumber numberWithInt: 0] forKey: @"numberOfImages"];
                                [newSeries setValue: nil forKey:@"thumbnail"];
                            }
                            
                            [_database.managedObjectContext deleteObject: originalSeries];
                            
                            [_database save:nil];
                        }
                        @catch (NSException * e)
                        {
                            N2LogExceptionWithStackTrace(e/*, @"reparsing"*/);
                        }
                        @finally {
                            [_database unlock];
                        }
                        
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
                            
                            [self displayWaitWindowIfNecessary];
                            
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
                                
                                if( NSRunInformationalAlertPanel( NSLocalizedString(@"Series Opening", nil), NSLocalizedString(@"Are you sure you want to open %d windows? It's a lot of windows for this screen...", nil), NSLocalizedString(@"Yes", nil), NSLocalizedString(@"Cancel", nil), nil, [[splittedSeries objectAtIndex: 0] count]) == NSAlertDefaultReturn)
                                    openAllWindows = YES;
                            }
                            
                            if( openAllWindows)
                            {
                                [self displayWaitWindowIfNecessary];
                                
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
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer
{
    return [self viewerDICOMInt:  movieViewer dcmFile: selectedLines viewer: viewer tileWindows: YES protocol: nil];
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer tileWindows: (BOOL) tileWindows
{
    return [self viewerDICOMInt:  movieViewer dcmFile: selectedLines viewer: viewer tileWindows: tileWindows protocol: nil];
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer tileWindows: (BOOL) tileWindows protocol: (NSDictionary*) protocol
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
        
        if( [[selectedLine valueForKey:@"type"] isEqualToString: @"Series"])
            [[AppController sharedAppController] addStudyToRecentStudiesMenu: [[selectedLine valueForKey: @"study"] objectID]];
        else
            [[AppController sharedAppController] addStudyToRecentStudiesMenu: selectedLine.objectID];
        
        //////////////////////////////////////
        // Open selected images only !!!
        //////////////////////////////////////
        
        if( [cells count] > 1 && [[selectedLine valueForKey:@"type"] isEqualToString: @"Series"])
        {
            NSArray  *curList = [self childrenArray: selectedLine];
            
            selectedFilesList = [[NSMutableArray alloc] initWithCapacity:0];
            
            for( NSCell* c in cells)
            {
                if( [c tag] < curList.count)
                {
                    NSManagedObject*  curImage = [curList objectAtIndex: [c tag]];
                    [selectedFilesList addObject: curImage];
                }
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
                    
                    if( matrixViewArray.count > [cell tag])
                    {
                        NSManagedObject*  curFile = [matrixViewArray objectAtIndex: [cell tag]];
                        
                        if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"])
                            loadList = [self childrenArray: selectedLine onlyImages: YES];
                        
                        if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"])
                            loadList = [self childrenArray: curFile onlyImages: YES];
                        
                        if( loadList) [toOpenArray addObject: loadList];
                    }
                }
            }
            
            [self processOpenViewerDICOMFromArray: toOpenArray movie: movieViewer viewer: viewer];
        }
        
        if( tileWindows)
        {
            NSArray *viewers = [ViewerController getDisplayed2DViewers];
            
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
            {
                [[AppController sharedAppController] tileWindows: protocol];
                
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
        N2LogExceptionWithStackTrace(e);
        NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), NSLocalizedString(@"Opening Error : %@\r\r%@", nil) , nil, nil, nil, e, [AppController printStackTrace: e]);
    }
    
    [_database unlock];
}

- (void) viewerSubSeriesDICOM: (id)sender
{
    openSubSeriesFlag = YES;
    [self viewerDICOM: sender];
    openSubSeriesFlag = NO;
}

- (void) viewerReparsedSeries: (id) sender
{
    openReparsedSeriesFlag = YES;
    [self viewerDICOM: sender];
    openReparsedSeriesFlag = NO;
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
    [_database lock];
    
    NSManagedObject	*item = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
    
    @try
    {
        if (sender == Nil &&
            [[oMatrix selectedCells] count] == 1 &&
            [[item valueForKey:@"type"] isEqualToString:@"Study"])
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
        N2LogExceptionWithStackTrace(e);
    }
    
    [_database unlock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OsirixDidLoadNewObjectNotification object:item userInfo:nil];
    
    [self closeWaitWindowIfNecessary];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void)viewerDICOMMergeSelection: (id)sender
{
    NSMutableArray	*images = [NSMutableArray array];
    
    
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        [self filesForDatabaseMatrixSelection: selectedItems];
    else
        [self filesForDatabaseOutlineSelection: selectedItems];
    
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
        
        [imagesArray sortUsingDescriptors: [[[imagesArray lastObject] series] sortDescriptorsForImages]];
        
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
        [leftIcon setImage: [NSImage imageNamed: @"smile"]];
        [rightIcon setImage: [NSImage imageNamed: @"smile"]];
        
        [subSeriesOKButton setEnabled: YES];
        
        [memoryMessage setStringValue: NSLocalizedString( @"OK !", nil)];
    }
    else
    {
        static BOOL firstTimeNotEnoughMemory = YES;
        
        if( firstTimeNotEnoughMemory)
        {
            firstTimeNotEnoughMemory = NO;
            [[AppController sharedAppController] osirix64bit: nil];
        }
        
        [leftIcon setImage: [NSImage imageNamed: @"error"]];
        [rightIcon setImage: [NSImage imageNamed: @"error"]];
        
        [subSeriesOKButton setEnabled: NO];
        
        [memoryMessage setStringValue: NSLocalizedString( @"Cannot load !", nil)];
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
    
    if (!subSeriesWindowIsOn)
    {
        subSeriesWindowIsOn = YES;
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
        
        subSeriesWindowIsOn = NO;
        
        NSArray *returnedArray = nil;
        
        if( result == NSRunStoppedResponse)
            returnedArray = [self produceNewArray: toOpenArray];
        
        [openSubSeriesArray release];
        
        [[NSUserDefaults standardUserDefaults] setInteger: copySortSeriesBySliceLocation forKey: @"sortSeriesBySliceLocation"];
        
        return returnedArray;
    }
    
    return nil;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark GUI functions

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

+ (long) computeDATABASEINDEXforDatabase:(NSString*)path // __deprecated
{
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
            NSRunCriticalAlertPanel(NSLocalizedString(@"Protected Mode", nil), NSLocalizedString(@"Horos is now running in Protected Mode (shift + option keys at startup): no images are displayed, allowing you to delete crashing or corrupted images/studies.", nil), NSLocalizedString(@"OK", nil), nil, nil);
        }
        
        _distantAlbumNoOfStudiesCache = [[NSMutableDictionary alloc] init];
        _albumNoOfStudiesCache = [[NSMutableArray alloc] init];
        databaseIndexDictionary = [[NSMutableDictionary alloc] initWithCapacity: 0];
        
        notFoundImage = [[NSImage imageNamed:@"FileNotFound.tif"] retain];
        
        reportFilesToCheck = [[NSMutableDictionary dictionary] retain];
        
        pressedKeys = [[NSMutableString stringWithString:@""] retain];
        
        processorsLock = [[NSConditionLock alloc] initWithCondition: 1];
        
        DatabaseIsEdited = NO;
        
        previousBonjourIndex = -1;
        toolbarSearchItem = nil;
        
        _filterPredicateDescription = nil;
        _filterPredicate = nil;
        _fetchPredicate = nil;
        
        matrixViewArray = nil;
        
        previousNoOfFiles = 0;
        previousItem = nil;
        
        searchType = 7;
        self.timeIntervalType = 0;
        
        outlineViewArray = [[NSArray array] retain];
        browserWindow = self;
        
        [[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
        [[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
        
        NSThread* thread = [NSThread currentThread];
        NSString* oldThreadName = thread.name;
        DicomDatabase* theDatabase = nil;
        [thread enterOperation];
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        @try
        {
            //thread.name = NSLocalizedString(@"Opening database...", nil);
            //ThreadModalForWindowController* tmfwc = [[ThreadModalForWindowController alloc] initWithThread:thread window:nil]; // sorry but this window is really ugly at startup...
            
            theDatabase = [[DicomDatabase activeLocalDatabase] retain]; // explicitly released later
            
            //[tmfwc invalidate];
            //[tmfwc release];
        }
        @catch (NSException* e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        @finally
        {
            [thread exitOperation];
            [pool release];
        }
        
        thread.name = oldThreadName;
        self.database = [theDatabase autorelease]; // explicitly retained earlier
        
        previewPix = [[NSMutableArray alloc] init];
        previewPixThumbnails = [[NSMutableArray alloc] init];
        
        [NSTimer scheduledTimerWithTimeInterval: 0.15 target:self selector:@selector(previewPerformAnimation:) userInfo:self repeats:YES];
        
        if( [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] < 1)
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"LISTENERCHECKINTERVAL"];
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"hideListenerError"] == NO)
            refreshTimer = [[NSTimer scheduledTimerWithTimeInterval: 5*60 target:self selector:@selector(refreshDatabase:) userInfo:self repeats:YES] retain];
        
        [NSTimer scheduledTimerWithTimeInterval: 10 target:self selector:@selector(emptyDeleteQueue:) userInfo:self repeats:YES]; // 10
        [NSTimer scheduledTimerWithTimeInterval: 1 target:self selector:@selector(refreshComparativeStudiesIfNeeded:) userInfo:self repeats:YES];
        
        loadPreviewIndex = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:OsirixReportModeChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alternateButtonPressed:) name:OsirixAlternateButtonPressedNotification object:nil];
    }
    return self;
}
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
    
    [[[databaseOutline tableColumnWithIdentifier: @"dateOpened"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
    [[[databaseOutline tableColumnWithIdentifier: @"date"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
    [[[databaseOutline tableColumnWithIdentifier: @"dateAdded"] dataCell] setFormatter:[NSUserDefaults dateTimeFormatter]];
    
    [[[databaseOutline tableColumnWithIdentifier: @"dateOfBirth"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
    [[[databaseOutline tableColumnWithIdentifier: @"reportURL"] dataCell] setFormatter:[NSUserDefaults dateFormatter]];
    [[[databaseOutline tableColumnWithIdentifier: @"noFiles"] dataCell] setFormatter: decimalNumberFormatter];
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

- (NSDateFormatter*)DateOfBirthFormat // __deprecated
{
    return  [NSUserDefaults dateFormatter];
}

+ (NSString*)DateOfBirthFormat:(NSDate*)d // __deprecated
{
    return  [[NSUserDefaults dateFormatter] stringFromDate:d];
}

- (NSDateFormatter*)DateTimeFormat // __deprecated
{
    return [NSUserDefaults dateTimeFormatter];
}

+ (NSString*)DateTimeFormat:(NSDate*)d // __deprecated
{
    return [[NSUserDefaults dateTimeFormatter] stringFromDate:d];
}

-(void)menuWillOpen:(NSMenu*)menu // DATABASE contextual menu and ALBUMS contextualMenu
{
    if (menu == columnsMenu) {
        [self columnsMenuWillOpen];
        return;
    }
    
    [menu removeAllItems];
    
    BOOL isWritable = ![self.database isReadOnly];
    
    if (menu == [albumTable menu])
    {
        if ([self.database isLocal])
        {
            int row = [albumTable clickedRow];
            NSMenuItem* item;
            
            if (![_database isReadOnly])
            {
                item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Edit Album", nil) action:@selector(albumTableDoublePressed:) keyEquivalent:@""] autorelease];
                [item setTarget:self];
                [menu addItem:item];
                
                [menu addItem: [NSMenuItem separatorItem]];
                
                item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Add Album", nil) action:@selector(addAlbum:) keyEquivalent:@""] autorelease];
                [item setTarget:self];
                [menu addItem:item];
                
                item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Add Smart Album", nil) action:@selector(addSmartAlbum:) keyEquivalent:@""] autorelease];
                [item setTarget:self];
                [menu addItem:item];
                
                [menu addItem: [NSMenuItem separatorItem]];
                
                if (row > 0) { // index 0 is database, cannot be removed. Negative index = click on empty table (not on a particular item)
                    item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Delete Album", nil) action:@selector(removeAlbum:) keyEquivalent:@""] autorelease];
                    [item setTarget:self];
                    [menu addItem:item];
                    
                    [menu addItem: [NSMenuItem separatorItem]];
                }
            }
            
            item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Save Albums", nil) action:@selector(saveAlbums:) keyEquivalent:@""] autorelease];
            [item setTarget: self]; // required because the drawner is the first responder
            [menu addItem:item];
            
            item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Import Albums", nil) action:@selector(addAlbums:) keyEquivalent:@""] autorelease];
            [item setTarget: self]; // required because the drawner is the first responder
            [menu addItem:item];
            
            [menu addItem: [NSMenuItem separatorItem]];
            
            item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Create Default Albums", nil) action:@selector(defaultAlbums:) keyEquivalent:@""] autorelease];
            [item setTarget: self]; // required because the drawner is the first responder
            [menu addItem:item];
        }
        
        return;
    }
    
    [menu addItemWithTitle: NSLocalizedString(@"Display only this patient", nil) action: @selector(searchForCurrentPatient:) keyEquivalent:@""];
    
    [menu addItem: [NSMenuItem separatorItem]];
    [menu addItemWithTitle: NSLocalizedString(@"Open Images", nil) action: @selector(viewerDICOM:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open Images in 4D", nil) action: @selector(MovieViewerDICOM:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open Sub-Selection", nil)  action:@selector(viewerSubSeriesDICOM:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open Reparsed Series", nil)  action:@selector(viewerReparsedSeries:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open Key Images", nil) action: @selector(viewerDICOMKeyImages:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open ROIs Images", nil) action: @selector(viewerDICOMROIsImages:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open ROIs and Key Images", nil) action: @selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Open Merged Selection", nil) action: @selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Reveal In Finder", nil) action: @selector(revealInFinder:) keyEquivalent:@""];
    if( [[AppController sharedAppController] workspaceMenu]) {
        [menu addItem: [NSMenuItem separatorItem]];
        NSMenuItem *mi = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"Load Workspace State DICOM SR", nil) action: nil keyEquivalent:@""] autorelease];
        [mi setSubmenu: [[[[AppController sharedAppController] workspaceMenu] copy] autorelease]];
        [menu addItem: mi];
        [menu addItemWithTitle: NSLocalizedString(@"Reset Workspace State", nil) action: @selector(resetWindowsState:) keyEquivalent:@""];
    }
    [menu addItem: [NSMenuItem separatorItem]];
    [menu addItemWithTitle: NSLocalizedString(@"Export to DICOM Network Node", nil) action: @selector(export2PACS:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export to Movie", nil) action: @selector(exportQuicktime:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export to JPEG", nil) action: @selector(exportJPEG:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export to TIFF", nil) action: @selector(exportTIFF:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export to DICOM File(s)", nil) action: @selector(exportDICOMFile:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export to Email", nil)  action:@selector(sendMail:) keyEquivalent:@""];
    [menu addItemWithTitle: NSLocalizedString(@"Export ROI and Key Images as a DICOM Series", nil) action:@selector(exportROIAndKeyImagesAsDICOMSeries:) keyEquivalent:@""];
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Add selected study(s) to user(s)", nil)  action:@selector(addStudiesToUser:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Send an email notification to user(s)", nil)  action:@selector(sendEmailNotification:) keyEquivalent:@""];
    }
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Compress DICOM files", nil)  action:@selector(compressSelectedFiles:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Decompress DICOM files", nil)  action:@selector(decompressSelectedFiles:) keyEquivalent:@""];
    }
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Lock Studies", nil)  action:@selector(lockStudies:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Unlock Studies", nil)  action:@selector(unlockStudies:) keyEquivalent:@""];
    }
    
    if (isWritable) { // TODO: allow report access, read-only
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Create/Open Report", nil) action: @selector(generateReport:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Convert Report to PDF...", nil) action: @selector(convertReportToPDF:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Convert Report to DICOM PDF", nil) action: @selector(convertReportToDICOMSR:) keyEquivalent:@""];
    }
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Merge Selected Studies", nil) action: @selector(mergeStudies:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Unify patient identity", nil) action: @selector(unifyStudies:) keyEquivalent:@""];
    }
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Delete", nil) action: @selector(delItem:) keyEquivalent:@""];
    }
    
    if (isWritable) {
        [menu addItem: [NSMenuItem separatorItem]];
        [menu addItemWithTitle: NSLocalizedString(@"Query Selected Patient from Q&R Window...", nil) action: @selector(querySelectedStudy:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Burn", nil) action: @selector(burnDICOM:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Anonymize", nil) action: @selector(anonymizeDICOM:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Rebuild Selected Thumbnails", nil)  action:@selector(rebuildThumbnails:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Regenerate Auto-Fill Comment field", nil)  action:@selector(regenerateAutoComments:) keyEquivalent:@""];
        [menu addItemWithTitle: NSLocalizedString(@"Copy Linked Files to Database Folder", nil)  action:@selector(copyToDBFolder:) keyEquivalent:@""];
    }
    
    NSArray *autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
    
    if(isWritable && [autoroutingRules count])
    {
        [menu addItem: [NSMenuItem separatorItem]];
        
        NSMenu *submenu = nil;
        
        if( [autoroutingRules count] > 0)
        {
            submenu = [[[NSMenu alloc] initWithTitle: NSLocalizedString(@"Apply this Routing Rule to Selection", nil)] autorelease];
            
            NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedString(@"All routing rules", nil)  action:@selector(applyRoutingRule:) keyEquivalent:@""] autorelease];
            [submenu addItem: item];
            [submenu addItem: [NSMenuItem separatorItem]];
            
            for( NSDictionary *routingRule in autoroutingRules)
            {
                NSString *s = [routingRule valueForKey: @"description"];
                
                if( [s length] > 0)
                    item = [[[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ - %@", [routingRule valueForKey: @"name"], s] action: @selector(applyRoutingRule:) keyEquivalent:@""] autorelease];
                else
                    item = [[[NSMenuItem alloc] initWithTitle: [routingRule valueForKey: @"name"] action: @selector(applyRoutingRule:) keyEquivalent:@""] autorelease];
                
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
}

-(void) awakeFromNib
{
    @try
    {
        //[self window].appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];;
        //[[self window] invalidateShadow];
        
        //	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //
        //	dispatch_apply(count, queue,
        //	^(size_t i)
        //	{
        //		printf("%u\n",i);
        //	});
        
        //    NSLog( @"%@", [[NSFontManager sharedFontManager] availableFonts]);
        
        NSRect r = NSMakeRect(0, 0, 0, 0);
        
        r = NSRectFromString( [[NSUserDefaults standardUserDefaults] stringForKey: @"DBWindowFrame"]);
        
        if( NSIsEmptyRect( r)) // No position for the window -> fullscreen
            [[self window] zoom: self];
        else
            [self.window setFrame: r display: YES];
        
        gHorizontalHistory = [[NSUserDefaults standardUserDefaults] boolForKey: @"horizontalHistory"];
        
        if( gHorizontalHistory)
        {
            NSSplitView * s = [[NSSplitView alloc] initWithFrame: splitViewVert.bounds];
            
            [s setDelegate: self];
            [s addSubview: comparativeScrollView];
            [s addSubview: matrixView];
            
            [splitViewVert addSubview: s];
            [splitViewVert addSubview: imageView];
            
            splitComparative = s;
        }
        
        [self setTableViewRowHeight];
        
        [self saveLoadAlbumsSortDescriptors];
        
        WaitRendering *wait = [[AppController sharedAppController] splashScreen];
        
        //	waitCompressionWindow  = [[Wait alloc] initWithString: NSLocalizedString( @"File Conversion", nil) :NO];
        //	[waitCompressionWindow setCancel:YES];
        
        
        [oMatrix setIntercellSpacing:NSMakeSize(-1, -1)];
        
        [wait showWindow:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionDidChangeNotification object:databaseOutline];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionIsChangingNotification object:databaseOutline];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:reportTemplatesListPopUpButton];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeScrollerStyleDidChangeNotification:) name:@"NSPreferredScrollerStyleDidChangeNotification" object:nil];
        [self observeScrollerStyleDidChangeNotification:nil];
        
        @try
        {
            //            [self.window safelySetUsesLightBottomGradient:YES];
            
            //  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewMatrixFrameDidChange:) name:NSViewFrameDidChangeNotification object:oMatrix];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewMatrixScrollViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:thumbnailsScrollView];
            [self previewMatrixScrollViewFrameDidChange:nil];
            
            NSTableColumn		*tableColumn = nil;
            NSPopUpButtonCell	*buttonCell = nil;
            
            // thumbnails : no background color
            [thumbnailsScrollView setDrawsBackground:NO];
            [[thumbnailsScrollView contentView] setDrawsBackground:NO];
            
            [self awakeSources];
            [oMatrix setDelegate:self];
            [oMatrix setSelectionByRect: NO];
            [oMatrix setDoubleAction:@selector(matrixDoublePressed:)];
            [oMatrix setFocusRingType: NSFocusRingTypeExterior];
            [oMatrix renewRows:0 columns: 0];
            //[oMatrix sizeToCells];
            
            [imageView setTheMatrix:oMatrix];
            
            // Bug for segmentedControls...
            //NSRect f = [segmentedAlbumButton frame];
            //f.size.height = 25;
            //[segmentedAlbumButton setFrame: f];
            
            [databaseOutline setAction:@selector(databasePressed:)];
            [databaseOutline setDoubleAction:@selector(databaseDoublePressed:)];
            [databaseOutline registerForDraggedTypes:@[NSFilenamesPboardType]];
            [databaseOutline setAllowsMultipleSelection:YES];
            [databaseOutline setAutosaveName: nil];
            [databaseOutline setAutosaveTableColumns: NO];
            [databaseOutline setAllowsTypeSelect: NO];
            
            [self setupToolbar];
            
            [toolbar setVisible:YES];
            //		[self showDatabase: self];
            
            // NSMenu for DatabaseOutline
            NSMenu* menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
            [menu setDelegate:self];
            [databaseOutline setMenu:menu];
            
            [self addHelpMenu];
            
            ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
            [cell setEditable:YES];
            [[albumTable tableColumnWithIdentifier:@"Source"] setDataCell:cell];
            [albumTable setDelegate:self];
            [albumTable registerForDraggedTypes:[BrowserController.DatabaseObjectXIDsPasteboardTypes arrayByAddingObjectsFromArray:@[
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                                                  O2AlbumDragType // we still support the original, non-UTI type, in case some plugin uses this (very unlikely)
#pragma clang diagnostic pop
                                                  ]]];

            //		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
            //		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
            //		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
            //		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
            
            statesArray = [[NSArray arrayWithObjects:NSLocalizedString(@"empty", nil), NSLocalizedString(@"unread", nil), NSLocalizedString(@"reviewed", nil), NSLocalizedString(@"dictated", nil), NSLocalizedString(@"validated", nil), nil] retain];
            
            
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
            
            [self loadSortDescriptors:nil];
            
            [databaseOutline selectRowIndexes: [NSIndexSet indexSetWithIndex: 0] byExtendingSelection:NO];
            [databaseOutline scrollRowToVisible: 0];
            [self buildColumnsMenu];
            
            self.modalityFilter = nil;
            
            [animationCheck setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"AutoPlayAnimation"]];
            
            activeSends = [[NSMutableDictionary dictionary] retain];
            sendLog = [[NSMutableArray array] retain];
            activeReceives = [[NSMutableDictionary dictionary] retain];
            receiveLog = [[NSMutableArray array] retain];
            
            //	sendQueue = [[NSMutableArray alloc] init];
            //	queueLock = [[NSConditionLock alloc] initWithCondition: QueueEmpty];
            //	[NSThread detachNewThreadSelector:@selector(runSendQueue:) toTarget:self withObject:nil];
            
            // bonjour
            bonjourBrowser = [[BonjourBrowser alloc] initWithBrowserController:self];
            [self displayBonjourServices];
            
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:bonjourBrowser];
            
            [splitDrawer restoreDefault: @"SplitDrawer"];
            [splitAlbums restoreDefault: @"SplitAlbums"];
            [splitViewHorz restoreDefault: @"SplitHorz2"];
            [splitComparative restoreDefault: @"SplitComparative"];
            [splitViewVert restoreDefault: @"SplitVert2"];
            
            if( gHorizontalHistory)
            {
                NSView* top = [[splitComparative subviews] objectAtIndex:0];
                BOOL hidden = [top isHidden] || [splitComparative isSubviewCollapsed: top];
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SplitComparativeHidden"] != hidden)
                    [self comparativeToggle: self];
            }
            else
            {
                NSView* right = [[splitComparative subviews] objectAtIndex:1];
                BOOL hidden = [right isHidden] || [splitComparative isSubviewCollapsed: right];
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SplitComparativeHidden"] != hidden)
                    [self comparativeToggle: self];
            }
            {
                NSView* left = [[splitDrawer subviews] objectAtIndex:0];
                BOOL hidden = [left isHidden] || [splitDrawer isSubviewCollapsed:left];
                if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SplitDrawerHidden"] != hidden)
                    [self drawerToggle: self];
            }
            
            // database : gray background
            //	[databaseOutline setUsesAlternatingRowBackgroundColors:NO];
            //	[databaseOutline setBackgroundColor:[NSColor lightGrayColor]];
            //	[databaseOutline setGridColor:[NSColor darkGrayColor]];
            //	[databaseOutline setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
            
            [[albumTable tableColumnWithIdentifier:@"Source"] setDataCell: [[[PrettyCell alloc] init] autorelease]];
            
            [[comparativeTable tableColumnWithIdentifier:@"Cell"] setDataCell: [[[ComparativeCell alloc] init] autorelease]];
            [comparativeTable setDoubleAction: @selector(doubleClickComparativeStudy:)];
            
            [self initContextualMenus];
            
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
            
            NSRunCriticalAlertPanel(NSLocalizedString(@"Error",nil), @"%@", NSLocalizedString( @"OK",nil), nil, nil, message);
            
            exit( 0);
        }
        
        [wait close];
        
        [self testAutorouting];
        
        [self setDBWindowTitle];
        
        loadingIsOver = YES;
        
        [self outlineViewRefresh];
        
        [self awakeActivity];
        [self.window makeKeyAndOrderFront: self];
        
        [self refreshMatrix: self];
        
#ifndef OSIRIX_LIGHT
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"restartAutoQueryAndRetrieve"] == YES && [[NSUserDefaults standardUserDefaults] objectForKey: @"savedAutoDICOMQuerySettingsArray"] != nil)
        {
            [[AppController sharedAppController] growlTitle: NSLocalizedString( @"Auto-Query", nil) description: NSLocalizedString( @"DICOM Auto-Query is restarting...", nil)  name:@"autoquery"];
            NSLog( @"-------- automatically restart DICOM AUTO-QUERY --------");
            
            WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Restarting Auto Query/Retrieve...", nil)];
            [wait showWindow:self];
            [[QueryController alloc] initAutoQuery: YES];
            [[QueryController currentAutoQueryController] switchAutoRetrieving: self];
            [NSThread sleepForTimeInterval: 0.5];
            [wait close];
            [wait autorelease];
        }
        else
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"autoRetrieving"];
#endif
        
#ifdef WITH_BANNER
        [NSThread detachNewThreadSelector: @selector(checkForBanner:) toTarget: self withObject: nil];
        
        CGFloat position = bannerSplit.frame.size.height - (banner.image.size.height+3);
        [bannerSplit setPosition: position ofDividerAtIndex: 0];
#else
       // [[[bannerSplit subviews] objectAtIndex:1] setHidden:YES];
#endif
        
        [[self window] setAnimationBehavior: NSWindowAnimationBehaviorNone];
        
        // Responder chain
        
        [albumTable setNextKeyView: databaseOutline];
        [_sourcesTableView setNextKeyView: databaseOutline];
        [databaseOutline setNextKeyView: searchField];
        [searchField setNextKeyView: databaseOutline];
        
        [self setSearchType: [[[searchField cell] searchMenuTemplate] itemWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"searchType"]]];
        
        //	NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
        //	[dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"LogEntry"]];
        //	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
        //
        //	NSError *error = nil;
        //	NSArray *logArray = [self.database.managedObjectContext executeFetchRequest:dbRequest error: &error];
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
        //	for( id log in logArray) [self.database.managedObjectContext deleteObject: log];
    }
    @catch (NSException *e) {
        N2LogException( e);
    }
    
    
    BOOL firstTimeExecution = ([[NSUserDefaults standardUserDefaults] objectForKey:@"FIRST_TIME_EXECUTION_2_0"] == nil);
    BOOL foundNotValidatedOsiriXPlugins = NO;
    
    if (firstTimeExecution)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"FIRST_TIME_EXECUTION_2_0"];
        
        
        
        NSArray* installedPlugins = [self->pluginManagerController plugins];
        for (NSDictionary* pluginDesc in installedPlugins)
        {
            if ([[pluginDesc objectForKey:@"HorosCompatiblePlugin"] boolValue] == NO)
            {
                foundNotValidatedOsiriXPlugins = YES;
                break;
            }
        }
        
        
        [[NSUserDefaults standardUserDefaults] setInteger:CPRInterpolationModeCubic
                                                   forKey:@"selectedCPRInterpolationMode"];
        
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            
            [self restoreWindowState:self];
            
        });
    }
    
    
    
    if (firstTimeExecution == YES && foundNotValidatedOsiriXPlugins == YES)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"OK",nil)];
        [alert setMessageText:NSLocalizedString(@"Not validated OsiriX plugins were detected!",nil)];
        [alert setInformativeText:NSLocalizedString(@"Not validated OsiriX plugins may cause Horos run-time errors. In case of problems, you can disable/uninstall them in [Plugins => Plugin Manager]. A brand new Horos plugin database is being built for you.",nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        [alert release];
    }
    
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_HOROS_STARTED detail:@"{}"];
    
    [ICloudDriveDetector performStartupICloudDriveTasks:self];
    [O2HMigrationAssistant performStartupO2HTasks:self];
}

- (IBAction) clickBanner:(id) sender
{
#ifdef WITH_BANNER
    if( [[self window] isKeyWindow])
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:URL_CLICK_BANNER]];
#endif
}

- (void) installBanner: (NSImage*) bannerImage
{
#ifdef WITH_BANNER
    [banner setImage: bannerImage];
    [bannerSplit setPosition: bannerSplit.frame.size.height - (banner.image.size.height+3) ofDividerAtIndex: 0];
#endif
}

// This gets executed in a separate thread
- (void) checkForBanner: (id) sender
{
#ifdef WITH_BANNER
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSError *error = nil;
    NSURLResponse *urlResponse = nil;
    
    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL: [NSURL URLWithString:URL_HOROS_BANNER] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval: 30] autorelease];
    NSData *imageData = [NSURLConnection sendSynchronousRequest: request returningResponse: &urlResponse error: &error];
    
    if( imageData && error == nil && [urlResponse.MIMEType isEqualToString: @"image/png"])
    {
        NSImage *bannerImage = [[[NSImage alloc] initWithData: imageData] autorelease];
        
        if( bannerImage)
            [self performSelectorOnMainThread: @selector(installBanner:) withObject: bannerImage waitUntilDone: NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
    
    [pool release];
#endif
}

-(void)dealloc
{
    [self deallocActivity];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey];
    [self deallocSources];
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
        keyPath = [keyPath substringFromIndex:7];
        if ([keyPath isEqual:OsirixBonjourSharingActiveFlagDefaultsKey])
        {
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
        
        unlink( "/tmp/kill_all_storescu");
        [[NSUserDefaults standardUserDefaults] setBool: hideListenerError_copy forKey: @"hideListenerError"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"copyHideListenerError"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // ----------
        
        [BrowserController tryLock:searchForComparativeStudiesLock during: 120];
        
        //Something in the delete queue? Write it to the disk
        [self saveDeleteQueue];
        [self syncReportsIfNecessary];
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    waitForRunningProcess = NO;
    
    [wait close];
    [wait autorelease];
    
    [pool release];
}

- (void) browserPrepareForClose
{
    //	[IncomingTimer invalidate];
    
    [[NSUserDefaults standardUserDefaults] setObject: NSStringFromRect( self.window.frame) forKey: @"DBWindowFrame"];
    
    NSLog( @"browserPrepareForClose");
    
    [self saveLoadAlbumsSortDescriptors];
    
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
    
    [splitViewVert saveDefault:@"SplitVert2"];
    [splitViewHorz saveDefault:@"SplitHorz2"];
    [splitAlbums saveDefault:@"SplitAlbums"];
    [splitComparative saveDefault:@"SplitComparative"];
    [splitDrawer saveDefault:@"SplitDrawer"];
    
    {
        NSView* left = [[splitDrawer subviews] objectAtIndex:0];
        BOOL hidden = [left isHidden] || [splitDrawer isSubviewCollapsed:[[splitDrawer subviews] objectAtIndex:0]];
        
        [[NSUserDefaults standardUserDefaults] setBool: hidden forKey: @"SplitDrawerHidden"];
    }
    
    if( gHorizontalHistory)
    {
        NSView* top = [[splitComparative subviews] objectAtIndex:0];
        BOOL hidden = [top isHidden] || [splitComparative isSubviewCollapsed:[[splitComparative subviews] objectAtIndex:0]];
        
        [[NSUserDefaults standardUserDefaults] setBool: hidden forKey: @"SplitComparativeHidden"];
    }
    else
    {
        NSView* right = [[splitComparative subviews] objectAtIndex:1];
        BOOL hidden = [right isHidden] || [splitComparative isSubviewCollapsed:[[splitComparative subviews] objectAtIndex:1]];
        
        [[NSUserDefaults standardUserDefaults] setBool: hidden forKey: @"SplitComparativeHidden"];
    }
    
    if( [[databaseOutline sortDescriptors] count] >= 1)
    {
        NSDictionary	*sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[databaseOutline sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[databaseOutline sortDescriptors] objectAtIndex: 0] key], @"key", nil];
        [[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"databaseSortDescriptor"];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[databaseOutline columnState] forKey: @"databaseColumns2"];
    
    [self.window setDelegate:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool: [animationCheck state] forKey: @"AutoPlayAnimation"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXTemporaryDatabase" error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/dicomsr_osirix" error:NULL];
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
    // Is there a full screen window displayed?
    for( id window in [NSApp orderedWindows])
    {
        if( [window isKindOfClass: [NSFullScreenWindow class]])
        {
            NSBeep();
            return NO;
        }
    }
    
    [ViewerController closeAllWindows];
    
    [_database save:NULL];
    
    if(/* newFilesInIncoming ||*/ [[ThreadsManager defaultManager] threadsCount] > 0)
    {
        NSAlert* w = [NSAlert alertWithMessageText: NSLocalizedString( @"Background Threads", NULL)
                                     defaultButton: NSLocalizedString( @"Cancel", NULL)
                                   alternateButton: NSLocalizedString( @"Quit", NULL)
                                       otherButton: NULL
                         informativeTextWithFormat: NSLocalizedString( @"Background threads are currently running. Are you sure you want to quit now? These threads will be cancelled.", NULL)];
        
        NSTimer *t = [NSTimer timerWithTimeInterval: 0.3 target:self selector:@selector(shouldTerminateCallback:) userInfo: w repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer: t forMode:NSModalPanelRunLoopMode];
        
        NSInteger r = [w runModal];
        
        [t invalidate];
        
        if( /*newFilesInIncoming ||*/ [[ThreadsManager defaultManager] threadsCount] > 0)
        {
            if( r == NSAlertDefaultReturn)
                return NO;
        }
        
        // AppController will cancel these threads and give them 10 secs to finish... then kill them
    }
    
    if( [SendController sendControllerObjects] > 0)
    {
        if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Sending - STORE", nil), NSLocalizedString(@"Files are currently being sent to a DICOM node. Are you sure you want to quit now? The sending will be stopped.", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Quit", nil), nil) == NSAlertDefaultReturn) return NO;
    }
    
    [self setDatabase:nil];
    
    return YES;
}

- (void)showDatabase: (id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    
    [self.window makeKeyAndOrderFront:sender];
    [self outlineViewRefresh];
}

- (void)keyDown:(NSEvent *)event
{
    NSResponder* firstResponder = [[self window] firstResponder];
    if (firstResponder == albumTable || firstResponder == _sourcesTableView || firstResponder == _activityTableView) {
        [super keyDown:event];
        return;
    }
    
    if( [[event characters] length] == 0) return;
    
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
    
    BOOL containsDistantStudy = NO;
    
    if( [[databaseOutline selectedRowIndexes] count] > 0)
    {
        NSUInteger idx = databaseOutline.selectedRowIndexes.firstIndex;
        
        while (idx != NSNotFound)
        {
            id object = [databaseOutline itemAtRow: idx];
            
            if( [object isDistant])
            {
                containsDistantStudy = YES;
                break;
            }
            
            idx = [databaseOutline.selectedRowIndexes indexGreaterThanIndex: idx];
        }
    }
    
    if( [[databaseOutline selectedRowIndexes] count] < 1 || containsDistantStudy == YES) // No Database Selection or Distant Study
    {
        if( containsDistantStudy == YES && [menuItem action] == @selector(querySelectedStudy:))
            return YES;
        
        if(	[menuItem action] == @selector(rebuildThumbnails:) ||
           [menuItem action] == @selector(searchForCurrentPatient:) ||
           [menuItem action] == @selector(viewerDICOM:) ||
           [menuItem action] == @selector(MovieViewerDICOM:) ||
           [menuItem action] == @selector(viewerDICOMMergeSelection:) ||
           [menuItem action] == @selector(revealInFinder:) ||
           [menuItem action] == @selector(export2PACS:) ||
           [menuItem action] == @selector(exportQuicktime:) ||
           [menuItem action] == @selector(exportJPEG:) ||
           [menuItem action] == @selector(exportTIFF:) ||
           [menuItem action] == @selector(exportDICOMFile:) ||
           [menuItem action] == @selector(sendMail:) ||
           [menuItem action] == @selector(addStudiesToUser:) ||
           [menuItem action] == @selector(sendEmailNotification:) ||
           [menuItem action] == @selector(compressSelectedFiles:) ||
           [menuItem action] == @selector(decompressSelectedFiles:) ||
           [menuItem action] == @selector(generateReport:) ||
           [menuItem action] == @selector(deleteReport:) ||
           [menuItem action] == @selector(convertReportToPDF:) ||
           [menuItem action] == @selector(convertReportToDICOMSR:) ||
           [menuItem action] == @selector(delItem:) ||
           [menuItem action] == @selector(querySelectedStudy:) ||
           [menuItem action] == @selector(burnDICOM:) ||
           [menuItem action] == @selector(anonymizeDICOM:) ||
           [menuItem action] == @selector(viewXML:) ||
           [menuItem action] == @selector(applyRoutingRule:) ||
           [menuItem action] == @selector(regenerateAutoComments:) ||
           [menuItem action] == @selector(unifyStudies:) ||
           [menuItem action] == @selector(viewerSubSeriesDICOM:) ||
           [menuItem action] == @selector(viewerReparsedSeries:) ||
           [menuItem action] == @selector(copyToDBFolder:)
           )
            return NO;
    }
    
    if( [[databaseOutline selectedRowIndexes] count] < 1 || containsDistantStudy == NO)
    {
        if(	[menuItem action] == @selector(retrieveSelectedPODStudies:))
            return NO;
    }
    
    if ([_database isReadOnly])
    {
        if([menuItem action] == @selector(compressSelectedFiles:) ||
           [menuItem action] == @selector(decompressSelectedFiles:) ||
           [menuItem action] == @selector(generateReport:) ||
           [menuItem action] == @selector(deleteReport:) ||
           [menuItem action] == @selector(convertReportToPDF:) ||
           [menuItem action] == @selector(convertReportToDICOMSR:) ||
           [menuItem action] == @selector(delItem:) ||
           [menuItem action] == @selector(regenerateAutoComments:) ||
           [menuItem action] == @selector(copyToDBFolder:) ||
           [menuItem action] == @selector(querySelectedStudy:) ||
           [menuItem action] == @selector(unifyStudies:) ||
           [menuItem action] == @selector(retrieveSelectedPODStudies:))
            return NO;
    }
    
    if ([_database isLocal] == NO)
    {
        if( [menuItem action] == @selector(deleteAlbum:) ||
           [menuItem action] == @selector(addAlbum:) ||
           [menuItem action] == @selector(addSmartAlbum:) ||
           [menuItem action] == @selector(addAlbums:) ||
           [menuItem action] == @selector(defaultAlbums:))
            return NO;
        
        if( [menuItem action] == @selector(selectFilesAndFoldersToAdd:) ||
           [menuItem action] == @selector(addURLToDatabase:) ||
           [menuItem action] == @selector(importRawData:))
            return NO;
        
        if( [menuItem action] == @selector(anonymizeDICOM:))
            return NO;
        
        if( [menuItem action] == @selector(compressSelectedFiles:) ||
           [menuItem action] == @selector(decompressSelectedFiles:))
            return NO;
    }
    
    if( [menuItem action] == @selector(convertReportToPDF:) || [menuItem action] == @selector(convertReportToDICOMSR:))
    {
        id item = [databaseOutline itemAtRow: [[databaseOutline selectedRowIndexes] firstIndex]];
        
        if( item)
        {
            DicomStudy *studySelected;
            
            if ([[item valueForKey: @"type"] isEqualToString:@"Study"])
                studySelected = (DicomStudy*) item;
            else
                studySelected = [item valueForKey:@"study"];
            
            if( [studySelected valueForKey:@"reportURL"] == nil)
                return NO;
        }
    }
    else if( menuItem.menu == imageTileMenu)
    {
        return [[[NSApp mainWindow] windowController] isKindOfClass:[ViewerController class]];
    }
    else if( [menuItem action] == @selector(unifyStudies:))
    {
        if (![_database isLocal]) return NO;
        
        if( [[databaseOutline selectedRowIndexes] count] <= 1) return NO;
        
        return YES;
    }
    else if( [menuItem action] == @selector(regenerateAutoComments:))
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"]) return YES;
        else return NO;
    }
    else if( [menuItem action] == @selector(viewerDICOMROIsImages:))
    {
        if( containsDistantStudy)
            return NO;
        
        if ([_database isLocal])
        {
            if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self ROIImages: menuItem] count] == 0) return NO;
        }
        else return YES;
    }
    else if( [menuItem action] == @selector(viewerKeyImagesAndROIsImages:))
    {
        if( containsDistantStudy)
            return NO;
        
        if ([_database isLocal])
        {
            if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self ROIsAndKeyImages: menuItem] count] == 0) return NO;
        }
        else return YES;
    }
    else if( [menuItem action] == @selector(exportROIAndKeyImagesAsDICOMSeries:))
    {
        if( containsDistantStudy)
            return NO;
        
        if ([_database isLocal])
        {
            if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self ROIsAndKeyImages: menuItem] count] == 0) return NO;
        }
        else return YES;
    }
    else if( [menuItem action] == @selector(viewerDICOMKeyImages:))
    {
        if( containsDistantStudy)
            return NO;
        
        if ([_database isLocal])
        {
            if( [[databaseOutline selectedRowIndexes] count] < 10 && [[self KeyImages: menuItem] count] == 0) return NO;
        }
        else return YES;
    }
    else if( [menuItem action] == @selector(createROIsFromRTSTRUCT:))
    {
        if( containsDistantStudy)
            return NO;
        
        if (![_database isLocal])
            return NO;
    }
    else if( [menuItem action] == @selector(compressSelectedFiles:))
    {
        if( containsDistantStudy)
            return NO;
    }
    else if( [menuItem action] == @selector(decompressSelectedFiles:))
    {
        if( containsDistantStudy)
            return NO;
    }
    else if( [menuItem action] == @selector(copyToDBFolder:))
    {
        if( containsDistantStudy)
            return NO;
        
        if (![_database isLocal])
            return NO;
        
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
    else if( [menuItem action] == @selector(lockStudies:))
    {
        if( containsDistantStudy)
            return NO;
        
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
    else if( [menuItem action] == @selector(unlockStudies:))
    {
        if( containsDistantStudy)
            return NO;
        
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
    else if( [menuItem action] == @selector(delItem:))
    {
        if( containsDistantStudy)
            return NO;
        
        if (![_database isLocal]) return NO;
        
        BOOL matrixThumbnails = YES;
        
        if( menuItem.menu == [oMatrix menu] || [[self window] firstResponder] == oMatrix)
            matrixThumbnails = YES;
        
        if( menuItem.menu == [databaseOutline menu] || [[self window] firstResponder] == databaseOutline || [[self window] firstResponder] == comparativeTable)
            matrixThumbnails = NO;
        
        if( matrixThumbnails)
            [menuItem setTitle: NSLocalizedString( @"Delete Selected Series Thumbnails", nil)];
        else
            [menuItem setTitle: NSLocalizedString( @"Delete Selected Lines", nil)];
    }
    else if( [menuItem action] == @selector(mergeStudies:))
    {
        if( containsDistantStudy)
            return NO;
        
        if (![_database isLocal]) return NO;
        
        NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
        BOOL	onlySeries = YES;
        
        NSInteger row = 0;
        for( NSInteger x = 0; x < [selectedRows count] ; x++)
        {
            row = ( x == 0) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
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
    else if( [menuItem action] == @selector(mergeSeries:))
    {
        if( containsDistantStudy)
            return NO;
        
        if (![_database isLocal]) return NO;
        
        if( [[oMatrix selectedCells] count] > 1) return YES;
        else return NO;
    }
    else if( [menuItem action] == @selector(annotMenu:))
    {
        if( [menuItem tag] == [[NSUserDefaults standardUserDefaults] integerForKey:@"ANNOTATIONS"]) [menuItem setState: NSOnState];
        else [menuItem setState: NSOffState];
    }
    return YES;
}

- (BOOL)is2DViewer
{
    return NO;
}

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
    
    //[helpMenu addItemWithTitle: NSLocalizedString(@"TBD", nil) action: @selector(help:) keyEquivalent: @""];
    [helpMenu addItemWithTitle: NSLocalizedString(@"Professional support", nil) action: @selector(openHorosSupport:) keyEquivalent: @""];
    [helpMenu addItemWithTitle: NSLocalizedString(@"Community support", nil) action: @selector(openCommunityPage:) keyEquivalent: @""];
    [helpMenu addItem: [NSMenuItem separatorItem]];
    [helpMenu addItemWithTitle: NSLocalizedString(@"Report a bug", nil) action: @selector(openBugReportPage:) keyEquivalent: @""];
    //[helpMenu addItem: [NSMenuItem separatorItem]];
    //[helpMenu addItemWithTitle: NSLocalizedString(@"Send an email to Horos support", nil) action: @selector(sendEmail:) keyEquivalent: @""];
    
    [helpMenu release];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark DICOM Network & Files functions

- (void) resetListenerTimer // __deprecated
{
    [DicomDatabase syncImportFilesFromIncomingDirTimerWithUserDefaults];
}

- (void) saveDeleteQueue
{
    [deleteQueue lock];
    NSArray	*copyArray = [NSArray arrayWithArray: deleteQueueArray];
    [deleteQueueArray removeAllObjects];
    
    if( copyArray.count)
    {
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]])
        {
            NSArray *oldQueue = [NSArray arrayWithContentsOfFile: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]];
            
            copyArray = [copyArray arrayByAddingObjectsFromArray: oldQueue];
            
            NSLog( @"---- old Delete Queue List found (%d files) add it to current queue.", (int) [oldQueue count]);
            
            [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
        }
        
        NSLog( @"---- save delete queue: %d objects", (int) [copyArray count]);
        
        [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
        [copyArray writeToFile: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] atomically: YES];
    }
    [deleteQueue unlock];
}

- (void) emptyDeleteQueueThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [deleteInProgress lock];
    [deleteQueue lock];
    NSArray	*copyArray = [NSArray arrayWithArray: deleteQueueArray];
    [deleteQueueArray removeAllObjects];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]])
    {
        NSArray *oldQueue = [NSArray arrayWithContentsOfFile: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]];
        
        copyArray = [copyArray arrayByAddingObjectsFromArray: oldQueue];
        
        NSLog( @"---- old Delete Queue List found (%d files) add it to current queue.", (int) [oldQueue count]);
        
        [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
    }
    
    if( copyArray.count)
    {
        NSMutableArray *folders = [NSMutableArray array];
        
        NSLog( @"delete Queue start: %d objects", (int) [copyArray count]);
        
        [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
        [copyArray writeToFile: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] atomically: YES];
        
        [deleteQueue unlock];
        
        long f = 0;
        NSString *lastFolder = nil;
        NSTimeInterval date = 0;
        for( NSString *file in copyArray)
        {
            unlink( [file UTF8String]);		// <- this is faster
            
            NSString *parentFolder = [file stringByDeletingLastPathComponent];
            if( [lastFolder isEqualToString: parentFolder] == NO)
            {
                if( [folders containsString: parentFolder] == NO)
                    [folders addObject: parentFolder];
                
                [lastFolder release];
                lastFolder = [[NSString alloc] initWithString: parentFolder];
            }
            
            if( [NSDate timeIntervalSinceReferenceDate] - date > 1)
            {
                date = [NSDate timeIntervalSinceReferenceDate];
                [NSThread currentThread].progress = (float)f / (float)[copyArray count];
                [NSThread currentThread].status = N2LocalizedSingularPluralCount( (long)copyArray.count-f, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                
                if( [NSThread currentThread].isCancelled) //The queue is saved as a plist, we can continue later...
                    break;
            }
            f++;
        }
        [NSThread currentThread].progress = (float) f / (float) [copyArray count];
        [NSThread currentThread].status = N2LocalizedSingularPluralCount( [copyArray count]-f, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
        
        [lastFolder release];
        
        if( [NSThread currentThread].isCancelled == NO)
            [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
        
        [deleteInProgress unlock];
        
        [NSThread currentThread].status = NSLocalizedString(@"Cleaning database folders...", nil);
        [NSThread currentThread].progress = -1;
        
        @try
        {
            for( NSString *f in folders)
            {
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath: f traverseLink: NO];
                
                if( [[fileAttributes objectForKey: NSFileType] isEqualToString: NSFileTypeDirectory])
                {
                    NSDate* dirCreationDate = [fileAttributes objectForKey:NSFileCreationDate];
                    if ((!dirCreationDate || -[dirCreationDate timeIntervalSinceNow] > 120) // if it has been created at least 2 minutes ago (or if we don't know)
                        && [[fileAttributes objectForKey: NSFileReferenceCount] intValue] < 4) // if it contains less than 3 files
                    { // check if this folder is empty, and delete it if necessary
                        int numberOfValidFiles = 0;
                        for( NSString *s in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: f error: nil])
                        {
                            if( [[s lastPathComponent] characterAtIndex: 0] != '.')
                                numberOfValidFiles++;
                        }
                        
                        if( numberOfValidFiles == 0 && [[f lastPathComponent] isEqualToString: @"ROIs"] == NO)
                        {
                            NSLog( @"delete Queue: delete folder: %@", f);
                            [[NSFileManager defaultManager] removeItemAtPath: f error:NULL];
                            
                        }
                    }
                }
                
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        NSLog(@"delete Queue end");
    }
    else {
        [deleteQueue unlock];
        [deleteInProgress unlock];
    }
    
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
        [[NSFileManager defaultManager] removeItemAtPath: @"/tmp/error_message" error:NULL];
        
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
    
    if( deleteQueueArray == nil) deleteQueueArray = [[NSMutableArray array] retain];
    if( deleteQueue == nil) deleteQueue = [[NSRecursiveLock alloc] init];
    if( deleteInProgress == nil) deleteInProgress = [[NSRecursiveLock alloc] init];
    
    if( [deleteInProgress tryLock])
    {
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]])
        {
            NSArray *oldQueue = [NSArray arrayWithContentsOfFile: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"]];
            
            NSLog( @"---- old Delete Queue List found (%d files) add it to current queue.", (int) [oldQueue count]);
            [[NSFileManager defaultManager] removeItemAtPath: [[self documentsDirectory] stringByAppendingPathComponent: @"DeleteQueueFile.plist"] error: nil];
            
            [deleteQueue lock];
            
            @try
            {
                [deleteQueueArray addObjectsFromArray: oldQueue];
            }
            @catch (NSException *e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            
            [deleteQueue unlock];
        }
        [deleteInProgress unlock];
    }
    
    if( [deleteQueueArray count] > 0)
    {
        if( [deleteInProgress tryLock])
        {
            [deleteInProgress unlock];
            
            NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(emptyDeleteQueueThread) object:  nil] autorelease];
            t.name = NSLocalizedString( @"Deleting files...", nil);
            t.status = N2LocalizedSingularPluralCount(deleteQueueArray.count, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
            t.progress = 0;
            t.supportsCancel = YES;
            [[ThreadsManager defaultManager] addThreadAndStart: t];
        }
    }
    
    if( self.database.managedObjectContext.deletedObjects.count)
    {
        NSLog( @"---- self.database.managedObjectContext.deletedObjects.count (%d) > 0 -> save db", (int) self.database.managedObjectContext.deletedObjects.count);
        [self.database save];
    }
}

- (void)addFileToDeleteQueue: (NSString*)file
{
    if( deleteQueueArray == nil) deleteQueueArray = [[NSMutableArray array] retain];
    if( deleteQueue == nil) deleteQueue = [[NSRecursiveLock alloc] init];
    if( deleteInProgress == nil) deleteInProgress = [[NSRecursiveLock alloc] init];
    
    [deleteQueue lock];
    if( file)
        [deleteQueueArray addObject: file];
    [deleteQueue unlock];
}

+ (NSString*)_findFirstDicomdirOnCDMedia: (NSString*)startDirectory // __deprecated
{
    @try {
        return [DicomDatabase _findDicomdirIn:[startDirectory stringsByAppendingPaths:[[[NSFileManager defaultManager] enumeratorAtPath:startDirectory filesOnly:YES] allObjects]]];
    }
    @catch (NSException *e) {
        N2LogException( e);
    }
    
    return nil;
}

+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination
{
    return [BrowserController unzipFile:  file withPassword:  pass destination:  destination showGUI: YES];
}

+ (BOOL) unzipFile: (NSString*) file withPassword: (NSString*) pass destination: (NSString*) destination showGUI: (BOOL) showGUI
{
    [[NSFileManager defaultManager] removeItemAtPath: destination error:NULL];
    
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
            [[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/" withIntermediateDirectories:YES attributes:nil error:NULL];
        
        [t setCurrentDirectoryPath: @"/tmp/"];
        if( pass)
            args = [NSArray arrayWithObjects: @"-qq", @"-o", @"-d", destination, @"-P", pass, file, nil];
        else
            args = [NSArray arrayWithObjects: @"-qq", @"-o", @"-d", destination, file, nil];
        [t setArguments: args];
        [t launch];
        while( [t isRunning])
            [NSThread sleepForTimeInterval: 0.1];
        
        //[t waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
    }
    @catch ( NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [wait close];
    [wait autorelease];
    
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
                [alert addButtonWithTitle: NSLocalizedString( @"Yes", nil)];
                [alert addButtonWithTitle: NSLocalizedString( @"No", nil)];
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
    // TODO: something
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
                NSString	*description = nil, *type = nil;
                
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

//- (void)listenerAnonymizeFiles: (NSArray*)files
//{
//	#ifndef OSIRIX_LIGHT
//	NSArray				*array = [NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"**anonymized**", [DCMAttributeTag tagWithName:@"PatientID"], @"00000",nil];
//	NSMutableArray		*tags = [NSMutableArray array];
//
//	[tags addObject:array];
//
//	for( NSString *file in files)
//	{
//		NSString *destPath = [file stringByAppendingString:@"temp"];
//
//		@try
//		{
//			[DCMObject anonymizeContentsOfFile: file  tags:tags  writingToFile:destPath];
//		}
//		@catch (NSException * e)
//		{
//            N2LogExceptionWithStackTrace(e);
//		}
//
//		[[NSFileManager defaultManager] removeItemAtPath: file error:NULL];
//		[[NSFileManager defaultManager] movePath:destPath toPath: file handler: nil];
//	}
//#endif
//}

#pragma deprecated (pathResolved:)
- (NSString*) pathResolved:(NSString*) inPath
{
    return [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath];
}

#pragma deprecated (isAliasPath:)
- (BOOL) isAliasPath:(NSString *)inPath
{
    return [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath] != nil;
}

#pragma deprecated (resolveAliasPath:)
- (NSString*) resolveAliasPath:(NSString*)inPath
{
    NSString* resolved = [[NSFileManager defaultManager] destinationOfAliasAtPath:inPath];
    return resolved ? resolved : inPath;
}

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path // __deprecated
{
    NSString *folder = path;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSString* temp = [self pathResolved:path];
        if (!temp)
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
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
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
        
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
    {
        filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
    }
    else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
    
    if( [filesToExport count])
    {
        [[NSWorkspace sharedWorkspace] selectFile:filesToExport.firstObject inFileViewerRootedAtPath:[filesToExport.firstObject stringByDeletingLastPathComponent]];
    }
}

static volatile int numberOfThreadsForJPEG = 0;

- (BOOL) waitForAProcessor
{
    int processors =  [[NSProcessInfo processInfo] processorCount];
    
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
        if( [mod rangeOfString: [dict valueForKey: @"modality"]].location != NSNotFound)
        {
            int compression = compression_none;
            if( [[dict valueForKey: @"compression"] intValue] == compression_sameAsDefault)
                dict = [array objectAtIndex: 0];
            
            compression = [[dict valueForKey: @"compression"] intValue];
            
            if( quality)
            {
                if( compression == compression_JPEG2000 || compression == compression_JPEGLS)
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
- (void)decompressDICOMJPEGinINCOMING:(NSArray*)array // __deprecated
{
    [self decompressDICOMList:array to:_database.incomingDirPath];
}

- (void)decompressDICOMJPEG:(NSArray*)array // __deprecated
{
    [self decompressDICOMList:array to:nil];
}

- (void)compressDICOMJPEGinINCOMING:(NSArray*)array // __deprecated
{
    [self compressDICOMWithJPEG:array to:_database.incomingDirPath];
}

- (void)compressDICOMJPEG:(NSArray*)array // __deprecated
{
    [self compressDICOMWithJPEG:array];
}

- (void)decompressArrayOfFiles:(NSArray*)array work:(NSNumber*)work // __deprecated
{
    switch ([work charValue])
    {
        case 'C':
            [_database processFilesAtPaths: array intoDirAtPath: nil mode: Compress];
            break;
        case 'X':
            [_database processFilesAtPaths: array intoDirAtPath: [_database incomingDirPath] mode: Compress];
            break;
        case 'D':
            [_database processFilesAtPaths: array intoDirAtPath: nil mode: Decompress];
            break;
        case 'I':
            [_database processFilesAtPaths: array intoDirAtPath: [_database incomingDirPath] mode: Decompress];
            break;
    }
}

- (IBAction) compressSelectedFiles: (id)sender
{
    if( /*bonjourDownloading == NO &&*/ [_database isLocal])
    {
        NSMutableArray *dicomFiles2Export = [NSMutableArray array];
        NSMutableArray *filesToExport;
        
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

- (void)checkIncomingThread: (id)sender // __deprecated
{
    [[DicomDatabase activeLocalDatabase] importFilesFromIncomingDir];
}

- (void) checkIncomingNow: (id) sender // __deprecated
{
    //	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
}

- (void)checkIncoming: (id)sender // __deprecated
{
    //	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
    [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
}

+ (void)writeMovieToPath:(NSString*)fileName images:(NSArray*)imagesArray framesPerSecond:(NSInteger)fps
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
        if (fps <= 0)
            fps = [[NSUserDefaults standardUserDefaults] integerForKey: @"quicktimeExportRateValue"];
        if (fps <= 0)
            fps = 10;
        
        CMTimeValue timeValue = 600 / fps;
        CMTime frameDuration = CMTimeMake( timeValue, 600);
        
        NSError *error = nil;
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath: fileName] fileType: AVFileTypeQuickTimeMovie error:&error];
        
        if (!error)
        {
            NSImage *im = [imagesArray lastObject];
            
            double bitsPerSecond = im.size.width * im.size.height * fps * 4;
            
            if( bitsPerSecond > 0)
            {
                NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                               AVVideoCodecH264, AVVideoCodecKey,
                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithDouble: bitsPerSecond], AVVideoAverageBitRateKey,
                                                [NSNumber numberWithInteger: 1], AVVideoMaxKeyFrameIntervalKey,
                                                nil], AVVideoCompressionPropertiesKey,
                                               [NSNumber numberWithInt: im.size.width], AVVideoWidthKey,
                                               [NSNumber numberWithInt: im.size.height], AVVideoHeightKey, nil];
                
                // Instanciate the AVAssetWriterInput
                AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
                
                if( writerInput == nil)
                    N2LogStackTrace( @"**** writerInput == nil : %@", videoSettings);
                
                // Instanciate the AVAssetWriterInputPixelBufferAdaptor to be connected to the writer input
                AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
                // Add the writer input to the writer and begin writing
                [writer addInput:writerInput];
                [writer startWriting];
                
                CMTime nextPresentationTimeStamp;
                
                nextPresentationTimeStamp = kCMTimeZero;
                
                [writer startSessionAtSourceTime:nextPresentationTimeStamp];
                
                for( NSImage *im in imagesArray)
                {
                    NSAutoreleasePool *pool = [NSAutoreleasePool new];
                    
                    CVPixelBufferRef buffer = nil;
                    
                    buffer = [QuicktimeExport CVPixelBufferFromNSImage: im];
                    
                    [pool release];
                    
                    if( buffer)
                    {
                        CVPixelBufferLockBaseAddress(buffer, 0);
                        while( writerInput && [writerInput isReadyForMoreMediaData] == NO)
                            [NSThread sleepForTimeInterval: 0.1];
                        [pixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:nextPresentationTimeStamp];
                        CVPixelBufferUnlockBaseAddress(buffer, 0);
                        CVPixelBufferRelease(buffer);
                        buffer = nil;
                        
                        nextPresentationTimeStamp = CMTimeAdd(nextPresentationTimeStamp, frameDuration);
                        
                        CVPixelBufferRelease(buffer);
                    }
                }
                [writerInput markAsFinished];
            }
            else
                N2LogStackTrace( @"********** bitsPerSecond == 0");
            
            [writer finishWriting];
        }
    }
    @catch( NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        [pool release];
    }
}

+ (void)writeMovieToPath:(NSString*)fileName images:(NSArray*)imagesArray {
    [self writeMovieToPath:fileName images:imagesArray framesPerSecond:0];
}

- (void)writeMovie:(NSArray*)imagesArray name:(NSString*)fileName
{
    [BrowserController writeMovieToPath:fileName images:imagesArray];
}

+(void)setPath:(NSString*)path relativeTo:(NSString*)dirPath forSeriesId:(int)seriesId kind:(NSString*)kind toSeriesPaths:(NSMutableDictionary*)seriesPaths
{
    
    if (seriesId == -1)
        NSLog(@"SeriesId %d", seriesId);
    
    if (seriesPaths)
    {
        NSNumber* seriesIdK = [NSNumber numberWithInt:seriesId];
        
        path = [path stringByReplacingCharactersInRange:dirPath.range withString:@""];
        if ([path characterAtIndex:0] == '/')
            path = [path stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@""];
        
        NSMutableDictionary* pathsForSeries = [seriesPaths objectForKey:seriesIdK];
        if (!pathsForSeries)
        {
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
    
    @try
    {
        int uniqueSeriesID = 0;
        BOOL first = YES;
        BOOL cineRateSet = NO;
        
        NSInteger fps = 10;
        
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
            if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
            else
            {
                if( first)
                {
                    if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), nil, [tempPath lastPathComponent]) == NSAlertDefaultReturn)
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
                        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
                    }
                    else break;
                }
            }
            first = NO;
            
            tempPath = [tempPath stringByAppendingPathComponent: [[NSMutableString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]] filenameString]];
            if( [[curImage valueForKeyPath: @"series.study.id"] isEqualToString: previousStudy] == NO || [[curImage valueForKeyPath: @"series.study.patientUID"] compare: previousPatientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
            {
                previousPatientUID = [curImage valueForKeyPath: @"series.study.patientUID"];
                previousStudy = [curImage valueForKeyPath: @"series.study.id"];
                previousSeries = -1;
                uniqueSeriesID = 0;
                previousSeriesInstanceUID = @"";
            }
            
            // Find the STUDY folder
            if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
                [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            NSString *seriesName = [curImage.series.name filenameString];
            if( seriesName.length == 0)
                seriesName = @"series";
            
            NSMutableString *seriesStr = [NSMutableString stringWithString: seriesName];
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
                                @autoreleasepool
                                {
                                    NSImage *newImage = [im imageByScalingProportionallyToSize:NSMakeSize( width, height)];
                                    if( newImage)
                                        [imagesArray replaceObjectAtIndex: index withObject: newImage];
                                    
                                }
                            }
                        }
                    }
                    
                    NSString* fullPath = [previousPath stringByAppendingPathExtension: @"mp4"];
                    [BrowserController writeMovieToPath:fullPath images:imagesArray];
                    [BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"mp4" toSeriesPaths:seriesPaths];
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
                            }
                            else
                            {
                                // TODO: write thumb on TMP, assign thumbnail to its filecontents, delete tmp file
                            }
                        }
                    }
                    @catch ( NSException *e)
                    {
                        N2LogExceptionWithStackTrace(e);
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
                    N2LogExceptionWithStackTrace(e);
                }
            }
            else if( [DCMAbstractSyntaxUID isStructuredReport: [curImage valueForKeyPath: @"series.seriesSOPClassUID"]])
            {
                [[NSFileManager defaultManager] confirmDirectoryAtPath:@"/tmp/dicomsr_osirix/"];
                
                NSString *htmlpath = [[@"/tmp/dicomsr_osirix/" stringByAppendingPathComponent: [[curImage valueForKey: @"completePath"] lastPathComponent]] stringByAppendingPathExtension: @"xml"];
                
                if( [[NSFileManager defaultManager] fileExistsAtPath: htmlpath] == NO)
                {
                    NSTask *aTask = [[[NSTask alloc] init] autorelease];
                    [aTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
                    [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/dsr2html"]];
                    [aTask setArguments: [NSArray arrayWithObjects: @"+X1", @"--unknown-relationship", @"--ignore-constraints", @"--ignore-item-errors", @"--skip-invalid-items", [curImage valueForKey: @"completePath"], htmlpath, nil]];
                    [aTask launch];
                    while( [aTask isRunning])
                        [NSThread sleepForTimeInterval: 0.1];
                    
                    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                    [aTask interrupt];
                }
                
                if( [[NSFileManager defaultManager] fileExistsAtPath: [htmlpath stringByAppendingPathExtension: @"pdf"]] == NO)
                {
                    if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]])
                    {
                        NSTask *aTask = [[[NSTask alloc] init] autorelease];
                        [aTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Decompress"]];
                        [aTask setArguments: [NSArray arrayWithObjects: htmlpath, @"pdfFromURL", nil]];
                        [aTask launch];
                        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
                        while( [aTask isRunning] && [NSDate timeIntervalSinceReferenceDate] - start < 10)
                            [NSThread sleepForTimeInterval: 0.1];
                        
                        //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                        [aTask interrupt];
                    }
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
                @autoreleasepool
                {
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
                                    fps = [dcmPix cineRate];
                                }
                            }
                            
                            [dcmPix release];
                        }
                    }
                    @catch( NSException *e)
                    {
                        N2LogExceptionWithStackTrace(e);
                    }
                }
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
                        @autoreleasepool
                        {
                            NSImage *newImage = [im imageByScalingProportionallyToSize:NSMakeSize( width, height)];
                            
                            if( newImage)
                                [imagesArray replaceObjectAtIndex: index withObject: newImage];
                        }
                    }
                }
            }
            
            NSString* fullPath = [previousPath stringByAppendingPathExtension:@"mp4"];
            [BrowserController writeMovieToPath:fullPath images:imagesArray framesPerSecond:fps];
            [BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"mp4" toSeriesPaths:seriesPaths];
        }
        else if( [imagesArray count] == 1)
        {
            NSArray *representations = [[imagesArray objectAtIndex: 0] representations];
            NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
            NSString* fullPath = [previousPath stringByAppendingPathExtension: @"jpg"];
            [bitmapData writeToFile:fullPath atomically:YES];
            [BrowserController setPath:fullPath relativeTo:path forSeriesId:previousSeries kind:@"jpg" toSeriesPaths:seriesPaths];
        }
        
        if( createHTML && imagesArray.count)
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
        N2LogExceptionWithStackTrace(e);
    }
    
    @finally
    {
        [splash close];
        [splash autorelease];
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages: YES];
    else
        [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages: YES];
    
    [sPanel setCanChooseDirectories:YES];
    [sPanel setCanChooseFiles:NO];
    [sPanel setAllowsMultipleSelection:NO];
    [sPanel setMessage: NSLocalizedString(@"Select the location where to export the Movie files:",nil)];
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
    {
        filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
        NSLog(@"Files from contextual menu: %d", (int) [filesToExport count]);
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
            if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
            else
            {
                if( i == 0)
                {
                    if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), nil, [tempPath lastPathComponent]) == NSAlertDefaultReturn)
                    {
                        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
                        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
                    }
                    else break;
                }
            }
            
            tempPath = [tempPath stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]]]];
            
            // Find the STUDY folder
            if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            NSMutableString *seriesStr = [NSMutableString stringWithString: @"series"];
            if( [curImage valueForKeyPath: @"series.name"])
                seriesStr = [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.name"]];
            
            [BrowserController replaceNotAdmitted:seriesStr];
            tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
            tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
            
            // Find the SERIES folder
            if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
            
            long imageNo = [[curImage valueForKey:@"instanceNumber"] intValue];
            
            if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue])
            {
                previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
                serieCount++;
            }
            
            dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, extension];
            
            int t = 2;
            while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
            {
                dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, t, extension];
                t++;
            }
            
            if( t != 2)
            {
                [renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, extension], @"oldName", [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, 1, extension], @"newName", nil]];
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
        [splash autorelease];
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
                        
                        if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound || [studiesArrayPatientUID
                                                                                                                                     indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { if( [obj compare: [study valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame) return YES; else return NO;}] == NSNotFound)
                        {
                            NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: user.managedObjectContext];
                            
                            [studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
                            [studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
                            
                            [studyLink setValue: user forKey: @"user"];
                            
                            @try
                            {
                                [[[WebPortal defaultWebPortal] database] save:nil];
                            }
                            @catch (NSException * e)
                            {
                                N2LogExceptionWithStackTrace(e);
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
                N2LogExceptionWithStackTrace(e);
            }
        }
    }
    
    [NSApp endSheet: addStudiesToUserWindow];
    [addStudiesToUserWindow orderOut: self];
}

-(IBAction)sendEmailNotification:(id)sender
{
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
                    // Add them to selected users AND send a notification email
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
                                
                                if( [studiesArrayStudyInstanceUID indexOfObject: [study valueForKey: @"studyInstanceUID"]] == NSNotFound ||
                                   [studiesArrayPatientUID indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) { if( [obj compare: [study valueForKey: @"patientUID"] options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame) return YES; else return NO;}] == NSNotFound)
                                {
                                    NSManagedObject *studyLink = [NSEntityDescription insertNewObjectForEntityForName: @"Study" inManagedObjectContext: user.managedObjectContext];
                                    
                                    [studyLink setValue: [[[study valueForKey: @"studyInstanceUID"] copy] autorelease] forKey: @"studyInstanceUID"];
                                    [studyLink setValue: [[[study valueForKey: @"patientUID"] copy] autorelease] forKey: @"patientUID"];
                                    [studyLink setValue: [NSDate dateWithTimeIntervalSinceReferenceDate: [[NSUserDefaults standardUserDefaults] doubleForKey: @"lastNotificationsDate"]] forKey: @"dateAdded"];
                                    
                                    [studyLink setValue: user forKey: @"user"];
                                    
                                    @try
                                    {
                                        [[[WebPortal defaultWebPortal] database] save:nil];
                                    }
                                    @catch (NSException * e)
                                    {
                                        N2LogExceptionWithStackTrace(e);
                                    }
                                    
                                    studiesArrayStudyInstanceUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"studyInstanceUID"];
                                    studiesArrayPatientUID = [[[user valueForKey: @"studies"] allObjects] valueForKey: @"patientUID"];
                                    
                                    [[WebPortal defaultWebPortal] updateLogEntryForStudy: study withMessage: @"Add Study to User" forUser: [user valueForKey: @"name"] ip: nil];
                                }
                            }
                        }
                        
                        [[WebPortal defaultWebPortal] sendNotificationsEmailsTo: destinationUsers aboutStudies: [self databaseSelection] predicate: nil customText: self.customTextNotificationEmail];
                    }
                }
                @catch( NSException *e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
            }
            @catch( NSException *e)
            {
                N2LogExceptionWithStackTrace(e);
            }
        }
    }
    
    [NSApp endSheet: notificationEmailWindow];
    [notificationEmailWindow orderOut: self];
#endif
}

-(IBAction)sendMail:(id)sender
{
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
            [[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/zipFilesForMail" withIntermediateDirectories:YES attributes:nil error:NULL];
            
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
                    NSRunAlertPanel(NSLocalizedString(@"Script Failure", @"Title on script failure window."), @"%@ %d", NSLocalizedString(@"OK", @""), nil, nil, NSLocalizedString(@"The script failed:", @"Message on script failure window."), scriptResult);
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
        NSManagedObjectContext *context = self.database.managedObjectContext;
        
        [context lock];
        
        @try
        {
            NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
            [dbRequest setEntity: [[self.database.managedObjectModel entitiesByName] objectForKey:@"Study"]];
            [dbRequest setPredicate: [NSPredicate predicateWithFormat:  @"studyInstanceUID == %@", uid]];
            
            NSError *error = nil;
            NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
            
            if( [studiesArray count])
            {
                DicomStudy *s = [studiesArray lastObject];
                
                NSString *reportURL = nil;
                
                if( [[path pathExtension] length])
                    reportURL = [NSString stringWithFormat: @"%@/%@.%@", [self.database reportsDirPath], [Reports getUniqueFilename: s], [path pathExtension]];
                else
                    reportURL = [NSString stringWithFormat: @"%@/%@", [self.database reportsDirPath], [Reports getUniqueFilename: s]];
                
                [[NSFileManager defaultManager] removeItemAtPath: reportURL error:NULL];
                [[NSFileManager defaultManager] copyPath: path toPath: reportURL handler: nil];
                [s setValue: reportURL forKey: @"reportURL"];
            }
        }
        
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
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
    int a = NSRunInformationalAlertPanel( [dict objectForKey: @"title"], @"%@", [dict objectForKey: @"button1"], [dict objectForKey: @"button2"], [dict objectForKey: @"button3"], [dict objectForKey: @"message"]);
    
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
        DicomDatabase *idatabase = [NSThread isMainThread] ? self.database : self.database.independentDatabase;
        NSString *location = [parameters objectForKey: @"location"];
        NSMutableArray *filesToExport = [parameters objectForKey: @"filesToExport"];
        NSMutableArray *dicomFiles2Export = [NSMutableArray arrayWithArray: [idatabase objectsWithIDs: [parameters objectForKey: @"dicomFiles2Export"]]];
        
        [filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];
        
        NSString			*dest = nil, *path = location;
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
                        extension = @"dcm";
                }
                
                if([extension isEqualToString:@""])
                    extension = @"dcm";
                
                NSString *tempPath;
                // if creating DICOMDIR. Limit length to 8 char
                if (!addDICOMDIR)
                {
                    NSString *name = [curImage valueForKeyPath: @"series.study.name"];
                    
                    if( name.length == 0)
                        name = @"unnamed";
                    
                    tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: name]]];
                }
                else
                {
                    NSMutableString *name;
                    
                    if( [[curImage valueForKeyPath: @"series.study.name"] length] == 0)
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
                    [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
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
                        
                        [self performSelectorOnMainThread: @selector(runInformationAlertPanel:) withObject: options waitUntilDone: YES]; // YES : because we are waiting the result
                        
                        int a;
                        if( [options objectForKey: @"result"])
                            a = [[options objectForKey: @"result"] intValue];
                        else a = NSAlertAlternateReturn; // Cancel
                        
                        if( a == NSAlertDefaultReturn)
                        {
                            [[NSFileManager defaultManager] removeItemAtPath:tempPath error:NULL];
                            [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
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
                    NSString *name = [curImage valueForKeyPath: @"series.study.studyName"];
                    NSString *idstring = [curImage valueForKeyPath: @"series.study.id"];
                    
                    if( name.length == 0)
                        name = @"unnamed";
                    
                    if( idstring == nil)
                        idstring = @"0";
                    
                    NSString *studyId = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: idstring]];
                    NSString *studyName = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: name]];
                    
                    if( studyId == nil || [studyId length] == 0)
                        studyId = @"0";
                    
                    if( studyName.length == 0)
                        studyName = @"unnamed";
                    
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
                        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
                    
                    studyPath = tempPath;
                    
                    NSString *sname = [curImage valueForKeyPath: @"series.name"];
                    if( sname.length == 0)
                        sname = @"series";
                    
                    NSString *seriesName = [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: sname]];
                    
                    NSNumber *seriesId = [curImage valueForKeyPath: @"series.id"];
                    
                    if( seriesId == nil)
                        seriesId = [NSNumber numberWithInt: 0];
                    
                    if( seriesName.length == 0)
                        seriesName = @"unnamed";
                    
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
                        [[NSFileManager defaultManager] createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
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
                    dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, extension];
                else
                    dest = [NSString stringWithFormat:@"%@/%4.4d%4.4d", tempPath, (int) serieCount, (int) imageNo];
                
                int t = 2;
                while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
                {
                    if (!addDICOMDIR)
                        dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, t, extension];
                    else
                        dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath, (int) imageNo, t];
                    t++;
                }
                
                if( t != 2)
                {
                    if (!addDICOMDIR)
                        [renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, extension], @"oldName", [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d-%4.4d.%@", tempPath, (int) serieCount, (int) imageNo, 1, extension], @"newName", nil]];
                    else
                        [renameArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%@/%4.4d%4.4d", tempPath, (int) serieCount, (int) imageNo], @"oldName", [NSString stringWithFormat:@"%@/%4.4d%d", tempPath, (int) imageNo, 1], @"newName", nil]];
                }
                
                NSError *error = nil;
                if( dest == nil || [[NSFileManager defaultManager] copyItemAtPath:[filesToExport objectAtIndex:i] toPath:dest error: &error] == NO)
                {
                    NSLog( @"***** %@", error);
                    NSLog( @"***** src = %@", [filesToExport objectAtIndex:i]);
                    NSLog( @"***** dst = %@", dest);
                }
                
                if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"])
                {
                    switch( [compressionMatrix selectedTag])
                    {
                        case 1: // compress
                            [files2Compress addObject: dest];
                            break;
                            
                        case 2: // decompress
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
                [NSThread currentThread].status = N2LocalizedSingularPluralCount( [filesToExport count]-i, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
                
                if( [splash aborted] || [NSThread currentThread].isCancelled)
                {
                    i = [filesToExport count];
                    exportAborted = YES;
                }
            }
        }
        @catch (NSException * e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [[DicomStudy dbModifyLock] unlock];
        
        for( NSDictionary *d in renameArray)
            [[NSFileManager defaultManager] moveItemAtPath: [d objectForKey: @"oldName"] toPath: [d objectForKey: @"newName"] error: nil];
        
        //close progress window
        [splash close];
        [splash autorelease];
        
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
        
        // ANR - I had to create this loop, otherwise, if I export a folder on the desktop, the dcmkdir will scan all files and folders available on the desktop.... not only the exported folder.
        
#ifndef OSIRIX_LIGHT
        if (addDICOMDIR && exportAborted == NO)
        {
            for( int i = 0; i < [filesToExport count]; i++)
            {
                NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
                NSString *studyName = [curImage valueForKeyPath: @"series.study.name"];
                
                if( studyName.length == 0)
                    studyName = @"unnamed";
                
                NSMutableString *name;
                
                if ([studyName length] > 8)
                    name = [NSMutableString stringWithString:[[studyName substringToIndex:7] uppercaseString]];
                else
                    name = [NSMutableString stringWithString:[studyName uppercaseString]];
                
                NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
                
                [BrowserController replaceNotAdmitted: name];
                
                NSString *tempPath = [path stringByAppendingPathComponent:name];
                
                if( [[NSFileManager defaultManager] fileExistsAtPath: [tempPath stringByAppendingPathComponent:@"DICOMDIR"]] == NO)
                {
                    //					if( [AppController hasMacOSXSnowLeopard] == NO)
                    //					{
                    //						NSRunCriticalAlertPanel( NSLocalizedString( @"DICOMDIR", nil), NSLocalizedString( @"DICOMDIR creation requires MacOS 10.6 or higher. DICOMDIR file will NOT be generated.", nil), NSLocalizedString( @"OK", nil), nil, nil);
                    //					}
                    //					else
                    //					{
                    //						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    //
                    //						NSTask *theTask;
                    //						NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+I",@"+id", tempPath,  nil];
                    //
                    //						theTask = [[NSTask alloc] init];
                    //						[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
                    //						[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmmkdir"]];
                    //						[theTask setCurrentDirectoryPath:tempPath];
                    //						[theTask setArguments:theArguments];
                    //
                    //						[theTask launch];
                    //						while( [theTask isRunning])
                    //                            [NSThread sleepForTimeInterval: 0.1];
                    //
                    //                        //[theTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                    //						[theTask release];
                    //
                    //						[pool release];
                    //					}
                    
                    [NSThread currentThread].status = NSLocalizedString( @"Writing DICOMDIR...", nil);
                    [DicomDir createDicomDirAtDir: tempPath];
                }
            }
        }
#endif
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"encryptForExport"] == YES && exportAborted == NO)
        {
            for( int i = 0; i < [filesToExport count]; i++)
            {
                NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
                
                NSString *studyName = [curImage valueForKeyPath: @"series.study.name"];
                
                if( studyName.length == 0)
                    studyName = @"unnamed";
                
                NSMutableString *name;
                NSString *tempPath;
                
                if( !addDICOMDIR)
                    tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: studyName]]];
                else
                {
                    if ([studyName length] > 8)
                        name = [NSMutableString stringWithString:[[studyName substringToIndex:7] uppercaseString]];
                    else
                        name = [NSMutableString stringWithString:[studyName uppercaseString]];
                    
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
                NSString *studyName = [curImage valueForKeyPath: @"series.study.name"];
                
                if( studyName.length == 0)
                    studyName = @"unnamed";
                
                NSMutableString *name;
                NSString *tempPath;
                
                if( !addDICOMDIR)
                    tempPath = [path stringByAppendingPathComponent: [BrowserController replaceNotAdmitted: [NSMutableString stringWithString: studyName]]];
                else
                {
                    if ([studyName length] > 8)
                        name = [NSMutableString stringWithString:[[studyName substringToIndex:7] uppercaseString]];
                    else
                        name = [NSMutableString stringWithString:[studyName uppercaseString]];
                    
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
        N2LogExceptionWithStackTrace(e);
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
                //				[t waitUntilExit];
                while( [t isRunning]) [NSThread sleepForTimeInterval: 0.01];
                
                free( objs);
            }
            
            i += no;
        }
    }
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    [wait close];
    [wait autorelease];
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
    
    @synchronized (destFile) {
        WaitRendering *wait = nil;
        if( [NSThread isMainThread] && showGUI == YES)
        {
            wait = [[WaitRendering alloc] init: NSLocalizedString(@"Compressing the files...", nil)];
            [wait showWindow:self];
        }
        
        [NSThread currentThread].status = NSLocalizedString( @"Compressing the files...", nil);
        
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
                while( [t isRunning])
                    [NSThread sleepForTimeInterval: 0.1];
                
                //[t waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
                
                if( [t terminationStatus] == 0 && deleteSource == YES)
                {
                    if( srcFolder)
                        [[NSFileManager defaultManager] removeItemAtPath: srcFolder error: nil];
                }
            }
        }
        @catch (NSException *e)
        {
            N2LogExceptionWithStackTrace(e);
        }
        
        [wait close];
        [wait autorelease];
    }
}

#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
- (void) exportROIAndKeyImagesAsDICOMSeries: (id) sender
{
    WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Generating the DICOM files...", nil)];
    [wait showWindow: self];
    
    DICOMExport *exporter = [[[DICOMExport alloc] init] autorelease];
    NSMutableArray *producedFiles = [NSMutableArray array];
    
    [exporter setSeriesDescription: NSLocalizedString( @"ROIs and Key Images", nil)];
    [exporter setSeriesNumber: 0];
    
    NSEvent *event = [[NSApplication sharedApplication] currentEvent];
    NSArray *images = nil;
    if([event modifierFlags] & NSAlternateKeyMask)
        images = [self KeyImages: self];
    else if([event modifierFlags] & NSShiftKeyMask)
        images = [self ROIImages: self];
    else
        images = [self ROIsAndKeyImages: self];
    
    for( DicomImage *image in images)
    {
        NSDictionary *d = [image imageAsDICOMScreenCapture: exporter];
        
        [producedFiles addObject: d];
    }
    
    if( [producedFiles count])
    {
        NSArray *objects = [BrowserController.currentBrowser.database addFilesAtPaths: [producedFiles valueForKey: @"file"]
                                                                    postNotifications: YES
                                                                            dicomOnly: YES
                                                                  rereadExistingItems: YES
                                                                    generatedByOsiriX: YES];
        
        objects = [BrowserController.currentBrowser.database objectsWithIDs: objects];
        
        if( objects.count)
            [self findAndSelectFile: nil image: objects.lastObject shouldExpand: NO];
    }
    
    [wait close];
    [wait autorelease];
}
#endif
#endif

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
                
                predicate = [NSPredicate predicateWithFormat: @"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX No Autodeletion", @"5005"];
                dicomFiles2Export = [[[dicomFiles2Export filteredArrayUsingPredicate: predicate] mutableCopy] autorelease];
                
                predicate = [NSPredicate predicateWithFormat: @"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX WindowsState SR", @"5006"];
                dicomFiles2Export = [[[dicomFiles2Export filteredArrayUsingPredicate: predicate] mutableCopy] autorelease];
            }
            @catch (NSException *e)
            {
                N2LogExceptionWithStackTrace(e);
            }
            
            filesToExport = [[[dicomFiles2Export valueForKey: @"completePath"] mutableCopy] autorelease];
        }
        
        [wait close];
        [wait autorelease];
        
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys: [[sPanel filenames] objectAtIndex:0], @"location", filesToExport, @"filesToExport", [dicomFiles2Export valueForKey: @"objectID"], @"dicomFiles2Export", nil];
        
        NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(exportDICOMFileInt: ) object: d] autorelease];
        t.name = NSLocalizedString( @"Exporting...", nil);
        t.supportsCancel = YES;
        t.status = N2LocalizedSingularPluralCount( [filesToExport count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
        
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        filesToAnonymize = [self filesForDatabaseMatrixSelection: dicomFiles2Anonymize];
    else
        filesToAnonymize = [self filesForDatabaseOutlineSelection: dicomFiles2Anonymize];
    
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
    
    [_sourcesTableView display];
    [_sourcesTableView setNeedsDisplay];
    
    if( attempts == 5)
    {
        NSRunCriticalAlertPanel(NSLocalizedString(@"Failed", nil), NSLocalizedString(@"Unable to unmount this disk. This disk is probably in used by another application.", nil), NSLocalizedString(@"OK",nil),nil, nil);
    }
}

- (void)alternateButtonPressed: (NSNotification*)n
{
    int i = [_sourcesTableView selectedRow];
    if( i > 0)
    {
        NSString *path = [[[bonjourBrowser services] objectAtIndex: i-1] valueForKey:@"Path"];
        
        [self resetToLocalDatabase];
        [self unmountPath: path];
    }
}

#ifndef OSIRIX_LIGHT

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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        files = [self filesForDatabaseMatrixSelection:objects onlyImages: NO];
    else
        files = [self filesForDatabaseOutlineSelection:objects onlyImages: NO];
    
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
    
    [[QueryController currentQueryController] showWindow:self];
    
    // *****
    
    NSIndexSet			*index = [databaseOutline selectedRowIndexes];
    NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
    NSManagedObject		*studySelected;
    
    if (item)
    {
        if ([[item valueForKey: @"type"] isEqualToString:@"Study"])
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
        
        if ([sender tag] == 0 && [QueryController currentQueryController] == nil)
            [[QueryController alloc] initAutoQuery: NO];
        else if ([sender tag] == 1 && [QueryController currentAutoQueryController] == nil)
            [[QueryController alloc] initAutoQuery: YES];
        
        if( [sender tag] == 0)
            [[QueryController currentQueryController] showWindow:self];
        
        if( [sender tag] == 1)
            [[QueryController currentAutoQueryController] showWindow:self];
    }
}
#endif

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
                case 6: spp = 1;
                    numberBytes = 4;
                    highBit = 31;
                    bitsAllocated = 32;
                    isSigned = YES;
                    isLittleEndian = YES;
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
                    [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", (int) i]] forName:@"InstanceNumber"];
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
                    
                    NSString *tempFilename = [[self INCOMINGPATH] stringByAppendingPathComponent: [NSString stringWithFormat:@"%d.dcm", (int) i]];
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
    XMLController * xmlController = [[XMLController alloc] initWithImage: [self firstObjectForDatabaseMatrixSelection]
                                                              windowName:[NSString stringWithFormat: NSLocalizedString( @"Meta-Data: %@", nil), [[self firstObjectForDatabaseMatrixSelection] valueForKey:@"completePath"]]
                                                                  viewer: nil];
    
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
    
    for( int i = 0; i < [filesArray count]; i++)
    {
        NSString *modality = [[filesArray objectAtIndex: i] valueForKey: @"modality"];
        if( [modality isEqualToString: @"RTSTRUCT"])
        {
            DCMObject *dcmObj = [DCMObject objectWithContentsOfFile: [filePaths objectAtIndex: i ] decodingPixelData: NO];
            
            DCMPix *pix = nil;
            @synchronized( previewPixThumbnails)
            {
                pix = [previewPix objectAtIndex: 0];  // Should only be one DCMPix associated w/ an RTSTRUCT
            }
            
            [pix createROIsFromRTSTRUCT: dcmObj];
        }
    }
}
#endif

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
//		if ([[[item valueForKey: @"type"] isEqualToString:@"Study"])
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

- (void) checkReportsDICOMSRConsistency // __deprecated
{
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

- (IBAction) convertReportToDICOMSR: (id)sender
{
    //    [checkBonjourUpToDateThreadLock lock]; // TODO: merge
    
    NSMutableArray *studies = [NSMutableArray array];
    
    for( NSManagedObject *o in [self databaseSelection])
    {
        DicomStudy *study = nil;
        
        if( [[o valueForKey:@"type"] isEqualToString:@"Series"])
            study = [o valueForKey:@"study"];
        else
            study = (DicomStudy*) o;
        
        if( [studies containsObject: study] == NO)
            [studies addObject: study];
    }
    
    NSMutableArray *newDICOMPDFReports = [NSMutableArray array];
    for( DicomStudy *study in studies)
    {
        @try 
        {
            NSString *filename = [self getNewFileDatabasePath: @"dcm"];
            
            [study saveReportAsDicomAtPath: filename];
            
            [newDICOMPDFReports addObject: filename];
        }
        @catch (NSException * e) 
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
            [AppController printStackTrace: e];
        }
        
        [_database addFilesAtPaths: newDICOMPDFReports
                 postNotifications: YES
                         dicomOnly: YES
               rereadExistingItems: YES
                 generatedByOsiriX: YES];
    }
    
    //    [checkBonjourUpToDateThreadLock unlock]; // TODO: merge
    [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
}


- (IBAction) convertReportToPDF: (id)sender
{
    NSIndexSet *index = [databaseOutline selectedRowIndexes];
    NSManagedObject *item = [databaseOutline itemAtRow:[index firstIndex]];
    
    if( item)
    {
        DicomStudy *studySelected;
        
        //		[checkBonjourUpToDateThreadLock lock]; // TODO: merge
        
        @try 
        {			
            if ([[item valueForKey: @"type"] isEqualToString:@"Study"])
                studySelected = (DicomStudy*) item;
            else
                studySelected = [item valueForKey:@"study"];
            
            NSSavePanel *panel = [NSSavePanel savePanel];
            
            [panel setCanSelectHiddenExtension:YES];
            [panel setRequiredFileType: @"pdf"];
            
            NSString *filename = [NSString stringWithFormat: NSLocalizedString( @"%@-Report.pdf", nil), studySelected.name];
            
            if( [panel runModalForDirectory: nil file: filename] == NSFileHandlingPanelOKButton)
            {
                [studySelected saveReportAsPdfAtPath: [panel filename]];
            }
        }
        @catch (NSException * e)
        {
            NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
            [AppController printStackTrace: e];
        }
        
        //		[checkBonjourUpToDateThreadLock unlock]; // TODO: merge
        [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
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
            if ([[item valueForKey: @"type"] isEqualToString:@"Study"])
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
                        
                        [PluginManager startProtectForCrashWithFilter: filter];
                        [filter deleteReportForStudy: studySelected];
                        [PluginManager endProtectForCrash];
                        
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
                        [[NSFileManager defaultManager] removeItemAtPath: [studySelected valueForKey:@"reportURL"] error:NULL];
                    
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
            N2LogExceptionWithStackTrace(e);
        }
        
        //		[checkBonjourUpToDateThreadLock unlock];
        [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];
    }
}

#ifndef OSIRIX_LIGHT
- (IBAction) generateReport: (id)sender
{
    NSIndexSet *index = [databaseOutline selectedRowIndexes];
    NSManagedObject *item = [databaseOutline itemAtRow:[index firstIndex]];
    int reportsMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue];
    
    if ([item isKindOfClass:[DicomSeries class]])
        item = [item valueForKey:@"study"];
    
    if( item)
    {
        [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_HOROS_REPORT_REQUESTED detail:[NSString stringWithFormat:@"{\"reportsMode\": \"%d\"}",reportsMode]];
        
        if( reportsMode == 0 && [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"] == nil) // Would absolutePathForAppBundleWithIdentifier be better here? (DDP)
        {
            NSRunAlertPanel( NSLocalizedString(@"Report Error", nil), NSLocalizedString(@"Microsoft Word is required to open/generate '.doc' reports. You can change it to TextEdit in the Preferences.", nil), nil, nil, nil);
            return;
        }
        
        DicomStudy *studySelected = nil;
        
        if ([[item valueForKey: @"type"] isEqualToString:@"Study"])
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
                        
                        [PluginManager startProtectForCrashWithFilter: filter];
                        [filter createReportForStudy: studySelected];
                        [PluginManager endProtectForCrash];
                        
                        NSLog(@"end generate report with plugin");
                        //[filter report: studySelected action: @"openReport"];
                    }
                    @catch (NSException * e) 
                    {
                        N2LogExceptionWithStackTrace(e);
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
                        NSLog( @"New report for: %@", [studySelected valueForKey: @"name"]);
                        
                        if (reportsMode != 3)
                        {
                            Reports	*report = [[Reports alloc] init];
                            if ([[sender class] isEqualTo:[reportTemplatesListPopUpButton class]])
                                [report setTemplateName:[[sender selectedItem] title]];
                            
                            if (![_database isLocal])
                                [report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/TEMP.noindex/", [self documentsDirectory]] type:reportsMode];
                            else
                                [report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/", [self.database reportsDirPath]] type:reportsMode];
                            
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
                    N2LogExceptionWithStackTrace(e);
                }
                
                //				[checkBonjourUpToDateThreadLock unlock];
            }
        }
    }
    
    [self performSelector: @selector(updateReportToolbarIcon:) withObject: nil afterDelay: 0.1];	
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
            //	OpenOffice.app / LibreOffice.app
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
        NSMutableArray* templatesArray = nil;
        switch ([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]) {
            case 2:
                templatesArray = [Reports pagesTemplatesList];
                break;
            case 0:
                templatesArray = [Reports wordTemplatesList];
                break;
        }
        
        NSIndexSet* index = [databaseOutline selectedRowIndexes];
        NSManagedObject	*selectedItem = [databaseOutline itemAtRow:[index firstIndex]];
        DicomStudy* studySelected;
        if ([[selectedItem valueForKey: @"type"] isEqualToString:@"Study"])
            studySelected = (DicomStudy*)selectedItem;
        else
            studySelected = [selectedItem valueForKey:@"study"];
        
        if (!studySelected.reportURL && templatesArray.count > 1)
        {
            switch ([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]) {
                case 2:
                    [reportTemplatesImageView setImage:[NSImage imageNamed:@"ReportPages"]];
                    break;
                case 0:
                    [reportTemplatesImageView setImage:[NSImage imageNamed:@"ReportWord"]];
                    break;
            }
            
            [item setView: reportTemplatesView];
            
            [item setMinSize: NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
            [item setMaxSize: NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
            
            reportToolbarItemType = -1;
        }
        else
        {
            NSImage* icon = nil;
            
            if (studySelected.reportURL)
            {
                if ([studySelected.reportURL hasPrefix: @"http://"] || [studySelected.reportURL hasPrefix: @"https://"])
                    icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"download"]; // Safari document
                else if ([[NSFileManager defaultManager] fileExistsAtPath:studySelected.reportURL])
                    icon = [[NSWorkspace sharedWorkspace] iconForFile:studySelected.reportURL];
                if (icon)
                    reportToolbarItemType = [NSDate timeIntervalSinceReferenceDate]; // To force the update
            }
            
            if (!icon)
                icon = [self reportIcon];	// Keep this line! Because item can be nil! see updateReportToolbarIcon function
            
            [item setImage:icon];
        }
#else
        [item setImage:[NSImage imageNamed:@"Report.icns"]];
#endif
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
}


- (void)reportToolbarItemWillPopUp: (NSNotification *)notif
{
#ifndef OSIRIX_LIGHT
    if ([[notif object] isEqualTo:reportTemplatesListPopUpButton])
    {
        [reportTemplatesListPopUpButton removeAllItems];
        [reportTemplatesListPopUpButton addItemWithTitle:@""];
        
        switch ([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]) {
            case 2:
                [reportTemplatesListPopUpButton addItemsWithTitles:[Reports pagesTemplatesList]];
                break;
            case 0:
                [reportTemplatesListPopUpButton addItemsWithTitles:[Reports wordTemplatesList]];
                break;
        }
        
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
    [self flagsChanged:[NSApp currentEvent]];
    
    @synchronized (_albumNoOfStudiesCache)
    {
        if (_albumNoOfStudiesCache.count == 0)
            [self refreshAlbums];
    }
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
        
        if( [[toolbarItem itemIdentifier] isEqualToString: ExportROIAndKeyImagesToolbarItemIdentifier])
        {
            if([event modifierFlags] & NSAlternateKeyMask)
            {
                [toolbarItem setImage: [NSImage imageNamed: ExportROIAndKeyImagesToolbarItemIdentifier]];
                [toolbarItem setAction: @selector(exportROIAndKeyImagesAsDICOMSeries:)];
                
                [toolbarItem setLabel: NSLocalizedString(@"Export Keys", nil)];
                [toolbarItem setPaletteLabel: NSLocalizedString(@"Export Keys", nil)];
                [toolbarItem setToolTip: NSLocalizedString(@"Export Key images of selected study/series as a DICOM Series", nil)];
            }
            else if([event modifierFlags] & NSShiftKeyMask)
            {
                [toolbarItem setImage: [NSImage imageNamed: ExportROIAndKeyImagesToolbarItemIdentifier]];
                [toolbarItem setAction: @selector(exportROIAndKeyImagesAsDICOMSeries:)];
                
                [toolbarItem setLabel: NSLocalizedString(@"Export ROIs", nil)];
                [toolbarItem setPaletteLabel: NSLocalizedString(@"Export ROIs", nil)];
                [toolbarItem setToolTip: NSLocalizedString(@"Export ROI images of selected study/series as a DICOM Series", nil)];
            }
            else
            {
                [toolbarItem setImage: [NSImage imageNamed: ExportROIAndKeyImagesToolbarItemIdentifier]];
                [toolbarItem setAction: @selector(exportROIAndKeyImagesAsDICOMSeries:)];
                
                [toolbarItem setLabel: NSLocalizedString(@"Export ROIs & Keys", nil)];
                [toolbarItem setPaletteLabel: NSLocalizedString(@"Export ROIs & Keys", nil)];
                [toolbarItem setToolTip: NSLocalizedString(@"Export ROI and Key images of selected study/series as a DICOM Series", nil)];
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
                    if( [item respondsToSelector:@selector(setRecursiveEnabled:)])
                        [item setRecursiveEnabled: YES];
                    else if( [[item view] respondsToSelector:@selector(setRecursiveEnabled:)])
                        [[item view] setRecursiveEnabled: YES];
                    else if( item)
                        NSLog( @"%@", item);
                    
                    im = [[item view] screenshotByCreatingPDF];
                }
                @catch (NSException * e)
                {
                    N2LogExceptionWithStackTrace(e);
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
            N2LogExceptionWithStackTrace(e);
        }
    }
#endif
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
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
        [toolbarItem setAction: @selector(exportQuicktime:)];
    }
    else if ([itemIdent isEqualToString: WebServerSingleNotification])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Notification", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Notification", nil)];
        [toolbarItem setImage: [NSImage imageNamed: WebServerSingleNotification]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(sendEmailNotification:)];
    }
    else if ([itemIdent isEqualToString: AddStudiesToUserItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Add Studies", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Add Studies", nil)];
        [toolbarItem setImage: [NSImage imageNamed: AddStudiesToUserItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(addStudiesToUser:)];
    }
    else if ([itemIdent isEqualToString: MailToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Email", nil)];
        [toolbarItem setImage: [NSImage imageNamed: MailToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(sendMail:)];
    }
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export selected study/series to a DICOM folder", nil)];
        [toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(exportDICOMFile:)];
    }
    else if ([itemIdent isEqualToString: ExportROIAndKeyImagesToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Export ROIs & Keys",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Export ROIs & Keys",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Export ROI and Key images of selected study/series as a DICOM Series", nil)];
        [toolbarItem setImage: [NSImage imageNamed: ExportROIAndKeyImagesToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(exportROIAndKeyImagesAsDICOMSeries:)];
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
        [toolbarItem setToolTip: NSLocalizedString(@"Anonymize selected study/series to a DICOM folder", nil)];
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
    else if ([itemIdent isEqualToString: ViewerToolbarItemIdentifier])
    {
        
        [toolbarItem setLabel: NSLocalizedString(@"2D Viewer",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"2D Viewer",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"View selected study/series",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ViewerToolbarItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(viewerDICOM:)];
    } 
    //	else if ([itemIdent isEqualToString: CDRomToolbarItemIdentifier])
    //	{
    //        
    //		[toolbarItem setLabel: NSLocalizedString(@"CD-Rom",nil)];
    //		[toolbarItem setPaletteLabel: NSLocalizedString(@"CD-Rom",nil)];
    //        [toolbarItem setToolTip: NSLocalizedString(@"Load images from current DICOM CD-Rom",nil)];
    //		[toolbarItem setImage: [NSImage imageNamed: CDRomToolbarItemIdentifier]];
    //		[toolbarItem setTarget: self];
    //		[toolbarItem setAction: @selector(ReadDicomCDRom:)];
    //    }
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
        [toolbarItem setMinSize:NSMakeSize(NSWidth([searchView frame]), NSHeight([searchView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([searchView frame])+100, NSHeight([searchView frame]))];
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
    else if ([itemIdent isEqualToString: ModalityFilterToolbarItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Modality", nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Modality", nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Modality", nil)];
        
        // Use a custom view, a text field, for the search item
        [toolbarItem setView: modalityFilterView];
        [toolbarItem setMinSize:NSMakeSize(NSWidth([modalityFilterView frame]), NSHeight([modalityFilterView frame]))];
        [toolbarItem setMaxSize:NSMakeSize(NSWidth([modalityFilterView frame]), NSHeight([modalityFilterView frame]))];
    }
    else if ([itemIdent isEqualToString: ResetSplitViewsItemIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Restore Views",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Restore Views",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Restore Views To Original State",nil)];
        [toolbarItem setImage: [NSImage imageNamed: ResetSplitViewsItemIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(restoreWindowState:)];
    }
    else if ([itemIdent isEqualToString: HorosMigrationAssistantIdentifier])
    {
        [toolbarItem setLabel: NSLocalizedString(@"Migration Assistant",nil)];
        [toolbarItem setPaletteLabel: NSLocalizedString(@"Migration Assistant",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Open Horos Migration Assistant",nil)];
        [toolbarItem setImage: [NSImage imageNamed: HorosMigrationAssistantIdentifier]];
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(openHorosMigrationAssistant:)];
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
        
        for (id key in [PluginManager plugins])
        {
            if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarItemForItemIdentifier:forBrowserController:)])
            {
                NSToolbarItem *item = [[[PluginManager plugins] objectForKey:key] toolbarItemForItemIdentifier: itemIdent forBrowserController: self];
                
                if( item)
                    toolbarItem = item;
            }
        }
    }
    
    return toolbarItem;
}


- (void) openHorosMigrationAssistant:(id) sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"O2H_MIGRATION_USER_ACTION"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if ([O2HMigrationAssistant isOsiriXInstalled] == NO)
    {
        NSRunInformationalAlertPanel(NSLocalizedString(@"Horos Migration Assistant", nil),
                                     NSLocalizedString(@"It seems you don't have OsiriX installed.", nil),
                                     NSLocalizedString(@"Return",nil), nil, nil);
        return;
    }
    
    [O2HMigrationAssistant performStartupO2HTasks:self];
}


- (void)spaceEvenly:(NSSplitView *)splitView
{
    // get the subviews of the split view
    NSArray *subviews = [splitView subviews];
    unsigned int n = [subviews count];
    
    // compute the new height of each subview
    float divider = [splitView dividerThickness];
    float height = ([splitView bounds].size.height - (n - 1) * divider) / n;
    
    // adjust the frames of all subviews
    float y = 0;
    NSView *subview;
    NSEnumerator *e = [subviews objectEnumerator];
    while ((subview = [e nextObject]) != nil)
    {
        NSRect frame = [subview frame];
        frame.origin.y = rintf(y);
        frame.size.height = rintf(y + height) - frame.origin.y;
        [subview setFrame:frame];
        y += height + divider;
    }
    
    // have the AppKit redraw the dividers
    [splitView adjustSubviews];
}


- (void) restoreWindowState:(id) sender
{
    NSView* left = [[splitDrawer subviews] objectAtIndex:0];
    [left setHidden:NO];
    NSRect f = left.frame;
    f.size.width  = 192;
    [left setFrame:f];
    
    
    [splitDrawer setHidden:NO];
    [self spaceEvenly:splitDrawer];
    
    [splitAlbums setHidden:NO];
    [self spaceEvenly:splitAlbums];
    [splitViewHorz setHidden:NO];
    [self spaceEvenly:splitViewHorz];
    [splitComparative setHidden:NO];
    [self spaceEvenly:splitComparative];
    [splitViewHorz setHidden:NO];
    [self spaceEvenly:splitViewVert];
    
    [splitDrawer saveDefault: @"SplitDrawer"];
    [splitAlbums saveDefault: @"SplitAlbums"];
    [splitViewHorz saveDefault: @"SplitHorz2"];
    [splitComparative saveDefault: @"SplitComparative"];
    [splitViewVert saveDefault: @"SplitVert2"];
    
    /*
    [splitDrawer restoreDefault: @"SplitDrawer"];
    [splitAlbums restoreDefault: @"SplitAlbums"];
    [splitViewHorz restoreDefault: @"SplitHorz2"];
    [splitComparative restoreDefault: @"SplitComparative"];
    [splitViewVert restoreDefault: @"SplitVert2"];
    
    for (NSView* _view in [splitDrawer subviews])
    {
        [_view setHidden:NO];
        [splitDrawer resizeSubviewsWithOldSize:splitDrawer.bounds.size];
    }
    
    for (NSView* _view in [splitAlbums subviews])
    {
        [_view setHidden:NO];
        [splitAlbums resizeSubviewsWithOldSize:splitAlbums.bounds.size];
    }

    for (NSView* _view in [splitViewHorz subviews])
    {
        [_view setHidden:NO];
        [splitViewHorz resizeSubviewsWithOldSize:splitViewHorz.bounds.size];
    }
    
    for (NSView* _view in [splitComparative subviews])
    {
        [_view setHidden:NO];
        [splitComparative resizeSubviewsWithOldSize:splitComparative.bounds.size];
    }
    
    for (NSView* _view in [splitViewVert subviews])
    {
        [_view setHidden:NO];
        [splitViewVert resizeSubviewsWithOldSize:splitViewVert.bounds.size];
    }
    
    [splitDrawer saveDefault: @"SplitDrawer"];
    [splitAlbums saveDefault: @"SplitAlbums"];
    [splitViewHorz saveDefault: @"SplitHorz2"];
    [splitComparative saveDefault: @"SplitComparative"];
    [splitViewVert saveDefault: @"SplitVert2"];
     */
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            //          ToggleDrawerToolbarItemIdentifier, // removed from default items because we have a dedicated button on the bottom left of this window
            ImportToolbarItemIdentifier,
            ExportToolbarItemIdentifier,
            MailToolbarItemIdentifier,
            QTSaveToolbarItemIdentifier,
            QueryToolbarItemIdentifier,
            SendToolbarItemIdentifier,
            AnonymizerToolbarItemIdentifier,
            BurnerToolbarItemIdentifier,
            XMLToolbarItemIdentifier,
            TrashToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            ViewersToolbarItemIdentifier,
            ViewerToolbarItemIdentifier,
            OpenKeyImagesAndROIsToolbarItemIdentifier,
            MovieToolbarItemIdentifier,
            ReportToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            TimeIntervalToolbarItemIdentifier,
            ModalityFilterToolbarItemIdentifier,
            SearchToolbarItemIdentifier,
            nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{	
    NSMutableArray *array = [NSMutableArray arrayWithObjects:
                             ViewersToolbarItemIdentifier,
                             SearchToolbarItemIdentifier,
                             TimeIntervalToolbarItemIdentifier,
                             ModalityFilterToolbarItemIdentifier,
                             NSToolbarCustomizeToolbarItemIdentifier,
                             NSToolbarFlexibleSpaceItemIdentifier,
                             NSToolbarSpaceItemIdentifier,
                             NSToolbarSeparatorItemIdentifier,
                             ImportToolbarItemIdentifier,
                             //			 CDRomToolbarItemIdentifier,
                             MailToolbarItemIdentifier,
                             WebServerSingleNotification,
                             AddStudiesToUserItemIdentifier,
                             QTSaveToolbarItemIdentifier,
                             QueryToolbarItemIdentifier,
                             ExportToolbarItemIdentifier,
                             ExportROIAndKeyImagesToolbarItemIdentifier,
                             AnonymizerToolbarItemIdentifier,
                             SendToolbarItemIdentifier,
                             ViewerToolbarItemIdentifier,
                             OpenKeyImagesAndROIsToolbarItemIdentifier,
                             MovieToolbarItemIdentifier,
                             BurnerToolbarItemIdentifier,
                             XMLToolbarItemIdentifier,
                             TrashToolbarItemIdentifier,
                             ReportToolbarItemIdentifier,
                             ToggleDrawerToolbarItemIdentifier,
                             ResetSplitViewsItemIdentifier,
                             HorosMigrationAssistantIdentifier,
                             nil];
    
    NSArray*		allPlugins = [[PluginManager pluginsDict] allKeys];
    NSMutableSet*	pluginsItems = [NSMutableSet setWithCapacity: [allPlugins count]];
    
    for( NSString *plugin in allPlugins)
    {
        if ([plugin isEqualToString: @"(-"])
            continue;
        
        NSBundle		*bundle = [[PluginManager pluginsDict] objectForKey: plugin];
        NSDictionary	*info = [bundle infoDictionary];
        
        if( [[info objectForKey: @"pluginType"] isEqualToString: @"Database"])
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
        [array addObjectsFromArray: [pluginsItems allObjects]];
    
    for (id key in [PluginManager plugins])
    {
        if ([[[PluginManager plugins] objectForKey:key] respondsToSelector:@selector(toolbarAllowedIdentifiersForBrowserController:)])
            [array addObjectsFromArray: [[[PluginManager plugins] objectForKey:key] toolbarAllowedIdentifiersForBrowserController: self]];
    }
    
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        [self filesForDatabaseMatrixSelection: selectedItems];
    else
        [self filesForDatabaseOutlineSelection: selectedItems];
    
    if( [selectedItems isEqual: lastROIsAndKeyImagesSelectedFiles] && ROIsAndKeyImagesCache)
    {
        if( sameSeries)
            *sameSeries = ROIsAndKeyImagesCacheSameSeries;
        
        return ROIsAndKeyImagesCache;
    }
    
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
                N2LogExceptionWithStackTrace(e);
            }
        }
        
        NSManagedObject *series = [[roisImagesArray lastObject] valueForKey: @"series"];
        
        ROIsAndKeyImagesCacheSameSeries = YES;
        if( sameSeries)
            *sameSeries = ROIsAndKeyImagesCacheSameSeries;
        
        for( DicomImage *image in roisImagesArray)
        {
            if( [image valueForKey: @"series"] != series)
            {
                ROIsAndKeyImagesCacheSameSeries = NO;
                if( sameSeries)
                    *sameSeries = ROIsAndKeyImagesCacheSameSeries;
                break;
            }
        }
    }
    
    [ROIsAndKeyImagesCache release];
    ROIsAndKeyImagesCache = [roisImagesArray retain];
    
    [lastROIsAndKeyImagesSelectedFiles release];
    lastROIsAndKeyImagesSelectedFiles = [selectedItems retain];
    
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
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        [self filesForDatabaseMatrixSelection: selectedItems];
    else
        [self filesForDatabaseOutlineSelection: selectedItems];
    
    if( [selectedItems isEqual: lastROIsImagesSelectedFiles] && ROIsImagesCache)
    {
        if( sameSeries)
            *sameSeries = ROIsImagesCacheSameSeries;
        
        return ROIsImagesCache;
    }
    
    NSMutableArray *roisImagesArray = [NSMutableArray array];
    
    if( [selectedItems count] > 0)
    {
        for( DicomImage *image in selectedItems)
        {
            NSString *str = [image.series.study roiPathForImage: image];
            
            @try {
                if( str && [[NSUnarchiver unarchiveObjectWithData: [SRAnnotation roiFromDICOM: str]] count] > 0)
                    [roisImagesArray addObject: image];
            }
            @catch (NSException *exception) {
                N2LogException( exception);
            }
        }
        
        NSManagedObject *series = [[roisImagesArray lastObject] valueForKey: @"series"];
        
        ROIsImagesCacheSameSeries = YES;
        if( sameSeries)
            *sameSeries = ROIsImagesCacheSameSeries;
        for( DicomImage *image in roisImagesArray)
        {
            if( [image valueForKey: @"series"] != series)
            {
                ROIsImagesCacheSameSeries = NO;
                if( sameSeries)
                    *sameSeries = ROIsImagesCacheSameSeries;
                break;
            }
        }
    }
    
    [ROIsImagesCache release];
    ROIsImagesCache = [roisImagesArray retain];
    
    [lastROIsImagesSelectedFiles release];
    lastROIsImagesSelectedFiles = [selectedItems retain];
    
    return roisImagesArray;
}

- (NSArray*) ROIImages: (id) sender
{
    return [self ROIImages: sender sameSeries: nil];
}

- (NSArray*) KeyImages: (id) sender
{
    NSMutableArray *selectedItems = [NSMutableArray array];
    
    if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
        [self filesForDatabaseMatrixSelection: selectedItems];
    else
        [self filesForDatabaseOutlineSelection: selectedItems];
    
    if( [selectedItems isEqual: lastKeyImagesSelectedFiles] && KeyImagesCache)
        return KeyImagesCache;
    
    NSMutableArray *keyImagesArray = [NSMutableArray array];
    
    for( NSManagedObject *image in selectedItems)
    {
        if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
            [keyImagesArray addObject: image];
    }
    
    [KeyImagesCache release];
    KeyImagesCache = [keyImagesArray retain];
    
    [lastKeyImagesSelectedFiles release];
    lastKeyImagesSelectedFiles = [selectedItems retain];
    
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
    
    BOOL containsDistantStudy = NO;
    
    if( [[databaseOutline selectedRowIndexes] count] > 0)
    {
        NSUInteger idx = databaseOutline.selectedRowIndexes.firstIndex;
        
        while (idx != NSNotFound)
        {
            id object = [databaseOutline itemAtRow: idx];
            
            if( [object isDistant])
            {
                containsDistantStudy = YES;
                break;
            }
            
            idx = [databaseOutline.selectedRowIndexes indexGreaterThanIndex:idx];
        }
    }
    
    if ([self.database isReadOnly])
    {
        if ([toolbarItem.itemIdentifier isEqualToString:ImportToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:WebServerSingleNotification] || 
            [toolbarItem.itemIdentifier isEqualToString:AddStudiesToUserItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:AnonymizerToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:TrashToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:ReportToolbarItemIdentifier] || // TODO: if report already exists, allow user to view it
            [toolbarItem.itemIdentifier isEqualToString:BurnerToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:AddStudiesToUserItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:QueryToolbarItemIdentifier]
            )
            return NO;
    }
    
    if( containsDistantStudy)
    {
        if ([toolbarItem.itemIdentifier isEqualToString:WebServerSingleNotification] || 
            [toolbarItem.itemIdentifier isEqualToString:AddStudiesToUserItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:AnonymizerToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:TrashToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:ReportToolbarItemIdentifier] ||
            [toolbarItem.itemIdentifier isEqualToString:BurnerToolbarItemIdentifier] || 
            [toolbarItem.itemIdentifier isEqualToString:AddStudiesToUserItemIdentifier]
            )
            return NO;
    }
    
    if( [[databaseOutline selectedRowIndexes] count] < 1 || containsDistantStudy) // No Database Selection
    {
        if( containsDistantStudy == YES && [toolbarItem action] == @selector(querySelectedStudy:))
            return YES;
        
        if(	[toolbarItem action] == @selector(rebuildThumbnails:) ||
           [toolbarItem action] == @selector(searchForCurrentPatient:) || 
           [toolbarItem action] == @selector(viewerDICOM:) || 
           [toolbarItem action] == @selector(viewerSubSeriesDICOM:) || 
           [toolbarItem action] == @selector(viewerReparsedSeries:) ||
           [toolbarItem action] == @selector(MovieViewerDICOM:) || 
           [toolbarItem action] == @selector(viewerDICOMMergeSelection:) || 
           [toolbarItem action] == @selector(revealInFinder:) || 
           [toolbarItem action] == @selector(export2PACS:) || 
           [toolbarItem action] == @selector(exportQuicktime:) || 
           [toolbarItem action] == @selector(exportJPEG:) || 
           [toolbarItem action] == @selector(exportTIFF:) || 
           [toolbarItem action] == @selector(exportDICOMFile:) ||
           [toolbarItem action] == @selector(exportROIAndKeyImagesAsDICOMSeries:) ||
           [toolbarItem action] == @selector(sendMail:) || 
           [toolbarItem action] == @selector(addStudiesToUser:) || 
           [toolbarItem action] == @selector(sendEmailNotification:) || 
           [toolbarItem action] == @selector(compressSelectedFiles:) || 
           [toolbarItem action] == @selector(decompressSelectedFiles:) || 
           [toolbarItem action] == @selector(generateReport:) || 
           [toolbarItem action] == @selector(deleteReport:) || 
           [toolbarItem action] == @selector(convertReportToPDF:) ||
           [toolbarItem action] == @selector(convertReportToDICOMSR:) ||
           [toolbarItem action] == @selector(delItem:) || 
           [toolbarItem action] == @selector(querySelectedStudy:) || 
           [toolbarItem action] == @selector(burnDICOM:) || 
           [toolbarItem action] == @selector(viewXML:) || 
           [toolbarItem action] == @selector(anonymizeDICOM:) || 
           [toolbarItem action] == @selector(applyRoutingRule:) ||
           [toolbarItem action] == @selector(viewerSubSeriesDICOM:) ||
           [toolbarItem action] == @selector(viewerReparsedSeries:)
           )
            return NO;
    }
    
    if (![_database isLocal])
    {
        if ([[toolbarItem itemIdentifier] isEqualToString: ImportToolbarItemIdentifier]) return NO;
        if ([[toolbarItem itemIdentifier] isEqualToString: TrashToolbarItemIdentifier]) return NO;
        if ([[toolbarItem itemIdentifier] isEqualToString: QueryToolbarItemIdentifier]) return NO;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: OpenKeyImagesAndROIsToolbarItemIdentifier])
    {
        if( containsDistantStudy)
            return NO;
        
        return ROIsAndKeyImagesButtonAvailable;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: ExportROIAndKeyImagesToolbarItemIdentifier])
    {
        if( containsDistantStudy)
            return NO;
        
        return ROIsAndKeyImagesButtonAvailable;
    }
    
    if ([[toolbarItem itemIdentifier] isEqualToString: ViewersToolbarItemIdentifier])
    {
        if( [ViewerController numberOf2DViewer] >= 1) return YES;
        else return NO;
    }
    
    if( [[toolbarItem itemIdentifier] isEqualToString: WebServerSingleNotification])
    {
        if( containsDistantStudy)
            return NO;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpWebServer"]  == NO || [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"] == NO)
            return NO;
    }
    
    if( [[toolbarItem itemIdentifier] isEqualToString: AddStudiesToUserItemIdentifier])
    {
        if( containsDistantStudy)
            return NO;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"httpWebServer"]  == NO || [[NSUserDefaults standardUserDefaults] boolForKey: @"passwordWebServer"] == NO)
            return NO;
    }
    
    return YES;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Bonjour

- (void)setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key // __deprecated
{
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
    if (![_database isLocal]) return [(RemoteDicomDatabase*)_database cacheDataForImage:(DicomImage*)obj maxFiles:no];
    else return [obj valueForKey:@"completePath"];
}

- (void)displayBonjourServices
{
    [_sourcesTableView reloadData];
}

- (void) switchToDefaultDBIfNeeded // __deprecated
{
    NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
    
    if( [[self documentsDirectory] isEqualToString: defaultPath] == NO)
        [self resetToLocalDatabase];
}

- (void)openDatabasePath: (NSString*)path
{
    NSThread* thread = [NSThread currentThread];
    [thread setName:NSLocalizedString(@"Opening database...", nil)];
    ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
    
    @try
    {
        DicomDatabase* db = [DicomDatabase databaseAtPath:path];
        if( db)
            [self setDatabase:db];
        else
            [NSException raise:NSGenericException format: @"DicomDatabase == nil"];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
        NSRunAlertPanel(NSLocalizedString(@"Horos Database", nil), NSLocalizedString( @"Horos cannot read/create this file/folder. Permissions error?", nil), nil, nil, nil);
        [self resetToLocalDatabase];
    }
    
    [tmc invalidate];
}


- (NSString*) localDatabasePath { // deprecated
    return [[DicomDatabase activeLocalDatabase] sqlFilePath];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Plugins

- (void)executeFilterFromString: (NSString*)name
{
    id filter = [[PluginManager plugins] objectForKey:name];
    
    if( filter == nil)
    {
        NSRunAlertPanel( NSLocalizedString( @"Plugins Error", nil), NSLocalizedString( @"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
        return;
    }
    
    [PluginManager startProtectForCrashWithFilter: filter];
    
    [[HorosHomePhone sharedHomePhone] callHomeInformingFunctionType:HOME_PHONE_PLUGIN_LAUNCHED detail:[NSString stringWithFormat:@"{\"PluginName\": \"%@\"}",name]];
    
    long result = [filter prepareFilter: nil];
    [filter filterImage: name];
    
    if( result)
    {
        NSRunAlertPanel( NSLocalizedString( @"Plugins Error", nil), NSLocalizedString( @"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
    }
    
    [PluginManager endProtectForCrash];
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
- (NSString *)setFixedDocumentsDirectory // __deprecated
{
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

- (NSString *) localDocumentsDirectory // __deprecated
{
    return [[DicomDatabase activeLocalDatabase] baseDirPath];
}

- (NSString *) fixedDocumentsDirectory // __deprecated
{
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

- (NSString*)INCOMINGPATH // __deprecated
{
    return [_database incomingDirPath];
}

+ (NSString *) defaultDocumentsDirectory // __deprecated
{
    //	NSString *dir = documentsDirectory();
    return [[DicomDatabase defaultDatabase] baseDirPath];
}

- (NSString*) TEMPPATH // __deprecated
{
    return [_database tempDirPath];
}

- (NSString*)documentsDirectory // __deprecated
{
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
    
    if( _searchString != searchString)
    {
        [_searchString release];
        _searchString = [searchString retain];
    }
    
    self.distantSearchString = nil;
    self.distantSearchType = searchType;
    
    [self setFilterPredicate:[self createFilterPredicate] description:[self createFilterDescription]];
    [self outlineViewRefresh];
    [databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
    
    if( _searchString.length > 2 || (_searchString.length >= 2 && searchType == 5))
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
        
        [NSThread detachNewThreadSelector: @selector(searchForSearchField:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: searchType], @"searchType", _searchString, @"searchString", [NSNumber numberWithInt: albumTable.selectedRow], @"selectedAlbumIndex", nil]];
    }
    else if( timeIntervalStart || timeIntervalEnd)
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
        
        if( albumTable.selectedRow == 0)
            [NSThread detachNewThreadSelector: @selector(searchForTimeIntervalFromTo:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: timeIntervalStart, @"from", timeIntervalEnd, @"to", nil]];
    }
    else
    {
        @synchronized( self)
        {
            [distantSearchThread cancel];
            [distantSearchThread release];
            distantSearchThread = nil;
        }
    }
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
    
    if( [_searchString length] > 0)
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

- (NSPredicate*) patientsnamePredicate: (NSString*) s
{
    return [self patientsnamePredicate: s soundex: [[NSUserDefaults standardUserDefaults] boolForKey: @"useSoundexForName"]];
}

- (NSPredicate*) patientsnamePredicate: (NSString*) s soundex:(BOOL) soundex
{
    s = [s stringByReplacingOccurrencesOfString: @"^" withString: @" "];
    s = [s stringByReplacingOccurrencesOfString: @", " withString: @" "];
    s = [s stringByReplacingOccurrencesOfString: @"," withString: @" "];
    
    NSMutableArray *predicates = [NSMutableArray array];
    
    @try {
        BOOL firstComponent = YES;
        NSArray *nameComponents = [s componentsSeparatedByString: @" "];
        
        for( NSString *component in nameComponents)
        {
            NSPredicate *p = nil;
            
            while( [component hasPrefix: @"*"])
            {
                component = [component substringFromIndex: 1];
                firstComponent = NO;
            }
            
            while( [component hasSuffix: @"*"])
                component = [component substringToIndex: component.length-1];
            
            if( firstComponent == NO)
            {
                if( soundex && [component length] >= 2)
                    p = [NSPredicate predicateWithFormat: @"(soundex CONTAINS[cd] %@) OR (name CONTAINS[cd] %@)", [DicomStudy soundex: component], component];
                else
                    p = [NSPredicate predicateWithFormat: @"name CONTAINS[cd] %@", component];
            }
            else
            {
                if( soundex && [component length] >= 2)
                    p = [NSPredicate predicateWithFormat: @"(soundex BEGINSWITH[cd] %@) OR (name BEGINSWITH[cd] %@)", [DicomStudy soundex: component], component];
                else
                    p = [NSPredicate predicateWithFormat: @"name BEGINSWITH[cd] %@", component];
            }
            
            if( p)
                [predicates addObject: p];
            
            firstComponent = NO;
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates: predicates];
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
                s = _searchString;
                
                if( [s length] >= 3)
                    predicate = [NSPredicate predicateWithFormat: @"(name CONTAINS[cd] %@) OR (patientID CONTAINS[cd] %@) OR (id CONTAINS[cd] %@) OR (comment CONTAINS[cd] %@) OR (comment2 CONTAINS[cd] %@) OR (comment3 CONTAINS[cd] %@) OR (comment4 CONTAINS[cd] %@) OR (studyName CONTAINS[cd] %@) OR (modality CONTAINS[cd] %@) OR (accessionNumber CONTAINS[cd] %@) OR (performingPhysician CONTAINS[cd] %@) OR (referringPhysician CONTAINS[cd] %@) OR (institutionName CONTAINS[cd] %@)", s, s, s, s, s, s, s, s, s, s, s, s, s];
                else if( [s length] >= 1)
                    predicate = [self patientsnamePredicate: _searchString];
                break;
                
            case 0:			// Patient Name
                predicate = [self patientsnamePredicate: _searchString];
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
                predicate = [NSPredicate predicateWithFormat: @"modality CONTAINS[cd] %@", _searchString];
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
    NSMutableArray* selectedItems = [NSMutableArray array];
    
    NSIndexSet* selectedRowIndexes = [databaseOutline selectedRowIndexes];
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
    NSManagedObjectModel	*model = self.database.managedObjectModel;
    NSManagedObjectContext	*context = self.database.managedObjectContext;
    
    // FIND ALL STUDIES of this patient
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientUID BEGINSWITH[cd] %@)", [study valueForKey:@"patientUID"]];
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
        N2LogExceptionWithStackTrace(e);
    }
    
    [context unlock];
    
    return studiesArray;
}

-(BOOL)isCurrentDatabaseBonjour
{
    return ![_database isLocal];
}

-(NSString*)currentDatabasePath
{
    return [_database baseDirPath];
}

-(NSManagedObjectContext*)bonjourManagedObjectContext
{
    if (![_database isLocal])
        return [_database managedObjectContext];
    return nil;
}

@end
