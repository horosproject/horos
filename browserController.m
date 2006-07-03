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

*/

#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "AnonymizerWindowController.h"
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
#import "DCMStoreSCU.h"
#import "SmartWindowController.h"
#import "QueryFilter.h"
#import "ImageAndTextCell.h"
#import "SearchWindowController.h"
#import "xNSImage.h"
#import "Wait.h"
#import "WaitRendering.h"
#import "DCMCalendarScript.h"
#import "DotMacKit/DotMacKit.h"
#import "BurnerWindowController.h"
#import "DCMObject.h"
#import "DCMTransferSyntax.h"
#import "DCMAttributeTag.h"
#import "DCMPixelDataAttribute.h"
#import "DCMCalendarDate.h"
#import <OsiriX/DCMTransferSyntax.h>
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMDirectory.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMDirectory.h>
#import <OsiriX/DCMNetServiceDelegate.h>
#import "NetworkSendDataHandler.h"
#import "LogWindowController.h"
#import "stringNumericCompare.h"
#import "SendController.h"
#import "Reports.h"
#import "LogManager.h"
#import "DCMTKStoreSCU.h"

#import "BonjourPublisher.h"
#import "BonjourBrowser.h"

#import "StructuredReportController.h"



#define DATABASEVERSION @"2.1"

#define DATABASEPATH @"/DATABASE/"
#define DATABASEFPATH @"/DATABASE"
#define DATAFILEPATH @"/Database.sql"
#define INCOMINGPATH @"/INCOMING/"
#define ERRPATH @"/NOT READABLE/"

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
extern BOOL						NEEDTOREBUILD;
extern NSMutableDictionary		*DATABASECOLUMNS;
extern NSLock					*PapyrusLock;


NSString	*iPodDirectory = 0L;
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

@interface BrowserController (private)

- (NSString*) _findFirstDicomdirOnCDMedia: (NSString*)startDirectory found:(BOOL) found;


@end

@implementation BrowserController

static NSString* 	DatabaseToolbarIdentifier			= @"DicomDatabase Toolbar Identifier";
static NSString*	ImportToolbarItemIdentifier			= @"Import.icns";
static NSString*	iPodToolbarItemIdentifier			= @"iPod.icns";
static NSString*	iDiskSendToolbarItemIdentifier		= @"iDiskSend.icns";
static NSString*	iDiskGetToolbarItemIdentifier		= @"iDiskGet.icns";
static NSString*	ExportToolbarItemIdentifier			= @"Export.icns";
static NSString*	AnonymizerToolbarItemIdentifier		= @"Anonymizer.icns";
static NSString*	QueryToolbarItemIdentifier			= @"QueryRetrieve.icns";
static NSString*	SendToolbarItemIdentifier			= @"Send.icns";
static NSString*	PrintToolbarItemIdentifier			= @"Print.icns";
static NSString*	ViewerToolbarItemIdentifier			= @"Viewer.icns";
static NSString*	CDRomToolbarItemIdentifier			= @"CDRom.icns";
static NSString*	MovieToolbarItemIdentifier			= @"Movie.icns";
static NSString*	TrashToolbarItemIdentifier			= @"trash.icns";
static NSString*	ReportToolbarItemIdentifier			= @"Report.icns";
static NSString*	BurnerToolbarItemIdentifier			= @"Burner.tif";
static NSString*	ToggleDrawerToolbarItemIdentifier   = @"StartupDisk.tiff";
static NSString*	SearchToolbarItemIdentifier			= @"Search";
static NSString*	TimeIntervalToolbarItemIdentifier	= @"TimeInterval";
static NSString*	DatabaseWindowToolbarItemIdentifier = @"DatabaseWindow.icns";


static BOOL			DICOMDIRCDMODE = NO;
//static NSArray*		tableColumns = 0L;

		NSArray*	statesArray = 0L;


static BOOL COMPLETEREBUILD = NO;

+ (BrowserController*) currentBrowser { return browserWindow;}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Add DICOM Database functions


- (NSString*) getNewFileDatabasePath: (NSString*) extension
{
	NSString        *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
	NSString		*dstPath;
	NSString		*subFolder;
	long			subFolderInt;

	do
	{
		
		subFolderInt = 10000L * ((DATABASEINDEX / 10000L) +1);
		
		if (![extension caseInsensitiveCompare:@"tif"] || ![extension caseInsensitiveCompare:@"tiff"])
			subFolder = [NSString stringWithFormat:@"%@TIF", OUTpath];
		else
			subFolder = [NSString stringWithFormat:@"%@%d", OUTpath, subFolderInt];

		if (![[NSFileManager defaultManager] fileExistsAtPath:subFolder])
			[[NSFileManager defaultManager] createDirectoryAtPath:subFolder attributes:nil];
		
		dstPath = [NSString stringWithFormat:@"%@/%d.%@", subFolder, DATABASEINDEX, extension];
		
		DATABASEINDEX++;
	}
	while ([[NSFileManager defaultManager] fileExistsAtPath: dstPath]);
	
	return dstPath;
}

- (void) reloadViewers: (NSMutableArray*) viewersListToReload
{
	long i;
	
	// Reload series if needed
	for( i = 0; i < [viewersListToReload count]; i++)
	{
		[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [[[[viewersListToReload objectAtIndex: i] fileList] objectAtIndex: 0] valueForKey:@"series"]]] movie: NO viewer :[viewersListToReload objectAtIndex: i] keyImagesOnly: NO];
	}
	
	if( queryController) [queryController refresh: self];

}

- (void) rebuildViewers: (NSMutableArray*) viewersListToRebuild
{
	long i;
	
	// Refresh preview matrix if needed
	for( i = 0; i < [viewersListToRebuild count]; i++)
	{
		[[viewersListToRebuild objectAtIndex: i] buildMatrixPreview];
		[[viewersListToRebuild objectAtIndex: i] matrixPreviewSelectCurrentSeries];
	}
}

- (void) callAddFilesToDatabaseSafe: (NSArray*) newFilesArray
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSString			*tempDirectory = [documentsDirectory() stringByAppendingString:@"/TEMP/"];
	NSString			*arrayFile = [tempDirectory stringByAppendingPathComponent:@"array.plist"];
	NSString			*databaseFile = [tempDirectory stringByAppendingPathComponent:@"database.plist"];
	NSString			*modelFile = [tempDirectory stringByAppendingPathComponent:@"model.plist"];
	
	[fm removeFileAtPath:arrayFile handler:0L];
	[fm removeFileAtPath:databaseFile handler:0L];
	[fm removeFileAtPath:modelFile handler:0L];
	
	[newFilesArray writeToFile:arrayFile atomically: YES];
	[[documentsDirectory() stringByAppendingString:DATABASEFPATH] writeToFile:databaseFile atomically: YES];
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/OsiriXDB_DataModel.mom"] writeToFile:modelFile atomically: YES];
    [allBundles release];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setCurrentDirectoryPath: tempDirectory];
	[theTask setArguments: [NSArray arrayWithObjects:arrayFile, databaseFile, modelFile, 0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/SafeDBRebuild"]];
	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
	
	[fm removeFileAtPath:arrayFile handler:0L];
	[fm removeFileAtPath:databaseFile handler:0L];
	[fm removeFileAtPath:modelFile handler:0L];
	
	[pool release];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles
{
	if( isCurrentDatabaseBonjour) return 0L;
	NSEnumerator			*enumerator = [newFilesArray objectEnumerator];
	NSString				*newFile;
	NSDate					*today = [NSDate date];
	NSError					*error = 0L;
	NSString				*curPatientUID = 0L, *curStudyID = 0L, *curSerieID = 0L;
	NSManagedObject			*image, *seriesTable, *study, *album;
	long					ii, i, x;
	unsigned				index;
	NSString				*INpath = [documentsDirectory() stringByAppendingString:DATABASEFPATH];
	Wait					*splash = 0L;
	NSManagedObjectModel	*model = [self managedObjectModel];
	NSManagedObjectContext	*context = [self managedObjectContext];
	NSMutableArray			*viewersList = [NSMutableArray arrayWithCapacity:0], *viewersListToRebuild = [NSMutableArray arrayWithCapacity:0], *viewersListToReload = [NSMutableArray arrayWithCapacity:0];
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*addedImagesArray = 0L;
	NSMutableArray			*modifiedStudiesArray = 0L;
	long					addFailed = NO;
	BOOL					COMMENTSAUTOFILL = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"];
	
	[incomingProgress performSelectorOnMainThread:@selector( startAnimation:) withObject:self waitUntilDone:NO];
	
	if( safeProcess)
	{
		NSLog( @"safe Process DB process");
	}
	
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
	}
	
	if( [newFilesArray count] > 50 && mainThread == [NSThread currentThread])
	{
		splash = [[Wait alloc] initWithString: [NSString stringWithFormat: NSLocalizedString(@"Adding %@ files...", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt:[newFilesArray count]]]]];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[newFilesArray count]/30];
	}
	
	ii = 0;
	[context lock];
	
	[context setStalenessInterval: 120];
	
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
		NSLog(@"exception: %@", [ne description]);
		NSLog(@"executeFetchRequest failed for studiesArray.");
		error = [NSError errorWithDomain:@"OsiriXDomain" code:1 userInfo: 0L];
	}
	if (error)
	{
		NSLog( @"addFilesToDatabase ERROR: %@", [error localizedDescription]);
		managedObjectContext = 0L;
		[context setStalenessInterval: 1200];
		[context unlock];
		
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
				
				curFile = [[DicomFile alloc] init: newFile];
				
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
					if( [[curDict objectForKey: @"fileType"] isEqualToString:@"DICOM"] == NO)
					{
						[curDict release];
						curDict = 0L;
					}
				}
				
				if( splash)
				{
					if( (ii++) % 30 == 0) [splash incrementBy:1];
					
					if( ii % 50000 == 0)
					{
						[self saveDatabase:currentDatabasePath];
					}
				}
				
				if( curDict != 0L)
				{
//					if( 0)
					{
						if( [[curDict objectForKey: @"studyID"] isEqualToString: curStudyID] == YES && [[curDict objectForKey: @"patientUID"] isEqualToString: curPatientUID] == YES)
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
								[study setValue:today forKey:@"dateAdded"];
							
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
								
								NSArray	*newStudiesArray = [studiesArray arrayByAddingObject: study];
								[studiesArray release];
								studiesArray = [newStudiesArray retain];
								
								[curSerieID release];	curSerieID = 0L;
								
							}
							else
							{
								study = [studiesArray objectAtIndex: index];
								[study setValue:today forKey:@"dateAdded"];
							}
							
							
							// For each new image in a pre-existing study, check if a viewer is already opened -> refresh the preview list
							for( x = 0; x < [viewersList count]; x++)
							{
								if( [[curDict objectForKey: @"patientUID"] isEqualToString: [[[[viewersList objectAtIndex: x] fileList] objectAtIndex: 0] valueForKeyPath:@"series.study.patientUID"]])
								{
									if( [viewersListToRebuild containsObject:[viewersList objectAtIndex: x]] == NO)
										[viewersListToRebuild addObject: [viewersList objectAtIndex: x]];
								}
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
								}
								else
								{
									seriesTable = [seriesArray objectAtIndex: index];
									[seriesTable setValue:today forKey:@"dateAdded"];
									
									// For each new image in a pre-existing series, check if a viewer is already opened -> reload the series
									for( x = 0; x < [viewersList count]; x++)
									{
										if( seriesTable == [[[[viewersList objectAtIndex: x] fileList] objectAtIndex: 0] valueForKey:@"series"]) [viewersListToReload addObject: [viewersList objectAtIndex: x]];
									}
								}
								
								[curSerieID release];
								curSerieID = [[curDict objectForKey: @"seriesID"] retain];
							}
							
							/*******************************************/
							/*********** Find image object *************/
							
							BOOL			iPod = NO, local = NO;
							if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
							{
								local = YES;
							}
							else
							{
								if( iPodDirectory)
								{
									if( [iPodDirectory length] < [newFile length])
									{
										if( [iPodDirectory isEqualToString:[newFile substringToIndex:[iPodDirectory length]]] == YES) iPod = YES;
									}
								}
							}
							
							NSArray		*imagesArray = [[seriesTable valueForKey:@"images"] allObjects] ;
							
							index = [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curDict objectForKey: [@"SOPUID" stringByAppendingString:SeriesNum]]];
							if( index == NSNotFound)
							{
								image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:context];
								[image setValue:[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] forKey:@"instanceNumber"];
								[image setValue:[[curDict objectForKey: [@"imageID" stringByAppendingString:SeriesNum]] stringValue] forKey:@"name"];
								[image setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								
								if( local) [image setValue: [newFile lastPathComponent] forKey:@"path"];
								else [image setValue:newFile forKey:@"path"];
								
								[image setValue:[NSNumber numberWithBool:iPod] forKey:@"iPod"];
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
							else
							{
								image = [imagesArray objectAtIndex: index];
								
								if( produceAddedFiles)
									[addedImagesArray addObject: image];
									
								if( local)	// Delete this file, it's already in the DB folder
								{
									if( [[image valueForKey:@"path"] isEqualToString: [newFile lastPathComponent]] == NO)
										[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
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
				NSLog(@"exception: %@", [ne description]);
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
		
		[context setStalenessInterval: 1200];
		[context unlock];
		
		if( addFailed == NO)
		{
			[self performSelectorOnMainThread:@selector( outlineViewRefresh) withObject:0L waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector( reloadViewers:) withObject:viewersListToReload waitUntilDone:YES];
			[self performSelectorOnMainThread:@selector( rebuildViewers:) withObject:viewersListToRebuild waitUntilDone:YES];
			
			databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
		}
	}
	
	[incomingProgress performSelectorOnMainThread:@selector( stopAnimation:) withObject:self waitUntilDone:NO];
	
	if( addFailed)
	{
		NSLog(@"adding failed....");
		
		return 0L;
	}
	
	return addedImagesArray;
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray :(BOOL) onlyDICOM
{
	return [self addFilesToDatabase: newFilesArray onlyDICOM:onlyDICOM safeRebuild:NO produceAddedFiles :YES];
}

-(NSArray*) addFilesToDatabase:(NSArray*) newFilesArray
{
	return [self addFilesToDatabase: newFilesArray onlyDICOM:NO safeRebuild:NO produceAddedFiles :YES];
}

- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames
{
    NSFileManager       *defaultManager = [NSFileManager defaultManager];
	NSMutableArray		*filesArray;
	long				i;
	BOOL				isDirectory = NO;
	
	filesArray = [[NSMutableArray alloc] initWithCapacity:0];
	
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
	
	filesArray = [self copyFilesIntoDatabaseIfNeeded:filesArray];
	
	NSLog(@"Start Database");
	NSArray	*newImages = [self addFilesToDatabase: filesArray];
	NSLog(@"End Database");
	
	[filesArray release];
	[self outlineViewRefresh];
	
	return newImages;
}

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
    
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/OsiriXDB_DataModel.mom"]]];
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
	
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	

    NSURL *url = [NSURL fileURLWithPath: currentDatabasePath];

	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{	// NSSQLiteStoreType - NSXMLStoreType
      localizedDescription = [error localizedDescription];
		error = [NSError errorWithDomain:@"OsiriXDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, NSUnderlyingErrorKey, [NSString stringWithFormat:@"Store Configuration Failure: %@", ((localizedDescription != nil) ? localizedDescription : @"Unknown Error")], NSLocalizedDescriptionKey, nil]];
    }
	
	[coordinator release];
	
	[managedObjectContext setStalenessInterval: 1200];
	
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
	[self addFilesAndFolderToDatabase: localFiles];
	
	return localFiles;
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

- (void) bonjourRunLoop:(id) sender
{
	[[NSRunLoop currentRunLoop] runMode:@"OsiriXLoopMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

-(void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour
{
	if( isCurrentDatabaseBonjour == NO)
		[self saveDatabase: currentDatabasePath];
		
	[currentDatabasePath release];
	currentDatabasePath = [a retain];
	isCurrentDatabaseBonjour = isBonjour;
	[self loadDatabase: currentDatabasePath];
	
	if( isCurrentDatabaseBonjour)
	{
		bonjourRunLoopTimer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(bonjourRunLoop:) userInfo:self repeats:YES] retain];;
	}
	else
	{
		[bonjourRunLoopTimer release];
		bonjourRunLoopTimer = 0L;
	}
	
	[self setFixedDocumentsDirectory];
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
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];

	[sPanel setRequiredFileType:@"sql"];
	
	if ([sPanel runModalForDirectory:documentsDirectory() file:NSLocalizedString(@"Database.sql", nil)] == NSFileHandlingPanelOKButton)
	{
		if( [currentDatabasePath isEqualToString: [sPanel filename]] == NO && [sPanel filename] != 0L)
		{
			[self saveDatabase: currentDatabasePath];
			
			[currentDatabasePath release];
			currentDatabasePath = [[sPanel filename] retain];
			
			[self loadDatabase: currentDatabasePath];
			[self saveDatabase: currentDatabasePath];
		}
	}
}

- (void) updateDatabaseModel: (NSString*) path :(NSString*) DBVersion
{
	NSString	*model = [NSString stringWithFormat:@"/OsiriXDB_Previous_DataModel%@.mom", DBVersion];

	if( [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString: model]] )
	{
		Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Updating database model...", nil)];
		[splash showWindow:self];
	
		long							x, z, xx, zz, yy;
		NSError							*error = nil;
		NSManagedObjectModel			*previousModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString: model]]];
		NSManagedObjectModel			*currentModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/OsiriXDB_DataModel.mom"]]];
		NSPersistentStoreCoordinator	*previousSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: previousModel];
		NSPersistentStoreCoordinator	*currentSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: currentModel];
		NSManagedObjectContext			*currentContext = [[NSManagedObjectContext alloc] init];
		NSManagedObjectContext			*previousContext = [[NSManagedObjectContext alloc] init];
		
		[currentContext setPersistentStoreCoordinator: currentSC];
		[previousContext setPersistentStoreCoordinator: previousSC];
		
		[previousSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: currentDatabasePath] options:nil error:&error];
		[currentSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: [documentsDirectory() stringByAppendingString:@"/Database3.sql"]] options:nil error:&error];
		
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
		[[NSFileManager defaultManager] movePath:[documentsDirectory() stringByAppendingString:@"/Database3.sql"] toPath:currentDatabasePath handler:nil];
		
		[previousModel release];
		[currentModel release];
		[previousSC release];
		[currentSC release];
		[currentContext release];
		[previousContext release];
		
		[splash close];
		[splash release];
	}
	else
	{
		NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot understand the model of current saved database... The database will be deleted (no images are lost).", nil), nil, nil, nil);
		[[NSFileManager defaultManager] removeFileAtPath:currentDatabasePath handler:nil];
		NEEDTOREBUILD = YES;
		COMPLETEREBUILD = YES;
	}
}

-(void) loadDatabase:(NSString*) path
{
	long        i;

	if( threadRunning)
	{
		shouldDie = YES;
		while (threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
		shouldDie = NO;
	}
	
	[albumTable selectRow:0 byExtendingSelection:NO];
	
	NSString	*DBVersion;
	
	DBVersion = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"]];
	
	if( DBVersion == 0L) 
		DBVersion = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
	
	if( DBVersion == 0L) 
		DBVersion = [NSString stringWithString:@"1.1"];
	
	NSLog(@"Opening DB: %@ Version: %@", path, DBVersion);
	
	if( [DBVersion isEqualToString: DATABASEVERSION] == NO )
	{
		[self updateDatabaseModel: path :DBVersion];
	}
	
	[managedObjectContext lock];
	[managedObjectContext unlock];
	[managedObjectContext release];
	managedObjectContext = 0L;
	[self managedObjectContext];

	// CHECK IF A DICOMDIR FILE IS AVAILABLE AT SAME LEVEL AS OSIRIX!?
	NSString	*dicomdir = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingString:@"/DICOMDIR"];
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
			NEEDTOREBUILD = NO;
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
	
	if( isCurrentDatabaseBonjour) [[self window] setTitle: [NSString stringWithFormat: NSLocalizedString(@"Bonjour Database (%@)", nil), [path lastPathComponent]]];
	else [[self window] setTitle: [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), path]];
	[[self window] setRepresentedFilename: path];
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
			
			[context lock];
			
			[context save: &error];
			if (error)
			{
				NSLog(@"error saving DB: %@", [[error userInfo] description]);
				NSLog( @"saveDatabase ERROR: %@", [error localizedDescription]);
				retError = -1L;
			}
			[context unlock];
			
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


-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput
{
	if ([ filesInput count] == 0) return filesInput;
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"COPYDATABASE"] == NO) return filesInput;
	
	NSMutableArray			*newList = [NSMutableArray arrayWithCapacity: [filesInput count]];
	NSString				*INpath = [documentsDirectory() stringByAppendingString:DATABASEFPATH];
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
			
			if( [self isItCD:pathFilesComponent] == NO) return filesInput;
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

    NSString        *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
	BOOL			isDir = YES;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
	
	NSString        *pathname;
    NSMutableArray  *filesOutput = [[NSMutableArray alloc] initWithCapacity:0];
	
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
	
	[filesInput release];
	return filesOutput;
}

- (IBAction) endReBuildDatabase:(id) sender
{
	[NSApp endSheet: rebuildWindow];
	[rebuildWindow orderOut: self];
	
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
	
	BOOL REBUILDEXTERNALPROCESS = YES;
	
	if( COMPLETEREBUILD)	// Delete the database file
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath])
		{
			[[NSFileManager defaultManager] removeFileAtPath: currentDatabasePath handler: 0L];
		}

	}
	else
	{
		[self saveDatabase:currentDatabasePath];
	}

		
	[managedObjectContext release];
	managedObjectContext = 0L;
	
	[databaseOutline reloadData];
	
	NSMutableArray				*filesArray;
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Step 1: Checking files...", nil)];
	[wait showWindow:self];
	
	filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
			
	// SCAN THE DATABASE FOLDER, TO BE SURE WE HAVE EVERYTHING!
	
	NSString	*aPath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
	BOOL		isDir = YES;
	long		totalFiles = 0;
	if (![[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:aPath attributes:nil];
	
	// In the DATABASE FOLDER, we have only folders! Delete all files that are wrongly there.... and then scan these folders containing the DICOM files
	
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for( i = 0; i < [dirContent count]; i++)
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]];
		id fileType = [[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: NO] objectForKey:NSFileType];
		if ([fileType isEqual:NSFileTypeRegular])
		{
			[[NSFileManager defaultManager] removeFileAtPath:itemPath handler: 0L];
		}
		
		totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: NO] objectForKey: NSFileReferenceCount] intValue];
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
			
			[REBUILDEXTERNALPROCESSProgress incrementBy: [[[[NSFileManager defaultManager] fileAttributesAtPath: curDir traverseLink: NO] objectForKey: NSFileReferenceCount] intValue]];
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
	
	[self outlineViewRefresh];
	[splash close];
	[splash release];
	
	[context unlock];
}

- (IBAction) ReBuildDatabaseSheet: (id)sender
{
	if( isCurrentDatabaseBonjour)
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Database Cleaning", 0L), NSLocalizedString(@"Cannot rebuild a distant database.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
		return;
	}

	long i;
	long totalFiles = 0;
	NSString	*aPath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for( i = 0; i < [dirContent count]; i++)
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: [dirContent objectAtIndex: i]];
		totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: NO] objectForKey: NSFileReferenceCount] intValue];
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
	
	// Logs cleaning
	
	if( [checkIncomingLock tryLock])
	{
		NSError					*error = 0L;
		long					i;
		NSFetchRequest			*request = [[[NSFetchRequest alloc] init] autorelease];
		NSArray					*logArray;
		NSDate					*producedDate = [[NSDate date] addTimeInterval: -[defaults integerForKey:@"LOGCLEANINGDAYS"]*60*60*24];
		NSManagedObjectContext	*context = [self managedObjectContext];
		NSPredicate				*predicate = [NSPredicate predicateWithFormat: @"startTime <= CAST(%f, \"NSDate\")", [producedDate timeIntervalSinceReferenceDate]];
		
		[request setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"LogEntry"]];
		[request setPredicate: predicate];
		
		[context lock];
		error = 0L;
		logArray = [context executeFetchRequest:request error:&error];
		
		for( i = 0; i < [logArray count]; i++)
			[context deleteObject: [logArray objectAtIndex: i]];
		
		[context unlock];
		
		[checkIncomingLock unlock];
	}
	
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
				
				[context lock];
				error = 0L;
				studiesArray = [context executeFetchRequest:request error:&error];
				
				NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"patientUID" ascending:YES];
				NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
				[sort release];
				
				for( i = 0; i < [studiesArray count]; i++)
				{
					NSString	*patientUID = [[studiesArray objectAtIndex: i] valueForKey:@"patientUID"];
					NSDate		*studyDate = [[studiesArray objectAtIndex: i] valueForKey:@"date"];
					NSDate		*openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
					
					if( openedStudyDate == 0L) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
					long		to, from = i;
					
					while( i < [studiesArray count]-1 && [patientUID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientUID"]] == YES)
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
				
				for (i = 0; i<[toBeRemoved count];i++)					// Check if studies are in an album or added today.  If so don't autoclean that study from the database (DDP: 051108).
				{
					if ( [[[toBeRemoved objectAtIndex: i] valueForKey: @"albums"] count] > 0 ||
					  [[[toBeRemoved objectAtIndex: i] valueForKey: @"dateAdded"] timeIntervalSinceNow] > -60*60*24.0 )  // within 24 hours
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
					if( threadWillRunning == YES) while( threadWillRunning == YES) {[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];}
					if( threadRunning)
					{
						shouldDie = YES;
						while (threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
						shouldDie = NO;
					}
					
					NSLog(@"Will delete: %d studies", [toBeRemoved count]);
					
					Wait *wait = [[Wait alloc] initWithString: NSLocalizedString(@"Database Auto-Cleaning...", nil)];
					[wait showWindow:self];
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
					}
					
					[self saveDatabase: currentDatabasePath];
					
					[self outlineViewRefresh];
					
					[wait close];
					[wait release];
				}
				
				[context unlock];
				
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
		
		free /= 1024;
		free /= 1024;
		
 		NSLog(@"HD Free Space: %d MB", (long) free);
		
		if( (long) free < [[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue])
		{
			NSError				*error = 0L;
			long				i, x;
			NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
			NSPredicate			*predicate = [NSPredicate predicateWithValue:YES];
			NSArray				*studiesArray;
			NSManagedObjectContext *context = [self managedObjectContext];
			
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
				
				NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"patientUID" ascending:YES];
				NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
				[sort release];
				
				for( i = 0; i < [studiesArray count]; i++)
				{
					NSString	*patientUID = [[studiesArray objectAtIndex: i] valueForKey:@"patientUID"];
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
					
					while( i < [studiesArray count]-1 && [patientUID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientUID"]] == YES)
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
				
				if( [defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"])
				{
					[context deleteObject: oldestStudy];
				}
				
				if( [defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"])
				{
					if( oldestOpenedStudy) [context deleteObject: oldestOpenedStudy];
				}
				
				fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath: currentDatabasePath];
				
				free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
				free /= 1024;
				free /= 1024;
				NSLog(@"HD Free Space: %d MB", (long) free);
			}
			while( (long) free < [[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue] && [studiesArray count] > 0);
			
			[self saveDatabase: currentDatabasePath];
			
			[self outlineViewRefresh];
			
			[context unlock];
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
	
	[[[sender menu] itemAtIndex: [sender tag]] setState: NSOnState];
	[toolbarSearchItem setLabel: [NSString stringWithFormat: NSLocalizedString(@"Search by %@", nil), [sender title]]];
	searchType = [sender tag];
	//create new Filter Predicate when changing searchType ans set searchString to nil;
	[self setSearchString:nil];
	//[self setFilterPredicate:[self createFilterPredicate]];
	[self outlineViewRefresh];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (IBAction) customIntervalNow:(id) sender
{
	if( [sender tag] == 0)
	{
		[customStart setDateValue: [NSDate date]];
		[customStart2 setDateValue: [NSDate date]];
	}
	
	if( [sender tag] == 1)
	{
		[customEnd setDateValue: [NSDate date]];
		[customEnd2 setDateValue: [NSDate date]];
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

- (NSPredicate*) smartAlbumPredicate:(NSManagedObject*) album
{
	NSMutableString		*pred = [NSMutableString stringWithString: [album valueForKey:@"predicateString"]];
	
	// DATES
	
	// Today:
	NSCalendarDate	*now = [NSCalendarDate calendarDate];
	NSCalendarDate	*start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
	NSDate			*today = [NSDate dateWithTimeIntervalSinceNow: [start timeIntervalSinceDate: now]];
	
//	NSLog( pred);

	NSDictionary	*sub = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithFormat:@"%f", [[now addTimeInterval: -60*60*1] timeIntervalSinceReferenceDate]],			@"$LASTHOUR",
																		[NSString stringWithFormat:@"%f", [[now addTimeInterval: -60*60*6] timeIntervalSinceReferenceDate]],			@"$LAST6HOURS",
																		[NSString stringWithFormat:@"%f", [[now addTimeInterval: -60*60*12] timeIntervalSinceReferenceDate]],			@"$LAST12HOURS",
																		[NSString stringWithFormat:@"%f", [today timeIntervalSinceReferenceDate]],										@"$TODAY",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24] timeIntervalSinceReferenceDate]],			@"$YESTERDAY",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*2] timeIntervalSinceReferenceDate]],		@"$2DAYS",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*7] timeIntervalSinceReferenceDate]],		@"$WEEK",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*31] timeIntervalSinceReferenceDate]],		@"$MONTH",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*31*2] timeIntervalSinceReferenceDate]],	@"$2MONTHS",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*31*3] timeIntervalSinceReferenceDate]],	@"$3MONTHS",
																		[NSString stringWithFormat:@"%f", [[today addTimeInterval: -60*60*24*365] timeIntervalSinceReferenceDate]],		@"$YEAR",
																		0L];
	
	NSEnumerator *enumerator = [sub keyEnumerator];
	NSString *key;
			
	while ((key = [enumerator nextObject]))
	{
		[pred replaceOccurrencesOfString:key withString: [sub valueForKey: key]	options: NSCaseInsensitiveSearch	range: NSMakeRange(0, [pred length])];
	}
	
	NSPredicate *predicate;
	
	@try
	{
		predicate = [NSPredicate predicateWithFormat: pred];
	}
	
	@catch( NSException *ne)
	{
		predicate = [NSPredicate predicateWithValue: NO];
	}
	
	return predicate;
}

- (void) outlineViewRefresh		// This function creates the 'root' array for the outlineView
{
	NSError				*error = 0L;
	long				i;
	NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
	NSPredicate			*predicate = 0L, *subPredicate = 0L;
	NSString			*description = [NSString string];
	NSIndexSet			*selectedRowIndexes =  [databaseOutline selectedRowIndexes];
	NSMutableArray		*previousObjects = [NSMutableArray arrayWithCapacity:0];
	BOOL				filtered = NO;
	
	unsigned index = [selectedRowIndexes firstIndex];
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
		
		if( rowIndex <= [bonjourBrowser BonjourServices]) description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [[[bonjourBrowser services] objectAtIndex: rowIndex-1] name]];
		else description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [[[bonjourBrowser services] objectAtIndex: rowIndex-1] valueForKey:@"Description"]];
		
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
		}
		else
		{
			subPredicate = [NSPredicate predicateWithFormat: @"ANY albums.name == %@", albumName];
			description = [description stringByAppendingFormat:NSLocalizedString(@"Album selected: %@", nil), albumName];
		}
		
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, 0L]];
		filtered = YES;
	}
	else description = [description stringByAppendingFormat:NSLocalizedString(@"No album selected", nil)];
	
	// ********************
	// TIME INTERVAL
	// ********************
	
	[self computeTimeInterval];
	
	if( timeIntervalStart != 0L || timeIntervalEnd != 0L)
	{
		NSString*		sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortTimeDateFormatString];	//stringByAppendingFormat:@"-%H:%M"];
		NSDictionary*	locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
		
		if( timeIntervalStart != 0L && timeIntervalEnd != 0L)
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%f, \"NSDate\") AND date <= CAST(%f, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate]];
		
			description = [description stringByAppendingFormat: NSLocalizedString(@" / Time Interval: from: %@ to: %@", nil), [timeIntervalStart descriptionWithCalendarFormat:sdf timeZone:0L locale:locale],  [timeIntervalEnd descriptionWithCalendarFormat:sdf timeZone:0L locale:locale] ];
		}
		else
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%f, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat:NSLocalizedString(@" / Time Interval: since: %@", nil), [timeIntervalStart descriptionWithCalendarFormat:sdf timeZone:0L locale:locale]];
		}
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, 0L]];
		filtered = YES;
	}
	
	// ********************
	// SEARCH FIELD
	// ********************

	//if ([_searchString length] > 0)
	if ([self filterPredicate])
	{
	/*
		switch( searchType)
		{
			case 0:			// Patient Name
				// ANY studies.name LIKE[c] "**" AND name == ""
				subPredicate = [NSPredicate predicateWithFormat: @"name LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat: NSLocalizedString(@" / Search: Patient's name = %@", nil), _searchString];
			break;
			
			case 1:			// Patient ID
				subPredicate = [NSPredicate predicateWithFormat: @"patientID LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat:@" / Search: Patient's ID = %@", _searchString];
			break;
			
			case 2:			// Study/Series ID
				subPredicate = [NSPredicate predicateWithFormat: @"id LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat:@" / Search: Study's ID = %@", _searchString];
			break;
			
			case 3:			// Comments
				subPredicate = [NSPredicate predicateWithFormat: @"comment LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat: NSLocalizedString(@" / Search: Comments = %@", nil), _searchString];
			break;
			
			case 4:			// Study Description
				subPredicate = [NSPredicate predicateWithFormat: @"studyName LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat: NSLocalizedString(@" / Search: Study Description = %@", nil), _searchString];
			break;
			
			case 5:			// Modality
				subPredicate = [NSPredicate predicateWithFormat:  @"modality LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				
				description = [description stringByAppendingFormat: NSLocalizedString(@" / Search: Modality = %@", nil), _searchString];
			break;
			
			case 6:			// Accession Number 
				subPredicate = [NSPredicate predicateWithFormat:  @"accessionNumber LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				description = [description stringByAppendingFormat: NSLocalizedString(@" / Search: Accession Number = %@", nil), _searchString];
			break;
			
			case 100:			// Advanced
				
			break;
		}
		*/
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, [self filterPredicate], 0L]];
		description = [description stringByAppendingString: [self filterPredicateDescription]];
		filtered = YES;
	}
	
	[request setPredicate: predicate];
	
	NSManagedObjectContext *context = [self managedObjectContext];
	[context lock];
	error = 0L;
	[outlineViewArray release];
	outlineViewArray = [context executeFetchRequest:request error:&error];
	
	if( filtered == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogether"] && [outlineViewArray count] > 0)
	{
		NSMutableArray	*patientPredicateArray = [NSMutableArray array];
		
		for( i = 0; i < [outlineViewArray count] ; i++)
		{
			[patientPredicateArray addObject: [NSPredicate predicateWithFormat:  @"(patientID == %@) AND (name == %@)", [[outlineViewArray objectAtIndex: i] valueForKey:@"patientID"], [[outlineViewArray objectAtIndex: i] valueForKey:@"name"]]];
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
	for( i = 0; i < [outlineViewArray count]; i++) images += [[[outlineViewArray objectAtIndex: i] valueForKey:@"noFiles"] intValue];
	description = [description stringByAppendingFormat: NSLocalizedString(@" / Result = %@ studies (%@ images)", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt: [outlineViewArray count]]], [numFmt stringForObjectValue:[NSNumber numberWithInt:images]]];
	
	// By default sort by name
	NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	NSArray * sortDescriptors;
	if( [databaseOutline sortDescriptors] == 0L || [[databaseOutline sortDescriptors] count] == 0)
		sortDescriptors = [NSArray arrayWithObjects: sort, sortdate, 0L];
	else
	{
		sortDescriptors = [NSArray arrayWithObjects: [[databaseOutline sortDescriptors] objectAtIndex: 0], sortdate, 0L];
	}
	outlineViewArray = [[outlineViewArray sortedArrayUsingDescriptors: sortDescriptors] retain];
	
	[context unlock];
	
	[databaseOutline reloadData];
	
	for( i = 0; i < [outlineViewArray count]; i++)
	{
		if( [[[outlineViewArray objectAtIndex: i] valueForKey:@"expanded"] boolValue]) [databaseOutline expandItem: [outlineViewArray objectAtIndex: i]];
		else [databaseOutline collapseItem: [outlineViewArray objectAtIndex: i]];
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

-(void) checkBonjourUpToDateThread:(id) sender
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	NSString	*path = [bonjourBrowser getDatabaseFile: [bonjourServicesList selectedRow]-1];
	if( path != 0L)
	{
		[self performSelectorOnMainThread:@selector(openDatabaseInBonjour:) withObject:path waitUntilDone:YES];
	}
	
	[self performSelectorOnMainThread:@selector(outlineViewRefresh) withObject:nil waitUntilDone:YES];
	
	[checkIncomingLock unlock];
		
	[pool release];
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

-(void) checkBonjourUpToDate:(id) sender
{
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
				if( [checkIncomingLock tryLock])
				{
				//	NSLog(@"lock checkBonjourUpToDate");
					[NSThread detachNewThreadSelector: @selector(checkBonjourUpToDateThread:) toTarget:self withObject: self];
				}
				else NSLog(@"checkBonjourUpToDate locked...");
			}
		}
		
		[self syncReportsIfNecessary: [bonjourServicesList selectedRow]-1];
	}
}

-(void) refreshDatabase:(id) sender
{
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	
	if( [checkIncomingLock tryLock])
	{
	//	NSLog(@"lock refreshDatabase");
		[self outlineViewRefresh];
		[checkIncomingLock unlock];
	}
	else NSLog(@"refreshDatabase locked...");
}

- (NSArray*) childrenArray: (NSManagedObject*) item
{
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		// Sort images with "instanceNumber"
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		NSArray *sortedArray = [[[item valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		
//		if([sortedArray count] == 1 && [[[sortedArray objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue] > 1)
//			return [NSArray arrayWithObject:item];

		return sortedArray;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
	{
		// Sort series with "id" & date
		NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
		NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
		NSArray * sortDescriptors;
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, 0L];
		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, 0L];
		[sortid release];
		[sortdate release];
		
		//return [[[item valueForKey:@"series"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		return [[item valueForKey:@"imageSeries"] sortedArrayUsingDescriptors: sortDescriptors];
	}

	return 0L;
}

- (NSArray*) imagesArray: (NSManagedObject*) item anyObjectIfPossible: (BOOL) any
{
	NSArray			*childrenArray = [self childrenArray: item];
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
			BOOL anyObject = NO;
		
			if( any)
			{
				anyObject = YES;
			
				if( [[childrenArray objectAtIndex: i] valueForKey:@"thumbnail"] == 0L) anyObject = NO;
			}
			
			if( anyObject)
			{
				NSManagedObject	*obj = [[[childrenArray objectAtIndex: i] valueForKey:@"images"] anyObject];
				if( obj) [imagesPathArray addObject: obj];
			}
			else
			{
				NSArray			*seriesArray = [self childrenArray: [childrenArray objectAtIndex: i]];
				
				// Get the middle image of the series
				if( [seriesArray count] > 0)
					[imagesPathArray addObject: [seriesArray objectAtIndex: [seriesArray count]/2]];
			}
		}
	}
	
	return imagesPathArray;
}

- (NSArray*) imagesArray: (NSManagedObject*) item
{
	return [self imagesArray: item anyObjectIfPossible: YES];
}

- (NSArray*) imagesPathArray: (NSManagedObject*) item
{
	return [[self imagesArray: item] valueForKey: @"completePath"];
}

- (NSMutableArray *) filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects
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
			NSArray		*imagesArray = [self imagesArray: curObj];
			
			if( isCurrentDatabaseBonjour)
			{
				for( i = 0; i < [imagesArray count]; i++)
				{
					[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: i] :0]];
				}
			}
			else [selectedFiles addObjectsFromArray: [imagesArray valueForKey: @"completePath"]];
			
			if( correspondingManagedObjects) [correspondingManagedObjects addObjectsFromArray: imagesArray];
		}
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
		{
			NSArray	*seriesArray = [self childrenArray: curObj];
			
			for( i = 0 ; i < [seriesArray count]; i++)
			{
				NSArray		*imagesArray = [self imagesArray: [seriesArray objectAtIndex: i]];
				
				if( isCurrentDatabaseBonjour)
				{
					for( x = 0; x < [imagesArray count]; x++)
					{
						[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: x] :0]];
					}
				}
				else [selectedFiles addObjectsFromArray: [imagesArray valueForKey: @"completePath"]];
				
				if( correspondingManagedObjects) [correspondingManagedObjects addObjectsFromArray: imagesArray];
			}
		}
	}
	
	return selectedFiles;

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
			// STOP les 2 threads!
			if( threadWillRunning == YES) while( threadWillRunning == YES) {[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];}
			if( threadRunning == YES)
			{
				shouldDie = YES;
				while( threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
				shouldDie = NO;
			}
			
			threadWillRunning = YES;
			
			[animationSlider setEnabled:NO];
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
			
			[NSThread detachNewThreadSelector: @selector(matrixLoadIcons:) toTarget: self withObject: item];
			
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

-(IBAction) delItem:(id) sender
{
	long					i, x, z, row, result;
	NSManagedObjectContext	*context = [self managedObjectContext];
	NSManagedObjectModel    *model = [self managedObjectModel];
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [NSMutableArray arrayWithCapacity:0], *studiesArray = [NSMutableArray arrayWithCapacity:0] , *seriesArray = [NSMutableArray arrayWithCapacity:0];
	NSError					*error = 0L;
	BOOL					matrixThumbnails = NO;
	int						animState = [animationCheck state];
	
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
	
	[animationCheck setState: NSOffState];
	
	[context lock];

	// Viewers List
	for( i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) [viewersList addObject: [[winList objectAtIndex:i] windowController]];
	}
	
	if( [albumTable selectedRow] > 0 && matrixThumbnails == NO)
	{
		NSManagedObject	*album = [[self albumArray] objectAtIndex: [albumTable selectedRow]];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == NO)
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove exams", 0L), NSLocalizedString(@"Do you want to only remove the selected exams from the current album or delete them from the database?", 0L), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Remove from current album",nil));
		else
		{
			result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete exams", 0L), NSLocalizedString(@"Are you sure you want to delete the selected exams?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}
	}
	else
	{
		result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete exams", 0L), NSLocalizedString(@"Are you sure you want to delete the selected exams?", 0L), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	}
	
	if( result == NSAlertOtherReturn)	// REMOVE FROM CURRENT ALBUMS, BUT DONT DELETE IT FROM THE DATABASE
	{
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			//Stop le thread
			if( threadWillRunning == YES) while( threadWillRunning == YES) {[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];}
			if( threadRunning == YES)
			{
				shouldDie = YES;
				while( threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
				shouldDie = NO;
			}
			
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
			//Stop the thread
			if( threadWillRunning == YES) while( threadWillRunning == YES) {[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];}
			if( threadRunning == YES)
			{
				shouldDie = YES;
				while( threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
				shouldDie = NO;
			}
			
			// Try to find images that aren't stored in the local database
			
			NSMutableArray	*objectsToDelete = [NSMutableArray arrayWithCapacity: 0], *nonLocalImagesPath = [NSMutableArray arrayWithCapacity: 0];
			
			WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing Delete...", nil)];
			[wait showWindow:self];
			
			if( matrixThumbnails)
			{
				[self filesForDatabaseMatrixSelection: objectsToDelete];
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
			}
			else
			{
				[self filesForDatabaseOutlineSelection: objectsToDelete];
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
			}
			
			[wait close];
			[wait release];
			
			NSLog(@"non-local images : %d", [nonLocalImagesPath count]);
			
			if( [nonLocalImagesPath  count] > 0)
			{
				result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove exams", 0L), NSLocalizedString(@"Some of the selected exams are not stored in the Database folder. Do you want to only remove the links of these exams from the database or also delete the original files?", 0L), NSLocalizedString(@"Remove the links",nil),  NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Delete the files",nil));
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
							[seriesArray addObject: series];
							[series setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
							[series setValue: 0L forKey:@"thumbnail"];
						}
						
						// ********* STUDY
						
						if( [series valueForKey:@"study"] != study)
						{
							study = [series valueForKeyPath:@"study"];
							
							if([studiesArray containsObject: study] == NO)
							{
								[studiesArray addObject: study];
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
			if( [[[studiesArray objectAtIndex: i] valueForKey:@"series"] count] == 0)
			{
				[context deleteObject: [studiesArray objectAtIndex: i]];
			}
		}
		[self saveDatabase: currentDatabasePath];
		
		[self outlineViewRefresh];
		
		[wait close];
		[wait release];
	}
	
	if( queryController) [queryController refresh: self];
	
	[context unlock];
	
	[animationCheck setState: animState];
	
	databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
}

- (void) refreshColumns
{
	NSDictionary	*columnsDatabase	= [[NSUserDefaults standardUserDefaults] objectForKey: @"COLUMNSDATABASE"];
	NSEnumerator	*enumerator			= [columnsDatabase keyEnumerator];
	NSString		*key;
	
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
	
	[managedObjectContext unlock];
}

//- (void) columnsMenuAction:(id) sender
//{
//	[databaseOutline setColumnWithIdentifier:[sender representedObject] visible: ![sender state]];
//	
//	long index = [[[databaseOutline allColumns] valueForKey:@"identifier"] indexOfObject: [sender representedObject]];
//		
//	if( index != NSNotFound)
//	{
//		[COLUMNSDATABASE setValue: [NSNumber numberWithInt: ![sender state]] forKey: [[[[databaseOutline allColumns] valueForKey:@"headerCell"] valueForKey:@"title"] objectAtIndex: index]];
//	}
//	
//	if( [sender state] == NSOffState)
//	{
//		[databaseOutline scrollColumnToVisible: [databaseOutline columnWithIdentifier:[sender representedObject]]];
//	}
//}
//
//- (void) outlineView:(NSOutlineView *)outlineView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn
//{
//	if ( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSControlKeyMask)
//	{
//		NSArray	*columnIdentifiers = [[databaseOutline tableColumns] valueForKey:@"identifier"];
//		long	i;
//		
//		for( i = 0; i < [columnsMenu numberOfItems]; i++)
//		{
//			long index = [columnIdentifiers indexOfObject: [[columnsMenu itemAtIndex: i] representedObject]];
//			
//			if( index != NSNotFound) [[columnsMenu itemAtIndex:i] setState: NSOnState];
//			else [[columnsMenu itemAtIndex:i] setState: NSOffState];
//		}
//		
//		[NSMenu popUpContextMenu: columnsMenu withEvent: [[NSApplication sharedApplication] currentEvent] forView: databaseOutline];
//	}
//}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if( managedObjectContext == 0L) return 0L;
	
	id returnVal = 0L;
	
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
	
	return returnVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL returnVal = NO;
	
	[managedObjectContext lock];
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = NO;
	else returnVal = YES;
	
	[managedObjectContext unlock];
	
	return returnVal;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( managedObjectContext == 0L) return 0L;
	
	int returnVal = 0;
	
	[managedObjectContext lock];
	
	if (!item)
	{
		returnVal = [outlineViewArray count];
	}
	else
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Image"]) returnVal = 0;
		if ([[item valueForKey:@"type"] isEqualToString:@"Series"]) returnVal = [[item valueForKey:@"images"] count];
		//if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"series"] count];
		if ([[item valueForKey:@"type"] isEqualToString:@"Study"]) returnVal = [[item valueForKey:@"imageSeries"] count];
	}
	
	[managedObjectContext unlock];
	
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
	
	[managedObjectContext lock];
	
	id returnVal = [self intOutlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
	
	[managedObjectContext unlock];
	
	return returnVal;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	DatabaseIsEdited = NO;
	
	[managedObjectContext lock];
	
	if( isCurrentDatabaseBonjour)
	{
		[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:item value:object forKey:[tableColumn identifier]];
	}
	
	[item setValue:object forKey:[tableColumn identifier]];
	
	[managedObjectContext unlock];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self outlineViewRefresh];
	
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	[cell setHighlighted: NO];
	[(ImageAndTextCell *)cell setImage: 0L];
	
	NSManagedObjectContext	*context = [self managedObjectContext];
	
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
				if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -60*10) [(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised1.tif"]];													// 10 min
				else if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -60*60) [(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised2.tif"]];												// 1 hour
				else if( [[item valueForKey:@"date"] timeIntervalSinceNow] > -4*60*60) [(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised3.tif"]];											// 4 hours
				else if( [[item valueForKey:@"date"] timeIntervalSinceReferenceDate] > [today timeIntervalSinceReferenceDate]) [(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Realised4.tif"]];	// today
				else icon = NO;
			}
			
			if( icon == NO)
			{
				if( [[item valueForKey:@"dateAdded"] timeIntervalSinceNow] > -60) [(ImageAndTextCell *)cell setImage:[NSImage imageNamed:@"Receiving.tif"]];
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
						[reportIcon setSize: NSMakeSize(16, 16)];
						
						[(ImageAndTextCell *)cell setImage: reportIcon];
					}
					else [item setValue: 0L forKey:@"reportURL"];
				}
			}
			
		}
		
	}
	else [cell setFont: [NSFont boldSystemFontOfSize:10]];
	
	[cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
	
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

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)pbItems toPasteboard:(NSPasteboard*)pboard {

	[pboard declareTypes: [NSArray arrayWithObjects: albumDragType, nil] owner:self];
	
	[pboard setPropertyList:0L forType:albumDragType];

	[draggedItems release];
	draggedItems = [pbItems retain];
	return YES;
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification
{
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
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
	[managedObjectContext lock];
	
	NSManagedObject	*object = [[notification userInfo] objectForKey:@"NSObject"];
	
	[object setValue:[NSNumber numberWithBool: YES] forKey:@"expanded"];
	
	[managedObjectContext unlock];
}

- (MyOutlineView*) databaseOutline {return databaseOutline;}

- (IBAction) databaseDoublePressed:(id)sender
{
	if( [databaseOutline clickedRow] == -1) return;

    NSManagedObject		*item = [databaseOutline itemAtRow:[databaseOutline clickedRow]];
    long				i;
					
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		// ZIP files with XML descriptor
		NSSet *imagesSet = [item valueForKeyPath: @"images.fileType"];
		NSArray *imagesArray = [imagesSet allObjects];
		if([imagesArray count]==1)
		{
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

				return;
			}
		}	
		
		// DICOM & others
		[appController setCurrentHangingProtocolForModality:nil description:nil];
		[self viewerDICOMInt :NO  dcmFile: [NSArray arrayWithObject:item] viewer:0L];
//		[appController setCurrentHangingProtocolForModality:[item valueForKeyPath:@"study.modality"] description:[item valueForKeyPath:@"study.studyName"]];
	}
	else	// STUDY - HANGING PROTOCOLS
	{
	
		// files with XML descriptor, do nothing
		NSSet *imagesSet = [item valueForKeyPath: @"series.images.fileType"];
		NSArray *imagesArray = [[[imagesSet allObjects] objectAtIndex:0] allObjects];
		if([imagesArray count]==1)
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
			{
				return;
			}
		}
	
		// DICOM & others
		[appController setCurrentHangingProtocolForModality:[item valueForKey:@"modality"] description:[item valueForKey:@"studyName"]];
		NSDictionary *currentHangingProtocol = [appController currentHangingProtocol];
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
				[databaseOutline selectRow:[databaseOutline rowForItem: [curImage valueForKey:@"series"]] byExtendingSelection: NO];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		else
		{
			if( [databaseOutline rowForItem: study] != [databaseOutline selectedRow])
			{
				[databaseOutline selectRow:[databaseOutline rowForItem: study] byExtendingSelection: NO];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		
		// Now... try to find the series in the matrix
		if( [databaseOutline isItemExpanded: study] == NO)
		{
			NSArray	*seriesArray = [self childrenArray: study];
			
			[self matrixDisplayIcons: self];	//Display the icons, if necessary
			
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
	NSManagedObjectModel	*model = [self managedObjectModel];
	NSManagedObjectContext	*context = [self managedObjectContext];
	long					x, i;
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	
	if( [viewer FullScreenON]) [viewersList addObject: viewer];
	else
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
	
	// FIND ALL STUDIES of this patient
	NSManagedObject		*study = [curImage valueForKeyPath:@"series.study"];
	NSManagedObject		*currentSeries = [curImage valueForKeyPath:@"series"];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientID == %@) AND (name == %@)", [study valueForKey:@"patientID"], [study valueForKey:@"name"]];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: predicate];
	
	[context lock];
	
	NSError	*error = 0L;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
	{
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
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
						NSString		*path = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Empty.tif"];
									
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
	
	[viewersList release];
}

-(void) loadSeries:(NSManagedObject *) series :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Thumbnails Matrix & Preview functions

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
	
	[self previewSliderAction: animationSlider];
}

- (void) previewSliderAction:(id) sender
{
	BOOL	animate = NO;
	long	noOfImages = 0;
	
    // Wait loading all images !!!
    if( threadWillRunning == YES) return;
    if( threadRunning == YES)  return;
	
    NSButtonCell    *cell = [oMatrix selectedCell];
    if( cell)
    {
		if( [cell isEnabled] == YES)
		{
			NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
			if( [[aFile valueForKey:@"type"] isEqualToString:@"Study"])
			{
				NSArray *images = [self imagesArray: [matrixViewArray objectAtIndex: [cell tag]]];
				
				if( [images count])
				{
					if( [images count] > 1) noOfImages = [images count];
					else noOfImages = [[[images objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
					
					if( [images count] > 1)
					{
						animate = YES;
						
						DCMPix*     dcmPix = 0L;
						dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: [sender intValue]] valueForKey:@"completePath"] :[sender intValue] :[images count] :0L :0 :[[[images objectAtIndex: [sender intValue]] valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:[images objectAtIndex: [sender intValue]]];
						
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
					else if( noOfImages > 1)	// It's a multi-frame single image
					{
						animate = YES;
						
						DCMPix*     dcmPix = 0L;
						dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: 0] valueForKey:@"completePath"] :[sender intValue] :noOfImages :0L :[sender intValue] :[[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:[images objectAtIndex: 0]];
						
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
    // Wait loading all images !!!
	if( managedObjectContext == 0L) return;
	if( bonjourDownloading) return;
	if( [animationCheck state] == NSOffState) return;
    if( threadWillRunning == YES) return;
    if( threadRunning == YES)  return;
    if( [[self window] isKeyWindow] == NO) return;
    
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
    if( threadWillRunning == YES) return;
    if( threadRunning == YES)  return;

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
	[animationSlider setIntValue:0];
	
    if( [theCell tag] >= 0)
    {
        NSManagedObject		*dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
        
        if( [oMatrix getRow:&row column:&column ofCell:theCell] == YES)
        {
			NSArray	*pathsArray = [self imagesPathArray: dcmFile];
			
			index = [theCell tag];
			
            if( pathsArray != 0L)
			{
				if( [[dcmFile valueForKey:@"type"] isEqualToString: @"study"]) [imageView setIndex: index];
				else [imageView setIndexWithReset: index :YES];
			}
        }
		
		[self initAnimationSlider];
    }
}

- (IBAction) matrixDoublePressed:(id)sender
{
    id  theCell = [oMatrix selectedCell];
    int column,row;
    
	[appController setCurrentHangingProtocolForModality:nil description:nil];
	
    if( [theCell tag] >= 0 ) {
		[self viewerDICOM: oMatrix];
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

		DCMPix		*pix = [previewPix objectAtIndex: i];
		NSImage		*img = 0L;
		
		img = [previewPixThumbnails objectAtIndex: i];
		if( img == 0L) NSLog( @"Error: [previewPixThumbnails objectAtIndex: i] == 0L");
		
		[managedObjectContext lock];
		
		NSString	*modality = [[pix imageObj] valueForKey: @"modality"];
		
		if ( img || [modality isEqualToString: @"RTSTRUCT"] )
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
			else if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"]) {
				long count = [[curFile valueForKey:@"images"] count];
				
				if( count == 1) {
					long frames = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
					
					if( frames > 1) [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Frames", 0L), name, frames]];
					else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Image", 0L), name, count]];
				}
				else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Images", 0L), name, count]];
				
				//	[oMatrix setToolTip:[NSString stringWithFormat:@"%@ (%@)", [curFile valueForKey:@"name"],[curFile valueForKey:@"id"]] forCell:cell];
			}
			else if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"]) {
				[cell setTitle:[NSString stringWithFormat:NSLocalizedString(@"Image %d", nil), i+1]];
			}
			else if( [[curFile valueForKey:@"type"] isEqualToString: @"Study"]) {
				[cell setTitle: name];
				[oMatrix setToolTip:[curFile valueForKey:@"name"] forCell:cell];
			}
			
			[cell setButtonType:NSPushOnPushOffButton];
			
			[cell setImage: img];
						
			if( setDCMDone == NO && i >= [[oMatrix selectedCell] tag]) {
				NSIndexSet  *index = [databaseOutline selectedRowIndexes];
				if( [index count] >= 1) {
					NSManagedObject* aFile = [databaseOutline itemAtRow:[index firstIndex]];
					
					[imageView setDCM:previewPix :[self imagesArray: aFile anyObjectIfPossible: YES] :0L :[[oMatrix selectedCell] tag] :'i' :YES];	//
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
		
		[managedObjectContext unlock];
	}
	[oMatrix setNeedsDisplay:YES];
}

-(void) matrixDisplayIcons:(id) sender
{
	long		i;
	
	if( bonjourDownloading) return;
	if( managedObjectContext == 0L) return;
	
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
		
		if( loadPreviewIndex == 0) [self initAnimationSlider];
		
		loadPreviewIndex = i;
	}
}

- (void) matrixLoadIcons:(NSManagedObject*) item
{
	NSAutoreleasePool               *pool = [[NSAutoreleasePool alloc] init];
	[item retain];
	
	long							i, subGroupCount = 1, position = 0;
	BOOL							StoreThumbnailsInDB = [[NSUserDefaults standardUserDefaults] boolForKey: @"StoreThumbnailsInDB"];
	BOOL							imageLevel = NO;
	
	threadWillRunning = NO;
	threadRunning = YES;

	while( [managedObjectContext tryLock] == NO)
	{
		if( shouldDie == YES)
		{
			[item release];
			[pool release];
			shouldDie = NO;
			threadRunning = NO;
			return;
		}
	}
	
	[incomingProgress performSelectorOnMainThread:@selector( startAnimation:) withObject:self waitUntilDone:NO];
	
	NSArray	*files = [self imagesArray: item anyObjectIfPossible:YES];
	
	if( [files count] > 1)
	{
		if( [[files objectAtIndex: 0] valueForKey:@"series"] == [[files objectAtIndex: 1] valueForKey:@"series"]) imageLevel = YES;
	}
	
	for( i = 0; i < [files count];i++) [[files objectAtIndex:i] valueForKeyPath:@"series.thumbnail"];	// ANR: important to avoid 'state is still active'
	
	if( imageLevel)	[managedObjectContext unlock];
	
	for( i = 0; i < [files count];i++)
	{
		DCMPix*     dcmPix;
		NSImage		*thumbnail = 0L;
		BOOL		computeThumbnail = NO;
		
		if( StoreThumbnailsInDB && !imageLevel)
		{
			thumbnail = [[[NSImage alloc] initWithData: [[files objectAtIndex:i] valueForKeyPath:@"series.thumbnail"]] autorelease];
			if( thumbnail == 0L) computeThumbnail = YES;
		}
		
		dcmPix  = [[DCMPix alloc] myinit:[[files objectAtIndex:i] valueForKey:@"completePath"] :position :subGroupCount :0L :0 :0 isBonjour:isCurrentDatabaseBonjour imageObj:[files objectAtIndex:i]];
		//[[[files objectAtIndex:i] valueForKeyPath:@"series.id"] intValue]
		
		if( dcmPix)
		{
			if( thumbnail == 0L)
			{
				[dcmPix computeWImage:YES :0 :0];
				if( [dcmPix getImage] == 0L) NSLog(@"getImage == 0L");
				[dcmPix revert];	// <- Kill the raw data
			}
			
			if( thumbnail == 0L) thumbnail = [dcmPix getImage];
			if( thumbnail == 0L) thumbnail = [NSImage imageNamed: @"FileNotFound.tif"];
		
			[previewPixThumbnails addObject: thumbnail];
			if( StoreThumbnailsInDB && computeThumbnail && !imageLevel)
			{
				[[[files objectAtIndex:i] valueForKey: @"series"] setValue: [thumbnail TIFFRepresentationUsingCompression: NSTIFFCompressionPackBits factor:0.5] forKey:@"thumbnail"];
			}
			[previewPix addObject: dcmPix];
			
			[dcmPix release];
			
			if (shouldDie == YES)
			{
				i = [files count];
				NSLog(@"LoadPreview should die");
			}
		}
		else
		{
			dcmPix = [[DCMPix alloc] myinitEmpty];
			[previewPix addObject: dcmPix];
			[previewPixThumbnails addObject: [NSImage imageNamed: @"FileNotFound.tif"]];
			
			[dcmPix release];
		}
	}
	
	if( imageLevel == NO)	[managedObjectContext unlock];
	
    threadRunning = NO;
    shouldDie = NO;
	
	[item release];
	
	[incomingProgress performSelectorOnMainThread:@selector( stopAnimation:) withObject:self waitUntilDone:NO];
	
	[self performSelectorOnMainThread:@selector( matrixDisplayIcons:) withObject:0L waitUntilDone: YES];
	
    [pool release];
}

-(long) COLUMN
{
    return COLUMN;
}

- (float)splitView:(NSSplitView *)sender constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset
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
		
        long pos = proposedPosition;
		
		pos += size.width/2;
		pos -= 17;
	   
        pos /= (size.width + space.width*2);
		if( pos <= 0) pos = 1;
		
        pos *= (size.width + space.width*2);
		pos += 17;
		
        return (float) pos;
    }

    return proposedPosition;
}

-(void) ViewFrameDidChange:(NSNotification*) note
{

	if( [note object] == [[splitViewVert subviews] objectAtIndex: 0])	// 1
	{
		NSSize size = [oMatrix cellSize];
        NSSize space = [oMatrix intercellSpacing];
        NSRect frame = [[[splitViewVert subviews] objectAtIndex: 0] frame];
		
		long preWidth = frame.size.width+1;
		long width = frame.size.width;
		long cellsize = (size.width + space.width*2);
		
		width += cellsize/2;
		width /=  cellsize;
		width *=  cellsize;
		
		width += 17;
		
		if( width != preWidth)
		{
			frame.size.width = width;
			[[[splitViewVert subviews] objectAtIndex: 0] setFrame: frame];
		}
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
        long	i, minrow, row;
        long	selectedCellTag = [[oMatrix selectedCell] tag];
		
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

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
	
	if ([sender isEqual:sourcesSplitView])
	{
		// minimum size of the top view (db, albums)
		return 200;
	}
	else
	{
		return proposedMax;
	}
}


- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMin ofSubviewAt:(int)offset
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
	else
	{
		return proposedMin;
	}
}

- (NSMutableArray *) filesForDatabaseMatrixSelection :(NSMutableArray*) correspondingManagedObjects
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
						[selectedFiles addObject: [self getLocalDCMPath: curObj :0]];
					}
					else [selectedFiles addObject: [curObj valueForKey: @"completePath"]];
					
					if( correspondingManagedObjects) [correspondingManagedObjects addObject: curObj];
				}
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"])
				{
					NSArray *imagesArray = [self imagesArray: curObj];
					
					if( isCurrentDatabaseBonjour)
					{
						for( i = 0; i < [imagesArray count]; i++)
						{
							[selectedFiles addObject: [self getLocalDCMPath: [imagesArray objectAtIndex: i] :0]];
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

- (void) createContextualMenu
{
	NSMenu			*contextual		=  [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	NSMenuItem		*item, *subItem;
	int				i = 0;
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export Files", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Toggle images/series displaying", nil)  action:@selector(displayImagesOfSeries:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil)  action:@selector(delItem:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Send to PACS", nil)  action:@selector(export2PACS:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy to iPod", nil)  action:@selector(sendiPod:) keyEquivalent:@""];
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
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Key Images", nil)  action:@selector(viewerDICOMKeyImages:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Merged Selection", nil)  action:@selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
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
		[albumTable reloadData];
		
		[albumTable selectRow:[[self albumArray] indexOfObject: album] byExtendingSelection: NO];
		
		[context unlock];
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
				
				[albumTable reloadData];
				
				[context unlock];
			//	[albumTable selectRow:[[self albumArray] indexOfObject: album] byExtendingSelection: NO];
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
			[context lock];
			
			if( [albumTable selectedRow] > 0)	// We cannot delete the first item !
			{
				//Stop le thread
				if( threadWillRunning == YES) while( threadWillRunning == YES) {[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];}
				if( threadRunning == YES)
				{
					shouldDie = YES;
					while( threadRunning == YES) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
					shouldDie = NO;
				}
				
				[context deleteObject: [[self albumArray]  objectAtIndex: [albumTable selectedRow]]];
			}
			
			[self saveDatabase: currentDatabasePath];
			
			[albumTable reloadData];
			
			[context unlock];
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
				
				[albumTable reloadData];
				
				[context unlock];
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
	
	[context lock];
	//Find all albums
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Album"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = 0L;
	NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
	
	NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	albumsArray = [albumsArray sortedArrayUsingDescriptors:  [NSArray arrayWithObjects: sort, 0L]];
	result = [NSArray arrayWithObject: [NSDictionary dictionaryWithObject: @"Database" forKey:@"name"]];
	
	[context unlock];
	
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
//	else if ([aTableView isEqual:sendLogTable])
//		return [sendLog count];
//	else if ([aTableView isEqual:receiveLogTable])
//		return [receiveLog count];
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
			if( rowIndex == 0)
			{
				// Find all studies
				NSError			*error = 0L;
				NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
				[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
				[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
				NSManagedObjectContext *context = [self managedObjectContext];
				[context lock];
				error = 0L;
				NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
				[context unlock];
				
				return [NSString stringWithFormat:@"%@",  [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]];
			}
			else
			{
				NSManagedObject	*object = [[self albumArray]  objectAtIndex: rowIndex];
				
				if( [[object valueForKey:@"smartAlbum"] boolValue] == YES)
				{
					// Find all studies
					NSError			*error = 0L;
					NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"Study"]];
					[dbRequest setPredicate: [self smartAlbumPredicate: object]];
					NSManagedObjectContext *context = [self managedObjectContext];
					[context lock];
					error = 0L;
					NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
					[context unlock];
					
					return [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]];
				}
				else return [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[[object valueForKey:@"studies"] count]]]];
			}
		}
		else
		{
			NSManagedObject	*object = [[self albumArray]  objectAtIndex: rowIndex];
			return [object valueForKey:@"name"];
		}
	}
//	else if ([aTableView isEqual:sendLogTable])
//		return [[sendLog objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	else if ([aTableView isEqual:bonjourServicesList])
	{
		if([[aTableColumn identifier] isEqualToString:@"Source"])
		{
			if (bonjourBrowser!=nil)
			{
				if( rowIndex == 0) return @"Local Database";
				else if( rowIndex <= [bonjourBrowser BonjourServices]) return [[[bonjourBrowser services] objectAtIndex: rowIndex-1] name];
				else return [[[bonjourBrowser services] objectAtIndex: rowIndex-1] valueForKey:@"Description"];
			}
			else
			{
				return @"Local Database";
			}
		}
	}
			
	return nil;
}

//- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
//	if ([aTableView isEqual:albumTable])
//	{
//		if( rowIndex > 0) return YES;
//	}	
//	else if ([aTableView isEqual:bonjourServicesList])
//	{
//		return NO;
//	}
//	return NO;
//}

- (void)tableView:(NSTableView *)aTableView
    setObjectValue:anObject
    forTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
//	if ([aTableView isEqual:albumTable] && rowIndex >= 1)
//	{
//		NSArray			*albumsArray = [self albumArray];
//		NSManagedObject	*object = [albumsArray objectAtIndex:rowIndex];
//		
//		if( [anObject isEqualToString: [[albumsArray objectAtIndex:rowIndex] valueForKey: @"name"]] == NO)
//		{
//			if( [[albumsArray valueForKey:@"name"] indexOfObject: anObject] == NSNotFound)
//			{
//				[[albumsArray objectAtIndex:rowIndex] setValue:anObject forKey:@"name"];
//				[albumTable reloadData];
//				[albumTable selectRow: [[self albumArray] indexOfObject:object] byExtendingSelection: NO];
//				[self saveDatabase: currentDatabasePath];
//			}
//			else NSRunAlertPanel(@"Database", @"Albums names have to be unique.", nil, nil, nil);
//		}
//	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if ([aTableView isEqual:albumTable])
	{
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 12];
		else txtFont = [NSFont systemFontOfSize:12];			
		
		[aCell setFont:txtFont];
		
		if( [[aTableColumn identifier] isEqualToString:@"Source"])
		{ 
			if ([[[[self albumArray] objectAtIndex:rowIndex] valueForKey:@"smartAlbum"] boolValue])
			{
				//[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"SmartAlbum.tiff"]];
				if(isCurrentDatabaseBonjour)
				{
					[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"small_sharedSmartAlbum.tiff"]];
				}
				else
				{
					[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"small_smartAlbum.tiff"]];
				}
			}
			else
			{
				//[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"Album.tiff"]];
				if(isCurrentDatabaseBonjour)
				{
					[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"small_sharedAlbum.tiff"]];
				}
				else
				{
					[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"small_album.tiff"]];
				}
			}
		}
	}
	
	if ([aTableView isEqual:bonjourServicesList])
	{
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 12];
		else txtFont = [NSFont systemFontOfSize:12];			
		
		[aCell setFont:txtFont];
		
		if (rowIndex == 0)
		{
			[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"osirix16x16.tiff"]];
		}
		else if (rowIndex <= [bonjourBrowser BonjourServices])
		{
			[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"bonjour.tiff"]];
		}
		else
		{
			[(ImageAndTextCell *)aCell setImage:[NSImage imageNamed:@"FixedIP.tif"]];
		}
	}
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
			}
			
			[self saveDatabase: currentDatabasePath];
			
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
			
			if( row == 0 && isCurrentDatabaseBonjour == YES) // Copying FROM
			{
				Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Copying from OsiriX database...", nil)];
				
				[splash showWindow:self];
				[[splash progress] setMaxValue:[imagesArray count]];

				for( i = 0; i < [imagesArray count]; i++)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					filePath = [self getLocalDCMPath: [imagesArray objectAtIndex: i] :10];
					destPath = [[documentsDirectory() stringByAppendingString:INCOMINGPATH] stringByAppendingPathComponent: [filePath lastPathComponent]];
					
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
				
				[splash close];
				[splash release];
			}
			else if( [bonjourServicesList selectedRow] != row)	 // Copying TO
			{
				Wait *splash = [[Wait alloc] initWithString:@"Copying to OsiriX database..."];
				long x;
				
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
		
		if( isCurrentDatabaseBonjour && row == 0) accept = YES;
		if( row > 0 && [bonjourServicesList selectedRow] != row) accept = YES;
		
		if( accept)
		{
			[bonjourServicesList setDropRow:row dropOperation:NSTableViewDropOn];
			return NSTableViewDropAbove;
		}
	}
	
	return NSDragOperationNone;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if( [[aNotification object] isEqual: albumTable])
	{
		// Clear search field
		[self setSearchString:nil];
		
		[self outlineViewRefresh];
	}
	
	if( [[aNotification object] isEqual: bonjourServicesList])
	{
		[self syncReportsIfNecessary: previousBonjourIndex];
		
		[self bonjourServiceClicked: bonjourServicesList];
		
		previousBonjourIndex = [bonjourServicesList selectedRow]-1;
	}
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Open 2D/4D Viewer functions

- (void) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages
{
	NS_DURING
		unsigned long		memBlockSize[ 200], memBlock, mem;
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
		
// NS_DURING (2) Compute Required Memory

		BOOL	enoughMemory = NO;
		long	subSampling = 1;
		
		while( enoughMemory == NO)
		{
			BOOL memTestFailed = NO;
			mem = 0;
			memBlock = 0;
			
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
				
				NSLog(@"Test memory for: %d Mb", (memBlock * sizeof(float)) / (1024 * 1024));
				unsigned char* testPtr = malloc( (memBlock * sizeof(float)) + 4096);
				if( testPtr == 0L) memTestFailed = YES;
				else free( testPtr);
				
				memBlockSize[ x] = memBlock;
				
			} //end for
			
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
		
		if( result == NSAlertDefaultReturn)
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
				char*		memBlockTestPtr[ 200];
				
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
}

- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer
{
	NSManagedObject		*selectedLine = [selectedLines objectAtIndex: 0];
    int					z, row, column;
	NSMutableArray		*selectedFilesList;
	NSArray				*loadList;
    NSArray				*cells;
    long				i, x;
	unsigned long		mem;
	long				numberImages, multiSeries = 1;
	BOOL				movieError = NO, multiFrame = NO;
	

	
    cells = [oMatrix selectedCells];
	
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
				NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"To see an animated series, you have to select multiple series of the same area at different times: e.g. a cardiac CT", 0L), NSLocalizedString(@"OK",nil), nil, nil);
				movieError = YES;
			}
			else if( [toOpenArray count] >= 100)
			{
				NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"4D Player is limited to a maximum number of 100 series.", 0L), NSLocalizedString(@"OK",nil), nil, nil);
				movieError = YES;
			}
			else
			{
				numberImages = -1;
				
				for( x = 0; x < [toOpenArray count]; x++)
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
		
		if( movieError == NO)
			[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
    }
	
	
	// If they are more than 1 window -> tile them
	NSArray					*winList = [NSApp windows];
	for( x = 0, i = 0; i < [winList count]; i++)
	{
		if( [[[winList objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) x++;
	}
	
	//if( x > 1) 
	[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
}



- (void) viewerDICOM:(id) sender{
	//// key Images if Commmand
	//if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSCommandKeyMask)  
	//	[self viewerDICOMKeyImages:sender];		
	//merge if shift key pressed.	
	
	 if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask) 
		[self viewerDICOMMergeSelection:sender];
	else
		[self newViewerDICOM:(id) sender];

}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void) newViewerDICOM: (id) sender
{
	long				index;
	NSMutableArray		*selectedItems			= [NSMutableArray arrayWithCapacity: 0];
	NSIndexSet			*selectedRowIndexes		= [databaseOutline selectedRowIndexes];
	NSManagedObject		*item					= [databaseOutline itemAtRow: [databaseOutline selectedRow]];
	
	//close open windows if option key pressed.	
	/*
	int i;
	if ([[NSApp currentEvent] modifierFlags]  & NSAlternateKeyMask) {
		for( i = 0; i < [[NSApp windows] count]; i++)
		{
			NSWindow *window = [[NSApp windows] objectAtIndex:i];
			if( [[window windowController] isKindOfClass:[ViewerController class]]) [[window windowController] close];
		}
	}
	*/	
	
	// do nothing for a ZIP file with XML descriptor
	BOOL zipFile = NO;
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		NSLog( @"Series");
		// ZIP files with XML descriptor
		NSSet *imagesSet = [item valueForKeyPath: @"images.fileType"];
		NSArray *imagesArray = [imagesSet allObjects];
		if([imagesArray count]==1)
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
			{
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

				return;
			}
		}
	}
	else	// STUDY
	{
	NSLog( @"STUDY");
		// files with XML descriptor, do nothing
		NSSet *imagesSet = [item valueForKeyPath: @"series.images.fileType"];
		NSArray *imagesArray = [[[imagesSet allObjects] objectAtIndex:0] allObjects];
		if([imagesArray count]==1)
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
			{
				return;
			}
		}
	}

	// regular files:
	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
       if ([selectedRowIndexes containsIndex:index])
	   {
			[selectedItems addObject: [databaseOutline itemAtRow:index]];
//			NSLog(@"Add Item: %@", [[databaseOutline itemAtRow:index] description]);
	   }
	}

	if (sender==Nil && [[oMatrix selectedCells] count]==1 && [[item valueForKey:@"type"] isEqualToString:@"Study"] == YES)
	{
		[appController setCurrentHangingProtocolForModality: [item valueForKey: @"modality"] description: [item valueForKey: @"studyName"]];	
		NSDictionary *currentHangingProtocol = [appController currentHangingProtocol];
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
	else														// Called by double click in matrix.
	{
		[appController setCurrentHangingProtocolForModality: Nil description: Nil];	
		[self viewerDICOMInt:NO	dcmFile: selectedItems viewer:0L];
	}
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void) viewerDICOMMergeSelection:(id) sender{
	long			index;
	NSMutableArray	*images = [NSMutableArray arrayWithCapacity:0];
	
	[appController setCurrentHangingProtocolForModality:nil description:nil];
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) [self filesForDatabaseMatrixSelection: images];
	else [self filesForDatabaseOutlineSelection: images];
	
	[self openViewerFromImages :[NSArray arrayWithObject:images] movie: nil viewer :nil keyImagesOnly:NO];
	
	[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
}

- (void) viewerDICOMKeyImages:(id) sender
{
	long			index;
	NSMutableArray	*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[appController setCurrentHangingProtocolForModality:nil description:nil];	
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];

	[self openViewerFromImages :[NSArray arrayWithObject:selectedItems] movie: nil viewer :nil keyImagesOnly:YES];
	
	[NSApp sendAction: @selector(tileWindows:) to:0L from: self];
}

- (void) MovieViewerDICOM:(id) sender
{
	long					index;
	NSMutableArray			*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[appController setCurrentHangingProtocolForModality:nil description:nil];

	NSIndexSet				*selectedRowIndexes = [databaseOutline selectedRowIndexes];

	for (index = [selectedRowIndexes firstIndex]; 1+[selectedRowIndexes lastIndex] != index; ++index)
	{
       if ([selectedRowIndexes containsIndex:index])
	   {			
			[selectedItems addObject: [databaseOutline itemAtRow:index]];
	   }
	}
	
	[self viewerDICOMInt:YES dcmFile: selectedItems viewer:0L];
}

- (IBAction) endOpenSubSeries:(id) sender
{
	[NSApp endSheet: subSeriesWindow];
	[subSeriesWindow orderOut: self];
	
	if( [sender tag] == 1)
	{
	
	}
}

- (IBAction) openSubSeries: (id)sender
{
	[NSApp beginSheet: subSeriesWindow
				modalForWindow: [self window]
				modalDelegate: nil
				didEndSelector: nil
				contextInfo: nil];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

//#pragma mark-
//#pragma mark serversArray functions
//
//- (int) numberOfItemsInComboBox:(NSComboBox *)aComboBox
//{
//	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
//
//
//	if ([aComboBox isEqual:serverList])
//	{
//		//add BONJOUR DICOM also
//		
//		int count = [serversArray count] + [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] count];
//		
//		return count;
//		//return [serversArray count];
//	}
//}

//- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
//{
//	NSArray			*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
//
//
//	if ([aComboBox isEqual:serverList]){
//		if( index > -1 && index < [serversArray count])
//		{
//			id theRecord = [serversArray objectAtIndex:index];
//			
//			return [NSString stringWithFormat:@"%@ - %@",[theRecord objectForKey:@"AETitle"],[theRecord objectForKey:@"Description"]];
//		}
//		else if( index > -1) {
//			id service = [[[DCMNetServiceDelegate sharedNetServiceDelegate] dicomServices] objectAtIndex:index - ([serversArray count])];
//			return [NSString stringWithFormat:NSLocalizedString(@"%@ - Bonjour", nil), [service name]];
//		}
//			
//	}
////	else {
////		if( index> -1)
////			return [syntaxArray objectAtIndex:index];
////	}
//	return nil;
//}

//- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString *)uncompletedString{
//	if ([aComboBoxCell isEqual:[syntaxList cell]]){
//		NSEnumerator *enumerator = [syntaxArray objectEnumerator];
//		NSString *string;
//		while (string = [enumerator nextObject]) {
//			if ([[string uppercaseString] hasPrefix:[uncompletedString uppercaseString]])
//				return string;
//		}
//	}
//	return nil;
//}
//
//- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)aString{
//		if ([aComboBoxCell isEqual:[syntaxList cell]]){
//			return [syntaxArray indexOfObject:aString];
//		}
//	return NSNotFound;
//}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark GUI functions


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
		
		bonjourReportFilesToCheck = [[NSMutableDictionary dictionary] retain];
		
		numFmt = [[NSNumberFormatter alloc] init];
		[numFmt setLocale: [NSLocale currentLocale]];
		[numFmt setFormat:@"0"];
		[numFmt setHasThousandSeparators: YES];
		
		checkIncomingLock = [[NSLock alloc] init];
		
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
		isCurrentDatabaseBonjour = NO;
		currentDatabasePath = 0L;
		currentDatabasePath = [[documentsDirectory() stringByAppendingString:DATAFILEPATH] retain];
		if( [[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath] == NO)
		{
			// Switch back to default location
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
			
			[currentDatabasePath release];
			currentDatabasePath = [[documentsDirectory() stringByAppendingString:DATAFILEPATH] retain];
			
			NEEDTOREBUILD = YES;
			COMPLETEREBUILD = YES;
		}
		
		[self setFixedDocumentsDirectory];
		[self setNetworkLogs];

		str = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
		
		shouldDie = NO;
		threadRunning = NO;
		threadWillRunning = NO;
		bonjourDownloading = NO;
		
		previewPix = [[NSMutableArray alloc] initWithCapacity:0];
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(previewPerformAnimation:) userInfo:self repeats:YES] retain];
		IncomingTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkIncoming:) userInfo:self repeats:YES] retain];
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:16.33 target:self selector:@selector(refreshDatabase:) userInfo:self repeats:YES] retain];
		bonjourTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkBonjourUpToDate:) userInfo:self repeats:YES] retain];
		databaseCleanerTimer = [[NSTimer scheduledTimerWithTimeInterval:60*60*2 target:self selector:@selector(autoCleanDatabaseDate:) userInfo:self repeats:YES] retain];
		deleteQueueTimer = [[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(emptyDeleteQueue:) userInfo:self repeats:YES] retain];
		
		bonjourRunLoopTimer = 0L;
		
		loadPreviewIndex = 0;
		matrixDisplayIcons = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(matrixDisplayIcons:) userInfo:self repeats:YES] retain];
		
		/* notifications from workspace */
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
															  selector: @selector(volumeMount:)
																  name: NSWorkspaceDidMountNotification
																object: nil];

		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
															  selector: @selector(volumeUnmount:)
																  name: NSWorkspaceDidUnmountNotification
																object: nil];
																

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(closeAllWindows:) name: @"Close All Viewers" object: nil];	
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mainWindowHasChanged:) name: NSWindowDidBecomeMainNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateCurrentImage:) name: @"DCMNewImageViewResponder" object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(ViewFrameDidChange:) name: NSViewFrameDidChangeNotification object: nil];
	}
		
	return self;
}

-(void) awakeFromNib
{
	long i;
	
	NSTableColumn		*tableColumn = nil;
	NSPopUpButtonCell	*buttonCell = nil;

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
	
	[albumDrawer setDelegate:self];
	[oMatrix setDelegate:self];
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
	
	
	[self loadDatabase: currentDatabasePath];

	// SCAN FOR AN IPOD!
	[self loadDICOMFromiPod];
	
	// NSMenu for DatabaseOutline
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Tools"];
	NSMenuItem *exportItem, *sendItem, *burnItem, *anonymizeItem, *keyImageItem;
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export Files", @"Export Files") action: @selector(exportDICOMFile:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Report", 0L) action: @selector(generateReport:) keyEquivalent:@""];
	[exportItem setTarget:self];
	[menu addItem:exportItem];
	[exportItem release];
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", nil) action: @selector(delItem:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Send to PACS", nil) action: @selector(export2PACS:) keyEquivalent:@""];
	[sendItem setTarget:self];
	[menu addItem:sendItem];
	[sendItem release];
	sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy to iPod", nil) action: @selector(sendiPod:) keyEquivalent:@""];
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
	
	
	[databaseOutline setMenu:menu];
	[menu release];
	
	[self addHelpMenu];
	
	ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
	[cell setEditable:YES];
	[[albumTable tableColumnWithIdentifier:@"Source"] setDataCell:cell];
	[albumTable setDelegate:self];
	[albumTable registerForDraggedTypes:[NSArray arrayWithObject:albumDragType]];
	[albumTable setDoubleAction:@selector(albumTableDoublePressed:)];
	
	[customStart setDateValue: [NSDate date]];
	[customStart2 setDateValue: [NSDate date]];
	[customEnd setDateValue: [NSDate date]];
	[customEnd2 setDateValue: [NSDate date]];
	
//	syntaxArray = [[NSArray arrayWithObjects:@"Explicit Little Endian", @"JPEG 2000 Lossless", @"JPEG 2000 Lossy 10:1", @"JPEG 2000 Lossy 20:1", @"JPEG 2000 Lossy 50:1",@"JPEG Lossless", @"JPEG High Quality (9)",  @"JPEG Medium High Quality (8)", @"JPEG Medium Quality (7)", nil] retain];
//	[syntaxList setDataSource:self];
	
	statesArray = [[NSArray arrayWithObjects:NSLocalizedString(@"empty", nil), NSLocalizedString(@"unread", nil), NSLocalizedString(@"reviewed", nil), NSLocalizedString(@"dictated", nil), 0L] retain];
	
	// Set International dates for columns
	NSString		*sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortTimeDateFormatString];
	NSDateFormatter	*dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[databaseOutline tableColumnWithIdentifier: @"dateOpened"] dataCell] setFormatter: dateFomat];
	[[[databaseOutline tableColumnWithIdentifier: @"date"] dataCell] setFormatter: dateFomat];
	[[[databaseOutline tableColumnWithIdentifier: @"dateAdded"] dataCell] setFormatter: dateFomat];
	
	sdf = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
	dateFomat = [[[NSDateFormatter alloc]  initWithDateFormat: sdf allowNaturalLanguage: YES] autorelease];
	[[[databaseOutline tableColumnWithIdentifier: @"dateOfBirth"] dataCell] setFormatter: dateFomat];
	

	ImageAndTextCell *cellName = [[[ImageAndTextCell alloc] init] autorelease];
	[[databaseOutline tableColumnWithIdentifier:@"name"] setDataCell:cellName];
	
	ImageAndTextCell *cellReport = [[[ImageAndTextCell alloc] init] autorelease];
	[[databaseOutline tableColumnWithIdentifier:@"reportURL"] setDataCell:cellReport];
	[[[databaseOutline tableColumnWithIdentifier: @"reportURL"] dataCell] setFormatter: dateFomat];
	
//	columnsMenu = [[NSMenu alloc] initWithTitle:@"Displayed Columns"];
//	for( i = 0; i < [[databaseOutline tableColumns] count]; i++)
//	{
//		NSTableColumn *col = [[databaseOutline tableColumns] objectAtIndex:i];
//		
//		if( [[col identifier] isEqualToString:@"name"] == NO)	// Patient name column HAS to be displayed
//		{
//			NSMenuItem	*item = [columnsMenu insertItemWithTitle:[[col headerCell] stringValue] action:@selector(columnsMenuAction:) keyEquivalent:@"" atIndex: [columnsMenu numberOfItems]];
//			[item setRepresentedObject: [col identifier]];
//		}
//	}

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
		{
			[albumDrawer open]; 
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"])
	{
		NSDictionary	*sort = [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"];
		{
			if( [databaseOutline isColumnWithIdentifierVisible: [sort objectForKey:@"key"]])
				[databaseOutline setSortDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:[sort objectForKey:@"key"] ascending:[[sort objectForKey:@"order"] boolValue]] autorelease]]];
			else
				[databaseOutline setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
		}
	}
	else
		[databaseOutline setSortDescriptors:[NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
	
	[databaseOutline selectRow: 0 byExtendingSelection:NO];
	[databaseOutline scrollRowToVisible: 0];
	
	[animationCheck setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"AutoPlayAnimation"]];
	
	activeSends = [[NSMutableDictionary dictionary] retain];
	sendLog = [[NSMutableArray array] retain];
	activeReceives = [[NSMutableDictionary dictionary] retain];
	receiveLog = [[NSMutableArray array] retain];
	
	sendQueue = [[NSMutableArray alloc] init];
	queueLock = [[NSConditionLock alloc] initWithCondition: QueueEmpty];
	[NSThread detachNewThreadSelector:@selector(runSendQueue:) toTarget:self withObject:nil];
	
	// bonjour
	bonjourPublisher = [[BonjourPublisher alloc] initWithBrowserController:self];
	bonjourBrowser = [[BonjourBrowser alloc] initWithBrowserController:self bonjourPublisher:bonjourPublisher];
	[self displayBonjourServices];
	
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"bonjourServiceName"])
	{
		[self setServiceName:[[NSUserDefaults standardUserDefaults] objectForKey:@"bonjourServiceName"]];
	}
	else
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
		[self setServiceName:myServiceName];
	}
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

- (IBAction)customize:(id)sender {
    [toolbar runCustomizationPalette:sender];
}

- (IBAction)showhide:(id)sender {
    [toolbar setVisible:![toolbar isVisible]];
}


- (void)closeAllWindows:(NSNotification *)note{
	NSLog(@"database Window make key");
	[[self window] makeKeyAndOrderFront:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[self emptyDeleteQueueThread];
	
	[deleteInProgress lock];
	[deleteInProgress unlock];
	
	[self syncReportsIfNecessary: previousBonjourIndex];
	
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

- (BOOL)windowShouldClose:(NSNotification *)aNotification
{
    [[self window] orderOut:self];
    return NO;
}

- (void) showDatabase:(id)sender
{
    [[self window] makeKeyAndOrderFront:sender];
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
        [super keyDown:event];
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
		NSLog(@"delete Queue start: %d objects", [copyArray count]);
		for( i = 0; i < [copyArray count]; i++)
			[[NSFileManager defaultManager] removeFileAtPath:[copyArray objectAtIndex: i] handler:nil];
		NSLog(@"delete Queue end");
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
					NSMutableArray  *filesArray = [[NSMutableArray alloc] initWithCapacity:0];
					
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

						
						//aPath = [aPath stringByAppendingPathComponent:@"DICOMDIR"];
						
						if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
						{
							long	i;
							
							[self addDICOMDIR: aPath :filesArray];
							
							switch ([[NSUserDefaults standardUserDefaults] integerForKey: @"STILLMOVIEMODE"])
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
					
					NSMutableArray	*newfilesArray = [self copyFilesIntoDatabaseIfNeeded:filesArray];
					
					if( newfilesArray == filesArray) mountedVolume = YES;
					
					filesArray = newfilesArray;
					
					NSArray	*newImages = [self addFilesToDatabase:filesArray :YES];
					
					mountedVolume = NO;
					
					[self outlineViewRefresh];
					
					if( [newImages count] > 0)
					{
						NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
						
						[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
						[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
					}
					
					[filesArray release];
				}
            }
        }
    }
	
	if( found == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"No CD or DVD has been found...",@"No CD or DVD has been found..."),NSLocalizedString(@"Please insert a DICOM CD or DVD.",@"Please insert a DICOM CD or DVD."), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

-(BOOL) isItCD:(NSArray*) pathFilesComponent
{
	if( [[[pathFilesComponent objectAtIndex: 1] uppercaseString] isEqualToString:@"VOLUMES"])
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

-(void) checkIncomingThread:(id) sender
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
    NSString        *INpath = [documentsDirectory() stringByAppendingString:INCOMINGPATH];
	NSString		*ERRpath = [documentsDirectory() stringByAppendingString:ERRPATH];
    NSString        *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
	BOOL			isDir = YES, routineActivated = [[NSUserDefaults standardUserDefaults] boolForKey: @"ROUTINGACTIVATED"];
	BOOL			DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"];
	NSArray			*RoutingCalendarsArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"ROUTING CALENDARS"];
	long			i;
	
	[incomingProgress performSelectorOnMainThread:@selector( startAnimation:) withObject:self waitUntilDone:NO];
	
	//NSLog(@"Scan folder START");
	
	if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO)
	{	
		//need to resolve aliases and symbolic links
		INpath = [self folderPathResolvingAliasAndSymLink:INpath];
		OUTpath = [self folderPathResolvingAliasAndSymLink:OUTpath];
		ERRpath = [self folderPathResolvingAliasAndSymLink:ERRpath];

		
		NSString        *pathname;
		NSMutableArray  *filesArray = [[NSMutableArray alloc] initWithCapacity:0];
		
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
					BOOL	isDicomFile;
					NSString *dstPath;
					dstPath = [OUTpath stringByAppendingString:[srcPath lastPathComponent]];
					
					isDicomFile = [DicomFile isDICOMFile :srcPath];
					
					if( isDicomFile == YES		||
						(([DicomFile isFVTiffFile:srcPath]		||
						[DicomFile isTiffFile:srcPath]			||
						[DicomFile isXMLDescriptedFile:srcPath]	||
						[DicomFile isXMLDescriptorFile:srcPath]) 
						&& [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == NO))
					{
//						dstPath = [self getNewFileDatabasePath:@"dcm"];
						
						if (isDicomFile)
						{
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
							//routing routine
							
							if( routineActivated)
							{
								if ([[NSWorkspace sharedWorkspace] fullPathForApplication:@"iCal"])
								{
									NSEnumerator	*enumerator	= [RoutingCalendarsArray objectEnumerator];
									NSString		*calendar;
									
									while (calendar = [enumerator nextObject])
									{
										DCMCalendarScript *calendarScript = [[[DCMCalendarScript alloc] initWithCalendar:calendar] autorelease];
										NSArray *routingDestination = [calendarScript routingDestination];
										if (routingDestination)
										{
											NSLog(@"have routingDestination");
											NSEnumerator *enumerator = [routingDestination objectEnumerator];
											NSMutableArray *route;
											while (route = [enumerator nextObject]) 
												[route addObject:dstPath];
											[NSThread detachNewThreadSelector:@selector(addToQueue:) toTarget:self withObject:routingDestination];
										}
									}
								}
							}
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
						dstPath = [NSString stringWithFormat:@"%@%d", INpath, x];
						x++;
					}
					while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
									
					[[NSFileManager defaultManager] movePath:[filesArray objectAtIndex: i] toPath:dstPath handler:nil];
				}
			}
		}
		
		[filesArray release];
	}
	[checkIncomingLock unlock];
	
	[incomingProgress performSelectorOnMainThread:@selector( stopAnimation:) withObject:self waitUntilDone:NO];
	
	[pool release];
}

-(void) checkIncoming:(id) sender
{
	if( isCurrentDatabaseBonjour) return;
	if( managedObjectContext == 0L) return;
	
	if( [checkIncomingLock tryLock])
	{
	//	 NSLog(@"lock checkIncoming");
		 
		[NSThread detachNewThreadSelector: @selector(checkIncomingThread:) toTarget:self withObject: self];
	}
	else NSLog(@"checkIncoming locked...");
}

- (IBAction) deleteReport: (id) sender
{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item)
	{
		NSManagedObject *studySelected;
		
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
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
	}
}

- (IBAction) generateReport: (id) sender
{
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
				NSLog(@"generate report with plugin");
				PluginFilter* filter = [[plugin principalClass] filter];
				[filter createReportForStudy: studySelected];
				NSLog(@"end generate report with plugin");
				//[filter report: studySelected action: @"openReport"];
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
						if (structuredReportController)
							[structuredReportController release];
						structuredReportController = [[StructuredReportController alloc] initWithStudy:studySelected];
					}
					
				}
				else
				{
					if (reportsMode < 3) {
						Reports	*report = [[Reports alloc] init];					
						[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/REPORTS/", documentsDirectory()] type:reportsMode];					
						[report release];
					}
					else {
						//structured report code here
						//Osirix will open DICOM Structured Reports
						//Release Old Controller
						if (structuredReportController)
							[structuredReportController release];
						structuredReportController = [[StructuredReportController alloc] initWithStudy:studySelected];
					}
				}
			}
		}
	}
}

- (void) exportDICOMFile:(id) sender
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
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the DICOM files:",0L)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",0L)];
	[sPanel setTitle: NSLocalizedString(@"Export",0L)];
	[sPanel setCanCreateDirectories:YES];
	[sPanel setAccessoryView:exportAccessoryView];
	
	if ([sPanel runModalForDirectory:0L file:0L types:0L] == NSFileHandlingPanelOKButton)
	{
		int					i, t;
		NSString			*dest, *path = [[sPanel filenames] objectAtIndex:0];
		Wait                *splash = [[Wait alloc] initWithString:@"Export..."];
		BOOL				addDICOMDIR = [addDICOMDIRButton state];
				
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToExport count]];

		for( i = 0; i < [filesToExport count]; i++)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSString		*extension = [[filesToExport objectAtIndex:i] pathExtension];
			
			if( [curImage valueForKey: @"fileType"])
			{
				if( [[curImage valueForKey: @"fileType"] isEqualToString:@"DICOM"]) extension = [NSString stringWithString:@"dcm"];
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
				
				[name replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"," withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"^" withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"/" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"-" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				tempPath = [path stringByAppendingPathComponent:name];
			}
			
			// Find the DICOM-PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( i == 0)
				{
					[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
					[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
				}
			}
			if (!addDICOMDIR)		
				tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.studyName"] ];
			else {				
				NSMutableString *name;
				if ([[curImage valueForKeyPath: @"series.study.studyName"] length] > 8 )
					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.studyName"] substringToIndex:7] uppercaseString]];
				else
					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.studyName"]uppercaseString]];
					
				NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];	
				
				[name replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"," withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"^" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"/" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"-" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				tempPath = [tempPath stringByAppendingPathComponent:name];
			}
				
			// Find the DICOM-STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			if (!addDICOMDIR ) {
				NSMutableString *seriesStr = [NSMutableString stringWithString: [curImage valueForKeyPath: @"series.name"]];
				[seriesStr replaceOccurrencesOfString: @"/" withString: @"_" options: NSLiteralSearch range: NSMakeRange(0,[seriesStr length])];
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
				
				[name replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [name length])];  
				[name replaceOccurrencesOfString:@"," withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"^" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"/" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"-" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				tempPath = [tempPath stringByAppendingPathComponent:name];
			}
			
			// Find the DICOM-SERIE folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
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
			
			if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
			{
				[[NSFileManager defaultManager] copyPath:[[[filesToExport objectAtIndex:i] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dest stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
			}
				
			[splash incrementBy:1];
			[pool release];
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
				
				[name replaceOccurrencesOfString:@" " withString:@"" options:nil range:NSMakeRange(0, [name length])];  
				[name replaceOccurrencesOfString:@"," withString:@"" options:nil range:NSMakeRange(0, [name length])]; 
				[name replaceOccurrencesOfString:@"^" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"/" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				[name replaceOccurrencesOfString:@"-" withString:@"" options:nil range:NSMakeRange(0, [name length])];
				
				NSString *tempPath = [path stringByAppendingPathComponent:name];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath:[tempPath stringByAppendingPathComponent:@"DICOMDIR"]] == NO)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					NSLog(@" ADD dicomdir");
					NSTask              *theTask;
					NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+id", tempPath,  nil];
					
					theTask = [[NSTask alloc] init];
					[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];	// DO NOT REMOVE !
					[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/dcmmkdir"]];
					[theTask setCurrentDirectoryPath:tempPath];
					[theTask setArguments:theArguments];		

					[theTask launch];
					[theTask waitUntilExit];
					[theTask release];
				}
			}
		}
		
		//close progress window	
		[splash close];
		[splash release];
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
		
		if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) filesToBurn = [self filesForDatabaseMatrixSelection:managedObjects];
		else filesToBurn = [self filesForDatabaseOutlineSelection:managedObjects];
		
		burnerWindowController = [[BurnerWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects  releaseAfterBurn:YES];

		[burnerWindowController showWindow:self];
	}
	else
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"OsiriX" 
			defaultButton:@"OK" 
			alternateButton:nil 
			otherButton:nil 
			informativeTextWithFormat:@"Burn in Progress. Please Wait"];
		[alert runModal];
	}
	//send to OsirixBurner

}

- (IBAction) anonymizeDICOM:(id) sender{
	NSMutableArray *paths = [NSMutableArray array];
	NSMutableArray *dicomFiles2Anonymize = [NSMutableArray array];
	NSMutableArray *filesToAnonymize;
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) filesToAnonymize = [[self filesForDatabaseMatrixSelection: dicomFiles2Anonymize] retain];
	else filesToAnonymize = [[self filesForDatabaseOutlineSelection: dicomFiles2Anonymize] retain];
	
    [anonymizerController showWindow:self];
	NSEnumerator *enumerator = [filesToAnonymize objectEnumerator];
	NSString *file;
	while (file = [enumerator nextObject]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString	*extension = [file pathExtension];
		if([extension isEqualToString:@"" ]) extension = [NSString stringWithString:@"dcm"];
		else {   // Added by rbrakes - check to see if "extension" includes only numbers (UID perhaps?).
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


- (void) printDICOM:(id) sender
{
	
}

- (void) loadDICOMFromiPod
{
	NSArray *allVolumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	int i, x, index;

	for (i=0;i<[allVolumes count];i++)
	{
		NSString *iPodControlPath = [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"iPod_Control"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath])
		{
			NSString *volumeName = [[allVolumes objectAtIndex:i] lastPathComponent];
			
			NSLog(@"Got an iPod volume named %@", volumeName);
			
			NSString	*path = [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"DICOM"];
			
			[iPodDirectory release];
			iPodDirectory = [path retain];
			
			// Find the DICOM folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:path]) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
			
			NSArray*	filenames = [NSArray arrayWithObject: path];
			
			mountedVolume = YES;
			[self addFilesAndFolderToDatabase: filenames];
			mountedVolume = NO;
		}
	}
}

- (IBAction) sendiPod:(id) sender
{
	NSArray		*allVolumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	int			i, x, t, index;
	BOOL		found = NO;

	for (i=0;i<[allVolumes count];i++)
	{
		NSString *iPodControlPath = [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"iPod_Control"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath])
		{
			found = YES;
			
			NSString *volumeName = [[allVolumes objectAtIndex:i] lastPathComponent];
			
			NSLog(@"Got an iPod volume named %@", volumeName);
			
			NSMutableArray *dicomFiles2Copy = [NSMutableArray array];
			
			NSMutableArray *files2Copy;
			
			if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) files2Copy = [self filesForDatabaseMatrixSelection: dicomFiles2Copy];
			else files2Copy = [self filesForDatabaseOutlineSelection: dicomFiles2Copy];
			
			if( files2Copy)
			{
				NSString	*path = [[allVolumes objectAtIndex:i] stringByAppendingPathComponent:@"DICOM"];
				BOOL		error = NO;
				
				// Find the DICOM folder
				if (![[NSFileManager defaultManager] fileExistsAtPath:path]) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
				
				
				Wait                *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying to your iPod",@"Copying to your iPod")];
				
				[splash showWindow:self];
				[[splash progress] setMaxValue:[files2Copy count]];
				
				for( x = 0 ; x < [files2Copy count]; x++)
				{
					NSString			*dstPath, *srcPath = [files2Copy objectAtIndex:x];
					NSString			*extension = [srcPath pathExtension];
					NSManagedObject		*curImage = [dicomFiles2Copy objectAtIndex:x];
					NSString			*tempPath;
					
					if( [[srcPath stringByDeletingLastPathComponent] isEqualToString:path] == NO && [[curImage valueForKey: @"iPod"] boolValue] == NO) // Is this file already on the iPod?
					{
						if( [curImage valueForKey: @"fileType"])
						{
							if( [[curImage valueForKey: @"fileType"] isEqualToString:@"DICOM"]) extension = [NSString stringWithString:@"dcm"];
						}
						
						if([extension isEqualToString:@""]) extension = [NSString stringWithString:@"dcm"];
						
						tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"] ];
						// Find the DICOM-PATIENT folder
						if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
						else
						{
							if( x == 0)
							{
								[[NSFileManager defaultManager] removeFileAtPath:tempPath handler:nil];
								[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
							}
						}
						
						tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.studyName"] ];
						// Find the DICOM-STUDY folder
						if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
						
						
						tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.name"] ];
						
						tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
						// Find the DICOM-SERIE folder
						if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
						
						
						dstPath = [NSString stringWithFormat:@"%@/%d.%@", tempPath, [[curImage valueForKey:@"instanceNumber"] intValue], extension];
						
						t = 2;
						while( [[NSFileManager defaultManager] fileExistsAtPath: dstPath])
						{
							dstPath = [NSString stringWithFormat:@"%@/%d #%d.%@", tempPath, [[curImage valueForKey:@"instanceNumber"] intValue], t, extension];
							t++;
						}
						
						BOOL success = [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil];
						
						if( success == NO)
						{
							NSRunAlertPanel( NSLocalizedString(@"iPod Error", nil), NSLocalizedString(@"OsiriX cannot copy these files to the iPod. Not enough room?", nil), nil, nil, nil);
							x = [files2Copy count];
						}
						
						if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
						{
							[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
						}
					}
					else NSLog( @"Already on the iPod!");
					
					[splash incrementBy:1];
				}
				
				[splash close];
				[splash release];
			}
			
			i = [allVolumes count]; // exit the loop...
		}
	}
	
	if( found == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"iPod?",@"iPod?"), NSLocalizedString(@"No iPod is currently connected to your computer",@"No iPod is currently connected to your computer"), NSLocalizedString(@"OK",nil),nil, nil);
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
				
				NSString        *dstPath, *OUTpath = [documentsDirectory() stringByAppendingString:DATABASEPATH];
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
}

- (IBAction) sendiDisk:(id) sender
{
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
				
				Wait                *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying to your iDisk",@"Copying to your iPod")];
				
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
							if( [[curImage valueForKey: @"fileType"] isEqualToString:@"DICOM"])
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
								[mySession removeFileAtPath:tempPath handler:nil];
								[mySession createDirectoryAtPath:tempPath attributes:nil];
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
	
	if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) files = [self filesForDatabaseMatrixSelection:objects];
	else files = [self filesForDatabaseOutlineSelection:objects];
	
	[self selectServer: objects];
}


- (void) queryDICOM:(id) sender
{
	[[self window] makeKeyAndOrderFront:sender];
	
    if(!queryController)
		queryController = [[QueryController alloc] init];
    [queryController showWindow:self];
}

-(void)volumeMount:(NSNotification *)notification
{
	NSLog(@"volume mounted");

	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"MOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	NSLog(sNewDrive);
	
	if( [self isItCD:[sNewDrive pathComponents]] == YES)
	{
		[self ReadDicomCDRom:self];
	}
	
	[self loadDICOMFromiPod];
}

-(void) removeAllMounted
{
	long		i, x;

	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = [self managedObjectContext];
	NSManagedObjectModel		*model = [self managedObjectModel];
	
	[context lock];
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
	[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
	NSError	*error = 0L;
	error = 0L;
	NSArray *imagesArray = [context executeFetchRequest:dbRequest error:&error];
	
	@try
	{
		if( [imagesArray count] > 0)
		{
			NSMutableArray			*studiesArray = [NSMutableArray arrayWithCapacity:0];
			NSMutableArray			*viewersList = [NSMutableArray arrayWithCapacity:0];
			
			for( i = 0; i < [[NSApp windows] count]; i++)
			{
				if( [[[[NSApp windows] objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) [viewersList addObject: [[[NSApp windows] objectAtIndex:i] windowController]];
			}
		
			// Find unavailable files
			for( i = 0; i < [imagesArray count]; i++)
			{
				NSManagedObject	*study = [[imagesArray objectAtIndex:i] valueForKeyPath:@"series.study"];
				
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
		NSLog( @"RemoveAllMounted");
	}
	
	[context unlock];
}

-(void)volumeUnmount:(NSNotification *)notification
{
	long		i, x;
	BOOL		needsUpdate = NO;
	NSRange		range;
	
	NSLog(@"volume unmounted");
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"UNMOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];	//uppercaseString];
	NSLog(sNewDrive);
	
	range.location = 0;
	range.length = [sNewDrive length];
	
	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = [self managedObjectContext];
	NSManagedObjectModel		*model = [self managedObjectModel];
	
	[context lock];
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
	[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
	NSError	*error = 0L;
	NSArray *imagesArray = [context executeFetchRequest:dbRequest error:&error];
//	NSMutableArray *studiesArray = [NSMutableArray arrayWithCapacity:0];
	
	if( [imagesArray count] > 0)
	{
		NSMutableArray			*viewersList = [NSMutableArray arrayWithCapacity:0];
		
		for( i = 0; i < [[NSApp windows] count]; i++)
		{
			if( [[[[NSApp windows] objectAtIndex:i] windowController] isKindOfClass:[ViewerController class]]) [viewersList addObject: [[[NSApp windows] objectAtIndex:i] windowController]];
		}
		
		Wait                *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Unmounting volume...",@"Unmounting volume")];
		[splash showWindow:self];

		[[splash progress] setMaxValue:[imagesArray count]/50];
		
		@try
		{
			// Find unavailable files
			for( i = 0; i < [imagesArray count]; i++)
			{
				if( [[[imagesArray objectAtIndex:i] valueForKey:@"completePath"] compare:sNewDrive options:NSCaseInsensitiveSearch range:range] == 0)
				{
					NSManagedObject	*study = [[imagesArray objectAtIndex:i] valueForKeyPath:@"series.study"];
					
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
		}
		
		[splash close];
		[splash release];
				
		if( needsUpdate)
		{
			[self saveDatabase: currentDatabasePath];
		}
		
		[self outlineViewRefresh];
	}
	
	[context unlock];
}

- (void)storeSCPComplete:(id)sender{
	//release storescp when done
	[sender release];
}

- (void)runSendQueue:(id)object{

	while (YES) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[queueLock lockWhenCondition:QueueHasData];
		NSArray *destination = [sendQueue objectAtIndex:0];
		NSString *filesToSend = nil;
		NSString *syntax = nil;
		NSDictionary *server = nil;
		DCMTransferSyntax *ts = nil;
		NSLog(@"destination count : %d", [destination count]);
		if ([destination count] == 3) {
			//old style layout.
			//get syntax
			/* 
			index 0: Server description
			index 1: TS
			index 2: file
			*/
			
			syntax = [destination objectAtIndex:1];
			//get Transfer Syntax and compression in indicated
			int compression = DCMLosslessQuality;
			if ([syntax isEqualToString:@"Explicit Little Endian"])
				ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
			else if ([syntax isEqualToString:@"JPEG 2000 Lossless"])
				ts = [DCMTransferSyntax JPEG2000LosslessTransferSyntax];
			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 10:1"]) {
				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
				compression = DCMHighQuality;
			}
			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 20:1"]) {
				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
				compression = DCMMediumQuality;
			}
			else if ([syntax isEqualToString:@"JPEG 2000 Lossy 50:1"]) {
				ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
				compression =  DCMLowQuality;
			}
			else if ([syntax isEqualToString:@"JPEG Lossless"])
				ts = [DCMTransferSyntax JPEGLosslessTransferSyntax];
			else if ([syntax isEqualToString:@"JPEG High Quality (9)"]) {
				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
				compression = DCMHighQuality;
			}
			else if ([syntax isEqualToString:@"JPEG High Quality (8)"]) {
				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
				compression =  DCMMediumQuality;
			}
			else if ([syntax isEqualToString:@"JPEG High Quality (7)"]) {
				ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
				compression =  DCMLowQuality;
			}
		// getServer
			NSArray					*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
			NSEnumerator			*enumerator			= [serversArray objectEnumerator];
			NSDictionary			*aServer;
			
			
			while (aServer = [enumerator nextObject]){
				if ([[aServer objectForKey:@"Description"] isEqualToString:[destination objectAtIndex:0]] )  {
					server = aServer;
					break;
				}
			}
			// file path
			filesToSend = [NSArray arrayWithObject:[destination objectAtIndex:2]];
			// only send if we have a server, Transfer Syntax and file
			if (server && ts && [[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:2]]) {	

				NSArray *objects = [NSArray arrayWithObjects:filesToSend, [NSNumber numberWithInt:compression], ts, [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"],    nil];
				NSArray *keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", nil];
				NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
				DCMStoreSCU *storeSCU = [DCMStoreSCU sendWithParameters:(NSDictionary *)params];
				
			}
			else {
				if (!server)
					NSLog(@"Routing:Not a valid DICOM destination");
				if (!ts)
					NSLog(@"Routing:Not a valid transfer syntax");
				if (![[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:2]])
					NSLog(@"Routing:Invalid File Path");
			}
				
		}
		
		else if  ([destination count] == 2){
			// New style routing.
			NSArray					*serversArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
			NSEnumerator			*serverEnumerator	= [serversArray objectEnumerator];
			NSDictionary			*aServer;
			
			NSString				*description		= nil;			
			NSString				*routeName			= [destination objectAtIndex:0];
			NSArray					*routes				= [[NSUserDefaults standardUserDefaults] arrayForKey:@"RoutingRules"];
			NSEnumerator			*enumerator			= [routes objectEnumerator];
			NSDictionary			*aRoute				= nil;
			NSDictionary			*route				= nil;
			int compression = DCMLosslessQuality;
			
			/* 
			index 0: Server Description
			index 2: file
			*/
			
			
			
			while (aRoute = [enumerator nextObject]) {				
				NSString *name = [aRoute objectForKey:@"name"];
				if ([name isEqualToString:routeName]){
						route = aRoute;
						break;
				}				
			}
			
			
			//we have a route. Now get info
			if (route) {
				description = [route objectForKey:@"Description"];
				//get server. Also check for Bonjour DICOM. Not added yet
				while (aServer = [serverEnumerator nextObject]){
					if ([[aServer objectForKey:@"Description"] isEqualToString:description] )  {
						server = aServer;
						break;
					}
				}
				
		
				//get TS
				int tsIndex = [[route objectForKey:@"transferSyntax"] intValue];
				switch (tsIndex) {
					case 0: 
						ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
						break;
					case 1:
						ts = [DCMTransferSyntax JPEG2000LosslessTransferSyntax];
						break;						
					case 2:
						ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
						compression = DCMHighQuality;
						break;
					case 3:
						ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
						compression = DCMMediumQuality;
						break;
					case 4:
						ts = [DCMTransferSyntax JPEG2000LossyTransferSyntax];
						compression =  DCMLowQuality;
						break;
					case 5:
						ts = [DCMTransferSyntax JPEGLosslessTransferSyntax];
						break;
					case 6:
						ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
						compression = DCMHighQuality;
						break;
					case 7:
						ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
						compression =  DCMMediumQuality;
						break;
					case 8:
						ts = [DCMTransferSyntax JPEGExtendedTransferSyntax];
						compression =  DCMLowQuality;
						break;
					default:
						ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];

				}			

			}
			
			filesToSend = [NSArray arrayWithObject:[destination objectAtIndex:1]];
			BOOL sendFile = YES;
			NSArray *rules = [route objectForKey:@"rules"];
			//need to load DICOM and see if file matches the rules
			if (rules) {
				sendFile = NO;
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:[destination objectAtIndex:1] decodingPixelData:NO];
				NSEnumerator *ruleEnumerator = [rules objectEnumerator];
				NSDictionary *rule;
				while (rule = [ruleEnumerator nextObject]) {
					int attrIndex = [[rule objectForKey:@"attribute"] intValue];
					NSString *attrName = nil;
					NSString *keyValue = [rule objectForKey:@"keyValue"];
					switch (attrIndex) {
						case 0: attrName = @"Modality"; break;
						case 1:	attrName = @"InstitutionName"; break;
						case 2:	attrName = @"ReferringPhysiciansName"; break;
						case 3:	attrName = @"PerformingPhysiciansName"; break;
					}
					if ([[dcmObject attributeValueWithName:attrName] rangeOfString:keyValue options:NSCaseInsensitiveSearch].location != NSNotFound)
						sendFile = YES;
					else
						sendFile = NO;
				}
			}


			if (sendFile && server && ts && [[NSFileManager defaultManager] fileExistsAtPath:[destination objectAtIndex:1]]) {	

				//NSArray *objects = [NSArray arrayWithObjects:filesToSend, [NSNumber numberWithInt:compression], ts, [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"],    nil];
				//NSArray *keys = [NSArray arrayWithObjects:@"filesToSend", @"compression", @"transferSyntax", @"callingAET", @"calledAET", @"hostname", @"port", nil];
				//NSDictionary *params = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
				//DCMStoreSCU *storeSCU = [DCMStoreSCU sendWithParameters:(NSDictionary *)params];
				
				DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"] 
										calledAET:[server objectForKey:@"AETitle"] 
										hostname:[server objectForKey:@"Address"] 
										port:[[server objectForKey:@"Port"] intValue] 
										filesToSend:(NSArray *)filesToSend
										transferSyntax:[[server objectForKey:@"Transfer Syntax"] intValue] 
										compression: 1.0
										extraParameters:nil];
				[storeSCU run:self];
				[storeSCU release];
				
				
			}
			//NSLog(@"New style Routing Information");
		}
		
		[sendQueue removeObjectAtIndex:0];
		[queueLock unlockWithCondition:([sendQueue count] ? QueueHasData : QueueEmpty)];
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.04]];
		[pool release];
	}	
}

- (void)addToQueue:(NSArray *)array{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[array retain];
	[queueLock lock];
	//NSLog(@"AddToQueue:%@", [array description]);
	[sendQueue mergeWithArray:array];
	[queueLock unlockWithCondition:QueueHasData];
	[array release];
	[pool release];
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
						ts = [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax];
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
					[dcmObject writeToFile:tempFilename withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
				} 
			}
			else
				NSLog(@"Not enough data");
		}
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
		[toolbarItem setToolTip: NSLocalizedString(@"Query and retrieve a DICOM study from your PACS archive",@"Query and retrieve a DICOM study from your PACS archive")];
		[toolbarItem setImage: [NSImage imageNamed: QueryToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(queryDICOM:)];
    }
    else if ([itemIdent isEqualToString: SendToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Send",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to your PACS archive",@"Send selected study/series to your PACS archive")];
		[toolbarItem setImage: [NSImage imageNamed: SendToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(export2PACS:)];
    }
	else if ([itemIdent isEqualToString: iPodToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"iPod",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"iPod",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Send selected study/series to your iPod",nil)];
		[toolbarItem setImage: [NSImage imageNamed: iPodToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(sendiPod:)];
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
    else if ([itemIdent isEqualToString: PrintToolbarItemIdentifier]) {
		
		[toolbarItem setLabel: NSLocalizedString(@"Print",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Print",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Print selected study/series to a DICOM printer",nil)];
		[toolbarItem setImage: [NSImage imageNamed: PrintToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(printDICOM:)];
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
        [toolbarItem setToolTip: NSLocalizedString(@"Delete selected exams from the database",nil)];
		[toolbarItem setImage: [NSImage imageNamed: TrashToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(delItem:)];
    }
	else if ([itemIdent isEqualToString: ReportToolbarItemIdentifier]) {
        
		[toolbarItem setLabel: NSLocalizedString(@"Report",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Report",nil)];
        [toolbarItem setToolTip: NSLocalizedString(@"Create/Open a report for selected study",nil)];
		[toolbarItem setImage: [NSImage imageNamed: ReportToolbarItemIdentifier]];
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
		[toolbarItem setTarget: albumDrawer];
		[toolbarItem setAction: @selector(toggle:)];
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
	else if ([itemIdent isEqualToString: DatabaseWindowToolbarItemIdentifier]) {		
		[toolbarItem setLabel: NSLocalizedString(@"Database", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Database", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Close viewers and open Database window", nil)];
		[toolbarItem setImage: [NSImage imageNamed: DatabaseWindowToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(databaseWindow:)];
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


- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	ImportToolbarItemIdentifier,
										CDRomToolbarItemIdentifier,
										QueryToolbarItemIdentifier,
										ExportToolbarItemIdentifier,
										AnonymizerToolbarItemIdentifier,
										SendToolbarItemIdentifier,
										iPodToolbarItemIdentifier,
										iDiskSendToolbarItemIdentifier,
										iDiskGetToolbarItemIdentifier,
										ViewerToolbarItemIdentifier,
										MovieToolbarItemIdentifier,
										BurnerToolbarItemIdentifier,
										ToggleDrawerToolbarItemIdentifier,
										NSToolbarFlexibleSpaceItemIdentifier,
										ReportToolbarItemIdentifier,
										TrashToolbarItemIdentifier,
										SearchToolbarItemIdentifier,
										TimeIntervalToolbarItemIdentifier,
										nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
	
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
											iPodToolbarItemIdentifier,
											iDiskSendToolbarItemIdentifier,
											iDiskGetToolbarItemIdentifier,
											ViewerToolbarItemIdentifier,
											MovieToolbarItemIdentifier,
											BurnerToolbarItemIdentifier,
											TrashToolbarItemIdentifier,
											ReportToolbarItemIdentifier,
											ToggleDrawerToolbarItemIdentifier,
											DatabaseWindowToolbarItemIdentifier,
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
		if ([[toolbarItem itemIdentifier] isEqualToString: iPodToolbarItemIdentifier]) return NO;
		
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

- (NSString*)  getLocalDCMPath: (NSManagedObject*) obj :(long) no
{
	if( isCurrentDatabaseBonjour)
	{
		return [bonjourBrowser getDICOMFile: [bonjourServicesList selectedRow]-1 forObject: obj noOfImages: no];
	}
	else return [obj valueForKey:@"completePath"];
}

- (void) setBonjourDownloading:(BOOL) v { bonjourDownloading = v;}

- (void)setServiceName:(NSString*) title
{
	[bonjourPublisher setServiceName: title];
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

- (IBAction) bonjourServiceClicked:(id)sender
{
    int index = [bonjourServicesList selectedRow]-1;
	
	[bonjourReportFilesToCheck removeAllObjects];
	
	if( index >= 0)
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
	else
	{
		NSString	*path = [documentsDirectory() stringByAppendingString:DATAFILEPATH];
		
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
	return [documentsDirectory() stringByAppendingString:DATAFILEPATH];
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
	
	result = [filter prepareFilter: nil];
	[filter filterImage:name];
	NSLog(@"executeFilter %@", [filter description]);
	if( result)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin", nil), nil, nil, nil);
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
					
					predicate = [NSPredicate predicateWithFormat: @"(name LIKE[c] %@) OR (patientID LIKE[c] %@) OR (id LIKE[c] %@) OR (comment LIKE[c] %@) OR (studyName LIKE[c] %@) OR (modality LIKE[c] %@) OR (accessionNumber LIKE[c] %@)", s, s, s, s, s, s, s];
				break;
				
				case 0:			// Patient Name
					predicate = [NSPredicate predicateWithFormat: @"name LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 1:			// Patient ID
					predicate = [NSPredicate predicateWithFormat: @"patientID LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 2:			// Study/Series ID
					predicate = [NSPredicate predicateWithFormat: @"id LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 3:			// Comments
					predicate = [NSPredicate predicateWithFormat: @"comment LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 4:			// Study Description
					predicate = [NSPredicate predicateWithFormat: @"studyName LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 5:			// Modality
					predicate = [NSPredicate predicateWithFormat:  @"modality LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 6:			// Accession Number 
					predicate = [NSPredicate predicateWithFormat:  @"accessionNumber LIKE[c] %@", [NSString stringWithFormat:@"*%@*", _searchString]];
				break;
				
				case 100:			// Advanced
					
				break;
			}
			
		}
	return predicate;
}



- (NSArray *)databaseSelection{
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

- (IBAction)databaseWindow:(id)sender{
	NSEnumerator *enumerator = [[NSApp windows] objectEnumerator];
	NSWindow *window;
	while (window = [enumerator nextObject]) {
		if (![window isEqual:[self window]])
			[window close];
	}
	[[self window] makeKeyAndOrderFront:sender];
}


@end
