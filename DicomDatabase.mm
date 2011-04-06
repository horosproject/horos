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


#import "BrowserController.h"


#define DATABASEVERSION @"2.5"


@interface DicomDatabase ()

-(void)modifyDefaultAlbums;

@end

@implementation DicomDatabase

+(NSString*)defaultDatabaseBasePath {
	
}

#pragma Factory

static DicomDatabase* defaultDatabase = nil;

+(DicomDatabase*)defaultDatabase {
	@synchronized(self) {
		if (!defaultDatabase)
			defaultDatabase = [[self localDatabaseAtPath:[self defaultDatabaseBasePath]] retain];
	}
	
	return defaultDatabase;
}

static NSMutableDictionary* localDatabasesDictionary = nil;

+(DicomDatabase*)localDatabaseAtPath:(NSString*)path {
	DicomDatabase* database = nil;
	
	@synchronized(self) {
		if (!localDatabasesDictionary)
			localDatabasesDictionary = [[NSMutableDictionary alloc] init];
		
		database = [localDatabasesDictionary objectForKey:path];
		if (database) return database;
		
		database = [[[self alloc] initWithPath:path] autorelease];
		[localDatabasesDictionary setObject:database forKey:path];
	}
	
	return database;
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

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"OsiriXDB_DataModel.momd"]]];
    return managedObjectModel;
}

-(id)initWithPath:(NSString*)p {
	self = [super initWithPath:p];
	dataFileIndex = [[N2MutableUInteger alloc] initWithValue:0];
	return p;
}

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	BOOL isNewFile = ![NSFileManager.defaultManager fileExistsAtPath:sqlFilePath];

	NSManagedObjectContext* context = [super contextAtPath:sqlFilePath];
	
	if (isNewFile)
		[self addDefaultAlbums];
	[self modifyDefaultAlbums];
	
	return context;
}

-(void)dealloc {
	[dataFileIndex release]; dataFileIndex = nil;
	[super dealloc];
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

-(NSString*)sqlFilePath {
	return [self.basePath stringByAppendingPathComponent:@"Database.sql"];
}

-(NSString*)dataDirPath {
	return [self.basePath stringByAppendingPathComponent:@"DATABASE.noindex"];
}

-(NSString*)decompressionDirPath {
	return [self.basePath stringByAppendingPathComponent:@"DECOMPRESSION.noindex"];
}

-(NSString*)toBeIndexedDirPath {
	return [self.basePath stringByAppendingPathComponent:@"TOBEINDEXED.noindex"];
}

-(NSString*)errorsDirPath {
	return [self.basePath stringByAppendingPathComponent:@"NOT READABLE"];
}

-(NSString*)reportsDirPath {
	return [self.basePath stringByAppendingPathComponent:@"REPORTS"];
}

-(NSString*)tempDirPath {
	return [self.basePath stringByAppendingPathComponent:@"TEMP.noindex"];
}

-(NSString*)uniquePathForNewDataFileWithExtension:(NSString*)ext {
	NSString* path = nil;
	
	if (ext.length > 4 || ext.length < 3) {
		if (ext.length)
			NSLog(@"Warning: strange extension \"%@\", it will be replaced with \"dcm\"", ext);
		ext = @"dcm"; 
	}

	@synchronized(dataFileIndex) {
		NSString* dataDirPath = self.dataDirPath;
		[NSFileManager.defaultManager confirmNoIndexDirectoryAtPath:dataDirPath]; // TODO: old impl only did this every 3 secs..
		
		[dataFileIndex increment];
		
		
		
	}

	return path;
}


{
	
	NSString *dstPath = nil;
	
	// This function can be called in multiple threads -> we want to be sure to have a UNIQUE file path
	@synchronized( self)
	{
		NSString *OUTpath = [dbFolder stringByAppendingPathComponent:DATABASEPATH], *subFolder;
		
		
		
		
		long long defaultFolderSizeDB = [BrowserController DefaultFolderSizeForDB];
		
		do
		{
			long long subFolderInt = [BrowserController DefaultFolderSizeForDB] * ((databaseIndex / defaultFolderSizeDB) +1);
			subFolder = [OUTpath stringByAppendingPathComponent: [NSString stringWithFormat:@"%lld", subFolderInt]];
			
			if( ![[NSFileManager defaultManager] fileExistsAtPath:subFolder])
				[[NSFileManager defaultManager] createDirectoryAtPath:subFolder attributes:nil];
			
			dstPath = [subFolder stringByAppendingPathComponent: [NSString stringWithFormat:@"%lld.%@", databaseIndex, extension]];
			
			fileExist = [[NSFileManager defaultManager] fileExistsAtPath: dstPath];
			
			if( fileExist == YES && firstExist == YES)
			{
				firstExist = NO;
				databaseIndex = [BrowserController computeDATABASEINDEXforDatabase: OUTpath] + 1;
			}
			else
				databaseIndex++;
		}
		while( fileExist == YES);
		
		[databaseIndexDictionary setObject: [NSNumber numberWithLongLong: databaseIndex] forKey: [dbFolder stringByAppendingPathComponent: DATABASEPATH]];
	}
	
	return dstPath;
	
}

#pragma mark Albums

+(NSArray*)albumsInContext:(NSManagedObjectContext*)context {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:DicomDatabaseAlbumEntityName inManagedObjectContext:context];
	req.predicate = [NSPredicate predicateWithValue:YES];
	return [context executeFetchRequest:req error:NULL];	
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
		NSLog(@"Exception in %s: %@", __PRETTY_FUNCTION__, e);
		[e printStackTrace];
	}
}

@end
