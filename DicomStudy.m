/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/***************************************** Modifications *********************************************

Version 2.3

	20051229	LP	Fixed bug in paths method. Now accesses completePath.
	20060101	DDP	Changed yearOld to return in the format 5 y or 23 d rather than 5 yo or 23 do,
					as this is more internationally generic.
				
	
****************************************************************************************************/

#import "DicomStudy.h"

@implementation DicomStudy

- (NSString *) localstring
{
	NSManagedObject	*obj = [[[[self valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
	
	BOOL local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	BOOL iPod = [[obj valueForKey:@"iPod"] boolValue];
	
	if( local) return @"L";
	else if( iPod) return @"i";
	else return @"";
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSString*) yearOld
{
	if( [self valueForKey: @"dateOfBirth"])
	{
		NSCalendarDate *momsBDay = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[self valueForKey:@"dateOfBirth"] timeIntervalSinceReferenceDate]];
		NSCalendarDate *dateOfBirth = [NSCalendarDate date];
		int		years, months, days;
		
		[dateOfBirth years:&years months:&months days:&days hours:NULL minutes:NULL seconds:NULL sinceDate:momsBDay];
		
		if( years < 2)
		{
			if( months < 3) return [NSString stringWithFormat:@"%d d", days];
			else return [NSString stringWithFormat:@"%d m", months];
		}
		else return [NSString stringWithFormat:@"%d y", years];
	}
	else return @"";
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSNumber *) noFiles
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] == 0)
	{
		NSSet	*series = [self valueForKey:@"series"];
		NSArray	*array = [series allObjects];
		
		long sum = 0, i;
		
		for( i = 0; i < [array count]; i++)
		{
			sum += [[[array objectAtIndex:i] valueForKey:@"images"] count];
		}
		
		NSNumber	*no = [NSNumber numberWithInt:sum];
		[self setPrimitiveValue:no forKey:@"numberOfImages"];
		return no;
	}
	else return [self primitiveValueForKey:@"numberOfImages"];
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) paths
{
//	NSLog(@"keyPath: %@", [[self valueForKeyPath:@"series.images.completePath"] description]);
	NSSet *sets = [self valueForKeyPath: @"series.images.completePath"];
	NSEnumerator *enumerator = [sets objectEnumerator];
	NSMutableSet *set = [NSMutableSet set];
//	NSEnumerator *enumerator = [[self primitiveValueForKey:@"series"] objectEnumerator];
	id subset;
	while (subset = [enumerator nextObject])
		[set unionSet: subset];
	return set;
}


//ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ

- (NSSet*) keyImages
{
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [[self primitiveValueForKey: @"series"] objectEnumerator];
	
	id object;
	while (object = [enumerator nextObject])
		[set unionSet:[object keyImages]];
	return set;
}
	


@end
