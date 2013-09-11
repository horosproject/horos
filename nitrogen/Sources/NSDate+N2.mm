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

#import "NSDate+N2.h"

@implementation NSDate (N2)

+(id)dateWithYYYYMMDD:(NSString*)datestr HHMMss:(NSString*)timestr
{
    if (datestr.length < 8)
        return nil;
    
    if( datestr.length != 8)
        datestr = [datestr stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    if(timestr.length >= 6)
        return [[[NSCalendarDate alloc] initWithString: [datestr stringByAppendingString: timestr] calendarFormat:@"%Y%m%d%H%M%S"] autorelease];
    
    return [[[NSCalendarDate alloc] initWithString: datestr calendarFormat:@"%Y%m%d%H%M"] autorelease];
    
    
//	NSDateComponents* dc = [NSDateComponents new];
//	
//	dc.year = [[datestr substringWithRange:NSMakeRange(0,4)] integerValue];
//	dc.month = [[datestr substringWithRange:NSMakeRange(4,2)] integerValue];
//	dc.day = [[datestr substringWithRange:NSMakeRange(6,2)] integerValue];
//	
//	dc.hour = dc.minute = dc.second = 0;
//	if (timestr.length >= 6) {
//		dc.hour = [[timestr substringWithRange:NSMakeRange(0,2)] integerValue];
//		dc.minute = [[timestr substringWithRange:NSMakeRange(2,2)] integerValue];
//		if (timestr.length >= 6) dc.second = [[timestr substringWithRange:NSMakeRange(4,2)] integerValue];
//	}
//	
//	NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//	NSDate* d = [cal dateFromComponents:dc];
//	[cal release];
//	[dc release];
//	return d;
}

@end
