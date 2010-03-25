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
	dicomTime = nil;
	
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
	[[self managedObjectContext] lock];
	
	BOOL local = YES;
	
	@try 
	{
		NSManagedObject	*obj = [[self valueForKey:@"images"] anyObject];
		local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[[self managedObjectContext] unlock];
	
	if( local) return @"L";
	else return @"";
}

- (NSNumber *) rawNoFiles
{
	NSNumber *no = nil;
	
	[[self managedObjectContext] lock];
	
	@try 
	{
		int v = [[[[self valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
		
		if( v > 1)
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count] - v + 1];
		else
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count]];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[[self managedObjectContext] unlock];
	
	return no;
}

- (NSNumber *) noFiles
{
	int n = [[self primitiveValueForKey:@"numberOfImages"] intValue];
	
	if( n == 0)
	{
		NSNumber *no = nil;
		
		[[self managedObjectContext] lock];
		
		@try 
		{
			NSString *sopClassUID = [self valueForKey: @"seriesSOPClassUID"];
		
			if( [DCMAbstractSyntaxUID isStructuredReport: sopClassUID] == NO && [DCMAbstractSyntaxUID isPresentationState: sopClassUID] == NO && [DCMAbstractSyntaxUID isSupportedPrivateClasses: sopClassUID] == NO)
			{
				int v = [[[[self valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
				
				int count = [[self valueForKey:@"images"] count];
				
				if( v > 1) // There are frames !
					no = [NSNumber numberWithInt: -count];
				else
					no = [NSNumber numberWithInt: count];
				
				[self willChangeValueForKey: @"numberOfImages"];
				[self setPrimitiveValue:no forKey:@"numberOfImages"];
				[self didChangeValueForKey: @"numberOfImages"];
				
				if( v > 1)
					no = [NSNumber numberWithInt: count]; // For the return
			}
			else no = [NSNumber numberWithInt: 0];
		}
		@catch (NSException * e) 
		{
			NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
		}
		
		[[self managedObjectContext] unlock];
		
		return no;
	}
	else
	{
		if( n < 0) // There are frames !
			return [NSNumber numberWithInt: -n];
		else
			return [self primitiveValueForKey:@"numberOfImages"];
	}
}

- (NSNumber *) noFilesExcludingMultiFrames
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] <= 0) // There are frames !
	{
		int v = [[[[self valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
		
		NSNumber *no;
		
		if( v > 1)
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count] - v + 1];
		else
			no = [self noFiles];
		
		return no;
	}
	else
		return [self noFiles];
}

- (NSSet *)paths
{
	[[self managedObjectContext] lock];
	
	NSSet *set = nil;
	@try 
	{
		set = [self valueForKeyPath:@"images.completePath"];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[[self managedObjectContext] unlock];
	
	return set;
}

- (NSSet *)keyImages
{
	[[self managedObjectContext] lock];
	
	NSSet *set = nil;
	@try 
	{
		NSArray *imageArray = [[self primitiveValueForKey:@"images"] allObjects];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"]; 
		set = [NSSet setWithArray:[imageArray filteredArrayUsingPredicate:predicate]];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	[[self managedObjectContext] unlock];
	
	return set;
}

- (NSArray *)sortedImages
{
	[[self managedObjectContext] lock];
	
	NSArray *imageArray = nil;
	NSArray *sortDescriptors = nil;
	
	@try 
	{
		imageArray = [[self primitiveValueForKey:@"images"] allObjects];
	
		sortDescriptors = [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]];
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}	
	
	[[self managedObjectContext] unlock];
	
	return [imageArray sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSDictionary *)dictionary
{
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

- (NSString*) albumsNames
{
	return [[self valueForKey: @"study"] valueForKey: @"albumsNames"];
}

@end
