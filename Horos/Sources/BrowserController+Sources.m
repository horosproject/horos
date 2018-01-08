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
#import "NSHost+N2.h"
#import "DefaultsOsiriX.h"
#import "NSString+N2.h"
#import "WaitRendering.h"

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
    NSMutableArray* _bonjourSources, *_bonjourServices;
    
    BOOL dontListenToSourcesChanges;
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
    MountTypeGeneric = 0,
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

-(void)removePathFromSources:(NSString*) path
{
    MountedDatabaseNodeIdentifier* mbs = nil;
    for (MountedDatabaseNodeIdentifier* ibs in self.sources.arrangedObjects)
        if ([ibs isKindOfClass:[MountedDatabaseNodeIdentifier class]] && [ibs.devicePath isEqualToString:path])
        {
            mbs = ibs;
            break;
        }
    if (mbs)
    {
        if ([[self sourceIdentifierForDatabase:self.database] isEqualToDataNodeIdentifier:mbs])
            [self performSelector: @selector(setDatabase:) withObject: DicomDatabase.defaultDatabase afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
        
        [mbs retain];
        [self.sources removeObject:mbs];
        [mbs willUnmount];
        [mbs performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
    }
}

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
    
    [_sourcesTableView registerForDraggedTypes:BrowserController.DatabaseObjectXIDsPasteboardTypes];
    
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
    else
        return [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:[(RemoteDicomDatabase*)database address] port:[(RemoteDicomDatabase*)database port] description:nil dictionary:nil];
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
        NSDictionary* source = [NSDictionary dictionaryWithObjectsAndKeys: [_database.baseDirPath stringByDeletingLastPathComponent], @"Path", [_database.baseDirPath.stringByDeletingLastPathComponent.lastPathComponent stringByAppendingString: NSLocalizedString( @" DB", @"DB = DataBase")], @"Description", nil];
        [[NSUserDefaults standardUserDefaults] setObject:[[[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"] arrayByAddingObject:source] forKey:@"localDatabasePaths"];
        
        i = [self rowForDatabase:_database];
    }
    if (i != [_sourcesTableView selectedRow])
        [_sourcesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
}

-(void)setDatabaseOnMainThread: (DicomDatabase*) db
{
    [self performSelector: @selector( setDatabase:) withObject: db afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
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
            db = [RemoteDicomDatabase databaseForLocation:address port:port name:name update:YES];
        }
        
        [self performSelectorOnMainThread:@selector( setDatabaseOnMainThread:) withObject:db waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        
        [NSThread sleepForTimeInterval: 1];
        
    } @catch (NSException* e)
    {
        [self performSelectorOnMainThread:@selector(selectCurrentDatabaseSource) withObject:nil waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        if (![e.description isEqualToString:@"Cancelled."])
        {
            N2LogExceptionWithStackTrace(e);
            [self performSelectorOnMainThread:@selector(_complain:) withObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat:0.1], NSLocalizedString(@"Error", nil), e.description, NULL] waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        }
    } @finally
    {
        [pool release];
    }
}

-(void)_complain:(NSArray*)why { // if 1st obj in array is a number then execute this after the delay specified by that number, with the rest of the array
    if ([[why objectAtIndex:0] isKindOfClass:[NSNumber class]])
        [self performSelector:@selector(_complain:) withObject:[why subarrayWithRange:NSMakeRange(1, (long)why.count-1)] afterDelay:[[why objectAtIndex:0] floatValue]];
    else
        NSBeginAlertSheet([why objectAtIndex:0], nil, nil, nil, self.window, NSApp, @selector(endSheet:), nil, nil, @"%@", [why objectAtIndex:1]);
}

-(NSThread*)initiateSetDatabaseAtPath:(NSString*)path name:(NSString*)name
{
    NSArray* io = [NSMutableArray arrayWithObjects: @"Local", path, name, nil];
    
    NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io] autorelease];
    thread.name = NSLocalizedString(@"Loading OsiriX database...", nil);
    thread.supportsCancel = YES;
    thread.status = NSLocalizedString(@"Reading data...", nil);
    
    [thread startModalForWindow:self.window];
    [thread start];
    
    return thread;
}

-(NSThread*)initiateSetRemoteDatabaseWithAddress:(NSString*)address port:(NSInteger)port name:(NSString*)name
{
    NSArray* io = [NSMutableArray arrayWithObjects: @"Remote", address, [NSNumber numberWithInteger:port], name, nil];
    
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(setDatabaseThread:) object:io];
    thread.name = NSLocalizedString(@"Loading remote OsiriX database...", nil);
    thread.supportsCancel = YES;
    [thread startModalForWindow:self.window];
    [thread start];
    
    return [thread autorelease];
}

- (void) setDatabaseWithModalWindow: (DicomDatabase*) db
{
    NSThread* thread = [NSThread currentThread];
    thread.name = NSLocalizedString(@"Opening database...", nil);
    thread.status = NSLocalizedString(@"Opening database...", nil);
    thread.supportsCancel = YES;
    
    ThreadModalForWindowController* tmc = [thread startModalForWindow:self.window];
    
    [self setDatabase: db];
    
    [tmc invalidate];
}

-(void)setDatabaseFromSourceIdentifier:(DataNodeIdentifier*)dni
{
    if ([dni isEqualToDataNodeIdentifier:[self sourceIdentifierForDatabase:_database]])
        return;
    
    @try
    {
        DicomDatabase* db = [dni database];
        
        if (db)
            [self performSelector: @selector( setDatabaseWithModalWindow:) withObject: db afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
        
        else if ([dni isKindOfClass:[LocalDatabaseNodeIdentifier class]])
            [self initiateSetDatabaseAtPath:dni.location name:dni.description];
        
        else if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
        {
            NSString* host = nil; NSInteger port = -1;
            [RemoteDatabaseNodeIdentifier location:dni.location port:dni.port toAddress:&host port:&port];
            
            if( host && port != -1)
                [self initiateSetRemoteDatabaseWithAddress:host port:port name:dni.description];
        }
        else
        {
            [UnavaliableDataNodeException raise:NSGenericException format:@"%@", NSLocalizedString(@"This is a DICOM destination node: you cannot browse its content. You can only drag & drop studies on them.", nil)];
        }
    } @catch (UnavaliableDataNodeException* e)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Sources", nil), nil, nil, nil, self.window, NSApp, @selector(endSheet:), nil, nil, @"%@", [e reason]);
        [self selectCurrentDatabaseSource];
    }
}

-(void)redrawSources
{
    if( [NSThread isMainThread])
        [_sourcesTableView setNeedsDisplay:YES];
    else
        [self performSelectorOnMainThread: @selector( redrawSources) withObject: nil waitUntilDone: NO];
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
        _bonjourSources = [[NSMutableArray alloc] init];
        _bonjourServices = [[NSMutableArray alloc] init];
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
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeWillUnmountNotification:) name:NSWorkspaceWillUnmountNotification object:nil];
        
        // Is there a DICOMDIR at the same level of OsiriX ?
        NSString *appFolder = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
        if( [[NSFileManager defaultManager] fileExistsAtPath: [appFolder stringByAppendingPathComponent: @"DICOMDIR"]])
        {
            @try {
                [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:appFolder description:appFolder.lastPathComponent dictionary:nil type:MountTypeGeneric]];
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            }
        }
        else if ( [[NSFileManager defaultManager] fileExistsAtPath: [appFolder stringByAppendingPathComponent: @"DICOMDIRPATH"]]) // Created by OsiriX Lite App Launcher (see main.mm)
        {
            NSString *dicomdir = [NSString stringWithContentsOfFile: [appFolder stringByAppendingPathComponent: @"DICOMDIRPATH"] encoding: NSUTF8StringEncoding error:nil];
            
            if( [[NSFileManager defaultManager] fileExistsAtPath: dicomdir])
                @try {
                    [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath: dicomdir.stringByDeletingLastPathComponent description:dicomdir.stringByDeletingLastPathComponent.lastPathComponent dictionary:nil type:MountTypeGeneric]];
                } @catch (NSException* e) {
                    N2LogExceptionWithStackTrace(e);
                }
        }
        else
        {
            int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"MOUNT"];
#ifdef OSIRIX_LIGHT
            mode = 0; //display the source
#endif
            
            if( mode != 2)
            {
                for (NSString* path in [[NSWorkspace sharedWorkspace] mountedRemovableMedia])
                    [self _analyzeVolumeAtPath:path];
            }
        }
    }
    
    return self;
}

-(void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidMountNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidUnmountNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceWillUnmountNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:NSWorkspaceDidRenameVolumeNotification object:nil];
    
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"DoNotSearchForBonjourServices"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"searchDICOMBonjour"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"SERVERS"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"OSIRIXSERVERS"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:@"localDatabasePaths"];
    
    [_nsbDicom release]; _nsbDicom = nil;
    [_nsbOsirix release]; _nsbOsirix = nil;
    [_bonjourSources release];
    [_bonjourServices release];
    
    //	[[[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"] removeObserver:self forValuesKey:@"values"];
    _browser = nil;
    [super dealloc];
}

-(void)_observeValueForKeyPathOfObjectChangeContext:(NSArray*)args {
    [self observeValueForKeyPath:[args objectAtIndex:0] ofObject:[args objectAtIndex:1] change:[args objectAtIndex:2] context:[[args objectAtIndex:3] pointerValue]];
}

+ (BOOL)host:(NSHost*)h1 isEqualToHost:(NSHost*)h2 {
#define MAC_CONCURRENT_ISEQUALTOHOST 10
    static dispatch_semaphore_t sid = 0;
    if (!sid)
        sid = dispatch_semaphore_create(MAC_CONCURRENT_ISEQUALTOHOST);
    
    if (dispatch_semaphore_wait(sid, DISPATCH_TIME_FOREVER) == 0)
        @try {
            if (h1.address && h2.address && [h1.address isEqualToString:h2.address])
                return YES;
            if (h1.name && h2.name && [h1.name isEqualToString:h2.name])
                return YES;
            //             return [h1 isEqualToHost:h2];
        } @catch (...) {
            @throw;
        } @finally {
            dispatch_semaphore_signal(sid);
        }
    
    return NO;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(_observeValueForKeyPathOfObjectChangeContext:) withObject:[NSArray arrayWithObjects: keyPath, object, change, [NSValue valueWithPointer:context], nil] waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        return;
    }
    
    //    NSKeyValueChange changeKind = [[change valueForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
    
    dontListenToSourcesChanges = YES;
    
    id previousNode = [_browser sourceIdentifierForDatabase:_browser.database];
    
    @try
    {
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
                        {
                            [dni retain];
                            [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                            [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
                        }
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
            NSHost* currentHost = [DefaultsOsiriX currentHost];
            NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"OSIRIXSERVERS"];
            // remove old items
            for (DataNodeIdentifier* dni in [[_browser.sources.content copy] autorelease])
            {
                if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && dni.entered) // is a remote database and is flagged as "entered"
                    if (![[a valueForKey:@"Address"] containsObject:dni.location])          // is no longer in the entered list
                    {
                        dni.entered = NO;                                                  // mark it as not entered
                        if (!dni.detected)
                        {
                            [dni retain];
                            [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                            [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
                        }
                    }
            }
            // add new items
            //        NSOperationQueue* queue = [[[NSOperationQueue alloc] init] autorelease];
            for (NSDictionary* d in a)
            {
                [NSThread performBlockInBackground:^{
                    // we're now in a background thread
                    NSString* dadd = [d valueForKey:@"Address"];
                    if ([[self class] host:[NSHost hostWithAddressOrName:dadd] isEqualToHost:currentHost]) // don't list self
                        return;
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        // we're now back in the main thread
                        DataNodeIdentifier* dni;
                        NSUInteger i = [[_browser.sources.content valueForKey:@"location"] indexOfObject:dadd];
                        if (i == NSNotFound) {
                            dni = [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:dadd port:[[d valueForKey:@"Port"] intValue] description:[d objectForKey:@"Description"] dictionary:d];
                            dni.entered = YES;
                            [_browser.sources addObject:dni];
                        } else {
                            dni = [_browser.sources.content objectAtIndex:i];
                            dni.entered = YES;
                            dni.description = [d objectForKey:@"Description"];
                            dni.dictionary = d;
                        }
                    }];
                }];
            }
        }
        
        if (context == DicomBrowserSourcesContext)
        {
            NSArray* a = [[NSUserDefaults standardUserDefaults] objectForKey:@"SERVERS"];
            NSMutableDictionary* aa = [NSMutableDictionary dictionary];
            for (NSDictionary* ai in a)
            {
                if( [[ai objectForKey: @"Activated"] boolValue] && [[ai objectForKey: @"Send"] boolValue])
                {
                    NSString *uniqueKey =[NSString stringWithFormat:@"%@%d%@", [ai objectForKey:@"Address"],[[ai objectForKey:@"Port"] unsignedIntValue],[ai objectForKey:@"AETitle"]];
                    [aa setObject:ai forKey:uniqueKey];
                }
            }
            // remove old items
            for (DataNodeIdentifier* dni in [[_browser.sources.content copy] autorelease])
            {
                if ([dni isKindOfClass:[DicomNodeIdentifier class]] && dni.entered) // is a dicom node and is flagged as "entered"
                    if (![[aa allKeys] containsObject:dni.location]) {             // is no longer in the entered list
                        dni.entered = NO;                                         // mark it as not entered
                        if (!dni.detected)
                        {
                            [dni retain];
                            [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                            [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
                        }
                    }
            }
            // add new items
            for (NSString* aak in aa)
            {
                //                [NSThread performBlockInBackground:^{
                //                    // we're now in a background thread
                //                    NSString* aet = nil;
                //                    if ([[self class] host:[DicomNodeIdentifier location:aak toHost:NULL port:NULL aet:&aet] isEqualToHost:currentHost] && [aet isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"]]) // don't list self
                //                        return;
                //                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // we're now back in the main thread
                DataNodeIdentifier* dni;
                NSUInteger i = [[_browser.sources.content valueForKey:@"location"] indexOfObject:aak];
                if (i == NSNotFound)
                {
                    NSDictionary *k = [aa objectForKey:aak];
                    dni = [DicomNodeIdentifier dicomNodeIdentifierWithLocation: [k objectForKey:@"Address"] port:[[k objectForKey:@"Port"] intValue] aetitle:[k objectForKey:@"AETitle"] description:[k objectForKey:@"Description"] dictionary:[aa objectForKey:aak]];
                    dni.entered = YES;
                    [_browser.sources addObject:dni];
                } else {
                    dni = [_browser.sources.content objectAtIndex:i];
                    dni.entered = YES;
                    dni.dictionary = [aa objectForKey:aak];
                    dni.description = [dni.dictionary objectForKey:@"Description"];
                }
                //                    }];
                //                }];
            }
        }
        
        if (context == SearchBonjourNodesContext)
            @synchronized (_bonjourSources) {
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) // add remote databases detected with bonjour
                { // remove remote databases detected with bonjour
                    for (DataNodeIdentifier* dni in _bonjourSources)
                        if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && dni.detected) {
                            dni.detected = NO;
                            if (!dni.entered && [_browser.sources.content containsObject:dni])
                            {
                                [dni retain];
                                [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                                [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
                            }
                        }
                } else
                { // add remote databases detected with bonjour
                    for (DataNodeIdentifier* dni in _bonjourSources)
                        if ([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && !dni.detected && dni.location) {
                            dni.detected = YES;
                            if (![_browser.sources.content containsObject:dni])
                                [_browser.sources addObject:dni];
                        }
                }
            }
        
        if (context == SearchDicomNodesContext)
            @synchronized (_bonjourSources) {
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])
                { // remove dicom nodes detected with bonjour
                    for (DataNodeIdentifier* dni in _bonjourSources)
                        if ([dni isKindOfClass:[DicomNodeIdentifier class]] && dni.detected) {
                            dni.detected = NO;
                            if (!dni.entered && [_browser.sources.content containsObject:dni])
                            {
                                [dni retain];
                                [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                                [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
                            }
                        }
                } else
                { // add dicom nodes detected with bonjour
                    for (DataNodeIdentifier* dni in _bonjourSources)
                        if ([dni isKindOfClass:[DicomNodeIdentifier class]] && !dni.detected && dni.location) {
                            dni.detected = YES;
                            if (![_browser.sources.content containsObject:dni])
                                [_browser.sources addObject:dni];
                        }
                }
            }
    }
    @catch (NSException *exception) {
        N2LogExceptionWithStackTrace( exception);
    }
    
    dontListenToSourcesChanges = NO;
    
    if( [_browser rowForSourceIdentifier: previousNode] == -1)
        [_browser performSelector: @selector(setDatabase:) withObject: DicomDatabase.defaultDatabase afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
    else
        [_browser selectSourceForDatabase: _browser.database];
}

-(void)netServiceDidResolveAddress:(NSNetService*)service
{
    @try
    {
        [service retain];
        [service stop]; //Technical Q&A QA1297
        
        DataNodeIdentifier* source0 = nil;
        @synchronized (_bonjourSources)
        {
            if( [_bonjourServices indexOfObject: service] != NSNotFound)
                source0 = [_bonjourSources objectAtIndex: [_bonjourServices indexOfObject: service]];
            else
                NSLog( @"***** unknown didResolve Service");
        }
        if (!source0)
            return;
        
        @try
        {
            NSDictionary* dict = nil;
            if (![service.domain isEqualToString:@"_osirixdb._tcp."])
                dict = [BonjourPublisher dictionaryFromXTRecordData:service.TXTRecordData];
            else dict = [DCMNetServiceDelegate DICOMNodeInfoFromTXTRecordData:service.TXTRecordData];
            
            if ([[dict objectForKey:@"UID"] isEqualToString:[AppController UID]])
            {
                @synchronized (_bonjourSources)
                {
                    NSLog( @"Remove Service: %@", service);
                    if( [_bonjourServices indexOfObject: service] != NSNotFound)
                    {
                        [_bonjourSources removeObjectAtIndex: [_bonjourServices indexOfObject: service]];
                        [_bonjourServices removeObject: service];
                    }
                    else
                        NSLog( @"***** unknown didResolve Service");
                }
                return; // it's me
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
            return;
        }
        
        @try {
            // we're now back in the main thread
            NSMutableArray* addresses = [NSMutableArray array];
            // Prefer IP4
            for (NSData* address in service.addresses)
            {
                struct sockaddr* sockAddr = (struct sockaddr*)address.bytes;
                if (sockAddr->sa_family == AF_INET)
                {
                    struct sockaddr_in* sockAddrIn = (struct sockaddr_in*)sockAddr;
                    char *str = inet_ntoa(sockAddrIn->sin_addr);
                    if( str)
                    {
                        NSString* host = [NSString stringWithUTF8String:str];
                        NSInteger port = ntohs(sockAddrIn->sin_port);
                        [addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
                    }
                }
            }
            // And search IPv6
            for (NSData* address in service.addresses)
            {
                struct sockaddr* sockAddr = (struct sockaddr*)address.bytes;
                if (sockAddr->sa_family == AF_INET6)
                {
                    struct sockaddr_in6* sockAddrIn6 = (struct sockaddr_in6*)sockAddr;
                    char buffer[INET6_ADDRSTRLEN];
                    if( inet_ntop(AF_INET6, &sockAddrIn6->sin6_addr, buffer, INET6_ADDRSTRLEN))
                    {
                        NSString* host = [NSString stringWithUTF8String:buffer];
                        NSInteger port = ntohs(sockAddrIn6->sin6_port);
                        [addresses addObject:[NSArray arrayWithObjects: host, [NSNumber numberWithInteger:port], NULL]];
                    }
                }
            }
            
            DataNodeIdentifier* source = source0;
            
            for (NSArray* address in addresses)
            {
                if (!source.location && address.count >= 2)
                {
                    if ([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]] || [source isKindOfClass:[DicomNodeIdentifier class]])
                    {
                        source.location = [address objectAtIndex:0];
                        source.port = [[address objectAtIndex:1] integerValue];
                    }
                    
                    if( [source isKindOfClass:[DicomNodeIdentifier class]])
                        source.aetitle = source.description;
                }
            }
            
            NSUInteger i = [_browser.sources.content indexOfObject:source];
            if (i != NSNotFound) // Already known
                @synchronized (_bonjourSources)
            {
                if( [_bonjourServices indexOfObject: service] != NSNotFound)
                    [_bonjourSources replaceObjectAtIndex: [_bonjourServices indexOfObject: service] withObject: (source = [_browser.sources.content objectAtIndex:i])];
                else
                    NSLog( @"***** unknown didResolve Service");
            }
            
            if ([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]])
                source.dictionary = [BonjourPublisher dictionaryFromXTRecordData:service.TXTRecordData];
            else
                source.dictionary = [DCMNetServiceDelegate DICOMNodeInfoFromTXTRecordData:service.TXTRecordData];
            
            if (source.location)
            {
                if (([source isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) ||
                    ([source isKindOfClass:[DicomNodeIdentifier class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])) {
                    
                    source.detected = YES;
                    if (![_browser.sources.content containsObject:source])
                        [_browser.sources addObject:source];
                }
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
    }
    @catch ( NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        [service release];
    }
}

-(void)netService:(NSNetService*)service didNotResolve:(NSDictionary*)errorDict
{
    [service stop];
    
    NSNetService* bsk = nil;
    
    @synchronized (_bonjourSources) {
        for (NSNetService* ibsk in _bonjourServices) {
            if ([ibsk isEqual: service]) {
                bsk = ibsk;
                break;
            }
        }
        
        if (!bsk)
            return;
        
        NSLog( @"Remove Service: %@", bsk);
        [_bonjourSources removeObjectAtIndex: [_bonjourServices indexOfObject: bsk]];
        [_bonjourServices removeObject: bsk];
    }
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didFindService:(NSNetService*)service moreComing:(BOOL)moreComing
{
    //NSLog(@"Bonjour service found: %@", service);
    
    DataNodeIdentifier* source;
    if (nsb == _nsbOsirix)
        source = [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:nil port:0 description:service.name dictionary:nil];
    else
        source = [DicomNodeIdentifier dicomNodeIdentifierWithLocation:nil port:0 aetitle:@"" description:service.name dictionary:nil];
    
    //    source.discovered = YES;
    //	source.service = service;
    @synchronized (_bonjourSources) {
        [_bonjourServices addObject: service];
        [_bonjourSources addObject: source];
    }
    NSLog( @"Find Service: %@", service);
    
    // resolve the address and port for this NSNetService
    [service setDelegate:self];
    [service resolveWithTimeout:30];
}

-(void)netServiceBrowser:(NSNetServiceBrowser*)nsb didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing
{
    NSLog(@"Bonjour service gone: %@", service);
    
    DataNodeIdentifier* dni;
    
    NSNetService *bsk = nil;
    @synchronized (_bonjourSources) {
        for (NSNetService* ibsk in _bonjourServices) {
            if ([ibsk isEqual: service]) {
                bsk = ibsk;
                break;
            }
        }
        
        if (!bsk)
            return;
        
        dni = [_bonjourSources objectAtIndex: [_bonjourServices indexOfObject: bsk]];
        
        if (([dni isKindOfClass:[RemoteDatabaseNodeIdentifier class]] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotSearchForBonjourServices"]) ||
            ([dni isKindOfClass:[DicomNodeIdentifier class]] && [[NSUserDefaults standardUserDefaults] boolForKey:@"searchDICOMBonjour"])) {
            
            dni.detected = NO;
            if (!dni.entered && [_browser.sources.content containsObject:dni])
            {
                [dni retain];
                [_browser.sources removeObject:dni]; // not entered, not detected.. remove it
                [dni performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
            }
        }
        
        // if the disappearing node is active, select the default DB
        if ([[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:dni])
        {
            [_browser performSelector: @selector(setDatabase:) withObject: DicomDatabase.defaultDatabase afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
        }
        NSLog( @"Remove Service: %@", bsk);
        [_bonjourSources removeObjectAtIndex: [_bonjourServices indexOfObject: bsk]];
        [_bonjourServices removeObject: bsk];
    }
}

-(void)_analyzeVolumeAtPath:(NSString*)path
{
    for (DataNodeIdentifier* ibs in _browser.sources.arrangedObjects)
        if ([ibs isKindOfClass:[LocalDatabaseNodeIdentifier class]] && [ibs.location hasPrefix:path])
        {
            return; // device is somehow already listed as a source
        }
    
    NSLog( @"--- start diskutil");
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/diskutil"];
    [task setArguments:[NSArray arrayWithObjects: @"info", @"-plist", path, NULL]];
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:[task standardError]];
    [task launch];
    while( [task isRunning]) [NSThread sleepForTimeInterval: 0.01];
    NSLog( @"--- end diskutil");
    
    NSData* output = [[[[[task standardError] fileHandleForReading] readDataToEndOfFile] retain] autorelease];
    [task release];
    
    NSDictionary* result = [NSPropertyListSerialization propertyListFromData:output mutabilityOption:NSPropertyListImmutable format:0 errorDescription:NULL];
    
    if ([[result objectForKey:@"OpticalMediaType"] length]) // is CD/DVD or other optical media
        @try {
            [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeGeneric]];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
    
    else if ([[result objectForKey:@"MediaType"] isEqualToString:@"iPod"])
        @try {
            [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeIPod]];
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
    else // Is there a DICOMDIR at root?
    {
        if( [[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent: @"DICOMDIR"]])
        {
            @try {
                [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeGeneric]];
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            }
        }
        else if( [[NSFileManager defaultManager] fileExistsAtPath: [path stringByAppendingPathComponent: OsirixDataDirName]])
        {
            @try {
                [_browser.sources addObject:[MountedDatabaseNodeIdentifier mountedDatabaseNodeIdentifierWithPath:path description:path.lastPathComponent dictionary:nil type:MountTypeGeneric]];
            } @catch (NSException* e) {
                N2LogExceptionWithStackTrace(e);
            }
        }
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
     
     NSString* bsdName = [NSString stringWithUTF8String:(char*)gvpib.vMDeviceID];
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
    int mode = [[NSUserDefaults standardUserDefaults] integerForKey: @"MOUNT"];
#ifdef OSIRIX_LIGHT
    mode = 0; //display the source
#endif
    
    if( mode == 2)
        return;
    
    NSString* path = [[notification.userInfo objectForKey: NSWorkspaceVolumeURLKey] path];
    BOOL oldPathWasMounted = NO;
    
    [_browser redrawSources];
    
    if ([notification.name isEqualToString:NSWorkspaceDidMountNotification])
    {
        [self _analyzeVolumeAtPath:[[notification.userInfo objectForKey: NSWorkspaceVolumeURLKey] path]];
    }
    
    if( [notification.name isEqualToString:NSWorkspaceDidRenameVolumeNotification])
    {
        path = [[[notification userInfo] objectForKey: NSWorkspaceVolumeOldURLKey] path];
    }
    
    if ([notification.name isEqualToString:NSWorkspaceDidUnmountNotification] || [notification.name isEqualToString:NSWorkspaceDidRenameVolumeNotification])
    {
        MountedDatabaseNodeIdentifier* mbs = nil;
        for (MountedDatabaseNodeIdentifier* ibs in _browser.sources.arrangedObjects)
            if ([ibs isKindOfClass:[MountedDatabaseNodeIdentifier class]] && [ibs.devicePath isEqualToString:path])
            {
                mbs = ibs;
                oldPathWasMounted = YES;
                break;
            }
        if (mbs)
        {
            if ([[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:mbs])
                [_browser performSelector: @selector(setDatabase:) withObject: DicomDatabase.defaultDatabase afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
            [mbs retain];
            [_browser.sources removeObject:mbs];
            [mbs willUnmount];
            [mbs performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
        }
    }
    
    if ([notification.name isEqualToString:NSWorkspaceDidRenameVolumeNotification] && oldPathWasMounted) // Re-mount an renamed path, that was previously mounted
    {
        [self _analyzeVolumeAtPath:[[notification.userInfo objectForKey: NSWorkspaceVolumeURLKey] path]];
    }
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
    
    [mbs willUnmount];
    
    if (mbs && [[_browser sourceIdentifierForDatabase:_browser.database] isEqualToDataNodeIdentifier:mbs])
    {
        DicomDatabase* db = [DicomDatabase activeLocalDatabase];
        if (db == _browser.database)
            db = [DicomDatabase defaultDatabase];
        
        [_browser performSelector: @selector(setDatabase:) withObject: db afterDelay: 0.01]; //This will guarantee that this will not happen in middle of a drag & drop, for example
    }
}

-(NSString*)tableView:(NSTableView*)tableView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
    NSString* tip = [bs toolTip];
    if (tip)
        return tip;
    return @"";
}

-(void)tableView:(NSTableView*)aTableView willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
    cell.image = nil;
    cell.font = [NSFont systemFontOfSize: [_browser fontSize: @"dbSourceFont"]];
    cell.textColor = nil;
    [cell.rightSubviews removeAllObjects];
    DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
    cell.title = bs.description;
    [bs willDisplayCell:cell];
}


-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if( operation != NSTableViewDropOn)
        return NSDragOperationNone;
    
    NSInteger selectedDatabaseIndex = [_browser rowForDatabase:_browser.database];
    if (row == selectedDatabaseIndex)
        return NSDragOperationNone;
    
    if (row >= _browser.sourcesCount && _browser.database != DicomDatabase.defaultDatabase)
    {
        [tableView setDropRow:[_browser rowForDatabase:DicomDatabase.defaultDatabase] dropOperation:NSTableViewDropOn];
        return NSDragOperationCopy;
    }
    
    if (row < [_browser sourcesCount])
    {
        if ([[_browser sourceIdentifierAtRow:row] isReadOnly])
            return NSDragOperationNone;
        [tableView setDropRow:row dropOperation:NSTableViewDropOn];
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pb = [info draggingPasteboard];
    NSArray* xids = [NSPropertyListSerialization propertyListFromData:[pb propertyListForType:[pb availableTypeFromArray:BrowserController.DatabaseObjectXIDsPasteboardTypes]]
                                                     mutabilityOption:NSPropertyListImmutable
                                                               format:NULL
                                                     errorDescription:NULL];
    NSMutableArray* items = [NSMutableArray array];
    for (NSString* xid in xids)
        [items addObject:[_browser.database objectWithID:[NSManagedObject UidForXid:xid]]];
    
    NSMutableArray* dicomImages = [DicomImage dicomImagesInObjects:items];
    
    return [_browser initiateCopyImages:dicomImages toSource:[_browser sourceIdentifierAtRow:row]];
}

-(void)tableViewSelectionDidChange:(NSNotification*)notification
{
    if( dontListenToSourcesChanges == NO)
    {
        NSInteger row = [(NSTableView*)notification.object selectedRow];
        DataNodeIdentifier* bs = [_browser sourceIdentifierAtRow:row];
        [_browser setDatabaseFromSourceIdentifier:bs];
    }
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
    cell.font = [NSFont boldSystemFontOfSize: [[BrowserController currentBrowser] fontSize: @"dbSourceFont"]];
    cell.image = [NSImage imageNamed:@"Horos.icns"];
}

-(NSString*)description
{
    for( NSDictionary *d in [[NSUserDefaults standardUserDefaults] objectForKey:@"localDatabasePaths"])
    {
        if( [[d valueForKey:@"Path"] isEqualToString: self.location.stringByDeletingLastPathComponent])
            return [d valueForKey: @"Description"];
    }
    
    return [[[self.location stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingString: NSLocalizedString( @" DB", @"DB = DataBase")];
}

-(CGFloat)sortValue {
    return CGFLOAT_MIN;
}

@end


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
    [_database release];
    
    _database = [[DicomDatabase databaseAtPath:self.location] retain];
    _database.isReadOnly = YES;
    _database.sourcePath = self.devicePath;
    _database.name = self.description;
    _database.hasPotentiallySlowDataAccess = YES;
    for (NSManagedObject* obj in _database.albums)
        [_database.managedObjectContext deleteObject:obj];
    
    [_database.managedObjectContext save: nil];
    
    [self performSelectorInBackground:@selector(volumeScanThread) withObject:nil];
}

-(void)volumeScanThread
{
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    @try
    {
        NSLog( @"--- volumeScanThread: start");
        
        NSThread* thread = [NSThread currentThread];
        @synchronized (self)
        {
            _scanThread = thread;
        }
        
        DicomDatabase* database = [_database independentDatabase];
        
        thread.name = NSLocalizedString(@"Scanning disc...", nil);
        [[ThreadsManager defaultManager] addThreadAndStart:thread];
        
        BOOL autoselect = [database scanAtPath:self.devicePath];
        
        if (![[database objectsForEntity:database.imageEntity] count])
        {
            [self retain];
            [[[BrowserController currentBrowser] sources] removeObject:self];
            [self willUnmount];
            [self performSelector: @selector( autorelease) withObject: nil afterDelay: 60];
            
            return;
        }
        
        self.detected = YES;
        
        BOOL selectSource = NO;
        
        NSInteger mode = [NSUserDefaults.standardUserDefaults integerForKey:@"MOUNT"];
//        BOOL autoSelectSourceCDDVD = [[NSUserDefaults standardUserDefaults] boolForKey:@"autoSelectSourceCDDVD"];
        
#ifdef OSIRIX_LIGHT
        mode = 0; //display the source
        autoSelectSourceCDDVD = YES;
#endif
        
        if (mode == -1 || [[NSApp currentEvent] modifierFlags]&NSCommandKeyMask) //The user clicked on the dialog box
        {
            if( autoselect)
                selectSource = YES;
        }
        else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoSelectSourceCDDVD"] && [[NSFileManager defaultManager] fileExistsAtPath:self.devicePath])
            selectSource = YES;
        
        if( selectSource)
            [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(setDatabaseFromSourceIdentifier:) withObject:self waitUntilDone:NO modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        else
            [[BrowserController currentBrowser] redrawSources];
        
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        @synchronized (self)
        {
            _scanThread = nil;
        }
        
        [pool release];
        
        NSLog( @"--- volumeScanThread: end");
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
    
    // does it contain an Horos Data folder?
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[devicePath stringByAppendingPathComponent:OsirixDataDirName] isDirectory:&isDir] && isDir) {
        path = devicePath;
        scan = NO;
    }
    
    if (type == MountTypeIPod) {
        path = devicePath;
        scan = NO;
    }
    
    MountedDatabaseNodeIdentifier* bs = [[self class] localDatabaseNodeIdentifierWithPath:path description:description dictionary:dictionary];
    bs.devicePath = devicePath;
    bs.mountType = type;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    
    if (scan)
        [bs initiateVolumeScan];
    else
        bs.detected = YES;
    
    return bs;
}

-(void)dealloc
{
    [_database release];
    
    [_unmountButton removeFromSuperview];
    [_unmountButton autorelease];
    _unmountButton = nil;
    
    //    [[NSFileManager defaultManager] removeItemAtPath:self.location error:NULL]; We cannot do it, because there was maybe threads attached to this sql file. The entire folder will be deleted when quitting or restarting OsiriX
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
    
    if( _unmountButton)
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
        
        [_unmountButton removeFromSuperview];
        [_unmountButton autorelease];
        _unmountButton = nil;
    }
}

@end

@implementation UnavaliableDataNodeException
@end



