/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

//7/5/05 Finxed bug in dicomTime. Changed comparison to first component rather than whole string. LP

#import "DCMCalendarDate.h"
#import "DCM.h"

@implementation DCMCalendarDate


+ (id)dicomDate:(NSString *)string{
	if ([string rangeOfString:@"-"].location == NSNotFound){
		//format for DA is YYMMDD = @"%Y%m%d"
		if (DEBUG)
			NSLog (@"date string: %@ intValue: %d", string,[string intValue] );
		NSString *format = @"%Y%m%d";
		if (string && [string intValue]) {
			if ([string length] == 10)
				format = @"%Y.%m.%d";
			else if ([string length] == 8)
				format = @"%Y%m%d";
			else if ([string length] == 6)
				format = @"%Y%m";
			else if ([string length] == 4)
				format = @"%Y";
			DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithString:string  calendarFormat:format] autorelease];

			[date setMicroseconds:0];
			[date setIsQuery:NO];
			[date setQueryString:nil];
			return date;
		}
		else
			return nil;
	}
	else
		return [DCMCalendarDate queryDate:string];
}
+ (id)dicomTime:(NSString *)string{
	if ([string rangeOfString:@"-"].location == NSNotFound){
		//format for TM is HHMMSS.ffffff = @"%H%M%S.%U";"
		// %U is our code for microseconds
			if (DEBUG)
			NSLog (@"time string: %@", string);
		if (string  && [string intValue]) {
			NSArray *timeComponents = [string componentsSeparatedByString:@"."];
			NSString *firstComponent = [timeComponents objectAtIndex:0];
			NSString *format = @"%H%M%S";
			if ([firstComponent length] == 8)
				format = @"%H:%M:%S";
			if ([firstComponent length] == 6)
				format = @"%H%M%S";
			else if ([firstComponent length] == 4)
				format = @"%H%M";
			else if ([firstComponent length] == 2)
				format = @"%H";
			DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithString:firstComponent calendarFormat:format] autorelease];
			int useconds = 0;
			if ([timeComponents count] > 1) {
				useconds = [[timeComponents objectAtIndex:1] intValue] * pow(10, 6 - [(NSString *)[timeComponents objectAtIndex:1] length]);
			}
			[date setMicroseconds:useconds];
			[date setIsQuery:NO];
			[date setQueryString:nil];
			return date;
		}
		else
			return nil;
	}
	else
		return [DCMCalendarDate queryDate:string];
}
+ (id)dicomDateTime:(NSString *)string{
	if ([string rangeOfString:@"-"].location == NSNotFound){
		//format for DT is HHMMSS.ffffff = @"@"%H%M%S.%U";"
		// %U is our code for microseconds
			if (DEBUG)
			NSLog (@"date time string: %@", string);
		if (string && [string intValue]) {
			NSArray *timeComponents = [string componentsSeparatedByString:@"."];
			NSString *format;
			int length = [string length];
			format = @"%Y%m%d%H%M%S";
			switch ([(NSString *)[timeComponents objectAtIndex:0] length]) {
				case 14:format = @"%Y%m%d%H%M%S";
					break;
				case 12:format = @"%Y%m%d%H%M";
					break;
				case 10:format = @"%Y%m%d%H";
					break;
				case 8:format = @"%Y%m%d";
					break;
				case 6:format = @"%Y%m";
					break;
				case 4:format = @"%Y";
					break;
				default: format = @"%Y%m%d%H%M%S";
					
			}
				/*
				else if (length == 18)
					format = @"%Y%m%d%H%M%S.%F";
				else
					format = @"%Y%m%d%H%M%S.%F%z";
				*/
			DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithString:[timeComponents objectAtIndex:0] calendarFormat:format] autorelease];
			int useconds = 0;
			if ([timeComponents count] > 1) {
				NSString *fraction;
				NSString *timeZone;
				if (length > 6) {
					fraction = [[timeComponents objectAtIndex:0] substringToIndex:5];
					timeZone = [[timeComponents objectAtIndex:0] substringFromIndex:6];
					int tzHours = [[timeZone substringToIndex:2] intValue];
					int tzMinutes = [[timeZone substringFromIndex:3] intValue];
					if (tzHours < 0)
						tzMinutes = -tzMinutes;
					NSTimeZone *tz = [NSTimeZone timeZoneForSecondsFromGMT:(tzHours * 3600) + (tzMinutes * 60)];
					[date setTimeZone:tz];
				}
				else 
					fraction = [timeComponents objectAtIndex:0];
				useconds = [fraction intValue] * pow(10, 6 - [(NSString *)[timeComponents objectAtIndex:0] length]);
			}
			[date setMicroseconds:useconds];
			[date setIsQuery:NO];
			[date setQueryString:nil];
			return date;
		}
		else
			return nil;
	}
	else
		return [DCMCalendarDate queryDate:string];
		
}

+ (id)dicomDateWithDate:(NSDate *)date{
	NSString *format = @"%Y%m%d";
	NSCalendarDate  *cDate= [date dateWithCalendarFormat:format timeZone:nil];
	NSString *dateString = [cDate descriptionWithCalendarFormat:format];
	return [DCMCalendarDate dicomDate:dateString];
}
	
+ (id)dicomTimeWithDate:(NSDate *)date{
	NSString *format = @"%H%M%S";
	//NSLog(@"time for date: %@", [date description]);
	NSCalendarDate  *cDate= [date dateWithCalendarFormat:format timeZone:nil];
	NSString *dateString = [cDate descriptionWithCalendarFormat:format];
	return [DCMCalendarDate dicomTime:dateString];
}
	
+ (id)queryDate:(NSString *)query{
	DCMCalendarDate *date = [[[DCMCalendarDate alloc] init] autorelease];
	[date setIsQuery:YES];
	[date setQueryString:query];
	return date;
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (id)copyWithZone:(NSZone *)zone{
	DCMCalendarDate *date = [super copyWithZone:zone];
	[date setMicroseconds:microseconds];
	return date;
}

- (NSString *)dateString{
	if (isQuery)
		return queryString;
	NSString *format = @"%Y%m%d";
	return [self descriptionWithCalendarFormat:format];
}

- (NSString *)timeString{
	if (isQuery)
		return queryString;
	NSString *format = @"%H%M%S";
	NSString *time =  [self descriptionWithCalendarFormat:format];
	return [NSString stringWithFormat:@"%@.%0000006d", time, microseconds];
}

- (NSString *)dateTimeString:(BOOL)withTimeZone{
	if (isQuery)
		return queryString;
	NSString *format = @"%Y%m%d%H%M%S";
	NSString *time =  [self descriptionWithCalendarFormat:format];
	if (!withTimeZone)
		return time;
	else {
		NSString *tz = [self descriptionWithCalendarFormat:@"%z"];
		return [NSString stringWithFormat:@"%@.%0000006d%@", time, microseconds,tz];
	}
}

- (NSNumber *)dateAsNumber{
	return [NSNumber numberWithInt:[[self dateString] intValue]];
}
- (NSNumber *)timeAsNumber{
	return [NSNumber numberWithInt:[[self timeString] floatValue]];
}

- (void)setMicroseconds:(int)useconds{
	microseconds = useconds;
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (BOOL)isQuery{
	return isQuery;
}

- (NSString *)queryString{
	return queryString;
}

- (void)dealloc{
	[queryString release];
	[super dealloc];
}

- (void)setIsQuery:(BOOL)query{
	isQuery = query;
}
- (void)setQueryString:(NSString *)query{
	[queryString release];
	queryString = [query retain];
	//NSLog(@"Date query: %@", queryString);
}

- (NSString *)description{
	if (isQuery)
		return queryString;
	return [super description];
}

- (DCMCalendarDate *)dateWithYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second timeZone:(NSTimeZone *)aTimeZone{ 
	return [DCMCalendarDate dicomDateWithDate:[self dateWithYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second timeZone:(NSTimeZone *)aTimeZone]];
}

@end
