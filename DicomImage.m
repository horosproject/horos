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

#import "DicomImage.h"
#import <OsiriX/DCM.h>
#import "DCMView.h"

#ifdef OSIRIX_VIEWER
#import "DCMPix.h"
#import "VRController.h"
#import "browserController.h"
#import "BonjourBrowser.h"
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
	
	r[ x] = 0;
	
	return r;
}

NSString* sopInstanceUIDDecode( unsigned char *r)
{
	unsigned int	i, x, length = strlen( (char *) r);
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

@implementation DicomImage

+ (NSString*) sopInstanceUIDEncodeString:(NSString*) s
{
	return [NSString stringWithUTF8String: sopInstanceUIDEncode( s)];
}

- (NSArray*) SRPaths
{
	NSMutableArray	*roiFiles = [NSMutableArray array];
	int	noOfFrames = [[self valueForKey: @"numberOfFrames"] intValue], x;
	
	for( x = 0; x < noOfFrames; x++)
	{
		NSString	*roiPath = [self SRPathForFrame: x];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
			[roiFiles addObject: roiPath];
	}
	
	return roiFiles;
}

- (NSArray*) SRFilenames
{
	NSMutableArray	*roiFiles = [NSMutableArray array];
	int	noOfFrames = [[self valueForKey: @"numberOfFrames"] intValue], x;
	
	for( x = 0; x < noOfFrames; x++)
	{
		NSString	*roiPath = [self SRFilenameForFrame: x];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
			[roiFiles addObject: roiPath];
	}
	
	return roiFiles;
}

- (NSString*) SRFilenameForFrame: (int) frameNo
{
	return [NSString stringWithFormat: @"%@-%d.dcm", [self uniqueFilename], frameNo];
}

- (NSString*) SRPathForFrame: (int) frameNo
{
	#ifdef OSIRIX_VIEWER
	NSString	*documentsDirectory = [[[BrowserController currentBrowser] fixedDocumentsDirectory] stringByAppendingPathComponent:ROIDATABASE];
	
	return [documentsDirectory stringByAppendingPathComponent: [self SRFilenameForFrame: frameNo]];
	#else
	return 0L;
	#endif
}

- (NSString*) sopInstanceUID
{
	if( sopInstanceUID) return sopInstanceUID;
	
//	char *ss = sopInstanceUIDEncode( @"1.3.6.1.4.1.19291.2.1.3.4214185015613178564241742949672953387242");
//	NSString* uid =  sopInstanceUIDDecode( [[NSData dataWithBytes: ss length: strlen( ss)+1] bytes]);
//	free( ss);
	
	unsigned char* src =  (unsigned char*) [[self primitiveValueForKey:@"compressedSopInstanceUID"] bytes];
	
	if( src)
	{
		NSString* uid =  sopInstanceUIDDecode( src);
		
		[sopInstanceUID release];
		sopInstanceUID = [uid retain];
	}
	else
	{
		[sopInstanceUID release];
		sopInstanceUID = 0L;
	}
	
	return sopInstanceUID;
}

- (void) setSopInstanceUID: (NSString*) s
{
	[sopInstanceUID release];
	sopInstanceUID = 0L;

	if( s)
	{
		char *ss = sopInstanceUIDEncode( s);
		[self setValue: [NSData dataWithBytes: ss length: strlen( ss)+1] forKey:@"compressedSopInstanceUID"];
		free( ss);
		
//		if( [[self sopInstanceUID] isEqualToString: s] == NO)
//			NSLog(@"******** ERROR sopInstanceUID : %@ %@", s, [self sopInstanceUID]);
	}
	else [self setValue: 0L forKey:@"compressedSopInstanceUID"];
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

#pragma mark-

- (NSNumber*) inDatabaseFolder
{
	if( inDatabaseFolder) return inDatabaseFolder;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedInDatabaseFolder"];
	
	if( f == 0L) f = [NSNumber numberWithBool: YES];
	
	[inDatabaseFolder release];
	inDatabaseFolder = [f retain];

	return inDatabaseFolder;
}

- (void) setInDatabaseFolder:(NSNumber*) f
{
	[inDatabaseFolder release];
	inDatabaseFolder = 0L;
	
	[self willChangeValueForKey:@"storedInDatabaseFolder"];
	if( [f boolValue] == YES)	
		[self setPrimitiveValue: 0L forKey:@"storedInDatabaseFolder"];
	else
		[self setPrimitiveValue: f forKey:@"storedInDatabaseFolder"];
	[self didChangeValueForKey:@"storedInDatabaseFolder"];
}

#pragma mark-

- (NSNumber*) height
{
	if( height) return height;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedHeight"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 512];
	
	[height release];
	height = [f retain];

	return height;
}

- (void) setHeight:(NSNumber*) f
{
	[height release];
	height = 0L;
	
	[self willChangeValueForKey:@"storedHeight"];
	if( [f intValue] == 512)	
		[self setPrimitiveValue: 0L forKey:@"storedHeight"];
	else
		[self setPrimitiveValue: f forKey:@"storedHeight"];
	[self didChangeValueForKey:@"storedHeight"];
}

#pragma mark-

- (NSNumber*) width
{
	if( width) return width;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedWidth"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 512];
	
	[width release];
	width = [f retain];

	return width;
}

- (void) setWidth:(NSNumber*) f
{
	[width release];
	width = 0L;
	
	[self willChangeValueForKey:@"storedWidth"];
	if( [f intValue] == 512)	
		[self setPrimitiveValue: 0L forKey:@"storedWidth"];
	else
		[self setPrimitiveValue: f forKey:@"storedWidth"];
	[self didChangeValueForKey:@"storedWidth"];
}

#pragma mark-

- (NSNumber*) numberOfFrames
{
	if( numberOfFrames) return numberOfFrames;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfFrames"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 1];

	[numberOfFrames release];
	numberOfFrames = [f retain];

	return numberOfFrames;
}

- (void) setNumberOfFrames:(NSNumber*) f
{
	[numberOfFrames release];
	numberOfFrames = 0L;
	
	[self willChangeValueForKey:@"storedNumberOfFrames"];
	if( [f intValue] == 1)	
		[self setPrimitiveValue: 0L forKey:@"storedNumberOfFrames"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfFrames"];
	[self didChangeValueForKey:@"storedNumberOfFrames"];
}

#pragma mark-

- (NSNumber*) numberOfSeries
{
	if( numberOfSeries) return numberOfSeries;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfSeries"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 1];

	[numberOfSeries release];
	numberOfSeries = [f retain];

	return numberOfSeries;
}

- (void) setNumberOfSeries:(NSNumber*) f
{
	[numberOfSeries release];
	numberOfSeries = 0L;
	
	[self willChangeValueForKey:@"storedNumberOfSeries"];
	if( [f intValue] == 1)	
		[self setPrimitiveValue: 0L forKey:@"storedNumberOfSeries"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfSeries"];
	[self didChangeValueForKey:@"storedNumberOfSeries"];
}

#pragma mark-

- (NSNumber*) mountedVolume
{
	if( mountedVolume) return mountedVolume;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedMountedVolume"];
	
	if( f == 0L)  f = [NSNumber numberWithBool: NO];

	[mountedVolume release];
	mountedVolume = [f retain];

	return mountedVolume;
}

- (void) setMountedVolume:(NSNumber*) f
{
	[mountedVolume release];
	mountedVolume = 0L;
	
	[self willChangeValueForKey:@"storedMountedVolume"];
	if( [f boolValue] == NO)
		[self setPrimitiveValue: 0L forKey:@"storedMountedVolume"];
	else
		[self setPrimitiveValue: f forKey:@"storedMountedVolume"];
	[self didChangeValueForKey:@"storedMountedVolume"];
}

#pragma mark-

- (NSNumber*) isKeyImage
{
	if( isKeyImage) return isKeyImage;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedIsKeyImage"];
	
	if( f == 0L)  f = [NSNumber numberWithBool: NO];

	[isKeyImage release];
	isKeyImage = [f retain];

	return isKeyImage;
}

- (void) setIsKeyImage:(NSNumber*) f
{
	[isKeyImage release];
	isKeyImage = 0L;
	
	[self willChangeValueForKey:@"storedIsKeyImage"];
	if( [f boolValue] == NO)
		[self setPrimitiveValue: 0L forKey:@"storedIsKeyImage"];
	else
		[self setPrimitiveValue: f forKey:@"storedIsKeyImage"];
	[self didChangeValueForKey:@"storedIsKeyImage"];
}

#pragma mark-

- (NSString*) extension
{
	if( extension) return extension;
	
	NSString	*f = [self primitiveValueForKey:@"storedExtension"];
	
	if( f == 0 || [f isEqualToString:@""]) f = [NSString stringWithString: @"dcm"];

	[extension release];
	extension = [f retain];

	return extension;
}

- (void) setExtension:(NSString*) f
{
	[extension release];
	extension = 0L;
	
	[self willChangeValueForKey:@"storedExtension"];
	if( [f isEqualToString:@"dcm"])
		[self setPrimitiveValue: 0L forKey:@"storedExtension"];
	else
		[self setPrimitiveValue: f forKey:@"storedExtension"];
	[self didChangeValueForKey:@"storedExtension"];
}

#pragma mark-

- (NSString*) modality
{
	if( modality) return modality;
	
	NSString	*f = [self primitiveValueForKey:@"storedModality"];
	
	if( f == 0 || [f isEqualToString:@""]) f = [NSString stringWithString: @"CT"];

	[modality release];
	modality = [f retain];

	return modality;
}

- (void) setModality:(NSString*) f
{
	[modality release];
	modality = 0L;
	
	[self willChangeValueForKey:@"storedModality"];
	if( [f isEqualToString:@"CT"])
		[self setPrimitiveValue: 0L forKey:@"storedModality"];
	else
		[self setPrimitiveValue: f forKey:@"storedModality"];
	[self didChangeValueForKey:@"storedModality"];
}

#pragma mark-

- (NSString*) fileType
{
	if( fileType) return fileType;
	
	NSString	*f = [self primitiveValueForKey:@"storedFileType"];
	
	if( f == 0 || [f isEqualToString:@""]) f =  [NSString stringWithString: @"DICOM"];
	
	[fileType release];
	fileType = [f retain];

	return fileType;
}

- (void) setFileType:(NSString*) f
{
	[fileType release];
	fileType = 0L;
	
	[self willChangeValueForKey:@"storedFileType"];
	if( [f isEqualToString:@"DICOM"])
		[self setPrimitiveValue: 0L forKey:@"storedFileType"];
	else
		[self setPrimitiveValue: f forKey:@"storedFileType"];
	[self didChangeValueForKey:@"storedFileType"];
}

#pragma mark-

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return 0L;
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = 0L;
	
	[self willChangeValueForKey:@"date"];
	[self setPrimitiveValue: date forKey:@"date"];
	[self didChangeValueForKey:@"date"];
}

- (NSNumber*) dicomTime
{
	if( dicomTime) return dicomTime;
	
	dicomTime = [[[DCMCalendarDate dicomTimeWithDate:[self valueForKey: @"date"]] timeAsNumber] retain];
	
	return dicomTime;
}

- (NSString*) type
{
	return  [NSString stringWithString: @"Image"];
}

//- (void)willSave
//{
//	if( [self isDeleted] == NO)
//	{
//		if( mxOffset) [self setPrimitiveValue: xOffset forKey:@"xOffset"];
//		if( myOffset) [self setPrimitiveValue: yOffset forKey:@"yOffset"];
//		if( mscale) [self setPrimitiveValue: scale forKey:@"scale"];
//		if( mrotationAngle) [self setPrimitiveValue: rotationAngle forKey:@"rotationAngle"];
//		if( mwindowLevel) [self setPrimitiveValue: windowLevel forKey:@"windowLevel"];
//		if( mwindowWidth) [self setPrimitiveValue: windowWidth forKey:@"windowWidth"];
//		if( mxFlipped) [self setPrimitiveValue: xFlipped forKey:@"xFlipped"];
//		if( myFlipped) [self setPrimitiveValue: yFlipped forKey:@"yFlipped"];
//		
//		mxOffset = NO;
//		myOffset = NO;
//		mscale = NO;
//		mrotationAngle = NO;
//		mwindowLevel = NO;
//		mwindowWidth = NO;
//		myFlipped = NO;
//		mxFlipped = NO;
//	}
//}

- (void) dealloc
{
	[dicomTime release];
	[sopInstanceUID release];
	[inDatabaseFolder release];
	[height release];
	[width release];
	[numberOfFrames release];
	[numberOfSeries release];
	[mountedVolume release];
	[isKeyImage release];
	[extension release];
	[modality release];
	[fileType release];
	
	[completePathCache release];
	
//	[xFlipped release];
//	[yFlipped release];
//	[windowLevel release];
//	[windowWidth release];
//	[scale release];
//	[rotationAngle release];
//	[xOffset release];
//	[yOffset release];
	
	[super dealloc];
}

-(NSString*) uniqueFilename	// Return a 'unique' filename that identify this image...
{
	return [NSString stringWithFormat:@"%@ %@",[self valueForKey:@"sopInstanceUID"], [self valueForKey:@"instanceNumber"]];
}

- (void) clearCompletePathCache
{
	[completePathCache release];
	completePathCache = 0L;
}

+ (NSString*) completePathForLocalPath:(NSString*) path directory:(NSString*) directory
{
	if( [path characterAtIndex: 0] != '/')
	{
		NSString	*extension = [path pathExtension];
		long		val = [[path stringByDeletingPathExtension] intValue];
		NSString	*dbLocation = [directory stringByAppendingPathComponent: @"DATABASE"];
		
		val /= 10000;
		val++;
		val *= 10000;
		
		return [[dbLocation stringByAppendingPathComponent: [NSString stringWithFormat: @"%d", val]] stringByAppendingPathComponent: path];
	}
	else return path;
}

- (NSString*) path
{
	NSNumber	*pathNumber = [self primitiveValueForKey: @"pathNumber"];
	
	if( pathNumber)
	{
		return [NSString stringWithFormat:@"%d.dcm", [pathNumber intValue]];
	}
	else return [self primitiveValueForKey: @"pathString"];
}

- (void) setPath:(NSString*) p
{
	if( [p characterAtIndex: 0] != '/')
	{
		if( [[p pathExtension] isEqualToString:@"dcm"])
		{
			[self willChangeValueForKey: @"pathNumber"];
			[self setPrimitiveValue: [NSNumber numberWithInt: [p intValue]] forKey:@"pathNumber"];
			[self didChangeValueForKey: @"pathNumber"];
			
			[self willChangeValueForKey: @"pathString"];
			[self setPrimitiveValue: 0L forKey:@"pathString"];
			[self didChangeValueForKey: @"pathString"];
			
			return;
		}
	}
	[self willChangeValueForKey: @"pathNumber"];
	[self setPrimitiveValue: 0L forKey:@"pathNumber"];
	[self didChangeValueForKey: @"pathNumber"];
	
	[self willChangeValueForKey: @"pathString"];
	[self setPrimitiveValue: p forKey:@"pathString"];
	[self didChangeValueForKey: @"pathString"];
}

-(NSString*) completePathWithDownload:(BOOL) download
{
	if( completePathCache) return completePathCache;
	
	#ifdef OSIRIX_VIEWER
	if( [[self valueForKey:@"inDatabaseFolder"] boolValue] == YES)
	{
		NSString			*path = [self valueForKey:@"path"];
		BrowserController	*cB = [BrowserController currentBrowser];
		
		if( [cB isCurrentDatabaseBonjour])
		{
			if( download)
				completePathCache = [[[cB bonjourBrowser] getDICOMFile: [cB currentBonjourService] forObject: self noOfImages: 1] retain];
			else
				completePathCache = [[BonjourBrowser uniqueLocalPath: self] retain];
			
			return completePathCache;
		}
		else
		{
			if( [path characterAtIndex: 0] != '/')
			{
				completePathCache = [[DicomImage completePathForLocalPath: path directory: [cB fixedDocumentsDirectory]] retain];
				return completePathCache;
			}
		}
	}
	#endif
	
	return [self valueForKey:@"path"];
}

-(NSString*) completePathResolved
{
	return [self completePathWithDownload: YES];
}

-(NSString*) completePath
{
	return [self completePathWithDownload: NO];
}

- (BOOL)validateForDelete:(NSError **)error
{
	BOOL delete = [super validateForDelete:(NSError **)error];
	if (delete)
	{
		#ifdef OSIRIX_VIEWER
		if( [[self valueForKey:@"inDatabaseFolder"] boolValue] == YES)
		{
			[[BrowserController currentBrowser] addFileToDeleteQueue: [self valueForKey:@"completePath"]];
			
			NSString *pathExtension = [[self valueForKey:@"path"] pathExtension];
			
			if( [pathExtension isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
			{
				[[BrowserController currentBrowser] addFileToDeleteQueue: [[[self valueForKey:@"completePath"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
			}
			else if([pathExtension isEqualToString:@"zip"])		// ZIP -> DELETE XML
			{
				[[BrowserController currentBrowser] addFileToDeleteQueue: [[[self valueForKey:@"completePath"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
			}
			
			[self setValue:[NSNumber numberWithBool:NO] forKey:@"inDatabaseFolder"];
		}
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: [VRController getUniqueFilenameScissorStateFor: self]])
		{
			[[NSFileManager defaultManager] removeFileAtPath: [VRController getUniqueFilenameScissorStateFor: self] handler: 0L];
		}
		
//		// Delete the associated ROIs
//		NSArray	*ROIsPaths = [self SRPaths];
//		if( [ROIsPaths count])
//		{
//			int i;
//			for( i = 0 ; i < [ROIsPaths count]; i++) [[NSFileManager defaultManager] removeFileAtPath:[ROIsPaths objectAtIndex: i] handler:0L];
//		}
		#endif
	}
	return delete;
}

- (NSSet *)paths{
	return [NSSet setWithObject:[self completePath]];
}

// DICOM Presentation State
- (DCMSequenceAttribute *)graphicAnnotationSequence{
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
	for (roi in rois){
		//will be either a Graphic Object sequence or a Text Object Sequence
		int roiType = [[roi valueForKey:@"roiType"] intValue];
		NSString *typeString = nil;
		if (roiType == tText) {// is text 
		}
		else // is a graphic
		{
			switch (roiType) {
				case tOval:
					typeString = @"ELLIPSE";
					break;
				case tOPolygon:
				case tCPolygon:
					typeString = @"POLYLINE";
					break;
			}
		}
		
	}	
	[pool release];
	 return graphicAnnotationSequence;
}

- (NSImage *)image
{
	#ifdef OSIRIX_VIEWER
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	NSData	*data = [[pix image] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];

	[pix release];
	return thumbnail;
	#endif

}
- (NSImage *)thumbnail
{
	#ifdef OSIRIX_VIEWER
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	NSData	*data = [[pix generateThumbnailImageWithWW:0 WL:0] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];
	[pix release];
	return thumbnail;
	#endif
}

- (NSDictionary *)dictionary{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	return dict;
}
	
- (NSString*) description
{
	NSString	*result = [super description];
	return [result stringByAppendingFormat:@"\rdicomTime: %@\rsopInstanceUID: %@", [self dicomTime], [self sopInstanceUID]];
}

@end
