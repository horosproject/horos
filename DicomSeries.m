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
#import "N2Debug.h"

#ifdef OSIRIX_VIEWER
#import "DicomFileDCMTKCategory.h"
#import "DICOMToNSString.h"
#import "XMLControllerDCMTKCategory.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#endif

@implementation DicomSeries

@synthesize dicomTime;

@dynamic comment, comment2, comment3, comment4;
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

- (id) valueForUndefinedKey:(NSString *)key
{
	NSArray* files = [self sortedImages];
	if( files.count)
	{
		DicomImage* image = [files objectAtIndex:[files count]/2];
		
		id value = [DicomFile getDicomField: key forFile: image.completePath];
		if( value)
			return value;
	}
	return [super valueForUndefinedKey: key];
}

- (void) dcmodifyThread: (NSDictionary*) dict
{
	#ifdef OSIRIX_VIEWER
	#ifndef OSIRIX_LIGHT
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[[DicomStudy dbModifyLock] lock];
	@try {
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
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [[DicomStudy dbModifyLock] unlock];
        [pool release];
    }
	#endif
	#endif
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
					
					NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector( dcmodifyThread:) object: dict] autorelease];
					t.name = NSLocalizedString( @"Updating DICOM files...", nil);
					t.status = [NSString stringWithFormat: NSLocalizedString( @"%d file(s)", nil), [[dict objectForKey: @"files"] count]];
					[[ThreadsManager defaultManager] addThreadAndStart: t];
				}
			}
		}
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
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
    @synchronized (self) {
        [dicomTime release];
        dicomTime = NULL;
        
        [self willChangeValueForKey: @"date"];
        [self setPrimitiveValue:date forKey:@"date"];
        [self didChangeValueForKey: @"date"];
    }
}

- (NSNumber*)dicomTime
{
    @synchronized (self) {
        if (!dicomTime)
            dicomTime = [[[DCMCalendarDate dicomTimeWithDate:self.date] timeAsNumber] retain];
        return dicomTime;
    }
    
    return nil;
}

-(NSData*)thumbnail
{
    NSData* thumbnailData = nil;
    
    @try
    {
        @synchronized( self) // To avoid multiple threads computing the same thumbnail
        {
            thumbnailData = [[self primitiveValueForKey:@"thumbnail"] retain]; // autoreleased when returning
            
            if( !thumbnailData)
            {
                NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
                
                [self.managedObjectContext lock];
                
                @try
                {
                    NSArray* files = [self sortedImages];
                    if (files.count)
                    {
                        DicomImage* image = [files objectAtIndex:[files count]/2];
                        
                        NSImage* thumbAv = [image thumbnailIfAlreadyAvailable];
                        if (thumbAv) {
                            NSImage* thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(70, 70)] autorelease];
                            
                            [thumbnail lockFocus];
                            [thumbAv drawInRect:NSMakeRect(0,0,70,70) fromRect:[thumbAv alignmentRect] operation:NSCompositeCopy fraction:1.0];
                            [thumbnail unlockFocus];
                            
                            thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                        }
                        else
                        if ([[NSFileHandle fileHandleForReadingAtPath: image.completePath] readDataOfLength: 100])	// This means the file is readable...
                        {
                            int frame = 0;
                            
                            if (files.count == 1 && image.numberOfFrames.intValue > 1)
                                frame = [image.numberOfFrames intValue]/2;
                            
                            if (image.frameID)
                                frame = image.frameID.intValue;
                            
                            NSString *recoveryPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"/ThumbnailPath"];
                            [[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
                            [[[[[self valueForKey:@"study"] objectID] URIRepresentation] absoluteString] writeToFile: recoveryPath atomically: YES encoding: NSASCIIStringEncoding  error: nil];
                            
                            NSImage *thumbnail = nil;
                            NSString *seriesSOPClassUID = [self valueForKey: @"seriesSOPClassUID"];
                            
                            if( [DCMAbstractSyntaxUID isSpectroscopy: seriesSOPClassUID])
                            {
                                thumbnail = [NSImage imageNamed: @"SpectroIcon.jpg"];
                                thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                            }
                            else if( [DCMAbstractSyntaxUID isStructuredReport: seriesSOPClassUID] || [DCMAbstractSyntaxUID isPDF: seriesSOPClassUID])
                            {
                                NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"txt"];
                                
                                thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( 70, 70)] autorelease];
                                
                                [thumbnail lockFocus];
                                [icon drawInRect: NSMakeRect( 0, 0, 70, 70) fromRect: [icon alignmentRect] operation: NSCompositeCopy fraction: 1.0];
                                [thumbnail unlockFocus];
                                
                                thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                            }
                            else if( [DCMAbstractSyntaxUID isImageStorage: seriesSOPClassUID] || [DCMAbstractSyntaxUID isRadiotherapy: seriesSOPClassUID] || [seriesSOPClassUID length] == 0)
                            {
                                DCMPix* dcmPix = [[DCMPix alloc] initWithPath: image.completePath :0 :1 :nil :frame :self.id.intValue isBonjour: [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]] imageObj:image];
                                [dcmPix CheckLoad];
                                
                                //Set the default series level window-width&level
                                
                                if( image.series.windowWidth == nil && image.series.windowLevel == nil)
                                {
                                    if( dcmPix.ww != 0 && dcmPix.wl != 0)
                                    {
                                        image.series.windowWidth = [NSNumber numberWithFloat: dcmPix.ww];
                                        image.series.windowLevel = [NSNumber numberWithFloat: dcmPix.wl];
                                    }
                                }
                                
                                thumbnail = [dcmPix generateThumbnailImageWithWW: [image.series.windowWidth floatValue] WL: [image.series.windowLevel floatValue]];
                                
                                if (!dcmPix.notAbleToLoadImage)
                                    thumbnailData = [[thumbnail JPEGRepresentationWithQuality:0.3] retain]; // autoreleased when returning
                                
                                [dcmPix release];
                            }
                            else
                            {
                                thumbnail = [NSImage imageNamed: @"FileNotFound.tif"];
                                thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                            }
                            
                            [[NSFileManager defaultManager] removeFileAtPath: recoveryPath handler: nil];
                        }
                    }

                    if (thumbnailData)
                    {
                        [self willChangeValueForKey: @"thumbnail"];
                        [self setPrimitiveValue:thumbnailData forKey:@"thumbnail"];
                        [self didChangeValueForKey: @"thumbnail"];
                    }
                }
                @catch (NSException * e)
                {
                    N2LogExceptionWithStackTrace(e);
                }
                
                [self.managedObjectContext unlock];
                
                [pool release];
            }
        }
    }
    @catch (NSException * e)
    {
        thumbnailData = [[[NSImage imageNamed: @"FileNotFound.tif"] TIFFRepresentation] retain];
    }
        
	return [thumbnailData autorelease];
}

- (NSString*) modalities
{
	return [self valueForKey: @"modality"];
}

- (NSString*) type
{
	return @"Series";
}

- (NSString *) localstring
{
	
	BOOL local = YES;
	
	[self.managedObjectContext lock];
	@try {
		NSManagedObject	*obj = [[self valueForKey:@"images"] anyObject];
		local = [[obj valueForKey:@"inDatabaseFolder"] boolValue];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	if (local)
        return @"L";
	else return @"";
}

- (NSNumber *) rawNoFiles
{
	NSNumber* no = nil;
	
	[self.managedObjectContext lock];
	@try 
	{
		int v = [[[[self valueForKey:@"images"] anyObject] valueForKey:@"numberOfFrames"] intValue];
		
		if( v > 1)
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count] - v + 1];
		else
			no = [NSNumber numberWithInt: [[self valueForKey:@"images"] count]];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return no;
}

- (NSNumber *) noFiles
{
	int n = [[self primitiveValueForKey:@"numberOfImages"] intValue];
	
	if( n == 0)
	{
		NSNumber* no = nil;
		
        [self.managedObjectContext lock];
		@try {
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
		@catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
		}
        @finally {
            [self.managedObjectContext unlock];
        }
		
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
    [self.managedObjectContext lock];
	@try {
		return [self valueForKeyPath:@"images.completePath"];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (NSSet *)pathsForForkedProcess
{
	[self.managedObjectContext lock];
	@try {
		return [self valueForKeyPath:@"images.completePathWithNoDownloadAndLocalOnly"];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}


- (NSSet *)keyImages
{
	[self.managedObjectContext lock];
	@try {
		NSArray *imageArray = [[self primitiveValueForKey:@"images"] allObjects];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isKeyImage == YES"]; 
		return [NSSet setWithArray:[imageArray filteredArrayUsingPredicate:predicate]];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
}

- (NSArray *)sortedImages
{
	[self.managedObjectContext lock];
	@try {
		NSArray* imageArray = [[self primitiveValueForKey:@"images"] allObjects];
		NSArray* sortDescriptors = [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]];
        return [imageArray sortedArrayUsingDescriptors:sortDescriptors];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}	
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return nil;
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
