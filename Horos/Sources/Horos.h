/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 ============================================================================*/

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#define BEGIN_EXTERN_C extern "C" {
#define END_EXTERN_C }
#else
#define BEGIN_EXTERN_C
#define END_EXTERN_C
#endif

NS_ASSUME_NONNULL_BEGIN

@interface Horos : NSObject

@end

@interface Horos (NSCalendarDate) // NSCalendarDate is deprecated and these methods replace the used APIs

+ (NSDate *)dateWithString:(NSString *)str calendarFormat:(NSString *)format;
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(nullable NSTimeZone *)aTimeZone;
+ (NSDate *):(NSDate *)date dateByAddingYears:(NSInteger)year months:(NSInteger)month days:(NSInteger)day hours:(NSInteger)hour minutes:(NSInteger)minute seconds:(NSInteger)second;
+ (void):(NSDate *)date years:(nullable NSInteger *)years months:(nullable NSInteger *)months days:(nullable NSInteger *)days hours:(nullable NSInteger *)hours minutes:(nullable NSInteger *)minutes seconds:(nullable NSInteger *)seconds sinceDate:(NSDate *)sinceDate;
+ (NSDateComponents *)components:(NSCalendarUnit)flags fromDate:(NSDate *)date;
+ (NSString *):(NSDate *)date descriptionWithCalendarFormat:(NSString *)format;

@end

NS_ASSUME_NONNULL_END
