/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "DCMCalendarDate.h"//aTimeZone
#import "DCM.h"

@implementation DCMCalendarDate


+ (id)dicomDate:(NSString *)string{

	if( string == nil) 
		return nil;
		
	if ([string rangeOfString:@"-"].location == NSNotFound)
	{
		//format for DA is YYMMDD = @"%Y%m%d"
		if (DCMDEBUG)
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
+ (id)dicomTime:(NSString *)string
{
	if( string == nil) 
		return nil;
		
	if ([string rangeOfString:@"-"].location == NSNotFound)
	{
		//format for TM is HHMMSS.ffffff = @"%H%M%S.%U";
			if (DCMDEBUG)
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
            
            int useconds = 0;
			if ([timeComponents count] > 1)
				useconds = [[timeComponents objectAtIndex:1] intValue] * pow(10, 6 - [(NSString *)[timeComponents objectAtIndex:1] length]);
            
			DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithString:firstComponent calendarFormat:format microseconds: useconds] autorelease];
			
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

+ (id)dicomDateTime:(NSString *)string
{
	if( string == nil) 
		return nil;
    
    if (DCMDEBUG)
        NSLog (@"date time string: %@", string);
    
    if (string.length) {
        NSArray *timeComponents = [string componentsSeparatedByString:@"."];
        NSString *format = nil;
//        int length = (int)[string length];
        
        if( timeComponents.count > 2)
            NSLog( @"****** DICOM DateTime invalid format: %@", string);
        
        switch ([(NSString *)[timeComponents objectAtIndex:0] length]) {
            case 19:format = @"%Y%m%d%H%M%S%z";
                break;
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
                NSLog( @"****** DICOM DateTime invalid format ? %@", string);
                break;
        }
        
        NSTimeZone *tz = nil;
        int useconds = 0;
        if ([timeComponents count] > 1) {
            NSString *timeZone = nil;
            NSString *usecondsString = nil;
            
            if( [[timeComponents objectAtIndex:1] rangeOfString: @"+"].location != NSNotFound)
            {
                usecondsString = [[timeComponents objectAtIndex:1] substringToIndex: [[timeComponents objectAtIndex:1] rangeOfString: @"+"].location];
                timeZone = [[timeComponents objectAtIndex:1] substringFromIndex: [[timeComponents objectAtIndex:1] rangeOfString: @"+"].location];
            }
            else if( [[timeComponents objectAtIndex:1] rangeOfString: @"-"].location != NSNotFound)
            {
                usecondsString = [[timeComponents objectAtIndex:1] substringToIndex: [[timeComponents objectAtIndex:1] rangeOfString: @"-"].location];
                timeZone = [[timeComponents objectAtIndex:1] substringFromIndex: [[timeComponents objectAtIndex:1] rangeOfString: @"-"].location];
            }
            else
            {
                usecondsString = [timeComponents objectAtIndex:1];
                timeZone = nil;
            }
            
            if( timeZone.length) {
                int tzHours = [[timeZone substringToIndex:3] intValue];
                int tzMinutes = [[timeZone substringFromIndex:3] intValue];
                if (tzHours < 0)
                    tzMinutes = -tzMinutes;
                tz = [NSTimeZone timeZoneForSecondsFromGMT:(tzHours * 3600) + (tzMinutes * 60)];
            }
            
            useconds = [usecondsString intValue] * pow(10, 6 - usecondsString.length);
        }
        
        DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithString:[timeComponents objectAtIndex:0] calendarFormat:format microseconds: useconds] autorelease];
        if( tz)
            [date setTimeZone: tz];
        
        [date setIsQuery:NO];
        [date setQueryString:nil];
        
        return date;
    }
    else
        return nil;
		
}

+ (id)dicomDateWithDate:(NSDate *)date
{
	NSString *format = @"%Y%m%d";
	NSCalendarDate  *cDate= [date dateWithCalendarFormat:format timeZone:nil];
	NSString *dateString = [cDate descriptionWithCalendarFormat:format];
	return [DCMCalendarDate dicomDate:dateString];
}
	
+ (id)dicomTimeWithDate:(NSDate *)date
{
	NSString *format = @"%H%M%S";
	NSCalendarDate  *cDate= [date dateWithCalendarFormat:format timeZone:nil];
	NSString *dateString = [cDate descriptionWithCalendarFormat:format];
	return [DCMCalendarDate dicomTime:dateString];
}

+ (id)dicomDateTimeWithDicomDate:(DCMCalendarDate*)date dicomTime:(DCMCalendarDate*)time
{
	if (date == nil || time == nil)
		return nil;
	
	DCMCalendarDate *dateTime = [[[DCMCalendarDate alloc] initWithYear:[date yearOfCommonEra] month:[date monthOfYear] day:[date dayOfMonth]
				hour:[time hourOfDay] minute:[time minuteOfHour] second:[time secondOfMinute] timeZone:[date timeZone]] autorelease];
	
	[dateTime setIsQuery:NO];
	[dateTime setQueryString:nil];
	return dateTime;
}
	
+ (id)queryDate:(NSString *)query{
	DCMCalendarDate *date = [[[DCMCalendarDate alloc] init] autorelease];
	[date setIsQuery:YES];
	[date setQueryString:query];
	return date;
}


+ (id)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(NSTimeZone *)aTimeZone{
	DCMCalendarDate *date = [[[DCMCalendarDate alloc] initWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:aTimeZone] autorelease];
    
	[date setIsQuery:NO];
	[date setQueryString:nil];
	return date;
}

//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark•

- (id) initWithString:(NSString *)description calendarFormat:(NSString *)format microseconds: (unsigned long) usecs
{
    NSCalendarDate *d = [NSCalendarDate dateWithString: description calendarFormat: format];
    
    if( usecs != 0)
        d = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[d dateByAddingTimeInterval: (NSTimeInterval) usecs / (NSTimeInterval) 1e6] timeIntervalSinceReferenceDate]];
    
    if( self = [super initWithTimeIntervalSinceReferenceDate: d.timeIntervalSinceReferenceDate])
    {
        [self setCalendarFormat: format];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone{
	DCMCalendarDate *date = [super copyWithZone:zone];
	return date;
}

- (NSString *)dateString{
	if (isQuery)
		return queryString;
	NSString *format = @"%Y%m%d";
	return [self descriptionWithCalendarFormat:format];
}

- (NSString *)timeStringWithMilliseconds{
	if (isQuery)
		return queryString;
	NSString *format = @"%H%M%S.%F";
	return [self descriptionWithCalendarFormat:format];
}

- (NSString *)timeString {
	if (isQuery)
		return queryString;
	NSString *format = @"%H%M%S";
	NSString *time =  [self descriptionWithCalendarFormat:format];
    
    NSTimeInterval ti = self.timeIntervalSinceReferenceDate;
    NSTimeInterval useconds = ti - (unsigned long)ti;
    time = [time stringByAppendingFormat: @".%0000006ld", (unsigned long) (useconds * 1e6)];
    
	return [NSString stringWithFormat:@"%@", time];
}

- (NSString *)dateTimeString:(BOOL)withTimeZone{
	if (isQuery)
		return queryString;
	NSString *format = @"%Y%m%d%H%M%S";
	NSString *time =  [self descriptionWithCalendarFormat:format];
    
    NSTimeInterval ti = self.timeIntervalSinceReferenceDate;
    NSTimeInterval useconds = ti - (unsigned long)ti;
    time = [time stringByAppendingFormat: @".%0000006ld", (unsigned long) (useconds * 1e6)];
    
	if (!withTimeZone)
		return time;
	else {
		NSString *tz = [self descriptionWithCalendarFormat:@"%z"];
		return [NSString stringWithFormat:@"%@%@", time,tz];
	}
}

- (NSNumber *)dateAsNumber{
	return [NSNumber numberWithInt:[[self dateString] intValue]];
}
- (NSNumber *)timeAsNumber{
	return [NSNumber numberWithInt:[[self timeString] floatValue]];
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
}

- (NSString *)description{
	if (isQuery)
		return queryString;
	if ([[self calendarFormat] isEqualToString:@"%H:%M:%S"] ||
			[[self calendarFormat] isEqualToString:@"%H%M%S"] ||
			[[self calendarFormat] isEqualToString:@"%H%M"] ||
			[[self calendarFormat] isEqualToString:@"%H"]) 
		return [self timeString];
    
	return [super description];
}

- (NSString *)descriptionWithLocale:(id)localeDictionary{
	if (isQuery)
		return queryString;
	if ([[self calendarFormat] isEqualToString:@"%H:%M:%S"] ||
			[[self calendarFormat] isEqualToString:@"%H%M%S"] ||
			[[self calendarFormat] isEqualToString:@"%H%M"] ||
			[[self calendarFormat] isEqualToString:@"%H"]) 
		return [self timeString];
    
	return [super descriptionWithLocale:localeDictionary];
}

@end
