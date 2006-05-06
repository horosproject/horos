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
* Version 2.3
*	20051215 LP Added sortedImages method to export the images sorted by Instance Number
*	20051229	LP	Fixed bug in paths method. Now Accesses completePath
*
*
*
*
*
*
*
*
*
*
*****************************************************************************************************/


#import "DicomSeries.h"

@implementation DicomSeries

- (NSString *) localstring
{
	NSManagedObject	*obj = [[self valueForKey:@"images"] anyObject];
	
	BOOL local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	BOOL iPod = [[obj valueForKey:@"iPod"] boolValue];
	
	if( local) return @"L";
	else if( iPod) return @"i";
	else return @"";
}

- (NSNumber *)noFiles
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] == 0)
	{
		NSNumber	*no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count]];
		[self setPrimitiveValue:no forKey:@"numberOfImages"];
		return no;
	}
	else return [self primitiveValueForKey:@"numberOfImages"];
}

- (NSSet *)paths{
/*
	NSMutableSet *set = [NSMutableSet set];
	NSEnumerator *enumerator = [[self primitiveValueForKey:@"images"] objectEnumerator];
	id object;
	while (object = [enumerator nextObject])
		[set unionSet:[object paths]];
	return set;
*/
	return  [self valueForKeyPath:@"images.completePath"];
}

- (NSSet *)keyImages{
	NSArray *imageArray = [[self primitiveValueForKey:@"images"] allObjects];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"]; 
	return [NSSet setWithArray:[imageArray filteredArrayUsingPredicate:predicate]];
}

- (NSArray *)sortedImages{
	NSArray *imageArray = [[self primitiveValueForKey:@"images"] allObjects];
	//sort by instance Number
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
	NSArray *sortDescriptors= [NSArray arrayWithObject:sortDescriptor];
	[sortDescriptor release];
	return [imageArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSString *)dicomSeriesInstanceUID{
	//core data stores the series uid int the form: seriesNumber, uid,  a bunch of other strings
	int seriesNumber = 0;
	if ([self primitiveValueForKey:@"id"])
		seriesNumber = [[self primitiveValueForKey:@"id"] intValue];

	NSString *numberString = [NSString stringWithFormat:@"%8.8d",seriesNumber];
	NSString *uid = [self primitiveValueForKey:@"seriesInstanceUID"];
	NSArray *array = [uid componentsSeparatedByString:@" "];
	if ([array count] < 2)
		return uid;
		
	if ([numberString isEqualToString:[array objectAtIndex: 0]])
		return [array objectAtIndex:1];
				
	return
		[array objectAtIndex:0];
}


@end
