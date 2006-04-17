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



#import "FlyThru.h"
#import "Spline3D.h"
#import "Piecewise3D.h"
#import <math.h>

@implementation FlyThru

-(id) init
{
	NSLog(@"FlyThru:init");
	self = [super init];
	
	stepCameras = [[NSMutableArray alloc] initWithCapacity:0];
	pathCameras = [[NSMutableArray alloc] initWithCapacity:0];
	stepsPositionInPath = 0L;
	
	[self setNumberOfFrames:50];
	interpolationMethod = 0;
	constantSpeed = YES;
	loop = NO;
	
	return self;
}

// steps
-(id) initWithFirstCamera: (Camera*) sCamera
{
	NSLog(@"FlyThru:initWithFirstCamera");
	self = [super init];
	
	stepCameras = [[NSMutableArray alloc] initWithCapacity:0];
	pathCameras = [[NSMutableArray alloc] initWithCapacity:0];
	stepsPositionInPath = 0L;
	
	[self addCamera: sCamera];
	[self setNumberOfFrames:50];
	interpolationMethod = 0;
	constantSpeed = YES;
	loop = NO;
	
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

-(NSArray*) steps
{
	return stepCameras;
}

// interpolation
-(void) setNumberOfFrames:(int)n
{
	numberOfFrames = n;
}

-(int) numberOfFrames
{
	return numberOfFrames;
}

-(void) setInterpolationMethod:(int)i
{
	interpolationMethod = i;
}

-(int) interpolationMethod
{
	return interpolationMethod;
}

-(void) setLoop:(BOOL)boo
{
	loop = boo;
}

-(BOOL) loop
{
	return loop;
}

-(void) computePath
{
	NSMutableArray	*tempStepCameras = [NSMutableArray arrayWithCapacity:([stepCameras count]+1)];
	[tempStepCameras addObjectsFromArray:stepCameras];
	
	if(loop)
	{
		[tempStepCameras addObject:[stepCameras objectAtIndex:0]];
		[self setNumberOfFrames:[self numberOfFrames]+1];
	}
	
	long nbStep = [tempStepCameras count];

	// instantiation
	NSMutableArray *stepPosition, *stepViewUp, *stepFocalPoint, *stepClippingRangeNear, *stepClippingRangeFar, *stepViewAngle, *stepEyeAngle, *stepParallelScale, *stepWL, *stepWW, *stepMinCroppingPlanes, *stepMaxCroppingPlanes;

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
	stepMinCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];
	stepMaxCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];
	
	// initialisation
	NSEnumerator *eCam = [tempStepCameras objectEnumerator];
	id cam;
	while (cam = [eCam nextObject])
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
		
		[stepMinCroppingPlanes addObject:[cam minCroppingPlanes]];
		[stepMaxCroppingPlanes addObject:[cam maxCroppingPlanes]];
	}
	
	// interpolation
	NSMutableArray *pathPosition, *pathViewUp, *pathFocalPoint, *pathClippingRangeNear, *pathClippingRangeFar, *pathViewAngle, *pathEyeAngle, *pathParallelScale, *pathWL, *pathWW, *pathMinCroppingPlanes, *pathMaxCroppingPlanes;
	
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
	pathMinCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];
	pathMaxCroppingPlanes = [NSMutableArray arrayWithCapacity:nbStep];

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
	pathMinCroppingPlanes = [self path: stepMinCroppingPlanes : interpolationMethod : NO];
	pathMaxCroppingPlanes = [self path: stepMaxCroppingPlanes : interpolationMethod : NO];

	// result
	NSEnumerator *ePathPosition = [pathPosition objectEnumerator];
	NSEnumerator *ePathViewUp = [pathViewUp objectEnumerator];
	NSEnumerator *ePathFocalPoint = [pathFocalPoint objectEnumerator];
	NSEnumerator *ePathClippingRangeNear = [pathClippingRangeNear objectEnumerator];
	NSEnumerator *ePathClippingRangeFar = [pathClippingRangeFar objectEnumerator];
	NSEnumerator *ePathViewAngle = [pathViewAngle objectEnumerator];
	NSEnumerator *ePathEyeAngle = [pathEyeAngle objectEnumerator];
	NSEnumerator *ePathParallelScale = [pathParallelScale objectEnumerator];
	NSEnumerator *ePathWL = [pathWL objectEnumerator];
	NSEnumerator *ePathWW = [pathWW objectEnumerator];
	NSEnumerator *ePathMinCroppingPlanes = [pathMinCroppingPlanes objectEnumerator];
	NSEnumerator *ePathMaxCroppingPlanes = [pathMaxCroppingPlanes objectEnumerator];
	
	id pos, vUp, foPt, near, far, view, eye, para, iwl, iww, minCropp, maxCropp;
	
	[pathCameras removeAllObjects];
	
	while (pos = [ePathPosition nextObject])
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
		minCropp = [ePathMinCroppingPlanes nextObject];
		maxCropp = [ePathMaxCroppingPlanes nextObject];
		
		Camera * c = [[Camera alloc] init];
		[c setPosition: pos];
		[c setViewUp: vUp];
		[c setFocalPoint: foPt];
		[c setClippingRangeFrom: [near x] To: [far x]];
		[c setViewAngle: [view x]];
		[c setEyeAngle: [eye x]];
		[c setParallelScale: [para x]];
		[c setWLWW: (long)[iwl x] : (long)[iww x]];
		[c setMinCroppingPlanes: minCropp];
		[c setMaxCroppingPlanes: maxCropp];
		
		[pathCameras addObject:c];
		[c release];
	}
	
	if(loop)
	{
		[pathCameras removeLastObject]; // otherwise this frame appears 2 times (it is the first AND last frame)
	}
	
	[self setNumberOfFrames: [pathCameras count]];

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
	
	NSEnumerator *enumSteps = [pts objectEnumerator];
	id stepPoint;
	long nbStep = [pts count];
	float t, deltaT;
	t = 0;
	deltaT = 1.0/(float)(nbStep-1);
	
	long i = 0;
	float timeStep[nbStep];
	
	while (stepPoint = [enumSteps nextObject])
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
			NSLog(@"t ::: %d",t);
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

-(NSArray*) pathCameras
{
	return pathCameras;
}

-(NSArray*) stepsPositionInPath
{
	return stepsPositionInPath;
}

-(NSMutableDictionary*) exportToXML
{
	NSMutableDictionary *xml;
	NSMutableArray *temp;
	xml = [[NSMutableDictionary alloc] init];
	temp = [NSMutableArray arrayWithCapacity:0];

	NSEnumerator *eCam = [stepCameras objectEnumerator];
	Camera *cam;
	while (cam = [eCam nextObject])
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
	NSEnumerator *enumerator = [stepsXML objectEnumerator];
	id cam;
	while ((cam = [enumerator nextObject]))
	{
		[self addCamera:[(Camera*) [[Camera alloc] initWithDictionary: cam] autorelease]];
	}
}

@end
