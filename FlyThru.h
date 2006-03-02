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
#import "Camera.h"
#import "Interpolation3D.h"

@interface FlyThru : NSObject {
	NSMutableArray	*stepCameras, *pathCameras, *stepsPositionInPath;
	int				numberOfFrames;
	int				interpolationMethod; // 1: spline / 2: piecewise
	BOOL			constantSpeed, loop;
}

// steps (cameras choosed by the user)
-(id) initWithFirstCamera: (Camera*) sCamera;
-(void) addCamera: (Camera*) aCamera;
-(void) addCamera: (Camera*) aCamera atIndex: (int) index;
-(void) removeCameraAtIndex: (int) index;
-(void) removeAllCamera;
-(NSArray*) steps; // return the list of steps

// interpolation (the path through every steps is computed)
-(void) setNumberOfFrames:(int)n;
-(int) numberOfFrames;
-(void) setInterpolationMethod:(int)i;
-(int) interpolationMethod;
-(void) setLoop:(BOOL)i; // to loop, the first step is duplicated as last step. 
-(BOOL) loop;
-(void) computePath; // interpollation of the path for every parameters
-(NSMutableArray*) path: (NSMutableArray*) pts : (int) interpolMeth : (BOOL) computeStepsPositions; // interpollation for 1 parameter
-(NSArray*) pathCameras; // interpolation result
-(NSArray*) stepsPositionInPath; // indexes of the steps in the interpolated path
-(NSMutableDictionary*) exportToXML;
-(void) setFromDictionary: (NSDictionary*) xml;

@end
