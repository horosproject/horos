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


#import "BrowserController.h"


@implementation DicomDatabase

+(DicomDatabase*)defaultDatabase {
	static DicomDatabase* database = NULL;
	@synchronized(self) {
		if (!database) // TODO: the next line MUST CHANGE and BrowserController MUST DISAPPEAR
			database = [[self alloc] initWithPath:[[BrowserController currentBrowser] documentsDirectory] context:[[BrowserController currentBrowser] defaultManagerObjectContext]];
	}
	return database;
}

-(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"OsiriXDB_DataModel.momd"]]];
    return managedObjectModel;
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


-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath {
	NSLog(@"******* DO NOT CALL THIS FUNCTION - NOT FINISHED / BUGGED : %s", __PRETTY_FUNCTION__); // TODO: once BrowserController / DicomDatabase doubles are solved, REMOVE THIS METHOD as it is defined in N2ManagedDatabase
	[NSException raise:NSGenericException format:@"DicomDatabase NOT READY for complete usage (contextAtPath:)"];
	return nil;
}

-(NSString*)sqlFilePath {
	return [self.basePath stringByAppendingPathComponent:@"Database.sql"];
}

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
						 [now addTimeInterval: -60*60*1],			@"LASTHOUR",
						 [now addTimeInterval: -60*60*6],			@"LAST6HOURS",
						 [now addTimeInterval: -60*60*12],			@"LAST12HOURS",
						 start,										@"TODAY",
						 [start addTimeInterval: -60*60*24],		@"YESTERDAY",
						 [start addTimeInterval: -60*60*24*2],		@"2DAYS",
						 [start addTimeInterval: -60*60*24*7],		@"WEEK",
						 [start addTimeInterval: -60*60*24*31],		@"MONTH",
						 [start addTimeInterval: -60*60*24*31*2],	@"2MONTHS",
						 [start addTimeInterval: -60*60*24*31*3],	@"3MONTHS",
						 [start addTimeInterval: -60*60*24*365],	@"YEAR",
						 nil];
	
	return [[NSPredicate predicateWithFormat:pred] predicateWithSubstitutionVariables: sub];
}





@end
