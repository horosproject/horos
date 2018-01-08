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



#import "QueryFilter.h"
#import "DCM.h"


@implementation QueryFilter

+ (id)queryFilter
{
	return [[[QueryFilter alloc] initWithObject:nil ofSearchType:0 forKey:nil] autorelease];
}

+ (id)queryFilterWithObject:(id)object ofSearchType:(int)searchType forKey:(id)key
{
	return [[[QueryFilter alloc] initWithObject:object ofSearchType:searchType forKey:key] autorelease];
}

- (id) initWithObject:(id)object ofSearchType:(int)searchType  forKey:(id)key
{
	//NSLog(@"object: %@", [object description]);
	if (self = [super init])
    {
		_object = [object retain];
		_searchType = searchType;
		_key = [key retain];
	}
	return self;
}

- (void) dealloc
{
	[_object release];
	[_key release];
	
	[super dealloc];
}

//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark¥

- (id) key{
	return _key;
}
- (id) object{
	return _object;
}
- (int) searchType{
	return _searchType;
}

//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark¥

- (void)setKey:(id)key{
	if( _key == key) return;
	
	[_key release];
	_key = [key retain];
}
- (void)setObject:(id)object{
	if( _object == object) return;

	[_object release];
	_object = [object retain];
}
	
- (void)setSearchType:(int)searchType{
	_searchType = searchType;
}


//------------------------------------------------------------------------------------------------------------------------------------
#pragma mark¥

- (NSString *)filteredValue
{
	switch (_searchType)
	{
        case 0:
            return [NSString stringWithFormat:@"*%@*", _object];
        break;	//contains
            
        case 1:
            return [NSString stringWithFormat:@"%@*", _object];
        break;  //searchStartsWith
            
        case 2:
            return [NSString stringWithFormat:@"*%@", _object];
        break;  //searchEndsWith
            
        case 3: //searchExactMatch
            if ([_object isKindOfClass:[NSDate class]]) //need to convert dates to strings
                return [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil];	
            else
                return _object;
        break;
        
        case searchToday:
            return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];  //today
        break;
        
        case searchYesterday:
            return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];  //Yesterday
        break;
        
        case searchBefore:
            return [NSString stringWithFormat:@"-%@", [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]; //before
        break;
        
        case searchAfter:
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
            {
                return [NSString stringWithFormat:@"%@-", [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]; //after
            }
            else
            {
                return [NSString stringWithFormat:@"%@-%@", [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil], [[DCMCalendarDate date] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]; //after
            }
        break;
        
        case searchWithin:
            return [self withinDateString]; //within
        break;
        
        case searchExactDate: 
            return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];
        break;
	}
	
	return nil;
}

- (NSString *)withinDateString
{
	DCMCalendarDate *endDate = [DCMCalendarDate date];
	NSCalendarDate *startDate = nil;
	
	NSString *today = [endDate dateString];
	NSString *dateRange = nil;
	
	switch ([_object intValue])
    {
        default:
        case searchWithinToday: return today; //today
		break;
        case searchWithinLast2Days: startDate = [endDate dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0 ];
		  //last 2 days
		break;
        case searchWithinLastWeek: startDate = [endDate dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0 ];
		break;
        case searchWithinLast2Weeks: startDate = [endDate dateByAddingYears:0 months:0 days:-14 hours:0 minutes:0 seconds:0 ];
		break;
        case searchWithinLastMonth: startDate = [endDate dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0 ];
		break;
        case searchWithinLast2Months: startDate = [endDate dateByAddingYears:0 months:-2 days:0 hours:0 minutes:0 seconds:0 ];
		break;
        case searchWithinLast3Months: startDate = [endDate dateByAddingYears:0 months:-3 days:0 hours:0 minutes:0 seconds:0 ];
		break;
        case searchWithinLastYear: startDate = [endDate dateByAddingYears:-1 months:0 days:0 hours:0 minutes:0 seconds:0 ];
		break;
	}
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"DICOMQueryAllowFutureQuery"])
    {
        dateRange = [NSString stringWithFormat:@"%@-", [[DCMCalendarDate dicomDateWithDate:startDate] dateString]];
    }
    else
    {
        dateRange = [NSString stringWithFormat:@"%@-%@", [[DCMCalendarDate dicomDateWithDate:startDate] dateString], [[DCMCalendarDate date] dateString]];
    }
	return dateRange;
}
	

@end
