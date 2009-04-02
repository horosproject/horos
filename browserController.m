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

#import <DiscRecording/DRDevice.h>
#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "AnonymizerWindowController.h"
#import "DicomSeries.h"
#import "DicomImage.h"
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
#import "SearchWindowController.h"
#import "Wait.h"
#import "WaitRendering.h"
#import "DotMacKit/DotMacKit.h"
#import "BurnerWindowController.h"
#import "DCMTransferSyntax.h"
#import "DCMAttributeTag.h"
#import "DCMPixelDataAttribute.h"
#import "DCMCalendarDate.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMDirectory.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMDirectory.h>
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
#import "StructuredReportController.h"
#import "QTExportHTMLSummary.h"
#import "BrowserControllerDCMTKCategory.h"
#import "BrowserMatrix.h"
#import "DicomStudy.h"
#import "PluginManager.h"
#import "XMLController.h"
#import "MutableArrayCategory.h"

#define DATABASEVERSION @"2.4"
#define DATABASEPATH @"/DATABASE.noindex/"
#define DECOMPRESSIONPATH @"/DECOMPRESSION/"
#define INCOMINGPATH @"/INCOMING.noindex/"
#define ERRPATH @"/NOT READABLE/"
#define DATABASEFPATH @"/DATABASE.noindex"
#define DATAFILEPATH @"/Database.sql"

//enum DCM_CompressionQuality {DCMLosslessQuality, DCMHighQuality, DCMMediumQuality, DCMLowQuality};

BrowserController  *browserWindow = nil;

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/storage/IOMedia.h>
#include <IOKit/storage/IOCDMedia.h>
#include <IOKit/storage/IODVDMedia.h>

static NSString *albumDragType = @"Osirix Album drag";
static BOOL loadingIsOver = NO;
static NSMenu *contextual = nil;
static NSMenu *contextualRT = nil;  // Alternate menus for RT objects (which often don't have images)
static int DicomDirScanDepth;

extern void compressJPEG (int inQuality, char* filename, unsigned char* inImageBuffP, int inImageHeight, int inImageWidth, int monochrome);
extern BOOL hasMacOSXTiger();
extern BOOL hasMacOSXLeopard();

extern int delayedTileWindows;
extern AppController *appController;
extern NSThread *mainThread;
extern BOOL NEEDTOREBUILD, COMPLETEREBUILD;
extern NSMutableDictionary *DATABASECOLUMNS;
extern NSRecursiveLock *PapyrusLock;

long DATABASEINDEX;

//static void
//sig_alrm(int signo)
//{
//    /* nothing to do, just return to wake up the pause */
//}

NSString *asciiString( NSString* name )
{
	NSMutableString	*outString;
	
	NSData *asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	
	outString = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
	[BrowserController replaceNotAdmitted:outString];
	
	if( [outString length] == 0)
		outString = @"AAA";
	
	return outString;
}

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
static NSString*	XMLToolbarItemIdentifier			= @"XML.icns";
static NSString*	OpenKeyImagesAndROIsToolbarItemIdentifier	= @"ROIsAndKeys.tif";
static NSString*	OpenKeyImagesToolbarItemIdentifier	= @"Keys.tif";
static NSString*	OpenROIsToolbarItemIdentifier	= @"ROIs.tif";

static NSTimeInterval	gLastActivity = 0;
static BOOL DICOMDIRCDMODE = NO;
static BOOL copyThread = YES, dontShowOpenSubSeries = NO;

static NSArray*	statesArray = nil;

@class DCMTKStudyQueryNode;

@synthesize checkIncomingLock;
@synthesize DateTimeFormat;
@synthesize DateOfBirthFormat;
@synthesize TimeFormat;
@synthesize TimeWithSecondsFormat;
@synthesize DateTimeWithSecondsFormat;
@synthesize matrixViewArray;
@synthesize oMatrix;
@synthesize COLUMN;
@synthesize databaseOutline;
@synthesize albumTable;
@synthesize currentDatabasePath;

@synthesize isCurrentDatabaseBonjour;
@synthesize bonjourDownloading;
@synthesize bonjourSourcesBox;
@synthesize bonjourServiceName;
@synthesize bonjourPasswordTextField = bonjourPassword;
@synthesize bonjourSharingCheck;
@synthesize bonjourPasswordCheck;
@synthesize bonjourBrowser;

@synthesize searchString = _searchString;
@synthesize fetchPredicate = _fetchPredicate;
@synthesize filterPredicate = _filterPredicate;
@synthesize filterPredicateDescription = _filterPredicateDescription;

@synthesize rtstructProgressBar, rtstructProgressPercent;

@synthesize pluginManagerController;

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
		
		[NSThread sleepForTimeInterval: 0.2];
	}
	
	NSLog( @"******* tryLockDuring failed for this lock: %@ (%d sec)", c, sec);
	
	return NO;
}

+ (BrowserController*) currentBrowser { return browserWindow; }
+ (NSArray*) statesArray { return statesArray; }
+ (void) updateActivity
{
	gLastActivity = [NSDate timeIntervalSinceReferenceDate];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Add DICOM Database functions

- (NSString*)getNewFileDatabasePath: (NSString*)extension
{
	return [self getNewFileDatabasePath: extension dbFolder: self.documentsDirectory];
}

- (NSString*)getNewFileDatabasePath: (NSString*)extension dbFolder: (NSString*)dbFolder
{
	NSString        *OUTpath = [dbFolder stringByAppendingPathComponent:DATABASEPATH];
	NSString		*dstPath;
	NSString		*subFolder;
	long			subFolderInt;
	
	[AppController createNoIndexDirectoryIfNecessary: OUTpath];
	
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
	// Reload series if needed
	for( ViewerController *vc in vl )
	{
		if( [[vc window] isVisible] && [[vc imageView] mouseDragging] == NO)
		{
			[self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: [[[vc fileList] objectAtIndex: 0] valueForKey:@"series"]]] movie: NO viewer : vc keyImagesOnly: NO];
		}
	}
	
	[[QueryController currentQueryController] refresh: self];
}

- (void) rebuildViewers: (NSMutableArray*) vlToRebuild
{	
	// Refresh preview matrix if needed
	for( ViewerController *vc in vlToRebuild )
	{
		if( [[vc window] isVisible] && [[vc imageView] mouseDragging] == NO)
		{
			[vc buildMatrixPreview: NO];
		}
	}
}

- (void) setDockLabel:(NSString*) label
{
	[[[NSApplication sharedApplication] dockTile] setBadgeLabel: label];
	[[[NSApplication sharedApplication] dockTile] display];
}

- (void) setGrowlMessage:(NSString*) message
{
	[appController growlTitle: NSLocalizedString( @"Incoming Files", nil) description: message name: @"newfiles"];
}
					
- (void) callAddFilesToDatabaseSafe: (NSArray*) newFilesArray
{
	NSLog( @"ERROR callAddFilesToDatabaseSafe is not AVAILABLE ANYMORE !");

	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSFileManager		*fm = [NSFileManager defaultManager];
	NSString			*tempDirectory = [[self documentsDirectory] stringByAppendingPathComponent:@"/TEMP/"];
	NSString			*arrayFile = [tempDirectory stringByAppendingPathComponent:@"array.plist"];
	NSString			*databaseFile = [tempDirectory stringByAppendingPathComponent:@"database.plist"];
	NSString			*modelFile = [tempDirectory stringByAppendingPathComponent:@"model.plist"];
	
	[fm removeFileAtPath:arrayFile handler:nil];
	[fm removeFileAtPath:databaseFile handler:nil];
	[fm removeFileAtPath:modelFile handler:nil];
	
	[newFilesArray writeToFile:arrayFile atomically: YES];
	[[[self documentsDirectory] stringByAppendingPathComponent:DATABASEFPATH] writeToFile:databaseFile atomically: YES encoding : NSUTF8StringEncoding error: nil];
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"] writeToFile:modelFile atomically: YES encoding : NSUTF8StringEncoding error: nil];
    [allBundles release];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setCurrentDirectoryPath: tempDirectory];
	[theTask setArguments: [NSArray arrayWithObjects:arrayFile, databaseFile, modelFile, nil]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/SafeDBRebuild"]];
	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
	
	[fm removeFileAtPath:arrayFile handler:nil];
	[fm removeFileAtPath:databaseFile handler:nil];
	[fm removeFileAtPath:modelFile handler:nil];
	
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
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	return [self addFilesToDatabase: newFilesArray onlyDICOM: onlyDICOM safeRebuild: safeProcess produceAddedFiles: produceAddedFiles parseExistingObject: parseExistingObject context: context dbFolder: [self documentsDirectory]];
}

- (NSArray*) subAddFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder
{
	NSString				*newFile;
	NSDate					*today = [NSDate date];
	NSError					*error = nil;
	NSString				*curPatientUID = nil, *curStudyID = nil, *curSerieID = nil;
	NSManagedObject			*seriesTable, *study;
	DicomImage				*image;
	NSInteger				index;
	NSString				*INpath = [dbFolder stringByAppendingPathComponent:DATABASEFPATH];
	NSString				*roiFolder = [dbFolder stringByAppendingPathComponent:@"/ROIs"];
	Wait					*splash = nil;
	NSManagedObjectModel	*model = self.managedObjectModel;
	NSMutableArray			*addedImagesArray = nil;
	NSMutableArray			*addedSeries = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray			*modifiedStudiesArray = nil;
	long					addFailed = NO;
	BOOL					DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"];
	BOOL					COMMENTSAUTOFILL = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"];
	NSString				*ERRpath = [[self documentsDirectory] stringByAppendingPathComponent:ERRPATH];
	BOOL					newStudy = NO, newObject = NO;
	NSMutableArray			*vlToRebuild = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray			*vlToReload = [NSMutableArray arrayWithCapacity: 0];
	BOOL					isCDMedia = NO, onlyDICOMROI = YES;
	NSMutableArray			*dicomFilesArray = [NSMutableArray arrayWithCapacity: [newFilesArray count]];
	
	NSString *reportsDirectory = [INpath stringByAppendingPathComponent:@"/REPORTS/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath: reportsDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath: reportsDirectory attributes:nil];
	
	if( [newFilesArray count] == 0) return [NSMutableArray arrayWithCapacity: 0];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDICOM"]) onlyDICOM = YES;
	
//#define RANDOMFILES
#ifdef RANDOMFILES
	NSMutableArray	*randomArray = [NSMutableArray array];
	for( int i = 0; i < 50000; i++)
	{
		[randomArray addObject:@"yahoo/google/osirix/microsoft"];
	}
	newFilesArray = randomArray;
#endif
	
	if( safeProcess) NSLog( @"safe Process DB process");
	
	if( mainThread == [NSThread currentThread] )
	{
		isCDMedia = [BrowserController isItCD: [newFilesArray objectAtIndex: 0]];
		
		[DicomFile setFilesAreFromCDMedia: isCDMedia];
		
		if( [newFilesArray count] > 50 || isCDMedia == YES)
		{
			splash = [[Wait alloc] initWithString: [NSString stringWithFormat: NSLocalizedString(@"Adding %@ files...", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt:[newFilesArray count]]]]];
			[splash showWindow:self];
			
			if( isCDMedia) [[splash progress] setMaxValue:[newFilesArray count]];
			else [[splash progress] setMaxValue:[newFilesArray count]/30];
			
			[splash setCancel: YES];
		}
	}
	
	int ii = 0;
	for (newFile in newFilesArray)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		@try
		{
			DicomFile		*curFile = nil;
			NSDictionary	*curDict = nil;
			
			#ifdef RANDOMFILES
				curFile = [[DicomFile alloc] initRandom];
			#else
				curFile = [[DicomFile alloc] init: newFile];
			#endif
			
			if(curFile == nil && [[newFile pathExtension] isEqualToString:@"zip"] == YES)
			{
				NSString *filePathWithoutExtension = [newFile stringByDeletingPathExtension];
				NSString *xmlFilePath = [filePathWithoutExtension stringByAppendingString:@".xml"];
				
				if([[NSFileManager defaultManager] fileExistsAtPath:xmlFilePath])
					curFile = [[DicomFile alloc] initWithXMLDescriptor:xmlFilePath path:newFile];
			}
			
			if( curFile)
			{
				curDict = [curFile dicomElements];
			
				if( onlyDICOM)
				{
					if( [[curDict objectForKey: @"fileType"] hasPrefix:@"DICOM"] == NO)
						curDict = nil;
				}
				
				if( curDict)
				{
					[dicomFilesArray addObject: curDict];
				}
				else
				{
					// This file was not readable -> If it is located in the DATABASE folder, we have to delete it or to move it to the 'NOT READABLE' folder
					if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
					{
						NSLog(@"**** Unreadable file: %@", newFile);
						
						if ( DELETEFILELISTENER)
						{
							[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
						}
						else
						{
							NSLog(@"**** This file in the DATABASE folder: move it to the unreadable folder");
							
							if( [[NSFileManager defaultManager] movePath: newFile toPath:[ERRpath stringByAppendingPathComponent: [newFile lastPathComponent]]  handler:nil] == NO)
								[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
						}
					}
				}
			
				[curFile release];
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
					if( (ii++) % 30 == 0)
						[splash incrementBy:1];
				}
			}
		}
		
		@catch (NSException * e)
		{
			NSLog( @"**** addFilesToDatabase exception : DicomFile alloc : %@", e);
		}
		
		[pool release];
		
		if( [splash aborted]) break;
	}
	
	[context retain];
	[context lock];
	
	// Find all current studies
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = nil;
	NSMutableArray *studiesArray = nil;
	
	@try
	{
		studiesArray = [[context executeFetchRequest:dbRequest error:&error] mutableCopy];
	}
	@catch( NSException *ne)
	{
		NSLog(@"AddFilesToDatabase executeFetchRequest exception: %@", [ne description]);
		NSLog(@"executeFetchRequest failed for studiesArray.");
		error = [NSError errorWithDomain:@"OsiriXDomain" code:1 userInfo: nil];
	}
	
	if (error)
	{
		NSLog( @"addFilesToDatabase ERROR: %@", [error localizedDescription]);
		//managedObjectContext = nil;
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
		
		NSMutableArray *studiesArrayStudyInstanceUID = [[studiesArray valueForKey:@"studyInstanceUID"] mutableCopy];
		
		// Add the new files
		for (NSDictionary *curDict in dicomFilesArray)
		{
			@try
			{
				newFile = [curDict objectForKey:@"filePath"];
				
				BOOL DICOMROI = NO;
				
				if( [DCMAbstractSyntaxUID isStructuredReport: [curDict objectForKey: @"SOPClassUID"]])
				{
					// Check if it is an OsiriX ROI SR
					if( [[curDict valueForKey:@"seriesDescription"] isEqualToString:@"OsiriX ROI SR"])
					{
						//NSLog( @"*/*/*/ OsiriX ROI SR");
						//NSLog( [curDict description]);
						
						// Move it to the ROIs folder
						NSString	*uidName = [SRAnnotation getFilenameFromSR: newFile];
						NSString	*destPath = [roiFolder stringByAppendingPathComponent: uidName];
						
						if( [newFile isEqualToString: destPath] == NO)
						{
							[[NSFileManager defaultManager] removeFileAtPath:destPath handler:nil];
							if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
							{
								NSLog( @"ROI SR MOVE :%@ to :%@", newFile, destPath);
								[[NSFileManager defaultManager] movePath:newFile toPath:destPath handler: nil];
							}
							else
							{
								NSLog( @"ROI SR COPY :%@ to :%@", newFile, destPath);
								[[NSFileManager defaultManager] copyPath:newFile toPath:destPath handler: nil];
							}
						}
						
						newFile = destPath;
						DICOMROI = YES;
					}
				}
				
				if( DICOMROI == NO)
					onlyDICOMROI = NO;
				
				// For now, we cannot add non-image DICOM files
				if( [curDict objectForKey:@"SOPClassUID"] != nil 
				   && [DCMAbstractSyntaxUID isImageStorage: [curDict objectForKey: @"SOPClassUID"]] == NO 
				   && [DCMAbstractSyntaxUID isRadiotherapy: [curDict objectForKey: @"SOPClassUID"]] == NO
				   && [DCMAbstractSyntaxUID isStructuredReport: [curDict objectForKey: @"SOPClassUID"]] == NO
				   && [DCMAbstractSyntaxUID isKeyObjectDocument: [curDict objectForKey: @"SOPClassUID"]] == NO)
				{
					NSLog(@"unsupported DICOM SOP CLASS");
					curDict = nil;
				}
				
				if( curDict != nil)
				{
					if( [[curDict objectForKey: @"studyID"] isEqualToString: curStudyID] == YES && [[curDict objectForKey: @"patientUID"] caseInsensitiveCompare: curPatientUID] == NSOrderedSame)
					{
						if( [[study valueForKey: @"modality"] isEqualToString: @"SR"] || [[study valueForKey: @"modality"] isEqualToString: @"OT"])
							[study setValue: [curDict objectForKey: @"modality"] forKey:@"modality"];
					}
					else
					{
						/*******************************************/
						/*********** Find study object *************/
						index = [studiesArrayStudyInstanceUID indexOfObject:[curDict objectForKey: @"studyID"]];
						if( index == NSNotFound)
						{
							// Fields
							study = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:context];
							
							newObject = YES;
							newStudy = YES;
							
							[study setValue:today forKey:@"dateAdded"];
							
							[studiesArray addObject: study];
							[studiesArrayStudyInstanceUID addObject: [curDict objectForKey: @"studyID"]];
							
							curSerieID = nil;
						}
						else
						{
							study = [studiesArray objectAtIndex: index];
							
							if( DICOMROI == NO)
								[study setValue:today forKey:@"dateAdded"];
							
							newObject = NO;
						}
						
						if( newObject || parseExistingObject)
						{
							[study setValue:[curDict objectForKey: @"studyID"] forKey:@"studyInstanceUID"];
							[study setValue:[curDict objectForKey: @"studyDescription"] forKey:@"studyName"];
							[study setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
							[study setValue:[curDict objectForKey: @"accessionNumber"] forKey:@"accessionNumber"];
							
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
						else
						{
							if( [[study valueForKey: @"modality"] isEqualToString: @"SR"] || [[study valueForKey: @"modality"] isEqualToString: @"OT"])
								[study setValue: [curDict objectForKey: @"modality"] forKey:@"modality"];
								
							if( [study valueForKey: @"studyName"] == nil || [[study valueForKey: @"studyName"] isEqualToString: @"unnamed"] || [[study valueForKey: @"studyName"] isEqualToString: @""])
								[study setValue: [curDict objectForKey: @"studyDescription"] forKey:@"studyName"];
						}
						curStudyID = [curDict objectForKey: @"studyID"];
						curPatientUID = [curDict objectForKey: @"patientUID"];
						
						if( produceAddedFiles)
							[modifiedStudiesArray addObject: study];
					}
					
					int NoOfSeries = [[curDict objectForKey: @"numberOfSeries"] intValue];
					for( int i = 0; i < NoOfSeries; i++)
					{
						NSString* SeriesNum = i ? [NSString stringWithFormat:@"%d",i] : @"";
						
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
								
								// Relations
								[seriesTable setValue:study forKey:@"study"];
								// If a study has an SC or other non primary image  series. May need to change modality to true modality
								if (([[study valueForKey:@"modality"] isEqualToString:@"OT"]  || [[study valueForKey:@"modality"] isEqualToString:@"SC"])
									&& !([[curDict objectForKey: @"modality"] isEqualToString:@"OT"] || [[curDict objectForKey: @"modality"] isEqualToString:@"SC"]))
									[study setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
							}
							
							curSerieID = [curDict objectForKey: @"seriesID"];
						}
						
						/*******************************************/
						/*********** Find image object *************/
						
						BOOL local = NO;
						if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
						{
							local = YES;
						}
						
						NSArray	*imagesArray = [[seriesTable valueForKey:@"images"] allObjects] ;
						int numberOfFrames = [[curDict objectForKey: @"numberOfFrames"] intValue];
						if( numberOfFrames == 0) numberOfFrames = 1;
							
						for( int f = 0 ; f < numberOfFrames; f++)
						{
							index = [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curDict objectForKey: [@"SOPUID" stringByAppendingString: SeriesNum]]];
							
							if( index != NSNotFound )
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
								
								if( DICOMROI == NO)
								{
									[study setValue:today forKey:@"dateAdded"];
									[seriesTable setValue:today forKey:@"dateAdded"];
								}
								
								[image setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								
								if( numberOfFrames > 1)
								{
									[image setValue:[NSNumber numberWithInt: f] forKey:@"frameID"];
									[image setValue:[NSNumber numberWithInt: f] forKey:@"instanceNumber"];
								}
								else
									[image setValue:[curDict objectForKey: [@"imageID" stringByAppendingString: SeriesNum]] forKey:@"instanceNumber"];
									
								if( local) [image setValue: [newFile lastPathComponent] forKey:@"path"];
								else [image setValue:newFile forKey:@"path"];
								
								if( DICOMROI) [image setValue: [NSNumber numberWithBool:YES] forKey:@"inDatabaseFolder"];
								else [image setValue:[NSNumber numberWithBool:local] forKey:@"inDatabaseFolder"];
								
								[image setValue:[curDict objectForKey: @"studyDate"]  forKey:@"date"];
								
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
								[seriesTable setValue: nil forKey:@"thumbnail"];
								
								// Relations
								[image setValue:seriesTable forKey:@"series"];
								
								if( COMMENTSAUTOFILL)
								{
									if([curDict objectForKey: @"commentsAutoFill"])
									{
										[seriesTable setValue:[curDict objectForKey: @"commentsAutoFill"] forKey:@"comment"];
										
										if( [study valueForKey:@"comment"] == nil || [[study valueForKey:@"comment"] isEqualToString:@""])
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
									error = nil;
									NSArray *albumArray = [context executeFetchRequest:dbRequest error:&error];
									
									NSManagedObject *album;
									for( album in albumArray )
									{
										if([[album valueForKey:@"name"] isEqualToString: [curDict valueForKey:@"album"]])
											break;
									}
									
									if ( album == nil )
									{
										//NSString *name = [curDict valueForKey:@"album"];
										//album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
										//[album setValue:name forKey:@"name"];
										
										for ( album in albumArray )
										{
											if ( [[album valueForKey:@"name"] isEqualToString: @"other"] )
												break;
										}
										
										if ( album == nil )
										{
											album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
											[album setValue:@"other" forKey:@"name"];
										}
									}
									
									// add the file to the album
									if ( [[album valueForKey:@"smartAlbum"] boolValue] == NO )
									{
										NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];	
										[studies addObject: [image valueForKeyPath:@"series.study"]];
									}
								}
							}
						}
					}
				}
				else
				{
					// This file was not readable -> If it is located in the DATABASE folder, we have to delete it or to move it to the 'NOT READABLE' folder
					if( [newFile length] >= [INpath length] && [newFile compare:INpath options:NSLiteralSearch range:NSMakeRange(0, [INpath length])] == NSOrderedSame)
					{
						NSLog(@"**** Unreadable file: %@", newFile);
						NSLog(@"**** This file in the DATABASE folder: move it to the unreadable folder");
						
						if ( DELETEFILELISTENER)
						{
							[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
						}
						else
						{
							if( [[NSFileManager defaultManager] movePath: newFile toPath:[ERRpath stringByAppendingPathComponent: [newFile lastPathComponent]]  handler:nil] == NO)
							{
								[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
							}
						}
					}
				}
			}
				
			@catch( NSException *ne)
			{
				NSLog(@"AddFilesToDatabase DicomFile exception: %@", [ne description]);
				NSLog(@"Parser failed for this file: %@", newFile);
			}
		}
		
		[studiesArrayStudyInstanceUID release];
		[studiesArray release];
		
		NSString *dockLabel = nil;
		NSString *growlString = nil;
		
		@try
		{
			// Compute no of images in studies/series
			if( produceAddedFiles)
				for( NSManagedObject *study in modifiedStudiesArray ) [study valueForKey:@"noFiles"];
			
			if( produceAddedFiles)
			{
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:addedImagesArray forKey:@"OsiriXAddToDBArray"];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"OsirixAddToDBNotification" object: nil userInfo:userInfo];
				
				if( [addedImagesArray count] && onlyDICOMROI == NO)
				{
					dockLabel = [NSString stringWithFormat:@"%d", [addedImagesArray count]];
					growlString = [NSString stringWithFormat: NSLocalizedString(@"Patient: %@\r%d images added to the database", nil), [[addedImagesArray objectAtIndex:0] valueForKeyPath:@"series.study.name"], [addedImagesArray count]];
				}
				
				[self executeAutorouting: addedImagesArray];
			}
		}
		@catch( NSException *ne)
		{
			NSLog(@"Compute no of images in studies/series: %@", [ne description]);
		}
		
		if( splash)
		{
			[splash close];
			[splash release];
			splash = nil;
		}
		
		@try
		{
			if( [NSDate timeIntervalSinceReferenceDate] - lastSaved > 120)
			{
				[self autoCleanDatabaseFreeSpace: self];
			
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
				
				for( NSManagedObject *seriesTable in addedSeries )
				{
					NSString			*curPatientID = [seriesTable valueForKeyPath:@"study.patientID"];
					
					for( ViewerController *vc in viewersList )
					{
						if( [[vc fileList] count] )
						{
							NSManagedObject	*firstObject = [[vc fileList] objectAtIndex: 0];
							
							// For each new image in a pre-existing study, check if a viewer is already opened -> refresh the preview list
							
							if( curPatientID == nil || [curPatientID isEqualToString: [firstObject valueForKeyPath:@"series.study.patientID"]])
							{
								if( [vlToRebuild containsObject: vc] == NO)
									[vlToRebuild addObject: vc];
							}
							
							if( seriesTable == [firstObject valueForKey:@"series"] )
							{
								if( [vlToReload containsObject: vc] == NO)
									[vlToReload addObject: vc];
							}
						}
					}
				}
			}
		}
		@catch( NSException *ne)
		{
			NSLog(@"vlToReload vlToRebuild: %@", [ne description]);
		}
		
		[context unlock];
		[context release];
		
		if( addFailed == NO)
		{
			if( dockLabel)
				[self performSelectorOnMainThread:@selector( setDockLabel:) withObject: dockLabel waitUntilDone:NO];
			
			if( growlString)
				[self performSelectorOnMainThread:@selector( setGrowlMessage:) withObject: growlString waitUntilDone:NO];
			
			if( mainThread == [NSThread currentThread])
				[self newFilesGUIUpdate: self];
				
			[newFilesConditionLock lock];
			
			int prevCondition = [newFilesConditionLock condition];
			
			for( ViewerController *a in vlToReload)
			{
				if( [viewersListToReload containsObject: a] == NO)
					[viewersListToReload addObject: a];
			}
			for( ViewerController *a in vlToRebuild)
			{
				if( [viewersListToRebuild containsObject: a] == NO)
					[viewersListToRebuild addObject: a];
			}
			
			if( newStudy || prevCondition == 1) [newFilesConditionLock unlockWithCondition: 1];
			else [newFilesConditionLock unlockWithCondition: 2];
			
			if( mainThread == [NSThread currentThread])
				[self newFilesGUIUpdate: self];
			
			databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
		}
	}
	
	[DicomFile setFilesAreFromCDMedia: NO];
	
	if( addFailed )
	{
		NSLog(@"adding failed....");
		
		return nil;
	}
	
	return addedImagesArray;
}

- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray onlyDICOM:(BOOL) onlyDICOM safeRebuild:(BOOL) safeProcess produceAddedFiles:(BOOL) produceAddedFiles parseExistingObject:(BOOL) parseExistingObject context: (NSManagedObjectContext*) context dbFolder:(NSString*) dbFolder
{
	#define CHUNK 50000

	if( [newFilesArray count] < CHUNK)
	{
		return [self subAddFilesToDatabase: newFilesArray onlyDICOM: onlyDICOM safeRebuild: safeProcess produceAddedFiles: produceAddedFiles parseExistingObject: parseExistingObject context:  context dbFolder: dbFolder];
	}
	else
	{
		int total = [newFilesArray count];
		NSMutableArray *result = [NSMutableArray arrayWithCapacity: total];
		
		for( int i = 0; i < total;)
		{
			int no;
			
			if( i + CHUNK >= total) no = total - i; 
			else no = CHUNK;
			
			NSRange range = NSMakeRange( i, no);
			
			id *objs = (id*) malloc( no * sizeof( id));
			if( objs)
			{
				[newFilesArray getObjects: objs range: range];
				
				NSArray *subArray = [NSArray arrayWithObjects: objs count: no];
				
				[result addObjectsFromArray: [self subAddFilesToDatabase: subArray onlyDICOM: onlyDICOM safeRebuild: safeProcess produceAddedFiles: produceAddedFiles parseExistingObject: parseExistingObject context:  context dbFolder: dbFolder]];
				
				free( objs);
			}
			
			i += no;
		}
		
		return result;
	}
}

- (void) newFilesGUIUpdateRun: (int) state viewersListToReload: (NSMutableArray*) cReload viewersListToRebuild: (NSMutableArray*) cRebuild
{
	if( state == 1)
	{
		[self outlineViewRefresh];
	}
	else
	{
		[databaseOutline reloadData];
		[albumTable reloadData];
		[self outlineViewSelectionDidChange: nil];
	}
	
	[self reloadViewers: cReload];
	[self rebuildViewers: cRebuild];
}

- (void) newFilesGUIUpdateRun:(int) state
{
	return [self newFilesGUIUpdateRun: state viewersListToReload: viewersListToReload viewersListToRebuild: viewersListToRebuild];
}

- (void) newFilesGUIUpdate:(id) sender
{
	if( [newFilesConditionLock tryLockWhenCondition: 1] || [newFilesConditionLock tryLockWhenCondition: 2])
	{
		NSMutableArray *cReload = [NSMutableArray arrayWithArray: viewersListToReload], *vReload = [NSMutableArray arrayWithCapacity: 20];
		
		for( ViewerController *v in cReload)
		{
			if( [[v imageView] mouseDragging] == NO && [v postprocessed] == NO)
			{
				[viewersListToReload removeObject: v];
				[vReload addObject: v];
			}
		}
		
		NSMutableArray *cRebuild = [NSMutableArray arrayWithArray: viewersListToRebuild], *vRebuild = [NSMutableArray arrayWithCapacity: 20];
		
		for( ViewerController *v in cRebuild)
		{
			if( [[v imageView] mouseDragging] == NO)
			{
				[viewersListToRebuild removeObject: v];
				[vRebuild addObject: v];
			}
		}
		
		int condition = [newFilesConditionLock condition];
		
		if( [viewersListToRebuild count] || [viewersListToReload count]) [newFilesConditionLock unlockWithCondition: condition];
		else [newFilesConditionLock unlockWithCondition: 0];
		
		[self newFilesGUIUpdateRun: condition viewersListToReload: vReload viewersListToRebuild: vRebuild];
	}
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	[newFilesConditionLock lock];
	
	[viewersListToReload removeObject: [note object]];
	[viewersListToRebuild removeObject: [note object]];
	
	[newFilesConditionLock unlock];
}

- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames copied:(BOOL*) copied
{
    NSFileManager       *defaultManager = [NSFileManager defaultManager];
	NSMutableArray		*filesArray;
	BOOL				isDirectory = NO;
	NSMutableArray		*commentsAndStatus = [NSMutableArray array];
	NSMutableArray		*reports = [NSMutableArray array];
	
	filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
	
	for( NSString *filename in filenames)
	{
		if( [[filename lastPathComponent] characterAtIndex: 0] != '.')
		{
			if([defaultManager fileExistsAtPath: filename isDirectory:&isDirectory])     // A directory
			{
				if( isDirectory == YES && [[filename pathExtension] isEqualToString:@"pages"] == NO)
				{
					NSString    *pathname;
					NSString	*folderSkip = nil;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath: filename];
					
					while (pathname = [enumer nextObject])
					{
						NSString * itemPath = [filename stringByAppendingPathComponent:pathname];
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
								
								if( [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES)
								{
									[self addDICOMDIR: filename : filesArray];
								}
								else
								{
									if( [[itemPath lastPathComponent] characterAtIndex: 0] != '.')
									{
										if( [[itemPath lastPathComponent] isEqualToString: @"CommentAndStatus.xml"])
										{
											[commentsAndStatus addObject: itemPath];
										}
										else if( [[[itemPath lastPathComponent] stringByDeletingPathExtension] isEqualToString: @"report"])
										{
											[reports addObject: itemPath];
										}
										else if( [[itemPath lastPathComponent] isEqualToString: @"reportStudyUID.xml"])
										{
										
										}
										else [filesArray addObject:itemPath];
									}
								}
							}
						}
						else if( [[pathname pathExtension] isEqualToString:@"pages"])
						{
							folderSkip = pathname;
							
							if( [[[pathname lastPathComponent] stringByDeletingPathExtension] isEqualToString: @"report"])
								[reports addObject: itemPath];
						}
					}
				}
				else    // A file
				{
					if( [[filename lastPathComponent] isEqualToString: @"CommentAndStatus.xml"])
					{
						[commentsAndStatus addObject: filename];
					}
					else if( [[[filename lastPathComponent] stringByDeletingPathExtension] isEqualToString: @"report"])
					{
						[reports addObject: filename];
					}
					else if( [[filename lastPathComponent] isEqualToString: @"reportStudyUID.xml"])
					{
						
					}
					else if( [[[filename lastPathComponent] uppercaseString] isEqualToString:@"DICOMDIR"] == YES)
					{
						[self addDICOMDIR: filename :filesArray];
					}
					else [filesArray addObject: filename];
				}
			}
		}
	}
	
	NSMutableArray	*newfilesArray = [self copyFilesIntoDatabaseIfNeeded: filesArray];
	
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
	
	for( NSString *path in commentsAndStatus)
	{
		[self importCommentsAndStatusFromDictionary: [NSDictionary dictionaryWithContentsOfFile: path]];
	}
	
	for( NSString *path in reports)
	{
		NSString *pathXML = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"reportStudyUID.xml"];
	
		[self importReport: path UID: [NSString stringWithContentsOfFile: pathXML]];
	}
	
	[self outlineViewRefresh];
	
	return newImages;
}

- (NSArray*) addFilesAndFolderToDatabase:(NSArray*) filenames
{
	return [self addFilesAndFolderToDatabase: filenames copied: nil];
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
		
		for ( NSDictionary *routingRule in autoroutingRules)
		{			
			@try
			{
				[self smartAlbumPredicateString: [routingRule objectForKey:@"filter"]];
			}
			
			@catch( NSException *ne)
			{
				NSRunAlertPanel( NSLocalizedString(@"Routing Filter Error", nil),  [NSString stringWithFormat: NSLocalizedString(@"Syntax error in this routing filter: %@\r\r%@\r\rSee Routing Preferences.", nil), [routingRule objectForKey:@"name"], [routingRule objectForKey:@"filter"]], nil, nil, nil);
			}
		}
	}
}

- (void) executeAutorouting: (NSArray *)newImages
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		NSArray	*autoroutingRules = [[NSUserDefaults standardUserDefaults] arrayForKey: @"AUTOROUTINGDICTIONARY"];
		
		for ( NSDictionary *routingRule in autoroutingRules)
		{
			if( [routingRule valueForKey:@"activated"] == nil || [[routingRule valueForKey:@"activated"] boolValue] == YES)
			{
				NSManagedObjectContext *context = self.managedObjectContext;
				
				[context retain];
				[context lock];
				
				NSPredicate	*predicate = nil;
				NSArray	*result = nil;
				
				@try
				{
					predicate = [self smartAlbumPredicateString: [routingRule objectForKey:@"filter"]];
					if( predicate) result = [newImages filteredArrayUsingPredicate: predicate];
					
					if( [result count])
					{
						if( [[routingRule valueForKey:@"previousStudies"] intValue] > 0)
						{
							NSMutableDictionary *patients = [NSMutableDictionary dictionary];
							
							// for each study
							for( id im in result)
							{
								if( [patients objectForKey: [im valueForKeyPath:@"series.study.patientUID"]] == nil)
									[patients setObject: [im valueForKeyPath:@"series.study"] forKey: [im valueForKeyPath:@"series.study.patientUID"]];
							}
							
							for( NSString *patientUID in [patients allKeys])
							{
								NSLog( patientUID);
								
								id study = [patients objectForKey: patientUID];
								
								NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"(patientUID == %@)", patientUID];
								NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
								dbRequest.entity = [self.managedObjectModel.entitiesByName objectForKey:@"Study"];
								dbRequest.predicate = predicate;
								
								NSError	*error = nil;
								NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
								
								if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound)
								{
									NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
									NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
									[sort release];
									NSMutableArray* s = [[[studiesArray sortedArrayUsingDescriptors: sortDescriptors] mutableCopy] autorelease];
									// remove original study from array
									[s removeObject: study];
									
									studiesArray = [NSArray arrayWithArray: s];
									
									// did we already send these studies ? If no, send them !
									
									if( autoroutingPreviousStudies == nil) autoroutingPreviousStudies = [[NSMutableDictionary dictionary] retain];
									
									int previousNumber = [[routingRule valueForKey:@"previousStudies"] intValue];
									
									for( id s in studiesArray)
									{
										NSString *key = [NSString stringWithFormat:@"%@ -> %@", [s valueForKey: @"studyInstanceUID"], [routingRule objectForKey:@"server"]];
										NSDate *when = [autoroutingPreviousStudies objectForKey: key];
										
										BOOL found = YES;
										
										if( [[routingRule valueForKey: @"previousModality"] boolValue])
										{
											if( [s valueForKey:@"modality"] && [study valueForKey:@"modality"])
											{
												if( [[study valueForKey:@"modality"] rangeOfString: [s valueForKey:@"modality"]].location == NSNotFound) found = NO;
											}
											else found = NO;
										}
										
										if( [[routingRule valueForKey: @"previousDescription"] boolValue])
										{
											if( [s valueForKey:@"studyName"] && [study valueForKey:@"studyName"])
											{
												if( [[study valueForKey:@"studyName"] rangeOfString: [s valueForKey:@"studyName"]].location == NSNotFound) found = NO;
											}
											else found = NO;
										}
										
										if( found && previousNumber > 0)
										{
											previousNumber--;
											
											// If we sent it more than 3 hours ago, re-send it
											if( when == nil || [when timeIntervalSinceNow] < -60*60*3)
											{
												[autoroutingPreviousStudies setObject: [NSDate date] forKey: key];
												
												for( NSManagedObject *series in [[s valueForKey:@"series"] allObjects])
													result = [result arrayByAddingObjectsFromArray: [[series valueForKey:@"images"] allObjects]];
											}
										}
									}
								}
							}
						}
						
						if( [[routingRule valueForKey:@"cfindTest"] boolValue])
						{
							NSMutableDictionary *studies = [NSMutableDictionary dictionary];
							
							for( id im in result)
							{
								if( [studies objectForKey: [im valueForKeyPath:@"series.study.studyInstanceUID"]] == nil)
									[studies setObject: [im valueForKeyPath:@"series.study"] forKey: [im valueForKeyPath:@"series.study.studyInstanceUID"]];
							}
							
							for( NSString *studyUID in [studies allKeys])
							{
								NSArray *serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
								
								NSString		*serverName = [routingRule objectForKey:@"server"];
								NSDictionary	*server = nil;
								
								for ( NSDictionary *aServer in serversArray)
								{
									if ([[aServer objectForKey:@"Description"] isEqualToString: serverName]) 
									{
										server = aServer;
										break;
									}
								}
								
								if( server)
								{
									[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"showErrorsIfQueryFailed"];
									NSArray *s = [QueryController queryStudyInstanceUID: studyUID server: server];
									[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"showErrorsIfQueryFailed"];
									
									if( [s count])
									{
										if( [s count] > 1)
											NSLog( @"Uh? multiple studies with same StudyInstanceUID on the distal node....");
										
										DCMTKStudyQueryNode* studyNode = [s lastObject];
										
										if( [[studyNode valueForKey:@"numberImages"] intValue] >= [[[studies objectForKey: studyUID] valueForKey: @"noFiles"] intValue])
										{
											// remove them, there are already there ! *probably*
											
											NSLog( @"Already available on the distant node : we will not send it.");
											
											NSMutableArray *r = [NSMutableArray arrayWithArray: result];
											
											for( int i = 0 ; i < [r count] ; i++)
											{
												if( [[[r objectAtIndex: i] valueForKeyPath: @"series.study.studyInstanceUID"] isEqualToString: studyUID])
												{
													[r removeObjectAtIndex: i];
													i--;
												}
											}
											
											result = r;
										}
									}
								}
							}
						}
					}
				}
				
				@catch( NSException *ne)
				{
					result = nil;
					NSLog( @"Error in autorouting filter :");
					NSLog( [ne name]);
					NSLog( [ne reason]);
				}
				
				if( [result count])
				{
					if( autoroutingQueueArray == nil) autoroutingQueueArray = [[NSMutableArray array] retain];
					if( autoroutingQueue == nil) autoroutingQueue = [[NSLock alloc] init];
					if( autoroutingInProgress == nil) autoroutingInProgress = [[NSLock alloc] init];
					
					[autoroutingQueue lock];
					
					[autoroutingQueueArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: result, @"objects", [routingRule objectForKey:@"server"], @"server", routingRule, @"routingRule", [routingRule valueForKey:@"failureRetry"], @"failureRetry", nil]];
					
					[autoroutingQueue unlock];
				}
				[context unlock];
				[context release];
			}
		}
		
		// Do some cleaning
		
		if( autoroutingPreviousStudies)
		{
			for( NSString *key in [autoroutingPreviousStudies allKeys])
			{
				if( [[autoroutingPreviousStudies objectForKey: key] timeIntervalSinceNow] < -60*60*3)
				{
					[autoroutingPreviousStudies removeObjectForKey: key];
				}
			}
		}
	}
}

- (void)showErrorMessage: (NSDictionary*)dict
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowErrorMessagesForAutorouting"] == NO) return;
	
	NSException	*ne = [dict objectForKey: @"exception"];
	NSDictionary *server = [dict objectForKey:@"server"];
	
	NSString	*message = [NSString stringWithFormat:@"%@\r\r%@\r%@\r\rServer:%@-%@:%@", NSLocalizedString( @"Autorouting DICOM StoreSCU operation failed.\rI will try again in 30 secs.", nil), [ne name], [ne reason], [server objectForKey:@"AETitle"], [server objectForKey:@"Address"], [server objectForKey:@"Port"]];
	
	NSAlert* alert = [NSAlert new];
	[alert setMessageText: NSLocalizedString(@"Autorouting Error",nil)];
	[alert setInformativeText: message];
	[alert setShowsSuppressionButton:YES];
	[alert runModal];
	if ([[alert suppressionButton] state] == NSOnState)
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"ShowErrorMessagesForAutorouting"];
}

- (void) executeSend :(NSArray*) samePatientArray server:(NSDictionary*) server dictionary: (NSDictionary*) dict
{
	if( [samePatientArray count] == 0) return;
	
	NSLog( @"Autorouting: %@ - %d images", [[samePatientArray objectAtIndex: 0] valueForKeyPath:@"series.study.name"], [samePatientArray count]);
		
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
		
		[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ne, @"exception", server, @"server", nil] waitUntilDone: NO];
		
		// We will try again later...
		
		if( [[dict valueForKey:@"failureRetry"] intValue] > 0)
		{
			[autoroutingQueue lock];
			
			NSLog( @"Autorouting failure count: %d", [[dict valueForKey:@"failureRetry"] intValue]);
			
			[autoroutingQueueArray addObject: [NSDictionary dictionaryWithObjectsAndKeys: samePatientArray, @"objects", [server objectForKey:@"Description"], @"server", dict, @"routingRule", [NSNumber numberWithInt: [[dict valueForKey:@"failureRetry"] intValue]-1], @"failureRetry", nil]];
			[autoroutingQueue unlock];
		}
	}
		
	[storeSCU release];
	storeSCU = nil;
}

- (void) processAutorouting
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *serversArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"];
	
	[autoroutingInProgress lock];
	
	[autoroutingQueue lock];
	NSArray	*copyArray = [NSArray arrayWithArray: autoroutingQueueArray];
	[autoroutingQueueArray removeAllObjects];
	[autoroutingQueue unlock];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOROUTINGACTIVATED"])
	{
		if( [copyArray count] )
		{
			NSLog(@"autorouting Queue start: %d objects", [copyArray count]);
			for ( NSDictionary *copy in copyArray )
			{
				NSArray			*objectsToSend = [copy objectForKey:@"objects"];
				NSString		*serverName = [copy objectForKey:@"server"];
				NSDictionary	*server = nil;
				
				for ( NSDictionary *aServer in serversArray)
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
					@try
					{
						NSSortDescriptor	*sort = [[[NSSortDescriptor alloc] initWithKey:@"series.study.patientID" ascending:YES] autorelease];
						NSArray				*sortDescriptors = [NSArray arrayWithObject: sort];
						
						objectsToSend = [objectsToSend sortedArrayUsingDescriptors: sortDescriptors];
						
						NSString			*previousPatientUID = nil;
						NSMutableArray		*samePatientArray = [NSMutableArray arrayWithCapacity: [objectsToSend count]];
						
						for( NSManagedObject *objectToSend in objectsToSend )
						{
							if( [previousPatientUID isEqualToString: [objectToSend valueForKeyPath:@"series.study.patientID"]])
							{
								[samePatientArray addObject: objectToSend];
							}
							else
							{
								// Send the collected files from the same patient
								
								if( [samePatientArray count]) [self executeSend: samePatientArray server: server dictionary: copy];
								
								// Reset
								[samePatientArray removeAllObjects];
								[samePatientArray addObject: objectToSend];
								
								previousPatientUID = [objectToSend valueForKeyPath:@"series.study.patientID"];
							}
						}
						
						if( [samePatientArray count])
							[self executeSend: samePatientArray server: server dictionary: copy];
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
					NSException *ne = [NSException exceptionWithName: NSLocalizedString(@"Unknown destination server. Add it to the Locations list - see Preferences.", nil) reason: [NSString stringWithFormat:@"Destination: %@", serverName] userInfo:nil];
					
					[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: ne, @"exception", [NSDictionary dictionary], @"server", nil] waitUntilDone: NO];
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
	if( autoroutingQueueArray != nil && autoroutingQueue != nil)
	{
		if( [autoroutingQueueArray count] > 0)
		{
			if( [autoroutingInProgress tryLock])
			{
				[appController growlTitle: NSLocalizedString( @"Autorouting", nil) description: NSLocalizedString(@"Autorouting starting...", nil) name: @"newfiles"];
				
				[autoroutingInProgress unlock];
				[NSThread detachNewThreadSelector:@selector(processAutorouting) toTarget:self withObject:nil];
			}
		}
	}
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
		
		[studiesArray setValue: 0L forKey: @"comment"];
		
		// Find all series
		dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		error = nil;
		
		NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
		
		[[splash progress] setMaxValue: [seriesArray count]];
		
		for( NSManagedObject *series in seriesArray )
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
							[series setValue: [dcm elementForKey: @"commentsAutoFill"] forKey:@"comment"];
							
							NSManagedObject *study = [series valueForKey: @"study"];
							
							if( [study valueForKey:@"comment"] == nil || [[study valueForKey:@"comment"] isEqualToString:@""])
								[study setValue: [dcm elementForKey: @"commentsAutoFill"] forKey:@"comment"];
						}
						else [series setValue: 0L forKey:@"comment"];
					}
					
					[dcm release];
				}
				else [series setValue: 0L forKey:@"comment"];
			}
			@catch ( NSException *e)
			{
				NSLog( @"regenerateAutoComments exception : %@", e);
			}
			
			[splash incrementBy:1];
		}
		[context unlock];
		
		[self outlineViewRefresh];
		
		[splash close];
		[splash release];
	}
}

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
    NSError *error = nil;
    NSString *localizedDescription;
	NSFileManager *fileManager;
	
	if( currentDatabasePath == nil) return nil;
	
	[[managedObjectContext undoManager] setLevelsOfUndo: 1];
	[[managedObjectContext undoManager] disableUndoRegistration];
	
    if (managedObjectContext) return managedObjectContext;
	
	if( loadIfNecessary == NO) return nil;
	
	fileManager = [NSFileManager defaultManager];
	
	[persistentStoreCoordinator release];
	
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel];
	
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	
    NSURL *url = [NSURL fileURLWithPath: currentDatabasePath];
	
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{	// NSSQLiteStoreType - NSXMLStoreType
		localizedDescription = [error localizedDescription];
		error = [NSError errorWithDomain:@"OsiriXDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, NSUnderlyingErrorKey, [NSString stringWithFormat:@"Store Configuration Failure: %@", ((localizedDescription != nil) ? localizedDescription : @"Unknown Error")], NSLocalizedDescriptionKey, nil]];
    }

	[[managedObjectContext undoManager] setLevelsOfUndo: 1];
	[[managedObjectContext undoManager] disableUndoRegistration];

	// This line is very important, if there is NO database.sql file
	[self saveDatabase: currentDatabasePath];
	
    return managedObjectContext;
}

- (NSManagedObjectContext *) defaultManagerObjectContext
{
	if( [currentDatabasePath isEqualToString: [self localDatabasePath]])
	{
		return [self managedObjectContext];
	}
	else
	{
		NSError *error = nil;
		
		NSPersistentStoreCoordinator *pSC = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel] autorelease];
		
		NSManagedObjectContext *mOC = [[[NSManagedObjectContext alloc] init] autorelease];
		[mOC setPersistentStoreCoordinator: pSC];
		
		NSURL *url = [NSURL fileURLWithPath: [self localDatabasePath]];
		
		if (![pSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
		{
			NSLog(@"********** defaultManagerObjectContext FAILED");
		}
		
		[[mOC undoManager] setLevelsOfUndo: 1];
		[[mOC undoManager] disableUndoRegistration];
		
		return mOC;
	}
}

- (NSManagedObjectContext *) managedObjectContext
{
	return [self managedObjectContextLoadIfNecessary: YES];
}

- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files
{
	DicomDirParser				*parsed		= [[DicomDirParser alloc] init: dicomdir];
	
	[parsed parseArray: files];
	
	[parsed release];
}

-(NSArray*) addURLToDatabaseFiles:(NSArray*) URLs
{
	NSMutableArray	*localFiles = [NSMutableArray arrayWithCapacity:0];
	
	// FIRST DOWNLOAD FILES TO LOCAL DATABASE
	
	for( NSURL *url in URLs )
	{
		NSData *data = [NSData dataWithContentsOfURL: url];
		
		if( data )
		{
			NSString *dstPath = [self getNewFileDatabasePath:@"dcm"];		
			[data writeToFile:dstPath  atomically:YES];
			[localFiles addObject:dstPath];
		}
	}
	
	// THEN, LOAD THEM
	return [self addFilesAndFolderToDatabase: localFiles];
}

- (void)addURLToDatabaseEnd: (id)sender
{
	if( [sender tag] == 1)
	{
		[[NSUserDefaults standardUserDefaults] setObject: [urlString stringValue] forKey: @"LASTURL"];
		NSArray *result = [self addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString: [urlString stringValue]]]];
		
		if( [result count] == 0 )
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

- (IBAction)selectFilesAndFoldersToAdd: (id)sender
{
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
    
	[self.window makeKeyAndOrderFront:sender];
	
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseDirectories:YES];
    
    int result = [oPanel runModalForDirectory:nil file:nil types:nil];
    
    if (result == NSOKButton )
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
			if( albumTable.selectedRow > 0 )
			{
				NSManagedObject *album = [self.albumArray objectAtIndex: albumTable.selectedRow];
				
				if ([[album valueForKey:@"smartAlbum"] boolValue] == NO )
				{
					NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
					
					for( NSManagedObject *object in newImages )
					{
						[studies addObject: [object valueForKeyPath:@"series.study"]];
					}
					
					needDBRefresh = YES;
					[self outlineViewRefresh];
				}
			}
			
			if( [newImages count] > 0 )
			{
				NSManagedObject		*object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
				
				[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
	}
}

-(void)openDatabaseIn: (NSString*)a Bonjour: (BOOL)isBonjour
{
	[self waitForRunningProcesses];
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Opening OsiriX database...", nil)];
	[wait showWindow:self];
	
	if( isCurrentDatabaseBonjour == NO)
		[self saveDatabase: currentDatabasePath];
	
	[currentDatabasePath release];
	currentDatabasePath = [a retain];
	isCurrentDatabaseBonjour = isBonjour;
	
	[self loadDatabase: currentDatabasePath];
	
	[wait close];
	[wait release];
}

- (void)openDatabaseInBonjour: (NSString*)path
{ 
	[self openDatabaseIn: path Bonjour: YES];
}

- (IBAction)openDatabase: (id)sender
{
	NSOpenPanel		*oPanel		= [NSOpenPanel openPanel];
	
	if ([oPanel runModalForDirectory:[self documentsDirectory] file:nil types:[NSArray arrayWithObject:@"sql"]] == NSFileHandlingPanelOKButton)
	{
		if( [currentDatabasePath isEqualToString: [oPanel filename]] == NO && [oPanel filename] != nil )
		{
			[self openDatabaseIn: [oPanel filename] Bonjour:NO];
		}
	}
}

- (IBAction)createDatabase: (id)sender
{
	if( isCurrentDatabaseBonjour )
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Database", nil), NSLocalizedString(@"Cannot create a SQL Index file for a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
		return;
	}
	
	NSSavePanel		*sPanel		= [NSSavePanel savePanel];
	
	[sPanel setRequiredFileType:@"sql"];
	
	if ([sPanel runModalForDirectory:[self documentsDirectory] file:NSLocalizedString(@"Database.sql", nil)] == NSFileHandlingPanelOKButton)
	{
		if( [currentDatabasePath isEqualToString: [sPanel filename]] == NO && [sPanel filename] != nil)
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

- (void) updateDatabaseModel: (NSString*) path :(NSString*) DBVersion
{
	NSString	*model = [NSString stringWithFormat:@"/OsiriXDB_Previous_DataModel%@.mom", DBVersion];
	
	if( [DBVersion isEqualToString: DATABASEVERSION]) model = [NSString stringWithFormat:@"/OsiriXDB_DataModel.mom"];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: model]] )
	{
		displayEmptyDatabase = YES;
		[self outlineViewRefresh];
		[self refreshMatrix: self];
		
		[managedObjectContext lock];
		[managedObjectContext unlock];
		[managedObjectContext release];
		managedObjectContext = nil;
		
		Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Updating database model...", nil)];
		[splash showWindow:self];
		
		NSError							*error = nil;
		NSManagedObjectModel			*previousModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: model]]];
		NSManagedObjectModel			*currentModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
		NSPersistentStoreCoordinator	*previousSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: previousModel];
		NSPersistentStoreCoordinator	*currentSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: currentModel];
		NSManagedObjectContext			*currentContext = [[NSManagedObjectContext alloc] init];
		NSManagedObjectContext			*previousContext = [[NSManagedObjectContext alloc] init];

		@try
		{
			NSMutableString *updatingProblems = nil;
			
			[currentContext setPersistentStoreCoordinator: currentSC];
			[previousContext setPersistentStoreCoordinator: previousSC];
			
			[[NSFileManager defaultManager] removeFileAtPath: [[self documentsDirectory] stringByAppendingPathComponent:@"/Database3.sql"] handler: nil];
			[[NSFileManager defaultManager] removeFileAtPath: [[self documentsDirectory] stringByAppendingPathComponent:@"/Database3.sql-journal"] handler: nil];
			
			[previousSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: currentDatabasePath] options:nil error:&error];
			[currentSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL: [NSURL fileURLWithPath: [[self documentsDirectory] stringByAppendingPathComponent:@"/Database3.sql"]] options:nil error:&error];
			
			NSEntityDescription		*currentStudyTable, *currentSeriesTable, *currentImageTable, *currentAlbumTable;
			NSArray					*albumProperties, *studyProperties, *seriesProperties, *imageProperties;
						
			[[currentContext undoManager] setLevelsOfUndo: 1];
			[[currentContext undoManager] disableUndoRegistration];
				
			[[previousContext undoManager] setLevelsOfUndo: 1];
			[[previousContext undoManager] disableUndoRegistration];
				
			// ALBUMS
			NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[previousModel entitiesByName] objectForKey:@"Album"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
			
			error = nil;
			NSArray *albums = [previousContext executeFetchRequest:dbRequest error:&error];
			albumProperties = [[[[previousModel entitiesByName] objectForKey:@"Album"] attributesByName] allKeys];
			for( NSManagedObject *previousAlbum in albums )
			{
				currentAlbumTable = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: currentContext];
				
				for ( NSString *name in albumProperties )
				{
					[currentAlbumTable setValue: [previousAlbum valueForKey: name] forKey: name];
				}
			}
			
			error = nil;
			[currentContext save: &error];
			
			// STUDIES
			dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[previousModel entitiesByName] objectForKey:@"Study"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
			
			error = nil;
			NSMutableArray *studies = [NSMutableArray arrayWithArray: [previousContext executeFetchRequest:dbRequest error:&error]];
			
			[[splash progress] setMaxValue:[studies count]];
			
			int chunk = 0;
			
			studies = [NSMutableArray arrayWithArray: [studies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease]]]];
			if( [studies count] > 100)
			{
				int max = [studies count] - chunk*100;
				if( max > 100) max = 100;
				studies = [NSMutableArray arrayWithArray: [studies subarrayWithRange: NSMakeRange( chunk*100, max)]];
				chunk++;
			}
			[studies retain];
			
			studyProperties = [[[[previousModel entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
			seriesProperties = [[[[previousModel entitiesByName] objectForKey:@"Series"] attributesByName] allKeys];
			imageProperties = [[[[previousModel entitiesByName] objectForKey:@"Image"] attributesByName] allKeys];
			
			int counter = 0;

			[[currentContext undoManager] setLevelsOfUndo: 1];
			[[currentContext undoManager] disableUndoRegistration];
				
			[[previousContext undoManager] setLevelsOfUndo: 1];
			[[previousContext undoManager] disableUndoRegistration];
			
			NSArray *currentAlbums = nil;
			NSArray *currentAlbumsNames = nil;
			
			while( [studies count] > 0 )
			{
				NSAutoreleasePool	*poolLoop = [[NSAutoreleasePool alloc] init];
				
				
				NSString *studyName = nil;
				
				@try
				{
					NSManagedObject *previousStudy = [studies lastObject];
					
					[studies removeLastObject];
					
					currentStudyTable = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext: currentContext];
					
					for ( NSString *name in studyProperties )
					{
						[currentStudyTable setValue: [previousStudy primitiveValueForKey: name] forKey: name];
						
						if( [name isEqualToString: @"name"])
							studyName = [previousStudy primitiveValueForKey: name];
					}
					
					// SERIES
					NSArray *series = [[previousStudy valueForKey:@"series"] allObjects];
					for( NSManagedObject *previousSeries in series )
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
						@try
						{
							currentSeriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext: currentContext];
							
							for ( NSString *name in seriesProperties )
							{
								if( [name isEqualToString: @"xOffset"] || 
									[name isEqualToString: @"yOffset"] || 
									[name isEqualToString: @"scale"] || 
									[name isEqualToString: @"rotationAngle"] || 
									[name isEqualToString: @"displayStyle"] || 
									[name isEqualToString: @"windowLevel"] || 
									[name isEqualToString: @"windowWidth"] || 
									[name isEqualToString: @"yFlipped"] || 
									[name isEqualToString: @"xFlipped"])
								{
									
								}
								else [currentSeriesTable setValue: [previousSeries primitiveValueForKey: name] forKey: name];
							}
							[currentSeriesTable setValue: currentStudyTable forKey: @"study"];
							
							// IMAGES
							NSArray *images = [[previousSeries valueForKey:@"images"] allObjects];
							for ( NSManagedObject *previousImage in images )
							{
								@try
								{
									currentImageTable = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext: currentContext];
									
									for( NSString *name in imageProperties )
									{
										if( [name isEqualToString: @"xOffset"] || 
											[name isEqualToString: @"yOffset"] || 
											[name isEqualToString: @"scale"] || 
											[name isEqualToString: @"rotationAngle"] || 
											[name isEqualToString: @"windowLevel"] || 
											[name isEqualToString: @"windowWidth"] || 
											[name isEqualToString: @"yFlipped"] || 
											[name isEqualToString: @"xFlipped"])
										{
											
										}
										else [currentImageTable setValue: [previousImage primitiveValueForKey: name] forKey: name];
									}
									[currentImageTable setValue: currentSeriesTable forKey: @"series"];
								}
								
								@catch (NSException *e)
								{
									NSLog(@"IMAGE LEVEL: Problems during updating: %@", e);
								}
							}
						}
						
						@catch (NSException *e)
						{
							NSLog(@"SERIES LEVEL: Problems during updating: %@", e);
						}
						[pool release];
					}
					
					NSArray		*storedInAlbums = [[previousStudy valueForKey: @"albums"] allObjects];
					
					if( [storedInAlbums count])
					{
						if( currentAlbums == nil)
						{
							// Find all current albums
							NSFetchRequest *r = [[[NSFetchRequest alloc] init] autorelease];
							[r setEntity: [[currentModel entitiesByName] objectForKey:@"Album"]];
							[r setPredicate: [NSPredicate predicateWithValue:YES]];
						
							error = nil;
							currentAlbums = [currentContext executeFetchRequest:r error:&error];
							currentAlbumsNames = [currentAlbums valueForKey:@"name"];
							
							[currentAlbums retain];
							[currentAlbumsNames retain];
						}
						
						@try
						{
							for( NSManagedObject *sa in storedInAlbums )
							{
								NSString		*name = [sa valueForKey:@"name"];
								
								NSMutableSet	*studiesStoredInAlbum = [[currentAlbums objectAtIndex: [currentAlbumsNames indexOfObject: name]] mutableSetValueForKey:@"studies"];
								
								[studiesStoredInAlbum addObject: currentStudyTable];
							}
						}
						
						@catch (NSException *e)
						{
							NSLog(@"ALBUM : %@", e);
						}
					}
				}
				
				@catch (NSException * e)
				{
					NSLog(@"STUDY LEVEL: Problems during updating: %@", e);
					NSLog(@"Patient Name: %@", studyName);
					if( updatingProblems == nil) updatingProblems = [[NSMutableString stringWithString:@""] retain];
					
					[updatingProblems appendFormat:@"%@\r", studyName];
				}
					
				[splash incrementBy:1];
				counter++;
				
				NSLog(@"%d", counter);
				
				if( counter % 100 == 0)
				{
					error = nil;
					[currentContext save: &error];
					
					[currentContext reset];
					[previousContext reset];
					
					[currentAlbums release];			currentAlbums = nil;
					[currentAlbumsNames release];		currentAlbumsNames = nil;
					
					[studies release];
					
					studies = [NSMutableArray arrayWithArray: [previousContext executeFetchRequest:dbRequest error:&error]];
					
					[[splash progress] setMaxValue:[studies count]];
					
					studies = [NSMutableArray arrayWithArray: [studies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease]]]];
					if( [studies count] > 100)
					{
						int max = [studies count] - chunk*100;
						if( max>100) max = 100;
						studies = [NSMutableArray arrayWithArray: [studies subarrayWithRange: NSMakeRange( chunk*100, max)]];
						chunk++;
					}
					
					[studies retain];
				}
				
				[poolLoop release];
			}
			
			error = nil;
			[currentContext save: &error];
			
			[[NSFileManager defaultManager] removeFileAtPath:currentDatabasePath handler:nil];
			[[NSFileManager defaultManager] movePath:[[self documentsDirectory] stringByAppendingPathComponent:@"/Database3.sql"] toPath:currentDatabasePath handler:nil];
			
			[studies release];					studies = nil;
			[currentAlbums release];			currentAlbums = nil;
			[currentAlbumsNames release];		currentAlbumsNames = nil;
			
			if( updatingProblems)
			{
				NSRunAlertPanel( NSLocalizedString(@"Database Update", nil), [NSString stringWithFormat:NSLocalizedString(@"Database updating generated errors. The corrupted studies have been removed:\r\r%@", nil), updatingProblems], nil, nil, nil);

//				NSRunAlertPanel( NSLocalizedString(@"Database Update", nil), NSLocalizedString(@"Database updating generated errors... The corrupted studies have been removed.", nil), nil, nil, nil);
				
				[updatingProblems release];
				updatingProblems = nil;
			}
		}
		
		@catch (NSException *e)
		{
			NSLog( @"updateDatabaseModel failed...");
			NSLog( [e description]);
			
			NEEDTOREBUILD = YES;
			COMPLETEREBUILD = YES;
			
			NSRunAlertPanel( NSLocalizedString(@"Database Update", nil), NSLocalizedString(@"Database updating failed... The database SQL index file is probably corrupted... The database will be reconstructed.", nil), nil, nil, nil);
		}
		
		[previousModel release];
		[currentModel release];
		[previousSC release];
		[currentSC release];
		
		[currentContext reset];
		[previousContext reset];
		
		[currentContext release];
		[previousContext release];
		
		[splash close];
		[splash release];
		
		displayEmptyDatabase = NO;
		needDBRefresh = YES;
	}
	else
	{
		int r = NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot understand the model of current saved database... The database index will be deleted and reconstructed (no images are lost).", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Quit", nil), nil);
		if( r == NSAlertAlternateReturn)
		{
			NSString *pathTemp = [[self documentsDirectory] stringByAppendingString:@"/Loading"];	// To avoid the crash message during next startup
			[[NSFileManager defaultManager] removeFileAtPath:pathTemp handler: nil];
			[[NSApplication sharedApplication] terminate: self];
		}
		[[NSFileManager defaultManager] removeFileAtPath:currentDatabasePath handler:nil];
		NEEDTOREBUILD = YES;
		COMPLETEREBUILD = YES;
	}
}

- (void) recomputePatientUIDs
{
	NSLog( @"recomputePatientUIDs");
	
	// Find all studies
	NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	NSManagedObjectContext *context = self.managedObjectContext;
	
	[context lock];
	NSError *error = nil;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	for( NSManagedObject *study in studiesArray )
	{
		@try
		{
			NSManagedObject *o = [[[[study valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
			DicomFile	*dcm = [[DicomFile alloc] init: [o valueForKey:@"completePath"]];
			
			if( dcm)
			{
				if( [dcm elementForKey:@"patientUID"])
					[study setValue: [dcm elementForKey:@"patientUID"] forKey:@"patientUID"];
			}
			
			[dcm release];
		}
		@catch ( NSException *e)
		{
			NSLog( @"recomputePatientUIDs exception : %@", e);
		}
	}
	[context unlock];
}

- (void)showEntireDatabase
{
	timeIntervalType = 0;
	[timeIntervalPopup selectItemWithTag: 0];
	
	[albumTable selectRow:0 byExtendingSelection:NO];
	self.searchString = @"";
}

- (void)setDBWindowTitle
{
	if( isCurrentDatabaseBonjour) [self.window setTitle: [NSString stringWithFormat: NSLocalizedString(@"Bonjour Database (%@)", nil), [currentDatabasePath lastPathComponent]]];
	else [self.window setTitle: [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), currentDatabasePath]];
	[self.window setRepresentedFilename: currentDatabasePath];
}

- (NSString*)getDatabaseFolderFor: (NSString*)path
{
	BOOL isDirectory;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] )
	{
		if( isDirectory == NO)
		{
			// It is a SQL file
			
			if( [[path pathExtension] isEqualToString:@"sql"] == NO) NSLog( @"**** No SQL extension ???");
			
			NSString	*db = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
			
			if( db == nil )
			{
				NSString	*p = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DATABASE.noindex"];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: p] )
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

- (NSString*)getDatabaseIndexFileFor: (NSString*)path
{
	BOOL isDirectory;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] )
	{
		if( isDirectory )
		{
			// Default SQL file
			NSString	*index = [[path stringByAppendingPathComponent:@"OsiriX Data"] stringByAppendingPathComponent:@"Database.sql"];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: index] )
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

- (int) findDBPath:(NSString*) path dbFolder:(NSString*) DBFolderLocation
{
	// Is this DB location available in the Source table? If not, add it
	BOOL found = NO;
	int i = 0;
	
	// First, is it the default DB ?
	NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
	
	if( [[defaultPath stringByAppendingPathComponent:@"Database.sql"] isEqualToString: path] )
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
		for( NSDictionary *service in [bonjourBrowser services] )
		{
			NSString	*type = [service valueForKey:@"type"];
			
			if( [type isEqualToString:@"localPath"] )
			{
				NSString	*cPath = [service valueForKey:@"Path"];
				
				if( [[[cPath pathExtension] lowercaseString] isEqualToString:@"sql"])
				{
					if( [path isEqualToString: cPath])
					{
						found = YES;
						i = [[bonjourBrowser services] indexOfObject: service] + 1;
						break;
					}
				}
				else
				{
					if( [cPath isEqualToString: DBFolderLocation] && [[path lastPathComponent] isEqualToString:@"Database.sql"])
					{
						found = YES;
						i = [[bonjourBrowser services] indexOfObject: service] + 1;
						break;
					}
				}
			}
		}
	}
	
	if( found)	return i;
	else return -1;
}

- (void) loadDatabase:(NSString*) path
{
	long        i;
	
	[[AppController sharedAppController] closeAllViewers: self];
	
	displayEmptyDatabase = YES;
	[self outlineViewRefresh];
	[self refreshMatrix: self];
	
	[albumTable selectRow:0 byExtendingSelection:NO];
	
	NSString	*DBVersion, *DBFolderLocation, *curPath = [self.documentsDirectory stringByDeletingLastPathComponent];
	
	DBVersion = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"]];
	DBFolderLocation = [NSString stringWithContentsOfFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"]];
	
	if( isCurrentDatabaseBonjour)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		DBFolderLocation = self.documentsDirectory;
		DBFolderLocation = [DBFolderLocation stringByDeletingLastPathComponent];
	}
	
	if( DBFolderLocation == nil)
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
		if( [self.documentsDirectory isEqualToString: [path stringByDeletingLastPathComponent]] == NO)
			[[self.documentsDirectory stringByDeletingLastPathComponent] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] atomically:YES encoding : NSUTF8StringEncoding error: nil];
		else
			[[NSFileManager defaultManager] removeFileAtPath: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] handler: nil];
			
		i = [self findDBPath: path dbFolder: DBFolderLocation];
		if( i == -1 )
		{
			NSLog( @"DB Not found -> we add it");
			
			NSArray			*dbArray		= [[NSUserDefaults standardUserDefaults] arrayForKey: @"localDatabasePaths"];
			
			if( dbArray == nil) dbArray = [NSArray array];
			
			if( [[path lastPathComponent] isEqualToString: @"Database.sql"])	// We will add the folder, since it is the default sql file for a DB folder
			{
				NSString	*name = [[NSFileManager defaultManager] displayNameAtPath: DBFolderLocation];
				
				dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: DBFolderLocation, @"Path", [name stringByAppendingString:@" DB"], @"Description", nil]];			
			}
			else
			{
				dbArray = [dbArray arrayByAddingObject: [NSDictionary dictionaryWithObjectsAndKeys: path, @"Path", [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@" DB"], @"Description", nil]];
			}
			
			[[NSUserDefaults standardUserDefaults] setObject: dbArray forKey: @"localDatabasePaths"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:nil];
			
			// Select it
			i = [self findDBPath: path dbFolder: DBFolderLocation];
		}
		
		if( i != [bonjourServicesList selectedRow])
		{
			if( i == -1) NSLog( @"**** NOT FOUND??? WHY? we added it... no?");
			dontLoadSelectionSource = YES;
			[bonjourServicesList selectRow: i byExtendingSelection: NO];
			dontLoadSelectionSource = NO;
		}
	}
	
	if( DBVersion == nil) 
		DBVersion = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
	
	NSLog(@"Opening DB: %@ Version: %@ DB Folder: %@", path, DBVersion, DBFolderLocation);
	
	if( DBVersion && [DBVersion isEqualToString: DATABASEVERSION] == NO )
	{
		[self updateDatabaseModel: path :DBVersion];
		
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"recomputePatientUID"];
	}
	
	[self resetLogWindowController];
	[[LogManager currentLogManager] resetLogs];
	
	[managedObjectContext lock];
	[managedObjectContext unlock];
	[managedObjectContext reset];
	[managedObjectContext release];
	managedObjectContext = nil;
	[self setFixedDocumentsDirectory];
	[self managedObjectContext];
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"recomputePatientUID"] )
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"recomputePatientUID"];
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Recompute Patient UIDs", nil)];
		[wait showWindow:self];
		
		@try
		{
			[self recomputePatientUIDs];
		}
		@catch (NSException *ne)
		{
			NSLog( @"recomputePatientUIDs exception: %@ %@", [ne name], [ne reason]);
		}
		
		[wait close];
		[wait release];
	}
	
	// CHECK IF A DICOMDIR FILE IS AVAILABLE AT SAME LEVEL AS OSIRIX!?
	NSString	*dicomdir = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/DICOMDIR"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dicomdir] )
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
		
		if( NEEDTOREBUILD )
		{
			[self ReBuildDatabase:self];
		}
		else
		{
			[self outlineViewRefresh];
		}
	}
	
	NSString *pathTemp = [[self documentsDirectory] stringByAppendingString:@"/Loading"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:pathTemp] )
	{
		[[NSFileManager defaultManager] removeFileAtPath:pathTemp handler: nil];
	}
	
	[AppController createNoIndexDirectoryIfNecessary: [[self documentsDirectory] stringByAppendingPathComponent: DATABASEPATH]];
	[AppController createNoIndexDirectoryIfNecessary: [[self documentsDirectory] stringByAppendingPathComponent: INCOMINGPATH]];
	
	[self setDBWindowTitle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriXServerArray has changed" object:nil];
	
	displayEmptyDatabase = NO;
	[self outlineViewRefresh];
	[self refreshMatrix: self];
	
	[[QueryController currentQueryController] refresh: self];
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
}

-(long)saveDatabase: (NSString*)path
{
	long retError = 0;
	
	if( DICOMDIRCDMODE == NO && isCurrentDatabaseBonjour == NO && currentDatabasePath != nil )
	{
		@try
		{
			NSManagedObjectContext *context = self.managedObjectContext;
			NSError *error = nil;
			
			[context retain];
			[context lock];
			
			[context save: &error];
			if (error )
			{
				NSLog(@"error saving DB: %@", [[error userInfo] description]);
				NSLog( @"saveDatabase ERROR: %@", [error localizedDescription]);
				retError = -1L;
			}
			[context unlock];
			[context release];
			
			if( path == nil) path = currentDatabasePath;
			
			[[NSString stringWithString:DATABASEVERSION] writeToFile: [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"DB_VERSION"] atomically:YES];
			
			[[NSUserDefaults standardUserDefaults] setObject:DATABASEVERSION forKey: @"DATABASEVERSION"];
			[[NSUserDefaults standardUserDefaults] setInteger: DATABASEINDEX forKey: @"DATABASEINDEX"];
			
			if( [NSThread currentThread] == mainThread)
				[self outlineViewRefresh];
		}
		
		@catch( NSException *ne )
		{
			NSLog( [ne name]);
			NSLog( [ne reason]);
		}
	}
	
	return retError;
}

- (void)selectThisStudy: (id)study
{
	NSLog( [study description]);
	[self outlineViewRefresh];
	
	[databaseOutline selectRow: [databaseOutline rowForItem: study] byExtendingSelection: NO];
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (void)copyFilesThread : (NSArray*)filesInput
{
	NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	NSString				*INpath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEFPATH];
	NSString				*incomingPath = [[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
	int						listenerInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"];
	BOOL					studySelected = NO;
	NSTimeInterval			lastCheck = [NSDate timeIntervalSinceReferenceDate];
	
	[autoroutingInProgress lock];
	
	BOOL first = YES;
	
	copyThread = YES;
	
	for( NSString *srcPath in filesInput)
	{
		NSString	*dstPath;
		NSString	*extension = [srcPath pathExtension];
		
		@try
		{
			if( copyThread == YES && [[srcPath stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
			{
				DicomFile	*curFile = [[DicomFile alloc] init: srcPath];
				
				if( curFile )
				{
					if([extension isEqualToString:@""])
						extension = [NSString stringWithString:@"dcm"]; 
					
					int x = 0;
					do
					{
						dstPath = [incomingPath stringByAppendingPathComponent: [NSString stringWithFormat:@".%d-%@", x, [srcPath lastPathComponent]]];	//We add a '.' at the beginning of the file, to avoid the checkincoming until it is fully copied
						x++;
					}
					while( [[NSFileManager defaultManager] fileExistsAtPath: dstPath]);
					
					[[NSFileManager defaultManager] copyPath: srcPath toPath: dstPath handler:nil];
					
					// Remove the '.'
					
					NSString *newDstPath = [[dstPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: [[dstPath lastPathComponent] substringFromIndex: 1]];
					[[NSFileManager defaultManager] movePath: dstPath toPath: newDstPath handler:nil];
					dstPath = newDstPath;
					
					if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
					{
						[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
					}
					
					if( first)
					{
						[self performSelectorOnMainThread:@selector( checkIncoming:) withObject: self waitUntilDone: YES];
						first = NO;
					}
					else if( studySelected == NO)
					{
						NSManagedObjectContext	*context = self. managedObjectContext;
						
						NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
						[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
						[dbRequest setPredicate: [NSPredicate predicateWithFormat:  @"studyInstanceUID == %@", [curFile elementForKey: @"studyID"]]];
						
						[context retain];
						[context lock];
						
						NSError *error = nil;
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
		@catch (NSException * e)
		{
			NSLog( @"copyFilesThread exception: %@", e);
		}
	}
	
	[self performSelectorOnMainThread:@selector( checkIncoming:) withObject: self waitUntilDone: NO];
	
	[autoroutingInProgress unlock];
	
	if( [filesInput count] )
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey:@"EJECTCDDVD"])
		{
			[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:  [filesInput objectAtIndex:0]];
		}
	}
	
	[pool release];
}

- (NSMutableArray*)copyFilesIntoDatabaseIfNeeded: (NSMutableArray*)filesInput
{
	return [self copyFilesIntoDatabaseIfNeeded: filesInput async: NO];
}

- (IBAction) copyToDBFolder: (id) sender
{
	BOOL matrixThumbnails = NO;
	
	if( isCurrentDatabaseBonjour) return;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		matrixThumbnails = YES;
		NSLog( @"copyToDBFolder from matrix");
	}
	
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray *files;
	
	if( matrixThumbnails)
		files = [self filesForDatabaseMatrixSelection: objects onlyImages: NO];
	else
		files = [self filesForDatabaseOutlineSelection: objects onlyImages: NO];
	
	[files removeDuplicatedStringsInSyncWithThisArray: objects];
	
	Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Copying linked files into Database...", nil)];
		
	[splash showWindow:self];
	[[splash progress] setMaxValue:[objects count]];
	[splash setCancel: YES];
		
	[managedObjectContext lock];
	@try
	{
		for( NSManagedObject *im in objects)
		{
			if( [[im valueForKey: @"inDatabaseFolder"] boolValue] == NO)
			{
				NSString *srcPath = [im valueForKey:@"completePath"];
				NSString *extension = [srcPath pathExtension];
				
				if([extension isEqualToString:@""])
					extension = [NSString stringWithString:@"dcm"]; 
				
				NSString *dstPath = [self getNewFileDatabasePath:extension];
				
				if( [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler:nil])
				{
					[im setValue: [NSNumber numberWithBool: YES] forKey:@"inDatabaseFolder"];
					[im setValue: [dstPath lastPathComponent] forKey:@"path"];
					[im setValue: [NSNumber numberWithBool: NO] forKey:@"mountedVolume"];
					[[im valueForKey:@"series"] setValue: [NSNumber numberWithBool: NO] forKey:@"mountedVolume"];
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
	}
	[managedObjectContext unlock];
	[splash close];
	[splash release];
}

- (NSMutableArray*)copyFilesIntoDatabaseIfNeeded: (NSMutableArray*)filesInput async: (BOOL)async
{
	return [self copyFilesIntoDatabaseIfNeeded: filesInput async: async COPYDATABASE: [[NSUserDefaults standardUserDefaults] boolForKey: @"COPYDATABASE"] COPYDATABASEMODE: [[NSUserDefaults standardUserDefaults] integerForKey: @"COPYDATABASEMODE"]];
}

- (NSMutableArray*)copyFilesIntoDatabaseIfNeeded: (NSMutableArray*)filesInput async: (BOOL)async COPYDATABASE: (BOOL) COPYDATABASE COPYDATABASEMODE:(int) COPYDATABASEMODE;
{
	if( isCurrentDatabaseBonjour) return nil;
	if( [filesInput count] == 0) return filesInput;
	if( COPYDATABASE == NO) return filesInput;
	
	NSMutableArray *newList = [NSMutableArray arrayWithCapacity: [filesInput count]];
	NSString *INpath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEFPATH];
	
	for( NSString *file in filesInput)
	{
		if( [[file commonPrefixWithString: INpath options: NSLiteralSearch] isEqualToString:INpath] == NO)
			[newList addObject: file];
	}
	
	if( [newList count] == 0) return filesInput;
	
	switch (COPYDATABASEMODE)
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
			
			NSLog( [filesInput objectAtIndex:0]);
			
			if( [BrowserController isItCD: [filesInput objectAtIndex:0]] == NO) return filesInput;
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
	
    NSString *OUTpath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEPATH];
	
	[AppController createNoIndexDirectoryIfNecessary: OUTpath];
	
    NSMutableArray  *filesOutput = [NSMutableArray array];
	
	if( async )
	{
		[NSThread detachNewThreadSelector:@selector(copyFilesThread:) toTarget:self withObject: filesInput];
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
			
			NSString	*extension = [srcPath pathExtension];
			
			@try
			{
				if( [[[srcPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] isEqualToString:INpath] == NO)
				{
					DicomFile	*curFile = [[DicomFile alloc] init: srcPath];
					
					if( curFile)
					{
						[curFile release];
						
						if([extension isEqualToString:@""])
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
				}
			}
			@catch (NSException * e)
			{
				NSLog( @"copyFilesIntoDatabaseIfNeeded exception: %@", e);
			}
			[splash incrementBy:1];
			
			[pool release];
			
			if( [splash aborted])
				break;
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
	
	if( [sender tag] )	{
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
		
		switch( [rebuildType selectedTag] )	{
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
	if( isCurrentDatabaseBonjour) return;
	
	[self waitForRunningProcesses];
	
	[[AppController sharedAppController] closeAllViewers: self];
	
	BOOL REBUILDEXTERNALPROCESS = NO;
	
	if( COMPLETEREBUILD)	// Delete the database file
	{
		if ([[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath])
		{
			[[NSFileManager defaultManager] removeFileAtPath: [currentDatabasePath stringByAppendingString:@" - old"] handler: nil];
			[[NSFileManager defaultManager] movePath: currentDatabasePath toPath: [currentDatabasePath stringByAppendingString:@" - old"] handler: nil];
		}
	}
	else
	{
		[self saveDatabase:currentDatabasePath];
	}
	
	displayEmptyDatabase = YES;
	[self outlineViewRefresh];
	[self refreshMatrix: self];
	
	[checkIncomingLock lock];
	
	[managedObjectContext lock];
	[managedObjectContext unlock];
	[managedObjectContext release];
	managedObjectContext = nil;
	
	[databaseOutline reloadData];
	
	NSMutableArray				*filesArray;
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Step 1: Checking files...", nil)];
	[wait showWindow:self];
	
	filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
	
	// SCAN THE DATABASE FOLDER, TO BE SURE WE HAVE EVERYTHING!
	
	NSString	*aPath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEPATH];
	NSString	*incomingPath = [[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
	long		totalFiles = 0;
	
	[AppController createNoIndexDirectoryIfNecessary: aPath];
	
	// In the DATABASE FOLDER, we have only folders! Move all files that are wrongly there to the INCOMING folder.... and then scan these folders containing the DICOM files
	
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for( NSString *dir in dirContent )
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: dir];
		id fileType = [[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey:NSFileType];
		if ([fileType isEqual:NSFileTypeRegular])
		{
			[[NSFileManager defaultManager] movePath:itemPath toPath:[incomingPath stringByAppendingPathComponent: [itemPath lastPathComponent]] handler: nil];
		}
		else totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
	}
	
	[wait close];
	[wait release];
	
	dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	
	Wait *REBUILDEXTERNALPROCESSProgress = nil;
	
	if( REBUILDEXTERNALPROCESS)
	{
		[managedObjectContext release];
		managedObjectContext = nil;
		
		REBUILDEXTERNALPROCESSProgress = [[Wait alloc] initWithString: [NSString stringWithFormat: NSLocalizedString(@"Adding %@ files...", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt:totalFiles]]]];
		[REBUILDEXTERNALPROCESSProgress showWindow:self];
		[[REBUILDEXTERNALPROCESSProgress progress] setMaxValue: totalFiles];
	}
	
	NSLog( @"Start Rebuild");
	
	for( NSString *name in dirContent )
	{
		NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
		
		NSString	*curDir = [aPath stringByAppendingPathComponent: name];
		NSArray		*subDir = [[NSFileManager defaultManager] directoryContentsAtPath: [aPath stringByAppendingPathComponent: name]];
		
		for( NSString *subName in subDir )
		{
			if( [subName characterAtIndex: 0] != '.')
				[filesArray addObject: [curDir stringByAppendingPathComponent: subName]];
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
	
	// ** DICOM ROI SR FOLDER
	dirContent = [[NSFileManager defaultManager] directoryContentsAtPath: [[self documentsDirectory] stringByAppendingPathComponent:@"ROIs"]];
	for( NSString *name in dirContent )
	{
		if( [name characterAtIndex: 0] != '.')
		{
			[filesArray addObject: [[[self documentsDirectory] stringByAppendingPathComponent:@"ROIs"] stringByAppendingPathComponent: name]];
		}
	}
	
	if( REBUILDEXTERNALPROCESS)
	{
		[self callAddFilesToDatabaseSafe: filesArray];
		
		[filesArray release];
		filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
	}
	
	// ** Finish the rebuild
	if( REBUILDEXTERNALPROCESS == NO)
	{
		[[self addFilesToDatabase: filesArray onlyDICOM:NO safeRebuild:NO produceAddedFiles:NO] valueForKey:@"completePath"];
	}
	else
	{
		[REBUILDEXTERNALPROCESSProgress close];
		[REBUILDEXTERNALPROCESSProgress release];
		REBUILDEXTERNALPROCESSProgress = nil;
	}
	
	NSLog( @"End Rebuild");
	
	[filesArray release];
	
	Wait  *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Step 3: Cleaning Database...", nil)];
	
	[splash showWindow:self];
	
	NSManagedObjectContext		*context = self.managedObjectContext;
	NSManagedObjectModel		*model = self.managedObjectModel;
	
	[context retain];
	[context lock];
	
	NSFetchRequest	*dbRequest;
	NSError			*error = nil;
	
	if( COMPLETEREBUILD == NO)
	{
		// FIND ALL images, and REMOVE non-available images
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		error = nil;
		NSArray *imagesArray = [context executeFetchRequest:dbRequest error:&error];
		
		[[splash progress] setMaxValue:[imagesArray count]/50];
		
		// Find unavailable files
		int counter = 0;
		for( NSManagedObject *aFile in imagesArray )
		{
			
			FILE *fp = fopen( [[aFile valueForKey:@"completePath"] UTF8String], "r");
			if( fp )
			{
				fclose( fp);
			}
			else
				[context deleteObject: aFile];
			
			if( counter++ % 50 == 0) [splash incrementBy:1];
		}
	}
	
	dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	error = nil;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	NSString	*basePath = [NSString stringWithFormat: @"%@/REPORTS/", [self documentsDirectory]];
	
	if ([studiesArray count] > 0 )
	{
		for( NSManagedObject *study in studiesArray )
		{
			BOOL deleted = NO;
			
			if( [[study valueForKey:@"series"] count] == 0)
			{
				deleted = YES;
				[context deleteObject: study];
			}
			
			if( [[study valueForKey:@"noFiles"] intValue] == 0)
			{
				if( deleted == NO) [context deleteObject: study];
			}
			
			// SCAN THE STUDIES FOR REPORTS
			NSString	*reportPath = nil;
			
			if( reportPath == nil)
			{
				reportPath = [basePath stringByAppendingFormat:@"%@.doc",[Reports getUniqueFilename: study]];
				if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath]) [study setValue:reportPath forKey:@"reportURL"];
			}
			
			if( reportPath == nil)
			{
				reportPath = [basePath stringByAppendingFormat:@"%@.rtf",[Reports getUniqueFilename: study]];
				if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath] ) [study setValue:reportPath forKey:@"reportURL"];
			}
			
			if( reportPath == nil)
			{
				reportPath = [basePath stringByAppendingFormat:@"%@.doc",[Reports getOldUniqueFilename: study]];
				if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath]) [study setValue:reportPath forKey:@"reportURL"];
			}
			
			if( reportPath == nil)
			{
				reportPath = [basePath stringByAppendingFormat:@"%@.rtf",[Reports getOldUniqueFilename: study]];
				if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath] ) [study setValue:reportPath forKey:@"reportURL"];
			}
		}
	}
	
	[self saveDatabase: currentDatabasePath];
	
	[splash close];
	[splash release];
	
	displayEmptyDatabase = NO;
	
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
		NSRunInformationalAlertPanel(NSLocalizedString(@"Database Cleaning", nil), NSLocalizedString(@"Cannot rebuild a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
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
	
	long totalFiles = 0;
	NSString	*aPath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEPATH];
	NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
	for(NSString *name in dirContent )
	{
		NSString * itemPath = [aPath stringByAppendingPathComponent: name];
		totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
	}
	
	[noOfFilesToRebuild setIntValue: totalFiles];
	
	long durationFor1000;
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"TOOLKITPARSER2"] == 0)
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
	
	if( minutes < 1) minutes = 1;
	
	if( hours) [estimatedTime setStringValue:[NSString stringWithFormat:@"%i hour(s), %i minutes", hours, minutes]];
	else [estimatedTime setStringValue:[NSString stringWithFormat:@"%i minutes", minutes]];
	
	[[AppController sharedAppController] closeAllViewers: self];
	
	[NSApp beginSheet: rebuildWindow
	   modalForWindow: self.window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
}

- (IBAction) rebuildSQLFile:(id) sender
{
	if( isCurrentDatabaseBonjour ) return;

	if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Rebuild SQL Index File", nil),
											 NSLocalizedString(@"Are you sure you want to rebuild SQL Index File? It can take several minutes.", nil),
											 NSLocalizedString(@"OK",nil),
											 NSLocalizedString(@"Cancel",nil),
											 nil) == NSAlertDefaultReturn)
	{
		[[AppController sharedAppController] closeAllViewers: self];
		
		[checkIncomingLock lock];
		
		[self saveDatabase: currentDatabasePath];
				
		[[self window] display];
		
		[self updateDatabaseModel: currentDatabasePath :DATABASEVERSION];
		
		[self loadDatabase: currentDatabasePath];
		
		[[self window] display];
		
		[checkIncomingLock unlock];
	}
}

- (void) autoCleanDatabaseDate: (id)sender
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	if( isCurrentDatabaseBonjour ) return;
	if( managedObjectContext == nil ) return;
	if( [NSDate timeIntervalSinceReferenceDate] - gLastActivity < 60*10) return;
	
	if( [checkIncomingLock tryLock])
	{
		NSError					*error = nil;
		NSFetchRequest			*request = [[[NSFetchRequest alloc] init] autorelease];
		NSArray					*logArray;
		NSDate					*producedDate = [[NSDate date] addTimeInterval: -[defaults integerForKey:@"LOGCLEANINGDAYS"]*60*60*24];
		NSManagedObjectContext	*context = self.managedObjectContext;
		NSPredicate				*predicate = [NSPredicate predicateWithFormat: @"startTime <= CAST(%lf, \"NSDate\")", [producedDate timeIntervalSinceReferenceDate]];
		
		[request setEntity: [self.managedObjectModel.entitiesByName objectForKey:@"LogEntry"]];
		[request setPredicate: predicate];
		
		[context retain];
		[context lock];
		error = nil;
		@try
		{
			logArray = [context executeFetchRequest:request error:&error];
			
			for( id log in logArray ) [context deleteObject: log];
		}
		@catch (NSException * e)
		{
			NSLog( @"autoCleanDatabaseDate exception");
			NSLog( [e description]);
		}
		
		[context unlock];
		[context release];
		
		[checkIncomingLock unlock];
	}
	
	[self buildAllThumbnails: self];
	
	if( [defaults boolForKey:@"AUTOCLEANINGDATE"] )
	{
		if( [defaults boolForKey: @"AUTOCLEANINGDATEPRODUCED"] == YES || [defaults boolForKey: @"AUTOCLEANINGDATEOPENED"] == YES)
		{
			if( [checkIncomingLock tryLock])
			{
				NSError				*error = nil;
				NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
				NSPredicate			*predicate = [NSPredicate predicateWithValue:YES];
				NSArray				*studiesArray;
				NSDate				*now = [NSDate date];
				NSDate				*producedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEPRODUCEDDAYS"] intValue]*60*60*24];
				NSDate				*openedDate = [now addTimeInterval: -[[defaults stringForKey:@"AUTOCLEANINGDATEOPENEDDAYS"] intValue]*60*60*24];
				NSMutableArray		*toBeRemoved = [NSMutableArray arrayWithCapacity: 0];
				NSManagedObjectContext *context = self.managedObjectContext;
				BOOL				dontDeleteStudiesWithComments = [[NSUserDefaults standardUserDefaults] boolForKey: @"dontDeleteStudiesWithComments"];
				
				request.entity = [self.managedObjectModel.entitiesByName objectForKey:@"Study"];
				request.predicate = predicate;
				
				[context retain];
				[context lock];
				
				@try
				{
					studiesArray = [context executeFetchRequest:request error:&error];
					
					NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease];
					studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
					
					for( int i = 0; i < [studiesArray count]; i++ )
					{
						NSString	*patientID = [[studiesArray objectAtIndex: i] valueForKey:@"patientID"];
						NSDate		*studyDate = [[studiesArray objectAtIndex: i] valueForKey:@"date"];
						NSDate		*openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"];
						
						if( openedStudyDate == nil ) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
						
						int to, from = i;
						
						while( i < [studiesArray count]-1 && [patientID isEqualToString:[[studiesArray objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
						{
							i++;
							studyDate = [studyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"date"]];
							if( [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]) openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateOpened"]];
							else openedStudyDate = [openedStudyDate laterDate: [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"]];
						}
						to = i;
						
						BOOL dateProduced = YES, dateOpened = YES;
						
						if( [defaults boolForKey: @"AUTOCLEANINGDATEPRODUCED"] )
							dateProduced = [producedDate compare: studyDate] == NSOrderedDescending;
						
						if( [defaults boolForKey: @"AUTOCLEANINGDATEOPENED"] )
						{
							if( openedStudyDate == nil) openedStudyDate = [[studiesArray objectAtIndex: i] valueForKey:@"dateAdded"];
							
							dateOpened = [openedDate compare: openedStudyDate] == NSOrderedDescending;
						}
						
						if(  dateProduced == YES && dateOpened == YES)
						{
							for( int x = from; x <= to; x++ )
							{
								if( [toBeRemoved containsObject:[studiesArray objectAtIndex: x]] == NO && [[[studiesArray objectAtIndex: x] valueForKey:@"lockedStudy"] boolValue] == NO)
								{
									if( dontDeleteStudiesWithComments)
									{
										NSString *str = [[studiesArray objectAtIndex: x] valueForKey: @"comment"];
										
										if( str == nil || [str isEqualToString: @""])
											[toBeRemoved addObject: [studiesArray objectAtIndex: x]];
									}
									else
										[toBeRemoved addObject: [studiesArray objectAtIndex: x]];
								}
							}
						}
					}
					
					for ( int i = 0; i < [toBeRemoved count]; i++ )					// Check if studies are in an album or added this week.  If so don't autoclean that study from the database (DDP: 051108).
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
						for ( int i = 0; i < [toBeRemoved count]; i++ )
						{
							NSString	*comment = [[toBeRemoved objectAtIndex: i] valueForKey: @"comment"];
							
							if( comment == nil) comment = @"";
							
							if ([comment rangeOfString:[defaults stringForKey: @"AUTOCLEANINGCOMMENTSTEXT"] options:NSCaseInsensitiveSearch].location == NSNotFound)
							{
								if( [defaults integerForKey: @"AUTOCLEANINGDONTCONTAIN"] == 0 )
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
				}
				@catch (NSException * e)
				{
					NSLog( @"autoCleanDatabaseDate");
					NSLog( [e description]);
				}
				
				if( [toBeRemoved count] > 0)							// (DDP: 051109) was > 1, i.e. required at least 2 studies out of date to be removed.
				{
					NSLog(@"Will delete: %d studies", [toBeRemoved count]);
					
					Wait *wait = [[Wait alloc] initWithString: NSLocalizedString(@"Database Auto-Cleaning...", nil)];
					[wait showWindow:self];
					[wait setCancel: YES];
					[[wait progress] setMaxValue:[toBeRemoved count]];
					
					@try
					{
						if( [defaults boolForKey: @"AUTOCLEANINGDELETEORIGINAL"] )
						{
							NSMutableArray	*nonLocalImagesPath = [NSMutableArray array];
							
							for ( NSManagedObject *curObj in toBeRemoved )
							{
								
								if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"])
								{
									NSArray	*seriesArray = [self childrenArray: curObj];
									
									for( NSManagedObject *series in seriesArray )
									{
										NSArray		*imagesArray = [self imagesArray: series];
										
										[nonLocalImagesPath addObjectsFromArray: [[imagesArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"]];
									}
								}
								else NSLog( @"Uh? Autocleaning, object strange...");
							}
							
							for ( NSString *path in nonLocalImagesPath )
							{
								[[NSFileManager defaultManager] removeFileAtPath: path handler:nil];
								
								if( [[path pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
								{
									[[NSFileManager defaultManager] removeFileAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
								}
								
								if( [[path pathExtension] isEqualToString:@"zip"])		// ZIP -> DELETE XML
								{
									[[NSFileManager defaultManager] removeFileAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"] handler:nil];
								}
							}
						}
						
						for( id obj in toBeRemoved )
						{
							[context deleteObject: obj];
							
							[wait incrementBy:1];
							if( [wait aborted]) break;
						}
						
						[self saveDatabase: currentDatabasePath];
						
						[self outlineViewRefresh];
					}
					@catch (NSException * e)
					{
						NSLog( @"autoCleanDatabaseDate");
						NSLog( [e description]);
					}
					[wait close];
					[wait release];
				}
				
				[context unlock];
				[context release];
				
				[checkIncomingLock unlock];
			}
		}
	}
	
	[self autoCleanDatabaseFreeSpace: 0L];
}

- (void) autoCleanDatabaseFreeSpace: (id)sender
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	if( isCurrentDatabaseBonjour) return;
	
	if( [defaults boolForKey:@"AUTOCLEANINGSPACE"])
	{
		if( [defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"] == NO && [defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"] == NO)
		{
			NSLog( @"***** WARNING - AUTOCLEANINGSPACE : no options specified !");
		}
		else
		{
			NSDictionary	*fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath: currentDatabasePath];
			
			unsigned long long free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
			
			if( free <= 0 )
			{
				NSLog( @"*** autoCleanDatabaseFreeSpace free <= 0 ??");
				NSLog( currentDatabasePath);
				
				return;
			}
			
			free /= 1024;
			free /= 1024;
			
			NSLog(@"HD Free Space: %d MB", (long) free);
			
			int freeMemoryRequested = [[defaults stringForKey:@"AUTOCLEANINGSPACESIZE"] intValue];
			
			if( sender == 0L)	// Received by the NSTimer : have a larger amount of free memory !
				freeMemoryRequested = (float) freeMemoryRequested * 1.3;
			
			if( (int) free < freeMemoryRequested)
			{
				NSLog(@"------------------- Limit Reached - Starting autoCleanDatabaseFreeSpace");
				
				[checkIncomingLock lock];
				
				NSFetchRequest			*request = [[[NSFetchRequest alloc] init] autorelease];
				NSArray					*studiesArray = nil;
				NSMutableArray			*unlockedStudies = nil;
				NSManagedObjectContext	*context = self.managedObjectContext;
				BOOL					dontDeleteStudiesWithComments = [[NSUserDefaults standardUserDefaults] boolForKey: @"dontDeleteStudiesWithComments"];
				
				[context retain];
				[context lock];

				@try
				{
					[request setEntity: [self.managedObjectModel.entitiesByName objectForKey:@"Study"]];
					[request setPredicate: [NSPredicate predicateWithValue: YES]];
					
					do
					{
						NSTimeInterval		producedInterval = 0;
						NSTimeInterval		openedInterval = 0;
						NSManagedObject		*oldestStudy = nil, *oldestOpenedStudy = nil;
						
						NSError *error = nil;
						studiesArray = [context executeFetchRequest:request error:&error];
						
						NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease];
						studiesArray = [studiesArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sort]];
						
						unlockedStudies = [NSMutableArray arrayWithArray: studiesArray];
						
						for( int i = 0; i < [unlockedStudies count]; i++ )
						{
							if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"lockedStudy"] boolValue] == YES)
							{
								[unlockedStudies removeObjectAtIndex: i];
								i--;
							}
							
							if( dontDeleteStudiesWithComments)
							{
								NSString *str = [[unlockedStudies objectAtIndex: i] valueForKey:@"comment"];
								
								if( str != nil && [str isEqualToString:@""] == NO)
								{
									[unlockedStudies removeObjectAtIndex: i];
									i--;
								}
							}
						}
						
						if( [unlockedStudies count] > 2)
						{
							for( long i = 0; i < [unlockedStudies count]; i++ )	{
								NSString	*patientID = [[unlockedStudies objectAtIndex: i] valueForKey:@"patientID"];
								long		to;
								
								if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)	{
									if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"] timeIntervalSinceNow] < -60*60*24)	// 24 hours
									{
										oldestStudy = [unlockedStudies objectAtIndex: i];
										producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
									}
								}
								
								NSDate *openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateOpened"];
								if( openedDate == nil) openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"];
								
								if( [openedDate timeIntervalSinceNow] < openedInterval )
								{
									oldestOpenedStudy = [unlockedStudies objectAtIndex: i];
									openedInterval = [openedDate timeIntervalSinceNow];
								}
								
								while( i < [unlockedStudies count]-1 && [patientID isEqualToString:[[unlockedStudies objectAtIndex: i+1] valueForKey:@"patientID"]] == YES)
								{
									i++;
									if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"date"] timeIntervalSinceNow] < producedInterval)	{
										if( [[[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"] timeIntervalSinceNow] < -60*60*24)	// 24 hours
										{
											oldestStudy = [unlockedStudies objectAtIndex: i];
											producedInterval = [[oldestStudy valueForKey:@"date"] timeIntervalSinceNow];
										}
									}
									
									openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateOpened"];
									if( openedDate == nil) openedDate = [[unlockedStudies objectAtIndex: i] valueForKey:@"dateAdded"];
									
									if( [openedDate timeIntervalSinceNow] < openedInterval)	{
										oldestOpenedStudy = [unlockedStudies objectAtIndex: i];
										openedInterval = [openedDate timeIntervalSinceNow];
									}
								}
								to = i;
							}
						}
						
						if( [defaults boolForKey:@"AUTOCLEANINGSPACEPRODUCED"] )
						{
							if( oldestStudy)
							{
								NSLog( @"delete oldestStudy: %@", [oldestStudy valueForKey:@"patientUID"]);
								[context deleteObject: oldestStudy];
							}
						}
						
						if ( [defaults boolForKey:@"AUTOCLEANINGSPACEOPENED"] )
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
					while( (long) free < freeMemoryRequested && [unlockedStudies count] > 2);
					
					[self saveDatabase: currentDatabasePath];
				}
				
				@catch ( NSException *e)
				{
					NSLog( @"autoCleanDatabaseFreeSpace exception");
					NSLog( [e description]);
				}
				
				[context unlock];
				[context release];
				
				[checkIncomingLock unlock];
				
				NSLog(@"------------------- Limit Reached - Finishing autoCleanDatabaseFreeSpace");
				
				// This will do a outlineViewRefresh
				if( [newFilesConditionLock tryLock])
					[newFilesConditionLock unlockWithCondition: 1];
			}
		}
	}
	
	{
		NSDictionary	*fsattrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath: currentDatabasePath];
		
		unsigned long long free = [[fsattrs objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
		free /= 1024;
		free /= 1024;
		
		NSLog(@"HD Free Space: %d MB", (long) free);
		
		if( free < 300)
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"Warning", nil),  NSLocalizedString(@"Hard disk is FULL !!!! Major risks of failure !!\r\rClean your database! ", nil), NSLocalizedString(@"OK",nil), nil, nil);
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
	if( [sender tag] == 0 )	{
		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	}
	
	if( [sender tag] == 1 )	{
		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
	}
}

- (IBAction)endCustomInterval: (id)sender
{
	if( [sender tag] == 1 )	{
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
							nil];
	
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
	}
	
	return pred;
}

- (void) outlineViewRefresh		// This function creates the 'root' array for the outlineView
{
	if( databaseOutline == nil) return;
	if( loadingIsOver == NO) return;
	
	NSError				*error =nil;
	NSFetchRequest		*request = [[[NSFetchRequest alloc] init] autorelease];
	NSPredicate			*predicate = nil, *subPredicate = nil;
	NSString			*description = [NSString string];
	NSIndexSet			*selectedRowIndexes =  [databaseOutline selectedRowIndexes];
	NSMutableArray		*previousObjects = [NSMutableArray arrayWithCapacity:0];
	NSArray				*albumArrayContent = nil;
	BOOL				filtered = NO;
	
	if( needDBRefresh) [albumNoOfStudiesCache removeAllObjects];
	needDBRefresh = NO;
	
	NSInteger index = [selectedRowIndexes firstIndex];
	while (index != NSNotFound )
	{
		[previousObjects addObject: [databaseOutline itemAtRow: index]];
		index = [selectedRowIndexes indexGreaterThanIndex:index];
	}
	
	[request setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
	
	predicate = [NSPredicate predicateWithValue:YES];
	
	if( displayEmptyDatabase) predicate = [NSPredicate predicateWithValue:NO];
	
	if( isCurrentDatabaseBonjour && [bonjourServicesList selectedRow] > 0)
	{
		int rowIndex = [bonjourServicesList selectedRow];
		
		NSDictionary *dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
		
		if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [[dict valueForKey:@"service"] name]];
		else description = [description stringByAppendingFormat:NSLocalizedString(@"Bonjour Database: %@ / ", nil), [dict valueForKey:@"Description"]];
		
	}
	else description = [description stringByAppendingFormat:NSLocalizedString(@"Local Database / ", nil)];
	
	// ********************
	// ALBUMS
	// ********************
	
	if( albumTable.selectedRow > 0 )
	{
		NSArray	*albumArray = self.albumArray;
		
		if( [albumArray count] > albumTable.selectedRow)
		{
			NSManagedObject	*album = [self.albumArray objectAtIndex: albumTable.selectedRow];
			NSString		*albumName = [album valueForKey:@"name"];
			
			if( [[album valueForKey:@"smartAlbum"] boolValue] == YES )
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
	else description = [description stringByAppendingFormat:NSLocalizedString(@"No album selected", nil)];
	
	// ********************
	// TIME INTERVAL
	// ********************
	
	[self computeTimeInterval];
	
	if( timeIntervalStart != nil || timeIntervalEnd != nil)
	{
		if( timeIntervalStart != nil && timeIntervalEnd != nil)
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\") AND date <= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate], [timeIntervalEnd timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat: NSLocalizedString(@" / Time Interval: from: %@ to: %@", nil),[DateTimeFormat stringFromDate: timeIntervalStart],  [DateTimeFormat stringFromDate: timeIntervalEnd] ];
		}
		else
		{
			subPredicate = [NSPredicate predicateWithFormat: @"date >= CAST(%lf, \"NSDate\")", [timeIntervalStart timeIntervalSinceReferenceDate]];
			
			description = [description stringByAppendingFormat:NSLocalizedString(@" / Time Interval: since: %@", nil), [DateTimeFormat stringFromDate: timeIntervalStart]];
		}
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, subPredicate, nil]];
		filtered = YES;
	}
	
	// ********************
	// SEARCH FIELD
	// ********************
	
	if ( self.filterPredicate )
	{
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects: predicate, self.filterPredicate, nil]];
		description = [description stringByAppendingString: self.filterPredicateDescription];
		filtered = YES;
	}
	
	[request setPredicate: predicate];
	
	NSManagedObjectContext *context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	error = nil;
	[outlineViewArray release];
	
	@try
	{
		if( albumArrayContent) outlineViewArray = [albumArrayContent filteredArrayUsingPredicate: predicate];
		else outlineViewArray = [context executeFetchRequest:request error:&error];
		
		if( [albumNoOfStudiesCache count] > albumTable.selectedRow && filtered == NO)
		{
			[albumNoOfStudiesCache replaceObjectAtIndex:albumTable.selectedRow withObject:[NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[outlineViewArray count]]]]];
		}
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"OutlineRefresh exception: %@", [ne description]);
		[request setPredicate: [NSPredicate predicateWithValue:YES]];
		outlineViewArray = [context executeFetchRequest:request error:&error];
	}
	
	if( albumTable.selectedRow > 0) filtered = YES;
	
	if( filtered == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"KeepStudiesOfSamePatientTogether"] && [outlineViewArray count] > 0 && [outlineViewArray count] < 300)
	{
		NSMutableArray	*patientPredicateArray = [NSMutableArray array];
		
		for( id obj in outlineViewArray )
		{
			[patientPredicateArray addObject: [NSPredicate predicateWithFormat:  @"(patientID == %@)", [obj valueForKey:@"patientID"]]];
		}
		
		[request setPredicate: [NSCompoundPredicate orPredicateWithSubpredicates: patientPredicateArray]];
		error = nil;
		[originalOutlineViewArray release];
		originalOutlineViewArray = [outlineViewArray retain];
		outlineViewArray = [context executeFetchRequest:request error:&error];
	}
	else
	{
		[originalOutlineViewArray release];
		originalOutlineViewArray = nil;
	}
	
	long images = 0;
	for( id obj in outlineViewArray )
	{
		images += [[obj valueForKey:@"noFiles"] intValue];
	}
	
	description = [description stringByAppendingFormat: NSLocalizedString(@" / Result = %@ studies (%@ images)", nil), [numFmt stringForObjectValue:[NSNumber numberWithInt: [outlineViewArray count]]], [numFmt stringForObjectValue:[NSNumber numberWithInt:images]]];
	
	NSSortDescriptor * sortdate = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO] autorelease];
	NSArray * sortDescriptors;
	if( [databaseOutline sortDescriptors] == nil || [[databaseOutline sortDescriptors] count] == 0 )
	{
		// By default sort by name
		NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		sortDescriptors = [NSArray arrayWithObjects: sort, sortdate, nil];
	}
	else if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] )
	{
		sortDescriptors = [NSArray arrayWithObjects: [[databaseOutline sortDescriptors] objectAtIndex: 0], sortdate, nil];
	}
	else sortDescriptors = [databaseOutline sortDescriptors];
	
	outlineViewArray = [[outlineViewArray sortedArrayUsingDescriptors: sortDescriptors] retain];
	
	[context unlock];
	[context release];
	
	[databaseOutline reloadData];
	
	for( id obj in outlineViewArray )
	{
		if( [[obj valueForKey:@"expanded"] boolValue]) [databaseOutline expandItem: obj];
	}
	
	if( [previousObjects count] > 0 )
	{
		BOOL extend = NO;
		for( id obj in previousObjects )
		{
			[databaseOutline selectRow: [databaseOutline rowForItem: obj] byExtendingSelection: extend];
			extend = YES;
		}
	}
	
	if( [outlineViewArray count] > 0 )
		[[NSNotificationCenter defaultCenter] postNotificationName: NSOutlineViewSelectionDidChangeNotification  object:databaseOutline userInfo: nil];
	
	[databaseDescription setStringValue: description];
	
	[albumTable reloadData];
}

- (void)checkBonjourUpToDateThread: (id)sender
{	
	if( [bonjourServicesList selectedRow] == -1) return;
	
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	[checkIncomingLock lock];
	[checkBonjourUpToDateThreadLock lock];
	
	NSString	*path = nil;
	@try
	{
		path = [bonjourBrowser getDatabaseFile: [bonjourServicesList selectedRow]-1];
	}
	
	@catch (NSException * e)
	{
		NSLog( @"checkBonjourUpToDateThread");
		NSLog( [e description]);
	}

	[checkIncomingLock unlock];
	[checkBonjourUpToDateThreadLock unlock];

	if( path != nil )
		[self performSelectorOnMainThread:@selector(openDatabaseInBonjour:) withObject:path waitUntilDone:YES];
		
//	[self performSelectorOnMainThread:@selector(outlineViewRefresh) withObject:nil waitUntilDone:YES];
	
	[pool release];
}

-(void)checkBonjourUpToDate: (id)sender
{
	[self testAutorouting];
	
	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	if( managedObjectContext == nil) return;
	if( [bonjourServicesList selectedRow] == -1) return;
	
	if( isCurrentDatabaseBonjour)
	{
		BOOL		doit = YES;
		
		if( [[ViewerController getDisplayed2DViewers] count]) doit = NO;
		
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
	else
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"syncOsiriXDB"])
			[[NSNotificationCenter defaultCenter] postNotificationName: @"OsiriXServerArray has changed" object:nil];
	}
}

- (void)refreshSmartAlbums
{
 	NSArray	*a = self.albumArray;
	
	if( self.albumArray.count == albumNoOfStudiesCache.count )
	{
		for ( unsigned int i = 0; i < [a count]; i++ )
		{
			if( [albumNoOfStudiesCache count] > i)
				if( [[[a objectAtIndex: i] valueForKey:@"smartAlbum"] boolValue] == YES) [albumNoOfStudiesCache replaceObjectAtIndex:i withObject:@""];
		}
	}
	else [albumNoOfStudiesCache removeAllObjects];
	
	[albumTable reloadData];
}

- (void)refreshAlbums
{
	[albumNoOfStudiesCache removeAllObjects];
	[albumTable reloadData];
}

- (void)refreshDatabase: (id)sender
{
	if( managedObjectContext == nil ) return;
	if( bonjourDownloading) return;
	if( DatabaseIsEdited) return;
	if( [databaseOutline editedRow] != -1) return;
	
	if( needDBRefresh || [[[self.albumArray objectAtIndex: albumTable.selectedRow] valueForKey:@"smartAlbum"] boolValue] == YES )
	{
		if( [checkIncomingLock tryLock] )
		{
			@try
			{
				[self outlineViewRefresh];
			}
			@catch (NSException * e)
			{
				NSLog( @"refreshDatabase exception");
				NSLog( [e description]);
			}
			[checkIncomingLock unlock];
		}
		else NSLog(@"refreshDatabase locked...");
	}
	else
	{
		[self refreshAlbums];
		[databaseOutline reloadData];
	}
}

- (NSArray*)childrenArray: (NSManagedObject*)item onlyImages: (BOOL)onlyImages
{
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"] )
	{
		[managedObjectContext lock];
		
		NSArray *sortedArray = nil;
		
		@try
		{
			// Sort images with "instanceNumber"
			NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
			NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
			[sort release];
			
			sortedArray = [[[item valueForKey:@"images"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		}
		
		@catch (NSException * e)
		{
			NSLog( [e description]);
		}

		[managedObjectContext unlock];

		return sortedArray;
	}
	
	if ([[item valueForKey:@"type"] isEqualToString:@"Study"])
	{
		[managedObjectContext lock];
		
		NSArray *sortedArray = nil;
		@try
		{
			// Sort series with "id" & date
			NSSortDescriptor * sortid = [[NSSortDescriptor alloc] initWithKey:@"seriesInstanceUID" ascending:YES selector:@selector(numericCompare:)];		//id
			NSSortDescriptor * sortdate = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
			NSArray * sortDescriptors;
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 0) sortDescriptors = [NSArray arrayWithObjects: sortid, sortdate, nil];
			if ([[NSUserDefaults standardUserDefaults] integerForKey: @"SERIESORDER"] == 1) sortDescriptors = [NSArray arrayWithObjects: sortdate, sortid, nil];
			[sortid release];
			[sortdate release];
			
			if( onlyImages) sortedArray = [[item valueForKey:@"imageSeries"] sortedArrayUsingDescriptors: sortDescriptors];
			else sortedArray = [[[item valueForKey:@"series"] allObjects] sortedArrayUsingDescriptors: sortDescriptors];
		}
		@catch (NSException * e)
		{
			NSLog( [e description]);
		}
		
		[managedObjectContext unlock];
		
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
	
	[managedObjectContext lock];
	
	@try
	{
		if ([[item valueForKey:@"type"] isEqualToString:@"Series"] )
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
				
				if( preferredObject != oMiddle )
				{
					if( [i valueForKey:@"thumbnail"] == nil) whichObject = oMiddle;
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
	}
	
	[managedObjectContext unlock];
	
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

- (void)deleteEmptyFoldersForDatabaseOutlineSelection
{
	NSEnumerator		*rowEnumerator = [databaseOutline selectedRowEnumerator];
	NSNumber			*row;
	NSManagedObject		*curObj;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[[[BrowserController currentBrowser] managedObjectContext] lock];
	
	while ( row = [rowEnumerator nextObject] )
	{
		curObj = [databaseOutline itemAtRow:[row intValue]];
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"] )
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
	
	[[[BrowserController currentBrowser] managedObjectContext] unlock];
}

- (NSManagedObject *)firstObjectForDatabaseOutlineSelection
{
	NSManagedObject		*aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
	
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
	NSMutableArray		*selectedFiles = [NSMutableArray array];
	NSEnumerator		*rowEnumerator = [databaseOutline selectedRowEnumerator];
	NSNumber			*row;
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	if( correspondingManagedObjects == nil) correspondingManagedObjects = [NSMutableArray array];
	
	[context retain];
	[context lock];
	
	@try
	{
		while (row = [rowEnumerator nextObject])
		{
			NSManagedObject *curObj = [databaseOutline itemAtRow:[row intValue]];
			
			if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"] )
			{
				NSArray		*imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
				
				[correspondingManagedObjects addObjectsFromArray: imagesArray];
			}
			
			if( [[curObj valueForKey:@"type"] isEqualToString:@"Study"] )
			{
				NSArray	*seriesArray = [self childrenArray: curObj onlyImages: onlyImages];
				
				int totImage = 0;
				
				for( NSManagedObject *obj in seriesArray )
				{
					NSArray		*imagesArray = [self imagesArray: obj onlyImages: onlyImages];
					
					totImage += [imagesArray count];
					
					[correspondingManagedObjects addObjectsFromArray: imagesArray];
				}
				
				if( onlyImages == NO && totImage == 0)							// We don't want empty studies
					[context deleteObject: curObj];
			}
		}
		
		[correspondingManagedObjects removeDuplicatedObjects];
		
		if( isCurrentDatabaseBonjour)
		{
			Wait *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Downloading files...", nil)];
			[splash showWindow:self];
			[splash setCancel: YES];
			
			[[splash progress] setMaxValue: [correspondingManagedObjects count]];
			
			for( NSManagedObject *obj in correspondingManagedObjects )
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
	}
	
	[context release];
	[context unlock];
	
	
	return selectedFiles;
	
}

- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects
{
	return [self filesForDatabaseOutlineSelection:correspondingManagedObjects onlyImages: YES];
}

- (void) resetROIsAndKeysButton
{
	ROIsAndKeyImagesButtonAvailable = YES;
		
	NSMutableArray *i = [NSMutableArray arrayWithArray: [[toolbar items] valueForKey: @"itemIdentifier"]];
	if( [i containsString: OpenKeyImagesAndROIsToolbarItemIdentifier] && isCurrentDatabaseBonjour == NO)
	{
		if( [[self window] firstResponder] == databaseOutline && [[databaseOutline selectedRowIndexes] count] > 10)
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

- (void)outlineViewSelectionDidChange: (NSNotification *)aNotification
{
	if( loadingIsOver == NO) return;
	
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item)
	{
		/**********
		 post notification of new selected item. Can be used by plugins to update RIS connection
		 **********/
		NSManagedObject *studySelected = [[[item entity] name] isEqual:@"Study"] ? item : [item valueForKey:@"study"];
		
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:studySelected forKey:@"Selected Study"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NewStudySelectedNotification" object:self userInfo:(NSDictionary *)userInfo];
		
		BOOL	refreshMatrix = YES;
		long	nowFiles = [[item valueForKey:@"noFiles"] intValue];
		
		if( previousItem == item)
		{
			if( nowFiles == previousNoOfFiles) refreshMatrix = NO;
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
			if( [files count] > 1 )
			{
				if( [[files objectAtIndex: 0] valueForKey:@"series"] == [[files objectAtIndex: 1] valueForKey:@"series"]) imageLevel = YES;
			}
			
			if( imageLevel == NO)
			{
				for( NSManagedObject *obj in files )
				{
					NSImage *thumbnail = [[[NSImage alloc] initWithData: [obj valueForKeyPath:@"series.thumbnail"]] autorelease];
					if( thumbnail == nil) thumbnail = notFoundImage;
					
					[previewPixThumbnails addObject: thumbnail];
				}
			}
			else
			{
				for( unsigned int i = 0; i < [files count];i++ ) [previewPixThumbnails addObject: notFoundImage];
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
			
			for( NSInteger x = 0; x < [seriesArray count] ; x++ )
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
			
			for( NSManagedObject	*series in seriesArray )
			{
				if( series != destSeries)
				{
					if( [[series valueForKey:@"type"] isEqualToString:@"Series"] )
					{
						NSArray *images = [[series valueForKey: @"images"] allObjects];
				
						for( id i in images)
							[i setValue: destSeries forKey: @"series"];
						
						[context deleteObject: series];
					}
				}
			}
			
			[destSeries setValue:[NSNumber numberWithInt:0] forKey:@"numberOfImages"];
		}
		
		[self saveDatabase: currentDatabasePath];
		
		[self refreshMatrix: self];
		
		[context unlock];
		[context release];
	}
}

- (IBAction) mergeSeries:(id) sender
{
	NSArray				*cells = [oMatrix selectedCells];
	NSMutableArray		*seriesArray = [NSMutableArray array];
	
	for( NSCell *cell in cells )
	{
		if( [cell isEnabled] == YES )
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
		
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		NSManagedObject	*destStudy = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
		
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
		
		NSLog(@"UNIFY STUDIES: %@", destStudy);
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++ )
		{
			NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			
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
		
		[self saveDatabase: currentDatabasePath];
		
		[self outlineViewRefresh];
		
		[databaseOutline selectRow:[databaseOutline rowForItem: destStudy] byExtendingSelection: NO];
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
	
	for( NSInteger x = 0; x < [selectedRows count] ; x++ )
	{
		NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
		NSManagedObject	*series = [databaseOutline itemAtRow: row];
		if( [[series valueForKey:@"type"] isEqualToString: @"Series"] == NO) onlySeries = NO;
		
		[seriesArray addObject: series];
	}
	
	if( onlySeries)
	{
		[self mergeSeriesExecute: seriesArray];
		return;
	}
	
	NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Merge Studies", nil), NSLocalizedString(@"Are you sure you want to merge the selected studies? It cannot be cancelled.\r\rWARNING! If you merge multiple patients, the Patient Name and ID will be identical.", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
	
	if( result == NSAlertDefaultReturn)
	{
		NSManagedObjectContext	*context = self.managedObjectContext;
		
		[context retain];
		[context lock];
		
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		// The destination study : prefer DICOM study
		NSManagedObject	*destStudy = [databaseOutline itemAtRow: [selectedRows firstIndex]];
		for( NSInteger x = 0; x < [selectedRows count] ; x++ )
		{
			NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*study = [databaseOutline itemAtRow: row];
			
			if( [[study valueForKey:@"type"] isEqualToString: @"Study"] == NO) study = [study valueForKey:@"study"];
			
			NSManagedObject *image = [[[[study valueForKey:@"series"] anyObject] valueForKey: @"images"] anyObject];
			
			if( [[image valueForKey:@"extension"] isEqualToString:@"dcm"])
				destStudy = study;
		}
		
		if( [[destStudy valueForKey:@"type"] isEqualToString: @"Study"] == NO) destStudy = [destStudy valueForKey:@"study"];
		
		NSLog(@"MERGING STUDIES: %@", destStudy);
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++ )
		{
			NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
			
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
		
		[self saveDatabase: currentDatabasePath];
		
		[self outlineViewRefresh];
		
		[databaseOutline selectRow:[databaseOutline rowForItem: destStudy] byExtendingSelection: NO];
		[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		
		[self refreshMatrix: self];
		
		[context unlock];
		[context release];
	}
}

- (void) delObjects:(NSMutableArray*) objectsToDelete
{	
	NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
	int result;
	NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers], *studiesArray = [NSMutableArray arrayWithCapacity:0] , *seriesArray = [NSMutableArray arrayWithCapacity:0];
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	if( [databaseOutline selectedRow] >= 0 )
	{
		[context lock];
		// Are some images locked?
		NSArray	*lockedImages = [objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"series.study.lockedStudy == YES"]];
		
		if( [lockedImages count] == [objectsToDelete count] && [lockedImages count] > 0 )
		{
			NSRunAlertPanel( NSLocalizedString(@"Locked Studies", nil),  NSLocalizedString(@"These images are stored in locked studies. First, unlock these studies to delete them.", nil), nil, nil, nil);
		}
		else
		{
			BOOL cancelled = NO;
			
			if( [lockedImages count] )
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
				}
			}
			
			if( cancelled == NO)
			{
				NSLog( @"locked images: %d", [lockedImages count]);
				
				// Try to find images that aren't stored in the local database
				
				NSMutableArray	*nonLocalImagesPath = [NSMutableArray arrayWithCapacity: 0];
				
				WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing Delete...", nil)];
				[wait showWindow:self];
				
				nonLocalImagesPath = [[objectsToDelete filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"inDatabaseFolder == NO"]] valueForKey:@"completePath"];
				
				[wait close];
				[wait release];
				
				NSLog(@"non-local images : %d", [nonLocalImagesPath count]);
				
				if( [nonLocalImagesPath  count] > 0 )
				{
					result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete/Remove images", nil), NSLocalizedString(@"Some of the selected images are not stored in the Database folder. Do you want to only remove the links of these images from the database or also delete the original files?", nil), NSLocalizedString(@"Remove the links",nil),  NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Delete the files",nil));
				}
				else result = NSAlertDefaultReturn;
				
				wait = [[WaitRendering alloc] init: NSLocalizedString(@"Deleting...", nil)];
				[wait showWindow:self];
				
				if( result == NSAlertAlternateReturn )
				{
					NSLog( @"Cancel");
				}
				else
				{			
					if( result == NSAlertDefaultReturn || result == NSAlertOtherReturn)
					{
						NSManagedObject	*study = nil, *series = nil;
						
						NSLog(@"objects to delete : %d", [objectsToDelete count]);
						
						for ( NSManagedObject *obj in objectsToDelete )
						{
							if( [obj valueForKey:@"series"] != series)
							{
								// ********* SERIES
								
								series = [obj valueForKey:@"series"];
								
								if([seriesArray containsObject: series] == NO )
								{
									if( series) [seriesArray addObject: series];
									
									// Is a viewer containing this series opened? -> close it
									for( ViewerController *vc in viewersList )
									{
										if( series == [[[vc fileList] objectAtIndex: 0] valueForKey:@"series"])
											[[vc window] close];
									}
								}
								
								// ********* STUDY
								
								if( [series valueForKey:@"study"] != study )
								{
									study = [series valueForKey:@"study"];
									
									if([studiesArray containsObject: study] == NO )
									{
										if( study) [studiesArray addObject: study];
										
										// Is a viewer containing this series opened? -> close it
										for( ViewerController *vc in viewersList )
										{
											if( study == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"])
											{
												[vc buildMatrixPreview];
											}
										}
									}
								}
							}
							
							[context deleteObject: obj ];
						}
						
						[databaseOutline selectRow:[selectedRows firstIndex] byExtendingSelection:NO];
					}
					
					if( result == NSAlertOtherReturn)
					{
						for( NSString *path in nonLocalImagesPath )
						{
							[[NSFileManager defaultManager] removeFileAtPath: path handler:nil];
							
							if( [[path pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
							{
								[[NSFileManager defaultManager] removeFileAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler:nil];
							}
							
							if( [[path pathExtension] isEqualToString:@"zip"])		// ZIP -> DELETE XML
							{
								[[NSFileManager defaultManager] removeFileAtPath:[[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"] handler:nil];
							}
							
							NSString *currentDirectory = [[path stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
							NSArray *dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:currentDirectory];
							
							//Is this directory empty?? If yes, delete it!
							
							if( [dirContent count] == 0) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
							if( [dirContent count] == 1)
							{
								if( [[[dirContent objectAtIndex: 0] uppercaseString] isEqualToString:@".DS_STORE"]) [[NSFileManager defaultManager] removeFileAtPath:currentDirectory handler:nil];
							}
						}
					}
				}
				[wait close];
				[wait release];
			}
		}
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
		[wait showWindow:self];
		
		[context save: nil];
		@try
		{
			// Remove series without images !
			for( NSManagedObject *series in seriesArray)
			{
				if( [[series valueForKey:@"images"] count] == 0 )
				{
					[context deleteObject: series];
				}
				else
				{
					[series setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
					[series setValue: nil forKey:@"thumbnail"];	
				}
			}
			
			[context save: nil];
			
			// Remove studies without series !
			for( NSManagedObject *study in studiesArray )
			{
				NSLog( @"Delete Study: %@ - %@", [study valueForKey:@"name"], [study valueForKey:@"patientID"]);
				
				if( [[study valueForKey:@"imageSeries"] count] == 0 )
				{
					[context deleteObject: study];
				}
				else
				{
					[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
				}
			}
			[self saveDatabase: currentDatabasePath];
			
		}
		
		@catch( NSException *ne)
		{
			NSLog( @"Exception during delItem");
			NSLog( [ne description]);
		}
		
		[context unlock];
		
		[wait close];
		[wait release];
	}
}

- (IBAction)delItem: (id)sender
{
	NSInteger				result;
	NSManagedObjectContext	*context = self.managedObjectContext;
	BOOL					matrixThumbnails = YES;
	int						animState = [animationCheck state];
	
	[self checkResponder];
		
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		matrixThumbnails = YES;
	
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [databaseOutline menu]) || [[self window] firstResponder] == databaseOutline)
		matrixThumbnails = NO;
	
	NSString *level = nil;
	
	if( matrixThumbnails)
		level = NSLocalizedString( @"Selected Thumbnails", nil);
	else
		level = NSLocalizedString( @"Selected Lines", nil);
	
	needDBRefresh = YES;
	
	[animationCheck setState: NSOffState];
	
	[context retain];
	[context lock];
	
	if( albumTable.selectedRow > 0 && matrixThumbnails == NO)
	{
		NSManagedObject	*album = [self.albumArray objectAtIndex: albumTable.selectedRow];
		
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
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0 )
		{			
			NSMutableArray *studiesToRemove = [NSMutableArray array];
			NSManagedObject	*album = [self.albumArray objectAtIndex: albumTable.selectedRow];
			
			for( NSInteger x = 0; x < [selectedRows count] ; x++ )
			{
				NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
				
				NSManagedObject	*study = [databaseOutline itemAtRow: row];
				
				if( [[study valueForKey:@"type"] isEqualToString: @"Study"] )
				{
					[studiesToRemove addObject: study];
					
					NSMutableSet	*studies = [album mutableSetValueForKey: @"studies"];
					[studies removeObject: study];
				}
			}
			
			if( isCurrentDatabaseBonjour)
			{
				// Do it remotely
				
				[bonjourBrowser removeStudies: studiesToRemove fromAlbum: album bonjourIndex:[bonjourServicesList selectedRow]-1];
			}
			
			[databaseOutline selectRow:[selectedRows firstIndex] byExtendingSelection:NO];
		}
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Updating database...", nil)];
		[wait showWindow:self];
		
		@try
		{
			[self saveDatabase: currentDatabasePath];
			[self refreshDatabase: self];
		}
		@catch( NSException *ne)
		{
			NSLog( @"Exception Updating database...");
			NSLog( [ne description]);
		}
		
		[wait close];
		[wait release];
	}
	else if( isCurrentDatabaseBonjour)
	{
		NSRunAlertPanel( NSLocalizedString(@"Bonjour Database", nil),  NSLocalizedString(@"You cannot modify a Bonjour shared database.", nil), nil, nil, nil);
		
		[context release];
		[context unlock];
		
		[animationCheck setState: animState];
		
		return;
	}
	
	if( result == NSAlertDefaultReturn)	// REMOVE AND DELETE IT FROM THE DATABASE
	{
		NSMutableArray *objectsToDelete = [NSMutableArray arrayWithCapacity: 0];
		
		if( matrixThumbnails)
		{
			[self filesForDatabaseMatrixSelection: objectsToDelete onlyImages: NO];
		}
		else
		{
			[self deleteEmptyFoldersForDatabaseOutlineSelection];
			[self filesForDatabaseOutlineSelection: objectsToDelete onlyImages: NO];
		}
		
		NSIndexSet *selectedRows = [databaseOutline selectedRowIndexes];
		
		if( [databaseOutline selectedRow] >= 0)
		{
			[self delObjects: objectsToDelete];
		}
		
		[[QueryController currentQueryController] refresh: self];
	}
	
	[context unlock];
	[context release];
	
	[animationCheck setState: animState];
	
	databaseLastModification = [NSDate timeIntervalSinceReferenceDate];
	
	[self refreshMatrix: self];
}

- (void)buildColumnsMenu
{
	[columnsMenu release];
	columnsMenu = [[NSMenu alloc] initWithTitle:@"columns"];
	
	
	NSArray	*columnIdentifiers = [[databaseOutline tableColumns] valueForKey:@"identifier"];
	
	for( NSTableColumn *col in [databaseOutline allColumns] )
	{
		NSMenuItem	*item = [columnsMenu insertItemWithTitle:[[col headerCell] stringValue] action:@selector(columnsMenuAction:) keyEquivalent:@"" atIndex: [columnsMenu numberOfItems]];
		[item setRepresentedObject: [col identifier]];
		
		NSInteger index = [columnIdentifiers indexOfObject: [col identifier]];
		
		if( [[col identifier] isEqualToString:@"name"] )
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
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	while( key = [enumerator nextObject] )
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
	
	[managedObjectContext unlock];
	[managedObjectContext release];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if( managedObjectContext == nil ) return nil;
	if( displayEmptyDatabase) return nil;
		
	id returnVal = nil;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	@try
	{
		if( item == nil )
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
		NSLog( [e description]);
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

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( managedObjectContext == nil) return 0;
	if( displayEmptyDatabase) return 0;
	
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
				if( isCurrentDatabaseBonjour)
				{
					return [bonjourBrowser getFileModification:[item valueForKey:@"reportURL"] index:[bonjourServicesList selectedRow]-1];
				}
				else if( [[NSFileManager defaultManager] fileExistsAtPath:[item valueForKey:@"reportURL"]])
				{
					NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:[item valueForKey:@"reportURL"]  traverseLink:YES];
					
					return [fattrs objectForKey:NSFileModificationDate];
				}
				else return nil;
			}
			else if( [[item valueForKey:@"reportSeries"] count])
			{
				NSArray *images = [[[[item valueForKey:@"reportSeries"] lastObject] valueForKey:@"images"] allObjects];
				
				return [[images lastObject] valueForKey:@"date"];
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
	if( managedObjectContext == nil) return nil;
	if( displayEmptyDatabase) return nil;
	
	[managedObjectContext lock];
	
	id returnVal = nil;
	
	@try
	{
		returnVal = [self intOutlineView: outlineView objectValueForTableColumn: tableColumn byItem: item];
	}
	
	@catch (NSException * e)
	{
		NSLog( [e description]);
	}

	[managedObjectContext unlock];
	
	return returnVal;
}

- (void) setDatabaseValue:(id) object item:(id) item forKey:(NSString*) key
{
	DatabaseIsEdited = NO;
	
	[managedObjectContext retain];
	[managedObjectContext lock];
	
	if( isCurrentDatabaseBonjour)
	{
		[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:item value:object forKey:key];
	}
	
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
	
	[managedObjectContext unlock];
	[managedObjectContext release];
	
	[self saveDatabase: currentDatabasePath];
	
	[[QueryController currentQueryController] refresh: self];
	[databaseOutline reloadData];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	[self setDatabaseValue: object item: item forKey: [tableColumn identifier]];
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[self outlineViewRefresh];
	
	if( [[[[databaseOutline sortDescriptors] objectAtIndex: 0] key] isEqualToString:@"name"] == NO )
	{
		[databaseOutline selectRow: 0 byExtendingSelection: NO];
	}
	
	[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
}

- (void)outlineView: (NSOutlineView *)outlineView willDisplayCell: (id)cell forTableColumn: (NSTableColumn *)tableColumn item: (id)item
{
	[cell setHighlighted: NO];
	
	if( [cell isKindOfClass: [ImageAndTextCell class]])
	{
		[(ImageAndTextCell*) cell setImage: nil];
		[(ImageAndTextCell*) cell setLastImage: nil];
	}
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	
	if ([[item valueForKey:@"type"] isEqualToString: @"Study"] )
	{
		if( [[tableColumn identifier] isEqualToString:@"lockedStudy"]) [cell setTransparent: NO];
		
		if( originalOutlineViewArray )
		{
			if( [originalOutlineViewArray containsObject: item]) [cell setFont: [NSFont boldSystemFontOfSize:12]];
			else [cell setFont: [NSFont systemFontOfSize:12]];
		}
		else [cell setFont: [NSFont boldSystemFontOfSize:12]];
		
		if( [[tableColumn identifier] isEqualToString:@"name"] )
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
		
		if( [[tableColumn identifier] isEqualToString:@"reportURL"])
		{
			if( (isCurrentDatabaseBonjour && [item valueForKey:@"reportURL"] != nil) || [[NSFileManager defaultManager] fileExistsAtPath: [item valueForKey:@"reportURL"]] == YES || [[item valueForKey:@"reportSeries"] count] > 0)
			{
				NSImage	*reportIcon = [NSImage imageNamed:@"Report.icns"];
				[reportIcon setSize: NSMakeSize(16, 16)];
				
				[(ImageAndTextCell*) cell setImage: reportIcon];
			}
			else [item setValue: nil forKey:@"reportURL"];
		}
		
	}
	else
	{
		if( [[tableColumn identifier] isEqualToString:@"lockedStudy"]) [cell setTransparent: YES];
		
		[cell setFont: [NSFont boldSystemFontOfSize:10]];
	}
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
			if( [[[dropDestination path] lastPathComponent] isEqualToString:@".Trash"] )
			{
				[self delItem:  nil];
			}
			else
			{
				NSMutableArray *dicomFiles2Export = [NSMutableArray array];
				NSMutableArray *filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export];
				
				r = [self exportDICOMFileInt: [dropDestination path] files: filesToExport objects: dicomFiles2Export];
			}
		}
		@catch (NSException * e)
		{
		}
		avoidRecursive = NO;
	}
	
	return r;
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)pbItems toPasteboard:(NSPasteboard*)pboard
{
	NSMutableArray *xmlArray = [NSMutableArray array];
	
	BOOL extend = NO;
	for( id pbItem in pbItems )
	{
		[olv selectRow:	[olv rowForItem: pbItem] byExtendingSelection: extend];
		extend = YES;
		[xmlArray addObject: [pbItem dictionary]];
	}
	
	[pboard declareTypes: [NSArray arrayWithObjects: albumDragType, NSFilesPromisePboardType, NSFilenamesPboardType, NSStringPboardType,  @"OsirixXMLPboardType", nil] owner:self];
	
	[pboard setPropertyList:nil forType:albumDragType];
	
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
	
	NSManagedObject	*image = nil;
	
	if( [matrixViewArray count] > 0 )
	{
		image = [matrixViewArray objectAtIndex: 0];
		if( [[image valueForKey:@"type"] isEqualToString:@"Image"]) [self findAndSelectFile: nil image: image shouldExpand :NO];
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

- (BOOL)isUsingExternalViewer: (NSManagedObject*)item
{
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"] )
	{
		// ZIP files with XML descriptor
		if([[item valueForKey:@"noFiles"] intValue] == 1 )
		{
			BOOL r = NO;
			
			[managedObjectContext lock];
			
			NSSet *imagesSet = [item valueForKeyPath: @"images.fileType"];
			NSArray *imagesArray = [imagesSet allObjects];
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"] )
			{
				NSLog(@"******** XMLDESCRIPTOR ********");
				
				NSSavePanel *savePanel = [NSSavePanel savePanel];
				[savePanel setCanSelectHiddenExtension:YES];
				[savePanel setRequiredFileType:@"zip"];
				
				imagesSet = [item valueForKeyPath: @"images.path"];
				imagesArray = [imagesSet allObjects];
				NSString *filePath = [imagesArray objectAtIndex:0];
				NSString *fileName = [filePath lastPathComponent];
				if([savePanel runModalForDirectory:nil file:fileName] == NSFileHandlingPanelOKButton)
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
				
				r = YES;
			}
			else if ([[imagesArray objectAtIndex:0] isEqualToString:@"DICOMMPEG2"])
			{
				imagesSet = [item valueForKeyPath: @"images.completePath"];
				imagesArray = [imagesSet allObjects];
				NSString *filePath = [imagesArray objectAtIndex:0];
				
				if( [[NSWorkspace sharedWorkspace] openFile: filePath withApplication:@"VLC"] == NO)
				{
					NSRunAlertPanel( NSLocalizedString( @"MPEG-2 File", nil), NSLocalizedString( @"MPEG-2 DICOM files require the VLC application. Available for free here: http://www.videolan.org/vlc/", nil), nil, nil, nil);
				}
				
				r = YES;
			}
			
			[managedObjectContext unlock];
			
			return r;
		}	
	}
	
	return NO;
}

- (void) databaseOpenStudy: (NSManagedObject*) item
{	
	if ([[item valueForKey:@"type"] isEqualToString:@"Series"])
	{
		if( [self isUsingExternalViewer: item] == NO )
		{
			// DICOM & others
			[self viewerDICOMInt :NO  dcmFile: [NSArray arrayWithObject:item] viewer:nil];
			
		}
	}
	else	// STUDY - Hanging Protocols - Windows State
	{
		// files with XML descriptor, do nothing
		
		[managedObjectContext lock];
		
		NSSet *imagesSet = [item valueForKeyPath: @"series.images.fileType"];
		NSArray *imagesArray = [[[imagesSet allObjects] objectAtIndex:0] allObjects];
		
		[managedObjectContext unlock];
		
		if([imagesArray count]==1 )
		{
			if([[imagesArray objectAtIndex:0] isEqualToString:@"XMLDESCRIPTOR"])
				return;
		}
		
		BOOL windowsStateApplied = NO;
		
		if( [item valueForKey:@"windowsState"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"])
		{
			NSData	*d = [item valueForKey:@"windowsState"];
			
			NSString	*tmp = [NSString stringWithFormat:@"/tmp/windowsState"];
			[[NSFileManager defaultManager] removeFileAtPath: tmp handler:nil];
			[d writeToFile: tmp atomically:YES];
			
			NSArray	*viewers = [NSArray arrayWithContentsOfFile: tmp];
			[[NSFileManager defaultManager] removeFileAtPath: tmp handler:nil];
			
			NSMutableArray *seriesToOpen =  [NSMutableArray array];
			NSMutableArray *viewersToLoad = [NSMutableArray array];
			
			[ViewerController closeAllWindows];
			
			for( NSDictionary *dict in viewers)
			{
				NSString	*studyUID = [dict valueForKey:@"studyInstanceUID"];
				NSString	*seriesUID = [dict valueForKey:@"seriesInstanceUID"];
				
				NSArray		*series4D = [seriesUID componentsSeparatedByString:@"\\**\\"];
				// Find the corresponding study & 4D series
				
				NSError					*error = nil;
				NSManagedObjectContext	*context = self.managedObjectContext;
				
				[context retain];
				[context lock];

				NSMutableArray *seriesForThisViewer =  nil;

				for( NSString *curSeriesUID in series4D)
				{
					NSFetchRequest			*request = [[[NSFetchRequest alloc] init] autorelease];
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
				
				[context unlock];
				[context release];
			}
			
			if( [seriesToOpen count] > 0 && [viewersToLoad count] == [seriesToOpen count])
			{
				if( waitOpeningWindow == nil) waitOpeningWindow  = [[WaitRendering alloc] init: NSLocalizedString(@"Opening...", nil)];
				[waitOpeningWindow showWindow:self];
				
				[AppController sharedAppController].checkAllWindowsAreVisibleIsOff = YES;
				
				for( int i = 0 ; i < [seriesToOpen count]; i++ )
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
				
				for( int i = 0 ; i < [viewersToLoad count]; i++ )
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
			
			if ([[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue] >= [[item valueForKey:@"imageSeries"] count])
			{
				[self viewerDICOMInt :NO  dcmFile:[self childrenArray: item] viewer:nil];
			}
			else
			{
				unsigned count = [[currentHangingProtocol objectForKey:@"Rows"] intValue] * [[currentHangingProtocol objectForKey:@"Columns"] intValue];
				if( count < 1) count = 1;
				
				NSMutableArray *children =  [NSMutableArray array];
				
				for ( int i = 0; i < count; i++ )
					[children addObject:[[self childrenArray: item] objectAtIndex:i]];
				
				[self viewerDICOMInt :NO  dcmFile:children viewer:nil];
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
	
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
	{
		NSManagedObject		*curObj = [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]];
		
		if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"] )
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

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand
{
	return [self findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: NO];
}

-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand extendingSelection: (BOOL) extendingSelection
{
	if( curImage == nil )
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
				error = nil;
				NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
				
				index = [[studiesArray  valueForKey:@"studyInstanceUID"] indexOfObject:[curFile elementForKey: @"studyID"]];
				if( index != NSNotFound )
				{
					study = [studiesArray objectAtIndex: index];
					NSArray		*seriesArray = [[study valueForKey:@"series"] allObjects];
					index = [[seriesArray valueForKey:@"seriesInstanceUID"] indexOfObject:[curFile elementForKey: @"seriesID"]];
					if( index != NSNotFound )
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
	
	NSInteger index = [outlineViewArray indexOfObject: study];
	
	if( index != NSNotFound )
	{
		if( expand || [databaseOutline isItemExpanded: study] )
		{
			[databaseOutline expandItem: study];
			
			if( [databaseOutline rowForItem: [curImage valueForKey:@"series"]] != [databaseOutline selectedRow] )
			{
				[databaseOutline selectRow:[databaseOutline rowForItem: [curImage valueForKey:@"series"]] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		else
		{
			if( [databaseOutline rowForItem: study] != [databaseOutline selectedRow] )
			{
				[databaseOutline selectRow:[databaseOutline rowForItem: study] byExtendingSelection: extendingSelection];
				[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
			}
		}
		
		// Now... try to find the series in the matrix
		if( [databaseOutline isItemExpanded: study] == NO )
		{
			NSArray	*seriesArray = [self childrenArray: study];
			
			[self outlineViewSelectionDidChange: nil];
			
			[self matrixDisplayIcons: self];	//Display the icons, if necessary
			
			NSInteger seriesPosition = [seriesArray indexOfObject: [curImage valueForKey:@"series"]];
			
			if( seriesPosition != NSNotFound )
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
	
	[self checkIncomingNow: self];
	
	@try
	{
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey: table]];
		[dbRequest setPredicate: [NSPredicate predicateWithFormat: request]];
		
		[context retain];
		[context lock];
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
		}
		[context unlock];
		[context release];
	}
	
	@catch (NSException * e)
	{
		NSLog( @"******* BrowserController findObject Exception");
		NSLog( [e description]);
	}
	
	if( element)
	{		
		if( [execute isEqualToString: @"Select"] || [execute isEqualToString: @"Open"])		// These 2 functions apply only to the first found element
		{
			NSManagedObject	*study = nil;
			
			if( [[element valueForKey: @"type"] isEqualToString: @"Image"]) study = [element valueForKeyPath: @"series.study"];
			else if( [[element valueForKey: @"type"] isEqualToString: @"Series"]) study = [element valueForKey: @"study"];
			else if( [[element valueForKey: @"type"] isEqualToString: @"Study"]) study = element;
			else NSLog( @"DB selectObject : Unknown table");
			
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
					[databaseOutline selectRow:[databaseOutline rowForItem: study] byExtendingSelection: NO];
					[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
				}
				
				if( [execute isEqualToString: @"Open"])
				{
					NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
					BOOL found = NO;
					
					if( [[element valueForKey: @"type"] isEqualToString: @"Study"])
					{
						// Is a viewer containing this study opened? -> select it
						for( ViewerController *vc in viewersList )
						{
							if(element == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"] )
							{
								[[vc window] makeKeyAndOrderFront: self];
								found = YES;
							}
						}
					}
					else if( [[element valueForKey: @"type"] isEqualToString: @"Series"])
					{
						// Is a viewer containing this series opened? -> select it
						for( ViewerController *vc in viewersList )
						{
							if(element == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series"] )
							{
								[[vc window] makeKeyAndOrderFront: self];
								found = YES;
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
						else [browserWindow viewerDICOM: self];
					}
				}
			}
			else return -1;
		}
		
		// Generate an answer containing the elements
		NSMutableString *a = [NSMutableString stringWithString: @"<value><array><data>"];
		
		for( NSManagedObject *obj in array )
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
				}
			}
			
			[c appendString: @"</struct></value>"];
			
			[a appendString: c];
		}
		
		[a appendString: @"</data></array></value>"];
		
		if( elements)
			*elements = a;
		
		if( [execute isEqualToString: @"Delete"] )
		{
			@try
			{
				[context retain];
				[context lock];
				
				for( NSManagedObject *curElement in array )
				{
					NSManagedObject	*study = nil;
					
					if( [[curElement valueForKey: @"type"] isEqualToString: @"Image"]) study = [curElement valueForKeyPath: @"series.study"];
					else if( [[curElement valueForKey: @"type"] isEqualToString: @"Series"]) study = [curElement valueForKey: @"study"];
					else if( [[curElement valueForKey: @"type"] isEqualToString: @"Study"]) study = curElement;
					else NSLog( @"DB selectObject : Unknown table");
					
					if( study)
						[context deleteObject: study];
				}
				
				[self saveDatabase: currentDatabasePath];
				
				[context unlock];
				[context release];
			}
			
			@catch (NSException * e)
			{
				NSLog( @"******* BrowserController findObject Exception - Delete");
				NSLog( [e description]);
			}
		}
		
		return 0;
	}
	
	return -1;
}

-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	BOOL					applyToAllViewers = [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"];
	BOOL					copyPatientsSettings = [[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDisplayImagesOfSamePatient"];
	
	[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"onlyDisplayImagesOfSamePatient"];
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		applyToAllViewers = !applyToAllViewers;
	
	if(  applyToAllViewers)
	{
		// If multiple viewer are opened, apply it to the entire list
		for( NSWindow *win in winList )
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
	
	if( index != NSNotFound )
	{
		BOOL				found = NO;
		NSManagedObject		*nextStudy;
		do
		{
			index += direction;
			if( index >= 0 && index < [outlineViewArray count] )
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriX Did Load New Object" object:study userInfo:nil];
	[viewersList release];
	
	[[NSUserDefaults standardUserDefaults] setBool: copyPatientsSettings forKey: @"onlyDisplayImagesOfSamePatient"];
}

-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	NSManagedObjectModel	*model = self.managedObjectModel;
	NSManagedObjectContext	*context = self.managedObjectContext;
	NSArray					*winList = [NSApp windows];
	NSMutableArray			*viewersList = [[NSMutableArray alloc] initWithCapacity:0];
	BOOL					applyToAllViewers = [[NSUserDefaults standardUserDefaults] boolForKey:@"nextSeriesToAllViewers"];
	
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
		applyToAllViewers = !applyToAllViewers;
	
	if( [viewer FullScreenON]) [viewersList addObject: viewer];
	else
	{
		// If multiple viewer are opened, apply it to the entire list
		if( applyToAllViewers)
		{
			for( NSWindow *win in winList )
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
	
	NSError	*error = nil;
	NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
	
	if ([studiesArray count] > 0 && [studiesArray indexOfObject:study] != NSNotFound )
	{
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		
		studiesArray = [studiesArray sortedArrayUsingDescriptors: sortDescriptors];
		
		NSArray	*seriesArray = [NSArray array];
		
		for(NSManagedObject	*curStudy in studiesArray )
			seriesArray = [seriesArray arrayByAddingObjectsFromArray: [self childrenArray: curStudy]];
		
		NSInteger index = [seriesArray indexOfObject: currentSeries];
		
		if( index != NSNotFound )
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
					
					for( ViewerController *vc in viewersList )
					{
						if( index >= 0 && index < [seriesArray count] )
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
		
	[context unlock];
	[context release];
	
	[viewersList release];
	
	if( delayedTileWindows)
	{
		delayedTileWindows = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:appController selector:@selector(tileWindows:) object:nil];
		[appController tileWindows: self];
	}
}

- (ViewerController*) loadSeries:(NSManagedObject *) series :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages
{
	return [self openViewerFromImages :[NSArray arrayWithObject: [self childrenArray: series]] movie: NO viewer :viewer keyImagesOnly:keyImages];
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
	
	for( NSInteger x = 0; x < rowIndex.count; x++ )
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

- (IBAction) copy: (id)sender
{
    NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	
	NSString *string = [self exportDBListOnlySelected: YES];
	
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

- (void) previewSliderAction:(id) sender
{
	BOOL	animate = NO;
	long	noOfImages = 0;
	
    NSButtonCell    *cell = [oMatrix selectedCell];
    if( cell)
	{
		if( [cell isEnabled] == YES)
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
				
				DCMPix*dcmPix = nil;
				dcmPix = [[DCMPix alloc] myinit: [image valueForKey:@"completePath"] :[animationSlider intValue] :noOfImages :nil :[animationSlider intValue] :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:image];
				
				if( dcmPix )
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
					
				if( [images count] )
				{ 
					if( [images count] > 1) noOfImages = [images count];
					else noOfImages = [[[images objectAtIndex:0] valueForKey:@"numberOfFrames"] intValue];
					
					if( [images count] > 1 || noOfImages == 1 )
					{
						animate = YES;
						
						if( [animationSlider intValue] >= [images count]) return;
						
						NSManagedObject *imageObj = [images objectAtIndex: [animationSlider intValue]];
						
						if( [[[imageView curDCM] sourceFile] isEqualToString: [[images objectAtIndex: [animationSlider intValue]] valueForKey:@"completePath"]] == NO || [[imageObj valueForKey: @"frameID"] intValue] != [[[imageView imageObj] valueForKey: @"frameID"] intValue])
						{
							DCMPix *dcmPix = nil;
							dcmPix = [[DCMPix alloc] myinit: [imageObj valueForKey:@"completePath"] :[animationSlider intValue] :[images count] :nil :[[imageObj valueForKey: @"frameID"] intValue] :[[imageObj valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: imageObj];
							
							if( dcmPix )
							{
								float   wl, ww;
								
								[imageView getWLWW:&wl :&ww];
								
								DCMPix *previousDcmPix = [[previewPix objectAtIndex: [cell tag]] retain];	// To allow the cached system in DCMPix to avoid reloading
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
								
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
							DCMPix*     dcmPix = [[DCMPix alloc] myinit: [[images objectAtIndex: 0] valueForKey:@"completePath"] :[animationSlider intValue] :noOfImages :nil :[animationSlider intValue] :[[[images objectAtIndex: 0] valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:[images objectAtIndex: 0]];
							
							if( dcmPix )
							{
								float   wl, ww;
								
								[imageView getWLWW:&wl :&ww];
								
								DCMPix *previousDcmPix = [[previewPix objectAtIndex: [cell tag]] retain];	// To allow the cached system in DCMPix to avoid reloading
								
								[previewPix replaceObjectAtIndex:[cell tag] withObject:(id) dcmPix];
								[dcmPix release];
								
								if( withReset) [imageView setIndexWithReset:[cell tag] :YES];
								else [imageView setIndex:[cell tag]];
								
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
	[self setDockIcon];
	
    // Wait loading all images !!!
	if( managedObjectContext == nil) return;
	if( bonjourDownloading) return;
	if( animationCheck.state == NSOffState ) return;
	
    if( self.window.isKeyWindow == NO ) return;
    if( animationSlider.isEnabled == NO ) return;
	
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
		reverseScrollWheel=-1.0;
	else
		reverseScrollWheel=1.0;
	float change = reverseScrollWheel * [theEvent deltaY];
	
	int	pos = [animationSlider intValue];
	
	if( change > 0 )
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

- (IBAction) matrixPressed: (id)sender
{
    id          theCell = [sender selectedCell];
    int         index;
    
	[self.window makeFirstResponder: oMatrix];
	
	if( [theCell tag] >= 0 )
	{
		NSManagedObject         *dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
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
	
    if( [theCell tag] >= 0 )
	{
		NSManagedObject         *dcmFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		if( [[dcmFile valueForKey:@"type"] isEqualToString: @"Study"] == NO )
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
    
    if( [theCell tag] >= 0 )
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
	
	for( long i=0; i < row*COLUMN; i++ )
	{
		NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
		cell.tag = i;
		[cell setTransparent: YES];
		[cell setEnabled: NO];
		cell.title = NSLocalizedString(@"loading...", nil);
		cell.image = nil;
		cell.bezelStyle = NSShadowlessSquareBezelStyle;
	}
	
	for( long i=0; i<noOfImages; i++ )
	{
		[[oMatrix cellWithTag: i] setTransparent:NO];
	}
	
	[oMatrix sizeToCells];
	
	[imageView setDCM:nil :nil :nil :0 :0 :YES];
	
	[self matrixDisplayIcons: self];
}

- (void)matrixNewIcon:(long) index: (NSManagedObject*)curFile
{	
//	if( shouldDie == NO )
	{
		long		i = index;
		
		if( curFile == nil )
		{
			[oMatrix setNeedsDisplay:YES];
			return;
		}
		
		if( i >= [previewPix count]) return;
		if( i >= [previewPixThumbnails count]) return;
		
		NSImage		*img = nil;
		
		img = [previewPixThumbnails objectAtIndex: i];
		if( img == nil) NSLog( @"Error: [previewPixThumbnails objectAtIndex: i] == nil");
		
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
			
			if ( img || [modality  hasPrefix: @"RT"] )
			{
				NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
				[cell setTransparent:NO];
				[cell setEnabled:YES];
				
				[cell setFont:[NSFont systemFontOfSize:9]];
				[cell setImagePosition: NSImageBelow];
				[cell setAction: @selector(matrixPressed:)];
				
				if ( [modality isEqualToString: @"RTSTRUCT"] )
				{
					[[contextualRT itemAtIndex: 0] setAction:@selector(createROIsFromRTSTRUCT:)];
					[cell setMenu: contextualRT];
				}
				else
				{
					[cell setMenu: contextual];
				}
				
				NSString	*name = [curFile valueForKey:@"name"];
				
				if( name.length > 15) name = [name substringToIndex: 15];
				
				if ( [modality hasPrefix: @"RT"] )
				{
					[cell setTitle: [NSString stringWithFormat: @"%@\r%@", name, modality]];
				}
				else if ([seriesSOPClassUID isEqualToString: [DCMAbstractSyntaxUID pdfStorageClassUID]])
				{
					[cell setTitle: @"PDF"];
					img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"pdf"]];
				}
				else if ([fileType isEqualToString: @"DICOMMPEG2"])
				{
					long count = [[curFile valueForKey:@"noFiles"] intValue];
					
					if( count == 1)
					{
						long frames = [[[[curFile valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
						
						if( frames > 1) [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"MPEG-2 Series\r%@\r%d Frames", nil), name, frames]];
						else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"MPEG-2 Series\r%@\r%d Image", nil), name, count]];
					}
					
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
					else [cell setTitle:[NSString stringWithFormat: NSLocalizedString(@"%@\r%d Images", nil), name, count]];
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
						
						[imageView setDCM:previewPix :[self imagesArray: aFile preferredObject: oAny] :nil :[[oMatrix selectedCell] tag] :'i' :YES];
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
		}
		
		[managedObjectContext unlock];
	}
	[oMatrix setNeedsDisplay:YES];
}

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

- (void)matrixDisplayIcons:(id) sender
{
	if( bonjourDownloading) return;
	if( managedObjectContext == nil) return;
	
	@try
	{
		if( [previewPix count] )
		{
			if( loadPreviewIndex < [previewPix count] )
			{
				long i;
				for( i = loadPreviewIndex; i < [previewPix count]; i++ )
				{
					NSButtonCell *cell = [oMatrix cellAtRow:i/COLUMN column:i%COLUMN];
					
					if( [cell isEnabled] == NO )
					{
						if( i < [previewPix count] )
						{
							if( [previewPix objectAtIndex: i] != nil )
							{
								if( i < [matrixViewArray count] )
								{
									[self matrixNewIcon:i :[matrixViewArray objectAtIndex: i]];
								}
							}
						}
					}
				}
				
				if( [oMatrix selectedCell] == 0 )
				{
					if( [matrixViewArray count] > 0 )
						[oMatrix selectCellWithTag: 0];
				}
				
				if( loadPreviewIndex == 0)
					[self initAnimationSlider];
				
				loadPreviewIndex = i;
			}
		}
		else [self initAnimationSlider];
	}
	
	@catch( NSException *ne )
	{
		NSLog(@"matrixDisplayIcons exception: %@", [ne description]);
	}
}

+ (NSData*)produceJPEGThumbnail: (NSImage*)image
{
	NSData *imageData = [image  TIFFRepresentation];
	
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	
	//	NSLog( @"bits per pixel: %d", [imageRep bitsPerPixel]);
	
	NSString	*uniqueFileName = [NSString stringWithFormat:@"/tmp/osirix_thumbnail_%lf.jpg", [NSDate timeIntervalSinceReferenceDate]];
	
	NSData	*result = nil;
	
	
	if( [imageRep bitsPerPixel] == 8)
	{
		[PapyrusLock lock];
		compressJPEG ( 30, (char*) [uniqueFileName UTF8String], [imageRep bitmapData], [imageRep pixelsHigh], [imageRep pixelsWide], 1);
		result = [NSData dataWithContentsOfFile:uniqueFileName];
		[[NSFileManager defaultManager] removeFileAtPath:uniqueFileName  handler:nil];
		[PapyrusLock unlock];
	}
	else if( [imageRep bitsPerPixel] == 8)
	{
		[PapyrusLock lock];
		compressJPEG ( 30, (char*) [uniqueFileName UTF8String], [imageRep bitmapData], [imageRep pixelsHigh], [imageRep pixelsWide], 0);
		result = [NSData dataWithContentsOfFile: uniqueFileName];
		[[NSFileManager defaultManager] removeFileAtPath:uniqueFileName  handler:nil];
		[PapyrusLock unlock];
	}
	else
	{
		NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.3] forKey:NSImageCompressionFactor];
		
		result = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		//NSJPEGFileType	NSJPEG2000FileType <- MAJOR memory leak with NSJPEG2000FileType when reading !!! Kakadu library...
	}
	
	//	NSLog( @"thumbnail size: %d", [result length]);
	
	return result;
}

- (void) buildThumbnail:(NSManagedObject*) series
{
	if( [series valueForKey:@"thumbnail"] == nil)
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		NSString *recoveryPath = [[self documentsDirectory] stringByAppendingPathComponent:@"/ThumbnailPath"];
		
		NSArray	*files = [self imagesArray: series];
		if( [files count] > 0)
		{
			NSManagedObject *image = [files objectAtIndex: [files count]/2];
			
			if( [NSData dataWithContentsOfFile: [image valueForKey:@"completePath"]])	// This means the file is readable...
			{
				int frame = 0;
				
				if( [files count] == 1 && [[image valueForKey:@"numberOfFrames"] intValue] > 1) frame = [[image valueForKey:@"numberOfFrames"] intValue]/2;
				
				if( [image valueForKey:@"frameID"]) frame = [[image valueForKey:@"frameID"] intValue];
				
				NSLog( @"Build thumbnail for:");
				NSLog( [image valueForKey:@"completePath"]);
				
				[[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
				[[[[[series valueForKey:@"study"] objectID] URIRepresentation] absoluteString] writeToFile: recoveryPath atomically: YES encoding: NSASCIIStringEncoding  error: nil];
				
				DCMPix	*dcmPix  = [[DCMPix alloc] myinit:[image valueForKey:@"completePath"] :0 :1 :nil :frame :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:image];
				
				if( dcmPix)
				{
					NSImage *thumbnail = [dcmPix generateThumbnailImageWithWW:0 WL:0];
					NSData *data = [BrowserController produceJPEGThumbnail: thumbnail];
					
					if( thumbnail && data) [series setValue: data forKey:@"thumbnail"];
					[dcmPix release];
				}
				
				[[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
			}
		}
		
		[pool release];
	}
}

- (IBAction) buildAllThumbnails:(id) sender
{
	if( [DCMPix isRunOsiriXInProtectedModeActivated]) return;
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"StoreThumbnailsInDB"] == NO) return;
	
	NSManagedObjectContext	*context = self.managedObjectContext;
	NSManagedObjectModel	*model = self.managedObjectModel;

	NSString *recoveryPath = [[self documentsDirectory] stringByAppendingPathComponent:@"/ThumbnailPath"];
	if( [[NSFileManager defaultManager] fileExistsAtPath: recoveryPath])
	{
		displayEmptyDatabase = YES;
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
		}
		
		if( studyObject)
		{
			int r = NSRunAlertPanel( NSLocalizedString(@"Corrupted files", nil), [NSString stringWithFormat:NSLocalizedString(@"A corrupted study crashed OsiriX:\r\r%@ / %@\r\rThis file will be deleted.\r\rYou can run OsiriX in Protected Mode (shift + option keys at startup) if you have more crashes.\r\rShould I delete this corrupted study? (Highly recommended)", nil), [studyObject valueForKey:@"name"], [studyObject valueForKey:@"studyName"], nil], NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil);
			if( r == NSAlertDefaultReturn)
			{
				[context lock];
				[context retain];
				
				@try
				{
					[context deleteObject: studyObject];
					[self saveDatabase: currentDatabasePath];
				}
					
				@catch( NSException *ne)
				{
					NSLog(@"buildAllThumbnails exception: %@", [ne description]);
				}
				
				[context unlock];
				[context release];
				
				[self outlineViewRefresh];
				[self refreshMatrix: self];
			}
		}
		
		displayEmptyDatabase = NO;
	}
	
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
				NSError	*error = nil;
				NSArray *seriesArray = [context executeFetchRequest:dbRequest error:&error];
				
				int maxSeries = [seriesArray count];
				
				if( maxSeries > 60 ) maxSeries = 60;	// We will continue next time...
				
				for( int i = 0; i < maxSeries; i++ )
				{
					NSManagedObject *series = [seriesArray objectAtIndex: i];
					
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

- (IBAction) resetWindowsState:(id)sender
{
	NSInteger				x, row;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	
	NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
	
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
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Series"])
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
	
	[self saveDatabase: currentDatabasePath];
	
	[context unlock];
	[context release];
}

- (IBAction)rebuildThumbnails: (id)sender
{
	NSInteger				row;
	NSManagedObjectContext	*context = self.managedObjectContext;
	
	[context retain];
	[context lock];
	
	NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
	
	if( [databaseOutline selectedRow] >= 0 )
	{
		for( NSInteger x = 0; x < selectedRows.count; x++ )
		{
			if( x == 0) row = selectedRows.firstIndex;
			else row = [selectedRows indexGreaterThanIndex: row];
			
			NSManagedObject	*object = [databaseOutline itemAtRow: row];
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Study"] )
			{
				[[self childrenArray: object] setValue:nil forKey:@"thumbnail"];
			}
			
			if( [[object valueForKey:@"type"] isEqualToString: @"Series"] )
			{
				[object setValue:nil forKey:@"thumbnail"];
			}
		}
	}
	
	[self saveDatabase: currentDatabasePath];
	
	[context unlock];
	[context release];
	
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
			NSImage		*thumbnail = nil;
			
			thumbnail = [ipreviewPixThumbnails objectAtIndex: i];
			
			int frame = 0;
			if( [[[files objectAtIndex: i] valueForKey:@"numberOfFrames"] intValue] > 1) frame = [[[files objectAtIndex: i] valueForKey:@"numberOfFrames"] intValue]/2;
			
			if( [[files objectAtIndex: i] valueForKey:@"frameID"]) frame = [[[files objectAtIndex: i] valueForKey:@"frameID"] intValue];
			
			DCMPix *dcmPix  = [[DCMPix alloc] myinit:[filesPaths objectAtIndex:i] :position :subGroupCount :nil :frame :0 isBonjour:isCurrentDatabaseBonjour imageObj: [files objectAtIndex: i]];
			
			if( dcmPix)
			{
				if( thumbnail == notFoundImage)
				{
					[dcmPix revert];	// <- Kill the raw data
					
					thumbnail = [dcmPix generateThumbnailImageWithWW:0 WL:0];
					if( thumbnail == nil) thumbnail = notFoundImage;
					
					[ipreviewPixThumbnails replaceObjectAtIndex: i withObject: thumbnail];
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
		NSLog(@"matrixLoadIcons exception: %@", ne.description );
	}
	
    [pool release];
}

- (CGFloat)splitView: (NSSplitView *)sender constrainSplitPosition: (CGFloat)proposedPosition ofSubviewAt: (NSInteger)offset
{
	if ([sender isEqual:sourcesSplitView] )
	{
		return proposedPosition;
	}
	
    if( [sender isVertical] == YES )
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
				NSLog( NSStringFromRect( [[self window] frame]));
				NSLog( NSStringFromRect( visibleScreenRect[ i]));
				
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
			[NSObject cancelPreviousPerformRequestsWithTarget:appController selector:@selector(tileWindows:) object:nil];
		delayedTileWindows = YES;
		[appController performSelector: @selector(tileWindows:) withObject:nil afterDelay: 0.1];
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

- (void)splitViewDidResizeSubviews: (NSNotification *)aNotification
{
    NSSize size = oMatrix.cellSize;
    NSSize space = oMatrix.intercellSpacing;
    NSRect frame = oMatrix.enclosingScrollView.frame;
    
    int newColumn = frame.size.width / (size.width + space.width*2);
    if( newColumn <= 0 ) newColumn = 1;
	
    if( newColumn != COLUMN )
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
        
		
        for( int i = [previewPix count]; i<row*COLUMN; i++ )
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
	if ([sender isEqual:sourcesSplitView] )
	{
		// minimum size of the top view (db, albums)
		return 200;
	}
	else if ([sender isEqual: splitViewHorz] )
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
	if ([sender isEqual:splitViewVert] )
	{
		return [sender bounds].size.width-200;
	}
	else if ([sender isEqual:sourcesSplitView] )
	{
		// maximum size of the top view (db, album) = opposite of the minimum size of the bottom view (bonjour)
		return [sender bounds].size.height-200;
	}
	else if ([sender isEqual: splitViewHorz] )
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
	
	if( cells != nil && aFile != nil ) 
	{
		
		for( NSCell *cell in cells )
		{
			if( [cell isEnabled] == YES )
			{
				NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [cell tag]];
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"] )
				{
					return curObj;
				}
				
				if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"] )
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
		if( cells != nil && aFile != nil )
		{
			for( NSCell *cell in cells )
			{
				if( [cell isEnabled] == YES )
				{
					NSManagedObject	*curObj = [matrixViewArray objectAtIndex: [cell tag]];
					
					if( [[curObj valueForKey:@"type"] isEqualToString:@"Image"])
					{
						[correspondingManagedObjects addObject: curObj];
					}
					
					if( [[curObj valueForKey:@"type"] isEqualToString:@"Series"] )
					{
						NSArray *imagesArray = [self imagesArray: curObj onlyImages: onlyImages];
						
						[correspondingManagedObjects addObjectsFromArray: imagesArray];
					}
				}
			}
		}
		
		[correspondingManagedObjects removeDuplicatedObjects];
		
		if( isCurrentDatabaseBonjour )
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
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	NSError *error = nil;
	NSArray *albumArray = [self.managedObjectContext executeFetchRequest:dbRequest error:&error];
	
	if( [albumArray count])
	{
		NSManagedObject *album;
		for( album in albumArray )
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
	
	[self.managedObjectContext unlock];
}

- (void) addAlbumsFile: (NSString*) file
{
	NSArray *albums = [NSArray arrayWithContentsOfFile: file];
		
		[self.managedObjectContext lock];
	
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
					[a setValue: [NSNumber numberWithBool: NO]
 forKey:@"smartAlbum"];
					
				[a setValue: [dict valueForKey: @"predicateString"] forKey:@"predicateString"];
			}
		}
		
		needDBRefresh = YES;
		[albumTable reloadData];
		
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

- (void)createContextualMenu
{
	NSMenuItem		*item;
	
	NSMenu *albumContextual	= [[[NSMenu alloc] initWithTitle:NSLocalizedString(@"Albums", nil)] autorelease];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Save Albums", nil)  action:@selector( saveAlbums:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[albumContextual addItem:item];
	
	[albumContextual addItem: [NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add Albums", nil)  action:@selector( addAlbums:) keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[albumContextual addItem:item];
	
	[albumTable setMenu: albumContextual];
	
	// ****************
	
	if ( contextual == nil ) contextual	= [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tools", nil)];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images", nil)  action:@selector(viewerDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images in 4D", nil)  action:@selector(MovieViewerDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Key Images", nil)  action:@selector(viewerDICOMKeyImages:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open ROIs Images", nil)  action:@selector(viewerDICOMROIsImages:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open ROIs and Key Images", nil)  action:@selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Merged Selection", nil)  action:@selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal In Finder", nil)  action:@selector(revealInFinder:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[contextual addItem: [NSMenuItem separatorItem]];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to DICOM Network Node", nil)  action:@selector(export2PACS:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to Quicktime", nil)  action:@selector(exportQuicktime:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to JPEG", nil)  action:@selector(exportJPEG:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to TIFF", nil)  action:@selector(exportTIFF:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to DICOM File(s)", nil)  action:@selector(exportDICOMFile:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to iDisk", nil)  action:@selector(sendiDisk:) keyEquivalent:@""];
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
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Merge Selected Series", nil)  action:@selector(mergeSeries:) keyEquivalent:@""];
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
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Burn", nil)  action:@selector(burnDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Anonymize", nil)  action:@selector(anonymizeDICOM:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Rebuild Selected Thumbnails", nil)  action:@selector(rebuildThumbnails:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy linked files to Database folder", nil)  action:@selector(copyToDBFolder:) keyEquivalent:@""];
	[contextual addItem:item];
	[item release];
	
	[oMatrix setMenu: contextual];
	
	// Create alternate contextual menu for RT objects
	
	if ( contextualRT == nil ) contextualRT	= [contextual copy];
	
	item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Create ROIs from RTSTRUCT", nil)  action:@selector(createROIsFromRTSTRUCT:) keyEquivalent:@""];
	[contextualRT insertItem: item atIndex: 0];
	[item release];
	
	[contextualRT insertItem: [NSMenuItem separatorItem] atIndex: 1];
	
	// Now remove non-applicable items - usually related to images (most RT objects don't have embedded images)
	
	NSInteger indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open images in 4D", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open Key Images", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs Images", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Open ROIs and Key Images", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to Quicktime", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to JPEG", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
	indx = [contextualRT indexOfItemWithTitle: NSLocalizedString( @"Export to TIFF", nil)];
	if ( indx >= 0 ) [contextualRT removeItemAtIndex: indx];
}

-(void) annotMenu:(id) sender
{
	[imageView annotMenu: sender];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Albums functions

- (IBAction)addSmartAlbum: (id)sender
{
	SmartWindowController *smartWindowController = [[SmartWindowController alloc] init];
	NSWindow *sheet = [smartWindowController window];
	
    [NSApp beginSheet: sheet
	   modalForWindow: self.window
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
    [NSApp runModalForWindow:sheet];
	
    // Sheet is up here.
    [NSApp endSheet: sheet];
    [sheet orderOut: self];
	NSMutableArray *criteria = [smartWindowController criteria];
	if ([criteria count] > 0 )
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
		NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
		
		name = [smartWindowController albumTitle];
		while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound)
		{
			name = [NSString stringWithFormat:@"%@ #%d", [smartWindowController albumTitle], i++];
		}
		
		NSManagedObject	*album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
		[album setValue:name forKey:@"name"];
		[album setValue:[NSNumber numberWithBool:YES] forKey:@"smartAlbum"];
		
		NSString *format = [NSString string];
		
		BOOL first = YES;
		for( NSString *search in criteria )
		{
			if ( first ) first = NO;
			else format = [format stringByAppendingFormat: NSLocalizedString(@" AND ", nil)];
			
			format = [format stringByAppendingFormat: @"(%@)", search];
		}
		
		NSLog( format);
		[album setValue:format forKey:@"predicateString"];
		
		[self saveDatabase: currentDatabasePath];
		
		needDBRefresh = YES;
		[albumTable reloadData];
		
		[albumTable selectRow:[self.albumArray indexOfObject: album] byExtendingSelection: NO];
		
		[context unlock];
		[context release];
		
		[self outlineViewRefresh];
	}
	
	[smartWindowController release];
}

- (IBAction) albumButtons: (id)sender
{
	switch( [sender selectedSegment] )
	{
		case 0:
		{ // Add album
			
			[NSApp beginSheet: newAlbum
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow:newAlbum];
			
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
				
				[context retain];
				[context lock];
				NSError *error = nil;
				NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
				
				name = [newAlbumName stringValue];
				while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound )
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
			
		case 1:
		{ // Add smart album
			
			[self addSmartAlbum: self];
		}
		break;
			
		case 2:	// Remove
			if( albumTable.selectedRow > 0)
			{
				if( NSRunInformationalAlertPanel(	NSLocalizedString(@"Delete an album", nil),
												 NSLocalizedString(@"Are you sure you want to delete this album?", nil),
												 NSLocalizedString(@"OK",nil),
												 NSLocalizedString(@"Cancel",nil),
												 nil) == NSAlertDefaultReturn)
				{
					NSManagedObjectContext	*context = self.managedObjectContext;
					
					[context retain];
					[context lock];
					
					if( albumTable.selectedRow > 0)	// We cannot delete the first item !
					{
						[context deleteObject: [self.albumArray  objectAtIndex: albumTable.selectedRow]];
					}
					
					[albumNoOfStudiesCache removeAllObjects];

					[self saveDatabase: currentDatabasePath];
					
					[albumTable reloadData];
					
					[context unlock];
					[context release];
					
					[self outlineViewRefresh];
				}
			}
		break;
	}
}

static BOOL needToRezoom;

- (void)drawerDidClose: (NSNotification *)notification
{
	if( needToRezoom )
	{
		[self.window zoom:self];
	}
}

- (void)drawerWillClose: (NSNotification *)notification
{
	if( self.window.isZoomed )
	{
		needToRezoom = YES;
	}
	else needToRezoom = NO;
}

- (void)drawerDidOpen: (NSNotification *)notification
{
	if( needToRezoom )
	{
		[self.window zoom:self];
	}
}

- (void)drawerWillOpen: (NSNotification *)notification
{
		needToRezoom = self.window.isZoomed;
}

- (IBAction)smartAlbumHelpButton: (id)sender
{
	if( [sender tag] == 0 )
	{
		[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"OsiriXTables" ofType:@"pdf"]];
	}
	
	if( [sender tag] == 1){
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developer.apple.com/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html#//apple_ref/doc/uid/TP40001795"]];
	}
}

- (IBAction)albumTableDoublePressed: (id)sender
{
	if( albumTable.selectedRow > 0)
	{
		NSManagedObject	*album = [self.albumArray objectAtIndex: albumTable.selectedRow];
		
		if( [[album valueForKey:@"smartAlbum"] boolValue] == YES )
		{
			[editSmartAlbumName setStringValue: [album valueForKey:@"name"]];
			[editSmartAlbumQuery setStringValue: [album valueForKey:@"predicateString"]];
			
//			NSArray *templates = [NSPredicateEditorRowTemplate templatesWithAttributeKeyPaths: [NSArray arrayWithObjects: @"comment", @"date", @"name",  nil] inEntityDescription: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
//			
//			[editSmartAlbumPredicate setRowTemplates: templates];	//[self smartAlbumPredicateString: [album valueForKey:@"predicateString"]]];
//			
//			if ([editSmartAlbumPredicate numberOfRows] == 0)
//				[editSmartAlbumPredicate addRow:self];
//			
//			[editSmartAlbumPredicate setObjectValue: [self smartAlbumPredicateString: [album valueForKey:@"predicateString"]]];
			
			[NSApp beginSheet: editSmartAlbum
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow:editSmartAlbum];
			
			[NSApp endSheet: editSmartAlbum];
			[editSmartAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse )
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
				NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
				
				if( [[editSmartAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO )	{
					name = [editSmartAlbumName stringValue];
					while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound )
					{
						name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
					}
					
					[album setValue:name forKey:@"name"];
				}
				
				[album setValue:[editSmartAlbumQuery stringValue] forKey:@"predicateString"];
				
				[self saveDatabase: currentDatabasePath];
				
				[albumTable selectRow: [self.albumArray indexOfObject:album] byExtendingSelection: NO];
				
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
			   modalForWindow: self.window
				modalDelegate: nil
			   didEndSelector: nil
				  contextInfo: nil];
			
			int result = [NSApp runModalForWindow:newAlbum];
			
			[NSApp endSheet: newAlbum];
			[newAlbum orderOut: self];
			
			if( result == NSRunStoppedResponse )	{
				long				i = 2;
				
				if( [[newAlbumName stringValue] isEqualToString: [album valueForKey:@"name"]] == NO )
				{
					NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Album"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
					NSManagedObjectContext *context = self.managedObjectContext;
					
					[context retain];
					[context lock];
					NSError *error = nil;
					NSArray *albumsArray = [context executeFetchRequest:dbRequest error:&error];
					
					NSString *name = newAlbumName.stringValue;
					while( [[albumsArray valueForKey:@"name"] indexOfObject: name] != NSNotFound )
					{
						name = [NSString stringWithFormat:@"%@ #%d", [newAlbumName stringValue], i++];
					}
					
					[album setValue:name forKey:@"name"];
					
					[self saveDatabase: currentDatabasePath];
					
					[albumTable selectRow: [self.albumArray indexOfObject:album] byExtendingSelection: NO];
					
					[albumTable reloadData];
					
					[context unlock];
					[context release];
				}
			}
		}
	}
}
- (NSArray*) albumArray
{
	NSManagedObjectContext	*context = self.managedObjectContext;
	NSManagedObjectModel	*model = self.managedObjectModel;
	
	[context retain];
	[context lock];
	
	NSArray *albumsArray = nil;
	NSArray *result = nil;
	
	@try
	{
		//Find all albums
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Album"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		NSError *error = nil;
		albumsArray = [context executeFetchRequest:dbRequest error:&error];
		
		NSSortDescriptor * sort = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
		albumsArray = [albumsArray sortedArrayUsingDescriptors:  [NSArray arrayWithObjects: sort, nil]];
		result = [NSArray arrayWithObject: [NSDictionary dictionaryWithObject: @"Database" forKey:@"name"]];
	}
	
	@catch (NSException *e)
	{
		NSLog( @"albumArray exception : %@", e);
	}
	
	[context unlock];
	[context release];
	
	return [result arrayByAddingObjectsFromArray: albumsArray];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
#pragma mark-
#pragma mark Albums/send & ReceiveLog/Bonjour TableView functions

//NSTableView delegate and datasource
- (NSInteger)numberOfRowsInTableView: (NSTableView *)aTableView
{	
	if ([aTableView isEqual:albumTable] )
	{
		if( displayEmptyDatabase) return 0;
		return [self.albumArray count];
	}
	else if ([aTableView isEqual:bonjourServicesList] )
	{
		if (bonjourBrowser!=nil )
		{
			return [[bonjourBrowser services] count]+1;
		}
		else
		{
			return 1;
		}
	}
	return 0;
}

- (id)tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex
{
	if ([aTableView isEqual:albumTable] )
	{
		if( displayEmptyDatabase) return nil;
		
		if([[aTableColumn identifier] isEqualToString:@"no"] )
		{
			int albumNo = [self.albumArray count];
			
			if( albumNoOfStudiesCache == nil || [albumNoOfStudiesCache count] != albumNo || [[albumNoOfStudiesCache objectAtIndex: rowIndex] isEqualToString:@""] == YES)
			{
				if( albumNoOfStudiesCache == nil || [albumNoOfStudiesCache count] != albumNo )
				{
					[albumNoOfStudiesCache release];
					
					albumNoOfStudiesCache = [[NSMutableArray alloc] initWithCapacity: albumNo];
					
					for( int i = 0; i < albumNo; i++) [albumNoOfStudiesCache addObject:@""];
				}
				
				if( rowIndex == 0 )
				{
					// Find all studies
					NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
					[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
					[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
					NSManagedObjectContext *context = self.managedObjectContext;
					
					[context retain];
					[context lock];
					NSError *error = nil;
					NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
					
					[context unlock];
					[context release];
					
					if( [albumNoOfStudiesCache count] > rowIndex)
						[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]]];
				}
				else
				{
					NSManagedObject	*object = [self.albumArray  objectAtIndex: rowIndex];
					
					if( [[object valueForKey:@"smartAlbum"] boolValue] == YES )
					{
						NSManagedObjectContext *context = self.managedObjectContext;
						
						[context retain];
						[context lock];
						
						@try
						{
							// Find all studies
							NSError			*error = nil;
							NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
							[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
							[dbRequest setPredicate: [self smartAlbumPredicate: object]];
							
							error = nil;
							NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
							
							if( [albumNoOfStudiesCache count] > rowIndex)
								[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[studiesArray count]]]]];
						}
						
						@catch( NSException *ne)
						{
							NSLog(@"TableView exception: %@", ne.description );
							if( [albumNoOfStudiesCache count] > rowIndex)
								[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject:@"err"];
						}
						
						[context unlock];
						[context release];
					}
					else
					{
						if( [albumNoOfStudiesCache count] > rowIndex)
							[albumNoOfStudiesCache replaceObjectAtIndex:rowIndex withObject: [NSString stringWithFormat:@"%@", [numFmt stringForObjectValue:[NSNumber numberWithInt:[[object valueForKey:@"studies"] count]]]]];
					}
				}
			}
			
			return [albumNoOfStudiesCache objectAtIndex: rowIndex];
		}
		else
		{
			NSManagedObject	*object = [self.albumArray  objectAtIndex: rowIndex];
			return [object valueForKey:@"name"];
		}
	}
	else if ([aTableView isEqual:bonjourServicesList] )
	{
		if([[aTableColumn identifier] isEqualToString:@"Source"] )
		{
			if (bonjourBrowser!=nil)
			{
				NSDictionary *dict = nil;
				if( rowIndex > 0) dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
				
				if( rowIndex == 0) return NSLocalizedString(@"Local Default Database", nil);
				else if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"]) return [[dict valueForKey:@"service"] name];
				else return [dict valueForKey:@"Description"];
			}
			else
			{
				return NSLocalizedString(@"Local Default Database", nil);
			}
		}
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if( [aCell isKindOfClass: [ImageAndTextCell class]] )
	{
		[(ImageAndTextCell*) aCell setLastImage: nil];
		[(ImageAndTextCell*) aCell setLastImageAlternate: nil];
	}
	
	if ([aTableView isEqual:albumTable] )
	{
		if( displayEmptyDatabase) return;
		
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 11];
		else txtFont = [NSFont systemFontOfSize:11];			
		
		[aCell setFont:txtFont];
		[aCell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
		if( [[aTableColumn identifier] isEqualToString:@"Source"] )
		{ 
			if ([[[self.albumArray objectAtIndex:rowIndex] valueForKey:@"smartAlbum"] boolValue] )
			{
				if (isCurrentDatabaseBonjour)
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
				if (isCurrentDatabaseBonjour)
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
	
	if ([aTableView isEqual:bonjourServicesList] )
	{
		NSFont *txtFont;
		
		if( rowIndex == 0) txtFont = [NSFont boldSystemFontOfSize: 11];
		else txtFont = [NSFont systemFontOfSize:11];
		
		[aCell setFont:txtFont];
		[aCell setLineBreakMode: NSLineBreakByTruncatingMiddle];
		
		
		NSDictionary *dict = nil;
		if( rowIndex > 0) dict = [[bonjourBrowser services] objectAtIndex: rowIndex-1];
		
		if (rowIndex == 0)
		{
			[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"osirix16x16.tiff"]];
		}
		else if( [[dict valueForKey:@"type"] isEqualToString:@"bonjour"] )
		{
			[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"bonjour.tiff"]];
		}
		else
		{
			NSString	*type = [dict valueForKey:@"type"];
			NSString	*path = [dict valueForKey:@"Path"];
			
			if( [type isEqualToString:@"dicomDestination"])
			{
				if( [dict valueForKey: @"icon"] && [NSImage imageNamed: [dict valueForKey: @"icon"]])
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed: [dict valueForKey: @"icon"]]];
				else
					[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"DICOMDestination.tif"]];
			}
			
			if( [type isEqualToString:@"fixedIP"])
				[(ImageAndTextCell*) aCell setImage:[NSImage imageNamed:@"FixedIP.tif"]];
			
			if( [type isEqualToString:@"localPath"] )
			{
				BOOL isDirectory;
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] )
				{
					if( isDirectory )
					{
						NSString *iPodControlPath = [path stringByAppendingPathComponent:@"iPod_Control"];
						BOOL isItAnIpod = [[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath];
						
						// Root?
						BOOL isThereAnOsiriXDataAtTheRoot = NO;
						
						NSArray* mountedVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
						for( NSString *vol in mountedVolumes )
						{
							if( [vol isEqualToString: path]) isThereAnOsiriXDataAtTheRoot = YES;
						}
						
						BOOL removableMedia = NO;
						NSArray* removableVolumes = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
						for( NSString *vol in removableVolumes )
						{
							if( [vol isEqualToString: path]) removableMedia = YES;
						}
						
						// iPod? or root?
						
						if (isItAnIpod || isThereAnOsiriXDataAtTheRoot)
						{
							NSImage	*im = [[NSWorkspace sharedWorkspace] iconForFile: path];
							[im setSize: NSMakeSize( 16, 16)];
							[(ImageAndTextCell*) aCell setImage: im];
							if( isItAnIpod || removableMedia )
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

- (void)sendDICOMFilesToOsiriXNode: (NSDictionary*)todo
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
		NSLog( ne.name );
		NSLog( ne.reason );
	}
	
	[storeSCU release];
	storeSCU = nil;
	
	[autoroutingInProgress unlock];
	
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
	}
	
	[context unlock];
	[context release];
	
	if( [seriesArray count]) return [seriesArray objectAtIndex: 0];
	else return nil;
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
		
		NSManagedObject *album = [albumArray objectAtIndex: row];
		
		if( draggedItems)
		{
			for( NSManagedObject *object in draggedItems)
			{
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
			
			if( [albumNoOfStudiesCache count] > row)
				[albumNoOfStudiesCache replaceObjectAtIndex:row withObject:@""];
			
			[tableView reloadData];
			
			if( isCurrentDatabaseBonjour)
			{
				// Do it remotely
				NSMutableArray *studiesToAdd = [NSMutableArray array];
				
				for( NSManagedObject *object in draggedItems)
				{
					if( [[object valueForKey:@"type"] isEqualToString:@"Study"])
						[studiesToAdd addObject: object];
					
					if( [[object valueForKey:@"type"] isEqualToString:@"Series"])
						[studiesToAdd addObject: [object valueForKey:@"study"]];
				}
				
				[bonjourBrowser addStudies: studiesToAdd toAlbum: album bonjourIndex:[bonjourServicesList selectedRow]-1];
			}
		}
		
		return YES;
	}
	
	if ([tableView isEqual:bonjourServicesList] )
	{
		if(draggedItems )
		{
			NSString *filePath, *destPath;
			NSMutableArray *imagesArray = [NSMutableArray arrayWithCapacity:0];
			
			for( NSManagedObject *object in draggedItems )
			{
				if( [[object valueForKey:@"type"] isEqualToString:@"Study"] )
				{
					for ( NSManagedObject *curSerie in [object valueForKey:@"series"] )
					{
						[imagesArray addObjectsFromArray: [[curSerie valueForKey:@"images"] allObjects]];
					}
				}
				
				if( [[object valueForKey:@"type"] isEqualToString:@"Series"] )
				{
					[imagesArray addObjectsFromArray: [[object valueForKey:@"images"] allObjects]];
				}
			}
			
			{
				NSMutableArray *paths = [NSMutableArray arrayWithArray: [imagesArray valueForKey: @"path"]];
				[paths removeDuplicatedStringsInSyncWithThisArray: imagesArray];
			}
			
			// DESTINATION IS A LOCAL PATH
			
			NSDictionary *object = nil;
			
			if( row > 0 ) object = [[bonjourBrowser services] objectAtIndex: row-1];
			
			if( [[object valueForKey: @"type"] isEqualToString:@"dicomDestination"])
			{
				NSArray * r = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly: NO];
				
				for( int i = 0 ; i < [r count]; i++)
				{
					NSDictionary *c = [r objectAtIndex: i];
					
					if( [[c objectForKey:@"Description"] isEqualToString: [object objectForKey:@"Description"]] &&
						[[c objectForKey:@"Address"] isEqualToString: [object objectForKey:@"Address"]] &&
						[[c objectForKey:@"Port"] intValue] == [[object objectForKey:@"Port"] intValue])
							[[NSUserDefaults standardUserDefaults] setInteger: i forKey:@"lastSendServer"];
				}
				
				[self selectServer: imagesArray];
			}
			else if( [[object valueForKey: @"type"] isEqualToString:@"localPath"] || (row == 0 && isCurrentDatabaseBonjour == NO) )
			{
				NSString	*dbFolder = nil;
				NSString	*sqlFile = nil;
				
				if( row == 0 )
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
						
						
						Wait *splash = nil;
						
						if( isCurrentDatabaseBonjour)
							splash = [[Wait alloc] initWithString:NSLocalizedString(@"Downloading files...", nil)];
						
						[splash showWindow:self];
						[[splash progress] setMaxValue:[imagesArray count]];
						
						NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: [imagesArray count]];
						for( NSManagedObject *img in imagesArray )
						{
							NSString	*sendPath = [self getLocalDCMPath: img :10];
							[packArray addObject: sendPath];
							
							[splash incrementBy:1];
						}
						
						// Add the ROIs
						for( DicomImage *img in imagesArray )
						{
							[packArray addObjectsFromArray: [img SRPaths]];
						}
						
						[splash close];
						[splash release];
						
						
						NSLog( @"DB Folder: %@", dbFolder);
						NSLog( @"SQL File: %@", sqlFile);
						NSLog( @"Current documentsDirectory: %@", self.documentsDirectory );
						
						NSPersistentStoreCoordinator *sc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel];
						NSManagedObjectContext *sqlContext = [[NSManagedObjectContext alloc] init];
						
						[sqlContext setPersistentStoreCoordinator: sc];
						
						if( [[sqlContext undoManager] isUndoRegistrationEnabled])
						{
							[[sqlContext undoManager] setLevelsOfUndo: 1];
							[[sqlContext undoManager] disableUndoRegistration];
						}
						NSError	*error = nil;
						NSArray *copiedObjects = nil;
						[sc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath: sqlFile] options:nil error:&error];
						
						if( [dbFolder isEqualToString: [self.documentsDirectory stringByDeletingLastPathComponent]] && isCurrentDatabaseBonjour == NO)	// same database folder - we don't need to copy the files
						{
							NSLog( @"Destination DB Folder is identical to Current DB Folder");
							
							copiedObjects = [self addFilesToDatabase: packArray onlyDICOM:NO safeRebuild:NO produceAddedFiles:YES parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
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
							
							for( int i = 0; i < [packArray count]; i++ )
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
							copiedObjects = [self addFilesToDatabase: dstFiles onlyDICOM:NO safeRebuild:NO produceAddedFiles:YES parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
						}
						
						// We will now copy the comments / status
						
						NSMutableArray *seriesArray = [NSMutableArray array];
						NSMutableArray *studiesArray = [NSMutableArray array];
						NSManagedObject	*study = nil, *series = nil;
						
						for (NSManagedObject *obj in copiedObjects)
						{
							if( [obj valueForKey:@"series"] != series)
							{
								// ********* SERIES
								series = [obj valueForKey:@"series"];
										
								if([seriesArray containsObject: series] == NO)
								{
									if( series) [seriesArray addObject: series];
									
									if( [series valueForKey:@"study"] != study)
									{
										study = [series valueForKey:@"study"];
											
										if([studiesArray containsObject: study] == NO)
										{
											if( study) [studiesArray addObject: study];
										}
									}
								}
							}
						}
						
						// Copy the comments/status/report at study level
						for (NSManagedObject *obj in studiesArray)
						{
							NSManagedObject *s = [self findStudyUID: [obj valueForKey: @"studyInstanceUID"]];
							
							if( [s valueForKey: @"comment"])
							{
								[obj setValue: [s valueForKey: @"comment"] forKey: @"comment"];
							}
							
							if( [s valueForKey: @"stateText"])
							{
								[obj setValue: [s valueForKey: @"stateText"] forKey: @"stateText"];
							}
							
							if( [s valueForKey: @"reportURL"])
							{
								if( [dbFolder isEqualToString: [self.documentsDirectory stringByDeletingLastPathComponent]] && isCurrentDatabaseBonjour == NO)	// same database folder - we don't need to copy the files
								{
									[obj setValue: [s valueForKey: @"reportURL"] forKey: @"reportURL"];
								}
								else
								{
									if( [[NSFileManager defaultManager] fileExistsAtPath: [s valueForKey: @"reportURL"]])
									{
										NSString *path = [s valueForKey: @"reportURL"];
										NSString *newPath = [NSString stringWithFormat: @"%@/REPORTS/%@", [dbFolder stringByAppendingPathComponent:@"OsiriX Data"], [path lastPathComponent]];
										
										[[NSFileManager defaultManager] copyPath: path toPath:newPath handler: nil];
										
										[obj setValue: newPath forKey: @"reportURL"];
									}
								}
							}
						}
						
						// Copy the comments/status at series level
						for (NSManagedObject *obj in seriesArray)
						{
							NSManagedObject *s = [self findSeriesUID: [obj valueForKey: @"seriesDICOMUID"]];
							
							if( [s valueForKey: @"comment"])
							{
								[obj setValue: [s valueForKey: @"comment"] forKey: @"comment"];
							}
							
							if( [s valueForKey: @"stateText"])
							{
								[obj setValue: [s valueForKey: @"stateText"] forKey: @"stateText"];
							}
						}
						
						error = nil;
						[sqlContext save: &error];
						
						[sc release];
						[sqlContext release];
					}
					
					@catch (NSException * e)
					{
						NSLog( [e description]);
						NSLog( @"Exception LOCAL PATH - DATABASE - tableView *******");
					}
				}
				else NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil),  NSLocalizedString(@"Destination Database / Index file is not available.", nil), NSLocalizedString(@"OK",nil), nil, nil);
				
				NSLog( @"-----------------------------");
			}
			else if( isCurrentDatabaseBonjour == YES)  // Copying FROM Distant to local OR distant
			{
				Wait *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Copying from OsiriX database...", nil)];
				BOOL OnlyDICOM = YES;
				BOOL succeed = NO;
				
				[splash showWindow:self];
				[[splash progress] setMaxValue:[imagesArray count]];
				
				for( NSManagedObject *img in imagesArray )
				{
					if( [[img valueForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) OnlyDICOM = NO;
				}
				
				if( OnlyDICOM && [[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
				{
					// We will use the DICOM-Store-SCP
					succeed = [bonjourBrowser retrieveDICOMFilesWithSTORESCU: [bonjourServicesList selectedRow]-1 to: row-1 paths: [imagesArray valueForKey:@"path"]];
					if( succeed )
					{
						for( int i = 0; i < [imagesArray count]; i++) [splash incrementBy:1];
					}
				}
				else NSLog( @"Not Only DICOM !");
				
				if( succeed == NO || OnlyDICOM == NO )
				{
					for( NSManagedObject *img in imagesArray )
					{
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						
						filePath = [self getLocalDCMPath: img :100];
						destPath = [[[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH] stringByAppendingPathComponent: [filePath lastPathComponent]];
						
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
				BOOL	OnlyDICOM = YES;
				
				NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: [imagesArray count]];
				
				for( NSManagedObject *img in imagesArray )
				{
					NSString	*sendPath = [self getLocalDCMPath: img :1];
					
					[packArray addObject: sendPath];
					
					if( [[img valueForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) OnlyDICOM = NO;
				}
				
				// Add the ROIs
				for( DicomImage *img in imagesArray )
				{
					[packArray addObjectsFromArray: [img SRPaths]];
				}
				
				NSDictionary *dcmNode = [[bonjourBrowser services] objectAtIndex: row-1];
				
				if( OnlyDICOM == NO ) NSLog( @"Not Only DICOM !");
				
				if( [dcmNode valueForKey:@"Port"] == nil && OnlyDICOM )
				{
					NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: dcmNode];
					[dict addEntriesFromDictionary: [bonjourBrowser getDICOMDestinationInfo: row-1]];
					[[bonjourBrowser services] replaceObjectAtIndex: row-1 withObject: dict];
					
					dcmNode = dict;
				}
				
				if( [dcmNode valueForKey:@"Port"] && OnlyDICOM )
				{
					WaitRendering		*wait = [[WaitRendering alloc] init: NSLocalizedString(@"Transfer started...", nil)];
					[wait showWindow:self];
					
					NSMutableDictionary	*todo = [NSMutableDictionary dictionaryWithDictionary: dcmNode];
					
					[todo setObject: packArray forKey:@"Files"];
					
					[NSThread detachNewThreadSelector:@selector( sendDICOMFilesToOsiriXNode:) toTarget:self withObject: todo];
					
					unsigned long finalTicks;
					Delay( 60, &finalTicks);
					
					[wait close];
					[wait release];
				}
				else
				{
					Wait	*splash = [[Wait alloc] initWithString:@"Copying to OsiriX database..."];
					[splash showWindow:self];
					[[splash progress] setMaxValue:[imagesArray count]];
					
					for( int i = 0; i < [imagesArray count]; )
					{
						NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
						NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: 10];
						
						for( int x = 0; x < 10; x++ )
						{
							if( i <  [imagesArray count] )
							{
								NSString	*sendPath = [self getLocalDCMPath:[imagesArray objectAtIndex: i] :1];
								
								[packArray addObject: sendPath];
								
								// Add the ROIs
								for( i = 0; i < [imagesArray count]; i++ )
								{
									[packArray addObjectsFromArray: [[imagesArray objectAtIndex: i] SRPaths]];
								}
								
								if([[sendPath pathExtension] isEqualToString:@"zip"] )
								{
									// it is a ZIP
									NSString *xmlPath = [[sendPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
									[packArray addObject: xmlPath];
								}
								[splash incrementBy:1];
							}
							i++;
						}
						
						if( [bonjourBrowser sendDICOMFile: row-1 paths: packArray] == NO)
						{
							NSRunAlertPanel( NSLocalizedString(@"Network Error", nil), NSLocalizedString(@"Failed to send the files to this node.", nil), nil, nil, nil);
							i = [imagesArray count];
						}
						
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

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if ([tableView isEqual:albumTable])
	{
		NSArray	*array = self.albumArray;
		
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

- (NSString *)tableView:(NSTableView *)tv toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	if( [tv isEqual: bonjourServicesList])
	{
		if( row > 0 )
		{
			NSDictionary	*dcmNode = [[bonjourBrowser services] objectAtIndex: row-1];
			
			if( [[dcmNode valueForKey:@"type"] isEqualToString: @"localPath"])
			{
				if( [[[dcmNode valueForKey:@"Path"] pathExtension] isEqualToString:@"sql"]) return [dcmNode valueForKey:@"Path"];
				else return [[dcmNode valueForKey:@"Path"] stringByAppendingPathComponent:@"OsiriX Data/"];
			}
			
			if( [[dcmNode valueForKey:@"type"] isEqualToString: @"dicomDestination"])
			{
				return [NSString stringWithFormat:@"%@ - %@:%@",[dcmNode objectForKey:@"AETitle"], [dcmNode objectForKey:@"Address"], [dcmNode objectForKey:@"Port"]];
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
	
	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification
{
	if( [[aNotification object] isEqual: albumTable] )
	{
		// Clear search field
		[self setSearchString:nil];
		
		if( albumTable.selectedRow < albumNoOfStudiesCache.count )
		{
			[albumNoOfStudiesCache replaceObjectAtIndex: albumTable.selectedRow withObject:@""];
		}
		[albumTable reloadData];
	}
	
	if( [[aNotification object] isEqual: bonjourServicesList] )
	{
		if( dontLoadSelectionSource == NO )
		{
			[self bonjourServiceClicked: bonjourServicesList];
		}
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
	
	for( int x = 0; x < [toOpenArray count]; x++ )
	{
		testPtr[ x] = nil;
	}
	
	for( int x = 0; x < [toOpenArray count]; x++ )
	{
		memBlock = 0;				
		NSArray* loadList = [toOpenArray objectAtIndex: x];
		
		if( [loadList count])
		{
			NSManagedObject*  curFile = [loadList objectAtIndex: 0];
			
			if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
			{
				mem += [[curFile valueForKey:@"width"] intValue]* [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
				memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
			}
			else
			{
				for( curFile in loadList )
				{				
					mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
					memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
				}
			}
			
			memBlock *= sizeof(float);
			memBlock += 4096;
			
			#if __LP64__
			#else
			unsigned long long max4GB = 4 * 1024;
			
			max4GB *= 1024 * 1024;
			
			if( memBlock >= max4GB)
			{
				memBlock = 0;	// 4-GB Limit
				NSLog(@"4-GB Memory limit for 32-bit application...", (memBlock) / (1024 * 1024));
			}
			#endif
			
			if( memBlock > 0)
				testPtr[ x] = malloc( memBlock);
			else
				testPtr[ x] = nil;
				
			if( testPtr[ x] == nil)
			{
				enoughMemory = NO;
				
				NSLog(@"Failed to allocate memory for: %d Mb", (memBlock) / (1024 * 1024));
			}
		}
		
	} //end for
	
	for( int x = 0; x < [toOpenArray count]; x++ )
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
	unsigned long		*memBlockSize = calloc( [toOpenArray count], sizeof (unsigned long));
	
	BOOL				multiFrame = NO;
	float				*fVolumePtr = nil;
	NSData				*volumeData = nil;
	NSMutableArray		*viewerPix[ 200];
	ViewerController	*movieController = nil;
	ViewerController	*createdViewer = viewer;
	
	@try
	{
		// NS_DURING (1) keyImages
		
		NSMutableArray *keyImagesToOpenArray = [NSMutableArray array];
		
		for( NSArray *loadList in toOpenArray )
		{
			NSMutableArray *keyImagesArray = [NSMutableArray array];
			
			for( NSManagedObject *image in loadList )
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
		
		if( dontShowOpenSubSeries == NO)
		{
			if (([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask) || ([self computeEnoughMemory: toOpenArray : nil] == NO))
			{
				toOpenArray = [self openSubSeries: toOpenArray];
			}
		}
		
		// NS_DURING (2) Compute Required Memory
		
		BOOL	enoughMemory = NO;
		long	subSampling = 1;
		unsigned long mem = 0;
		
		while( enoughMemory == NO )
		{
			BOOL memTestFailed = NO;
			unsigned char **testPtr = calloc( [toOpenArray count], sizeof( unsigned char*));
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++ )
			{
				unsigned long memBlock = 0;
				NSArray *loadList = [toOpenArray objectAtIndex: x];
				
				if( [loadList count])
				{
					NSManagedObject*  curFile = [loadList objectAtIndex: 0];
					[curFile setValue:[NSDate date] forKeyPath:@"series.dateOpened"];
					[curFile setValue:[NSDate date] forKeyPath:@"series.study.dateOpened"];
					
					if( [loadList count] == 1 && ( [[curFile valueForKey:@"numberOfFrames"] intValue] > 1 || [[curFile valueForKey:@"numberOfSeries"] intValue] > 1))  //     **We selected a multi-frame image !!!
					{
						multiFrame = YES;
						
						mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
						memBlock += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue] * [[curFile valueForKey:@"numberOfFrames"] intValue];
					}
					else
					{
						for( curFile in loadList )
						{
							long h = [[curFile valueForKey:@"height"] intValue];
							long w = [[curFile valueForKey:@"width"] intValue];
							
							w += 2;
							
							if( w*h < 256*256)
							{
								w = 256;
								h = 256;
							}
							
							mem += w * h;
							memBlock += w * h;
						}
					}
					
					if ( memBlock < 256 * 256 ) memBlock = 256 * 256;  // This is the size of array created when when an image doesn't exist, a 256 square graduated gray scale.
					
					testPtr[ x] = malloc( (memBlock * sizeof(float)) + 4096);
					if( testPtr[ x] == nil)
					{
						memTestFailed = YES;
						NSLog(@"Failed to allocate memory for: %d Mb", (memBlock * sizeof(float)) / (1024 * 1024));
					}
					memBlockSize[ x] = memBlock;
				}
				
			} //end for
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++ )
			{
				if( testPtr[ x]) free( testPtr[ x]);
			}
			
			free( testPtr);
			
			// TEST MEMORY : IF NOT ENOUGH -> REDUCE SAMPLING
			
			if( memTestFailed )
			{
				NSLog(@"Test memory failed -> sub-sampling");
				
				NSMutableArray *newArray = [NSMutableArray array];
				
				subSampling *= 2;
				
				for( NSArray *loadList in toOpenArray )
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
		
		if( subSampling != 1 )
		{
			NSArray	*winList = [NSApp windows];
			for( NSWindow *win in winList )
			{
				if( [win isMiniaturized] )
				{
					[win deminiaturize:self];
				}
			}
			
			result = NSRunInformationalAlertPanel( NSLocalizedString(@"Not enough memory", nil),  [NSString stringWithFormat: NSLocalizedString(@"Your computer doesn't have enough RAM to load this series, but I can load a subset of the series: 1 on %d images.", nil), subSampling], NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		}
		
		// NS_DURING (3) Load Images (memory allocation)
		
		BOOL notEnoughMemory = NO;
		
		if( result == NSAlertDefaultReturn && toOpenArray != nil )
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
				char **memBlockTestPtr = calloc( [toOpenArray count], sizeof( char*) );
				
				NSLog(@"4D Viewer TOTAL: %d Mb", (mem * sizeof(float)) / (1024 * 1024));
				for( unsigned long x = 0; x < [toOpenArray count]; x++ )
				{
					memBlockTestPtr[ x] = malloc(memBlockSize[ x] * sizeof(float));
					NSLog(@"4D Viewer: I will try to allocate: %d Mb", (memBlockSize[ x]* sizeof(float)) / (1024 * 1024));
					
					if( memBlockTestPtr[ x] == nil) notEnoughMemory = YES;
				}
				
				for( unsigned long x = 0; x < [toOpenArray count]; x++ )
				{
					if( memBlockTestPtr[ x] != nil) free( memBlockTestPtr[ x]);
				}
				
				if( notEnoughMemory )
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
		
		if( notEnoughMemory == NO )
		{
			for( unsigned long x = 0; x < [toOpenArray count]; x++ )
			{
//				NSLog(@"Current block to malloc: %d Mb", (memBlockSize[ x] * sizeof( float)) / (1024*1024));
				fVolumePtr = malloc( memBlockSize[ x] * sizeof(float));
				unsigned long mem = 0;
				
				if( fVolumePtr )
				{
					volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:memBlockSize[ x]*sizeof( float) freeWhenDone:YES];
					NSArray *loadList = [toOpenArray objectAtIndex: x];
					
					if( [loadList count] )
						[[WindowLayoutManager sharedWindowLayoutManager] setCurrentHangingProtocolForModality: [[loadList objectAtIndex: 0] valueForKeyPath:@"series.study.modality"] description:[[loadList objectAtIndex: 0] valueForKeyPath:@"series.study.studyName"]];
					
					// Why viewerPix[0] (fixed value) within the loop? Because it's not a 4D volume !
					viewerPix[0] = [[NSMutableArray alloc] initWithCapacity:0];
					NSMutableArray *correspondingObjects = [[NSMutableArray alloc] initWithCapacity:0];
					
					if( [loadList count] == 1 && [[[loadList objectAtIndex: 0] valueForKey:@"numberOfFrames"] intValue] > 1 )
					{
						multiFrame = YES;							
						NSManagedObject*  curFile = [loadList objectAtIndex: 0];
						
						for( unsigned long i = 0; i < [[curFile valueForKey:@"numberOfFrames"] intValue]; i++ )
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: 0];								
							DCMPix*	dcmPix = [[DCMPix alloc] myinit: [curFile valueForKey:@"completePath"] :i :[[curFile valueForKey:@"numberOfFrames"] intValue] :fVolumePtr+mem :i :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curFile];
							
							if( dcmPix )
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
						for( unsigned long i = 0; i < [loadList count]; i++ )
						{
							NSManagedObject*  curFile = [loadList objectAtIndex: i];
							DCMPix* dcmPix = [[DCMPix alloc] myinit: [curFile valueForKey:@"completePath"] :i :[loadList count] :fVolumePtr+mem :[[curFile valueForKey:@"frameID"] intValue] :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curFile];
							
							if( dcmPix )
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
					
					if( [viewerPix[0] count] != [loadList count] && multiFrame == NO )
					{
						for( unsigned int i = 0; i < [viewerPix[0] count]; i++ )
						{
							[[viewerPix[0] objectAtIndex: i] setID: i];
							[[viewerPix[0] objectAtIndex: i] setTot: [viewerPix[0] count]];
						}
						if( [viewerPix[0] count] == 0)
							NSRunCriticalAlertPanel( NSLocalizedString(@"Files not available (readable)", nil), NSLocalizedString(@"No files available (readable) in this series.", nil), NSLocalizedString(@"Continue",nil), nil, nil);
						else
							NSRunCriticalAlertPanel( NSLocalizedString(@"Not all files available (readable)", nil),  [NSString stringWithFormat: NSLocalizedString(@"Not all files are available (readable) in this series.\r%d files are missing.", nil), [loadList count] - [viewerPix[0] count]], NSLocalizedString(@"Continue",nil), nil, nil);
					}
					//opening images refered to in viewerPix[0] in the adequate viewer
					
					if( [viewerPix[0] count] > 0 )
					{
						if( movieViewer == NO )
						{
							if( multiFrame == YES)
							{
								NSMutableArray  *filesAr = [[NSMutableArray alloc] initWithCapacity: [viewerPix[0] count]];
								
								if( [correspondingObjects count])
								{
									for( unsigned int i = 0; i < [viewerPix[0] count]; i++)
										[filesAr addObject: [correspondingObjects objectAtIndex:0]];
								}
								
								if( viewer )
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
								}
								else
								{
									//creation of new viewer
									createdViewer = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles:[NSMutableArray arrayWithArray:correspondingObjects] withVolume:volumeData];
									[createdViewer showWindowTransition];
									[createdViewer startLoadImageThread];
								}
							}
						}
						else
						{
							//movieViewer==YES
							if( movieController == nil )
							{
								movieController = [[ViewerController alloc] initWithPix:viewerPix[0] withFiles:[NSMutableArray arrayWithArray:correspondingObjects] withVolume:volumeData];
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
		
	}
	@catch( NSException *e)
	{
		NSLog(@"Exception opening Viewer: %@", e);
		NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), [NSString stringWithFormat: NSLocalizedString(@"Opening Error : %@", nil), e] , nil, nil, nil);
	}
	
	free( memBlockSize );
	
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

- (IBAction) selectAll4DSeries:(id) sender
{
	if( [subOpenMatrix4D isEnabled] == YES)
		[NSApp stopModalWithCode: 7];
}

- (void) processOpenViewerDICOMFromArray:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer: (ViewerController*) viewer
{
	long				numberImages;
	BOOL				movieError = NO;
	
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
			
			if( [singleSeries count] > 1 )
			{
				[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
				
				interval = [[[singleSeries objectAtIndex: 0] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: 1] valueForKey:@"sliceLocation"] floatValue];
				
				if( interval == 0)	// 4D - 3D
				{
					int pos3Dindex = 1;
					for( int x = 1; x < [singleSeries count]; x++ )
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
					for( int x = 1; x < [singleSeries count]; x++ )
					{
						interval = [[[singleSeries objectAtIndex: x -1] valueForKey:@"sliceLocation"] floatValue] - [[[singleSeries objectAtIndex: x] valueForKey:@"sliceLocation"] floatValue];
						
						if( (interval < 0 && previousinterval > 0) || (interval > 0 && previousinterval < 0) )
						{
							[splittedSeries addObject: [NSMutableArray array]];
							NSLog(@"split at: %d", x);
							
							previousinterval = 0;
						}
						else if( previousinterval )
						{
							if( fabs(interval/previousinterval) > 2.0f || fabs(interval/previousinterval) < 0.5f )
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
		
		if( [toOpenArray count] == 1 )
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"To see an animated series, you have to select multiple series of the same area at different times: e.g. a cardiac CT", nil), NSLocalizedString(@"OK",nil), nil, nil);
			movieError = YES;
		}
		else if( [toOpenArray count] >= 200 )
		{
			NSRunCriticalAlertPanel( NSLocalizedString(@"4D Player",@"4D Player"), NSLocalizedString(@"4D Player is limited to a maximum number of 200 series.", nil), NSLocalizedString(@"OK",nil), nil, nil);
			movieError = YES;
		}
		else
		{
			numberImages = -1;
			
			for( unsigned long x = 0; x < [toOpenArray count]; x++ )
			{
				if( numberImages == -1 )
				{
					numberImages = [[toOpenArray objectAtIndex: x] count];
				}
				else if( [[toOpenArray objectAtIndex: x] count] != numberImages )
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
			NSMutableArray  *intervalArray = [NSMutableArray array];
			
			float interval, previousinterval = 0;
			
			[splittedSeries addObject: [NSMutableArray array]];
			
			if( [singleSeries count] > 1 )
			{
				[[splittedSeries lastObject] addObject: [singleSeries objectAtIndex: 0]];
				
				if( [[[singleSeries lastObject] valueForKey: @"numberOfFrames"] intValue] > 1)
				{
					for( id o in singleSeries)	//We need to extract the *true* sliceLocation
					{
						DCMPix *p = [[DCMPix alloc] myinit:[o valueForKey:@"completePath"] :0 :1 :nil :[[o valueForKey:@"frameID"] intValue] :[[o valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: o];
						
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
					
					for( int x = 1; x < [singleSeries count]; x++ )
					{
						if( [[intervalArray objectAtIndex: x] floatValue] - previousLocation == 0 )
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
								NSLog(@"split at: %d", x);
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
									NSLog(@"split at: %d", x);
									previousinterval = 0;
								}
								else if( previousinterval)
								{
									if( fabs(interval/previousinterval) > 1.2f || fabs(interval/previousinterval) < 0.8f)
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
					
					DCMPix *dcmPix  = [[DCMPix alloc] myinit:[oob valueForKey:@"completePath"] :0 :1 :nil :[[oob valueForKey:@"frameID"] intValue] :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: oob];
					
					if( dcmPix )
					{
						NSImage	 *img = [dcmPix generateThumbnailImageWithWW:0 WL:0];
						
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
				
				if( areData4D )
				{
					for( int i = 0 ; i < [[splittedSeries objectAtIndex: 0] count]; i++)
					{
						NSManagedObject	*oob = [[splittedSeries objectAtIndex: 0] objectAtIndex: i];
						
						DCMPix *dcmPix  = [[DCMPix alloc] myinit:[oob valueForKey:@"completePath"] :0 :1 :nil :[[oob valueForKey:@"frameID"] intValue] :[[oob valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj: oob];
						
						if( dcmPix)
						{
							NSImage	 *img = [dcmPix generateThumbnailImageWithWW:0 WL:0];
							
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
				if( result == 2 )
				{
					[supOpenButtons selectCellWithTag: 2];
					
					if( [subOpenMatrix3D selectedColumn] < 0)
					{
						if( [subOpenMatrix4D selectedColumn] < 0) result = 0;
						else result = 5;
					}
				}
				else if( result == 6 )
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
	
	if( movieError == NO && toOpenArray != nil )
		[self openViewerFromImages :toOpenArray movie: movieViewer viewer :viewer keyImagesOnly:NO];
		
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
	
	[managedObjectContext lock];
	
	@try
	{
		NSManagedObject		*selectedLine = [selectedLines objectAtIndex: 0];
		NSInteger			row, column;
		NSMutableArray		*selectedFilesList;
		NSArray				*loadList;
			
		NSArray				*cells = [oMatrix selectedCells];
		
		if( [cells count] == 0 && [[oMatrix cells] count] > 0 )
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
			
			for( NSCell* c in cells )
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
			
			NSMutableArray	*toOpenArray = [NSMutableArray arrayWithCapacity: 0];
			
			int x = 0;
			if( [cells count] == 1 && [selectedLines count] > 1 )	// Just one thumbnail is selected, but multiples lines are selected
			{
				for( NSManagedObject* curFile in selectedLines )
				{
					x++;
					loadList = nil;
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Study"] )
					{
						// Find the first series of images! DONT TAKE A ROI SERIES !
						if( [[curFile valueForKey:@"imageSeries"] count])
						{
							curFile = [[curFile valueForKey:@"imageSeries"] objectAtIndex: 0];
							loadList = [self childrenArray: curFile];
						}
					}
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"] )
					{
						loadList = [self childrenArray: curFile];
					}
					
					if( loadList) [toOpenArray addObject: loadList];
				}
			}
			else
			{
				for( NSButtonCell *cell in cells )
				{
					x++;
					if( [oMatrix getRow: &row column: &column ofCell: cell] == NO )
					{
						row = 0;
						column = 0;
					}
					
					loadList = nil;
					
					NSManagedObject*  curFile = [matrixViewArray objectAtIndex: [cell tag]];
					
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Image"]) loadList = [self childrenArray: selectedLine];
					if( [[curFile valueForKey:@"type"] isEqualToString: @"Series"]) loadList = [self childrenArray: curFile];
					
					if( loadList) [toOpenArray addObject: loadList];
				}
			}
			
			[self processOpenViewerDICOMFromArray: toOpenArray movie: movieViewer viewer: viewer];
		}
		
		if( tileWindows )
		{
			NSArray *viewers = [ViewerController getDisplayed2DViewers];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
			{
				[[AppController sharedAppController] tileWindows: self];
				
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
		
		NSRunAlertPanel( NSLocalizedString(@"Opening Error", nil), [NSString stringWithFormat: NSLocalizedString(@"Opening Error : %@", nil), e] , nil, nil, nil);
	}
	
	[managedObjectContext unlock];
}

- (void)viewerDICOM: (id)sender
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
	NSManagedObject		*item = [databaseOutline itemAtRow: [databaseOutline selectedRow]];
	
	[managedObjectContext lock];
	
	if (sender == Nil && [[oMatrix selectedCells] count] == 1 && [[item valueForKey:@"type"] isEqualToString:@"Study"] == YES )
	{
		NSArray *array = [self databaseSelection];
		
		BOOL savedValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"automaticWorkspaceLoad"];
		
		if( [array count] > 1 && savedValue == YES) [[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"automaticWorkspaceLoad"];
		
		for( id obj in array )
		{
			[databaseOutline selectRow: [databaseOutline rowForItem: obj] byExtendingSelection: NO];
			[self databaseOpenStudy: obj];
		}
		
		if( [array count] > 1 && savedValue == YES) [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"automaticWorkspaceLoad"];
	}
	else
	{
		if( [self isUsingExternalViewer: [matrixViewArray objectAtIndex: [[oMatrix selectedCell] tag]]] == NO )
		{
			[self viewerDICOMInt:NO	dcmFile: [self databaseSelection] viewer: nil];
		}
	}
	
	[managedObjectContext unlock];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"OsiriX Did Load New Object" object:item userInfo:nil];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (void)viewerDICOMMergeSelection: (id)sender
{
	NSMutableArray	*images = [NSMutableArray arrayWithCapacity:0];
	
	
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
}

- (void) viewerDICOMKeyImages:(id) sender
{
	NSMutableArray	*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	
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
}

- (void) MovieViewerDICOM:(id) sender
{
	NSInteger				index;
	NSMutableArray			*selectedItems = [NSMutableArray arrayWithCapacity:0];
	
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
	
	for( NSArray *loadList in toOpenArray )
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
		
		if( [imagesArray count] > 0)
			[newArray addObject: imagesArray];
	}
	
	return newArray;
}

- (IBAction) checkMemory:(id) sender
{
	unsigned long mem;
	
	if( [self computeEnoughMemory: [self produceNewArray: openSubSeriesArray] :&mem] )
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

- (void) setSubInterval: (id)sender
{
	subInterval = [sender intValue];
	
	[self checkMemory: self];
}

- (void) setSubFrom: (id)sender
{
	subFrom = [sender intValue];
	
	if( managedObjectContext == nil) return;
	if( bonjourDownloading) return;
	
	[animationSlider setIntValue: subFrom-1];
	[self previewSliderAction: nil];
	
	[self checkMemory: self];
}

- (void)setSubTo: (id)sender
{
	subTo = [sender intValue];
	
	if( managedObjectContext == nil) return;
	if( bonjourDownloading) return;
	
	[animationSlider setIntValue: subTo-1];
	[self previewSliderAction: nil];
	
	[self checkMemory: self];
}

- (NSArray*)openSubSeries: (NSArray*)toOpenArray
{
	[[waitOpeningWindow window] orderOut: self];
	
	openSubSeriesArray = [toOpenArray retain];
	
	if( [[NSApp mainWindow] level] > NSModalPanelWindowLevel){ NSBeep(); return nil;}		// To avoid the problem of displaying this sheet when the user is in fullscreen mode
	if( [[NSApp keyWindow] level] > NSModalPanelWindowLevel) { NSBeep(); return nil;}		// To avoid the problem of displaying this sheet when the user is in fullscreen mode
	
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subTo"];
	[self setValue:[NSNumber numberWithInt:[[toOpenArray objectAtIndex:0] count]] forKey:@"subMax"];
	
	[self setValue:[NSNumber numberWithInt:1] forKey:@"subFrom"];
	[self setValue:[NSNumber numberWithInt:2] forKey:@"subInterval"];
	
	[NSApp beginSheet: subSeriesWindow
	   modalForWindow: [NSApp mainWindow]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
	
	[self checkMemory: self];
	
	int result = [NSApp runModalForWindow: subSeriesWindow];
	
	[NSApp endSheet: subSeriesWindow];
	[subSeriesWindow orderOut: self];
	
	[[waitOpeningWindow window] orderBack: self];
	
	if( result == NSRunStoppedResponse )
	{
		[openSubSeriesArray release];
		
		return [self produceNewArray: toOpenArray];
	}
	
	[openSubSeriesArray release];
	
	return nil;
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

- (IBAction)fullScreenMenu: (id)sender
{
	// Is the item available in the toolbar?
	NSArray	*visibleItems = [toolbar visibleItems];
	
	for( id toolbarItem in visibleItems ){
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

- (id)initWithWindow: (NSWindow *)window
{
	displayEmptyDatabase = YES;
	
	[AppController initialize];
	
	for( int i = 0 ; i < [[NSScreen screens] count] ; i++)
	{
		visibleScreenRect[ i] = [[[NSScreen screens] objectAtIndex: i] visibleFrame];
	}
	
	if (hasMacOSXLeopard() == NO)	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", nil), NSLocalizedString(@"This application requires MacOS X 10.5 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		exit(0);
	}
	
	self = [super initWithWindow: window];
	if( self )
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
		
		if( [BrowserController _currentModifierFlags] & NSShiftKeyMask && [BrowserController _currentModifierFlags] & NSAlternateKeyMask )
		{
			NSLog( @"WARNING ---- Protected Mode Activated");
			[DCMPix setRunOsiriXInProtectedMode: YES];
		}
		
		if( [DCMPix isRunOsiriXInProtectedModeActivated] )
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
		[numFmt setNumberStyle: NSNumberFormatterDecimalStyle];
//		[numFmt setLocale: [NSLocale currentLocale]];
//		[numFmt setFormat:@"0"];
//		[numFmt setHasThousandSeparators: YES];
		
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
		toolbarSearchItem = nil;
		managedObjectModel = nil;
		managedObjectContext = nil;
		
		_filterPredicateDescription = nil;
		_filterPredicate = nil;
		_fetchPredicate = nil;
		
		matrixViewArray = nil;
		draggedItems = nil;
		
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
		
		isCurrentDatabaseBonjour = NO;
		currentDatabasePath = nil;
		currentDatabasePath = [[[self documentsDirectory] stringByAppendingPathComponent:DATAFILEPATH] retain];
		if( [[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath] == NO )
		{
			// Switch back to default location
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DEFAULT_DATABASELOCATION"];
			
			[currentDatabasePath release];
			currentDatabasePath = [[[self documentsDirectory] stringByAppendingPathComponent:DATAFILEPATH] retain];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: currentDatabasePath] == NO )
			{
				NEEDTOREBUILD = YES;
				COMPLETEREBUILD = YES;
			}
		}
		[self loadDatabase: currentDatabasePath];
		[self setFixedDocumentsDirectory];
		[self setNetworkLogs];
		
		// NSString *str = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
		
//		shouldDie = NO;
		bonjourDownloading = NO;
		
		previewPix = [[NSMutableArray alloc] initWithCapacity:0];
		
		timer = [[NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(previewPerformAnimation:) userInfo:self repeats:YES] retain];
		if([[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] < 1) [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"LISTENERCHECKINTERVAL"];
		IncomingTimer = [[NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"] target:self selector:@selector(checkIncoming:) userInfo:self repeats:YES] retain];
		refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:63.33 target:self selector:@selector(refreshDatabase:) userInfo:self repeats:YES] retain];
		bonjourTimer = [[NSTimer scheduledTimerWithTimeInterval: 5*60 target:self selector:@selector(checkBonjourUpToDate:) userInfo:self repeats:YES] retain];	//*60
		databaseCleanerTimer = [[NSTimer scheduledTimerWithTimeInterval:60*60 + 2.5 target:self selector:@selector(autoCleanDatabaseDate:) userInfo:self repeats:YES] retain];
		deleteQueueTimer = [[NSTimer scheduledTimerWithTimeInterval: 10 target:self selector:@selector(emptyDeleteQueue:) userInfo:self repeats:YES] retain];
		autoroutingQueueTimer = [[NSTimer scheduledTimerWithTimeInterval:35 target:self selector:@selector(emptyAutoroutingQueue:) userInfo:self repeats:YES] retain];
		
		
		loadPreviewIndex = 0;
		matrixDisplayIcons = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(matrixDisplayIcons:) userInfo:self repeats:YES] retain];
		
		[[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(newFilesGUIUpdate:) userInfo:self repeats:YES] retain];
		
		/* notifications from workspace */
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeMount:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(volumeUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(willVolumeUnmount:) name:NSWorkspaceWillUnmountNotification object:nil];
		
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainWindowHasChanged:) name:NSWindowDidBecomeMainNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:@"reportModeChanged" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReportToolbarIcon:) name:NSOutlineViewSelectionIsChangingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportToolbarItemWillPopUp:) name:NSPopUpButtonWillPopUpNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rtstructNotification:) name:@"RTSTRUCTNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AlternateButtonPressed:) name:@"AlternateButtonPressed" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CloseViewerNotification:) name:@"CloseViewerNotification" object:nil];
		
//		[[NSNotificationCenter defaultCenter] addObserver: self
//												selector: @selector(listChangedTest:)
//												name: @"OsiriXServerArray has changed"
//												object: nil];
		
//		[[NSTimer scheduledTimerWithTimeInterval: 5 target:self selector:@selector(autoTest:) userInfo:self repeats:NO] retain];
		
		displayEmptyDatabase = NO;
		
		
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
	
	[DateTimeFormat release];
	DateTimeFormat = [[NSDateFormatter alloc] init];
	[DateTimeFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateFormat2"]];
	
	[DateOfBirthFormat release];
	DateOfBirthFormat = [[NSDateFormatter alloc] init];
	[DateOfBirthFormat setDateFormat: [[NSUserDefaults standardUserDefaults] stringForKey: @"DBDateOfBirthFormat2"]];
	
	[[[databaseOutline tableColumnWithIdentifier: @"dateOpened"] dataCell] setFormatter: DateTimeFormat];
	[[[databaseOutline tableColumnWithIdentifier: @"date"] dataCell] setFormatter: DateTimeFormat];
	[[[databaseOutline tableColumnWithIdentifier: @"dateAdded"] dataCell] setFormatter: DateTimeFormat];
	
	[[[databaseOutline tableColumnWithIdentifier: @"dateOfBirth"] dataCell] setFormatter: DateOfBirthFormat];
	[[[databaseOutline tableColumnWithIdentifier: @"reportURL"] dataCell] setFormatter: DateOfBirthFormat];
}

+ (NSString*) DateTimeWithSecondsFormat:(NSDate*) t
{
	return [[[BrowserController currentBrowser] DateTimeWithSecondsFormat] stringFromDate: t];
}

+ (NSString*) TimeWithSecondsFormat:(NSDate*) t
{
	return [[[BrowserController currentBrowser] TimeWithSecondsFormat] stringFromDate: t];
}

+ (NSString*) TimeFormat:(NSDate*) t
{
	return [[[BrowserController currentBrowser] TimeFormat] stringFromDate: t];
}

+ (NSString*) DateOfBirthFormat:(NSDate*) d
{
	return [[[BrowserController currentBrowser] DateOfBirthFormat] stringFromDate: d];
}

+ (NSString*) DateTimeFormat:(NSDate*) d
{
	return [[[BrowserController currentBrowser] DateTimeFormat] stringFromDate: d];
}

-(void) awakeFromNib
{
	WaitRendering *wait = nil;
	
	if( sizeof( long) == 8 )
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting 64-bit version", nil)];
	}
	else
	{
		wait = [[WaitRendering alloc] init: NSLocalizedString(@"Starting 32-bit version", nil)];
	}
	
	if( autoroutingQueueArray == nil) autoroutingQueueArray = [[NSMutableArray array] retain];
	if( autoroutingQueue == nil) autoroutingQueue = [[NSLock alloc] init];
	if( autoroutingInProgress == nil) autoroutingInProgress = [[NSLock alloc] init];
	
	[wait showWindow:self];
	
	@try
	{
		NSTableColumn		*tableColumn = nil;
		NSPopUpButtonCell	*buttonCell = nil;
		
		[albumDrawer setPreferredEdge: NSMinXEdge];
		
		// thumbnails : no background color
		[thumbnailsScrollView setDrawsBackground:NO];
		[[thumbnailsScrollView contentView] setDrawsBackground:NO];
		
		if (hasMacOSXLeopard() == NO)
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"MacOS X", nil), NSLocalizedString(@"This application requires MacOS X 10.5 or higher. Please upgrade your operating system.", nil), NSLocalizedString(@"OK", nil), nil, nil);
			exit(0);
		}
		
		//	[self splitViewDidResizeSubviews:nil];
		[self.window setFrameAutosaveName:@"DBWindow"];
		
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
		NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Tools"];
		NSMenuItem *exportItem, *sendItem, *burnItem, *anonymizeItem, *keyImageItem;
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Display only this patient", nil) action: @selector(searchForCurrentPatient:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		
		[menu addItem: [NSMenuItem separatorItem]];
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images", nil) action: @selector(viewerDICOM:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open images in 4D", nil) action: @selector(MovieViewerDICOM:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Key Images", nil) action: @selector(viewerDICOMKeyImages:) keyEquivalent:@""];
		[keyImageItem setTarget:self];
		[menu addItem:keyImageItem];
		[keyImageItem release];
		keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open ROIs Images", nil) action: @selector(viewerDICOMROIsImages:) keyEquivalent:@""];
		[keyImageItem setTarget:self];
		[menu addItem:keyImageItem];
		[keyImageItem release];
		keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open ROIs and Key Images", nil) action: @selector(viewerKeyImagesAndROIsImages:) keyEquivalent:@""];
		[keyImageItem setTarget:self];
		[menu addItem:keyImageItem];
		[keyImageItem release];
		keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Open Merged Selection", nil) action: @selector(viewerDICOMMergeSelection:) keyEquivalent:@""];
		[keyImageItem setTarget:self];
		[menu addItem:keyImageItem];
		[keyImageItem release];
		
		keyImageItem= [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal In Finder", nil) action: @selector(revealInFinder:) keyEquivalent:@""];
		[keyImageItem setTarget:self];
		[menu addItem:keyImageItem];
		[keyImageItem release];
		
		[menu addItem: [NSMenuItem separatorItem]];
		
		sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to DICOM Network Node", nil) action: @selector(export2PACS:) keyEquivalent:@""];
		[sendItem setTarget:self];
		[menu addItem:sendItem];
		[sendItem release];
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to Quicktime", nil) action: @selector(exportQuicktime:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to JPEG", nil) action: @selector(exportJPEG:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to TIFF", nil) action: @selector(exportTIFF:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to DICOM File(s)", nil) action: @selector(exportDICOMFile:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
		sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Export to iDisk", nil) action: @selector(sendiDisk:) keyEquivalent:@""];
		[sendItem setTarget:self];
		[menu addItem:sendItem];
		[sendItem release];
		
		[menu addItem: [NSMenuItem separatorItem]];
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Compress DICOM files in JPEG", nil)  action:@selector(compressSelectedFiles:) keyEquivalent:@""];
		[menu addItem:exportItem];
		[exportItem release];
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Decompress DICOM JPEG files", nil)  action:@selector(decompressSelectedFiles:) keyEquivalent:@""];
		[menu addItem:exportItem];
		[exportItem release];
		
		[menu addItem: [NSMenuItem separatorItem]];
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Report", nil) action: @selector(generateReport:) keyEquivalent:@""];
		[exportItem setTarget:self];
		[menu addItem:exportItem];
		[exportItem release];
			
		[menu addItem: [NSMenuItem separatorItem]];
		
		sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Merge Selected Studies", nil) action: @selector(mergeStudies:) keyEquivalent:@""];
		[sendItem setTarget:self];
		[menu addItem:sendItem];
		[sendItem release];
		
		sendItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Unify patient identity", nil) action: @selector(unifyStudies:) keyEquivalent:@""];
		[sendItem setTarget:self];
		[menu addItem:sendItem];
		[sendItem release];
		
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
		
		exportItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy linked files to Database folder", nil)  action:@selector(copyToDBFolder:) keyEquivalent:@""];
		[menu addItem:exportItem];
		[exportItem release];
		
		[databaseOutline setMenu:menu];
		[menu release];
		
		[self addHelpMenu];
		
		ImageAndTextCell *cell = [[[ImageAndTextCell alloc] init] autorelease];
		[cell setEditable:YES];
		[[albumTable tableColumnWithIdentifier:@"Source"] setDataCell:cell];
		[albumTable setDelegate:self];
		[albumTable registerForDraggedTypes:[NSArray arrayWithObject:albumDragType]];
		[albumTable setDoubleAction:@selector(albumTableDoublePressed:)];
		
		[customStart setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customStart2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		[customEnd2 setDateValue: [NSCalendarDate dateWithYear:[[NSCalendarDate date] yearOfCommonEra] month:[[NSCalendarDate date] monthOfYear] day:[[NSCalendarDate date] dayOfMonth] hour:0 minute:0 second:0 timeZone: nil]];
		
		//	syntaxArray = [[NSArray arrayWithObjects:@"Explicit Little Endian", @"JPEG 2000 Lossless", @"JPEG 2000 Lossy 10:1", @"JPEG 2000 Lossy 20:1", @"JPEG 2000 Lossy 50:1",@"JPEG Lossless", @"JPEG High Quality (9)",  @"JPEG Medium High Quality (8)", @"JPEG Medium Quality (7)", nil] retain];
		//	[syntaxList setDataSource:self];
		
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
		
		if( [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"] )
		{
			NSDictionary	*sort = [[NSUserDefaults standardUserDefaults] objectForKey: @"databaseSortDescriptor"];
			{
				if( [databaseOutline isColumnWithIdentifierVisible: [sort objectForKey:@"key"]] )
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
		
		[cell setEditable:NO];
		[[bonjourServicesList tableColumnWithIdentifier:@"Source"] setDataCell:cell];
		
		[bonjourServicesList registerForDraggedTypes:[NSArray arrayWithObject:albumDragType]];
		
		[bonjourServicesList selectRow: 0 byExtendingSelection:NO];
		
		[splitViewVert restoreDefault:@"SPLITVERT2"];
		[splitViewHorz restoreDefault:@"SPLITHORZ2"];
//		[sourcesSplitView restoreDefault:@"SPLITSOURCE"];
		
		//remove LogView. Code no longer needed. LP
		//NSRect	frame = [[[logViewSplit subviews] objectAtIndex: 1] frame];
		//frame.size.height = 0;
		//[[[logViewSplit subviews] objectAtIndex: 1] setFrame: frame];
		//[logViewSplit adjustSubviews];
		
		[self autoCleanDatabaseDate: self];
		
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
		[self loadDICOMFromiPod];
	}
	
	@catch( NSException *ne)
	{
		NSLog(@"AwakeFromNib exception: %@", [ne description]);
		NSString *path = [[self documentsDirectory] stringByAppendingPathComponent:@"/Loading"];
		[path writeToFile:path atomically:NO encoding : NSUTF8StringEncoding error: nil];
		
		NSString *message = [NSString stringWithFormat: NSLocalizedString(@"A problem occured during start-up of OsiriX:\r\r%@",nil), [ne description]];
		
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error",nil), message, NSLocalizedString( @"OK",nil), nil, nil);
		
		exit( 0);
	}
	
	[wait close];
	[wait release];
	
	[self testAutorouting];
	
	[self setDBWindowTitle];
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"drawerState"] )
	{
		if( [[[NSUserDefaults standardUserDefaults] objectForKey: @"drawerState"] intValue] == NSDrawerOpenState)
			[albumDrawer openOnEdge:NSMinXEdge];
		else
			[albumDrawer close];
	}
	
	loadingIsOver = YES;
	
	[self outlineViewRefresh];
	
	[self.window makeKeyAndOrderFront: self];
	
	[self refreshMatrix: self];
	
	[sourcesSplitView restoreDefault:@"SPLITSOURCE"];
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
	[BrowserController tryLock: managedObjectContext during: 120];
	[BrowserController tryLock: checkIncomingLock during: 120];
	[BrowserController tryLock: checkBonjourUpToDateThreadLock during: 120];
	
	while( [SendController sendControllerObjects] > 0 )
		[NSThread sleepForTimeInterval: 0.04];
	
	[BrowserController tryLock: decompressThreadRunning during: 120];
	[BrowserController tryLock: deleteInProgress during: 120];
		
	[self emptyDeleteQueueThread];
	
	[BrowserController tryLock: deleteInProgress during: 120];
	[BrowserController tryLock: autoroutingInProgress during: 120];
	
	[self emptyAutoroutingQueue:self];
	
	[BrowserController tryLock: autoroutingInProgress during: 120];
	
	[self syncReportsIfNecessary: previousBonjourIndex];
	
	[BrowserController tryLock: checkIncomingLock during: 120];
}

- (void) browserPrepareForClose
{
	NSLog( @"browserPrepareForClose");
	
	copyThread = NO;
	
	[self saveDatabase: currentDatabasePath];
	
	[self waitForRunningProcesses];

	[self saveDatabase: currentDatabasePath];
	
	[self removeAllMounted];
	
	newFilesInIncoming = NO;
	[self setDockIcon];
	
	[sourcesSplitView saveDefault:@"SPLITSOURCE"];
    [splitViewVert saveDefault:@"SPLITVERT2"];
    [splitViewHorz saveDefault:@"SPLITHORZ2"];
	
	if( [[databaseOutline sortDescriptors] count] >= 1 )
	{
		NSDictionary	*sort = [NSDictionary	dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:[[[databaseOutline sortDescriptors] objectAtIndex: 0] ascending]], @"order", [[[databaseOutline sortDescriptors] objectAtIndex: 0] key], @"key", nil];
		[[NSUserDefaults standardUserDefaults] setObject:sort forKey: @"databaseSortDescriptor"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:[databaseOutline columnState] forKey: @"databaseColumns2"];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt: [albumDrawer state]] forKey: @"drawerState"];
	
    [self.window setDelegate:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool: [animationCheck state] forKey: @"AutoPlayAnimation"];
	
	// bonjour defaults
	[[NSUserDefaults standardUserDefaults] setBool: [bonjourSharingCheck state] forKey: @"bonjourSharing"];
	[[NSUserDefaults standardUserDefaults] setObject:[bonjourServiceName stringValue] forKey: @"bonjourServiceName"];
	
	[[NSUserDefaults standardUserDefaults] setBool: [bonjourPasswordCheck state] forKey: @"bonjourPasswordProtected"];
	[[NSUserDefaults standardUserDefaults] setObject:[bonjourPassword stringValue] forKey: @"bonjourPassword"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[bonjourSharingCheck setState: NSOffState];
	[bonjourPublisher toggleSharing:NO];
}

- (BOOL)shouldTerminate: (id)sender
{
	[self saveDatabase: currentDatabasePath];
	
	if( newFilesInIncoming)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Listener - STORE", nil), NSLocalizedString(@"New files are arriving in the DICOM Database. Are you sure you want to quit now? The DICOM Listener will be stopped.", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Quit", nil), nil) == NSAlertDefaultReturn) return NO;
	}
	
	if( [SendController sendControllerObjects] > 0 )
	{
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
	
    if (c == NSDeleteCharacter ||
        c == NSBackspaceCharacter)
        [self delItem:nil];
    
	else if(c == NSNewlineCharacter ||
             c == NSEnterCharacter ||
             c == NSCarriageReturnCharacter)
        [self viewerDICOM:nil];
		
	else if(c == ' ')
		[animationCheck setState: ![animationCheck state]];
	
    else
	{
		[pressedKeys appendString: [event characters]];
		
		NSLog(@"%@", pressedKeys);
		
		NSArray		*result = [outlineViewArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", [NSString stringWithFormat:@"%@", pressedKeys]]];
		
		[NSObject cancelPreviousPerformRequestsWithTarget: pressedKeys selector:@selector(setString:) object:@""];
		[pressedKeys performSelector:@selector(setString:) withObject:@"" afterDelay:0.5];
		
		if( [result count] )
		{
			[databaseOutline selectRow: [databaseOutline rowForItem: [result objectAtIndex: 0]] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: databaseOutline.selectedRow];
		}
		else NSBeep();
    }
}

- (void)mainWindowHasChanged:(NSNotification *)note
{
	[mainWindow release];
	mainWindow = [[note object] retain];
}

- (BOOL)validateMenuItem: (NSMenuItem*) menuItem
{
	if ( menuItem.menu == imageTileMenu )
	{
		return [mainWindow.windowController isKindOfClass:[ViewerController class]];
	}
	else if( [menuItem action] == @selector( viewerDICOMROIsImages:))
	{
		if( isCurrentDatabaseBonjour == NO)
		{
			if( [[databaseOutline selectedRowIndexes] count] < 20 && [[self ROIImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( viewerKeyImagesAndROIsImages:))
	{
		if( isCurrentDatabaseBonjour == NO)
		{
			if( [[databaseOutline selectedRowIndexes] count] < 20 && [[self ROIsAndKeyImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( viewerDICOMKeyImages:))
	{
		if( isCurrentDatabaseBonjour == NO)
		{
			if( [[databaseOutline selectedRowIndexes] count] < 20 && [[self KeyImages: menuItem] count] == 0) return NO;
		}
		else return YES;
	}
	else if( [menuItem action] == @selector( createROIsFromRTSTRUCT:))
	{
		if( isCurrentDatabaseBonjour) return NO;
	}
	else if( [menuItem action] == @selector( compressSelectedFiles:))
	{
		if( isCurrentDatabaseBonjour) return NO;
	}
	else if( [menuItem action] == @selector( decompressSelectedFiles:))
	{
		if( isCurrentDatabaseBonjour) return NO;
	}
	else if( [menuItem action] == @selector( copyToDBFolder:))
	{
		if( isCurrentDatabaseBonjour) return NO;
		
			
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
	else if( [menuItem action] == @selector( delItem:))
	{
		if( isCurrentDatabaseBonjour) return NO;
	}
	else if( [menuItem action] == @selector( mergeStudies:))
	{
		if( isCurrentDatabaseBonjour) return NO;
		
		NSIndexSet		*selectedRows = [databaseOutline selectedRowIndexes];
		BOOL	onlySeries = YES;
		
		for( NSInteger x = 0; x < [selectedRows count] ; x++ )
		{
			NSInteger row = ( x == 0 ) ? [selectedRows firstIndex] : [selectedRows indexGreaterThanIndex: row];
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
		if( isCurrentDatabaseBonjour) return NO;
		
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
	NSMenu *helpMenu = [[NSMenu allocWithZone: [NSMenu menuZone]] initWithTitle:NSLocalizedString(@"Help", nil)];
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
		
	[deleteInProgress lock];
	[deleteQueue lock];
	NSArray	*copyArray = [NSArray arrayWithArray: deleteQueueArray];
	[deleteQueueArray removeAllObjects];
	[deleteQueue unlock];
	
	if( copyArray.count )
	{
		[appController growlTitle: NSLocalizedString( @"Files removing", nil) description: [NSString stringWithFormat: NSLocalizedString( @"%d files to delete", nil), [copyArray count]]  name:@"delete"];
		
		NSLog(@"delete Queue start: %d objects", [copyArray count]);
		for( NSString *file in copyArray )
			unlink( [file UTF8String] );		// <- this is faster
		//			[[NSFileManager defaultManager] removeFileAtPath:[copyArray objectAtIndex: i] handler:nil];
		NSLog(@"delete Queue end");
		
		[appController growlTitle: NSLocalizedString( @"Files removing", nil) description: NSLocalizedString( @"Finished", nil) name:@"delete"];
	}
	
	[deleteInProgress unlock];
	[pool release];
}

- (void)emptyDeleteQueue: (id)sender
{
	// Check for the errors generated by the Q&R DICOM functions -- see dcmqrsrv.mm
	
	NSString *str = [NSString stringWithContentsOfFile: @"/tmp/error_message"];
	if( str)
	{
		[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/error_message" handler: nil];
		NSRunAlertPanel( NSLocalizedString( @"DICOM Network Error", nil), str, NSLocalizedString( @"OK", nil), nil, nil);
	}
	
	//////////////////////////////////////////////////
	
	if( deleteQueueArray != nil && deleteQueue != nil )
	{
		if( [deleteQueueArray count] > 0 )
		{
			if( [deleteInProgress tryLock] )
			{
				[deleteInProgress unlock];
				[NSThread detachNewThreadSelector:@selector(emptyDeleteQueueThread) toTarget:self withObject:nil];
			}
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"checkDICOMListenerWithEcho"] && newFilesInIncoming == NO)
	{
		// Send a c-echo on our ip
		if ([[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
		{
			if( [[AppController sharedAppController] echoTest] == NO)
			{
				NSLog(@"********");
				NSLog(@"******** C-ECHO FAILED ON OUR IP ADDRESS - RESTART DICOM LISTENER ************");
				NSLog(@"********");
				
				[[AppController sharedAppController] killDICOMListenerWait: NO];
				[[AppController sharedAppController] restartSTORESCP];
			}
			else NSLog(@"C-ECHO TEST: SUCCEEDED");
		}
	}

}

- (void)addFileToDeleteQueue: (NSString*)file
{
	if( deleteQueueArray == nil ) deleteQueueArray = [[NSMutableArray array] retain];
	if( deleteQueue == nil ) deleteQueue = [[NSLock alloc] init];
	if( deleteInProgress == nil ) deleteInProgress = [[NSLock alloc] init];
	
	[deleteQueue lock];
	[deleteQueueArray addObject: file];
	[deleteQueue unlock];
}

+ (NSString*)_findFirstDicomdirOnCDMedia: (NSString*)startDirectory found: (BOOL)found
{
	DicomDirScanDepth++;
	
	NSArray *fileNames = nil;
	NSString *filePath = nil;
	BOOL isDirectory = FALSE;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	fileNames = [[NSFileManager defaultManager] directoryContentsAtPath: startDirectory];
	for( int i = 0; i < [fileNames count] && !found; i++ )
	{
		filePath = [startDirectory stringByAppendingPathComponent: [fileNames objectAtIndex: i]];
		NSString *upperString = [[fileNames objectAtIndex: i] uppercaseString];
		if([upperString isEqualToString: @"DICOMDIR"] || [upperString isEqualToString: @"DICOMDIR."] )
		{
			return filePath;
		}
		else if( [[fileNames objectAtIndex: i] characterAtIndex: 0] != '.' )
		{
			isDirectory = FALSE;
			if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] )
			{
				if(isDirectory == YES && DicomDirScanDepth < 3)	{
					if((filePath = [BrowserController _findFirstDicomdirOnCDMedia: filePath found:found]) != nil)
						return filePath;
				}
			}
		}
	}
	
	DicomDirScanDepth--;
	
	return nil;
}

-(void) ReadDicomCDRom:(id) sender
{
	NSArray	*removeableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
	BOOL found = NO;
	
	for( NSString *mediaPath in removeableMedia )
	{
		BOOL		isWritable, isUnmountable, isRemovable, hasDICOMDIR = NO;
		NSString	*description, *type;
		
		[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath: mediaPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&type];
		
		if( isRemovable == YES)
		{
			// hasDICOMDIR ?
			{
				NSString *aPath = mediaPath;
				NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
				
				if( enumer == nil)
					aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
				
				DicomDirScanDepth = 0;
				aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath found: FALSE];
				
				if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
					hasDICOMDIR = YES;
			}
			
			if(  hasDICOMDIR == YES)
			{
				// ADD ALL FILES OF THIS VOLUME TO THE DATABASE!
				NSMutableArray  *filesArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
				
				found = YES;
				
				if ([[NSUserDefaults standardUserDefaults] boolForKey: @"USEDICOMDIR"])
				{
					NSString    *aPath = mediaPath;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					if( enumer == nil )
					{
						aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
						enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					}
					
					// DICOMDIR should be located at the root level
					DicomDirScanDepth = 0;
					aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath found: FALSE];
					
					if( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
					{
						int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"STILLMOVIEMODE"];
						
						@try
						{
							[self addDICOMDIR: aPath :filesArray];
						}
						
						@catch (NSException *e)
						{
							NSLog( e.description );
						}
						
						
						switch ( mode )
						{
							case 0: // ALL FILES
								
								break;
								
							case 1: //EXCEPT STILL
								for( int i = 0; i < [filesArray count]; i++ )
								{
									if( [[[filesArray objectAtIndex:i] lastPathComponent] isEqualToString:@"STILL"] == YES )
									{
										[filesArray removeObjectAtIndex:i];
										i--;
									}
								}
								break;
								
								case 2: //EXCEPT MOVIE
								for( int i = 0; i < [filesArray count]; i++ )
								{
									if( [[[filesArray objectAtIndex:i] lastPathComponent] isEqualToString:@"MOVIE"] == YES )
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
							NSRunCriticalAlertPanel(NSLocalizedString(@"DICOMDIR",nil), NSLocalizedString(@"No DICOMDIR file has been found on this CD/DVD. Unable to load images.",nil),NSLocalizedString( @"OK",nil), nil, nil);
					}
				}
				else
				{
					NSString    *pathname;
					NSString    *aPath = mediaPath;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					if( enumer == nil )
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
								addFile = NO;
							
							if( [[[itemPath lastPathComponent] uppercaseString] isEqualToString:@".DS_STORE"] == YES)
								addFile = NO;
							
							if( [[itemPath lastPathComponent] length] > 0 && [[itemPath lastPathComponent] characterAtIndex: 0] == '.')
								addFile = NO;
							
							for( NSString *s in [itemPath pathComponents])
							{
								NSString *e = [s pathExtension];
								
								if( [e isEqualToString:@""] || [[e lowercaseString] isEqualToString:@"dcm"] || [[e lowercaseString] isEqualToString:@"img"] || [[e lowercaseString] isEqualToString:@"im"]  || [[e lowercaseString] isEqualToString:@"dicom"])
								{
								}
								else
								{
									addFile = NO;
								}
							}
							
							if( addFile) [filesArray addObject:itemPath];
							else NSLog(@"skip this file: %@", [itemPath lastPathComponent]);
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
	
	if( found == NO )
	{
		if( [[DRDevice devices] count] )
		{
			DRDevice	*device = [[DRDevice devices] objectAtIndex: 0];
			
			// Is the bay close? open it for the user
			if( [[[device status] valueForKey: DRDeviceIsTrayOpenKey] boolValue] == YES)
			{
				[device closeTray];
				[appController growlTitle: NSLocalizedString( @"CD/DVD", nil) description: NSLocalizedString(@"Please wait. CD/DVD is loading...", nil) name:@"newfiles"];
				return;
			}
			else
			{
				if( [[[device status] valueForKey: DRDeviceIsBusyKey] boolValue] == NO && [[[device status] valueForKey: DRDeviceMediaStateKey] isEqualToString:DRDeviceMediaStateNone])
					[device openTray];
				else
				{
					[appController growlTitle: NSLocalizedString( @"CD/DVD", nil) description: NSLocalizedString(@"Cannot find a valid DICOM CD/DVD format.", nil) name:@"newfiles"];
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
		
		for( NSString *mediaPath in removeableMedia )
		{
			NSLog( path );
			NSLog( mediaPath );
			if( [[mediaPath commonPrefixWithString: path options: NSCaseInsensitiveSearch] isEqualToString: mediaPath] )
			{
				BOOL		isWritable, isUnmountable, isRemovable, hasDICOMDIR = NO;
				NSString	*description, *type;
				
				[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath: mediaPath isRemovable:&isRemovable isWritable:&isWritable isUnmountable:&isUnmountable description:&description type:&type];
				
				if( isRemovable == YES)
				{
					// hasDICOMDIR ?
					NSString *aPath = mediaPath;
					NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:aPath];
					
					if( enumer == nil)
						aPath = [NSString stringWithFormat:@"/Volumes/Untitled"];
					
					DicomDirScanDepth = 0;
					aPath = [BrowserController _findFirstDicomdirOnCDMedia: aPath found: FALSE];
					
					if( [[NSFileManager defaultManager] fileExistsAtPath:aPath])
						hasDICOMDIR = YES;
						
					if(  hasDICOMDIR == YES)
						return YES;
				}
			}
		}
	}
	return NO;
}

- (void)listenerAnonymizeFiles: (NSArray*)files
{
	NSArray				*array = [NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"******", nil];
	NSMutableArray		*tags = [NSMutableArray array];
	
	[tags addObject:array];
	
	for( NSString *file in files )
	{
		NSString *destPath = [file stringByAppendingString:@"temp"];
		
		[DCMObject anonymizeContentsOfFile: file  tags:tags  writingToFile:destPath];
		[[NSFileManager defaultManager] removeFileAtPath: file handler: nil];
		[[NSFileManager defaultManager] movePath:destPath toPath: file handler: nil];
	}
}

- (NSString*) pathResolved:(NSString*) inPath
{
	CFStringRef resolvedPath = nil;
	CFURLRef	url = CFURLCreateWithFileSystemPath(NULL /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != NULL)
	{
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
		{
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased)
			{
				CFURLRef resolvedurl = CFURLCreateFromFSRef(NULL /*allocator*/, &fsRef);
				if (resolvedurl != NULL)
				{
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
	return resolved ? resolved : inPath;
}

- (NSString *)folderPathResolvingAliasAndSymLink:(NSString *)path
{
	NSString *folder = path;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		if (![self isAliasPath:path])
			[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		//we have an alias
		else
		{ 
			//NSLog(@"INCOMING alias");
			folder = [self pathResolved: path];
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
		if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink]) 
			folder= [[NSFileManager defaultManager] pathContentOfSymbolicLinkAtPath:path];
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
	
	if( [filesToExport count] )
	{
		[[NSWorkspace sharedWorkspace] selectFile:[filesToExport objectAtIndex: 0] inFileViewerRootedAtPath:nil];
	}
}

static volatile int numberOfThreadsForJPEG = 0;

- (BOOL) waitForAProcessor
{
	int processors =  MPProcessors();
	
	[processorsLock lockWhenCondition: 1];
	BOOL result = numberOfThreadsForJPEG >= processors;
	if( result == NO )
	{
		numberOfThreadsForJPEG++;
		if( numberOfThreadsForJPEG >= processors )
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

- (void)decompressDICOMJPEGinINCOMING: (NSString*)compressedPath
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	NSString			*INpath = [[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
	
	[self decompressDICOM:compressedPath to: [INpath stringByAppendingPathComponent:[compressedPath lastPathComponent]]];
	
	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

- (void)decompressDICOMJPEG: (NSString*)compressedPath
{
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	
	[self decompressDICOM:compressedPath to: nil];
	
	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

- (void)compressDICOMJPEG: (NSString*)compressedPath
{
	NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
	
	[self compressDICOMWithJPEG:compressedPath];
	
	[processorsLock lock];
	if( numberOfThreadsForJPEG >= 0) numberOfThreadsForJPEG--;
	[processorsLock unlockWithCondition: 1];
	
	[pool release];
}

- (void)decompressArrayOfFiles: (NSArray*)array work: (NSNumber*)work
{
	[decompressThreadRunning lock];
	[decompressArrayLock lock];
	[decompressArray addObjectsFromArray: array];
	[decompressArrayLock unlock];
	[decompressThreadRunning unlock];
	
	[self decompressThread: work];
}

- (IBAction) compressSelectedFiles: (id)sender
{
	if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO )
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
		
		for( int i = 0 ; i < [filesToExport count] ; i++ )
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
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", nil), NSLocalizedString(@"Cannot compress images in a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
}

- (IBAction)decompressSelectedFiles: (id)sender
{

	if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO )
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
		
		for( int i = 0 ; i < [filesToExport count] ; i++ )
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
	else NSRunInformationalAlertPanel(NSLocalizedString(@"Non-Local Database", nil), NSLocalizedString(@"Cannot decompress images in a distant database.", nil), NSLocalizedString(@"OK",nil), nil, nil);
}

- (void) decompressThread: (NSNumber*) typeOfWork
{	
	[decompressThreadRunning lock];
	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
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
	NSArray *array = [NSArray arrayWithArray: decompressArray];
	[decompressArray removeAllObjects];
	[decompressArrayLock unlock];
	
	numberOfThreadsForJPEG = 0;
	
	switch( tow)
	{
		case 'C':
			[appController growlTitle: NSLocalizedString( @"Files Compression", nil) description:[NSString stringWithFormat: NSLocalizedString(@"Starting to compress %d files", nil), [array count]] name:@"newfiles"];
			break;
			
		case 'D':
			[appController growlTitle: NSLocalizedString( @"Files Decompression", nil) description:[NSString stringWithFormat: NSLocalizedString(@"Starting to decompress %d files", nil), [array count]] name:@"newfiles"];
			break;
	}
	
	for( id obj in array )
	{
		[self waitForAProcessor];
		
		switch( tow)
		{
			case 'C':
				[NSThread detachNewThreadSelector: @selector( compressDICOMJPEG:) toTarget:self withObject: obj];
				break;
				
			case 'D':
				[NSThread detachNewThreadSelector: @selector( decompressDICOMJPEG:) toTarget:self withObject: obj];
				break;
				
			case 'I':
				[NSThread detachNewThreadSelector: @selector( decompressDICOMJPEGinINCOMING:) toTarget:self withObject: obj];
				break;
		}
	}
	
	finished = NO;
	do
	{
		[processorsLock lockWhenCondition: 1];
		if( numberOfThreadsForJPEG <= 0 )
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
			[appController growlTitle: NSLocalizedString( @"Files Compression", nil) description: NSLocalizedString(@"Done !", nil) name:@"newfiles"];
			break;
			
		case 'D':
			[appController growlTitle: NSLocalizedString( @"Files Decompression", nil) description: NSLocalizedString(@"Done !", nil) name:@"newfiles"];
			break;
	}
	
	[pool release];
	
	[decompressThreadRunning unlock];
}

- (void)checkIncomingThread: (id)sender
{
	@try
	{
		NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
		
		[checkIncomingLock lock];
		
		@try
		{
			NSString        *INpath = [[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
			NSString		*ERRpath = [[self documentsDirectory] stringByAppendingPathComponent:ERRPATH];
			NSString        *OUTpath = [[self documentsDirectory] stringByAppendingPathComponent:DATABASEPATH];
			NSString        *DECOMPRESSIONpath = [[self documentsDirectory] stringByAppendingPathComponent:DECOMPRESSIONPATH];
			BOOL			DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"];
			BOOL			DECOMPRESSDICOMLISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DECOMPRESSDICOMLISTENER"];
			BOOL			COMPRESSDICOMLISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMPRESSDICOMLISTENER"];
			
			//NSLog(@"Scan folder START");
			
			if( bonjourDownloading == NO && isCurrentDatabaseBonjour == NO )
			{	
				//need to resolve aliases and symbolic links
				INpath = [self folderPathResolvingAliasAndSymLink:INpath];
				OUTpath = [self folderPathResolvingAliasAndSymLink:OUTpath];
				ERRpath = [self folderPathResolvingAliasAndSymLink:ERRpath];
				DECOMPRESSIONpath = [self folderPathResolvingAliasAndSymLink:DECOMPRESSIONpath];
				
				[AppController createNoIndexDirectoryIfNecessary: OUTpath];
				
				NSString        *pathname;
				NSMutableArray  *filesArray = [[NSMutableArray alloc] initWithCapacity:0];
				NSMutableArray	*compressedPathArray = [[NSMutableArray alloc] initWithCapacity:0];
				
				NSDirectoryEnumerator *enumer = [[NSFileManager defaultManager] enumeratorAtPath:INpath];
				
				while (pathname = [enumer nextObject])
				{
					NSString *srcPath = [INpath stringByAppendingPathComponent:pathname];
					NSString *originalPath = srcPath;
					
					if ([[[srcPath lastPathComponent] uppercaseString] isEqualToString:@".DS_STORE"])
						continue;
					
					if ( [[srcPath lastPathComponent] length] > 0 && [[srcPath lastPathComponent] characterAtIndex: 0] == '.')
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
						else if( fattrs != nil && [[fattrs objectForKey:NSFileBusy] boolValue] == NO && [[fattrs objectForKey:NSFileSize] longLongValue] > 0)
						{
							BOOL		isDicomFile;
							BOOL		isJPEGCompressed;
							NSString	*dstPath = [OUTpath stringByAppendingPathComponent:[srcPath lastPathComponent]];
							
							isDicomFile = [DicomFile isDICOMFile:srcPath compressed:&isJPEGCompressed];
							
							if( isDicomFile == YES ||
							   (([DicomFile isFVTiffFile:srcPath] ||
								 [DicomFile isTiffFile:srcPath] ||
								 [DicomFile isNRRDFile:srcPath] ||
								 [DicomFile isXMLDescriptedFile:srcPath]||
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
									if ([DicomFile isXMLDescriptorFile:srcPath])
									{ // XML comes before ZIP in alphabetic order...
										[[NSFileManager defaultManager] movePath:srcPath toPath:dstPath handler:nil]; // move the XML first
										srcPath = [[srcPath stringByDeletingPathExtension] stringByAppendingString:@".zip"];
										dstPath = [[dstPath stringByDeletingPathExtension] stringByAppendingString:@".zip"];
									}
									
									if ([DicomFile isXMLDescriptedFile:srcPath])
									{
										if ([[NSFileManager defaultManager] fileExistsAtPath:[[srcPath stringByDeletingPathExtension] stringByAppendingString:@".xml"]])
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
								
								if ( result == YES )
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
				
				if ( [filesArray count] > 0 )
				{
					newFilesInIncoming = YES;
					
					if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ANONYMIZELISTENER"] == YES )
					{
						[self listenerAnonymizeFiles: filesArray];
					}
					
					for( id filter in [PluginManager preProcessPlugins] )
					{
						[filter processFiles: filesArray];
					}
					
					NSArray*	addedFiles = [[self addFilesToDatabase: filesArray]  valueForKey:@"completePath"];
					
					if( addedFiles)
					{
					}
					else	// Add failed.... Keep these files: move them back to the INCOMING folder and try again later....
					{
						NSString *dstPath;
						long x = 0;
						
						NSLog(@"Move the files back to the incoming folder...");
						
						for( NSString *file in filesArray )
						{
							do
							{
								dstPath = [INpath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", x]];
								x++;
							}
							while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
							
							[[NSFileManager defaultManager] movePath: file toPath: dstPath handler: nil];
						}
					}
					
					if( COMPRESSDICOMLISTENER )
					{
						if( [filesArray count] > 0 )
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
				
				if( [compressedPathArray count] > 0 )
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
		
		lastCheckIncoming  = [NSDate timeIntervalSinceReferenceDate];
		
		[pool release];
	}
	@catch (NSException * e)
	{
		NSLog( @"checkIncomingThread exception %@", e);
	}
}

- (void)setDockIcon
{
	NSImage	*image = nil;
	
	if( newFilesInIncoming) image = downloadingOsiriXIcon;
	else
	{
		image = standardOsiriXIcon;
		[[[NSApplication sharedApplication] dockTile] setBadgeLabel:@""];
	}
	
	if( currentIcon != image)
	{
		currentIcon = image;
		[[NSApplication sharedApplication] setApplicationIconImage: image];
		NSLog( @"dock icon set");
	}
}

- (void)checkIncomingNow: (id)sender
{
	if( isCurrentDatabaseBonjour) return;
	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
	if( managedObjectContext == nil) return;
	if( [NSDate timeIntervalSinceReferenceDate] - lastCheckIncoming < 0.5) return;
	
	[checkIncomingLock lock];
	[self checkIncomingThread: self];
	[checkIncomingLock unlock];
}

- (void)checkIncoming: (id)sender
{
	if( isCurrentDatabaseBonjour) return;
	if( DatabaseIsEdited == YES && [[self window] isKeyWindow] == YES) return;
	if( managedObjectContext == nil) return;
	if( [NSDate timeIntervalSinceReferenceDate] - lastCheckIncoming < 1) return;
	
	if( [checkIncomingLock tryLock] )
	{
		[NSThread detachNewThreadSelector: @selector( checkIncomingThread:) toTarget:self withObject: self];
		[checkIncomingLock unlock];
	}
	else
	{
		NSLog(@"checkIncoming locked...");
		newFilesInIncoming = YES;
	}
	
	[self setDockIcon];
}

- (void) createEmptyMovie:(NSMutableDictionary*) dict
{
	QTMovie	* e = [QTMovie movie];
	[dict setObject: e forKey:@"movie"];
	
	[e detachFromCurrentThread];
}

- (void) movieWithFile:(NSMutableDictionary*) dict
{
	QTMovie *e = [QTMovie movieWithFile:[dict objectForKey:@"file"] error:nil];
	[dict setObject: e forKey:@"movie"];
	
	[e detachFromCurrentThread];
}

- (void)writeMovie: (NSArray*)imagesArray name: (NSString*)fileName
{
	QTMovie *mMovie = nil;
	
	if( mainThread != [NSThread currentThread])
	{
		[QTMovie enterQTKitOnThread];
		
		NSMutableDictionary *dict;
		
		dict = [NSMutableDictionary dictionary];
		
		[self performSelectorOnMainThread: @selector( createEmptyMovie:) withObject: dict waitUntilDone: YES];
		
		QTMovie *empty = [dict objectForKey:@"movie"];
		
		[empty attachToCurrentThread];
		[empty writeToFile: [fileName stringByAppendingString:@"temp"] withAttributes: nil];
		[empty detachFromCurrentThread];
		
		dict = [NSMutableDictionary dictionaryWithObjectsAndKeys: [fileName stringByAppendingString:@"temp"], @"file", nil];
		[self performSelectorOnMainThread: @selector( movieWithFile:) withObject: dict waitUntilDone: YES];
		
		mMovie = [dict objectForKey:@"movie"];
		
		[mMovie attachToCurrentThread];
	}
	else
	{
		// Life is so much simplier in a single thread application...
		
		[[QTMovie movie] writeToFile: [fileName stringByAppendingString:@"temp"] withAttributes: nil];
		mMovie = [QTMovie movieWithFile:[fileName stringByAppendingString:@"temp"] error:nil];
	}
	
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	long long timeValue = 60;
	long timeScale = 600;
	
	QTTime curTime = QTMakeTime(timeValue, timeScale);
	
	NSMutableDictionary *myDict = [NSMutableDictionary dictionaryWithObject: @"jpeg" forKey: QTAddImageCodecType];
	
	for ( id img in imagesArray )
	{
		NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
		
		[mMovie addImage: img forDuration:curTime withAttributes: myDict];
		
		[pool release];
	}
	
	[mMovie writeToFile: fileName withAttributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: QTMovieFlatten]];
	[[NSFileManager defaultManager] removeFileAtPath:[fileName stringByAppendingString:@"temp"] handler: nil];

	if( mainThread != [NSThread currentThread])
	{
		[mMovie detachFromCurrentThread];
		[QTMovie exitQTKitOnThread];
	}
}

-(void) exportQuicktimeInt:(NSArray*) dicomFiles2Export :(NSString*) path :(BOOL) html
{
	Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", nil) :NO];
	NSMutableArray		*imagesArray = [NSMutableArray array];
	NSString			*tempPath, *previousPath = nil;
	long				previousSeries = -1;
	NSString			*previousStudy = @"";
	BOOL				createHTML = html;
	
	NSMutableDictionary *htmlExportDictionary = [NSMutableDictionary dictionary];
	
	[splash setCancel:YES];
	[splash showWindow:self];
	[[splash progress] setMaxValue:[dicomFiles2Export count]];
	
	[managedObjectContext lock];
	
	@try
	{
		BOOL first = YES;
		for( NSManagedObject *curImage in dicomFiles2Export )
		{
			
			NSString *conv = asciiString( [curImage valueForKeyPath: @"series.study.name"]);
			
			tempPath = [path stringByAppendingPathComponent: conv];
			
			NSMutableArray *htmlExportSeriesArray;
			if(![htmlExportDictionary objectForKey:[curImage valueForKeyPath: @"series.study.name"]])
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
				if( first )
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
			
			tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", asciiString( [curImage valueForKeyPath: @"series.study.studyName"]), [curImage valueForKeyPath: @"series.study.id"]]];
			if( [[curImage valueForKeyPath: @"series.study.id"] isEqualToString:previousStudy] == NO )
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
			
			if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue] )
			{
				if( [imagesArray count] > 1 )
				{
					[self writeMovie: imagesArray name: [previousPath stringByAppendingString:@".mov"]];
				}
				else if( [imagesArray count] == 1 )
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
						NSData *bitmapData = nil;
						NSArray *representations = [thumbnail representations];
						bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
						[bitmapData writeToFile:[tempPath stringByAppendingString:@"_thumb.jpg"] atomically:YES];
					}
				}
				
				[imagesArray removeAllObjects];
				previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
			}
			
			previousPath = [NSString stringWithString: tempPath];
			
			int frames = [[curImage valueForKey:@"numberOfFrames"] intValue];
			
			if( [curImage valueForKey:@"frameID"]) frames = 1;
			
			for (int x = 0; x < frames; x++)
			{
				int frame = x;
				
				if( [curImage valueForKey:@"frameID"])
					frame = [[curImage valueForKey:@"frameID"] intValue];
				
				DCMPix* dcmPix = [[DCMPix alloc] myinit: [curImage valueForKey:@"completePathResolved"] :0 :1 :nil :frame :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curImage];
				
				if( dcmPix )
				{
					float curWW = 0;
					float curWL = 0;
					
					if( [[curImage valueForKey:@"series"] valueForKey:@"windowWidth"] )
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
			}
			
			[splash incrementBy:1];
			
			if( [splash aborted] ) break;
		}
		
		if( [imagesArray count] > 1 )
		{
			[self writeMovie: imagesArray name: [previousPath stringByAppendingString:@".mov"]];
		}
		else if( [imagesArray count] == 1 )
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
			[htmlExport release];
		}
	}
	
	@catch (NSException * e)
	{
		NSLog( [e description]);
	}
	
	[managedObjectContext unlock];
	
	[splash close];
	[splash release];
}

- (void)exportQuicktime: (id)sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
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
	
	NSMutableArray *dicomFiles2Export = [NSMutableArray array];
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
	
	if ([sPanel runModalForDirectory:nil file:nil types:nil] == NSFileHandlingPanelOKButton )
	{
		NSString			*dest, *path = [[sPanel filenames] objectAtIndex:0];
		Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", nil)];
		BOOL				addDICOMDIR = [addDICOMDIRButton state];
		
		[splash setCancel:YES];
		[splash showWindow:self];
		[[splash progress] setMaxValue:[filesToExport count]];
		
		for( int i = 0; i < [filesToExport count]; i++ )
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
			NSString *extension = format;
			
			NSString *tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
			
			// Find the PATIENT folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath]) [[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			else
			{
				if( i == 0)	{
					if( NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@)", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), nil) == NSAlertDefaultReturn)
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
			
			int t = 2;
			while( [[NSFileManager defaultManager] fileExistsAtPath: dest] )
			{
				if (!addDICOMDIR)
					dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d #%d.%@", tempPath, serieCount, imageNo, t, extension];
				else
					dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, t];
				t++;
			}
			
			DCMPix* dcmPix = [[DCMPix alloc] myinit: [curImage valueForKey:@"completePathResolved"] :0 :1 :nil :[[curImage valueForKey:@"frameID"] intValue] :[[curImage valueForKeyPath:@"series.id"] intValue] isBonjour:isCurrentDatabaseBonjour imageObj:curImage];
			
			if( dcmPix )
			{
				float curWW = 0;
				float curWL = 0;
				
				if( [[curImage valueForKey:@"series"] valueForKey:@"windowWidth"] )
				{
					curWW = [[[curImage valueForKey:@"series"] valueForKey:@"windowWidth"] floatValue];
					curWL = [[[curImage valueForKey:@"series"] valueForKey:@"windowLevel"] floatValue];
				}
				
				if( curWW != 0 && curWW !=curWL)
					[dcmPix checkImageAvailble :curWW :curWL];
				else
					[dcmPix checkImageAvailble :[dcmPix savedWW] :[dcmPix savedWL]];
				
				if( [format isEqualToString:@"jpg"] )
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
			
			[pool release];
		}
		
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

+ (void)replaceNotAdmitted: (NSMutableString*)name
{
	[name replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"." withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"," withString:@"" options:0 range:NSMakeRange(0, [name length])]; 
	[name replaceOccurrencesOfString:@"^" withString:@"" options:0 range:NSMakeRange(0, [name length])]; 
	[name replaceOccurrencesOfString:@"/" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"\\" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"|" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@":" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"*" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0, [name length])];
	[name replaceOccurrencesOfString:@"?" withString:@"" options:0 range:NSMakeRange(0, [name length])];
}

- (void) importCommentsAndStatusFromDictionary:(NSDictionary*) d
{
	NSManagedObjectContext *context = self.managedObjectContext;
	
	[context lock];
	
	@try
	{
		NSFetchRequest	*dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[self.managedObjectModel entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithFormat:  @"studyInstanceUID == %@", [d valueForKey: @"studyInstanceUID"]]];
		
		NSError *error = nil;
		NSArray *studiesArray = [context executeFetchRequest:dbRequest error:&error];
		
		if( [studiesArray count])
		{
			DicomStudy *s = [studiesArray lastObject];
			
			if( [(NSString*) [d valueForKey: @"comment"] length])
				[s setValue: [d valueForKey: @"comment"] forKey: @"comment"];
			
			if( [[d valueForKey: @"stateText"] intValue])
				[s setValue: [d valueForKey: @"stateText"] forKey: @"stateText"];
			
			NSArray *series = [[s valueForKey:@"series"] allObjects];
			
			for( NSDictionary *ds in [d valueForKey: @"series"])
			{
				NSArray *ss = [series filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:  @"seriesInstanceUID == %@", [ds valueForKey: @"seriesInstanceUID"]]];
				
				if( [ss count])
				{
					if( [[ds valueForKey: @"stateText"] intValue])
						[[ss lastObject] setValue: [ds valueForKey: @"stateText"] forKey: @"stateText"];
					
					if( [(NSString*) [ds valueForKey: @"comment"] length])
						[[ss lastObject] setValue: [ds valueForKey: @"comment"] forKey: @"comment"];
				}
			}
		}
	}
	
	@catch (NSException * e)
	{
		NSLog( @"importCommentsAndStatusFromDictionary exception: %@", e);
	}
	
	[context unlock];
}

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
		}
		
		[context unlock];
	}
}

- (NSDictionary*) dictionaryWithCommentsAndStatus:(NSManagedObject *)s
{
	BOOL data = NO;
	NSMutableDictionary *studyDict = [NSMutableDictionary dictionary];
	@try
	{
		[studyDict setValue: [s valueForKey: @"studyInstanceUID"] forKey: @"studyInstanceUID"];
		
		if( [(NSString*) [s valueForKey: @"comment"] length]) data = YES;
		[studyDict setValue: [s valueForKey: @"comment"] forKey: @"comment"];
		
		if( [[s valueForKey: @"stateText"] intValue] ) data = YES;
		[studyDict setValue: [s valueForKey: @"stateText"] forKey: @"stateText"];
		
		NSMutableArray *seriesArray = [NSMutableArray array];
		for( DicomSeries *series in [[s valueForKey: @"series"] allObjects])
		{
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			
			if( [(NSString*) [series valueForKey: @"comment"] length]) data = YES;
			[dict setValue: [series valueForKey: @"comment"] forKey: @"comment"];
			
			if( [[series valueForKey: @"stateText"] intValue]) data = YES;
			[dict setValue: [series valueForKey: @"stateText"] forKey: @"stateText"];
			
			[dict setValue: [series valueForKey: @"seriesInstanceUID"] forKey: @"seriesInstanceUID"];
			
			[seriesArray addObject: dict];
		}
		
		[studyDict setObject: seriesArray forKey: @"series"];
	}
	
	@catch (NSException * e)
	{
		NSLog( @"dictionaryWithCommentsAndStatus exception: %@", e);
	}
	
	if( data)
		return studyDict;
	else
		return nil;
}

- (NSArray*)exportDICOMFileInt: (NSString*) location files: (NSMutableArray*)filesToExport objects: (NSMutableArray*)dicomFiles2Export
{
	[filesToExport removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Export];

	NSString			*dest, *path = location;
	Wait                *splash = [[Wait alloc] initWithString:NSLocalizedString(@"Export...", nil)];
	BOOL				addDICOMDIR = [addDICOMDIRButton state];
	long				previousSeries = -1;
	long				serieCount		= 0;
	NSMutableArray		*result = [NSMutableArray array];
	NSMutableArray		*files2Compress = [NSMutableArray array];
	BOOL				exportROIs = [[NSUserDefaults standardUserDefaults] boolForKey:@"AddROIsForExport"];
	DicomStudy			*previousStudy = nil;
	
	[splash setCancel:YES];
	[splash showWindow:self];
	[[splash progress] setMaxValue:[filesToExport count]];
	
	for( int i = 0; i < [filesToExport count]; i++ )
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSManagedObject	*curImage = [dicomFiles2Export objectAtIndex:i];
		NSString		*extension = [[filesToExport objectAtIndex:i] pathExtension];
		NSString		*roiFolder = nil;
		
		if( [curImage valueForKey: @"fileType"] )
		{
			if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"]) extension = [NSString stringWithString:@"dcm"];
		}
		
		NSArray	*roiFiles = nil;
		if( exportROIs)
			roiFiles = [curImage valueForKey: @"SRPaths"];
		
		if([extension isEqualToString:@""]) extension = [NSString stringWithString:@"dcm"]; 
		
		NSString *tempPath;
		// if creating DICOMDIR. Limit length to 8 char
		if (!addDICOMDIR)  
			tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
		else
		{
			NSMutableString *name;
			if ([(NSString*) [curImage valueForKeyPath: @"series.study.name"] length] > 8)
				name = [NSMutableString stringWithString:[[[curImage valueForKeyPath: @"series.study.name"] substringToIndex:7] uppercaseString]];
			else
				name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.name"] uppercaseString]];
			
			NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
			
			[BrowserController replaceNotAdmitted: name];
			
			tempPath = [path stringByAppendingPathComponent:name];
		}
		
		// Find the DICOM-PATIENT folder
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:tempPath] )
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			[result addObject: [tempPath lastPathComponent]];
		}
		else
		{
			if( i == 0 )
			{
				int a = NSRunInformationalAlertPanel( NSLocalizedString(@"Export", nil), [NSString stringWithFormat: NSLocalizedString(@"A folder already exists. Should I replace it? It will delete the entire content of this folder (%@), or merge the existing content with the new files?", nil), [tempPath lastPathComponent]], NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Merge", nil));
				
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
		
		if( [folderTree selectedTag] == 0 )
		{
			if (!addDICOMDIR)		
				tempPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat: @"%@ - %@", [curImage valueForKeyPath: @"series.study.studyName"], [curImage valueForKeyPath: @"series.study.id"]]];
			else
			{				
				NSMutableString *name;
				if ([(NSString*)[curImage valueForKeyPath: @"series.study.id"] length] > 8 )
					name = [NSMutableString stringWithString:[[[curImage valueForKeyPath:@"series.study.id"] substringToIndex:7] uppercaseString]];
				else
					name = [NSMutableString stringWithString:[[curImage valueForKeyPath: @"series.study.id"] uppercaseString]];
				
				NSData* asciiData = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
				name = [[[NSMutableString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
				
				[BrowserController replaceNotAdmitted: name];
				tempPath = [tempPath stringByAppendingPathComponent:name];
			}
			
			// Find the DICOM-STUDY folder
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
				[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
			
			studyPath = tempPath;
			
			// Find the ROIs folder
			if( [roiFiles count] )
			{
				roiFolder = [tempPath stringByAppendingPathComponent:@"ROI"];
				
				if (![[NSFileManager defaultManager] fileExistsAtPath: roiFolder]) [[NSFileManager defaultManager] createDirectoryAtPath: roiFolder attributes:nil];
			}
			
			if ( !addDICOMDIR )
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
			if (![[NSFileManager defaultManager] fileExistsAtPath:tempPath])
				[[NSFileManager defaultManager] createDirectoryAtPath:tempPath attributes:nil];
		}
		else studyPath = tempPath;
		
		if( previousStudy != [curImage valueForKeyPath: @"series.study"])
		{
			previousStudy = [curImage valueForKeyPath: @"series.study"];
			
			NSDictionary *commentsAndStatus = [self dictionaryWithCommentsAndStatus: previousStudy];
			
			if( commentsAndStatus)
			{
				[[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat:@"%@/CommentAndStatus.xml", studyPath]  handler: nil];
				[commentsAndStatus writeToFile: [NSString stringWithFormat:@"%@/CommentAndStatus.xml", studyPath] atomically: YES];
			}
			
			if( [previousStudy valueForKey:@"reportURL"])
			{
				NSString *extension = [[previousStudy valueForKey:@"reportURL"] pathExtension];
				
				NSString *filename;
				
				if( [extension length]) filename = [NSString stringWithFormat: @"report.%@", extension];
				else filename = @"report";
				
				if( [[NSFileManager defaultManager] fileExistsAtPath: [previousStudy valueForKey:@"reportURL"]])
				{
					[[NSFileManager defaultManager] removeFileAtPath: [NSString stringWithFormat:@"%@/%@", studyPath, filename]  handler: nil];
					[[NSFileManager defaultManager] copyPath: [previousStudy valueForKey:@"reportURL"] toPath: [NSString stringWithFormat:@"%@/%@", studyPath, filename] handler: nil];
					[[previousStudy valueForKey:@"studyInstanceUID"] writeToFile: [NSString stringWithFormat:@"%@/reportStudyUID.xml", studyPath] atomically: YES];
				}
			}
		}
		
		long imageNo = [[curImage valueForKey:@"instanceNumber"] intValue];
		
		if( previousSeries != [[curImage valueForKeyPath: @"series.id"] intValue] )
		{
			previousSeries = [[curImage valueForKeyPath: @"series.id"] intValue];
			serieCount++;
		}
		if (!addDICOMDIR )
			dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d.%@", tempPath, serieCount, imageNo, extension];
		else
			dest = [NSString stringWithFormat:@"%@/%4.4d%4.4d", tempPath, serieCount, imageNo];
		
		int t = 2;
		while( [[NSFileManager defaultManager] fileExistsAtPath: dest] )
		{
			if (!addDICOMDIR)
				dest = [NSString stringWithFormat:@"%@/IM-%4.4d-%4.4d #%d.%@", tempPath, serieCount, imageNo, t, extension];
			else
				dest = [NSString stringWithFormat:@"%@/%4.4d%d", tempPath,  imageNo, t];
			t++;
		}
		
		[[NSFileManager defaultManager] copyPath:[filesToExport objectAtIndex:i] toPath:dest handler:nil];
		
		if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"] )
		{
			switch( [compressionMatrix selectedTag] )
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
		
		if( [roiFiles count] )
		{
			for( NSString *roiFile in roiFiles )
			{
				NSString	*destROIPath = [roiFolder stringByAppendingPathComponent: [roiFile lastPathComponent]];
				
				if( addDICOMDIR)
					destROIPath = [[destROIPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: [NSString stringWithFormat:@"%4.4d", 1]];
				
				t = 2;
				while( [[NSFileManager defaultManager] fileExistsAtPath: destROIPath])
				{
					destROIPath = [[destROIPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: [NSString stringWithFormat:@"%4.4d", t]];
					t++;
				}
				
				[[NSFileManager defaultManager] copyPath: roiFile
												  toPath: destROIPath
												 handler: nil];
			}
		}
		
		[splash incrementBy:1];
		
		if( [splash aborted]) 
			i = [filesToExport count];
		
		[pool release];
	}
	
	if( [files2Compress count] > 0 )
	{
		switch( [compressionMatrix selectedTag] )
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
			
			if( [[NSFileManager defaultManager] fileExistsAtPath:[tempPath stringByAppendingPathComponent:@"DICOMDIR"]] == NO )
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
				
				[pool release];
			}
		}
	}
	
	//close progress window	
	[splash close];
	[splash release];
	
	return result;
}

- (void)exportDICOMFile: (id)sender
{
	NSOpenPanel			*sPanel			= [NSOpenPanel openPanel];
	
	[sPanel setCanChooseDirectories:YES];
	[sPanel setCanChooseFiles:NO];
	[sPanel setAllowsMultipleSelection:NO];
	[sPanel setMessage: NSLocalizedString(@"Select the location where to export the DICOM files:",nil)];
	[sPanel setPrompt: NSLocalizedString(@"Choose",nil)];
	[sPanel setTitle: NSLocalizedString(@"Export",nil)];
	[sPanel setCanCreateDirectories:YES];
	[sPanel setAccessoryView:exportAccessoryView];
	
	[compressionMatrix selectCellWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"Compression Mode for Export"]];
	
	if ([sPanel runModalForDirectory:nil file:nil types:nil] == NSFileHandlingPanelOKButton)
	{
		NSMutableArray *dicomFiles2Export = [NSMutableArray array];
		NSMutableArray *filesToExport;
		
		WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Preparing the files...", nil)];
		[wait showWindow:self];
		
		NSLog( [sender description]);
		[self checkResponder];
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix)
		{
			//Burn additional Files. Not just images. Add SRs
			filesToExport = [self filesForDatabaseMatrixSelection: dicomFiles2Export onlyImages:YES];
			NSLog(@"Files from contextual menu: %d", [filesToExport count]);
		}
		else filesToExport = [self filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages:YES];
		
		[wait close];
		[wait release];
		
		[self exportDICOMFileInt: [[sPanel filenames] objectAtIndex:0] files: filesToExport objects: dicomFiles2Export];
		
		[[NSUserDefaults standardUserDefaults] setInteger:[compressionMatrix selectedTag] forKey:@"Compression Mode for Export"];
	}
}

- (void) setBurnerWindowControllerToNIL
{
	burnerWindowController = nil;
}

- (BOOL) checkBurner
{
	if( burnerWindowController)
	{
		[[burnerWindowController window] makeKeyAndOrderFront: self];
		
		return NO;
	}
	
	return YES;
}

- (void)burnDICOM: (id)sender
{
	if( burnerWindowController == nil )
	{
		NSMutableArray *managedObjects = [NSMutableArray array];
		NSMutableArray *filesToBurn;
		//Burn additional Files. Not just images. Add SRs
		[self checkResponder];
		if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) filesToBurn = [self filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];
		else filesToBurn = [self filesForDatabaseOutlineSelection:managedObjects onlyImages:NO];
		
		[filesToBurn removeDuplicatedStringsInSyncWithThisArray: managedObjects];
		
		burnerWindowController = [[BurnerWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects];
		
		[burnerWindowController showWindow:self];
	}
	else
	{
		NSRunInformationalAlertPanel( NSLocalizedString(@"Burn", nil), NSLocalizedString(@"A burn session is already opened. Close it to burn a new study.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		[[burnerWindowController window] makeKeyAndOrderFront:self];
	}
}

- (IBAction)anonymizeDICOM: (id)sender
{
	NSMutableArray *paths = [NSMutableArray array];
	NSMutableArray *dicomFiles2Anonymize = [NSMutableArray array];
	NSMutableArray *filesToAnonymize;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) filesToAnonymize = [[self filesForDatabaseMatrixSelection: dicomFiles2Anonymize] retain];
	else filesToAnonymize = [[self filesForDatabaseOutlineSelection: dicomFiles2Anonymize] retain];
	
	[filesToAnonymize removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Anonymize];
	
    [anonymizerController showWindow:self];
	
	NSString *file;
	for (file in filesToAnonymize)
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
		if( self.albumTable.selectedRow > 0)
		{
			NSManagedObject *album = [self.albumArray objectAtIndex: [[self albumTable] selectedRow]];
			
			if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
			{
				NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];
				
				for( NSManagedObject *object in newImages)
				{
					[studies addObject: [object valueForKeyPath:@"series.study"]];
				}
				
				[self outlineViewRefresh];
			}
		}
		
		if( [newImages count] > 0 )
		{
			NSManagedObject *object = [[newImages objectAtIndex: 0] valueForKeyPath:@"series.study"];
			
			[databaseOutline selectRow: [databaseOutline rowForItem: object] byExtendingSelection: NO];
			[databaseOutline scrollRowToVisible: [databaseOutline selectedRow]];
		}
	}
	
	[filesToAnonymize release];
}	

- (void) unmountPath:(NSString*) path
{
	[bonjourServicesList display];
	
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
				unsigned long finalTicks;
				Delay( 60, &finalTicks);
			}
			else success = YES;
		}
	}
	
	[path release];
	
	[bonjourServicesList display];
	[bonjourServicesList setNeedsDisplay];
	
	if( attempts == 5 )
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Failed", nil), NSLocalizedString(@"Unable to unmount this disk. This disk is probably in used by another application.", nil), NSLocalizedString(@"OK",nil),nil, nil);
	}
}

- (void)AlternateButtonPressed: (NSNotification*)n
{
	int i = [bonjourServicesList selectedRow];
	if( i > 0 )
	{
		NSString *path = [[[[bonjourBrowser services] objectAtIndex: i-1] valueForKey:@"Path"] retain];
	
		[self resetToLocalDatabase];
		
		[self performSelector:@selector(unmountPath:) withObject:path afterDelay:0.2];
	}
}

- (void)loadDICOMFromiPod
{
	NSArray *allVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	NSString	*defaultPath = documentsDirectoryFor( [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"], [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]);
	
	for ( NSString *path in allVolumes)
	{
		NSString *iPodControlPath = [path stringByAppendingPathComponent:@"iPod_Control"];
		BOOL isItAnIpod = [[NSFileManager defaultManager] fileExistsAtPath:iPodControlPath];
		BOOL isThereAnOsiriXDataAtTheRoot = [[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent:@"OsiriX Data"]];
		
		if( isItAnIpod || isThereAnOsiriXDataAtTheRoot)
		{
			if( [path isEqualToString: defaultPath] == NO && [[path stringByAppendingPathComponent:@"OsiriX Data"] isEqualToString: defaultPath] == NO)
			{
				NSString *volumeName = [path lastPathComponent];
				
				NSLog(@"Got a volume named %@", volumeName);
							
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
					
					if( selectedDict )
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
}

- (void)loadDICOMFromiDisk: (id)sender
{
	if( isCurrentDatabaseBonjour ) return;
	
	int delete = 0;

	if( NSRunInformationalAlertPanel( NSLocalizedString(@"iDisk", nil), NSLocalizedString(@"Should I delete the files on the iDisk after the copy?", nil), NSLocalizedString(@"Delete the files", nil), NSLocalizedString(@"Leave them", nil), nil) == NSAlertDefaultReturn)
	{
		delete = 1;
	}
	else
	{
		delete = 0;
	}
	
	WaitRendering *wait = [[WaitRendering alloc] init: [NSString stringWithFormat: NSLocalizedString(@"Receiving files from iDisk", nil)]];
	[wait showWindow:self];
	
	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects: @"getFilesFromiDisk", [NSString stringWithFormat:@"%d", delete], nil]];
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
	
	NSArray	*filesArray = [NSArray arrayWithContentsOfFile: @"/tmp/files2load"];
	
	if( [filesArray count])
	{
		NSString *incomingFolder = [[self documentsDirectory] stringByAppendingPathComponent:INCOMINGPATH];
		
		for( NSString *path in filesArray)
		{
			[[NSFileManager defaultManager] movePath: path toPath: [incomingFolder stringByAppendingPathComponent: [path lastPathComponent]] handler: nil];
		}
	}
	
	[wait close];
	[wait release];
}

- (IBAction)sendiDisk: (id)sender
{
	int					success;
	
	// Copy the files!

	NSMutableArray *dicomFiles2Copy = [NSMutableArray array];
	NSMutableArray *files2Copy;
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) files2Copy = [self filesForDatabaseMatrixSelection: dicomFiles2Copy];
	else files2Copy = [self filesForDatabaseOutlineSelection: dicomFiles2Copy];
	
	[files2Copy removeDuplicatedStringsInSyncWithThisArray: dicomFiles2Copy];
	
	if( files2Copy )
	{
		NSMutableArray	*directories2copy = [NSMutableArray array];
		
		NSString *path = @"/tmp/folder2send2iDisk/";
		
		[[NSFileManager defaultManager] removeFileAtPath: path handler: nil];
		[[NSFileManager defaultManager] createDirectoryAtPath: path attributes: nil];
		
		for( int x = 0 ; x < [files2Copy count]; x++ )
		{
			NSString			*dstPath, *srcPath = [files2Copy objectAtIndex:x];
			NSString			*extension = [srcPath pathExtension];
			NSString			*tempPath;
			NSManagedObject		*curImage = [dicomFiles2Copy objectAtIndex:x];
			
			if([curImage valueForKey: @"fileType"] )
			{
				if( [[curImage valueForKey: @"fileType"] hasPrefix:@"DICOM"] )
					extension = [NSString stringWithString:@"dcm"];
			}
			
			if([extension isEqualToString:@""] )
				extension = [NSString stringWithString:@"dcm"];
			
			tempPath = [path stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.name"]];
			
			// Find the DICOM-PATIENT folder
			if( [[NSFileManager defaultManager] fileExistsAtPath: tempPath] == NO)
			{
				success = [[NSFileManager defaultManager] createDirectoryAtPath: tempPath attributes: nil];
				NSLog( @"success = %d", success);
				[directories2copy addObject: tempPath];
			}
			
			tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.study.studyName"] ];
			
			success = [[NSFileManager defaultManager] createDirectoryAtPath: tempPath attributes: nil];
			NSLog( @"success = %d %@", success, tempPath);
			
			tempPath = [tempPath stringByAppendingPathComponent:[curImage valueForKeyPath: @"series.name"] ];
			
			tempPath = [tempPath stringByAppendingFormat:@"_%@", [curImage valueForKeyPath: @"series.id"]];
			
			success = [[NSFileManager defaultManager] createDirectoryAtPath: tempPath attributes: nil];
			NSLog( @"success = %d %@", success, tempPath);
			
			dstPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat:@"%d.%@", [[curImage valueForKey:@"instanceNumber"] intValue], extension]];
			
			long t = 2;
			while( [[NSFileManager defaultManager] fileExistsAtPath: dstPath] )
			{
				dstPath = [tempPath stringByAppendingPathComponent: [NSString stringWithFormat:@"%d #%d.%@", [[curImage valueForKey:@"instanceNumber"] intValue], t, extension]];
				t++;
			}
					
			success = [[NSFileManager defaultManager] copyPath:srcPath toPath:dstPath handler: nil];
			NSLog( @"success = %d %@", success, dstPath);
					
			if( [extension isEqualToString:@"hdr"])		// ANALYZE -> COPY IMG
			{
				[[NSFileManager defaultManager] copyPath:[[srcPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] toPath:[[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"] handler: nil];
			}
		}
		
		[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/files2send" handler: nil];
		[directories2copy writeToFile: @"/tmp/files2send" atomically: YES];
		
		NSTask *theTask = [[NSTask alloc] init];
		
		long fileSize = 0;
		
		for( NSString *file in files2Copy)
			fileSize += [[[[NSFileManager defaultManager] fileAttributesAtPath:file traverseLink: YES] objectForKey:NSFileSize] longLongValue];
		
		fileSize /= 1024;
		fileSize /= 1024;
		
		WaitRendering *wait = [[WaitRendering alloc] init: [NSString stringWithFormat: NSLocalizedString(@"Sending files (%d files, %d MB) to iDisk", nil), [files2Copy count], fileSize]];
		[wait showWindow:self];
		
		[theTask setArguments: [NSArray arrayWithObjects: @"sendFilesToiDisk", @"/tmp/files2send", nil]];
		[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
		[theTask launch];
		[theTask waitUntilExit];
		[theTask release];
		
		[wait close];
		[wait release];
		
		for( NSString *directoryPath in directories2copy)
			[[NSFileManager defaultManager] removeFileAtPath: directoryPath handler: nil];
	}
}

- (void)selectServer: (NSArray*)objects
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
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) files = [self filesForDatabaseMatrixSelection:objects onlyImages: YES];
	else files = [self filesForDatabaseOutlineSelection:objects onlyImages: YES];
	
	[files removeDuplicatedStringsInSyncWithThisArray: objects];
	
	[self selectServer: objects];
}

- (IBAction)querySelectedStudy: (id)sender
{
	[self.window makeKeyAndOrderFront:sender];
	
    if( [QueryController currentQueryController] == nil) [[QueryController alloc] init];
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

- (void)queryDICOM: (id)sender
{
	if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)	// Query selected patient
		[self querySelectedStudy: self];
	else
	{
		[self.window makeKeyAndOrderFront:sender];
		
		if(![QueryController currentQueryController]) [[QueryController alloc] init];
		else [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"updateServers"];
		
		[[QueryController currentQueryController] showWindow:self];
	}
}

-(void)volumeMount: (NSNotification *)notification
{
	NSLog(@"volume mounted");
	
	[self loadDICOMFromiPod];
	
	if( isCurrentDatabaseBonjour) return;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"MOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	
	NSLog( sNewDrive);
	
	if( [BrowserController isItCD: sNewDrive] == YES )
	{
		[self ReadDicomCDRom: nil];
	}
	
	[self displayBonjourServices];
}

- (void)removeAllMounted
{
	if( isCurrentDatabaseBonjour) return;
	
	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = self.managedObjectContext;
	NSManagedObjectModel		*model = self.managedObjectModel;
	
	[context retain];
	[context lock];
	
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
	[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
	NSError	*error = nil;
	NSArray *seriesArray = [[context executeFetchRequest:dbRequest error:&error] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
	
	@try
	{
		if( [seriesArray count] > 0 )
		{
			NSMutableArray			*viewersList = [ViewerController getDisplayed2DViewers];
			
			// Find unavailable files
			for( NSManagedObject *study in seriesArray )
			{
				
				// Is a viewer containing this study opened? -> close it
				for( ViewerController *vc in viewersList )
				{
					if( study == [[[vc fileList] objectAtIndex: 0] valueForKeyPath:@"series.study"] )
					{
						[vc.window close];
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
		NSLog( ne.description );
	}
	
	[context unlock];
	[context release];
}

- (void)willVolumeUnmount: (NSNotification *)notification
{
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];
	
	// Is it an iPod?
	if ([[NSFileManager defaultManager] fileExistsAtPath: [sNewDrive stringByAppendingPathComponent:@"iPod_Control"]] )
	{
		// Is it currently selected? -> switch back to default DB path
		int row = [bonjourServicesList selectedRow];
		if( row > 0 )
		{
			if( [[[[bonjourBrowser services] objectAtIndex: row-1] valueForKey:@"Path"] isEqualToString: sNewDrive])
				[self resetToLocalDatabase];
		}
		
		// Remove it from the Source list
		
		int z = self.currentBonjourService;
		NSDictionary	*selectedDict = nil;
		if( z >= 0 ) selectedDict = [[[bonjourBrowser services] objectAtIndex: z] retain];
		
		for( int x = 0; x < [[bonjourBrowser services] count]; x++ )
		{
			NSDictionary	*c = [[bonjourBrowser services] objectAtIndex: x];
			
			if( [[c valueForKey:@"type"] isEqualToString:@"localPath"] )
			{
				if( [[c valueForKey:@"Path"] isEqualToString: sNewDrive] )
				{
					[[bonjourBrowser services] removeObjectAtIndex: x];
					x--;
				}
			}
		}
		
		if( selectedDict )
		{
			NSInteger index = [[bonjourBrowser services] indexOfObject: selectedDict];
			
			if( index == NSNotFound)
				[self resetToLocalDatabase];
			else
				[self setCurrentBonjourService: index];
			
			[selectedDict release];
		}
		[self displayBonjourServices];
	}
	
	
	if( [BrowserController isItCD: sNewDrive] == YES)
		checkForMountedFiles = YES;
	else
		checkForMountedFiles = NO;
	
	//Are we currently copying files from a CD (separate thread?) -> stop it !
	copyThread = NO;
}

- (void)volumeUnmount: (NSNotification *)notification
{
	BOOL		needsUpdate = NO;
	NSRange		range;
	
	if( isCurrentDatabaseBonjour) return;
	if( checkForMountedFiles == NO) return;
	
	NSLog(@"volume unmounted");
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"UNMOUNT"] == NO) return;
	
	NSString *sNewDrive = [[ notification userInfo] objectForKey : @"NSDevicePath"];	//uppercaseString];
	NSLog( sNewDrive);
	
	range.location = 0;
	range.length = [sNewDrive length];
	
	// FIND ALL images that ARENT local, and REMOVE non-available images
	NSManagedObjectContext		*context = self.managedObjectContext;
	NSManagedObjectModel		*model = self.managedObjectModel;
	
	if( [context tryLock])
	{
		[context retain];
		
		DatabaseIsEdited = YES;
		
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Series"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue: YES]];
		NSError	*error = nil;
		NSArray *seriesArray = [[context executeFetchRequest:dbRequest error:&error] filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"mountedVolume == YES"]];
		
		if( [seriesArray count] > 0 )
		{
			NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
			
			@try
			{
				// Find unavailable files
				for( int i = 0; i < [seriesArray count]; i++ )
				{
					NSManagedObject	*image = [[[seriesArray objectAtIndex:i] valueForKey:@"images"] anyObject];
					if( [[image  valueForKey:@"completePath"] compare:sNewDrive options:NSCaseInsensitiveSearch range:range] == 0 )
					{
						NSManagedObject	*study = [[seriesArray objectAtIndex:i] valueForKey:@"study"];
						
						needsUpdate = YES;
						
						// Is a viewer containing this study opened? -> close it
						for( ViewerController *vc in viewersList )
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
				NSLog( [ne description]);
			}
			
			if( needsUpdate )
			{
				[self saveDatabase: currentDatabasePath];
			}
			
			[self outlineViewRefresh];
			[self refreshMatrix: self];
		}
		
		[context unlock];
		[context release];
		
		DatabaseIsEdited = NO;
	}
	
	[self displayBonjourServices];
}

- (void)storeSCPComplete: (id)sender
{
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
			
			int spp;
			int highBit = 7;
			int bitsAllocated = 8;
			float numberBytes;
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
				for (i = 0; i < s; i++)
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
					
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:highBit]] forName:@"HighBit"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsAllocated"];
					[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsStored"];
					
					//add Pixel data
					NSString *vr = @"OW";
					if (numberBytes < 2)
						vr = @"OB";
					
					NSRange range = NSMakeRange([offset intValue] + subDataLength * i, subDataLength);
					NSMutableData *subdata = [NSMutableData dataWithData:[data subdataWithRange:range]];
					
					DCMTransferSyntax *ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
					if (isLittleEndian == NO)
					{
						if( isSigned == NO)
						{
							unsigned short *ptr = (unsigned short*) [subdata mutableBytes];
							int l = subDataLength/2;
							while( l-- > 0)
								ptr[ l] = EndianU16_BtoL( ptr[ l]);
						}
						else
						{
							short *ptr = ( short*) [subdata mutableBytes];
							int l = subDataLength/2;
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
					
					NSString	*tempFilename = [[self documentsDirectory] stringByAppendingFormat:@"/INCOMING.noindex/%d.dcm", i];
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
    XMLController * xmlController = [[XMLController alloc] initWithImage: [self firstObjectForDatabaseMatrixSelection] windowName:[NSString stringWithFormat:@"Meta-Data: %@", [[self firstObjectForDatabaseMatrixSelection] valueForKey:@"completePath"]] viewer: nil];
    
    [xmlController showWindow:self];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark RTSTRUCT

- (void)createROIsFromRTSTRUCT: (id)sender
{
	NSMutableArray *filesArray = [NSMutableArray array];
	NSMutableArray *filePaths = [self filesForDatabaseMatrixSelection: filesArray];
	
	for ( int i = 0; i < [filesArray count]; i++ )
	{
		NSString *modality = [[filesArray objectAtIndex: i] valueForKey: @"modality"];
		if ( [modality isEqualToString: @"RTSTRUCT"] )
		{
			DCMObject *dcmObj = [DCMObject objectWithContentsOfFile: [filePaths objectAtIndex: i ] decodingPixelData: NO];
			DCMPix *pix = [previewPix objectAtIndex: 0];  // Should only be one DCMPix associated w/ an RTSTRUCT
			
			[pix createROIsFromRTSTRUCT: dcmObj];
		}
	}
}

- (void)rtstructNotification: (NSNotification *)note
{
	BOOL visible = [[[note userInfo] objectForKey: @"RTSTRUCTProgressBar"] boolValue];
	if ( visible ) [self setRtstructProgressPercent: [[[note userInfo] objectForKey: @"RTSTRUCTProgressPercent"] floatValue]];
	[self setRtstructProgressBar: visible];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark -
#pragma mark Report functions

- (IBAction)srReports: (id)sende
{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];

	NSManagedObject *studySelected;
	
	if (item)
	{
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		if (structuredReportController)
			[structuredReportController release];
		
		structuredReportController = [[StructuredReportController alloc] initWithStudy:studySelected];
	}
}

- (void) syncReportsIfNecessary
{
	[self syncReportsIfNecessary: [bonjourServicesList selectedRow]-1];
}

- (void) syncReportsIfNecessary: (int)index
{
	if( isCurrentDatabaseBonjour)
	{
		NSEnumerator *enumerator = [bonjourReportFilesToCheck keyEnumerator];
		NSString *key;
		
		while ( (key = [enumerator nextObject]))
		{
			NSString	*file = [BonjourBrowser bonjour2local: key];
			
			BOOL isDirectory;
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: file isDirectory: &isDirectory])
			{
				NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: file traverseLink:YES];
				
				NSDate *previousDate = [bonjourReportFilesToCheck objectForKey: key];
				
				NSLog(@"file : %@", file);
				NSLog(@"Sync %@ : %@ - %@", key, [previousDate description], [[fattrs objectForKey:NSFileModificationDate] description]);
				
				if( [previousDate isEqualToDate: [fattrs objectForKey:NSFileModificationDate]] == NO )
				{
					NSLog(@"Sync %@ : %@ - %@", key, [previousDate description], [[fattrs objectForKey:NSFileModificationDate] description]);
					
					// The file has changed... send back a copy to the bonjour server
					
					if( [bonjourBrowser sendFile:file index: index])
					{
						[bonjourReportFilesToCheck setObject: [fattrs objectForKey:NSFileModificationDate] forKey: key];
						
						if( [[file pathExtension] isEqualToString: @"zip"])
							[[NSFileManager defaultManager] removeItemAtPath: file error: nil];
					}
				}
			}
			else NSLog( @"file?");
		}
	}
}

- (IBAction)deleteReport: (id)sender
{
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	
	if( item )
	{
		NSManagedObject *studySelected;
		
		[checkBonjourUpToDateThreadLock lock];
		
		if ([[[item entity] name] isEqual:@"Study"])
			studySelected = item;
		else
			studySelected = [item valueForKey:@"study"];
		
		long result = NSRunInformationalAlertPanel(NSLocalizedString(@"Delete report", nil), NSLocalizedString(@"Are you sure you want to delete the selected report?", nil), NSLocalizedString(@"OK",nil), NSLocalizedString(@"Cancel",nil), nil);
		
		if( result == NSAlertDefaultReturn)
		{
			if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue] == 3 )
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
			else if( [studySelected valueForKey:@"reportURL"] != nil )
			{
				if( isCurrentDatabaseBonjour )
				{
					[[NSFileManager defaultManager] removeFileAtPath:[BonjourBrowser bonjour2local: [studySelected valueForKey:@"reportURL"]] handler:nil];
					[bonjourReportFilesToCheck removeObjectForKey: [[studySelected valueForKey:@"reportURL"] lastPathComponent]];
					
					// Set only LAST component -> the bonjour server will complete the address
					[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:studySelected value:nil forKey:@"reportURL"];
					
					[studySelected setValue: nil forKey:@"reportURL"];
				}
				else
				{
					[[NSFileManager defaultManager] removeFileAtPath:[studySelected valueForKey:@"reportURL"] handler:nil];
					[studySelected setValue: nil forKey:@"reportURL"];
				}
				[databaseOutline reloadData];
			}
			else if( [[item valueForKey:@"reportSeries"] count])
			{
				NSManagedObjectContext	*context = self.managedObjectContext;
				
				[context lock];
				
				NSArray *array = [item valueForKey:@"reportSeries"];
				
				for( NSManagedObject *o in array)
					[context deleteObject: o];
				
				[context unlock];
				
				[self saveDatabase: currentDatabasePath];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"OsirixDeletedReport" object:nil userInfo:nil];
		}
		
		[checkBonjourUpToDateThreadLock unlock];
		[self updateReportToolbarIcon:nil];
	}
}

- (IBAction) generateReport: (id)sender
{
	[self updateReportToolbarIcon:nil];
	NSIndexSet			*index = [databaseOutline selectedRowIndexes];
	NSManagedObject		*item = [databaseOutline itemAtRow:[index firstIndex]];
	int reportsMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSMODE"] intValue];
	if( item)
	{
		if( reportsMode == 0 && [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Microsoft Word"] == nil) // Would absolutePathForAppBundleWithIdentifier be better here? (DDP)
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
			NSBundle *plugin = [[PluginManager reportPlugins] objectForKey: [[NSUserDefaults standardUserDefaults] stringForKey:@"REPORTSPLUGIN"]];
			
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
			
			@try
			{
				if( isCurrentDatabaseBonjour)
				{
					NSString	*localFile = nil;
					
					if( isCurrentDatabaseBonjour)
					{
						if( [item valueForKey:@"reportURL"])
							[[NSFileManager defaultManager] removeItemAtPath: [BonjourBrowser bonjour2local: [item valueForKey:@"reportURL"]]	error: nil];
					}
					
					if( [item valueForKey:@"reportURL"])
						localFile = [bonjourBrowser getFile:[item valueForKey:@"reportURL"] index:[bonjourServicesList selectedRow]-1];
					
					if( localFile != nil && [[NSFileManager defaultManager] fileExistsAtPath: localFile] == YES)
					{
						if (reportsMode < 3)
							[[NSWorkspace sharedWorkspace] openFile: localFile];
						else
						{
							//structured report code here
							//Osirix will open DICOM Structured Reports
						}
					}
					else
					{
						Reports	*report = [[Reports alloc] init];
						
						[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/TEMP/", [self documentsDirectory]] type:reportsMode];
						
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
					if( [studySelected valueForKey:@"reportURL"] != nil && [[NSFileManager defaultManager] fileExistsAtPath:[studySelected valueForKey:@"reportURL"]] == YES)
					{
						if (reportsMode < 3)
							[[NSWorkspace sharedWorkspace] openFile: [studySelected valueForKey:@"reportURL"]];
						else
						{
							//structured report code here
							//Osirix will open DICOM Structured Reports
							//Release Old Controller
							[self srReports:sender];
						}
					}
					else
					{
						if (reportsMode < 3)
						{
							Reports	*report = [[Reports alloc] init];
							if([[sender class] isEqualTo:[reportTemplatesListPopUpButton class]])[report setTemplateName:[[sender selectedItem] title]];
							[report createNewReport: studySelected destination: [NSString stringWithFormat: @"%@/REPORTS/", [self documentsDirectory]] type:reportsMode];					
							[report release];
						}
						else
						{
							//structured report code here
							//Osirix will open DICOM Structured Reports
							//Release Old Controller
							[self srReports:sender];
						}
					}
				}
			}
			@catch (NSException * e)
			{
				NSLog( @"Generate Report: %@", [e description]);
			}
			
			[checkBonjourUpToDateThreadLock unlock];
		}
	}
	[self updateReportToolbarIcon:nil];
}

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
		
		for( int i=0; i<[toolbarItems count]; i++ )
		{
			item = [toolbarItems objectAtIndex:i];
			if ([[item itemIdentifier] isEqualToString:ReportToolbarItemIdentifier] )
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
			if( [[NSFileManager defaultManager] fileExistsAtPath: [studySelected valueForKey: @"reportURL"]])
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
}

- (void)reportToolbarItemWillPopUp: (NSNotification *)notif
{
	if([[notif object] isEqualTo:reportTemplatesListPopUpButton] )
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

- (void)windowDidResignKey:(NSNotification *)notification
{
	DatabaseIsEdited = NO;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self flagsChanged: 0L];
}

- (void) flagsChanged:(NSEvent *)event
{
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
}

- (void)drawerToggle: (id)sender
{
    NSDrawerState state = [albumDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state)
        [albumDrawer close];
	else
        [albumDrawer openOnEdge:NSMinXEdge];
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
    else if ([itemIdent isEqualToString: ExportToolbarItemIdentifier])
	{
        
		[toolbarItem setLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Export",nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Export selected study/series to a DICOM folder",@"Export selected study/series to a DICOM folder")];
		[toolbarItem setImage: [NSImage imageNamed: ExportToolbarItemIdentifier]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(exportDICOMFile:)];
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
		if( [[PluginManager pluginsDict] objectForKey: itemIdent] != nil )
		{
			NSBundle *bundle = [[PluginManager pluginsDict] objectForKey: itemIdent];
			NSDictionary *info = [bundle infoDictionary];
			
			[toolbarItem setLabel: itemIdent];
			[toolbarItem setPaletteLabel: itemIdent];
			NSDictionary* toolTips = [info objectForKey: @"ToolbarToolTips"];
			if( toolTips )
				[toolbarItem setToolTip: [toolTips objectForKey: itemIdent]];
			else
				[toolbarItem setToolTip: itemIdent];
			
			//			NSLog( @"ICON:");
			//			NSLog( [info objectForKey:@"ToolbarIcon"]);
			
			NSImage	*image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"ToolbarIcon"]]] autorelease];
			if( !image ) image = [[NSWorkspace sharedWorkspace] iconForFile: [bundle bundlePath]];
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
			ImportToolbarItemIdentifier,
			ExportToolbarItemIdentifier,
			CDRomToolbarItemIdentifier,
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
			 SearchToolbarItemIdentifier,
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
	
	for( NSString *plugin in allPlugins )
	{
		if ([plugin isEqualToString: @"(-"])
			continue;
		
		NSBundle		*bundle = [[PluginManager pluginsDict] objectForKey: plugin];
		NSDictionary	*info = [bundle infoDictionary];
		
		if( [[info objectForKey: @"pluginType"] isEqualToString: @"Database"] == YES )
		{
			id allowToolbarIcon = [info objectForKey: @"allowToolbarIcon"];
			if( allowToolbarIcon )
			{
				if( [allowToolbarIcon boolValue] == YES )
				{
					NSArray* toolbarNames = [info objectForKey: @"ToolbarNames"];
					if( toolbarNames )
					{
						if( [toolbarNames containsObject: plugin] )
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
	
	if( [[addedItem itemIdentifier] isEqualToString:SearchToolbarItemIdentifier] )
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
	NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];

	if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
	{
		NSMutableArray	*filesArray = [NSMutableArray array];
		
		for( DicomImage *o in selectedItems)
		{
			NSString	*str = [o SRPathForFrame: 0];
			[filesArray addObject: [str lastPathComponent]];
		}
		[[BrowserController currentBrowser] getDICOMROIFiles: filesArray];
	}

	NSMutableArray *roisImagesArray = [NSMutableArray array];

	if( [selectedItems count] > 0)
	{
		for( DicomImage *image in selectedItems)
		{
			NSString	*str = [image SRPathForFrame: 0];
			
			if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
			{
				NSString	*imagePath = [BonjourBrowser uniqueLocalPath: image];
				str = [[imagePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: [str lastPathComponent]];
			}
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: str])
				[roisImagesArray addObject: image];
			else if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
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
	}
	else
	{
		NSRunInformationalAlertPanel(NSLocalizedString(@"ROIs Images", nil), NSLocalizedString(@"No images containing ROIs or Key Images are found in this selection.", nil), NSLocalizedString(@"OK",nil), nil, nil);
	}
}

- (NSArray*) ROIImages: (id) sender sameSeries:(BOOL*) sameSeries
{
	NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];

	if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
	{
		NSMutableArray	*filesArray = [NSMutableArray array];
		
		for( DicomImage *o in selectedItems)
		{
			NSString	*str = [o SRPathForFrame: 0];
			[filesArray addObject: [str lastPathComponent]];
		}
		[[BrowserController currentBrowser] getDICOMROIFiles: filesArray];
	}

	NSMutableArray *roisImagesArray = [NSMutableArray array];

	if( [selectedItems count] > 0)
	{
		for( DicomImage *image in selectedItems)
		{
			NSString	*str = [image SRPathForFrame: 0];
			
			if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
			{
				NSString	*imagePath = [BonjourBrowser uniqueLocalPath: image];
				str = [[imagePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: [str lastPathComponent]];
			}
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: str])
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
	NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity:0];
	
	[self checkResponder];
	if( ([sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu]) || [[self window] firstResponder] == oMatrix) [self filesForDatabaseMatrixSelection: selectedItems];
	else [self filesForDatabaseOutlineSelection: selectedItems];
	
	NSMutableArray *keyImagesArray = [NSMutableArray array];
	
	for( NSManagedObject *image in selectedItems )
	{					
		if( [[image valueForKey:@"isKeyImage"] boolValue] == YES)
			[keyImagesArray addObject: image];
	}
	
	return keyImagesArray;
}

- (BOOL)validateToolbarItem: (NSToolbarItem *)toolbarItem
{
	if( isCurrentDatabaseBonjour )
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
		return ROIsAndKeyImagesButtonAvailable;
	}
	
    return YES;
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Bonjour

- (void) getDICOMROIFiles:(NSArray*) files
{
	[bonjourBrowser getDICOMROIFiles:[bonjourServicesList selectedRow]-1 roisPaths:files];
}

- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key
{
	[bonjourBrowser setBonjourDatabaseValue:[bonjourServicesList selectedRow]-1 item:obj value:value forKey:key];
}

- (NSString*) bonjourPassword
{
	if( [bonjourPasswordCheck state] == NSOnState) return [bonjourPassword stringValue];
	else return nil;
}

- (NSString*) askPassword
{
	[password setStringValue:@""];
	
	[NSApp beginSheet:	bonjourPasswordWindow
	   modalForWindow: self.window
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

- (long)currentBonjourService
{ return [bonjourServicesList selectedRow] - 1; }

- (void)setCurrentBonjourService: (int)index
{
	dontLoadSelectionSource = YES;
	[bonjourServicesList selectRow: index+1 byExtendingSelection: NO];
	dontLoadSelectionSource = NO;
}

- (NSString*)getLocalDCMPath: (NSManagedObject*)obj : (long)no
{
	if( isCurrentDatabaseBonjour) return [bonjourBrowser getDICOMFile: [bonjourServicesList selectedRow]-1 forObject: obj noOfImages: no];
	else return [obj valueForKey:@"completePath"];
}

- (NSString*)defaultSharingName
{
	char s[_POSIX_HOST_NAME_MAX+1];
	gethostname(s,_POSIX_HOST_NAME_MAX);
	NSString *c = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
	NSRange range = [c rangeOfString: @"."];
	if( range.location != NSNotFound) c = [c substringToIndex: range.location];
	
	return c;
}

- (NSString*) serviceName
{
	return [bonjourPublisher serviceName];
}

- (void)setServiceName: (NSString*)title
{
	if( title && [title length] > 0 )
		[bonjourPublisher setServiceName: title];
	else
	{
		[bonjourPublisher setServiceName: [self defaultSharingName]];
		[bonjourServiceName setStringValue: [self defaultSharingName]];
	}
}

- (IBAction)toggleBonjourSharing: (id)sender
{
	[self setBonjourSharingEnabled:([sender state] == NSOnState)];
	
	[self switchToDefaultDBIfNeeded];
}

- (void)setBonjourSharingEnabled:(BOOL)boo
{
	[self setServiceName: [bonjourServiceName stringValue]];
	[bonjourPublisher toggleSharing:boo];
}

- (void)bonjourWillPublish
{
	[bonjourServiceName setEnabled:NO];
}

- (void)bonjourDidStop
{
	[bonjourServiceName setEnabled:YES];
	
	if( [bonjourSharingCheck state] == NSOnState)
	{
		NSLog(@"**** Bonjour did stop ! Restarting it!");
		[self setBonjourSharingEnabled: YES];
	}
}

- (void)displayBonjourServices
{
	[bonjourServicesList reloadData];
}

- (void)resetToLocalDatabase 
{
	[bonjourServicesList selectRow:0 byExtendingSelection:NO];
	[self bonjourServiceClicked: bonjourServicesList];
}

- (void) switchToDefaultDBIfNeeded
{
	NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
	
	if( [[self documentsDirectory] isEqualToString: defaultPath] == NO)
		[self resetToLocalDatabase];
}

- (void)openDatabasePath: (NSString*)path
{
	BOOL isDirectory;
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory])
	{
		if( isDirectory)
		{
			[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey:@"DATABASELOCATION"];
			[[NSUserDefaults standardUserDefaults] setObject: path forKey:@"DATABASELOCATIONURL"];
			
			[self openDatabaseIn: [[self documentsDirectory] stringByAppendingPathComponent:@"/Database.sql"] Bonjour: NO];
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

- (IBAction)bonjourServiceClickedProceed: (id)sender
{
	if( [bonjourServicesList selectedRow] == -1) return;
	
	dontLoadSelectionSource = YES;
	
	[self saveDatabase:currentDatabasePath];
	
    int index = [bonjourServicesList selectedRow]-1;
	
	[bonjourReportFilesToCheck removeAllObjects];
	
	if( index >= 0)
	{
		NSDictionary *object = [[bonjourBrowser services] objectAtIndex: index];
		
		// DICOM DESTINATION
		if( [[object valueForKey: @"type"] isEqualToString:@"dicomDestination"])
		{
			NSRunAlertPanel( NSLocalizedString(@"DICOM Destination", nil), NSLocalizedString(@"It is a DICOM destination node: you cannot browse its content. You can only drag & drop studies on them.", nil), nil, nil, nil);
			
			[bonjourServicesList selectRow: previousBonjourIndex+1 byExtendingSelection:NO];
		}
		// LOCAL PATH - DATABASE
		else if( [[object valueForKey: @"type"] isEqualToString:@"localPath"])
		{
			[self openDatabasePath: [object valueForKey: @"Path"]];
		}
		else	// NETWORK - DATABASE - bonjour / fixedIP
		{
			displayEmptyDatabase = YES;
			[self outlineViewRefresh];
			[self refreshMatrix: self];
			
			NSString	*path = [bonjourBrowser getDatabaseFile: index showWaitingWindow: YES];
						
			if( path == nil || [path isEqualToString: @"aborted"])
			{
				if( [path isEqualToString: @"aborted"]) NSLog( @"Transfer aborted");
				else NSRunAlertPanel( NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot connect to the database.", nil), nil, nil, nil);
				
				[[BrowserController currentBrowser] resetToLocalDatabase];
			}
			else
			{
				NSLog(@"Bonjour DB = %@", path);
				
				[segmentedAlbumButton setEnabled: NO];
				
				[self openDatabaseIn: path Bonjour: YES];
			}
			
			displayEmptyDatabase = NO;
		}
	}
	else // LOCAL DEFAULT DATABASE
	{
		[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
		[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
		
		NSString	*path = [[self documentsDirectory] stringByAppendingPathComponent:DATAFILEPATH];
		
		[segmentedAlbumButton setEnabled: YES];
		
		if( [path isEqualToString: currentDatabasePath] == NO)
			[self openDatabaseIn: path Bonjour: NO];
	}
	
	[self setSearchString:nil];
	previousBonjourIndex = [bonjourServicesList selectedRow]-1;
	
	dontLoadSelectionSource = NO;
}

- (IBAction)bonjourServiceClicked: (id)sender
{
	[self syncReportsIfNecessary: previousBonjourIndex];
	[albumNoOfStudiesCache removeAllObjects];
	
	[[AppController sharedAppController] closeAllViewers: self];	
	
	[self waitForRunningProcesses];
	[bonjourBrowser waitTheLock];
	
	[self performSelector:@selector( bonjourServiceClickedProceed:) withObject: sender afterDelay: 0.01];
}

- (NSString*) localDatabasePath
{
	return [[self documentsDirectory] stringByAppendingPathComponent:DATAFILEPATH];
}

//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

#pragma mark-
#pragma mark Plugins

- (void)executeFilterFromString: (NSString*)name
{
	long			result;
    id				filter = [[PluginManager plugins] objectForKey:name];
	
	if (filter==nil)
	{
		NSRunAlertPanel(NSLocalizedString(@"Plugins Error", nil), NSLocalizedString(@"OsiriX cannot launch the selected plugin.", nil), nil, nil, nil);
		return;
	}
	
	result = [filter prepareFilter: nil];
	[filter filterImage:name];
	NSLog(@"executeFilter %@", [filter description]);
	if( result )	{
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

- (NSString *)setFixedDocumentsDirectory
{
	[fixedDocumentsDirectory release];
	fixedDocumentsDirectory = [[self documentsDirectory] retain];
	
	if( fixedDocumentsDirectory == nil)
	{
		NSRunAlertPanel( NSLocalizedString(@"Database Location Error", nil), NSLocalizedString(@"Cannot locate Database path.", nil), nil, nil, nil);
		exit(0);
	}
	
	strcpy( cfixedDocumentsDirectory, [fixedDocumentsDirectory UTF8String]);
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"addNewIncomingFilesToDefaultDBOnly"])
	{
		NSString *defaultPath = [self documentsDirectoryFor: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] url: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"]];
		strcpy( cfixedIncomingDirectory, [defaultPath UTF8String]);
	}
	else strcpy( cfixedIncomingDirectory, [fixedDocumentsDirectory UTF8String]);
	
	return fixedDocumentsDirectory;
}

- (NSString *)fixedDocumentsDirectory
{
	if( fixedDocumentsDirectory == nil) [self setFixedDocumentsDirectory];
	return fixedDocumentsDirectory;
}

- (char *)cfixedDocumentsDirectory
{ return cfixedDocumentsDirectory; }

- (char *)cfixedIncomingDirectory
{ return cfixedIncomingDirectory;}

- (NSString *)documentsDirectory
{
	NSString *dir = documentsDirectory();
	return dir;
}

- (NSString *) documentsDirectoryFor:(int) mode url:(NSString*) url
{
	NSString	*dir = documentsDirectoryFor( mode, url);
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
	if( [databaseOutline selectedRow] != -1 )
	{
		NSManagedObject   *aFile = [databaseOutline itemAtRow:[databaseOutline selectedRow]];
		
		if( aFile )
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
	//NSLog(@"set Filter Predicate");
	[_filterPredicate release];
	_filterPredicate = [predicate retain];
	
	[_filterPredicateDescription release];
	_filterPredicateDescription = [desc retain];
}

- (NSString *)createFilterDescription
{
	NSString *description = nil;
	
	if ( [_searchString length] > 0 )
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

- (NSPredicate *)createFilterPredicate
{
	NSPredicate *predicate = nil;
	NSString	*s;
	
	if ([_searchString length] > 0)
	{
		switch (searchType)
		{
			case 7:			// All Fields
				s = [NSString stringWithFormat:@"%@", _searchString];
				
				predicate = [NSPredicate predicateWithFormat: @"(name CONTAINS[cd] %@) OR (patientID CONTAINS[cd] %@) OR (id CONTAINS[cd] %@) OR (comment CONTAINS[cd] %@) OR (studyName CONTAINS[cd] %@) OR (modality CONTAINS[cd] %@) OR (accessionNumber CONTAINS[cd] %@)", s, s, s, s, s, s, s];
				break;
				
			case 0:			// Patient Name
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
				predicate = [NSPredicate predicateWithFormat:  @"modality CONTAINS[cd] %@", _searchString];
				break;
				
			case 6:			// Accession Number 
				predicate = [NSPredicate predicateWithFormat:  @"accessionNumber CONTAINS[cd] %@", _searchString];
				break;
				
			case 100:			// Advanced
				
				break;
		}
		
	}
	return predicate;
}

- (NSArray *) databaseSelection
{
	NSMutableArray		*selectedItems			= [NSMutableArray arrayWithCapacity: 0];
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

//Comparisons
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
	
	[context retain];
	[context lock];
	
	NSError	*error = nil;
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
