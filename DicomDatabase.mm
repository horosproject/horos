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

-(NSString*)sqlFilePath {
	return [self.basePath stringByAppendingPathComponent:@"Database.sql"];
}

+(NSArray*)albumsInContext:(NSManagedObjectContext*)context {
	NSFetchRequest* req = [[[NSFetchRequest alloc] init] autorelease];
	req.entity = [NSEntityDescription entityForName:@"Album" inManagedObjectContext:context];
	req.predicate = [NSPredicate predicateWithValue:YES];
	return [context executeFetchRequest:req error:NULL];	
}

-(NSArray*)albums {
	[self.managedObjectContext lock];
	@try {
		NSArray* albums = [DicomDatabase albumsInContext:self.managedObjectContext];
		
		NSSortDescriptor* sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];

		return [albums sortedArrayUsingDescriptors:[NSArray arrayWithObject: sd]];
	} @catch (NSException* e) {
		NSLog(@"Exception: [DicomDatabase albums] %@", e);
	} @finally {
		[self.managedObjectContext unlock];
	}
	
	return NULL;
}

+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string {
	if (!string.length)
		return [NSPredicate predicateWithValue:YES];
	
	NSMutableString* pred = [NSMutableString stringWithString: string];
	
	// DATES
	NSCalendarDate* now = [NSCalendarDate calendarDate];
	NSCalendarDate* start = [NSCalendarDate dateWithYear:[now yearOfCommonEra] month:[now monthOfYear] day:[now dayOfMonth] hour:0 minute:0 second:0 timeZone: [now timeZone]];
	NSDictionary* sub = [NSDictionary dictionaryWithObjectsAndKeys:
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*1] ],			@"$LASTHOUR",
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*6] ],			@"$LAST6HOURS",
						 [NSString stringWithFormat:@"\"%@\"", [now addTimeInterval: -60*60*12] ],			@"$LAST12HOURS",
						 [NSString stringWithFormat:@"\"%@\"", start ],										@"$TODAY",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24] ],		@"$YESTERDAY",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*2] ],		@"$2DAYS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*7] ],		@"$WEEK",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31] ],		@"$MONTH",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31*2] ],	@"$2MONTHS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*31*3] ],	@"$3MONTHS",
						 [NSString stringWithFormat:@"\"%@\"", [start addTimeInterval: -60*60*24*365] ],	@"$YEAR",
						 nil];
	
	for (NSString* key in sub)
		[pred replaceOccurrencesOfString:key withString:[sub valueForKey:key] options:NSCaseInsensitiveSearch range:pred.range];
	
	return [NSPredicate predicateWithFormat:pred];
}





@end
