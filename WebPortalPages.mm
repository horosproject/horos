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

#import "WebPortalPages.h"
#import "DicomAlbum.h"
#import "WebPortalUser.h"


@implementation WebPortalPages

@end


@implementation ArrayTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSArray*)object {
	if ([key isEqual:@"count"])
		return [NSNumber numberWithUnsignedInt:object.count];
	return NULL;
}

@end


@implementation DateTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(NSDate*)object {
	if ([key isEqual:@"Months"]) {
		static NSArray* monthNames = [[NSArray alloc] initWithObjects: NSLocalizedString(@"January", @"Month"), NSLocalizedString(@"February", @"Month"), NSLocalizedString(@"March", @"Month"), NSLocalizedString(@"April", @"Month"), NSLocalizedString(@"May", @"Month"), NSLocalizedString(@"June", @"Month"), NSLocalizedString(@"July", @"Month"), NSLocalizedString(@"August", @"Month"), NSLocalizedString(@"September", @"Month"), NSLocalizedString(@"October", @"Month"), NSLocalizedString(@"November", @"Month"), NSLocalizedString(@"December", @"Month"), NULL];
		NSMutableArray* months = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:-1], @"value", NSLocalizedString(@"Month", @"Month"), @"name", [NSNumber numberWithBool:YES], @"selected", [NSNumber numberWithBool:YES], @"disabled", NULL]];
		for (NSUInteger i = 0; i < 12; ++i)
			[months addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [monthNames objectAtIndex:i], @"name", [NSNumber numberWithBool: [calDate monthOfYear] == i+1 ], @"selected", NULL]];
		return months;
	}
	
	if ([key isEqual:@"Days"]) {
		NSMutableArray* days = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		if (!object)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0], @"value", NSLocalizedString(@"Day", @"Day"), @"name", [NSNumber numberWithBool:YES], @"selected", [NSNumber numberWithBool:YES], @"disabled", NULL]];
		for (NSUInteger i = 0; i < 31; ++i)
			[days addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i+1], @"value", [NSNumber numberWithInt:i+1], @"name", [NSNumber numberWithBool: [calDate dayOfMonth] == i+1 ], @"selected", NULL]];
		return days;
	}
	
	const NSUInteger NextYears = 5;
	if ([key isEqual:@"NextYears"]) {
		NSMutableArray* years = [NSMutableArray array];
		NSCalendarDate* calDate = object? [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:object.timeIntervalSinceReferenceDate] : NULL;
		NSCalendarDate* currDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[NSDate timeIntervalSinceReferenceDate]];
		if ([calDate yearOfCommonEra] < [currDate yearOfCommonEra])
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", [NSNumber numberWithBool:YES], @"selected", NULL]];
		for (NSUInteger i = [currDate yearOfCommonEra]; i < [currDate yearOfCommonEra]+NextYears; ++i)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:i], @"value", [NSNumber numberWithInt:i], @"name", [NSNumber numberWithBool: [calDate yearOfCommonEra] == i ], @"selected", NULL]];
		if ([calDate yearOfCommonEra] >= [currDate yearOfCommonEra]+NextYears)
			[years addObject:[NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"value", [NSNumber numberWithInt:[calDate yearOfCommonEra]], @"name", [NSNumber numberWithBool:YES], @"selected", NULL]];
		return years;
	}
	
	return NULL;
}

@end


@implementation AlbumTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(DicomAlbum*)object {
	if ([key isEqual:@"type"])
		return object.smartAlbum.boolValue? @"SmartAlbum" : @"Album";
	return NULL;
}

@end


@implementation UserTransformer

+(id)create {
	return [[[self alloc] init] autorelease];
}

-(id)valueForKey:(NSString*)key object:(WebPortalUser*)object {
	if ([key isEqual:@"originalName"])
		return object.name;
	return NULL;
}

@end
