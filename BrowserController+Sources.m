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

#import "BrowserController+Sources.h"
#import "BrowserController+Sources+Copy.h"
#import "DataNodeIdentifier.h"
#import "PrettyCell.h"
#import "DicomDatabase.h"
#import "RemoteDicomDatabase.h"
#import "NSManagedObject+N2.h"
#import "DicomImage.h"
#import "MutableArrayCategory.h"
#import "NSImage+N2.h"
#import "NSUserDefaultsController+N2.h"
#import "N2Debug.h"
#import "NSThread+N2.h"
#import "N2Operators.h"
#import "ThreadModalForWindowController.h"
#import "BonjourPublisher.h"
#import "DicomFile.h"
#import "ThreadsManager.h"
#import "NSDictionary+N2.h"
#import "NSFileManager+N2.h"
#import "DCMNetServiceDelegate.h"
#import "AppController.h"
#import <netinet/in.h>
#import <arpa/inet.h>
#import "DicomDatabase+Scan.h"
#import "DCMPix.h"

#import "NSString+N2.h"

/*
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
*/

@interface BrowserSourcesHelper : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate>/*<NSTableViewDelegate,NSTableViewDataSource>*/
{
	BrowserController* _browser;
	NSNetServiceBrowser* _nsbOsirix;
	NSNetServiceBrowser* _nsbDicom;
	NSMutableDictionary* _bonjourSources;
}

-(id)initWithBrowser:(BrowserController*)browser;
-(void)_analyzeVolumeAtPath:(NSString*)path;

@end

@interface DefaultLocalDatabaseNodeIdentifier : LocalDatabaseNodeIdentifier

+(DefaultLocalDatabaseNodeIdentifier*)identifier;

@end

/*@interface BonjourDataNodeIdentifier : DataNodeIdentifier
{
	NSNetService* _service;
}

@property(retain) NSNetService* service;

-(NSInteger)port;

@end*/

@interface MountedDatabaseNodeIdentifier : LocalDatabaseNodeIdentifier
{
	NSString* _devicePath;
	DicomDatabase* _database;
    NSInteger _mountType;
    NSThread* _scanThread;
    NSButton* _unmountButton;
}

enum {
    MountTypeUndefined = 0,
    MountTypeIPod = 1
};

@property(retain) NSString* devicePath;
@property NSInteger mountType;

+(id)mountedDatabaseNodeIdentifierWithPath:(NSString*)devicePath description:(NSString*)description dictionary:(NSDictionary*)dictionary type:(NSInteger)type;

-(void)willUnmount;

@end

@interface UnavaliableDataNodeException : NSException
@end

@implementation BrowserController (Sources)

-(void)awakeSources
{
	[_sourcesArrayController setSortDescriptors:[NSArray arrayWithObjects: [[[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES] autorelease], NULL]];
	[_sourcesArrayController setAutomaticallyRearrangesObjects:YES];
	[_sourcesArrayController addObject:[DefaultLocalDatabaseNodeIdentifier identifier]];
	[_sourcesArrayController setSelectsInsertedObjects:NO];
	
	_sourcesHelper = [[BrowserSourcesHelper alloc] initWithBrowser:self];
	[_sourcesTableView setDataSource:_sourcesHelper];
	[_sourcesTableView setDelegate:_sourcesHelper];
	
	PrettyCell* cell = [[[PrettyCell alloc] init] autorelease];
	[[_sourcesTableView tableColumnWithIdentifier:@"Source"] setDataCell:cell];
	
	[_sourcesTableView registerForDraggedTypes:[NSArray arrayWithObject:O2AlbumDragType]];
	
	[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

-(void)deallocSources
{
	[_sourcesHelper release]; _sourcesHelper = nil;
}

-(NSInteger)sourcesCount
{
	return [[_sourcesArrayController arrangedObjects] count];
}

-(DataNodeIdentifier*)sourceIdentifierAtRow:(int)row
{
	return ([_sourcesArrayController.arrangedObjects count] > row)? [_sourcesArrayController.arrangedObjects objectAtIndex:row] : nil;
}

-(int)rowForSourceIdentifier:(DataNodeIdentifier*)source
{
	for (NSInteger i = 0; i < [[_sourcesArrayController arrangedObjects] count]; ++i)
		if ([[_sourcesArrayController.arrangedObjects objectAtIndex:i] isEqualToDataNodeIdentifier:source])
			return i;
	return -1;
}

-(DataNodeIdentifier*)sourceIdentifierForDatabase:(DicomDatabase*)database // TODO: move this to -[DicomDatabase dataNodeIdentifier]
{
	if (database == [DicomDatabase defaultDatabase])
		return [DefaultLocalDatabaseNodeIdentifier identifier];
	if (database.isLocal)
		return [LocalDatabaseNodeIdentifier localDatabaseNodeIdentifierWithPath:database.baseDirPath];
	else return [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:[RemoteDatabaseNodeIdentifier locationWithAddress:[(RemoteDicomDatabase*)database address] port:[(RemoteDicomDatabase*)database port]] description:nil dictionary:nil];	
}

-(int)rowForDatabase:(DicomDatabase*)database
{
	return [self rowForSourceIdentifier:[self sourceIdentifierForDatabase:database]];
}

-(void)selectSourceForDatabase:(DicomDatabase*)database
{
	NSInteger row = [self rowForDatabase:database];
	if (row >= 0)
		[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	else NSLog(@"Warning: couldn't find database in sources (%@)", database);
}

-(void)selectCurrentDatabaseSource
{
	if (!_database)
    {
		[_sourcesTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
		return;
	}
	
	NSInteger i = [self rowForDatabase:_database];
	if (i == -1 && _database != [DicomDatabase defaultDatabase])
    {
		[self rowForDatabase:_database];
		NSDictionary* source = [NSDictionary dictionaryWithObjectsAndKeys: [_database.baseDirPath stringByDeletingLastPathComponent], @"Path", [_database.baseDirPath.stringByDeletingLastPathComponent.lastPathComponent stringByAppendingString:@" DB"], @"Description", nil];
		[[NSUserDefaults standardUserDefaults] setObject:[[[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"] arrayByAddingObject:source] forKey:@"localDatabasePaths"];
		i = [self rowForDatabase:_database];
	}
    if (i != [_sourcesTableView selectedRow])
		[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}

-(void)setDatabaseThread:(NSArray*)io
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try
    {
		NSString* type = [io objectAtIndex:0];
		DicomDatabase* db = nil;
		
		if ([type isEqualToString:@"Local"])
        {
			NSString* path = [io objectAtIndex:1];
			if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            {
				NSString* message = NSLocalizedString(@"The selected database's data was not found on your computer.", nil);
				if ([path hasPrefix:@"/Volumes/"])
					  message = [message stringByAppendingFormat:@" %@", NSLocalizedString(@"If it is stored on an external drive? If so, please make sure the device in connected and on.", nil)];
				[NSException raise:NSGenericException format:@"%@", message];
			}
			
			NSString* name = io.count > 2? [io objectAtIndex:2] : nil;
			db = [DicomDatabase databaseAtPath:path name:name];
		}
		
		if ([type isEqualToString:@"Remote"])
        {
			NSString* address = [io objectAtIndex:1];
			NSInteger port = [[io objectAtIndex:2] intValue];
			NSString* name = io.count > 3? [io objectAtIndex:3] : nil;
			NSString* ap = [NSString stringWithFormat:@"%@:%d", address, port];
			db = [RemoteDicomDatabase databaseForLocation:ap name:name];
		}
		
		[self performSelectorOnMainThread:@selector(setDatabase:) withObject:db waitUntilDone:NO];
	} @catch (NSException* e)
    {
		[self performSelectorOnMainThread:@selector(selectCurrentDatabaseSource) withObject:nil waitUntilDone:NO];
		if (![e.description isEqualToString:@"Cancelled."])
        {
			N2LogExceptionWithStackTrace(e);
			[self performSelectorOnMainThread:@selector(_complain:) withObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:0.1], NSLocalizedString(@"Error", nil), e.description, NULL] waitUntilDone:NO];
		}
	} @finally
    {
		[pool release];
	}
}

-(void)_complain:(NSArray*)why { // if 1st obj in array is a number then execute this after the delay specified by that number, with the rest of the array
	if ([[why objectAtIndex:0] isKindOfClass:[NSNumber class]])
		[self performSelector:@selector(_complain:) withObject:[why subarrayWithRange:NSMakeRange(1, why.count-1)] afterDelay:[[why objectAtIndex:0] floatValue]];
	else NSBeginAlertSheet([why objectAtIndex:0], nil, nil, nil, self.window, NSApp, @selector(endSheet:), nil, nil, [why objectAtIndex:1]);
}

-(NSThread*)initiateSetDatabaseAtPath:(NSString*)path name:(NSString*)name
{
	NSArray* io = [NSMutableArray arrayWithObjects: @"Local", path, name, nil];
	
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io] autorelease];
	thread.name = NSLocalizedString(@"Loading OsiriX database...", nil);
	thread.supportsCancel = YES;
	thread.status = NSLocalizedString(@"Reading data...", nil);
	
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return thread;
}

-(NSThread*)initiateSetRemoteDatabaseWithAddress:(NSString*)address port:(NSInteger)port name:(NSString*)name
{
	NSArray* io = [NSMutableArray arrayWithObjects: @"Remote", address, [NSNumber numberWithInteger:port], name, nil];
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io];
	thread.name = NSLocalizedString(@"Loading remote OsiriX database...", nil);
	thread.supportsCancel = YES;
	ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
	[thread start];
	
	return [thread autorelease];
}

-(void)setDatabaseFromSourceIdentifier:(DataNodeIdentifier*)dni
{
	if ([dni isEqualToDataNodeIdentifier:[self sourceIdentifierForDatabase:_database]])
		return;
	
    @try
    {
        DicomDatabase* db = [dni database];
        
        if (db) 
            [self setDatabase:db];
        else
            if ([dni isKindOfClass:[LocalDatabaseNodeIdentifier class]])
                [self initiateSetDatabaseAtPath:dni.location name:dni.description];
            else if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]]) {
                NSString* host; NSInteger port; [RemoteDatabaseNodeIdentifier location:dni.location toAddress:&host port:&port];
                [self initiateSetRemoteDatabaseWithAddress:host port:port name:dni.description];
            } else {
                [UnavaliableDataNodeException raise:NSGenericException format:@"%@", NSLocalizedString(@"This is a DICOM destination node: you cannot browse its content. You can only drag & drop studies on them.", nil)];
            }
    } @catch (UnavaliableDataNodeException* e)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Sources", nil), nil, nil, nil, self.window, NSApp, @selector(endSheet:), nil, nil, [e reason]);
        [self selectCurrentDatabaseSource];
    }
}

-(void)redrawSources
{
	[_sourcesTableView setNeedsDisplay:YES];
}

-(long)currentBonjourService { // __deprecated
	return [_sourcesTableView selectedRow]-1;
}

-(void)setCurrentBonjourService:(int)index { // __deprecated
	[_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index+1] byExtendingSelection:NO];
}

-(int)findDBPath:(NSString*)path dbFolder:(NSString*)DBFolderLocation { // __deprecated
	NSInteger i = [self rowForSourceIdentifier:[LocalDatabaseNodeIdentifier localDatabaseNodeIdentifierWithPath:path]];
	if (i < 0) i = [self rowForSourceIdentifier:[LocalDatabaseNodeIdentifier localDatabaseNodeIdentifierWithPath:DBFolderLocation]];
	return i;
}

@end

@implementation BrowserSourcesHelper

static void* const LocalBrowserSourcesContext = @"LocalBrowserSourcesContext";
static void* const RemoteBrowserSourcesContext = @"RemoteBrowserSourcesContext";
static void* const DicomBrowserSourcesContext = @"DicomBrowserSourcesContext";
static void* const SearchBonjourNodesContext = @"SearchBonjourNodesContext";
static void* const SearchDicomNodesContext = @"SearchDicomNodesContext";

-(id)initWithBrowser:(BrowserController*)browser
{
	if ((self = [super init]))
    {
		_browser = browser;
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"localDatabasePaths" options:NSKeyValueObservingOptionInitial context:LocalBrowserSourcesContext];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"OSIRIXSERVERS" options:NSKeyValueObservingOptionInitial context:RemoteBrowserSourcesContext];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"SERVERS" options:NSKeyValueObservingOptionInitial context:DicomBrowserSourcesContext];
		_bonjourSources = [[NSMutableDictionary alloc] init];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"searchDICOMBonjour" options:NSKeyValueObservingOptionInitial context:SearchDicomNodesContext];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:@"DoNotSearchForBonjourServices" options:NSKeyValueObservingOptionInitial context:SearchBonjourNodesContext];
        _nsbOsirix = [[NSNetServiceBrowser alloc] init];
		[_nsbOsirix setDelegate:self];
		[_nsbOsirix searchForServicesOfType:@"_osirixdb._tcp." inDomain:@""];
		_nsbDicom = [[NSNetServiceBrowser alloc] init];
		[_nsbDicom setDelegate:self];
		[_nsbDicom searchForServicesOfType:@"_dicom._tcp." inDomain:@""];
		// mounted devices
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidUnmountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeWillUnmountNotification:) name:NSWorkspaceWillUnmountNotification object:nil];
		for (NSString* path in [[NSWorkspace sharedWorkspace] mountedRemovableMedia])
			[self _analyzeVolumeAtPath:path];
	}
	
	return self;
}

-(void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidMountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidUnmountNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceWillUnmountNotification object:nil];
	[_nsbDicom release]; _nsbDicom = nil;
	[_nsbOsirix release]; _nsbOsirix = nil;
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"DoNotSearchForBonjourServices"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"searchDICOMBonjour"];
	[_bonjourSources release];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SERVERS"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"OSIRIXSERVERS"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"localDatabasePaths"];
//	[[[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"] removeObserver:self forValuesKey:@"values"];
	_browser = nil;
	[super dealloc];
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
    [self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, object, change, [NSValue valueWithPointer:context], nil] waitUntilDone:NO];
        return;
    }
    
    NSKeyValueChange changeKind = [[change valueForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
	
	if (context == LocalBrowserSourcesContext)
    {
		NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"];
        // remove old items
		for (DataNodeIdentifier* dni in [[_browser.sources.content copy] autorelease])
        {
			if ([dni isKindOfClass:[LocalDatabaseNodeIdentifier class]] && dni.entered) // is a local database and is flagged as "entered"
				if (![[a valueForKey:@"Path"] containsObject:dni.location]) {          // is no longer in the entered list
					dni.entered = NO;                                                 // mark it as not entered
                    if (!dni.detected)
                        [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                }
		}
		// add new items
		for (NSDictionary* d in a)
        {
			NSString* dpath = [d valueForKey:@"Path"];
			if ([[DicomDatabase baseDirPathForPath:dpath] isEqualToString:DicomDatabase.defaultDatabase.baseDirPath]) // is already listed as "default database"
				continue;
            DataNodeIdentifier* dni;
			NSUInteger i = [[_browser.sources.content valueForKey:@"location"] indexOfObject:dpath];
			if (i == NSNotFound) {
                dni = [LocalDatabaseNodeIdentifier localDatabaseNodeIdentifierWithPath:dpath description:[d objectForKey:@"Description"] dictionary:d];
                dni.entered = YES;
				[_browser.sources addObject:dni];
			} else {
                dni = [_browser.sources.content objectAtIndex:i];
                dni.entered = YES;
				dni.description = [d objectForKey:@"Description"];
				dni.dictionary = d;
			}
		}
	}
	
	if (context == RemoteBrowserSourcesContext)
    {
		NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"OSIRIXSERVERS"];
		// remove old items
		for (DataNodeIdentifier* dni in [[_browser.sources.content copy] autorelease])
        {
			if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && dni.entered) // is a remote database and is flagged as "entered"
				if (![[a valueForKey:@"Address"] containsObject:dni.location]) {        // is no longer in the entered list
					dni.entered = NO;                                                  // mark it as not entered
                    if (!dni.detected)
                        [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                }
		}
		// add new items
		for (NSDictionary* d in a)
        {
			NSString* dadd = [d valueForKey:@"Address"];
            DataNodeIdentifier* dni;
			NSUInteger i = [[_browser.sources.content valueForKey:@"location"] indexOfObject:dadd];
			if (i == NSNotFound) {
                dni = [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:dadd description:[d objectForKey:@"Description"] dictionary:d];
                dni.entered = YES;
				[_browser.sources addObject:dni];
			} else {
                dni = [_browser.sources.content objectAtIndex:i];
                dni.entered = YES;
                dni.description = [d objectForKey:@"Description"];
				dni.dictionary = d;
			}
		}
	}
	
	if (context == DicomBrowserSourcesContext)
    {
		NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"SERVERS"];
		NSMutableDictionary* aa = [NSMutableDictionary dictionary];
		for (NSDictionary* ai in a)
			[aa setObject:ai forKey:[DicomNodeIdentifier locationWithAddress:[ai objectForKey:@"Address"] port:[[ai objectForKey:@"Port"] integerValue] aet:[ai objectForKey:@"AETitle"]]];
		// remove old items
		for (DataNodeIdentifier* dni in [[_browser.sources.content copy] autorelease])
        {
			if ([dni isKindOfClass:[DicomNodeIdentifier class]] && dni.entered) // is a dicom node and is flagged as "entered"
				if (![[aa allKeys] containsObject:dni.location]) {             // is no longer in the entered list
					dni.entered = NO;                                         // mark it as not entered
                    if (!dni.detected)
                        [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                }
		}
		// add new items
		for (NSString* aak in aa)
        {
            DataNodeIdentifier* dni;
			NSUInteger i = [[_browser.sources.content valueForKey:@"location"] indexOfObject:aak];
			if (i == NSNotFound) {
				dni = [DicomNodeIdentifier dicomNodeIdentifierWithLocation:aak description:[[aa objectForKey:aak] objectForKey:@"Description"] dictionary:[aa objectForKey:aak]];
                dni.entered = YES;
                [_browser.sources addObject:dni];
			} else {
                dni = [_browser.sources.content objectAtIndex:i];
                dni.entered = YES;
				dni.dictionary = [aa objectForKey:aak];
                dni.description = [dni.dictionary objectForKey:@"Description"];
			}
		}
	}
	
	if (context == SearchBonjourNodesContext)
    {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) // add remote databases detected with bonjour
        { // remove remote databases detected with bonjour
			for (DataNodeIdentifier* dni in _bonjourSources.allValues)
				if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && dni.detected) {
                    dni.detected = NO;
                    if (!dni.entered && [_browser.sources.content containsObject:dni])
                        [_browser.sources removeObject:dni];
                }
		} else 
        { // add remote databases detected with bonjour
			for (DataNodeIdentifier* dni in _bonjourSources.allValues)
				if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && !dni.detected && dni.location) {
					dni.detected = YES;
                    if (![_browser.sources.content containsObject:dni])
                        [_browser.sources addObject:dni];
                }
		}
	}
	
	if (context == SearchDicomNodesContext)
    {
		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])
        { // remove dicom nodes detected with bonjour
			for (DataNodeIdentifier* dni in _bonjourSources.allValues)
				if ([dni isKindOfClass:[DicomNodeIdentifier class]] && dni.detected) {
                    dni.detected = NO;
                    if (!dni.entered && [_browser.sources.content containsObject:dni])
                        [_browser.sources removeObject:dni];
                }
		} else
        { // add dicom nodes detected with bonjour
			for (DataNodeIdentifier* dni in _bonjourSources.allValues)
				if ([dni isKindOfClass:[DicomNodeIdentifier class]] && !dni.detected && dni.location) {
					dni.detected = YES;
                    if (![_browser.sources.content containsObject:dni])
                        [_browser.sources addObject:dni];
                }
		}
	}
	
	// showhide bonjour sources
}

-(void)netServiceDidResolveAddress:(NSNetService*)service
{
    NSValue* key = [NSValue valueWithPointer:service];
    DataNodeIdentifier* source = [_bonjourSources objectForKey:key];
	if (!source) return;
    
    NSHost* host = [NSHost hostWithName:service.hostName];
    if ([host isEqualToHost:[NSHost currentHost]]) // it's from this machine, but is it from this instance of OsiriX ?
        if ([service isEqual:[[BonjourPublisher currentPublisher] netService]] || [service isEqual:[[AppController sharedAppController] dicomBonjourPublisher]]) {
            [_bonjourSources removeObjectForKey:key];
            return; // it's me
        }
    
	NSMutableArray* addresses = [NSMutableArray array];
	for (NSData* address in service.addresses)
    {
        struct sockaddr* sockAddr = (struct sockaddr*)address.bytes;
		if (sockAddr->sa_family == AF_INET)
        {
			struct sockaddr_in* sockAddrIn = (struct sockaddr_in*)sockAddr;
			NSString* host = [NSString stringWithUTF8String:inet_ntoa(sockAddrIn->sin_addr)];
			NSInteger port = ntohs(sockAddrIn->sin_port);
			[addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
		}
        else if (sockAddr->sa_family == AF_INET6)
        {
			struct sockaddr_in6* sockAddrIn6 = (struct sockaddr_in6*)sockAddr;
			char buffer[256];
			const char* rv = inet_ntop(AF_INET6, &sockAddrIn6->sin6_addr, buffer, sizeof(buffer));
			NSString* host = [NSString stringWithUTF8String:buffer];
			NSInteger port = ntohs(sockAddrIn6->sin6_port);
			[addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
		}
	}
	
	for (NSArray* address in addresses)
    {
		// NSLog(@"\t%@:%@", [address objectAtIndex:0], [address objectAtIndex:1]);
		if (!source.location)
			if ([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
				source.location = [[address objectAtIndex:0] stringByAppendingFormat:@":%@", [address objectAtIndex:1]];
			else source.location = [service.name stringByAppendingFormat:@"@%@:%@", [address objectAtIndex:0], [address objectAtIndex:1]];
	}
	
    NSUInteger i = [_browser.sources.content indexOfObject:source];
    if (i != NSNotFound) // Already known
        [_bonjourSources setObject:(source = [_browser.sources.content objectAtIndex:i]) forKey:key];
    
	if ([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
		source.dictionary = [BonjourPublisher dictionaryFromXTRecordData:service.TXTRecordData];
	else source.dictionary = [DCMNetServiceDelegate DICOMNodeInfoFromTXTRecordData:service.TXTRecordData];
		
	if (source.location)
    {
		NSLog(@" -> Adding %@", source.location);
		if (([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) || 
            ([source isKindOfClass:[DicomNodeIdentifier class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])) {
			
            source.detected = YES;
            if (![_browser.sources.content containsObject:source])
                [_browser.sources addObject:source];
        }
	}
}

-(void)netService:(NSNetService*)service didNotResolve:(NSDictionary*)errorDict
{
	[_bonjourSources removeObjectForKey:[NSValue valueWithPointer:service]];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{
	NSLog(@"Bonjour service found: %@", service);
	
	DataNodeIdentifier* source;
	if (nsb == _nsbOsirix)
		source = [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:nil description:service.name dictionary:nil];
	else source = [DicomNodeIdentifier dicomNodeIdentifierWithLocation:nil description:service.name dictionary:nil];
	
//    source.discovered = YES;
//	source.service = service;
	[_bonjourSources setObject:source forKey:[NSValue valueWithPointer:[service retain]]];
	
	// resolve the address and port for this NSNetService
	[service setDelegate:self];
	[service resolveWithTimeout:5];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing
{
	if (nsb == _nsbOsirix)
		if ([service isEqual:[[BonjourPublisher currentPublisher] netService]])
			return; // it's me
	if (nsb == _nsbDicom)
		if ([service isEqual:[[AppController sharedAppController] dicomBonjourPublisher]])
			return; // it's me
	
	NSLog(@"Bonjour service gone: %@", service);
	
    NSValue* bsk = nil;
    for (NSValue* ibsk in _bonjourSources) {
        NSNetService* ibsks = [ibsk pointerValue];
		if ([ibsks isEqual:service]) {
			bsk = ibsk;
            break;
        }
    }
	if (!bsk)
		return;
    DataNodeIdentifier* dni = [_bonjourSources objectForKey:bsk];
	
    if (([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) ||
        ([dni isKindOfClass:[DicomNodeIdentifier class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])) {
        
        dni.detected = NO;
        if (!dni.entered && [_browser.sources.content containsObject:dni])
            [_browser.sources removeObject:dni];
    }
	
    // if the disappearing node is active, seelct the default DB
	if ([[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:dni])
		[_browser setDatabase:DicomDatabase.defaultDatabase];
	
    [(id)[bsk pointerValue] release]; // release the NSNetService
	[_bonjourSources removeObjectForKey:bsk];
}

-(void)_analyzeVolumeAtPath:(NSString*)path
{
	BOOL used = NO;
	for (DataNodeIdentifier* ibs in _browser.sources.arrangedObjects)
		if ([ibs isKindOfClass:[LocalDatabaseNodeIdentifier class]] && [ibs.location hasPrefix:path])
			return; // device is somehow already listed as a source
	
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/sbin/diskutil"];
	[task setArguments:[NSArray arrayWithObjects: @"info", @"-plist", path, NULL]];
	[task setStandardError:[NSPipe pipe]];
	[task setStandardOutput:[task standardError]];
	[task launch];
	[task waitUntilExit];
	NSData* output = [[[[[task standardError] fileHandleForReading] readDataToEndOfFile] retain] autorelease];
	[task release];
	
	NSDictionary* result = [NSPropertyListSerialization propertyListFromData:output mutabilityOption:NSPropertyListImmutable format:0 errorDescription:NULL];

	if ([[result objectForKey:@"OpticalMediaType"] length]) // is CD/DVD or other optical media
		@try {
			[_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeUndefined]];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
	
    if ([[result objectForKey:@"MediaType"] isEqualToString:@"iPod"])
        @try {
			[_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeIPod]];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
	
	
/*	OSStatus err;
	kern_return_t kr;
	
	FSRef ref;
	err = FSPathMakeRef((const UInt8*)[path fileSystemRepresentation], &ref, nil);
	if (err != noErr) return;
	FSCatalogInfo catInfo;
	err = FSGetCatalogInfo(&ref, kFSCatInfoVolume, &catInfo, nil, nil, nil);
	if (err != noErr) return;
	
	GetVolParmsInfoBuffer gvpib;
	HParamBlockRec hpbr;
	hpbr.ioParam.ioNamePtr = NULL;
	hpbr.ioParam.ioVRefNum = catInfo.volume;
	hpbr.ioParam.ioBuffer = (Ptr)&gvpib;
	hpbr.ioParam.ioReqCount = sizeof(gvpib);
	err = PBHGetVolParmsSync(&hpbr);
	if (err != noErr) return;
	
	NSString* bsdName = [NSString stringWithCString:(char*)gvpib.vMDeviceID];
	NSLog(@"we are mounting %@ ||| %@", path, bsdName);
	
	CFDictionaryRef matchingDict = IOBSDNameMatching(kIOMasterPortDefault, 0, (const char*)gvpib.vMDeviceID);
	io_iterator_t ioIterator = nil;
	kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &ioIterator);
	if (kr != kIOReturnSuccess) return;
	
	io_service_t ioService;
	while (ioService = IOIteratorNext(ioIterator)) {
		CFTypeRef data = IORegistryEntrySearchCFProperty(ioService, kIOServicePlane, CFSTR("BSD Name"), kCFAllocatorDefault, kIORegistryIterateRecursively);
		NSLog(@"\t%@", data);
		io_name_t ioName;
		IORegistryEntryGetName(ioService, ioName);
		NSLog(@"\t\t%s", ioName);
		
		CFRelease(data);
		IOObjectRelease(ioService);
	}
	
	IOObjectRelease(ioIterator);*/
}

-(void)_observeVolumeNotification:(NSNotification*)notification
{
	NSString* path = [notification.userInfo objectForKey:@"NSDevicePath"];

	[_browser redrawSources];
	
	if ([notification.name isEqualToString:NSWorkspaceDidMountNotification])
    {
		[self _analyzeVolumeAtPath:[notification.userInfo objectForKey:@"NSDevicePath"]];
	}
    
    if ([notification.name isEqualToString:NSWorkspaceDidUnmountNotification])
    {
        MountedDatabaseNodeIdentifier* mbs = nil;
        for (MountedDatabaseNodeIdentifier* ibs in _browser.sources.arrangedObjects)
            if ([ibs isKindOfClass:[MountedDatabaseNodeIdentifier class]] && [ibs.devicePath isEqualToString:path])
            {
                mbs = ibs;
                break;
            }
        if (mbs)
        {
            if ([[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:mbs])
                [_browser setDatabase:DicomDatabase.defaultDatabase];
            [_browser.sources removeObject:mbs];
        }
    }
	
//	for (BrowserSource* bs in _browser.sources)
//		if (bs.type == BrowserSourceTypeLocal && [bs.location hasPrefix:root]) {
//			NSButton* button = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 16, 16)] autorelease];
//			button.image = [NSImage imageNamed:@"iPodEjectOff.tif"];
//			button.alternateImage = [NSImage imageNamed:@"iPodEjectOn.tif"];
//			button.gradientType = NSGradientNone;
//			button.bezelStyle = 0;
//			bs.extraView = button;
//		}
			
}


-(void)_observeVolumeWillUnmountNotification:(NSNotification*)notification
{
	NSString* path = [notification.userInfo objectForKey:@"NSDevicePath"];
	
    [DCMPix purgeCachedDictionaries];
    
	MountedDatabaseNodeIdentifier* mbs = nil;
	for (MountedDatabaseNodeIdentifier* ibs in _browser.sources.arrangedObjects)
		if ([ibs isKindOfClass:[MountedDatabaseNodeIdentifier class]] && [ibs.devicePath isEqualToString:path])
        {
			mbs = ibs;
			break;
		}
    
	if (mbs)
        [mbs willUnmount];
    
    if (mbs && [[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:mbs])
    {
        DicomDatabase* db = [DicomDatabase activeLocalDatabase];
        if (db == _browser.database)
            db = [DicomDatabase defaultDatabase];
        [_browser setDatabase:db];
    }
}

-(NSString*)tableView:(NSTableView*)tableView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
	NSString* tip = [bs toolTip];
	if (tip) return tip;
	return bs.location;
}

-(void)tableView:(NSTableView*)aTableView willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	cell.image = nil;
	cell.font = [NSFont systemFontOfSize:11];
	cell.textColor = nil;
    [cell.rightSubviews removeAllObjects];
	DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
    cell.title = bs.description;
	[bs willDisplayCell:cell];
}


-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	NSInteger selectedDatabaseIndex = [_browser rowForDatabase:_browser.database];
	if (row == selectedDatabaseIndex)
		return NSDragOperationNone;
	
	if (row >= _browser.sourcesCount && _browser.database != DicomDatabase.defaultDatabase)
    {
		[tableView setDropRow:[_browser rowForDatabase:DicomDatabase.defaultDatabase] dropOperation:NSTableViewDropOn];
		return NSTableViewDropAbove;
	}
	
	if (row < [_browser sourcesCount])
    {
		if ([[_browser sourceIdentifierAtRow:row] isReadOnly])
			return NSDragOperationNone;
		[tableView setDropRow:row dropOperation:NSTableViewDropOn];
		return NSTableViewDropAbove;
	}
	
	return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	NSArray* xids = [NSPropertyListSerialization propertyListFromData:[pb propertyListForType:@"BrowserController.database.context.XIDs"] 
													 mutabilityOption:NSPropertyListImmutable 
															   format:NULL 
													 errorDescription:NULL];
	NSMutableArray* items = [NSMutableArray array];
	for (NSString* xid in xids)
		[items addObject:[_browser.database objectWithID:[NSManagedObject UidForXid:xid]]];
	
	NSString *filePath, *destPath;
	NSMutableArray* dicomImages = [DicomImage dicomImagesInObjects:items];
	[[NSMutableArray arrayWithArray:[dicomImages valueForKey:@"path"]] removeDuplicatedStringsInSyncWithThisArray:dicomImages]; // remove duplicated paths
	
	return [_browser initiateCopyImages:dicomImages toSource:[_browser sourceIdentifierAtRow:row]];
}

-(void)tableViewSelectionDidChange:(NSNotification*)notification
{
	NSInteger row = [(NSTableView*)notification.object selectedRow];
	DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
	[_browser setDatabaseFromSourceIdentifier:bs];
}

@end

@implementation DefaultLocalDatabaseNodeIdentifier

+(DefaultLocalDatabaseNodeIdentifier*)identifier
{
	static DefaultLocalDatabaseNodeIdentifier* identifier = nil;
	if (!identifier)
		identifier = [[[self class] localDatabaseNodeIdentifierWithPath:DicomDatabase.defaultDatabase.baseDirPath] retain];
	return identifier;
}

-(void)willDisplayCell:(PrettyCell*)cell
{
	cell.font = [NSFont boldSystemFontOfSize:11];
	cell.image = [NSImage imageNamed:@"osirix16x16.tif"];
}

-(NSString*)description
{
	return NSLocalizedString(@"Local Default Database", nil);
}

-(CGFloat)sortValue {
	return CGFLOAT_MIN;
}

@end

/*@implementation BonjourDataNodeIdentifier

@synthesize service = _service;

-(void)dealloc
{
	self.service = nil;
	[super dealloc];
}

-(void)willDisplayCell:(PrettyCell*)cell
{
	[super willDisplayCell:cell];
	
	NSImage* bonjour = [NSImage imageNamed:@"bonjour_whitebg.png"];
	
	NSImage* image = [[[NSImage alloc] initWithSize:cell.image.size] autorelease];
	[image lockFocus];
	[cell.image drawInRect:NSMakeRect(0,0,cell.image.size.width,cell.image.size.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	[bonjour drawInRect:NSMakeRect(1,1,14,14) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
	[image unlockFocus];
	
	cell.image = image;
}

-(NSInteger)port
{
	NSInteger port;
	[RemoteDicomDatabase address:self.location toHost:NULL port:&port];
	return port;
}

@end*/


@implementation MountedDatabaseNodeIdentifier

@synthesize devicePath = _devicePath;
@synthesize mountType = _mountType;

-(id)init
{
    if ((self = [super init]))
    {
        _unmountButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,14,14)];
        _unmountButton.image = [NSImage imageNamed:@"Eject_gray"];
        _unmountButton.image.size = NSMakeSize(10,11);
        _unmountButton.alternateImage = [NSImage imageNamed:@"Eject_lightgray"];
        _unmountButton.alternateImage.size = NSMakeSize(10,11);
        _unmountButton.imagePosition = NSImageOnly;
        _unmountButton.bezelStyle = 0;
        [_unmountButton setButtonType:NSMomentaryLightButton];
        [_unmountButton setBordered:NO];
        NSButtonCell* cell = _unmountButton.cell;
        cell.gradientType = NSGradientNone;
        [cell setHighlightsBy:NSContentsCellMask];
        
        _unmountButton.target = self;
        _unmountButton.action = @selector(_eject:);
    }

    return self;
}

-(void)_eject:(id)sender
{
    [[NSWorkspace sharedWorkspace] performSelectorInBackground:@selector(unmountAndEjectDeviceAtPath:) withObject:self.devicePath];
}

-(void)initiateVolumeScan
{
	_database = [[DicomDatabase databaseAtPath:self.location] retain];
    _database.isReadOnly = YES;
    _database.name = self.description;
	for (NSManagedObject* obj in _database.albums)
		[_database.managedObjectContext deleteObject:obj];
	[self performSelectorInBackground:@selector(volumeScanThread) withObject:nil];
}

-(void)volumeScanThread
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	@try
    {
		NSThread* thread = [NSThread currentThread];
        @synchronized (self)
        {
            _scanThread = thread;
        }
        
		thread.name = NSLocalizedString(@"Scanning disc...", nil);
		[[ThreadsManager defaultManager] addThreadAndStart:thread];
		[_database scanAtPath:self.devicePath];
		
		if (![[_database objectsForEntity:_database.imageEntity] count])
        {
			[[[BrowserController currentBrowser] sources] removeObject:self];
			return;
		}
		
        self.detected = YES;
        
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoSelectSourceCDDVD"] && [[NSFileManager defaultManager] fileExistsAtPath:self.devicePath])
			[[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabaseFromSource:) withObject:self waitUntilDone:NO];
        else [[BrowserController currentBrowser] redrawSources];
	} @catch (NSException* e)
    {
		N2LogExceptionWithStackTrace(e);
	} @finally
    {
        @synchronized (self)
        {
            _scanThread = nil;
        }

		[pool release];
	}
}

-(DicomDatabase*)database
{
	if (!_detected)
        [UnavaliableDataNodeException raise:NSGenericException format:@"%@", NSLocalizedString(@"This disk is being processed. It is currently not available.", nil)];
    return _database;
}

+(id)mountedDatabaseNodeIdentifierWithPath:(NSString*)devicePath description:(NSString*)description dictionary:(NSDictionary*)dictionary type:(NSInteger)type
{
	BOOL scan = YES;
	NSString* path = [[NSFileManager defaultManager] tmpFilePathInTmp];
	
	// does it contain an OsiriX Data folder?
	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:OsirixDataDirName] isDirectory:&isDir] && isDir) {
		path = devicePath;
		scan = NO;
	}
    
    if (type == MountTypeIPod) {
		path = devicePath;
		scan = NO;
    }
	
	MountedDatabaseNodeIdentifier* bs = [self localDatabaseNodeIdentifierWithPath:path description:description dictionary:dictionary];
	bs.devicePath = devicePath;
    bs.mountType = type;
	[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	
	if (scan) {
		[bs initiateVolumeScan];
	}
	
    if (type == MountTypeIPod) {
        bs.detected = YES;
    }
    
	return bs;
}

-(void)dealloc
{
	[_database release];
    
    [_unmountButton removeFromSuperview];
    [_unmountButton release];
    
    [[NSFileManager defaultManager] removeItemAtPath:self.location error:NULL];
    self.devicePath = nil;
	[super dealloc];
}

//-(NSString*)_bcsChars:(NSString*)s {
//	NSMutableString* r = [NSMutableString stringWithFormat:@"%d, %@ -", s.length, s];
//	for (NSInteger i = 0; i < s.length; ++i)
//		[r appendFormat:@" %04x", [s characterAtIndex:i]];
//	return r;
//}

-(void)willDisplayCell:(PrettyCell*)cell
{
	[super willDisplayCell:cell];
	
//	NSLog(@"%@", [self _bcsChars:self.devicePath]);
	NSImage* im = [[NSWorkspace sharedWorkspace] iconForFile:self.devicePath];
	im.size = [im sizeByScalingProportionallyToSize: cell.image? cell.image.size : NSMakeSize(16,16) ];
	cell.image = im;
    
    if (!_detected)
        cell.textColor = [NSColor grayColor];
    
    [cell.rightSubviews addObject:_unmountButton];
}

-(NSString*)toolTip
{
	return self.devicePath;
}

-(BOOL)isReadOnly
{
	if (self.mountType == MountTypeIPod)
        return NO;
	return YES;
}

-(CGFloat)sortValue {
	return CGFLOAT_MIN+1;
}

-(void)willUnmount
{
    @synchronized (self)
    {
        [DCMPix purgeCachedDictionaries];
        
        if (_scanThread)
            [_scanThread cancel];
        
        [[BrowserController currentBrowser] redrawSources];
    }
}

@end

@implementation UnavaliableDataNodeException
@end



