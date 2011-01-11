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


@interface DicomDatabase ()

@property(readwrite, retain) NSManagedObjectContext* managedObjectContext;

@end


@implementation DicomDatabase

@synthesize managedObjectContext;

+(NSManagedObjectModel*)managedObjectModel {
	static NSManagedObjectModel* managedObjectModel = NULL;
	
	if (!managedObjectModel)
		managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"OsiriXDB_DataModel.momd"]]];
    
    return managedObjectModel;
}

-(id)initWithContext:(NSManagedObjectContext*)context {
	self = [super init];
	self.managedObjectContext = context;
	return self;
}

-(void)dealloc {
	self.managedObjectContext = NULL;
	[super dealloc];
}

-(void)save:(NSError**)err {
	[managedObjectContext lock];
	@try {
		NSError* perr = NULL;
		NSError** rerr = err? err : &perr;
		[managedObjectContext save:rerr];
		if (!err && perr) NSLog(@"Error: [DicomDatabase save:] %@", perr.description);
	} @catch(NSException* e) {
		if (!err)
			NSLog(@"Exception: [DicomDatabase save:] %@", e.description);
		else *err = [NSError errorWithDomain:@"Exception" code:-1 userInfo:[NSDictionary dictionaryWithObject:e forKey:@"Exception"]];
	} @finally {
		[managedObjectContext unlock];
	}
}

-(NSEntityDescription*)entityForName:(NSString*)name {
	return [NSEntityDescription entityForName:name inManagedObjectContext:self.managedObjectContext];
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
