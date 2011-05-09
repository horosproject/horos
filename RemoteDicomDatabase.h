//
//  RemoteDicomDatabase.h
//  OsiriX
//
//  Created by Alessandro Volz on 04.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"

@class DicomImage, DicomAlbum;

@interface RemoteDicomDatabase : DicomDatabase {
	NSString* _baseBaseDirPath;
	NSString* _sqlFileName;
	NSString* _address;
	NSInteger _port;
	NSHost* _host;
	NSRecursiveLock* _updateLock;
	NSTimer* _updateTimer;
	NSTimeInterval _timestamp;
}

@property(readonly,retain) NSString* address;
@property(readonly) NSInteger port;
@property(readonly,retain) NSHost* host;

+(NSHost*)address:(NSString*)address toHost:(NSHost**)host port:(NSInteger*)port;
+(NSHost*)address:(NSString*)address toHost:(NSHost**)host port:(NSInteger*)port aet:(NSString**)aet;
+(NSString*)addressWithHost:(NSHost*)host port:(NSInteger)port aet:(NSString*)aet;
+(NSString*)addressWithHostname:(NSString*)host port:(NSInteger)port aet:(NSString*)aet;

+(DicomDatabase*)databaseForAddress:(NSString*)path;
+(DicomDatabase*)databaseForAddress:(NSString*)path name:(NSString*)name;

-(id)initWithAddress:(NSString*)address;
-(id)initWithHost:(NSHost*)host port:(NSInteger)port;

-(NSThread*)initiateUpdate;

-(NSString*)localPathForImage:(DicomImage*)image;

-(NSString*)fetchDataForImage:(DicomImage*)image maxFiles:(NSInteger)maxFiles;
-(void)uploadFilesAtPaths:(NSArray*)paths;
-(void)uploadFilesAtPaths:(NSArray*)paths generatedByOsiriX:(BOOL)generatedByOsiriX;
-(void)addStudies:(NSArray*)dicomStudies toAlbum:(DicomAlbum*)dicomAlbum;
-(void)removeStudies:(NSArray*)dicomStudies fromAlbum:(DicomAlbum*)dicomAlbum;
-(void)object:(NSManagedObject*)object setValue:(id)value forKey:(NSString*)key;

+(NSDictionary*)fetchDicomDestinationInfoForHost:(NSHost*)host port:(NSInteger)port;
-(NSDictionary*)fetchDicomDestinationInfo;

-(void)storeScuImages:(NSArray*)dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax;


@end
