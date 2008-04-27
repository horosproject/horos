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

#import <Cocoa/Cocoa.h>
#import "DicomImage.h"

NSString* sopInstanceUIDDecode( unsigned char *r);
void* sopInstanceUIDEncode( NSString *sopuid);

@class DCMSequenceAttribute;

/** \brief  Core Data Entity for an image (frame) */

@interface DicomImage : NSManagedObject
{
	NSString	*completePathCache;
	
	NSString	*sopInstanceUID;
	NSNumber	*inDatabaseFolder;
	NSNumber	*height, *width;
	NSNumber	*numberOfFrames;
	NSNumber	*numberOfSeries;
	NSNumber	*mountedVolume;
	NSNumber	*isKeyImage, *dicomTime;
	NSString	*extension;
	NSString	*modality;
	NSString	*fileType;

//	BOOL		mxOffset;
//	BOOL		myOffset;
//	BOOL		mscale;
//	BOOL		mrotationAngle;
//	BOOL		mwindowLevel;
//	BOOL		mwindowWidth;
//	BOOL		myFlipped, mxFlipped;
//
//	NSNumber	*xOffset;
//	NSNumber	*yOffset;
//	NSNumber	*scale;
//	NSNumber	*rotationAngle;
//	NSNumber	*windowLevel;
//	NSNumber	*windowWidth;
//	
//	NSNumber	*yFlipped, *xFlipped;
}

+ (NSString*) sopInstanceUIDEncodeString:(NSString*) s;
- (NSString*) uniqueFilename;
- (NSSet*) paths;
- (NSString*) completePath;
- (NSString*) completePathResolved;
- (void) clearCompletePathCache;
- (DCMSequenceAttribute*) graphicAnnotationSequence;
- (NSImage *)image;
- (NSImage *)thumbnail;
- (NSDictionary *)dictionary;
- (NSString*) completePathWithDownload:(BOOL) download;
+ (NSString*) completePathForLocalPath:(NSString*) path directory:(NSString*) directory;
- (NSString*) SRFilenameForFrame: (int) frameNo;
- (NSString*) SRPathForFrame: (int) frameNo;
- (NSArray*) SRFilenames;
- (NSArray*) SRPaths;
- (NSString	*)sopInstanceUID;
@end
