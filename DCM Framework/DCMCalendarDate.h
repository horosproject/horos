//
//  DCMCalendarDate.h
//  OsiriX
//
//  Created by Lance Pysher on Wed Jul 14 2004.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Foundation/Foundation.h>

@interface DCMCalendarDate : NSCalendarDate {
	int microseconds;
	NSString *queryString;
	BOOL isQuery;
}

+ (id)dicomDate:(NSString *)string;
+ (id)dicomTime:(NSString *)string;
+ (id)dicomDateTime:(NSString *)string;
+ (id)dicomDateWithDate:(NSDate *)date;
+ (id)dicomTimeWithDate:(NSDate *)date;
+ (id)queryDate:(NSString *)query;

- (DCMCalendarDate *)dateWithYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second timeZone:(NSTimeZone *)aTimeZone;

- (NSString *)dateString;
- (NSString *)timeString;
- (NSString *)dateTimeString:(BOOL)withTimeZone;
- (NSString *)queryString;

- (NSNumber *)dateAsNumber;
- (NSNumber *)timeAsNumber;


- (void)setMicroseconds:(int)useconds;
- (BOOL)isQuery;
- (void)setIsQuery:(BOOL)query;
- (void)setQueryString:(NSString *)query;
- (NSString *)description;

@end
