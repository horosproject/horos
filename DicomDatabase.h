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
	N2MutableUInteger* _dataFileIndex;
	NSString* _baseDirPath;
	NSString* _dataBaseDirPath;
	NSString* _name;
	NSRecursiveLock* _processFilesLock;
	NSTimer* _importFilesFromIncomingDirTimer;
	NSRecursiveLock* _importFilesFromIncomingDirLock;
	BOOL _isFileSystemFreeSizeLimitReached;
	NSTimeInterval _timeOfLastIsFileSystemFreeSizeLimitReachedVerification;
}

+(NSString*)defaultBaseDirPath;
+(NSString*)baseDirPathForMode:(int)mode path:(NSString*)path;

+(NSArray*)allDatabases;
+(DicomDatabase*)defaultDatabase;
+(DicomDatabase*)databaseAtPath:(NSString*)path;
+(DicomDatabase*)databaseAtPath:(NSString*)path name:(NSString*)name;
+(DicomDatabase*)databaseForContext:(NSManagedObjectContext*)c; // hopefully one day this will be __deprecated
+(DicomDatabase*)activeLocalDatabase;
+(void)setActiveLocalDatabase:(DicomDatabase*)ldb;

@property(readonly,retain) NSString* baseDirPath;
@property(readonly,retain) NSString* dataBaseDirPath;
@property(readwrite,retain) NSString* name;

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
-(NSString*)dumpDirPath;
-(NSString*)pagesDirPath;
-(NSString*)htmlTemplatesDirPath;
-(NSString*)modelVersionFilePath;  // this should become private
-(NSString*)loadingFilePath; // this should become private

-(NSUInteger)computeDataFileIndex; // this method should be private, but is declared because called from deprecated api
-(NSString*)uniquePathForNewDataFileWithExtension:(NSString*)ext;

-(void)addDefaultAlbums;
-(NSArray*)albums;
+(NSArray*)albumsInContext:(NSManagedObjectContext*)context; // this method should be private, but is declared because called from deprecated api
+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string;

-(BOOL)compressFilesAtPaths:(NSArray*)paths;
-(BOOL)compressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(BOOL)decompressFilesAtPaths:(NSArray*)paths;
-(BOOL)decompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(void)initiateCompressFilesAtPaths:(NSArray*)paths;
-(void)initiateCompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(void)initiateDecompressFilesAtPaths:(NSArray*)paths;
-(void)initiateDecompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;

-(NSArray*)addFilesAtPaths:(NSArray*)paths;
-(NSArray*)addFilesAtPaths:(NSArray*)paths dicomOnly:(BOOL)dicomOnly postNotifications:(BOOL)pastNotifications rereadExistingItems:(BOOL)rereadExistingItems;	

-(BOOL)isFileSystemFreeSizeLimitReached;
-(void)importFilesFromIncomingDir; // this method should be private, but is declared because called from deprecated api
-(void)initiateImportFilesFromIncomingDirUnlessAlreadyImporting;
-(void)syncImportFilesFromIncomingDirTimerWithUserDefaults; // called from deprecated API

// some of these methods should be private, but is declared because called from deprecated api
-(void)rebuild;
-(void)rebuild:(BOOL)complete;
-(void)checkForExistingReportForStudy:(NSManagedObject*)study;
-(void)checkReportsConsistencyWithDICOMSR;
-(void)rebuildSqlFile;
-(void)reduceCoreDataFootPrint;
-(void)checkForHtmlTemplates;

@end
