/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>
#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"

/** \brief   MPR views for endoscopy
*/

@interface EndoscopyMPRView : OrthogonalMPRView {
	NSPoint	cameraPosition, cameraFocalPoint;
	float	cameraAngle;
	long	focalPointX, focalPointY, focalShiftX, focalShiftY, near, maxFocalLength;
	long	viewUpX, viewUpY;
	NSArray* flyThroughPath;
}

@property  (retain) NSArray* flyThroughPath;


- (void) setCameraPosition: (float) x : (float) y;
- (NSPoint) cameraPosition;
- (void) setCameraFocalPoint: (float) x : (float) y;
- (NSPoint) cameraFocalPoint;
- (void) setCameraAngle: (float) alpha;
- (float) cameraAngle;

- (void) setFocalPointX: (long) x;
- (void) setFocalPointY: (long) y;
- (long) focalPointX;
- (long) focalPointY;
- (void) setFocalShiftX: (long) x;
- (void) setFocalShiftY: (long) y;
- (long) focalShiftX;
- (long) focalShiftY;

- (void) setViewUpX: (long) x;
- (void) setViewUpY: (long) y;
- (long) viewUpX;
- (long) viewUpY;

-(unsigned char*) superGetRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical;

@end
