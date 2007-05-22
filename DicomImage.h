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

#import <Cocoa/Cocoa.h>
#import "DicomImage.h"

@class DCMSequenceAttribute;

@interface DicomImage : NSManagedObject
{
	NSString	*completePathCache;
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

@end
