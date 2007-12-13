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

#import "DicomSeries.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>

@implementation DicomSeries

- (void) dealloc
{
	if( [self isDeleted] == NO)
	{
		[self setPrimitiveValue: xOffset forKey:@"xOffset"];
		[self setPrimitiveValue: yOffset forKey:@"yOffset"];
		[self setPrimitiveValue: scale forKey:@"scale"];
		[self setPrimitiveValue: rotationAngle forKey:@"rotationAngle"];
		[self setPrimitiveValue: displayStyle forKey:@"displayStyle"];
		[self setPrimitiveValue: windowLevel forKey:@"windowLevel"];
		[self setPrimitiveValue: windowWidth forKey:@"windowWidth"];
		[self setPrimitiveValue: xFlipped forKey:@"xFlipped"];
		[self setPrimitiveValue: yFlipped forKey:@"yFlipped"];
	}
	[xFlipped release];
	[yFlipped release];
	[windowLevel release];
	[windowWidth release];
	[scale release];
	[rotationAngle release];
	[xOffset release];
	[yOffset release];
	[displayStyle release];
	
	[super dealloc];
}

#pragma mark-
- (NSNumber*) xFlipped
{
	if( xFlipped) return xFlipped;
	
	xFlipped = [[self primitiveValueForKey:@"xFlipped"] retain];
	return xFlipped;
}

- (void) setXFlipped:(NSNumber*) f
{
	if( f != xFlipped)
	{
		[xFlipped release];
		xFlipped = [f retain];
	}
}

- (NSNumber*) yFlipped
{
	if( yFlipped) return yFlipped;
	
	yFlipped = [[self primitiveValueForKey:@"yFlipped"] retain];
	return yFlipped;
}

- (void) setYFlipped:(NSNumber*) f
{
	if( f != yFlipped)
	{
		[yFlipped release];
		yFlipped = [f retain];
	}
}

- (NSNumber*) windowLevel
{
	if( windowLevel) return windowLevel;
	
	windowLevel = [[self primitiveValueForKey:@"windowLevel"] retain];
	return windowLevel;
}

- (void) setWindowLevel:(NSNumber*) f
{
	if( f != windowLevel)
	{
		[windowLevel release];
		windowLevel = [f retain];
	}
}

- (NSNumber*) windowWidth
{
	if( windowWidth) return windowWidth;
	
	windowWidth = [[self primitiveValueForKey:@"windowWidth"] retain];
	return windowWidth;
}

- (void) setWindowWidth:(NSNumber*) f
{
	if( f != windowWidth)
	{
		[windowWidth release];
		windowWidth = [f retain];
	}
}

- (NSNumber*) xOffset
{
	if( xOffset) return xOffset;
	
	xOffset = [[self primitiveValueForKey:@"xOffset"] retain];
	return xOffset;
}

- (void) setXOffset:(NSNumber*) f
{
	if( f != xOffset)
	{
		[xOffset release];
		xOffset = [f retain];
	}
}

- (NSNumber*) yOffset
{
	if( yOffset) return yOffset;
	
	yOffset = [[self primitiveValueForKey:@"yOffset"] retain];
	return yOffset;
}

- (void) setYOffset:(NSNumber*) f
{
	if( f != yOffset)
	{
		[yOffset release];
		yOffset = [f retain];
	}
}

- (NSNumber*) scale
{
	if( scale) return scale;
	
	scale = [[self primitiveValueForKey:@"scale"] retain];
	return scale;
}

- (void) setScale:(NSNumber*) f
{
	if( f != scale)
	{
		[scale release];
		scale = [f retain];
	}
}

- (NSNumber*) rotationAngle
{
	if( rotationAngle) return rotationAngle;
	
	rotationAngle = [[self primitiveValueForKey:@"rotationAngle"] retain];
	return rotationAngle;
}

- (void) setRotationAngle:(NSNumber*) f
{
	if( f != rotationAngle)
	{
		[rotationAngle release];
		rotationAngle = [f retain];
	}
}

- (NSNumber*) displayStyle
{
	if( displayStyle) return displayStyle;
	
	displayStyle = [[self primitiveValueForKey:@"displayStyle"] retain];
	return displayStyle;
}

- (void) setDisplayStyle:(NSNumber*) f
{
	if( f != displayStyle)
	{
		[displayStyle release];
		displayStyle = [f retain];
	}
}

#pragma mark-

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
