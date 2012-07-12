//
//  FlyAssistant.h

/*=========================================================================
 Author: Chunliang Wang (chunliang.wang@liu.se)
 
 
 Program:  FLy Through Assistant And Centerline tracking for CT endoscopy
 
 This file is part of FLy Through Assistant And Centerline tracking for CT endoscopy.
 
 Copyright (c) 2010,
 Center for Medical Image Science and Visualization (CMIV),
 Linköping University, Sweden, http://www.cmiv.liu.se/
 
 FLy Through Assistant And Centerline tracking for CT endoscopy is free software;
 you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software 
 Foundation, either version 3 of the License, or (at your option)
 any later version.
 
 FLy Through Assistant And Centerline tracking for CT endoscopy  is distributed in
 the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 =========================================================================*/
 

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "Point3D.h"
#import "OSIVoxel.h"
#define ERROR_NOENOUGHMEM 1
#define ERROR_CANNOTFINDPATH 2
#define ERROR_DISTTRANSNOTFINISH 3

enum PathAssistantMode {
    None,
    Basic,
    AtoB
};
typedef enum PathAssistantMode PathAssistantMode;

@interface FlyAssistant : NSObject {
	float* input;
	float* distmap;

	float im2wordTransformMatrix[4][4];
	float word2imTransformMatirx[4][4];
	
	int inputWidth,inputHeight,inputDepth;
	float inputSpacing_x, inputSpacing_y, inputSpacing_z;
	int distmapWidth,distmapHeight,distmapDepth;
	float resampleVoxelSize;
	float resampleScale_x;
	float resampleScale_y;
	float resampleScale_z;
	int distmapVolumeSize,distmapImageSize;
	float sampleMetric[2][3];
	float *csmap;
	float centerlineResampleStepLength;
	float threshold;
	BOOL isDistanceTransformFinished;
	
    unsigned long inputImageSize, inputVolumeSize;
    float thresholdA, thresholdB;
    float inputMinValue, inputMaxValue;
    
    vImagePixelCount * inputHisto;
    unsigned int histoSize;
}
@property  float centerlineResampleStepLength;
- (id) initWithVolume:(float*)data WidthDimension:(int*)dim Spacing:(float*)spacing ResampleVoxelSize:(float)vsize;
- (int) setResampleVoxelSize:(float)vsize;
- (void) setThreshold:(float)thres Asynchronous:(BOOL)async;
- (void) converPoint2ResampleCoordinate:(Point3D*)pt;
- (void) converPoint2InputCoordinate:(Point3D*)pt;
- (void) thresholdImage;
- (void) distanceTransformWithThreshold: (id) sender;
- (int) caculateNextPositionFrom: (Point3D*) pt Towards:(Point3D*)dir;
- (int) createCenterline:(NSMutableArray*)centerline FromPointA:(Point3D*)pta ToPointB:(Point3D*)ptb withSmoothing:(BOOL)smoothFlag;
- (Point3D*) caculateNextCenterPointFrom: (Point3D*) pt Towards:(Point3D*)dir WithStepLength:(float)steplen;
- (int) calculateSampleMetric:(float) a :(float) b :(float) c;
- (int) resamplecrosssection:(Point3D*) pt : (Point3D*) dir :(float) steplength;
- (float) stepCostFrom:(int)index1 To:(int)index2;
- (void) trackCenterline:(NSMutableArray*)line From:(int)currentindex WithLabel:(unsigned char*)labelmap;
- (void) downSampleCenterlineWithLocalRadius:(NSMutableArray*)centerline;
- (void) createSmoothedCenterlin:(NSMutableArray*)centerline withStepLength:(float)len;
- (float) radiusAtPoint:(OSIVoxel *)pt;
- (float) averageRadiusAt:(int)index On:(NSMutableArray*)centerline InRange:(int) nrange;
- (void) computeHistogram;
- (void) determineImageRange;
- (OSIVoxel*) computeMaximizingViewDirectionFrom:(OSIVoxel*) center LookingAt:(OSIVoxel*) direction;
- (unsigned int) traceLineFrom:(Point3D *) center accordingTo:(Point3D *) direction;
- (BOOL) point:(Point3D *)p InVolumeX:(int)x Y:(int)y Z:(int)z;
- (int) input3DCoords2LineCoords:(const int)x :(const int)y :(const int)z;
- (int) distMap3DCoords2LineCoords:(const int)x :(const int)y :(const int)z;
@end
