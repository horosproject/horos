/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "BrowserController.h"
#import "SendController.h"
#import "Wait.h"
#import "DCMNetServiceDelegate.h"
#import "DCM.h"
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

@interface DCMTKStoreSCUOperation: NSOperation
{
    NSArray *files;
    NSDictionary *server;
    NSThread *thread;
}
@property (retain) NSArray *files;
@property (retain) NSDictionary *server;
@property (retain) NSThread *thread;

- (id) initWithFiles:(NSArray*) a server: (NSDictionary*) s;

@end

@implementation DCMTKStoreSCUOperation
@synthesize files, server, thread;

- (id) initWithFiles:(NSArray*) a server:(NSDictionary*) s
{
    self = [super init];
    
    self.files = a;
    self.server = s;
    
    return self;
}

- (void) showErrorMessage:(NSException*) ne
{
	NSString *message = [NSString stringWithFormat:@"%@\r\r%@\r%@", NSLocalizedString( @"DICOM StoreSCU operation failed.", nil), [ne name], [ne reason]];
    
	NSRunCriticalAlertPanel(NSLocalizedString(@"DICOM Send Error",nil), @"%@", NSLocalizedString( @"OK",nil), nil, nil, message);
}

- (void) main
{
    @autoreleasepool
    {
        if( self.isCancelled)
            return;
        
        self.thread = [NSThread currentThread];
        self.thread.progress = 0;
        
        DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc] initWithCallingAET: [NSUserDefaults defaultAETitle]
                                                   calledAET: [server objectForKey:@"AETitle"]
                                                    hostname: [server objectForKey:@"Address"]
                                                        port: [[server objectForKey:@"Port"] intValue]
                                                 filesToSend: files
                                              transferSyntax: [[NSUserDefaults standardUserDefaults] integerForKey:@"syntaxListOffis"]
                                                 compression: 1.0
                                             extraParameters: server];
        
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
}

- (void) dealloc
{
    self.files = nil;
    self.server = nil;
    self.thread = nil;
    [super dealloc];
}

@end

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

- (BOOL) hasKeyImages
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"];
    NSArray *objectsToSend = [_files filteredArrayUsingPredicate:predicate];
    
    return objectsToSend.count;
}

- (BOOL) hasSecondaryCapturesImages
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"modality CONTAINS[c] %@", @"SC"];
    NSArray *objectsToSend = [_files filteredArrayUsingPredicate:predicate];
    
    return objectsToSend.count;
}

- (id)initWithFiles:(NSArray *)files
{
	if (self = [super initWithWindowNibName:@"Send"])
	{
		NSLog( @"SendController initWithFiles: %d files", (int) files.count);
		
		sendControllerObjects++;
		
		_abort = NO;
		_files = [files copy];
		
		[self setNumberFiles: [NSString stringWithFormat: @"%d", (int) [[[NSSet setWithArray: [_files valueForKey: @"completePath"]] allObjects] count]]];
		
		_serverIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendServer"];	
		
		if( _serverIndex >= [[DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly: NO] count])
			_serverIndex = 0;
		
		_keyImageIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastSendWhat"];
		
        if( _keyImageIndex == 1 && self.hasKeyImages == NO) //KeyImages
            _keyImageIndex = 0;
        
        if( _keyImageIndex == 1 && self.hasSecondaryCapturesImages == NO) //SC
            _keyImageIndex = 0;
        
		_readyForRelease = NO;
		_lock = [[NSRecursiveLock alloc] init];
		
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:nil];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SendControllerConcurrentThreads" options:NSKeyValueObservingOptionInitial context:nil];
        
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
        
        if( [keyPath isEqualToString: @"values.SendControllerConcurrentThreads"])
        {
            // Find current server (if it exists)
            
            NSMutableArray *servers = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"SERVERS"] mutableCopy] autorelease];
            NSDictionary *currentServer = [self server];
            
            for( NSDictionary *server in servers)
            {
                if( [[server objectForKey: @"Address"] isEqualToString: [currentServer objectForKey: @"Address"]] && [[server objectForKey: @"Description"] isEqualToString: [currentServer objectForKey: @"Description"]])
                {
                    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary: server];
                    
                    [d setObject: [[NSUserDefaults standardUserDefaults] objectForKey: @"SendControllerConcurrentThreads"] forKey: @"SendControllerConcurrentThreads"];
                    
                    [servers replaceObjectAtIndex: [servers indexOfObject: server] withObject: d];
                    
                    [[NSUserDefaults standardUserDefaults] setObject: servers forKey: @"SERVERS"];
                    
                    break;
                }
            }
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
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SendControllerConcurrentThreads"];
    
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
		
		[[NSUserDefaults standardUserDefaults] setInteger: preferredTS forKey: @"syntaxListOffis"];
        
        if( [[self server] objectForKey: @"SendControllerConcurrentThreads"])
            [[NSUserDefaults standardUserDefaults] setInteger: [[[self server] objectForKey: @"SendControllerConcurrentThreads"] intValue] forKey: @"SendControllerConcurrentThreads"];
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
        
        // Remove duplicates
        objectsToSend = [[NSSet setWithArray: objectsToSend] allObjects];
        
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
            
            predicate = [NSPredicate predicateWithFormat:@"!(series.name CONTAINS[c] %@) AND !(series.id == %@)", @"OsiriX WindowsState SR", @"5006"];
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

- (void) executeSend:(NSArray*) files patientName: (NSString*) patientName
{
	if( [NSThread currentThread].isCancelled)
		return;
	
	[NSThread currentThread].name = [NSString stringWithFormat: @"%@ %@", NSLocalizedString( @"Sending...", nil), patientName];
    
	// Send the collected files from the same patient
    
    NSMutableArray *operations = [NSMutableArray array];
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    queue.name = [NSString stringWithFormat: @"%@ %@", NSLocalizedString( @"Sending...", nil), patientName];
    
    unsigned int maxThreads = [[NSUserDefaults standardUserDefaults] integerForKey: @"SendControllerConcurrentThreads"];
    
    if( maxThreads > [[NSUserDefaults standardUserDefaults] integerForKey: @"MaximumSendControllerConcurrentThreads"])
        maxThreads = [[NSUserDefaults standardUserDefaults] integerForKey: @"MaximumSendControllerConcurrentThreads"];
    
    if( maxThreads <= 0)
        maxThreads = 1;
    
    if( maxThreads > 1)
        NSLog( @"DCMTKStoreSCU threads: %d", maxThreads);
    
    unsigned long loc = 0;
    do
    {
        NSRange range = NSMakeRange( loc, ceil( (float)files.count / (float)maxThreads));
        if( operations.count == maxThreads-1)
            range.length = files.count - range.location;
        
        if( range.location + range.length > files.count)
            range.length = files.count-range.location;
        
        if( range.length)
        {
            loc += range.length;
            
            DCMTKStoreSCUOperation *op = [[[DCMTKStoreSCUOperation alloc] initWithFiles: [files subarrayWithRange: range] server: [self server]] autorelease];
            
            [operations addObject: op];
            [queue addOperation: op];
        }
                                  
    }
    while( loc < files.count);
    
//    NSUInteger initialOpCount = queue.operationCount;
    while (queue.operationCount)
    {
        if( [[NSThread currentThread] isCancelled])
        {
            [NSThread currentThread].progress = -1;
            [NSThread currentThread].status = NSLocalizedString( @"Cancelling...", nil);
            [queue cancelAllOperations];
            break;
        }
        
        float progress = 0;
        for( DCMTKStoreSCUOperation *o in operations)
        {
            if( [queue.operations containsObject: o] == NO)
                progress += 1.0;
            else if( o.thread.progress >= 0)
                progress += o.thread.progress;
        }
        
        progress /= operations.count;
        [NSThread currentThread].progress = progress;
        
        int remainingFiles = (files.count - files.count * progress);
        [NSThread currentThread].status = N2LocalizedSingularPluralCount( remainingFiles, NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
        
        [NSThread sleepForTimeInterval:0.1];
    }
    
    [queue waitUntilAllOperationsAreFinished];
}

static int globalDCMTKSCUCounter = 0;

- (void) sendDICOMFilesOffis:(NSDictionary *) dict 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSArray *arraysOfFiles = [dict objectForKey: @"arraysOfFiles"];
    NSArray *arrayOfPatientNames = [dict objectForKey: @"arrayOfPatientNames"];
    
    globalDCMTKSCUCounter++;
    
    while( globalDCMTKSCUCounter > 1 && globalDCMTKSCUCounter >= [[NSUserDefaults standardUserDefaults] integerForKey: @"MaximumSendGlobalControllerConcurrentThreads"])
        [NSThread sleepForTimeInterval: 0.1];
    
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
    
    globalDCMTKSCUCounter--;
    
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
