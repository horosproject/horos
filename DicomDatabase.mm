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
#import "Reports.h"
#import "AppController.h"


#import "BrowserController.h"


#define CurrentDatabaseVersion @"2.5"


@interface DicomDatabase ()

@property(readwrite,retain) NSString* basePath;
@property(readwrite,retain) NSString* dataBasePath;
@property(readwrite,retain) N2MutableUInteger* dataFileIndex;

+(NSString*)sqlFilePathForBasePath:(NSString*)basePath;
-(void)modifyDefaultAlbums;
-(void)recomputePatientUIDs;
-(BOOL)upgradeSqlFileFromModelVersion:(NSString*)databaseModelVersion;

@end

@implementation DicomDatabase

static const NSString* const SqlFileName = @"Database.sql";

+(NSString*)basePathForPath:(NSString*)path {
	if ([path hasSuffix:[SqlFileName pathExtension]])
		path = [path stringByDeletingLastPathComponent];
	return path;
}

+(NSString*)basePathForMode:(int)mode path:(NSString*)path {
	switch (mode) {
		case 0:
			path = [NSFileManager.defaultManager findSystemFolderOfType:kDocumentsFolderType forDomain:kOnAppropriateDisk];
			break;
		case 1:
			break;
		default:
			path = nil;
			break;
	}
	
	path = [path stringByAppendingPathComponent:@"OsiriX Data"];
	if (!path)
		N2LogError(@"nil path");
	else {
		[NSFileManager.defaultManager confirmDirectoryAtPath:path];
		[NSFileManager.defaultManager confirmDirectoryAtPath:[path stringByAppendingPathComponent:@"REPORTS"]]; // TODO: why? not here...
	}
	
	return path;
}

+(NSString*)defaultBasePath {
	NSString* path = nil;
	@try {
		path = [self basePathForMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"] path:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]];
		if (!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {	// STILL NOT AVAILABLE?? Use the default folder.. and reset this strange URL..
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DATABASELOCATION"];
			[[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"DEFAULT_DATABASELOCATION"];
			path = [self basePathForMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"DATABASELOCATION"] path:[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"]];
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
			defaultDatabase = [[self databaseAtPath:[self defaultBasePath]] retain];
	}
	
	return defaultDatabase;
}

static NSMutableDictionary* databasesDictionary = nil;

+(void)knowAbout:(DicomDatabase*)db {
	@synchronized(self) {
		if (!databasesDictionary)
			databasesDictionary = [[NSMutableDictionary alloc] init];
	}
	
	if (db)
		@synchronized(databasesDictionary) {
			if (![[databasesDictionary allValues] containsObject:db])
				[databasesDictionary setObject:db forKey:db.basePath];
		}
}

+(DicomDatabase*)databaseAtPath:(NSString*)path {
	path = [self basePathForPath:path];
	
	@synchronized(databasesDictionary) {
		DicomDatabase* database = [databasesDictionary objectForKey:path];
		if (database) return database;
		return [[[self alloc] initWithPath:[self sqlFilePathForBasePath:path]] autorelease];
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
					// we must return a valid DicomDatabase with the right context
					return [[DicomDatabase alloc] initWithPath:dbi.basePath context:c];
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
	if (ldb != self.activeLocalDatabase) {
		[activeLocalDatabase release];
		activeLocalDatabase = [ldb retain];
		[NSNotificationCenter.defaultCenter postNotificationName:OsirixActiveLocalDatabaseDidChangeNotification object:nil];
	}
}

#pragma mark Instance

@synthesize basePath = _basePath, dataBasePath = _dataBasePath, dataFileIndex = _dataFileIndex;

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"OsiriXDB_DataModel.momd"]]];
    return managedObjectModel;
}

-(id)initWithPath:(NSString*)p context:(NSManagedObjectContext*)c { // reminder: context may be nil (assigned in -[N2ManagedDatabase initWithPath:] after calling this method)
	p = [DicomDatabase basePathForPath:p];
	p = [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:p];
	[NSFileManager.defaultManager confirmDirectoryAtPath:p];
	
	NSString* sqlFilePath = [DicomDatabase sqlFilePathForBasePath:p];
	BOOL isNewFile = ![NSFileManager.defaultManager fileExistsAtPath:sqlFilePath];
	
	// init and register
	
	self = [super initWithPath:sqlFilePath context:c];
	
	self.basePath = p;
	_dataBasePath = [NSString stringWithContentsOfFile:[p stringByAppendingPathComponent:@"DBFOLDER_LOCATION"] encoding:NSUTF8StringEncoding error:NULL];
	if (!_dataBasePath) _dataBasePath = p;
	[_dataBasePath retain];
	
	[DicomDatabase knowAbout:self];
	
	// post-init
	
	[NSFileManager.defaultManager removeItemAtPath:self.loadingFilePath error:nil];
	
	_dataFileIndex = [[N2MutableUInteger alloc] initWithValue:0];
	
	// create dirs if necessary
	
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.dataDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.incomingDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.tempDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.reportsDirPath];
	[NSFileManager.defaultManager confirmDirectoryAtPath:self.dumpDirPath];
	
	// if a TOBEINDEXED dir exists, move it into INCOMING so we will import the data
	
	if ([NSFileManager.defaultManager fileExistsAtPath:self.toBeIndexedDirPath])
		[NSFileManager.defaultManager moveItemAtPath:self.toBeIndexedDirPath toPath:[self.incomingDirPath stringByAppendingPathComponent:@"TOBEINDEXED.noindex"] error:NULL];
	
	// report templates
	
	for (NSString* rfn in [NSArray arrayWithObjects: @"ReportTemplate.doc", @"ReportTemplate.rtf", @"ReportTemplate.odt", nil]) {
		NSString* rfp = [self.basePath stringByAppendingPathComponent:rfn];
		if (![NSFileManager.defaultManager fileExistsAtPath:rfp])
			[NSFileManager.defaultManager copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:rfn] toPath:rfp error:NULL];
	}
	
	NSString* pagesTemplatesDirPath = [self.basePath stringByAppendingPathComponent:@"PAGES TEMPLATES"];
	if (![NSFileManager.defaultManager fileExistsAtPath:pagesTemplatesDirPath])
		[NSFileManager.defaultManager createSymbolicLinkAtPath:pagesTemplatesDirPath withDestinationPath:[AppController checkForPagesTemplate] error:NULL];
	
	[self checkForHtmlTemplates];
	
	// ...
	
	if (isNewFile)
		[self addDefaultAlbums];
	[self modifyDefaultAlbums];	
	
	return self;
}

-(void)dealloc {
	self.dataFileIndex = nil;
	self.dataBasePath = nil;
	self.basePath = nil;
	[super dealloc];
}

-(BOOL)isLocal {
	return YES;
}

-(NSString*)name {
	return [NSString stringWithFormat:NSLocalizedString(@"Local Database (%@)", nil), self.basePath];
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

-(void)save:(NSError **)err {
	// TODO: BrowserController did this...
//	if ([[AppController sharedAppController] isSessionInactive]) {
//		NSLog(@"---- Session is not active : db will not be saved");
//		return;
//	}
	
	[self lock];
	@try {
		[super save:err];
		[NSUserDefaults.standardUserDefaults setObject:CurrentDatabaseVersion forKey:@"DATABASEVERSION"];
		[CurrentDatabaseVersion writeToFile:self.modelVersionFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self unlock];
	}
}

const NSString* const DicomDatabaseImageEntityName = @"Image";
const NSString* const DicomDatabaseSeriesEntityName = @"Series";
const NSString* const DicomDatabaseStudyEntityName = @"Study";
const NSString* const DicomDatabaseAlbumEntityName = @"Album";
const NSString* const DicomDatabaseLogEntryEntityName = @"LogEntry";

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

/*-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	NSLog(@"******* DO NOT CALL THIS FUNCTION - NOT FINISHED / BUGGED : %s", __PRETTY_FUNCTION__); // TODO: once BrowserController / DicomDatabase doubles are solved, REMOVE THIS METHOD as it is defined in N2ManagedDatabase
	[NSException raise:NSGenericException format:@"DicomDatabase NOT READY for complete usage (contextAtPath:)"];
	return nil;
}*/

+(NSString*)sqlFilePathForBasePath:(NSString*)basePath {
	return [basePath stringByAppendingPathComponent:SqlFileName];
}

-(NSString*)sqlFilePath {
	return [DicomDatabase sqlFilePathForBasePath:self.basePath];
}

-(NSString*)dataDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"DATABASE.noindex"]];
}

-(NSString*)incomingDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"INCOMING.noindex"]];
}

-(NSString*)decompressionDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"DECOMPRESSION.noindex"]];
}

-(NSString*)toBeIndexedDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"TOBEINDEXED.noindex"]];
}

-(NSString*)tempDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"TEMP.noindex"]];
}

-(NSString*)dumpDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"DUMP"]];
}

-(NSString*)errorsDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"NOT READABLE"]];
}

-(NSString*)reportsDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"REPORTS"]];
}

-(NSString*)pagesDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"PAGES"]];
}

-(NSString*)roisDirPath {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"ROIs"]];
}

-(NSString*)htmlTemplatesDir {
	return [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[self.dataBasePath stringByAppendingPathComponent:@"ROIs"]];
}

-(NSString*)modelVersionFilePath {
	return [self.basePath stringByAppendingPathComponent:@"DB_VERSION"];
}

-(NSString*)loadingFilePath {
	return [self.basePath stringByAppendingPathComponent:@"Loading"];
}

-(NSUInteger)computeDataFileIndex {
	DLog(@"In -[DicomDatabase computeDataFileIndex] for %@ initially %lld", self.sqlFilePath, _dataFileIndex.value);
	
	@synchronized(_dataFileIndex) {
		@try {
			NSString* path = self.dataDirPath;
			NSString* temp = [NSFileManager.defaultManager destinationOfSymbolicLinkAtPath:path error:nil];
			if (temp) path = temp;

			// delete empty dirs and scan for files with number names // TODO: this is too slow for NAS systems
			for (NSString* f in [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil]) {
				NSString* fpath = [path stringByAppendingPathComponent:f];
				NSDictionary* fattr = [NSFileManager.defaultManager fileAttributesAtPath:fpath traverseLink:YES];
				
				// check if this folder is empty, and delete it if necessary
				if ([[fattr objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory] && [[fattr objectForKey:NSFileReferenceCount] intValue] < 4) {
					int numberOfValidFiles = 0;
					
					for (NSString* s in [NSFileManager.defaultManager contentsOfDirectoryAtPath:fpath error:nil])
						if ([[s stringByDeletingPathExtension] integerValue] > 0)
							numberOfValidFiles++;
					
					if (!numberOfValidFiles)
						[NSFileManager.defaultManager removeItemAtPath:fpath error:nil];
					else {
						NSUInteger fi = [f integerValue];
						if (fi > _dataFileIndex.value)
							_dataFileIndex.value = fi;
					}
				}
			}
			
			// scan directories
			
			if (_dataFileIndex.value > 0) {
				NSInteger t = _dataFileIndex.value;
				t -= [BrowserController DefaultFolderSizeForDB];
				if (t < 0) t = 0;
				
				NSArray* paths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", _dataFileIndex.value]] error:nil];
				for (NSString* s in paths) {
					long si = [[s stringByDeletingPathExtension] integerValue];
					if (si > t)
						t = si;
				}
				
				_dataFileIndex.value = t+1;
			}
			
			DLog(@"   -[DicomDatabase computeDataFileIndex] for %@ computed %lld", self.sqlFilePath, _dataFileIndex.value);
		} @catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		}
	}
	
	return _dataFileIndex.value;
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
		[NSFileManager.defaultManager confirmNoIndexDirectoryAtPath:dataDirPath]; // TODO: old impl only did this every 3 secs..
		
		[_dataFileIndex increment];
		long long defaultFolderSizeForDB = [BrowserController DefaultFolderSizeForDB]; // TODO: hmm..
		
		BOOL fileExists = NO, firstExists = YES;
		do {
			long long subFolderInt = defaultFolderSizeForDB*(_dataFileIndex.value/defaultFolderSizeForDB+1);
			NSString* subFolderPath = [dataDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld", subFolderInt]];
			[NSFileManager.defaultManager confirmDirectoryAtPath:subFolderPath];
			
			path = [subFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld.%@", _dataFileIndex.value, ext]];
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
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:DicomDatabaseAlbumEntityName inManagedObjectContext:context];
	req.predicate = [NSPredicate predicateWithValue:YES];
	return [context executeFetchRequest:req error:NULL];
}

-(NSArray*)albums { // TODO: cache!
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
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval:-60*60]],			@"$LASTHOUR",
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval:-60*60*6]],			@"$LAST6HOURS",
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval:-60*60*12]],		@"$LAST12HOURS",
						 [NSString stringWithFormat:@"\"%@\"", start],									@"$TODAY",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24]],		@"$YESTERDAY",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*2]],	@"$2DAYS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*7]],	@"$WEEK",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*31]],	@"$MONTH",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*31*2]],	@"$2MONTHS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*31*3]],	@"$3MONTHS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval:-60*60*24*365]],	@"$YEAR",
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
			if ([predicate isKindOfClass:NSString.class]) {
				album.predicateString = predicate;
				album.smartAlbum = [NSNumber numberWithBool:YES];
			}
		}
	}
	
	[self save:nil];
	
	// TODO: refreshAlbums
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

#pragma mark Other

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
		
		[NSFileManager.defaultManager removeItemAtPath:[self.basePath stringByAppendingPathComponent:@"Database3.sql"] error:nil];
		[NSFileManager.defaultManager removeItemAtPath:[self.basePath stringByAppendingPathComponent:@"Database3.sql-journal"] error:nil];
		
		if (![oldPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:self.sqlFilePath] options:nil error:&err])
			N2LogError(err.description);
		
		if (![newPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:[self.basePath stringByAppendingPathComponent:@"Database3.sql"]] options:nil error:&err])
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
		if( [studies count] > 100)
		{
			int max = [studies count] - chunk*100;
			if( max > 100) max = 100;
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
					if( [name isEqualToString: @"isKeyImage"] || 
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
					
					if( [name isEqualToString: @"name"])
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
							if( [name isEqualToString: @"xOffset"] || 
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
							else if(  [name isEqualToString: @"isKeyImage"] || 
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
									if( [name isEqualToString: @"xOffset"] || 
									   [name isEqualToString: @"yOffset"] || 
									   [name isEqualToString: @"scale"] || 
									   [name isEqualToString: @"rotationAngle"] || 
									   [name isEqualToString: @"windowLevel"] || 
									   [name isEqualToString: @"windowWidth"] || 
									   [name isEqualToString: @"yFlipped"] || 
									   [name isEqualToString: @"xFlipped"])
									{
										
									}
									else if( [name isEqualToString: @"isKeyImage"] || 
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
				
				if( [storedInAlbums count])
				{
					if( newAlbums == nil)
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
			
			if( counter % 100 == 0)
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
				if( [studies count] > 100)
				{
					int max = [studies count] - chunk*100;
					if( max>100) max = 100;
					studies = [NSMutableArray arrayWithArray: [studies subarrayWithRange: NSMakeRange( chunk*100, max)]];
					chunk++;
				}
				
				[studies retain];
			}
			
			[poolLoop release];
		}
		
		[newContext save:NULL];
		
		[[NSFileManager defaultManager] removeItemAtPath: [[self basePath] stringByAppendingPathComponent:@"Database-Old-PreviousVersion.sql"] error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:self.sqlFilePath toPath:[[self basePath] stringByAppendingPathComponent:@"Database-Old-PreviousVersion.sql"] error:NULL];
		[[NSFileManager defaultManager] moveItemAtPath:[[self basePath] stringByAppendingPathComponent:@"Database3.sql"] toPath:self.sqlFilePath error:NULL];
		
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
	
//	if (isCurrentDatabaseBonjour) return;
	
//	[self waitForRunningProcesses];
	
	//[[AppController sharedAppController] closeAllViewers: self];
	
	if (complete) {	// Delete the database file
		if ([NSFileManager.defaultManager fileExistsAtPath:self.sqlFilePath]) {
			[NSFileManager.defaultManager removeItemAtPath:[self.sqlFilePath stringByAppendingString:@" - old"] error:NULL];
			[NSFileManager.defaultManager moveItemAtPath:self.sqlFilePath toPath:[self.sqlFilePath stringByAppendingString:@" - old"] error:NULL];
		}
	} else [self save:NULL];
	
//	displayEmptyDatabase = YES;
//	[self outlineViewRefresh];
//	[self refreshMatrix: self];
	
	[self lock];
	
//	[managedObjectContext lock];
//	[managedObjectContext unlock];
//	[managedObjectContext release];
//	managedObjectContext = nil;
	
//	[databaseOutline reloadData];
	
//	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Step 1: Checking files...", nil)];
//	[wait showWindow:self];
	
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
			if( [subName characterAtIndex: 0] != '.')
				[filesArray addObject: [curDir stringByAppendingPathComponent: subName]];
		}
		
		[pool release];
	}
	
	// ** DICOM ROI SR FOLDER
	dirContent = [[NSFileManager defaultManager] directoryContentsAtPath:self.roisDirPath];
	for (NSString *name in dirContent)
		if ([name characterAtIndex:0] != '.')
			[filesArray addObject: [self.roisDirPath stringByAppendingPathComponent: name]];
	
	NSManagedObjectContext *context = self.managedObjectContext;
	NSManagedObjectModel *model = self.managedObjectModel;
	
	[self.managedObjectContext lock];
	@try
	{
		// ** Finish the rebuild
		[[[BrowserController currentBrowser] addFilesToDatabase: filesArray onlyDICOM:NO produceAddedFiles:NO] valueForKey:@"completePath"]; // TODO: AAAARGH
		
		NSLog( @"End Rebuild");
		
		[filesArray release];
		
	//	Wait  *splash = [[Wait alloc] initWithString: NSLocalizedString(@"Step 3: Cleaning Database...", nil)];
		
	//	[splash showWindow:self];
		
		NSFetchRequest	*dbRequest;
		NSError			*error = nil;
		
		if( !complete == NO)
		{
			// FIND ALL images, and REMOVE non-available images
			
			NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
			[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
			[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
			error = nil;
			NSArray *imagesArray = [context executeFetchRequest:dbRequest error:&error];
			
		//	[[splash progress] setMaxValue:[imagesArray count]/50];
			
			// Find unavailable files
			int counter = 0;
			for( NSManagedObject *aFile in imagesArray)
			{
				
				FILE *fp = fopen( [[aFile valueForKey:@"completePath"] UTF8String], "r");
				if( fp)
				{
					fclose( fp);
				}
				else
					[context deleteObject: aFile];
				
				counter++;//if( counter++ % 50 == 0) [splash incrementBy:1];
			}
		}
		
		dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Study"]];
		[dbRequest setPredicate: [NSPredicate predicateWithValue:YES]];
		error = nil;
		NSArray* studiesArray = [context executeFetchRequest:dbRequest error:&error];
		NSString* basePath = self.reportsDirPath;
		
		if ([studiesArray count] > 0)
		{
			for( NSManagedObject *study in studiesArray)
			{
				BOOL deleted = NO;
				
				[self checkForExistingReportForStudy:study];
				
				if( [[study valueForKey:@"series"] count] == 0)
				{
					deleted = YES;
					[context deleteObject: study];
				}
				
				if( [[study valueForKey:@"noFiles"] intValue] == 0)
				{
					if( deleted == NO) [context deleteObject: study];
				}
			}
		}
		
		[self save:NULL];
		
	//	[splash close];
	//	[splash release];
		
	//	displayEmptyDatabase = NO;
		
		[self checkReportsConsistencyWithDICOMSR];
		
//		[self outlineViewRefresh];
	}
	@catch( NSException *e)
	{
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self.managedObjectContext unlock];
	}
	[context unlock];
	[context release];
	
	
}

-(void)checkReportsConsistencyWithDICOMSR {
	// Find all studies with reportURL
	[self.managedObjectContext lock];
	
	@try 
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:  @"reportURL != NIL"];
		NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
		dbRequest.entity = [self.managedObjectModel.entitiesByName objectForKey:@"Study"];
		dbRequest.predicate = predicate;
		
		NSError	*error = nil;
		NSArray *studiesArray = [self.managedObjectContext executeFetchRequest:dbRequest error:&error];
		
		for (DicomStudy *s in studiesArray)
			[s archiveReportAsDICOMSR];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[self.managedObjectContext unlock];
	}
}

- (void)checkForExistingReportForStudy:(NSManagedObject*)study {
#ifndef OSIRIX_LIGHT
	@try
	{
		// Is there a report?
		NSString	*reportsBasePath = self.reportsDirPath;
		NSString	*reportPath = nil;
		
		// TODO: use FOREACH loop...`
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.pages",[Reports getUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.odt",[Reports getUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.doc",[Reports getUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.rtf",[Reports getUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.pages",[Reports getOldUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.rtf",[Reports getOldUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
		
		if( reportPath == nil)
		{
			reportPath = [reportsBasePath stringByAppendingFormat:@"%@.doc",[Reports getOldUniqueFilename: study]];
			if( [[NSFileManager defaultManager] fileExistsAtPath: reportPath])
				[study setValue:reportPath forKey:@"reportURL"];
			else reportPath = nil;
		}
	}
	@catch ( NSException *e)
	{
		N2LogExceptionWithStackTrace(e);
	}
#endif
}

-(void)dumpSqlFile {
	//WaitRendering *splash = [[WaitRendering alloc] init:NSLocalizedString(@"Dumping SQL Index file...", nil)]; // TODO: status
	//[splash showWindow:self];
	
	@try {
		NSString* repairedDBFile = [self.basePath stringByAppendingPathComponent:@"Repaired.txt"];
		
		[NSFileManager.defaultManager removeItemAtPath:repairedDBFile error:nil];
		[NSFileManager.defaultManager createFileAtPath:repairedDBFile contents:[NSData data] attributes:nil];
		
		NSTask* theTask = [[NSTask alloc] init];
		[theTask setLaunchPath: @"/usr/bin/sqlite3"];
		[theTask setStandardOutput:[NSFileHandle fileHandleForWritingAtPath:repairedDBFile]];
		[theTask setCurrentDirectoryPath:self.basePath.stringByDeletingLastPathComponent];
		[theTask setArguments:[NSArray arrayWithObjects:SqlFileName, @".dump", nil]];
		
		[theTask launch];
		[theTask waitUntilExit];
		int dumpStatus = [theTask terminationStatus];
		[theTask release];
		
		if (dumpStatus == 0) {
			NSString* repairedDBFinalFile = [self.basePath stringByAppendingPathComponent: @"RepairedFinal.sql"];
			[NSFileManager.defaultManager removeItemAtPath:repairedDBFinalFile error:nil];

			theTask = [[NSTask alloc] init];
			[theTask setLaunchPath:@"/usr/bin/sqlite3"];
			[theTask setStandardInput:[NSFileHandle fileHandleForReadingAtPath:repairedDBFile]];
			[theTask setCurrentDirectoryPath:self.basePath.stringByDeletingLastPathComponent];
			[theTask setArguments:[NSArray arrayWithObjects: @"RepairedFinal.sql", nil]];		
			
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
//	[checkIncomingLock lock];
	
	[self save:NULL];
	[self dumpSqlFile];
	[self upgradeSqlFileFromModelVersion:CurrentDatabaseVersion];
	[self checkReportsConsistencyWithDICOMSR];
	
//	[checkIncomingLock unlock];
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
	NSString *htmlTemplatesDirectory = [self htmlTemplatesDirectory];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlTemplatesDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlTemplatesDirectory attributes:nil];
	
	// HTML templates
	NSString *templateFile;
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportPatientsTemplate.html"];
	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportPatientsTemplate.html"] toPath:templateFile handler:nil];
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportStudiesTemplate.html"];
	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStudiesTemplate.html"] toPath:templateFile handler:nil];
	
	templateFile = [htmlTemplatesDirectory stringByAppendingPathComponent:@"QTExportSeriesTemplate.html"];
	NSLog( @"%@", templateFile);
	if ([[NSFileManager defaultManager] fileExistsAtPath:templateFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportSeriesTemplate.html"] toPath:templateFile handler:nil];
	
	// HTML-extra directory
	NSString *htmlExtraDirectory = [htmlTemplatesDirectory stringByAppendingPathComponent:@"html-extra/"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:htmlExtraDirectory] == NO)
		[[NSFileManager defaultManager] createDirectoryAtPath:htmlExtraDirectory attributes:nil];
	
	// CSS file
	NSString *cssFile = [htmlExtraDirectory stringByAppendingPathComponent:@"style.css"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:cssFile] == NO)
		[[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/QTExportStyle.css"] toPath:cssFile handler:nil];
	
}

@end
