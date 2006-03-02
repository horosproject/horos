//
//  ROIVolume.h
//  OsiriX
//
//  Created by joris on 1/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMPix.h"
#import "DCMView.h" 
#import "ROI.h"

#define id Id
#include "vtkPoints.h"
#include "vtkPolyData.h"
#include "vtkDelaunay3D.h"
#include "vtkDataSetMapper.h"
#include "vtkActor.h"
#include "vtkProperty.h"
#include "vtkSurfaceReconstructionFilter.h"
#include "vtkContourFilter.h"
#include "vtkReverseSense.h"
#include "vtkPolyDataMapper.h"
#include "vtkPolygon.h"
#include "vtkCellArray.h"

#include "vtkFloatArray.h"
#include "vtkPointData.h"
#undef id

@interface ROIVolume : NSObject {
	NSMutableArray		*roiList;
	vtkActor			*roiVolumeActor;
	float				volume, red, green, blue, opacity, factor;
	NSColor				*color;
	BOOL				visible;
	NSString			*name;
	
	NSMutableDictionary		*properties;
}

- (void) setROIList: (NSArray*) newRoiList;
- (void) prepareVTKActor;

- (BOOL) isVolume;
- (NSValue*) roiVolumeActor;

- (float) volume;

- (NSColor*) color;
- (void) setColor: (NSColor*) c;

- (float) red;
- (void) setRed: (float) r;
- (float) green;
- (void) setGreen: (float) g;
- (float) blue;
- (void) setBlue: (float) b;
- (float) opacity;
- (void) setOpacity: (float) o;

- (float) factor;
- (void) setFactor: (float) f;

- (BOOL) visible;
- (void) setVisible: (BOOL) d;

- (NSString*) name;

- (NSDictionary*) properties;

@end
