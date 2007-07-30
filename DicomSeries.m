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
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>

@implementation DicomSeries

- (void) dealloc
{
	[dicomTime release];
	
	[super dealloc];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = 0L;
	
	[self setPrimitiveValue: date forKey:@"date"];
}

- (NSNumber*) dicomTime
{
	if( dicomTime) return dicomTime;
	
	dicomTime = [[[DCMCalendarDate dicomTimeWithDate:[self valueForKey: @"date"]] timeAsNumber] retain];
	
	return dicomTime;
}


- (NSString*) type
{
	return @"Series";
}

- (NSString *) localstring
{
	NSManagedObject	*obj = [[self valueForKey:@"images"] anyObject];
	
	BOOL local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	
	if( local) return @"L";
	else return @"";
}

- (NSNumber *) noFiles
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] == 0)
	{
		NSNumber	*no;
		
		if( [DCMAbstractSyntaxUID isStructuredReport: [self valueForKey: @"seriesSOPClassUID"]] == NO)
		{
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count]];
			[self setPrimitiveValue:no forKey:@"numberOfImages"];
		}
		else no = [NSNumber numberWithInt: 0];
		
		return no;
	}
	else return [self primitiveValueForKey:@"numberOfImages"];
}

- (NSSet *)paths
{
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

- (NSDictionary *)dictionary{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if ([self primitiveValueForKey:@"seriesDescription"])
		[dict  setObject: [self primitiveValueForKey:@"seriesDescription"] forKey: @"Series Protocol"];
	if ([self primitiveValueForKey:@"name"])
		[dict  setObject: [self primitiveValueForKey:@"name"] forKey: @"Series Description"];
	if ([self primitiveValueForKey:@"id"])
		[dict  setObject: [self primitiveValueForKey:@"id"] forKey: @"Series Number"];
	if ([self primitiveValueForKey:@"modality"])
		[dict  setObject: [self primitiveValueForKey:@"modality"] forKey: @"Modality"];
	if ([self primitiveValueForKey:@"date"])
		[dict  setObject: [self primitiveValueForKey:@"date"] forKey: @"Series Date"];
	if ([self primitiveValueForKey:@"seriesDICOMUID"] )
		[dict  setObject: [self primitiveValueForKey:@"seriesDICOMUID"] forKey: @"Series Instance UID"];
	if ([self primitiveValueForKey:@"comment"] )
		[dict  setObject: [self primitiveValueForKey:@"comment"] forKey: @"Comment"];
	return dict;
}


@end
