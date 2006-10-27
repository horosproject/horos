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




#import "Camera.h"

@implementation Camera

-(id) init
{	
	self = [super init];
	
	position = [[Point3D alloc] init];
	viewUp = [[Point3D alloc] init];
	focalPoint = [[Point3D alloc] init];
	
	clippingRangeNear = 0;
	clippingRangeFar = 0;
	parallelScale = 0;
	viewAngle = 0;
	eyeAngle = 0;
	wl = 0;
	ww = 0;

	minCroppingPlanes = [[Point3D alloc] init];
	maxCroppingPlanes = [[Point3D alloc] init];
	
	fusionPercentage = 0.0;

	is4D = NO;
	movieIndexIn4D = 0;
		
	previewImage = [[NSImage alloc]  initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/Empty.tif"]];
	return self;
}

-(id) initWithCamera: (Camera*)c
{
	self = [super init];
	position = [[Point3D alloc] initWithPoint3D: [c position]];
	viewUp = [[Point3D alloc] initWithPoint3D: [c viewUp]];
	focalPoint = [[Point3D alloc] initWithPoint3D: [c focalPoint]];
	clippingRangeNear = [c clippingRangeNear];
	clippingRangeFar = [c clippingRangeFar];
	viewAngle = [c viewAngle];
	eyeAngle = [c eyeAngle];
	parallelScale = [c parallelScale];
	wl = [c wl];
	ww = [c ww];
	
	minCroppingPlanes = [[Point3D alloc] initWithPoint3D: [c minCroppingPlanes]];
	maxCroppingPlanes = [[Point3D alloc] initWithPoint3D: [c maxCroppingPlanes]];
	
	fusionPercentage = [c fusionPercentage];
	
	previewImage = [[c previewImage] copy];
	return self;
}

-(void) dealloc
{
	[position release];
	[viewUp release];
	[focalPoint release];
	[previewImage release];
	[minCroppingPlanes release];
	[maxCroppingPlanes release];
	
	[super dealloc];
}

-(void) setPosition: (Point3D*)p
{
	[position setPoint3D: p];
}

-(Point3D*) position
{
	return position;
}

-(void) setViewUp: (Point3D*)p
{
	[viewUp setPoint3D: p];
}

-(Point3D*) viewUp
{
	return viewUp;
}

-(void) setFocalPoint: (Point3D*)p
{
	[focalPoint setPoint3D: p];
}

-(Point3D*) focalPoint
{
	return focalPoint;
}

-(void) setClippingRangeFrom: (float)near To: (float)far
{
	clippingRangeNear = near;
	clippingRangeFar = far;
}

-(float) clippingRangeNear
{
	return clippingRangeNear;
}

-(float) clippingRangeFar
{
	return clippingRangeFar;
}

-(void) setViewAngle: (float)angle
{
	viewAngle = angle;
}

-(float) viewAngle
{
	return viewAngle;
}

-(void) setEyeAngle: (float)angle
{
	eyeAngle = angle;
}

-(float) eyeAngle
{
	return eyeAngle;
}

-(void) setParallelScale: (float)scale
{
	parallelScale = scale;
}

-(float) parallelScale
{
	return parallelScale;
}

-(void) setWLWW: (float) newWl : (float) newWw
{
	wl = newWl;
	ww = newWw;
}

-(float) wl
{
	return wl;
}

-(float) ww
{
	return ww;
}

-(void) setMinCroppingPlanes: (Point3D*)p
{
	[minCroppingPlanes setPoint3D: p];
}

-(Point3D*) minCroppingPlanes
{
	return minCroppingPlanes;
}

-(void) setMaxCroppingPlanes: (Point3D*)p
{
	[maxCroppingPlanes setPoint3D: p];
}

-(Point3D*) maxCroppingPlanes
{
	return maxCroppingPlanes;
}

- (void)setFusionPercentage:(float)f;
{
	fusionPercentage = f;
}

- (float)fusionPercentage;
{
	return fusionPercentage;
}

- (void)setIs4D:(BOOL)boo;
{
	is4D = boo;
}

- (BOOL)is4D;
{
	return is4D;
}

- (void)setMovieIndexIn4D:(long)i;
{
	movieIndexIn4D = i;
}

- (long)movieIndexIn4D;
{
	return movieIndexIn4D;
}

-(void) setPreviewImage: (NSImage*)im
{
	if( previewImage != im)
	{
		[previewImage release];
		
		previewImage = [im retain];
	}
}

-(NSImage*) previewImage
{
	return previewImage;
}

-(NSString*) description
{
	NSMutableString *desc = [NSMutableString stringWithCapacity:0];
	//[desc appendString:@"Camera \n"];
	[desc appendString:[NSString stringWithFormat:@"Position: %@\n",[self position]]];
	[desc appendString:[NSString stringWithFormat:@"ViewUp: %@\n",[self viewUp]]];
	[desc appendString:[NSString stringWithFormat:@"FocalPoint: %@\n",[self focalPoint]]];	
	[desc appendString:[NSString stringWithFormat:@"clippingRangeNear: %f\n",[self clippingRangeNear]]];
	[desc appendString:[NSString stringWithFormat:@"clippingRangeFar: %f\n",[self clippingRangeFar]]];
	[desc appendString:[NSString stringWithFormat:@"viewAngle: %f\n",[self viewAngle]]];
	[desc appendString:[NSString stringWithFormat:@"eyeAngle: %f\n",[self eyeAngle]]];
	[desc appendString:[NSString stringWithFormat:@"parallelScale: %f\n",[self parallelScale]]];
	[desc appendString:[NSString stringWithFormat:@"wl: %f\n",[self wl]]];
	[desc appendString:[NSString stringWithFormat:@"ww: %f\n",[self ww]]];
	[desc appendString:[NSString stringWithFormat:@"minCroppingPlanes: %@\n",[self minCroppingPlanes]]];
	[desc appendString:[NSString stringWithFormat:@"maxCroppingPlanes: %@\n",[self maxCroppingPlanes]]];
	[desc appendString:[NSString stringWithFormat:@"fusionPercentage: %f\n",[self fusionPercentage]]];
	return desc;
}

-(NSMutableDictionary*) exportToXML
{
	NSMutableDictionary *xml;
	xml = [[NSMutableDictionary alloc] init];
		
	[xml setObject: [position exportToXML] forKey:@"position"];
	[xml setObject: [viewUp exportToXML] forKey:@"viewUp"];
	[xml setObject: [focalPoint exportToXML] forKey:@"focalPoint"];

	[xml setObject:[NSString stringWithFormat:@"%f",[self clippingRangeNear]] forKey:@"clippingRangeNear"];
	[xml setObject:[NSString stringWithFormat:@"%f",[self clippingRangeFar]] forKey:@"clippingRangeFar"];	
	[xml setObject:[NSString stringWithFormat:@"%f",[self viewAngle]] forKey:@"viewAngle"];	
	[xml setObject:[NSString stringWithFormat:@"%f",[self eyeAngle]] forKey:@"eyeAngle"];	
	[xml setObject:[NSString stringWithFormat:@"%f",[self parallelScale]] forKey:@"parallelScale"];
	[xml setObject:[NSString stringWithFormat:@"%f",[self wl]] forKey:@"wl"];
	[xml setObject:[NSString stringWithFormat:@"%f",[self ww]] forKey:@"ww"];
	
	[xml setObject: [minCroppingPlanes exportToXML] forKey:@"minCroppingPlanes"];
	[xml setObject: [maxCroppingPlanes exportToXML] forKey:@"maxCroppingPlanes"];
	
	[xml setObject:[NSString stringWithFormat:@"%f",[self fusionPercentage]] forKey:@"fusionPercentage"];
	
	return [xml autorelease];
}

-(id) initWithDictionary: (NSDictionary*) xml
{
	self = [super init];
	position = [(Point3D*) [Point3D alloc] initWithDictionary: [xml valueForKey:@"position"]];
	viewUp = [(Point3D*) [Point3D alloc] initWithDictionary: [xml valueForKey:@"viewUp"]];
	focalPoint = [(Point3D*) [Point3D alloc] initWithDictionary: [xml valueForKey:@"focalPoint"]];
	clippingRangeNear = [[xml valueForKey:@"clippingRangeNear"] floatValue];
	clippingRangeFar = [[xml valueForKey:@"clippingRangeFar"] floatValue];
	viewAngle = [[xml valueForKey:@"viewAngle"] floatValue];
	eyeAngle = [[xml valueForKey:@"eyeAngle"] floatValue];
	parallelScale = [[xml valueForKey:@"parallelScale"] floatValue];
	wl = [[xml valueForKey:@"wl"] floatValue];
	ww = [[xml valueForKey:@"ww"] floatValue];
	minCroppingPlanes = [(Point3D*) [Point3D alloc] initWithDictionary: [xml valueForKey:@"minCroppingPlanes"]];
	maxCroppingPlanes = [(Point3D*) [Point3D alloc] initWithDictionary: [xml valueForKey:@"maxCroppingPlanes"]];
	fusionPercentage = [[xml valueForKey:@"fusionPercentage"] floatValue];
	return self;
}

@end
