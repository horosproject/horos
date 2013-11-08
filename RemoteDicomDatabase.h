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
    dispatch_semaphore_t _connectionsSemaphoreId;
    NSString *password;
}

@property(readonly,retain) NSString* address;
@property(readonly) NSInteger port;
@property(readonly,retain) NSHost* host;

+(RemoteDicomDatabase*)databaseForLocation:(NSString*)location port:(NSUInteger)port name:(NSString*)name update:(BOOL)flagUpdate;

-(id)initWithLocation:(NSString*)location port:(NSUInteger)port;
-(id)initWithHost:(NSHost*)host port:(NSInteger)port update:(BOOL)flagUpdate;

-(NSThread*)initiateUpdate;

-(NSString*)cacheDataForImage:(DicomImage*)image maxFiles:(NSInteger)maxFiles;
-(NSString*)localPathForImage:(DicomImage*)image;

-(void)uploadFilesAtPaths:(NSArray*)paths imageObjects:(NSArray*)images;
-(void)uploadFilesAtPaths:(NSArray*)paths imageObjects:(NSArray*)images generatedByOsiriX:(BOOL)generatedByOsiriX;

-(void)addStudies:(NSArray*)dicomStudies toAlbum:(DicomAlbum*)dicomAlbum;
-(void)removeStudies:(NSArray*)dicomStudies fromAlbum:(DicomAlbum*)dicomAlbum;

-(void)object:(NSManagedObject*)object setValue:(id)value forKey:(NSString*)key;

+(NSDictionary*)fetchDicomDestinationInfoForAddress:(NSString*)address port:(NSInteger)port;
-(NSDictionary*)fetchDicomDestinationInfo;

-(void)storeScuImages:(NSArray*)dicomImages toDestinationAETitle:(NSString*)aet address:(NSString*)address port:(NSInteger)port transferSyntax:(int)exsTransferSyntax;


@end
