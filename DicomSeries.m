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

//- (void)willSave
//{
//	if( [self isDeleted] == NO)
//	{
//		if( mxOffset) [self setPrimitiveValue: xOffset forKey:@"xOffset"];
//		if( myOffset) [self setPrimitiveValue: yOffset forKey:@"yOffset"];
//		if( mscale) [self setPrimitiveValue: scale forKey:@"scale"];
//		if( mrotationAngle) [self setPrimitiveValue: rotationAngle forKey:@"rotationAngle"];
//		if( mdisplayStyle) [self setPrimitiveValue: displayStyle forKey:@"displayStyle"];
//		if( mwindowLevel) [self setPrimitiveValue: windowLevel forKey:@"windowLevel"];
//		if( mwindowWidth) [self setPrimitiveValue: windowWidth forKey:@"windowWidth"];
//		if( mxFlipped) [self setPrimitiveValue: xFlipped forKey:@"xFlipped"];
//		if( myFlipped) [self setPrimitiveValue: yFlipped forKey:@"yFlipped"];
//
//		mxOffset = NO;
//		myOffset = NO;
//		mscale = NO;
//		mrotationAngle = NO;
//		mdisplayStyle = NO;
//		mwindowLevel = NO;
//		mwindowWidth = NO;
//		myFlipped = NO;
//		mxFlipped = NO;
//	}
//}

- (void) dealloc
{
//	[xFlipped release];
//	[yFlipped release];
//	[windowLevel release];
//	[windowWidth release];
//	[scale release];
//	[rotationAngle release];
//	[xOffset release];
//	[yOffset release];
//	[displayStyle release];
	[dicomTime release];
	
	[super dealloc];
}

#pragma mark-
//- (NSNumber*) xFlipped
//{
//	[self willAccessValueForKey:@"xFlipped"];
//	if( xFlipped == 0L)
//		xFlipped = [[self primitiveValueForKey:@"xFlipped"] retain];
//	[self didAccessValueForKey:@"xFlipped"];
//	return xFlipped;
//}
//
//- (void) setXFlipped:(NSNumber*) f
//{
//	if( f != xFlipped)
//	{
//		mxFlipped = YES;
//		[xFlipped release];
//		xFlipped = [f retain];
//	}
//}
//
//- (NSNumber*) yFlipped
//{
//	[self willAccessValueForKey:@"yFlipped"];
//	if( yFlipped == 0L)
//		yFlipped = [[self primitiveValueForKey:@"yFlipped"] retain];
//	[self didAccessValueForKey:@"yFlipped"];
//	return yFlipped;
//}
//
//- (void) setYFlipped:(NSNumber*) f
//{
//	if( f != yFlipped)
//	{
//		myFlipped = YES;
//		[yFlipped release];
//		yFlipped = [f retain];
//	}
//}
//
//- (NSNumber*) windowLevel
//{
//	[self willAccessValueForKey:@"windowLevel"];
//	if( windowLevel == 0L)
//		windowLevel = [[self primitiveValueForKey:@"windowLevel"] retain];
//	[self didAccessValueForKey:@"windowLevel"];
//	return windowLevel;
//}
//
//- (void) setWindowLevel:(NSNumber*) f
//{
//	if( f != windowLevel)
//	{
//		mwindowLevel = YES;
//		[windowLevel release];
//		windowLevel = [f retain];
//	}
//}
//
//- (NSNumber*) windowWidth
//{
//	[self willAccessValueForKey:@"windowWidth"];
//	if( windowWidth == 0L)
//		windowWidth = [[self primitiveValueForKey:@"windowWidth"] retain];
//	[self didAccessValueForKey:@"windowWidth"];
//	return windowWidth;
//}
//
//- (void) setWindowWidth:(NSNumber*) f
//{
//	if( f != windowWidth)
//	{
//		mwindowWidth = YES;
//		[windowWidth release];
//		windowWidth = [f retain];
//	}
//}
//
//- (NSNumber*) xOffset
//{
//	[self willAccessValueForKey:@"xOffset"];
//	if( xOffset == 0L)
//		xOffset = [[self primitiveValueForKey:@"xOffset"] retain];
//	[self didAccessValueForKey:@"xOffset"];
//	return xOffset;
//}
//
//- (void) setXOffset:(NSNumber*) f
//{
//	if( f != xOffset)
//	{
//		mxOffset = YES;
//		[xOffset release];
//		xOffset = [f retain];
//	}
//}
//
//- (NSNumber*) yOffset
//{
//	[self willAccessValueForKey:@"yOffset"];
//	if( yOffset == 0L)
//		yOffset = [[self primitiveValueForKey:@"yOffset"] retain];
//	[self didAccessValueForKey:@"yOffset"];
//	return yOffset;
//}
//
//- (void) setYOffset:(NSNumber*) f
//{
//	if( f != yOffset)
//	{
//		myOffset = YES;
//		[yOffset release];
//		yOffset = [f retain];
//	}
//}
//
//- (NSNumber*) scale
//{
//	[self willAccessValueForKey:@"scale"];
//	if( scale == 0L)
//		scale = [[self primitiveValueForKey:@"scale"] retain];
//	[self didAccessValueForKey:@"scale"];
//	return scale;
//}
//
//- (void) setScale:(NSNumber*) f
//{
//	if( f != scale)
//	{
//		mscale = YES;
//		[scale release];
//		scale = [f retain];
//	}
//}
//
//- (NSNumber*) rotationAngle
//{
//	[self willAccessValueForKey:@"rotationAngle"];
//	if( rotationAngle == 0L)
//		rotationAngle = [[self primitiveValueForKey:@"rotationAngle"] retain];
//	[self didAccessValueForKey:@"rotationAngle"];
//	return rotationAngle;
//}
//
//- (void) setRotationAngle:(NSNumber*) f
//{
//	if( f != rotationAngle)
//	{
//		mrotationAngle = YES;
//		[rotationAngle release];
//		rotationAngle = [f retain];
//	}
//}
//
//- (NSNumber*) displayStyle
//{
//	[self willAccessValueForKey:@"displayStyle"];
//	if( displayStyle == 0L)
//		displayStyle = [[self primitiveValueForKey:@"displayStyle"] retain];
//	[self didAccessValueForKey:@"displayStyle"];
//	return displayStyle;
//}
//
//- (void) setDisplayStyle:(NSNumber*) f
//{
//	if( f != displayStyle)
//	{
//		mdisplayStyle = YES;
//		[displayStyle release];
//		displayStyle = [f retain];
//	}
//}

#pragma mark-

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = 0L;
	
	[self willChangeValueForKey: @"date"];
	[self setPrimitiveValue: date forKey:@"date"];
	[self didChangeValueForKey: @"date"];
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
			
			[self willChangeValueForKey: @"numberOfImages"];
			[self setPrimitiveValue:no forKey:@"numberOfImages"];
			[self didChangeValueForKey: @"numberOfImages"];
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

- (NSComparisonResult)compareName:(DicomSeries*)series;
{
	return [[self valueForKey:@"name"] caseInsensitiveCompare:[series valueForKey:@"name"]];
}

@end
