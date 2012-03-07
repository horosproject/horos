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

#import "RemoteDicomDatabase.h"
#import "N2Debug.h"
#import "NSFileManager+N2.h"
#import "N2Connection.h"
#import "NSThread+N2.h"
#import "ThreadsManager.h"
#import "BrowserController.h" // TODO: awwww
#import "N2MutableUInteger.h"
#import "Notifications.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "DicomAlbum.h"
#import "DicomFile.h"
#import "NSManagedObject+N2.h"
#import "DCMTKStoreSCU.h"
#import "ViewerController.h"
#import "DataNodeIdentifier.h"

@interface RemoteDicomDatabase ()

@property(readwrite,retain) NSString* address;
@property(readwrite) NSInteger port;
@property(readwrite,retain) NSHost* host;

-(void)update;

@end

@implementation RemoteDicomDatabase

+(RemoteDicomDatabase*)databaseForLocation:(NSString*)location {
	return [self databaseForLocation:location name:nil];
}

+(RemoteDicomDatabase*)databaseForLocation:(NSString*)location name:(NSString*)name {
	return [self databaseForLocation:location name:nil update:YES];
}

+(RemoteDicomDatabase*)databaseForLocation:(NSString*)location name:(NSString*)name update:(BOOL)flagUpdate {
	NSHost* host;
	NSInteger port;
	[RemoteDatabaseNodeIdentifier location:location toHost:&host port:&port];
	
    if (!host.addresses.count && !host.names.count)
        [NSException raise:NSGenericException format:@"%@", NSLocalizedString(@"This remote database is unaccessible because its address could not be resolved.", nil)];
    
	NSArray* dbs = [DicomDatabase allDatabases];
	for (RemoteDicomDatabase* db in dbs)
		if ([db isKindOfClass:[RemoteDicomDatabase class]])
			if ([[(RemoteDicomDatabase*)db host] isEqualToHost:host] && [(RemoteDicomDatabase*)db port] == port) {
				if (flagUpdate)
					[db update];
				return db;
			}
	
	RemoteDicomDatabase* db = [[[self alloc] initWithHost:host port:port update:flagUpdate] autorelease];
	if (name) db.name = name;
	
	return db;
}

#pragma mark Instance

@synthesize address = _address, port = _port, host = _host;

-(NSString*)location {
    return [RemoteDatabaseNodeIdentifier locationWithAddress:self.address port:self.port];
}

-(DataNodeIdentifier*)dataNodeIdentifier {
    return [RemoteDatabaseNodeIdentifier remoteDatabaseNodeIdentifierWithLocation:self.location description:self.description dictionary:nil];
}

-(NSString*)name {
	return _name? _name : [NSString stringWithFormat:NSLocalizedString(@"OsiriX database at %@", nil), self.host.name];
}

-(id)initWithLocation:(NSString*)location {
	NSHost* host;
	NSInteger port;
	[RemoteDatabaseNodeIdentifier location:location toHost:&host port:&port];
	return [self initWithHost:host port:port update:YES];
}

-(id)initWithHost:(NSHost*)host port:(NSInteger)port update:(BOOL)flagUpdate {
	NSString* path = [NSFileManager.defaultManager tmpFilePathInTmp];
	[NSFileManager.defaultManager confirmDirectoryAtPath:path];
	
	self = [super initWithPath:path];
	_baseBaseDirPath = [path retain];
	_updateLock = [[NSRecursiveLock alloc] init];
#define MAX_SIMULTANEOUS_NONURGENT_CONNECTIONS 10
    MPCreateSemaphore(MAX_SIMULTANEOUS_NONURGENT_CONNECTIONS, MAX_SIMULTANEOUS_NONURGENT_CONNECTIONS, &_connectionsSemaphoreId);

	self.host = host;
	self.address = host.address;
	self.port = port;
	
	if (flagUpdate)
		@try {
			[self update];
		} @catch (...) {
			[self release]; self = nil;
			@throw;
		}
	
	return self;
}

-(void)dealloc {
	[_updateTimer invalidate];
	
	NSRecursiveLock* temp;
	
	temp = _updateLock;
	[temp lock]; // if currently importing, wait until finished
	_updateLock = nil;
	[temp unlock];
	[temp release];
	
    MPDeleteSemaphore(_connectionsSemaphoreId);
    
	self.address = nil;
	self.host = nil;
	
    NSString* baseBaseDirPath = [_baseBaseDirPath autorelease];
	
	[super dealloc];
	
    if (baseBaseDirPath) {
        [NSFileManager.defaultManager removeItemAtPath:baseBaseDirPath error:NULL];
    }
}

-(BOOL)isLocal {
	return NO;
}

-(void)_updateTimerCallback {
	[self initiateUpdate];
}

+(void)_updateTimerCallbackClass:(NSTimer*)timer {
	NSValue* rddp = timer.userInfo;
	RemoteDicomDatabase* rdd = (RemoteDicomDatabase*)rddp.pointerValue;
	[rdd _updateTimerCallback];
}

-(NSString*)sqlFilePath {
	if (_sqlFileName)
		return [self.baseDirPath stringByAppendingPathComponent:_sqlFileName];
	else return [super sqlFilePath];
}

-(NSString*)localPathForImage:(DicomImage*)image {
	NSString* name = nil;
	
	if (image.numberOfFrames.intValue > 1)
		name = [NSString stringWithFormat:@"%@.%@", image.XID, [image extension]];
	else name = [NSString stringWithFormat:@"%@-%d.%@", image.XID, image.instanceNumber.intValue, [image extension]];
	
	return [self.tempDirPath stringByAppendingPathComponent:[DicomFile NSreplaceBadCharacter:name]];
}

-(NSArray*)addFilesInDictionaries:(NSArray*)dicomFilesArray postNotifications:(BOOL)postNotifications rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX {
    NSArray* objectIDs = [super addFilesDescribedInDictionaries:dicomFilesArray postNotifications:postNotifications rereadExistingItems:rereadExistingItems generatedByOsiriX:generatedByOsiriX];
    
    NSArray* r = [self objectsWithIDs:objectIDs];
    
    NSMutableArray* filesToSend = [NSMutableArray arrayWithCapacity:r.count];
    for (NSInteger i = 0; i < r.count; ++i) {
        DicomImage* image = [r objectAtIndex:i];
        NSString* path = image.completePath;
        if ([path hasPrefix:self.dataDirPath]) { // is in DATABASE dir, remote databases work in TEMP dir only
            NSString* tpath = [self localPathForImage:image];
            [[NSFileManager defaultManager] removeItemAtPath:tpath error:NULL];
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:tpath error:NULL];
            path = image.pathString = tpath;
            image.pathNumber = nil;
            // [image clearCompletePathCache]; useless
        } 
        
        [filesToSend addObject:path];
    }
    
    if (filesToSend.count)
        [self performSelectorInBackground:@selector(_uploadFilesAtPathsGeneratedByOsiriX:) withObject:[NSArray arrayWithObjects:filesToSend, [NSNumber numberWithBool:generatedByOsiriX], nil]];
    
    return r;
}

-(void)_uploadFilesAtPathsGeneratedByOsiriX:(NSArray*)io {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSArray* paths = [io objectAtIndex:0];
        BOOL byOsiriX = [[io objectAtIndex:1] boolValue];
        
        NSThread* thread = [NSThread currentThread];
        thread.name = NSLocalizedString(@"Remote DICOM add...", @"name of thread that sends dicom files to the remote database after local addFiles");
        thread.status = NSLocalizedString(@"Sending data...", nil);
        [[ThreadsManager defaultManager] addThreadAndStart:thread];
        
        [self uploadFilesAtPaths:paths generatedByOsiriX:byOsiriX];
    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

#pragma mark Communication

-(NSData*)synchronousRequest:(NSData*)request urgent:(BOOL)urgent dataHandlerTarget:(id)target selector:(SEL)sel context:(void*)context {
    OSStatus waitOnSemaphoreStatus = 0;
    if (urgent)
        waitOnSemaphoreStatus = -1; // to avoid MPSignalSemaphore
    else if (_connectionsSemaphoreId)
        waitOnSemaphoreStatus = MPWaitOnSemaphore(_connectionsSemaphoreId, kDurationForever); // this limits the number of simultaneous connections to this remote database
    @try {
        return [N2Connection sendSynchronousRequest:request toAddress:self.address port:self.port dataHandlerTarget:target selector:sel context:context];
    } @catch (...) {
        @throw;
    } @finally {
        if (_connectionsSemaphoreId && waitOnSemaphoreStatus == noErr)
            MPSignalSemaphore(_connectionsSemaphoreId);
    }
    return nil;
}

-(NSData*)synchronousRequest:(NSData*)request urgent:(BOOL)now {
    return [self synchronousRequest:request urgent:now dataHandlerTarget:nil selector:nil context:nil];
}

+(void)_data:(NSMutableData*)data appendInt:(unsigned int)i {
	unsigned int big = NSSwapHostIntToBig(i);
	[data appendBytes:&big length:4];
}

+(void)_data:(NSMutableData*)data appendStringUTF8:(NSString*)str {
	const char* cstr = str.UTF8String;
	unsigned int cstrlen = cstr? strlen(cstr)+1 : 0;
	[RemoteDicomDatabase _data:data appendInt:cstrlen];
	if (cstr) [data appendBytes:cstr length:cstrlen];
}

NSString* const FailedToConnectExceptionMessage = @"Failed to connect to the remote host. Is database sharing activated on the distant computer?";
NSString* const InvalidResponseExceptionMessage = @"Invalid response data from remote host.";

-(NSString*)fetchDatabaseVersion {
	NSMutableData* request = [NSMutableData dataWithBytes:"DBVER" length:6];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return [[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] autorelease];
}

-(BOOL)fetchIsPasswordProtected {
	NSMutableData* request = [NSMutableData dataWithBytes:"ISPWD" length:6];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	if (response.length != sizeof(int)) [NSException raise:NSInternalInconsistencyException format:@"%@", NSLocalizedString(InvalidResponseExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)response.bytes))? YES : NO;
}

-(BOOL)fetchIsRightPassword:(NSString*)password {
	NSMutableData* request = [NSMutableData dataWithBytes:"PASWD" length:6];
	[RemoteDicomDatabase _data:request appendStringUTF8:password];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	if (response.length != sizeof(int)) [NSException raise:NSInternalInconsistencyException format:@"%@", NSLocalizedString(InvalidResponseExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)response.bytes))? YES : NO;
}

-(unsigned int)fetchDatabaseIndexSize {
	NSMutableData* request = [NSMutableData dataWithBytes:"DBSIZ" length:6];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	if (response.length != sizeof(int)) [NSException raise:NSInternalInconsistencyException format:@"%@", NSLocalizedString(InvalidResponseExceptionMessage, nil)];
	return NSSwapBigIntToHost(*((int*)response.bytes));
}

-(NSString*)fetchDatabaseIndex {
	NSThread* thread = [NSThread currentThread];
	thread.status = NSLocalizedString(@"Negotiating with remote OsiriX...", nil);
	
	NSString* version = [self fetchDatabaseVersion];
	
	if (![version isEqualToString:CurrentDatabaseVersion])
		[NSException raise:NSDestinationInvalidException format:NSLocalizedString(@"Invalid remote database model %@. When sharing databases, make sure both ends are running the same version of OsiriX.", nil), version];
	
//	DLog(@"RDD version: %@", version);

	BOOL isPasswordProtected = [self fetchIsPasswordProtected];
	// if (isPasswordProtected) DLog(@"RDD is password protected", version);
	NSString* password = nil;
	if (isPasswordProtected) {
		password = [[BrowserController currentBrowser] askPassword]; // TODO: awww
		BOOL isRightPassword = [self fetchIsRightPassword:password];
		if (!isRightPassword)
			[NSException raise:NSInvalidArgumentException format:@"%@", NSLocalizedString(@"Wrong password for remote database.", nil)];
		// else DLog(@"RDD password ok");
	}
	
	NSUInteger databaseIndexSize = [self fetchDatabaseIndexSize];
//	DLog(@"RDD index size is %d", databaseIndexSize);
	
	[thread enterOperation];
	thread.status = NSLocalizedString(@"Transferring database index...", nil);
	
	NSString* path = [NSFileManager.defaultManager tmpFilePathInDir:self.baseDirPath];
	NSOutputStream* fileStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
	[fileStream open];
	
	NSData* request = [NSMutableData dataWithBytes:"DATAB" length:6];
	NSArray* context = [NSArray arrayWithObjects: thread, [NSNumber numberWithUnsignedInteger:databaseIndexSize], fileStream, [N2MutableUInteger mutableUIntegerWithUInteger:0], nil];
	[self synchronousRequest:request urgent:YES dataHandlerTarget:self selector:@selector(_connection:handleData_fetchDatabaseIndex:context:) context:context];
	
	[fileStream close];
	[thread exitOperation];
	
	if (thread.isCancelled)
		return nil;
	
	thread.status = NSLocalizedString(@"Done.", nil);
	
	return path;
}

-(NSInteger)_connection:(N2Connection*)connection handleData_fetchDatabaseIndex:(NSData*)data context:(NSArray*)context {
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
		} else [NSException raise:NSGenericException format:@"%@", fileStream.streamError.localizedDescription];
	}
		
	thread.progress = 1.0*obtainedSize.unsignedIntegerValue/databaseIndexSize;
	thread.progressDetails = [NSString stringWithFormat:NSLocalizedString(@"Received %d of %d bytes", nil), obtainedSize.unsignedIntegerValue, databaseIndexSize];
	
	return data.length;
}

-(NSTimeInterval)fetchDatabaseTimestamp {
	NSMutableData* request = [NSMutableData dataWithBytes:"VERSI" length:6];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	if (response.length != sizeof(NSSwappedDouble)) [NSException raise:NSInternalInconsistencyException format:@"%@", NSLocalizedString(InvalidResponseExceptionMessage, nil)];
	return NSSwapBigDoubleToHost(*((NSSwappedDouble*)response.bytes));
}

+(NSDictionary*)fetchDicomDestinationInfoForAddress:(NSString*)address port:(NSInteger)port {
	if (!port) port = 8780;
	NSMutableData* request = [NSMutableData dataWithBytes:"GETDI" length:6];
	NSData* response = [N2Connection sendSynchronousRequest:request toAddress:address port:port];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return [NSUnarchiver unarchiveObjectWithData:response];
}

-(NSDictionary*)fetchDicomDestinationInfo {
	return [RemoteDicomDatabase fetchDicomDestinationInfoForAddress:self.address port:self.port];
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
		
		_timestamp = [self fetchDatabaseTimestamp];
		
		thread.status = NSLocalizedString(@"Opening index...", nil);
		NSManagedObjectContext* context = [self contextAtPath:path];
		
		// TODO: CHANGE!! we want to DIFF ;) or is it too slow?
		
		for (ViewerController* vc in [ViewerController getDisplayed2DViewers])
			[vc.window orderOut:self];
		
		[_sqlFileName release];
		_sqlFileName = [[path lastPathComponent] retain];
        NSString* oldSqlFilePath = [_sqlFilePath autorelease];
		_sqlFilePath = [path retain];
		self.managedObjectContext = context;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixAddToDBNotification object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:_O2AddToDBAnywayNotification object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixDicomDatabaseDidChangeContextNotification object:self];
		
        // delete old index file
        [NSFileManager.defaultManager removeItemAtPath:oldSqlFilePath error:NULL];
	} @catch (NSException* e) {
		@throw;
	} @finally {
		[_updateLock unlock];
		[thread exitOperation];
	}
	
	if (!_updateTimer) {
		_updateTimer = [NSTimer timerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"DatabaseRefreshInterval"] target:[RemoteDicomDatabase class] selector:@selector(_updateTimerCallbackClass:) userInfo:[NSValue valueWithPointer:self] repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:_updateTimer forMode:NSModalPanelRunLoopMode];
		[[NSRunLoop mainRunLoop] addTimer:_updateTimer forMode:NSDefaultRunLoopMode];
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
	
	if ([[ViewerController getDisplayed2DViewers] count])
		return nil;
	
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

-(BOOL)needsUpdate {
	NSTimeInterval timestamp = [self fetchDatabaseTimestamp];
	return timestamp != _timestamp;
}

-(NSString*)fetchFileModificationDate:(NSString*)path { // ------------------------------------ this seems to be unused
	NSMutableData* request = [NSMutableData dataWithBytes:"MFILE" length:6];
	NSData* pathData = [path dataUsingEncoding:NSUnicodeStringEncoding];
	[RemoteDicomDatabase _data:request appendInt:pathData.length];
	[request appendData:pathData];
	NSData* response = [self synchronousRequest:request urgent:YES];
	if (!response.length) [NSException raise:NSObjectInaccessibleException format:@"%@", NSLocalizedString(FailedToConnectExceptionMessage, nil)];
	return [[[NSString alloc] initWithData:response encoding:NSUnicodeStringEncoding] autorelease];
}

-(void)object:(NSManagedObject*)object setValue:(id)value forKey:(NSString*)key {
	NSMutableData* request = [NSMutableData dataWithBytes:"SETVA" length:6];
	[RemoteDicomDatabase _data:request appendStringUTF8:object.objectID.URIRepresentation.absoluteString];
	[RemoteDicomDatabase _data:request appendStringUTF8: [value isKindOfClass:[NSNumber class]]? [value stringValue] : value];
	[RemoteDicomDatabase _data:request appendStringUTF8:key];
	[self synchronousRequest:request urgent:YES];
	_timestamp = [self fetchDatabaseTimestamp];
}

enum RemoteDicomDatabaseStudiesAlbumAction { RemoteDicomDatabaseStudiesAlbumActionAdd, RemoteDicomDatabaseStudiesAlbumActionRemove };

-(void)_studies:(NSArray*)dicomStudies album:(DicomAlbum*)dicomAlbum action:(RemoteDicomDatabaseStudiesAlbumAction)action {
	const char* command = nil;
	if (action == RemoteDicomDatabaseStudiesAlbumActionAdd) command = "ADDAL";
	if (action == RemoteDicomDatabaseStudiesAlbumActionRemove) command = "REMAL";
	if (!command) [NSException raise:NSInvalidArgumentException format:@"Invalid action."];
	
	NSMutableArray* studiesIds = [NSMutableArray array];
	for (DicomStudy* dicomStudy in dicomStudies)
		[studiesIds addObject:dicomStudy.objectID.URIRepresentation.absoluteString];
	NSString* albumId = dicomAlbum.objectID.URIRepresentation.absoluteString;
	
	NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys: studiesIds, @"albumStudies", albumId, @"albumUID", nil];
	
	NSMutableData* request = [NSMutableData dataWithBytes:command length:6];
	[RemoteDicomDatabase _data:request appendStringUTF8:params.description];
	
	[self synchronousRequest:request urgent:YES];
	
	_timestamp = [self fetchDatabaseTimestamp];
}

-(void)addStudies:(NSArray*)dicomStudies toAlbum:(DicomAlbum*)dicomAlbum {
    [super addStudies:dicomStudies toAlbum:dicomAlbum];
	[self _studies:dicomStudies album:dicomAlbum action:RemoteDicomDatabaseStudiesAlbumActionAdd];
}

-(void)removeStudies:(NSArray*)dicomStudies fromAlbum:(DicomAlbum*)dicomAlbum {
	[self _studies:dicomStudies album:dicomAlbum action:RemoteDicomDatabaseStudiesAlbumActionRemove];
}

-(void)uploadFilesAtPaths:(NSArray*)paths {
	return [self uploadFilesAtPaths:paths generatedByOsiriX:NO];
}

-(void)uploadFilesAtPaths:(NSArray*)paths generatedByOsiriX:(BOOL)generatedByOsiriX {
	NSThread* thread = [NSThread currentThread];
	[thread enterOperation];
	@try {
		for (NSString* path in paths)
			if (![NSFileManager.defaultManager fileExistsAtPath:path])
				[NSException raise:NSInvalidArgumentException format:@"File not available."];
		
		NSMutableData* request = [NSMutableData dataWithBytes: generatedByOsiriX? "SENDG" : "SENDD" length:6];
		[RemoteDicomDatabase _data:request appendInt:paths.count];
		NSMutableArray* filesInRequest = [NSMutableArray array];
		
		for (NSInteger i = 0; i < paths.count; ++i) {
			NSString* path = [paths objectAtIndex:i];
			thread.progress = 1.0*(i-filesInRequest.count/2)/paths.count;
			
			[filesInRequest addObject:path];
			NSData* fileData = [[NSData alloc] initWithContentsOfFile:path];
			[RemoteDicomDatabase _data:request appendInt:fileData.length];
			[request appendData:fileData];
			[fileData release];
			
			if (request.length > 32*1024*1024 || (path == paths.lastObject && filesInRequest.count)) { // we split the send in smaller chunks to avoid allocation problems
				NSMutableData* count = [NSMutableData data];
				[RemoteDicomDatabase _data:count appendInt:filesInRequest.count];
				[request replaceBytesInRange:NSMakeRange(6,count.length) withBytes:count.bytes length:count.length];
				
				[self synchronousRequest:request urgent:YES];
                
				[request setLength:6+count.length];
				[filesInRequest removeAllObjects];
			}
            
            if (thread.isCancelled)
                break;
		}
	} @catch (...) {
		@throw;
	} @finally {
		[thread exitOperation];
	}

}

-(NSString*)cacheDataForImage:(DicomImage*)image maxFiles:(NSInteger)maxFiles { // maxFiles is veeery indicative
	NSString* localPath = [self localPathForImage:image];
	
	if ([NSFileManager.defaultManager fileExistsAtPath:localPath])
		return localPath;
	
	NSMutableArray* localPaths = [NSMutableArray array];
	NSMutableArray* remotePaths = [NSMutableArray array];
	
	NSArray* images = [image.series.images.allObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]]]; // TODO: sort after preferences
	NSInteger size = 0, i = [images indexOfObject:image];
	
	NSMutableArray* currentFetchXIDs = [NSMutableArray array];
	
	while (i < images.count) {
		DicomImage* iImage = [images objectAtIndex:i++];
		NSString* iLocalPath = [self localPathForImage:iImage];
		
		if ([NSFileManager.defaultManager fileExistsAtPath:iLocalPath])
			continue;
		
		[localPaths addObject:iLocalPath];
		[remotePaths addObject:iImage.path];
		
		size += iImage.width.intValue*iImage.height.intValue*2*iImage.numberOfFrames.intValue;
		
		if ([iImage.path.pathExtension isEqualToString:@"zip"]) { // it is a ZIP
//			NSLog(@"BONJOUR ZIP");
			NSString* iPathXml = [iImage.path.stringByDeletingPathExtension stringByAppendingPathExtension:@"xml"];
			if(![NSFileManager.defaultManager fileExistsAtPath:iPathXml]) {
				// it has an XML descriptor with it
//				NSLog(@"BONJOUR XML");
				[localPaths addObject:[iLocalPath.stringByDeletingPathExtension stringByAppendingPathExtension:@"xml"]];
				[remotePaths addObject:iPathXml];
			}
		}
		
		if (size >= maxFiles*512*512*2)
			break;
	}
	
	if (!localPaths.count)
		return nil;
	
	// DLog(@"RDD requesting images: %@", localPaths.description);
	
	NSMutableData* request = [NSMutableData dataWithBytes:"DICOM" length:6];
	
	[RemoteDicomDatabase _data:request appendInt:localPaths.count];
	for (NSString* remotePath in remotePaths)
		[RemoteDicomDatabase _data:request appendStringUTF8:remotePath];
	for (NSString* localPath in localPaths)
		[RemoteDicomDatabase _data:request appendStringUTF8:localPath];
	
	NSMutableArray* context = [NSMutableArray arrayWithObjects: [N2MutableUInteger mutableUIntegerWithUInteger:0], nil];

    NSInteger retries;
    for (retries = 0; retries < 5; ++retries) {
        [self synchronousRequest:request urgent:(maxFiles<=1) dataHandlerTarget:self selector:@selector(_connection:handleData_fetchDataForImage:context:) context:context];
        if ([NSFileManager.defaultManager fileExistsAtPath:localPath])
            break;
        [NSThread sleepForTimeInterval:0.005*retries];
    }
    
	if (![NSFileManager.defaultManager fileExistsAtPath:localPath])
        NSLog(@"Error: we tried %d times and weren't able to fetch the remote image", retries);
    else if (retries > 0) NSLog(@"Warning: we had to try %d times in order to successfully fetch a remote image", retries+1);
    
    return localPath;
}

-(NSInteger)_connection:(N2Connection*)connection handleData_fetchDataForImage:(NSData*)data context:(NSMutableArray*)context {
	N2MutableUInteger* state = [context objectAtIndex:0];
	int readSize = 0;
	
	// context[0] state
	// context[1] number of files in response
	// context[2] size of file
	// context[3] temporary file path
	// context[4] output stream to temporary file
	// context[5] total size written te tomporary file
	// context[6] size of filename
	
	while (data.length > readSize) {
		// DLog(@"_handleData_fetchDataForImage state %d", state.unsignedIntegerValue);
		switch (state.unsignedIntegerValue) {
			case 0: { // expecting number of files in response
				if (data.length-readSize >= 4) {
					unsigned int big;
					[data getBytes:&big range:NSMakeRange(readSize, 4)];
					unsigned int n = NSSwapBigIntToHost(big);
					[context addObject:[NSNumber numberWithUnsignedInt:n]]; // [1]
					//DLog(@"RDD receiving %d files", n);
					readSize += 4;
					state.unsignedIntegerValue = 1;
				} else return readSize;
			} break;
			case 1: { // expecting size of next file
				if (data.length-readSize >= 4) {
					unsigned int big;
					[data getBytes:&big range:NSMakeRange(readSize, 4)];
					unsigned int l = NSSwapBigIntToHost(big);
					[context addObject:[NSNumber numberWithUnsignedInt:l]]; // [2]
					//DLog(@"RDD next file is %d bytes", l);
					
					NSString* path = [NSFileManager.defaultManager tmpFilePathInDir:self.tempDirPath];
					[context addObject:path]; // [3]
					NSOutputStream* stream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
					[stream open];
					[context addObject:stream]; // [4]
					[context addObject:[N2MutableUInteger mutableUIntegerWithUInteger:0]]; // [5]
					
					readSize += 4;
					state.unsignedIntegerValue = 2;
				} else return readSize;
			} break;
			case 2: { // expecting file data, its length is in context
				unsigned int l = [[context objectAtIndex:2] unsignedIntValue];
				NSOutputStream* stream = [context objectAtIndex:4];
				N2MutableUInteger* streamSize = [context objectAtIndex:5];
				unsigned int ll = MIN(data.length-readSize, l-streamSize.unsignedIntegerValue);
				while (ll > 0) {
					NSInteger w = [stream write:(const uint8_t*)data.bytes+readSize maxLength:ll];
					if (w > 0) {
						ll -= w;
						readSize += w;
						streamSize.unsignedIntegerValue = streamSize.unsignedIntegerValue+w;
					} else [NSException raise:NSGenericException format:@"%@", stream.streamError.localizedDescription];
				}
				
				if (streamSize.unsignedIntegerValue >= l)
					state.unsignedIntegerValue = 3;
			} break;
			case 3: { // expecting length of name of received file
				if (data.length-readSize >= 4) {
					unsigned int big;
					[data getBytes:&big range:NSMakeRange(readSize, 4)];
					unsigned int l = NSSwapBigIntToHost(big);
					[context addObject:[NSNumber numberWithUnsignedInt:l]]; // [6]
					//DLog(@"RDD next path is %d bytes", l);
					readSize += 4;
					state.unsignedIntegerValue = 4;
				} else return readSize;
			} break;
			case 4: {
				unsigned int pathSize = [[context objectAtIndex:6] unsignedIntValue];
				if (data.length-readSize >= pathSize) {
					NSString* path = [NSString stringWithUTF8String:(char*)data.bytes+readSize];
					readSize += pathSize;
					//DLog(@"RDD path is %@", path);
					[context removeLastObject]; // rm [6]
					[context removeLastObject]; // rm [5]
					[[context objectAtIndex:4] close];
					[context removeLastObject]; // rm [4]
					
					if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
						NSLog(@"Notice: strange, we seem to have redownloaded a remote image (%@)", path);
						[NSFileManager.defaultManager removeItemAtPath:path error:NULL];
					}
					
					[NSFileManager.defaultManager moveItemAtPath:[context objectAtIndex:3] toPath:path error:NULL];
					
					[context removeLastObject]; // rm [3]
					[context removeLastObject]; // rm [2]
					state.unsignedIntegerValue = 1;
				} else return readSize;
			} break;
		}
	}
	
	return readSize;
}

-(NSData*)sendMessage:(NSDictionary*)message { // ------------------------------------ this seems to be unused
	NSMutableData* request = [NSMutableData dataWithBytes:"NEWMS" length:6];

	NSData* data = [NSPropertyListSerialization dataFromPropertyList:message format:kCFPropertyListBinaryFormat_v1_0 errorDescription:nil];
	[RemoteDicomDatabase _data:request appendInt:data.length];
	[request appendData:data];
	
	return [self synchronousRequest:request urgent:YES];
}

-(void)storeScuImages:(NSArray*)dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax {
	NSMutableArray* imagePaths = [NSMutableArray array];
	for (DicomImage* image in dicomImages)
		if (![imagePaths containsObject:image.path])
			[imagePaths addObject:image.path];
	
	NSMutableData* request = [NSMutableData dataWithBytes:"DCMSE" length:6];

	[RemoteDicomDatabase _data:request appendStringUTF8:aet];
	[RemoteDicomDatabase _data:request appendStringUTF8:address];
	[RemoteDicomDatabase _data:request appendStringUTF8:[[NSNumber numberWithInt:port] stringValue]];
	[RemoteDicomDatabase _data:request appendStringUTF8:[[NSNumber numberWithInt:[DCMTKStoreSCU sendSyntaxForListenerSyntax:exsTransferSyntax]] stringValue]];
	
	[RemoteDicomDatabase _data:request appendInt:imagePaths.count];
	for (NSString* path in imagePaths)
		[RemoteDicomDatabase _data:request appendStringUTF8:path];
	
	[self synchronousRequest:request urgent:YES];
}

-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested {
}

-(void)cleanOldStuff {
}

-(void)initiateCleanUnlessAlreadyCleaning {
}


#pragma mark Special

-(BOOL)rebuildAllowed {
	return NO;
}

-(void)initiateImportFilesFromIncomingDirUnlessAlreadyImporting { // don't
}

-(void)rebuild:(BOOL)complete { // do nothing
}

-(void)addDefaultAlbums { // do nothing
}

@end
