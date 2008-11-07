/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "QueryFilter.h"
#import "Osirix/DCM.h"


@implementation QueryFilter

+ (id)queryFilter{
	return [[[QueryFilter alloc] initWithObject:nil ofSearchType:0 forKey:nil] autorelease];
}
+ (id)queryFilterWithObject:(id)object ofSearchType:(int)searchType  forKey:(id)key{
	return [[[QueryFilter alloc] initWithObject:object ofSearchType:searchType forKey:key] autorelease];
}
- (id) initWithObject:(id)object ofSearchType:(int)searchType  forKey:(id)key{
	//NSLog(@"object: %@", [object description]);
	if (self = [super init]){
		_object = [object retain];
		_searchType = searchType;
		_key = [key retain];
	}
	return self;
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
//	NSLog(@"search type: %d object:%@", _searchType, [_object description]);

	switch (_searchType)
	{
	case 0: return [NSString stringWithFormat:@"*%@*", _object];	//contains
	case 1: return [NSString stringWithFormat:@"%@*", _object];		//searchStartsWith
	case 2: return [NSString stringWithFormat:@"*%@", _object];		//searchEndsWith
	case 3: //searchExactMatch
			if ([_object isKindOfClass:[NSDate class]]) //need to convert dates to strings
				return [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil];	
			else
				return _object;
	case 4: return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];  //today
	case 5: return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];   //Yesterday
	case 6: return [NSString stringWithFormat:@"-%@", [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]; //before
	case 7: return [NSString stringWithFormat:@"%@-", [_object descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil]]; //after
	case 8: return [self withinDateString]; //within
	case 9:  return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];
	
	case 10: return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];  //today am
	case 11: return [_object descriptionWithCalendarFormat:@"%Y%m%d-%Y%m%d" timeZone:nil locale:nil];  //today pm
	}
	
	return nil;
}

- (NSString *)withinDateString{
	DCMCalendarDate *endDate = [DCMCalendarDate date];
	NSCalendarDate *startDate = nil;
	
	NSString *today = [endDate dateString];
	NSString *dateRange = today;
	
	switch ([_object intValue]){
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
	//dateRange =[NSString stringWithFormat:@"%@-%@", [startDate dateString], today];
	dateRange =[NSString stringWithFormat:@"%@-", [[DCMCalendarDate dicomDateWithDate:startDate] dateString]];
	//NSLog(@"dateRange %@", dateRange);
	return dateRange;
}
	

@end
