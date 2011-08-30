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
#import "NSString+N2.h"
#import "Notifications.h"
#import "DicomAlbum.h"
#import "NSException+N2.h"
#import "N2MutableUInteger.h"
#import "NSFileManager+N2.h"
#import "N2Debug.h"
#import "DicomImage.h"
#import "DicomStudy.h"
#import "DicomFile.h"
#import "DicomFileDCMTKCategory.h"
#import "Reports.h"
#import "ThreadsManager.h"
#import "AppController.h"
#import "NSDictionary+N2.h"
#import "BrowserControllerDCMTKCategory.h"
#import "PluginManager.h"
#import "NSThread+N2.h"
#import "NSArray+N2.h"
#import "DicomDatabase+DCMTK.h"
#import "NSError+OsiriX.h"
#import "DCMAbstractSyntaxUID.h"
#import "QueryController.h"
#import "DCMTKStudyQueryNode.h"
#import "N2Debug.h"
#import "NSUserDefaults+OsiriX.h"

NSString* const CurrentDatabaseVersion = @"2.5";


@interface DicomDatabase ()

@property(readwrite,retain) NSString* baseDirPath;
@property(readwrite,retain) NSString* dataBaseDirPath;
@property(readwrite,retain) N2MutableUInteger* dataFileIndex;

+(NSString*)sqlFilePathForBasePath:(NSString*)basePath;
-(void)modifyDefaultAlbums;
-(void)recomputePatientUIDs;
-(BOOL)upgradeSqlFileFromModelVersion:(NSString*)databaseModelVersion;

@end

@implementation DicomDatabase

+(void)initializeDicomDatabaseClass {
	[NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:OsirixCanActivateDefaultDatabaseOnlyDefaultsKey options:NSKeyValueObservingOptionInitial context:[DicomDatabase class]];
}

+(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if (context == [DicomDatabase class]) {
		if ([keyPath isEqualToString:valuesKeyPath(OsirixCanActivateDefaultDatabaseOnlyDefaultsKey)]) {
			if ([NSUserDefaults canActivateOnlyDefaultDatabase])
				[self setActiveLocalDatabase:self.defaultDatabase];
		}
	}
}

static NSString* const SqlFileName = @"Database.sql";
NSString* const OsirixDataDirName = @"OsiriX Data";

+(NSString*)baseDirPathForPath:(NSString*)path {
	// were we given a path inside a OsirixDataDirName dir?
	NSArray* pathParts = path.pathComponents;
	for (int i = pathParts.count-1; i >= 0; --i)
		if ([[pathParts objectAtIndex:i] isEqualToString:OsirixDataDirName]) {
			path = [NSString pathWithComponents:[pathParts subarrayWithRange:NSMakeRange(0,i+1)]];
			break;
		}
	
	// otherwise, consider the path was incomplete and just append the OsirixDataDirName element to tho path
	if (![[path lastPathComponent] isEqualToString:OsirixDataDirName]) 
		path = [path stringByAppendingPathComponent:OsirixDataDirName];
	
	return path;
}

+(NSString*)baseDirPathForMode:(int)mode path:(NSString*)path {
	switch (mode) {
		case 0:
			path = [NSFileManager.defaultManager findSystemFolderOfType:kDocumentsFolderType forDomain:kOnAppropriateDisk];
#ifdef MACAPPSTORE
			NSString* temp = [self baseDirPathForPath:path];
			BOOL isDir;
			if (![NSFileManager.defaultManager fileExistsAtPath:temp isDirectory:&isDir] || !isDir)
				path = [NSFileManager.defaultManager userApplicationSupportFolderForApp];
#endif
			break;
		case 1:
			break;
		default:
			path = nil;
			break;
	}
	
	path = [self baseDirPathForPath:path];
	if (!path)
		N2LogError(@"nil path");
	else {
		[NSFileManager.defaultManager confirmDirectoryAtPath:path];
	}
	
	return path;
}

+(NSString*)defaultBaseDirPath {
	NSString* path = nil;
	@try {
		path = [self baseDirPathForMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"] path:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]];
		if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {	// STILL NOT AVAILABLE?? Use the default folder.. and reset this strange URL..
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DEFAULT_DATABASELOCATION"];
			path = [self baseDirPathForMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"] path:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]];
		}
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	
	return path;
}

#pragma Factory

static DicomDatabase* defaultDatabase = nil;

+(DicomDatabase*)defaultDatabase {
	@synchronized(self) {
		if (!defaultDatabase)
			defaultDatabase = [[self databaseAtPath:[self defaultBaseDirPath] name:NSLocalizedString(@"Default DB", nil)] retain];
	}
	
	return defaultDatabase;
}

static NSMutableDictionary* databasesDictionary = nil;

+(NSArray*)allDatabases {
	@synchronized(databasesDictionary) {
		return [[[databasesDictionary allValues] copy] autorelease];
	}
	
	return nil;
}

+(void)knowAbout:(DicomDatabase*)db {
	@synchronized(self) {
		if (!databasesDictionary)
			databasesDictionary = [[NSMutableDictionary alloc] init];
	}
	
	if (db)
		@synchronized(databasesDictionary) {
			if (![[databasesDictionary allValues] containsObject:db] && ![databasesDictionary objectForKey:db.baseDirPath])
				[databasesDictionary setObject:db forKey:db.baseDirPath];
		}
}

-(void)release { // TODO: remove logs..
	NSInteger prc;
	@synchronized(self) {
		prc = self.retainCount;
//		if (prc <= 2)
//			NSLog(@"%@ - [DicomDatabase release] self.rc = %d, managedObjectContext.rc = %d ", self.name, prc, self.managedObjectContext.retainCount); 
		[super release];
	}
	
	NSInteger rc = prc-1;
//	if (rc == 1)
//		NSLog(@"\tself.rc = %d, managedObjectContext.rc = %d ", self.retainCount, self.managedObjectContext.retainCount);
//	if (rc == 0)
//		NSLog(@"\tself.rc = 0, zombies arising..?");
	
	@synchronized(databasesDictionary) {
		if (rc == 1 && [databasesDictionary keyForObject:self]) {
//			NSLog(@"\tThis database's retainCount has gone down to 1; the context has %d registered objects", self.managedObjectContext.registeredObjects.count);

			//[managedObjectContext invalidate];
				
			if (self.managedObjectContext.retainCount /*- self.managedObjectContext.registeredObjects.count*/ == 1) {
//				NSLog(@"\t\tThe context seems to be retained only by the database and by its registered objects.. We can release the database!");
					id key = [databasesDictionary keyForObject:self];
					if (key) [databasesDictionary removeObjectForKey:key];
			}
		}
	}
}

//-(id)retain {
//	NSLog(@"%@ - [DicomDatabase retain] self.rc = %d, managedObjectContext.rc = %d ", self.name, self.retainCount, self.managedObjectContext.retainCount); 
//	return [super retain];
//}

+(DicomDatabase*)databaseAtPath:(NSString*)path {
	return [[self class] databaseAtPath:path name:nil];
}

+(DicomDatabase*)databaseAtPath:(NSString*)path name:(NSString*)name {
	path = [self baseDirPathForPath:path];
	
	@synchronized(databasesDictionary) {
		DicomDatabase* database = [databasesDictionary objectForKey:path];
		if (database) return database;
		database = [[[[self class] alloc] initWithPath:[self sqlFilePathForBasePath:path]] autorelease];
		database.name = name;
		return database;
	}
	
	return nil;
}

+(DicomDatabase*)databaseForContext:(NSManagedObjectContext*)c { // hopefully one day this will be __deprecated
	if (databasesDictionary)
		@synchronized(databasesDictionary) {
			// is it the MOC of a listed database?
			for (DicomDatabase* dbi in [databasesDictionary allValues])
				if (dbi.managedObjectContext == c)
					return dbi;
			// is it an independent MOC of a listed database?
			for (DicomDatabase* dbi in [databasesDictionary allValues])
				if (dbi.managedObjectContext.persistentStoreCoordinator == c.persistentStoreCoordinator) {
					// we must return a valid DicomDatabase with the specified context
					DicomDatabase* db = [[DicomDatabase alloc] initWithPath:dbi.baseDirPath context:c];
					db.name = dbi.name;
					return db;
				}
		}
	[NSException raise:NSGenericException format:@"Unidentified database context"];
	return nil;
}

static DicomDatabase* activeLocalDatabase = nil;

+(DicomDatabase*)activeLocalDatabase {
	return activeLocalDatabase? activeLocalDatabase : self.defaultDatabase;
}

+(void)setActiveLocalDatabase:(DicomDatabase*)ldb {
	if (!ldb.isLocal)
		return;
	if (ldb != self.activeLocalDatabase) {
		[activeLocalDatabase release];
		activeLocalDatabase = [ldb retain];
		[NSNotificationCenter.defaultCenter postNotificationName:OsirixActiveLocalDatabaseDidChangeNotification object:nil];
	}
}

-(id)independentDatabase {
	DicomDatabase* idd = [super independentDatabase];
	[idd->_dataFileIndex release];
	idd->_dataFileIndex = [_dataFileIndex retain];
	return idd;
}

#pragma mark Instance

@synthesize baseDirPath = _baseDirPath, dataBaseDirPath = _dataBaseDirPath, dataFileIndex = _dataFileIndex, name = _name, timeOfLastModification = _timeOfLastModification;
@synthesize isReadOnly = _isReadOnly;

-(NSString*)description {
	return [NSString stringWithFormat:@"<%@ 0x%08x> \"%@\"", self.className, self, self.name];
}

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"OsiriXDB_DataModel.momd"]]];
    return managedObjectModel;
}

/*-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary {
	static NSMutableDictionary* dict = NULL;
	if (!dict)
		dict = [[NSMutableDictionary alloc] initWithCapacity:4];
	return dict;
}*/

-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c { // reminder: context may be nil (assigned in -[N2ManagedDatabase initWithPath:] after calling this method)
	p = [DicomDatabase baseDirPathForPath:p];
//	NSLog(@"DicomDatabase initWithPath:%@", p);
	p = [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:p];
	[NSFileManager.defaultManager confirmDirectoryAtPath:p];
	
	NSString* sqlFilePath = [DicomDatabase sqlFilePathForBasePath:p];
	BOOL isNewFile = ![NSFileManager.defaultManager fileExistsAtPath:sqlFilePath];
	
	// init and register
	
	self = [super initWithPath:sqlFilePath context:c];
	
	self.baseDirPath = p;
	_dataBaseDirPath = [NSString stringWithContentsOfFile:[p stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] encoding:NSUTF8StringEncoding error:NULL];
	if (!_dataBaseDirPath) _dataBaseDirPath = p;
	[_dataBaseDirPath retain];
	
	[DicomDatabase knowAbout:self];
	
	// post-init
	
	[NSFileManager.defaultManager removeItemAtPath:self.loadingFilePath error:nil];
	
	_dataFileIndex = [[N2MutableUInteger alloc] initWithUInteger:0];
	_processFilesLock = [[NSRecursiveLock alloc] init];
	_importFilesFromIncomingDirLock = [[NSRecursiveLock alloc] init];
	
	// create dirs if necessary
	
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.dataDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.incomingDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.tempDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.reportsDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.dumpDirPath];
	strncpy(baseDirPathC, self.baseDirPath.fileSystemRepresentation, sizeof(baseDirPathC));
	strncpy(incomingDirPathC, self.incomingDirPath.fileSystemRepresentation, sizeof(incomingDirPathC));
	strncpy(tempDirPathC, self.tempDirPath.fileSystemRepresentation, sizeof(tempDirPathC));
	
	// if a TOBEINDEXED dir exists, move it into INCOMING so we will import the data
	
	if ([NSFileManager.defaultManager fileExistsAtPath:self.toBeIndexedDirPath])
		[NSFileManager.defaultManager moveItemAtPath:self.toBeIndexedDirPath toPath:[self.incomingDirPath stringByAppendingPathComponent:@"TOBEINDEXED.noindex"] error:NULL];
	
	// report templates
	
	for (NSString* rfn in [NSArray arrayWithObjects: @"ReportTemplate.doc", @"ReportTemplate.rtf", @"ReportTemplate.odt", nil]) {
		NSString* rfp = [self.baseDirPath stringByAppendingPathComponent:rfn];
		if (![NSFileManager.defaultManager fileExistsAtPath:rfp])
			[NSFileManager.defaultManager copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:rfn] toPath:rfp error:NULL];
	}
	
	NSString* pagesTemplatesDirPath = [self.baseDirPath stringByAppendingPathComponent:@"PAGES TEMPLATES"];
	if (![NSFileManager.defaultManager fileExistsAtPath:pagesTemplatesDirPath])
		[NSFileManager.defaultManager createSymbolicLinkAtPath:pagesTemplatesDirPath withDestinationPath:[AppController checkForPagesTemplate] error:NULL];
	
	[self checkForHtmlTemplates];
	
	// ...
	
	if (isNewFile)
		[self addDefaultAlbums];
	[self modifyDefaultAlbums];
	
	[self initRouting];
	[self initClean];
	
	[DicomDatabase syncImportFilesFromIncomingDirTimerWithUserDefaults];
	
	return self;
}

-(void)dealloc {
	[self deallocClean];
	[self deallocRouting];

	NSRecursiveLock* temp;
	
	temp = _importFilesFromIncomingDirLock;
	[temp lock]; // if currently importing, wait until finished
	_importFilesFromIncomingDirLock = nil;
	[temp unlock];
	[temp release];
	
	temp = _processFilesLock;
	[temp lock]; // if currently importing, wait until finished
	_processFilesLock = nil;
	[temp unlock];
	[temp release];
	
	self.dataFileIndex = nil;
	self.dataBaseDirPath = nil;
	self.baseDirPath = nil;
	
	[super dealloc];
}

-(BOOL)isLocal {
	return YES;
}

-(NSString*)name {
	return _name? _name : [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), self.baseDirPath];
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	// custom migration
	
	NSString* modelVersion = [NSString stringWithContentsOfFile:self.modelVersionFilePath encoding:NSUTF8StringEncoding error:nil];
	if (!modelVersion) modelVersion = [NSUserDefaults.standardUserDefaults stringForKey:@"DATABASEVERSION"];
	
	if (modelVersion && ![modelVersion isEqualToString:CurrentDatabaseVersion]) {
		if ([self upgradeSqlFileFromModelVersion:modelVersion])
			[self recomputePatientUIDs]; // if upgradeSqlFileFromModelVersion returns NO, the database was rebuilt so no need to recompute IDs
	}
	
	// super + spec
	
	NSManagedObjectContext* context = [super contextAtPath:sqlFilePath];
	[context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	
	return context;
}

-(BOOL)save:(NSError **)err {
	// TODO: BrowserController did this...
//	if ([[AppController sharedAppController] isSessionInactive]) {
//		NSLog(@"---- Session is not active : db will not be saved");
//		return;
//	}
	
	BOOL b = NO;
	
	[self lock];
	@try {
		b = [super save:err];
		[NSUserDefaults.standardUserDefaults setObject:CurrentDatabaseVersion forKey:@"DATABASEVERSION"];
		[CurrentDatabaseVersion writeToFile:self.modelVersionFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self unlock];
	}
	
	return b;
}

NSString* const DicomDatabaseImageEntityName = @"Image";
NSString* const DicomDatabaseSeriesEntityName = @"Series";
NSString* const DicomDatabaseStudyEntityName = @"Study";
NSString* const DicomDatabaseAlbumEntityName = @"Album";
NSString* const DicomDatabaseLogEntryEntityName = @"LogEntry";

-(NSEntityDescription*)imageEntity {
	return [self entityForName:DicomDatabaseImageEntityName];
}

-(NSEntityDescription*)seriesEntity {
	return [self entityForName:DicomDatabaseSeriesEntityName];
}

-(NSEntityDescription*)studyEntity {
	return [self entityForName:DicomDatabaseStudyEntityName];
}

-(NSEntityDescription*)albumEntity {
	return [self entityForName:DicomDatabaseAlbumEntityName];
}

-(NSEntityDescription*)logEntryEntity {
	return [self entityForName:DicomDatabaseLogEntryEntityName];
}

+(NSString*)sqlFilePathForBasePath:(NSString*)basePath {
	return [basePath stringByAppendingPathComponent:SqlFileName];
}

-(NSString*)sqlFilePath {
	return [DicomDatabase sqlFilePathForBasePath:self.baseDirPath];
}

-(NSString*)dataDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"DATABASE.noindex"]];
}

-(NSString*)incomingDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"INCOMING.noindex"]];
}

-(NSString*)decompressionDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"DECOMPRESSION.noindex"]];
}

-(NSString*)toBeIndexedDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"TOBEINDEXED.noindex"]];
}

-(NSString*)tempDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"TEMP.noindex"]];
}

-(NSString*)dumpDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"DUMP"]];
}

-(NSString*)errorsDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"NOT READABLE"]];
}

-(NSString*)reportsDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"REPORTS"]];
}

-(NSString*)pagesDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"PAGES"]];
}

-(NSString*)roisDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"ROIs"]];
}

-(NSString*)htmlTemplatesDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBaseDirPath stringByAppendingPathComponent:@"HTML_TEMPLATES"]];
}

-(NSString*)modelVersionFilePath {
	return [self.baseDirPath stringByAppendingPathComponent:@"DB_VERSION"];
}

-(NSString*)loadingFilePath {
	return [self.baseDirPath stringByAppendingPathComponent:@"Loading"];
}

-(const char*)baseDirPathC {
	return baseDirPathC;
}

-(const char*)incomingDirPathC {
	return incomingDirPathC;
}

-(const char*)tempDirPathC {
	return tempDirPathC;
}

-(NSUInteger)computeDataFileIndex {
	DLog(@"In -[DicomDatabase computeDataFileIndex] for %@ initially %ld", self.sqlFilePath, _dataFileIndex.unsignedIntegerValue);
	
	BOOL hereBecauseZero = (_dataFileIndex.unsignedIntegerValue == 0);
	@synchronized(_dataFileIndex) {
		if (hereBecauseZero && _dataFileIndex.unsignedIntegerValue != 0)
			return _dataFileIndex.unsignedIntegerValue += 1;
		@try {
			NSString* path = self.dataDirPath;
//			NSLog(@"Path is %@", path);

			// delete empty dirs and scan for files with number names
			NSArray* fs = [[NSFileManager.defaultManager enumeratorAtPath:path filesOnly:NO recursive:NO] allObjects]; // [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil];
//			NSLog(@"Scanning %d dirs", fs.count);
			for (NSString* f in fs) {
//				NSLog(@"Scanning dir %@", f);
				NSString* fpath = [path stringByAppendingPathComponent:f];
				//NSDictionary* fattr = [NSFileManager.defaultManager fileAttributesAtPath:fpath traverseLink:YES];
				//NSLog(@"Has %d attrs", fattr.count);
				
				// check if this folder is empty, and delete it if necessary
				BOOL isDir;
				if ([NSFileManager.defaultManager fileExistsAtPath:fpath isDirectory:&isDir] && isDir) {
					NSAutoreleasePool* pool = [NSAutoreleasePool new];
					@try {
						BOOL hasValidFiles = NO;
						
//						NSLog(@"Content of %@", f);
						N2DirectoryEnumerator* n2de = [NSFileManager.defaultManager enumeratorAtPath:fpath filesOnly:NO recursive:NO];
						NSString* s;
						while (s = [n2de nextObject]) // [NSFileManager.defaultManager contentsOfDirectoryAtPath:fpath error:nil])
							if ([[s stringByDeletingPathExtension] integerValue] > 0) {
								hasValidFiles = YES;
								break;
							}
						
						if (!hasValidFiles)
							[NSFileManager.defaultManager removeItemAtPath:fpath error:nil];
						else {
							NSUInteger fi = [f integerValue];
							if (fi > _dataFileIndex.unsignedIntegerValue)
								_dataFileIndex.unsignedIntegerValue = fi;
						}
					} @catch (NSException* e) {
						N2LogExceptionWithStackTrace(e);
					} @finally {
						[pool release];
					}
				}
			}
			
			// scan directories
			
			if (_dataFileIndex.unsignedIntegerValue > 0) {
//				NSLog(@"datafileindex is %d", _dataFileIndex.unsignedIntegerValue);
				
				NSInteger t = _dataFileIndex.unsignedIntegerValue;
				t -= [BrowserController DefaultFolderSizeForDB];
				if (t < 0) t = 0;
				
				NSArray* paths = [[NSFileManager.defaultManager enumeratorAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", _dataFileIndex.unsignedIntegerValue]] filesOnly:NO recursive:NO] allObjects]; // [NSFileManager.defaultManager contentsOfDirectoryAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", _dataFileIndex.unsignedIntegerValue]] error:nil];
//				NSLog(@"contains %d files", paths.count);
				for (NSString* s in paths) {
					long si = [[s stringByDeletingPathExtension] integerValue];
					if (si > t)
						t = si;
				}
				
				_dataFileIndex.unsignedIntegerValue = t;
			}
			
			if (!_dataFileIndex.unsignedIntegerValue)
				_dataFileIndex.unsignedIntegerValue = 1;
			
			DLog(@"   -[DicomDatabase computeDataFileIndex] for %@ computed %ld", self.sqlFilePath, _dataFileIndex.unsignedIntegerValue);
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		}
	}
	
	return _dataFileIndex.unsignedIntegerValue;
}

-(NSString*)uniquePathForNewDataFileWithExtension:(NSString*)ext {
	NSString* path = nil;
	
	if (ext.length > 4 || ext.length < 3) {
		if (ext.length)
			NSLog(@"Warning: strange extension \"%@\", it will be replaced with \"dcm\"", ext);
		ext = @"dcm"; 
	}

	@synchronized(_dataFileIndex) {
		NSString* dataDirPath = self.dataDirPath;
		[NSFileManager.defaultManager confirmNoIndexDirectoryAtPath:dataDirPath]; // old impl only did this every 3 secs..
		
		if (!_dataFileIndex.unsignedIntegerValue)
			[self computeDataFileIndex];
		[_dataFileIndex increment];
		long long defaultFolderSizeForDB = [BrowserController DefaultFolderSizeForDB];
		
		BOOL fileExists = NO, firstExists = YES;
		do {
			long long subFolderInt = defaultFolderSizeForDB*(_dataFileIndex.unsignedIntegerValue/defaultFolderSizeForDB+1);
			NSString* subFolderPath = [dataDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld", subFolderInt]];
			[NSFileManager.defaultManager confirmDirectoryAtPath:subFolderPath];
			
			path = [subFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.%@", (long long)_dataFileIndex.unsignedIntegerValue, ext]];
			fileExists = [NSFileManager.defaultManager fileExistsAtPath:path];
			
			if (fileExists)
				if (firstExists) {
					firstExists = NO;
					[self computeDataFileIndex];
				} else [_dataFileIndex increment];
		} while (fileExists);
	}

	return path;
}

#pragma mark Albums

+(NSArray*)albumsInContext:(NSManagedObjectContext*)context {
	if (!context) return [NSArray array];
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:DicomDatabaseAlbumEntityName inManagedObjectContext:context];
	req.predicate = [NSPredicate predicateWithValue:YES];
    
    [context lock];
    @try {
        return [context executeFetchRequest:req error:NULL];
    } @catch (NSException* e) {
        N2LogException(e);
    } @finally {
        [context unlock];
    }
    
    return nil;
}

-(NSArray*)albums {
	NSArray* albums = [DicomDatabase albumsInContext:self.managedObjectContext];
	NSSortDescriptor* sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	return [albums sortedArrayUsingDescriptors:[NSArray arrayWithObject: sd]];
}

+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string {
	if (!string.length)
		return [NSPredicate predicateWithValue:YES];
	
	NSMutableString* pred = [NSMutableString stringWithString: string];
	
	// DATES
	NSCalendarDate* now = [NSCalendarDate calendarDate];
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
	NSDictionary* sub = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*1] timeIntervalSinceReferenceDate]],			@"$LASTHOUR",
						 [NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*6] timeIntervalSinceReferenceDate]],			@"$LAST6HOURS",
						 [NSString stringWithFormat:@"%lf", [[now addTimeInterval: -60*60*12] timeIntervalSinceReferenceDate]],			@"$LAST12HOURS",
						 [NSString stringWithFormat:@"%lf", [start timeIntervalSinceReferenceDate]],										@"$TODAY",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24] timeIntervalSinceReferenceDate]],		@"$YESTERDAY",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*2] timeIntervalSinceReferenceDate]],		@"$2DAYS",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*7] timeIntervalSinceReferenceDate]],		@"$WEEK",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31] timeIntervalSinceReferenceDate]],		@"$MONTH",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31*2] timeIntervalSinceReferenceDate]],	@"$2MONTHS",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*31*3] timeIntervalSinceReferenceDate]],	@"$3MONTHS",
						 [NSString stringWithFormat:@"%lf", [[start addTimeInterval: -60*60*24*365] timeIntervalSinceReferenceDate]],	@"$YEAR",
						 nil];
	
	for (NSString* key in sub)
		[pred replaceOccurrencesOfString:key withString:[sub valueForKey:key] options:NSCaseInsensitiveSearch range:pred.range];
	
	return [NSPredicate predicateWithFormat:pred];
}

-(void)addDefaultAlbums {
	NSDictionary* albumDescriptors = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"(dateAdded >= CAST($LASTHOUR, 'NSDate'))", @"Just Added",
									  @"(ANY series.modality CONTAINS[cd] 'MR') AND (date >= CAST($TODAY, 'NSDate'))", @"Today MR",
									  @"(ANY series.modality CONTAINS[cd] 'CT') AND (date >= CAST($TODAY, 'NSDate'))", @"Today CT",
									  @"(ANY series.modality CONTAINS[cd] 'MR') AND (date >= CAST($YESTERDAY, 'NSDate') AND date <= CAST($TODAY, 'NSDate'))", @"Yesterday MR",
									  @"(ANY series.modality CONTAINS[cd] 'CT') AND (date >= CAST($YESTERDAY, 'NSDate') AND date <= CAST($TODAY, 'NSDate'))", @"Yesterday CT",
									  [NSNull null], @"Interesting Cases",
									  @"(comment != '' AND comment != NIL)", @"Cases with comments",
									  NULL];
	
	NSArray* albums = [self albums];
	
	for (NSString* name in albumDescriptors) {
		NSString* localizedName = NSLocalizedString(name, nil);
		if ([[albums valueForKey:@"name"] indexOfObject:localizedName] == NSNotFound) {
			DicomAlbum* album = [self newObjectForEntity:self.albumEntity];
			album.name = localizedName;
			NSString* predicate = [albumDescriptors objectForKey:name];
			if ([predicate isKindOfClass:[NSString class]]) {
				album.predicateString = predicate;
				album.smartAlbum = [NSNumber numberWithBool:YES];
			}
		}
	}
	
	[self save:nil];
}

-(void)modifyDefaultAlbums {
	@try {
		for (DicomAlbum* album in self.albums)
			if ([album.predicateString isEqualToString:@"(ANY series.comment != '' AND ANY series.comment != NIL) OR (comment != '' AND comment != NIL)"])
				album.predicateString = @"(comment != '' AND comment != NIL)";
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
}

#pragma mark Lifecycle

-(BOOL)isFileSystemFreeSizeLimitReached {
	NSTimeInterval currentTime = NSDate.timeIntervalSinceReferenceDate;
	if (currentTime-_timeOfLastIsFileSystemFreeSizeLimitReachedVerification > 20) {
		// refresh _isFileSystemFreeSizeLimitReached
		NSDictionary* dataBasePathAttrs = [[NSFileManager defaultManager] fileSystemAttributesAtPath:self.dataBaseDirPath];
		NSNumber* dataBasePathFreeSize = [dataBasePathAttrs objectForKey:NSFileSystemFreeSize];
		if (dataBasePathFreeSize) {
			unsigned long long freeBytes = [dataBasePathFreeSize unsignedLongLongValue], freeMegaBytes = freeBytes/1024/1024;
			
			_isFileSystemFreeSizeLimitReached = freeMegaBytes < 300; // 300 MB is the lower limit
			_timeOfLastIsFileSystemFreeSizeLimitReachedVerification = currentTime;
			
			if (_isFileSystemFreeSizeLimitReached)
				NSLog(@"Warning: the volume used to store data for %@ is full, incoming files will be deleted and DICOM transferts will be rejected", self.name);			
		} else return YES;
	}

	return _isFileSystemFreeSizeLimitReached;
}



//- (void)listenerAnonymizeFiles: (NSArray*)files
//{
//#ifndef OSIRIX_LIGHT
//	NSArray* array = [NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"**anonymized**", nil];
//	NSMutableArray* tags = [NSMutableArray array];
//	
//	[tags addObject:array];
//	
//	for( NSString *file in files)
//	{
//		NSString *destPath = [file stringByAppendingString:@"temp"];
//		
//		@try
//		{
//			[DCMObject anonymizeContentsOfFile: file  tags:tags  writingToFile:destPath];
//		}
//		@catch (NSException * e)
//		{
//          N2LogExceptionWithStackTrace(e);
//		}
//		
//		[[NSFileManager defaultManager] removeFileAtPath: file handler: nil];
//		[[NSFileManager defaultManager] movePath:destPath toPath: file handler: nil];
//	}
//#endif
//}

enum { Compress, Decompress };

-(BOOL)compressFilesAtPaths:(NSArray*)paths {
	return [DicomDatabase compressDicomFilesAtPaths:paths];
}

-(BOOL)compressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir {
	return [DicomDatabase compressDicomFilesAtPaths:paths intoDirAtPath:destDir];
}

-(BOOL)decompressFilesAtPaths:(NSArray*)paths {
	return [DicomDatabase decompressDicomFilesAtPaths:paths];
}

-(BOOL)decompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir {
	return [DicomDatabase decompressDicomFilesAtPaths:paths intoDirAtPath:destDir];
}

-(void)_processFilesAtPaths_processChunk:(NSArray*)io {
	NSArray* chunk = [io objectAtIndex:0];
	NSString* destDir = [io objectAtIndex:1];
	int mode = [[io objectAtIndex:2] intValue];
	
	if (mode == Compress)
		[DicomDatabase compressDicomFilesAtPaths:chunk intoDirAtPath:destDir];
	else [DicomDatabase decompressDicomFilesAtPaths:chunk intoDirAtPath:destDir];
}

-(void)processFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir mode:(int)mode {
	NSString* nameFormat = mode == Compress ? NSLocalizedString(@"Compressing %d DICOM files...", nil) : NSLocalizedString(@"Decompressing %d DICOM files...", nil);
	
	NSThread* thread = [NSThread currentThread];
//	[thread pushLevel];
	thread.name = [NSString stringWithFormat:nameFormat, paths.count];
	thread.status = NSLocalizedString(@"Waiting for similar threads to complete...", nil);
	
	[_processFilesLock lock];
	@try {
		thread.status = NSLocalizedString(@"Processing...", nil);
		
		size_t nTasks = MPProcessors();
		size_t chunkSize = paths.count/nTasks;
		if (chunkSize < 20) chunkSize = 20;
		
		NSArray* chunks = [paths splitArrayIntoArraysOfMinSize:chunkSize maxArrays:nTasks];
		
		NSOperationQueue* queue = [NSOperationQueue new];
		for (NSArray* chunk in chunks)
			[queue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_processFilesAtPaths_processChunk:) object:[NSArray arrayWithObjects: chunk, destDir, [NSNumber numberWithInt:mode], nil]] autorelease]];
		[queue waitUntilAllOperationsAreFinished];
		[queue release];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_processFilesLock unlock];
//		[thread popLevel];
	}
}

-(void)threadBridgeForProcessFilesAtPaths:(NSDictionary*)params {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		[self processFilesAtPaths:[params objectForKey:@":"] intoDirAtPath:[params objectForKey:@"intoDirAtPath:"] mode:[[params objectForKey:@"mode:"] intValue]];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(void)initiateProcessFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir mode:(int)mode {
	[self performSelectorInBackground:@selector(threadBridgeForProcessFilesAtPaths:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:
																								 paths, @":",
																								 [NSNumber numberWithInt:mode], @"mode:",
																								 destDir, @"intoDirAtPath:", // destDir can be nil
																								 nil]];
}

-(void)initiateCompressFilesAtPaths:(NSArray*)paths {
	[self initiateProcessFilesAtPaths:paths intoDirAtPath:nil mode:Compress];
}

-(void)initiateCompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir {
	[self initiateProcessFilesAtPaths:paths intoDirAtPath:destDir mode:Compress];
}

-(void)initiateDecompressFilesAtPaths:(NSArray*)paths {
	[self initiateProcessFilesAtPaths:paths intoDirAtPath:nil mode:Decompress];
}

-(void)initiateDecompressFilesAtPaths:(NSArray*)paths intoDirAtPath:(NSString*)destDir {
	[self initiateProcessFilesAtPaths:paths intoDirAtPath:destDir mode:Decompress];
}




-(NSArray*)addFilesAtPaths:(NSArray*)paths {
	return [self addFilesAtPaths:paths postNotifications:YES];
}

-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications {
	return [self addFilesAtPaths:paths postNotifications:postNotifications dicomOnly:NO rereadExistingItems:NO];
}

-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems {
	return [self addFilesAtPaths:paths postNotifications:postNotifications dicomOnly:dicomOnly rereadExistingItems:rereadExistingItems generatedByOsiriX:NO];
}

-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX {
	return [self addFilesAtPaths:paths postNotifications:postNotifications dicomOnly:dicomOnly rereadExistingItems:rereadExistingItems generatedByOsiriX:generatedByOsiriX mountedVolume:NO];
}

-(NSArray*)addFilesAtPaths:(NSArray*)paths postNotifications:(BOOL)postNotifications dicomOnly:(BOOL)dicomOnly rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX mountedVolume:(BOOL)mountedVolume {
	NSThread* thread = [NSThread currentThread];
	
	NSArray* chunks = [paths splitArrayIntoArraysOfMinSize:100000 maxArrays:0];
	NSMutableArray* retArray = [NSMutableArray array];

	NSError* error = nil;
	
	NSString* errorsDirPath = self.errorsDirPath;
	NSString* dataDirPath = self.dataDirPath;
	NSString* reportsDirPath = self.reportsDirPath;
	NSString* tempDirPath = self.tempDirPath;
	
	//[thread enterOperationWithRange:0:0.66]
	
	for (NSArray* newFilesArray in chunks) {
		NSManagedObjectModel* model = self.managedObjectModel;
		NSMutableArray *completeImagesArray = nil, *modifiedStudiesArray = nil;
		BOOL DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"], addFailed = NO;
		NSMutableArray *dicomFilesArray = [NSMutableArray arrayWithCapacity: [newFilesArray count]];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: dataDirPath] == NO)
			[[NSFileManager defaultManager] createDirectoryAtPath: dataDirPath attributes:nil];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: reportsDirPath] == NO)
			[[NSFileManager defaultManager] createDirectoryAtPath: reportsDirPath attributes:nil];
		
		if ([newFilesArray count] == 0) return [NSMutableArray array];
		
		//	if ([[NSUserDefaults standardUserDefaults] boolForKey: @"onlyDICOM"]) onlyDICOM = YES;
		
//#define RANDOMFILES
#ifdef RANDOMFILES
		NSMutableArray* randomArray = [NSMutableArray array];
		for( int i = 0; i < 50000; i++)
			[randomArray addObject:@"yahoo/google/osirix/microsoft"];
		newFilesArray = randomArray;
#endif
		
		BOOL isCDMedia = [BrowserController isItCD:[newFilesArray objectAtIndex:0]];
		[DicomFile setFilesAreFromCDMedia:isCDMedia];
		
		for (NSInteger i = 0; i < newFilesArray.count; ++i) {
	//		thread.progress = 1.0*i/newFilesArray.count;
			
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			@try {
				NSString* newFile = [newFilesArray objectAtIndex:i];
				DicomFile *curFile = nil;
				NSMutableDictionary	*curDict = nil;
				
				@try {
#ifdef RANDOMFILES
					curFile = [[DicomFile alloc] initRandom];
#else
					curFile = [[DicomFile alloc] init:newFile];
#endif
				} @catch (NSException * e) {
					N2LogExceptionWithStackTrace(e);
				}
				
				if (curFile)
				{
					curDict = [curFile dicomElements];
					
					if (dicomOnly)
					{
						if ([[curDict objectForKey: @"fileType"] hasPrefix:@"DICOM"] == NO)
							curDict = nil;
					}
					
					if (curDict)
					{
						[dicomFilesArray addObject: curDict];
					}
					else
					{
						// This file was not readable -> If it is located in the DATABASE folder, we have to delete it or to move it to the 'NOT READABLE' folder
						if (dataDirPath && [newFile hasPrefix: dataDirPath])
						{
							NSLog(@"**** Unreadable file: %@", newFile);
							
							if ( DELETEFILELISTENER)
							{
								[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
							}
							else
							{
								NSLog(@"**** This file in the DATABASE folder: move it to the unreadable folder");
								
								if ([[NSFileManager defaultManager] movePath: newFile toPath:[errorsDirPath stringByAppendingPathComponent: [newFile lastPathComponent]]  handler:nil] == NO)
									[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
							}
						}
					}
					
					[curFile release];
				}
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			} @finally {
				[pool release];
			}
			
			if (thread.isCancelled)
				break;
		}
		
		if( mountedVolume)
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"someImagesAreMounted"];
		
		// Find all current studies
		
		
		[thread enterOperation/*WithRange:0.66:0.34*/];
		NSArray* addedImagesArray = [self addFilesDescribedInDictionaries:dicomFilesArray postNotifications:postNotifications rereadExistingItems:rereadExistingItems generatedByOsiriX:generatedByOsiriX mountedVolume:mountedVolume];
		[thread exitOperation];
		
		
		
		[DicomFile setFilesAreFromCDMedia: NO];
		
		[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/dicomsr_osirix" handler: nil];
		
		if (addFailed)
		{
			NSLog(@"adding failed....");
			
			return nil;
		}
		
		[retArray addObjectsFromArray:addedImagesArray];
	}
	
	return retArray;
}

/*
 Keys in (MUTABLE) dictionaries:
 
 filePath
 SOPClassUID
 seriesDescription
 seriesID (?)
 fileType
 studyID
 patientUID
 modality
 
 accessionNumber
 patientBirthDate
 patientSex
 patientName
 patientID
 studyNumber
 studyDescription
 referringPhysiciansName
 performingPhysiciansName
 institutionName
 
 hasDICOM
 studyDate
 date
 seriesDICOMUID
 SOPClassUID
 seriesID
 seriesDescription
 seriesNumber
 studyDate
 protocolName
 
 numberOfFrames
 SOPUID* ()
 imageID* ()
 
 sliceLocation
 fileType
 height
 width
 numberOfSeries
 numberOfROIs
 referencedSOPInstanceUID
 commentsAutoFill
 seriesComments
 studyComments
 stateText
 keyFrames
 
 album
 
 */
-(NSArray*)addFilesDescribedInDictionaries:(NSArray*)dicomFilesArray postNotifications:(BOOL)postNotifications rereadExistingItems:(BOOL)rereadExistingItems generatedByOsiriX:(BOOL)generatedByOsiriX mountedVolume:(BOOL)mountedVolume {
	NSThread* thread = [NSThread currentThread];
	NSMutableArray* addedImagesArray = [NSMutableArray arrayWithCapacity: [dicomFilesArray count]];
	[self lock];
	@try {
		NSMutableArray* studiesArray = [[self objectsForEntity:self.studyEntity] mutableCopy];
		
		NSDate *defaultDate = [NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:nil];
		
		NSMutableArray* completeImagesArray = [NSMutableArray arrayWithCapacity: [dicomFilesArray count]];
		NSMutableArray* modifiedStudiesArray = [NSMutableArray array];
		
		DicomStudy *study = nil;
		DicomSeries *seriesTable = nil;
		DicomImage *image = nil;
		NSMutableArray *studiesArrayStudyInstanceUID = [[studiesArray valueForKey:@"studyInstanceUID"] mutableCopy];
		
		NSString *curPatientUID = nil, *curStudyID = nil, *curSerieID = nil;
		BOOL newStudy = NO, newObject = NO;
		
		NSDate* today = [NSDate date];
		NSString* dataDirPath = self.dataDirPath;
		NSString* reportsDirPath = self.reportsDirPath;
		NSString* errorsDirPath = self.errorsDirPath;
		int combineProjectionSeries = [[NSUserDefaults standardUserDefaults] boolForKey:@"combineProjectionSeries"], combineProjectionSeriesMode = [[NSUserDefaults standardUserDefaults] boolForKey: @"combineProjectionSeriesMode"];
		BOOL COMMENTSAUTOFILL = [[NSUserDefaults standardUserDefaults] boolForKey: @"COMMENTSAUTOFILL"];
		BOOL DELETEFILELISTENER = [[NSUserDefaults standardUserDefaults] boolForKey: @"DELETEFILELISTENER"];

		NSString* newFile = nil;
		
		// Add the new files
		for (NSInteger i = 0; i < dicomFilesArray.count; ++i) {
			thread.progress = 1.0*i/dicomFilesArray.count;
			
			@try {
				NSMutableDictionary *curDict = [dicomFilesArray objectAtIndex:i];
//				NSLog(@"curDict: %@", curDict);
				
				newFile = [curDict objectForKey:@"filePath"];
				
				BOOL DICOMSR = NO;
				BOOL inParseExistingObject = rereadExistingItems;
				
				NSString *SOPClassUID = [curDict objectForKey:@"SOPClassUID"];
				
				if ([DCMAbstractSyntaxUID isStructuredReport: SOPClassUID])
				{
					// Check if it is an OsiriX Annotations SR
					if ([[curDict valueForKey:@"seriesDescription"] isEqualToString: @"OsiriX Annotations SR"])
					{
						[curDict setValue: @"OsiriX Annotations SR" forKey: @"seriesID"];
						inParseExistingObject = YES;
						DICOMSR = YES;
					}
					
					// Check if it is an OsiriX ROI SR
					if ([[curDict valueForKey:@"seriesDescription"] isEqualToString: @"OsiriX ROI SR"])
					{
						[curDict setValue: @"OsiriX ROI SR" forKey: @"seriesID"];
						
						inParseExistingObject = YES;
						DICOMSR = YES;
					}
					
					// Check if it is an OsiriX Report SR
					if ([[curDict valueForKey:@"seriesDescription"] isEqualToString: @"OsiriX Report SR"])
					{
						[curDict setValue: @"OsiriX Report SR" forKey: @"seriesID"];
						
						inParseExistingObject = YES;
						DICOMSR = YES;
					}
				}
				
				if (SOPClassUID != nil 
				   && [DCMAbstractSyntaxUID isImageStorage: SOPClassUID] == NO 
				   && [DCMAbstractSyntaxUID isRadiotherapy: SOPClassUID] == NO
				   && [DCMAbstractSyntaxUID isStructuredReport: SOPClassUID] == NO
				   && [DCMAbstractSyntaxUID isKeyObjectDocument: SOPClassUID] == NO
				   && [DCMAbstractSyntaxUID isPresentationState: SOPClassUID] == NO
				   && [DCMAbstractSyntaxUID isSupportedPrivateClasses: SOPClassUID] == NO
				   && [DCMAbstractSyntaxUID isWaveform: SOPClassUID] == NO)
				{
					NSLog(@"unsupported DICOM SOP CLASS (%@)-> Reject the file : %@", SOPClassUID, newFile);
					curDict = nil;
				}
				
				if ([curDict objectForKey:@"SOPClassUID"] == nil && [[curDict objectForKey: @"fileType"] hasPrefix:@"DICOM"] == YES)
				{
					NSLog(@"no DICOM SOP CLASS -> Reject the file: %@", newFile);
					curDict = nil;
				}
				
				if (curDict != nil)
				{
					if ([[curDict objectForKey: @"studyID"] isEqualToString: curStudyID] == YES && [[curDict objectForKey: @"patientUID"] caseInsensitiveCompare: curPatientUID] == NSOrderedSame)
					{
						if ([[study valueForKey: @"modality"] isEqualToString: @"SR"] || [[study valueForKey: @"modality"] isEqualToString: @"OT"])
							[study setValue: [curDict objectForKey: @"modality"] forKey:@"modality"];
					}
					else
					{
						/*******************************************/
						/*********** Find study object *************/
						// match: StudyInstanceUID and patientUID (see patientUID function in dicomFile.m, based on patientName, patientID and patientBirthDate)
						study = nil;
						curSerieID = nil;
						
						NSInteger index = [studiesArrayStudyInstanceUID indexOfObject:[curDict objectForKey: @"studyID"]];
						
						if (index != NSNotFound)
						{
							if ([[curDict objectForKey: @"fileType"] hasPrefix:@"DICOM"] == NO) // We do this double check only for DICOM files.
							{
								study = [studiesArray objectAtIndex: index];
							}
							else
							{
								if ([[curDict objectForKey: @"patientUID"] caseInsensitiveCompare: [[studiesArray objectAtIndex: index] valueForKey: @"patientUID"]] == NSOrderedSame)
									study = [studiesArray objectAtIndex: index];
								else
								{
									NSLog( @"-*-*-*-*-* same studyUID (%@), but not same patientUID (%@ versus %@)", [curDict objectForKey: @"studyID"], [curDict objectForKey: @"patientUID"], [[studiesArray objectAtIndex: index] valueForKey: @"patientUID"]);
									
									NSString *curUID = [curDict objectForKey: @"studyID"];
									for( int i = 0 ; i < [studiesArrayStudyInstanceUID count]; i++)
									{
										NSString *uid = [studiesArrayStudyInstanceUID objectAtIndex: i];
										
										if ([uid isEqualToString: curUID])
										{
											if ([[curDict objectForKey: @"patientUID"] caseInsensitiveCompare: [[studiesArray objectAtIndex: i] valueForKey: @"patientUID"]] == NSOrderedSame)
												study = [studiesArray objectAtIndex: i];
										}
									}
								}
							}
						}
						
						if (study == nil)
						{
							// Fields
							study = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext:self.managedObjectContext];
							
							newObject = YES;
							newStudy = YES;
							
							study.dateAdded = today;
							
							[studiesArray addObject: study];
							[studiesArrayStudyInstanceUID addObject: [curDict objectForKey: @"studyID"]];
							
							curSerieID = nil;
						}
						else
						{
							newObject = NO;
						}
						
						if (newObject || inParseExistingObject)
						{
							study.studyInstanceUID = [curDict objectForKey: @"studyID"];
							study.accessionNumber = [curDict objectForKey: @"accessionNumber"];
							study.modality = [curDict objectForKey: @"modality"];
							study.dateOfBirth = [curDict objectForKey: @"patientBirthDate"];
							study.patientSex = [curDict objectForKey: @"patientSex"];
							study.patientID = [curDict objectForKey: @"patientID"];
							study.name = [curDict objectForKey: @"patientName"];
							study.patientUID = [curDict objectForKey: @"patientUID"];
							study.id = [curDict objectForKey: @"studyNumber"];
							
							if ([DCMAbstractSyntaxUID isStructuredReport: SOPClassUID] && inParseExistingObject)
							{
								if ([[curDict objectForKey: @"studyDescription"] length])
									study.studyName = [curDict objectForKey: @"studyDescription"];
								if ([[curDict objectForKey: @"referringPhysiciansName"] length])
									study.referringPhysician = [curDict objectForKey: @"referringPhysiciansName"];
								if ([[curDict objectForKey: @"performingPhysiciansName"] length])
									study.performingPhysician = [curDict objectForKey: @"performingPhysiciansName"];
								if ([[curDict objectForKey: @"institutionName"] length])
									study.institutionName = [curDict objectForKey: @"institutionName"];
							}
							else
							{
								study.studyName = [curDict objectForKey: @"studyDescription"];
								study.referringPhysician = [curDict objectForKey: @"referringPhysiciansName"];
								study.performingPhysician = [curDict objectForKey: @"performingPhysiciansName"];
								study.institutionName = [curDict objectForKey: @"institutionName"];
							}
							
							//need to know if is DICOM so only DICOM is queried for Q/R
							if ([curDict objectForKey: @"hasDICOM"])
								study.hasDICOM = [curDict objectForKey: @"hasDICOM"];
							
							if (newObject)
								[self checkForExistingReportForStudy:study];
						}
						else
						{
							if ([[study valueForKey: @"modality"] isEqualToString: @"SR"] || [[study valueForKey: @"modality"] isEqualToString: @"OT"])
								study.modality = [curDict objectForKey: @"modality"];
							
							if ([study valueForKey: @"studyName"] == nil || [[study valueForKey: @"studyName"] isEqualToString: @"unnamed"] || [[study valueForKey: @"studyName"] isEqualToString: @""])
								study.studyName = [curDict objectForKey: @"studyDescription"];
						}
						
						if ([curDict objectForKey: @"studyDate"] && [[curDict objectForKey: @"studyDate"] isEqualToDate: defaultDate] == NO)
						{
							if ([study valueForKey: @"date"] == 0L || [[study valueForKey: @"date"] isEqualToDate: defaultDate] || [[study valueForKey: @"date"] timeIntervalSinceDate: [curDict objectForKey: @"studyDate"]] >= 0)
								[study setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
						}
						
						curStudyID = [curDict objectForKey: @"studyID"];
						curPatientUID = [curDict objectForKey: @"patientUID"];
						
						[modifiedStudiesArray addObject: study];
					}
					
					int NoOfSeries = [[curDict objectForKey: @"numberOfSeries"] intValue];
					for( int i = 0; i < NoOfSeries; i++)
					{
						NSString* SeriesNum = i ? [NSString stringWithFormat:@"%d",i] : @"";
						NSString* curDictSeriesID = [curDict objectForKey:[@"seriesID" stringByAppendingString:SeriesNum]];
						
						if ([curDictSeriesID isEqualToString: curSerieID])
						{
						}
						else
						{
							/********************************************/
							/*********** Find series object *************/
							
							NSArray *seriesArray = [[study valueForKey:@"series"] allObjects];
							
							NSInteger index = [[seriesArray valueForKey:@"seriesInstanceUID"] indexOfObject:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]]];
							if (index == NSNotFound)
							{
								// Fields
								seriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext:self.managedObjectContext];
								[seriesTable setValue:today forKey:@"dateAdded"];
								
								newObject = YES;
							}
							else
							{
								seriesTable = [seriesArray objectAtIndex: index];
								newObject = NO;
							}
							
							if (newObject || inParseExistingObject)
							{
								if ([curDict objectForKey: @"seriesDICOMUID"]) [seriesTable setValue:[curDict objectForKey: @"seriesDICOMUID"] forKey:@"seriesDICOMUID"];
								if ([curDict objectForKey: @"SOPClassUID"]) [seriesTable setValue:[curDict objectForKey: @"SOPClassUID"] forKey:@"seriesSOPClassUID"];
								[seriesTable setValue:[curDict objectForKey: [@"seriesID" stringByAppendingString:SeriesNum]] forKey:@"seriesInstanceUID"];
								[seriesTable setValue:[curDict objectForKey: [@"seriesDescription" stringByAppendingString:SeriesNum]] forKey:@"name"];
								[seriesTable setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
								[seriesTable setValue:[curDict objectForKey: [@"seriesNumber" stringByAppendingString:SeriesNum]] forKey:@"id"];
								[seriesTable setValue:[curDict objectForKey: @"studyDate"] forKey:@"date"];
								[seriesTable setValue:[curDict objectForKey: @"protocolName"] forKey:@"seriesDescription"];
								
								// Relations
								[seriesTable setValue:study forKey:@"study"];
								// If a study has an SC or other non primary image  series. May need to change modality to true modality
								if (([[study valueForKey:@"modality"] isEqualToString:@"OT"]  || [[study valueForKey:@"modality"] isEqualToString:@"SC"])
									&& !([[curDict objectForKey: @"modality"] isEqualToString:@"OT"] || [[curDict objectForKey: @"modality"] isEqualToString:@"SC"]))
									[study setValue:[curDict objectForKey: @"modality"] forKey:@"modality"];
							}
							
							curSerieID = curDictSeriesID;
						}
						
						/*******************************************/
						/*********** Find image object *************/
						
						BOOL local = NO;
						
						if (dataDirPath && [newFile hasPrefix: dataDirPath])
							local = YES;
						
						NSArray	*imagesArray = [[seriesTable valueForKey:@"images"] allObjects];
						int numberOfFrames = [[curDict objectForKey: @"numberOfFrames"] intValue];
						if (numberOfFrames == 0) numberOfFrames = 1;
						
						for( int f = 0 ; f < numberOfFrames; f++)
						{
							NSInteger index = imagesArray.count? [[imagesArray valueForKey:@"sopInstanceUID"] indexOfObject:[curDict objectForKey: [@"SOPUID" stringByAppendingString: SeriesNum]]] : NSNotFound;
							
							if (index != NSNotFound)
							{
								image = [imagesArray objectAtIndex: index];
								
								// Does this image contain a valid image path? If not replace it, with the new one
								if ([[NSFileManager defaultManager] fileExistsAtPath: [DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory:self.dataBaseDirPath]] == YES && inParseExistingObject == NO)
								{
									[addedImagesArray addObject: image];
									
									if (local)	// Delete this file, it's already in the DB folder
									{
										if ([[image valueForKey:@"path"] isEqualToString: [newFile lastPathComponent]] == NO)
											[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
									}
									
									newObject = NO;
								}
								else
								{
									newObject = YES;
									[image clearCompletePathCache];
									
									NSString *imPath = [DicomImage completePathForLocalPath: [image valueForKey:@"path"] directory:self.dataBaseDirPath];
									
									if ([[image valueForKey:@"inDatabaseFolder"] boolValue] && [imPath isEqualToString: newFile] == NO)
									{
										if ([[NSFileManager defaultManager] fileExistsAtPath: imPath])
											[[NSFileManager defaultManager] removeFileAtPath: imPath handler:nil];
									}
								}
							}
							else
							{
								image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:self.managedObjectContext];
								
								newObject = YES;
							}
							
							[completeImagesArray addObject: image];
							
							if (newObject || inParseExistingObject)
							{
								if (DICOMSR == NO)
									[seriesTable setValue:today forKey:@"dateAdded"];
								
								[image setValue: [curDict objectForKey: @"modality"] forKey:@"modality"];
								
								if (numberOfFrames > 1)
								{
									[image setValue: [NSNumber numberWithInt: f] forKey:@"frameID"];
									
									NSString *Modality = [study valueForKey: @"modality"];
									if (combineProjectionSeries && combineProjectionSeriesMode == 0 && ([Modality isEqualToString:@"MG"] || [Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]))
									{
										// *******Combine all CR and DR Modality series in a study into one series
										long imageInstance = [[curDict objectForKey: [ @"imageID" stringByAppendingString: SeriesNum]] intValue];
										imageInstance *= 10000;
										imageInstance += f;
										[image setValue: [NSNumber numberWithLong: imageInstance] forKey:@"instanceNumber"];
									}
									else [image setValue: [NSNumber numberWithInt: f] forKey:@"instanceNumber"];
								}
								else
									[image setValue: [curDict objectForKey: [@"imageID" stringByAppendingString: SeriesNum]] forKey:@"instanceNumber"];
								
								if (local) [image setValue: [newFile lastPathComponent] forKey:@"path"];
								else [image setValue:newFile forKey:@"path"];
								
								[image setValue:[NSNumber numberWithBool: local] forKey:@"inDatabaseFolder"];
								
								[image setValue:[curDict objectForKey: @"studyDate"]  forKey:@"date"];
								
								[image setValue:[curDict objectForKey: [@"SOPUID" stringByAppendingString: SeriesNum]] forKey:@"sopInstanceUID"];
								
                                if( [[curDict objectForKey: @"sliceLocationArray"] count] > f)
									[image setValue: [[curDict objectForKey: @"sliceLocationArray"] objectAtIndex: f] forKey:@"sliceLocation"];
								else
									[image setValue:[curDict objectForKey: @"sliceLocation"] forKey:@"sliceLocation"];
                                
                                if( [[curDict objectForKey: @"imageCommentPerFrame"] count] > f)
									[image setValue: [[curDict objectForKey: @"imageCommentPerFrame"] objectAtIndex: f] forKey:@"comment"];

								[image setValue:[[newFile pathExtension] lowercaseString] forKey:@"extension"];
								[image setValue:[curDict objectForKey: @"fileType"] forKey:@"fileType"];
								
								[image setValue:[curDict objectForKey: @"height"] forKey:@"height"];
								[image setValue:[curDict objectForKey: @"width"] forKey:@"width"];
								[image setValue:[curDict objectForKey: @"numberOfFrames"] forKey:@"numberOfFrames"];
								[image setValue:[NSNumber numberWithBool: mountedVolume] forKey:@"mountedVolume"];
								if (mountedVolume)
									[seriesTable setValue:[NSNumber numberWithBool:mountedVolume] forKey:@"mountedVolume"];
								[image setValue:[curDict objectForKey: @"numberOfSeries"] forKey:@"numberOfSeries"];
								
								if (generatedByOsiriX)
									[image setValue: [NSNumber numberWithBool: generatedByOsiriX] forKey: @"generatedByOsiriX"];
								else
									[image setValue: 0L forKey: @"generatedByOsiriX"];
								
								[seriesTable setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[study setValue:[NSNumber numberWithInt:0]  forKey:@"numberOfImages"];
								[seriesTable setValue: nil forKey:@"thumbnail"];
								
								if (DICOMSR && [curDict objectForKey: @"numberOfROIs"] && [curDict objectForKey: @"referencedSOPInstanceUID"]) // OsiriX ROI SR
								{
									NSString *s = [curDict objectForKey: @"referencedSOPInstanceUID"];
									[image setValue: s forKey:@"comment"];
									[image setValue: [curDict objectForKey: @"numberOfROIs"] forKey:@"scale"];
								}
								
								// Relations
								[image setValue:seriesTable forKey:@"series"];
								
								//									if (isBonjour)
								//									{
								//										if (local)
								//										{
								//											NSString *bonjourPath = [BonjourBrowser uniqueLocalPath: image];
								//											[[NSFileManager defaultManager] removeItemAtPath: bonjourPath error: nil];
								//											[[NSFileManager defaultManager] moveItemAtPath: newFile toPath: bonjourPath error: nil];
								//											[bonjourFilesToSend addObject: bonjourPath];
								//										}
								//										else
								//											[bonjourFilesToSend addObject: newFile];
								//										
								//										NSLog( @"------ AddFiles to a shared Bonjour DB: %@", [newFile lastPathComponent]);
								//									}
								
								if (DICOMSR == NO)
								{
									if (COMMENTSAUTOFILL)
									{
										if([curDict objectForKey: @"commentsAutoFill"])
										{
											[seriesTable setPrimitiveValue: [curDict objectForKey: @"commentsAutoFill"] forKey: @"comment"];
											[study setPrimitiveValue:[curDict objectForKey: @"commentsAutoFill"] forKey: @"comment"];
										}
									}
									
									if (generatedByOsiriX == NO && [(NSString*)[curDict objectForKey: @"seriesComments"] length] > 0)
										[seriesTable setPrimitiveValue: [curDict objectForKey: @"seriesComments"] forKey: @"comment"];
									
									if (generatedByOsiriX == NO && [(NSString*)[curDict objectForKey: @"studyComments"] length] > 0)
										[study setPrimitiveValue: [curDict objectForKey: @"studyComments"] forKey: @"comment"];
									
									if (generatedByOsiriX == NO && [[study valueForKey:@"stateText"] intValue] == 0 && [[curDict objectForKey: @"stateText"] intValue] != 0)
										[study setPrimitiveValue: [curDict objectForKey: @"stateText"] forKey: @"stateText"];
									
									if (generatedByOsiriX == NO && [curDict objectForKey: @"keyFrames"])
									{
										@try
										{
											for( NSString *k in [curDict objectForKey: @"keyFrames"])
											{
												if ([k intValue] == f) // corresponding frame
												{
													[image setPrimitiveValue: [NSNumber numberWithBool: YES] forKey: @"storedIsKeyImage"];
													break;
												}
											}
										}
										@catch (NSException * e) {
                                            N2LogExceptionWithStackTrace(e);
                                        }
									}
								}
								
								if (DICOMSR && [[curDict valueForKey:@"seriesDescription"] isEqualToString: @"OsiriX Report SR"])
								{
									BOOL reportUpToDate = NO;
									NSString *p = [study reportURL];
									
									if (p && [[NSFileManager defaultManager] fileExistsAtPath: p])
									{
										NSDictionary *fattrs = [[NSFileManager defaultManager] attributesOfItemAtPath: p error: nil];
										if ([[curDict objectForKey: @"studyDate"] isEqualToDate: [fattrs objectForKey: NSFileModificationDate]])
											reportUpToDate = YES;
									}
									
									if (reportUpToDate == NO)
									{
										NSString *reportURL = nil; // <- For an empty DICOM SR File
										
										DicomImage *reportSR = [study reportImage];
										
										if (reportSR == image) // Because we can have multiple reports -> only the most recent one is valid
										{
											NSString *reportURL = nil, *reportPath = [DicomDatabase extractReportSR: newFile contentDate: [curDict objectForKey: @"studyDate"]];
											
											if (reportPath)
											{
												if ([reportPath length] > 8 && ([reportPath hasPrefix: @"http://"] || [reportPath hasPrefix: @"https://"]))
												{
													reportURL = reportPath;
												}
												else // It's a file!
												{
													NSString *reportFilePath = nil;
													
													//														if (isBonjour)
													//															reportFilePath = [tempDirPath stringByAppendingPathComponent: [reportPath lastPathComponent]];
													//														else
													reportFilePath = [reportsDirPath stringByAppendingPathComponent: [reportPath lastPathComponent]];
													
													[[NSFileManager defaultManager] removeItemAtPath: reportFilePath error: nil];
													[[NSFileManager defaultManager] moveItemAtPath: reportPath toPath: reportFilePath error: nil];
													
													reportURL = [@"REPORTS/" stringByAppendingPathComponent: [reportPath lastPathComponent]];
												}
												
												NSLog( @"--- DICOM SR -> Report : %@", [curDict valueForKey: @"patientName"]);
											}
											
											if ([reportURL length] > 0)
												[study setPrimitiveValue: reportURL forKey: @"reportURL"];
											else
												[study setPrimitiveValue: 0L forKey: @"reportURL"];
										}
									}
								}
								
								[addedImagesArray addObject: image];
								
//								if(seriesTable && [addedSeries containsObject: seriesTable] == NO)
//									[addedSeries addObject: seriesTable];
								
								if (DICOMSR == NO && [curDict valueForKey:@"album"] !=nil)
								{
									NSArray* albumArray = self.albums;
									
									DicomAlbum* album = NULL;
									for (album in albumArray)
									{
										if ([album.name isEqualToString:[curDict valueForKey:@"album"]])
											break;
									}
									
									if (album == nil)
									{
										//NSString *name = [curDict valueForKey:@"album"];
										//album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: context];
										//[album setValue:name forKey:@"name"];
										
										for (album in albumArray)
										{
											if ([album.name isEqualToString:@"other"])
												break;
										}
										
										if (album == nil)
										{
											album = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: self.managedObjectContext];
											[album setValue:@"other" forKey:@"name"];
											
											//@synchronized( [BrowserController currentBrowser])
											//											{
											//												cachedAlbumsManagedObjectContext = nil;
											//											}
										}
									}
									
									// add the file to the album
									if ( [[album valueForKey:@"smartAlbum"] boolValue] == NO)
									{
										NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];	
										[studies addObject: [image valueForKeyPath:@"series.study"]];
										[[image valueForKeyPath:@"series.study"] archiveAnnotationsAsDICOMSR];
									}
								}
							}
						}
					}
				}
				else
				{
					// This file was not readable -> If it is located in the DATABASE folder, we have to delete it or to move it to the 'NOT READABLE' folder
					if (dataDirPath && [newFile hasPrefix: dataDirPath])
					{
						NSLog(@"**** Unreadable file: %@", newFile);
						
						if ( DELETEFILELISTENER)
						{
							[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
						}
						else
						{
							if ([[NSFileManager defaultManager] movePath: newFile toPath:[errorsDirPath stringByAppendingPathComponent: [newFile lastPathComponent]]  handler:nil] == NO)
								[[NSFileManager defaultManager] removeFileAtPath: newFile handler:nil];
						}
					}
				}
			}
			@catch (NSException* e)
			{
				N2LogExceptionWithStackTrace(e);
			}
		}
		
		[studiesArrayStudyInstanceUID release];
		[studiesArray release];
		
		NSString* growlString = nil;
		NSString* growlStringNewStudy = nil;
		
		@try
		{
			// Compute no of images in studies/series
			for( NSManagedObject *study in modifiedStudiesArray) [study valueForKey:@"noFiles"];
			
			// Reapply annotations from DICOMSR file
			for( DicomStudy *study in modifiedStudiesArray) [study reapplyAnnotationsFromDICOMSR];
			
			//				if (isBonjour && [bonjourFilesToSend count] > 0)
			//				{
			//					if (generatedByOsiriX)
			//						[NSThread detachNewThreadSelector: @selector( sendFilesToCurrentBonjourGeneratedByOsiriXDB:) toTarget: browserController withObject: bonjourFilesToSend];
			//					else 
			//						[NSThread detachNewThreadSelector: @selector( sendFilesToCurrentBonjourDB:) toTarget: browserController withObject: bonjourFilesToSend];
			//				}
			
			
			NSAutoreleasePool* pool = [NSAutoreleasePool new];
			@try {
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:addedImagesArray forKey:OsirixAddToDBNotificationImagesArray];
				NSDictionary* userInfo2 = [NSDictionary dictionaryWithObject:completeImagesArray forKey:OsirixAddToDBCompleteNotificationImagesArray];
                [self performSelectorOnMainThread:@selector(_notify:) withObject:[NSArray arrayWithObjects:_O2AddToDBAnywayNotification, self, userInfo, nil] waitUntilDone:NO];
                [self performSelectorOnMainThread:@selector(_notify:) withObject:[NSArray arrayWithObjects:_O2AddToDBAnywayCompleteNotification, self, userInfo2, nil] waitUntilDone:NO];
				if (postNotifications) {
                    [self performSelectorOnMainThread:@selector(_notify:) withObject:[NSArray arrayWithObjects:OsirixAddToDBNotification, self, userInfo, nil] waitUntilDone:NO];
                    [self performSelectorOnMainThread:@selector(_notify:) withObject:[NSArray arrayWithObjects:OsirixAddToDBCompleteNotification, self, userInfo2, nil] waitUntilDone:NO];
				}
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			} @finally {
				[pool release];
			}
				
			if (postNotifications) {
				if ([addedImagesArray count] > 0) { // && generatedByOsiriX == NO)
					growlString = [NSString stringWithFormat: NSLocalizedString(@"Patient: %@\r%d images added to the database", nil), [[addedImagesArray objectAtIndex:0] valueForKeyPath:@"series.study.name"], [addedImagesArray count]];
					growlStringNewStudy = [NSString stringWithFormat: NSLocalizedString(@"%@\r%@", nil), [[addedImagesArray objectAtIndex:0] valueForKeyPath:@"series.study.name"], [[addedImagesArray objectAtIndex:0] valueForKeyPath:@"series.study.studyName"]];
				}
				
				if (self.isLocal)
					[self applyRoutingRules:nil toImages:addedImagesArray];
			}
			
		}
		@catch( NSException *ne)
		{
            N2LogExceptionWithStackTrace(ne);
		}
		
		BOOL addFailed = NO;
		
		@try {
			[self cleanForFreeSpace];
			
			NSError* err = nil;
			if (![self save:&err]) {
				NSLog( @"***** error saving DB: %@", [[err userInfo] description]);
				NSLog( @"***** saveDatabase ERROR: %@", [err localizedDescription]);
				addFailed = YES;
			}
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		}
		
		if (addFailed == NO) {
			self.timeOfLastModification = [NSDate timeIntervalSinceReferenceDate];
			if (postNotifications) {
				if (growlString)
					[self performSelectorOnMainThread:@selector(_growlImagesAdded:) withObject:growlString waitUntilDone:NO];
				if (newStudy && growlStringNewStudy)
					[self performSelectorOnMainThread:@selector(_growlNewStudy:) withObject:growlStringNewStudy waitUntilDone:NO];
			}
		}
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self unlock];
	}
	
	return addedImagesArray;
}

-(void)_notify:(NSArray*)args {
    [NSNotificationCenter.defaultCenter postNotificationName:[args objectAtIndex:0] object:[args objectAtIndex:1] userInfo:[args objectAtIndex:2]];
}

-(void)copyFilesThread:(NSDictionary*)dict {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	//	[autoroutingInProgress lock];
	
	BOOL first = YES, studySelected = NO, onlyDICOM = [[dict objectForKey: @"onlyDICOM"] boolValue];
	NSArray *filesInput = [dict objectForKey: @"filesInput"];
	
	int total = 0;
	
	for( int i = 0; i < [filesInput count];)
	{
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		
		@try
		{
			NSMutableArray *copiedFiles = [NSMutableArray array];
			
			NSTimeInterval twentySeconds = [NSDate timeIntervalSinceReferenceDate] + 5;
			
			if( [[dict objectForKey: @"mountedVolume"] boolValue] == YES && [[dict objectForKey: @"copyFiles"] boolValue] == NO)
				twentySeconds = [NSDate timeIntervalSinceReferenceDate] + 20.0;
			
			for( ; i < [filesInput count] && twentySeconds > [NSDate timeIntervalSinceReferenceDate]; i++)
			{
				NSString *srcPath = [filesInput objectAtIndex: i], *dstPath = nil;
				
				if( [[dict objectForKey: @"copyFiles"] boolValue])
				{
					NSString *extension = [srcPath pathExtension];
					
					if( [extension isEqualToString:@""])
						extension = [NSString stringWithString:@"dcm"]; 
					
					if( [extension length] > 4 || [extension length] < 3)
						extension = [NSString stringWithString:@"dcm"];
					
					dstPath = [self uniquePathForNewDataFileWithExtension:extension];
					
					NSError* err = nil;
					if( [[NSFileManager defaultManager] copyItemAtPath: srcPath toPath: dstPath error:&err])
					{
						if( [extension isEqualToString: @"dcm"] == NO)
						{
							DicomFile *dcmFile = [[[DicomFile alloc] init: dstPath] autorelease];
							
							if( [[[dcmFile dicomElements] objectForKey: @"fileType"] hasPrefix: @"DICOM"])
							{
								NSString *newPathExtension = [[dstPath stringByDeletingPathExtension] stringByAppendingPathExtension: @"dcm"];
								
								[[NSFileManager defaultManager] moveItemAtPath: dstPath toPath: newPathExtension error: nil];
								
								dstPath = newPathExtension;
							}
						}
						
						[copiedFiles addObject: dstPath];
					}
					else
						NSLog( @"***** copyItemAtPath %@ failed : %@", srcPath, err);
				}
				else
				{
					if( [[NSFileManager defaultManager] fileExistsAtPath: srcPath])
					{
						if( [[dict objectForKey: @"mountedVolume"] boolValue])
						{
							@try
							{
								if( [[[DicomFile alloc] init: srcPath] autorelease]) // Pre-load for CD/DVD in cache
								{
									[copiedFiles addObject: srcPath];
								}
								else NSLog( @"**** DicomFile *curFile = nil");
							}
							@catch (NSException * e) {
                                N2LogExceptionWithStackTrace(e);
                            }
						}
						else
						{
							if( [[NSUserDefaults standardUserDefaults] boolForKey: @"validateFilesBeforeImporting"] && [[dict objectForKey: @"mountedVolume"] boolValue] == NO) // mountedVolume : it's too slow to test the files now from a CD
							{
								// Pre-load for faster validating
								NSData *d = [NSData dataWithContentsOfFile: srcPath];
							}
							[copiedFiles addObject: srcPath];
						}
					}
				}
				
				if( [NSThread currentThread].isCancelled)
					break;
				
				if( i == [filesInput count]-1 || twentySeconds <= [NSDate timeIntervalSinceReferenceDate])
				{
					if( [[NSUserDefaults standardUserDefaults] boolForKey: @"validateFilesBeforeImporting"])
					{
						if( i == [filesInput count]-1)
							[NSThread currentThread].progress = -1;
						
						[NSThread currentThread].status =  NSLocalizedString( @"Validating the files...", nil);
					}
					else
					{
						if( i == [filesInput count]-1)
						{
							[NSThread currentThread].progress = 1;
							[NSThread currentThread].status =  NSLocalizedString( @"Done. Finishing...", nil);
						}
						else
							[NSThread currentThread].status =  NSLocalizedString( @"Indexing the files...", nil);
					}
				}
				else
				{
					[NSThread currentThread].status = [NSString stringWithFormat: @"%d %@ left", [filesInput count]-i, i==1? NSLocalizedString( @"file", nil) : NSLocalizedString( @"files", nil) ];
					[NSThread currentThread].progress = (float) (i+1) / [filesInput count];
				}
			}
			
			BOOL succeed = YES;
			
#ifndef OSIRIX_LIGHT
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"validateFilesBeforeImporting"] && [[dict objectForKey: @"mountedVolume"] boolValue] == NO) // mountedVolume : it's too slow to test the files now from a CD
				succeed = [DicomDatabase testFiles: copiedFiles];
#endif
			
			NSArray *objects = nil;
			
			if( succeed)
			{
				BOOL mountedVolume = [[dict objectForKey: @"mountedVolume"] boolValue];
				
				if( [[dict objectForKey: @"copyFiles"] boolValue])
					mountedVolume = NO;
				
				objects = 	   [BrowserController addFiles: copiedFiles
												toContext: [[BrowserController currentBrowser] managedObjectContext]
											   toDatabase: [BrowserController currentBrowser]
												onlyDICOM: onlyDICOM 
										 notifyAddedFiles: YES
									  parseExistingObject: NO
												 dbFolder: [[BrowserController currentBrowser] documentsDirectory]
										generatedByOsiriX: NO
											mountedVolume: mountedVolume];
				
				total += [copiedFiles count];
			}
			else
			{
				for( NSString * f in copiedFiles)
					[[NSFileManager defaultManager]removeItemAtPath: f error: nil];
			}
			
			if( [objects count])
			{
				if( studySelected == NO)
				{
					if( [[dict objectForKey: @"selectStudy"] boolValue])
						[self performSelectorOnMainThread: @selector( selectThisStudy:) withObject: [[objects objectAtIndex: 0] valueForKeyPath: @"series.study"] waitUntilDone: NO];
					
					studySelected = YES;
				}
				
				BrowserController* bc = [BrowserController currentBrowser];
				if (bc.database == self && bc.albumTable.selectedRow > 0 && [[dict objectForKey:@"addToAlbum"] boolValue])
				{
					NSManagedObject *album = [bc.albumArray objectAtIndex:bc.albumTable.selectedRow];
					
					if ([[album valueForKey:@"smartAlbum"] boolValue] == NO)
					{
						NSMutableSet *studies = [album mutableSetValueForKey: @"studies"];
						
						for( NSManagedObject *object in objects)
						{
							[studies addObject: [object valueForKeyPath:@"series.study"]];
							[[object valueForKeyPath:@"series.study"] archiveAnnotationsAsDICOMSR];
						}
					}
				}
			}
			
			if( [NSThread currentThread].isCancelled)
				break;
		}
		@catch (NSException * e)
		{
            N2LogExceptionWithStackTrace(e);
		}
		
		[pool2 release];
	}
	
	//	[autoroutingInProgress unlock];
	
	if( [[dict objectForKey: @"ejectCDDVD"] boolValue] == YES && [[dict objectForKey: @"copyFiles"] boolValue] == YES)
	{
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EJECTCDDVD"])
			[[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [filesInput objectAtIndex:0]];
	}
	
	[pool release];
}


-(void)_growlImagesAdded:(NSString*)message {
	[AppController.sharedAppController growlTitle:NSLocalizedString(@"Incoming Files", nil) description:message name:@"newfiles"];
}

-(void)_growlNewStudy:(NSString*)message {
	[AppController.sharedAppController growlTitle:NSLocalizedString(@"New Study", nil) description:message name:@"newstudy"];
}

-(NSInteger)importFilesFromIncomingDir {
	NSMutableArray* compressedPathArray = [NSMutableArray array];
	NSThread* thread = [NSThread currentThread];
	BOOL listenerCompressionSettings = [[NSUserDefaults standardUserDefaults] integerForKey: @"ListenerCompressionSettings"];
	NSArray* addedFiles = nil;
	
	[thread enterOperation];
	thread.status = NSLocalizedString(@"Listing files...", nil);
	
	[NSFileManager.defaultManager confirmNoIndexDirectoryAtPath:self.decompressionDirPath];
	
	[_importFilesFromIncomingDirLock lock];
	@try {
		if ([self isFileSystemFreeSizeLimitReached]) {
			[self cleanForFreeSpace];
			if ([self isFileSystemFreeSizeLimitReached]) {
				NSLog(@"WARNING! THE DATABASE DISK IS FULL!!");
				return 0;
			}
		}
		
		NSMutableArray *filesArray = [NSMutableArray array];
#ifdef OSIRIX_LIGHT
		listenerCompressionSettings = 0;
#endif
		
		BOOL twoStepsIndexing = [[NSUserDefaults standardUserDefaults] boolForKey:@"twoStepsIndexing"];
		NSMutableArray* twoStepsIndexingArrayFrom = [NSMutableArray array];
		NSMutableArray* twoStepsIndexingArrayTo = [NSMutableArray array];
		
		[AppController createNoIndexDirectoryIfNecessary:self.dataDirPath];
		
		int maxNumberOfFiles = [[NSUserDefaults standardUserDefaults] integerForKey:@"maxNumberOfFilesForCheckIncoming"];
		if (maxNumberOfFiles < 100) maxNumberOfFiles = 100;
		if (maxNumberOfFiles > 30000) maxNumberOfFiles = 30000;
		
		NSString *pathname;
		NSDirectoryEnumerator *enumer = [NSFileManager.defaultManager enumeratorAtPath:self.incomingDirPath limitTo:-1]; // For next release...
		// NSDirectoryEnumerator *enumer = [NSFileManager.defaultManager enumeratorAtPath:self.incomingDirPath];
		
		[OsiriX setReceivingIcon];
		
		while( (pathname = [enumer nextObject]) && [filesArray count] < maxNumberOfFiles)
		{
			NSString *srcPath = [self.incomingDirPath stringByAppendingPathComponent:pathname];
			NSString *originalPath = srcPath;
			NSString *lastPathComponent = [srcPath lastPathComponent];
			
			if ([[lastPathComponent uppercaseString] hasSuffix:@".DS_STORE"])
			{
				[[NSFileManager defaultManager] removeItemAtPath: srcPath error: nil];
				continue;
			}
			
			if ([[lastPathComponent uppercaseString] hasSuffix:@"__MACOSX"])
			{
				[[NSFileManager defaultManager] removeItemAtPath: srcPath error: nil];
				continue;
			}
			
			if (![ThreadsManager.defaultManager.threads containsObject:thread])
				[ThreadsManager.defaultManager addThreadAndStart:thread];
			
			if ( [lastPathComponent length] > 0 && [lastPathComponent characterAtIndex: 0] == '.')
			{
				NSDictionary *atr = [enumer fileAttributes];// [[NSFileManager defaultManager] attributesOfItemAtPath: srcPath error: nil];
				if ([atr fileModificationDate] && [[atr fileModificationDate] timeIntervalSinceNow] < -60*60*24)
				{
					[NSThread sleepForTimeInterval: 0.1]; //We want to be 100% sure...
					
					atr = [[NSFileManager defaultManager] attributesOfItemAtPath: srcPath error: nil];
					if ([atr fileModificationDate] && [[atr fileModificationDate] timeIntervalSinceNow] < -60*60*24)
					{
						NSLog( @"old files with '.' -> delete it : %@", srcPath);
						if (srcPath)
							[[NSFileManager defaultManager] removeItemAtPath: srcPath error: nil];
					}
				}
				continue;
			}
			
			BOOL isAlias = NO;
			srcPath = [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:srcPath resolved:&isAlias];
			
			// Is it a real file? Is it writable (transfer done)?
			//					if ([[NSFileManager defaultManager] isWritableFileAtPath:srcPath] == YES)	<- Problems with CD : read-only files, but valid files
			{
				NSDictionary *fattrs = [enumer fileAttributes];	//[[NSFileManager defaultManager] fileAttributesAtPath:srcPath traverseLink: YES];
				
				//						// http://www.noodlesoft.com/blog/2007/03/07/mystery-bug-heisenbergs-uncertainty-principle/
				//						[fattrs allKeys];
				
				//						NSLog( @"%@", [fattrs objectForKey:NSFileBusy]);
				
				if ([[fattrs objectForKey:NSFileType] isEqualToString: NSFileTypeDirectory] == YES)
				{
					NSArray		*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath: srcPath];
					
					//Is this directory empty?? If yes, delete it!
					//if alias assume nested folders should stay
					if ([dirContent count] == 0 && !isAlias) [[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
					if ([dirContent count] == 1)
					{
						if ([[[dirContent objectAtIndex: 0] uppercaseString] hasSuffix:@".DS_STORE"])
							[[NSFileManager defaultManager] removeFileAtPath:srcPath handler:nil];
					}
				}
				else if (fattrs != nil && [[fattrs objectForKey:NSFileBusy] boolValue] == NO && [[fattrs objectForKey:NSFileSize] longLongValue] > 0)
				{
					if ([[srcPath pathExtension] isEqualToString: @"zip"] || [[srcPath pathExtension] isEqualToString: @"osirixzip"])
					{
						NSString *compressedPath = [self.decompressionDirPath stringByAppendingPathComponent: lastPathComponent];
						[[NSFileManager defaultManager] movePath:srcPath toPath:compressedPath handler:nil];
						[compressedPathArray addObject: compressedPath];
					}
					else
					{
						BOOL isDicomFile, isJPEGCompressed, isImage;
						NSString *dstPath = [self.dataDirPath stringByAppendingPathComponent: lastPathComponent];
						
						isDicomFile = [DicomFile isDICOMFile:srcPath compressed: &isJPEGCompressed image: &isImage];
						
						if (isDicomFile == YES ||
						   (([DicomFile isFVTiffFile:srcPath] ||
							 [DicomFile isTiffFile:srcPath] ||
							 [DicomFile isNRRDFile:srcPath])
							&& [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == NO))
						{
							if (isDicomFile && isImage) {
								if ((isJPEGCompressed == YES && listenerCompressionSettings == 1) || (isJPEGCompressed == NO && listenerCompressionSettings == 2
#ifndef OSIRIX_LIGHT
																									  && [DicomDatabase fileNeedsDecompression: srcPath]
#else	
#endif
								)) {
									NSString *compressedPath = [self.decompressionDirPath stringByAppendingPathComponent: lastPathComponent];
									
									[[NSFileManager defaultManager] movePath:srcPath toPath:compressedPath handler:nil];
									
									[compressedPathArray addObject: compressedPath];
									
									continue;
								}
								
								dstPath = [self uniquePathForNewDataFileWithExtension:@"dcm"];
							} else dstPath = [self uniquePathForNewDataFileWithExtension:[[srcPath pathExtension] lowercaseString]];
							
							BOOL result;
							
							if (isAlias)
							{
								if (twoStepsIndexing)
								{
									NSString *stepsPath = [self.toBeIndexedDirPath stringByAppendingPathComponent: [dstPath lastPathComponent]];
									
									result = [[NSFileManager defaultManager] copyPath:srcPath toPath: stepsPath handler:nil];
									[[NSFileManager defaultManager] removeFileAtPath:originalPath handler:nil];
									
									if (result)
									{
										[twoStepsIndexingArrayFrom addObject: stepsPath];
										[twoStepsIndexingArrayTo addObject: dstPath];
									}
								}
								else
								{
									result = [[NSFileManager defaultManager] copyPath:srcPath toPath: dstPath handler:nil];
									[[NSFileManager defaultManager] removeFileAtPath:originalPath handler:nil];
								}
							}
							else
							{
								if (twoStepsIndexing)
								{
									NSString *stepsPath = [self.toBeIndexedDirPath stringByAppendingPathComponent: [dstPath lastPathComponent]];
									
									result = [[NSFileManager defaultManager] movePath:srcPath toPath: stepsPath handler:nil];
									
									if (result)
									{
										[twoStepsIndexingArrayFrom addObject: stepsPath];
										[twoStepsIndexingArrayTo addObject: dstPath];
									}
								}
								else
									result = [[NSFileManager defaultManager] movePath:srcPath toPath: dstPath handler:nil];
							}
							
							if (result == YES)
								[filesArray addObject:dstPath];
						}
						else // DELETE or MOVE THIS UNKNOWN FILE ?
						{
							if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DELETEFILELISTENER"])
								[[NSFileManager defaultManager] removeItemAtPath:srcPath error:NULL];
							else {
								if (![NSFileManager.defaultManager moveItemAtPath:srcPath toPath:[self.errorsDirPath stringByAppendingPathComponent:lastPathComponent] error:NULL])
									[NSFileManager.defaultManager removeFileAtPath:srcPath handler:nil];
							}
						}
					}
				}
			}
		}
		
		if (twoStepsIndexing == YES && [twoStepsIndexingArrayFrom count] > 0)
		{
//				[database unlock];
			
			for( int i = 0 ; i < [twoStepsIndexingArrayFrom count] ; i++)
			{
				[[NSFileManager defaultManager] removeItemAtPath: [twoStepsIndexingArrayTo objectAtIndex: i]  error: nil];
				[[NSFileManager defaultManager] moveItemAtPath: [twoStepsIndexingArrayFrom objectAtIndex: i] toPath: [twoStepsIndexingArrayTo objectAtIndex: i] error: nil];
				[[NSFileManager defaultManager] removeItemAtPath: [twoStepsIndexingArrayFrom objectAtIndex: i]  error: nil];
			}
			
//				[database lock];
		}
		
		if ([filesArray count] > 0)
		{
//				if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"ANONYMIZELISTENER"] == YES)
//					[self listenerAnonymizeFiles: filesArray];
			
			if ([[PluginManager preProcessPlugins] count]) {
				thread.status = [NSString stringWithFormat:NSLocalizedString(@"Preprocessing %d files with %d plugins...", nil), filesArray.count, [[PluginManager preProcessPlugins] count]];
				for (id filter in [PluginManager preProcessPlugins])
					@try {
						[filter processFiles: filesArray];
					} @catch (NSException* e) {
						N2LogExceptionWithStackTrace(e);
					}
			}
			
			thread.status = [NSString stringWithFormat:NSLocalizedString(@"Adding %d files...", nil), filesArray.count];
			addedFiles = [[self addFilesAtPaths:filesArray] valueForKey:@"completePath"];
			
			if (!addedFiles) // Add failed.... Keep these files: move them back to the INCOMING folder and try again later....
			{
				NSString *dstPath;
				int x = 0;
				
				NSLog(@"Move the files back to the incoming folder...");
				
				for( NSString *file in filesArray)
				{
					do
					{
						dstPath = [self.incomingDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", x]];
						x++;
					}
					while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
					
					[[NSFileManager defaultManager] movePath: file toPath: dstPath handler: nil];
				}
			}
		}
		
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_importFilesFromIncomingDirLock unlock];
	}
	
#ifndef OSIRIX_LIGHT
	if ([compressedPathArray count] > 0)  {// there are files to compress/decompress in the decompression dir
		thread.status = [NSString stringWithFormat:NSLocalizedString(@"Decompressing %d files...", nil), compressedPathArray.count];
		
		if (listenerCompressionSettings == 1 || listenerCompressionSettings == 0) // decompress, listenerCompressionSettings == 0 for zip support!
			[self decompressFilesAtPaths:compressedPathArray intoDirAtPath:self.incomingDirPath];
		else if (listenerCompressionSettings == 2)	// compress
			[self compressFilesAtPaths:compressedPathArray intoDirAtPath:self.incomingDirPath];
	}
#endif
	
	[OsiriX unsetReceivingIcon];

	[thread exitOperation];
	return addedFiles.count;
}

-(void)importFilesFromIncomingDirThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSThread* thread = [NSThread currentThread];
		thread.name = NSLocalizedString(@"Adding incoming files...", nil);
		NSInteger importCount = [self importFilesFromIncomingDir];
		
		if (self == DicomDatabase.activeLocalDatabase)
			[AppController.sharedAppController performSelectorOnMainThread:@selector(setBadgeLabel:) withObject:(importCount? [[NSNumber numberWithInteger:importCount] stringValue] : nil) waitUntilDone:NO];
		
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[pool release];
	}
}

-(void)initiateImportFilesFromIncomingDirUnlessAlreadyImporting {
	//if ([[AppController sharedAppController] isSessionInactive])
	//	return;
	
	if ([_importFilesFromIncomingDirLock tryLock]) {
		if ([BrowserController isHardDiskFull]) {
			[NSFileManager.defaultManager removeItemAtPath:[self incomingDirPath] error:nil]; // Kill the incoming directory
			[[AppController sharedAppController] growlTitle:NSLocalizedString(@"Warning", nil) description: NSLocalizedString(@"The database volume is full! Incoming files are ignored.", nil) name:@"newfiles"];
		}
		
		@try {
			[self performSelectorInBackground:@selector(importFilesFromIncomingDirThread) withObject:nil]; // TODO: NSOperationQueues pls
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		} @finally {
			[_importFilesFromIncomingDirLock unlock];
		}
	} else
		NSLog(@"Warning: couldn't initiate import of incoming files");
}

+(void)importFilesFromIncomingDirTimerCallback:(NSTimer*)timer {
	for (DicomDatabase* dbi in [self allDatabases])
		if (dbi.isLocal)
			[dbi initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
}

+(void)syncImportFilesFromIncomingDirTimerWithUserDefaults {
	static NSTimer* importFilesFromIncomingDirTimer = nil;
	
	NSInteger newInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"LISTENERCHECKINTERVAL"];
	if (importFilesFromIncomingDirTimer.timeInterval == newInterval)
		return;
	
	[importFilesFromIncomingDirTimer invalidate];
	[importFilesFromIncomingDirTimer release];
	importFilesFromIncomingDirTimer = nil;
	if (newInterval) {
		importFilesFromIncomingDirTimer = [[NSTimer timerWithTimeInterval:newInterval target:self selector:@selector(importFilesFromIncomingDirTimerCallback:) userInfo:nil repeats:YES] retain];
		[[NSRunLoop mainRunLoop] addTimer:importFilesFromIncomingDirTimer forMode:NSModalPanelRunLoopMode];
		[[NSRunLoop mainRunLoop] addTimer:importFilesFromIncomingDirTimer forMode:NSDefaultRunLoopMode];
	}
}

#pragma mark Other

-(BOOL)rebuildAllowed {
	return YES;
}

-(BOOL)upgradeSqlFileFromModelVersion:(NSString*)databaseModelVersion {
	NSString* oldModelFilename = [NSString stringWithFormat:@"OsiriXDB_Previous_DataModel%@.mom", databaseModelVersion];
	if ([databaseModelVersion isEqualToString:CurrentDatabaseVersion]) oldModelFilename = [NSString stringWithFormat:@"OsiriXDB_DataModel.mom"]; // same version 
	
	if (![NSFileManager.defaultManager fileExistsAtPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:oldModelFilename]]) {
		int r = NSRunAlertPanel(NSLocalizedString(@"OsiriX Database", nil), NSLocalizedString(@"OsiriX cannot understand the model of current saved database... The database index will be deleted and reconstructed (no images are lost).", nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Quit", nil), nil);
		if (r == NSAlertAlternateReturn) {
			[NSFileManager.defaultManager removeItemAtPath:self.loadingFilePath error:nil]; // to avoid the crash message during next startup
			[NSApp terminate:self];
		}
		
		[[NSFileManager defaultManager] removeItemAtPath:self.sqlFilePath error:nil];
		
		[self rebuild:YES];
		
		return NO;
	}
	
	NSManagedObjectModel* oldModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:oldModelFilename]]];
	NSPersistentStoreCoordinator* oldPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:oldModel];
	NSManagedObjectContext* oldContext = [[NSManagedObjectContext alloc] init];

	NSManagedObjectModel* newModel = self.managedObjectModel;
	NSPersistentStoreCoordinator* newPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:newModel];
	NSManagedObjectContext* newContext = [[NSManagedObjectContext alloc] init];
	
	@try {
		NSError* err = NULL;
		NSMutableArray* upgradeProblems = [NSMutableArray array];
		
		[oldContext setPersistentStoreCoordinator:oldPersistentStoreCoordinator];
		[oldContext setUndoManager: nil];
		[newContext setPersistentStoreCoordinator:newPersistentStoreCoordinator];
		[newContext setUndoManager: nil];
		
		[NSFileManager.defaultManager removeItemAtPath:[self.baseDirPath stringByAppendingPathComponent:@"Database3.sql"] error:nil];
		[NSFileManager.defaultManager removeItemAtPath:[self.baseDirPath stringByAppendingPathComponent:@"Database3.sql-journal"] error:nil];
		
		if (![oldPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:self.sqlFilePath] options:nil error:&err])
			N2LogError(err.description);
		
		if (![newPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:[self.baseDirPath stringByAppendingPathComponent:@"Database3.sql"]] options:nil error:&err])
			N2LogError(err.description);
		
		NSManagedObject *newStudyTable, *newSeriesTable, *newImageTable, *newAlbumTable;
		NSArray *albumProperties, *studyProperties, *seriesProperties, *imageProperties;
		
		NSArray* albums = [DicomDatabase albumsInContext:oldContext];
		albumProperties = [[[[oldModel entitiesByName] objectForKey:@"Album"] attributesByName] allKeys];
		for (NSManagedObject* oldAlbum in albums)
		{
			newAlbumTable = [NSEntityDescription insertNewObjectForEntityForName:@"Album" inManagedObjectContext: newContext];
			
			for ( NSString *name in albumProperties)
			{
				[newAlbumTable setValue: [oldAlbum valueForKey: name] forKey: name];
			}
		}
		
		[newContext save:nil];
		
		// STUDIES
		NSFetchRequest* dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[oldModel entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		
		NSMutableArray* studies = [NSMutableArray arrayWithArray: [oldContext executeFetchRequest:dbRequest error:nil]];
		
		//[[splash progress] setMaxValue:[studies count]];
		
		int chunk = 0;
		
		studies = [NSMutableArray arrayWithArray: [studies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease]]]];
		if ([studies count] > 100)
		{
			int max = [studies count] - chunk*100;
			if (max > 100) max = 100;
			studies = [NSMutableArray arrayWithArray: [studies subarrayWithRange: NSMakeRange( chunk*100, max)]];
			chunk++;
		}
		[studies retain];
		
		studyProperties = [[[[oldModel entitiesByName] objectForKey:@"Study"] attributesByName] allKeys];
		seriesProperties = [[[[oldModel entitiesByName] objectForKey:@"Series"] attributesByName] allKeys];
		imageProperties = [[[[oldModel entitiesByName] objectForKey:@"Image"] attributesByName] allKeys];
		
		int counter = 0;
		
		NSArray *newAlbums = nil;
		NSArray *newAlbumsNames = nil;
		
		while( [studies count] > 0)
		{
			NSAutoreleasePool	*poolLoop = [[NSAutoreleasePool alloc] init];
			
			
			NSString *studyName = nil;
			
			@try
			{
				NSManagedObject *oldStudy = [studies lastObject];
				
				[studies removeLastObject];
				
				newStudyTable = [NSEntityDescription insertNewObjectForEntityForName:@"Study" inManagedObjectContext: newContext];
				
				for ( NSString *name in studyProperties)
				{
					if ([name isEqualToString: @"isKeyImage"] || 
					   [name isEqualToString: @"comment"] ||
					   [name isEqualToString: @"comment2"] ||
					   [name isEqualToString: @"comment3"] ||
					   [name isEqualToString: @"comment4"] ||
					   [name isEqualToString: @"reportURL"] ||
					   [name isEqualToString: @"stateText"])
					{
						[newStudyTable setPrimitiveValue: [oldStudy primitiveValueForKey: name] forKey: name];
					}
					else [newStudyTable setValue: [oldStudy primitiveValueForKey: name] forKey: name];
					
					if ([name isEqualToString: @"name"])
						studyName = [oldStudy primitiveValueForKey: name];
				}
				
				// SERIES
				NSArray *series = [[oldStudy valueForKey:@"series"] allObjects];
				for( NSManagedObject *oldSeries in series)
				{
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					@try
					{
						newSeriesTable = [NSEntityDescription insertNewObjectForEntityForName:@"Series" inManagedObjectContext: newContext];
						
						for( NSString *name in seriesProperties)
						{
							if ([name isEqualToString: @"xOffset"] || 
							   [name isEqualToString: @"yOffset"] || 
							   [name isEqualToString: @"scale"] || 
							   [name isEqualToString: @"rotationAngle"] || 
							   [name isEqualToString: @"displayStyle"] || 
							   [name isEqualToString: @"windowLevel"] || 
							   [name isEqualToString: @"windowWidth"] || 
							   [name isEqualToString: @"yFlipped"] || 
							   [name isEqualToString: @"xFlipped"])
							{
								
							}
							else if ( [name isEqualToString: @"isKeyImage"] || 
									[name isEqualToString: @"comment"] ||
									[name isEqualToString: @"comment2"] ||
									[name isEqualToString: @"comment3"] ||
									[name isEqualToString: @"comment4"] ||
									[name isEqualToString: @"reportURL"] ||
									[name isEqualToString: @"stateText"])
							{
								[newSeriesTable setPrimitiveValue: [oldSeries primitiveValueForKey: name] forKey: name];
							}
							else [newSeriesTable setValue: [oldSeries primitiveValueForKey: name] forKey: name];
						}
						[newSeriesTable setValue: newStudyTable forKey: @"study"];
						
						// IMAGES
						NSArray *images = [[oldSeries valueForKey:@"images"] allObjects];
						for ( NSManagedObject *oldImage in images)
						{
							@try
							{
								newImageTable = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext: newContext];
								
								for( NSString *name in imageProperties)
								{
									if ([name isEqualToString: @"xOffset"] || 
									   [name isEqualToString: @"yOffset"] || 
									   [name isEqualToString: @"scale"] || 
									   [name isEqualToString: @"rotationAngle"] || 
									   [name isEqualToString: @"windowLevel"] || 
									   [name isEqualToString: @"windowWidth"] || 
									   [name isEqualToString: @"yFlipped"] || 
									   [name isEqualToString: @"xFlipped"])
									{
										
									}
									else if ([name isEqualToString: @"isKeyImage"] || 
											[name isEqualToString: @"comment"] ||
											[name isEqualToString: @"comment2"] ||
											[name isEqualToString: @"comment3"] ||
											[name isEqualToString: @"comment4"] ||
											[name isEqualToString: @"reportURL"] ||
											[name isEqualToString: @"stateText"])
									{
										[newImageTable setPrimitiveValue: [oldImage primitiveValueForKey: name] forKey: name];
									}
									else [newImageTable setValue: [oldImage primitiveValueForKey: name] forKey: name];
								}
								[newImageTable setValue: newSeriesTable forKey: @"series"];
							}
							
							@catch (NSException *e)
							{
								NSLog(@"IMAGE LEVEL: Problems during updating: %@", e);
								[e printStackTrace];
							}
						}
					}
					
					@catch (NSException *e)
					{
						NSLog(@"SERIES LEVEL: Problems during updating: %@", e);
						[e printStackTrace];
					}
					[pool release];
				}
				
				NSArray		*storedInAlbums = [[oldStudy valueForKey: @"albums"] allObjects];
				
				if ([storedInAlbums count])
				{
					if (newAlbums == nil)
					{
						// Find all current albums
						NSFetchRequest *r = [[[NSFetchRequest alloc] init] autorelease];
						[r setEntity: [[newModel entitiesByName] objectForKey:@"Album"]];
						[r setPredicate: [NSPredicate predicateWithValue:YES]];
						
						newAlbums = [newContext executeFetchRequest:r error:NULL];
						newAlbumsNames = [newAlbums valueForKey:@"name"];
						
						[newAlbums retain];
						[newAlbumsNames retain];
					}
					
					@try
					{
						for( NSManagedObject *sa in storedInAlbums)
						{
							NSString *name = [sa valueForKey:@"name"];
							NSMutableSet *studiesStoredInAlbum = [[newAlbums objectAtIndex: [newAlbumsNames indexOfObject: name]] mutableSetValueForKey:@"studies"];
							
							[studiesStoredInAlbum addObject: newStudyTable];
						}
					}
					
					@catch (NSException *e)
					{
						NSLog(@"ALBUM : %@", e);
						[e printStackTrace];
					}
				}
			}
			
			@catch (NSException * e)
			{
				NSLog(@"STUDY LEVEL: Problems during updating: %@", e);
				NSLog(@"Patient Name: %@", studyName);
				[upgradeProblems addObject:studyName];
				
				[e printStackTrace];
			}
			
	//		[splash incrementBy:1];
			counter++;
			
			NSLog(@"%d", counter);
			
			if (counter % 100 == 0)
			{
				[newContext save:nil];
				
				[newContext reset];
				[oldContext reset];
				
				[newAlbums release];			newAlbums = nil;
				[newAlbumsNames release];		newAlbumsNames = nil;
				
				[studies release];
				
				studies = [NSMutableArray arrayWithArray: [oldContext executeFetchRequest:dbRequest error:nil]];
				
			//	[[splash progress] setMaxValue:[studies count]];
				
				studies = [NSMutableArray arrayWithArray: [studies sortedArrayUsingDescriptors: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"patientID" ascending:YES] autorelease]]]];
				if ([studies count] > 100)
				{
					int max = [studies count] - chunk*100;
					if (max>100) max = 100;
					studies = [NSMutableArray arrayWithArray: [studies subarrayWithRange: NSMakeRange( chunk*100, max)]];
					chunk++;
				}
				
				[studies retain];
			}
			
			[poolLoop release];
		}
		
		[newContext save:NULL];
		
		[[NSFileManager defaultManager] removeItemAtPath: [self.baseDirPath stringByAppendingPathComponent:@"Database-Old-PreviousVersion.sql"] error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:self.sqlFilePath toPath:[self.baseDirPath stringByAppendingPathComponent:@"Database-Old-PreviousVersion.sql"] error:NULL];
		[[NSFileManager defaultManager] moveItemAtPath:[self.baseDirPath stringByAppendingPathComponent:@"Database3.sql"] toPath:self.sqlFilePath error:NULL];
		
		[studies release];					studies = nil;
		[newAlbums release];			newAlbums = nil;
		[newAlbumsNames release];		newAlbumsNames = nil;
		
		if (upgradeProblems.count)
			NSRunAlertPanel(NSLocalizedString(@"Database Upgrade", nil), [NSString stringWithFormat:NSLocalizedString(@"The upgrade encountered %d errors. These corrupted studies have been removed: %@", nil), upgradeProblems.count, [upgradeProblems componentsJoinedByString:@", "]], nil, nil, nil);
		
		return YES;
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
		
		NSRunAlertPanel( NSLocalizedString(@"Database Update", nil), NSLocalizedString(@"Database updating failed... The database SQL index file is probably corrupted... The database will be reconstructed.", nil), nil, nil, nil);
		
		[self rebuild:YES];
		
		return NO;
	} @finally {
		[oldContext reset];
		[oldContext release];
		[oldPersistentStoreCoordinator release];
		[oldModel release];
		
		[newContext reset];
		[newContext release];
		[newPersistentStoreCoordinator release];
		[newModel release];
	}
	
	return NO;
}



- (void)recomputePatientUIDs { // TODO: this is SLOW -> show advancement
	NSLog(@"In %s", __PRETTY_FUNCTION__);
	
	// Find all studies
	NSFetchRequest* dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: self.studyEntity];
	[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
	
	[self.managedObjectContext lock];
	@try {
		NSArray* studiesArray = [self.managedObjectContext executeFetchRequest:dbRequest error:nil];
		for (DicomStudy* study in studiesArray) {
			@try {
				DicomImage* o = [[[[study valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
				DicomFile* dcm = [[DicomFile alloc] init:o.completePath];
				if (dcm && [dcm elementForKey:@"patientUID"])
					study.patientUID = [dcm elementForKey:@"patientUID"];
				[dcm release];
			} @catch (NSException* e) {
				N2LogExceptionWithStackTrace(e);
			}
		}
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self.managedObjectContext unlock];
	}
}

-(void)rebuild {
	[self rebuild:NO];
}

-(void)rebuild:(BOOL)complete {
	NSThread* thread = [NSThread currentThread];
	
//	[self waitForRunningProcesses];
	
	[NSNotificationCenter.defaultCenter postNotificationName:OsirixDatabaseObjectsMayBecomeUnavailableNotification object:self userInfo:nil];
	//[[AppController sharedAppController] closeAllViewers: self];

	[_importFilesFromIncomingDirLock lock];
	
	if (complete) {	// Delete the database file
		self.managedObjectContext = nil;
		if ([NSFileManager.defaultManager fileExistsAtPath:self.sqlFilePath]) {
			[NSFileManager.defaultManager removeItemAtPath:[self.sqlFilePath stringByAppendingString:@" - old"] error:NULL];
			[NSFileManager.defaultManager moveItemAtPath:self.sqlFilePath toPath:[self.sqlFilePath stringByAppendingString:@" - old"] error:NULL];
		}
		self.managedObjectContext = [self contextAtPath:self.sqlFilePath];
	} else [self save:NULL];
	
	[self lock];
	@try {
		thread.status = NSLocalizedString(@"Scanning database directory...", nil);
		
		NSMutableArray *filesArray = [[NSMutableArray alloc] initWithCapacity: 10000];
		
		// SCAN THE DATABASE FOLDER, TO BE SURE WE HAVE EVERYTHING!
		
		NSString	*aPath = [self dataDirPath];
		NSString	*incomingPath = [self incomingDirPath];
		long		totalFiles = 0;
		
		// In the DATABASE FOLDER, we have only folders! Move all files that are wrongly there to the INCOMING folder.... and then scan these folders containing the DICOM files
		
		NSArray	*dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
		for( NSString *dir in dirContent)
		{
			NSString * itemPath = [aPath stringByAppendingPathComponent: dir];
			id fileType = [[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey:NSFileType];
			if ([fileType isEqual:NSFileTypeRegular])
			{
				[[NSFileManager defaultManager] movePath:itemPath toPath:[incomingPath stringByAppendingPathComponent: [itemPath lastPathComponent]] handler: nil];
			}
			else totalFiles += [[[[NSFileManager defaultManager] fileAttributesAtPath: itemPath traverseLink: YES] objectForKey: NSFileReferenceCount] intValue];
		}
		
		dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:aPath];
		
		NSLog( @"Start Rebuild");
		
		for( NSString *name in dirContent)
		{
			NSAutoreleasePool		*pool = [[NSAutoreleasePool alloc] init];
			
			NSString	*curDir = [aPath stringByAppendingPathComponent: name];
			NSArray		*subDir = [[NSFileManager defaultManager] directoryContentsAtPath: [aPath stringByAppendingPathComponent: name]];
			
			for( NSString *subName in subDir)
			{
				if ([subName characterAtIndex: 0] != '.')
					[filesArray addObject: [curDir stringByAppendingPathComponent: subName]];
			}
			
			[pool release];
		}
		
		// ** DICOM ROI SR FOLDER
		dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:self.roisDirPath];
		for (NSString *name in dirContent)
			if ([name characterAtIndex:0] != '.')
				[filesArray addObject: [self.roisDirPath stringByAppendingPathComponent: name]];
	
	
		// ** Finish the rebuild
		thread.status = [NSString stringWithFormat:NSLocalizedString(@"Adding %d files...", nil), filesArray.count];
		[self addFilesAtPaths:filesArray postNotifications:NO];
		
		NSLog(@"End Rebuild");
		
		[filesArray release];
		
		NSFetchRequest	*dbRequest;
		NSError			*error = nil;
		
		if (!complete) {
			thread.status = NSLocalizedString(@"Checking for missing files...", nil);
			
			// remove non-available images
			for (DicomImage* aFile in [self objectsForEntity:self.imageEntity]) {
				FILE* fp = fopen(aFile.completePath.UTF8String, "r");
				if (fp)
					fclose( fp);
				else [self.managedObjectContext deleteObject:aFile];
			}
			
			// remove empty studies
			thread.status = NSLocalizedString(@"Checking for empty studies...", nil);
			for (DicomStudy* study in [self objectsForEntity:self.studyEntity]) {
				[self checkForExistingReportForStudy:study];
				if (study.series.count == 0 || study.noFiles.intValue == 0)
					[self.managedObjectContext deleteObject: study];
			}
		}
		
		[self save:NULL];
		
		thread.status = NSLocalizedString(@"Checking reports consistency...", nil);
		[self checkReportsConsistencyWithDICOMSR];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_importFilesFromIncomingDirLock unlock];
		[self unlock];
	}
}

-(void)checkReportsConsistencyWithDICOMSR {
	// Find all studies with reportURL
	[self.managedObjectContext lock];
	
	@try {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"reportURL != NIL"];
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		dbRequest.entity = [self.managedObjectModel.entitiesByName objectForKey:@"Study"];
		dbRequest.predicate = predicate;
		
		NSError	*error = nil;
		NSArray *studiesArray = [self.managedObjectContext executeFetchRequest:dbRequest error:&error];
		
		for (DicomStudy *s in studiesArray)
			[s archiveReportAsDICOMSR];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self.managedObjectContext unlock];
	}
}

-(void)checkForExistingReportForStudy:(DicomStudy*)study {
#ifndef OSIRIX_LIGHT
	@try { // is there a report?
		NSArray* filenames = [NSArray arrayWithObjects: [Reports getUniqueFilename:study], [Reports getOldUniqueFilename:study], NULL];
		NSArray* extensions = [NSArray arrayWithObjects: @"pages", @"odt", @"doc", @"rtf", NULL];
		for (NSString* filename in filenames)
			for (NSString* extension in extensions) {
				NSString* reportPath = [self.reportsDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", filename, extension]];
				if ([NSFileManager.defaultManager fileExistsAtPath:reportPath]) {
					study.reportURL = reportPath;
					return;
				}
			}
	} @catch ( NSException *e) {
		N2LogExceptionWithStackTrace(e);
	}
#endif
}

-(void)dumpSqlFile {
	//WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString(@"Dumping SQL Index file...", nil)]; // TODO: status
	//[splash showWindow:self];
	
	@try {
		NSString* repairedDBFile = [self.sqlFilePath stringByAppendingPathExtension:@"dump"];
		
		[NSFileManager.defaultManager removeItemAtPath:repairedDBFile error:nil];
		[NSFileManager.defaultManager createFileAtPath:repairedDBFile contents:[NSData data] attributes:nil];
		
		NSTask* theTask = [[NSTask alloc] init];
		[theTask setLaunchPath: @"/usr/bin/sqlite3"];
		[theTask setStandardOutput:[NSFileHandle fileHandleForWritingAtPath:repairedDBFile]];
		[theTask setArguments:[NSArray arrayWithObjects: self.sqlFilePath, @".dump", nil]];
		
		[theTask launch];
		[theTask waitUntilExit];
		int dumpStatus = [theTask terminationStatus];
		[theTask release];
		
		if (dumpStatus == 0) {
			NSString* repairedDBFinalFile = [repairedDBFile stringByAppendingPathExtension: @"sql"];
			[NSFileManager.defaultManager removeItemAtPath:repairedDBFinalFile error:nil];
			
			theTask = [[NSTask alloc] init];
			[theTask setLaunchPath:@"/usr/bin/sqlite3"];
			[theTask setStandardInput:[NSFileHandle fileHandleForReadingAtPath:repairedDBFile]];
			[theTask setArguments:[NSArray arrayWithObjects: repairedDBFinalFile, nil]];		
			
			[theTask launch];
			[theTask waitUntilExit];
			
			if ([theTask terminationStatus] == 0) {
				NSInteger tag = 0;
				[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:self.sqlFilePath.stringByDeletingLastPathComponent destination:nil files:[NSArray arrayWithObject:self.sqlFilePath.lastPathComponent] tag:&tag];
				[NSFileManager.defaultManager moveItemAtPath:repairedDBFinalFile toPath:self.sqlFilePath error:nil];
			}
			
			[theTask release];
		}
	
		[[NSFileManager defaultManager] removeItemAtPath: repairedDBFile error: nil];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
	
//	[splash close];
//	[splash release];
}

-(void)rebuildSqlFile {
	[_importFilesFromIncomingDirLock lock];
	
	[self save:NULL];
	self.managedObjectContext = nil;
	
	[self dumpSqlFile];
	[self upgradeSqlFileFromModelVersion:CurrentDatabaseVersion];
	
	self.managedObjectContext = [self contextAtPath:self.sqlFilePath];
	
	[self checkReportsConsistencyWithDICOMSR];
	
	[_importFilesFromIncomingDirLock unlock];
}

-(void)reduceCoreDataFootPrint {
	NSLog(@"In %s", __PRETTY_FUNCTION__);
	
	if ([self tryLock])
		@try {
			NSError *err = nil;
			[self save:&err];
			if (!err)
				[self.managedObjectContext reset];
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		} @finally {
			[self unlock];
		}
}

-(void)checkForHtmlTemplates {
	// directory
	NSString* htmlTemplatesDirectory = [self htmlTemplatesDirPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlTemplatesDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlTemplatesDirectory attributes:nil];
	
	// HTML templates
	NSString *templateFile;
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportPatientsTemplate.html"];
//	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QTExportPatientsTemplate.html"] toPath:templateFile handler:nil];
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"];
//	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"] toPath:templateFile handler:nil];
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportSeriesTemplate.html"];
//	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QTExportSeriesTemplate.html"] toPath:templateFile handler:nil];
	
	// HTML-extra directory
	NSString *htmlExtraDirectory = [htmlTemplatesDirectory stringByAppendingPathComponent:@"html-extra/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlExtraDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlExtraDirectory attributes:nil];
	
	// CSS file
	NSString *cssFile = [htmlExtraDirectory stringByAppendingPathComponent:@"style.css"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:cssFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"QTExportStyle.css"] toPath:cssFile handler:nil];
	
}

@end
