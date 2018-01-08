/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/



#import "FlyThru.h"
#import "Spline3D.h"
#import "Piecewise3D.h"
#import "N3Geometry.h"
#import <math.h>

@implementation FlyThru

@synthesize steps = stepCameras,  pathCameras, stepsPositionInPath, numberOfFrames, interpolationMethod, constantSpeed, loop;


-(id) init
{
	return [self initWithFirstCamera:nil];
}

// steps
-(id) initWithFirstCamera: (Camera*) sCamera
{
	NSLog(@"FlyThru:initWithFirstCamera");
	self = [super init];
	
	stepCameras = [[NSMutableArray alloc] initWithCapacity:0];
	pathCameras = [[NSMutableArray alloc] initWithCapacity:0];
	stepsPositionInPath = nil;
	
	if (sCamera) [self addCamera: sCamera];
	self.numberOfFrames = 50;
	self.interpolationMethod = 1;
	self.constantSpeed = YES;
	self.loop = NO;
	
	return self;
}

-(void) dealloc
{
	[stepCameras release];
	[pathCameras release];
	[stepsPositionInPath release];
	
	[super dealloc];
}

-(void) addCamera: (Camera*) aCamera
{
	[stepCameras addObject:aCamera];
}

-(void) addCamera: (Camera*) aCamera atIndex: (int) index
{
	[stepCameras insertObject:aCamera atIndex:index];
}

-(void) removeCameraAtIndex: (int) index
{
	if( index >= 0)
		[stepCameras removeObjectAtIndex:index];
}

-(void) removeAllCamera
{
	[stepCameras removeAllObjects];
}


-(void) computePath
{
	NSMutableArray	*tempStepCameras = [NSMutableArray arrayWithCapacity:([stepCameras count]+1)];
	[tempStepCameras addObjectsFromArray:stepCameras];
	
	if(loop)
	{
		[tempStepCameras addObject:[stepCameras objectAtIndex:0]];
		self.numberOfFrames += 1;
	}
	NSLog(@"numberOfFrames: %d", self.numberOfFrames);
	long nbStep = [tempStepCameras count];

	// instantiation
	NSMutableArray *stepPosition, *stepViewUp, *stepFocalPoint, *stepClippingRangeNear, *stepClippingRangeFar, *stepViewAngle, *stepEyeAngle, *stepParallelScale, *stepWL, *stepWW, *stepCroppingPlanes, *stepFusionPercentage, *stepMovieIndexIn4D;

	stepPosition = [NSMutableArray arrayWithCapacity:nbStep];
	stepViewUp = [NSMutableArray arrayWithCapacity:nbStep];
	stepFocalPoint = [NSMutableArray arrayWithCapacity:nbStep];
	stepClippingRangeNear = [NSMutableArray arrayWithCapacity:nbStep];
	stepClippingRangeFar = [NSMutableArray arrayWithCapacity:nbStep];
	stepViewAngle = [NSMutableArray arrayWithCapacity:nbStep];
	stepEyeAngle = [NSMutableArray arrayWithCapacity:nbStep];
	stepParallelScale = [NSMutableArray arrayWithCapacity:nbStep];
	stepWL = [NSMutableArray arrayWithCapacity:nbStep];
	stepWW = [NSMutableArray arrayWithCapacity:nbStep];
	stepCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];
	stepFusionPercentage = [NSMutableArray arrayWithCapacity:nbStep];
	stepMovieIndexIn4D = [NSMutableArray arrayWithCapacity:nbStep];
	
	// initialisation
	Camera *cam;
	for (cam in tempStepCameras)
	{
		[stepPosition addObject:[cam position]];
		[stepViewUp addObject:[cam viewUp]];
		[stepFocalPoint addObject:[cam focalPoint]];
		// for scalar values : creating artificial 3D points to be able to use the same method 'path'
		[stepClippingRangeNear addObject: [[[Point3D alloc] initWithValues:[cam clippingRangeNear]:0:0] autorelease] ];
		[stepClippingRangeFar addObject: [[[Point3D alloc] initWithValues:[cam clippingRangeFar]:0:0] autorelease] ];
		[stepViewAngle addObject: [[[Point3D alloc] initWithValues:[cam viewAngle]:0:0] autorelease] ];
		[stepEyeAngle addObject: [[[Point3D alloc] initWithValues:[cam eyeAngle]:0:0] autorelease] ];
		[stepParallelScale addObject: [[[Point3D alloc] initWithValues:[cam parallelScale]:0:0] autorelease] ];
		[stepWL addObject: [[[Point3D alloc] initWithValues:(float)[cam wl]:0:0] autorelease] ];
		[stepWW addObject: [[[Point3D alloc] initWithValues:(float)[cam ww]:0:0] autorelease] ];
		[stepFusionPercentage addObject: [[[Point3D alloc] initWithValues:[cam fusionPercentage]:0:0] autorelease] ];
		[stepMovieIndexIn4D addObject: [[[Point3D alloc] initWithValues:[cam movieIndexIn4D]:0:0] autorelease]];
		
		[stepCroppingPlanes addObject:[cam croppingPlanes]];
	}
	
	// interpolation
	NSMutableArray *pathPosition, *pathViewUp, *pathFocalPoint, *pathClippingRangeNear, *pathClippingRangeFar, *pathViewAngle, *pathEyeAngle, *pathParallelScale, *pathWL, *pathWW, *pathCroppingPlanes, *pathFusionPercentage, *pathMovieIndexIn4D;
	
	pathPosition = [NSMutableArray arrayWithCapacity:nbStep];
	pathViewUp = [NSMutableArray arrayWithCapacity:nbStep];
	pathFocalPoint = [NSMutableArray arrayWithCapacity:nbStep];
	pathClippingRangeNear = [NSMutableArray arrayWithCapacity:nbStep];
	pathClippingRangeFar = [NSMutableArray arrayWithCapacity:nbStep];
	pathViewAngle = [NSMutableArray arrayWithCapacity:nbStep];
	pathEyeAngle = [NSMutableArray arrayWithCapacity:nbStep];
	pathParallelScale = [NSMutableArray arrayWithCapacity:nbStep];
	pathWL = [NSMutableArray arrayWithCapacity:nbStep];
	pathWW = [NSMutableArray arrayWithCapacity:nbStep];
	pathCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];
	pathFusionPercentage = [NSMutableArray arrayWithCapacity:nbStep];
	pathMovieIndexIn4D = [NSMutableArray arrayWithCapacity:nbStep];
	
	[stepsPositionInPath release];
	stepsPositionInPath = [[NSMutableArray alloc] initWithCapacity:0];
	
	pathPosition = [self path: stepPosition : interpolationMethod : YES];
	pathViewUp = [self path: stepViewUp : interpolationMethod : NO];
	pathFocalPoint = [self path: stepFocalPoint : interpolationMethod : NO];
	pathClippingRangeNear = [self path: stepClippingRangeNear : interpolationMethod : NO];
	pathClippingRangeFar = [self path: stepClippingRangeFar : interpolationMethod : NO];
	pathViewAngle = [self path: stepViewAngle : interpolationMethod : NO];
	pathEyeAngle = [self path: stepEyeAngle : interpolationMethod : NO];
	pathParallelScale = [self path: stepParallelScale : interpolationMethod : NO];
	pathWL = [self path: stepWL : interpolationMethod : NO];
	pathWW = [self path: stepWW : interpolationMethod : NO];
    
    pathCroppingPlanes = [self pathCroppingPlanes: stepCroppingPlanes : interpolationMethod : NO];
    
    pathFusionPercentage = [self path: stepFusionPercentage : interpolationMethod : NO];
	pathMovieIndexIn4D = [self path:stepMovieIndexIn4D :interpolationMethod :NO];
	
	// result
	NSEnumerator *ePathViewUp = [pathViewUp objectEnumerator];
	NSEnumerator *ePathFocalPoint = [pathFocalPoint objectEnumerator];
	NSEnumerator *ePathClippingRangeNear = [pathClippingRangeNear objectEnumerator];
	NSEnumerator *ePathClippingRangeFar = [pathClippingRangeFar objectEnumerator];
	NSEnumerator *ePathViewAngle = [pathViewAngle objectEnumerator];
	NSEnumerator *ePathEyeAngle = [pathEyeAngle objectEnumerator];
	NSEnumerator *ePathParallelScale = [pathParallelScale objectEnumerator];
	NSEnumerator *ePathWL = [pathWL objectEnumerator];
	NSEnumerator *ePathWW = [pathWW objectEnumerator];
	NSEnumerator *ePathCroppingPlanes = [pathCroppingPlanes objectEnumerator];
	NSEnumerator *ePathFusionPercentage = [pathFusionPercentage objectEnumerator];
	NSEnumerator *ePathMovieIndexIn4D = [pathMovieIndexIn4D objectEnumerator];
	
	id pos, vUp, foPt, near, far, view, eye, para, iwl, iww, cropp, fusion, index4D;
	
	[pathCameras removeAllObjects];
	
	for (pos in pathPosition)
	{
		vUp = [ePathViewUp nextObject];
		foPt = [ePathFocalPoint nextObject];
		near = [ePathClippingRangeNear nextObject];
		far = [ePathClippingRangeFar nextObject];
		view = [ePathViewAngle nextObject];
		eye = [ePathEyeAngle nextObject];
		para = [ePathParallelScale nextObject];
		iwl = [ePathWL nextObject];
		iww = [ePathWW nextObject];
		cropp = [ePathCroppingPlanes nextObject];
		fusion = [ePathFusionPercentage nextObject];
		index4D = [ePathMovieIndexIn4D nextObject];
		
		Camera * c = [[Camera alloc] init];
		[c setPosition: pos];
		[c setViewUp: vUp];
		[c setFocalPoint: foPt];
		[c setClippingRangeFrom: [near x] To: [far x]];
		[c setViewAngle: [view x]];
		[c setEyeAngle: [eye x]];
		[c setParallelScale: [para x]];
		[c setWLWW: (long)[iwl x] : (long)[iww x]];
		[c setCroppingPlanes: cropp];
		[c setFusionPercentage: [fusion x]];
		[c setMovieIndexIn4D: (long)[index4D x]];
		
		[pathCameras addObject:c];
		[c release];
	}
	
	if(loop)
		[pathCameras removeLastObject]; // otherwise this frame appears 2 times (it is the first AND last frame)
    
	self.numberOfFrames =  [pathCameras count];

}

-(NSMutableArray*) pathCroppingPlanes: (NSMutableArray*) planesSteps : (int) interpolMeth : (BOOL) computeStepsPositions
{
    NSMutableArray *origins[ 6];
    NSMutableArray *vectors[ 6];
    
    for( int i = 0; i < 6; i++)
    {
        origins[ i] = [NSMutableArray array];
        vectors[ i] = [NSMutableArray array];
    }
    
    for( NSMutableArray *planes in planesSteps)
    {
        int i = 0;
        for( NSValue *v in planes)
        {
            N3Plane plane = [v N3PlaneValue];
            
            [origins[ i] addObject: [[[Point3D alloc] initWithValues: plane.point.x :plane.point.y :plane.point.z] autorelease]];
            [vectors[ i] addObject: [[[Point3D alloc] initWithValues: plane.normal.x :plane.normal.y :plane.normal.z] autorelease]];
            
            i++;
        }
    }
    
    NSMutableArray *path = [[NSMutableArray alloc] initWithCapacity: [planesSteps count]];
    
    NSMutableArray *o = [NSMutableArray array];
    NSMutableArray *n = [NSMutableArray array];
    
    for( int i = 0; i < 6; i++)
    {
        [o addObject: [self path: origins[ i]  :interpolMeth :computeStepsPositions]];
        [n addObject: [self path: vectors[ i]  :interpolMeth :computeStepsPositions]];
    }
    
    int steps = [[o lastObject] count];
    
    for( int x = 0; x < steps; x++)
    {
        NSMutableArray *croppingPlanes = [NSMutableArray array];
        
        for( int i = 0; i < 6; i++)
        {
            N3Plane plane = N3PlaneMake( [[[o objectAtIndex: i] objectAtIndex: x] N3VectorValue], N3VectorNormalize( [[[n objectAtIndex: i] objectAtIndex: x] N3VectorValue]));
            
            [croppingPlanes addObject: [NSValue valueWithN3Plane: plane]];
        }
        
        [path addObject: croppingPlanes];
    }
    
    return [path autorelease];
}

-(NSMutableArray*) path: (NSMutableArray*) pts : (int) interpolMeth : (BOOL) computeStepsPositions
{
	Interpolation3D *function;
	
	if(interpolMeth == 1)
	{
		function = [[Spline3D alloc] init];
	}
	else
	{
		function = [[Piecewise3D alloc] init];
	}
	
	id stepPoint;
	long nbStep = [pts count];
	float t, deltaT;
	t = 0;
	deltaT = 1.0/(float)(nbStep-1);
	
	long i = 0;
	float timeStep[ nbStep];
	
	for (stepPoint in pts)
	{
		Point3D *p = [[Point3D alloc] initWithPoint3D:stepPoint];
		[function addPoint :t :p];
		[p release];
		
		timeStep[i] = t ;
		i++; 
		t = t + deltaT;
	}

	NSMutableArray *path = [[NSMutableArray alloc] initWithCapacity:nbStep];	
	deltaT = 1.0/(float)(numberOfFrames-1);

	if (computeStepsPositions)
	{
		float inc = (float)numberOfFrames/(float)(nbStep-1);
		for( t = 0 ; t <= numberOfFrames ; t += inc )
		{		
			[stepsPositionInPath addObject:[NSNumber numberWithUnsignedInt:t]];
		}		
	}

	for( t = 0 ; t <= 1 ; t += deltaT )
	{
		Point3D *tempPoint = [function evaluateAt: t];
		[path addObject:tempPoint];
	}
	
	[function release];
	
	return [path autorelease];
}



-(NSMutableDictionary*) exportToXML
{
	NSMutableDictionary *xml;
	NSMutableArray *temp;
	xml = [[NSMutableDictionary alloc] init];
	temp = [NSMutableArray array];

	Camera *cam;
	for (cam in stepCameras)
	{
		[temp addObject: [cam exportToXML]];
	}
	
	[xml setObject:temp forKey:@"Step Cameras"];
	return [xml autorelease];
}

-(void) setFromDictionary: (NSDictionary*) xml
{
	[self removeAllCamera];
	NSArray *stepsXML = [xml valueForKey:@"Step Cameras"];
	id cam;
	for (cam in stepsXML)
	{
		[self addCamera:[(Camera*) [[Camera alloc] initWithDictionary: cam] autorelease]];
	}
}

@end
