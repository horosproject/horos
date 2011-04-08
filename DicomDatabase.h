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

#import "N2ManagedDatabase.h"

@class N2MutableUInteger;

/*
 This class currently only does 1/1000 of what it is planned to do later.
 This will be a BrowserController's backbone.
 */
@interface DicomDatabase : N2ManagedDatabase {
	N2MutableUInteger* dataFileIndex;
	NSString* dataBasePath;
}

+(DicomDatabase*)defaultDatabase;
+(DicomDatabase*)localDatabaseAtPath:(NSString*)path;
+(DicomDatabase*)activeLocalDatabase;
+(DicomDatabase*)databaseForContext:(NSManagedObjectContext*)c;
+(void)setActiveLocalDatabase:(DicomDatabase*)ldb;

-(BOOL)isLocal;

extern const NSString* const DicomDatabaseImageEntityName;
extern const NSString* const DicomDatabaseSeriesEntityName;
extern const NSString* const DicomDatabaseStudyEntityName;
extern const NSString* const DicomDatabaseAlbumEntityName;
extern const NSString* const DicomDatabaseLogEntryEntityName;
-(NSEntityDescription*)imageEntity;
-(NSEntityDescription*)seriesEntity;
-(NSEntityDescription*)studyEntity;
-(NSEntityDescription*)albumEntity;
-(NSEntityDescription*)logEntryEntity;

-(NSString*)dataDirPath;
-(NSString*)incomingDirPath;
-(NSString*)errorsDirPath;
-(NSString*)decompressionDirPath;
-(NSString*)toBeIndexedDirPath;
-(NSString*)errorsDirPath;
-(NSString*)reportsDirPath;
-(NSString*)tempDirPath;
-(NSString*)pagesDirPath;
-(NSString*)modelVersionFilePath;  // this should become private
-(NSString*)loadingFilePath; // this should become private

-(NSUInteger)computeDataFileIndex; // this method should be private, but is declared because called from deprecated api
-(NSString*)uniquePathForNewDataFileWithExtension:(NSString*)ext;

-(void)addDefaultAlbums;
-(NSArray*)albums;
+(NSArray*)albumsInContext:(NSManagedObjectContext*)context;
+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string;

-(void)rebuild:(BOOL)complete;
-(void)checkForExistingReportForStudy:(NSManagedObject*)study; // this method should be private, but is declared because called from deprecated api

@end
