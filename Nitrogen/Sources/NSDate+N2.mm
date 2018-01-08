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
