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


@interface RemoteDicomDatabase ()

@property(readwrite,retain) NSString* address;

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
	db.name = name;
	
	return db;
}

#pragma mark Instance

@synthesize address = _address;

-(id)initWithAddress:(NSString*)address {
	NSString* path = [NSFileManager.defaultManager tmpFilePathInTmp];
	[NSFileManager.defaultManager confirmDirectoryAtPath:path];
	
	self = [super initWithPath:path];
	self.address = address;
	
	return self;
}

-(void)dealloc {
	self.address = nil;
	
	NSError* err = nil;
	if (![NSFileManager.defaultManager removeItemAtPath:self.baseDirPath error:&err])
		N2LogError(err);
	else if (err) N2LogError(err);
	
	[super dealloc];
}

-(BOOL)isLocal {
	return NO;
}

-(void)save:(NSError **)err {
	NSLog(@"Notice: trying to -[RemoteDicomDatabase save], ignored");
}

-(NSString*)name {
	return _name? _name : [NSString stringWithFormat:NSLocalizedString(@"Remote Database (%@)", nil), self.baseDirPath.lastPathComponent];
}

-(void)rebuild:(BOOL)complete { // do nothing
}

-(void)autoClean { // do nothing
}

-(void)addDefaultAlbums { // do nothing
}

@end
