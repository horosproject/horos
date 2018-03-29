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
 ============================================================================*/

#import "Horos.h"

@implementation Horos

@end

@implementation Horos (NSCalendarDate) // for now we are forwarding calls to the deprecated NSCalendarDate APIs

+ (NSDate *)dateWithString:(NSString *)str calendarFormat:(NSString *)format {
//    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
//    df.dateFormat = format;
//    df.formatterBehavior = NSDateFormatterBehavior10_0;
//    return [df dateFromString:str];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSCalendarDate dateWithString:str calendarFormat:format];
#pragma clang diagnostic pop
}

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(nullable NSTimeZone *)aTimeZone {
//    NSDateComponents *dc = [[[NSDateComponents alloc] init] autorelease];
//    dc.year = year;
//    dc.day = day;
//    dc.hour = hour;
//    dc.minute = minute;
//    dc.second = second;
//    dc.timeZone = aTimeZone;
//    return [dc date];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [NSCalendarDate dateWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:aTimeZone];
#pragma clang diagnostic pop
}

+ (NSDate *):(NSDate *)date dateByAddingYears:(NSInteger)years months:(NSInteger)months days:(NSInteger)days hours:(NSInteger)hours minutes:(NSInteger)minutes seconds:(NSInteger)seconds {
//    NSDateComponents *dc = [[[NSDateComponents alloc] init] autorelease];
//    dc.year = years;
//    dc.day = days;
//    dc.hour = hours;
//    dc.minute = minutes;
//    dc.second = seconds;
//    return [[NSCalendar currentCalendar] dateByAddingComponents:dc toDate:date options:0];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] dateByAddingYears:years months:months days:days hours:hours minutes:minutes seconds:seconds];;
#pragma clang diagnostic pop
}

+ (void):(NSDate *)date years:(NSInteger *)years months:(NSInteger *)months days:(NSInteger *)days hours:(NSInteger *)hours minutes:(NSInteger *)minutes seconds:(NSInteger *)seconds sinceDate:(NSDate *)sinceDate {
//    NSCalendarUnit flags = 0;
//    if (years) flags |= NSCalendarUnitYear;
//    if (months) flags |= NSCalendarUnitMonth;
//    if (days) flags |= NSCalendarUnitDay;
//    if (hours) flags |= NSCalendarUnitHour;
//    if (minutes) flags |= NSCalendarUnitMinute;
//    if (seconds) flags |= NSCalendarUnitSecond;
//    NSDateComponents *dc = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:flags fromDate:sinceDate toDate:date options:0];
//    if (years) *years = dc.year;
//    if (months) *months = dc.month;
//    if (days) *days = dc.day;
//    if (hours) *hours = dc.hour;
//    if (minutes) *minutes = dc.minute;
//    if (seconds) *seconds = dc.second;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] years:years months:months days:days hours:hours minutes:minutes seconds:seconds sinceDate:[NSCalendarDate dateWithTimeInterval:0 sinceDate:sinceDate]];
#pragma clang diagnostic pop
}

+ (NSDateComponents *)components:(NSCalendarUnit)flags fromDate:(NSDate *)date {
    return [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] components:flags fromDate:date];
}

+ (NSString *):(NSDate *)date descriptionWithCalendarFormat:(NSString *)format {
//    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
//    df.formatterBehavior = NSDateFormatterBehavior10_0;
//    df.dateFormat = format;
//    return [df stringFromDate:date];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[NSCalendarDate dateWithTimeInterval:0 sinceDate:date] descriptionWithCalendarFormat:format];
#pragma clang diagnostic pop
}

+ (NSArray<NSString *> *)WeasisCustomizationPaths {
    return @[ [@"~/Library/Application Support/Horos/Weasis" stringByExpandingTildeInPath], @"/Library/Application Support/Horos/Weasis" ];
}

@end
