/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/




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

#include "DCMView.h" // for ToolMode

@class ViewerController;


/** \brief ITK based segmentation for region growing
*/
@interface ITKSegmentation3D : NSObject {

	ITK		*itkImage;
	BOOL	_resampledData;
	
}

#ifdef id
#define redefineID
#undef id
#endif

+ (NSArray*) fastGrowingRegionWithVolume: (float*) volume width:(long) w height:(long) h depth:(long) depth seedPoint:(long*) seed from:(float) from pixList:(NSArray*) pixList;
- (id) initWith :(NSMutableArray*) pix :(float*) volumeData  :(long) slice;
- (id) initWithPix :(NSMutableArray*) pix volume:(float*) volumeData  slice:(long) slice resampleData:(BOOL)resampleData;
- (void) regionGrowing3D:(ViewerController*) srcViewer :(ViewerController*) destViewer :(long) slice :(NSPoint) startingPoint :(int) algorithmNumber :(NSArray*) parameters :(BOOL) setIn :(float) inValue :(BOOL) setOut :(float) outValue :(ToolMode) roiType :(long) roiResolution :(NSString*) newname :(BOOL) mergeWithExistingROIs;
// extract lumen for Centerline calculation
//- (NSArray *)endoscopySegmentationForViewer:(ViewerController*) srcViewer seeds:(NSArray *)seeds;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints;
+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints largestRegion:(BOOL) largestRegion;

#ifdef redefineID
#define id Id
#undef redefineID
#endif

@end
