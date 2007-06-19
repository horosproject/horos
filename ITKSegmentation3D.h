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
#define id Id
	#include "itkImage.h"
	#include "itkImportImageFilter.h"
#undef id
#import "ITK.h"
#else
@class ITK;
#endif

@class ViewerController;

@interface ITKSegmentation3D : NSObject {

	ITK		*itkImage;
	BOOL	_resampledData;
	
}

+ (NSArray*) fastGrowingRegionWithVolume: (float*) volume width:(long) w height:(long) h depth:(long) depth seedPoint:(long*) seed from:(float) from pixList:(NSArray*) pixList;
- (id) initWith :(NSMutableArray*) pix :(float*) volumeData  :(long) slice;
- (id) initWithPix :(NSMutableArray*) pix volume:(float*) volumeData  slice:(long) slice resampleData:(BOOL)resampleData;
- (void) regionGrowing3D:(ViewerController*) srcViewer :(ViewerController*) destViewer :(long) slice :(NSPoint) startingPoint :(int) algorithmNumber :(NSArray*) parameters :(BOOL) setIn :(float) inValue :(BOOL) setOut :(float) outValue :(int) roiType :(long) roiResolution :(NSString*) newname;
// extract lumen for Centerline calculation
- (void)endoscopySegmentationForViewer:(ViewerController*) srcViewer seeds:(NSArray *)seeds;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints largestRegion:(BOOL) largestRegion;
@end
