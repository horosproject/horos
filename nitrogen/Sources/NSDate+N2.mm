/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
