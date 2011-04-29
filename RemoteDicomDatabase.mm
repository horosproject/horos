//
//  RemoteDicomDatabase.mm
//  OsiriX
//
//  Created by Alessandro Volz on 04.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "RemoteDicomDatabase.h"
#import "N2Debug.h"
#import "NSFileManager+N2.h"
#import "N2Connection.h"
#import "NSThread+N2.h"
#import "ThreadsManager.h"
#import "BrowserController.h" // TODO: awwww
#import "N2MutableUInteger.h"

@interface RemoteDicomDatabase ()

@property(readwrite,retain) NSString* address;
@property(readwrite) NSInteger port;
@property(readwrite,retain) NSHost* host;

-(void)update;

@end

@implementation RemoteDicomDatabase

+(DicomDatabase*)databaseForAddress:(NSString*)path {
	return [self databaseForAddress:path name:nil];
}

+(DicomDatabase*)databaseForAddress:(NSString*)address name:(NSString*)name {
	NSArray* dbs = [DicomDatabase allDatabases];
	for (DicomDatabase* db in dbs)
		if ([db isKindOfClass:RemoteDicomDatabase.class])
			if ([[(RemoteDicomDatabase*)db address] isEqual:address])
				return db;
	
	DicomDatabase* db = [[self alloc] initWithAddress:address];
	if (name) db.name = name;
	
	return db;
}

#pragma mark Instance

@synthesize address = _address, port = _port, host = _host;

-(id)initWithAddress:(NSString*)address {
	NSString* path = [NSFileManager.defaultManager tmpFilePathInTmp];
	[NSFileManager.defaultManager confirmDirectoryAtPath:path];
	
	self = [super initWithPath:path];
	_updateLock = [[NSRecursiveLock alloc] init];
	
	NSArray* addressParts = [address componentsSeparatedByString:@":"];
	self.address = [addressParts objectAtIndex:0];
	if (addressParts.count > 1)
		self.port = [[addressParts objectAtIndex:1] integerValue];
	self.host = [NSHost hostWithName:self.address];
	
	[self update];
	
	return self;
}

-(void)dealloc {
	NSRecursiveLock* temp;
	
	temp = _updateLock;
	[temp lock]; // if currently importing, wait until finished
	_updateLock = nil;
	[temp unlock];
	[temp release];	
	
	self.address = nil;
	self.host = nil;
	
	NSError* err = nil;
	if (![NSFileManager.defaultManager removeItemAtPath:self.baseDirPath error:&err])
		N2LogError(err);
	else if (err) N2LogError(err);
	
	[super dealloc];
}

-(BOOL)isLocal {
	return NO;
}

-(NSString*)sqlFilePath {
	if (_sqlFileName)
		return [self.baseDirPath stringByAppendingPathComponent:_sqlFileName];
	else return [super sqlFilePath];
}

const NSString* const FailedToConnectExceptionMessage = @"Failed to connect to the remote host. Is database sharing activated on the distant computer?";

-(NSString*)fetchDatabaseVersion {
	NSMutableData* request = [NSMutableData dataWithBytes:"DBVER" length:6];
	NSData* response = [N2Connection sendSynchronousRequest:request toHost:self.host port:self.port];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
}

-(BOOL)fetchIsPasswordProtected {
	NSMutableData* request = [NSMutableData dataWithBytes:"ISPWD" length:6];
	NSData* response = [N2Connection sendSynchronousRequest:request toHost:self.host port:self.port];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)[response bytes]))? YES : NO;
}

-(BOOL)fetchIsRightPassword:(NSString*)password {
	NSMutableData* request = [NSMutableData dataWithBytes:"PASWD" length:6];
	const char* passwordC = [password UTF8String];
	size_t passwordCLength = strlen(passwordC)+1;
	unsigned int passwordCLengthBig = NSSwapHostIntToBig(passwordCLength);
	[request appendBytes:&passwordCLengthBig length:4];
	[request appendBytes:passwordC length:passwordCLength];
	NSData* response = [N2Connection sendSynchronousRequest:request toHost:self.host port:self.port];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)[response bytes]))? YES : NO;
}

-(unsigned int)fetchDatabaseIndexSize {
	NSMutableData* request = [NSMutableData dataWithBytes:"DBSIZ" length:6];
	NSData* response = [N2Connection sendSynchronousRequest:request toHost:self.host port:self.port];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)[response bytes]));
}

-(NSString*)fetchDatabaseIndex {
	NSThread* thread = [NSThread currentThread];
	thread.status = NSLocalizedString(@"Negotiating with remote OsiriX...", nil);
	
	NSString* version = [self fetchDatabaseVersion];
	
	if (![version isEqualToString:CurrentDatabaseVersion])
		[NSException raise:NSDestinationInvalidException format:NSLocalizedString(@"Invalid remote database model %@. When sharing databases, make sure both ends are running the same version of OsiriX", nil), version];
	
	DLog(@"RDD version: %@", version);

	// TODO: password check is client-only, do it on the server side!
//	BOOL isPasswordProtected = [self fetchIsPasswordProtected];
//	if (isPasswordProtected) DLog(@"RDD is password protected", version);
//	NSString* password = nil;
//	if (isPasswordProtected) {
//		password = [[BrowserController currentBrowser] askPassword]; // TODO: awww
//		BOOL isRightPassword = [self fetchIsRightPassword:password];
//		if (!isRightPassword)
//			[NSException raise:NSInvalidArgumentException format:NSLocalizedString(@"Wrong password for remote database.", nil)];
//		else DLog(@"RDD password ok");
//	}
	
	NSUInteger databaseIndexSize = [self fetchDatabaseIndexSize];
	DLog(@"RDD index size is %d", databaseIndexSize);
	
	thread.status = NSLocalizedString(@"Transferring database index...", nil);
	[thread enterOperation];
	
	NSString* path = [NSFileManager.defaultManager tmpFilePathInDir:self.baseDirPath];
	NSOutputStream* fileStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
	[fileStream open];
	
	NSData* request = [NSMutableData dataWithBytes:"DATAB" length:6];
	NSArray* context = [NSArray arrayWithObjects: thread, [NSNumber numberWithUnsignedInteger:databaseIndexSize], fileStream, [N2MutableUInteger mutableUIntegerWithUInteger:0], nil];
	[N2Connection sendSynchronousRequest:request toHost:self.host port:self.port dataHandlerTarget:self selector:@selector(fetchDatabaseIndexHandleData:context:) context:context];
	
	[fileStream close];
	[thread exitOperation];
	
	if (thread.isCancelled)
		return nil;
	
	thread.status = NSLocalizedString(@"Done.", nil);
	
	return path;
}

-(NSInteger)fetchDatabaseIndexHandleData:(NSData*)data context:(NSArray*)context {
	NSThread* thread = [context objectAtIndex:0];
	NSInteger databaseIndexSize = [[context objectAtIndex:1] unsignedIntegerValue];
	NSOutputStream* fileStream = [context objectAtIndex:2];
	N2MutableUInteger* obtainedSize = [context objectAtIndex:3];
	
	NSInteger size = data.length, start = 0;
	while (size > 0) {
		NSInteger w = [fileStream write:(const uint8_t*)data.bytes+start maxLength:size];
		if (w > 0) {
			size -= w;
			start += w;
			obtainedSize.unsignedIntegerValue = obtainedSize.unsignedIntegerValue + w;
		} else [NSException raise:NSGenericException format:fileStream.streamError.localizedDescription];
	}
		
	thread.progress = 1.0*obtainedSize.unsignedIntegerValue/databaseIndexSize;
	thread.progressDetails = [NSString stringWithFormat:NSLocalizedString(@"Received %d of %d bytes", nil), obtainedSize.unsignedIntegerValue, databaseIndexSize];
	
	return data.length;
}

-(void)update {
	NSThread* thread = [NSThread currentThread];
	
	[thread enterOperation];
	[_updateLock lock];
	@try {
		thread.status = NSLocalizedString(@"Downloading index...", nil);
		NSString* path = [self fetchDatabaseIndex];
		if (!path)
			[NSException raise:NSGenericException format:@"Cancelled."];
		
		thread.status = NSLocalizedString(@"Opening index...", nil);
		NSManagedObjectContext* context = [self contextAtPath:path];
		
		[_sqlFileName release];
		_sqlFileName = [[path lastPathComponent] retain];
		[_sqlFilePath autorelease];
		_sqlFilePath = [path retain];
		[_managedObjectContext autorelease];
		_managedObjectContext = [context retain];
		
		
		
		
		
		
		
//		for ([ViewerController getDisplayed2DViewers] count]) {
//			
//		}
		
		
		
		
	} @catch (NSException* e) {
		@throw;
	} @finally {
		[_updateLock unlock];
		[thread exitOperation];
	}
}


-(void)updateThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSThread* thread = [NSThread currentThread];
		thread.name = NSLocalizedString(@"Updating remote database...", nil);
		[[ThreadsManager defaultManager] addThreadAndStart:thread];
		[self update];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(NSThread*)initiateUpdate {
//	if( DatabaseIsEdited) return;
	
	if ([_updateLock tryLock])
		@try {
			NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(updateThread:) object:nil];
			[thread start];
			return thread;
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		} @finally {
			[_updateLock unlock];
		}
	
	return nil;
}










-(void)save:(NSError **)err {
	NSLog(@"Notice: trying to -[RemoteDicomDatabase save], ignored");
}

-(NSString*)name {
	return _name? _name : [NSString stringWithFormat:NSLocalizedString(@"OsiriX database at %@", nil), self.address];
}

-(void)rebuild:(BOOL)complete { // do nothing
}

-(void)autoClean { // do nothing
}

-(void)addDefaultAlbums { // do nothing
}

@end
