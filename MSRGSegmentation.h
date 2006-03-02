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

@interface MSRGSegmentation : NSObject {
	NSMutableArray* criteriaViewerList;
	ViewerController* markerViewer;
	int* markerBuffer;
	float* criteriaBuffer;
	unsigned char* criteriaBufferChar;
	int sizeMarker[3];
	int sizeCriteria[3];
}
- (id) initWithViewerList:(NSMutableArray*)list currentViewer:(ViewerController*)srcViewer;
- (id) start3DMSRGSegmentationWithStackHeigt:(long)height stackWidth:(long)width stackDepth:(long)depth;
- (id) start2DMSRGSegmentationWithStackHeigt:(long)height stackWidth:(long)width stackDepth:(long)depth;
- (id) startMSRGSegmentation;
@end
