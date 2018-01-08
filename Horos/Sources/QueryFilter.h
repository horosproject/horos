/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/



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
