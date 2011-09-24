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

#import "BrowserController+Sources+Copy.h"
#import "DicomImage.h"
#import "DicomFile.h"
#import "DicomDatabase.h"
#import "BrowserSource.h"
#import "DCMNetServiceDelegate.h"
#import "MutableArrayCategory.h"
#import "ThreadsManager.h"
#import "RemoteDicomDatabase.h"
#import "NSThread+N2.h"
#import "N2Debug.h"


@implementation BrowserController (SourcesCopy)

-(void)copyImagesToLocalBrowserSourceThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	NSArray* dicomImages = [io objectAtIndex:0];
	BrowserSource* destination = [io objectAtIndex:1];
	
	NSMutableArray* imagePaths = [NSMutableArray array];
	for (DicomImage* image in dicomImages)
		if (![imagePaths containsObject:image.completePath])
			[imagePaths addObject:image.completePath];
	
	thread.status = NSLocalizedString(@"Opening database...", nil);
	DicomDatabase* dstDatabase = [DicomDatabase databaseAtPath:destination.location];
	
    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Copying %d %@...", nil), imagePaths.count, (imagePaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
	NSMutableArray* dstPaths = [NSMutableArray array];
    
    NSTimeInterval fiveSeconds = [NSDate timeIntervalSinceReferenceDate] + 5;
    
    for (NSInteger i = 0; i < imagePaths.count; ++i)
    {
		thread.progress = 1.0*i/imagePaths.count;
        
        if (thread.isCancelled)
            break;
        
		NSString* srcPath = [imagePaths objectAtIndex:i];
		NSString* dstPath = [dstDatabase uniquePathForNewDataFileWithExtension: @"dcm"];
		
#define USECORESERVICESFORCOPY 1
        
#ifdef USECORESERVICESFORCOPY
        char *targetPath = nil;
        OptionBits options = kFSFileOperationSkipSourcePermissionErrors + kFSFileOperationSkipPreflight;
        OSStatus err = FSPathCopyObjectSync( [srcPath UTF8String], [[dstPath stringByDeletingLastPathComponent] UTF8String], (CFStringRef) [dstPath lastPathComponent], &targetPath, options);
        
        if( err == 0)
#else
        NSError* err = nil;
        if([NSFileManager.defaultManager copyItemAtPath:srcPath toPath:dstPath error:nil])
#endif
        {
            if( [DicomFile isDICOMFile: dstPath] == NO)
            {
                [[NSFileManager defaultManager] moveItemAtPath: dstPath toPath: [[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension: [srcPath pathExtension]] error: nil];
            }
            
            [dstPaths addObject:dstPath];
        }
        
        if( fiveSeconds < [NSDate timeIntervalSinceReferenceDate])
        {
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Indexing %d %@...", nil), dstPaths.count, (dstPaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil))];
            [dstDatabase addFilesAtPaths:dstPaths];
            [dstPaths removeAllObjects];
            
            fiveSeconds = [NSDate timeIntervalSinceReferenceDate] + 5;
        }
        
        thread.status = [NSString stringWithFormat:NSLocalizedString(@"Copying %d %@...", nil), imagePaths.count-i, (imagePaths.count-i == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
	}
	
    thread.status = [NSString stringWithFormat:NSLocalizedString(@"Indexing %d %@...", nil), dstPaths.count, (dstPaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil))];
	thread.progress = -1;
	[dstDatabase addFilesAtPaths:dstPaths];
	
	[pool release];
}

-(void)copyImagesToRemoteBrowserSourceThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	NSArray* dicomImages = [io objectAtIndex:0];
	BrowserSource* destination = [io objectAtIndex:1];
	
	NSMutableArray* imagePaths = [NSMutableArray array];
	for (DicomImage* image in dicomImages)
		if (![imagePaths containsObject:image.completePath])
			[imagePaths addObject:image.completePath];
	
	thread.status = NSLocalizedString(@"Opening database...", nil);
	RemoteDicomDatabase* dstDatabase = [RemoteDicomDatabase databaseForAddress:destination.location name:destination.description update:NO];
	
	thread.status = [NSString stringWithFormat:NSLocalizedString(@"Sending %d %@...", nil), imagePaths.count, (imagePaths.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
	
    @try {
        [dstDatabase uploadFilesAtPaths:imagePaths];
	} @catch (NSException* e) {
        thread.status = NSLocalizedString(@"Error: destination is unavailable", nil);
        N2LogExceptionWithStackTrace(e);
        [NSThread sleepForTimeInterval:1];
    }
    
	[pool release];
}

-(void)copyRemoteImagesToLocalBrowserSourceThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	NSMutableArray* dicomImages = [[[io objectAtIndex:0] mutableCopy] autorelease];
	BrowserSource* destination = [io objectAtIndex:1];
	RemoteDicomDatabase* srcDatabase = [io objectAtIndex:2];
	
	NSMutableArray* imagePaths = [[[dicomImages valueForKey:@"completePath"] mutableCopy] autorelease];
	[imagePaths removeDuplicatedStringsInSyncWithThisArray:dicomImages];
	
	thread.status = NSLocalizedString(@"Opening database...", nil);
	DicomDatabase* dstDatabase = [DicomDatabase databaseAtPath:destination.location name:destination.description];
	
	thread.status = [NSString stringWithFormat:NSLocalizedString(@"Fetching %d %@...", nil), dicomImages.count, (dicomImages.count == 1 ? NSLocalizedString(@"file", nil) : NSLocalizedString(@"files", nil)) ];
	NSMutableArray* dstPaths = [NSMutableArray array];
	for (NSInteger i = 0; i < dicomImages.count; ++i)
    {
        @try
        {
            DicomImage* dicomImage = [dicomImages objectAtIndex:i];
            NSString* srcPath = [srcDatabase fetchDataForImage:dicomImage maxFiles:0];
            
            if (srcPath) {
                NSString* ext = [DicomFile isDICOMFile:srcPath]? @"dcm" : srcPath.pathExtension;
                NSString* dstPath = [dstDatabase uniquePathForNewDataFileWithExtension:ext];
                
                if ([NSFileManager.defaultManager moveItemAtPath:srcPath toPath:dstPath error:NULL])
                    [dstPaths addObject:dstPath];
            }
        }
        @catch (NSException *exception)
        {
            N2LogExceptionWithStackTrace( exception);
        }
		thread.progress = 1.0*i/dicomImages.count;
		
        if (thread.isCancelled)
            break;
	}
	
	thread.status = NSLocalizedString(@"Indexing files...", nil);
	thread.progress = -1;
	[dstDatabase addFilesAtPaths:dstPaths];
	
	[pool release];
}

-(void)copyRemoteImagesToRemoteBrowserSourceThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	NSMutableArray* dicomImages = [[[io objectAtIndex:0] mutableCopy] autorelease];
	BrowserSource* destination = [io objectAtIndex:1];
	RemoteDicomDatabase* srcDatabase = [io objectAtIndex:2];
	
	NSMutableArray* imagePaths = [[[dicomImages valueForKey:@"completePath"] mutableCopy] autorelease];
	[imagePaths removeDuplicatedStringsInSyncWithThisArray:dicomImages];
	
	NSString* dstAddress = nil;
	NSString* dstAET = nil;
	NSInteger dstPort = 0;
	NSInteger dstSyntax = 0;
	if (destination.type == BrowserSourceTypeRemote) {
		[RemoteDicomDatabase address:destination.location toAddress:&dstAddress port:NULL];
		dstPort = [[destination.dictionary objectForKey:@"port"] integerValue];
		dstAET = [destination.dictionary objectForKey:@"AETitle"];
		if (!dstAET || !dstPort || !dstSyntax) {
			thread.status = NSLocalizedString(@"Fetching destination information...", nil);
			RemoteDicomDatabase* dstDatabase = [RemoteDicomDatabase databaseForAddress:destination.location name:destination.description update:NO];
            NSDictionary* dstInfo = nil;
            @try {
                dstInfo = [dstDatabase fetchDicomDestinationInfo];
            } @catch (NSException* e) {
                thread.status = NSLocalizedString(@"Error: destination is unavailable", nil);
                N2LogExceptionWithStackTrace(e);
                [NSThread sleepForTimeInterval:1];
            }
			if ([dstInfo objectForKey:@"AETitle"]) dstAET = [dstInfo objectForKey:@"AETitle"];
			if ([dstInfo objectForKey:@"Port"]) dstPort = [[dstInfo objectForKey:@"Port"] integerValue];
			if ([dstInfo objectForKey:@"TransferSyntax"]) dstSyntax = [[dstInfo objectForKey:@"TransferSyntax"] integerValue];
		}
	} else if (destination.type == BrowserSourceTypeDicom) {
		[RemoteDicomDatabase address:destination.location toAddress:&dstAddress port:&dstPort aet:&dstAET];
		dstSyntax = [[destination.dictionary objectForKey:@"TransferSyntax"] integerValue];
	}

	thread.status = [NSString stringWithFormat:NSLocalizedString(@"Sending SCU request...", nil), dicomImages.count];
	[srcDatabase storeScuImages:dicomImages toDestinationAETitle:dstAET address:dstAddress port:dstPort transferSyntax:dstSyntax];

	[pool release];
}

-(BOOL)initiateCopyImages:(NSArray*)dicomImages toSource:(BrowserSource*)destination {
	if (_database.isLocal) {
		switch (destination.type) {
			case BrowserSourceTypeLocal: { // local OsiriX to local OsiriX
				NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyImagesToLocalBrowserSourceThread:) object:[NSArray arrayWithObjects: dicomImages, destination, _database, NULL]] autorelease];
				thread.name = NSLocalizedString(@"Copying images...", nil);
                thread.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart:thread];
				return YES;
			} break;
			case BrowserSourceTypeRemote: { // local OsiriX to remote OsiriX
				NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyImagesToRemoteBrowserSourceThread:) object:[NSArray arrayWithObjects: dicomImages, destination, _database, NULL]] autorelease];
                thread.supportsCancel = YES;
				thread.name = NSLocalizedString(@"Sending images...", nil);
				[[ThreadsManager defaultManager] addThreadAndStart:thread];
				return YES;
			} break;
			case BrowserSourceTypeDicom: { // local OsiriX to remote DICOM
				NSArray* r = [DCMNetServiceDelegate DICOMServersListSendOnly:YES QROnly:NO];
				for (int i = 0; i < r.count; ++i)
					if ([[r objectAtIndex:i] isEqual:destination.dictionary])
						[NSUserDefaults.standardUserDefaults setInteger:i forKey:@"lastSendServer"];
				[self selectServer:dicomImages];
				return YES;
				// [_database storeScuImages:dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax];
			} break;
		}
	} else {
		switch (destination.type) {
			case BrowserSourceTypeLocal: { // remote OsiriX to local OsiriX
				NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyRemoteImagesToLocalBrowserSourceThread:) object:[NSArray arrayWithObjects: dicomImages, destination, _database, NULL]] autorelease];
				thread.name = NSLocalizedString(@"Copying images...", nil);
                thread.supportsCancel = YES;
				[[ThreadsManager defaultManager] addThreadAndStart:thread];
				return YES;
			} break;
			case BrowserSourceTypeRemote: // remote OsiriX to remote OsiriX
			case BrowserSourceTypeDicom: { // remote OsiriX to remote DICOM
				NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(copyRemoteImagesToRemoteBrowserSourceThread:) object:[NSArray arrayWithObjects: dicomImages, destination, _database, NULL]] autorelease];
				thread.name = NSLocalizedString(@"Initiating image transfert...", nil);
				[[ThreadsManager defaultManager] addThreadAndStart:thread];
				return YES;
			} break;
		}
	}
	
	return NO;
	
	/*NSDictionary *object = nil;
	
	if( row > 0)
		object = [NSDictionary dictionaryWithDictionary: [[bonjourBrowser services] objectAtIndex: row-1]];
	
	if( [[object valueForKey: @"type"] isEqualToString:@"dicomDestination"]) // destination remote DICOM node
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
	else if( [[object valueForKey: @"type"] isEqualToString:@"localPath"] || (row == 0 && [_database isLocal])) // destination local
	{
		NSString	*dbFolder = nil;
		NSString	*sqlFile = nil;
		
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
				
				
				Wait *splash = nil;
				
				if (![_database isLocal])
					splash = [[Wait alloc] initWithString:NSLocalizedString(@"Downloading files...", nil)];
				
				[splash showWindow:self];
				[[splash progress] setMaxValue:[imagesArray count]];
				
				NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: [imagesArray count]];
				for( NSManagedObject *img in imagesArray)
				{
					NSString	*sendPath = [self getLocalDCMPath: img :10];
					[packArray addObject: sendPath];
					
					[splash incrementBy:1];
				}
				
				[splash close];
				[splash release];
				
				
				NSLog( @"DB Folder: %@", dbFolder);
				NSLog( @"SQL File: %@", sqlFile);
				NSLog( @"Current documentsDirectory: %@", self.documentsDirectory);
				
				NSPersistentStoreCoordinator *sc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel];
				NSManagedObjectContext *sqlContext = [[NSManagedObjectContext alloc] init];
				
				[sqlContext setPersistentStoreCoordinator: sc];
				[sqlContext setUndoManager: nil];
				
				NSError	*error = nil;
				NSArray *copiedObjects = nil;
				
				NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];	//[NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
				
				if( [sc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath: sqlFile] options: options error:&error] == nil)
					NSLog( @"****** tableView acceptDrop addPersistentStoreWithType error: %@", error);
				
				if( [dbFolder isEqualToString: [self.documentsDirectory stringByDeletingLastPathComponent]] && [_database isLocal])	// same database folder - we don't need to copy the files
				{
					NSLog( @"Destination DB Folder is identical to Current DB Folder");
					
					copiedObjects = [self addFilesToDatabase: packArray onlyDICOM:NO produceAddedFiles:YES parseExistingObject:NO context: sqlContext dbFolder: [dbFolder stringByAppendingPathComponent:@"OsiriX Data"]];
				}
				else
				{
					NSMutableArray	*dstFiles = [NSMutableArray array];
					NSLog( @"Destination DB Folder is NOT identical to Current DB Folder");
					
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: packArray, @"packArray", dbFolder, @"dbFolder", sqlContext, @"sqlContext", nil];
					
					NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( copyToDB:) object: dict] autorelease];
					t.name = NSLocalizedString( @"Copying files to another DB...", nil);
					t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [packArray count]];
					t.supportsCancel = YES;
					t.progress = 0;
					[[ThreadsManager defaultManager] addThreadAndStart: t];
				}
				
				error = nil;
				[sqlContext save: &error];
				
				[sc release];
				[sqlContext release];
			}
			
			@catch (NSException * e)
			{
                N2LogExceptionWithStackTrace(e, @"local path database");
			}
		}
		else NSRunCriticalAlertPanel( NSLocalizedString(@"Error",nil),  NSLocalizedString(@"Destination Database / Index file is not available.", nil), NSLocalizedString(@"OK",nil), nil, nil);
		
		NSLog( @"-----------------------------");
	}
	else if (![_database isLocal]) // copying from (remote) to (local|distant)
	{ 
		if (!row || [object objectForKey:<#(id)aKey#>])
			
			[_database ];
		
		BOOL OnlyDICOM = YES;
		BOOL succeed = NO;
		
		[splash showWindow:self];
		[[splash progress] setMaxValue:[imagesArray count]];
		
		for( NSManagedObject *img in imagesArray)
		{
			if( [[img valueForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) OnlyDICOM = NO;
		}
		
		if( OnlyDICOM && [[NSUserDefaults standardUserDefaults] boolForKey: @"STORESCP"])
		{
			// We will use the DICOM-Store-SCP
			NSMutableDictionary* destination = [[[[bonjourBrowser services] objectAtIndex:row-1] mutableCopy] autorelease];
			if (row == 0)
				[destination addEntriesFromDictionary:[RemoteDicomDatabase fetchDicomDestinationInfoForHost:[NSHost hostWithAddress:] port:[]]];
			else {
				
			}
			
			[(RemoteDicomDatabase*)_database storeScuImages:imagesArray toDestinationAETitle:<#(NSString *)aet#> address:<#(NSString *)address#> port:<#(NSInteger)port#> transferSyntax:<#(int)transferSyntax#>];
			for (int i = 0; i < [imagesArray count]; i++) [splash incrementBy:1];
		}
		else NSLog( @"Not Only DICOM !");
		
		if( succeed == NO || OnlyDICOM == NO)
		{
			NSString *rootPath = [self INCOMINGPATH];
			
			for( NSManagedObject *img in imagesArray)
			{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				filePath = [self getLocalDCMPath: img :100];
				destPath = [rootPath stringByAppendingPathComponent: [filePath lastPathComponent]];
				
				// The files are moved to the INCOMING folder : they will be automatically added when switching back to local database!
				
				[[NSFileManager defaultManager] copyPath:filePath toPath:destPath handler:nil];
				
				[splash incrementBy:1];
				
				[pool release];
			}
		}
		
	}
	else if( [_sourcesTableView selectedRow] != row && row > 0 && object != nil)	 // Copying From Local to distant
	{ NSLog(@"TODO: THHIIIIIIIIISSSSSSSSSS"); 
		BOOL OnlyDICOM = YES;
		
		NSDictionary *dcmNode = object;
		
		if( OnlyDICOM == NO)
			NSLog( @"Not Only DICOM !");
		
		if( [dcmNode valueForKey:@"Port"] == nil && OnlyDICOM)
		{
			NSMutableDictionary	*dict = [NSMutableDictionary dictionaryWithDictionary: dcmNode];
			[dict addEntriesFromDictionary: [bonjourBrowser getDICOMDestinationInfo: row-1]];
			[[bonjourBrowser services] replaceObjectAtIndex: row-1 withObject: dict];
			
			dcmNode = dict;
		}
		
		if( [dcmNode valueForKey:@"Port"] && OnlyDICOM)
		{
			[SendController sendFiles: imagesArray toNode: dcmNode usingSyntax: [[dcmNode valueForKey: @"TransferSyntax"] intValue]];
		}
		else
		{
			Wait *splash = [[Wait alloc] initWithString:@"Copying to OsiriX database..."];
			[splash showWindow:self];
			[[splash progress] setMaxValue:[imagesArray count]];
			
			for( int i = 0; i < [imagesArray count];)
			{
				NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
				NSMutableArray		*packArray = [NSMutableArray arrayWithCapacity: 10];
				
				for( int x = 0; x < 10; x++)
				{
					if( i <  [imagesArray count])
					{
						NSString *sendPath = [self getLocalDCMPath:[imagesArray objectAtIndex: i] :1];
						
						[packArray addObject: sendPath];
						
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
	else return NO;*/
}

@end
