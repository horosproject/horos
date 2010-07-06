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
#import "DicomStudy.h"
#import "DicomImage.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import <OsiriX/DCM.h>
#import "NSImage+OsiriX.h"
#import "DCMPix.h"
#import "BrowserController.h"
#import "MutableArrayCategory.h"

#ifdef OSIRIX_VIEWER
#import "DicomFileDCMTKCategory.h"
#import "DICOMToNSString.h"
#import "XMLControllerDCMTKCategory.h"
#endif

@implementation DicomSeries

@synthesize dicomTime;

@dynamic comment;
@dynamic date;
@dynamic dateAdded;
@dynamic dateOpened;
@dynamic displayStyle;
@dynamic id;
@dynamic modality;
@dynamic mountedVolume;
@dynamic name;
@dynamic numberOfImages;
@dynamic numberOfKeyImages;
@dynamic rotationAngle;
@dynamic scale;
@dynamic seriesDescription;
@dynamic seriesDICOMUID;
@dynamic seriesInstanceUID;
@dynamic seriesSOPClassUID;
@dynamic stateText;
@dynamic thumbnail;
@dynamic windowLevel;
@dynamic windowWidth;
@dynamic xFlipped;
@dynamic xOffset;
@dynamic yFlipped;
@dynamic yOffset;
@dynamic images;
@dynamic study;

- (void) dealloc
{
	[dicomTime release];
	
	[super dealloc];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (void) dcmodifyThread: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[DicomStudy dbModifyLock] lock];
	
	#ifdef OSIRIX_VIEWER
	#ifndef OSIRIX_LIGHT
	@try 
	{
		NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--ignore-errors", nil];
		
		if( [dict objectForKey: @"value"] == nil || [(NSString*)[dict objectForKey: @"value"] length] == 0)
			[params addObjectsFromArray: [NSArray arrayWithObjects: @"-e", [dict objectForKey: @"field"], nil]];
		else
			[params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", [dict objectForKey: @"field"], [dict objectForKey: @"value"]], nil]];
		
		NSMutableArray *files = [NSMutableArray arrayWithArray: [dict objectForKey: @"files"]];
		
		if( files)
		{
			[files removeDuplicatedStrings];
			
			[params addObjectsFromArray: files];
			
			@try
			{
				NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [[DicomFile getEncodingArrayForFile: [files lastObject]] objectAtIndex: 0]];
				
				[XMLController modifyDicom: params encoding: encoding];
				
				for( id loopItem in files)
					[[NSFileManager defaultManager] removeFileAtPath: [loopItem stringByAppendingString:@".bak"] handler:nil];
			}
			@catch (NSException * e)
			{
				NSLog(@"**** DicomStudy setComment: %@", e);
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	#endif
	#endif
	
	[[DicomStudy dbModifyLock] unlock];
	
	[pool release];
}


- (void) setComment: (NSString*) c
{
	#ifdef OSIRIX_VIEWER
	#ifndef OSIRIX_LIGHT
	@try 
	{
		if( [self.study.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"]  && [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]] == NO)
		{
			if( c == nil)
				c = @"";
			
			if( [(NSString*)[self primitiveValueForKey: @"comment"] length] != 0 || [c length] != 0)
			{
				if( [c isEqualToString: [self primitiveValueForKey: @"comment"]] == NO)
				{
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [[self paths] allObjects], @"files", @"(0020,4000)", @"field", c, @"value", nil];
					[NSThread detachNewThreadSelector: @selector( dcmodifyThread:) toTarget: self withObject: dict];
				}
			}
		}
	}
	@catch (NSException * e) 
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	#endif
	#endif
	
	NSString *previousValue = [self primitiveValueForKey: @"comment"];
	
	[self willChangeValueForKey: @"comment"];
	[self setPrimitiveValue: c forKey: @"comment"];
	[self didChangeValueForKey: @"comment"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[[self valueForKey: @"study"] archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment2: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment2"];
	
	[self willChangeValueForKey: @"comment2"];
	[self setPrimitiveValue: c forKey: @"comment2"];
	[self didChangeValueForKey: @"comment2"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[[self valueForKey: @"study"] archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment3: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment3"];
	
	[self willChangeValueForKey: @"comment3"];
	[self setPrimitiveValue: c forKey: @"comment3"];
	[self didChangeValueForKey: @"comment3"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[[self valueForKey: @"study"] archiveAnnotationsAsDICOMSR];
	}
}

- (void) setComment4: (NSString*) c
{
	NSString *previousValue = [self primitiveValueForKey: @"comment4"];
	
	[self willChangeValueForKey: @"comment4"];
	[self setPrimitiveValue: c forKey: @"comment4"];
	[self didChangeValueForKey: @"comment4"];
	
	if( [previousValue length] != 0 || [c length] != 0)
	{
		if( [c isEqualToString: previousValue] == NO)
			[[self valueForKey: @"study"] archiveAnnotationsAsDICOMSR];
	}
}

- (void) setStateText: (NSNumber*) c
{
	NSNumber *previousState = [self primitiveValueForKey: @"stateText"];
	
	[self willChangeValueForKey: @"stateText"];
	[self setPrimitiveValue: c forKey: @"stateText"];
	[self didChangeValueForKey: @"stateText"];
	
	if( [c intValue] != [previousState intValue])
		[[self valueForKey: @"study"] archiveAnnotationsAsDICOMSR];
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = NULL;
	
	[self willChangeValueForKey: @"date"];
	[self setPrimitiveValue:date forKey:@"date"];
	[self didChangeValueForKey: @"date"];
}

- (NSNumber*)dicomTime
{
	if (!dicomTime)
		dicomTime = [[[DCMCalendarDate dicomTimeWithDate:self.date] timeAsNumber] retain];
	return dicomTime;
}

-(NSData*)thumbnail
{
	NSData* thumbnailData = [self primitiveValueForKey:@"thumbnail"];
	
	if( !thumbnailData)
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		NSArray* files = [self sortedImages];
		if (files.count)
		{
			DicomImage* image = [files objectAtIndex:[files count]/2];
			
			if ([NSData dataWithContentsOfFile: image.completePath])	// This means the file is readable...
			{
				int frame = 0;
				
				if (files.count == 1 && image.numberOfFrames.intValue > 1)
					frame = [image.numberOfFrames intValue]/2;
				
				if (image.frameID)
					frame = image.frameID.intValue;
				
				NSString *recoveryPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"/ThumbnailPath"];
				[[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
				[[[[[self valueForKey:@"study"] objectID] URIRepresentation] absoluteString] writeToFile: recoveryPath atomically: YES encoding: NSASCIIStringEncoding  error: nil];
				
//				NSLog( @"Build thumbnail for: %@", image.completePath);
				
				NSImage *thumbnail = nil;
				
				if( [DCMAbstractSyntaxUID isSpectroscopy: [self valueForKey: @"seriesSOPClassUID"]])
				{
					thumbnail = [NSImage imageNamed: @"SpectroIcon.jpg"]; 
					
					thumbnailData = [thumbnail TIFFRepresentation];
				}
				else if( [DCMAbstractSyntaxUID isStructuredReport: [self valueForKey: @"seriesSOPClassUID"]])
				{
					NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"pdf"];
					
					thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( 70, 70)] autorelease];
					
					[thumbnail lockFocus];
					[icon drawInRect: NSMakeRect( 0, 0, 70, 70) fromRect: [icon alignmentRect] operation: NSCompositeCopy fraction: 1.0];
					[thumbnail unlockFocus];
					
					thumbnailData = [thumbnail TIFFRepresentation];
				}
				else
				{
					DCMPix* dcmPix = [[DCMPix alloc] initWithPath: image.completePath :0 :1 :nil :frame :self.id.intValue isBonjour: [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]] imageObj:image];
					[dcmPix CheckLoad];
					
					thumbnail = [dcmPix generateThumbnailImageWithWW: [image.series.windowWidth floatValue] WL: [image.series.windowLevel floatValue]];
					
					if (!dcmPix.notAbleToLoadImage)
						thumbnailData = [thumbnail JPEGRepresentationWithQuality:0.3];
					
					[dcmPix release];
				}
				[[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
			}
		}

		if( thumbnailData)
		{
			[self willChangeValueForKey: @"thumbnail"];
			[self setPrimitiveValue:thumbnailData forKey:@"thumbnail"];
			[self didChangeValueForKey: @"thumbnail"];
		}
		
		[pool release];
	}
	
	return thumbnailData;
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

- (NSComparisonResult)compareName:(DicomSeries*)series;
{
	return [[self valueForKey:@"name"] caseInsensitiveCompare:[series valueForKey:@"name"]];
}

- (NSString*) albumsNames
{
	return [[self valueForKey: @"study"] valueForKey: @"albumsNames"];
}

@end
