/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DicomImage.h"
#import "browserController.h"
#import "BonjourBrowser.h"
#import <OsiriX/DCM.h>
#import "DCMView.h"
#import "DCMPix.h"
#import "VRController.h"

inline int charToInt( unsigned char c)
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
	
	return 1;
}

inline unsigned char intToChar( int c)
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
	unsigned char	*r = malloc( 128);
	
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
	unsigned int	i, x, length = strlen( (char *)r );  // Assumes length will always be < 256!
	char			str[ 256];
	
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

//- (NSString*) sopInstanceUID
//{
//	char*	t = sopInstanceUIDDecode( (unsigned char*) [[self primitiveValueForKey:@"compressedSopInstanceUID"] bytes]);
//	NSString* uid = [NSString stringWithUTF8String: t];
//	free( t);
//	
//	return uid;
//}
//
//- (void) setSopInstanceUID: (NSString*) s
//{
//	char *ss = sopInstanceUIDEncode( s);
//	[self setValue: [NSData dataWithBytes: ss length: strlen( ss)] forKey:@"compressedSopInstanceUID"];
//}

- (NSString*) fileType
{
	NSString	*f = [self primitiveValueForKey:@"fileType"];
	
	if( f == 0 || [f isEqualToString:@""]) return @"DICOM";
	else return f;
}

- (NSString*) type
{
	return @"Image";
}

- (void) dealloc
{
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

-(NSString*) completePathWithDownload:(BOOL) download
{
	if( completePathCache) return completePathCache;
	
	if( [[self valueForKey:@"inDatabaseFolder"] boolValue] == YES)
	{
		NSString			*path = [self primitiveValueForKey:@"path"];
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
	
	return [self primitiveValueForKey:@"path"];
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
	NSEnumerator *enumerator = [rois objectEnumerator];
	id roi;
	while (roi = [enumerator nextObject]){
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
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	//[pix computeWImage:NO :[[self valueForKeyPath:@"series.windowLevel"] floatValue] :[[self valueForKeyPath:@"series.windowWidth"] floatValue]];
	[pix computeWImage:NO :0 :0];
	NSData	*data = [[pix getImage] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];

	[pix release];
	return thumbnail;

}
- (NSImage *)thumbnail{
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	//[pix computeWImage:YES :[[self valueForKeyPath:@"series.windowLevel"] floatValue] :[[self valueForKeyPath:@"series.windowWidth"] floatValue]];
	[pix computeWImage:YES :0 :0];
	NSData	*data = [[pix getImage] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];
	[pix release];
	return thumbnail;
}

- (NSDictionary *)dictionary{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	return dict;
}
	


@end
