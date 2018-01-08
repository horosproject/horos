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

#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DicomImage.h"
#import "DicomDatabase.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCM.h"
#import "NSImage+OsiriX.h"
#import "DCMPix.h"
#import "BrowserController.h"
#import "MutableArrayCategory.h"
#import "N2Debug.h"
#import "N2Stuff.h"

#ifdef OSIRIX_VIEWER
#import "DicomFileDCMTKCategory.h"
#import "DICOMToNSString.h"
#import "XMLControllerDCMTKCategory.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "VRController.h"
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

- (BOOL) isDistant
{
    return NO;
}

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
		
        @try {
            id value = [image valueForKey:key];
            if (value)
                return value;
        }
        @catch (NSException *exception) {
            // do nothing
        }
        
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
        
        NSMutableArray* tagAndValues = [NSMutableArray array];
        
        if( [dict objectForKey: @"value"] == nil || [(NSString*)[dict objectForKey: @"value"] length] == 0)
        {
            
            [tagAndValues addObjectsFromArray:
             [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:[dict objectForKey: @"field"]],
              @"",nil]
             ];
            
            //[params addObjectsFromArray: [NSArray arrayWithObjects: @"-e", [dict objectForKey: @"field"], nil]];
        }
        else
        {
            [tagAndValues addObjectsFromArray:
             [NSArray  arrayWithObjects:[DCMAttributeTag tagWithTagString:[dict objectForKey: @"field"]],
              [dict objectForKey: @"value"],nil]
             ];
            
            //[params addObjectsFromArray: [NSArray arrayWithObjects: @"-i", [NSString stringWithFormat: @"%@=%@", [dict objectForKey: @"field"], [dict objectForKey: @"value"]], nil]];
        }
        
        NSMutableArray *files = [NSMutableArray arrayWithArray: [dict objectForKey: @"files"]];
        
        [XMLController modifyDicom:tagAndValues dicomFiles:files];
        
        for( id loopItem in files)
        {
            [[NSFileManager defaultManager] removeItemAtPath:[loopItem stringByAppendingString:@".bak"] error:NULL];
        }
        
        
        
        
        
        /*
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
					[[NSFileManager defaultManager] removeItemAtPath: [loopItem stringByAppendingString:@".bak"] error:NULL];
			}
			@catch (NSException * e)
			{
				NSLog(@"**** DicomStudy setComment: %@", e);
			}
		}
        */
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
		if( [self.study.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"]  && [[DicomDatabase databaseForContext:self.managedObjectContext] isLocal])
		{
			if( c == nil)
				c = @"";
			
			if( [(NSString*)[self primitiveValueForKey: @"comment"] length] != 0 || [c length] != 0)
			{
				if( [c isEqualToString: [self primitiveValueForKey: @"comment"]] == NO)
				{
					NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [[self paths] allObjects], @"files", @"(0020,4000)", @"field", c, @"value", nil];
					
					NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(dcmodifyThread:) object: dict] autorelease];
					t.name = NSLocalizedString( @"Updating DICOM files...", nil);
					t.status = N2LocalizedSingularPluralCount( [[dict objectForKey: @"files"] count], NSLocalizedString(@"file", nil), NSLocalizedString(@"files", nil));
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
			[self.study archiveAnnotationsAsDICOMSR];
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
			[self.study archiveAnnotationsAsDICOMSR];
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
			[self.study archiveAnnotationsAsDICOMSR];
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
			[self.study archiveAnnotationsAsDICOMSR];
	}
}

- (void) setStateText: (NSNumber*) c
{
	NSNumber *previousState = [self primitiveValueForKey: @"stateText"];
	
	[self willChangeValueForKey: @"stateText"];
	[self setPrimitiveValue: c forKey: @"stateText"];
	[self didChangeValueForKey: @"stateText"];
	
	if( [c intValue] != [previousState intValue])
		[self.study archiveAnnotationsAsDICOMSR];
}

- (void) didTurnIntoFault
{
    [dicomTime release];
    dicomTime = nil;
}

- (void) setDate:(NSDate*) date
{
    @synchronized (self)
    {
        [dicomTime release];
        dicomTime = nil;
        
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

//- (void) setThumbnail:(NSData *)thumbnail
//{
//    
//    //                [img setScalesWhenResized: YES];
//    //                [img setSize:NSMakeSize(fillWidth, [fillImage size].height)];
//    
//#ifndef NDEBUG
//    NSImageRep* rep = [[[NSBitmapImageRep alloc] initWithData: thumbnail] autorelease];
//    NSImage* img = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
//    [img addRepresentation:rep];
//    
//    if( img.size.width > THUMBNAILSIZE || img.size.height > THUMBNAILSIZE)
//        NSLog( @"img: %f %f", img.size.width, img.size.height);
//#endif
//    
//    [self willChangeValueForKey: @"thumbnail"];
//    [self setPrimitiveValue:thumbnail forKey:@"thumbnail"];
//    [self didChangeValueForKey: @"thumbnail"];
//}

-(NSData*)thumbnail
{
    NSData* thumbnailData = nil;
    
    [self.managedObjectContext lock];
    @try
    {
        thumbnailData = [[self primitiveValueForKey:@"thumbnail"] retain]; // autoreleased when returning
        
        if( !thumbnailData)
        {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            
            @try
            {
                NSArray* files = [self sortedImages];
                if (files.count)
                {
                    DicomImage* image = [files objectAtIndex:[files count]/2];
                    
                    NSImage* thumbAv = [image thumbnailIfAlreadyAvailable];
                    if (thumbAv) {
                        NSImage* thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize(THUMBNAILSIZE, THUMBNAILSIZE)] autorelease];
                        
                        [thumbnail lockFocus];
                        [thumbAv drawInRect:NSMakeRect(0,0,THUMBNAILSIZE,THUMBNAILSIZE) fromRect:[thumbAv alignmentRect] operation:NSCompositeCopy fraction:1.0];
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
                        
                        NSString *recoveryPath = [[[DicomDatabase databaseForContext:self.managedObjectContext] baseDirPath] stringByAppendingPathComponent:@"ThumbnailPath"];
                        [[NSFileManager defaultManager] removeItemAtPath: recoveryPath error:NULL];
                        [[[[self.study objectID] URIRepresentation] absoluteString] writeToFile: recoveryPath atomically: YES encoding: NSASCIIStringEncoding  error: nil];
                        
                        NSImage *thumbnail = nil;
                        NSString *seriesSOPClassUID = self.seriesSOPClassUID;
                        
                        if( [[DCMAbstractSyntaxUID RTStructureSetStorage] isEqualToString: seriesSOPClassUID])
                        {
                            thumbnail = [NSImage imageNamed: @"RTStructIcon.jpg"];
                            thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                        }
                        else if( [DCMAbstractSyntaxUID isSpectroscopy: seriesSOPClassUID])
                        {
                            thumbnail = [NSImage imageNamed: @"SpectroIcon.jpg"];
                            thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                        }
                        else if( [DCMAbstractSyntaxUID isStructuredReport: seriesSOPClassUID] || [DCMAbstractSyntaxUID isPDF: seriesSOPClassUID])
                        {
                            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"txt"];
                            
                            thumbnail = [[[NSImage alloc] initWithSize: NSMakeSize( THUMBNAILSIZE, THUMBNAILSIZE)] autorelease];
                            
                            [thumbnail lockFocus];
                            [icon drawInRect: NSMakeRect( 0, 0, THUMBNAILSIZE, THUMBNAILSIZE) fromRect: [icon alignmentRect] operation: NSCompositeCopy fraction: 1.0];
                            [thumbnail unlockFocus];
                            
                            thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                        }
                        else if( [DCMAbstractSyntaxUID isImageStorage: seriesSOPClassUID] || [DCMAbstractSyntaxUID isRadiotherapy: seriesSOPClassUID] || [seriesSOPClassUID length] == 0)
                        {
                            DCMPix* dcmPix = [[DCMPix alloc] initWithPath: image.completePath :0 :1 :nil :frame :self.id.intValue isBonjour: ![[DicomDatabase databaseForContext:self.managedObjectContext] isLocal] imageObj:image];
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
                            
                            if (!(dcmPix.notAbleToLoadImage))
                                thumbnailData = [[thumbnail JPEGRepresentationWithQuality:0.3] retain]; // autoreleased when returning
                            
                            [dcmPix release];
                        }
                        else
                        {
                            thumbnail = [NSImage imageNamed: @"FileNotFound.tif"];
                            thumbnailData = [[thumbnail TIFFRepresentation] retain]; // autoreleased when returning
                        }
                        
                        [[NSFileManager defaultManager] removeItemAtPath: recoveryPath error:NULL];
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
            
            [pool release];
        }
    }
    @catch (NSException * e)
    {
        thumbnailData = [[[NSImage imageNamed: @"FileNotFound.tif"] TIFFRepresentation] retain];
    }
    @finally
    {
        [self.managedObjectContext unlock];
    }
        
	return [thumbnailData autorelease];
}

- (NSString*) modalities
{
	return self.modality;
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
		NSManagedObject	*obj = [self.images anyObject];
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
		int v = [[[self.images anyObject] valueForKey:@"numberOfFrames"] intValue];
		
		if( v > 1)
			no = [NSNumber numberWithInt: [self.images count] - v + 1];
		else
			no = [NSNumber numberWithInt: [self.images count]];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}
    @finally {
        [self.managedObjectContext unlock];
    }
	
	return no;
}

- (NSSet*) images
{
    if( self.managedObjectContext.deletedObjects.count == 0)
        return [self primitiveValueForKey: @"images"];
    else
    {
        NSSet *s = nil;
        @autoreleasepool
        {
            s = [[[self primitiveValueForKey: @"images"] objectsWithOptions: NSEnumerationConcurrent passingTest:^BOOL(DicomImage *obj, BOOL *stop)
                {
                    if( obj.isDeleted)
                        return NO;
                    
                    return YES;
                }] retain];
        }
        
        return [s autorelease];
    }
}

- (NSNumber *) noFiles
{
    @try {
        int n = [[self primitiveValueForKey:@"numberOfImages"] intValue];
        
        if( n == 0)
        {
            NSNumber* no = nil;
            
            [self.managedObjectContext lock];
            @try {
                NSString *sopClassUID = self.seriesSOPClassUID;
            
                if( [DCMAbstractSyntaxUID isStructuredReport: sopClassUID] == NO && [DCMAbstractSyntaxUID isPresentationState: sopClassUID] == NO && [DCMAbstractSyntaxUID isSupportedPrivateClasses: sopClassUID] == NO)
                {
                    int v = [[[self.images anyObject] valueForKey:@"numberOfFrames"] intValue];
                    
                    int count = [self.images count];
                    
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
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    
    return [NSNumber numberWithInt: 0];
}

- (NSNumber *) noFilesExcludingMultiFrames
{
	if( [[self primitiveValueForKey:@"numberOfImages"] intValue] <= 0) // There are frames !
	{
		int v = [[[self.images anyObject] valueForKey:@"numberOfFrames"] intValue];
		
		NSNumber *no;
		
		if( v > 1)
			no = [NSNumber numberWithInt: [self.images count] - v + 1];
		else
			no = [self noFiles];
		
		return no;
	}
	else
		return [self noFiles];
}

- (DicomSeries*) previousSeries
{
    NSArray *series = self.study.imageSeries;
    
    NSUInteger index = [series indexOfObject: self];
    
    if( index != NSNotFound && index > 0)
        return [series objectAtIndex: index-1];
    
    return nil;
}

- (DicomSeries*) nextSeries
{
    NSArray *series = self.study.imageSeries;
    
    NSUInteger index = [series indexOfObject: self];
    
    if( index != NSNotFound && index < (long)series.count-1)
        return [series objectAtIndex: index+1];
    
    return nil;
}

- (void) setStudy:(DicomStudy *)study
{
    [self willChangeValueForKey:@"study"];
    [self setPrimitiveValue: study forKey: @"study"];
    [self didChangeValueForKey:@"study"];
    
    [self.study setNumberOfImages: nil];
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
		NSArray *imageArray = [self.images allObjects];
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

- (NSArray*) sortDescriptorsForImages
{
	int sortSeriesBySliceLocation = [[NSUserDefaults standardUserDefaults] integerForKey: @"sortSeriesBySliceLocation"];
    
	NSSortDescriptor *sortInstance = nil, *sortLocation = nil, *sortDate = nil;
    
	sortDate = [NSSortDescriptor sortDescriptorWithKey: @"date" ascending: (sortSeriesBySliceLocation > 0) ? YES : NO];
	sortInstance = [NSSortDescriptor sortDescriptorWithKey: @"instanceNumber" ascending: YES];
	sortLocation = [NSSortDescriptor sortDescriptorWithKey: @"sliceLocation" ascending: (sortSeriesBySliceLocation > 0) ? YES : NO];
    
	NSArray *sortDescriptors = nil;
    
	if( sortSeriesBySliceLocation == 0)
		sortDescriptors = [NSArray arrayWithObjects: sortInstance, sortLocation, nil];
	else
	{
		if( sortSeriesBySliceLocation == 2 || sortSeriesBySliceLocation == -2)
			sortDescriptors = [NSArray arrayWithObjects: sortDate, sortLocation, sortInstance, nil];
		else
			sortDescriptors = [NSArray arrayWithObjects: sortLocation, sortInstance, nil];
	}
	
	return sortDescriptors;
}

- (NSArray *)sortedImages
{
	@try {
        return [self.images.allObjects sortedArrayUsingDescriptors: self.sortDescriptorsForImages];
	}
	@catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	}	
    @finally {
    }
	
	return nil;
}

-(NSString*) uniqueFilename	// Return a 'unique' filename that identify this series
{
	return [NSString stringWithFormat:@"%@ %ld", self.seriesInstanceUID, (long) [self.date timeIntervalSinceReferenceDate]];
}

- (BOOL)validateForDelete:(NSError **)error
{
    BOOL delete = [super validateForDelete: error];
    
    @synchronized (self)
    {
        if (delete)
        {
#ifndef OSIRIX_LIGHT
            NSString *vrFile = [VRController getUniqueFilenameScissorStateFor: self];
            if( vrFile && [[NSFileManager defaultManager] fileExistsAtPath: vrFile])
                [[NSFileManager defaultManager] removeItemAtPath: vrFile error:NULL];
#endif

        }
    }
    
    return delete;
}

- (NSComparisonResult)compareName:(DicomSeries*)series;
{
	return [self.name caseInsensitiveCompare:[series valueForKey:@"name"]];
}

- (NSString*) albumsNames
{
	return [self.study valueForKey: @"albumsNames"];
}

@end
