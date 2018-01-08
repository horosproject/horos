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
