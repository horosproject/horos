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

#import "BrowserController.h"
#import "SendController.h"
#import "Wait.h"
#import <OsiriX/DCMNetServiceDelegate.h>
#import <OsiriX/DCM.h>
#import "PluginFilter.h"
#import "PluginManager.h"
#import "DCMTKStoreSCU.h"
#import "MutableArrayCategory.h"
#import "Notifications.h"
#import "QueryController.h"
#import "DicomStudy.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "NSUserDefaults+OsiriX.h"
#import "N2Stuff.h"

static volatile int sendControllerObjects = 0;

@implementation SendController

+(int) sendControllerObjects
{
	return sendControllerObjects;
}

+ (void) sendFiles:(NSArray *) files toNode: (NSDictionary*) node
{
	return [SendController sendFiles: files toNode: node usingSyntax: SendExplicitLittleEndian];
}

+ (void) sendFiles:(NSArray *) files toNode: (NSDictionary*) node usingSyntax: (int) syntax
{
	BOOL s = [[NSUserDefaults standardUserDefaults] boolForKey: @"sendROIs"];

	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"sendROIs"];
	[[NSUserDefaults standardUserDefaults] setInteger: syntax forKey:@"syntaxListOffis"];
	
	SendController *sendController = [[SendController alloc] initWithFiles: files];
	[sendController sendToNode: node];
	
	[[NSUserDefaults standardUserDefaults] setBool: s forKey: @"sendROIs"];
}

+ (void) sendFiles: (NSArray *) files
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMSENDALLOWED"] == NO)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"DICOM Sending is not activated. Contact your PACS manager for more information about DICOM Send.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		return;
	}

	if( [files  count])
	{
		if( [[DCMNetServiceDelegate DICOMServersListSendOnly: YES QROnly: NO] count] > 0)
		{
			SendController *sendController = [[SendController alloc] initWithFiles:files];
			[NSApp beginSheet: [sendController window] modalForWindow:[NSApp mainWindow] modalDelegate:sendController didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
		else
		{
			NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No DICOM destinations available. See Preferences to add DICOM locations.",nil),NSLocalizedString( @"OK",nil), nil, nil);
		}
	}
	else
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"No files are selected...",nil),NSLocalizedString( @"OK",nil), nil, nil);
	}
}

- (id)initWithFiles:(NSArray *)files
{
	if (self = [super initWithWindowNibName:@"Send"])
	{
		NSLog( @"SendController initWithFiles: %d files", (int) files.count);
		
		sendControllerObjects++;
		
		_abort = NO;
		_files = [files copy];
		
		[self setNumberFiles: [NSString stringWithFormat: @"%d", (int) [_files  count]]];
		
		_serverIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendServer"];	
		
		if( _serverIndex >= [[DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly: NO] count])
			_serverIndex = 0;
		
		_keyImageIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendWhat"];
		
		_readyForRelease = NO;
		_lock = [[NSRecursiveLock alloc] init];
		
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver: self
												selector: @selector(updateDestinationPopup:)
												name: @"DCMNetServicesDidChange"
												object: nil];
	}
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
        if( [keyPath isEqualToString: @"values.SERVERS"])
        {
            [self updateDestinationPopup: nil];
        }
	}
}


- (void) windowDidLoad
{
	if 	([_files  count])
	{
		[self updateDestinationPopup: nil];
		
		int count = [[DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO] count];
		if (_serverIndex < count)
			[newServerList selectItemAtIndex: _serverIndex];
        
		[keyImageMatrix selectCellWithTag: _keyImageIndex];
		
		[self selectServer: newServerList];
	}

}

- (void)dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SERVERS"];
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
	sendControllerObjects--;
	
	NSLog(@"SendController Released");
	[_destinationServer release];
	[_files release];
	[_numberFiles release];
	[_lock lock];
	[_lock unlock];
	[_lock release];
	
	[super dealloc];
}

- (void)releaseSelfWhenDone:(id)sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	[_lock lock];
	[_lock unlock];
    
	[self performSelectorOnMainThread: @selector(autorelease) withObject: nil waitUntilDone: NO];
    
    [pool release];
}

- (NSString *)numberFiles{
	return _numberFiles;
}

- (void)setNumberFiles:(NSString *)numberFiles
{
	[_numberFiles release];
	_numberFiles = [numberFiles retain];
}

- (id)server
{
	if( _destinationServer)
		return _destinationServer;
	
	return [self serverAtIndex:_serverIndex];
}


#pragma mark Accessors functions

- (id)serverAtIndex:(int)index
{
	NSArray *serversArray = [DCMNetServiceDelegate DICOMServersListSendOnly: YES QROnly:NO];
	
	if(	index > -1 && index < [serversArray count]) return [serversArray objectAtIndex:index];
	
	return nil;
}

- (IBAction)selectServer: (id)sender
{
	//NSLog(@"select server: %@", [sender description]);
	_serverIndex = [sender indexOfSelectedItem];
	
	[[NSUserDefaults standardUserDefaults] setInteger:_serverIndex forKey:@"lastSendServer"];
	
	if ([[self server] isKindOfClass:[NSDictionary class]])
	{
		int preferredTS = [[[self server] objectForKey:@"TransferSyntax"] intValue];
		
		[[NSUserDefaults standardUserDefaults] setInteger: preferredTS forKey:@"syntaxListOffis"];
	}	
	
	[addressAndPort setStringValue: [NSString stringWithFormat:@"%@ : %@", [[self server] objectForKey:@"Address"], [[self server] objectForKey:@"Port"]]];
}

- (int) keyImageIndex
{
	return _keyImageIndex;
}

- (void) setKeyImageIndex:(int)index
{
	_keyImageIndex = index;
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"lastSendWhat"];
}

#pragma mark sheet functions

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
}

- (IBAction) endSelectServer:(id) sender
{	
	[[self window] orderOut:sender];
	[NSApp endSheet: [self window] returnCode:[sender tag]];
	NSArray *objectsToSend = _files;
	
	if( [sender tag])   //User clicks OK Button
    {		
		if (_keyImageIndex == 1)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"];
			objectsToSend = [_files filteredArrayUsingPredicate:predicate];
		}
		
		if (_keyImageIndex == 2)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"modality CONTAINS[c] %@", @"SC"];
			objectsToSend = [objectsToSend filteredArrayUsingPredicate:predicate];
		}

		NSMutableArray *files2Send = [objectsToSend valueForKey: @"completePath"];
		
		if( files2Send != nil && [files2Send count] > 0)
		{
			if( files2Send)
				[self sendToNode: [self server] objects: objectsToSend];
			else
				[self autorelease];
		}
		else
		{
			NSRunAlertPanel(NSLocalizedString(@"DICOM Send",nil),NSLocalizedString( @"There are no files of selected type to send.",nil),NSLocalizedString( @"OK",nil), nil, nil);
			
			[self autorelease];
		}
	}
	else // Cancel
		[self autorelease];
}

- (void) addArray: (NSMutableArray*) a toArraysOfFiles: (NSMutableArray*) arraysOfFiles andArrayOfPatientNames: (NSMutableArray*) arrayOfPatientNames
{
    if( a.count == 0)
        return;
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"sendROIs"] == NO)
    {
        @try
        {
            NSPredicate *predicate = nil;
            
            predicate = [NSPredicate predicateWithFormat:@"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX ROI SR", @"5002"];
            [a filterUsingPredicate:predicate];
            
            predicate = [NSPredicate predicateWithFormat:@"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX Report SR", @"5003"];
            [a filterUsingPredicate:predicate];
            
            predicate = [NSPredicate predicateWithFormat:@"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX Annotations SR", @"5004"];
            [a filterUsingPredicate:predicate];
            
            predicate = [NSPredicate predicateWithFormat:@"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX No Autodeletion", @"5005"];
            [a filterUsingPredicate:predicate];
        }
        
        @catch( NSException *e)
        {
            NSLog( @"***** executeSend exception: %@", e);
        }
    }
    
    [arrayOfPatientNames addObject: [[a lastObject] valueForKeyPath: @"series.study.name"]];
    [arraysOfFiles addObject: [a valueForKey: @"completePathResolved"]];
}

- (void) sendToNode: (NSDictionary*) node
{
    [self sendToNode: node objects: nil];
}

- (void) sendToNode: (NSDictionary*) node objects:(NSArray*) objects
{
	if( objects == nil)
		objects = _files;
	
    NSMutableArray *objectsToSend = [NSMutableArray arrayWithArray: objects];
    
	[_lock lock];
	[NSThread detachNewThreadSelector: @selector(releaseSelfWhenDone:) toTarget: self withObject: nil];
	
	[_destinationServer release];
	_destinationServer = [node retain];
	
    NSMutableArray *arraysOfFiles = [NSMutableArray array];
    NSMutableArray *arrayOfPatientNames = [NSMutableArray array];
//    DicomDatabase *database = nil;
    
	@try
	{
        [objectsToSend sortUsingDescriptors: [NSArray arrayWithObject: [NSSortDescriptor sortDescriptorWithKey:@"series.study.patientUID" ascending:YES]]];
        
		// Remove duplicated files 
		NSMutableArray *paths = [NSMutableArray arrayWithArray: [objectsToSend valueForKey: @"completePathResolved"]];
		[paths removeDuplicatedStringsInSyncWithThisArray: objectsToSend];
		
        if( objectsToSend.count)
        {
            NSString *previousPatientUID = nil;
            NSMutableArray *samePatientArray = [NSMutableArray array];
            
            for( DicomImage *image in objectsToSend)
            {
                NSString *patientUID = [image valueForKeyPath:@"series.study.patientUID"];
                BOOL newPatient = NO;
                
                if( [previousPatientUID compare: patientUID options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] == NSOrderedSame)
                    [samePatientArray addObject: image];
                
                else
                {
                    [self addArray: samePatientArray toArraysOfFiles: arraysOfFiles andArrayOfPatientNames: arrayOfPatientNames];
                    
                    // Reset
                    samePatientArray = [NSMutableArray array];
                    [samePatientArray addObject: image];
                    
                    previousPatientUID = [[patientUID copy] autorelease];
                }
            }
            
            [self addArray: samePatientArray toArraysOfFiles: arraysOfFiles andArrayOfPatientNames: arrayOfPatientNames];
        }
	}
	@catch (NSException *e)
	{
		NSLog( @"***** sendDICOMFilesOffis exception: %@", e);
	}
    
    if( arraysOfFiles.count)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: arraysOfFiles, @"arraysOfFiles", arrayOfPatientNames, @"arrayOfPatientNames", nil];
        
        NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(sendDICOMFilesOffis:) object: dict] autorelease];
        t.name = NSLocalizedString( @"Sending...", nil);
        t.supportsCancel = YES;
        t.progress = 0;
        t.status = N2LocalizedSingularPluralCount( [_files count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
        [[ThreadsManager defaultManager] addThreadAndStart: t];
    }
}

#pragma mark Sending functions

- (void) showErrorMessage:(NSException*) ne
{
	NSString	*message = [NSString stringWithFormat:@"%@\r\r%@\r%@", NSLocalizedString( @"DICOM StoreSCU operation failed.", nil), [ne name], [ne reason]];

	NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send Error",nil), message, NSLocalizedString( @"OK",nil), nil, nil);
}

- (void) executeSend:(NSArray*) files patientName: (NSString*) patientName
{
	if( [NSThread currentThread].isCancelled)
		return;
	
	[NSThread currentThread].name = [NSString stringWithFormat: @"%@ %@", NSLocalizedString( @"Sending...", nil), patientName];
    
	// Send the collected files from the same patient
	
	NSString *calledAET = [[self server] objectForKey:@"AETitle"];
	NSString *hostname = [[self server] objectForKey:@"Address"];
	NSString *destPort = [[self server] objectForKey:@"Port"];
	
    NSMutableDictionary* xp = [NSMutableDictionary dictionaryWithDictionary:[self server]];
//    [xp setObject:database forKey:@"DicomDatabase"];
    
	storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET:[NSUserDefaults defaultAETitle] 
			calledAET:calledAET 
			hostname:hostname 
			port:[destPort intValue] 
			filesToSend:files
			transferSyntax: [[NSUserDefaults standardUserDefaults] integerForKey:@"syntaxListOffis"]
			compression: 1.0
			extraParameters:[self server]];
	
	@try
	{
		[storeSCU run:self];
	}
	
	@catch( NSException *ne)
	{
		[self performSelectorOnMainThread:@selector(showErrorMessage:) withObject:ne waitUntilDone: NO];
	}
	
	[storeSCU release];
	storeSCU = nil;
}

- (void) sendDICOMFilesOffis:(NSDictionary *) dict 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *arraysOfFiles = [dict objectForKey: @"arraysOfFiles"];
    NSArray *arrayOfPatientNames = [dict objectForKey: @"arrayOfPatientNames"];
//    DicomDatabase *database = [dict objectForKey: @"database"];
    
	@try
	{
        for( int i = 0;i < arraysOfFiles.count;i++)
        {
            [self executeSend: [arraysOfFiles objectAtIndex: i] patientName: [arrayOfPatientNames objectAtIndex: i]];
        }
	}
	@catch (NSException *e)
	{
		NSLog( @"***** sendDICOMFilesOffis exception: %@", e);
	}
    
	//need to unlock to allow release of self after send complete
	[_lock performSelectorOnMainThread:@selector(unlock) withObject:nil waitUntilDone: NO];
    
    [pool release];
}

#pragma mark serversArray functions

- (void) updateDestinationPopup: (NSNotification *)note
{
	if( newServerList)
	{
		NSString *currentTitle = [[[newServerList selectedItem] title] retain];
		
		[newServerList removeAllItems];
		for( NSDictionary *d in [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO])
		{
			NSString *title = [NSString stringWithFormat:@"%@ - %@",[d objectForKey:@"AETitle"],[d objectForKey:@"Description"]];
			
			while( [newServerList indexOfItemWithTitle: title] != -1)
				title = [title stringByAppendingString: @" "];
				
			[newServerList addItemWithTitle: title];
		}
		
		for( NSMenuItem *d in [newServerList itemArray])
		{
			if( [[d title] isEqualToString: currentTitle])
				[newServerList selectItem: d];
		}
		
		[currentTitle release];
	}
}
@end
