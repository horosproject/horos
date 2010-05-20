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
#import "DCMObjectPixelDataImport.h"
#import "DCMView.h"
#import "MutableArrayCategory.h"
#import "DicomFile.h"
#import "DICOMToNSString.h"
#import "XMLController.h"
#import "XMLControllerDCMTKCategory.h"
#include <zlib.h>

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

@interface NSData (OsiriX)
- (BOOL) isEqualToSopInstanceUID:(NSData*) sopInstanceUID;
@end

@implementation NSData (OsiriX)

- (BOOL) isEqualToSopInstanceUID:(NSData*) sopInstanceUID
{
	NSUInteger length = [self length];
	if( length == 0)
		return NO;
	
	NSUInteger sopInstanceUIDLength = [sopInstanceUID length];
	if( sopInstanceUIDLength == 0)
		return NO;
	
	const UInt8* bytes = (const UInt8*) [self bytes];
	if( bytes[length-1] == 0)
		length --;
	
	const UInt8* sopInstanceUIDBytes = (const UInt8*) [sopInstanceUID bytes];
	if (sopInstanceUIDBytes[sopInstanceUIDLength-1] == 0)
		sopInstanceUIDLength --;
	
	if (length == sopInstanceUIDLength)
		return (memcmp(bytes, sopInstanceUIDBytes, length) == 0);
	
	return NO;
}
@end

@implementation DicomImage

@dynamic comment;
@dynamic compressedSopInstanceUID;
@dynamic date;
@dynamic frameID;
@dynamic instanceNumber;
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

+ (NSData*) sopInstanceUIDEncodeString:(NSString*) s
{
	int length = [s length];
	length ++;
	length /= 2;
	
	return [NSData dataWithBytesNoCopy: sopInstanceUIDEncode( s) length: length freeWhenDone: YES];
}

- (NSArray*) SRPaths
{
	NSMutableArray	*roiFiles = [NSMutableArray array];
	int	x;
	
	NSString *roiPath = [self SRPathForFrame: [[self valueForKey: @"frameID"] intValue]];
	
	if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
		[roiFiles addObject: roiPath];
	
	return roiFiles;
}


- (NSString*) SRFilenameForFrame: (int) frameNo
{
	return [NSString stringWithFormat: @"%@-%d.dcm", [self uniqueFilename], frameNo];
}

- (NSString*) SRPathForFrame: (int) frameNo
{
	#ifdef OSIRIX_VIEWER
	NSString *d;
	
	if( [[BrowserController currentBrowser] isCurrentDatabaseBonjour])
		d = [DicomImage dbPathForManagedContext: [self managedObjectContext]];
	else
		d = [[DicomImage dbPathForManagedContext: [self managedObjectContext]] stringByAppendingPathComponent:ROIDATABASE];
	
	return [d stringByAppendingPathComponent: [self SRFilenameForFrame: frameNo]];
	#else
	return nil;
	#endif
}

- (NSString*) sopInstanceUID
{
	if( sopInstanceUID) return sopInstanceUID;
	
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

- (void) setSopInstanceUID: (NSString*) s
{
	[sopInstanceUID release];
	sopInstanceUID = nil;

	if( s)
	{
		int length = [s length];
		length++;
		length /= 2;
		
		char *ss = sopInstanceUIDEncode( s);
		[self setValue: [NSData dataWithBytes: ss length: length] forKey:@"compressedSopInstanceUID"];
		free( ss);
		
//		if( [[self sopInstanceUID] isEqualToString: s] == NO)
//			NSLog(@"******** ERROR sopInstanceUID : %@ %@", s, [self sopInstanceUID]);
	}
	else [self setValue: nil forKey:@"compressedSopInstanceUID"];
}

#pragma mark-


#pragma mark-

- (NSNumber*) inDatabaseFolder
{
	if( inDatabaseFolder) return inDatabaseFolder;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedInDatabaseFolder"];
	
	if( f == nil) f = [NSNumber numberWithBool: YES];
	
	[inDatabaseFolder release];
	inDatabaseFolder = [f retain];

	return inDatabaseFolder;
}

- (void) setInDatabaseFolder:(NSNumber*) f
{
	[inDatabaseFolder release];
	inDatabaseFolder = nil;
	
	[self willChangeValueForKey:@"storedInDatabaseFolder"];
	if( [f boolValue] == YES)	
		[self setPrimitiveValue: nil forKey:@"storedInDatabaseFolder"];
	else
		[self setPrimitiveValue: f forKey:@"storedInDatabaseFolder"];
	[self didChangeValueForKey:@"storedInDatabaseFolder"];
}

#pragma mark-

- (NSNumber*) height
{
	if( height) return height;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedHeight"];
	
	if( f == nil) f = [NSNumber numberWithInt: 512];
	
	[height release];
	height = [f retain];

	return height;
}

- (void) setHeight:(NSNumber*) f
{
	[height release];
	height = nil;
	
	[self willChangeValueForKey:@"storedHeight"];
	if( [f intValue] == 512)	
		[self setPrimitiveValue: nil forKey:@"storedHeight"];
	else
		[self setPrimitiveValue: f forKey:@"storedHeight"];
	[self didChangeValueForKey:@"storedHeight"];
}

#pragma mark-

- (NSNumber*) width
{
	if( width) return width;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedWidth"];
	
	if( f == nil) f = [NSNumber numberWithInt: 512];
	
	[width release];
	width = [f retain];

	return width;
}

- (void) setWidth:(NSNumber*) f
{
	[width release];
	width = nil;
	
	[self willChangeValueForKey:@"storedWidth"];
	if( [f intValue] == 512)	
		[self setPrimitiveValue: nil forKey:@"storedWidth"];
	else
		[self setPrimitiveValue: f forKey:@"storedWidth"];
	[self didChangeValueForKey:@"storedWidth"];
}

#pragma mark-

- (NSNumber*) numberOfFrames
{
	if( numberOfFrames) return numberOfFrames;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfFrames"];
	
	if( f == nil) f = [NSNumber numberWithInt: 1];

	[numberOfFrames release];
	numberOfFrames = [f retain];

	return numberOfFrames;
}

- (void) setNumberOfFrames:(NSNumber*) f
{
	[numberOfFrames release];
	numberOfFrames = nil;
	
	[self willChangeValueForKey:@"storedNumberOfFrames"];
	if( [f intValue] == 1)	
		[self setPrimitiveValue: nil forKey:@"storedNumberOfFrames"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfFrames"];
	[self didChangeValueForKey:@"storedNumberOfFrames"];
}

#pragma mark-

- (NSNumber*) numberOfSeries
{
	if( numberOfSeries) return numberOfSeries;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfSeries"];
	
	if( f == nil) f = [NSNumber numberWithInt: 1];

	[numberOfSeries release];
	numberOfSeries = [f retain];

	return numberOfSeries;
}

- (void) setNumberOfSeries:(NSNumber*) f
{
	[numberOfSeries release];
	numberOfSeries = nil;
	
	[self willChangeValueForKey:@"storedNumberOfSeries"];
	if( [f intValue] == 1)	
		[self setPrimitiveValue: nil forKey:@"storedNumberOfSeries"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfSeries"];
	[self didChangeValueForKey:@"storedNumberOfSeries"];
}

#pragma mark-

- (NSNumber*) mountedVolume
{
	if( mountedVolume) return mountedVolume;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedMountedVolume"];
	
	if( f == nil)  f = [NSNumber numberWithBool: NO];

	[mountedVolume release];
	mountedVolume = [f retain];

	return mountedVolume;
}

- (void) setMountedVolume:(NSNumber*) f
{
	[mountedVolume release];
	mountedVolume = nil;
	
	[self willChangeValueForKey:@"storedMountedVolume"];
	if( [f boolValue] == NO)
		[self setPrimitiveValue: nil forKey:@"storedMountedVolume"];
	else
		[self setPrimitiveValue: f forKey:@"storedMountedVolume"];
	[self didChangeValueForKey:@"storedMountedVolume"];
}

#pragma mark-

- (void) dcmodifyThread: (NSDictionary*) dict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[DicomStudy dbModifyLock] lock];
	
#ifdef OSIRIX_VIEWER
#ifndef OSIRIX_LIGHT
	@try 
	{
		NSMutableArray	*params = [NSMutableArray arrayWithObjects:@"dcmodify", @"--ignore-errors", nil];
		
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

- (NSNumber*) isKeyImage
{
	if( isKeyImage) return isKeyImage;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedIsKeyImage"];
	
	if( f == nil)  f = [NSNumber numberWithBool: NO];

	[isKeyImage release];
	isKeyImage = [f retain];

	return isKeyImage;
}

- (void) setIsKeyImage:(NSNumber*) f
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[isKeyImage release];
	isKeyImage = nil;
	
	if( [f boolValue] != [[self primitiveValueForKey: @"storedIsKeyImage"] boolValue])
	{
		#ifdef OSIRIX_VIEWER
		#ifndef OSIRIX_LIGHT
		if( [self.series.study.hasDICOM boolValue] == YES && [[NSUserDefaults standardUserDefaults] boolForKey: @"savedCommentsAndStatusInDICOMFiles"])
		{
			NSString *c = nil;
			if( [[self numberOfFrames] intValue] > 1)
			{
				[[DicomStudy dbModifyLock] lock];
				
				DCMObject *dcmObject = [[DCMObjectPixelDataImport alloc] initWithContentsOfFile: [self valueForKey:@"completePath"] decodingPixelData: NO];
				
				if( [dcmObject.attributes objectForKey: @"0028,6022"])
				{
					int frame = [[self frameID] intValue];
					
					NSMutableArray *keyFrames = [NSMutableArray arrayWithArray: [[dcmObject.attributes objectForKey: @"0028,6022"] values]];
					
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
					else
						c = @"";
				}
				
				[dcmObject release];
				
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: c, @"value", [NSArray arrayWithObject: [self valueForKey:@"completePath"]], @"files", @"(0028,6022)", @"field", nil];
				[NSThread detachNewThreadSelector: @selector( dcmodifyThread:) toTarget: self withObject: dict];
				
				[[DicomStudy dbModifyLock] unlock];
			}
			else
			{
				if( [f boolValue])
					c = @"0"; // frame 0 is key image 
				else
					c = @"";
					
				NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: c, @"value", [NSArray arrayWithObject: [self valueForKey:@"completePath"]], @"files", @"(0028,6022)", @"field", nil];
				[NSThread detachNewThreadSelector: @selector( dcmodifyThread:) toTarget: self withObject: dict];
			}
		}
		#endif
		#endif
		
		[self willChangeValueForKey: @"storedIsKeyImage"];
		
		if( [f boolValue] == NO)
			[self setPrimitiveValue: nil forKey:@"storedIsKeyImage"];
		else
			[self setPrimitiveValue: f forKey:@"storedIsKeyImage"];
		
		[self didChangeValueForKey:@"storedIsKeyImage"];
	}
	
	[pool release];
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
	extension = nil;
	
	[self willChangeValueForKey:@"storedExtension"];
	if( [f isEqualToString:@"dcm"])
		[self setPrimitiveValue: nil forKey:@"storedExtension"];
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
	modality = nil;
	
	[self willChangeValueForKey:@"storedModality"];
	if( [f isEqualToString:@"CT"])
		[self setPrimitiveValue: nil forKey:@"storedModality"];
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
	fileType = nil;
	
	[self willChangeValueForKey:@"storedFileType"];
	if( [f isEqualToString:@"DICOM"])
		[self setPrimitiveValue: nil forKey:@"storedFileType"];
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
	return nil;
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = nil;
	
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
	
	[super dealloc];
}

-(NSString*) uniqueFilename	// Return a 'unique' filename that identify this image...
{
	return [NSString stringWithFormat:@"%@ %@",[self valueForKey:@"sopInstanceUID"], [self valueForKey:@"instanceNumber"]];
}

- (void) clearCompletePathCache
{
	[completePathCache release];
	completePathCache = nil;
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

+ (NSString*) dbPathForManagedContext: (NSManagedObjectContext *) c
{
	NSPersistentStoreCoordinator *sc = [c persistentStoreCoordinator];
	NSArray *stores = [sc persistentStores];
	
	if( [stores count] != 1)
	{
		NSLog( @"*** warning [stores count] != 1 : %@", stores);
		
		for( id s in stores)
			NSLog( @"%@", [[[sc URLForPersistentStore: s] path] stringByDeletingLastPathComponent]);
	}	
	return [[[sc URLForPersistentStore: [stores lastObject]] path] stringByDeletingLastPathComponent];
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
				completePathCache = [[[BonjourBrowser currentBrowser] getDICOMFile: [cB currentBonjourService] forObject: self noOfImages: 1] retain];
			else
				completePathCache = [[BonjourBrowser uniqueLocalPath: self] retain];
			
			return completePathCache;
		}
		else
		{
			if( [path characterAtIndex: 0] != '/')
			{
				completePathCache = [[DicomImage completePathForLocalPath: path directory: [DicomImage dbPathForManagedContext: [self managedObjectContext]]] retain];
				
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
				[[BrowserController currentBrowser] addFileToDeleteQueue: [[[self valueForKey:@"completePath"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
			
			[self setValue:[NSNumber numberWithBool:NO] forKey:@"inDatabaseFolder"];
		}
		#endif
		
		#ifndef OSIRIX_LIGHT
		if( [[NSFileManager defaultManager] fileExistsAtPath: [VRController getUniqueFilenameScissorStateFor: self]])
			[[NSFileManager defaultManager] removeFileAtPath: [VRController getUniqueFilenameScissorStateFor: self] handler: nil];
		#endif
	}
	return delete;
}

- (NSSet *)paths
{
	return [NSSet setWithObject:[self completePath]];
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
		int roiType = [[roi valueForKey:@"roiType"] intValue];
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
	DCMPix *pix = [[DCMPix alloc] initWithPath:[self valueForKey:@"completePath"] :0 :0 :nil :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	NSData	*data = [[pix image] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];

	[pix release];
	return thumbnail;
	#endif

}
- (NSImage *)thumbnail
{
	#ifdef OSIRIX_VIEWER
	DCMPix *pix = [[DCMPix alloc] initWithPath:[self valueForKey:@"completePath"] :0 :0 :nil :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	NSData	*data = [[pix generateThumbnailImageWithWW:0 WL:0] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];
	[pix release];
	return thumbnail;
	#endif
}

- (NSDictionary *)dictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	return dict;
}
	
- (NSString*) description
{
	NSString	*result = [super description];
	return [result stringByAppendingFormat:@"\rdicomTime: %@\rsopInstanceUID: %@", [self dicomTime], [self sopInstanceUID]];
}

@end
