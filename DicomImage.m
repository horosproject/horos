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

#import "DicomImage.h"
#import "DicomSeries.h"
#import "DicomStudy.h"
#import "DicomFileDCMTKCategory.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMAbstractSyntaxUID.h>
#import "DCMObjectPixelDataImport.h"
#import "DCMView.h"
#import "MutableArrayCategory.h"
#import "DicomFile.h"
#import "DICOMToNSString.h"
#import "XMLController.h"
#import "XMLControllerDCMTKCategory.h"
#include <zlib.h>
#import "DicomDatabase.h"
#import "RemoteDicomDatabase.h"
#import "N2Debug.h"

#ifdef OSIRIX_VIEWER
#import "DCMPix.h"
#import "SRAnnotation.h"
#import "VRController.h"
#import "browserController.h"
#import "BonjourBrowser.h"
#import "ThreadsManager.h"
#import "DCMView.h"
#import "AppController.h"
#endif

#define ROIDATABASE @"/ROIs/"

static inline int charToInt( unsigned char c)
{
	switch( c)
	{
		case 0:			return 0;		break;
		case '0':		return 1;		break;
		case '1':		return 2;		break;
		case '2':		return 3;		break;
		case '3':		return 4;		break;
		case '4':		return 5;		break;
		case '5':		return 6;		break;
		case '6':		return 7;		break;
		case '7':		return 8;		break;
		case '8':		return 9;		break;
		case '9':		return 10;		break;
		case '.':		return 11;		break;
	}
	
	return c % 12;
}

static inline unsigned char intToChar( int c)
{
	switch( c)
	{
		case 0:		return 0;		break;
		case 1:		return '0';		break;
		case 2:		return '1';		break;
		case 3:		return '2';		break;
		case 4:		return '3';		break;
		case 5:		return '4';		break;
		case 6:		return '5';		break;
		case 7:		return '6';		break;
		case 8:		return '7';		break;
		case 9:		return '8';		break;
		case 10:	return '9';		break;
		case 11:	return '.';		break;
	}
	
	return '0';
}

void* sopInstanceUIDEncode( NSString *sopuid)
{
	unsigned int	i, x;
	unsigned char	*r = malloc( 1024);
	
    if( r)
    {
        for( i = 0, x = 0; i < [sopuid length];)
        {
            unsigned char c1, c2;
            
            c1 = [sopuid characterAtIndex: i];
            i++;
            if( i == [sopuid length]) c2 = 0;
            else c2 = [sopuid characterAtIndex: i];
            i++;
            
            r[ x] = (charToInt( c1) << 4) + charToInt( c2);
            x++;
        }
	}
    
	return r;
}

NSString* sopInstanceUIDDecode( unsigned char *r, int length)
{
	unsigned int	i, x;
	char			str[ 1024];
	
	for( i = 0, x = 0; i < length; i++)
	{
		unsigned char c1, c2;
		
		c1 = r[ i] >> 4;
		c2 = r[ i] & 15;
		
		str[ x] = intToChar( c1);
		x++;
		str[ x] = intToChar( c2);
		x++;
	}
	
	str[ x ] = '\0';
	
	return [NSString stringWithCString:str encoding: NSASCIIStringEncoding];
}

@implementation NSData (OsiriX)

- (BOOL) isEqualToSopInstanceUID:(NSData*) sopInstanceUID
{
	NSUInteger length = [self length];
	if (length == 0)
		return NO;
	
	NSUInteger sopInstanceUIDLength = [sopInstanceUID length];
	if (sopInstanceUIDLength == 0)
		return NO;
	
	const UInt8* bytes = (const UInt8*) [self bytes];
	if( bytes[length-1] == 0)
		length --;
	
	const UInt8* sopInstanceUIDBytes = (const UInt8*) [sopInstanceUID bytes];
	if (sopInstanceUIDBytes[sopInstanceUIDLength-1] == 0)
		sopInstanceUIDLength --;
	
	if (length == sopInstanceUIDLength)
	{
		if (memcmp(bytes, sopInstanceUIDBytes, length) == 0)
			return YES;
	}
	
	return NO;
}
@end

@implementation DicomImage

@dynamic comment, comment2, comment3, comment4;
@dynamic compressedSopInstanceUID;
@dynamic date;
@dynamic frameID;
@dynamic instanceNumber;
@dynamic importedFile;
@dynamic pathNumber;
@dynamic pathString;
@dynamic rotationAngle;
@dynamic scale;
@dynamic sliceLocation;
@dynamic stateText;
@dynamic storedExtension;
@dynamic storedFileType;
@dynamic storedHeight;
@dynamic storedInDatabaseFolder;
@dynamic storedIsKeyImage;
@dynamic storedModality;
@dynamic storedMountedVolume;
@dynamic storedNumberOfFrames;
@dynamic storedNumberOfSeries;
@dynamic storedWidth;
@dynamic windowLevel;
@dynamic windowWidth;
@dynamic xFlipped;
@dynamic xOffset;
@dynamic yFlipped;
@dynamic yOffset;
@dynamic zoom;
@dynamic series;

- (BOOL) isDistant
{
    return NO;
}

-(id)copy
{
    id copy = [super copy];
    
    [copy setThumbnail: [[_thumbnail copy] autorelease]];
    
    return copy;
}

+ (NSData*) sopInstanceUIDEncodeString:(NSString*) s
{
	int length = [s length];
	length ++;
	length /= 2;
	
	return [NSData dataWithBytesNoCopy: sopInstanceUIDEncode( s) length: length freeWhenDone: YES];
}

- (NSString*) SRPath
{
	NSString *roiPath = [self SRPathForFrame: [self.frameID intValue]];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
		return roiPath;
	
	return nil;
}


- (NSString*) SRFilenameForFrame: (int) frameNo
{
	return [NSString stringWithFormat: @"%@-%d.dcm", [self uniqueFilename], frameNo];
}

- (NSString*) SRPathForFrame: (int) frameNo
{
	#ifdef OSIRIX_VIEWER
	NSString *d;
	
    DicomDatabase* db = [DicomDatabase databaseForContext:[self managedObjectContext]];
	if (![db isLocal])
		d = [db dataBaseDirPath];
	else
		d = [[db dataBaseDirPath] stringByAppendingPathComponent:ROIDATABASE];
	
	return [d stringByAppendingPathComponent: [self SRFilenameForFrame: frameNo]];
	#else
	return nil;
	#endif
}

- (NSString*) sopInstanceUID
{
    @synchronized (self) {
        if (sopInstanceUID)
            return sopInstanceUID;
    
//	char *ss = sopInstanceUIDEncode( @"1.3.6.1.4.1.19291.2.1.3.4214185015613178564241742949672953387242");
//	NSString* uid =  sopInstanceUIDDecode( [[NSData dataWithBytes: ss length: strlen( ss)+1] bytes]);
//	free( ss);
	
        NSData *data = [self primitiveValueForKey:@"compressedSopInstanceUID"];
        
        unsigned char* src =  (unsigned char*) [data bytes];
        
        if( src)
        {
            NSString* uid =  sopInstanceUIDDecode( src, [data length]);
            
            [sopInstanceUID release];
            sopInstanceUID = [uid retain];
        }
        else
        {
            [sopInstanceUID release];
            sopInstanceUID = nil;
        }
        
        return sopInstanceUID;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setSopInstanceUID: (NSString*) s
{
    @synchronized (self) {
        [sopInstanceUID release];
        sopInstanceUID = nil;

        if( s)
        {
            int length = [s length];
            length++;
            length /= 2;
            
            char *ss = sopInstanceUIDEncode( s);
            [self setValue: [NSData dataWithBytesNoCopy: ss length: length] forKey:@"compressedSopInstanceUID"];
            
    //		if( [[self sopInstanceUID] isEqualToString: s] == NO)
    //			NSLog(@"******** ERROR sopInstanceUID : %@ %@", s, [self sopInstanceUID]);
        }
        else [self setValue: nil forKey:@"compressedSopInstanceUID"];
    }
}

#pragma mark-

- (NSNumber*) inDatabaseFolder
{
    @synchronized (self) {
        if( inDatabaseFolder) return inDatabaseFolder;
        
        NSNumber *f = [self primitiveValueForKey:@"storedInDatabaseFolder"];
        
        if( f == nil) f = [NSNumber numberWithBool: YES];
        
        [inDatabaseFolder release];
        inDatabaseFolder = [f retain];

        return inDatabaseFolder;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setInDatabaseFolder:(NSNumber*) f
{
    @synchronized (self) {
        [inDatabaseFolder release];
        inDatabaseFolder = nil;
        
        [self willChangeValueForKey:@"storedInDatabaseFolder"];
        if( [f boolValue] == YES)	
            [self setPrimitiveValue: nil forKey:@"storedInDatabaseFolder"];
        else
            [self setPrimitiveValue: f forKey:@"storedInDatabaseFolder"];
        [self didChangeValueForKey:@"storedInDatabaseFolder"];
    }
}

#pragma mark-

-(void)_updateMetaData_size {
	DicomFile* df = [[DicomFile alloc] init:[self completePath]];
	[self setStoredWidth:[NSNumber numberWithLong:[df getWidth]]];
	[self setStoredHeight:[NSNumber numberWithLong:[df getHeight]]];
	[df release];
}

- (NSNumber*) height
{
	@synchronized (self) {
        if (height) return height;
        
        NSNumber* f = [self primitiveValueForKey:@"storedHeight"];
        if (f == nil) f = [NSNumber numberWithInt: 512];
        else if ([f integerValue] == OsirixDicomImageSizeUnknown) {
            [self _updateMetaData_size];
            f = [self primitiveValueForKey:@"storedHeight"];
        }
        
        [height release];
        height = [f retain];

        return height;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setHeight:(NSNumber*) f
{
	@synchronized (self) {
        [height release];
        height = nil;
        
        [self willChangeValueForKey:@"storedHeight"];
        if( [f intValue] == 512)	
            [self setPrimitiveValue: nil forKey:@"storedHeight"];
        else
            [self setPrimitiveValue: f forKey:@"storedHeight"];
        [self didChangeValueForKey:@"storedHeight"];
    }
}

#pragma mark-

- (NSNumber*) width
{
	@synchronized (self) {
        if (width) return width;
        
        NSNumber* f = [self primitiveValueForKey:@"storedWidth"];
        if (f == nil) f = [NSNumber numberWithInt: 512];
        else if ([f integerValue] == OsirixDicomImageSizeUnknown) {
            [self _updateMetaData_size];
            f = [self primitiveValueForKey:@"storedWidth"];
        }
        
        [width release];
        width = [f retain];

        return width;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setWidth:(NSNumber*) f
{
	@synchronized (self) {
        [width release];
        width = nil;
        
        [self willChangeValueForKey:@"storedWidth"];
        if( [f intValue] == 512)	
            [self setPrimitiveValue: nil forKey:@"storedWidth"];
        else
            [self setPrimitiveValue: f forKey:@"storedWidth"];
        [self didChangeValueForKey:@"storedWidth"];
    }
}

#pragma mark-

- (NSNumber*) numberOfFrames
{
	@synchronized (self) {
        if( numberOfFrames) return numberOfFrames;
        
        NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfFrames"];
        
        if( f == nil) f = [NSNumber numberWithInt: 1];

        [numberOfFrames release];
        numberOfFrames = [f retain];

        return numberOfFrames;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setNumberOfFrames:(NSNumber*) f
{
	@synchronized (self) {
        [numberOfFrames release];
        numberOfFrames = nil;

        [self willChangeValueForKey:@"storedNumberOfFrames"];
        if( [f intValue] == 1)	
            [self setPrimitiveValue: nil forKey:@"storedNumberOfFrames"];
        else
            [self setPrimitiveValue: f forKey:@"storedNumberOfFrames"];
        [self didChangeValueForKey:@"storedNumberOfFrames"];
    }
}

#pragma mark-

- (NSNumber*) numberOfSeries
{
	@synchronized (self) {
        if( numberOfSeries) return numberOfSeries;
        
        NSNumber *f = [self primitiveValueForKey:@"storedNumberOfSeries"];
        
        if( f == nil) f = [NSNumber numberWithInt: 1];

        [numberOfSeries release];
        numberOfSeries = [f retain];

        return numberOfSeries;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setNumberOfSeries:(NSNumber*) f
{
	@synchronized (self) {
        [numberOfSeries release];
        numberOfSeries = nil;
        
        [self willChangeValueForKey:@"storedNumberOfSeries"];
        if( [f intValue] == 1)	
            [self setPrimitiveValue: nil forKey:@"storedNumberOfSeries"];
        else
            [self setPrimitiveValue: f forKey:@"storedNumberOfSeries"];
        [self didChangeValueForKey:@"storedNumberOfSeries"];
    }
}

- (void) setSeries:(DicomSeries *)series
{
    [self willChangeValueForKey:@"series"];
    [self setPrimitiveValue: series forKey: @"series"];
    [self didChangeValueForKey:@"series"];
    
    [self.series.study setNumberOfImages: nil];
    [self.series setNumberOfImages: nil];
}

#pragma mark-

//- (NSNumber*) mountedVolume
//{
//	if( mountedVolume) return mountedVolume;
//	
//	NSNumber	*f = [self primitiveValueForKey:@"storedMountedVolume"];
//	
//	if( f == nil)  f = [NSNumber numberWithBool: NO];
//
//	[mountedVolume release];
//	mountedVolume = [f retain];
//
//	return mountedVolume;
//    return nil;
//}

//- (void) setMountedVolume:(NSNumber*) f
//{
//	[mountedVolume release];
//	mountedVolume = nil;
//	
//	[self willChangeValueForKey:@"storedMountedVolume"];
//	if( [f boolValue] == NO)
//		[self setPrimitiveValue: nil forKey:@"storedMountedVolume"];
//	else
//		[self setPrimitiveValue: f forKey:@"storedMountedVolume"];
//	[self didChangeValueForKey:@"storedMountedVolume"];
//}

#pragma mark-

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

- (NSNumber*) isImageStorage
{
    return [NSNumber numberWithBool: [DCMAbstractSyntaxUID isImageStorage: self.series.seriesSOPClassUID]];
}

- (NSNumber*) isKeyImage
{
	@synchronized (self) {
        if( isKeyImage) return isKeyImage;
        
        NSNumber *f = [self primitiveValueForKey:@"storedIsKeyImage"];
        
        if( f == nil)  f = [NSNumber numberWithBool: NO];

        [isKeyImage release];
        isKeyImage = [f retain];

        return isKeyImage;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setIsKeyImage:(NSNumber*) f
{
	@synchronized (self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [isKeyImage release];
        isKeyImage = nil;
        
        if( [f boolValue] != [[self primitiveValueForKey: @"storedIsKeyImage"] boolValue])
        {
            #ifdef OSIRIX_VIEWER
            #ifndef OSIRIX_LIGHT
            if( [self.series.study.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"]  && [[BrowserController currentBrowser] isBonjour: [self managedObjectContext]] == NO)
            {
                NSString *c = nil;
                
                if( [[self numberOfFrames] intValue] > 1)
                {
                    [[DicomStudy dbModifyLock] lock];
                    @try {
                        DCMObject *dcmObject = [[DCMObjectPixelDataImport alloc] initWithContentsOfFile: self.completePath decodingPixelData: NO];
                        
                        if( [dcmObject.attributes objectForKey: @"0028,6022"]) // DCM_FramesOfInterestDescription
                        {
                            int frame = [[self frameID] intValue];
                            
                            NSMutableArray *keyFrames = [NSMutableArray arrayWithArray: [[dcmObject.attributes objectForKey: @"0028,6022"] values]]; // DCM_FramesOfInterestDescription
                            
                            BOOL found = NO;
                            for( NSString *k in keyFrames)
                            {
                                if( [k intValue] == frame) // corresponding frame
                                {
                                    if( [f boolValue] == NO)
                                        [keyFrames removeObject: k];
                                        
                                    found = YES;
                                    break;
                                }
                            }
                            
                            if( [f boolValue] == YES && found == NO)
                                [keyFrames addObject: [[self frameID] stringValue]];
                            
                            c = [keyFrames componentsJoinedByString: @"\\"];
                        }
                        else
                        {
                            if( [f boolValue])
                                c = [[self frameID] stringValue];
                        }
                        
                        [dcmObject release];
                        
                        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObject: self.completePath], @"files", @"(0028,6022)", @"field", c, @"value", nil]; // c can be nil : it's important to have it at the end
                        
                        NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(dcmodifyThread:) object: dict] autorelease];
                        t.name = NSLocalizedString( @"Updating DICOM files...", nil);
                        [[ThreadsManager defaultManager] addThreadAndStart: t];
                    }
                    @catch (NSException* e) {
                        N2LogExceptionWithStackTrace(e);
                    }
                    @finally {
                        [[DicomStudy dbModifyLock] unlock];
                    }
                }
                else
                {
                    if( [f boolValue])
                        c = @"0"; // frame 0 is key image 
                        
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObject: self.completePath], @"files", @"(0028,6022)", @"field", c, @"value", nil]; // c can be nil : it's important to have it at the end

                    NSThread *t = [[[NSThread alloc] initWithTarget:self selector:@selector(dcmodifyThread:) object: dict] autorelease];
                    t.name = NSLocalizedString( @"Updating DICOM files...", nil);
                    [[ThreadsManager defaultManager] addThreadAndStart: t];
                }
            }
            #endif
            #endif
            
            NSNumber *previousValue = [self primitiveValueForKey: @"storedIsKeyImage"];
            
            [self willChangeValueForKey: @"storedIsKeyImage"];
            
            if( [f boolValue] == NO)
                [self setPrimitiveValue: nil forKey:@"storedIsKeyImage"];
            else
                [self setPrimitiveValue: f forKey:@"storedIsKeyImage"];
            
            [self didChangeValueForKey:@"storedIsKeyImage"];
            
            if( [f intValue] != [previousValue intValue])
                [[self valueForKeyPath: @"series.study"] archiveAnnotationsAsDICOMSR];
        }
        
        [pool release];
    }
}

#pragma mark-

- (NSString*) extension
{
    @synchronized (self) {
        if( extension) return extension;
        
        NSString *f = [self primitiveValueForKey:@"storedExtension"];
        
        if( f == 0 || [f isEqualToString:@""]) f = @"dcm";

        [extension release];
        extension = [f retain];

        return extension;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setExtension:(NSString*) f
{
    @synchronized (self) {
        [extension release];
        extension = nil;
        
        [self willChangeValueForKey:@"storedExtension"];
        if( [f isEqualToString:@"dcm"])
            [self setPrimitiveValue: nil forKey:@"storedExtension"];
        else
            [self setPrimitiveValue: f forKey:@"storedExtension"];
        [self didChangeValueForKey:@"storedExtension"];
    }
}

#pragma mark-

- (NSString*) modality
{
    @synchronized (self) {
        if( modality) return modality;
        
        NSString *f = [self primitiveValueForKey:@"storedModality"];
        
        if( f == 0 || [f isEqualToString:@""]) f = @"CT";

        [modality release];
        modality = [f retain];

        return modality;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setModality:(NSString*) f
{
    @synchronized (self) {
        [modality release];
        modality = nil;
        
        [self willChangeValueForKey:@"storedModality"];
        if( [f isEqualToString:@"CT"])
            [self setPrimitiveValue: nil forKey:@"storedModality"];
        else
            [self setPrimitiveValue: f forKey:@"storedModality"];
        [self didChangeValueForKey:@"storedModality"];
    }
}

#pragma mark-

- (NSString*) fileType
{
    @synchronized (self) {
        if( fileType) return fileType;
        
        NSString *f = [self primitiveValueForKey:@"storedFileType"];
        
        if( f == 0 || [f isEqualToString:@""]) f =  @"DICOM";
        
        [fileType release];
        fileType = [f retain];

        return fileType;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (void) setFileType:(NSString*) f
{
    @synchronized (self) {
        [fileType release];
        fileType = nil;
        
        [self willChangeValueForKey:@"storedFileType"];
        if( [f isEqualToString:@"DICOM"])
            [self setPrimitiveValue: nil forKey:@"storedFileType"];
        else
            [self setPrimitiveValue: f forKey:@"storedFileType"];
        [self didChangeValueForKey:@"storedFileType"];
    }
}

#pragma mark-

- (void) setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (NSString*) name
{
	return nil;
}

- (id) valueForUndefinedKey:(NSString *)key
{
	id value = [DicomFile getDicomField: key forFile: [self completePath]];

	if( value) return value;
	
	return [super valueForUndefinedKey: key];
}

- (void) setDate:(NSDate*) date
{
    @synchronized (self) {
        [dicomTime release];
        dicomTime = nil;
        
        [self willChangeValueForKey:@"date"];
        [self setPrimitiveValue: date forKey:@"date"];
        [self didChangeValueForKey:@"date"];
    }
}

- (NSNumber*) dicomTime
{
    @synchronized (self) {
        if( dicomTime) return dicomTime;
        
        dicomTime = [[[DCMCalendarDate dicomTimeWithDate:self.date] timeAsNumber] retain];
        
        return dicomTime;
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

- (NSString*) type
{
	return  @"Image";
}

- (void) dealloc
{
    [self didTurnIntoFault];
	[super dealloc];
}

-(NSString*) uniqueFilename	// Return a 'unique' filename that identify this image...
{
	return [NSString stringWithFormat:@"%@ %@",self.sopInstanceUID, self.instanceNumber];
}

+ (NSString*) completePathForLocalPath:(NSString*) path directory:(NSString*) directory
{
	if( [path characterAtIndex: 0] != '/')
	{
		long		val = [[path stringByDeletingPathExtension] intValue];
		NSString	*dbLocation = [directory stringByAppendingPathComponent: @"DATABASE.noindex"];
		
		val /= [BrowserController DefaultFolderSizeForDB];
		val++;
		val *= [BrowserController DefaultFolderSizeForDB];
		
		return [[dbLocation stringByAppendingPathComponent: [NSString stringWithFormat: @"%d", (int) val]] stringByAppendingPathComponent: path];
	}
	else return path;
}

- (NSString*) path
{
	NSNumber *pathNumber = [self primitiveValueForKey: @"pathNumber"];
	
	if( pathNumber)
		return [NSString stringWithFormat:@"%d.dcm", [pathNumber intValue]];
	else return [self primitiveValueForKey: @"pathString"];
}

- (void) setPath:(NSString*) p
{
    [self didTurnIntoFault];
    
	if( [p characterAtIndex: 0] != '/')
	{
		if( [[p pathExtension] isEqualToString:@"dcm"])
		{
			[self willChangeValueForKey: @"pathNumber"];
			[self setPrimitiveValue: [NSNumber numberWithInt: [p intValue]] forKey:@"pathNumber"];
			[self didChangeValueForKey: @"pathNumber"];
			
			[self willChangeValueForKey: @"pathString"];
			[self setPrimitiveValue: nil forKey:@"pathString"];
			[self didChangeValueForKey: @"pathString"];
			
			return;
		}
	}
	[self willChangeValueForKey: @"pathNumber"];
	[self setPrimitiveValue: nil forKey:@"pathNumber"];
	[self didChangeValueForKey: @"pathNumber"];
	
	[self willChangeValueForKey: @"pathString"];
	[self setPrimitiveValue: p forKey:@"pathString"];
	[self didChangeValueForKey: @"pathString"];
}

- (void)didTurnIntoFault
{
	[dicomTime release]; dicomTime = nil;
	[sopInstanceUID release];  sopInstanceUID = nil;
	[inDatabaseFolder release];  inDatabaseFolder = nil;
	[height release];  height = nil;
	[width release];  width = nil;
	[numberOfFrames release];  numberOfFrames = nil;
	[numberOfSeries release];  numberOfSeries = nil;
	[isKeyImage release];  isKeyImage = nil;
	[extension release];  extension = nil;
	[modality release];  modality = nil;
	[fileType release];  fileType = nil;
	[completePathCache release]; completePathCache = nil;
    [_thumbnail release]; _thumbnail = nil;
}

-(NSString*) completePathWithDownload:(BOOL) download supportNonLocalDatabase: (BOOL) supportNonLocalDatabase
{
    @try
    {
        if( completePathCache && download == NO)
            return completePathCache;
        
        DicomDatabase* db = [DicomDatabase databaseForContext: self.managedObjectContext];
        
        BOOL isLocal = YES;
        if (supportNonLocalDatabase)
            isLocal = [db isLocal];
        
        if (completePathCache) {
            if (download == NO)
                return completePathCache;
            else if (isLocal)
                return completePathCache;
        }
        
        #ifdef OSIRIX_VIEWER
        if( [self.inDatabaseFolder boolValue] == YES)
        {
            NSString *path = self.path;
            
            if( !isLocal)
            {
                NSString* temp = [DicomImage completePathForLocalPath:path directory:db.dataBaseDirPath];
                if ([[NSFileManager defaultManager] fileExistsAtPath:temp])
                    return temp;
                
                [completePathCache release];
                
                if (download)
                    completePathCache = [[(RemoteDicomDatabase*)db cacheDataForImage:self maxFiles:1] retain];
                else
                    completePathCache = [[(RemoteDicomDatabase*)db localPathForImage:self] retain];
                
                return completePathCache;
            }
            else
            {
                if( [path characterAtIndex: 0] != '/')
                {
                    [completePathCache release];
                    completePathCache = [[DicomImage completePathForLocalPath: path directory: db.dataBaseDirPath] retain];
                    return completePathCache;
                }
            }
        }
        #endif
        
        return self.path;
    }
    @catch (NSException *e) {
        N2LogExceptionWithStackTrace(e);
    }
    
    return nil; // to resolve a compiler warning: this line never executes
}

-(NSString*) completePathWithDownload:(BOOL) download
{
    return [self completePathWithDownload: download supportNonLocalDatabase: YES];
}

-(NSString*) completePathResolved
{
	return [self completePathWithDownload: YES];
}

-(NSString*) completePathWithNoDownloadAndLocalOnly
{
    return [self completePathWithDownload: NO supportNonLocalDatabase: NO];
}

-(NSString*) completePath
{
	return [self completePathWithDownload: NO];
}

- (BOOL)validateForDelete:(NSError **)error
{
    BOOL delete = [super validateForDelete: error];
    
    @synchronized (self)
    {
        if (delete)
        {
            #ifdef OSIRIX_VIEWER
            if( [self.inDatabaseFolder boolValue] == YES)
            {
                [[BrowserController currentBrowser] addFileToDeleteQueue: self.completePath];
                
                if( [[self.path pathExtension] isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
                    [[BrowserController currentBrowser] addFileToDeleteQueue: [[self.completePath stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
                
                self.inDatabaseFolder = [NSNumber numberWithBool: NO];
            }
            #endif
        }
    }
    
    return delete;
}

- (NSSet *)paths
{
	return [NSSet setWithObject:[self completePath]];
}

- (NSSet *)pathsForForkedProcess
{
	return [NSSet setWithObject:[self completePathWithNoDownloadAndLocalOnly]];
}

#ifndef OSIRIX_LIGHT
// DICOM Presentation State
- (DCMSequenceAttribute *)graphicAnnotationSequence
{
	//main sequnce that includes the graphics overlays : ROIs and annotation
	DCMSequenceAttribute *graphicAnnotationSequence = [DCMSequenceAttribute sequenceAttributeWithName:@"GraphicAnnotationSequence"];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//need the original file to get SOPClassUID and possibly SOPInstanceUID
	DCMObject *imageObject = [DCMObject objectWithContentsOfFile:[self primitiveValueForKey:@"completePath"] decodingPixelData:NO];
	
	//ref image sequence only has one item.
	DCMSequenceAttribute *refImageSequence = [DCMSequenceAttribute sequenceAttributeWithName:@"ReferencedImageSequence"];
	DCMObject *refImageObject = [DCMObject dcmObject];
	[refImageObject setAttributeValues:[self primitiveValueForKey:@"sopInstanceUID"] forName:@"ReferencedSOPInstanceUID"];
	[refImageObject setAttributeValues:[[imageObject attributeValueWithName:@"SOPClassUID"] values] forName:@"ReferencedSOPClassUID"];
	// may need to add references frame number if we add a frame object  Nothing here yet.
	
	[refImageSequence addItem:refImageObject];
	
	// Some basic graphics info
	
	DCMAttribute *graphicAnnotationUnitsAttr = [DCMAttribute attributeWithAttributeTag:[DCMAttributeTag tagWithName:@"GraphicAnnotationUnits"]];
	[graphicAnnotationUnitsAttr setValues:[NSMutableArray arrayWithObject:@"PIXEL"]];
	
	//loop through the ROIs and add
	NSSet *rois = [self primitiveValueForKey:@"rois"];
	id roi;
	for (roi in rois)
	{
		//will be either a Graphic Object sequence or a Text Object Sequence
		ToolMode roiType = (ToolMode)[[roi valueForKey:@"roiType"] intValue];
		NSString *typeString = nil;
		if (roiType == tText)
		{// is text 
		}
		else // is a graphic
		{
			switch (roiType)
			{
				case tOval:
					typeString = @"ELLIPSE";
					break;
				case tOPolygon:
				case tCPolygon:
					typeString = @"POLYLINE";
					break;
                default:;
			}
		}
		
	}	
	[pool release];
	 return graphicAnnotationSequence;
}
#endif

- (NSImage *)image
{
#ifdef OSIRIX_VIEWER
    @synchronized (self) {
        DCMPix *pix = [[DCMPix alloc] initWithPath:self.completePath :0 :0 :nil :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
        NSData	*data = [[pix image] TIFFRepresentation];
        NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];

        [pix release];
        return thumbnail;
    }
#endif
    return nil;
}

- (NSImage *)thumbnail
{
#ifdef OSIRIX_VIEWER
    @synchronized (self) {
        if (_thumbnail)
            return _thumbnail;
        DCMPix *pix = [[DCMPix alloc] initWithPath:self.completePath :0 :0 :nil :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
        NSData	*data = [[pix generateThumbnailImageWithWW:0 WL:0] TIFFRepresentation];
        NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];
        [pix release];
        return thumbnail;
    }
#endif
    return nil;
}

-(NSImage*) imageAsScreenCapture:(NSRect)frame
{
    if( [NSThread isMainThread] == NO)
    {
        N2LogStackTrace( @"****** this function works only on MAIN thread");
        return nil;
    }
    
    NSImage *renderedImage = nil;
    
    #ifdef OSIRIX_VIEWER
    @try
    {
        DCMPix* pix = [[DCMPix alloc] initWithPath: self.completePath :0 :0 :nil :self.frameID.intValue :self.series.id.intValue isBonjour:NO imageObj: self];
        
        [pix CheckLoad];
        
        NSWindow* win = [[NSWindow alloc] initWithContentRect:frame styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        DicomImage* roisImage = [self.series.study roiForImage:self inArray:nil];
        NSArray* rois = roisImage? [NSUnarchiver unarchiveObjectWithData:[SRAnnotation roiFromDICOM:[roisImage completePath]]] : nil;
        
        DCMView* view = [[DCMView alloc] initWithFrame:frame imageRows:self.height.intValue imageColumns:self.width.intValue];
        [view setPixels:[NSMutableArray arrayWithObject:pix] files:[NSMutableArray arrayWithObject:self] rois:(rois? [NSMutableArray arrayWithObject:rois] : nil) firstImage:0 level:'i' reset:YES];
        [win.contentView addSubview:view];
        [view drawRect:frame];
        
        renderedImage = [view nsimage];
        
        [view removeFromSuperview];
        [view release];
        [win release];
        [pix release];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    #endif
    
    return renderedImage;
}

-(NSDictionary*) imageAsDICOMScreenCapture:(DICOMExport*) exporter
{
    if( [NSThread isMainThread] == NO)
    {
        N2LogStackTrace( @"****** this function works only on MAIN thread");
        return nil;
    }
    
    NSDictionary *dicomImage = nil;
    
#ifdef OSIRIX_VIEWER
    @try
    {
        DCMPix* pix = [[DCMPix alloc] initWithPath: self.completePath :0 :0 :nil :self.frameID.intValue :self.series.id.intValue isBonjour:NO imageObj: self];
        
        [pix CheckLoad];
        
        if( pix.pwidth && pix.pheight)
        {
            NSRect frame = NSMakeRect( 0, 0, pix.pwidth, pix.pheight);
            
            // Not smaller than @"DicomImageScreenCapture" prefs
            frame.size.height = MAX( frame.size.height, [[NSUserDefaults standardUserDefaults] integerForKey: @"DicomImageScreenCaptureHeight"]);
            frame.size.width = MAX( frame.size.width, [[NSUserDefaults standardUserDefaults] integerForKey: @"DicomImageScreenCaptureWidth"]);
            
            // Not larger than a screen
            NSRect viewerRect = [[[[AppController sharedAppController] viewerScreens] lastObject] frame];
            frame.size.height = MIN( frame.size.height, viewerRect.size.height);
            frame.size.width = MIN( frame.size.width, viewerRect.size.width);
            
            NSWindow* win = [[NSWindow alloc] initWithContentRect:frame styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
            
            DicomImage* roisImage = [self.series.study roiForImage:self inArray:nil];
            NSArray* rois = roisImage? [NSUnarchiver unarchiveObjectWithData:[SRAnnotation roiFromDICOM:[roisImage completePath]]] : nil;
            
            DCMView* view = [[DCMView alloc] initWithFrame:frame imageRows:self.height.intValue imageColumns:self.width.intValue];
            view.annotationType = annotGraphics;
            [view setPixels:[NSMutableArray arrayWithObject:pix] files:[NSMutableArray arrayWithObject:self] rois:(rois? [NSMutableArray arrayWithObject:rois] : nil) firstImage:0 level:'i' reset:YES];
            [win.contentView addSubview:view];
            
            [view setCOPYSETTINGSINSERIESdirectly: NO];
            [view updatePresentationStateFromSeriesOnlyImageLevel: NO scale: YES offset: YES];
            [view drawRect:frame];
            
            int size = frame.size.width > frame.size.height ? frame.size.width : frame.size.height;
            
            dicomImage = [view exportDCMCurrentImage: exporter size: size];
            
            [view removeFromSuperview];
            [view release];
            [win release];
        }
        
        [pix release];
    }
    @catch (NSException* e)
    {
        N2LogExceptionWithStackTrace(e);
    }
#endif
    
    return dicomImage;
}

-(NSImage*)thumbnailIfAlreadyAvailable {
#ifdef OSIRIX_VIEWER
    return _thumbnail;
#endif
    return nil;
}

- (void)setThumbnail:(NSImage*)image {
#ifdef OSIRIX_VIEWER
    @synchronized (self) {
        if (image != _thumbnail) {
            [_thumbnail release];
            _thumbnail = [image retain];
        }
    }
#endif
}

- (NSString*) description
{
	NSString *result = [super description];
	return [result stringByAppendingFormat:@"\rdicomTime: %@\rsopInstanceUID: %@", [self dicomTime], [self sopInstanceUID]];
}

+(NSMutableArray*)dicomImagesInObjects:(NSArray*)objects {
	NSMutableArray* dicomImages = [NSMutableArray array];
	
	for (NSManagedObject* object in objects) {
		if ([[object valueForKey:@"type"] isEqualToString:@"Study"])
			for( NSManagedObject *curSerie in [object valueForKey:@"series"])
				[dicomImages addObjectsFromArray: [[curSerie valueForKey:@"images"] allObjects]];
		
		if ([[object valueForKey:@"type"] isEqualToString:@"Series"])
			[dicomImages addObjectsFromArray: [[object valueForKey:@"images"] allObjects]];
		
		if ([[object valueForKey:@"type"] isEqualToString:@"Image"])
			[dicomImages addObject:object];
	}

	return dicomImages;
}


@end
