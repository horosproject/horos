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

#import "BonjourPublisher.h"
#import "BonjourBrowser.h"
#import "DCMPix.h"
#import "DCMTKStoreSCU.h"
#import "SendController.h"
#import "DicomStudy.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "NSUserDefaultsController+N2.h"
#import "N2Debug.h"
#import "DicomDatabase.h"
#import "DicomImage.h"
#import "AppController.h"
#import "N2ConnectionListener.h"
#import "N2Connection.h"
#import "NSFileManager+N2.h"
#import "N2Locker.h"

// imports required for socket initialization
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

// BY DEFAULT OSIRIX USES 8780 PORT

#include <netdb.h>
#include <unistd.h>
#include <netinet/in.h>
#include <arpa/inet.h>

extern const char *GetPrivateIP();


@interface O2DatabaseConnection : N2Connection {
    int _mode, _hdi;
    NSMutableArray* _stack;
}

@end


@implementation BonjourPublisher

+ (BonjourPublisher*) currentPublisher // __deprecated
{
	return [[AppController sharedAppController] bonjourPublisher];
}

- (id)init
{
	if ((self = [super init]))
	{
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingNameDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingPasswordFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:OsirixBonjourSharingPasswordDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];		
	}
	return self;
}

- (void) dealloc
{
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingActiveFlagDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingNameDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingPasswordFlagDefaultsKey];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:OsirixBonjourSharingPasswordDefaultsKey];

	[dicomSendLock release];
//	self.serviceName = NULL;
    
    [_bonjour release];
	
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
		keyPath = [keyPath substringFromIndex:7];
		if ([keyPath isEqualToString:OsirixBonjourSharingActiveFlagDefaultsKey]) {
			[self toggleSharing:[NSUserDefaultsController IsBonjourSharingActive]];
			return;
		} else
		if ([keyPath isEqualToString:OsirixBonjourSharingNameDefaultsKey]) {
		//	[self ];
			return;
		} else
		if ([keyPath isEqualToString:OsirixBonjourSharingPasswordFlagDefaultsKey]) {
			return;
		} else
		if ([keyPath isEqualToString:OsirixBonjourSharingPasswordDefaultsKey]) {
			return;
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (int) OsiriXDBCurrentPort // __deprecated
{
	return [_listener port];
}

- (void)toggleSharing:(BOOL)activate
{
    @try {
        if (activate && !_listener) {
            _listener = [[N2ConnectionListener alloc] initWithPort:8780 connectionClass:[O2DatabaseConnection class]];
//            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionOpened:) name:N2ConnectionListenerOpenedConnectionNotification object:_listener];
            [_listener setThreadPerConnection:YES];
            if (_listener)
                NSLog(@"OsiriX database shared on port %d", [_listener port]);
            else NSLog(@"Warning: unable to share OsiriX database");
        }
        
        if (!activate && _listener) {
            [_listener release];
            _listener = nil;
        }
        
        [self updateBonjour];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
}

- (void)updateBonjour {
    if (!_bonjour) {
        // lazily instantiate the NSNetService object that will advertise on our behalf.  Passing in "" for the domain causes the service
        // to be registered in the default registration domain, which will currently always be "local"
        _bonjour = [[NSNetService alloc] initWithDomain:@"" type:@"_osirixdb._tcp." name:[NSUserDefaults bonjourSharingName] port:[_listener port]];
        _bonjour.delegate = self;
    }
    
    NSMutableDictionary* txtrec = [NSMutableDictionary dictionary];
#define EitherOr(a, b) (a? a : b)
    [txtrec setObject: EitherOr([[NSUserDefaults standardUserDefaults] stringForKey:@"AETITLE"], @"OSIRIX") forKey:@"AETitle"];
    [txtrec setObject: EitherOr([[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"11112") forKey:@"port"];
#undef EitherOr
    if ([AppController UID])
        [txtrec setObject:[AppController UID] forKey:@"UID"];
    
    if( [_bonjour setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtrec]] == NO)
        NSLog(@"Warning: OsiriX Bonjour net service setTXTRecordData FAILED");

    if (_listener)
        [_bonjour publish];
    else [_bonjour stop];
}

- (NSNetService*)netService { // __deprecated
    return _bonjour;
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict
{
	NSLog(@"Warning: OsiriX Bonjour net service did not publish, %@", errorDict);
    [_bonjour release];
    _bonjour = nil;
}

- (void) netServiceDidStop:(NSNetService *)sender
{
    NSLog(@"OsiriX Bonjour net service did stop");
}


//- (void)connectionOpened:(NSNotification*)notification {
//	N2Connection* connection = [[notification userInfo] objectForKey:N2ConnectionListenerOpenedConnection];
//	[connection setDelegate:self];
//}

+(NSDictionary*)dictionaryFromXTRecordData:(NSData*)data {
	NSMutableDictionary* d = [NSMutableDictionary dictionary];
	NSDictionary* dict = [NSNetService dictionaryFromTXTRecordData:data];
	
	for (NSString* key in dict) {
		NSData* data = [dict objectForKey:key];
		if ([key isEqualToString:@"AETitle"])
			[d setObject:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] forKey:key];
		else if ([key isEqualToString:@"port"])
			[d setObject:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] forKey:key];
		else if ([key isEqualToString:@"UID"])
			[d setObject:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] forKey:key];
		else [d setObject:data forKey:key];
	}
	
	return d;
}

- (void) sendDICOMFilesToOsiriXNode:(NSDictionary*) todo
{
	@autoreleasepool
    {
        if (dicomSendLock == nil)
            dicomSendLock = [[NSLock alloc] init];
        
        [dicomSendLock lock];
        @try {
            DCMTKStoreSCU *storeSCU = [[DCMTKStoreSCU alloc]	initWithCallingAET: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"]
                                                                        calledAET: [todo objectForKey:@"AETitle"] 
                                                                        hostname: [todo objectForKey:@"Address"] 
                                                                        port: [[todo objectForKey:@"Port"] intValue] 
                                                                        filesToSend: [todo valueForKey: @"Files"]
                                                                        transferSyntax: [[todo objectForKey:@"TransferSyntax"] intValue] 
                                                                        compression: 1.0
                                                                        extraParameters: [NSDictionary dictionaryWithObject:[DicomDatabase defaultDatabase] forKey:@"DicomDatabase"]]; // nil == TLS not supported !
                                    
            @try
            {
                [storeSCU run: nil];
            }
            
            @catch (NSException *ne)
            {
                NSLog( @"Bonjour DICOM Send FAILED");
                NSLog( @"%@", [ne name]);
                NSLog( @"%@", [ne reason]);
            }
            
            [storeSCU release];
            storeSCU = nil;
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            [dicomSendLock unlock];
        }
    }
}

@end

@implementation O2DatabaseConnection

- (id)initWithAddress:(NSString*)address port:(NSInteger)port tls:(BOOL)tlsFlag is:(NSInputStream*)is os:(NSOutputStream*)os {
	if ((self = [super initWithAddress:address port:port tls:tlsFlag is:is os:os])) {
//		[self setCloseOnRemoteClose:YES];
        _stack = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc {
    [_stack release];
    [super dealloc];
}

enum Modes {
    NONE = 0, DONE,
    DATAB,
    DBSIZ,
    GETDI,
    VERSI,
    DBVER,
    ISPWD,
    PASWD,
    SENDD,
    SENDG,
    NEWMS,
    ADDAL,
    REMAL,
    SETVA,
    MFILE,
    DCMSE,
    DICOM
};

static NSString* const O2NotEnoughData = @"O2NotEnoughData";

- (void)handleData:(NSMutableData*)data {
    _hdi = 0;
    
    @try {
        if (_mode == NONE) {
            if (self.availableSize < 6)
                return;
            char command[6];
            [self readData:6 toBuffer:command];
            
            if (strcmp(command, "DATAB") == 0)
                _mode = DATAB;
            else if (strcmp(command, "DBSIZ") == 0)
                _mode = DBSIZ;
            else if (strcmp(command, "GETDI") == 0)
                _mode = GETDI;
            else if (strcmp(command, "VERSI") == 0)
                _mode = VERSI;
            else if (strcmp(command, "DBVER") == 0)
                _mode = DBVER;
            else if (strcmp(command, "ISPWD") == 0)
                _mode = ISPWD;
            else if (strcmp(command, "PASWD") == 0)
                _mode = PASWD;
            else if (strcmp(command, "SENDD") == 0)
                _mode = SENDD;
            else if (strcmp(command, "SENDG") == 0)
                _mode = SENDG;
            else if (strcmp(command, "NEWMS") == 0)
                _mode = NEWMS;
            else if (strcmp(command, "ADDAL") == 0)
                _mode = ADDAL;
            else if (strcmp(command, "REMAL") == 0)
                _mode = REMAL;
            else if (strcmp(command, "SETVA") == 0)
                _mode = SETVA;
            else if (strcmp(command, "MFILE") == 0)
                _mode = MFILE;
            else if (strcmp(command, "DCMSE") == 0)
                _mode = DCMSE;
            else if (strcmp(command, "DICOM") == 0)
                _mode = DICOM;

            if (_mode == NONE)
                [self close];
        }

        switch (_mode) {
            case DATAB:
                return [self DATAB];
            case DBSIZ:
                return [self DBSIZ];
            case GETDI:
                return [self GETDI];
            case VERSI:
                return [self VERSI];
            case DBVER:
                return [self DBVER];
            case ISPWD:
                return [self ISPWD];
            case PASWD:
                return [self PASWD];
            case SENDD:
                return [self SEND];
            case SENDG:
                return [self SEND];
            case NEWMS:
                return [self NEWMS];
            case ADDAL:
                return [self ADDAL];
            case REMAL:
                return [self REMAL];
            case SETVA:
                return [self SETVA];
            case MFILE:
                return [self MFILE];
            case DCMSE:
                return [self DCMSE];
            case DICOM:
                return [self DICOM];
        }
    } @catch (NSException* e) {
        if ([e.name isEqualToString:O2NotEnoughData])
            return;
        @throw e;
    } @finally {
        if (_mode == DONE)
        {
            if (self.writeBufferSize)
                self.closeWhenDoneSending = YES;
            else [self close];
        }
    }
}

- (void)connectionFinishedSendingData {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleData:) object:nil];
    [self performSelector:@selector(handleData:) withObject:nil afterDelay:0]; // fill send buffer, maybe...
}

- (void)_stackObject:(id)o {
    [_stack addObject:o];
    ++_hdi;
}

- (id)_stackedObject {
    if (_stack.count <= _hdi)
        return nil;
    return [_stack objectAtIndex:_hdi++];
}

- (void)_unstack {
    [_stack removeObjectAtIndex:--_hdi];
}

- (void)_requireDataSize:(int)size {
    if (self.availableSize < size)
        [NSException raise:O2NotEnoughData format:nil];
}

- (int)_readInt {
    [self _requireDataSize:4];
    
    int value;
    [self readData:4 toBuffer:&value];
    value = NSSwapBigIntToHost(value);
    
    return value;
}

- (int)_stackReadInt {
    if (_stack.count > _hdi)
    {
//        N2LogStackTrace( @"_stack.count > _hdi");
        return [[self _stackedObject] intValue];
    }
    int value = [self _readInt];
    
    [self _stackObject:[NSNumber numberWithInt:value]];
    
    return value;
}

- (NSString*)_readString {
    [self _requireDataSize:4];
    
    int length;
    [self.readBuffer getBytes:&length length:4];
    length = NSSwapBigIntToHost(length);

    [self _requireDataSize:length+4];
    
    [self readData:4];
    
    NSData* data = [self readData:length];
    
    return [NSString stringWithUTF8String:data.bytes];
}

- (NSString*)_stackReadString {
    if (_stack.count > _hdi)
    {
//        N2LogStackTrace( @"_stack.count > _hdi");
        return [self _stackedObject];
    }
    NSString* value = [self _readString];
    
    [self _stackObject:value];
    
    return value;
}

- (DicomDatabase*)_stackIndependentDatabase {
    if (_stack.count > _hdi)
    {
//        N2LogStackTrace( @"_stack.count > _hdi");
        return [self _stackedObject];
    }
    DicomDatabase* database = [[DicomDatabase defaultDatabase] independentDatabase];
    
    [self _stackObject:database];
    
    return database;
}

- (void)DATAB {
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    NSMutableData* representationToSend = nil;
    
    N2Locker* lock = [self _stackedObject];
    if (!lock) {
        [self _stackObject:[N2Locker lock:[[idatabase managedObjectContext] persistentStoreCoordinator]]]; // this object unlocks the persistentStoreCoordinator when released
        [idatabase save];
    }
    
    BOOL done = NO;
    
    @try
    {
        // we send the database SQL file
        NSString* databasePath = [idatabase sqlFilePath];
        
#if __LP64__
        representationToSend = [NSMutableData dataWithContentsOfFile: databasePath];
        done = YES;
#else
        NSNumber* fileSize = [self _stackedObject];
        if (!fileSize) {
            NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: databasePath traverseLink: YES];
            long long ll = [[fattrs objectForKey:NSFileSize] longLongValue];
            [self _stackObject:(fileSize = [NSNumber numberWithLongLong:ll])];
        }
        
        // read 200 MB per cycle
#define DATA_READ_SIZE 200L
        
        if (fileSize.longLongValue/1024/1024 > DATA_READ_SIZE)
        {
            NSFileHandle* dbFileHandle = [self _stackedObject];
            if (!dbFileHandle) {
                dbFileHandle = [NSFileHandle fileHandleForReadingAtPath: databasePath];
                [self _stackObject:dbFileHandle];
            }
                
            if (self.writeBufferSize > 0) // to optimize memory usage, don't queue additional data until the send buffer is empty
                return;
            
            NSData* chunk = [dbFileHandle readDataOfLength: DATA_READ_SIZE * 1024L*1024L];
            if ([chunk length]) {
                [self writeData: chunk];
                return;
            } else
                done = YES;
            
            [self _unstack];
        }
        else
        {
            representationToSend = [NSMutableData dataWithContentsOfFile: databasePath];
            done = YES;
        }
        
        [self _unstack];
#endif
    }
    @catch (NSException *e) {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        if (done) {
            [self _unstack]; // -> release N2Locker, unlocks the persistentStoreCoordinator (this line may not be called, so the persistentStoreCoordinator will be unlocked when this connection object is released -- when the stack is released)
        }
    }
    
    if (representationToSend)
        [self writeData:representationToSend];
    
    NSLog(@"Bonjour connection received from %@", _address);

    _mode = DONE;
}

- (void)DBSIZ {
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    int fileSize;
    
    [[[idatabase managedObjectContext] persistentStoreCoordinator] lock];
    @try
    {
        [idatabase save];
        
        NSString *databasePath = [idatabase sqlFilePath];
        
        NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath: databasePath traverseLink: YES];
        
        fileSize = [[fattrs objectForKey:NSFileSize] longLongValue];
    }
    @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
        [[[idatabase managedObjectContext] persistentStoreCoordinator] unlock];
    }
    
    int size = NSSwapHostIntToBig(fileSize);
    [self writeData:[NSData dataWithBytes:&size length:sizeof(int)]];
    
    _mode = DONE;
}

- (void)GETDI {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys: [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"], @"AETitle", [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"], @"Port", [NSString stringWithFormat: @"%d", [DCMTKStoreSCU sendSyntaxForListenerSyntax: [[NSUserDefaults standardUserDefaults] integerForKey: @"preferredSyntaxForIncoming"]]], @"TransferSyntax", nil];
    
    [self writeData:[NSMutableData dataWithData: [NSArchiver archivedDataWithRootObject: dictionary]]];
    
    _mode = DONE;
}

- (void)VERSI {
    DicomDatabase* idatabase = [self _stackIndependentDatabase];

    NSTimeInterval val = [idatabase timeOfLastModification];
    
    NSSwappedDouble swappedValue = NSSwapHostDoubleToBig( val);
    
    if( sizeof( swappedValue.v) != 8) NSLog(@"********** warning sizeof( swappedValue) != 8");
    
    [self writeData:[NSMutableData dataWithBytes: &swappedValue.v length:sizeof(NSTimeInterval)]];
    
    _mode = DONE;
}

- (void)DBVER {
    NSString	*versString = [[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASEVERSION"];
    
    [self writeData:[NSMutableData dataWithData: [versString dataUsingEncoding: NSASCIIStringEncoding]]];
    
    _mode = DONE;
}

- (void)ISPWD {
    // is this database protected by a password
    NSString* pswd = [NSUserDefaultsController BonjourSharingPassword];
    
    int val = 0;
    if (pswd)
        val = NSSwapHostIntToBig(1);
    
    [self writeData:[NSMutableData dataWithBytes:&val length:sizeof(int)]];
    
    _mode = DONE;
}

- (void)PASWD {
    NSString* incomingPswd = [self _stackReadString];
    
    // We read the string
    int val = 0;
    
    if (![NSUserDefaultsController BonjourSharingPassword] || [incomingPswd isEqualToString: [NSUserDefaultsController BonjourSharingPassword]])
    {
        val = NSSwapHostIntToBig(1);
    }
    
    [self writeData:[NSMutableData dataWithBytes:&val length:sizeof(int)]];
    
    _mode = DONE;
}

- (void)SEND {
    int fileNo = [self _stackReadInt];
    
    NSMutableArray* savedFiles = [self _stackedObject];
    if (!savedFiles) [self _stackObject:(savedFiles = [NSMutableArray array])];
    
    while (savedFiles.count < fileNo)
    {
        int fileSize = [self _stackReadInt];
        [self _requireDataSize:fileSize];
        
        NSString* dstPath = [[BrowserController currentBrowser] getNewFileDatabasePath: @"dcm"];
        
        [[self readData:fileSize] writeToFile:dstPath atomically:YES];
        
        [savedFiles addObject: dstPath];
        
        [self _unstack];
    }
    
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    NSArray *objects = [idatabase addFilesAtPaths: savedFiles postNotifications: YES dicomOnly: NO rereadExistingItems: YES generatedByOsiriX:(_mode == SENDG)];
    
    objects = [idatabase objectsWithIDs: objects];
    
    NSMutableData* representationToSend = [NSMutableData data];
    unsigned int temp = NSSwapHostIntToBig([objects count]);
    [representationToSend appendBytes:&temp length:4];
    for (DicomImage* image in objects) {
        unsigned int temp = NSSwapHostIntToBig(image.pathNumber.intValue);
        [representationToSend appendBytes:&temp length:4];
    }
    
    [self writeData:representationToSend];

    _mode = DONE;
}

- (void)NEWMS { // is this used ? nah
    int size = [self _stackReadInt];
    
    [self _requireDataSize:size];
//    NSData* da = [self readData:size];
    
//    NSDictionary* d = [NSPropertyListSerialization propertyListFromData:da mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
//
//    if (d)
//    {
//        NSString *message = [d objectForKey:@"message"];
//    }
    
    _mode = DONE;
}

- (void)ADDAL {
    NSString* object = [self _stackReadString];
    
    NSDictionary* d = (NSDictionary*)[NSPropertyListSerialization
                                      propertyListFromData:[NSData dataWithBytesNoCopy:(void*)object.UTF8String length:strlen(object.UTF8String) freeWhenDone:NO]
                                      mutabilityOption:NSPropertyListImmutable
                                      format:NULL
                                      errorDescription:NULL];
    
    if (!d) [NSException raise:NSGenericException format:@"can't parse parameters"];
    
    NSArray *studies = [d objectForKey:@"albumStudies"];
    NSString *albumUID = [d objectForKey:@"albumUID"];
    
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    @try
    {
        DicomAlbum* album = [idatabase objectWithID:albumUID]; // [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: albumUID]]];
        NSMutableSet* albumStudies = [album mutableSetValueForKey:@"studies"];
        
        for (NSString* uri in studies)
        {
            DicomStudy* study = [idatabase objectWithID:uri]; // (DicomStudy*) [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]]];
            [albumStudies addObject:study];
            [study archiveAnnotationsAsDICOMSR];
        }
        
        [idatabase save:nil];
        
        [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(refreshDatabase:) withObject:self waitUntilDone:NO];
    }
    
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    
    _mode = DONE;
}

- (void)REMAL {
    NSString* object = [self _stackReadString];
    
    NSDictionary* d = (NSDictionary*)[NSPropertyListSerialization
                                      propertyListFromData:[NSData dataWithBytesNoCopy:(void*)object.UTF8String length:strlen(object.UTF8String) freeWhenDone:NO]
                                      mutabilityOption:NSPropertyListImmutable
                                      format:NULL
                                      errorDescription:NULL];
    
    if (!d) [NSException raise:NSGenericException format:@"can't parse parameters"];

    NSArray *studies = [d objectForKey:@"albumStudies"];
    NSString *albumUID = [d objectForKey:@"albumUID"];
    
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    @try
    {
        DicomAlbum* album = [idatabase objectWithID:albumUID]; // [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: albumUID]]];
        NSMutableSet* albumStudies = [album mutableSetValueForKey: @"studies"];
        
        for (NSString* uri in studies)
        {
            DicomStudy* study = [idatabase objectWithID:uri]; // (DicomStudy*) [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: uri]]];
            [albumStudies removeObject:study];
            [study archiveAnnotationsAsDICOMSR];
        }
        
        [idatabase save:nil];

        [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(refreshDatabase:) withObject:self waitUntilDone:NO];
    }
    
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
    }

    _mode = DONE;

}

- (void)SETVA {
    NSString* objectId = [self _stackReadString];
    NSString* value = [self _stackReadString];
    NSString* key = [self _stackReadString];
    
    DicomDatabase* idatabase = [self _stackIndependentDatabase];
    
    @try
    {
        NSManagedObject* item = [idatabase objectWithID:objectId]; // [context objectWithID: [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation: [NSURL URLWithString: object]]];
        
        //NSLog(@"URL:%@", object);
        if( item)
        {
            if( [[item valueForKeyPath: key] isKindOfClass: [NSNumber class]]) [item setValue: [NSNumber numberWithInt: [value intValue]] forKeyPath: key];
            else
            {
                if( [key isEqualToString: @"reportURL"] == YES)
                {
                    if( value == nil)
                    {
                        [[NSFileManager defaultManager] removeFileAtPath:[item valueForKeyPath: key] handler:nil];
                    }
                    else if( [[key pathComponents] count] == 1)
                    {
                        value = [[idatabase reportsDirPath] stringByAppendingPathComponent: [value lastPathComponent]];
                    }
                }
                
                [item setValue: value forKeyPath: key];
            }
        }
        
        [idatabase save:NULL];
    }
    
    @catch (NSException *e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally {
    }
    
    [[BrowserController currentBrowser] performSelectorOnMainThread:@selector(refreshDatabase:) withObject:self waitUntilDone:NO];
    
    _mode = DONE;
}

- (void)MFILE {
    NSString* path = [self _stackReadString];
    
    if( [path length])
    {
        if( [path characterAtIndex: 0] != '/')
            path = [[[DicomDatabase defaultDatabase] baseDirPath] stringByAppendingPathComponent: path];
    }
    
    NSDictionary *fattrs = [[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:YES];
    
    NSData	*content = [[[fattrs objectForKey:NSFileModificationDate] description] dataUsingEncoding: NSUnicodeStringEncoding];
    
    [self writeData:content];
    
    _mode = DONE;
}

- (void)DCMSE {
    NSString* AETitle = [self _stackReadString];
    NSString* Address = [self _stackReadString];
    NSString* Port = [self _stackReadString];
    NSString* TransferSyntax = [self _stackReadString];
    
    int noOfFiles = [self _stackReadInt];

    NSMutableArray* localPaths = [self _stackedObject];
    if (!localPaths) [self _stackObject:(localPaths = [NSMutableArray array])];

    while (localPaths.count < noOfFiles)
    {
        NSString* path = [self _stackReadString];
        
        if( [path UTF8String] [0] != '/')
        {
            int val = [[path stringByDeletingPathExtension] intValue];
            
            NSString *dbLocation = [[DicomDatabase defaultDatabase] sqlFilePath];
            
            val /= [BrowserController DefaultFolderSizeForDB];
            val++;
            val *= [BrowserController DefaultFolderSizeForDB];
            
            path = [[dbLocation stringByDeletingLastPathComponent] stringByAppendingFormat:@"/DATABASE.noindex/%d/%@", val, path];
        }
        
        [localPaths addObject: path];
        
        [self _unstack]; // the string
    }
    
    if( [Address isEqualToString: @"127.0.0.1"])
    {
        Address = _address;
    }
    
    NSDictionary *todo = [NSDictionary dictionaryWithObjectsAndKeys: Address, @"Address", TransferSyntax, @"TransferSyntax", Port, @"Port", AETitle, @"AETitle", localPaths, @"Files", nil];
    
    [NSThread detachNewThreadSelector:@selector(sendDICOMFilesToOsiriXNode:) toTarget:[BonjourPublisher currentPublisher] withObject: todo];

    _mode = DONE;
}

- (void)DICOM
{
    @synchronized( self)
    {
        int noOfFiles = [self _stackReadInt];
        
        NSMutableArray* localPaths = [self _stackedObject];
        if (!localPaths) [self _stackObject:(localPaths = [NSMutableArray array])];
        NSMutableArray* dstPaths = [self _stackedObject];
        if (!dstPaths) [self _stackObject:(dstPaths = [NSMutableArray array])];
        
        while (localPaths.count < noOfFiles)
        {
            NSString* path = [self _stackReadString];
            
            if( [path UTF8String] [ 0] != '/')
            {
                if( [[[path pathComponents] objectAtIndex: 0] isEqualToString:@"ROIs"])
                {
                    //It's a ROI !
                    NSString	*local = [[[DicomDatabase defaultDatabase] sqlFilePath] stringByDeletingLastPathComponent];
                    
                    path = [[local stringByAppendingPathComponent:@"/ROIs/"] stringByAppendingPathComponent: [path lastPathComponent]];
                }
                else
                {
                    
                    int val = [[path stringByDeletingPathExtension] intValue];
                    
                    val /= [BrowserController DefaultFolderSizeForDB];
                    val++;
                    val *= [BrowserController DefaultFolderSizeForDB];
                    
                    NSString	*local = [[[DicomDatabase defaultDatabase] sqlFilePath] stringByDeletingLastPathComponent];
                    
                    path = [[[local stringByAppendingPathComponent:@"/DATABASE.noindex/"] stringByAppendingPathComponent: [NSString stringWithFormat:@"%d", val]] stringByAppendingPathComponent: path];
                }
            }
            
            [localPaths addObject: path];
            
            //				if([[path pathExtension] isEqualToString:@"zip"])
            //				{
            //					// it is a ZIP
            //					NSLog(@"BONJOUR ZIP");
            //					NSString *xmlPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
            //					NSLog(@"xmlPath : %@", xmlPath);
            //					if([[NSFileManager defaultManager] fileExistsAtPath:xmlPath])
            //					{
            //						// it has an XML descriptor with it
            //						NSLog(@"BONJOUR XML");
            //						[localPaths addObject:xmlPath];
            //					}
            //				}

            [self _unstack]; // the string
        }
        
        while (dstPaths.count < noOfFiles)
        {
            NSString* path = [self _stackReadString];
            
            [dstPaths addObject: path];
            
            //				if([[path pathExtension] isEqualToString:@"zip"])
            //				{
            //					// it is a ZIP
            //					NSLog(@"BONJOUR ZIP");
            //					NSString *xmlPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"];
            //					NSLog(@"xmlPath : %@", xmlPath);
            //					if([[NSFileManager defaultManager] fileExistsAtPath:xmlPath])
            //					{
            //						// it has an XML descriptor with it
            //						NSLog(@"BONJOUR XML");
            //						[dstPaths addObject:xmlPath];
            //					}
            //				}
            
            [self _unstack]; // the string
        }
        
        int temp = NSSwapHostIntToBig(noOfFiles);
        [self writeData:[NSData dataWithBytesNoCopy:&temp length:4 freeWhenDone:NO]];
        for (int i = 0; i < noOfFiles; i++)
        {
            NSString* path = [localPaths objectAtIndex: i];
            
            //						if ([[NSFileManager defaultManager] fileExistsAtPath: path] == NO)
            //							NSLog( @"Bonjour Publisher - File doesn't exist at path: %@", path);
            
            NSData* content = [NSData dataWithContentsOfMappedFile:path];
            int size = NSSwapHostIntToBig([content length]);
            [self writeData:[NSData dataWithBytesNoCopy:&size length:4 freeWhenDone:NO]];
            [self writeData:content];
            
            const char* string = [[dstPaths objectAtIndex:i] UTF8String];
            int stringSize = NSSwapHostIntToBig( strlen( string)+1);	// +1 to include the last 0 !
            [self writeData:[NSData dataWithBytesNoCopy:&stringSize length:4 freeWhenDone:NO]];
            [self writeData:[NSData dataWithBytesNoCopy:(void*)string length:strlen(string)+1 freeWhenDone:NO]];
        }
        
        _mode = DONE;
    }
}






@end
