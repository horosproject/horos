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



#import "Camera.h"

@implementation Camera

@synthesize index, position, focalPoint, viewUp, previewImage, is4D, viewAngle, eyeAngle, forceUpdate,
			parallelScale, clippingRangeNear, clippingRangeFar, ww, wl, fusionPercentage, rollAngle, 
			movieIndexIn4D, croppingPlanes, windowCenterX, windowCenterY, LOD;


- (id) init
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
    
    croppingPlanes = [[NSMutableArray alloc] init];
    
    for( int i = 0; i < 6; i++)
        [croppingPlanes addObject: [NSValue valueWithN3Plane: N3PlaneInvalid]];
    
	fusionPercentage = 0.0;

	is4D = NO;
	movieIndexIn4D = 0;
	
	//previewImage = [[NSImage alloc]  initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/Empty.tif"]];
	previewImage = nil;
	
	return self;
}

-(id) initWithCamera: (Camera*)c
{
	self = [super init];
	self.position = c.position;
	self.viewUp = c.viewUp;
	self.focalPoint = c.focalPoint;
	self.clippingRangeNear = c.clippingRangeNear;
	self.clippingRangeFar = c.clippingRangeFar;
	self.viewAngle = c.viewAngle;
	self.eyeAngle = c.eyeAngle;
	self.parallelScale = c.parallelScale;
	self.wl = c.wl;
	self.ww = c.ww;
    self.croppingPlanes = c.croppingPlanes;
	self.fusionPercentage = c.fusionPercentage;
	self.windowCenterX = c.windowCenterX;
	self.windowCenterY = c.windowCenterY;
	self.previewImage = c.previewImage;
	return self;
}

- (id)copyWithZone:(NSZone *)zone{
	return [[Camera alloc] initWithCamera:self];
}

-(void) dealloc
{
	[position release];
	[viewUp release];
	[focalPoint release];
	[previewImage release];
    
    [croppingPlanes release];
	
	[super dealloc];
}



-(void) setClippingRangeFrom: (float)near To: (float)far
{
	self.clippingRangeNear = near;
	self.clippingRangeFar = far;
}

-(void) setWLWW: (float) newWl : (float) newWw
{
	self.wl = newWl;
	self.ww = newWw;
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
	
    int i = 0;
    for( NSValue *v in croppingPlanes)
        [xml setObject: [(id) N3PlaneCreateDictionaryRepresentation( [v N3PlaneValue]) autorelease] forKey: [NSString stringWithFormat: @"croppingPlanes %d", i]];
    
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
    
    for( int i = 0; i < 6; i++)
    {
        N3Plane plane;
        if( N3PlaneMakeWithDictionaryRepresentation( (CFDictionaryRef) [xml valueForKey: [NSString stringWithFormat: @"croppingPlanes %d", i]], &plane))
           [croppingPlanes replaceObjectAtIndex: i withObject: [NSValue valueWithN3Plane: plane]];
    }
	fusionPercentage = [[xml valueForKey:@"fusionPercentage"] floatValue];
	return self;
}

@end
