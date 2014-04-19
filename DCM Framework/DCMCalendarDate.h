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

#import <Foundation/Foundation.h>


/** \brief Subclass of NSCalendarDate to deal with the  DICOM date and time formats 
*
* Subclass of NSCalendarDate to deal with the  DICOM date and time formats.
*/
@interface DCMCalendarDate : NSCalendarDate {
	NSString *queryString;
	BOOL isQuery;
}

/** Create a DICOM date from a string
* Format for DA is YYMMDD = @"%Y%m%d"
* or occasionally @"%Y.%m.%d", @"%Y%m", @"%Y" 
*/
+ (id)dicomDate:(NSString *)string;

/** Create a DICOM time from a string 
* Format for TM is HHMMSS.ffffff = @"%H%M%S.%U";"
* %U is our code for microseconds
* Also deals with the possiblity time is only down to seconds, minutes, or hours
*/
+ (id)dicomTime:(NSString *)string;

/** Create a DICOM datetime from a string
* Default format for DateTime is %Y%m%d%H%M%S
*/
+ (id)dicomDateTime:(NSString *)string;

/** Create a DICOM date from an NSDate */
+ (id)dicomDateWithDate:(NSDate *)date;

/** Create a DICOM time from a string */
+ (id)dicomTimeWithDate:(NSDate *)date;

/** Create a DICOM datetime from a DICOM date and a DICOM time */
+ (id)dicomDateTimeWithDicomDate:(DCMCalendarDate*)date dicomTime:(DCMCalendarDate*)time;

/** Create a DICOM date from a string for queries */
+ (id)queryDate:(NSString *)query;

/** Create a DICOM date the name of this method should change but I don't want to do it right before a release - spalte */
+ (id)dateWithYear:(NSInteger)year month:(NSUInteger)month day:(NSUInteger)day hour:(NSUInteger)hour minute:(NSUInteger)minute second:(NSUInteger)second timeZone:(NSTimeZone *)aTimeZone;

/** return the date as a DICOM formatted string */
- (NSString *)dateString;

/** return the time as a DICOM formatted string */
- (NSString *)timeString;
- (NSString *)timeStringWithMilliseconds;

/** return the datetime as a DICOM formatted string */
- (NSString *)dateTimeString:(BOOL)withTimeZone;

/** return the query as a DICOM formatted string */
- (NSString *)queryString;


/** return the date as an NSNumber YYYYMMDD*/
- (NSNumber *)dateAsNumber;

/** return the time as an NSNumber HHMMSS.ff*/
- (NSNumber *)timeAsNumber;

/** Test to see if this is a query */
- (BOOL)isQuery;

/** Set query flag */
- (void)setIsQuery:(BOOL)query;

/** set the query String */
- (void)setQueryString:(NSString *)query;

/** Human readable description of the date */
- (NSString *)description;
- (NSString *)descriptionWithLocale:(id)localeDictionary;
@end
