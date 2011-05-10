//
//  BrowserController+Sources.m
//  OsiriX
//
//  Created by Alessandro Volz on 06.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "BrowserController+Sources.h"
#import "BrowserSource.h"
#import "ImageAndTextCell.h"
#import "DicomDatabase.h"
#import "RemoteDicomDatabase.h"
#import "NSManagedObject+N2.h"
#import "DicomImage.h"
#import "MutableArrayCategory.h"
#import "NSUserDefaultsController+N2.h"
#import "N2Debug.h"
#import "NSThread+N2.h"
#import "N2Operators.h"
#import "ThreadModalForWindowController.h"
#import "BonjourPublisher.h"
#import <netinet/in.h>
#import <arpa/inet.h>


@interface BrowserSourcesHelper : NSObject/*<NSTableViewDelegate,NSTableViewDataSource>*/ {
	BrowserController* _browser;
	NSNetServiceBrowser* _nsb;
	NSMutableDictionary* _bonjourSources;
}

-(id)initWithBrowser:(BrowserController*)browser;

@end

@interface DefaultBrowserSource : BrowserSource
@end

@interface BonjourBrowserSource : BrowserSource {
	NSNetService* _service;
}

@property(retain) NSNetService* service;

@end



@implementation BrowserController (Sources)

-(void)awakeSources {
	[_sourcesArrayController setSortDescriptors:[NSArray arrayWithObjects: [[[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES] autorelease], NULL]];
	[_sourcesArrayController setAutomaticallyRearrangesObjects:YES];
	[_sourcesArrayController addObject:[DefaultBrowserSource browserSourceForLocalPath:DicomDatabase.defaultDatabase.baseDirPath]];
	[_sourcesArrayController setSelectsInsertedObjects:NO];
	
	_sourcesHelper = [[BrowserSourcesHelper alloc] initWithBrowser:self];
	[_sourcesTableView setDataSource:_sourcesHelper];
	[_sourcesTableView setDelegate:_sourcesHelper];
	
	ImageAndTextCell* cell = [[[ImageAndTextCell alloc] init] autorelease];
	[cell setEditable:NO];
	[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[[_sourcesTableView tableColumnWithIdentifier:@"Source"] setDataCell:cell];
	
	[_sourcesTableView registerForDraggedTypes:[NSArray arrayWithObject:O2AlbumDragType]];
	
	[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

-(void)deallocSources {
	[_sourcesHelper release]; _sourcesHelper = nil;
}

-(NSInteger)sourcesCount {
	return [[_sourcesArrayController arrangedObjects] count];
}

-(BrowserSource*)sourceAtRow:(int)row {
	return [_sourcesArrayController.arrangedObjects objectAtIndex:row];
}

-(int)rowForSource:(BrowserSource*)source {
	for (NSInteger i = 0; i < [[_sourcesArrayController arrangedObjects] count]; ++i)
		if ([[_sourcesArrayController.arrangedObjects objectAtIndex:i] isEqualToSource:source])
			return i;
	return -1;
}

-(BrowserSource*)sourceForDatabase:(DicomDatabase*)database {
	if (database.isLocal)
		return [BrowserSource browserSourceForLocalPath:database.baseDirPath];
	else return [BrowserSource browserSourceForAddress:[NSString stringWithFormat:@"%@:%d", [(RemoteDicomDatabase*)database host], [(RemoteDicomDatabase*)database port]] description:nil dictionary:nil];	
}

-(int)rowForDatabase:(DicomDatabase*)database {
	return [self rowForSource:[self sourceForDatabase:database]];
}

-(void)selectSourceForDatabase:(DicomDatabase*)database {
	NSInteger row = [self rowForDatabase:database];
	if (row >= 0)
		[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	else NSLog(@"Warning: couldn't find database in sources (%@)", database);
}

-(void)selectCurrentDatabaseSource {
	NSInteger i = [self rowForDatabase:_database];
	if (i != [_sourcesTableView selectedRow])
		[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}

-(void)setDatabaseThread:(NSArray*)io {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSString* type = [io objectAtIndex:0];
		DicomDatabase* db = nil;
		
		
		if ([type isEqualToString:@"Local"]) {
			NSString* path = [io objectAtIndex:1];
			NSString* name = io.count > 2? [io objectAtIndex:2] : nil;
			db = [DicomDatabase databaseAtPath:path name:name];
		}
		
		if ([type isEqualToString:@"Remote"]) {
			NSString* address = [io objectAtIndex:1];
			NSInteger port = [[io objectAtIndex:2] intValue];
			NSString* name = io.count > 3? [io objectAtIndex:3] : nil;
			NSString* ap = [NSString stringWithFormat:@"%@:%d", address, port];
			db = [RemoteDicomDatabase databaseForAddress:ap name:name];
		}
		
		[self performSelectorOnMainThread:@selector(setDatabase:) withObject:db waitUntilDone:NO];
	} @catch (NSException* e) {
		if (![e.description isEqualToString:@"Cancelled."])
			N2LogExceptionWithStackTrace(e);
		[self performSelectorOnMainThread:@selector(selectCurrentDatabaseSource) withObject:nil waitUntilDone:NO];
	} @finally {
		[pool release];
	}
}

-(NSThread*)initiateSetDatabaseAtPath:(NSString*)path name:(NSString*)name {
	NSArray* io = [NSMutableArray arrayWithObjects: @"Local", path, name, nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io];
	thread.name = NSLocalizedString(@"Loading OsiriX database...", nil);
	thread.supportsCancel = YES;
	thread.status = NSLocalizedString(@"Reading data...", nil);
	
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return [thread autorelease];
}

-(NSThread*)initiateSetRemoteDatabaseWithAddress:(NSString*)address port:(NSInteger)port name:(NSString*)name {
	NSArray* io = [NSMutableArray arrayWithObjects: @"Remote", address, [NSNumber numberWithInteger:port], name, nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io];
	thread.name = NSLocalizedString(@"Loading remote OsiriX database...", nil);
	thread.supportsCancel = YES;
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return [thread autorelease];
}

-(void)setDatabaseFromSource:(BrowserSource*)source {
	if ([source isEqualToSource:[self sourceForDatabase:_database]])
		return;
	
	DicomDatabase* db = [source database];
	
	if (db) 
		[self setDatabase:db];
	else
		switch (source.type) {
			case BrowserSourceTypeLocal: {
				[self initiateSetDatabaseAtPath:source.location name:source.description];
			} break;
			case BrowserSourceTypeRemote: {
				NSHost* host; NSInteger port; [RemoteDicomDatabase address:source.location toHost:&host port:&port];
				[self initiateSetRemoteDatabaseWithAddress:host.address port:port name:source.description];
			} break;
			default:
				[self selectCurrentDatabaseSource]; // TODO: oaeiuiouioei
		}
}

-(BOOL)copyImages:(NSArray*)dicomImages toSource:(BrowserSource*)destination {
	if (_database.isLocal) switch (destination.type) {
		case BrowserSourceTypeLocal: { // local OsiriX to local OsiriX
			
		} break;
		case BrowserSourceTypeRemote: { // local OsiriX to remote OsiriX
			
		} break;
		case BrowserSourceTypeDicom: { // local OsiriX to remote DICOM
			//[_database storeScuImages:dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax];
		} break;
	} else switch (destination.type) {
		case BrowserSourceTypeLocal: { // remote OsiriX to local OsiriX
			
		} break;
		case BrowserSourceTypeRemote: { // remote OsiriX to remote OsiriX
			
		} break;
		case BrowserSourceTypeDicom: { // remote OsiriX to remote DICOM
			//[_database storeScuImages:dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax];
		} break;
	}
	
	return NO;
	
	/*
	 
	 NSDictionary *object = nil;
	 
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
	 NSLog( @"%@", [e description]);
	 NSLog( @"Exception LOCAL PATH - DATABASE - tableView *******");
	 [AppController printStackTrace: e];
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
	 { NSLog(@"TODO: THHIIIIIIIIISSSSSSSSSS"); /*
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

-(long)currentBonjourService { // __deprecated
	return [_sourcesTableView selectedRow]-1;
}

-(void)setCurrentBonjourService:(int)index { // __deprecated
	[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index+1] byExtendingSelection:NO];
}

-(int)findDBPath:(NSString*)path dbFolder:(NSString*)DBFolderLocation { // __deprecated
	NSInteger i = [self rowForSource:[BrowserSource browserSourceForLocalPath:path]];
	if (i == -1) i = [self rowForSource:[BrowserSource browserSourceForLocalPath:DBFolderLocation]];
	return i;
}

@end

@implementation BrowserSourcesHelper

static void* const LocalBrowserSourcesContext = @"LocalBrowserSourcesContext";
static void* const RemoteBrowserSourcesContext = @"RemoteBrowserSourcesContext";
static void* const DicomBrowserSourcesContext = @"DicomBrowserSourcesContext";
static void* const SearchBonjourNodesContext = @"SearchBonjourNodesContext";

-(id)initWithBrowser:(BrowserController*)browser {
	if ((self = [super init])) {
		_browser = browser;
		[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:@"localDatabasePaths" options:NSKeyValueObservingOptionInitial context:LocalBrowserSourcesContext];
		[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:@"OSIRIXSERVERS" options:NSKeyValueObservingOptionInitial context:RemoteBrowserSourcesContext];
		[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:DicomBrowserSourcesContext];
		_bonjourSources = [[NSMutableDictionary alloc] init];
		[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:@"DoNotSearchForBonjourServices" options:NSKeyValueObservingOptionInitial context:SearchBonjourNodesContext];
		_nsb = [[NSNetServiceBrowser alloc] init];
		[_nsb setDelegate:self];
		[_nsb searchForServicesOfType:@"_osirixdb._tcp." inDomain:@""];
	}
	
	return self;
}

-(void)dealloc {
	[_nsb release]; _nsb = nil;
	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:@"DoNotSearchForBonjourServices"];
	[_bonjourSources dealloc];
	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:@"SERVERS"];
	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:@"OSIRIXSERVERS"];
	[NSUserDefaultsController.sharedUserDefaultsController removeObserver:self forValuesKey:@"localDatabasePaths"];
//	[[NSUserDefaults.standardUserDefaults objectForKey:@"localDatabasePaths"] removeObserver:self forValuesKey:@"values"];
	_browser = nil;
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	NSKeyValueChange changeKind = [[change valueForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
	
	if (context == LocalBrowserSourcesContext) {
		NSArray* a = [NSUserDefaults.standardUserDefaults objectForKey:@"localDatabasePaths"];
		// remove old items
		for (NSInteger i = [[_browser.sources arrangedObjects] count]-1; i >= 0; --i) {
			BrowserSource* is = [_browser.sources.arrangedObjects objectAtIndex:i];
			if (is.type == BrowserSourceTypeLocal && ![is isKindOfClass:DefaultBrowserSource.class])
				if (![[a valueForKey:@"Path"] containsObject:is.location])
					[_browser.sources removeObjectAtArrangedObjectIndex:i];
		}
		// add new items
		for (NSDictionary* d in a) {
			NSString* dpath = [d valueForKey:@"Path"];
			if (![[_browser.sources.arrangedObjects valueForKey:@"location"] containsObject:dpath])
				[_browser.sources addObject:[BrowserSource browserSourceForLocalPath:dpath description:[d objectForKey:@"Description"] dictionary:d]];
		}
	}
	
	if (context == RemoteBrowserSourcesContext) {
		NSArray* a = [NSUserDefaults.standardUserDefaults objectForKey:@"OSIRIXSERVERS"];
		// remove old items
		for (NSInteger i = [[_browser.sources arrangedObjects] count]-1; i >= 0; --i) {
			BrowserSource* is = [_browser.sources.arrangedObjects objectAtIndex:i];
			if (is.type == BrowserSourceTypeRemote)
				if (![[a valueForKey:@"Address"] containsObject:is.location])
					[_browser.sources removeObjectAtArrangedObjectIndex:i];
		}
		// add new items
		for (NSDictionary* d in a) {
			NSString* dadd = [d valueForKey:@"Address"];
			if (![[_browser.sources.arrangedObjects valueForKey:@"location"] containsObject:dadd])
				[_browser.sources addObject:[BrowserSource browserSourceForAddress:dadd description:[d objectForKey:@"Description"] dictionary:d]];
		}
	}
	
	if (context == DicomBrowserSourcesContext) {
		NSArray* a = [NSUserDefaults.standardUserDefaults objectForKey:@"SERVERS"];
		// remove old items
		for (NSInteger i = [[_browser.sources arrangedObjects] count]-1; i >= 0; --i) {
			BrowserSource* is = [_browser.sources.arrangedObjects objectAtIndex:i];
			if (is.type == BrowserSourceTypeDicom)
				if (![[a valueForKey:@"Address"] containsObject:is.location])
					[_browser.sources removeObjectAtArrangedObjectIndex:i];
		}
		// add new items
		for (NSDictionary* d in a) {
			NSString* dadd = [d valueForKey:@"Address"];
			
			if (![[_browser.sources.arrangedObjects valueForKey:@"location"] containsObject:dadd])
				[_browser.sources addObject:[BrowserSource browserSourceForDicomNodeAtAddress:dadd description:[d objectForKey:@"Description"] dictionary:d]];
		}
	}
	
	// showhide bonjour sources
}

-(void)netServiceDidResolveAddress:(NSNetService*)service {
	BrowserSource* source = [_bonjourSources objectForKey:[NSValue valueWithPointer:service]];
	if (!source) return;
	
	NSLog(@"Detected remote database: %@", service);
	
	NSMutableArray* addresses = [NSMutableArray array];
	for (NSData* address in service.addresses) {
        struct sockaddr* sockAddr = (struct sockaddr*)address.bytes;
		if (sockAddr->sa_family == AF_INET) {
			struct sockaddr_in* sockAddrIn = (struct sockaddr_in*)sockAddr;
			NSString* host = [NSString stringWithUTF8String:inet_ntoa(sockAddrIn->sin_addr)];
			NSInteger port = ntohs(sockAddrIn->sin_port);
			[addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
		} else
		if (sockAddr->sa_family == AF_INET6) {
			struct sockaddr_in6* sockAddrIn6 = (struct sockaddr_in6*)sockAddr;
			char buffer[256];
			const char* rv = inet_ntop(AF_INET6, &sockAddrIn6->sin6_addr, buffer, sizeof(buffer));
			NSString* host = [NSString stringWithUTF8String:buffer];
			NSInteger port = ntohs(sockAddrIn6->sin6_port);
			[addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
		}
	}
	
	NSArray* selfAddresses = NSHost.currentHost.addresses;
	BOOL isMe = NO;
	for (NSArray* address in addresses) {
		// NSLog(@"\t%@:%@", [address objectAtIndex:0], [address objectAtIndex:1]);
		if (!source.location)
			source.location = [[address objectAtIndex:0] stringByAppendingFormat:@":%@", [address objectAtIndex:1]];
		if (!isMe && [selfAddresses containsObject:[address objectAtIndex:0]] && [[address objectAtIndex:1] integerValue] == [BonjourPublisher.currentPublisher OsiriXDBCurrentPort])
			isMe = YES;
	}
	
	if (isMe) {
		// NSLog(@"\t\tIt's me!");
		[_bonjourSources removeObjectForKey:[NSValue valueWithPointer:service]];
		return;
	}
	
	//	if (![NSUserDefaults.standardUserDefaults boolForKey:@"DoNotSearchForBonjourServices"])
		if (source.location)
			[_browser.sources addObject:source];
}

-(void)netService:(NSNetService*)service didNotResolve:(NSDictionary*)errorDict {
	[_bonjourSources removeObjectForKey:[NSValue valueWithPointer:service]];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	// NSLog(@"Remote OsiriX database detected: %@", service);
	NSNetService* me = [[BonjourPublisher currentPublisher] netService];
	
	BonjourBrowserSource* source = [BonjourBrowserSource browserSourceForAddress:nil description:service.name dictionary:nil];
	source.service = service;
	[_bonjourSources setObject:source forKey:[NSValue valueWithPointer:service]];
	
	// resolve the address and port for this NSNetService
	[service setDelegate:self];
	[service resolveWithTimeout:5];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	BrowserSource* source = [_bonjourSources objectForKey:[NSValue valueWithPointer:service]];
	if (!source) return;
	
	NSLog(@"Remote database gone: %@", service);
	
//	if (![NSUserDefaults.standardUserDefaults boolForKey:@"DoNotSearchForBonjourServices"])
		[_browser.sources removeObject:source];
	
	[_bonjourSources removeObjectForKey:[NSValue valueWithPointer:service]];
	
	NSLog(@"TODO: THIS!!! e-irhesidhieieh if db is alive, kill kill kill it NOW");
}

-(NSString*)tableView:(NSTableView*)tableView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
	BrowserSource* bs = [_browser sourceAtRow:row];
	return bs.location;
}

-(void)tableView:(NSTableView*)aTableView willDisplayCell:(ImageAndTextCell*)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row {
	cell.image = nil;
	cell.lastImage = nil;
	cell.lastImageAlternate = nil;
	cell.font = [NSFont systemFontOfSize:11];
	BrowserSource* bs = [_browser sourceAtRow:row];
	[bs willDisplayCell:cell];
}


-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSInteger selectedDatabaseIndex = [_browser rowForDatabase:_browser.database];
	if (row == selectedDatabaseIndex)
		return NSDragOperationNone;
	
	if (row >= _browser.sourcesCount && _browser.database != DicomDatabase.defaultDatabase) {
		[tableView setDropRow:[_browser rowForDatabase:DicomDatabase.defaultDatabase] dropOperation:NSTableViewDropOn];
		return NSTableViewDropAbove;
	}
	
	if (row < [_browser sourcesCount]) {
		[tableView setDropRow:row dropOperation:NSTableViewDropOn];
		return NSTableViewDropAbove;
	}
	
	return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	NSPasteboard* pb = [info draggingPasteboard];
	NSArray* xids = [pb propertyListForType:@"BrowserController.database.context.XIDs"];
	NSMutableArray* items = [NSMutableArray array];
	for (NSString* xid in xids)
		[items addObject:[_browser.database objectWithID:[NSManagedObject UidForXid:xid]]];
	
	NSString *filePath, *destPath;
	NSMutableArray* dicomImages = [DicomImage dicomImagesInObjects:items];
	[[NSMutableArray arrayWithArray:[dicomImages valueForKey:@"path"]] removeDuplicatedStringsInSyncWithThisArray:dicomImages]; // remove duplicated paths
	
	return [_browser copyImages:dicomImages toSource:[_browser sourceAtRow:row]];
}

-(void)tableViewSelectionDidChange:(NSNotification*)notification {
	NSInteger row = [(NSTableView*)notification.object selectedRow];
	BrowserSource* bs = [_browser sourceAtRow:row];
	[_browser setDatabaseFromSource:bs];
}

@end

@implementation DefaultBrowserSource

-(void)willDisplayCell:(ImageAndTextCell*)cell {
	cell.font = [NSFont boldSystemFontOfSize:11];
	cell.image = [NSImage imageNamed:@"osirix16x16.tif"];
}

-(NSString*)description {
	return NSLocalizedString(@"Local Default Database", nil);
}

-(NSComparisonResult)compare:(BrowserSource*)other {
	if ([self isKindOfClass:DefaultBrowserSource.class]) return NSOrderedAscending;
	else if ([other isKindOfClass:DefaultBrowserSource.class]) return NSOrderedDescending;
	return [super compare:other];
}

@end

@implementation BonjourBrowserSource

@synthesize service = _service;

-(void)dealloc {
	self.service = nil;
	[super dealloc];
}

-(void)willDisplayCell:(ImageAndTextCell*)cell {
	[super willDisplayCell:cell];
	
	NSImage* bonjour = [NSImage imageNamed:@"bonjour_whitebg.png"];
	
	NSImage* image = [[[NSImage alloc] initWithSize:cell.image.size] autorelease];
	[image lockFocus];
	[cell.image drawInRect:NSMakeRect(NSZeroPoint,cell.image.size) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	[bonjour drawInRect:NSMakeRect(1,1,14,14) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	[image unlockFocus];
	
	cell.image = image;
}

@end
