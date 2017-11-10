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

#ifdef __cplusplus
#import "ITK.h"
#else
@class ITK;
#endif

@class ViewerController;

@interface MSRGSegmentation : NSObject {
	NSMutableArray* criteriaViewerList;
	ViewerController* markerViewer;
	unsigned char* markerBuffer;
	int sizeMarker[3];
	int numberOfCriteria;
	int width,height,depth;
	// bounding parameters
	BOOL isBounding;
	NSRect boundingRegion;
	BOOL isGrow3D;
	int boundingZstart;
	int boundingZEnd;
}
- (id) initWithViewerList:(NSMutableArray*)list currentViewer:(ViewerController*)srcViewer boundingBoxOn:(BOOL)boundOn GrowIn3D:(BOOL)growing3D boundingRect:(NSRect)rectBounding boundingBeginZ:(int)bZstart boundingEndZ:(int)bEndZ;
- (id) start3DMSRGSegmentationWithOneCriterion;
- (id) startMSRGSegmentation;
- (BOOL) build2DMarkerBuffer;
@end
