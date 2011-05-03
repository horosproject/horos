//
//  RemoteDicomDatabase.h
//  OsiriX
//
//  Created by Alessandro Volz on 04.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"


@interface RemoteDicomDatabase : DicomDatabase {
	NSString* _baseBaseDirPath;
	NSString* _sqlFileName;
	NSString* _address;
	NSInteger _port;
	NSHost* _host;
	NSRecursiveLock* _updateLock;
}

@property(readonly,retain) NSString* address;
@property(readonly) NSInteger port;
@property(readonly,retain) NSHost* host;

+(DicomDatabase*)databaseForAddress:(NSString*)path;
+(DicomDatabase*)databaseForAddress:(NSString*)path name:(NSString*)name;

-(id)initWithAddress:(NSString*)address;
-(id)initWithHost:(NSHost*)host port:(NSInteger)port;

-(NSThread*)initiateUpdate;

@end
