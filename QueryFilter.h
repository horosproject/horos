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

enum searchTypes {searchContains = 0, searchStartsWith, searchEndsWith, searchExactMatch};
enum dateSearchTypes {searchToday = 4, searchYesterday, searchBefore, searchAfter, searchWithin, searchExactDate};
enum dateWithinSearch {searchWithinToday = 10, searchWithinLast2Days, searchWithinLastWeek, searchWithinLast2Weeks, searchWithinLastMonth,searchWithinLast2Months, searchWithinLast3Months, searchWithinLastYear};
enum modalities {osiCR = 0,osiCT,osiDX,osiES,osiMG,osiMR,osiNM,osiOT,osiPT,osiRF,osiSC,osiUS,osiXA};
enum studyState {empty = 0, unread, reviewed, dictated, validated};


/** \brief Query Filter */
@interface QueryFilter : NSObject {
	id _key;
	id _object;
	int _searchType;

}
+ (id)queryFilter;
+ (id)queryFilterWithObject:(id)object ofSearchType:(int)searchType forKey:(id)key;
- (id) initWithObject:(id)object ofSearchType:(int)searchType forKey:(id)key;

- (id) key;
- (id) object;
- (int) searchType;
- (NSString *)filteredValue;

- (void)setKey:(id)key;
- (void)setObject:(id)object;
- (void)setSearchType:(int)searchType;

- (NSString *)withinDateString;


@end
