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

#ifdef __cplusplus
#import "ITK.h"
#else
@class ITK;
#endif

@class ViewerController;

@interface ITKSegmentation3D : NSObject {

	ITK		*itkImage;
	
}

+ (unsigned char*) fastGrowingRegionWithVolume: (float*) volume width:(long) w height:(long) h depth:(long) depth seedPoint:(long*) seed from:(float) from viewer:(ViewerController*) srcViewer;
- (id) initWith :(NSMutableArray*) pix :(float*) srcPtr  :(long) slice;
- (void) regionGrowing3D:(ViewerController*) srcViewer :(ViewerController*) destViewer :(long) slice :(NSPoint) startingPoint :(int) algorithmNumber :(NSArray*) parameters :(long) setIn :(float) inValue :(long) setOut :(float) outValue :(int) roiType :(long) roiResolution :(NSString*) newname;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height;
@end
