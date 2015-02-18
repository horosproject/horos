/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/




#import <Cocoa/Cocoa.h>
#import "Camera.h"
#import "Interpolation3D.h"

/** \brief Manages 3D flythrus
*/

@interface FlyThru : NSObject {
	NSMutableArray	*stepCameras, *pathCameras, *stepsPositionInPath;
	int				numberOfFrames;
	int				interpolationMethod; // 1: spline / 2: piecewise
	BOOL			constantSpeed, loop;
	
}

@property (readwrite, retain) NSMutableArray *steps;
@property (readwrite, retain) NSMutableArray *pathCameras;
@property (readwrite, retain) NSMutableArray *stepsPositionInPath;
@property int numberOfFrames;
@property int interpolationMethod;

@property BOOL constantSpeed;
@property BOOL loop;


// steps (cameras choosed by the user)
-(id) initWithFirstCamera: (Camera*) sCamera;
-(void) addCamera: (Camera*) aCamera;
-(void) addCamera: (Camera*) aCamera atIndex: (int) index;
-(void) removeCameraAtIndex: (int) index;
-(void) removeAllCamera;



-(void) computePath; // interpollation of the path for every parameters
-(NSMutableArray*) path: (NSMutableArray*) pts : (int) interpolMeth : (BOOL) computeStepsPositions; // interpollation for 1 parameter

-(NSMutableDictionary*) exportToXML;
-(void) setFromDictionary: (NSDictionary*) xml;

@end
