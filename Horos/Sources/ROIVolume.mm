/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "options.h"

#import "ROIVolume.h"
#import "Notifications.h"
#import "ViewerController.h"
#import "ITKSegmentation3D.h"
#import "ROIVolumeView.h"
#import "WaitRendering.h"

@implementation ROIVolume

@synthesize factor;

- (id) initWithViewer: (ViewerController*) v
{
	self = [super init];
	if (self != nil)
	{
		roiList = [[NSMutableArray alloc] initWithCapacity:0];
		roiVolumeActor = nil;
		name = @"";
		[name retain];
		volume = 0.0;
		red = 0.0;
		green = 1.0;
		blue = 1.0;
		opacity = 1.0;
		factor = 1.0;
		textured = YES;
		color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
		visible = NO;
        viewer = [v retain];

		NSArray *keys   = [NSArray arrayWithObjects:@"name", @"volume", @"red", @"green", @"blue", @"opacity", @"color", @"visible", @"texture", nil];
		NSArray *values = [NSArray arrayWithObjects:	name,
														[NSNumber numberWithFloat:volume],
														[NSNumber numberWithFloat:red],
														[NSNumber numberWithFloat:green],
														[NSNumber numberWithFloat:blue],
														[NSNumber numberWithFloat:opacity],
														color,
														[NSNumber numberWithBool:visible],
														[NSNumber numberWithBool:textured], nil];
		properties = [[NSMutableDictionary alloc] initWithObjects: values forKeys: keys];
	}
	return self;
}

- (void) dealloc
{
    [viewer release];
	[roiList release];
	[properties release];
	
	if(roiVolumeActor != nil)
		roiVolumeActor->Delete();
	
	if( textureImage)
		textureImage->Delete();
	
	[name release];
	
	[super dealloc];
}

- (void) setROIList: (NSArray*) newRoiList
{
	int i;
	float prevArea, preLocation;
	prevArea = 0.;
	preLocation = 0.;
	volume = 0.;
	
	for(i = 0; i < [newRoiList count]; i++)
	{
		ROI *curROI = [newRoiList objectAtIndex:i];
		if([curROI type]==tPencil || [curROI type]==tCPolygon || [curROI type]==tPlain)
		{
			[roiList addObject:curROI];
			// volume
			DCMPix *curDCM = [curROI pix];
			float curArea = [curROI roiArea];
			if( preLocation != 0)
				volume += (([curDCM sliceLocation] - preLocation)/10.) * (curArea + prevArea)/2.;
			prevArea = curArea;
			preLocation = [curDCM sliceLocation];
		}
	}
	
	if([roiList count])
	{
		ROI *curROI = [roiList objectAtIndex:0];
		[name release];
		name = [[curROI name] retain];
		[properties setValue:name forKey:@"name"];
		[properties setValue:[NSNumber numberWithFloat:volume] forKey:@"volume"];
	}
}

- (void) prepareVTKActor
{
	WaitRendering *splash = [[WaitRendering alloc] init: NSLocalizedString( @"Preparing 3D Object...", nil)];
	[splash showWindow:self]; 
    
	roiVolumeActor = vtkActor::New();
    
    vtkMapper *map = [ROIVolumeView generateMapperForRoi: roiList.lastObject viewerController: viewer factor: factor statistics: nil];
    
    if( map)
    {
        roiVolumeActor->SetMapper(map);
        roiVolumeActor->GetProperty()->FrontfaceCullingOn();
        roiVolumeActor->GetProperty()->BackfaceCullingOn();

        map->Delete();
        
        if( [[NSUserDefaults standardUserDefaults] integerForKey: @"UseDelaunayFor3DRoi"] == 0)
        {
            DCMPix *o = [viewer.pixList objectAtIndex: 0];
            
            float cosines[ 9];
            
            [o orientation: cosines];
            
            vtkMatrix4x4 *matrice = vtkMatrix4x4::New();
            matrice->Element[0][0] = cosines[0]; matrice->Element[1][0] = cosines[1]; matrice->Element[2][0] = cosines[2]; matrice->Element[3][0] = 0;
            matrice->Element[0][1] = cosines[3]; matrice->Element[1][1] = cosines[4]; matrice->Element[2][1] = cosines[5]; matrice->Element[3][1] = 0;
            matrice->Element[0][2] = cosines[6]; matrice->Element[1][2] = cosines[7]; matrice->Element[2][2] = cosines[8]; matrice->Element[3][2] = 0;
            matrice->Element[0][3] = 0; matrice->Element[1][3] = 0; matrice->Element[2][3] = 0; matrice->Element[3][3] = 1;
            
            roiVolumeActor->SetPosition( factor*[o originX] * matrice->Element[0][0] + factor*[o originY] * matrice->Element[1][0] + factor*[o originZ]*matrice->Element[2][0], factor*[o originX] * matrice->Element[0][1] + factor*[o originY] * matrice->Element[1][1] + factor*[o originZ]*matrice->Element[2][1], factor*[o originX] * matrice->Element[0][2] + factor*[o originY] * matrice->Element[1][2] + factor*[o originZ]*matrice->Element[2][2]);
            
            roiVolumeActor->SetUserMatrix( matrice);
            matrice->Delete();
        }
        
        // *****************Texture
        NSString *location = [[NSUserDefaults standardUserDefaults] stringForKey:@"textureLocation"];
        
        if( location == nil || [location isEqualToString:@""])
            location = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"texture.tif"];
        
        vtkTIFFReader *bmpread = vtkTIFFReader::New();
        bmpread->SetFileName( [location UTF8String]);
        bmpread->Update();
        
        textureImage = vtkTexture::New();
        textureImage->SetInputConnection( bmpread->GetOutputPort());
        textureImage->InterpolateOn();
        //textureImage->Update();
        bmpread->Delete();

        roiVolumeActor->SetTexture( textureImage);
        
        if( roiVolumeActor)
        {
            roiVolumeActor->GetProperty()->SetColor(red, green, blue);
            roiVolumeActor->GetProperty()->SetSpecular(0.3);
            roiVolumeActor->GetProperty()->SetSpecularPower(20);
            roiVolumeActor->GetProperty()->SetAmbient(0.2);
            roiVolumeActor->GetProperty()->SetDiffuse(0.8);
            roiVolumeActor->GetProperty()->SetOpacity(opacity);
        }
	}
    
	[splash close];
	[splash autorelease];
}

- (BOOL) isVolume
{
	return ([roiList count]>0);
}

- (BOOL) isRoiVolumeActorComputed
{
	if(roiVolumeActor)
		return YES;
	else
		return NO;
}

- (NSValue*) roiVolumeActor
{
	if(roiVolumeActor == nil)
		[self prepareVTKActor];
	
	return [NSValue valueWithPointer:roiVolumeActor];
}

- (float) volume
{
	return volume;
}

- (NSColor*) color
{
	return color;
}

- (void) setColor: (NSColor*) c;
{
	color = c;
	red = [c redComponent];
	green = [c greenComponent];
	blue = [c blueComponent];
	opacity = [c alphaComponent];
	[properties setValue:color forKey:@"color"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"color" forKey:@"key"]];
}

- (float) red
{
	return red;
}

- (void) setRed: (float) r
{
	red = r;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:red] forKey:@"red"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"red" forKey:@"key"]];
}

- (float) green
{
	return green;
}

- (void) setGreen: (float) g
{
	green = g;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:green] forKey:@"green"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"green" forKey:@"key"]];
}

- (float) blue
{
	return blue;
}

- (void) setBlue: (float) b
{
	blue = b;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetColor(red, green, blue);
	[properties setValue:[NSNumber numberWithFloat:blue] forKey:@"blue"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"blue" forKey:@"key"]];
}

- (float) opacity
{
	return opacity;
}

- (void) setOpacity: (float) o
{
	opacity = o;
	color = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:opacity];
	if( roiVolumeActor) roiVolumeActor->GetProperty()->SetOpacity(opacity);
	[properties setValue:[NSNumber numberWithFloat:opacity] forKey:@"opacity"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"opacity" forKey:@"key"]];
}

- (BOOL) texture
{
	return textured;
}

- (void) setTexture: (BOOL) o
{
	textured = o;
	
	if( roiVolumeActor)
	{
		if( o) roiVolumeActor->SetTexture( textureImage);
		else roiVolumeActor->SetTexture( nil);
	}
	[properties setValue:[NSNumber numberWithBool: textured] forKey:@"texture"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"texture" forKey:@"key"]];
}

- (BOOL) visible
{
	return visible;
}

- (void) setVisible: (BOOL) d
{	
	visible = d;
	[properties setValue:[NSNumber numberWithBool:visible] forKey:@"visible"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIVolumePropertiesChangedNotification object:self userInfo:[NSDictionary dictionaryWithObject:@"visible" forKey:@"key"]];
}

- (NSString*) name
{
	return name;
}

- (NSDictionary*) properties
{
	return properties;
}

- (NSMutableDictionary*)displayProperties;
{
	NSMutableDictionary *displayProperties = [NSMutableDictionary dictionary];
	[displayProperties setValue:[properties valueForKey:@"color"] forKey:@"color"];
	[displayProperties setValue:[properties valueForKey:@"red"] forKey:@"red"];
	[displayProperties setValue:[properties valueForKey:@"green"] forKey:@"green"];
	[displayProperties setValue:[properties valueForKey:@"blue"] forKey:@"blue"];
	[displayProperties setValue:[properties valueForKey:@"opacity"] forKey:@"opacity"];
	[displayProperties setValue:[properties valueForKey:@"texture"] forKey:@"texture"];
	[displayProperties setValue:[properties valueForKey:@"visible"] forKey:@"visible"];

	return displayProperties;
}

- (void)setDisplayProperties:(NSDictionary*)newProperties;
{
	[self setColor:[newProperties valueForKey:@"color"]];
	[self setRed:[[newProperties valueForKey:@"red"] floatValue]];
	[self setGreen:[[newProperties valueForKey:@"green"] floatValue]];
	[self setBlue:[[newProperties valueForKey:@"blue"] floatValue]];
	[self setOpacity:[[newProperties valueForKey:@"opacity"] floatValue]];
	[self setTexture:[[newProperties valueForKey:@"texture"] boolValue]];
	[self setVisible:[[newProperties valueForKey:@"visible"] boolValue]];
}

@end
