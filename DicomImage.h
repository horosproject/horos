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

@class DCMSequenceAttribute;

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
}

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
@end
