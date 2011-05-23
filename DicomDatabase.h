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


extern const NSString* const CurrentDatabaseVersion;

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
	NSRecursiveLock* _importFilesFromIncomingDirLock;
	BOOL _isFileSystemFreeSizeLimitReached;
	NSTimeInterval _timeOfLastIsFileSystemFreeSizeLimitReachedVerification;
	NSTimeInterval _timeOfLastModification;
	char baseDirPathC[4096], incomingDirPathC[4096], tempDirPathC[4096]; // these paths are used from the DICOM listener
	// +Routing
	NSMutableArray* _routingSendQueues;
	NSRecursiveLock* _routingLock;
	// +Clean
	NSRecursiveLock* _cleanLock;
}

+(void)initializeDicomDatabaseClass;

+(NSString*)defaultBaseDirPath;
+(NSString*)baseDirPathForPath:(NSString*)path;
+(NSString*)baseDirPathForMode:(int)mode path:(NSString*)path;

+(NSArray*)allDatabases;
+(DicomDatabase*)defaultDatabase;
+(DicomDatabase*)databaseAtPath:(NSString*)path;
+(DicomDatabase*)databaseAtPath:(NSString*)path name:(NSString*)name;
+(DicomDatabase*)databaseForContext:(NSManagedObjectContext*)c; // hopefully one day this will be __deprecated
+(DicomDatabase*)activeLocalDatabase;
+(void)setActiveLocalDatabase:(DicomDatabase*)ldb;

@property(readonly,retain) NSString* baseDirPath; // OsiriX Data
@property(readonly,retain) NSString* dataBaseDirPath; // depends on the content of the file at baseDirPath/DBFOLDER_LOCATION
@property(readwrite,retain) NSString* name;
@property(readwrite) NSTimeInterval timeOfLastModification;

-(BOOL)isLocal;

#pragma mark Entities
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

#pragma mark Paths
// these paths are inside baseDirPath
-(NSString*)sqlFilePath; // this is already defined in N2ManagedDatabase
-(NSString*)modelVersionFilePath; // this should become private
-(NSString*)loadingFilePath; // this should become private
// these paths are inside dataBaseDirPath
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
// these paths are used from the DICOM listener
-(const char*)baseDirPathC;
-(const char*)incomingDirPathC;
-(const char*)tempDirPathC;

-(NSUInteger)computeDataFileIndex; // this method should be private, but is declared because called from deprecated api
-(NSString*)uniquePathForNewDataFileWithExtension:(NSString*)ext;

#pragma mark Albums
-(void)addDefaultAlbums;
-(NSArray*)albums;
+(NSArray*)albumsInContext:(NSManagedObjectContext*)context; // this method should be private, but is declared because called from deprecated api
+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string;
-(void)resetAlbumsCache;

#pragma mark Add files
-(NSArray*)addFilesAtPaths:(NSArray*)paths;
-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications;	
-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems;	
-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX;	
-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX mountedVolume:(BOOL)mountedVolume;

#pragma mark Incoming
-(BOOL)isFileSystemFreeSizeLimitReached;
-(void)importFilesFromIncomingDir; // this method should be private, but is declared because called from deprecated api
-(void)initiateImportFilesFromIncomingDirUnlessAlreadyImporting;
+(void)syncImportFilesFromIncomingDirTimerWithUserDefaults; // called from deprecated API

#pragma mark Compress/decompress
-(BOOL)compressFilesAtPaths:(NSArray*)paths;
-(BOOL)compressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(BOOL)decompressFilesAtPaths:(NSArray*)paths;
-(BOOL)decompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(void)initiateCompressFilesAtPaths:(NSArray*)paths;
-(void)initiateCompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;
-(void)initiateDecompressFilesAtPaths:(NSArray*)paths;
-(void)initiateDecompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir;

#pragma mark Other
-(BOOL)rebuildAllowed;
// some of these methods should be private, but is declared because called from deprecated api
-(void)rebuild;
-(void)rebuild:(BOOL)complete;
-(void)checkForExistingReportForStudy:(NSManagedObject*)study;
-(void)checkReportsConsistencyWithDICOMSR;
-(void)rebuildSqlFile;
-(void)reduceCoreDataFootPrint;
-(void)checkForHtmlTemplates;

@end

#import "DicomDatabase+Routing.h"
#import "DicomDatabase+Clean.h"

