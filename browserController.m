/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


/***************************************** Modifications *********************************************

Version 2.3

	20051215	LP	Added viewerDICOMMergeSelection method to open a viewer with merged Series 
					Added newDICOMViewer method to allow for key masks to vary viewer opening
	20051215	LP	Added _searchString varaible and associated methods. SearchField bound to _searchString
					Allows searches to be performed programmatically. 
					Also separates the model from the view.
	20051216	DDP	Database autocleaning now checks to see if an old study was added today and won't purge it if so.
	20051216	LP	Added filter and fetch predicates to clean up fetch code in the future and to allow fetches to be 
					performed programmatically such as by plugins
	20051217	ANR	viewerDICOMMergeSelection and viewerDICOMKeyImages modified to support matrix contextual menu
	20051217	LP	Modified outlineViewRefresh to use filterPredicate. 
					Clear search field when changing search type
	20051220	LP	Moved DICOM send code to SendController.
	20060101	DDP	Changed opendDatabase method to openDatabase (also in MainMenu Nib class definition).
	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).
	20060111	LP	Added AddDirectory option to ExportDICOM. Also added option to add DICOMDIR. 
	20060112	DDP	I think files may be autoreleased during recursive call to _testForValidFilePath, so I've bracketed
					the call to [... parseArray] in addDICOMDIR with a retain/release pair.
				DDP	Now allows return key to open from database like a double click with modality layout prefs, but only
					when one series is selected. Achieved by modifying [... newViwerDICOM].
	20060116	LP	Fixed potential bug assigning image path when adding DICOMDIR to exported Files
	20060128	LP	Changing routing Protocol
	20060128	LP	Modified isDICOMFile to test with DCMFramework as last resort. some valid files not read by papyrus
	20060308	RBR	Added test for RTSTRUCT in matrixNewIcon.  Write button icon indicating RTSTRUCT rather than error button.
	20060309	LP	added databaseWindow: to close all viewers
	20060607	LP Converted routing to DCMTK
	20060720	MS	openViewerWithImages caused some problems with large series. App became unstable and crashed from time to time
					memBlockTestPtr & memBlockSize arrays were limited to 200
					
Version 2.5

	20060809	DDP	Increased auto-delete safe buffer to 7 days from the time a study is added to a database.
				DDP	Renamed clearComplePathCache to clearCompletePathCache, as per DicomImage.
				DDP	Included DicomImage.h and typed image to be a DicomImage* rather than just NSManagedObject in addFilesToDatabase (reduces compile warnings).

*/

#import <DiscRecording/DRDevice.h>
#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "AnonymizerWindowController.h"
#import "DicomImage.h"
#import "DCMPix.h"

#import "AppController.h"
#import "dicomData.h"
#import "DCMPix.h"
#import "BrowserController.h"
#import "viewerController.h"
#import "PluginFilter.h"
#import "ReportPluginFilter.h"
#import "dicomFile.h"
#import "NSSplitViewSave.h"
#import "Papyrus3/Papyrus3.h"
#import "DicomDirParser.h"
#import "MutableArrayCategory.h"
#import "SmartWindowController.h"
#import "QueryFilter.h"
#import "ImageAndTextCell.h"
#import "SearchWindowController.h"
#import "Wait.h"
#import "WaitRendering.h"
#import "DotMacKit/DotMacKit.h"
#import "BurnerWindowController.h"
#import "DCMObject.h"
#import "DCMTransferSyntax.h"
#import "DCMAttributeTag.h"
#import "DCMPixelDataAttribute.h"
#import "DCMCalendarDate.h"
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMDirectory.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMDirectory.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "NetworkSendDataHandler.h"
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
#import "StructuredReportController.h"
#import "QTExportHTMLSummary.h"
#import "BrowserControllerDCMTKCategory.h"
#import "BrowserMatrix.h"

#define DATABASEVERSION @"2.1"
#define DATABASEPATH @"/DATABASE/"
#define DECOMPRESSIONPATH @"/DECOMPRESSION/"
#define INCOMINGPATH @"/INCOMING/"
#define ERRPATH @"/NOT READABLE/"
#define DATABASEFPATH @"/DATABASE"
#define DATAFILEPATH @"/Database.sql"

enum DCM_CompressionQuality {DCMLosslessQuality, DCMHighQuality, DCMMediumQuality, DCMLowQuality};

BrowserController  *browserWindow = 0L;

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>

static mach_port_t	gMasterPort;
static NSString *albumDragType = @"Osirix Album drag";
static Wait *waitSendWindow = 0L;

extern BOOL hasMacOSXTiger();
extern NSString					*documentsDirectory();

extern NSMutableArray			*preProcessPlugins;
extern NSMutableDictionary		*reportPlugins;
extern AppController			*appController;
extern NSMutableDictionary		*plugins, *pluginsDict;
extern NSThread					*mainThread;
extern BOOL						NEEDTOREBUILD, COMPLETEREBUILD;
extern NSMutableDictionary		*DATABASECOLUMNS;
extern NSLock					*PapyrusLock;

long		DATABASEINDEX;

//NSArray *syntaxArray;
//BOOL	queueThreadIsRunning;

Boolean IsWholeMedia(io_service_t service, BOOL *result)
{
    //
    // Determine if the object passed in represents an IOMedia (or subclass) object.
    // If it does, retrieve the "Whole" property.
    // If this is the whole media object, find out if it is a CD, DVD, or something else.
    // If it isn't the whole media object, iterate across its parents in the IORegistry
    // until the whole media object is found.
    //
    // Note that media types other than CD and DVD are not distinguished by class name
    // but are generic IOMedia objects.
    //
    
    Boolean 		isWholeMedia = false;
    io_name_t		className;
    kern_return_t	kernResult;
	
	*result = NO;
	
    if (IOObjectConformsTo(service, kIOMediaClass)) {
        
        CFTypeRef wholeMedia;
        
        wholeMedia = IORegistryEntryCreateCFProperty(service, 
                                                     CFSTR(kIOMediaWholeKey), 
                                                     kCFAllocatorDefault, 
                                                     0);
                                                    
        if (NULL == wholeMedia) {
            printf("Could not retrieve Whole property\n");
        }
        else {                                        
            isWholeMedia = CFBooleanGetValue(wholeMedia);
            CFRelease(wholeMedia);
        }
    }
            
    if (isWholeMedia) {
        if (IOObjectConformsTo(service, kIOCDMediaClass)) {
            printf("is a CD\n");
			*result = YES;
        }
        else if (IOObjectConformsTo(service, kIODVDMediaClass)) {
            printf("is a DVD\n");
			*result = YES;
        }
        else {
            kernResult = IOObjectGetClass(service, className);
            printf("is of class %s\n", className);
        }            
    }

    return isWholeMedia;
}

BOOL FindWholeMedia(io_service_t service)
{
    kern_return_t	kernResult;
    io_iterator_t	iter;
	BOOL			result = NO;
	BOOL			isWholeMedia = NO;
    // Create an iterator across all parents of the service object passed in.
    kernResult = IORegistryEntryCreateIterator(service,
                                               kIOServicePlane,
                                               kIORegistryIterateRecursively | kIORegistryIterateParents,
                                               &iter);
    
    if (KERN_SUCCESS != kernResult) {
        printf("IORegistryEntryCreateIterator returned %d\n", kernResult);
    }
    else if (iter == 0L) {
        printf("IORegistryEntryCreateIterator returned a NULL iterator\n");
    }
    else {

        
        // A reference on the initial service object is released in the do-while loop below,
        // so add a reference to balance 
        IOObjectRetain(service);	
        
        do {
            isWholeMedia = IsWholeMedia(service, &result);
            IOObjectRelease(service);
        } while ((service = IOIteratorNext(iter)) && !isWholeMedia && result == NO);
                
        IOObjectRelease(iter);
    }
	
	return result;
}

BOOL GetAdditionalVolumeInfo(char *bsdName)
{
    // The idea is that given the BSD node name corresponding to a volume,
    // I/O Kit can be used to find the information about the media, drive, bus, and so on
    // that is maintained in the IORegistry.
    //
    // In this sample, we find out if the volume is on a CD, DVD, or some other media.
    // This is done as follows:
    // 
    // 1. Find the IOMedia object that represents the entire (whole) media that the volume is on. 
    //
    // If the volume is on partitioned media, the whole media object will be a parent of the volume's
    // media object. If the media is not partitioned, (a floppy disk, for example) the volume's media
    // object will be the whole media object.
    // 
    // The whole media object is indicated in the IORegistry by the presence of a property with the key
    // "Whole" and value "Yes".
    //
    // 2. Determine which I/O Kit class the whole media object belongs to.
    //
    // For CD media the class name will be "IOCDMedia," and for DVD media the class name will be
    // "IODVDMedia". Other media will be of the generic "IOMedia" class.
    //
    
    CFMutableDictionaryRef	matchingDict;
    kern_return_t		kernResult;
    io_iterator_t 		iter;
    io_service_t		service;
	BOOL				result = NO;
    
    matchingDict = IOBSDNameMatching(gMasterPort, 0, bsdName);
    if (NULL == matchingDict) {
        printf("IOBSDNameMatching returned a NULL dictionary.\n");
    }
    else {
        // Return an iterator across all objects with the matching BSD node name. Note that there
        // should only be one match!
        kernResult = IOServiceGetMatchingServices(gMasterPort, matchingDict, &iter);    
    
        if (KERN_SUCCESS != kernResult) {
            printf("IOServiceGetMatchingServices returned %d\n", kernResult);
        }
        else if (iter==Nil) {
            printf("IOServiceGetMatchingServices returned a NULL iterator\n");
        }
        else {
            service = IOIteratorNext(iter);
            
            // Release this now because we only expect the iterator to contain
            // a single io_service_t.
            IOObjectRelease(iter);
            
            if (service==Nil) {
                printf("IOIteratorNext returned NULL\n");
            }
            else {
                result = FindWholeMedia(service);
                IOObjectRelease(service);
            }
        }
    }
	
	return result;
}

NSString* asciiString (NSString* name)
{
	NSMutableString	*outString;

	NSData		*asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	
	outString = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
	[BrowserController replaceNotAdmitted:outString];
	
	return outString;
}

@interface BrowserController (private)

- (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory found:(BOOL) found;


@end

@implementation BrowserController

static NSString* 	DatabaseToolbarIdentifier			= @"DicomDatabase Toolbar Identifier";
static NSString*	ImportToolbarItemIdentifier			= @"Import.icns";
static NSString*	iDiskSendToolbarItemIdentifier		= @"iDiskSend.icns";
static NSString*	iDiskGetToolbarItemIdentifier		= @"iDiskGet.icns";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	AnonymizerToolbarItemIdentifier		= @"Anonymizer.icns";
static NSString*	QueryToolbarItemIdentifier			= @"QueryRetrieve.icns";
static NSString*	SendToolbarItemIdentifier			= @"Send.icns";
static NSString*	ViewerToolbarItemIdentifier			= @"Viewer.icns";
static NSString*	CDRomToolbarItemIdentifier			= @"CDRom.icns";
static NSString*	MovieToolbarItemIdentifier			= @"Movie.icns";
static NSString*	TrashToolbarItemIdentifier			= @"trash.icns";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	BurnerToolbarItemIdentifier			= @"Burner.tif";
static NSString*	ToggleDrawerToolbarItemIdentifier   = @"StartupDisk.tiff";
static NSString*	SearchToolbarItemIdentifier			= @"Search";
static NSString*	TimeIntervalToolbarItemIdentifier	= @"TimeInterval";

static NSTimeInterval	gLastActivity = 0;
static BOOL				DICOMDIRCDMODE = NO;
//static NSArray*		tableColumns = 0L;

		NSArray*	statesArray = 0L;




+ (BrowserController*) currentBrowser { return browserWindow;}
+ (NSArray*) statesArray { return statesArray;}
+ (void) updateActivity
{
	gLastActivity = [NSDate timeIntervalSinceReferenceDate];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Add DICOM Database functions

- (NSString*) getNewFileDatabasePath: (NSString*) extension
{
	return [self getNewFileDatabasePath: extension dbFolder: [self documentsDirectory]];
}

- (NSString*) getNewFileDatabasePath: (NSString*) extension dbFolder: (NSString*) dbFolder
{
	NSString        *OUTpath = [dbFolder stringByAppendingPathComponent:DATABASEPATH];
	NSString		*dstPath;
	NSString		*subFolder;
	long			subFolderInt;

	do
	{
		subFolderInt = 10000L * ((DATABASEINDEX / 10000L) +1);
		subFolder = [OUTpath stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", subFolderInt]];

		if (![[NSFileManager defaultManager] fileExistsAtPath:subFolder])
			[[NSFileManager defaultManager] createDirectoryAtPath:subFolder attributes:nil];
		
		dstPath = [subFolder stringByAppendingPathComponent: [NSString stringWithFormat:@"%d.%@", DATABASEINDEX, extension]];
		
		DATABASEINDEX++;
	}
	while ([[NSFileManager defaultManager] fileExistsAtPath: dstPath]);
	
	return dstPath;
}

- (void) reloadViewers: (NSMutableArray*) vl
{
	long i;
	
	// Reload series if needed
	for( i = 0; i < [vl count]; i++)
	{
		if( [[[vl objectAtIndex: i] window] isVisible])
			[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [[[[vl objectAtIndex: i] fileList] objectAtIndex: 0] valueForKey:@"series"]]] movie: NO viewer :[vl objectAtIndex: i] keyImagesOnly: NO];
	}
	
	[[QueryController currentQueryController] refresh: self];
}

- (void) rebuildViewers: (NSMutableArray*) vlToRebuild
{
	long i;
	
	// Refresh preview matrix if needed
	for( i = 0; i < [vlToRebuild count]; i++)
	{
		if( [[[vlToRebuild objectAtIndex: i] window] isVisible])
			[[vlToRebuild objectAtIndex: i] buildMatrixPreview: NO];
	//	[[vlToRebuild objectAtIndex: i] matrixPreviewSelectCurrentSeries];
	}
}

- (void) callAddFilesToDatabaseSafe: (NSArray*) newFilesArray
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSString			*tempDirectory = [documentsDirectory() stringByAppendingPathComponent:@"/TEMP/"];
	NSString			*arrayFile = [tempDirectory stringByAppendingPathComponent:@"array.plist"];
	NSString			*databaseFile = [tempDirectory stringByAppendingPathComponent:@"database.plist"];
	NSString			*modelFile = [tempDirectory stringByAppendingPathComponent:@"model.plist"];
	
	[fm removeFileAtPath:arrayFile handler:0L];
	[fm removeFileAtPath:databaseFile handler:0L];
	[fm removeFileAtPath:modelFile handler:0L];
	
	[newFilesArray writeToFile:arrayFile atomically: YES];
	[[documentsDirectory() stringByAppendingPathComponent:DATABASEFPATH] writeToFile:databaseFile atomically: YES];
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"] writeToFile:modelFile atomically: YES];
    [allBundles release];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setCurrentDirectoryPath: tempDirectory];
	[theTask setArguments: [NSArray arrayWithObjects:arrayFile, databaseFile, modelFile, 0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/SafeDBRebuild"]];
	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
	
	[fm removeFileAtPath:arrayFile handler:0L];
	[fm removeFileAtPath:databaseFile handler:0L];
	[fm removeFileAtPath:modelFile handler:0L];
	
	[pool release];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray
{
	return [self addFilesToDatabase: newFilesArray onlyDICOM:NO safeRebuild:NO produceAddedFiles :YES];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray :(BOOL) onlyDICOM
{
	return [self addFilesToDatabase: newFilesArray onlyDICOM:onlyDICOM safeRebuild:NO produceAddedFiles :YES];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles
{
	return [self addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject: NO];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject
{
	NSManagedObjectContext	*context = [self managedObjectContext];
	
	return [self addFilesToDatabase: newFilesArray onlyDICOM: onlyDICOM safeRebuild: safeProcess produceAddedFiles: produceAddedFiles parseExistingObject: parseExistingObject context: context dbFolder: documentsDirectory()];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder
{
	NSEnumerator			*enumerator = [newFilesArray objectEnumerator];
	NSString				*newFile;
	NSDate					*today = [NSDate date];
	NSError					*error = 0L;
	NSString				*curPatientUID = 0L, *curStudyID = 0L, *curSerieID = 0L;
	NSManagedObject			*seriesTable, *study, *album;
	DicomImage				*image;
	long					ii, i, x;
	unsigned long			index;
	NSString				*INpath = [dbFolder stringByAppendingPathComponent:DATABASEFPATH];
	Wait					*splash = 0L;
	NSManagedObjectModel	*model = [self managedObjectModel];
	NSMutableArray			*addedImagesArray = 0L;
	NSMutableArray			*addedSeries = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray			*modifiedStudiesArray = 0L;
	long					addFailed = NO;
	BOOL					COMMENTSAUTOFILL = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"];
	BOOL					newStudy = NO, newObject = NO;
	NSMutableArray			*vlToRebuild = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray			*vlToReload = [NSMutableArray arrayWithCapacity: 0];
	BOOL					isCDMedia = NO;
	

	if( [newFilesArray count] == 0) return [NSMutableArray arrayWithCapacity: 0];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDICOM"]) onlyDICOM = YES;
	
//	#define RANDOMFILES
	
	#ifdef RANDOMFILES
	NSMutableArray	*randomArray = [NSMutableArray array];
	for( i = 0; i < 5000; i++)
	{
		[randomArray addObject:@"yahoo/google/osirix/microsoft"];
	}
	newFilesArray = randomArray;
	enumerator = [newFilesArray objectEnumerator];
	#endif
	
	if( safeProcess)
	{
		NSLog( @"safe Process DB process");
	}
	
	if( mainThread == [NSThread currentThread])
	{
		isCDMedia = [BrowserController isItCD: [[newFilesArray objectAtIndex: 0] pathComponents]];
		
		[DicomFile setFilesAreFromCDMedia: isCDMedia];
		
		if( [newFilesArray count] > 50 || isCDMedia == YES)
		{
			splash = [[Wait alloc] initWithString: [NSString stringWithFormat: NSLocalizedString(@"Adding %@ files...", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt:[newFilesArray count]]]]];
			[splash showWindow:self];
			
			if( isCDMedia) [[splash progress] setMaxValue:[newFilesArray count]];
			else [[splash progress] setMaxValue:[newFilesArray count]/30];
		}
	}
	
	ii = 0;
	[context retain];
	[context lock];
	
	[context setStalenessInterval: 1200];
	
	// Find all current studies
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *studiesArray;
	@try
	{
		studiesArray = [[context executeFetchRequest:dbRequest error:&error] retain];
	}
	@catch( NSException *ne)
	{
		NSLog(@"AddFilesToDatabase executeFetchRequest exception: %@", [ne description]);
		NSLog(@"executeFetchRequest failed for studiesArray.");
		error = [NSError errorWithDomain:@"OsiriXDomain" code:1 userInfo: 0L];
	}
	if (error)
	{
		NSLog( @"addFilesToDatabase ERROR: %@", [error localizedDescription]);
		//managedObjectContext = 0L;
		[context setStalenessInterval: 1200];
		[context unlock];
		[context release];
		
		//All these files were NOT saved..... due to an error. Move them back to the INCOMING folder.
		addFailed = YES;
	}
	else
	{
		if( produceAddedFiles)
		{
			addedImagesArray = [NSMutableArray arrayWithCapacity: [newFilesArray count]];
			modifiedStudiesArray = [NSMutableArray arrayWithCapacity: 0];
		}
		
		// Add the new files
		while (newFile = [enumerator nextObject])
		{
			@try
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				DicomFile		*curFile = 0L;
				NSDictionary	*curDict = 0L;
				
				#ifdef RANDOMFILES
				curFile = [[DicomFile alloc] initRandom];
				#else
				curFile = [[DicomFile alloc] init: newFile];
				#endif
				
				if(curFile == 0L && [[newFile pathExtension] isEqualToString:@"zip"] == YES)
				{
					NSString *filePathWithoutExtension = [newFile stringByDeletingPathExtension];
					NSString *xmlFilePath = [filePathWithoutExtension stringByAppendingString:@".xml"];
					
					if([[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath])
					{
						NSLog(@"read the xml data");
						NSLog(@"xmlFilePath : %@", xmlFilePath);
						NSLog(@"newFile : %@", newFile);
						curFile = [[DicomFile alloc] initWithXMLDescriptor:xmlFilePath path:newFile];
						NSLog(@"xml data OK");
					}
				}
				
				if( curFile)
				{
					curDict = [[curFile dicomElements] retain];
					[curFile release];
					curFile = 0L;
				}
				else curDict = [curDict retain];
				
				if( onlyDICOM)
				{
					if( [[curDict objectForKey: @"fileType"] hasPrefix:@"DICOM"] == NO)
					{
						[curDict release];
						curDict = 0L;
					}
				}
				
				// For now, we cannot add non-image DICOM files
				if( [curDict objectForKey:@"SOPClassUID"] != nil 
				&& [DCMAbstractSyntaxUID isImageStorage: [curDict objectForKey: @"SOPClassUID"]] == NO 
				&& [DCMAbstractSyntaxUID isRadiotherapy: [curDict objectForKey: @"SOPClassUID"]] == NO
				&& [DCMAbstractSyntaxUID isStructuredReport: [curDict objectForKey: @"SOPClassUID"]] == NO
				&& [DCMAbstractSyntaxUID isKeyObjectDocument: [curDict objectForKey: @"SOPClassUID"]] == NO)
				{
					NSLog(@"unsupported DICOM SOP CLASS");
					[curDict release];
					curDict = 0L;
				}
				
				if( splash)
				{
					if( isCDMedia)
					{
						ii++;
						[splash incrementBy:1];
					}
					else
					{
						if( (ii++) % 30 == 0) [splash incrementBy:1];
					}
					
					if( ii % 50000 == 0)
					{
						[self saveDatabase:currentDatabasePath];
					}
				}
				
				if( curDict != 0L)
				{
//					if( 0)
					{
						if( [[curDict objectForKey: @"studyID"] isEqualToString: curStudyID] == YES && [[curDict objectForKey: @"patientUID"] caseInsensitiveCompare: curPatientUID] == NSOrderedSame)
						{
							
						}
						else
						{
							/*******************************************/
							/*********** Find study object *************/
							index = [[studiesArray  valueForKey:@"studyInstanceUID"] indexOfObject:[curDict objectForKey: @"studyID"]];
							if( index == NSNotFound)
							{
								// Fields
								study = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:context];
								
								newObject = YES;
								newStudy = YES;
								
								[study setValue:today forKey:@"dateAdded"];
								
								NSArray	*newStudiesArray = [studiesArray arrayByAddingObject: study];
								[studiesArray release];
								studiesArray = [newStudiesArray retain];
								
								[curSerieID release];	curSerieID = 0L;
							}
							else
							{
								study = [studiesArray objectAtIndex: index];
								
								newObject = NO;
							}
							
							if( newObject || parseExistingObject)
							{
								[study setValue:[curDict objectForKey: @"studyID"] forKey:@"studyInstanceUID"];
								[study setValue:[curDict objectForKey: @"studyDescription"] forKey:@"studyName"];
								[study setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
								[study setValue:[curDict objectForKey: @"accessionNumber"] forKey:@"accessionNumber"];
							
								DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
								[study setValue:[time timeAsNumber] forKey:@"dicomTime"];
							
								[study setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								[study setValue:[curDict objectForKey: @"patientBirthDate"] forKey:@"dateOfBirth"];
								[study setValue:[curDict objectForKey: @"patientSex"] forKey:@"patientSex"];
								[study setValue:[curDict objectForKey: @"referringPhysiciansName"] forKey:@"referringPhysician"];
								[study setValue:[curDict objectForKey: @"performingPhysiciansName"] forKey:@"performingPhysician"];
								[study setValue:[curDict objectForKey: @"institutionName"] forKey:@"institutionName"];
							
								[study setValue:[curDict objectForKey: @"patientID"] forKey:@"patientID"];
								[study setValue:[curDict objectForKey: @"patientName"] forKey:@"name"];
								[study setValue:[curDict objectForKey: @"patientUID"] forKey:@"patientUID"];
								[study setValue:[curDict objectForKey: @"studyNumber"] forKey:@"id"];
								[study setValue:[curDict objectForKey: @"studyComment"] forKey:@"comment"];
							
								//need to know if is DICOM so only DICOM is queried for Q/R
								if ([curDict objectForKey: @"hasDICOM"])
									[study setValue:[curDict objectForKey: @"hasDICOM"] forKey:@"hasDICOM"];
							}
							
							[curStudyID release];			curStudyID = [[curDict objectForKey: @"studyID"] retain];
							[curPatientUID release];		curPatientUID = [[curDict objectForKey: @"patientUID"] retain];
							
							if( produceAddedFiles)
								[modifiedStudiesArray addObject: study];
						}
						
						long NoOfSeries = [[curDict objectForKey: @"numberOfSeries"] intValue];
						for(i = 0; i < NoOfSeries; i++)
						{
							NSString* SeriesNum;
							if (i)
								SeriesNum = [NSString stringWithFormat:@"%d",i];
							else
								SeriesNum = @"";
							
							if( [[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]] isEqualToString: curSerieID])
							{
							}
							else
							{
								/********************************************/
								/*********** Find series object *************/
								
								NSArray		*seriesArray = [[study valueForKey:@"series"] allObjects];
								
								//NSLog([curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]]);
								
								index = [[seriesArray valueForKey:@"seriesInstanceUID"] indexOfObject:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]]];
								if( index == NSNotFound)
								{
									// Fields
									seriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext:context];
									[seriesTable setValue:today forKey:@"dateAdded"];
									
									newObject = YES;
								}
								else
								{
									seriesTable = [seriesArray objectAtIndex: index];
									newObject = NO;
								}
								
								if( newObject || parseExistingObject)
								{
									if( [curDict objectForKey: @"seriesDICOMUID"]) [seriesTable setValue:[curDict objectForKey: @"seriesDICOMUID"] forKey:@"seriesDICOMUID"];
									if( [curDict objectForKey: @"SOPClassUID"]) [seriesTable setValue:[curDict objectForKey: @"SOPClassUID"] forKey:@"seriesSOPClassUID"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]] forKey:@"seriesInstanceUID"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesDescription" stringByAppendingString:SeriesNum]] forKey:@"name"];
									[seriesTable setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
									[seriesTable setValue:[curDict objectForKey: [@"seriesNumber" stringByAppendingString:SeriesNum]] forKey:@"id"];
									[seriesTable setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
									[seriesTable setValue:[curDict objectForKey: @"protocolName"] forKey:@"seriesDescription"];
									
									DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
									[seriesTable setValue:[time timeAsNumber] forKey:@"dicomTime"];
									
									// Relations
									[seriesTable setValue:study forKey:@"study"];
									// If a study has an SC or other non primary image  series. May need to change modality to true modality
									if (([[study valueForKey:@"modality"] isEqualToString:@"OT"]  || [[study valueForKey:@"modality"] isEqualToString:@"SC"])
										&& !([[curDict objectForKey: @"modality"] isEqualToString:@"OT"] || [[curDict objectForKey: @"modality"] isEqualToString:@"SC"]))
										[study setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								}
								
								[curSerieID release];
								curSerieID = [[curDict objectForKey: @"seriesID"] retain];
							}
							
							/*******************************************/
							/*********** Find image object *************/
							
							BOOL			local = NO;
							if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
							{
								local = YES;
							}
							
							NSArray		*imagesArray = [[seriesTable valueForKey:@"images"] allObjects] ;
							
							index = [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curDict objectForKey: [@"SOPUID" stringByAppendingString:SeriesNum]]];
							if( index != NSNotFound)
							{
								image = [imagesArray objectAtIndex: index];
								
								// Does this image contain a valid image path? If not replace it, with the new one
								if( [[NSFileManager defaultManager] fileExistsAtPath: [DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory: dbFolder]] == YES && parseExistingObject == NO)
								{
									if( produceAddedFiles)
										[addedImagesArray addObject: image];
									
									if( local)	// Delete this file, it's already in the DB folder
									{
										if( [[image valueForKey:@"path"] isEqualToString: [newFile lastPathComponent]] == NO)
											[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
									}
									
									newObject = NO;
								}
								else
								{
									newObject = YES;
									[image clearCompletePathCache];
									
									if( [[image valueForKey:@"inDatabaseFolder"] boolValue] && [[DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory: dbFolder] isEqualToString: newFile] == NO)
									{
										if( [[NSFileManager defaultManager] fileExistsAtPath: [DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory: dbFolder]])
											[[NSFileManager defaultManager] removeFileAtPath: [DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory: dbFolder] handler:nil];
									}
								}
							}
							else
							{
								image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
								
								newObject = YES;
							}
							
							if( newObject || parseExistingObject)
							{
								needDBRefresh = YES;
								
								[study setValue:today forKey:@"dateAdded"];
								[seriesTable setValue:today forKey:@"dateAdded"];
								
								[image setValue:[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] forKey:@"instanceNumber"];
//								[image setValue:[[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] stringValue] forKey:@"name"];
								[image setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								
								if( local) [image setValue: [newFile lastPathComponent] forKey:@"path"];
								else [image setValue:newFile forKey:@"path"];
								
								[image setValue:[NSNumber numberWithBool:local] forKey:@"inDatabaseFolder"];
								
								[image setValue:[curDict objectForKey: @"studyDate"]  forKey:@"date"];
								DCMCalendarDate *time = [DCMCalendarDate dicomTimeWithDate:[curDict objectForKey: @"studyDate"]];
								[image setValue:[time timeAsNumber] forKey:@"dicomTime"];
								
								[image setValue:[curDict objectForKey: [@"SOPUID" stringByAppendingString:SeriesNum]] forKey:@"sopInstanceUID"];
								[image setValue:[curDict objectForKey: @"sliceLocation"] forKey:@"sliceLocation"];
								[image setValue:[[newFile pathExtension] lowercaseString] forKey:@"extension"];
								[image setValue:[curDict objectForKey: @"fileType"] forKey:@"fileType"];
								
								[image setValue:[curDict objectForKey: @"height"] forKey:@"height"];
								[image setValue:[curDict objectForKey: @"width"] forKey:@"width"];
								[image setValue:[curDict objectForKey: @"numberOfFrames"] forKey:@"numberOfFrames"];
								[image setValue:[NSNumber numberWithBool:mountedVolume] forKey:@"mountedVolume"];
								if( mountedVolume) [seriesTable setValue:[NSNumber numberWithBool:mountedVolume] forKey:@"mountedVolume"];
								[image setValue:[curDict objectForKey: @"numberOfSeries"] forKey:@"numberOfSeries"];
							
								[seriesTable setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[seriesTable setValue: 0L forKey:@"thumbnail"];
								
								// Relations
								[image setValue:seriesTable forKey:@"series"];
								
								if( COMMENTSAUTOFILL)
								{
									if([curDict objectForKey: @"commentsAutoFill"])
									{
										[seriesTable setValue:[curDict objectForKey: @"commentsAutoFill"] forKey:@"comment"];
										
										if( [study valueForKey:@"comment"] == 0L || [[study valueForKey:@"comment"] isEqualToString:@""])
										{
											[study setValue:[curDict objectForKey: @"commentsAutoFill"] forKey:@"comment"];
										}
									}
								}
								
								if( produceAddedFiles)
									[addedImagesArray addObject: image];
								
								if( [addedSeries containsObject: seriesTable] == NO) [addedSeries addObject: seriesTable];
								
								if([curDict valueForKey:@"album"] !=nil)
								{
									//Find all albums
									NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
									[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Album"]];
									[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
									error = 0L;
									NSArray *albumArray = [context executeFetchRequest:dbRequest error:&error];
									
									NSManagedObject *album = nil;
									int i;
									for(i=0 ; i<[albumArray count] ; i++)
									{
										if([[[albumArray objectAtIndex: i] valueForKeyPath:@"name"] isEqualToString: [curDict valueForKey:@"album"]])
										{
											album = [albumArray objectAtIndex: i];
										}
									}
									
									if (album == nil)
									{
//										NSString *name = [curDict valueForKey:@"album"];
//										album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
//										[album setValue:name forKey:@"name"];
										
										for(i=0 ; i<[albumArray count] ; i++)
										{
											if([[[albumArray objectAtIndex: i] valueForKeyPath:@"name"] isEqualToString: @"other"])
											{
												album = [albumArray objectAtIndex: i];
											}
										}
										
										if (album == nil)
										{
											album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
											[album setValue:@"other" forKey:@"name"];
										}
									}
									
									// add the file to the album
									if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
									{
										NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];	
										[studies addObject: [image valueForKeyPath:@"series.study"]];
									}
								}
							}
						}
					}
					[curFile release];
					
					[curDict release];
					curDict = 0L;
				}
				[pool release];
			}
			
			@catch( NSException *ne)
			{
				NSLog(@"AddFilesToDatabase DicomFile exception: %@", [ne description]);
				NSLog(@"Parser failed for this file: %@", newFile);
			}
		}

		[studiesArray release];
		
		// Compute no of images in studies/series
		if( produceAddedFiles)
			for( i = 0; i < [modifiedStudiesArray count]; i++) [[modifiedStudiesArray objectAtIndex: i] valueForKey:@"noFiles"];
		
		if( produceAddedFiles)
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:addedImagesArray forKey:@"OsiriXAddToDBArray"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"OsirixAddToDBNotification" object: nil userInfo:userInfo];
			
			if( [addedImagesArray count])
				[appController growlTitle: NSLocalizedString( @"Incoming Files", 0L) description:[NSString stringWithFormat: NSLocalizedString(@"Patient: %@\r%d images added to the database", 0L), [[addedImagesArray objectAtIndex:0] valueForKeyPath:@"series.study.name"], [addedImagesArray count]] name:@"newfiles"];
		}
		
		[curPatientUID release];
		[curStudyID release];
		[curSerieID release];
		
		if( splash)
		{
			[splash close];
			[splash release];
			splash = 0L;
		}
		
		[self autoCleanDatabaseFreeSpace: self];
		
		if( [NSDate timeIntervalSinceReferenceDate] - lastSaved > 30)
		{
			if( [self saveDatabase:currentDatabasePath] != 0)
			{
				//All these files were NOT saved..... due to an error. Move them back to the INCOMING folder.
				addFailed = YES;
			}
			
			lastSaved = [NSDate timeIntervalSinceReferenceDate];
		}
				
		if( addFailed == NO)
		{
			NSMutableArray		*viewersList = [ViewerController getDisplayed2DViewers];
			NSArray				*winList = [NSApp windows];
			
			for( i = 0; i < [addedSeries count]; i++)
			{
				NSManagedObject		*seriesTable = [addedSeries objectAtIndex: i];
				NSString			*curPatientID = [seriesTable valueForKeyPath:@"study.patientID"];
								
				for( x = 0; x < [viewersList count]; x++)
				{
					if( [[[viewersList objectAtIndex: x] fileList] count])
					{
						NSManagedObject	*firstObject = [[[viewersList objectAtIndex: x] fileList] objectAtIndex: 0];
						
						// For each new image in a pre-existing study, check if a viewer is already opened -> refresh the preview list
						
						if( [curPatientID isEqualToString: [firstObject valueForKeyPath:@"series.study.patientID"]])
						{
							if( [vlToRebuild containsObject:[viewersList objectAtIndex: x]] == NO)
								[vlToRebuild addObject: [viewersList objectAtIndex: x]];
						}
						
						if( seriesTable == [firstObject valueForKey:@"series"])
						{
							if( [vlToReload containsObject:[viewersList objectAtIndex: x]] == NO)
								[vlToReload addObject: [viewersList objectAtIndex: x]];
						}
					}
				}
			}
		}
		
		[context setStalenessInterval: 1200];
		[context unlock];
		[context release];
		
		if( addFailed == NO)
		{
			if( mainThread == [NSThread currentThread])
			{
				// Purge viewersListToReload & viewersListToReload arrays
				[self newFilesGUIUpdate: self];
				
				[viewersListToReload addObjectsFromArray: vlToReload];
				[viewersListToRebuild addObjectsFromArray: vlToRebuild];
				
				if( newStudy) [self newFilesGUIUpdateRun: 1];
				else [self newFilesGUIUpdateRun: 2];
			}
			else
			{
				[newFilesConditionLock lockWhenCondition: 0];
				
				[viewersListToReload addObjectsFromArray: vlToReload];
				[viewersListToRebuild addObjectsFromArray: vlToRebuild];
				
				if( newStudy) [newFilesConditionLock unlockWithCondition: 1];
				else [newFilesConditionLock unlockWithCondition: 2];
			}
			
			databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
		}
	}
	
	[DicomFile setFilesAreFromCDMedia: NO];
	
	if( addFailed)
	{
		NSLog(@"adding failed....");
		
		return 0L;
	}
	
	return addedImagesArray;
}

- (void) newFilesGUIUpdateRun:(int) state
{
	if( state == 1)
	{
		[self outlineViewRefresh];
	}
	else
	{
		[databaseOutline reloadData];
		[albumTable reloadData];
		[self outlineViewSelectionDidChange: 0L];
	}
	
	[self reloadViewers: viewersListToReload];
	[self rebuildViewers: viewersListToRebuild];
	
	[viewersListToReload removeAllObjects];
	[viewersListToRebuild removeAllObjects];
}

- (void) newFilesGUIUpdate:(id) sender
{
	if( [newFilesConditionLock tryLockWhenCondition: 1] || [newFilesConditionLock tryLockWhenCondition: 2])
	{
		int condition = [newFilesConditionLock condition];
		[newFilesConditionLock unlockWithCondition: 0];
		
		NSLog( @"newFilesGUIUpdate");
		[self newFilesGUIUpdateRun: condition];
	}
}

- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames copied:(BOOL*) copied
{
    NSFileManager       *defaultManager = [NSFileManager defaultManager];
	NSMutableArray		*filesArray;
	long				i;
	BOOL				isDirectory = NO;
	
	filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	for( i = 0; i < [filenames count]; i++)
	{
		if( [[[filenames objectAtIndex:i] lastPathComponent] characterAtIndex: 0] != '.')
		{
			if([defaultManager fileExistsAtPath:[filenames objectAtIndex:i] isDirectory:&isDirectory])     // A directory
			{
				if( isDirectory == YES)
				{
					NSString    *pathname;
					NSString    *aPath = [filenames objectAtIndex:i];
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
				
					while (pathname = [enumer nextObject])
					{
						NSString * itemPath = [aPath stringByAppendingPathComponent:pathname];
						id fileType = [[enumer fileAttributes] objectForKey:NSFileType];
						
						if ([fileType isEqual:NSFileTypeRegular])
						{
							if( [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES)
							{
								[self addDICOMDIR: [filenames objectAtIndex:i] :filesArray];
							}
							else
							{
								if( [[itemPath lastPathComponent] characterAtIndex: 0] != '.')
									[filesArray addObject:itemPath];
							}
						}
					}
				}
				else    // A file
				{
					if( [[[[filenames objectAtIndex:i] lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES)
					{
						[self addDICOMDIR: [filenames objectAtIndex:i] :filesArray];
					}
					else [filesArray addObject:[filenames objectAtIndex:i]];
				}
			}
		}
	}
	
	NSMutableArray	*newfilesArray = [self copyFilesIntoDatabaseIfNeeded:filesArray];
	
	if( newfilesArray == filesArray)
	{
		if( copied) *copied = NO;
	}
	else
	{
		if( copied) *copied = YES;
		filesArray = newfilesArray;
		mountedVolume = NO;
	}
	
	NSArray	*newImages = [self addFilesToDatabase:filesArray];
	
	[self outlineViewRefresh];
	
	return newImages;
}

- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames
{
	return [self addFilesAndFolderToDatabase:(NSArray*) filenames copied: 0L];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Autorouting functions

- (void) testAutorouting
{
	// Test the routing filters
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		NSArray	*autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
		int i;
			
		for( i = 0; i < [autoroutingRules count]; i++)
		{
			NSDictionary	*routingRule = [autoroutingRules objectAtIndex: i];
			
			@try
			{
				[[BrowserController currentBrowser] smartAlbumPredicateString: [routingRule objectForKey:@"filter"]];
			}
		
			@catch( NSException *ne)
			{
				NSRunAlertPanel( NSLocalizedString(@"Routing Filter Error", nil),  [NSString stringWithFormat: NSLocalizedString(@"Syntax error in this routing filter: %@\r\r%@\r\rSee Routing Preferences.", nil), [routingRule objectForKey:@"name"], [routingRule objectForKey:@"filter"]], nil, nil, nil);
			}
		}
	}
}

- (void) OsirixAddToDBNotification:(NSNotification *) note
{
	NSArray					*newImages = [[note userInfo] objectForKey:@"OsiriXAddToDBArray"];
	int						i, x;
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		NSArray	*autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
		
		for( i = 0; i < [autoroutingRules count]; i++)
		{
			NSDictionary	*routingRule = [autoroutingRules objectAtIndex: i];
			
			if( [routingRule valueForKey:@"activated"] == 0L || [[routingRule valueForKey:@"activated"] boolValue] == YES)
			{
				NSManagedObjectContext *context = [self managedObjectContext];
				
				[context retain];
				[context lock];
				 
				NSPredicate			*predicate = 0L;
				NSArray				*result;
				
				@try
				{
					predicate = [self smartAlbumPredicateString: [routingRule objectForKey:@"filter"]];
					if( predicate) result = [newImages filteredArrayUsingPredicate: predicate];
				}
				
				@catch( NSException *ne)
				{
					result = 0L;
					NSLog( @"Error in autorouting filter :");
					NSLog( [ne name]);
					NSLog( [ne reason]);
				}
				
				if( [result count])
				{
					if( autoroutingQueueArray == 0L) autoroutingQueueArray = [[NSMutableArray array] retain];
					if( autoroutingQueue == 0L) autoroutingQueue = [[NSLock alloc] init];
					if( autoroutingInProgress == 0L) autoroutingInProgress = [[NSLock alloc] init];
					
					[autoroutingQueue lock];
					
					[autoroutingQueueArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: result, @"objects", [routingRule objectForKey:@"server"], @"server", 0L]];
					
					[autoroutingQueue unlock];
				}
				[context unlock];
				[context release];
			}
		}
	}
}

- (void) showErrorMessage:(NSDictionary*) dict
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowErrorMessagesForAutorouting"] == NO) return;
	
	NSException	*ne = [dict objectForKey: @"exception"];
	NSDictionary *server = [dict objectForKey:@"server"];
	
	NSString	*message = [NSString stringWithFormat:@"%@\r\r%@\r%@\r\rServer:%@-%@:%@", NSLocalizedString( @"Autorouting DICOM StoreSCU operation failed.\rI will try again in 30 secs.", nil), [ne name], [ne reason], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"]];

	NSRunCriticalAlertPanel(NSLocalizedString(@"Autorouting Error",nil), message, NSLocalizedString( @"OK",nil), nil, nil);
}

- (void) executeSend :(NSArray*) samePatientArray server:(NSDictionary*) server
{
	BOOL	isFault = NO;
	
	int x;
	for( x = 0; x < [samePatientArray count] ; x++) if( [[samePatientArray objectAtIndex: x] isFault]) isFault = YES;
	
	if( isFault) NSLog( @"Fault on objects: not available for sending");
	else
	{
		NSLog( @"%@", [[samePatientArray objectAtIndex: 0] valueForKeyPath:@"series.study.name"]);
								
		DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
															calledAET: [server objectForKey:@"AETitle"] 
															hostname: [server objectForKey:@"Address"] 
															port: [[server objectForKey:@"Port"] intValue] 
															filesToSend: [samePatientArray valueForKey: @"completePath"]
															transferSyntax: [[server objectForKey:@"Transfer Syntax"] intValue] 
															compression: 1.0
															extraParameters: nil];
		
		@try
		{
			[storeSCU run:self];
		}
		
		@catch (NSException *ne)
		{
			NSLog( @"Autorouting FAILED");
			NSLog( [ne name]);
			NSLog( [ne reason]);
			
			[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ne, @"exception", server, @"server", 0L] waitUntilDone: NO];
			
			// We will try again later...
			[autoroutingQueue lock];
			[autoroutingQueueArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: samePatientArray, @"objects", [server objectForKey:@"Description"], @"server", 0L]];
			[autoroutingQueue unlock];
		}
		
		[storeSCU release];
		storeSCU = 0L;
	}
}

- (void) processAutorouting
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	NSArray				*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	int i;
	
	[autoroutingInProgress lock];
	
	[autoroutingQueue lock];
	NSArray	*copyArray = [NSArray arrayWithArray: autoroutingQueueArray];
	[autoroutingQueueArray removeAllObjects];
	[autoroutingQueue unlock];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		if( [copyArray count])
		{
			NSLog(@"autorouting Queue start: %d objects", [copyArray count]);
			for( i = 0; i < [copyArray count]; i++)
			{
				NSArray			*objectsToSend = [[copyArray objectAtIndex: i] objectForKey:@"objects"];
				NSString		*serverName = [[copyArray objectAtIndex: i] objectForKey:@"server"];
				NSDictionary	*server = 0L;
				
				NSDictionary	*aServer;
				NSEnumerator	*serverEnumerator	= [serversArray objectEnumerator];
				while (aServer = [serverEnumerator nextObject])
				{
					if ([[aServer objectForKey:@"Description"] isEqualToString: serverName]) 
					{
						NSLog( [aServer description]);
						server = aServer;
						break;
					}
				}
				
				if( server)
				{
					int		x;
					
					@try
					{
						NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"series.study.patientID" ascending:YES] autorelease];
						NSArray				*sortDescriptors = [NSArray arrayWithObject: sort];
						
						objectsToSend = [objectsToSend sortedArrayUsingDescriptors: sortDescriptors];
						
						
						NSString			*previousPatientUID = 0L;
						NSMutableArray		*samePatientArray = [NSMutableArray arrayWithCapacity: [objectsToSend count]];
						
						for( x = 0; x < [objectsToSend count] ; x++)
						{
							if( [previousPatientUID isEqualToString: [[objectsToSend objectAtIndex: x] valueForKeyPath:@"series.study.patientID"]])
							{
								[samePatientArray addObject: [objectsToSend objectAtIndex: x]];
							}
							else
							{
								// Send the collected files from the same patient
								
								if( [samePatientArray count]) [self executeSend: samePatientArray server: server];
								
								// Reset
								[samePatientArray removeAllObjects];
								[samePatientArray addObject: [objectsToSend objectAtIndex: x]];
								
								previousPatientUID = [[objectsToSend objectAtIndex: x] valueForKeyPath:@"series.study.patientID"];
							}
						}
						
						if( [samePatientArray count]) [self executeSend: samePatientArray server: server];
					}
					
					@catch( NSException *ne)
					{
						NSLog( [ne name]);
						NSLog( [ne reason]);
					}
				}
				else
				{
					NSLog(@"server not found for autorouting: %@", serverName);
					NSException *ne = [NSException exceptionWithName: NSLocalizedString(@"Unknown destination server. Add it to the Locations list - see Preferences.", 0L) reason: [NSString stringWithFormat:@"Destination: %@", serverName] userInfo:0L];
					
					[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ne, @"exception", [NSDictionary dictionary], @"server", 0L] waitUntilDone: NO];
				}
			}
			
			NSLog(@"autorouting Queue end");
		}
	}
	[autoroutingInProgress unlock];
	[pool release];
}

- (void) emptyAutoroutingQueue:(id) sender
{
	if( autoroutingQueueArray != 0L && autoroutingQueue != 0L)
	{
		if( [autoroutingQueueArray count] > 0)
		{
			if( [autoroutingInProgress tryLock])
			{
				[autoroutingInProgress unlock];
				[NSThread detachNewThreadSelector:@selector(processAutorouting) toTarget:self withObject:0L];
			}
		}
	}
}

#pragma mark-
#pragma mark iCal routing functions - will be re-activated with iCal API in MacOS 10.5
//
//- (void)runSendQueue:(id)object{
//
//	while (YES) {
//		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//		[queueLock lockWhenCondition:QueueHasData];
//		NSArray *destination = [sendQueue objectAtIndex:0];
//		NSString *filesToSend = nil;
//		NSString *syntax = nil;
//		NSDictionary *server = nil;
//		DCMTransferSyntax *ts = nil;
//		NSLog(@"destination count : %d", [destination count]);
//		if ([destination count] == 3) {
//			//old style layout.
//			//get syntax
//			/* 
//			index 0: Server description
//			index 1: TS
//			index 2: file
//			*/
//			
//			syntax = [destination objectAtIndex:1];
//			//get Transfer Syntax and compression in indicated
//			int compression = DCMLosslessQuality;
//			if ([syntax isEqualToString:@"Explicit Little Endian"])
//				ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
//			else if ([syntax isEqualToString:@"JPEG 2000 Lossless"])
//				ts = [DCMTransferSyntax JPEG2000LosslessTransferSyntax];
//			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 10:1"]) {
//				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//				compression = DCMHighQuality;
//			}
//			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 20:1"]) {
//				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//				compression = DCMMediumQuality;
//			}
//			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 50:1"]) {
//				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
//				compression =  DCMLowQuality;
//			}
//			else if ([syntax isEqualToString:@"JPEG Lossless"])
//				ts = [DCMTransferSyntax JPEGLosslessTransferSyntax];
//			else if ([syntax isEqualToString:@"JPEG High Quality (9)"]) {
//				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//				compression = DCMHighQuality;
//			}
//			else if ([syntax isEqualToString:@"JPEG High Quality (8)"]) {
//				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//				compression =  DCMMediumQuality;
//			}
//			else if ([syntax isEqualToString:@"JPEG High Quality (7)"]) {
//				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
//				compression =  DCMLowQuality;
//			}
//		// getServer
//			NSArray					*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
//			NSEnumerator			*enumerator			= [serversArray objectEnumerator];
//			NSDictionary			*aServer;
//			
//			
//			while (aServer = [enumerator nextObject]){
//				if ([[aServer objectForKey:@"Description"] isEqualToString:[destination objectAtIndex:0]] )  {
//					server = aServer;
//					break;
//				}
//			}
//			// file path
//			filesToSend = [NSArray arrayWithObject:[destination objectAtIndex:2]];
//			// only send if we have a server, Transfer Syntax and file
//			if (server && ts && [[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:2]]) {	
//
//				NSArray *objects = [NSArray arrayWithObjects:filesToSend, [NSNumber numberWithInt:compression], ts, [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"],    nil];
//				NSArray *keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", nil];
//				NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
//				DCMStoreSCU *storeSCU = [DCMStoreSCU sendWithParameters:(NSDictionary *)params];
//				
//			}
//			else {
//				if (!server)
//					NSLog(@"Routing:Not a valid DICOM destination");
//				if (!ts)
//					NSLog(@"Routing:Not a valid transfer syntax");
//				if (![[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:2]])
//					NSLog(@"Routing:Invalid File Path");
//			}
//				
//		}
//		
//		else if  ([destination count] == 2){
//			// New style routing.
//			NSArray					*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
//			NSEnumerator			*serverEnumerator	= [serversArray objectEnumerator];
//			NSDictionary			*aServer;
//			
//			NSString				*description		= nil;			
//			NSString				*routeName			= [destination objectAtIndex:0];
//			NSArray					*routes				= [[NSUserDefaults standardUserDefaults] arrayForKey:@"RoutingRules"];
//			NSEnumerator			*enumerator			= [routes objectEnumerator];
//			NSDictionary			*aRoute				= nil;
//			NSDictionary			*route				= nil;
//			int compression = DCMLosslessQuality;
//			
//			/* 
//			index 0: Server Description
//			index 2: file
//			*/
//			
//			while (aRoute = [enumerator nextObject]) {				
//				NSString *name = [aRoute objectForKey:@"name"];
//				if ([name isEqualToString:routeName]){
//						route = aRoute;
//						break;
//				}				
//			}
//			
//			//we have a route. Now get info
//			if (route) {
//				description = [route objectForKey:@"Description"];
//				//get server. Also check for Bonjour DICOM. Not added yet
//				while (aServer = [serverEnumerator nextObject]){
//					if ([[aServer objectForKey:@"Description"] isEqualToString:description] )  {
//						server = aServer;
//						break;
//					}
//				}
//			}
//			
//			filesToSend = [NSArray arrayWithObject:[destination objectAtIndex:1]];
//			BOOL sendFile = YES;
//			NSArray *rules = [route objectForKey:@"rules"];
//			//need to load DICOM and see if file matches the rules
//			if (rules) {
//				sendFile = NO;
//				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[destination objectAtIndex:1] decodingPixelData:NO];
//				NSEnumerator *ruleEnumerator = [rules objectEnumerator];
//				NSDictionary *rule;
//				while (rule = [ruleEnumerator nextObject]) {
//					int attrIndex = [[rule objectForKey:@"attribute"] intValue];
//					NSString *attrName = nil;
//					NSString *keyValue = [rule objectForKey:@"keyValue"];
//					switch (attrIndex) {
//						case 0: attrName = @"Modality"; break;
//						case 1:	attrName = @"InstitutionName"; break;
//						case 2:	attrName = @"ReferringPhysiciansName"; break;
//						case 3:	attrName = @"PerformingPhysiciansName"; break;
//					}
//					if ([[dcmObject attributeValueWithName:attrName] rangeOfString:keyValue options:NSCaseInsensitiveSearch].location != NSNotFound)
//						sendFile = YES;
//					else
//						sendFile = NO;
//				}
//			}
//
//
//			if (sendFile && server && ts && [[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:1]])
//			{	
//				DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
//										calledAET:[server objectForKey:@"AETitle"] 
//										hostname:[server objectForKey:@"Address"] 
//										port:[[server objectForKey:@"Port"] intValue] 
//										filesToSend:(NSArray *)filesToSend
//										transferSyntax:[[server objectForKey:@"Transfer Syntax"] intValue] 
//										compression: 1.0
//										extraParameters:nil];
//				[storeSCU run:self];
//				[storeSCU release];
//				
//				
//			}
//			//NSLog(@"New style Routing Information");
//		}
//		
//		[sendQueue removeObjectAtIndex:0];
//		[queueLock unlockWithCondition:([sendQueue count] ? QueueHasData : QueueEmpty)];
//		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.04]];
//		[pool release];
//	}	
//}
//
//- (void)addToQueue:(NSArray *)array{
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	[array retain];
//	[queueLock lock];
//	//NSLog(@"AddToQueue:%@", [array description]);
//	[sendQueue mergeWithArray:array];
//	[queueLock unlockWithCondition:QueueHasData];
//	[array release];
//	[pool release];
//}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Database functions

- (NSTimeInterval) databaseLastModification
{
	if( databaseLastModification == 0) databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
	
	return databaseLastModification;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel) return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
    [allBundles release];
    
    return managedObjectModel;
}

- (NSManagedObjectContext *) managedObjectContextLoadIfNecessary:(BOOL) loadIfNecessary
{
    NSError *error = 0L;
    NSString *localizedDescription;
	NSFileManager *fileManager;
	
	if( currentDatabasePath == 0L) return 0L;
	
    if (managedObjectContext) return managedObjectContext;
	
	if( loadIfNecessary == NO) return 0L;
	
	fileManager = [NSFileManager defaultManager];
	
	[persistentStoreCoordinator release];
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	

    NSURL *url = [NSURL fileURLWithPath: currentDatabasePath];

	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{	// NSSQLiteStoreType - NSXMLStoreType
      localizedDescription = [error localizedDescription];
		error = [NSError errorWithDomain:@"OsiriXDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, NSUnderlyingErrorKey, [NSString stringWithFormat:@"Store Configuration Failure: %@", ((localizedDescription != nil) ? localizedDescription : @"Unknown Error")], NSLocalizedDescriptionKey, nil]];
    }
	
	[managedObjectContext setStalenessInterval: 1200];
	
	// This line is very important, if there is NO database.sql file
	[self saveDatabase: currentDatabasePath];
	
    return managedObjectContext;
}

- (NSManagedObjectContext *) managedObjectContext
{
	return [self managedObjectContextLoadIfNecessary: YES];
}

- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files
{
	long						i;
	NSMutableArray				*result		= Nil;
	DicomDirParser				*parsed		= [[DicomDirParser alloc] init: dicomdir];

	[parsed parseArray: files];

	[parsed release];
}

-(NSArray*) addURLToDatabaseFiles:(NSArray*) URLs
{
	long			i;
	NSMutableArray	*localFiles = [NSMutableArray arrayWithCapacity:0];

	// FIRST DOWNLOAD FILES TO LOCAL DATABASE
	
	for( i = 0; i < [URLs count]; i++)
	{
		NSData *data = [NSData dataWithContentsOfURL: [URLs objectAtIndex: i]];
		
		if( data)
		{
			NSString *dstPath;
			
			dstPath = [self getNewFileDatabasePath:@"dcm"];		
			[data writeToFile:dstPath  atomically:YES];
			[localFiles addObject:dstPath];
		}
	}
	
	// THEN, LOAD THEM
	return [self addFilesAndFolderToDatabase: localFiles];
}

- (void) addURLToDatabaseEnd:(id) sender
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

- (void) addURLToDatabase:(id) sender
{
	[urlString setStringValue: [[NSUserDefaults standardUserDefaults] stringForKey: @"LASTURL"]];
	[NSApp beginSheet: urlWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction) selectFilesAndFoldersToAdd:(id) sender
{
    int                 result, i;
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];

    BOOL                isDirectory;
    
	[[self window] makeKeyAndOrderFront:sender];
	
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    
    result = [oPanel runModalForDirectory:0L file:nil types:nil];
    
    if (result == NSOKButton) 
    {
		if( [[oPanel filenames] count] == 1 && [[[[oPanel filenames] objectAtIndex: 0] pathExtension] isEqualToString: @"sql"])  // It's a database file!
		{
			[self openDatabaseIn: [[oPanel filenames] objectAtIndex: 0] Bonjour:NO];
		}
		else
		{	
			NSArray	*newImages = [self addFilesAndFolderToDatabase: [oPanel filenames]];
			
			// Are we adding new files in a album?
			
			//can't add to smart Album
			if( [albumTable selectedRow] > 0)
			{
				NSManagedObject *album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
				
				if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
				{
					NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
					
					for( i = 0; i < [newImages count]; i++)
					{
						NSManagedObject		*object = [newImages objectAtIndex: i];
						[studies addObject: [object valueForKeyPath:@"series.study"]];
					}
					
					needDBRefresh = YES;
					[self outlineViewRefresh];
				}
			}
			
			if( [newImages count] > 0)
			{
				NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
				[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
	}
}

- (void) bonjourRunLoop:(id) sender
{
	[[NSRunLoop currentRunLoop] runMode:@"OsiriXLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

-(void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour
{
	[self waitForRunningProcesses];

	if( isCurrentDatabaseBonjour == NO)
		[self saveDatabase: currentDatabasePath];
	
	[currentDatabasePath release];
	currentDatabasePath = [a retain];
	isCurrentDatabaseBonjour = isBonjour;
	[self loadDatabase: currentDatabasePath];
	
	if( isCurrentDatabaseBonjour)
	{
		bonjourRunLoopTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(bonjourRunLoop:) userInfo:self repeats:YES] retain];
	}
	else
	{
		[bonjourRunLoopTimer release];
		bonjourRunLoopTimer = 0L;
	}
}

-(void) openDatabaseInBonjour:(NSString*) path
{ 
	[self openDatabaseIn: path Bonjour: YES];
}

-(IBAction) openDatabase:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];

	if ([oPanel runModalForDirectory:documentsDirectory() file:nil types:[NSArray arrayWithObject:@"sql"]] == NSFileHandlingPanelOKButton)
	{
		if( [currentDatabasePath isEqualToString: [oPanel filename]] == NO && [oPanel filename] != 0L)
		{
			[self openDatabaseIn: [oPanel filename] Bonjour:NO];
		}
	}
}

-(IBAction) createDatabase:(id) sender
{
	if( isCurrentDatabaseBonjour)
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Database", 0L), NSLocalizedString(@"Cannot create a SQL Index file for a distant database.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		return;
	}
	
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];
	
	[sPanel setRequiredFileType:@"sql"];
	
	if ([sPanel runModalForDirectory:documentsDirectory() file:NSLocalizedString(@"Database.sql", nil)] == NSFileHandlingPanelOKButton)
	{
		if( [currentDatabasePath isEqualToString: [sPanel filename]] == NO && [sPanel filename] != 0L)
		{
			[self waitForRunningProcesses];
			
			[self saveDatabase: currentDatabasePath];
			
			[currentDatabasePath release];
			currentDatabasePath = [[sPanel filename] retain];
			
			[self loadDatabase: currentDatabasePath];
			[self saveDatabase: currentDatabasePath];
		}
	}
}

-(IBAction) createDatabaseFolder:(id) sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];

	[oPanel setCanChooseDirectories: YES];
	[oPanel setCanChooseFiles: NO];
	
	if( [sender tag] == 1)
	{
		[oPanel setPrompt: @"Create"];
		[oPanel setTitle: @"Create a Database Folder"];
	}
	else
	{
		[oPanel setPrompt: @"Open"];
		[oPanel setTitle: @"Open a Database Folder"];
	}
	
	if ([oPanel runModalForDirectory:documentsDirectory() file:nil types:nil] == NSFileHandlingPanelOKButton)
	{
		NSString	*location = [oPanel filename];
		
		if( [[location lastPathComponent] isEqualToString:@"OsiriX Data"])
			location = [location stringByDeletingLastPathComponent];

		if( [[location lastPathComponent] isEqualToString:@"DATABASE"] && [[[location stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:@"OsiriX Data"])
			location = [[location stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
		
		[self openDatabasePath: location];
	}
}

- (void) updateDatabaseModel: (NSString*) path :(NSString*) DBVersion
{
	NSString	*model = [NSString stringWithFormat:@"/OsiriXDB_Previous_DataModel%@.mom", DBVersion];

	if( [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: model]] )
	{
		Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Updating database model...", nil)];
		[splash showWindow:self];
	
		long							x, z, xx, zz, yy;
		NSError							*error = nil;
		NSManagedObjectModel			*previousModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: model]]];
		NSManagedObjectModel			*currentModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
		NSPersistentStoreCoordinator	*previousSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: previousModel];
		NSPersistentStoreCoordinator	*currentSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: currentModel];
		NSManagedObjectContext			*currentContext = [[NSManagedObjectContext alloc] init];
		NSManagedObjectContext			*previousContext = [[NSManagedObjectContext alloc] init];
		
		[currentContext setPersistentStoreCoordinator: currentSC];
		[previousContext setPersistentStoreCoordinator: previousSC];
		
		[previousSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: currentDatabasePath] options:nil error:&error];
		[currentSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: [documentsDirectory() stringByAppendingPathComponent:@"/Database3.sql"]] options:nil error:&error];
		
		NSArray	*previousEntities = [previousModel entities];
		NSEntityDescription		*currentStudyTable, *currentSeriesTable, *currentImageTable, *currentAlbumTable;
		NSArray					*properties;
		
		[currentContext setStalenessInterval: 1];
		[previousContext setStalenessInterval: 1];
		
		// ALBUMS
		NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[previousModel entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		
		error = 0L;
		NSArray *albums = [previousContext executeFetchRequest:dbRequest error:&error];
		for( z = 0; z < [albums count]; z++)
		{
			NSManagedObject			*previousAlbum = [albums objectAtIndex: z];
			
			currentAlbumTable = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: currentContext];
			
			properties = [[[[previousModel entitiesByName] objectForKey:@"Album"] attributesByName] allKeys];
			for( x = 0; x < [properties count]; x++)
			{
				NSString	*name = [properties objectAtIndex: x];
			//	NSLog( @"Album: %@ : %@", name, [previousAlbum valueForKey: name]);
				[currentAlbumTable setValue: [previousAlbum valueForKey: name] forKey: name];
			}
		}
		
		error = 0L;
		[currentContext save: &error];
		
		// Find all current albums
		dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[currentModel entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		
		error = 0L;
		NSArray *currentAlbums = [currentContext executeFetchRequest:dbRequest error:&error];
		NSArray *currentAlbumsNames = [currentAlbums valueForKey:@"name"];
		
		// STUDIES
		dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[previousModel entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		
		error = 0L;
		NSArray *studies = [previousContext executeFetchRequest:dbRequest error:&error];
		[[splash progress] setMaxValue:[studies count]];
		for( z = 0; z < [studies count]; z++)
		{
			NSManagedObject			*previousStudy = [studies objectAtIndex: z];
			
			currentStudyTable = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext: currentContext];
			
			properties = [[[[previousModel entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
			for( x = 0; x < [properties count]; x++)
			{
				NSString	*name = [properties objectAtIndex: x];
			//	NSLog( @"Study: %@ : %@", name, [previousStudy valueForKey: name]);
				[currentStudyTable setValue: [previousStudy valueForKey: name] forKey: name];
			}
			
			// SERIES
			NSArray *series = [[previousStudy valueForKey:@"series"] allObjects];
			for( x = 0; x < [series count]; x++)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				NSManagedObject			*previousSeries = [series objectAtIndex: x];
				
				currentSeriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext: currentContext];
				
				properties = [[[[previousModel entitiesByName] objectForKey:@"Series"] attributesByName] allKeys];
				for( zz = 0; zz < [properties count]; zz++)
				{
					NSString	*name = [properties objectAtIndex: zz];
				//	NSLog( @"Series: %@ : %@", name, [previousSeries valueForKey: name]);
					[currentSeriesTable setValue: [previousSeries valueForKey: name] forKey: name];
				}
				[currentSeriesTable setValue: currentStudyTable forKey: @"study"];
				
				// IMAGES
				NSArray *images = [[previousSeries valueForKey:@"images"] allObjects];
				for( zz = 0; zz < [images count]; zz++)
				{
					NSManagedObject			*previousImage = [images objectAtIndex: zz];
					
					currentImageTable = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext: currentContext];
				
					properties = [[[[previousModel entitiesByName] objectForKey:@"Image"] attributesByName] allKeys];
					for( yy = 0; yy < [properties count]; yy++)
					{
						NSString	*name = [properties objectAtIndex: yy];
					//	NSLog( @"Image: %@ : %@", name, [previousImage valueForKey: name]);
						[currentImageTable setValue: [previousImage valueForKey: name] forKey: name];
					}
					[currentImageTable setValue: currentSeriesTable forKey: @"series"];
				}
				
				[pool release];
			}
			
			NSArray		*storedInAlbums = [[previousStudy valueForKey: @"albums"] allObjects];
			for( zz = 0; zz < [storedInAlbums count]; zz++)
			{
				NSString		*name = [[storedInAlbums objectAtIndex: zz] valueForKey:@"name"];
				
				NSMutableSet	*studiesStoredInAlbum = [[currentAlbums objectAtIndex: [currentAlbumsNames indexOfObject: name]] mutableSetValueForKey:@"studies"];
				[studiesStoredInAlbum addObject: currentStudyTable];
			}
			
			[splash incrementBy:1];
			
			if( z % 100 == 0)
			{
				error = 0L;
				[currentContext save: &error];
			}
		}
		
		error = 0L;
		[currentContext save: &error];
		
		[[NSFileManager defaultManager] removeFileAtPath:currentDatabasePath handler:nil];
		[[NSFileManager defaultManager] movePath:[documentsDirectory() stringByAppendingPathComponent:@"/Database3.sql"] toPath:currentDatabasePath handler:nil];
		
		[previousModel release];
		[currentModel release];
		[previousSC release];
		[currentSC release];
		[currentContext release];
		[previousContext release];
		
		[splash close];
		[splash release];
		
		needDBRefresh = YES;
	}
	else
	{
		NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot understand the model of current saved database... The database will be deleted (no images are lost).", nil), nil, nil, nil);
		[[NSFileManager defaultManager] removeFileAtPath:currentDatabasePath handler:nil];
		NEEDTOREBUILD = YES;
		COMPLETEREBUILD = YES;
	}
}

- (void) recomputePatientUIDs
{
	NSLog( @"recomputePatientUIDs");
	
	// Find all studies
	NSError			*error = 0L;
	NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	NSManagedObjectContext *context = [self managedObjectContext];
	
	[context retain];
	[context lock];
	error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	int i;
	for( i = 0 ; i < [studiesArray count]; i++)
	{
		NSManagedObject *o = [[[[[studiesArray objectAtIndex: i] valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
		DicomFile	*dcm = [[DicomFile alloc] init: [o valueForKey:@"completePath"]];
		
		if( dcm)
		{
			if( [dcm elementForKey:@"patientUID"])
				[[studiesArray objectAtIndex: i] setValue: [dcm elementForKey:@"patientUID"] forKey:@"patientUID"];
		}
		
		[dcm release];
	}
	[context unlock];
	[context release];
}

- (void) showEntireDatabase
{
	timeIntervalType = 0;
	[timeIntervalPopup selectItemWithTag: 0];
	
	[albumTable selectRow:0 byExtendingSelection:NO];
	[self setSearchString: @""];
}

- (void) setDBWindowTitle
{
	if( isCurrentDatabaseBonjour) [[self window] setTitle: [NSString stringWithFormat: NSLocalizedString(@"Bonjour Database (%@)", nil), [currentDatabasePath lastPathComponent]]];
	else [[self window] setTitle: [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), currentDatabasePath]];
	[[self window] setRepresentedFilename: currentDatabasePath];
}

- (NSString*) getDatabaseFolderFor: (NSString*) path
{
	BOOL isDirectory;
			
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory == NO)
		{
			// It is a SQL file
			
			if( [[path pathExtension] isEqualToString:@"sql"] == NO) NSLog( @"**** No SQL extension ???");
			
			NSString	*db = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
			
			if( db == 0L)
			{
				NSString	*p = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DATABASE"];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: p])
				{
					db = [[path stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]; 
				}
				else
				{
					db = [[self documentsDirectory] stringByDeletingLastPathComponent];
				}
			}
			
			return db;
		}
		else
		{
			return path;
		}
	}
	
	return 0L;
}

- (NSString*) getDatabaseIndexFileFor: (NSString*) path
{
	BOOL isDirectory;
			
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory)
		{
			// Default SQL file
			NSString	*index = [[path stringByAppendingPathComponent:@"OsiriX Data"] stringByAppendingPathComponent:@"Database.sql"];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: index])
			{
				[path writeToFile: [[path stringByAppendingPathComponent:@"OsiriX Data"] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] atomically:YES];
				
				return index;
			}
			
			return 0L;
		}
		else
		{
			return path;
		}
	}
	
	return 0L;
}

- (int) findDBPath:(NSString*) path dbFolder:(NSString*) DBFolderLocation
{
	// Is this DB location available in the Source table? If not, add it
	BOOL found = NO;
	int i = 0;
	
	// First, is it the default DB ?
	NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
	
	if( [[defaultPath stringByAppendingPathComponent:@"Database.sql"] isEqualToString: path])
	{
		found = YES;
		i = 0;
		NSLog( @"default DB");
	}
	
	// Second, is it the selected DB ?
	if( found == NO && [bonjourServicesList selectedRow] > 0)
	{
		NSString	*cPath = [[[bonjourBrowser services] objectAtIndex: [bonjourServicesList selectedRow]-1] valueForKey:@"Path"];
		
		BOOL isDirectory;
			
		if( [[NSFileManager defaultManager] fileExistsAtPath:cPath isDirectory: &isDirectory])
		{
			if( isDirectory) cPath = [[cPath stringByAppendingPathComponent: @"OsiriX Data"] stringByAppendingPathComponent: @"Database.sql"];
		}
		
		if( [cPath isEqualToString: path])
		{
			NSLog( @"selected DB");
			
			found = YES;
			i = [bonjourServicesList selectedRow];
		}
	}
	
	// Third, is it available in the list ?
	if( found == NO)
	{
		for( i = 0; i < [[bonjourBrowser services] count]; i++)
		{
			NSString	*type = [[[bonjourBrowser services] objectAtIndex: i] valueForKey:@"type"];
			
			if( [type isEqualToString:@"localPath"])
			{
				NSString	*cPath = [[[bonjourBrowser services] objectAtIndex: i] valueForKey:@"Path"];
				BOOL		isDirectory;
				
				if( [[[cPath pathExtension] lowercaseString] isEqualToString:@"sql"])
				{
					if( [path isEqualToString: cPath])
					{
						found = YES;
						break;
					}
				}
				else
				{
					if( [cPath isEqualToString: DBFolderLocation] && [[path lastPathComponent] isEqualToString:@"Database.sql"])
					{
						found = YES;
						break;
					}
				}
			}
		}
		i++;
	}

	if( found)	return i;
	else return -1;
}

- (void) loadDatabase:(NSString*) path
{
	long        i;
	
	[[AppController sharedAppController] closeAllViewers: self];
	
	shouldDie = YES;
	[matrixLoadIconsLock lock];
	[matrixLoadIconsLock unlock];
	shouldDie = NO;
	
	[albumTable selectRow:0 byExtendingSelection:NO];
	
	NSString	*DBVersion, *DBFolderLocation, *curPath = [[self documentsDirectory] stringByDeletingLastPathComponent];
	
	DBVersion = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"]];
	DBFolderLocation = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
	
	if( isCurrentDatabaseBonjour)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		DBFolderLocation = [self documentsDirectory];
		DBFolderLocation = [DBFolderLocation stringByDeletingLastPathComponent];
	}
	
	if( DBFolderLocation == 0L)
		DBFolderLocation = curPath;
	
	BOOL isDirectory;
	if( [[NSFileManager defaultManager] fileExistsAtPath: DBFolderLocation isDirectory: &isDirectory])
	{
		if( isDirectory == NO)
			DBFolderLocation = curPath;
	}
	else DBFolderLocation = curPath;
	
	if( [DBFolderLocation isEqualToString: curPath] == NO)
	{
		NSLog( @"Update DATABASELOCATIONURL to :%@ from %@", DBFolderLocation, curPath);
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: DBFolderLocation forKey: @"DATABASELOCATIONURL"];
	}
	
	if( isCurrentDatabaseBonjour == NO)
	{
		[[[self documentsDirectory] stringByDeletingLastPathComponent] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] atomically:YES];
		
		i = [self findDBPath: path dbFolder: DBFolderLocation];
		if( i == -1)
		{
			NSLog( @"DB Not found -> we add it");
			
			NSArray			*dbArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
			
			if( [[path lastPathComponent] isEqualToString: @"Database.sql"])	// We will add the folder, since it is the default sql file for a DB folder
			{
				NSString	*name = [[NSFileManager defaultManager] displayNameAtPath: DBFolderLocation];
			
				dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: DBFolderLocation, @"Path", [name stringByAppendingString:@" DB"], @"Description", 0L]];			
			}
			else
			{
				dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: path, @"Path", [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" DB"], @"Description", 0L]];
			}
			
			[[NSUserDefaults standardUserDefaults] setObject: dbArray forKey: @"localDatabasePaths"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:0L];
			
			// Select it
			i = [self findDBPath: path dbFolder: DBFolderLocation];
		}
		
		if( i != [bonjourServicesList selectedRow])
		{
			dontLoadSelectionSource = YES;
			[bonjourServicesList selectRow: i byExtendingSelection: NO];
			dontLoadSelectionSource = NO;
		}
	}
	
	if( DBVersion == 0L) 
		DBVersion = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
	
	NSLog(@"Opening DB: %@ Version: %@ DB Folder: %@", path, DBVersion, DBFolderLocation);
	
	if( [DBVersion isEqualToString: DATABASEVERSION] == NO )
	{
		[self updateDatabaseModel: path :DBVersion];
		
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"recomputePatientUID"];
	}
		
	[[LogManager currentLogManager] resetLogs];
	
	[managedObjectContext lock];
	[managedObjectContext unlock];
//	NSLog( @"retainCount %d", [managedObjectContext retainCount]);
	[managedObjectContext release];
	managedObjectContext = 0L;
	[self setFixedDocumentsDirectory];
	[self managedObjectContext];

	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"recomputePatientUID"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"recomputePatientUID"];
		
		@try
		{
			[self recomputePatientUIDs];
		}
		@catch (NSException *ne)
		{
			NSLog( @"recomputePatientUIDs exception: %@ %@", [ne name], [ne reason]);
		}
	}


	// CHECK IF A DICOMDIR FILE IS AVAILABLE AT SAME LEVEL AS OSIRIX!?
	NSString	*dicomdir = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/DICOMDIR"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dicomdir])
	{
		DICOMDIRCDMODE = YES;
		
		NSMutableArray		*filesArray = [[NSMutableArray alloc] initWithCapacity:0];
		[self addDICOMDIR:dicomdir :filesArray];
		[self addFilesAndFolderToDatabase:filesArray];
        [filesArray release];
	}
	else
	{
		DICOMDIRCDMODE = NO;
		
		if( NEEDTOREBUILD)
		{
			[self ReBuildDatabase:self];
		}
		else
		{
			[self outlineViewRefresh];
		}
	}
	
	NSString *pathTemp = [documentsDirectory() stringByAppendingString:@"/Loading"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:pathTemp])
	{
		[[NSFileManager defaultManager] removeFileAtPath:pathTemp handler: 0L];
	}
	
	[self setDBWindowTitle];
}

-(long) saveDatabase:(NSString*) path
{
	long retError = 0;
	
	if( DICOMDIRCDMODE == NO && isCurrentDatabaseBonjour == NO && currentDatabasePath != 0L)
	{
		@try
		{
			NSManagedObjectModel *model = [self managedObjectModel];
			NSManagedObjectContext *context = [self managedObjectContext];
			NSError *error = nil;
			long	i;
			
			[context retain];
			[context lock];
			
			[context save: &error];
			if (error)
			{
				NSLog(@"error saving DB: %@", [[error userInfo] description]);
				NSLog( @"saveDatabase ERROR: %@", [error localizedDescription]);
				retError = -1L;
			}
			[context unlock];
			[context release];
			
			if( path == 0L) path = currentDatabasePath;
			
			[[NSString stringWithString:DATABASEVERSION] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"] atomically:YES];
			
			[[NSUserDefaults standardUserDefaults] setObject:DATABASEVERSION forKey: @"DATABASEVERSION"];
			[[NSUserDefaults standardUserDefaults] setInteger: DATABASEINDEX forKey: @"DATABASEINDEX"];
		}
		
		@catch( NSException *ne)
		{
			NSLog( [ne name]);
			NSLog( [ne reason]);
		}
	}
	
	return retError;
}

- (void) selectThisStudy:(id) study
{
	NSLog( [study description]);
	[self outlineViewRefresh];
	
	[databaseOutline selectRow: [databaseOutline rowForItem: study] byExtendingSelection: NO];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (void) copyFilesThread : (NSArray*) filesInput
{
	NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	NSString				*INpath = [documentsDirectory() stringByAppendingPathComponent:DATABASEFPATH];
	NSString				*incomingPath = [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH];
	int						i, listenerInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"];
	BOOL					studySelected = NO;
	NSTimeInterval			lastCheck = [NSDate timeIntervalSinceReferenceDate];
	
	[autoroutingInProgress lock];
	
	for( i = 0 ; i < [filesInput count]; i++)
	{
		NSString	*dstPath, *srcPath = [filesInput objectAtIndex:i];
		NSString	*extension = [srcPath pathExtension];
		
		if( [[srcPath stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
		{
			DicomFile	*curFile = [[DicomFile alloc] init: srcPath];
			
			if( curFile)
			{
				if([extension isEqualToString:@""])
					extension = [NSString stringWithString:@"dcm"]; 
				
				int x = 0;
				do
				{
					dstPath = [incomingPath stringByAppendingPathComponent: [NSString stringWithFormat:@"%d-%@", x, [srcPath lastPathComponent]]];
					x++;
				}
				while( [[NSFileManager defaultManager] fileExistsAtPath: dstPath]);
				
				[[NSFileManager defaultManager] copyPath:srcPath toPath: dstPath handler:nil];
				
				if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
				{
					[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
				}
				
				if( i == 0) [self performSelectorOnMainThread:@selector( checkIncoming:) withObject: self waitUntilDone: YES];
				
				else if( studySelected == NO)
				{
					NSManagedObject			*study;
					NSManagedObjectContext	*context = [self managedObjectContext];
					NSError					*error = 0L;
					
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
					[dbRequest setPredicate: [NSPredicate predicateWithFormat:  @"studyInstanceUID == %@", [curFile elementForKey: @"studyID"]]];
					
					[context retain];
					[context lock];
					
					error = 0L;
					NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
					if( [studiesArray count])
					{
						[context unlock];
						[context release];
						
						[self performSelectorOnMainThread:@selector(selectThisStudy:) withObject:[studiesArray objectAtIndex: 0] waitUntilDone: YES];
						studySelected = YES;
					}
					else
					{
						[context unlock];
						[context release];
					}
				}
				else if( listenerInterval > 5 && ([NSDate timeIntervalSinceReferenceDate] - lastCheck) > 5)
				{
					lastCheck = [NSDate timeIntervalSinceReferenceDate];
					[self performSelectorOnMainThread:@selector( checkIncoming:) withObject: self waitUntilDone: YES];
				}
				
				[curFile release];
			}
		}
	}
	
	[self performSelectorOnMainThread:@selector( checkIncoming:) withObject: self waitUntilDone: NO];
	
	[autoroutingInProgress unlock];
	
	if( [filesInput count])
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"EJECTCDDVD"])
		{
			[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:  [filesInput objectAtIndex:0]];
		}
	}
	
	[pool release];
}

-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput
{
	return [self copyFilesIntoDatabaseIfNeeded: filesInput async: NO];
}

-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput async: (BOOL) async
{
	if ([ filesInput count] == 0) return filesInput;
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"COPYDATABASE"] == NO) return filesInput;
	
	NSMutableArray			*newList = [NSMutableArray arrayWithCapacity: [filesInput count]];
	NSString				*INpath = [documentsDirectory() stringByAppendingPathComponent:DATABASEFPATH];
	long					i;
	
	for( i = 0; i < [filesInput count]; i++)
	{
		if( [[[filesInput objectAtIndex: i] stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
		{
			[newList addObject: [filesInput objectAtIndex: i]];
		}
	}
	
	if( [newList count] == 0) return filesInput;
	
	switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASEMODE"])
	{
		case always:
		break;
		
		case notMainDrive:
		{
			NSArray			*pathFilesComponent = [[filesInput objectAtIndex:0] pathComponents];
			
			if( [[[pathFilesComponent objectAtIndex: 1] uppercaseString] isEqualToString:@"VOLUMES"]) //
			{
				NSLog(@"not the main drive!");
			}
			else
			{
				return filesInput;
			}
		}
		break;
		
		case cdOnly:
		{
			NSArray			*pathFilesComponent = [[filesInput objectAtIndex:0] pathComponents];
			BOOL			isACDDVD = NO;
			
			NSLog( [filesInput objectAtIndex:0]);
			
			if( [BrowserController isItCD:pathFilesComponent] == NO) return filesInput;
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
					return filesInput;
					break;
				case NSAlertAlternateReturn:
					[filesInput removeAllObjects];		// zero the array before it is returned.
					return filesInput;
					break;
				}
		break;
	}

    NSString        *OUTpath = [documentsDirectory() stringByAppendingPathComponent:DATABASEPATH];
	BOOL			isDir = YES;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
	
	NSString        *pathname;
    NSMutableArray  *filesOutput = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	if( async)
	{
		[NSThread detachNewThreadSelector:@selector(copyFilesThread:) toTarget:self withObject: filesInput];
	}
	else
	{
		Wait                *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying into Database...",@"Copying into Database...")];
		
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesInput count]];
		
		for( i = 0 ; i < [filesInput count]; i++)
		{
			NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
			
			NSString	*dstPath, *srcPath = [filesInput objectAtIndex:i];
			NSString	*extension = [srcPath pathExtension];
			
			if( [[srcPath stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
			{
				DicomFile	*curFile = [[DicomFile alloc] init: srcPath];
				
				if( curFile)
				{
					[curFile release];
				
					if([extension isEqualToString:@""])
						extension = [NSString stringWithString:@"dcm"]; 
					
					dstPath = [self getNewFileDatabasePath:extension];	
					
					if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil] == YES)
					{
						[filesOutput addObject:dstPath];
					}
					
					if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
					{
						[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
					}
				}
			}
			
			[splash incrementBy:1];
			
			[pool release];
		}
	
		[splash close];
		[splash release];
	}
	
	return filesOutput;
}

- (IBAction) endReBuildDatabase:(id) sender
{
	[NSApp endSheet: rebuildWindow];
	[rebuildWindow orderOut: self];
	
	[self waitForRunningProcesses];
	
	if( [sender tag])
	{
//		switch( [rebuildMode selectedTag])
//		{
//			case 0:
//				REBUILDEXTERNALPROCESS = NO;
//			break;
//			
//			case 1:
//				REBUILDEXTERNALPROCESS = YES;
//			break;
//		}
		
		switch( [rebuildType selectedTag])
		{
			case 0:
				COMPLETEREBUILD = YES;
			break;
			
			case 1:
				COMPLETEREBUILD = NO;
			break;
		}
		
		[self ReBuildDatabase: self];
	}
}

- (IBAction) ReBuildDatabase:(id) sender
{
	BOOL        available;
	long        i;
	
	if( isCurrentDatabaseBonjour) return;
	
	[self waitForRunningProcesses];
	
	BOOL REBUILDEXTERNALPROCESS = YES;

	if( COMPLETEREBUILD)	// Delete the database file
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath])
		{
			[[NSFileManager defaultManager] removeFileAtPath: [currentDatabasePath stringByAppendingString:@" - old"] handler: 0L];
			[[NSFileManager defaultManager] movePath: currentDatabasePath toPath: [currentDatabasePath stringByAppendingString:@" - old"] handler: 0L];
		}
	}
	else
	{
		[self saveDatabase:currentDatabasePath];
	}
	
	[checkIncomingLock lock];
	
	[managedObjectContext lock];
	[managedObjectContext unlock];
	[managedObjectContext release];
	managedObjectContext = 0L;
	
	
	
	[databaseOutline reloadData];
	
	NSMutableArray				*filesArray;
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Step 1: Checking files...", nil)];
	[wait showWindow:self];
	
	filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
			
	// SCAN THE DATABASE FOLDER, TO BE SURE WE HAVE EVERYTHING!
	
	NSString	*aPath = [documentsDirectory() stringByAppendingPathComponent:DATABASEPATH];
	NSString	*incomingPath = [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH];
	BOOL		isDir = YES;
	long		totalFiles = 0;
	if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:aPath attributes:nil];
	
	// In the DATABASE FOLDER, we have only folders! Move all files that are wrongly there to the INCOMING folder.... and then scan these folders containing the DICOM files
	
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for( i = 0; i < [dirContent count]; i++)
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]];
		id fileType = [[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey:NSFileType];
		if ([fileType isEqual:NSFileTypeRegular])
		{
			[[NSFileManager defaultManager] movePath:itemPath toPath:[incomingPath stringByAppendingPathComponent: [itemPath lastPathComponent]] handler: 0L];
		}
		else totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
	}
	
	[wait close];
	[wait release];

	dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	
	
	Wait	*REBUILDEXTERNALPROCESSProgress = 0L;
	
	if( REBUILDEXTERNALPROCESS)
	{
		[managedObjectContext release];
		managedObjectContext = 0L;
		
		REBUILDEXTERNALPROCESSProgress = [[Wait alloc] initWithString: [NSString stringWithFormat: NSLocalizedString(@"Adding %@ files...", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt:totalFiles]]]];
		[REBUILDEXTERNALPROCESSProgress showWindow:self];
		[[REBUILDEXTERNALPROCESSProgress progress] setMaxValue: totalFiles];
	}
	
	NSLog( @"Start Rebuild");
	
	for( i = 0; i < [dirContent count]; i++)
	{
		NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
		
		NSString	*curDir = [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]];
		NSArray		*subDir = [[NSFileManager defaultManager] directoryContentsAtPath: [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]]];
		long		z;
		
		for( z = 0;  z < [subDir count]; z++)
		{
			if( [[subDir objectAtIndex: z] characterAtIndex: 0] != '.')
				[filesArray addObject: [curDir stringByAppendingPathComponent: [subDir objectAtIndex: z]]];
		}
		
		if( REBUILDEXTERNALPROCESS)
		{
			[self callAddFilesToDatabaseSafe: filesArray];
			
			[filesArray release];
			filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
			
			[REBUILDEXTERNALPROCESSProgress incrementBy: [[[[NSFileManager defaultManager] fileAttributesAtPath: curDir traverseLink: YES] objectForKey: NSFileReferenceCount] intValue]];
		}
		
		[pool release];
	}
	
	if( REBUILDEXTERNALPROCESS == NO)
	{
		[[self addFilesToDatabase: filesArray onlyDICOM:NO safeRebuild:NO produceAddedFiles:NO] valueForKey:@"completePath"];
	}
	else
	{
		[REBUILDEXTERNALPROCESSProgress close];
		[REBUILDEXTERNALPROCESSProgress release];
		REBUILDEXTERNALPROCESSProgress = 0L;
	}
	
	NSLog( @"End Rebuild");

	[filesArray release];
	
	Wait  *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Step 3: Cleaning Database...", 0L)];
	
	[splash showWindow:self];
	
	NSManagedObjectContext		*context = [self managedObjectContext];
	NSManagedObjectModel		*model = [self managedObjectModel];
	
	[context retain];
	[context lock];
	
	NSFetchRequest	*dbRequest;
	NSError			*error = 0L;
	
	if( COMPLETEREBUILD == NO)
	{
		// FIND ALL images, and REMOVE non-available images
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		error = 0L;
		NSArray *imagesArray = [context executeFetchRequest:dbRequest error:&error];
		
		[[splash progress] setMaxValue:[imagesArray count]/50];
		
		// Find unavailable files
		for( i = 0; i < [imagesArray count]; i++)
		{
			NSManagedObject       *aFile = [imagesArray objectAtIndex:i];
			
			FILE *fp;
			
			fp = fopen( [[aFile valueForKey:@"completePath"] UTF8String], "r");
			if( fp)
			{
				fclose( fp);
			}
			else [context deleteObject: aFile];
			
			if( i % 50 == 0) [splash incrementBy:1];
		}
	}

	dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
	
	if ([seriesArray count] > 0)
	{
		for( i = 0; i < [seriesArray count]; i++)
		{
			if( [[[seriesArray objectAtIndex: i] valueForKey:@"noFiles"] intValue] == 0)
			{
				[context deleteObject: [seriesArray objectAtIndex: i]];
			}
		}
	}
	
	dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	NSString	*basePath = [NSString stringWithFormat: @"%@/REPORTS/", documentsDirectory()];
	
	if ([studiesArray count] > 0)
	{
		for( i = 0; i < [studiesArray count]; i++)
		{
			BOOL deleted = NO;
			
			if( [[[studiesArray objectAtIndex: i] valueForKey:@"series"] count] == 0)
			{
				deleted = YES;
				[context deleteObject: [studiesArray objectAtIndex: i]];
			}
			
			if( [[[studiesArray objectAtIndex: i] valueForKey:@"noFiles"] intValue] == 0)
			{
				if( deleted == NO) [context deleteObject: [studiesArray objectAtIndex: i]];
			}
			
			// SCAN THE STUDIES FOR REPORTS
			NSString	*reportPath;
			
			reportPath = [basePath stringByAppendingFormat:@"%@.doc",[Reports getUniqueFilename:[studiesArray objectAtIndex: i]]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath]) [[studiesArray objectAtIndex: i] setValue:reportPath forKey:@"reportURL"];
			
			reportPath = [basePath stringByAppendingFormat:@"%@.rtf",[Reports getUniqueFilename:[studiesArray objectAtIndex: i]]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath]) [[studiesArray objectAtIndex: i] setValue:reportPath forKey:@"reportURL"];
		}
	}
	
	[self saveDatabase: currentDatabasePath];
	
	[splash close];
	[splash release];
	
	[self outlineViewRefresh];
	
	[checkIncomingLock unlock];
	
	[context unlock];
	[context release];
	
	COMPLETEREBUILD = NO;
	NEEDTOREBUILD = NO;
}

- (IBAction) ReBuildDatabaseSheet: (id)sender
{
	if( isCurrentDatabaseBonjour)
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Database Cleaning", 0L), NSLocalizedString(@"Cannot rebuild a distant database.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		return;
	}

	// Wait if there is something in the delete queue
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[self emptyDeleteQueueThread];
	
	[deleteInProgress lock];
	[deleteInProgress unlock];
	//
	
	// Wait if there is something in the autorouting queue
	[autoroutingInProgress lock];
	[autoroutingInProgress unlock];
	
	[self emptyAutoroutingQueue:self];
	
	[autoroutingInProgress lock];
	[autoroutingInProgress unlock];
	
	long i;
	long totalFiles = 0;
	NSString	*aPath = [documentsDirectory() stringByAppendingPathComponent:DATABASEPATH];
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for( i = 0; i < [dirContent count]; i++)
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]];
		totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
	}

	[noOfFilesToRebuild setIntValue: totalFiles];
	
	long durationFor1000;
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TOOLKITPARSER"] == 0)
	{
		durationFor1000 = 18;
		[warning setHidden: NO];
	}
	else
	{
		durationFor1000 = 9;
		[warning setHidden: YES];
	}
	
	long totalSeconds = totalFiles * durationFor1000 / 1000;
	long hours = (totalSeconds / 3600);
	long minutes = ((totalSeconds / 60) - hours*60);
	long seconds = (totalSeconds % 60);

	if( minutes < 1) minutes = 1;

	if( hours) [estimatedTime setStringValue:[NSString stringWithFormat:@"%i hour(s), %i minutes", hours, minutes]];
	else [estimatedTime setStringValue:[NSString stringWithFormat:@"%i minutes", minutes]];
	
	[NSApp beginSheet: rebuildWindow
			modalForWindow: [self window]
			modalDelegate: nil
			didEndSelector: nil
			contextInfo: nil];
}

- (void) autoCleanDatabaseDate:(id) sender
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	if( isCurrentDatabaseBonjour) return;
	if( managedObjectContext == 0L) return;
	if( [NSDate timeIntervalSinceReferenceDate] - gLastActivity < 60*10) return;
	
	if( [checkIncomingLock tryLock])
	{
		NSError					*error = 0L;
		long					i;
		NSFetchRequest			*request = [[[NSFetchRequest alloc] init] autorelease];
		NSArray					*logArray;
		NSDate					*producedDate = [[NSDate date] addTimeInterval: -[defaults integerForKey:@"LOGCLEANINGDAYS"]*60*60*24];
		NSManagedObjectContext	*context = [self managedObjectContext];
		NSPredicate				*predicate = [NSPredicate predicateWithFormat: @"startTime <= CAST(%lf, \"NSDate\")", [producedDate timeIntervalSinceReferenceDate]];
		
		[request setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"LogEntry"]];
		[request setPredicate: predicate];
		
		[context retain];
		[context lock];
		error = 0L;
		logArray = [context executeFetchRequest:request error:&error];
		
		for( i = 0; i < [logArray count]; i++)
			[context deleteObject: [logArray objectAtIndex: i]];
		
		[context unlock];
		[context release];
		
		[checkIncomingLock unlock];
	}
	
	[self buildAllThumbnails: self];
	
	if( [defaults boolForKey:@"AUTOCLEANINGDATE"])
	{
		if( [defaults boolForKey: @"AUTOCLEANINGDATEPRODUCED"] == YES || [defaults boolForKey: @"AUTOCLEANINGDATEOPENED"] == YES)
		{
			if( [checkIncomingLock tryLock])
			{
			//	NSLog(@"lock autoCleanDatabaseDate");
				
				NSError				*error = 0L;
				long				i, x;
				NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
				NSPredicate			*predicate = [NSPredicate predicateWithValue:YES];
				NSArray				*studiesArray;
				NSDate				*now = [NSDate date];
				NSDate				*producedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"] intValue]*60*60*24];
				NSDate				*openedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEOPENEDDAYS"] intValue]*60*60*24];
				NSMutableArray		*toBeRemoved = [NSMutableArray arrayWithCapacity: 0];
				NSManagedObjectContext *context = [self managedObjectContext];
				
				[request setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
				[request setPredicate: predicate];
				
				[context retain];
				[context lock];
				
				error = 0L;
				studiesArray = [context executeFetchRequest:request error:&error];
				
				NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease];
				studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
				
				for( i = 0; i < [studiesArray count]; i++)
				{
					NSString	*patientID = [[studiesArray objectAtIndex: i] valueForKey:@"patientID"];
					NSDate		*studyDate = [[studiesArray objectAtIndex: i] valueForKey:@"date"];
					NSDate		*openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
					
					if( openedStudyDate == 0L) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
					long		to, from = i;
					
					while( i < [studiesArray count]-1 && [patientID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
					{
						i++;
						studyDate = [studyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"date"]];
						if( [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]) openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]];
						else openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"]];
					}
					to = i;
					
					BOOL dateProduced = YES, dateOpened = YES;
					
					if( [defaults boolForKey: @"AUTOCLEANINGDATEPRODUCED"])
					{
						if( [producedDate compare: studyDate] == NSOrderedDescending)
						{
							dateProduced = YES;
						}
						else dateProduced = NO;
					}
					
					if( [defaults boolForKey: @"AUTOCLEANINGDATEOPENED"])
					{
						if( openedStudyDate == 0L) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
					
						if( [openedDate compare: openedStudyDate] == NSOrderedDescending)
						{
							dateOpened = YES;
						}
						else dateOpened = NO;
					}
					
					if(  dateProduced == YES && dateOpened == YES)
					{
						for( x = from; x <= to; x++) if( [toBeRemoved containsObject:[studiesArray objectAtIndex: x]] == NO) [toBeRemoved addObject: [studiesArray objectAtIndex: x]];
					}
				}
				
				for (i = 0; i<[toBeRemoved count];i++)					// Check if studies are in an album or added this week.  If so don't autoclean that study from the database (DDP: 051108).
				{
					if ( [[[toBeRemoved objectAtIndex: i] valueForKey: @"albums"] count] > 0 ||
					  [[[toBeRemoved objectAtIndex: i] valueForKey: @"dateAdded"] timeIntervalSinceNow] > -60*60*7*24.0 )  // within 7 days
					{
						[toBeRemoved removeObjectAtIndex: i];
						i--;
					}
				}
				
				if( [defaults boolForKey: @"AUTOCLEANINGCOMMENTS"])
				{
					for (i = 0; i<[toBeRemoved count];i++)
					{
						NSString	*comment = [[toBeRemoved objectAtIndex: i] valueForKey: @"comment"];
						
						if( comment == 0L) comment = @"";
						
						if ([comment rangeOfString:[defaults stringForKey: @"AUTOCLEANINGCOMMENTSTEXT"] options:NSCaseInsensitiveSearch].location == NSNotFound)
						{
							if( [defaults integerForKey: @"AUTOCLEANINGDONTCONTAIN"] == 0)
							{
								[toBeRemoved removeObjectAtIndex: i];
								i--;
							}
						}
						else
						{
							if( [defaults integerForKey: @"AUTOCLEANINGDONTCONTAIN"] == 1)
							{
								[toBeRemoved removeObjectAtIndex: i];
								i--;
							}
						}
					}
				}

				if( [toBeRemoved count] > 0)							// (DDP: 051109) was > 1, i.e. required at least 2 studies out of date to be removed.
				{														// Stop thread
					shouldDie = YES;
					[matrixLoadIconsLock lock];
					[matrixLoadIconsLock unlock];
					shouldDie = NO;
					
					NSLog(@"Will delete: %d studies", [toBeRemoved count]);
					
					Wait *wait = [[Wait alloc] initWithString: NSLocalizedString(@"Database Auto-Cleaning...", nil)];
					[wait showWindow:self];
					[wait setCancel: YES];
					[[wait progress] setMaxValue:[toBeRemoved count]];
					
					if( [defaults boolForKey: @"AUTOCLEANINGDELETEORIGINAL"])
					{
						NSMutableArray	*nonLocalImagesPath = [NSMutableArray array];
						
						for (x = 0; x< [toBeRemoved count];x++)
						{
							NSManagedObject	*curObj = [toBeRemoved objectAtIndex: x];
							
							if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
							{
								NSArray	*seriesArray = [self childrenArray: curObj];
								
								for( i = 0 ; i < [seriesArray count]; i++)
								{
									NSArray		*imagesArray = [self imagesArray: [seriesArray objectAtIndex: i]];
									
									[nonLocalImagesPath addObjectsFromArray: [[imagesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"]];
								}
							}
							else NSLog( @"Uh? Autocleaning, object strange...");
						}
						
						for( i = 0; i < [nonLocalImagesPath count]; i++)
						{
							[[NSFileManager defaultManager] removeFileAtPath:[nonLocalImagesPath objectAtIndex: i] handler:nil];
							
							if( [[[nonLocalImagesPath objectAtIndex: i] pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
							{
								[[NSFileManager defaultManager] removeFileAtPath:[[[nonLocalImagesPath objectAtIndex: i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
							}
							
							if( [[[nonLocalImagesPath objectAtIndex: i] pathExtension] isEqualToString:@"zip"])		// ZIP -> DELETE XML
							{
								[[NSFileManager defaultManager] removeFileAtPath:[[[nonLocalImagesPath objectAtIndex: i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"] handler:nil];
							}
						}
					}
					
					for( i = 0; i < [toBeRemoved count]; i++)
					{
						[context deleteObject: [toBeRemoved objectAtIndex: i]];
						
						[wait incrementBy:1];
						if( [wait aborted])
							i = [toBeRemoved count];
					}
					
					[self saveDatabase: currentDatabasePath];
					
					[self outlineViewRefresh];
					
					[wait close];
					[wait release];
				}
				
				[context unlock];
				[context release];
				
				[checkIncomingLock unlock];
			}
		}
	}
}

- (void) autoCleanDatabaseFreeSpace:(id) sender
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	if( isCurrentDatabaseBonjour) return;
	
	if( [defaults boolForKey:@"AUTOCLEANINGSPACE"])
	{
		NSDictionary	*fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath: currentDatabasePath];
		
		unsigned long long free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
		
		if( free <= 0)
		{
			NSLog( @"*** autoCleanDatabaseFreeSpace free <= 0 ??");
			NSLog( currentDatabasePath);
			
			return;
		}
		
		free /= 1024;
		free /= 1024;
		
 		NSLog(@"HD Free Space: %d MB", (long) free);
		
		if( (int) free < [[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue])
		{
			NSLog(@"Limit Reached - Starting autoCleanDatabaseFreeSpace");
			
			NSError				*error = 0L;
			long				i, x;
			NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
			NSPredicate			*predicate = [NSPredicate predicateWithValue:YES];
			NSArray				*studiesArray;
			NSManagedObjectContext *context = [self managedObjectContext];
			
			[context retain];
			[context lock];
			[request setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
			[request setPredicate: predicate];
			
			do
			{
				NSTimeInterval		producedInterval = 0;
				NSTimeInterval		openedInterval = 0;
				NSMutableArray		*toBeRemoved = [NSMutableArray arrayWithCapacity: 0];
				NSManagedObject		*oldestStudy = 0L, *oldestOpenedStudy = 0L;
				NSDate				*openedDate;
				
				error = 0L;
				studiesArray = [context executeFetchRequest:request error:&error];
				
				NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease];
				studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
				
				if( [studiesArray count] > 2)
				{
					for( i = 0; i < [studiesArray count]; i++)
					{
						NSString	*patientID = [[studiesArray objectAtIndex: i] valueForKey:@"patientID"];
						long		to, from = i;
						
						if( [[[studiesArray objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)
						{
							oldestStudy = [studiesArray objectAtIndex: i];
							producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
						}
						
						openedDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
						if( openedDate == 0L) openedDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
						
						if( [openedDate timeIntervalSinceNow] < openedInterval)
						{
							oldestOpenedStudy = [studiesArray objectAtIndex: i];
							openedInterval = [openedDate timeIntervalSinceNow];
						}
						
						while( i < [studiesArray count]-1 && [patientID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
						{
							i++;
							if( [[[studiesArray objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)
							{
								oldestStudy = [studiesArray objectAtIndex: i];
								producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
							}
							
							openedDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
							if( openedDate == 0L) openedDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
							
							if( [openedDate timeIntervalSinceNow] < openedInterval)
							{
								oldestOpenedStudy = [studiesArray objectAtIndex: i];
								openedInterval = [openedDate timeIntervalSinceNow];
							}
						}
						to = i;
					}
				}
				
				if( [defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"])
				{
					if( oldestStudy)
					{
						NSLog( @"delete oldestStudy: %@", [oldestStudy valueForKey:@"patientUID"]);
						[context deleteObject: oldestStudy];
					}
				}
				
				if( [defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"])
				{
					if( oldestOpenedStudy)
					{
						NSLog( @"delete oldestOpenedStudy: %@", [oldestOpenedStudy valueForKey:@"patientUID"]);
						[context deleteObject: oldestOpenedStudy];
					}
				}
				
				[deleteInProgress lock];
				[deleteInProgress unlock];
				
				[self emptyDeleteQueueThread];
				
				[deleteInProgress lock];
				[deleteInProgress unlock];
				
				fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath: currentDatabasePath];
				
				free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
				free /= 1024;
				free /= 1024;
				NSLog(@"HD Free Space: %d MB", (long) free);
			}
			while( (long) free < [[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue] && [studiesArray count] > 2);
			
			[self saveDatabase: currentDatabasePath];
			
			[context unlock];
			[context release];
			
			// This will do a outlineViewRefresh
			if( [newFilesConditionLock tryLock])
				[newFilesConditionLock unlockWithCondition: 1];
		}
	}
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
	long i;
	
	for(  i = 0; i < [[sender menu] numberOfItems]; i++) [[[sender menu] itemAtIndex: i] setState: NSOffState];
	
	[[[sender menu] itemWithTag: [sender tag]] setState: NSOnState];
	[toolbarSearchItem setLabel: [NSString stringWithFormat: NSLocalizedString(@"Search by %@", nil), [sender title]]];
	searchType = [sender tag];
	//create new Filter Predicate when changing searchType ans set searchString to nil;
	[self setSearchString:nil];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (IBAction) customIntervalNow:(id) sender
{
	if( [sender tag] == 0)
	{
		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	}
	
	if( [sender tag] == 1)
	{
		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	}
}

- (IBAction) endCustomInterval:(id) sender
{
	if( [sender tag] == 1)
	{
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
			[timeIntervalStart release];		timeIntervalStart = 0L;
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 1:	// 1 hour
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 2:	// 6 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*6] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 3:	// 12 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*12] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 7:	// 24 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*24] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 8:	// 48 hours
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: -60*60*48] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		break;
		
		case 4:	// Today
		{
			NSCalendarDate *now = [NSCalendarDate calendarDate];
			NSCalendarDate *start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
			
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [start timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		}
		break;
		
		case 5:	// One week
		{
			NSCalendarDate *now		= [NSCalendarDate calendarDate];
			NSCalendarDate *oneWeek = [now dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0];
			
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [oneWeek timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
		}
		break;
		
		case 6:	// One month
		{
			NSCalendarDate *now		= [NSCalendarDate calendarDate];
			NSCalendarDate *oneWeek = [now dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
	
			[timeIntervalStart release];		timeIntervalStart = [[NSDate dateWithTimeIntervalSinceNow: [oneWeek timeIntervalSinceDate: now]] retain];
			[timeIntervalEnd release];			timeIntervalEnd = 0L;
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
				modalForWindow: [self window]
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
	NSMutableString		*pred = [NSMutableString stringWithString: string];
	
	// DATES
	
	// Today:
	NSCalendarDate	*now = [NSCalendarDate calendarDate];
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
	
	NSDictionary	*sub = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*1] ],			@"$LASTHOUR",
																		[NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*6] ],			@"$LAST6HOURS",
																		[NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*12] ],			@"$LAST12HOURS",
																		[NSString stringWithFormat:@"\"%@\"", start ],										@"$TODAY",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24] ],			@"$YESTERDAY",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*2] ],		@"$2DAYS",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*7] ],		@"$WEEK",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31] ],		@"$MONTH",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31*2] ],	@"$2MONTHS",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31*3] ],	@"$3MONTHS",
																		[NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*365] ],		@"$YEAR",
																		0L];
	
	NSEnumerator *enumerator = [sub keyEnumerator];
	NSString *key;
			
	while ((key = [enumerator nextObject]))
	{
		[pred replaceOccurrencesOfString:key withString: [sub valueForKey: key]	options: NSCaseInsensitiveSearch	range: NSMakeRange(0, [pred length])];
	}
	
	NSPredicate *predicate;
	
	if( [string isEqualToString:@""]) predicate = [NSPredicate predicateWithValue: YES];
	else
	{
		predicate = [NSPredicate predicateWithFormat: pred];
	}
	return predicate;
}

- (NSPredicate*) smartAlbumPredicate:(NSManagedObject*) album
{
	NSPredicate	*pred = 0L;
	
	@try
	{
		pred = [self smartAlbumPredicateString: [album valueForKey:@"predicateString"]];
	}
	
	@catch( NSException *ne)
	{
		pred = [NSPredicate predicateWithValue: NO];
		
		NSLog( @"filter error %@ : %@", [ne name] ,[ne reason]);
	}
	
	return pred;
}

- (void) outlineViewRefresh		// This function creates the 'root' array for the outlineView
{
	if( [[self window] isVisible] == NO) return;
	
	NSError				*error = 0L;
	long				i;
	NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
	NSPredicate			*predicate = 0L, *subPredicate = 0L;
	NSString			*description = [NSString string];
	NSIndexSet			*selectedRowIndexes =  [databaseOutline selectedRowIndexes];
	NSMutableArray		*previousObjects = [NSMutableArray arrayWithCapacity:0];
	NSArray				*albumArrayContent = 0L;
	BOOL				filtered = NO;
	
	if( needDBRefresh) [albumNoOfStudiesCache removeAllObjects];
	needDBRefresh = NO;
	
	unsigned long index = [selectedRowIndexes firstIndex];
	while (index != NSNotFound)
	{
		[previousObjects addObject: [databaseOutline itemAtRow: index]];
		index = [selectedRowIndexes indexGreaterThanIndex:index];
	}
	
	[request setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
	
	predicate = [NSPredicate predicateWithValue:YES];
	
	if( isCurrentDatabaseBonjour)
	{
		int rowIndex = [bonjourServicesList selectedRow];
		
		if( rowIndex <= 0) NSLog( @"******** rowIndex <= 0");
		
		NSDictionary *dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
		
		if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [[dict valueForKey:@"service"] name]];
		else description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [dict valueForKey:@"Description"]];
		
	}
	else description = [description stringByAppendingFormat:NSLocalizedString(@"Local Database / ", nil)];
	
	// ********************
	// ALBUMS
	// ********************
	
	if( [albumTable selectedRow] > 0)
	{
		NSManagedObject	*album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
		NSString		*albumName = [album valueForKey:@"name"];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
		{
			subPredicate = [self smartAlbumPredicate: album];
			description = [description stringByAppendingFormat:NSLocalizedString(@"Smart Album selected: %@", nil), albumName];
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, 0L]];
		}
		else
		{
			albumArrayContent = [[album valueForKey:@"studies"] allObjects];
			description = [description stringByAppendingFormat:NSLocalizedString(@"Album selected: %@", nil), albumName];
		}
	}
	else description = [description stringByAppendingFormat:NSLocalizedString(@"No album selected", nil)];
	
	// ********************
	// TIME INTERVAL
	// ********************
	
	[self computeTimeInterval];
	
	if( timeIntervalStart != 0L || timeIntervalEnd != 0L)
	{
		NSString*		sdf = [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateFormat"];	//stringByAppendingFormat:@"-%H:%M"];
		NSDictionary*	locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		
		if( timeIntervalStart != 0L && timeIntervalEnd != 0L)
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate]];
		
			description = [description stringByAppendingFormat: NSLocalizedString(@" / Time Interval: from: %@ to: %@", nil), [timeIntervalStart descriptionWithCalendarFormat:sdf timeZone:0L locale:locale],  [timeIntervalEnd descriptionWithCalendarFormat:sdf timeZone:0L locale:locale] ];
		}
		else
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat:NSLocalizedString(@" / Time Interval: since: %@", nil), [timeIntervalStart descriptionWithCalendarFormat:sdf timeZone:0L locale:locale]];
		}
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, 0L]];
		filtered = YES;
	}
	
	// ********************
	// SEARCH FIELD
	// ********************
	
	if ([self filterPredicate])
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [self filterPredicate], 0L]];
		description = [description stringByAppendingString: [self filterPredicateDescription]];
		filtered = YES;
	}
	
	[request setPredicate: predicate];
	
	NSManagedObjectContext *context = [self managedObjectContext];
	
	[context retain];
	[context lock];
	error = 0L;
	[outlineViewArray release];
	
	@try
	{
		if( albumArrayContent) outlineViewArray = [albumArrayContent filteredArrayUsingPredicate: predicate];
		else outlineViewArray = [context executeFetchRequest:request error:&error];
		
		if( [albumNoOfStudiesCache count] > [albumTable selectedRow] && filtered == NO)
		{
			[albumNoOfStudiesCache replaceObjectAtIndex:[albumTable selectedRow] withObject:[NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[outlineViewArray count]]]]];
		}
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"OutlineRefresh exception: %@", [ne description]);
		[request setPredicate: [NSPredicate predicateWithValue:YES]];
		outlineViewArray = [context executeFetchRequest:request error:&error];
	}
	
	if( [albumTable selectedRow] > 0) filtered = YES;
	
	if( filtered == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogether"] && [outlineViewArray count] > 0 && [outlineViewArray count] < 300)
	{
		NSMutableArray	*patientPredicateArray = [NSMutableArray array];
		
		for( i = 0; i < [outlineViewArray count] ; i++)
		{
			[patientPredicateArray addObject: [NSPredicate predicateWithFormat:  @"(patientID == %@)", [[outlineViewArray objectAtIndex: i] valueForKey:@"patientID"]]];
		}
		
		[request setPredicate: [NSCompoundPredicate orPredicateWithSubpredicates: patientPredicateArray]];
		error = 0L;
		[originalOutlineViewArray release];
		originalOutlineViewArray = [outlineViewArray retain];
		outlineViewArray = [context executeFetchRequest:request error:&error];
	}
	else
	{
		[originalOutlineViewArray release];
		originalOutlineViewArray = 0L;
	}
	
	long images = 0;
	for( i = 0; i < [outlineViewArray count]; i++)
	{
		images += [[[outlineViewArray objectAtIndex: i] valueForKey:@"noFiles"] intValue];
	}
	
	description = [description stringByAppendingFormat: NSLocalizedString(@" / Result = %@ studies (%@ images)", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt: [outlineViewArray count]]], [numFmt stringForObjectValue:[NSNumber numberWithInt:images]]];
	
	NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray * sortDescriptors;
	if( [databaseOutline sortDescriptors] == 0L || [[databaseOutline sortDescriptors] count] == 0)
	{
		// By default sort by name
		NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		sortDescriptors = [NSArray arrayWithObjects: sort, sortdate, 0L];
	}
	else if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"])
	{
		sortDescriptors = [NSArray arrayWithObjects: [[databaseOutline sortDescriptors] objectAtIndex: 0], sortdate, 0L];
	}
	else sortDescriptors = [databaseOutline sortDescriptors];
	
	outlineViewArray = [[outlineViewArray sortedArrayUsingDescriptors: sortDescriptors] retain];
	
	[context unlock];
	[context release];
	
	[databaseOutline reloadData];
	
	for( i = 0; i < [outlineViewArray count]; i++)
	{
		if( [[[outlineViewArray objectAtIndex: i] valueForKey:@"expanded"] boolValue]) [databaseOutline expandItem: [outlineViewArray objectAtIndex: i]];
	}
	
	if( [previousObjects count] > 0)
	{
		for( i = 0; i < [previousObjects count]; i++)
		{
			if( i == 0) [databaseOutline selectRow: [databaseOutline rowForItem: [previousObjects objectAtIndex: i]] byExtendingSelection: NO];
			else [databaseOutline selectRow: [databaseOutline rowForItem: [previousObjects objectAtIndex: i]] byExtendingSelection: YES];
		}
	}
	
	if( [outlineViewArray count] > 0 )
		[[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: 0L];
	
	[databaseDescription setStringValue: description];
	
	[albumTable reloadData];
}

- (BonjourBrowser *) bonjourBrowser;
{
	return bonjourBrowser;
}

-(void) checkBonjourUpToDateThread:(id) sender
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	[checkIncomingLock lock];
	[checkBonjourUpToDateThreadLock lock];
	
	NSString	*path = [bonjourBrowser getDatabaseFile: [bonjourServicesList selectedRow]-1];
	if( path != 0L)
	{
		[self performSelectorOnMainThread:@selector(openDatabaseInBonjour:) withObject:path waitUntilDone:YES];
	}
	
	[checkIncomingLock unlock];
	[checkBonjourUpToDateThreadLock unlock];
	
	[self performSelectorOnMainThread:@selector(outlineViewRefresh) withObject:nil waitUntilDone:YES];
	
	[pool release];
}


-(void) checkBonjourUpToDate:(id) sender
{
	[self testAutorouting];
	
	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	if( managedObjectContext == 0L) return;
	
	if( isCurrentDatabaseBonjour)
	{
		long		i;
		NSArray		*winList = [NSApp windows];
		BOOL		doit = YES;
		
		for( i = 0; i < [winList count]; i++)
		{
			if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) doit = NO;
		}
		
		if( doit)
		{
			if( [bonjourBrowser isBonjourDatabaseUpToDate: [bonjourServicesList selectedRow]-1] == NO)
			{
				[self syncReportsIfNecessary: [bonjourServicesList selectedRow]-1];
				
				if( [checkIncomingLock tryLock])
				{
					[NSThread detachNewThreadSelector: @selector(checkBonjourUpToDateThread:) toTarget:self withObject: self];
					[checkIncomingLock unlock];
				}
				else NSLog(@"checkBonjourUpToDate locked...");
			}
		}
		
		[self syncReportsIfNecessary: [bonjourServicesList selectedRow]-1];
	}
}

-(void) refreshSmartAlbums
{
	int i;
	NSArray	*a = [self albumArray];
	
	if( [a count] == [albumNoOfStudiesCache count])
	{
		for( i = 0; i < [a count]; i++)
		{
			if( [[[a objectAtIndex: i] valueForKey:@"smartAlbum"] boolValue] == YES) [albumNoOfStudiesCache replaceObjectAtIndex:i withObject:@""];
		}
	}
	
	[albumTable reloadData];
}

-(void) refreshDatabase:(id) sender
{
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	if( [databaseOutline editedRow] != -1) return;
	
	if( needDBRefresh || [[[[self albumArray] objectAtIndex: [albumTable selectedRow]] valueForKey:@"smartAlbum"] boolValue] == YES)
	{
		if( [checkIncomingLock tryLock])
		{
			[self outlineViewRefresh];
			[checkIncomingLock unlock];
		}
		else NSLog(@"refreshDatabase locked...");
	}
	else
	{
		[self refreshSmartAlbums];
		[databaseOutline reloadData];
	}
}

- (NSArray*) childrenArray: (NSManagedObject*) item onlyImages:(BOOL) onlyImages
{
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		[managedObjectContext lock];
		
		// Sort images with "instanceNumber"
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		NSArray *sortedArray = [[[item valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		
		[managedObjectContext unlock];
		
		return sortedArray;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
	{
		[managedObjectContext lock];
		
		// Sort series with "id" & date
		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors;
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, 0L];
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, 0L];
		[sortid release];
		[sortdate release];
		
		NSArray *sortedArray;
		
		if( onlyImages) sortedArray = [[item valueForKey:@"imageSeries"] sortedArrayUsingDescriptors: sortDescriptors];
		else sortedArray = [[[item valueForKey:@"series"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		
		[managedObjectContext unlock];
		
		return sortedArray;
	}

	return 0L;
}

- (NSArray*) childrenArray: (NSManagedObject*) item
{
	return [self childrenArray: item onlyImages: YES];
}

- (NSArray*) imagesArray: (NSManagedObject*) item preferredObject: (int) preferredObject onlyImages:(BOOL) onlyImages
{
	NSArray			*childrenArray = [self childrenArray: item onlyImages:onlyImages];
	NSMutableArray	*imagesPathArray = 0L;
	long			i;
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		return childrenArray;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
	{
		imagesPathArray = [NSMutableArray arrayWithCapacity: [childrenArray count]];
		
		for( i = 0; i < [childrenArray count]; i++)
		{
			int whichObject = preferredObject;
			
			if( preferredObject == oFirstForFirst)
			{
				if( i != 0) preferredObject = oAny;
			}
			
			if( preferredObject != oMiddle)
			{
				if( [[childrenArray objectAtIndex: i] valueForKey:@"thumbnail"] == 0L) whichObject = oMiddle;
			}
			
			switch( whichObject)
			{
				case oAny:
				{
					NSManagedObject	*obj = [[[childrenArray objectAtIndex: i] valueForKey:@"images"] anyObject];
					if( obj) [imagesPathArray addObject: obj];
				}
				break;
				case oMiddle:
				{
					NSArray			*seriesArray = [self childrenArray: [childrenArray objectAtIndex: i] onlyImages:onlyImages];
				
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
					NSArray			*seriesArray = [self childrenArray: [childrenArray objectAtIndex: i] onlyImages:onlyImages];
					
					// Get the middle image of the series
					if( [seriesArray count] > 0)
						[imagesPathArray addObject: [seriesArray objectAtIndex: 0]];
				}
				break;
			}
		}
	}
	
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

- (void) deleteEmptyFoldersForDatabaseOutlineSelection
{
	NSEnumerator		*rowEnumerator = [databaseOutline selectedRowEnumerator];
	NSNumber			*row;
	NSManagedObject		*curObj;
	NSManagedObjectContext	*context = [self managedObjectContext];

	while (row = [rowEnumerator nextObject]) 
	{
		curObj = [databaseOutline itemAtRow:[row intValue]];
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
		{
			if( [[curObj valueForKey:@"images"] count] == 0)
				[context deleteObject: curObj];
		}
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
		{
			if( [[curObj valueForKey:@"imageSeries"] count] == 0)
				[context deleteObject: curObj];
		}
	}
}

- (NSManagedObject *) firstObjectForDatabaseOutlineSelection
{
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
	{
		aFile = [[aFile valueForKey:@"series"] anyObject];
	}
	
	if( [[aFile valueForKey:@"type"] isEqualToString:@"Series"])
	{
		aFile = [[aFile valueForKey:@"images"] anyObject];
	}
	
	return aFile;
}

#define BONJOURPACKETS 50

- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages
{
	long				i, x, type;
    NSString			*pat, *stud, *ser;
	NSMutableArray		*selectedFiles = [NSMutableArray array];
	NSEnumerator		*rowEnumerator = [databaseOutline selectedRowEnumerator];
	NSNumber			*row;
	NSManagedObject		*curObj;
	
	while (row = [rowEnumerator nextObject]) 
	{
		curObj = [databaseOutline itemAtRow:[row intValue]];
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
		{
			NSArray		*imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
			
			if( isCurrentDatabaseBonjour)
			{
				for( i = 0; i < [imagesArray count]; i++)
				{
					[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: i] :BONJOURPACKETS]];
				}
			}
			else [selectedFiles addObjectsFromArray: [imagesArray valueForKey: @"completePath"]];
			
			if( correspondingManagedObjects) [correspondingManagedObjects addObjectsFromArray: imagesArray];
		}
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSArray	*seriesArray = [self childrenArray: curObj onlyImages: onlyImages];
			
			for( i = 0 ; i < [seriesArray count]; i++)
			{
				NSArray		*imagesArray = [self imagesArray: [seriesArray objectAtIndex: i] onlyImages: onlyImages];
				
				if( isCurrentDatabaseBonjour)
				{
					for( x = 0; x < [imagesArray count]; x++)
					{
						[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: x] :BONJOURPACKETS]];
					}
				}
				else [selectedFiles addObjectsFromArray: [imagesArray valueForKey: @"completePath"]];
				
				if( correspondingManagedObjects) [correspondingManagedObjects addObjectsFromArray: imagesArray];
			}
		}
	}
	
	return selectedFiles;

}

- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects
{
	return [self filesForDatabaseOutlineSelection:correspondingManagedObjects onlyImages: YES];
}

- (void) outlineViewSelectionDidChange:(NSNotification *)aNotification
{	
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item)
	{
		/**********
		post notification of new selected item. Can be used by plugins to update RIS connection
		**********/
		NSManagedObject *studySelected;
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:studySelected forKey:@"Selected Study"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NewStudySelectedNotification" object:self userInfo:(NSDictionary *)userInfo];
		
		BOOL	refreshMatrix = YES;
		long	nowFiles = [[item valueForKey:@"noFiles"] intValue];
		
		if( previousItem == item)
		{
			if( nowFiles == previousNoOfFiles) refreshMatrix = NO;
		}
		
		previousNoOfFiles = nowFiles;

		if( refreshMatrix)
		{
			shouldDie = YES;
			[matrixLoadIconsLock lock];
			[matrixLoadIconsLock unlock];
			shouldDie = NO;
			
			[animationSlider setEnabled:NO];
			[animationSlider setMaxValue:0];
			[animationSlider setNumberOfTickMarks:1];
			[animationSlider setIntValue:0];
			
			NSArray			*children = [self childrenArray: item];
			NSMutableArray	*imagePaths = [NSMutableArray arrayWithCapacity: 0];
			
			[matrixViewArray release];
			
			if ([[item valueForKey:@"type"] isEqualToString:@"Series"] && 
					[[[item valueForKey:@"images"] allObjects] count] == 1 && 
					[[[[[item valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1)
				matrixViewArray = [[NSArray arrayWithObject:item] retain];
			else
				matrixViewArray = [[self childrenArray: item] retain];
			
			long cellId;
			
			if( previousItem == item) cellId = [[oMatrix selectedCell] tag];
			else [oMatrix selectCellWithTag: 0];
			
			[self matrixInit: [matrixViewArray count]];
			
			BOOL imageLevel = NO;
			NSArray	*files = [self imagesArray: item preferredObject:oFirstForFirst];
			if( [files count] > 1)
			{
				if( [[files objectAtIndex: 0] valueForKey:@"series"] == [[files objectAtIndex: 1] valueForKey:@"series"]) imageLevel = YES;
			}
			
			int i;
			if( imageLevel == NO)
			{
				for( i = 0; i < [files count];i++)
				{
					NSImage *thumbnail = [[[NSImage alloc] initWithData: [[files objectAtIndex:i] valueForKeyPath:@"series.thumbnail"]] autorelease];
					if( thumbnail == 0L) thumbnail = notFoundImage;
					
					[previewPixThumbnails addObject: thumbnail];
				}
			}
			else
			{
				for( i = 0; i < [files count];i++) [previewPixThumbnails addObject: notFoundImage];
			}
			
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: files, @"files", [files valueForKey:@"completePath"], @"filesPaths",[NSNumber numberWithBool: imageLevel], @"imageLevel", 0L];
			[NSThread detachNewThreadSelector: @selector(matrixLoadIcons:) toTarget: self withObject: dict];
			
			if( previousItem == item)
			{
				[oMatrix selectCellWithTag: cellId];
			}
		}
		
		if( previousItem != item)
		{
			[previousItem release];
			previousItem = [item retain];
		}
	}
	else
	{
		[oMatrix selectCellWithTag: 0];
		[self matrixInit: 0];
		
		[previousItem release];
		previousItem = 0L;
	}
}

-(void) delItemMatrix: (NSManagedObject*) obj
{
	NSManagedObject		*study = [obj valueForKeyPath:@"series.study"];
	BOOL				wasExpanded = [databaseOutline isItemExpanded: study];
	
	if( [self findAndSelectFile:0L image:obj shouldExpand:YES])
	{
		[self delItem: self];
		
		[databaseOutline selectRow:[databaseOutline rowForItem: study] byExtendingSelection: NO];
		if( wasExpanded == NO) [databaseOutline collapseItem: study];
	}
}

- (IBAction) delItem:(id) sender
{
	long					i, x, z, row, result;
	NSManagedObjectContext	*context = [self managedObjectContext];
	NSManagedObjectModel    *model = [self managedObjectModel];
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [ViewerController getDisplayed2DViewers], *studiesArray = [NSMutableArray arrayWithCapacity:0] , *seriesArray = [NSMutableArray arrayWithCapacity:0];
	NSError					*error = 0L;
	BOOL					matrixThumbnails = NO;
	int						animState = [animationCheck state];
	NSMutableArray			*objectsToDelete = [NSMutableArray arrayWithCapacity: 0];
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	{
		matrixThumbnails = YES;
		NSLog( @"Delete from matrix");
	}
	
	if( isCurrentDatabaseBonjour)
	{
		NSRunAlertPanel( NSLocalizedString(@"Bonjour Database", nil),  NSLocalizedString(@"You cannot modify a Bonjour shared database.", nil), nil, nil, nil);
		return;
	}
	
	needDBRefresh = YES;
	
	[animationCheck setState: NSOffState];
	
	[context retain];
	[context lock];
	
	if( matrixThumbnails)
	{
		[self filesForDatabaseMatrixSelection: objectsToDelete onlyImages: NO];
	}
	else
	{
		[self deleteEmptyFoldersForDatabaseOutlineSelection];
		[self filesForDatabaseOutlineSelection: objectsToDelete onlyImages: NO];
	}
	
	if( [albumTable selectedRow] > 0 && matrixThumbnails == NO)
	{
		NSManagedObject	*album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == NO)
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", 0L), NSLocalizedString(@"Do you want to only remove the selected images from the current album or delete them from the database?", 0L), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Remove from current album",nil));
		else
		{
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", 0L), NSLocalizedString(@"Are you sure you want to delete the selected images?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}
	}
	else
	{
		result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete images", 0L), NSLocalizedString(@"Are you sure you want to delete the selected images?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	}
	
	if( result == NSAlertOtherReturn)	// REMOVE FROM CURRENT ALBUMS, BUT DONT DELETE IT FROM THE DATABASE
	{
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			shouldDie = YES;
			[matrixLoadIconsLock lock];
			[matrixLoadIconsLock unlock];
			shouldDie = NO;
			
			for( x = 0; x < [selectedRows count] ; x++)
			{
				if( x == 0) row = [selectedRows firstIndex];
				else row = [selectedRows indexGreaterThanIndex: row];
				
				NSManagedObject	*study = [databaseOutline itemAtRow: row];
				
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"])
				{
					NSManagedObject	*album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
					
					NSMutableSet	*studies = [NSMutableSet setWithCapacity:0 ];
					[studies setSet: [album valueForKey:@"studies"]];
					[studies removeObject: study];
					
					[album setValue: studies forKey:@"studies"];
				}
			}
			
			[databaseOutline selectRow:[selectedRows firstIndex] byExtendingSelection:NO];
		}
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
		[wait showWindow:self];
		
		[self saveDatabase: currentDatabasePath];
		
		[self outlineViewRefresh];
		
		[wait close];
		[wait release];
	}
	
	if( result == NSAlertDefaultReturn)	// REMOVE AND DELETE IT FROM THE DATABASE
	{
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			shouldDie = YES;
			[matrixLoadIconsLock lock];
			[matrixLoadIconsLock unlock];
			shouldDie = NO;
			
			// Try to find images that aren't stored in the local database
			
			NSMutableArray	*nonLocalImagesPath = [NSMutableArray arrayWithCapacity: 0];
			
			WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing Delete...", nil)];
			[wait showWindow:self];
			
			if( matrixThumbnails)
			{
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
			}
			else
			{
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
			}
			
			[wait close];
			[wait release];
			
			NSLog(@"non-local images : %d", [nonLocalImagesPath count]);
			
			if( [nonLocalImagesPath  count] > 0)
			{
				result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", 0L), NSLocalizedString(@"Some of the selected images are not stored in the Database folder. Do you want to only remove the links of these images from the database or also delete the original files?", 0L), NSLocalizedString(@"Remove the links",nil),  NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Delete the files",nil));
			}
			else result = NSAlertDefaultReturn;
			
			wait = [[WaitRendering alloc] init: NSLocalizedString(@"Deleting...", nil)];
			[wait showWindow:self];
			
			if( result == NSAlertDefaultReturn || result == NSAlertOtherReturn)
			{
				NSManagedObject	*study = 0L, *series = 0L;
				
				NSLog(@"objects to delete : %d", [objectsToDelete count]);
				
				for( x = 0 ; x < [objectsToDelete count]; x++)
				{
					if( [[objectsToDelete objectAtIndex: x] valueForKey:@"series"] != series)
					{
						// ********* SERIES
						
						series = [[objectsToDelete objectAtIndex: x] valueForKey:@"series"];
						
						if([seriesArray containsObject: series] == NO)
						{
							if( series) [seriesArray addObject: series];
							[series setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
							[series setValue: 0L forKey:@"thumbnail"];
						}
						
						// ********* STUDY
						
						if( [series valueForKey:@"study"] != study)
						{
							study = [series valueForKeyPath:@"study"];
							
							if([studiesArray containsObject: study] == NO)
							{
								if( study) [studiesArray addObject: study];
								[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
							}
							
							// Is a viewer containing this study opened? -> close it
							for( i = 0; i < [viewersList count]; i++)
							{
								if( study == [[[[viewersList objectAtIndex: i] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"]) [[[viewersList objectAtIndex: i] window] close];
							}
						}
					}
					
					[context deleteObject: [objectsToDelete objectAtIndex: x]];
				}
				
				[databaseOutline selectRow:[selectedRows firstIndex] byExtendingSelection:NO];
			}
			
			if( result == NSAlertOtherReturn)
			{
				for( i = 0; i < [nonLocalImagesPath count]; i++)
				{
					[[NSFileManager defaultManager] removeFileAtPath:[nonLocalImagesPath objectAtIndex: i] handler:nil];
					
					if( [[[nonLocalImagesPath objectAtIndex: i] pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
					{
						[[NSFileManager defaultManager] removeFileAtPath:[[[nonLocalImagesPath objectAtIndex: i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
					}
					
					if( [[[nonLocalImagesPath objectAtIndex: i] pathExtension] isEqualToString:@"zip"])		// ZIP -> DELETE XML
					{
						[[NSFileManager defaultManager] removeFileAtPath:[[[nonLocalImagesPath objectAtIndex: i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"] handler:nil];
					}
					
					NSString *currentDirectory = [[[nonLocalImagesPath objectAtIndex: i] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
					NSArray *dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:currentDirectory];
					
					//Is this directory empty?? If yes, delete it!
					
					if( [dirContent count] == 0) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
					if( [dirContent count] == 1)
					{
						if( [[[dirContent objectAtIndex: 0] uppercaseString] isEqualToString:@".DS_STORE"]) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
					}
				}
			}
			
			[wait close];
			[wait release];
		}
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
		[wait showWindow:self];
		
		[self saveDatabase: currentDatabasePath];
		@try
		{
			// Remove series without images !
			for( i = 0; i < [seriesArray count]; i++)
			{
				if( [[[seriesArray objectAtIndex: i] valueForKey:@"images"] count] == 0)
				{
					[context deleteObject: [seriesArray objectAtIndex: i]];
				}
			}
			
			[self saveDatabase: currentDatabasePath];
			
			// Remove studies without series !
			for( i = 0; i < [studiesArray count]; i++)
			{
				NSLog( @"Delete Study: %@ - %@", [[studiesArray objectAtIndex: i] valueForKey:@"name"], [[studiesArray objectAtIndex: i] valueForKey:@"patientID"]);
				
				if( [[[studiesArray objectAtIndex: i] valueForKey:@"imageSeries"] count] == 0)
				{
					[context deleteObject: [studiesArray objectAtIndex: i]];
				}
			}
			[self saveDatabase: currentDatabasePath];
			
		}
		@catch( NSException *ne)
		{
			NSLog( @"Exception during delItem");
			NSLog( [ne description]);
		}
		
		[self outlineViewRefresh];
		
		[wait close];
		[wait release];
		
	}
	
	[[QueryController currentQueryController] refresh: self];
	
	[context unlock];
	[context release];
	
	[animationCheck setState: animState];
	
	databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
}

- (void) buildColumnsMenu
{
	[columnsMenu release];
	columnsMenu = [[NSMenu alloc] initWithTitle:@"columns"];
	
	
	NSArray	*columnIdentifiers = [[databaseOutline tableColumns] valueForKey:@"identifier"];
	int i;
	
	for( i = 0; i < [[databaseOutline allColumns] count]; i++)
	{
		NSTableColumn *col = [[databaseOutline allColumns] objectAtIndex:i];		
		NSMenuItem	*item = [columnsMenu insertItemWithTitle:[[col headerCell] stringValue] action:@selector(columnsMenuAction:) keyEquivalent:@"" atIndex: [columnsMenu numberOfItems]];
		[item setRepresentedObject: [col identifier]];
		
		long index = [columnIdentifiers indexOfObject: [col identifier]];
		
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

- (void) columnsMenuAction:(id) sender
{
	[sender setState: ![sender state]];

	if( [[sender representedObject] isEqualToString:@"name"]) [[NSUserDefaults standardUserDefaults] setBool:![sender state] forKey:@"HIDEPATIENTNAME"];
	else
	{
		NSArray				*titleArray = [[columnsMenu itemArray] valueForKey:@"title"];
		int				i;
		NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithCapacity: 0];
		
		for( i = 0; i < [titleArray count]; i++)
		{
			NSString*	key = [titleArray objectAtIndex: i];
			
			if( [key length] > 0)
				[dict setValue:[NSNumber numberWithInt:[[[columnsMenu itemArray] objectAtIndex: i] state]] forKey: key];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"COLUMNSDATABASE"];
	}
}

- (void) refreshColumns
{
	NSDictionary	*columnsDatabase	= [[NSUserDefaults standardUserDefaults] objectForKey: @"COLUMNSDATABASE"];
	NSEnumerator	*enumerator			= [columnsDatabase keyEnumerator];
	NSString		*key;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	while( key = [enumerator nextObject])
	{
		long index = [[[[databaseOutline allColumns] valueForKey:@"headerCell"] valueForKey:@"title"] indexOfObject: key];
		
		if( index != NSNotFound)
		{
			NSString	*identifier = [[[databaseOutline allColumns] objectAtIndex: index] identifier];
			
			if( [databaseOutline isColumnWithIdentifierVisible: identifier] != [[columnsDatabase valueForKey: key] intValue])
			{
				[databaseOutline setColumnWithIdentifier:identifier visible: [[columnsDatabase valueForKey: key] intValue]];
				
				if( [[columnsDatabase valueForKey: key] intValue] == NSOnState)
				{
					[databaseOutline scrollColumnToVisible: [databaseOutline columnWithIdentifier: identifier]];
				}
			}
		}
	}
	
	[self buildColumnsMenu];
	
	[managedObjectContext unlock];
	[managedObjectContext release];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if( managedObjectContext == 0L) return 0L;
	
	id returnVal = 0L;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	if( item == 0L) 
	{
		returnVal = [outlineViewArray objectAtIndex: index];
	}
	else
	{
		returnVal = [[self childrenArray: item] objectAtIndex: index];
	}
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	return returnVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL returnVal = NO;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = NO;
	else returnVal = YES;
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	return returnVal;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( managedObjectContext == 0L) return 0L;
	
	int returnVal = 0;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
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
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	return returnVal;
}

- (id)intOutlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	// *********************************************
	//	PLUGINS
	// *********************************************
	
	if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 3 && 
							[[tableColumn identifier] isEqualToString:@"reportURL"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSBundle *plugin = [reportPlugins objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
					
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
				if( isCurrentDatabaseBonjour)
				{
					return [bonjourBrowser getFileModification:[item valueForKey:@"reportURL"] index:[bonjourServicesList selectedRow]-1];
				}
				else if( [[NSFileManager defaultManager] fileExistsAtPath:[item valueForKey:@"reportURL"]])
				{
					NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[item valueForKey:@"reportURL"]  traverseLink:YES];
				
					return [fattrs objectForKey:NSFileModificationDate];
				}
				else return 0L;
			}
			else return 0L;
		}
		else return 0L;
	}
	
	if( [[tableColumn identifier] isEqualToString:@"stateText"])
	{
		if( [[item valueForKey:@"stateText"] intValue] == 0) return 0L;
		else return [item valueForKey:@"stateText"];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"name"])
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSString	*name;
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"HIDEPATIENTNAME"])
				name = [NSString stringWithString:@"Name hidden"];
			else
				name = [item valueForKey:@"name"];
			
			//return [NSString stringWithFormat:@"%@ (%d series)", name, [[item valueForKey:@"series"] count]];
			return [NSString stringWithFormat:@"%@ (%d series)", name, [[item valueForKey:@"imageSeries"] count]];
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
	if( managedObjectContext == 0L) return 0L;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	id returnVal = [self intOutlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	return returnVal;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	DatabaseIsEdited = NO;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	if( isCurrentDatabaseBonjour)
	{
		[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:item value:object forKey:[tableColumn identifier]];
	}
	
	if( [[tableColumn identifier] isEqualToString:@"stateText"])
	{
		if( [object intValue] >= 0) [item setValue:object forKey:[tableColumn identifier]];
	}
	else [item setValue:object forKey:[tableColumn identifier]];
	
	[refreshTimer setFireDate: [NSDate dateWithTimeIntervalSinceNow:0.5]];
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	[self saveDatabase: currentDatabasePath];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self outlineViewRefresh];
	
	if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO)
	{
		[databaseOutline selectRow: 0 byExtendingSelection: NO];
	}
	
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setHighlighted: NO];
	
	if( [cell isKindOfClass: [ImageAndTextCell class]])
	{
		[(ImageAndTextCell*) cell setImage: 0L];
		[(ImageAndTextCell*) cell setLastImage: 0L];
	}
	
	NSManagedObjectContext	*context = [self managedObjectContext];
	
	[context retain];
	[context lock];
	
	if ([[item valueForKey:@"type"] isEqualToString: @"Study"])
	{
		if( originalOutlineViewArray)
		{
			if( [originalOutlineViewArray containsObject: item]) [cell setFont: [NSFont boldSystemFontOfSize:12]];
			else [cell setFont: [NSFont systemFontOfSize:12]];
		}
		else [cell setFont: [NSFont boldSystemFontOfSize:12]];
		
		if( [[tableColumn identifier] isEqualToString:@"name"])
		{
			BOOL	icon = NO;
			
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
		}
		
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] != 3)
		{
		
			if( [[tableColumn identifier] isEqualToString:@"reportURL"])
			{
				if( [item valueForKey:@"reportURL"])
				{
					if( isCurrentDatabaseBonjour || [[NSFileManager defaultManager] fileExistsAtPath:[item valueForKey:@"reportURL"]] == YES)
					{
						NSImage	*reportIcon = [NSImage imageNamed:@"Report.icns"];
						//NSImage	*reportIcon = [self reportIcon];
						[reportIcon setSize: NSMakeSize(16, 16)];
						
						[(ImageAndTextCell*) cell setImage: reportIcon];
					}
					else [item setValue: 0L forKey:@"reportURL"];
				}
			}
			
		}
		
	}
	else [cell setFont: [NSFont boldSystemFontOfSize:10]];
	
	[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
	
	[context unlock];
	[context release];
	
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

- (NSArray *)outlineView:(NSOutlineView *)outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items
{
	if( [[[dropDestination path] lastPathComponent] isEqualToString:@".Trash"])
	{
		[[BrowserController currentBrowser] delItem:  0L];
		return 0L;
	}
	else
	{
		NSMutableArray	*dicomFiles2Export = [NSMutableArray array];
		NSArray			*filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
		return [self exportDICOMFileInt: [dropDestination path] files: filesToExport objects: dicomFiles2Export];
	}
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)pbItems toPasteboard:(NSPasteboard*)pboard
{
	NSMutableArray *xmlArray = [NSMutableArray array];
	int i;
	for( i = 0 ; i < [pbItems count]; i++)
	{
		BOOL extend = i;
		[olv selectRow:	[olv rowForItem: [pbItems objectAtIndex: i]] byExtendingSelection: extend];
		[xmlArray addObject: [[pbItems objectAtIndex: i] dictionary]];
	}
	
	[pboard declareTypes: [NSArray arrayWithObjects: albumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType,  @"OsirixXMLPboardType", nil] owner:self];
	
	[pboard setPropertyList:0L forType:albumDragType];
	
    [pboard setPropertyList:[NSArray arrayWithObject:@"dcm"] forType:NSFilesPromisePboardType];
	
	[pboard setData:[NSArchiver archivedDataWithRootObject:xmlArray]  forType:@"OsiriXPboardType"];

	[draggedItems release];
	draggedItems = [pbItems retain];
	return YES;
}

- (void) setDraggedItems:(NSArray*) pbItems
{
	[draggedItems release];
	draggedItems = [pbItems retain];
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	NSManagedObject	*object = [[notification userInfo] objectForKey:@"NSObject"];
	
	[object setValue:[NSNumber numberWithBool: NO] forKey:@"expanded"];
	
	NSManagedObject	*image = 0L;
	
	if( [matrixViewArray count] > 0)
	{
		image = [matrixViewArray objectAtIndex: 0];
		if( [[image valueForKey:@"type"] isEqualToString:@"Image"]) [self findAndSelectFile: 0L image: image shouldExpand :NO];
	}
	
	[managedObjectContext unlock];
	[managedObjectContext release];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	NSManagedObject	*object = [[notification userInfo] objectForKey:@"NSObject"];
	
	[object setValue:[NSNumber numberWithBool: YES] forKey:@"expanded"];
	
	[managedObjectContext unlock];
	[managedObjectContext release];
}

- (MyOutlineView*) databaseOutline {return databaseOutline;}

- (BOOL) isUsingExternalViewer: (NSManagedObject*) item
{
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		// ZIP files with XML descriptor
		if([[item valueForKey:@"noFiles"] intValue] == 1)
		{
			NSSet *imagesSet = [item valueForKeyPath: @"images.fileType"];
			NSArray *imagesArray = [imagesSet allObjects];
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
			{
				NSLog(@"******** XMLDESCRIPTOR ********");
				
				NSSavePanel *savePanel = [NSSavePanel savePanel];
				[savePanel setCanSelectHiddenExtension:YES];
				[savePanel setRequiredFileType:@"zip"];
				
				imagesSet = [item valueForKeyPath: @"images.path"];
				imagesArray = [imagesSet allObjects];
				NSString *filePath = [imagesArray objectAtIndex:0];
				NSString *fileName = [filePath lastPathComponent];
				if([savePanel runModalForDirectory:0L file:fileName] == NSFileHandlingPanelOKButton)
				{
					// write the file to the specified location on the disk
					NSFileManager *fileManager = [NSFileManager defaultManager];
					// zip
					NSString *newFilePath = [[savePanel URL] path];
					if ([fileManager fileExistsAtPath:filePath])
						[fileManager copyPath:filePath toPath:newFilePath handler:nil];
					// xml
					NSMutableString *xmlFilePath = [NSMutableString stringWithCapacity:[filePath length]];
					[xmlFilePath appendString: [filePath substringToIndex:[filePath length]-[[filePath pathExtension] length]]];
					[xmlFilePath appendString: @"xml"];
					NSLog(@"xmlFilePath : %@", xmlFilePath);
					NSMutableString *newXmlFilePath = [NSMutableString stringWithCapacity:[newFilePath length]];
					[newXmlFilePath appendString: [newFilePath substringToIndex:[newFilePath length]-[[newFilePath pathExtension] length]]];
					[newXmlFilePath appendString: @"xml"];
					NSLog(@"newXmlFilePath : %@", newXmlFilePath);
					if ([fileManager fileExistsAtPath:xmlFilePath])
						[fileManager copyPath:xmlFilePath toPath:newXmlFilePath handler:nil];
				}

				return YES;
			}
			else if ([[imagesArray objectAtIndex:0] isEqualToString:@"DICOMMPEG2"])
			{
				imagesSet = [item valueForKeyPath: @"images.path"];
				imagesArray = [imagesSet allObjects];
				NSString *filePath = [imagesArray objectAtIndex:0];
				
				if( [[NSWorkspace sharedWorkspace]openFile: filePath withApplication:@"VLC"] == NO)
				{
					NSRunAlertPanel( NSLocalizedString( @"MPEG-2 File", 0L), NSLocalizedString( @"MPEG-2 DICOM files require the VLC application. Available for free here: http://www.videolan.org/vlc/", 0L), nil, nil, nil);
				}
				
				return YES;
			}

		}	
	}
	
	return NO;
}

- (void) databaseOpenStudy: (NSManagedObject*) item
{
	long				i;
					
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		if( [self isUsingExternalViewer: item] == NO)
		{
			// DICOM & others
			[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:nil description:nil];
			[self viewerDICOMInt :NO  dcmFile: [NSArray arrayWithObject:item] viewer:0L];
	//		[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:[item valueForKeyPath:@"study.modality"] description:[item valueForKeyPath:@"study.studyName"]];
		}
	}
	else	// STUDY - HANGING PROTOCOLS
	{
		// files with XML descriptor, do nothing
		NSSet *imagesSet = [item valueForKeyPath: @"series.images.fileType"];
		NSArray *imagesArray = [[[imagesSet allObjects] objectAtIndex:0] allObjects];
		if([imagesArray count]==1)
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"]) return;
		}
	
		// DICOM & others
		/* Need to improve Hanging Protocols	
			Things Advanced Hanging Protocol needs to do.
			For Advanced Hanging Protocols Need to Search for Comparisons
			Arrange Series in a Particular order by either series description or series number
			Could have preset ww/wl and CLUT
			Series Fusion at start
			Could have a 3D ViewerController instead of a 2D ViewerController
				If 2D viewer need to set starting orientation, wwwl, CLUT, if SR preset surfaces.
				Preprocess Volume - extract heart, Get Center line for vessel Colon, etc
				
			Root object is NSArray we can search through with predicates to get a filteredArray
		*/
		
		if (![[WindowLayoutManager sharedWindowLayoutManager] hangStudy:item])
		{
			NSLog( [item description]);
			
			//Use Basic Hanging Protocols
			[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:[item valueForKey:@"modality"] description:[item valueForKey:@"studyName"]];
			NSDictionary *currentHangingProtocol = [[WindowLayoutManager sharedWindowLayoutManager] currentHangingProtocol];
			//if ([[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue] >= [[item valueForKey:@"series"] count])
			if ([[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue] >= [[item valueForKey:@"imageSeries"] count])
			{
				[self viewerDICOMInt :NO  dcmFile:[self childrenArray: item] viewer:0L];
			}
			else {
				unsigned count = [[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue];
				if( count < 1) count = 1;
				
				NSMutableArray *children =  [NSMutableArray array];
				int i;
				for (i = 0; i < count; i++)
					[children addObject:[[self childrenArray: item] objectAtIndex:i] ];
				
				[self viewerDICOMInt :NO  dcmFile:children viewer:0L];
			}
		}
	}
}

- (IBAction) databaseDoublePressed:(id)sender
{
	NSManagedObject		*item;
	
	if( [databaseOutline clickedRow] != -1) item = [databaseOutline itemAtRow:[databaseOutline clickedRow]];
	else item = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	[self databaseOpenStudy: item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if( [[tableColumn identifier] isEqualToString:@"comment"])
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
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	{
		NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]];
				
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
		{
			files = [self filesForDatabaseMatrixSelection: dicomFiles];
			
			if( [databaseOutline isItemExpanded: [curObj valueForKeyPath:@"series.study"]])
				[databaseOutline collapseItem: [curObj valueForKeyPath:@"series.study"]];
			
		//	[self findAndSelectFile:0L image:[dicomFiles objectAtIndex: 0] shouldExpand:NO];
		}
		else
		{
			files = [self filesForDatabaseMatrixSelection: dicomFiles];
			[self findAndSelectFile:0L image:[dicomFiles objectAtIndex: 0] shouldExpand:YES];
		}
	}
}

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand
{
	return [self findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: NO];
}

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection
{
	if( curImage == 0L)
	{
		BOOL isDirectory;
		
		if([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])     // A directory
		{
			DicomFile			*curFile = 0L;
			 
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
		
			//We have first to find the image object from the path
			
			NSError				*error = 0L;
			NSString			*name;
			long				index;
			
			if( curFile)
			{
				NSManagedObject	*study, *seriesTable;
				NSManagedObjectContext *context = [self managedObjectContext];
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				[context retain];
				[context lock];
				error = 0L;
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
				[curFile release];
				[context unlock];
				[context release];
			}
		}
	}

	NSManagedObject	*study = [curImage valueForKeyPath:@"series.study"];
	
	long index = [outlineViewArray indexOfObject: study];
	
	if( index != NSNotFound)
	{
		if( expand || [databaseOutline isItemExpanded: study])
		{
			[databaseOutline expandItem: study];
			
			if( [databaseOutline rowForItem: [curImage valueForKey:@"series"]] != [databaseOutline selectedRow])
			{
				[databaseOutline selectRow:[databaseOutline rowForItem: [curImage valueForKey:@"series"]] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		else
		{
			if( [databaseOutline rowForItem: study] != [databaseOutline selectedRow])
			{
				[databaseOutline selectRow:[databaseOutline rowForItem: study] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		
		// Now... try to find the series in the matrix
		if( [databaseOutline isItemExpanded: study] == NO)
		{
			NSArray	*seriesArray = [self childrenArray: study];
			
			[self outlineViewSelectionDidChange: 0L];
			
			[self matrixDisplayIcons: self];	//Display the icons, if necessary
			
			[matrixLoadIconsLock lock];
			[matrixLoadIconsLock unlock];
			
			long seriesPosition = [seriesArray indexOfObject: [curImage valueForKey:@"series"]];
			
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

-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	NSManagedObjectModel	*model = [self managedObjectModel];
	long					x, i;
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"nextPatientToAllViewers"])
	{
		// If multiple viewer are opened, apply it to the entire list
		for( i = 0; i < [winList count]; i++)
		{
			if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
			{
				[viewersList addObject: [[winList objectAtIndex:i] windowController]];
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
	
	long index = [outlineViewArray indexOfObject: study];
	
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
			else return;
			
		}while( found == NO);
		
		NSManagedObject	*series =  [[self childrenArray:nextStudy] objectAtIndex:0];
		
		[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
		
		[self loadNextSeries:[[self childrenArray: series] objectAtIndex: 0] :0 :viewer :YES keyImagesOnly:keyImages];
	}
	
	[viewersList release];
}

-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	if ([[WindowLayoutManager sharedWindowLayoutManager] hangingProtocolInUse]) {
		if (direction)
			[[WindowLayoutManager sharedWindowLayoutManager] nextSeriesSet];
		else
			[[WindowLayoutManager sharedWindowLayoutManager] previousSeriesSet];
	}
	else
	{
		NSManagedObjectModel	*model = [self managedObjectModel];
		NSManagedObjectContext	*context = [self managedObjectContext];
		long					x, i;
		NSArray					*winList = [NSApp windows];
		NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
		
		if( [viewer FullScreenON]) [viewersList addObject: viewer];
		else
		{
			// If multiple viewer are opened, apply it to the entire list
			if( [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"])
			{
				for( i = 0; i < [winList count]; i++)
				{
					if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]])
					{
						[viewersList addObject: [[winList objectAtIndex:i] windowController]];
					}
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
		NSManagedObject		*currentSeries = [curImage valueForKeyPath:@"series"];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientID == %@)", [study valueForKey:@"patientID"]];
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: predicate];
		
		[context retain];
		[context lock];
		
		NSError	*error = 0L;
		NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
		
		if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
		{
			NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
			NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
			[sort release];
			
			studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
			
			NSArray					*seriesArray = [NSArray array];
			
			for( x = 0; x < [studiesArray count]; x ++)
			{
				NSManagedObject			*curStudy = [studiesArray objectAtIndex: x];
				
				seriesArray = [seriesArray arrayByAddingObjectsFromArray: [self childrenArray: curStudy]];
			}
			
			long index = [seriesArray indexOfObject: currentSeries];
			
			if( index != NSNotFound)
			{
				if( direction == 0)	// Called from loadNextPatient
				{
					if( firstViewer == NO) direction = 1;
				}
				
				index += direction*[viewersList count];
				if( index < 0) index = 0;
				if( index < [seriesArray count])
				{
					for( x = 0; x < [viewersList count]; x++)
					{
						if( index >= 0 && index < [seriesArray count])
						{
							[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [seriesArray objectAtIndex: index]]] movie: NO viewer :[viewersList objectAtIndex:x] keyImagesOnly:keyImages];
						}
						else
						{
							// CREATE AN EMPTY SERIES !!!!
					
							NSMutableArray  *viewerPix = [[NSMutableArray alloc] initWithCapacity:0];
							NSMutableArray  *filesAr = [[NSMutableArray alloc] initWithCapacity:0];
							float			*fVolumePtr = 0L;
							NSData			*volumeData = 0L;
							NSString		*path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Empty.tif"];
										
							NSDictionary	*curFile = [NSDictionary dictionaryWithObjectsAndKeys:path, @"completePath", @"xxx", @"uniqueFilename", @"OT", @"modality", 0L];
							[filesAr addObject: curFile];
							
							fVolumePtr = malloc(100 * 100 * sizeof(float));
							
							DCMPix			*dcmPix = [[DCMPix alloc] myinit:path :0 :1 :fVolumePtr :0 :0];
							[viewerPix addObject: dcmPix];
							[dcmPix release];
							
							volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:100 * 100 * sizeof(float) freeWhenDone:YES]; 
							
							[[viewersList objectAtIndex: x] changeImageData:viewerPix :filesAr :volumeData :NO];
							[[viewersList objectAtIndex: x] startLoadImageThread];
							
							[volumeData release];
							[viewerPix release];
							[filesAr release];
						}
						
						index++;
					}
				}
			}
		}
		
		[context unlock];
		[context release];
		
		[viewersList release];
	}
}

-(void) loadSeries:(NSManagedObject *) series :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
}

-(IBAction) copy:(id) sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
			
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	if( aFile)
		[pb setString: [aFile valueForKey:@"name"] forType:NSStringPboardType];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Thumbnails Matrix & Preview functions

static BOOL withReset = NO;

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
		if([[aFile valueForKey:@"type"] isEqualToString:@"Study"])
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
		else if ([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && 
					[[[aFile valueForKey:@"images"] allObjects] count] == 1 && 
					[[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1)
		{
			noOfImages = [[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
			animate = YES;
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

- (void) previewSliderAction:(id) sender
{
	BOOL	animate = NO;
	long	noOfImages = 0;
	
	if( [matrixLoadIconsLock tryLock]) [matrixLoadIconsLock unlock];
	else return;
	
    NSButtonCell    *cell = [oMatrix selectedCell];
    if( cell)
    {
		if( [cell isEnabled] == YES)
		{
			if( [cell tag] >= [matrixViewArray count]) return;
			
			NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
			if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
			{
				NSArray *images = [self imagesArray: [matrixViewArray objectAtIndex: [cell tag]]];
				
				if( [images count])
				{
					if( [images count] > 1) noOfImages = [images count];
					else noOfImages = [[[images objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
					
					if( [images count] > 1 || noOfImages == 1)
					{
						animate = YES;
						
						if( [sender intValue] >= [images count]) return;
						
						if( [[[imageView curDCM] sourceFile] isEqualToString: [[images objectAtIndex: [sender intValue]] valueForKey:@"completePath"]] == NO)
						{						
							DCMPix*     dcmPix = 0L;
							dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: [sender intValue]] valueForKey:@"completePath"] :[sender intValue] :[images count] :0L :0 :[[[images objectAtIndex: [sender intValue]] valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:[images objectAtIndex: [sender intValue]]];
							
							if( dcmPix)
							{
								float   wl, ww;
								int     row, column;
								
								[imageView getWLWW:&wl :&ww];
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
							}
						}
					}
					else if( noOfImages > 1)	// It's a multi-frame single image
					{
						animate = YES;

						if( [[[imageView curDCM] sourceFile] isEqualToString: [[images objectAtIndex:0] valueForKey:@"completePath"]] == NO
							|| [[imageView curDCM] frameNo] != [sender intValue]
							|| [[imageView curDCM] serieNo] != [[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue])
						{
							DCMPix*     dcmPix = 0L;
							dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: 0] valueForKey:@"completePath"] :[sender intValue] :noOfImages :0L :[sender intValue] :[[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:[images objectAtIndex: 0]];
							
							if( dcmPix)
							{
								float   wl, ww;
								int     row, column;
								
								[imageView getWLWW:&wl :&ww];
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
							}
						}
					}
				}
			}
			else if ([[aFile valueForKey:@"type"] isEqualToString:@"Series"] && 
					[[[aFile valueForKey:@"images"] allObjects] count] == 1 && 
					[[[[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1) // multi frame image that is directly selected
			{
				NSManagedObject* image = [[[aFile valueForKey:@"images"] allObjects] objectAtIndex:0];
				
				noOfImages = [[image valueForKey:@"numberOfFrames"] intValue];
				animate = YES;
				
				DCMPix*     dcmPix = 0L;
				dcmPix = [[DCMPix alloc] myinit: [image valueForKey:@"completePath"] :[sender intValue] :noOfImages :0L :[sender intValue] :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:image];
				
				if( dcmPix)
				{
					float   wl, ww;
					int     row, column;
					
					[imageView getWLWW:&wl :&ww];
					
					[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
					[dcmPix release];
					
					[imageView setIndex:[cell tag]];
				}
			}
		}
    }
}

-(void) previewPerformAnimation:(id) sender
{
	[self setDockIcon];
	
    // Wait loading all images !!!
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
	if( [animationCheck state] == NSOffState) return;
	if( [matrixLoadIconsLock tryLock]) [matrixLoadIconsLock unlock];
	else return;
    if( [[self window] isKeyWindow] == NO) return;
    if( [animationSlider isEnabled] == NO) return;
	
	int	pos = [animationSlider intValue];
	pos++;
	if( pos > [animationSlider maxValue]) pos = 0;
	
	[animationSlider setIntValue: pos];
	[self previewSliderAction: animationSlider];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	float				reverseScrollWheel;					// DDP (050913): allow reversed scroll wheel preference.
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"Scroll Wheel Reversed"])
		reverseScrollWheel=-1.0;
	else
		reverseScrollWheel=1.0;
	float change = reverseScrollWheel * [theEvent deltaY];

    // Wait loading all images !!!
	if( [matrixLoadIconsLock tryLock]) [matrixLoadIconsLock unlock];
	else return;
	
	int	pos = [animationSlider intValue];

	if( change > 0)
	{
		change = ceil( change);
		pos += change;
	}
	else
	{
		change = floor( change);
		pos += change;
	}
	
	if( pos > [animationSlider maxValue]) pos = 0;
	if( pos < 0) pos = [animationSlider maxValue];
	
	[animationSlider setIntValue: pos];
	[self previewSliderAction: animationSlider];
}

- (IBAction) matrixPressed:(id)sender
{
    id          theCell = [sender selectedCell];
    int         row, column, count, index;
    
	NSLog(@"matrixPressed");
	
	[[self window] makeFirstResponder:databaseOutline];
	
	[animationSlider setEnabled:NO];
	[animationSlider setMaxValue:0];
	[animationSlider setNumberOfTickMarks:1];
	[animationSlider setIntValue:0];
	
    if( [theCell tag] >= 0)
    {
		 NSManagedObject         *dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		 
		 if( [[dcmFile valueForKey:@"type"] isEqualToString: @"Study"] == NO)
		 {
			index = [theCell tag];
			[imageView setIndex: index];
		 }
		
		[self initAnimationSlider];
    }
}

- (IBAction) matrixDoublePressed:(id)sender
{
    id  theCell = [oMatrix selectedCell];
    int column,row;
    
	[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:nil description:nil];
	
    if( [theCell tag] >= 0 ) {
		[self viewerDICOM: [[oMatrix menu] itemAtIndex:0]];
    }
}

-(void) matrixInit:(long) noOfImages
{
	NSSize size		= [oMatrix cellSize];
	NSSize space	= [oMatrix intercellSpacing];
	NSRect frame	= [[oMatrix enclosingScrollView] frame];
	
	long	i, minrow;
	
	setDCMDone = NO;
	loadPreviewIndex = 0;
	
	[previewPix release];
	[previewPixThumbnails release];
	
	previewPix = [[NSMutableArray alloc] initWithCapacity:0];
	previewPixThumbnails = [[NSMutableArray alloc] initWithCapacity:0];
		
	if( COLUMN == 0) NSLog(@"COLUMN = 0, ERROR");
	
	int row = ceil((float) noOfImages/(float) COLUMN);
	
	[oMatrix renewRows:row columns: COLUMN];
	
	for( i=0;i<row*COLUMN;i++)
	{
		NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
		[cell setTag:i];
		[cell setTransparent:YES];
		[cell setEnabled:NO];
		[cell setTitle:NSLocalizedString(@"loading...", nil)];
		[cell setImage:0L];
		[cell setBezelStyle: NSShadowlessSquareBezelStyle];
	}
	
	for( i=0;i<noOfImages;i++)
	{
		[[oMatrix cellWithTag: i] setTransparent:NO];
	}
	
	[oMatrix sizeToCells];
	
	[imageView setDCM:0L :0L :0L :0 :0L :YES];
	
	[self matrixDisplayIcons: self];
}

-(void) matrixNewIcon:(long) index :(NSManagedObject*) curFile
{	
	if( shouldDie == NO)
	{
		long		i = index;
		
		if( curFile == nil ) {
			[oMatrix setNeedsDisplay:YES];
			return;
		}
		
		if( i >= [previewPix count]) return;
		if( i >= [previewPixThumbnails count]) return;
		
		DCMPix		*pix = [previewPix objectAtIndex: i];
		NSImage		*img = 0L;
		
		img = [previewPixThumbnails objectAtIndex: i];
		if( img == 0L) NSLog( @"Error: [previewPixThumbnails objectAtIndex: i] == 0L");
		
		[managedObjectContext retain];
		[managedObjectContext lock];
		
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
					if( [curFile valueForKey:@"thumbnail"] == 0L)
					{
						if( [[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"])
						{
							NSData *data = [BrowserController produceJPEGThumbnail: img];
							[curFile setValue: data forKey:@"thumbnail"];
						}
					}
				}
			}
			
			if( img || [modality isEqualToString: @"RTSTRUCT"])
			{
				NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
				[cell setTransparent:NO];
				[cell setEnabled:YES];
				
				[cell setFont:[NSFont systemFontOfSize:10]];
				[cell setImagePosition: NSImageBelow];
				[cell setAction: @selector(matrixPressed:)];
				
				NSString	*name = [curFile valueForKey:@"name"];
				
				if( [name length] > 15) name = [name substringToIndex: 15];
				
				if ( [modality isEqualToString: @"RTSTRUCT"] ) {
					[cell setTitle: [NSString stringWithFormat: @"%@\r%@", name, @"RTSTRUCT"]];
				}
				else if ([seriesSOPClassUID isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
				{
					[cell setAction: @selector(pdfPreview:)];
					[cell setTitle: @"Open PDF"];
					img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"pdf"]];
				}
				else if ([fileType isEqualToString: @"DICOMMPEG2"])
				{
					long count = [[curFile valueForKey:@"noFiles"] intValue];
					
					if( count == 1) {
						long frames = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
						
						if( frames > 1) [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"MPEG-2 Series\r%@\r%d Frames", 0L), name, frames]];
						else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"MPEG-2 Series\r%@\r%d Image", 0L), name, count]];
					}
					
					img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"mpeg2"]];
				}
				else if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"]) {
					long count = [[curFile valueForKey:@"noFiles"] intValue];
					
					if( count == 1) {
						long frames = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
						
						if( frames > 1) [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Frames", 0L), name, frames]];
						else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Image", 0L), name, count]];
					}
					else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Images", 0L), name, count]];
				}
				else if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"])
				{
					if( [[curFile valueForKey: @"sliceLocation"] floatValue])
						[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d\r%.2f", nil), i+1, [[curFile valueForKey: @"sliceLocation"] floatValue]]];
					else
						[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d", nil), i+1]];
				}
				
				[cell setButtonType:NSPushOnPushOffButton];
				
				[cell setImage: img];
							
				if( setDCMDone == NO)
				{
					NSIndexSet  *index = [databaseOutline selectedRowIndexes];
					if( [index count] >= 1)
					{
						NSManagedObject* aFile = [databaseOutline itemAtRow:[index firstIndex]];
						
						[imageView setDCM:previewPix :[self imagesArray: aFile preferredObject: oAny] :0L :[[oMatrix selectedCell] tag] :'i' :YES];
						[imageView setStringID:@"previewDatabase"];
						setDCMDone = YES;
					}
				}
			}		
			else {  // Show Error Button
				NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
				[cell setImage: nil];
				[oMatrix setToolTip: NSLocalizedString(@"File not readable", nil) forCell:cell];
				[cell setTitle: NSLocalizedString(@"File not readable", nil)];			
				[cell setFont:[NSFont systemFontOfSize:10]];
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
		}
		
		[managedObjectContext unlock];
		[managedObjectContext release];
	}
	[oMatrix setNeedsDisplay:YES];
}

- (void) pdfPreview:(id)sender
{
    [self matrixPressed:sender];
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
	NSLog(@"open pdf with Preview");
		//check if the folder PDF exists in OsiriX document folder
	NSString *pathToPDF = [documentsDirectory() stringByAppendingPathComponent:@"/PDF/"];
	if (!([[NSFileManager defaultManager] fileExistsAtPath:pathToPDF]))
	[[NSFileManager defaultManager] createDirectoryAtPath:pathToPDF attributes:nil];
	
	//pathToPDF = /PDF/yyyymmdd.hhmmss.pdf
	NSDateFormatter *datetimeFormatter = [[[NSDateFormatter alloc]initWithDateFormat:@"%Y%m%d.%H%M%S" allowNaturalLanguage:NO] autorelease];
	pathToPDF = [pathToPDF stringByAppendingPathComponent: [datetimeFormatter stringFromDate:[NSDate date]]];
	pathToPDF = [pathToPDF stringByAppendingPathExtension:@"pdf"];
	NSLog(pathToPDF);
		
	//creating file and opening it with preview
	NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[sender selectedCell] tag]];
	NSLog([curObj valueForKey: @"type"]);
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	if( [[curObj valueForKey:@"type"] isEqualToString: @"Series"] == YES) curObj = [[self childrenArray: curObj] objectAtIndex: 0];
	
	[managedObjectContext unlock];
	[managedObjectContext release];

	NSLog([curObj valueForKey: @"completePath"]);	
	
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[curObj valueForKey: @"completePath"] decodingPixelData:NO];
	NSData *encapsulatedPDF = [dcmObject attributeValueWithName:@"EncapsulatedDocument"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if( [fileManager createFileAtPath:pathToPDF contents:encapsulatedPDF attributes:nil]) [[NSWorkspace sharedWorkspace] openFile:pathToPDF];
	else NSLog(@"couldn't open pdf");
	
	[pool release];	
}

- (NSMatrix*) oMatrix
{
	return oMatrix;
}

-(void) matrixDisplayIcons:(id) sender
{
	long		i;
	
	if( bonjourDownloading) return;
	if( managedObjectContext == 0L) return;
	
	@try
	{
		if( [previewPix count])
		{
			if( loadPreviewIndex < [previewPix count])
			{
				for( i = loadPreviewIndex; i < [previewPix count];i++)
				{
					NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
					
					if( [cell isEnabled] == NO)
					{
						if( i < [previewPix count])
						{
							if( [previewPix objectAtIndex: i] != 0L)
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
		NSLog(@"matrixDisplayIcons exception: %@", [ne description]);
	}
}

+ (NSData*) produceJPEGThumbnail:(NSImage*) image
{
	NSData *imageData = [image  TIFFRepresentation];
	
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
	
	NSData	*result = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];	//NSJPEGFileType	NSJPEG2000FileType <- MAJOR memory leak with NSJPEG2000FileType when reading !!! Kakadu library...
	
	NSLog( @"thumbnail size: %d", [result length]);
	
	return result;
}

- (void) buildThumbnail:(NSManagedObject*) series
{
	if( [series valueForKey:@"thumbnail"] == 0L)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		NSArray	*files = [self imagesArray: series];
		if( [files count] > 0)
		{
			NSManagedObject *image = [files objectAtIndex: [files count]/2];
			
			if( [NSData dataWithContentsOfFile: [image valueForKey:@"completePath"]])	// This means the file is readable...
			{
				int frame = 0;
				if( [[image valueForKey:@"numberOfFrames"] intValue] > 1) frame = [[image valueForKey:@"numberOfFrames"] intValue]/2;
				
				NSLog( @"Build thumbnail for:");
				NSLog( [image valueForKey:@"completePath"]);
				DCMPix	*dcmPix  = [[DCMPix alloc] myinit:[image valueForKey:@"completePath"] :0 :1 :0L :frame :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:image];
				
				if( dcmPix)
				{
					[dcmPix computeWImage:YES :0 :0];
					NSImage *thumbnail = [dcmPix getImage];
					NSData *data = [BrowserController produceJPEGThumbnail: thumbnail];

					if( thumbnail && data) [series setValue: data forKey:@"thumbnail"];
					[dcmPix release];
				}
			}
		}
		
		[pool release];
	}
}

- (IBAction) buildAllThumbnails:(id) sender
{
	if( [DCMPix isRunOsiriXInProtectedModeActivated]) return;
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"] == NO) return;

	NSManagedObjectContext	*context = [self managedObjectContext];
	NSManagedObjectModel	*model = [self managedObjectModel];
	long i;
	
	if( [checkIncomingLock tryLock])
	{	
		if( [context tryLock])
		{
			[context retain];
			
			DatabaseIsEdited = YES;
			
			@try
			{
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
				[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"thumbnail == NIL"]];
				NSError	*error = 0L;
				NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
				
				int maxSeries = [seriesArray count];
				
				if( maxSeries > 60) maxSeries = 60;	// We will continue next time...
				
				for( i = 0; i < maxSeries; i++)
				{
					NSManagedObject	*series = [seriesArray objectAtIndex: i];
					
					if([DCMAbstractSyntaxUID isImageStorage:[series valueForKey:@"seriesSOPClassUID"]] || [DCMAbstractSyntaxUID isRadiotherapy:[series valueForKey:@"seriesSOPClassUID"]] || [series valueForKey:@"seriesSOPClassUID"] == nil)
						[self buildThumbnail: series];
				}
				
				[self saveDatabase: currentDatabasePath];
			}
			
			@catch( NSException *ne)
			{
				NSLog(@"buildAllThumbnails exception: %@", [ne description]);
			}
			
			[context unlock];
			[context release];
		}
		[checkIncomingLock unlock];
	}
	
	DatabaseIsEdited = NO;
}

- (IBAction) rebuildThumbnails:(id) sender
{
	long					i, x, z, row, result;
	NSManagedObjectContext	*context = [self managedObjectContext];
	NSManagedObjectModel    *model = [self managedObjectModel];
	NSError					*error = 0L;
	
	[context retain];
	[context lock];
	
	NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
	if( [databaseOutline selectedRow] >= 0)
	{
		shouldDie = YES;
		[matrixLoadIconsLock lock];
		[matrixLoadIconsLock unlock];
		shouldDie = NO;
		
		for( x = 0; x < [selectedRows count] ; x++)
		{
			if( x == 0) row = [selectedRows firstIndex];
			else row = [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*object = [databaseOutline itemAtRow: row];
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Study"])
			{
				[[self childrenArray: object] setValue:0L forKey:@"thumbnail"];
			}
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Series"])
			{
				[object setValue:0L forKey:@"thumbnail"];
			}
		}
	}
	
	[self saveDatabase: currentDatabasePath];
	
	[self outlineViewRefresh];
	
	[context unlock];
	[context release];
	
	[previousItem release];
	previousItem = 0L;
	[[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: 0L];
}

- (void) matrixLoadIcons:(NSDictionary*) dict
{
	NSAutoreleasePool               *pool = [[NSAutoreleasePool alloc] init];
	long							i, subGroupCount = 1, position = 0;
	BOOL							imageLevel = [[dict valueForKey: @"imageLevel"] boolValue];
	NSArray							*files = [dict valueForKey: @"files"];
	NSArray							*filesPaths = [dict valueForKey: @"filesPaths"];
	
	[matrixLoadIconsLock lock];
	
	@try
	{
		for( i = 0; i < [filesPaths count];i++)
		{
			DCMPix*     dcmPix;
			NSImage		*thumbnail = 0L;
			
			thumbnail = [previewPixThumbnails objectAtIndex: i];
			
			int frame = 0;
			if( [[[files objectAtIndex: i] valueForKey:@"numberOfFrames"] intValue] > 1) frame = [[[files objectAtIndex: i] valueForKey:@"numberOfFrames"] intValue]/2;
			
			dcmPix  = [[DCMPix alloc] myinit:[filesPaths objectAtIndex:i] :position :subGroupCount :0L :frame :0 isBonjour:isCurrentDatabaseBonjour imageObj: [files objectAtIndex: i]];
			
			if( dcmPix)
			{
				if( thumbnail == notFoundImage)
				{
					[dcmPix computeWImage:YES :0 :0];
					if( [dcmPix getImage] == 0L) NSLog(@"getImage == 0L");
					[dcmPix revert];	// <- Kill the raw data
					
					thumbnail = [dcmPix getImage];
					if( thumbnail == 0L) thumbnail = notFoundImage;
					
					[previewPixThumbnails replaceObjectAtIndex: i withObject: thumbnail];
				}
				
				[previewPix addObject: dcmPix];
				[dcmPix release];
				
				if (shouldDie == YES) i = [filesPaths count];
			}
			else
			{
				dcmPix = [[DCMPix alloc] myinitEmpty];
				[previewPix addObject: dcmPix];
				[previewPixThumbnails replaceObjectAtIndex: i withObject: notFoundImage];
				[dcmPix release];
			}
			
//			Delay( 10, 0L);
		}
		
		shouldDie = NO;
		
		[self performSelectorOnMainThread:@selector( matrixDisplayIcons:) withObject:0L waitUntilDone: NO];
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"matrixLoadIcons exception: %@", [ne description]);
	}
	
	[matrixLoadIconsLock unlock];
	
    [pool release];
}

-(long) COLUMN
{
    return COLUMN;
}

#if !__LP64__
- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset
#else
- (CGFloat)splitView:(NSSplitView *)sender constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)offset
#endif
{
	if ([sender isEqual:sourcesSplitView])
	{
		return proposedPosition;
	}
	
    if( [sender isVertical] == YES)
    {
        NSSize size = [oMatrix cellSize];
        NSSize space = [oMatrix intercellSpacing];
        NSRect frame = [[oMatrix enclosingScrollView] frame];
		
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

-(void) ViewFrameDidChange:(NSNotification*) note
{
	if( [note object] == [[splitViewVert subviews] objectAtIndex: 1])	// 1
	{
		NSSize size = [oMatrix cellSize];
        NSSize space = [oMatrix intercellSpacing];
        NSRect frame = [[[splitViewVert subviews] objectAtIndex: 0] frame];
		
		int preWidth = frame.size.width+1;
		int width = frame.size.width;
		int cellsize = (size.width + space.width*2);
		
		width += cellsize/2;
		width /=  cellsize;
		width *=  cellsize;
		
		width += 17;
		
		while( [splitViewVert frame].size.width - width - [splitViewVert dividerThickness] <= 200 && width > 0) width -= cellsize;
	
		frame.size.width = width;
		[[[splitViewVert subviews] objectAtIndex: 0] setFrame: frame];
		
		frame = [[[splitViewVert subviews] objectAtIndex: 1] frame];
		frame.size.width = [splitViewVert frame].size.width - width - [splitViewVert dividerThickness];
		
		[[[splitViewVert subviews] objectAtIndex: 1] setFrame: frame];
		
		[splitViewVert adjustSubviews];
	}

}

-(void) splitViewDidResizeSubviews:(NSNotification *)aNotification
{
    NSSize size = [oMatrix cellSize];
    NSSize space = [oMatrix intercellSpacing];
    NSRect frame = [[oMatrix enclosingScrollView] frame];
    
    int newColumn = frame.size.width / (size.width + space.width*2);
    if( newColumn <= 0) newColumn = 1;
	
    if( newColumn != COLUMN)
    {
        int	i, minrow, row;
        int	selectedCellTag = [[oMatrix selectedCell] tag];
		
        COLUMN = newColumn;
        if( COLUMN == 0) { COLUMN = 1; NSLog(@"ERROR COLUMN = 0");}
        
		row = ceil((float)[matrixViewArray count]/(float) newColumn);
//		row = ceil((float)[[oMatrix cells] count]/(float)newColumn);
	//	minrow = 1 + (frame.size.height / (size.height + space.height*2));
	//	if( row < minrow) row = minrow;
		
        [oMatrix renewRows:row columns:newColumn];
        [oMatrix sizeToCells];
        
		
        for( i = [previewPix count];i<row*COLUMN;i++)
        {
            NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
            [cell setTransparent:YES];
            [cell setEnabled:NO];
        }
		
		[oMatrix selectCellWithTag: selectedCellTag];
    }
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
	if ([sender isEqual:splitViewVert]) return NO;
	else return YES;
}

#if __LP64__
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
#else
- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
#endif
{
	
	if ([sender isEqual:sourcesSplitView])
	{
		// minimum size of the top view (db, albums)
		return 200;
	}
	else if ([sender isEqual: splitViewHorz])
	{
		return [oMatrix cellSize].height;
	}
	else
	{
		return [oMatrix cellSize].width;
	}
}

#if __LP64__
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
#else
- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
#endif
{
	if ([sender isEqual:splitViewVert])
	{
		return [sender bounds].size.width-200;
	}
	else if ([sender isEqual:sourcesSplitView])
	{
		// maximum size of the top view (db, album) = opposite of the minimum size of the bottom view (bonjour)
		return [sender bounds].size.height-200;
	}
	else if ([sender isEqual: splitViewHorz])
	{
		return [sender bounds].size.height- (2*[oMatrix cellSize].height);
	}
	else
	{
		return [oMatrix cellSize].width;
	}
}

- (NSManagedObject *) firstObjectForDatabaseMatrixSelection
{
	NSArray				*cells = [oMatrix selectedCells];
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
	if( cells != 0L && aFile != 0L)
    {
		int x;
		
		for( x = 0; x < [cells count]; x++)
		{
			if( [[cells objectAtIndex: x] isEnabled] == YES)
			{
				NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[cells objectAtIndex: x] tag]];
				
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
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects onlyImages:(BOOL) onlyImages
{
	long				i, x, type;
    NSString			*pat, *stud, *ser;
	NSMutableArray		*selectedFiles = [NSMutableArray array];
	NSNumber			*row;
	NSArray				*cells = [oMatrix selectedCells];
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
    if( cells != 0L && aFile != 0L)
    {
		for( x = 0; x < [cells count]; x++)
		{
			if( [[cells objectAtIndex: x] isEnabled] == YES)
			{
				NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[cells objectAtIndex: x] tag]];
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
				{
					if( isCurrentDatabaseBonjour)
					{
						[selectedFiles addObject: [self getLocalDCMPath: curObj :50]];
					}
					else [selectedFiles addObject: [curObj valueForKey: @"completePath"]];
					
					if( correspondingManagedObjects) [correspondingManagedObjects addObject: curObj];
				}
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
				{
					NSArray *imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
					
					if( isCurrentDatabaseBonjour)
					{
						for( i = 0; i < [imagesArray count]; i++)
						{
							[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: i] :50]];
						}
					}
					else [selectedFiles addObjectsFromArray: [imagesArray valueForKey: @"completePath"]];
					
					if( correspondingManagedObjects) [correspondingManagedObjects addObjectsFromArray: imagesArray];
				}
			}
		}
	}
		
	return selectedFiles;
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects
{
	return [self filesForDatabaseMatrixSelection: correspondingManagedObjects onlyImages: YES];
}

- (NSArray*) matrixViewArray
{
	return matrixViewArray;
}

- (void) createContextualMenu
{
	NSMenu			*contextual		=  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenuItem		*item, *subItem;
	int				i = 0;
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images", nil)  action:@selector(viewerDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images in 4D", nil)  action:@selector(MovieViewerDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Key Images", nil)  action:@selector(viewerDICOMKeyImages:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Merged Selection", nil)  action:@selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal In Finder", nil)  action:@selector(revealInFinder:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as DICOM Files", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];

	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as Quicktime Files", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];

	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as JPEG Files", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Compress DICOM files in JPEG", nil)  action:@selector(compressSelectedFiles:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Decompress DICOM JPEG files", nil)  action:@selector(decompressSelectedFiles:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Toggle images/series displaying", nil)  action:@selector(displayImagesOfSeries:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil)  action:@selector(delItem:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Query this patient from Q&R window", nil)  action:@selector(querySelectedStudy:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Send to DICOM node", nil)  action:@selector(export2PACS:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy to iDisk", nil)  action:@selector(sendiDisk:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Burn", nil)  action:@selector(burnDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Anonymize", nil)  action:@selector(anonymizeDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];

	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Rebuild Selected Thumbnails", nil)  action:@selector(rebuildThumbnails:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[oMatrix setMenu:contextual];
	
	[contextual release];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Albums functions

- (IBAction)addSmartAlbum: (id)sender{
	SmartWindowController *smartWindowController = [[SmartWindowController alloc] init];
	NSWindow *sheet = [smartWindowController window];
	
    [NSApp beginSheet: sheet
            modalForWindow: [self window]
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
			
    [NSApp runModalForWindow:sheet];

    // Sheet is up here.
    [NSApp endSheet: sheet];
    [sheet orderOut: self];
	NSMutableArray *criteria = [smartWindowController criteria];
	if ([criteria count] > 0)
	{
		NSError				*error = 0L;
		NSString			*name;
		long				i = 2;
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		NSManagedObjectContext *context = [self managedObjectContext];
		
		[context retain];
		[context lock];
		error = 0L;
		NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
		
		name = [smartWindowController albumTitle];
		while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
		{
			name = [NSString stringWithFormat:@"%@ #%d", [smartWindowController albumTitle], i++];
		}
		
		NSManagedObject	*album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
		[album setValue:name forKey:@"name"];
		[album setValue:[NSNumber numberWithBool:YES] forKey:@"smartAlbum"];
		
		NSString		*format = [NSString string];
		
		for( i = 0; i < [criteria count]; i++)
		{
			NSString		*search = [criteria objectAtIndex: i];
			
			if( i != 0) format = [format stringByAppendingFormat: NSLocalizedString(@" AND ", nil)];
			format = [format stringByAppendingFormat: @"(%@)", search];
		}
		
		NSLog( format);
		[album setValue:format forKey:@"predicateString"];
		
		[self saveDatabase: currentDatabasePath];
		
		needDBRefresh = YES;
		[albumTable reloadData];
		
		[albumTable selectRow:[[self albumArray] indexOfObject: album] byExtendingSelection: NO];
		
		[context unlock];
		[context release];
		
		[self outlineViewRefresh];
	}
	
	[smartWindowController release];
}

- (IBAction) albumButtons: (id)sender
{
	switch( [sender selectedSegment])
	{
		case 0:	// Add album
		{
			[NSApp beginSheet: newAlbum
				modalForWindow: [self window]
				modalDelegate: nil
				didEndSelector: nil
				contextInfo: nil];
				
			int result = [NSApp runModalForWindow:newAlbum];
			
			[NSApp endSheet: newAlbum];
			[newAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse)
			{
				NSError				*error = 0L;
				NSString			*name;
				long				i = 2;
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Album"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				NSManagedObjectContext *context = [self managedObjectContext];
				
				[context retain];
				[context lock];
				error = 0L;
				NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
				
				name = [newAlbumName stringValue];
				while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
				{
					name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
				}
				
				NSManagedObject	*album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
				[album setValue:name forKey:@"name"];
				
				[self saveDatabase: currentDatabasePath];
				
				needDBRefresh = YES;
				[albumTable reloadData];
				
				[context unlock];
				[context release];
				
				[self outlineViewRefresh];
			}
		}
		break;
		
		case 1:	// Add smart album
		{
			[self addSmartAlbum: self];
		}
		break;
		
		case 2:	// Remove
		if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Delete an album", 0L),
											NSLocalizedString(@"Are you sure you want to delete this album?", 0L),
											NSLocalizedString(@"OK",nil),
											NSLocalizedString(@"Cancel",nil),
											0L) == NSAlertDefaultReturn)
		{
			long					i, x, row;
			NSManagedObjectContext	*context = [self managedObjectContext];
			
			[context retain];
			[context lock];
			
			if( [albumTable selectedRow] > 0)	// We cannot delete the first item !
			{
				shouldDie = YES;
				[matrixLoadIconsLock lock];
				[matrixLoadIconsLock unlock];
				shouldDie = NO;
				
				[context deleteObject: [[self albumArray]  objectAtIndex: [albumTable selectedRow]]];
			}
			
			[self saveDatabase: currentDatabasePath];
			
			[albumNoOfStudiesCache removeAllObjects];
			[albumTable reloadData];
			
			[context unlock];
			[context release];
			
			[self outlineViewRefresh];
		}
		break;
	}
}

static BOOL needToRezoom;

- (void)drawerDidClose:(NSNotification *)notification
{
	if( needToRezoom)
	{
		[[self window] zoom:self];
	}
}

- (void)drawerWillClose:(NSNotification *)notification
{
	if( [[self window] isZoomed])
	{
		needToRezoom = YES;
	}
	else needToRezoom = NO;
}

- (void)drawerDidOpen:(NSNotification *)notification
{
	if( needToRezoom)
	{
		[[self window] zoom:self];
	}
}

- (void)drawerWillOpen:(NSNotification *)notification
{
	if( [[self window] isZoomed])
	{
		needToRezoom = YES;
	}
	else needToRezoom = NO;
}

- (IBAction) smartAlbumHelpButton:(id) sender
{
	if( [sender tag] == 0)
	{
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"]];
	}
	
	if( [sender tag] == 1)
	{
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
	}
}

- (IBAction) albumTableDoublePressed:(id) sender
{
	if( [albumTable selectedRow] > 0)
	{
		NSManagedObject	*album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == YES)
		{
			[editSmartAlbumName setStringValue: [album valueForKey:@"name"]];
			[editSmartAlbumQuery setStringValue: [album valueForKey:@"predicateString"]];
			
			[NSApp beginSheet: editSmartAlbum
			modalForWindow: [self window]
			modalDelegate: nil
			didEndSelector: nil
			contextInfo: nil];
				
			int result = [NSApp runModalForWindow:editSmartAlbum];
			
			[NSApp endSheet: editSmartAlbum];
			[editSmartAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse)
			{
				NSError				*error = 0L;
				NSString			*name;
				long				i = 2;
				
				NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Album"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				
				NSManagedObjectContext *context = [self managedObjectContext];
				
				[context retain];
				[context lock];
				error = 0L;
				NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
				
				if( [[editSmartAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO)
				{
					name = [editSmartAlbumName stringValue];
					while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
					{
						name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
					}
					
					[album setValue:name forKey:@"name"];
				}
				
				[album setValue:[editSmartAlbumQuery stringValue] forKey:@"predicateString"];
				
				[self saveDatabase: currentDatabasePath];
				
				[albumTable selectRow: [[self albumArray] indexOfObject:album] byExtendingSelection: NO];
				
				[self outlineViewRefresh];
				
				[albumNoOfStudiesCache removeAllObjects];
				[albumTable reloadData];
				
				[context unlock];
				[context release];
			}
		}
		else
		{
			[newAlbumName setStringValue: [album valueForKey:@"name"]];
			
			[NSApp beginSheet: newAlbum
			modalForWindow: [self window]
			modalDelegate: nil
			didEndSelector: nil
			contextInfo: nil];
				
			int result = [NSApp runModalForWindow:newAlbum];
			
			[NSApp endSheet: newAlbum];
			[newAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse)
			{
				NSError				*error = 0L;
				NSString			*name;
				long				i = 2;
				
				if( [[newAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO)
				{
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Album"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
					NSManagedObjectContext *context = [self managedObjectContext];
					
					[context retain];
					[context lock];
					error = 0L;
					NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
					
					name = [newAlbumName stringValue];
					while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
					{
						name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
					}
					
					[album setValue:name forKey:@"name"];
					
					[self saveDatabase: currentDatabasePath];
					
					[albumTable selectRow: [[self albumArray] indexOfObject:album] byExtendingSelection: NO];
					
					[albumTable reloadData];
					
					[context unlock];
					[context release];
				}
			}
		}
	}
}

- (NSTableView*) albumTable { return albumTable;}

- (NSArray*) albumArray
{
	NSError					*error = 0L;
	NSArray					*result;
	NSString				*dbName = @"main";
	NSManagedObjectContext	*context = [self managedObjectContext];
	NSManagedObjectModel	*model = [self managedObjectModel];
	
	[context retain];
	[context lock];
	
	//Find all albums
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Album"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
	
	NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	albumsArray = [albumsArray sortedArrayUsingDescriptors:  [NSArray arrayWithObjects: sort, 0L]];
	result = [NSArray arrayWithObject: [NSDictionary dictionaryWithObject: @"Database" forKey:@"name"]];
	
	[context unlock];
	[context release];
	
	return [result arrayByAddingObjectsFromArray: albumsArray];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Albums/send & ReceiveLog/Bonjour TableView functions

//NSTableView delegate and datasource
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if ([aTableView isEqual:albumTable])
	{
		return [[self albumArray] count];
	}
	else if ([aTableView isEqual:bonjourServicesList])
	{
		if (bonjourBrowser!=nil)
		{
			return [[bonjourBrowser services] count]+1;
		}
		else
		{
			return 1;
		}
	}
	return nil;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ([aTableView isEqual:albumTable])
	{
		if([[aTableColumn identifier] isEqualToString:@"no"])
		{
			int albumNo = [[self albumArray] count];
			
			if( albumNoOfStudiesCache == 0L || [albumNoOfStudiesCache count] != albumNo || [[albumNoOfStudiesCache objectAtIndex: rowIndex] isEqualToString:@""] == YES)
			{
				if( albumNoOfStudiesCache == 0L || [albumNoOfStudiesCache count] != albumNo)
				{
					[albumNoOfStudiesCache release];
					
					albumNoOfStudiesCache = [[NSMutableArray alloc] initWithCapacity: albumNo];
					int i;
					for( i = 0; i < albumNo; i++) [albumNoOfStudiesCache addObject:@""];
				}
				
				if( rowIndex == 0)
				{
					// Find all studies
					NSError			*error = 0L;
					NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
					NSManagedObjectContext *context = [self managedObjectContext];
					
					[context retain];
					[context lock];
					error = 0L;
					NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
					
					[context unlock];
					[context release];
					
					[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]]];
				}
				else
				{
					NSManagedObject	*object = [[self albumArray]  objectAtIndex: rowIndex];
					
					if( [[object valueForKey:@"smartAlbum"] boolValue] == YES)
					{
						NSManagedObjectContext *context = [self managedObjectContext];
						
						[context retain];
						[context lock];
						
						@try
						{
							// Find all studies
							NSError			*error = 0L;
							NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
							[dbRequest setPredicate: [self smartAlbumPredicate: object]];
							
							error = 0L;
							NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
							
							[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]]];
						}
						
						@catch( NSException *ne)
						{
							NSLog(@"TableView exception: %@", [ne description]);
							[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject:@"err"];
						}
						
						[context unlock];
						[context release];
					}
					else [albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[[object valueForKey:@"studies"] count]]]]];
				}
			}
			
			return [albumNoOfStudiesCache objectAtIndex: rowIndex];
		}
		else
		{
			NSManagedObject	*object = [[self albumArray]  objectAtIndex: rowIndex];
			return [object valueForKey:@"name"];
		}
	}
	else if ([aTableView isEqual:bonjourServicesList])
	{
		if([[aTableColumn identifier] isEqualToString:@"Source"])
		{
			if (bonjourBrowser!=nil)
			{
				NSDictionary *dict = 0L;
				if( rowIndex > 0) dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
				
				if( rowIndex == 0) return NSLocalizedString(@"Local Default Database", 0L);
				else if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) return [[dict valueForKey:@"service"] name];
				else return [dict valueForKey:@"Description"];
			}
			else
			{
				return NSLocalizedString(@"Local Default Database", 0L);
			}
		}
	}
			
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if( [aCell isKindOfClass: [ImageAndTextCell class]])
	{
		[(ImageAndTextCell*) aCell setLastImage: 0L];
		[(ImageAndTextCell*) aCell setLastImageAlternate: 0L];
	}
	
	if ([aTableView isEqual:albumTable])
	{
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 11];
		else txtFont = [NSFont systemFontOfSize:11];			
		
		[aCell setFont:txtFont];
		[aCell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
		if( [[aTableColumn identifier] isEqualToString:@"Source"])
		{ 
			if ([[[[self albumArray] objectAtIndex:rowIndex] valueForKey:@"smartAlbum"] boolValue])
			{
				if(isCurrentDatabaseBonjour)
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_sharedSmartAlbum.tiff"]];
				}
				else
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_smartAlbum.tiff"]];
				}
			}
			else
			{
				if(isCurrentDatabaseBonjour)
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_sharedAlbum.tiff"]];
				}
				else
				{
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"small_album.tiff"]];
				}
			}
		}
	}
	
	if ([aTableView isEqual:bonjourServicesList])
	{
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 11];
		else txtFont = [NSFont systemFontOfSize:11];			
		
		[aCell setFont:txtFont];
		[aCell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
		
		NSDictionary *dict = 0L;
		if( rowIndex > 0) dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
		
		if (rowIndex == 0)
		{
			[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"osirix16x16.tiff"]];
		}
		else if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"])
		{
			[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"bonjour.tiff"]];
		}
		else
		{
			NSString	*type = [dict valueForKey:@"type"];
			NSString	*path = [dict valueForKey:@"Path"];
			
			if( [type isEqualToString:@"fixedIP"])
				[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"FixedIP.tif"]];
				
			if( [type isEqualToString:@"localPath"])
			{
				BOOL isDirectory;
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
				{
					if( isDirectory)
					{
						NSString *iPodControlPath = [path stringByAppendingPathComponent:@"iPod_Control"];
						BOOL isItAnIpod = [[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath];
						
						// Root?
						BOOL isThereAnOsiriXDataAtTheRoot = NO;
						int i;
						
						NSArray* mountedVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
						for( i = 0; i < [mountedVolumes count] ; i++)
						{
							if( [[mountedVolumes objectAtIndex: i] isEqualToString: path]) isThereAnOsiriXDataAtTheRoot = YES;
						}

						BOOL removableMedia = NO;
						NSArray* removableVolumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
						for( i = 0; i < [removableVolumes count] ; i++)
						{
							if( [[removableVolumes objectAtIndex: i] isEqualToString: path]) removableMedia = YES;
						}
						
						// iPod? or root?
						
						if (isItAnIpod || isThereAnOsiriXDataAtTheRoot)
						{
							NSImage	*im = [[NSWorkspace sharedWorkspace] iconForFile: path];
							[im setSize: NSMakeSize( 16, 16)];
							[(ImageAndTextCell*) aCell setImage: im];
							if( isItAnIpod || removableMedia)
							{
								[(ImageAndTextCell*) aCell setLastImage: [NSImage imageNamed:@"iPodEjectOff.tif"]];
								[(ImageAndTextCell*) aCell setLastImageAlternate: [NSImage imageNamed:@"iPodEjectOn.tif"]]; 
							}
						}
						else if( [[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:@"OsiriX Data"] isDirectory: &isDirectory])
						{
							[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"FolderIcon.tif"]];
						}
						else
							[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"away.tif"]];
					}
					else
						[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"FileIcon.tif"]];
				}
				else
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"away.tif"]];
			}
		}
	}
}

- (void) sendDICOMFilesToOsiriXNode:(NSDictionary*) todo
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	NSLog( @"sendDICOMFilesToOsiriXNode started");
	
	[autoroutingInProgress lock];
	
	DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
																calledAET: [todo objectForKey:@"AETitle"] 
																hostname: [todo objectForKey:@"Address"] 
																port: [[todo objectForKey:@"Port"] intValue] 
																filesToSend: [todo valueForKey: @"Files"]
																transferSyntax: [[todo objectForKey:@"Transfer Syntax"] intValue] 
																compression: 1.0
																extraParameters: nil];
							
	@try
	{
		[storeSCU run:self];
	}
	
	@catch (NSException *ne)
	{
		NSLog( @"Bonjour DICOM Send FAILED");
		NSLog( [ne name]);
		NSLog( [ne reason]);
	}
	
	[storeSCU release];
	storeSCU = 0L;
	
	[autoroutingInProgress unlock];
	
	NSLog( @"sendDICOMFilesToOsiriXNode ended");
	
	[pool release];
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	long i;
	
	if ([tableView isEqual:albumTable] && !isCurrentDatabaseBonjour)
	{
		NSArray	*albumArray = [self albumArray];
	
		if (row >= [albumArray count] || row  == 0)
			return NO;
		
		//can't add to smart Album
		if ([[[albumArray objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue]) return NO;
		
		NSManagedObject *album = [albumArray objectAtIndex: row];
		
		if( draggedItems)
		{
			for( i = 0; i < [draggedItems count]; i++)
			{
				NSManagedObject		*object = [draggedItems objectAtIndex: i];
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Study"])
				{
					NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
					
					[studies addObject: object];
				}
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Series"])
				{
					NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
					
					[studies addObject: [object valueForKey:@"study"]];
				}
			}
			
			[self saveDatabase: currentDatabasePath];
			
			[albumNoOfStudiesCache replaceObjectAtIndex:row withObject:@""];
			[tableView reloadData];
		}
		
		return YES;
	}
	
	if ([tableView isEqual:bonjourServicesList])
	{
		if(draggedItems)
		{
			NSManagedObject *curStudy, *curSerie, *curImage;
			NSString		*filePath, *destPath;
			
			NSEnumerator		*enumeratorSeries, *enumeratorImages;
			NSMutableArray		*imagesArray = [NSMutableArray arrayWithCapacity:0];
			long				noOfFiles = 0;
			
			for( i = 0; i < [draggedItems count]; i++)
			{
				NSManagedObject		*object = [draggedItems objectAtIndex: i];
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Study"])
				{
					enumeratorSeries = [[object valueForKey:@"series"] objectEnumerator];
					while (curSerie = [enumeratorSeries nextObject])
					{
						[imagesArray addObjectsFromArray: [[curSerie valueForKey:@"images"] allObjects]];
					}
				}
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Series"])
				{
					[imagesArray addObjectsFromArray: [[object valueForKey:@"images"] allObjects]];
				}
			}
			
			// DESTINATION IS A LOCAL PATH
			
			NSDictionary *object = 0L;
			
			if( row > 0) object = [[bonjourBrowser services] objectAtIndex: row-1];
			
			if( [[object valueForKey: @"type"] isEqualToString:@"localPath"] || (row == 0 && isCurrentDatabaseBonjour == NO))
			{
				NSString	*dbFolder = 0L;
				NSString	*sqlFile = 0L;
				
				if( row == 0)
				{
					dbFolder = [[self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]] stringByDeletingLastPathComponent];
					sqlFile = [[dbFolder stringByAppendingPathComponent:@"OsiriX Data"] stringByAppendingPathComponent:@"Database.sql"];
				}
				else
				{
					dbFolder = [self getDatabaseFolderFor: [object valueForKey: @"Path"]];
					sqlFile = [self getDatabaseIndexFileFor: [object valueForKey: @"Path"]];				
				}
				
				if( sqlFile && dbFolder)
				{
					// LOCAL PATH - DATABASE
					@try
					{
						NSLog( @"-----------------------------");
						NSLog( @"Destination is a 'local' path");
						
						
						Wait *splash = 0L;
						
						if( isCurrentDatabaseBonjour)
							splash = [[Wait alloc] initWithString:NSLocalizedString(@"Downloading files...", nil)];
						
						[splash showWindow:self];
						[[splash progress] setMaxValue:[imagesArray count]];
							
						NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: [imagesArray count]];
						for( i = 0; i < [imagesArray count]; i++)
						{
							NSString	*sendPath = [self getLocalDCMPath:[imagesArray objectAtIndex: i] :10];
							[packArray addObject: sendPath];
							
							[splash incrementBy:1];
						}
						
						[splash close];
						[splash release];
						
						
						NSLog( @"DB Folder: %@", dbFolder);
						NSLog( @"SQL File: %@", sqlFile);
						NSLog( @"Current documentsDirectory: %@", [self documentsDirectory]);
						
						NSPersistentStoreCoordinator *sc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
						NSManagedObjectContext *sqlContext = [[NSManagedObjectContext alloc] init];
							
						[sqlContext setPersistentStoreCoordinator: sc];

						NSError	*error = 0L;
						[sc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath: sqlFile] options:nil error:&error];
						
						if( [dbFolder isEqualToString: [[self documentsDirectory] stringByDeletingLastPathComponent]] && isCurrentDatabaseBonjour == NO)	// same database folder - we don't need to copy the files
						{
							NSLog( @"Destination DB Folder is identical to Current DB Folder");
							
							[self addFilesToDatabase: packArray onlyDICOM:NO safeRebuild:NO produceAddedFiles:NO parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
						}
						else
						{
							NSMutableArray	*dstFiles = [NSMutableArray array];
							NSLog( @"Destination DB Folder is NOT identical to Current DB Folder");
							
							// First we copy the files to the DATABASE folder
							splash = [[Wait alloc] initWithString:NSLocalizedString(@"Copying to OsiriX database...", nil)];
							
							[splash setCancel:YES];
							[splash showWindow:self];
							[[splash progress] setMaxValue:[packArray count]];
							
							for( i=0; i < [packArray count]; i++)
							{
								[splash incrementBy:1];
								
								NSString *dstPath, *srcPath = [packArray objectAtIndex: i];
								BOOL isDicomFile = [DicomFile isDICOMFile:srcPath];
								
								if( isDicomFile) dstPath = [self getNewFileDatabasePath:@"dcm" dbFolder: [dbFolder stringByAppendingPathComponent: @"OsiriX Data"]];
								else dstPath = [self getNewFileDatabasePath: [[srcPath pathExtension] lowercaseString] dbFolder: [dbFolder stringByAppendingPathComponent: @"OsiriX Data"]];
								
								if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil])
									[dstFiles addObject: dstPath];
									
								if( [splash aborted]) 
									i = [packArray count];
							}
							[splash close];
							[splash release];
							
							// Then we add the files to the sql file
							[self addFilesToDatabase: dstFiles onlyDICOM:NO safeRebuild:NO produceAddedFiles:NO parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
						}
						
						error = 0L;
						[sqlContext save: &error];
						
						[sc release];
						[sqlContext release];
					}
					
					@catch (NSException * e)
					{
						NSLog( [e description]);
						NSLog( @"Exception !! *******");
					}
				}
				else NSRunCriticalAlertPanel( NSLocalizedString(@"Error",0L),  NSLocalizedString(@"Destination Database / Index file is not available.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
				
				NSLog( @"-----------------------------");
			}
			else if( isCurrentDatabaseBonjour == YES)  // Copying FROM Distant to local OR distant
			{
				Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Copying from OsiriX database...", nil)];
				BOOL OnlyDICOM = YES;
				BOOL succeed = NO;
				
				[splash showWindow:self];
				[[splash progress] setMaxValue:[imagesArray count]];
				
				for( i = 0; i < [imagesArray count]; i++)
				{
					if( [[[imagesArray objectAtIndex:i] valueForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) OnlyDICOM = NO;
				}
				
				if( OnlyDICOM)
				{
					succeed = [bonjourBrowser retrieveDICOMFilesWithSTORESCU: [bonjourServicesList selectedRow]-1 to: row-1 paths: [imagesArray valueForKey:@"path"]];
					if( succeed)
					{
						for( i = 0; i < [imagesArray count]; i++) [splash incrementBy:1];
					}
				}
				else NSLog( @"Not Only DICOM !");
				
				if( succeed == NO || OnlyDICOM == NO)
				{
					for( i = 0; i < [imagesArray count]; i++)
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
						filePath = [self getLocalDCMPath: [imagesArray objectAtIndex: i] :100];
						destPath = [[documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH] stringByAppendingPathComponent: [filePath lastPathComponent]];
						
						// The files are moved to the INCOMING folder : they will be automatically added when switching back to local database!
						
						[[NSFileManager defaultManager] copyPath:filePath toPath:destPath handler:nil];
						
						if([[filePath pathExtension] isEqualToString:@"zip"])
						{
							// it is a ZIP
							NSString *xmlPath = [[filePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
							NSString *xmlDestPath = [[destPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
							[[NSFileManager defaultManager] copyPath:xmlPath toPath:xmlDestPath handler:nil];
						}
						
						[splash incrementBy:1];
						
						[pool release];
					}
				}
				else [[splash progress] setDoubleValue: [imagesArray count]];
				
				[splash close];
				[splash release];
			}
			else if( [bonjourServicesList selectedRow] != row)	 // Copying From Local to distant
			{
				long	x;
				BOOL	OnlyDICOM = YES;
								
				NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: [imagesArray count]];
				
				for( i = 0; i < [imagesArray count]; i++)
				{
					NSString	*sendPath = [self getLocalDCMPath:[imagesArray objectAtIndex: i] :1];
				
					[packArray addObject: sendPath];
					
					if( [[[imagesArray objectAtIndex:i] valueForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) OnlyDICOM = NO;
				}
				
				NSDictionary *dcmNode = [[bonjourBrowser services] objectAtIndex: row-1];
				
				if( OnlyDICOM == NO) NSLog( @"Not Only DICOM !");
				
				if( [dcmNode valueForKey:@"Address"] && OnlyDICOM)
				{
					WaitRendering		*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Transfer started...", nil)];
					[wait showWindow:self];
					
					NSMutableDictionary	*todo = [NSMutableDictionary dictionaryWithDictionary: dcmNode];
					
					[todo setObject: packArray forKey:@"Files"];
					
					[NSThread detachNewThreadSelector:@selector( sendDICOMFilesToOsiriXNode:) toTarget:self withObject: todo];
					
					Delay( 60, 0L);
					
					[wait close];
					[wait release];
				}
				else
				{
					Wait	*splash = [[Wait alloc] initWithString:@"Copying to OsiriX database..."];
					[splash showWindow:self];
					[[splash progress] setMaxValue:[imagesArray count]];
					
					for( i = 0; i < [imagesArray count];)
					{
						NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
						NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: 10];
						
						for( x = 0; x < 10; x++)
						{
							if( i <  [imagesArray count])
							{
								NSString	*sendPath = [self getLocalDCMPath:[imagesArray objectAtIndex: i] :1];
							
								[packArray addObject: sendPath];
								
								if([[sendPath pathExtension] isEqualToString:@"zip"])
								{
									// it is a ZIP
									NSString *xmlPath = [[sendPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
									[packArray addObject: xmlPath];
								}
								[splash incrementBy:1];
							}
							i++;
						}
						
						[bonjourBrowser sendDICOMFile: row-1 paths: packArray];
						
						[pool release];
					}
					
					[splash close];
					[splash release];
				}
			}
			else return NO;
		}
		
		return YES;
	}
	
	return NO;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([tableView isEqual:albumTable] && !isCurrentDatabaseBonjour)
	{
		NSArray	*array = [self albumArray];
		
		if ((row >= [array count]) || [[[array objectAtIndex:row] valueForKey:@"smartAlbum"] boolValue] || row == 0) return NSDragOperationNone;
		
		[albumTable setDropRow:row dropOperation:NSTableViewDropOn];
		
		return NSTableViewDropAbove;
	}
	
	if ([tableView isEqual:bonjourServicesList])
	{
		BOOL accept = NO;
		
		if( row <= [[bonjourBrowser services] count])
		{
			if( [bonjourServicesList selectedRow] != row) accept = YES;
			
			if( accept)
			{
				[bonjourServicesList setDropRow:row dropOperation:NSTableViewDropOn];
				return NSTableViewDropAbove;
			}
		}
	}
	
	return NSDragOperationNone;
}

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(int)row mouseLocation:(NSPoint)mouseLocation
{
	if( [tv isEqual: bonjourServicesList])
	{
		if( row > 0)
		{
			NSString		*result = 0L;
			NSDictionary	*dcmNode = [[bonjourBrowser services] objectAtIndex: row-1];
			
			if( [[dcmNode valueForKey:@"type"] isEqualToString: @"localPath"])
			{
				if( [[[dcmNode valueForKey:@"Path"] pathExtension] isEqualToString:@"sql"]) return [dcmNode valueForKey:@"Path"];
				else return [[dcmNode valueForKey:@"Path"] stringByAppendingPathComponent:@"OsiriX Data/"];
			}
			
			if( [[dcmNode valueForKey:@"type"] isEqualToString: @"fixedIP"])
			{
				return [dcmNode valueForKey:@"Address"];
			}
			
			if( [[dcmNode valueForKey:@"type"] isEqualToString: @"bonjour"])
			{
				return [dcmNode valueForKey:@"Address"];
			}
		}
		else
		{
			return  [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
		}
	}
	
	return 0L;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if( [[aNotification object] isEqual: albumTable])
	{
		// Clear search field
		[self setSearchString:nil];
		
		if( [albumTable selectedRow] < [albumNoOfStudiesCache count])
		{
			[albumNoOfStudiesCache replaceObjectAtIndex: [albumTable selectedRow]  withObject:@""];
		}
		[albumTable reloadData];
	}
	
	if( [[aNotification object] isEqual: bonjourServicesList])
	{
		if( dontLoadSelectionSource == NO)
		{
			[self syncReportsIfNecessary: previousBonjourIndex];
			
			[albumNoOfStudiesCache removeAllObjects];
			
			[self bonjourServiceClicked: bonjourServicesList];
			
			[self setSearchString:nil];
			
			previousBonjourIndex = [bonjourServicesList selectedRow]-1;
		}
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Open 2D/4D Viewer functions

- (BOOL) computeEnoughMemory:(NSArray*) toOpenArray :(unsigned long*) requiredMem
{
	BOOL enoughMemory = YES;
	unsigned long long mem = 0, memBlock = 0, x, i;
	unsigned char* testPtr[ 800];
	
	for( x = 0; x < [toOpenArray count]; x++)
	{
		memBlock = 0;				
		NSArray* loadList = [toOpenArray objectAtIndex: x];
		NSManagedObject*  curFile = [loadList objectAtIndex: 0];
		
		if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
		{
			mem += [[curFile valueForKey:@"width"] intValue]* [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
			memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
		}
		else
		{
			for( i = 0; i < [loadList count]; i++)
			{
				curFile = [loadList objectAtIndex: i];
				
				mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
				memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
			}
		}
		
		NSLog(@"Test memory for: %d Mb", (memBlock * sizeof(float)) / (1024 * 1024));
		testPtr[ x] = malloc( (memBlock * sizeof(float)) + 4096);
		if( testPtr[ x] == 0L) enoughMemory = NO;
		
	} //end for
	
	for( x = 0; x < [toOpenArray count]; x++)
	{
		if( testPtr[ x]) free( testPtr[ x]);
	}
	
	mem /= 1024;
	mem /= 1024;
	
	if( requiredMem) *requiredMem = mem;
	
	return enoughMemory;
}

- (void) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages
{
	
	// memBlockSize was previously declared as a dynamic array, but this was causing problems with the call stack
	// thus, I've declared it on the heap instead.  - RBR 2007-05-20
	unsigned long		*memBlockSize = malloc( [toOpenArray count] * sizeof *memBlockSize );
	
	NS_DURING
		// masu 2006-07-19
		// size of array should be size of toOpenArray - was:
		unsigned long		memBlock, mem;
		long				x, i;
	//	long				z;
		NSArray				*loadList = 0L;
		BOOL				multiFrame = NO;
		float				*fVolumePtr = 0L;
		NSData				*volumeData = 0L;
		NSMutableArray		*viewerPix[ 50];
		ViewerController	*movieController = 0L;
		
// NS_DURING (1) keyImages
		
		if( keyImages)
		{
			NSArray *keyImagesToOpenArray = [NSArray array];
			
			for( x = 0; x < [toOpenArray count]; x++)
			{
				loadList = [toOpenArray objectAtIndex: x];
				
				NSArray *keyImagesArray = [NSArray array];
				for( i = 0; i < [loadList count]; i++)
				{
					NSManagedObject	*image = [loadList objectAtIndex: i];
					
					if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
						keyImagesArray = [keyImagesArray arrayByAddingObject: image];
				}
				
				if( [keyImagesArray count] > 0)
					keyImagesToOpenArray = [keyImagesToOpenArray arrayByAddingObject: keyImagesArray];
			}
			
			if( [keyImagesToOpenArray count] > 0) toOpenArray = keyImagesToOpenArray;
		}
		
		if (([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) || ([self computeEnoughMemory: toOpenArray : 0L] == NO))
		{
			toOpenArray = [self openSubSeries: toOpenArray];
		}
		
// NS_DURING (2) Compute Required Memory

		BOOL	enoughMemory = NO;
		long	subSampling = 1;
		
		while( enoughMemory == NO)
		{
			BOOL memTestFailed = NO;
			mem = 0;
			memBlock = 0;
			unsigned char* testPtr[ 800];
			
			for( x = 0; x < [toOpenArray count]; x++)
			{
				memBlock = 0;				
				loadList = [toOpenArray objectAtIndex: x];
				NSManagedObject*  curFile = [loadList objectAtIndex: 0];
				[curFile setValue:[NSDate date] forKeyPath:@"series.dateOpened"];
				[curFile setValue:[NSDate date] forKeyPath:@"series.study.dateOpened"];
				
				if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
				{
					multiFrame = YES;
					
					mem += [[curFile valueForKey:@"width"] intValue]* [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
					memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
				}
				else
				{
					for( i = 0; i < [loadList count]; i++)
					{
						curFile = [loadList objectAtIndex: i];
						
						mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
						memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
					}
				}
				
				if ( memBlock == 1 ) memBlock = 256 * 256;  // This is the size of array created when when an image doesn't exist, a 256 square graduated gray scale.
				
				NSLog(@"Test memory for: %d Mb", (memBlock * sizeof(float)) / (1024 * 1024));
				testPtr[ x] = malloc( (memBlock * sizeof(float)) + 4096);
				if( testPtr[ x] == 0L) memTestFailed = YES;
				memBlockSize[ x] = memBlock;
				
			} //end for
			
			for( x = 0; x < [toOpenArray count]; x++)
			{
				if( testPtr[ x]) free( testPtr[ x]);
			}
			
			// TEST MEMORY : IF NOT ENOUGH -> REDUCE SAMPLING
			
			if( memTestFailed)
			{
				NSLog(@"Test memory failed -> sub-sampling");
				
				NSArray *newArray = [NSArray array];
				
				subSampling *= 2;
				
				for( x = 0; x < [toOpenArray count]; x++)
				{
					loadList = [toOpenArray objectAtIndex: x];
					
					NSArray *imagesArray = [NSArray array];
					for( i = 0; i < [loadList count]; i++)
					{
						NSManagedObject	*image = [loadList objectAtIndex: i];
						
						if( i % 2 == 0)	imagesArray = [imagesArray arrayByAddingObject: image];
					}
					
					if( [imagesArray count] > 0)
						newArray = [newArray arrayByAddingObject: imagesArray];
				}
				
				toOpenArray = newArray;
			}
			else enoughMemory = YES;
		} //end while
		
		int result = NSAlertDefaultReturn;
		
		if( subSampling != 1)
		{
			NSArray	*winList = [NSApp windows];
			for( i = 0; i < [winList count]; i++)
			{
				if([[winList objectAtIndex:i] isMiniaturized])
				{
					[[winList objectAtIndex:i] deminiaturize:self];
				}
			}
			
			result = NSRunInformationalAlertPanel( NSLocalizedString(@"Not enough memory", 0L),  [NSString stringWithFormat: NSLocalizedString(@"Your computer doesn't have enough RAM to load this series, but I can load a subset of the series: 1 on %d images.", 0L), subSampling], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}

// NS_DURING (3) Load Images (memory allocation)
		
		BOOL		notEnoughMemory = NO;
		
		if( result == NSAlertDefaultReturn && toOpenArray != 0L)
		{
			if( movieViewer == NO)
			{
//				NSLog(@"I will try to allocate: %d Mb", (mem * sizeof(float)) / (1024 * 1024));
//				
//				fVolumePtr = malloc(mem * sizeof(float));
//				if( fVolumePtr == 0L)
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
//				fVolumePtr = 0L;	
			}
			else
			{
				// masu 2006-07-19
				// this array might be to small- was:
				//char*		memBlockTestPtr[ 200];
				char*		memBlockTestPtr[[toOpenArray count]];
				
				NSLog(@"4D Viewer TOTAL: %d Mb", (mem * sizeof(float)) / (1024 * 1024));
				for( x = 0; x < [toOpenArray count]; x++)
				{
					memBlockTestPtr[ x] = malloc(memBlockSize[ x] * sizeof(float));
					NSLog(@"4D Viewer: I will try to allocate: %d Mb", (memBlockSize[ x]* sizeof(float)) / (1024 * 1024));
					
					if( memBlockTestPtr[ x] == 0L) notEnoughMemory = YES;
				}
				
				for( x = 0; x < [toOpenArray count]; x++)
				{
					if( memBlockTestPtr[ x] != 0L) free( memBlockTestPtr[ x]);
				}
				
				if( notEnoughMemory)
				{
					NSRunCriticalAlertPanel( NSLocalizedString(@"Not enough memory",@"Not enough memory"),  NSLocalizedString(@"Your computer doesn't have enough RAM to load this series",@"Your computer doesn't have enough RAM to load this series"), NSLocalizedString(@"OK",nil), nil, nil);
				}
				
				fVolumePtr = 0L;
			}
		}
		else notEnoughMemory = YES;

// NS_DURING (4) Load Images loop
		
		if( notEnoughMemory == NO)
		{
			mem = 0;
			for( x = 0; x < [toOpenArray count]; x++)
			{
				NSLog(@"Current block to malloc: %d Mb", (memBlockSize[ x] * sizeof( float)) / (1024*1024));
				fVolumePtr = malloc( memBlockSize[ x] * sizeof(float));
				mem = 0;
				
				if( fVolumePtr)
				{
					volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:memBlockSize[ x]*sizeof( float) freeWhenDone:YES];
					loadList = [toOpenArray objectAtIndex: x];
					// Why viewerPix[0] (fixed value) within the loop?					
					viewerPix[0] = [[NSMutableArray alloc] initWithCapacity:0];
					NSMutableArray *correspondingObjects = [[NSMutableArray alloc] initWithCapacity:0];
					
					if( [loadList count] == 1 && [[[loadList objectAtIndex: 0] valueForKey:@"numberOfFrames"] intValue] > 1)
					{
						multiFrame = YES;							
						NSManagedObject*  curFile = [loadList objectAtIndex: 0];
						
						for( i = 0; i < [[curFile valueForKey:@"numberOfFrames"] intValue]; i++)
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: 0];								
							DCMPix*			dcmPix;
							dcmPix = [[DCMPix alloc] myinit: [curFile valueForKey:@"completePath"] :i :[[curFile valueForKey:@"numberOfFrames"] intValue] :fVolumePtr+mem :i :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curFile];
							
							if( dcmPix)
							{
								mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
								
								[viewerPix[0] addObject: dcmPix];
								[correspondingObjects addObject: curFile];
								[dcmPix release];
							}
						} //end for
					}
					else
					{
						//multiframe==NO
						for( i = 0; i < [loadList count]; i++)
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: i];
							DCMPix*     dcmPix;
							dcmPix = [[DCMPix alloc] myinit: [curFile valueForKey:@"completePath"] :i :[loadList count] :fVolumePtr+mem :0 :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curFile];
							
							if( dcmPix)
							{
								mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
								
								[viewerPix[0] addObject: dcmPix];
								[correspondingObjects addObject: curFile];
								[dcmPix release];
							}
							else
							{
								NSLog( @"not readable: %@", [curFile valueForKey:@"completePath"] );
							}
						}
					}
					
					if( [viewerPix[0] count] != [loadList count] && multiFrame == NO)
					{
						for( i = 0; i < [viewerPix[0] count]; i++)
						{
							[[viewerPix[0] objectAtIndex: i] setID: i];
							[[viewerPix[0] objectAtIndex: i] setTot: [viewerPix[0] count]];
						}
						if( [viewerPix[0] count] == 0)
							NSRunCriticalAlertPanel( NSLocalizedString(@"Files not available (readable)", 0L), NSLocalizedString(@"No files available (readable) in this series.", 0L), NSLocalizedString(@"Continue",nil), nil, nil);
						else
							NSRunCriticalAlertPanel( NSLocalizedString(@"Not all files available (readable)", 0L),  [NSString stringWithFormat: NSLocalizedString(@"Not all files are available (readable) in this series.\r%d files are missing.", 0L), [loadList count] - [viewerPix[0] count]], NSLocalizedString(@"Continue",nil), nil, nil);
					}
					//opening images refered to in viewerPix[0] in the adequate viewer
					
					if( [viewerPix[0] count] > 0)
					{
						if( movieViewer == NO)
						{
							if( multiFrame == YES)
							{
								NSMutableArray  *filesAr = [[NSMutableArray alloc] initWithCapacity: [viewerPix[0] count]];
								
								for( i = 0; i < [viewerPix[0] count]; i++) [filesAr addObject:[correspondingObjects objectAtIndex:0]];
								
								if( viewer)
								{
									//reuse of existing viewer
									[viewer changeImageData:viewerPix[0] :filesAr :volumeData :YES];
									[viewer startLoadImageThread];
								}
								else
								{
									//creation of new viewer
									ViewerController * viewerController;
									viewerController = [[ViewerController alloc] viewCinit:viewerPix[0] :filesAr :volumeData];
									[viewerController showWindowTransition];
									[viewerController startLoadImageThread];
								}		
								
								[filesAr release];
							}
							else
							{
								//multiframe == NO
								if( viewer)
								{
									//reuse of existing viewer
									[viewer changeImageData:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData :YES];
									[viewer startLoadImageThread];
								}
								else
								{
									//creation of new viewer
									ViewerController * viewerController;
									viewerController = [[ViewerController alloc] viewCinit:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData];
									[viewerController showWindowTransition];
									[viewerController startLoadImageThread];
								}
							}
						}
						else
						{
							//movieViewer==YES
							if( movieController == 0L)
							{
								movieController = [[ViewerController alloc] viewCinit:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData];
							}
							else
							{
								[movieController addMovieSerie:viewerPix[0] :[NSMutableArray arrayWithArray:correspondingObjects] :volumeData];
							}
						}
						[volumeData release];
					}
					
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
		
	NS_HANDLER
		NSLog(@"Exception opening Viewer: %@", [localException description]);
	NS_ENDHANDLER
	
	free( memBlockSize );
	
}

- (IBAction) selectSubSeriesAndOpen:(id) sender
{
	[NSApp stopModalWithCode: 2];
}

- (IBAction) selectAll3DSeries:(id) sender
{
	[NSApp stopModalWithCode: 6];
}

- (IBAction) selectAll4DSeries:(id) sender
{
	if( [subOpenMatrix4D isEnabled] == YES)
		[NSApp stopModalWithCode: 7];
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer
{
	NSManagedObject		*selectedLine = [selectedLines objectAtIndex: 0];
    unsigned long		z;
	
	#if !__LP64__
	int					row, column;
	#else
	long				row, column;
	#endif
	
	NSMutableArray		*selectedFilesList;
	NSArray				*loadList;
    NSArray				*cells;
    long				i, x;
	unsigned long		mem;
	long				numberImages, multiSeries = 1;
	BOOL				movieError = NO, multiFrame = NO;
	
	WaitRendering		*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
	[wait showWindow:self];
	
    cells = [oMatrix selectedCells];
	
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
		
		mem = 0;
		for( i = 0; i < [cells count]; i++)
		{
			NSManagedObject*  curImage = [curList objectAtIndex: [[cells objectAtIndex:i] tag]];
			
			[selectedFilesList addObject: curImage];
		}
		
		[self openViewerFromImages :[NSArray arrayWithObject: selectedFilesList] movie: movieViewer viewer :viewer keyImagesOnly:NO];
		
		[selectedFilesList release];
    }
    else
    {
		BOOL			multipleLines = NO;
		//////////////////////////////////////
		// Open series !!!
		//////////////////////////////////////
		
		//////////////////////////////////////
		// Prepare an array that contains arrays of series
		//////////////////////////////////////
		
		NSMutableArray	*toOpenArray = [NSMutableArray arrayWithCapacity: 0];
		
		if( [cells count] == 1 && [selectedLines count] > 1)	// Just one thumbnail is selected, but multiples lines are selected
		{
			for( x = 0; x < [selectedLines count]; x++)
			{
				NSManagedObject* curFile = [selectedLines objectAtIndex: x];
						
				loadList = 0L;
				
				if( [[curFile valueForKey:@"type"] isEqualToString: @"Study"])
				{
					curFile = [[[curFile valueForKey:@"series"] allObjects] objectAtIndex: 0];
					loadList = [self childrenArray: curFile];
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
			for( x = 0; x < [cells count]; x++)
			{
				NSButtonCell *cell = [cells objectAtIndex:x];
				if( [oMatrix getRow:&row column:&column ofCell:cell] == NO)
				{
					row = 0;
					column = 0;
				}
				
				loadList = 0L;
				
				NSManagedObject*  curFile = [matrixViewArray objectAtIndex: [cell tag]];
				
				if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"]) loadList = [self childrenArray: selectedLine];
				if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"]) loadList = [self childrenArray: curFile];
				
				if( loadList) [toOpenArray addObject: loadList];
			}
		}
				
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
					
					interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
					
					if( interval == 0)	// 4D - 3D
					{
						int pos3Dindex = 1;
						for( x = 1; x < [singleSeries count]; x++)
						{
							interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
							
							if( interval != 0) pos3Dindex = 0;
							
							if( [splittedSeries count] <= pos3Dindex) [splittedSeries addObject: [NSMutableArray array]];
							
							[[splittedSeries objectAtIndex: pos3Dindex] addObject: [singleSeries objectAtIndex: x]];
							
							pos3Dindex++;
						}
					}
					else	// 3D - 4D
					{				
						for( x = 1; x < [singleSeries count]; x++)
						{
							interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
							
							if( (interval < 0 && previousinterval > 0) || (interval > 0 && previousinterval < 0))
							{
								[splittedSeries addObject: [NSMutableArray array]];
								NSLog(@"split at: %d", x);
								
								previousinterval = 0;
							}
							else if( previousinterval)
							{
								if( fabs(interval/previousinterval) > 2.0 || fabs(interval/previousinterval) < 0.5)
								{
									[splittedSeries addObject: [NSMutableArray array]];
									NSLog(@"split at: %d", x);
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
				NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"To see an animated series, you have to select multiple series of the same area at different times: e.g. a cardiac CT", 0L), NSLocalizedString(@"OK",nil), nil, nil);
				movieError = YES;
			}
			else if( [toOpenArray count] >= 200)
			{
				NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"4D Player is limited to a maximum number of 200 series.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
				movieError = YES;
			}
			else
			{
				numberImages = -1;
				
				for( x = 0; x < [toOpenArray count]; x++)
				{
					NSLog( @"%d", [[toOpenArray objectAtIndex: x] count]);
					
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
		else if( [toOpenArray count] == 1)	// Just one thumbnail is selected,
		{
			if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
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
						for( x = 1; x < [singleSeries count]; x++)
						{
							interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
							
							if( interval != 0) pos3Dindex = 0;
							
							if( [splittedSeries count] <= pos3Dindex) [splittedSeries addObject: [NSMutableArray array]];
							
							[[splittedSeries objectAtIndex: pos3Dindex] addObject: [singleSeries objectAtIndex: x]];
							
							pos3Dindex++;
						}
					}
					else	// 3D - 4D
					{
						BOOL	fixedRepetition = YES;
						int		repetition = 0, previousPos = 0;
						float	previousLocation;
						
						previousLocation = [[[singleSeries objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue];
						
						for( x = 1; x < [singleSeries count]; x++)
						{
							if( [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue] - previousLocation == 0)
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
							
							for( x = 1; x < [singleSeries count]; x++)
							{
								if( x % repetition == 0)
								{
									[splittedSeries addObject: [NSMutableArray array]];
									NSLog(@"split at: %d", x);
								}
																
								[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: x]];
							}
						}
						else
						{
							for( x = 1; x < [singleSeries count]; x++)
							{
								interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
								
								if( [[splittedSeries lastObject] count] > 2)
								{
									if( (interval < 0 && previousinterval > 0) || (interval > 0 && previousinterval < 0))
									{
										[splittedSeries addObject: [NSMutableArray array]];
										NSLog(@"split at: %d", x);
										previousinterval = 0;
									}
									else if( previousinterval)
									{
										if( fabs(interval/previousinterval) > 1.2 || fabs(interval/previousinterval) < 0.8)
										{
											[splittedSeries addObject: [NSMutableArray array]];
											NSLog(@"split at: %d", x);
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
					[wait close];
					[wait release];
					wait = 0L;
					
					[subOpenMatrix3D renewRows: 1 columns: [splittedSeries count]];
					[subOpenMatrix3D sizeToCells];
					[subOpenMatrix3D setTarget:self];
					[subOpenMatrix3D setAction: @selector( selectSubSeriesAndOpen:)];
					
					[subOpenMatrix4D renewRows: 1 columns: [[splittedSeries objectAtIndex: 0] count]];
					[subOpenMatrix4D sizeToCells];
					[subOpenMatrix4D setTarget:self];
					[subOpenMatrix4D setAction: @selector( selectSubSeriesAndOpen:)];
					
					[[supOpenButtons cellWithTag: 3] setEnabled: YES];
					
					BOOL	areData4D = YES;
					
					for( i = 0 ; i < [splittedSeries count]; i++)
					{
						if( [[splittedSeries objectAtIndex: 0] count] != [[splittedSeries objectAtIndex:i] count])
						{
							[[supOpenButtons cellWithTag: 3] setEnabled: NO];
							areData4D = NO;
						}
					}
					
					for( i = 0 ; i < [splittedSeries count]; i++)
					{
						NSManagedObject	*oob = [[splittedSeries objectAtIndex:i] objectAtIndex: [[splittedSeries objectAtIndex:i] count] / 2];
						
						DCMPix *dcmPix  = [[DCMPix alloc] myinit:[oob valueForKey:@"completePath"] :0 :1 :0L :0 :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: oob];
						
						if( dcmPix)
						{
							[dcmPix computeWImage:YES :0 :0];
							
							NSImage	 *img = [dcmPix getImage];
							
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
						for( i = 0 ; i < [[splittedSeries objectAtIndex: 0] count]; i++)
						{
							NSManagedObject	*oob = [[splittedSeries objectAtIndex: 0] objectAtIndex: i];
							
							DCMPix *dcmPix  = [[DCMPix alloc] myinit:[oob valueForKey:@"completePath"] :0 :1 :0L :0 :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: oob];
							
							if( dcmPix)
							{
								[dcmPix computeWImage:YES :0 :0];
								
								NSImage	 *img = [dcmPix getImage];
								
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
								
								for( i = 0; i < [splittedSeries count]; i++)
								{
									[array4D addObject: [[splittedSeries objectAtIndex: i] objectAtIndex: [subOpenMatrix4D selectedColumn]]];
								}
								
								toOpenArray = [NSMutableArray arrayWithObject: array4D];
							}
						break;
						
						case 6:
						
							wait = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
							[wait showWindow:self];

							for( i = 0; i < [splittedSeries count]; i++)
							{
								toOpenArray = [NSMutableArray arrayWithObject: [splittedSeries objectAtIndex: i]];
								[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
							}
							toOpenArray = 0L;
						break;
						
						case 7:
							{
							BOOL openAllWindows = YES;
						
							if( [[splittedSeries objectAtIndex: 0] count] > 25)
							{
								openAllWindows = NO;
								
								if( NSRunInformationalAlertPanel( NSLocalizedString(@"Series Opening", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you sure you want to open %d windows? It's a lot of windows for this screen...", nil), [[splittedSeries objectAtIndex: 0] count]], NSLocalizedString(@"Yes", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
									openAllWindows = YES;
							}
							
							if( openAllWindows)
							{
								wait = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
								[wait showWindow:self];
								
								for( i = 0; i < [[splittedSeries objectAtIndex: 0] count]; i++)
								{
									NSMutableArray	*array4D = [NSMutableArray array];
									
									for( x = 0; x < [splittedSeries count]; x++)
									{
										[array4D addObject: [[splittedSeries objectAtIndex: x] objectAtIndex: i]];
									}
									
									toOpenArray = [NSMutableArray arrayWithObject: array4D];
									
									[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
								}
							}
							toOpenArray = 0L;
							}
						break;
					}
				}
			}
		}

		
		if( movieError == NO && toOpenArray != 0L)
			[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
    }
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
	else
		[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
		
	[wait close];
	[wait release];
}



- (void) viewerDICOM:(id) sender
{
	//// key Images if Commmand
	//if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask)  
	//	[self viewerDICOMKeyImages:sender];		
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) 
		[self viewerDICOMMergeSelection:sender];
	else
		[self newViewerDICOM:(id) sender];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void) newViewerDICOM: (id) sender
{
	NSManagedObject		*item = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
	
	if (sender == Nil && [[oMatrix selectedCells] count] == 1 && [[item valueForKey:@"type"] isEqualToString:@"Study"] == YES)
	{
		NSArray *a = [self databaseSelection];
		
		int i;
		for( i = 0; i < [a count]; i++)
		{
			[databaseOutline selectRow: [databaseOutline rowForItem:  [a objectAtIndex: i]] byExtendingSelection: NO];
			[self databaseOpenStudy: [a objectAtIndex: i]];
		}
	}
	else
	{
		if( [self isUsingExternalViewer: [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]]] == NO)
		{
			[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality: Nil description: Nil];	
			[self viewerDICOMInt:NO	dcmFile: [self databaseSelection] viewer:0L];
		}
	}
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void) viewerDICOMMergeSelection:(id) sender{
	long			index;
	NSMutableArray	*images = [NSMutableArray arrayWithCapacity:0];
	
	[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:nil description:nil];
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) [self filesForDatabaseMatrixSelection: images];
	else [self filesForDatabaseOutlineSelection: images];
	
	[self openViewerFromImages :[NSArray arrayWithObject:images] movie: nil viewer :nil keyImagesOnly:NO];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
	else
		[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
}

- (void) viewerDICOMKeyImages:(id) sender
{
	long			index;
	NSMutableArray	*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:nil description:nil];	
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];

	[self openViewerFromImages :[NSArray arrayWithObject:selectedItems] movie: nil viewer :nil keyImagesOnly:YES];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
		[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
	else
		[NSApp sendAction: @selector(checkAllWindowsAreVisible:) to:0L from: self];
}

- (void) MovieViewerDICOM:(id) sender
{
	long					index;
	NSMutableArray			*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality:nil description:nil];

	NSIndexSet				*selectedRowIndexes = [databaseOutline selectedRowIndexes];
	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
       if ([selectedRowIndexes containsIndex:index]) [selectedItems addObject: [databaseOutline itemAtRow:index]];
	}
	
	[self viewerDICOMInt:YES dcmFile: selectedItems viewer:0L];
}

static NSArray*	openSubSeriesArray = 0L;

-(NSArray*) produceNewArray: (NSArray*) toOpenArray
{
	NSArray *newArray = [NSArray array];
		
	int from = subFrom-1, to = subTo, interval = subInterval, x, i;
	
	if( interval < 1) interval = 1;
//	if( [subSeriesInterval state] == NSOnState) interval = [subSeriesSlider intValue];
//	else interval = 1;
	
//	[subSeriesIntervalText setIntValue: [subSeriesSlider intValue]];
	
//	from = [subSeriesFrom intValue]-1;
//	to = [subSeriesTo intValue];
	
	int max = 0;
	for( x = 0; x < [toOpenArray count]; x++)
	{
		NSArray *loadList = [toOpenArray objectAtIndex: x];
		
		if( max < [loadList count]) max = [loadList count];
		
		if( from >= to) from = to-1;
		if( from < 0) from = 0;
		if( to < 0) to = 0;
	}
	
	if( from > max) from = max;
	if( to > max) to = max;
	
//	[subSeriesFrom setIntValue: from+1];
//	[subSeriesTo setIntValue: to];
	
	for( x = 0; x < [toOpenArray count]; x++)
	{
		NSArray *loadList = [toOpenArray objectAtIndex: x];
		
		from = subFrom-1;
		to = subTo;
		
		if( from >= [loadList count]) from = [loadList count];
		if( to >= [loadList count]) to = [loadList count];
		
		NSArray *imagesArray = [NSArray array];
		for( i = from; i < to; i++)
		{
			NSManagedObject	*image = [loadList objectAtIndex: i];
			
			if( i % interval == 0)	imagesArray = [imagesArray arrayByAddingObject: image];
		}
		
		if( [imagesArray count] > 0)
			newArray = [newArray arrayByAddingObject: imagesArray];
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
		
		[memoryMessage setStringValue: [NSString stringWithFormat: @"Enough Memory ! (%d MB needed)",  mem * sizeof(float)]];
	}
	else
	{
		[notEnoughMem setHidden: NO];
		[enoughMem setHidden: YES];
		[subSeriesOKButton setEnabled: NO];
		
		[memoryMessage setStringValue: [NSString stringWithFormat: @"Not Enough Memory ! (%d MB needed)", mem* sizeof(float)]];
	}
}

- (void) setSubInterval:(id) sender
{
	subInterval = [sender intValue];
	
	[self checkMemory: self];
}

- (void) setSubFrom:(id) sender
{
	subFrom = [sender intValue];
	
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
	if( [matrixLoadIconsLock tryLock]) [matrixLoadIconsLock unlock];
	else return;
	
	[animationSlider setIntValue: subFrom-1];
	[self previewSliderAction: animationSlider];
	
	[self checkMemory: self];
}

- (void) setSubTo:(id) sender
{
	subTo = [sender intValue];
	
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
    if( [matrixLoadIconsLock tryLock]) [matrixLoadIconsLock unlock];
	else return;
	
	[animationSlider setIntValue: subTo-1];
	[self previewSliderAction: animationSlider];
	
	[self checkMemory: self];
}

- (NSArray*) openSubSeries: (NSArray*) toOpenArray
{
	openSubSeriesArray = [toOpenArray retain];
	
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subTo"];
	[self setValue:[NSNumber numberWithInt:1] forKey:@"subFrom"];
	[self setValue:[NSNumber numberWithInt:2] forKey:@"subInterval"];
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subMax"];
	
	[NSApp beginSheet: subSeriesWindow
				modalForWindow:	[NSApp mainWindow]					//[self window]
				modalDelegate: nil
				didEndSelector: nil
				contextInfo: nil];
	
	[self checkMemory: self];
	
	int result = [NSApp runModalForWindow: subSeriesWindow];
	
	[NSApp endSheet: subSeriesWindow];
	[subSeriesWindow orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		[openSubSeriesArray release];
		
		return [self produceNewArray: toOpenArray];
	}
	
	[openSubSeriesArray release];
	
	return 0L;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark GUI functions


+ (unsigned int)_currentModifierFlags;
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

- (id)initWithWindow:(NSWindow *)window
{
	[AppController initialize];
	
	if (hasMacOSXTiger() == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", nil), NSLocalizedString(@"This application requires MacOS X 10.4 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		exit(0);
	}
	
	self = [super initWithWindow: window];
	if( self)
	{
		long       i;
		NSString    *str;
		
		if( [BrowserController _currentModifierFlags] & NSShiftKeyMask && [BrowserController _currentModifierFlags] & NSAlternateKeyMask)
		{
			NSLog( @"WARNING ---- Protected Mode Activated");
			[DCMPix setRunOsiriXInProtectedMode: YES];
		}
		
		if( [DCMPix isRunOsiriXInProtectedModeActivated])
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"Protected Mode", nil), NSLocalizedString(@"OsiriX is now running in Protected Mode (shift + option keys at startup): no images are displayed, allowing you to delete crashing or corrupted images/studies.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
		
		newFilesConditionLock = [[NSConditionLock alloc] initWithCondition: 0];
		viewersListToRebuild = [[NSMutableArray alloc] initWithCapacity: 0];
		viewersListToReload = [[NSMutableArray alloc] initWithCapacity: 0];
		
		downloadingOsiriXIcon = [[NSImage imageNamed:@"OsirixDownload.icns"] retain];
		standardOsiriXIcon = [[NSImage imageNamed:@"Osirix.icns"] retain];
		
		notFoundImage = [[NSImage imageNamed:@"FileNotFound.tif"] retain];
//		notFoundDataThumbnail = [[BrowserController produceJPEGThumbnail: notFound] retain];
		
		bonjourReportFilesToCheck = [[NSMutableDictionary dictionary] retain];
		
		pressedKeys = [[NSMutableString stringWithString:@""] retain];
		numFmt = [[NSNumberFormatter alloc] init];
		[numFmt setLocale: [NSLocale currentLocale]];
		[numFmt setFormat:@"0"];
		[numFmt setHasThousandSeparators: YES];
		
		matrixLoadIconsLock = [[NSLock alloc] init];
		checkBonjourUpToDateThreadLock = [[NSLock alloc] init];
		checkIncomingLock = [[NSRecursiveLock alloc] init];
		decompressArrayLock = [[NSLock alloc] init];
		decompressThreadRunning = [[NSLock alloc] init];
		processorsLock = [[NSConditionLock alloc] initWithCondition: 1];
		decompressArray = [[NSMutableArray alloc] initWithCapacity: 0];
		
		DATABASEINDEX	= [[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASEINDEX"];
		
		DatabaseIsEdited = NO;
		
		previousBonjourIndex = -1;
		lastSaved = 0;
		mountedVolume = NO;
		toolbarSearchItem = 0L;
		managedObjectModel = 0L;
		managedObjectContext = 0L;
		
		_filterPredicateDescription = 0L;
		_filterPredicate = 0L;
		_fetchPredicate = 0L;
		
		matrixViewArray = 0L;
		draggedItems = 0L;
		
		previousNoOfFiles = 0;
		previousItem = 0L;
		
		searchType = 7;
		timeIntervalType = 0;
		timeIntervalStart = timeIntervalEnd = 0L;
		
		outlineViewArray = [[NSArray array] retain];
		browserWindow = self;
		
		COLUMN = 4;
		
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		isCurrentDatabaseBonjour = NO;
		currentDatabasePath = 0L;
		currentDatabasePath = [[documentsDirectory() stringByAppendingPathComponent:DATAFILEPATH] retain];
		if( [[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath] == NO)
		{
			// Switch back to default location
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
			
			[currentDatabasePath release];
			currentDatabasePath = [[documentsDirectory() stringByAppendingPathComponent:DATAFILEPATH] retain];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath] == NO)
			{
				NEEDTOREBUILD = YES;
				COMPLETEREBUILD = YES;
			}
		}
		[self loadDatabase: currentDatabasePath];
		[self setFixedDocumentsDirectory];
		[self setNetworkLogs];

		str = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
		
		shouldDie = NO;
		bonjourDownloading = NO;
		
		previewPix = [[NSMutableArray alloc] initWithCapacity:0];
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(previewPerformAnimation:) userInfo:self repeats:YES] retain];
		IncomingTimer = [[NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] target:self selector:@selector(checkIncoming:) userInfo:self repeats:YES] retain];
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:63.33 target:self selector:@selector(refreshDatabase:) userInfo:self repeats:YES] retain];
		bonjourTimer = [[NSTimer scheduledTimerWithTimeInterval:10*60 target:self selector:@selector(checkBonjourUpToDate:) userInfo:self repeats:YES] retain];
		databaseCleanerTimer = [[NSTimer scheduledTimerWithTimeInterval:60*60 + 2.5 target:self selector:@selector(autoCleanDatabaseDate:) userInfo:self repeats:YES] retain];
		deleteQueueTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(emptyDeleteQueue:) userInfo:self repeats:YES] retain];
		autoroutingQueueTimer = [[NSTimer scheduledTimerWithTimeInterval:35 target:self selector:@selector(emptyAutoroutingQueue:) userInfo:self repeats:YES] retain];
		
		bonjourRunLoopTimer = 0L;
		
		loadPreviewIndex = 0;
		matrixDisplayIcons = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(matrixDisplayIcons:) userInfo:self repeats:YES] retain];
		
		[[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(newFilesGUIUpdate:) userInfo:self repeats:YES] retain];
		
		/* notifications from workspace */
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeMount:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(willVolumeUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowHasChanged:) name:NSWindowDidBecomeMainNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentImage:) name:@"DCMNewImageViewResponder" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OsirixAddToDBNotification:) name:@"OsirixAddToDBNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:@"reportModeChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionIsChangingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtstructNotification:) name:@"RTSTRUCTNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AlternateButtonPressed:) name:@"AlternateButtonPressed" object:nil];
	}
	return self;
}

- (void) setDBDate
{
	NSString		*sdf = [[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateFormat"];
	NSDateFormatter	*dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[databaseOutline tableColumnWithIdentifier: @"dateOpened"] dataCell] setFormatter: dateFomat];
	[[[databaseOutline tableColumnWithIdentifier: @"date"] dataCell] setFormatter: dateFomat];
	[[[databaseOutline tableColumnWithIdentifier: @"dateAdded"] dataCell] setFormatter: dateFomat];

	sdf = [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat"];
	dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[databaseOutline tableColumnWithIdentifier: @"dateOfBirth"] dataCell] setFormatter: dateFomat];
	[[[databaseOutline tableColumnWithIdentifier: @"reportURL"] dataCell] setFormatter: dateFomat];
}

-(void) awakeFromNib
{
	WaitRendering		*wait = 0L;
	
	if( sizeof( long) == 8)
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting 64-bit version", nil)];
	}
	else
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting 32-bit version", nil)];
	}

	if( autoroutingQueueArray == 0L) autoroutingQueueArray = [[NSMutableArray array] retain];
	if( autoroutingQueue == 0L) autoroutingQueue = [[NSLock alloc] init];
	if( autoroutingInProgress == 0L) autoroutingInProgress = [[NSLock alloc] init];
	
	[wait showWindow:self];
	
	@try
	{
	long i;
	
	NSTableColumn		*tableColumn = nil;
	NSPopUpButtonCell	*buttonCell = nil;
	
	[albumDrawer setPreferredEdge: NSMinXEdge];
	[albumDrawer openOnEdge: NSMinXEdge]; 
	
	// thumbnails : no background color
	[thumbnailsScrollView setDrawsBackground:NO];
	[[thumbnailsScrollView contentView] setDrawsBackground:NO];

	if (hasMacOSXTiger() == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", nil), NSLocalizedString(@"This application requires MacOS X 10.4 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		exit(0);
	}
	
//	[self splitViewDidResizeSubviews:nil];
	[[self window] setFrameAutosaveName:@"DBWindow"];
	
	[bonjourServicesList setDelegate: self];
	[albumDrawer setDelegate:self];
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
	
	[databaseOutline setDoubleAction:@selector(databaseDoublePressed:)];
	[databaseOutline registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[databaseOutline setAllowsMultipleSelection:YES];
	[databaseOutline setAutosaveName: 0L];
	[databaseOutline setAutosaveTableColumns: NO];
				
	[self setupToolbar];
	
	
	[toolbar setVisible:YES];
	[self showDatabase: self];
	
	// SCAN FOR AN IPOD!
	[self loadDICOMFromiPod];
	
	// NSMenu for DatabaseOutline
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Tools"];
	NSMenuItem *exportItem, *sendItem, *burnItem, *anonymizeItem, *keyImageItem;
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Display only this patient", 0L) action: @selector(searchForCurrentPatient:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images", 0L) action: @selector(viewerDICOM:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images in 4D", 0L) action: @selector(MovieViewerDICOM:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	//keyImages
	keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Key Images", nil) action: @selector(viewerDICOMKeyImages:) keyEquivalent:@""];
	[keyImageItem setTarget:self];
	[menu addItem:keyImageItem];
	[keyImageItem release];
	//merged Series
	keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Merged Selection", nil) action: @selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
	[keyImageItem setTarget:self];
	[menu addItem:keyImageItem];
	[keyImageItem release];
	
	keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal In Finder", nil) action: @selector(revealInFinder:) keyEquivalent:@""];
	[keyImageItem setTarget:self];
	[menu addItem:keyImageItem];
	[keyImageItem release];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as DICOM Files", 0L) action: @selector(exportDICOMFile:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as Quicktime Files", 0L) action: @selector(exportQuicktime:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export as JPEG Files", 0L) action: @selector(exportJPEG:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Compress DICOM files in JPEG", nil)  action:@selector(compressSelectedFiles:) keyEquivalent:@""];
	[menu addItem:exportItem];
	[exportItem release];
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Decompress DICOM JPEG files", nil)  action:@selector(decompressSelectedFiles:) keyEquivalent:@""];
	[menu addItem:exportItem];
	[exportItem release];

	[menu addItem: [NSMenuItem separatorItem]];
	
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Report", 0L) action: @selector(generateReport:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action: @selector(delItem:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Query this patient from Q&R window", nil) action: @selector(querySelectedStudy:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Send to DICOM node", nil) action: @selector(export2PACS:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy to iDisk", nil) action: @selector(sendiDisk:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	burnItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Burn", nil) action: @selector(burnDICOM:) keyEquivalent:@""];
	[burnItem setTarget:self];
	[menu addItem:burnItem];
	[burnItem release];
	anonymizeItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Anonymize", nil) action: @selector(anonymizeDICOM:) keyEquivalent:@""];
	[anonymizeItem setTarget:self];
	[menu addItem:anonymizeItem];
	[anonymizeItem release];
	anonymizeItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Rebuild Selected Thumbnails", nil)  action:@selector(rebuildThumbnails:) keyEquivalent:@""];
	[anonymizeItem setTarget:self];
	[menu addItem:anonymizeItem];
	[anonymizeItem release];
	
	[databaseOutline setMenu:menu];
	[menu release];
	
	[self addHelpMenu];
	
	ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
	[cell setEditable:YES];
	[[albumTable tableColumnWithIdentifier:@"Source"] setDataCell:cell];
	[albumTable setDelegate:self];
	[albumTable registerForDraggedTypes:[NSArray arrayWithObject:albumDragType]];
	[albumTable setDoubleAction:@selector(albumTableDoublePressed:)];
	
	[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: 0L]];
	
//	syntaxArray = [[NSArray arrayWithObjects:@"Explicit Little Endian", @"JPEG 2000 Lossless", @"JPEG 2000 Lossy 10:1", @"JPEG 2000 Lossy 20:1", @"JPEG 2000 Lossy 50:1",@"JPEG Lossless", @"JPEG High Quality (9)",  @"JPEG Medium High Quality (8)", @"JPEG Medium Quality (7)", nil] retain];
//	[syntaxList setDataSource:self];
	
	statesArray = [[NSArray arrayWithObjects:NSLocalizedString(@"empty", nil), NSLocalizedString(@"unread", nil), NSLocalizedString(@"reviewed", nil), NSLocalizedString(@"dictated", nil), 0L] retain];
	

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
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"drawerState"])
	{
		if( [[[NSUserDefaults standardUserDefaults] objectForKey: @"drawerState"] intValue] == NSDrawerOpenState)
			[albumDrawer open]; 
		else
			[albumDrawer close];
	}
	
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
	
	[databaseOutline selectRow: 0 byExtendingSelection:NO];
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
	
	[self setServiceName:[[NSUserDefaults standardUserDefaults] objectForKey:@"bonjourServiceName"]];
	
	[bonjourServiceName setStringValue:[bonjourPublisher serviceName]];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"bonjourSharing"])
	{
		[bonjourPublisher toggleSharing:YES];
		[bonjourSharingCheck setState:NSOnState];
	}
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"bonjourPasswordProtected"])
	{
		[bonjourPasswordCheck setState:NSOnState];
	}
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"bonjourPassword"])
	{
		[bonjourPassword setStringValue: [[NSUserDefaults standardUserDefaults] objectForKey:@"bonjourPassword"]];
	}
	
	ImageAndTextCell *cellBonjour = [[[ImageAndTextCell alloc] init] autorelease];
	[cell setEditable:NO];
	[[bonjourServicesList tableColumnWithIdentifier:@"Source"] setDataCell:cell];
	
	[bonjourServicesList registerForDraggedTypes:[NSArray arrayWithObject:albumDragType]];
	
	[bonjourServicesList selectRow: 0 byExtendingSelection:NO];

	[splitViewVert restoreDefault:@"SPLITVERT2"];
	[splitViewHorz restoreDefault:@"SPLITHORZ2"];
	[sourcesSplitView restoreDefault:@"SPLITSOURCE"];
	
	//remove LogView. Code no longer needed. LP
	//NSRect	frame = [[[logViewSplit subviews] objectAtIndex: 1] frame];
	//frame.size.height = 0;
	//[[[logViewSplit subviews] objectAtIndex: 1] setFrame: frame];
	//[logViewSplit adjustSubviews];
	
	[self autoCleanDatabaseDate: self];
	
	[self splitViewDidResizeSubviews: 0L];
	
	
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
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"AwakeFromNib exception: %@", [ne description]);
		NSString            *path = [documentsDirectory() stringByAppendingPathComponent:@"/Loading"];
		[path writeToFile:path atomically:NO];
	}
	
	[wait close];
	[wait release];
	
	[self testAutorouting];
	
	[self setDBWindowTitle];
}

- (IBAction)customize:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (IBAction)showhide:(id)sender {
    [toolbar setVisible:![toolbar isVisible]];
}

- (void) waitForRunningProcesses
{
	[bonjourBrowser waitTheLock];

	[checkIncomingLock lock];
	[checkIncomingLock unlock];
	
	[checkBonjourUpToDateThreadLock lock];
	[checkBonjourUpToDateThreadLock unlock];
	
	while( [SendController sendControllerObjects] > 0)
	{
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.04]];
	}
	
	[decompressThreadRunning lock];
	[decompressThreadRunning unlock];
	
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[self emptyDeleteQueueThread];
	
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[autoroutingInProgress lock];
	[autoroutingInProgress unlock];
	
	[self emptyAutoroutingQueue:self];
	
	[autoroutingInProgress lock];
	[autoroutingInProgress unlock];

	[self syncReportsIfNecessary: previousBonjourIndex];
	
	[checkIncomingLock lock];
	[checkIncomingLock unlock];
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog( @"windowWillClose");

	[self waitForRunningProcesses];

	newFilesInIncoming = NO;
	[self setDockIcon];
	
	[sourcesSplitView saveDefault:@"SPLITSOURCE"];
    [splitViewVert saveDefault:@"SPLITVERT2"];
    [splitViewHorz saveDefault:@"SPLITHORZ2"];
	
	if( [[databaseOutline sortDescriptors] count] >= 1)
	{
		NSDictionary	*sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[databaseOutline sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[databaseOutline sortDescriptors] objectAtIndex: 0] key], @"key", 0L];
		[[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"databaseSortDescriptor"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:[databaseOutline columnState] forKey: @"databaseColumns2"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt: [albumDrawer state]] forKey: @"drawerState"];
	
    [[self window] setDelegate:nil];
    [self saveDatabase: currentDatabasePath];

	[[NSUserDefaults standardUserDefaults] setBool: [animationCheck state] forKey: @"AutoPlayAnimation"];
	
	// bonjour defaults
	[[NSUserDefaults standardUserDefaults] setBool: [bonjourSharingCheck state] forKey: @"bonjourSharing"];
	[[NSUserDefaults standardUserDefaults] setObject:[bonjourServiceName stringValue] forKey: @"bonjourServiceName"];

	[[NSUserDefaults standardUserDefaults] setBool: [bonjourPasswordCheck state] forKey: @"bonjourPasswordProtected"];
	[[NSUserDefaults standardUserDefaults] setObject:[bonjourPassword stringValue] forKey: @"bonjourPassword"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[bonjourPublisher toggleSharing:NO];
	
	[self removeAllMounted];
	
    [self release];
}

- (BOOL) shouldTerminate: (id) sender
{
	if( newFilesInIncoming)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Listener - STORE", nil), NSLocalizedString(@"New files are arriving in the DICOM Database. Are you sure you want to quit now? The DICOM Listener will be stopped.", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Quit", nil), 0L) == NSAlertDefaultReturn) return NO;
	}
	
	if( [SendController sendControllerObjects] > 0)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Sending - STORE", nil), NSLocalizedString(@"Files are currently being sent to a DICOM node. Are you sure you want to quit now? The sending will be stopped.", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Quit", nil), 0L) == NSAlertDefaultReturn) return NO;
	}
	
	return YES;
}

- (void) showDatabase:(id)sender
{
    [[self window] makeKeyAndOrderFront:sender];
	[self outlineViewRefresh];
}

- (void)keyDown:(NSEvent *)event{
    unichar c = [[event characters] characterAtIndex:0];
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter) {
        [self delItem:nil];
    }else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter){
        [self viewerDICOM:nil];
    }
	else if(c == ' ')
	{
		[animationCheck setState: ![animationCheck state]];
	}
    else
    {
		[pressedKeys appendString: [event characters]];
		
		NSArray		*result = [outlineViewArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name LIKE[cd] %@", [NSString stringWithFormat:@"%@*", pressedKeys]]];
		
		[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
		
		if( [result count])
		{
			[databaseOutline selectRow: [databaseOutline rowForItem: [result objectAtIndex: 0]] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		}
    }
}

-(void) updateCurrentImage:(NSNotification *)note{
	int i;
	for (i = 0; i< [imageTileMenu numberOfItems]; i++) [[imageTileMenu itemAtIndex:i] setState:NSOffState];
	
	int rows = [[note object] rows];
	int columns = [[note object] columns];
	int tag =  ((rows - 1) * 4) + (columns - 1);
	
	[[imageTileMenu itemWithTag:tag] setState:NSOnState];
}

- (void)mainWindowHasChanged:(NSNotification *)note{
	[mainWindow release];
	mainWindow = [[note object] retain];
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem
{
	if ([menuItem menu] == imageTileMenu ) {
		if ([[mainWindow windowController] isKindOfClass:[ViewerController class]])
			return YES;
		else
			return NO;
	}
	return YES;
}

- (BOOL) is2DViewer
{
	return NO;
}

- (IBAction)customizeViewerToolBar:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (void)addHelpMenu
{
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *helpItem = [mainMenu addItemWithTitle:NSLocalizedString(@"Help", nil) action:nil keyEquivalent:@""];
	NSMenu *helpMenu = [[NSMenu allocWithZone: [NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Help", nil)];
	[helpItem setSubmenu:helpMenu];
	[helpMenu addItemWithTitle: NSLocalizedString(@"Email Project Lead", nil) action: @selector(sendEmail:) keyEquivalent: @""];
	[helpMenu addItemWithTitle: NSLocalizedString(@"Go to Home Page", nil) action: @selector(openOsirixWebPage:) keyEquivalent: @""];	
	[helpMenu addItemWithTitle: NSLocalizedString(@"OsiriX Discussion Group", nil) action: @selector(openOsirixDiscussion:) keyEquivalent: @""];
	[helpMenu addItem: [NSMenuItem separatorItem]];
	[helpMenu addItemWithTitle: NSLocalizedString(@"User Manual", nil) action: @selector(help:) keyEquivalent: @""];
	[helpMenu addItemWithTitle: NSLocalizedString(@"Online Documentation", nil) action: @selector(openOsirixWikiWebPage:) keyEquivalent: @""];
	[helpMenu release];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark DICOM Network & Files functions

- (void) resetListenerTimer
{
	[IncomingTimer invalidate];
	[IncomingTimer release];
	
	NSLog( @"Listener check: %d", [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"]);
	
	IncomingTimer = [[NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] target:self selector:@selector(checkIncoming:) userInfo:self repeats:YES] retain];
}

- (void) emptyDeleteQueueThread
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
	int i;
	
	[deleteInProgress lock];
	[deleteQueue lock];
	NSArray	*copyArray = [NSArray arrayWithArray: deleteQueueArray];
	[deleteQueueArray removeAllObjects];
	[deleteQueue unlock];
	
	if( [copyArray count])
	{
		[appController growlTitle: NSLocalizedString( @"Files removing", 0L) description: [NSString stringWithFormat: NSLocalizedString( @"%d files to delete", 0L), [copyArray count]]  name:@"delete"];
	
		NSLog(@"delete Queue start: %d objects", [copyArray count]);
		for( i = 0; i < [copyArray count]; i++)
			unlink( [[copyArray objectAtIndex: i] UTF8String]);		// <- this is faster
//			[[NSFileManager defaultManager] removeFileAtPath:[copyArray objectAtIndex: i] handler:nil];
		NSLog(@"delete Queue end");

		[appController growlTitle: NSLocalizedString( @"Files removing", 0L) description: NSLocalizedString( @"Finished", 0L) name:@"delete"];
	}
	
	[deleteInProgress unlock];
	[pool release];
}

- (void) emptyDeleteQueue:(id) sender
{
	if( deleteQueueArray != 0L && deleteQueue != 0L)
	{
		if( [deleteQueueArray count] > 0)
		{
			if( [deleteInProgress tryLock])
			{
				[deleteInProgress unlock];
				[NSThread detachNewThreadSelector:@selector(emptyDeleteQueueThread) toTarget:self withObject:0L];
			}
		}
	}
}

- (void) addFileToDeleteQueue:(NSString*) file
{
	if( deleteQueueArray == 0L) deleteQueueArray = [[NSMutableArray array] retain];
	if( deleteQueue == 0L) deleteQueue = [[NSLock alloc] init];
	if( deleteInProgress == 0L) deleteInProgress = [[NSLock alloc] init];

	[deleteQueue lock];
	[deleteQueueArray addObject: file];
	[deleteQueue unlock];
}

- (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory found:(BOOL) found
{
	NSArray *fileNames = nil;
	NSString *filePath = nil;
	BOOL isDirectory = FALSE;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	int i = 0;
	fileNames = [[NSFileManager defaultManager] directoryContentsAtPath: startDirectory];
	for(i = 0; i < [fileNames count] && !found; i++)
	{
		filePath = [startDirectory stringByAppendingPathComponent: [fileNames objectAtIndex: i]];
		NSString *upperString = [[fileNames objectAtIndex: i] uppercaseString];
		if([upperString isEqualToString: @"DICOMDIR"] || [upperString isEqualToString: @"DICOMDIR."])
		{
			return filePath;
		}
		else if(/*![[NSWorkspace sharedWorkspace] isFilePackageAtPath: [fileNames objectAtIndex: i]] || */
				 [[fileNames objectAtIndex: i] characterAtIndex: 0] != '.')
		{
			isDirectory = FALSE;
			if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory])
			{
				if(isDirectory)
				{
					if((filePath = [self _findFirstDicomdirOnCDMedia: filePath found:found]) != nil)
						return filePath;
				}
			}
		}
	}
	
	return nil;
}

-(void) ReadDicomCDRom:(id) sender
{
	#if !__LP64__
    kern_return_t		kernResult; 
    OSErr				result = noErr;
    ItemCount			volumeIndex;
	BOOL				found = NO;
	
    kernResult = IOMasterPort(MACH_PORT_NULL, &gMasterPort);
    if (KERN_SUCCESS != kernResult)
        printf("IOMasterPort returned %d\n", kernResult);

    // Iterate across all mounted volumes using FSGetVolumeInfo. This will return nsvErr
    // (no such volume) when volumeIndex becomes greater than the number of mounted volumes.
    for (volumeIndex = 1; result == noErr || result != nsvErr; volumeIndex++)
    {
        FSVolumeRefNum	actualVolume;
        HFSUniStr255	volumeName;
        FSVolumeInfo	volumeInfo;
        
        bzero((void *) &volumeInfo, sizeof(volumeInfo));
        
        // We're mostly interested in the volume reference number (actualVolume)
        result = FSGetVolumeInfo(kFSInvalidVolumeRefNum,
                                 volumeIndex,
                                 &actualVolume,
                                 kFSVolInfoFSInfo,
                                 &volumeInfo,
                                 &volumeName,
                                 NULL); 
        
        if (result == noErr)
        {
            GetVolParmsInfoBuffer volumeParms;
            HParamBlockRec pb;
            
            // Use the volume reference number to retrieve the volume parameters. See the documentation
            // on PBHGetVolParmsSync for other possible ways to specify a volume.
            pb.ioParam.ioNamePtr = NULL;
            pb.ioParam.ioVRefNum = actualVolume;
            pb.ioParam.ioBuffer = (Ptr) &volumeParms;
            pb.ioParam.ioReqCount = sizeof(volumeParms);
            
            // A version 4 GetVolParmsInfoBuffer contains the BSD node name in the vMDeviceID field.
            // It is actually a char * value. This is mentioned in the header CoreServices/CarbonCore/Files.h.
            result = PBHGetVolParmsSync(&pb);
            
            if (result != noErr)
            {
                printf("PBHGetVolParmsSync returned %d\n", result);
            }
            else {
                // This code is just to convert the volume name from a HFSUniCharStr to
                // a plain C string so we can print it with printf. It'd be preferable to
                // use CoreFoundation to work with the volume name in its Unicode form.
                CFStringRef	volNameAsCFString;
                char		volNameAsCString[256];
                
                volNameAsCFString = CFStringCreateWithCharacters(kCFAllocatorDefault,
                                                                 volumeName.unicode,
                                                                 volumeName.length);
                                                                 
                // If the conversion to a C string fails, just treat it as a null string.
                if (!CFStringGetCString(volNameAsCFString,
                                        volNameAsCString,
                                        sizeof(volNameAsCString),
                                        kCFStringEncodingUTF8))
                {
                    volNameAsCString[0] = 0;
                }
                
                // The last parameter of this printf call is the BSD node name from the
                // GetVolParmsInfoBuffer struct.
                printf("Volume \"%s\" (vRefNum %d), BSD node /dev/%s, ", volNameAsCString, actualVolume, (char *) volumeParms.vMDeviceID);
				
                // Use the BSD node name to call I/O Kit and get additional information about the volume
                if( GetAdditionalVolumeInfo((char *) volumeParms.vMDeviceID) == YES)
				{
					// ADD ALL FILES OF THIS VOLUME TO THE DATABASE!
					NSMutableArray  *filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
					
					found = YES;
					
					if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USEDICOMDIR"])
					{
						NSString    *aPath = [NSString stringWithFormat:@"/Volumes/%s",volNameAsCString];
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == 0L)
						{
							aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
							enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						}
						
						// DICOMDIR should be located at the root level
						// DICOMDIR should be located at the root level
						// masu 07.10.2005 a Dicomdir is not necessarily in the root.
						// so search for the firstdicomdir file on disk
						// !!! on MAC OS X the pathes are casesensitive and in a dicomdir the pathes
						// are stored in uppercase
						aPath = [self _findFirstDicomdirOnCDMedia: aPath found: FALSE];
						
						if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
						{
							int	i;
							int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"STILLMOVIEMODE"];
							
							@try
							{
								[self addDICOMDIR: aPath :filesArray];
							}
							
							@catch (NSException * e)
							{
								NSLog( [e description]);
							}
							
							
							switch ( mode)
							{
								case 0: // ALL FILES
								
								break;
								
								case 1: //EXCEPT STILL
									for( i = 0; i < [filesArray count]; i++)
									{
										if( [[[filesArray objectAtIndex:i] lastPathComponent] isEqualToString:@"STILL"] == YES)
										{
											[filesArray removeObjectAtIndex:i];
											i--;
										}
									}
								break;
								
								case 2: //EXCEPT MOVIE
									for( i = 0; i < [filesArray count]; i++)
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
						else NSRunCriticalAlertPanel(NSLocalizedString(@"DICOMDIR",nil), NSLocalizedString(@"No DICOMDIR file has been found on this CD/DVD. Unable to load images.",nil),NSLocalizedString( @"OK",nil), nil, nil);
					}
					else
					{
						NSString    *pathname;
						NSString    *aPath = [NSString stringWithFormat:@"/Volumes/%s",volNameAsCString];
						NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
						
						if( enumer == 0L)
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
								
								if( [[itemPath lastPathComponent] isEqualToString:@"DICOMDIR"] == YES)
								{
									addFile = NO;
								}
								
								if( addFile) [filesArray addObject:itemPath];
							}
						}
						
					}
					
					[self autoCleanDatabaseFreeSpace: self];
					
					NSMutableArray	*newfilesArray = [self copyFilesIntoDatabaseIfNeeded:filesArray async: YES];
					
					if( newfilesArray == filesArray)
					{
						mountedVolume = YES;
						NSArray	*newImages = [self addFilesToDatabase:filesArray :YES];
						mountedVolume = NO;
					
						[self outlineViewRefresh];
					
						if( [newImages count] > 0)
						{
							NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
						
							[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
							[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
						}
					}
					
					[self autoCleanDatabaseFreeSpace: self];
				}
            }
        }
    }
	
	if( found == NO)
	{
		if( [[DRDevice devices] count])
		{
			DRDevice	*device = [[DRDevice devices] objectAtIndex: 0];
			
			// Is the bay close? open it for the user
			if( [[[device status] valueForKey: DRDeviceIsTrayOpenKey] boolValue] == YES)
			{
				[device closeTray];
				[appController growlTitle: NSLocalizedString( @"CD/DVD", 0L) description: NSLocalizedString(@"Please wait. CD/DVD is loading...", 0L) name:@"newfiles"];
				return;
			}
			else
			{
				if( [[[device status] valueForKey: DRDeviceIsBusyKey] boolValue] == NO &&[[[device status] valueForKey: DRDeviceMediaStateKey] isEqualToString:DRDeviceMediaStateNone])
					[device openTray];
				else
				{
					[appController growlTitle: NSLocalizedString( @"CD/DVD", 0L) description: NSLocalizedString(@"Please wait. CD/DVD is loading...", 0L) name:@"newfiles"];
					return;
				}
			}
		}
		
		NSRunCriticalAlertPanel(NSLocalizedString(@"No CD or DVD has been found...",@"No CD or DVD has been found..."),NSLocalizedString(@"Please insert a DICOM CD or DVD.",@"Please insert a DICOM CD or DVD."), NSLocalizedString(@"OK",nil), nil, nil);
	}
	#endif
}

+(BOOL) isItCD:(NSArray*) pathFilesComponent
{
	#if !__LP64__
	if( [pathFilesComponent count] > 2 && [[[pathFilesComponent objectAtIndex: 1] uppercaseString] isEqualToString:@"VOLUMES"])
	{
		kern_return_t		kernResult; 
		OSErr				result = noErr;
		ItemCount			volumeIndex;
		BOOL				found = NO;
		
		kernResult = IOMasterPort(MACH_PORT_NULL, &gMasterPort);
		if (KERN_SUCCESS != kernResult)
			printf("IOMasterPort returned %d\n", kernResult);
		
		// Iterate across all mounted volumes using FSGetVolumeInfo. This will return nsvErr
		// (no such volume) when volumeIndex becomes greater than the number of mounted volumes.
		for (volumeIndex = 1; result == noErr || result != nsvErr; volumeIndex++)
		{
			FSVolumeRefNum	actualVolume;
			HFSUniStr255	volumeName;
			FSVolumeInfo	volumeInfo;
			
			bzero((void *) &volumeInfo, sizeof(volumeInfo));
			
			// We're mostly interested in the volume reference number (actualVolume)
			result = FSGetVolumeInfo(kFSInvalidVolumeRefNum,
									 volumeIndex,
									 &actualVolume,
									 kFSVolInfoFSInfo,
									 &volumeInfo,
									 &volumeName,
									 NULL); 
			
			if (result == noErr)
			{
				GetVolParmsInfoBuffer volumeParms;
				HParamBlockRec pb;
				
				// Use the volume reference number to retrieve the volume parameters. See the documentation
				// on PBHGetVolParmsSync for other possible ways to specify a volume.
				pb.ioParam.ioNamePtr = NULL;
				pb.ioParam.ioVRefNum = actualVolume;
				pb.ioParam.ioBuffer = (Ptr) &volumeParms;
				pb.ioParam.ioReqCount = sizeof(volumeParms);
				
				// A version 4 GetVolParmsInfoBuffer contains the BSD node name in the vMDeviceID field.
				// It is actually a char * value. This is mentioned in the header CoreServices/CarbonCore/Files.h.
				result = PBHGetVolParmsSync(&pb);
				
				if (result != noErr)
				{
					printf("PBHGetVolParmsSync returned %d\n", result);
				}
				else {
					// This code is just to convert the volume name from a HFSUniCharStr to
					// a plain C string so we can print it with printf. It'd be preferable to
					// use CoreFoundation to work with the volume name in its Unicode form.
					CFStringRef	volNameAsCFString;
					char		volNameAsCString[256];
					
					volNameAsCFString = CFStringCreateWithCharacters(kCFAllocatorDefault,
																	 volumeName.unicode,
																	 volumeName.length);
																	 
					// If the conversion to a C string fails, just treat it as a null string.
					if (!CFStringGetCString(volNameAsCFString,
											volNameAsCString,
											sizeof(volNameAsCString),
											kCFStringEncodingUTF8))
					{
						volNameAsCString[0] = 0;
					}
					
					// The last parameter of this printf call is the BSD node name from the
					// GetVolParmsInfoBuffer struct.
					printf("Volume \"%s\" (vRefNum %d), BSD node /dev/%s, ", volNameAsCString, actualVolume, (char *) volumeParms.vMDeviceID);
					
					// Use the BSD node name to call I/O Kit and get additional information about the volume
					if( GetAdditionalVolumeInfo((char *) volumeParms.vMDeviceID) == YES)
					{
						NSLog([pathFilesComponent objectAtIndex:2]);
						if( strcmp( volNameAsCString, [[pathFilesComponent objectAtIndex:2] cString]) == 0)
						{
							return YES;
						}
						
						if( strcmp( volNameAsCString, "ISO_9660_CD") == 0)
						{
							return YES;
						}
					}
				}
			}
		}
	}
	
	#endif
	return NO;
}

- (void) listenerAnonymizeFiles: (NSArray*) files
{
	long				i;
	NSArray				*array = [NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"******", nil];
	NSMutableArray		*tags = [NSMutableArray array];
	
	[tags addObject:array];

	for( i = 0; i < [files count]; i ++)
	{
		NSString			*destPath = [[files objectAtIndex:i] stringByAppendingString:@"temp"];
		
		[DCMObject anonymizeContentsOfFile:[files objectAtIndex:i]  tags:tags  writingToFile:destPath];
		[[NSFileManager defaultManager] removeFileAtPath:[files objectAtIndex:i] handler:nil];
		[[NSFileManager defaultManager] movePath:destPath toPath:[files objectAtIndex:i] handler:nil];
	}
}

- (NSString*) pathResolved:(NSString*) inPath
{
	CFStringRef resolvedPath = nil;
	CFURLRef	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef)) {
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased) {
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL /*allocator*/, &fsRef);
				if (resolvedurl != NULL) {
					resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedurl);
				}
			}
		}
		CFRelease(url);
	}
	return (NSString *)resolvedPath;
}

- (BOOL) isAliasPath:(NSString *)inPath
{
	return [self pathResolved:inPath] != nil;
}

- (NSString*) resolveAliasPath:(NSString*) inPath
{
	NSString *resolved = [self pathResolved:inPath];
	return (nil != resolved) ? resolved : inPath;
}

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path{
	NSString *folder = path;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		if (![self isAliasPath:path])
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		//we have an alias
		else { 
			//NSLog(@"INCOMING alias");
			folder = [self pathResolved: path];
		}
	}
		/* 
		if it exists see if it is a file or symbolic link
		if it is a file, create a folder else leave it
		*/
	else{	
		NSDictionary *attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
		if (![[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) 
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];				
		attrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO];
		//get absolute path if link
		if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink]) 
			folder= [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath:path];
	}
	return folder;
}

- (IBAction) revealInFinder:(id) sender
{
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
		
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	{
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
	}
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
	if( [filesToExport count])
	{
		[[NSWorkspace sharedWorkspace] selectFile:[filesToExport objectAtIndex: 0] inFileViewerRootedAtPath:0L];
	}
}

static volatile int numberOfThreadsForJPEG = 0;

- (BOOL) waitForAProcessor
{
	int processors =  MPProcessors();
	
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

-(void) decompressDICOMJPEGinINCOMING:(NSString*) compressedPath
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	NSString			*INpath = [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH];
	
	[self decompressDICOM:compressedPath to: [INpath stringByAppendingPathComponent:[compressedPath lastPathComponent]]];
		
	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

-(void) decompressDICOMJPEG:(NSString*) compressedPath
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];

	[self decompressDICOM:compressedPath to: 0L];
	
	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

-(void) compressDICOMJPEG:(NSString*) compressedPath
{
	NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	
	[self compressDICOMWithJPEG:compressedPath];

	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

- (void) decompressArrayOfFiles: (NSArray*) array work:(NSNumber*) work
{
	[decompressThreadRunning lock];
	[decompressArrayLock lock];
	[decompressArray addObjectsFromArray: array];
	[decompressArrayLock unlock];
	[decompressThreadRunning unlock];
	
	[self decompressThread: work];
}

- (IBAction) compressSelectedFiles:(id) sender
{
	if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO)
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
			
		if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
		{
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
		
		int i;
		NSMutableArray *result = [NSMutableArray array];
		
		for( i = 0 ; i < [filesToExport count] ; i++)
		{
			if( [[[dicomFiles2Export objectAtIndex:i] valueForKey:@"fileType"] hasPrefix:@"DICOM"])
				[result addObject: [filesToExport objectAtIndex: i]];
		}
		
		[decompressThreadRunning lock];
		
		[decompressArrayLock lock];
		[decompressArray addObjectsFromArray: result];
		[decompressArrayLock unlock];
		
		[NSThread detachNewThreadSelector: @selector( decompressThread:) toTarget:self withObject: [NSNumber numberWithChar: 'C']];
		[decompressThreadRunning unlock];
	}
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", 0L), NSLocalizedString(@"Cannot compress images in a distant database.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
}

- (IBAction) decompressSelectedFiles:(id) sender
{
	if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO)
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
			
		if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
		{
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
		
		int i;
		NSMutableArray *result = [NSMutableArray array];
		
		for( i = 0 ; i < [filesToExport count] ; i++)
		{
			if( [[[dicomFiles2Export objectAtIndex:i] valueForKey:@"fileType"] hasPrefix:@"DICOM"])
				[result addObject: [filesToExport objectAtIndex: i]];
		}
		
		[decompressThreadRunning lock];
		[decompressArrayLock lock];
		[decompressArray addObjectsFromArray: result];
		[decompressArrayLock unlock];
		
		[NSThread detachNewThreadSelector: @selector( decompressThread:) toTarget:self withObject: [NSNumber numberWithChar: 'D']];
		[decompressThreadRunning unlock];
	}
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", 0L), NSLocalizedString(@"Cannot decompress images in a distant database.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
}

- (void) decompressThread: (NSNumber*) typeOfWork
{	
	[decompressThreadRunning lock];
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSArray				*array;
	int					i;
	char				tow = [typeOfWork charValue];
	BOOL				finished;
	
	finished = NO;
	do
	{
		[processorsLock lockWhenCondition: 1];
		if( numberOfThreadsForJPEG <= 0)
		{
			finished = YES;
			[processorsLock unlockWithCondition: 1];
		}
		else [processorsLock unlockWithCondition: 0];
	}
	while( finished == NO);

	[decompressArrayLock lock];
	array = [NSArray arrayWithArray: decompressArray];
	[decompressArray removeAllObjects];
	[decompressArrayLock unlock];
	
	numberOfThreadsForJPEG = 0;
	
	switch( tow)
	{
		case 'C':
			[appController growlTitle: NSLocalizedString( @"Files Compression", 0L) description:[NSString stringWithFormat: NSLocalizedString(@"Starting to compress %d files", 0L), [array count]] name:@"newfiles"];
		break;
		
		case 'D':
			[appController growlTitle: NSLocalizedString( @"Files Decompression", 0L) description:[NSString stringWithFormat: NSLocalizedString(@"Starting to decompress %d files", 0L), [array count]] name:@"newfiles"];
		break;
	}
	
	for( i = 0; i < [array count]; i++)
	{
		[self waitForAProcessor];
		
		switch( tow)
		{
			case 'C':
				[NSThread detachNewThreadSelector: @selector( compressDICOMJPEG:) toTarget:self withObject: [array objectAtIndex: i]];
			break;
			
			case 'D':
				[NSThread detachNewThreadSelector: @selector( decompressDICOMJPEG:) toTarget:self withObject: [array objectAtIndex: i]];
			break;
			
			case 'I':
				[NSThread detachNewThreadSelector: @selector( decompressDICOMJPEGinINCOMING:) toTarget:self withObject: [array objectAtIndex: i]];
			break;
		}
	}
	
	finished = NO;
	do
	{
		[processorsLock lockWhenCondition: 1];
		if( numberOfThreadsForJPEG <= 0)
		{
			finished = YES;
			[processorsLock unlockWithCondition: 1];
		}
		else [processorsLock unlockWithCondition: 0];
	}
	while( finished == NO);
	
	switch( tow)
	{
		case 'C':
			[appController growlTitle: NSLocalizedString( @"Files Compression", 0L) description: NSLocalizedString(@"Done !", 0L) name:@"newfiles"];
		break;
		
		case 'D':
			[appController growlTitle: NSLocalizedString( @"Files Decompression", 0L) description: NSLocalizedString(@"Done !", 0L) name:@"newfiles"];
		break;
	}
	
	[pool release];
	
	[decompressThreadRunning unlock];
}

-(void) checkIncomingThread:(id) sender
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	[checkIncomingLock lock];
	
	@try
	{
		NSString        *INpath = [documentsDirectory() stringByAppendingPathComponent:INCOMINGPATH];
		NSString		*ERRpath = [documentsDirectory() stringByAppendingPathComponent:ERRPATH];
		NSString        *OUTpath = [documentsDirectory() stringByAppendingPathComponent:DATABASEPATH];
		NSString        *DECOMPRESSIONpath = [documentsDirectory() stringByAppendingPathComponent:DECOMPRESSIONPATH];
		BOOL			isDir = YES;
		BOOL			DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"];
		BOOL			DECOMPRESSDICOMLISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DECOMPRESSDICOMLISTENER"];
		BOOL			COMPRESSDICOMLISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMPRESSDICOMLISTENER"];
		long			i;
		
		//NSLog(@"Scan folder START");
		
		if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO)
		{	
			//need to resolve aliases and symbolic links
			INpath = [self folderPathResolvingAliasAndSymLink:INpath];
			OUTpath = [self folderPathResolvingAliasAndSymLink:OUTpath];
			ERRpath = [self folderPathResolvingAliasAndSymLink:ERRpath];
			DECOMPRESSIONpath = [self folderPathResolvingAliasAndSymLink:DECOMPRESSIONpath];
			
			NSString        *pathname;
			NSMutableArray  *filesArray = [[NSMutableArray alloc] initWithCapacity:0];
			NSMutableArray	*compressedPathArray = [[NSMutableArray alloc] initWithCapacity:0];
			
			NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:INpath];
			
			while (pathname = [enumer nextObject])
			{
				NSString *srcPath = [INpath stringByAppendingPathComponent:pathname];
				NSString *originalPath = srcPath;
				//NSLog(@"Incoming path: %@", srcPath);
				if ([[[srcPath lastPathComponent] uppercaseString] isEqualToString:@".DS_STORE"])
					continue;
				
				BOOL result, isAlias = [self isAliasPath: srcPath];
				if( isAlias) srcPath = [self pathResolved: srcPath];
				
				// Is it a real file? Is it writable (transfer done)?
				if ([[NSFileManager defaultManager] isWritableFileAtPath:srcPath] == YES)
				{
					NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:srcPath traverseLink: YES];
					
					if( [[fattrs objectForKey:NSFileType] isEqualToString: NSFileTypeDirectory] == YES)
					{
						NSArray		*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath: srcPath];
						
						//Is this directory empty?? If yes, delete it!
						//if alias assume nested folders should stay
						if( [dirContent count] == 0 && !isAlias) [[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
						if( [dirContent count] == 1)
						{
							if( [[[dirContent objectAtIndex: 0] uppercaseString] isEqualToString:@".DS_STORE"]) [[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
						}
					}
					else if( fattrs != 0L && [[fattrs objectForKey:NSFileBusy] boolValue] == NO && [[fattrs objectForKey:NSFileSize] longLongValue] > 0)
					{
						BOOL		isDicomFile;
						BOOL		isJPEGCompressed;
						NSString	*dstPath = [OUTpath stringByAppendingPathComponent:[srcPath lastPathComponent]];
						
						isDicomFile = [DicomFile isDICOMFile:srcPath compressed:&isJPEGCompressed];
						
						if( isDicomFile == YES		||
							(([DicomFile isFVTiffFile:srcPath]		||
							[DicomFile isTiffFile:srcPath]			||
							[DicomFile isXMLDescriptedFile:srcPath]	||
							[DicomFile isXMLDescriptorFile:srcPath]) 
							&& [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == NO))
						{
							newFilesInIncoming = YES;
							
							if (isDicomFile)
							{
								if( isJPEGCompressed && DECOMPRESSDICOMLISTENER)
								{
									NSString	*compressedPath = [DECOMPRESSIONpath stringByAppendingPathComponent:[srcPath lastPathComponent]];
									
									[[NSFileManager defaultManager] movePath:srcPath toPath:compressedPath handler:nil];
									
									[compressedPathArray addObject: compressedPath];
									
									continue;
								}
								
								dstPath = [self getNewFileDatabasePath:@"dcm"];
							}
							else dstPath = [self getNewFileDatabasePath: [[srcPath pathExtension] lowercaseString]];
							//else dstPath = [self getNewFileDatabasePath:[[srcPath stringByDeletingPathExtension] lastPathComponent]: [[srcPath pathExtension] lowercaseString]];
							
							if( isAlias)
							{
								result = [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil];
								[[NSFileManager defaultManager] removeFileAtPath:originalPath handler:nil];
							}
							else
							{
								if ([DicomFile isXMLDescriptorFile:srcPath]) // XML comes before ZIP in alphabetic order...
								{
									[[NSFileManager defaultManager] movePath:srcPath toPath:dstPath handler:nil]; // move the XML first
									srcPath = [[srcPath stringByDeletingPathExtension] stringByAppendingString:@".zip"];
									dstPath = [[dstPath stringByDeletingPathExtension] stringByAppendingString:@".zip"];
								}
								
								if([DicomFile isXMLDescriptedFile:srcPath])
								{
									if ([[NSFileManager defaultManager]
											fileExistsAtPath:[[srcPath stringByDeletingPathExtension] stringByAppendingString:@".xml"]])
									{
										// move the XML first
										[[NSFileManager defaultManager]
												movePath	:[[srcPath stringByDeletingPathExtension] stringByAppendingString:@".xml"]
												toPath		:[[dstPath stringByDeletingPathExtension] stringByAppendingString:@".xml"] 
												handler		:nil];
										// the ZIP will be moved next line
									}
								}
								
								result = [[NSFileManager defaultManager] movePath:srcPath toPath:dstPath handler:nil];
							}
							
							if( result == YES)
							{
								[filesArray addObject:dstPath];
							}
						}
						else // DELETE or MOVE THIS UNKNOWN FILE ?
						{
							if ( DELETEFILELISTENER)
							{
								[[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
							}
							else
							{
							//	NSLog( [ERRpath stringByAppendingPathComponent: [srcPath lastPathComponent]]);
								
								if( [[NSFileManager defaultManager] movePath:srcPath toPath:[ERRpath stringByAppendingPathComponent: [srcPath lastPathComponent]]  handler:nil] == NO)
								{
									[[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
								}
							}
						}
					}
				}
			}
			
			if( [filesArray count] > 0)
			{
				newFilesInIncoming = YES;
				
				if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ANONYMIZELISTENER"] == YES)
				{
					[self listenerAnonymizeFiles: filesArray];
				}
				
				for( i = 0; i < [preProcessPlugins count]; i++)
				{
					id				filter = [preProcessPlugins objectAtIndex:i];
					
					[filter processFiles: filesArray];
				}
			
				NSArray*	addedFiles = [[self addFilesToDatabase: filesArray]  valueForKey:@"completePath"];
				
				if( addedFiles)
				{
				}
				else	// Add failed.... Keep these files: move them back to the INCOMING folder and try again later....
				{
					NSString *dstPath;
					long i, x = 0;
					
					NSLog(@"Move the files back to the incoming folder...");
					
					for( i = 0; i < [filesArray count]; i++)
					{
						do
						{
							dstPath = [INpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", x]];
							x++;
						}
						while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
						
						[[NSFileManager defaultManager] movePath:[filesArray objectAtIndex: i] toPath:dstPath handler:nil];
					}
				}
				
				if( COMPRESSDICOMLISTENER)
				{
					if( [filesArray count] > 0)
					{
						[decompressThreadRunning lock];
						[decompressArrayLock lock];
						[decompressArray addObjectsFromArray: filesArray];
						[decompressArrayLock unlock];
						[decompressThreadRunning unlock];
						
						[self decompressThread: [NSNumber numberWithChar: 'C']];
					}
				}
			}
			else
			{
				if( [compressedPathArray count] == 0) newFilesInIncoming = NO;
				else newFilesInIncoming = YES;
			}
			
			[filesArray release];
			
			if( [compressedPathArray count] > 0)
			{
				[decompressArrayLock lock];
				[decompressArray addObjectsFromArray: compressedPathArray];
				[decompressArrayLock unlock];
				
				[NSThread detachNewThreadSelector: @selector( decompressThread:) toTarget:self withObject: [NSNumber numberWithChar: 'I']];
			}
			[compressedPathArray release];
		}
		else newFilesInIncoming = NO;
	}
	
	@catch( NSException *ne)
	{
		NSLog( @"WARNING ******** - CheckIncomingThread Exception : %@", [ne description]);
	}
	
	[checkIncomingLock unlock];
	
	[pool release];
}

-(void) setDockIcon
{
	NSImage	*image = 0L;
	
	if( newFilesInIncoming) image = downloadingOsiriXIcon;
	else image = standardOsiriXIcon;
	
	if( currentIcon != image)
	{
		currentIcon = image;
		[[NSApplication sharedApplication] setApplicationIconImage: image];
		NSLog( @"dock icon set");
	}
}

-(void) checkIncoming:(id) sender
{
	if( isCurrentDatabaseBonjour) return;
	if( managedObjectContext == 0L) return;
	
	if( [checkIncomingLock tryLock])
	{
		[NSThread detachNewThreadSelector: @selector(checkIncomingThread:) toTarget:self withObject: self];
		[checkIncomingLock unlock];
	}
	else
	{
		NSLog(@"checkIncoming locked...");
		newFilesInIncoming = YES;
	}
	
	[self setDockIcon];
}

- (void) writeMovie: (NSArray*) imagesArray name: (NSString*) fileName
{
	[[QTMovie movie] writeToFile: [fileName stringByAppendingString:@"temp"] withAttributes: 0L];
			
	QTMovie *mMovie = [QTMovie movieWithFile:[fileName stringByAppendingString:@"temp"] error:nil];
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	long long timeValue = 60;
	long timeScale = 600;
	
	QTTime curTime = QTMakeTime(timeValue, timeScale);
	
	NSDictionary *myDict = [NSDictionary dictionaryWithObject: @"jpeg" forKey: QTAddImageCodecType];
	
	int	curSample;
	for (curSample = 0; curSample < [imagesArray count]; curSample++) 
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		[mMovie addImage:[imagesArray objectAtIndex: curSample] forDuration:curTime withAttributes: myDict];
		
		[pool release];
	}
	
	[mMovie writeToFile: fileName withAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten]];
	[[NSFileManager defaultManager] removeFileAtPath:[fileName stringByAppendingString:@"temp"] handler:0L];
}

-(void) exportQuicktimeInt:(NSArray*) dicomFiles2Export :(NSString*) path :(BOOL) html
{
	int					i, t;
	NSString			*dest;
	Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", 0L) :NO];
	BOOL				addDICOMDIR = [addDICOMDIRButton state];
	NSMutableArray		*imagesArray = [NSMutableArray array];
	NSString			*tempPath, *previousPath = 0L;
	long				previousSeries = -1;
	NSString			*previousStudy = @"";
	BOOL				createHTML = html;

	NSMutableDictionary *htmlExportDictionary = [NSMutableDictionary dictionary];
	
	[splash setCancel:YES];
	[splash showWindow:self];
	[[splash progress] setMaxValue:[dicomFiles2Export count]];

	@try 
	{
		for( i = 0; i < [dicomFiles2Export count]; i++)
		{
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSString *extension = 0L;
			
			tempPath = [path stringByAppendingPathComponent: asciiString( [curImage valueForKeyPath: @"series.study.name"])];
			
			NSMutableArray *htmlExportSeriesArray;
			if(![htmlExportDictionary objectForKey:[curImage valueForKeyPath: @"series.study.patientUID"]])
			{
				htmlExportSeriesArray = [NSMutableArray array];
				[htmlExportSeriesArray addObject:[curImage valueForKey: @"series"]];
				[htmlExportDictionary setObject:htmlExportSeriesArray forKey:[curImage valueForKeyPath: @"series.study.patientUID"]];
			}
			else
			{
				htmlExportSeriesArray = [htmlExportDictionary objectForKey:[curImage valueForKeyPath: @"series.study.patientUID"]];
				[htmlExportSeriesArray addObject:[curImage valueForKey: @"series"]];
			}
			
			// Find the PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( i == 0)
				{
					if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
					{
						[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
					}
					else break;
				}
			}
			
			tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", asciiString( [curImage valueForKeyPath: @"series.study.studyName"]), [curImage valueForKeyPath: @"series.study.id"]]];
			if( [[curImage valueForKeyPath: @"series.study.id"] isEqualToString:previousStudy] == NO)
			{
				previousStudy = [curImage valueForKeyPath: @"series.study.id"];
				previousSeries = -1;
			}
			
			// Find the STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			NSMutableString *seriesStr = [NSMutableString stringWithString: asciiString( [curImage valueForKeyPath: @"series.name"])];
			[BrowserController replaceNotAdmitted:seriesStr];
			tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
			tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
			
			if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue])
			{
				if( [imagesArray count] > 1)
				{
					[self writeMovie: imagesArray name: [previousPath stringByAppendingString:@".mov"]];
				}
				else if( [imagesArray count] == 1)
				{
					NSArray *representations = [[imagesArray objectAtIndex: 0] representations];
					NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
					[bitmapData writeToFile:[previousPath stringByAppendingString:@".jpg"] atomically:YES];
				}
				
				//
				if(createHTML)
				{
					NSImage	*thumbnail = [[[NSImage alloc] initWithData: [curImage valueForKeyPath: @"series.thumbnail"]] autorelease];
					if(!thumbnail)
						thumbnail = [[NSImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Empty.tif"]];

					if( thumbnail)
					{
						NSData *bitmapData = 0L;
						NSArray *representations = [thumbnail representations];
						bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
						[bitmapData writeToFile:[tempPath stringByAppendingString:@"_thumb.jpg"] atomically:YES];
					}
				}
				
				[imagesArray removeAllObjects];
				previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
			}
			
			previousPath = [NSString stringWithString: tempPath];
			
			DCMPix* dcmPix = [[DCMPix alloc] myinit: [curImage valueForKey:@"completePathResolved"] :0 :1 :0L :0 :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curImage];
			
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
				
				[imagesArray addObject: [dcmPix image]];
				[dcmPix release];
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted]) 
				i = [dicomFiles2Export count];
		}
	
		if( [imagesArray count] > 1)
		{
			[self writeMovie: imagesArray name: [previousPath stringByAppendingString:@".mov"]];
		}
		else if( [imagesArray count] == 1)
		{
			NSArray *representations = [[imagesArray objectAtIndex: 0] representations];
			NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			[bitmapData writeToFile:[previousPath stringByAppendingString:@".jpg"] atomically:YES];
		}
		
		if(createHTML)
		{
			QTExportHTMLSummary *htmlExport = [[QTExportHTMLSummary alloc] init];
			[htmlExport setPatientsDictionary:htmlExportDictionary];
			[htmlExport setPath:path];
			[htmlExport createHTMLfiles];
		}
	}
	
	@catch (NSException * e)
	{
		NSLog( [e description]);
	}
	
	[splash close];
	[splash release];
}

- (void) exportQuicktime:(id) sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	NSLog( [sender description]);
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	{
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		NSLog(@"Files from contextual menu: %d", [filesToExport count]);
	}
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the Quicktime files:",0L)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",0L)];
	[sPanel setTitle: NSLocalizedString(@"Export",0L)];
	[sPanel setCanCreateDirectories:YES];
	
	[sPanel setAccessoryView:exportQuicktimeView];
	
	if ([sPanel runModalForDirectory:0L file:0L types:0L] == NSFileHandlingPanelOKButton)
	{
		[self exportQuicktimeInt: dicomFiles2Export :[[sPanel filenames] objectAtIndex:0] :[exportHTMLButton state]];
	}
}

- (void) exportJPEG:(id) sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	long				previousSeries = -1;
	long				serieCount		= 0;
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
	NSMutableArray *filesToExport;
	
	NSLog( [sender description]);
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	{
		filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export];
		NSLog(@"Files from contextual menu: %d", [filesToExport count]);
	}
	else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the JPEG files:",0L)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",0L)];
	[sPanel setTitle: NSLocalizedString(@"Export",0L)];
	[sPanel setCanCreateDirectories:YES];
	
	if ([sPanel runModalForDirectory:0L file:0L types:0L] == NSFileHandlingPanelOKButton)
	{
		int					i, t;
		NSString			*dest, *path = [[sPanel filenames] objectAtIndex:0];
		Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", 0L)];
		BOOL				addDICOMDIR = [addDICOMDIRButton state];
		
		[splash setCancel:YES];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToExport count]];

		for( i = 0; i < [filesToExport count]; i++)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSString *extension = @"jpg";
			
			NSString *tempPath;
			
			tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
			
			// Find the PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( i == 0)
				{
					if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
					{
						[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
						[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
					}
					else break;
				}
			}
			
			tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]]];

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
			
			t = 2;
			while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
			{
				if (!addDICOMDIR)
					dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d #%d.%@", tempPath, serieCount, imageNo, t, extension];
				else
					dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, t];
				t++;
			}
			
			DCMPix* dcmPix = [[DCMPix alloc] myinit: [curImage valueForKey:@"completePathResolved"] :0 :1 :0L :0 :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curImage];
			
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
				
				NSArray *representations = [[dcmPix image] representations];
				NSData *bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
				[bitmapData writeToFile:dest atomically:YES];
				
				[dcmPix release];
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted]) 
				i = [filesToExport count];
				
			[pool release];
		}
		
		//close progress window	
		[splash close];
		[splash release];
	}
}

+ (void) replaceNotAdmitted:(NSMutableString*) name
{
	[name replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"." withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"," withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
	[name replaceOccurrencesOfString:@"^" withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
	[name replaceOccurrencesOfString:@"/" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"\\" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"|" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"-" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@":" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"*" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"<" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@">" withString:@"" options:nil range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"?" withString:@"" options:nil range:NSMakeRange(0, [name length])];
}

- (NSArray*) exportDICOMFileInt:(NSString*) location files:(NSArray*) filesToExport objects:(NSArray*) dicomFiles2Export
{
	int					i, t;
	NSString			*dest, *path = location;
	Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", 0L)];
	BOOL				addDICOMDIR = [addDICOMDIRButton state];
	long				previousSeries = -1;
	long				serieCount		= 0;
	NSMutableArray		*result = [NSMutableArray array];
	NSMutableArray		*files2Compress = [NSMutableArray array];
	
	[splash setCancel:YES];
	[splash showWindow:self];
	[[splash progress] setMaxValue:[filesToExport count]];
	
	for( i = 0; i < [filesToExport count]; i++)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
		NSString		*extension = [[filesToExport objectAtIndex:i] pathExtension];
		
		if( [curImage valueForKey: @"fileType"])
		{
			if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"]) extension = [NSString stringWithString:@"dcm"];
		}
		
		if([extension isEqualToString:@""]) extension = [NSString stringWithString:@"dcm"]; 
		
		NSString *tempPath;
		// if creating DICOMDIR. Limit length to 8 char
		if (!addDICOMDIR)  
			tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
		else {
			NSMutableString *name;
			if ([[curImage valueForKeyPath: @"series.study.name"] length] > 8)
				name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
			else
				name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
			
			NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
			
			[BrowserController replaceNotAdmitted: name];
			
			tempPath = [path stringByAppendingPathComponent:name];
		}
		
		// Find the DICOM-PATIENT folder
		if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			[result addObject: [tempPath lastPathComponent]];
		}
		else
		{
			if( i == 0)
			{
				if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
				{
					[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
					[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
				}
				else break;
			}
		}
		
		if( [folderTree selectedTag] == 0)
		{
			if (!addDICOMDIR)		
				tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]]];
			else
			{				
				NSMutableString *name;
				if ([[curImage valueForKeyPath: @"series.study.id"] length] > 8 )
					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath:@"series.study.id"] substringToIndex:7] uppercaseString]];
				else
					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.id"] uppercaseString]];
				
				NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
				
				[BrowserController replaceNotAdmitted: name];
				tempPath = [tempPath stringByAppendingPathComponent:name];
			}
				
			// Find the DICOM-STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			if (!addDICOMDIR )
			{
				NSMutableString *seriesStr = [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.name"]];
				
				[BrowserController replaceNotAdmitted:seriesStr];
				
				tempPath = [tempPath stringByAppendingPathComponent: seriesStr ];
				tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
			}
			else
			{
				NSMutableString *name;
	//				if ([[curImage valueForKeyPath: @"series.name"] length] > 8)
	//					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.name"] substringToIndex:7] uppercaseString]];
	//				else
	//					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.name"] uppercaseString]];
				
				name = [NSMutableString stringWithString: [[[curImage valueForKeyPath: @"series.id"] stringValue] uppercaseString]];
				
				NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
				
				[BrowserController replaceNotAdmitted: name];
				tempPath = [tempPath stringByAppendingPathComponent:name];
			}
			
			// Find the DICOM-SERIE folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
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
		
		t = 2;
		while( [[NSFileManager defaultManager] fileExistsAtPath: dest])
		{
			if (!addDICOMDIR)
				dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d #%d.%@", tempPath, serieCount, imageNo, t, extension];
			else
				dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, t];
			t++;
		}
		
		[[NSFileManager defaultManager] copyPath:[filesToExport objectAtIndex:i] toPath:dest handler:0L];
		
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
		
		if( [splash aborted]) 
			i = [filesToExport count];
		
		[pool release];
	}
	
	if( [files2Compress count] > 0)
	{
		switch( [compressionMatrix selectedTag])
		{
			case 1:
				[self decompressArrayOfFiles: files2Compress work: [NSNumber numberWithChar: 'C']];
			break;
			
			case 2:
				[self decompressArrayOfFiles: files2Compress work: [NSNumber numberWithChar: 'D']];
			break;
		}
	}
	
	// add DICOMDIR
	//NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",path];
	
	// ANR - I had to create this loop, otherwise, if I export a folder on the desktop, the dcmkdir will scan all files and folders available on the desktop.... not only the exported folder.
	
	if (addDICOMDIR)
	{
		for( i = 0; i < [filesToExport count]; i++)
		{
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSMutableString *name;
			
			if ([[curImage valueForKeyPath: @"series.study.name"] length] > 8)
				name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
			else
				name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
			
			NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
			
			[BrowserController replaceNotAdmitted: name];
			
			NSString *tempPath = [path stringByAppendingPathComponent:name];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath:[tempPath stringByAppendingPathComponent:@"DICOMDIR"]] == NO)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				NSLog(@" ADD dicomdir");
				NSTask              *theTask;
				NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+I",@"+id", tempPath,  nil];
				
				theTask = [[NSTask alloc] init];
				[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
				[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmmkdir"]];
				[theTask setCurrentDirectoryPath:tempPath];
				[theTask setArguments:theArguments];		

				[theTask launch];
				[theTask waitUntilExit];
				[theTask release];
				// masu 2008-08-28 relase for pool was missing
				[pool release];
			}
		}
	}
	
	//close progress window	
	[splash close];
	[splash release];
	
	return result;
}

- (void) exportDICOMFile:(id) sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the DICOM files:",0L)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",0L)];
	[sPanel setTitle: NSLocalizedString(@"Export",0L)];
	[sPanel setCanCreateDirectories:YES];
	[sPanel setAccessoryView:exportAccessoryView];
	
	[compressionMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"Compression Mode for Export"]];
	
	if ([sPanel runModalForDirectory:0L file:0L types:0L] == NSFileHandlingPanelOKButton)
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing the files...", nil)];
		[wait showWindow:self];
		
		NSLog( [sender description]);
		if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
		{
			//Burn additional Files. Not just images. Add SRs
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages:NO];
			NSLog(@"Files from contextual menu: %d", [filesToExport count]);
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages:NO];
		
		[wait close];
		[wait release];
		
		[self exportDICOMFileInt: [[sPanel filenames] objectAtIndex:0] files: filesToExport objects: dicomFiles2Export];
		
		[[NSUserDefaults standardUserDefaults] setInteger:[compressionMatrix selectedTag] forKey:@"Compression Mode for Export"];
	}
}

- (void) setBurnerWindowControllerToNIL
{	
	burnerWindowController = 0L;
}

- (void) burnDICOM:(id) sender
{
	if( burnerWindowController == 0L)
	{
		NSMutableArray *managedObjects = [[NSMutableArray alloc] init];
		NSMutableArray *filesToBurn;
		//Burn additional Files. Not just images. Add SRs
		if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) filesToBurn = [self filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];
		else filesToBurn = [self filesForDatabaseOutlineSelection:managedObjects   onlyImages:NO];
		
		burnerWindowController = [[BurnerWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects];

		[burnerWindowController showWindow:self];
	}
	else
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"OsiriX" 
			defaultButton:@"OK" 
			alternateButton:nil 
			otherButton:nil 
			informativeTextWithFormat:@"Burn in Progress. Please Wait."];
		[alert runModal];
	}
	//send to OsirixBurner

}

- (IBAction) anonymizeDICOM:(id) sender
{
	NSMutableArray *paths = [NSMutableArray array];
	NSMutableArray *dicomFiles2Anonymize = [NSMutableArray array];
	NSMutableArray *filesToAnonymize;
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) filesToAnonymize = [[self filesForDatabaseMatrixSelection: dicomFiles2Anonymize] retain];
	else filesToAnonymize = [[self filesForDatabaseOutlineSelection: dicomFiles2Anonymize] retain];
	
    [anonymizerController showWindow:self];
	
	NSEnumerator *enumerator = [filesToAnonymize objectEnumerator];
	NSString *file;
	while (file = [enumerator nextObject])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString	*extension = [file pathExtension];
		if([extension isEqualToString:@"" ]) extension = [NSString stringWithString:@"dcm"];
		else
		{   // Added by rbrakes - check to see if "extension" includes only numbers (UID perhaps?).
			int num;
			NSScanner *scanner = [NSScanner scannerWithString: extension];
			if ( [scanner scanInt: &num] && [scanner isAtEnd] ) extension = [NSString stringWithString:@"dcm"];
		}
		
		if ([extension  caseInsensitiveCompare:@"dcm"] == NSOrderedSame)
			[paths addObject:file]; 
		
		[pool release];

	}
	if(!anonymizerController)
		anonymizerController = [[AnonymizerWindowController alloc] init];
	
	[anonymizerController setFilesToAnonymize:paths :dicomFiles2Anonymize];
	[anonymizerController showWindow:self];
	[anonymizerController anonymize:self];
		
	if( [anonymizerController cancelled] == NO && [[NSUserDefaults standardUserDefaults] boolForKey:@"replaceAnonymize"] == YES && isCurrentDatabaseBonjour == NO)
	{
		// Delete the non-anonymized
		[self delItem: sender];
		
		// Add the anonymized files
		NSArray	*newImages = [self addFilesAndFolderToDatabase: [anonymizerController producedFiles]];
		
		// Are we adding new files in a album?
		// can't add to smart Album
		if( [[self albumTable] selectedRow] > 0)
		{
			NSManagedObject *album = [[self albumArray] objectAtIndex: [[self albumTable] selectedRow]];
			
			if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
			{
				NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
				
				int i;
				for( i = 0; i < [newImages count]; i++)
				{
					NSManagedObject		*object = [newImages objectAtIndex: i];
					[studies addObject: [object valueForKeyPath:@"series.study"]];
				}
				
				[self outlineViewRefresh];
			}
		}
		
		if( [newImages count] > 0)
		{
			NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
			[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		}
	}
	
	[filesToAnonymize release];
}	

- (IBAction)setImageTiling: (id)sender{
	int columns = 1;
	int rows = 1;
	 int tag;
     NSMenuItem *item;

    if ([sender class] == [NSMenuItem class]) {
        NSArray *menuItems = [[sender menu] itemArray];
        NSEnumerator *enumerator = [menuItems objectEnumerator];
        while(item = [enumerator nextObject])
            [item setState:NSOffState];
        tag = [(NSMenuItem *)sender tag];
    //    [sender setState:NSOnState];
    }
	
	if (tag < 16) {
		rows = (tag / 4) + 1;
		columns =  (tag %  4) + 1;
	}
	
	NSArray *objects = [NSArray arrayWithObjects:[NSNumber numberWithInt:columns], [NSNumber numberWithInt:rows], nil];
	NSArray *keys = [NSArray arrayWithObjects:@"Columns", @"Rows", nil];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMImageTilingHasChanged"  object:self userInfo: userInfo];
}

-(void) AlternateButtonPressed:(NSNotification*) n
{
	int i = [bonjourServicesList selectedRow];
	if( i > 0)
	{
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Volume unmounting...", nil)];
		[wait showWindow:self];
		[bonjourServicesList display];
		NSString	*path = [[[bonjourBrowser services] objectAtIndex: i-1] valueForKey:@"Path"];
		BOOL success = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:  path];
		[bonjourServicesList display];
		[bonjourServicesList setNeedsDisplay];
		[wait close];
		[wait release];
		
		if( success == NO)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"Failed", 0L), NSLocalizedString(@"Unable to unmount this disk. This disk is probably in used by another application.", 0L), NSLocalizedString(@"OK",nil),nil, nil);
		}
	}
}

- (void) loadDICOMFromiPod
{
	NSArray *allVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	int i, x, index;

	for ( i=0 ; i < [allVolumes count]; i++)
	{
		NSString *iPodControlPath = [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"iPod_Control"];
		BOOL isItAnIpod = [[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath];
		BOOL isThereAnOsiriXDataAtTheRoot = [[NSFileManager defaultManager] fileExistsAtPath: [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"OsiriX Data"]];
		
		if( isItAnIpod || isThereAnOsiriXDataAtTheRoot)
		{
			NSString *volumeName = [[allVolumes objectAtIndex:i] lastPathComponent];
			
			NSLog(@"Got a volume named %@", volumeName);
			
			NSString	*path = [allVolumes objectAtIndex:i];
			
			// Find the OsiriX Data folder at root
			if (![[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:@"OsiriX Data"]]) [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:@"OsiriX Data"] attributes:nil];
			
			// Is this iPod already in the list?
			int x;
			BOOL found = NO;
			for( x = 0; x < [[bonjourBrowser services] count]; x++)
			{
				NSDictionary	*c = [[bonjourBrowser services] objectAtIndex: x];
				
				if( [[c valueForKey:@"type"] isEqualToString:@"localPath"])
				{
					if( [[c valueForKey:@"Path"] isEqualToString: path]) found = YES;
				}
			}
			
			if( found == NO)
			{
				int z = [self currentBonjourService];
				NSDictionary	*selectedDict = 0L;
				if( z >= 0) selectedDict = [[[bonjourBrowser services] objectAtIndex: z] retain];
				
				NSMutableDictionary	*dict = [NSMutableDictionary dictionary];
				
				NSString	*name = 0L;
				
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
					int index = [[bonjourBrowser services] indexOfObject: selectedDict];
					
					if( index == NSNotFound)
						[self resetToLocalDatabase];
					else
						[self setCurrentBonjourService: index];
						
					[selectedDict release];
				}
				[self displayBonjourServices];
			}
		}
	}
}

-(void) scaniDiskDir:(DMiDiskSession*) mySession :(NSString*) path :(NSArray*) dir :(NSMutableArray*) files
{
	long		i;
	BOOL		isDirectory;
	NSString	*item;
	
	for( i =0 ; i < [dir count]; i++)
	{
		item = [path stringByAppendingPathComponent: [dir objectAtIndex:i]];
		
		NSLog( item);
		
		if( [mySession fileExistsAtPath:item isDirectory:&isDirectory])
		{
			if( isDirectory)
			{
				NSArray *dirContent = [mySession directoryContentsAtPath: item];
				[self scaniDiskDir:mySession :item :dirContent :files];
			}
			else [files addObject: item];
		}
	}
}

- (void) loadDICOMFromiDisk:(id) sender
{
	if( isCurrentDatabaseBonjour) return;
	
	#if !__LP64__
	
	BOOL				delete, success;
	long				i;
	DMMemberAccount		*myDotMacMemberAccount;
	
	 myDotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"----"];
	
	if (myDotMacMemberAccount != nil)
	{
		DMiDiskSession *mySession = [DMiDiskSession iDiskSessionWithAccount: myDotMacMemberAccount];
		
		if( mySession)
		{
			if( NSRunInformationalAlertPanel( NSLocalizedString(@"iDisk", nil), NSLocalizedString(@"Should I delete the files on the iDisk after the copy?", nil), NSLocalizedString(@"Delete the files", nil), NSLocalizedString(@"Leave them", nil), 0L) == NSAlertDefaultReturn)
			{
				delete = YES;
			}
			else
			{
				delete = NO;
			}
			
			NSString	*path = @"Documents/DICOM";
			
			// Find the DICOM folder
			success = YES;
			if( ![mySession fileExistsAtPath:path]) success = [mySession createDirectoryAtPath:path attributes:nil];
			
			if( success)
			{
				NSMutableArray  *filesArray = [[NSMutableArray alloc] initWithCapacity: 0];
				Wait			*splash = [[Wait alloc] initWithString: NSLocalizedString(@"Getting DICOM files from your iDisk",@"Getting DICOM files from your iDisk")];
				
				[splash setCancel:YES];
				[splash showWindow:self];
				
				[[NSFileManager defaultManager] removeFileAtPath:[documentsDirectory() stringByAppendingFormat:@"/TEMP/DICOM"] handler: 0L];
				
				NSArray *dirContent = [mySession directoryContentsAtPath: path];
				[self scaniDiskDir:mySession :path :dirContent :filesArray];
				
				[[splash progress] setMaxValue:[filesArray count]];

				// Move the new DICOM FILES to the DATABASE folder
				
				NSString        *dstPath, *OUTpath = [documentsDirectory() stringByAppendingPathComponent:DATABASEPATH];
				BOOL			isDir = YES;
				
				if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
				
				for( i = 0; i < [filesArray count]; i++)
				{
					dstPath = [self getNewFileDatabasePath:@"dcm"];
					
					[mySession movePath:[filesArray objectAtIndex: i] toPath:dstPath handler: 0L];
					
					[filesArray replaceObjectAtIndex:i withObject: dstPath];
					
					[splash incrementBy:1];
					
					if( [splash aborted])
					{
						[filesArray removeObjectsInRange: NSMakeRange(i, [filesArray count]-i)];
					}
				}
				
				[browserWindow addFilesAndFolderToDatabase: filesArray];
				
				[filesArray release];
				
				[splash close];
				[splash release];
				
				if( delete)
				{
					[mySession removeFileAtPath:path handler: 0L];
				}
			}
			else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"Unable to contact dotMac service.",@"Unable to contact dotMac service."), NSLocalizedString(@"OK",nil),nil, nil);
		}
		else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"Unable to contact dotMac service.",@"Unable to contact dotMac service."), NSLocalizedString(@"OK",nil),nil, nil);
	}
	else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"No iDisk is currently defined in your system.",@"No iDisk is currently defined in your system."),NSLocalizedString( @"OK",nil),nil, nil);
	#endif
}

- (IBAction) sendiDisk:(id) sender
{
	#if !__LP64__
	int					i, t, x, index;
	BOOL				success = YES;
	DMMemberAccount		*myDotMacMemberAccount;
	
	 myDotMacMemberAccount = [DMMemberAccount accountFromPreferencesWithApplicationID:@"----"];
	
	if (myDotMacMemberAccount != nil)
	{
		DMiDiskSession *mySession = [DMiDiskSession iDiskSessionWithAccount: myDotMacMemberAccount];
				
		// Copy the files!
		if( mySession)
		{
			NSMutableArray *dicomFiles2Copy = [NSMutableArray array];
			NSMutableArray *files2Copy;
			
			if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) files2Copy = [self filesForDatabaseMatrixSelection: dicomFiles2Copy];
			else files2Copy = [self filesForDatabaseOutlineSelection: dicomFiles2Copy];
			
			if( files2Copy)
			{
				NSString	*path = @"Documents/DICOM";
				
				// Find the DICOM folder
				if( ![mySession fileExistsAtPath:path]) [mySession createDirectoryAtPath:path attributes:nil];
				
				Wait                *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying to your iDisk",0L)];
				
				[splash setCancel:YES];
				[splash showWindow:self];
				[[splash progress] setMaxValue:[files2Copy count]];
				
				for( x = 0 ; x < [files2Copy count]; x++)
				{
					NSString			*dstPath, *srcPath = [files2Copy objectAtIndex:x];
					NSString			*extension = [srcPath pathExtension];
					NSString			*tempPath;
					NSManagedObject		*curImage = [dicomFiles2Copy objectAtIndex:x];

					if( [[srcPath stringByDeletingLastPathComponent] isEqualToString:path] == NO) // Is this file already on the iPod?
					{
						if([curImage valueForKey: @"fileType"])
						{
							if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"])
							{
								extension = [NSString stringWithString:@"dcm"];
							}
						}
						
						if([extension isEqualToString:@""])
						{
							extension = [NSString stringWithString:@"dcm"];
						}
						
						tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"] ];
						// Find the DICOM-PATIENT folder
						if( ![mySession fileExistsAtPath:tempPath]) [mySession createDirectoryAtPath:tempPath attributes:nil];
						else
						{
							if( i == 0)
							{
								if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), 0L) == NSAlertDefaultReturn)
								{
									[mySession removeFileAtPath:tempPath handler:nil];
									[mySession createDirectoryAtPath:tempPath attributes:nil];
								}
								else break;
							}
						}
			
						tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.studyName"] ];
						// Find the DICOM-STUDY folder
						if( ![mySession fileExistsAtPath:tempPath]) [mySession createDirectoryAtPath:tempPath attributes:nil];
						
						tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.name"] ];
						
						tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
						// Find the DICOM-SERIE folder
						if( ![mySession fileExistsAtPath:tempPath]) [mySession createDirectoryAtPath:tempPath attributes:nil];
						
						dstPath = [NSString stringWithFormat:@"%@/%d.%@", tempPath, [[curImage valueForKey:@"instanceNumber"] intValue], extension];
						
						t = 2;
						while( [mySession fileExistsAtPath: dstPath])
						{
							dstPath = [NSString stringWithFormat:@"%@/%d #%d.%@", tempPath, [[curImage valueForKey:@"instanceNumber"] intValue], t, extension];
							t++;
						}
						
						if( [mySession copyPath:srcPath toPath:dstPath handler: 0L] == NO)
						{
							success = NO;
							x = [files2Copy count];
						}
						
						if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
						{
							[mySession copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler: 0L];
						}
					}
					else NSLog( @"Already on the iDisk!");
					
					[splash incrementBy:1];
					
					if( [splash aborted])
					{
						x = [files2Copy count];
					}
				}
				
				[splash close];
				[splash release];
				
				if( success == NO)
				{
					NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"Unable to contact dotMac service.",@"Unable to contact dotMac service."), NSLocalizedString(@"OK",nil),nil, nil);
				}
			}
			else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"Unable to contact dotMac service.",@"Unable to contact dotMac service."), NSLocalizedString(@"OK",nil),nil, nil);
		}
	}
	else NSRunCriticalAlertPanel(NSLocalizedString(@"iDisk?",@"iDisk?"), NSLocalizedString(@"No iDisk is currently defined in your system.",@"No iDisk is currently defined in your system."), NSLocalizedString(@"OK",nil),nil, nil);
	#endif
}

- (void) selectServer: (NSArray*) objects
{
	if( [objects count] > 0) [SendController sendFiles:objects];
	else NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No files are selected...",nil),NSLocalizedString( @"OK",nil), nil, nil);
}

- (void) export2PACS:(id) sender
{
	[[self window] makeKeyAndOrderFront:sender];

	NSMutableArray	*objects = [NSMutableArray array];
	NSMutableArray  *files;
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) files = [self filesForDatabaseMatrixSelection:objects onlyImages: NO];
	else files = [self filesForDatabaseOutlineSelection:objects onlyImages: NO];
	
	[self selectServer: objects];
}

- (IBAction) querySelectedStudy:(id) sender
{
	[[self window] makeKeyAndOrderFront:sender];
	
    if( [QueryController currentQueryController] == 0L) [[QueryController alloc] init];

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

- (void) queryDICOM:(id) sender
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)	// Query selected patient
		[self querySelectedStudy: self];
	else
	{
		[[self window] makeKeyAndOrderFront:sender];
		
		if(![QueryController currentQueryController]) [[QueryController alloc] init];
		[[QueryController currentQueryController] showWindow:self];
	}
}

-(void)volumeMount:(NSNotification *)notification
{
	NSLog(@"volume mounted");
	
	[self loadDICOMFromiPod];

	if( isCurrentDatabaseBonjour) return;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"MOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	NSLog(sNewDrive);
	
	if( [BrowserController isItCD:[sNewDrive pathComponents]] == YES)
	{
		[self ReadDicomCDRom:self];
	}
	
	[self displayBonjourServices];
}

-(void) removeAllMounted
{
	long		i, x;

	if( isCurrentDatabaseBonjour) return;
	
	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = [self managedObjectContext];
	NSManagedObjectModel		*model = [self managedObjectModel];
	
	[context retain];
	[context lock];
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
	NSError	*error = 0L;
	NSArray *seriesArray = [[context executeFetchRequest:dbRequest error:&error] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
	
	@try
	{
		if( [seriesArray count] > 0)
		{
			NSMutableArray			*studiesArray = [NSMutableArray arrayWithCapacity:0];
			NSMutableArray			*viewersList = [ViewerController getDisplayed2DViewers];
			
			// Find unavailable files
			for( i = 0; i < [seriesArray count]; i++)
			{
				NSManagedObject	*study = [[seriesArray objectAtIndex:i] valueForKeyPath:@"study"];
				
				// Is a viewer containing this study opened? -> close it
				for( x = 0; x < [viewersList count]; x++)
				{
					if( study == [[[[viewersList objectAtIndex: x] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
					{
						[[[viewersList objectAtIndex: x] window] close];
					}
				}
				
				[context deleteObject: study];
			}
			
			[self saveDatabase: currentDatabasePath];
		}
	}
	@catch( NSException *ne)
	{
		NSLog( @"RemoveAllMounted Exception");
		NSLog( [ne description]);
	}
	
	[context unlock];
	[context release];
}

-(void) willVolumeUnmount:(NSNotification *)notification
{
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	
	// Is it an iPod?
	if ([[NSFileManager defaultManager] fileExistsAtPath: [sNewDrive stringByAppendingPathComponent:@"iPod_Control"]])
	{
		// Is it currently selected? -> switch back to default DB path
		int row = [bonjourServicesList selectedRow];
		if( row > 0)
		{
			if( [[[[bonjourBrowser services] objectAtIndex: row-1] valueForKey:@"Path"] isEqualToString: sNewDrive])
				[self resetToLocalDatabase];
		}
		
		// Remove it from the Source list
		
		int z = [self currentBonjourService];
		NSDictionary	*selectedDict = 0L;
		if( z >= 0) selectedDict = [[[bonjourBrowser services] objectAtIndex: z] retain];
		
		int x;
		for( x = 0; x < [[bonjourBrowser services] count]; x++)
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
			int index = [[bonjourBrowser services] indexOfObject: selectedDict];
			
			if( index == NSNotFound)
				[self resetToLocalDatabase];
			else
				[self setCurrentBonjourService: index];
			
			[selectedDict release];
		}
		[self displayBonjourServices];
	}
}

-(void)volumeUnmount:(NSNotification *)notification
{
	long		i, x;
	BOOL		needsUpdate = NO;
	NSRange		range;
	
	if( isCurrentDatabaseBonjour) return;
	
	NSLog(@"volume unmounted");
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"UNMOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];	//uppercaseString];
	NSLog( sNewDrive);
	
	range.location = 0;
	range.length = [sNewDrive length];
	
	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = [self managedObjectContext];
	NSManagedObjectModel		*model = [self managedObjectModel];
	
	[checkIncomingLock lock];
	
	if( [context tryLock])
	{
		[context retain];
		
		DatabaseIsEdited = YES;

		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		NSError	*error = 0L;
		NSArray *seriesArray = [[context executeFetchRequest:dbRequest error:&error] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];

		Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Unmounting volume...",@"Unmounting volume")];
		[splash showWindow:self];

		if( [seriesArray count] > 0)
		{
			NSMutableArray			*viewersList = [ViewerController getDisplayed2DViewers];
			
			[[splash progress] setMaxValue:[seriesArray count]/50];
			
			@try
			{
				// Find unavailable files
				for( i = 0; i < [seriesArray count]; i++)
				{
					NSManagedObject	*image = [[[seriesArray objectAtIndex:i] valueForKey:@"images"] anyObject];
					if( [[image  valueForKey:@"completePath"] compare:sNewDrive options:NSCaseInsensitiveSearch range:range] == 0)
					{
						NSManagedObject	*study = [[seriesArray objectAtIndex:i] valueForKeyPath:@"study"];
						
						needsUpdate = YES;
						
						// Is a viewer containing this study opened? -> close it
						for( x = 0; x < [viewersList count]; x++)
						{
							if( study == [[[[viewersList objectAtIndex: x] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
							{
								[[[viewersList objectAtIndex: x] window] close];
							}
						}
						
						[context deleteObject: study];
					}
					
					if( i % 50 == 0) [splash incrementBy:1];
				}
			}
			@catch( NSException *ne)
			{
				NSLog( @"Unmount exception");
				NSLog( [ne description]);
			}
			
			if( needsUpdate)
			{
				[self saveDatabase: currentDatabasePath];
			}
			
			[self outlineViewRefresh];
		}

		[splash close];
		[splash release];
		[context unlock];
		[context release];
	}
		
	[checkIncomingLock unlock];
	
	DatabaseIsEdited = NO;
	
	[self displayBonjourServices];
}

- (void)storeSCPComplete:(id)sender{
	//release storescp when done
	[sender release];
}

- (IBAction)importRawData:(id)sender{
	[[rdPatientForm cellWithTag:0] setStringValue:@"Raw Data"]; //Patient Name
	[[rdPatientForm cellWithTag:1] setStringValue:@"RD0001"];	//Patient ID
	[[rdPatientForm cellWithTag:2] setStringValue:@"Raw Data Secondary Capture"]; //Study Descripition
	
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
	//[openPanel setNameFieldLabel:NSLocalizedString(@"Save in:", nil)];
	[openPanel setMessage:NSLocalizedString(@"Choose file containing raw data:", nil)];
	
	if ([openPanel runModalForTypes:nil] == NSOKButton){
		NSData *data = [NSData dataWithContentsOfFile:[openPanel filename]];
		if (data){
			
			
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
			
			int spp;
			int highBit = 7;
			int bitsAllocated = 8;
			float numberBytes;
			BOOL isSigned = YES;
			BOOL isLittleEndian = YES;
			NSString *photometricInterpretation = @"MONOCHROME2";
			switch (pixelType) {
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
						isLittleEndian = YES;
						break;
				default:	spp = 1;
							numberBytes = 2;
			}
			int subDataLength = spp  * numberBytes * [rows intValue] * [columns intValue];	
			if ([data length] >= subDataLength * [slices intValue]  + [offset intValue])	{					
				int i;
				int s = [slices intValue];
				//tmpObject for StudyUID andd SeriesUID				
				DCMObject *tmpObject = [DCMObject secondaryCaptureObjectWithBitDepth:numberBytes * 8  samplesPerPixel:spp numberOfFrames:1];
				NSString *studyUID = [tmpObject attributeValueWithName:@"StudyInstanceUID"];
				NSString *seriesUID = [tmpObject attributeValueWithName:@"SeriesInstanceUID"];
				int studyID = [[NSUserDefaults standardUserDefaults] integerForKey:@"SCStudyID"];
				DCMCalendarDate *studyDate = [DCMCalendarDate date];
				DCMCalendarDate *seriesDate = [DCMCalendarDate date];
				[[NSUserDefaults standardUserDefaults] setInteger:(++studyID) forKey:@"SCStudyID"];
				for (i = 0; i < s; i++){
					NSLog(@"slice: %d", i);
					DCMObject *dcmObject = [DCMObject secondaryCaptureObjectWithBitDepth:numberBytes * 8  samplesPerPixel:spp numberOfFrames:1];
					DCMCalendarDate *aquisitionDate = [DCMCalendarDate date];
					//add attributes
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyUID] forName:@"StudyInstanceUID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:seriesUID] forName:@"SeriesInstanceUID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:patientName] forName:@"PatientsName"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:patientID] forName:@"PatientID"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:studyDescription] forName:@"StudyDescription"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", i]] forName:@"InstanceNumber"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d", 1]] forName:@"id"];
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
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithBool:highBit]] forName:@"HighBit"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsAllocated"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsStored"];
					
					//add Pixel data
					NSString *vr = @"OW";
					if (numberBytes < 2)
						vr = @"OB";
					DCMTransferSyntax *ts;
					if (isLittleEndian)
						ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
					else
						ts = [DCMTransferSyntax ExplicitVRBigEndianTransferSyntax];
					DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"PixelData"];
					DCMPixelDataAttribute *attr = [[[DCMPixelDataAttribute alloc] initWithAttributeTag:tag 
													vr:vr 
													length:numberBytes
													data:nil 
													specificCharacterSet:nil
													transferSyntax:ts 
													dcmObject:dcmObject
													decodeData:NO] autorelease];
					NSRange range = NSMakeRange([offset intValue] + subDataLength * i, subDataLength);
					NSMutableData *subdata = [NSMutableData dataWithData:[data subdataWithRange:range]];
					[attr addFrame:subdata];
					
					[dcmObject setAttribute:attr];
					NSLog(@"raw data to Dicom: %@", [dcmObject description]);
					 NSString	*tempFilename = [documentsDirectory() stringByAppendingFormat:@"/INCOMING/%d.dcm", i];
					[dcmObject writeToFile:tempFilename withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
				} 
			}
			else
				NSLog(@"Not enough data");
		}
	}
}
//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark RTSTRUCT

-(void) rtstructNotification: (NSNotification *)note
{
	BOOL visible = [[[note userInfo] objectForKey: @"RTSTRUCTProgressBar"] boolValue];
	if ( visible ) [self setRtstructProgressPercent: [[[note userInfo] objectForKey: @"RTSTRUCTProgressPercent"] floatValue]];
	[self setRtstructProgressBar: visible];
	
}
	
- (BOOL)rtstructProgressBar {
	return rtstructProgressBar;
}

- (void)setRtstructProgressBar: (BOOL)s {
	rtstructProgressBar = s;
}

- (float)rtstructProgressPercent {
	return rtstructProgressPercent;
}
		
- (void)setRtstructProgressPercent: (float)p {
	rtstructProgressPercent = p;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark Report functions

- (IBAction)srReports: (id)sender{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];			
	NSManagedObject *studySelected;
	if (item) {	
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		if (structuredReportController)
			[structuredReportController release];
		structuredReportController = [[StructuredReportController alloc] initWithStudy:studySelected];
	}
}

-(void) syncReportsIfNecessary: (int) index
{
	NSLog(@"Sync reports");
	
	if( isCurrentDatabaseBonjour)
	{
		NSEnumerator *enumerator = [bonjourReportFilesToCheck keyEnumerator];
		NSString *key;
	   
		while ((key = [enumerator nextObject]))
		{
			NSString	*file = [BonjourBrowser bonjour2local: key];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: file])
			{
				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: file traverseLink:YES];
				
				NSDate *previousDate = [bonjourReportFilesToCheck objectForKey: key];
				NSLog(@"file : %@", file);
				NSLog(@"Sync %@ : %@ - %@", key, [previousDate description], [[fattrs objectForKey:NSFileModificationDate] description]);
				if( [previousDate isEqualToDate: [fattrs objectForKey:NSFileModificationDate]] == NO)
				{
					NSLog(@"Sync %@ : %@ - %@", key, [previousDate description], [[fattrs objectForKey:NSFileModificationDate] description]);
					
					// The file has changed... send back a copy to the bonjour server
					
					[bonjourBrowser sendFile:file index: index];
					
					[bonjourReportFilesToCheck setObject: [fattrs objectForKey:NSFileModificationDate] forKey: key];
				}
			}
			else NSLog( @"file?");
		}
	}
}

- (IBAction) deleteReport: (id) sender
{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item)
	{
		NSManagedObject *studySelected;
		
		[checkBonjourUpToDateThreadLock lock];
		
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		long result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete report", 0L), NSLocalizedString(@"Are you sure you want to delete the selected report?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		
		if( result == NSAlertDefaultReturn)
		{
			if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 3)
			{
				NSBundle *plugin = [reportPlugins objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
						
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
			else if( [studySelected valueForKey:@"reportURL"] != 0L)
			{
				if( isCurrentDatabaseBonjour)
				{
					[[NSFileManager defaultManager] removeFileAtPath:[BonjourBrowser bonjour2local: [studySelected valueForKey:@"reportURL"]] handler:0L];
					[bonjourReportFilesToCheck removeObjectForKey: [[studySelected valueForKey:@"reportURL"] lastPathComponent]];
					
					// Set only LAST component -> the bonjour server will complete the address
					[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:studySelected value:0L forKey:@"reportURL"];
					
					[studySelected setValue: 0L forKey:@"reportURL"];
				}
				else
				{
					[[NSFileManager defaultManager] removeFileAtPath:[studySelected valueForKey:@"reportURL"] handler:0L];
					[studySelected setValue: 0L forKey:@"reportURL"];
				}
				[databaseOutline reloadData];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"OsirixDeletedReport" object:nil userInfo:nil];
		}
		
		[checkBonjourUpToDateThreadLock unlock];
		[self updateReportToolbarIcon:nil];
	}
}

- (IBAction) generateReport: (id) sender
{
	[self updateReportToolbarIcon:nil];
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	int reportsMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue];
	if( item)
	{
		if( reportsMode == 0 && [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"] == 0L) // Would absolutePathForAppBundleWithIdentifier be better here? (DDP)
		{
			NSRunAlertPanel( NSLocalizedString(@"Report Error", nil), NSLocalizedString(@"Microsoft Word is required to open/generate '.doc' reports. You can change it to TextEdit in the Preferences.", nil), nil, nil, nil);
			return;
		}
	
		NSManagedObject *studySelected;
		
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		// *********************************************
		//	PLUGINS
		// *********************************************
		
		if( reportsMode == 3)
		{
			NSBundle *plugin = [reportPlugins objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
					
			if( plugin)
			{
				[checkBonjourUpToDateThreadLock lock];
				
				NSLog(@"generate report with plugin");
				PluginFilter* filter = [[plugin principalClass] filter];
				[filter createReportForStudy: studySelected];
				NSLog(@"end generate report with plugin");
				//[filter report: studySelected action: @"openReport"];
				
				[checkBonjourUpToDateThreadLock unlock];
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
			[checkBonjourUpToDateThreadLock lock];
			
			// *********************************************
			//	BONJOUR
			// *********************************************

			if( isCurrentDatabaseBonjour)
			{
				NSString	*localFile = 0L;
				
				if( [item valueForKey:@"reportURL"])
					localFile = [bonjourBrowser getFile:[item valueForKey:@"reportURL"] index:[bonjourServicesList selectedRow]-1];
				
				if( localFile != 0L && [[NSFileManager defaultManager] fileExistsAtPath:localFile] == YES)
				{
					if (reportsMode < 3)
						[[NSWorkspace sharedWorkspace] openFile: localFile];
					else {
						//structured report code here
						//Osirix will open DICOM Structured Reports
					}
				}
				else
				{
					Reports	*report = [[Reports alloc] init];
					
					[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/TEMP/", documentsDirectory()] type:reportsMode];
					
					[bonjourBrowser sendFile:[studySelected valueForKey:@"reportURL"] index: [bonjourServicesList selectedRow]-1];
					
					// Set only LAST component -> the bonjour server will complete the address
					[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:studySelected value:[[studySelected valueForKey:@"reportURL"] lastPathComponent] forKey:@"reportURL"];
					
					[report release];
				}
				
				NSString	*localReportFile = [BonjourBrowser bonjour2local: [studySelected valueForKey:@"reportURL"]];
				if( [[NSFileManager defaultManager] fileExistsAtPath: localReportFile])
				{
					NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:localReportFile traverseLink:YES];
					[bonjourReportFilesToCheck setObject:[fattrs objectForKey:NSFileModificationDate] forKey: [[studySelected valueForKey:@"reportURL"] lastPathComponent]];
				}
				else NSLog(@"Uh?");
			}
			else
			{
			
		// *********************************************
		//	LOCAL FILE
		// *********************************************

				// Is there a Report URL ? If yes, open it; If no, create a new one
				if( [studySelected valueForKey:@"reportURL"] != 0L && [[NSFileManager defaultManager] fileExistsAtPath:[studySelected valueForKey:@"reportURL"]] == YES)
				{
					if (reportsMode < 3)
						[[NSWorkspace sharedWorkspace] openFile: [studySelected valueForKey:@"reportURL"]];
					else {
						//structured report code here
						//Osirix will open DICOM Structured Reports
						//Release Old Controller
						[self srReports:sender];
					}
					
				}
				else
				{
					if (reportsMode < 3) {
						Reports	*report = [[Reports alloc] init];
						if([[sender class] isEqualTo:[reportTemplatesListPopUpButton class]])[report setTemplateName:[[sender selectedItem] title]];
						[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/REPORTS/", documentsDirectory()] type:reportsMode];					
						[report release];
					}
					else {
						//structured report code here
						//Osirix will open DICOM Structured Reports
						//Release Old Controller
						[self srReports:sender];
					}
				}
			}
			
			[checkBonjourUpToDateThreadLock unlock];
		}
	}
	[self updateReportToolbarIcon:nil];
}

- (NSImage*)reportIcon;
{
	NSString *iconName = @"Report.icns";
	switch([[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue])
	{
		case 0: // M$ Word
		{
			iconName = @"ReportWord.icns";
		}
		break;
		case 1: // TextEdit (RTF)
		{
			iconName = @"ReportRTF.icns";
		}
		break;
		case 2: // Pages.app
		{
			iconName = @"ReportPages.icns";
		}
		break;
	}
	return [NSImage imageNamed:iconName];
}

- (void)updateReportToolbarIcon:(NSNotification *)note
{
	long i;
	NSToolbarItem *item;
	NSArray *toolbarItems = [toolbar items];
	for(i=0; i<[toolbarItems count]; i++)
	{
		item = [toolbarItems objectAtIndex:i];
		if ([[item itemIdentifier] isEqualToString:ReportToolbarItemIdentifier])
		{
			[toolbar removeItemAtIndex:i];
			[toolbar insertItemWithItemIdentifier:ReportToolbarItemIdentifier atIndex:i];
		}
	}
}

- (void)setToolbarReportIconForItem:(NSToolbarItem *)item;
{
	NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];

	NSIndexSet *index = [databaseOutline selectedRowIndexes];
	NSManagedObject	*selectedItem = [databaseOutline itemAtRow:[index firstIndex]];
	NSManagedObject *studySelected;
	if ([[[selectedItem entity] name] isEqual:@"Study"])
		studySelected = selectedItem;
	else
		studySelected = [selectedItem valueForKey:@"study"];
	
	if([pagesTemplatesArray count]>1 && [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue]==2 && ![[NSFileManager defaultManager] fileExistsAtPath:[studySelected valueForKey:@"reportURL"]])
	{
		[item setView:reportTemplatesView];
		[item setMinSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
		[item setMaxSize:NSMakeSize(NSWidth([reportTemplatesView frame]), NSHeight([reportTemplatesView frame]))];
	}
	else
	{
		[item setImage:[self reportIcon]];
	}
}

- (void)reportToolbarItemWillPopUp:(NSNotification *)notif;
{
	if([[notif object] isEqualTo:reportTemplatesListPopUpButton])
	{
		NSMutableArray *pagesTemplatesArray = [Reports pagesTemplatesList];
		[reportTemplatesListPopUpButton removeAllItems];
		[reportTemplatesListPopUpButton addItemWithTitle:@""];
		[reportTemplatesListPopUpButton addItemsWithTitles:pagesTemplatesArray];
		[reportTemplatesListPopUpButton setAction:@selector(generateReport:)];
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Toolbar functions

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    toolbar = [[NSToolbar alloc] initWithIdentifier: DatabaseToolbarIdentifier];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[[self window] setShowsToolbarButton:NO];
	[[[self window] toolbar] setVisible: YES];
    
//    [[self window] makeKeyAndOrderFront:nil];
}

- (void) drawerToggle:(id) sender
{
    NSDrawerState state = [albumDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state)
        [albumDrawer close];
	else
        [albumDrawer openOnEdge:NSMinXEdge];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	
	if ([itemIdent isEqualToString: ImportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Import",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Import",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Import a DICOM file or folder",@"Import a DICOM file or folder")];
		[toolbarItem setImage: [NSImage imageNamed: ImportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectFilesAndFoldersToAdd:)];
    }
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export selected study/series to a DICOM folder",@"Export selected study/series to a DICOM folder")];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
    } 
	else if ([itemIdent isEqualToString: AnonymizerToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Anonymize",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Anonymize",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Anonymize selected study/series to a DICOM folder",@"Anonymize selected study/series to a DICOM folder")];
		[toolbarItem setImage: [NSImage imageNamed: AnonymizerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(anonymizeDICOM:)];
    } 
    else if ([itemIdent isEqualToString: QueryToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Query",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Query",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Query and retrieve a DICOM study from a DICOM node\rShift + click to query selected patient.",0L)];
		[toolbarItem setImage: [NSImage imageNamed: QueryToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(queryDICOM:)];
    }
    else if ([itemIdent isEqualToString: SendToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to a DICOM node",@"Send selected study/series to a DICOM node")];
		[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(export2PACS:)];
    }
	else if ([itemIdent isEqualToString: iDiskGetToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"iDisk Get",nil)];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"iDisk Get",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load DICOM files from iDisk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iDiskGetToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(loadDICOMFromiDisk:)];
	}
	else if ([itemIdent isEqualToString: iDiskSendToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"iDisk Send",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"iDisk Send",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to your iDisk",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iDiskSendToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendiDisk:)];
	}
    else if ([itemIdent isEqualToString: ViewerToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"2D-3D Viewer",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"2D-3D Viewer",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"View selected study/series in 2D-3D",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ViewerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(viewerDICOM:)];
    } 
	else if ([itemIdent isEqualToString: CDRomToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"CD-Rom",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"CD-Rom",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load images from current DICOM CD-Rom",nil)];
		[toolbarItem setImage: [NSImage imageNamed: CDRomToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(ReadDicomCDRom:)];
    }
	else if ([itemIdent isEqualToString: MovieToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"4D Viewer",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"4D Viewer",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Load multiple series into an animated 4D series",nil)];
		[toolbarItem setImage: [NSImage imageNamed: MovieToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(MovieViewerDICOM:)];
    } 
	else if ([itemIdent isEqualToString: TrashToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Delete",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Delete",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Delete selected images from the database",nil)];
		[toolbarItem setImage: [NSImage imageNamed: TrashToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(delItem:)];
    }
	else if ([itemIdent isEqualToString: ReportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Report",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Report",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Create/Open a report for selected study",nil)];
		//[toolbarItem setImage: [NSImage imageNamed: ReportToolbarItemIdentifier]];
		[self setToolbarReportIconForItem:toolbarItem];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(generateReport:)];
    }
	else if ([itemIdent isEqualToString: BurnerToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Burn",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Burn",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Burn a DICOM-compatible CD or DVD",@"Burn a DICOM-compatible CD or DVD")];
		[toolbarItem setImage: [NSImage imageNamed: BurnerToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(burnDICOM:)];		//burnDICOM
    } 
	else if ([itemIdent isEqualToString: ToggleDrawerToolbarItemIdentifier]) {
        
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
		if( [pluginsDict objectForKey: itemIdent] != 0L)
		{
			NSBundle *bundle = [pluginsDict objectForKey: itemIdent];
			NSDictionary *info = [bundle infoDictionary];
			
			[toolbarItem setLabel: itemIdent];
			[toolbarItem setPaletteLabel: itemIdent];
			[toolbarItem setToolTip: itemIdent];
			
//			NSLog( @"ICON:");
//			NSLog( [info objectForKey:@"ToolbarIcon"]);
			
			NSImage	*image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"ToolbarIcon"]]] autorelease];
			if( !image ) image = [[NSWorkspace sharedWorkspace] iconForFile: [bundle bundlePath]];
			[toolbarItem setImage: image];
			
			[toolbarItem setTarget: self];
			[toolbarItem setAction: @selector(executeFilterFromToolbar:)];
		}
		else toolbarItem = nil;
    }

     return [toolbarItem autorelease];
}


- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:	ImportToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										CDRomToolbarItemIdentifier,
										QueryToolbarItemIdentifier,
										SendToolbarItemIdentifier,
										AnonymizerToolbarItemIdentifier,
										BurnerToolbarItemIdentifier,
										TrashToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										ViewerToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										ToggleDrawerToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										ReportToolbarItemIdentifier,
										SearchToolbarItemIdentifier,
										TimeIntervalToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{	
	NSArray	*array;
	
	array = [NSArray arrayWithObjects:		SearchToolbarItemIdentifier,
											TimeIntervalToolbarItemIdentifier,
											NSToolbarCustomizeToolbarItemIdentifier,
											NSToolbarFlexibleSpaceItemIdentifier,
											NSToolbarSpaceItemIdentifier,
											NSToolbarSeparatorItemIdentifier,
											ImportToolbarItemIdentifier,
											CDRomToolbarItemIdentifier,
											QueryToolbarItemIdentifier,
											ExportToolbarItemIdentifier,
											AnonymizerToolbarItemIdentifier,
											SendToolbarItemIdentifier,
											iDiskSendToolbarItemIdentifier,
											iDiskGetToolbarItemIdentifier,
											ViewerToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											BurnerToolbarItemIdentifier,
											TrashToolbarItemIdentifier,
											ReportToolbarItemIdentifier,
											ToggleDrawerToolbarItemIdentifier,
											nil];

	long		i;
	NSArray*	allPlugins = [pluginsDict allKeys];
	
	for( i = 0; i < [allPlugins count]; i++)
	{
		NSBundle		*bundle = [pluginsDict objectForKey: [allPlugins objectAtIndex: i]];
		NSDictionary	*info = [bundle infoDictionary];
		
		if( [[info objectForKey:@"pluginType"] isEqualToString: @"Database"] == YES)
		{
			if( [info objectForKey:@"allowToolbarIcon"])
			{
				if( [[info objectForKey:@"allowToolbarIcon"] boolValue] == YES) array = [array arrayByAddingObject: [allPlugins objectAtIndex: i]];
			}
		}
	}
	
    return array;
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
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

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];

	if( [[removedItem itemIdentifier] isEqualToString:SearchToolbarItemIdentifier])
	{
		[toolbarSearchItem release];
		toolbarSearchItem = 0L;
	}
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
	if( isCurrentDatabaseBonjour)
	{
		if ([[toolbarItem itemIdentifier] isEqualToString: ImportToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: iDiskSendToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: iDiskGetToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: CDRomToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: TrashToolbarItemIdentifier]) return NO;
		if ([[toolbarItem itemIdentifier] isEqualToString: QueryToolbarItemIdentifier]) return NO;
	}
	
    return YES;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Bonjour

- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key
{
	[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:obj value:value forKey:key];
}

- (BOOL) isCurrentDatabaseBonjour
{
	return isCurrentDatabaseBonjour;
}

- (NSString*) bonjourPassword
{
	if( [bonjourPasswordCheck state] == NSOnState) return [bonjourPassword stringValue];
	else return 0L;
}

- (NSString*) askPassword
{
	[password setStringValue:@""];
	
	[NSApp beginSheet:	bonjourPasswordWindow
						modalForWindow: [self window]
						modalDelegate: nil
						didEndSelector: nil
						contextInfo: nil];
				
	int result = [NSApp runModalForWindow:bonjourPasswordWindow];
	
	[NSApp endSheet: bonjourPasswordWindow];
	[bonjourPasswordWindow orderOut: self];
	
	if( result == NSRunStoppedResponse)
	{
		return [password stringValue];
	}
	
	return @"";
}

- (long) currentBonjourService {return [bonjourServicesList selectedRow]-1;}

- (void) setCurrentBonjourService:(int) index
{
	dontLoadSelectionSource = YES;
	[bonjourServicesList selectRow: index+1 byExtendingSelection: NO];
	dontLoadSelectionSource = NO;
}

- (NSString*)  getLocalDCMPath: (NSManagedObject*) obj :(long) no
{
	if( isCurrentDatabaseBonjour) return [bonjourBrowser getDICOMFile: [bonjourServicesList selectedRow]-1 forObject: obj noOfImages: no];
	else return [obj valueForKey:@"completePath"];
}

- (void) setBonjourDownloading:(BOOL) v { bonjourDownloading = v;}


- (NSString*) defaultSharingName
{
	NSString *userName = (NSString*)CSCopyUserName(NO);
	NSMutableString *myServiceName = [[NSMutableString alloc] initWithString:userName];
	if([[[myServiceName substringFromIndex:[myServiceName length]-1] uppercaseString] isEqualToString:@"S"])
	{
		[myServiceName appendString:@"' OsiriX"];
	}
	else
	{
		[myServiceName appendString:@"'s OsiriX"];
	}

	return myServiceName;
}

- (void)setServiceName:(NSString*) title
{
	if( title && [title length] > 0)
		[bonjourPublisher setServiceName: title];
	else
	{
		[bonjourPublisher setServiceName: [self defaultSharingName]];
		[bonjourServiceName setStringValue: [self defaultSharingName]];
	}
}

- (IBAction)toggleBonjourSharing:(id) sender
{
	[self setBonjourSharingEnabled:([sender state] == NSOnState)];
}

- (void) setBonjourSharingEnabled:(BOOL) boo
{
	[self setServiceName: [bonjourServiceName stringValue]];
	[bonjourPublisher toggleSharing:boo];
}

- (void) bonjourWillPublish
{
	[bonjourServiceName setEnabled:NO];
}

- (void) bonjourDidStop
{
	[bonjourServiceName setEnabled:YES];
}

- (void) displayBonjourServices
{
	[bonjourServicesList reloadData];
}

- (void) resetToLocalDatabase
{
	[bonjourServicesList selectRow:0 byExtendingSelection:NO];
	[self bonjourServiceClicked: bonjourServicesList];
}

- (void) openDatabasePath: (NSString*) path
{
	BOOL isDirectory;
			
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory)
		{
			[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey:@"DATABASELOCATION"];
			[[NSUserDefaults standardUserDefaults] setObject: path forKey:@"DATABASELOCATIONURL"];
			
			[self openDatabaseIn: [documentsDirectory() stringByAppendingPathComponent:@"/Database.sql"] Bonjour: NO];
		}
		else
		{
			if( [currentDatabasePath isEqualToString: path] == NO)
			{
				[self openDatabaseIn: path Bonjour:NO];
			}
		}
	}
	else
	{
		NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot read this file/folder.", nil), nil, nil, nil);
		[self resetToLocalDatabase];
	}
}

- (IBAction) bonjourServiceClicked:(id)sender
{
    int index = [bonjourServicesList selectedRow]-1;
	
	[bonjourReportFilesToCheck removeAllObjects];
	
	if( index >= 0)
	{
		NSDictionary *object = [[bonjourBrowser services] objectAtIndex: index];
		
		// LOCAL PATH - DATABASE
		
		if( [[object valueForKey: @"type"] isEqualToString:@"localPath"])
		{
			[self openDatabasePath: [object valueForKey: @"Path"]];
		}
		else	// NETWORK - DATABASE - bonjour / fixedIP
		{
			WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Connecting to OsiriX database...", nil)];
			[wait showWindow:self];
			NSString	*path = [bonjourBrowser getDatabaseFile: index];
			[wait close];
			[wait release];
			
			if( path == 0L)
			{
				NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot connect to the database.", nil), nil, nil, nil);
				[bonjourServicesList selectRow: 0 byExtendingSelection:NO];
			}
			else
			{
				NSLog(@"Bonjour DB = %@", path);
				
				[segmentedAlbumButton setEnabled: NO];
				
				[self openDatabaseIn: path Bonjour: YES];
			}
		}
	}
	else // LOCAL DEFAULT DATABASE
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];

		NSString	*path = [documentsDirectory() stringByAppendingPathComponent:DATAFILEPATH];
		
		[segmentedAlbumButton setEnabled: YES];

		[self openDatabaseIn: path Bonjour: NO];
	}
}

- (NSString*) currentDatabasePath
{
	return currentDatabasePath;
}

- (NSString*) localDatabasePath
{
	return [documentsDirectory() stringByAppendingPathComponent:DATAFILEPATH];
}

- (NSBox*) bonjourSourcesBox
{
	return bonjourSourcesBox;
}

- (NSTextField*) bonjourServiceName
{
	return bonjourServiceName;
}

- (NSTextField*) bonjourPasswordTextField
{
	return bonjourPassword;
}

- (NSButton*) bonjourSharingCheck
{
	return bonjourSharingCheck;
}

- (NSButton*) bonjourPasswordCheck;
{
	return bonjourPasswordCheck;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Plugins

- (void)executeFilterFromString:( NSString*) name{
	long			result;
    id				filter = [plugins objectForKey:name];
	
		if(filter==nil)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
		return;
	}
	
	result = [filter prepareFilter: nil];
	[filter filterImage:name];
	NSLog(@"executeFilter %@", [filter description]);
	if( result)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
		return;
	}
}

- (void)executeFilterDB:(id)sender
{
	[self executeFilterFromString:[sender title]];
}

- (void) executeFilterFromToolbar:(id) sender
{
	[self executeFilterFromString:[sender label]];
}

- (void) setNetworkLogs
{
	isNetworkLogsActive = [[NSUserDefaults standardUserDefaults] boolForKey: @"NETWORKLOGS"];
}

- (BOOL) isNetworkLogsActive
{
	return isNetworkLogsActive;
}

- (NSString *) setFixedDocumentsDirectory
{
	[fixedDocumentsDirectory release];
	fixedDocumentsDirectory = [documentsDirectory() retain];
	
	strcpy( cfixedDocumentsDirectory, [fixedDocumentsDirectory UTF8String]);
	
	NSLog( @"setFixedDocumentsDirectory");
	return fixedDocumentsDirectory;
}

- (char *) cfixedDocumentsDirectory
{
	return cfixedDocumentsDirectory;
}

- (NSString *) fixedDocumentsDirectory
{
	if( fixedDocumentsDirectory == 0L) [self setFixedDocumentsDirectory];
	return fixedDocumentsDirectory;
}

- (NSString *) documentsDirectory
{
	NSString	*dir = documentsDirectory();
	
	return dir;
}

- (NSString *) documentsDirectoryFor:(int) mode url:(NSString*) url
{
	NSString	*dir = documentsDirectoryFor( mode, url);
	
	return dir;
}

- (IBAction)showLogWindow: (id)sender {
	    if(!logWindowController)
		logWindowController = [[LogWindowController alloc] init];
    [logWindowController showWindow:self];
}

- (NSString *)searchString{
	return _searchString;
}
- (void)setSearchString:(NSString *)searchString{
	[_searchString release];
	_searchString = [searchString retain];
	[self setFilterPredicate:[self createFilterPredicate] description:[self createFilterDescription]];
	[self outlineViewRefresh];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];

}

- (IBAction) searchForCurrentPatient:(id) sender
{
	if( [databaseOutline selectedRow])
	{
		NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
		if( aFile)
		{
			if([[aFile valueForKey:@"type"] isEqualToString:@"Study"])
				[self setSearchString: [aFile valueForKey:@"name"]];
			else
				[self setSearchString: [aFile valueForKeyPath:@"study.name"]];
		}
	}
}

- (NSPredicate*)fetchPredicate{
	return _fetchPredicate;
}

- (void)setFetchPredicate:(NSPredicate *)predicate{
	[_fetchPredicate release];
	_fetchPredicate = [predicate retain];
}

- (NSPredicate*)filterPredicate{
	return _filterPredicate;
}

- (NSString*) filterPredicateDescription
{
	return _filterPredicateDescription;
}

- (void)setFilterPredicate:(NSPredicate *)predicate description:(NSString*) desc{
	//NSLog(@"set Filter Predicate");
	[_filterPredicate release];
	_filterPredicate = [predicate retain];
	
	[_filterPredicateDescription release];
	_filterPredicateDescription = [desc retain];
}

- (NSString *)createFilterDescription{
	NSString *description = nil;
	
	if ([_searchString length] > 0)
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
				
				case 100:			// Advanced
				break;
			}
			
		}
	return description;
}

- (NSPredicate *)createFilterPredicate{
	NSPredicate *predicate = nil;
	NSString *description = nil;
	NSString	*s;
	
	if ([_searchString length] > 0)
		{
			switch(searchType)
			{
				case 7:			// All Fields
					s = [NSString stringWithFormat:@"*%@*", _searchString];
					
					predicate = [NSPredicate predicateWithFormat: @"(name LIKE[cd] %@) OR (patientID LIKE[cd] %@) OR (id LIKE[cd] %@) OR (comment LIKE[cd] %@) OR (studyName LIKE[cd] %@) OR (modality LIKE[cd] %@) OR (accessionNumber LIKE[cd] %@)", s, s, s, s, s, s, s];
				break;
				
				case 0:			// Patient Name
					predicate = [NSPredicate predicateWithFormat: @"name LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 1:			// Patient ID
					predicate = [NSPredicate predicateWithFormat: @"patientID LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 2:			// Study/Series ID
					predicate = [NSPredicate predicateWithFormat: @"id LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 3:			// Comments
					predicate = [NSPredicate predicateWithFormat: @"comment LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 4:			// Study Description
					predicate = [NSPredicate predicateWithFormat: @"studyName LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 5:			// Modality
					predicate = [NSPredicate predicateWithFormat:  @"modality LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 6:			// Accession Number 
					predicate = [NSPredicate predicateWithFormat:  @"accessionNumber LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 100:			// Advanced
					
				break;
			}
			
		}
	return predicate;
}

- (NSArray *) databaseSelection{
	long				index;
	NSMutableArray		*selectedItems			= [NSMutableArray arrayWithCapacity: 0];
	NSIndexSet			*selectedRowIndexes		= [databaseOutline selectedRowIndexes];
	
	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
       if ([selectedRowIndexes containsIndex:index])
	   {
			[selectedItems addObject: [databaseOutline itemAtRow:index]];
	   }
	}
	return selectedItems;
}

//Comparisons
// Finding Comparisons
- (NSArray *)relatedStudiesForStudy:(id)study
{
	NSManagedObjectModel	*model = [self managedObjectModel];
	NSManagedObjectContext	*context = [self managedObjectContext];
	
	// FIND ALL STUDIES of this patient
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientID == %@)", [study valueForKey:@"patientID"]];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: predicate];
	
	[context retain];
	[context lock];
	
	NSError	*error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
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
	
	[context unlock];
	[context release];
	
	return studiesArray;
}


@end
