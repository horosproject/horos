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
 OsirX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 =========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "MPR2DController.h"
#import "MPR2DView.h"
#import "DCMPix.h"
#import "altivecFunctions.h"
#import "DCMPix.h"
#include <Accelerate/Accelerate.h>
#import "DCMView.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/CGLCurrent.h>

#define MINIMUMINTERVAL 0.3

static		float				deg2rad = 3.14159265358979/180.0; 
static		NSTimeInterval		interval = 0;


/*
   Rotate a point p by angle theta around an arbitrary axis r
   Return the rotated point.
   Positive angles are anticlockwise looking down the axis
   towards the origin.
   Assume right hand coordinate system.
*/
XYZ ArbitraryRotate(XYZ p,double theta,XYZ r)
{
   XYZ q = {0.0,0.0,0.0};
   float costheta,sintheta;

//   Normalise(&r);
   costheta = cos(theta);
   sintheta = sin(theta);

   q.x += (costheta + (1 - costheta) * r.x * r.x) * p.x;
   q.x += ((1 - costheta) * r.x * r.y - r.z * sintheta) * p.y;
   q.x += ((1 - costheta) * r.x * r.z + r.y * sintheta) * p.z;

   q.y += ((1 - costheta) * r.x * r.y + r.z * sintheta) * p.x;
   q.y += (costheta + (1 - costheta) * r.y * r.y) * p.y;
   q.y += ((1 - costheta) * r.y * r.z - r.x * sintheta) * p.z;

   q.z += ((1 - costheta) * r.x * r.z - r.y * sintheta) * p.x;
   q.z += ((1 - costheta) * r.y * r.z + r.x * sintheta) * p.y;
   q.z += (costheta + (1 - costheta) * r.z * r.z) * p.z;

   return(q);
}

//#if __ppc__ || __ppc64__
//void vmax(vector float *a, vector float *b, vector float *r, long size)
//{
//		long i = size / 4;
//	
//		while(i-- > 0)
//		{
//			*r++ = vec_max( *a++, *b++);
//		}
//}
//
//
//void vmin(vector float *a, vector float *b, vector float *r, long size)
//{
//	long i = size / 4;
//	
//	while(i-- > 0)
//	{
//		*r++ = vec_min( *a++, *b++);
//	}
//}
//#endif
//
//void vmaxNoAltivec(float *a, float *b, float *r, long size)
//{
//	long i = size;
//	
//	while(i-- > 0)
//	{
//		if( *a > *b) { *r++ = *a++; b++; }
//		else { *r++ = *b++; a++; }
//	}
//}
//
//void vminNoAltivec( float *a,  float *b,  float *r, long size)
//{
//	long i = size;
//	
//	while(i-- > 0)
//	{
//		if( *a < *b) { *r++ = *a++; b++; }
//		else { *r++ = *b++; a++; }
//	}
//}

@implementation MPR2DView

-(void) setOrientationVector:(long) x
{
	orientationVector = x;
}

- (void) applyOrientation
{
	DCMView		*oView = [[[self window] windowController] originalView];

	NSLog( @"Orientation: %d", orientationVector);
	switch( orientationVector)
	{
		case 1:
			[finalView setRotation: 90];
			[finalViewBlending setRotation: 90];
			
			[perpendicularView setMPRAngle: 180];
		break;
		
		case 2:
			[perpendicularView setRotation: 180];
			[oView setMPRAngle: 180];
			
			[finalView setRotation: 180];
			[finalViewBlending setRotation: 180];
		break;
		
		case eAxialPos:
			[perpendicularView setRotation: 90];
		break;
		
		case eAxialNeg:
			[perpendicularView setRotation: -90];
			[finalView setYFlipped: YES];
			[finalViewBlending setYFlipped: YES];
		break;
		
		default:
			NSLog( @"Orientation Unknown: %d", orientationVector);
		break;
	}
}

-(void) normalize: (float *)v : (float *)v2
{
	float length = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);

   // too close to 0, can't make a normalized vector
   if (length < .000001)
      return;

   v2[0] = v[ 0] / length;
   v2[1] = v[ 1] / length;
   v2[2] = v[ 2] / length;
}

- (void) vectorCross: (float *) s1 :(float *) s2 :(float *) d
{
	d[ 0] = (s1[1] * s2[2]) - (s1[2] * s2[1]);
	d[ 1] = (s1[2] * s2[0]) - (s1[0] * s2[2]);
	d[ 2] = (s1[0] * s2[1]) - (s1[1] * s2[0]);
}

-(void) angleBetween: (float*) v1 :(float*)  v2 :(float*)  axis :(float*) angle
{
	float	n1[3], n2[3];
	
	// turn vectors into unit vectors 
	[self normalize: v1 : n1];
	[self normalize: v2 : n2];
	
	*angle = acos( n1[0]*n2[0] + n1[1]*n2[1] + n1[2]*n2[2]);
	
	NSLog(@"Angle: %2.2f", *angle/deg2rad);
	
	//angle = Math.acos( sfvec3f.dot(n1,n2) );
	
	// if no noticable rotation is available return zero rotation
	// this way we avoid Cross product artifacts 
	if( fabs( *angle) < 0.0001 )
	{
		NSLog(@"No rotation");
		axis[ 0] = 0;	axis[ 1] = 0;	axis[ 2] = 0;	*angle = 0;
	}
	
	// in this case there are 2 lines on the same axis 
	if( fabs( fabs( *angle) - 3.1415926) < 0.001)
	{ 
		NSLog(@"Same axis");
	//	n1 = n1.Rotx( 0.5f ); 
		// there are an infinite number of normals 
		// in this case. Anyone of these normals will be 
		// a valid rotation (180 degrees). so I rotate the curr axis by 0.5 radians this way we get one of these normals 
  }
	
	[self vectorCross:n1 :n2 :axis];
}

-(void) axView:(id) sender
{
//	if( blendingController)
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(blendingCoronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(blendingSaggital);
//		if( [bax state] == NSOffState) aRenderer->AddActor(blendingAxial);
//	}
//	else
//	{
//		if( [bcor state] == NSOnState) aRenderer->RemoveActor(coronal);
//		if( [bsag state] == NSOnState) aRenderer->RemoveActor(saggital);
//		if( [bax state] == NSOffState) aRenderer->AddActor(axial);
//	}
//	
//	[bcor setState:NSOffState];
//	[bsag setState:NSOffState];
//	[bax setState:NSOnState];
	
	aCamera->SetFocalPoint (0, 0, 0);
	aCamera->SetPosition (0, 0, -1);
	aCamera->ComputeViewPlaneNormal();
	aCamera->SetViewUp(0, -1, 0);
	aCamera->OrthogonalizeViewUp();
//	aRenderer->ResetCamera();
	
//	[self setNeedsDisplay:YES];
}

-(BOOL) acceptsFirstMouse:(NSEvent*) theEvent
{
	return YES;
}

- (void) CloseViewerNotification: (NSNotification*) note
{
	if([note object] == blendingController) // our blended serie is closing itself....
	{
		[self setBlendingPixSource:nil];
	}
}

-(id)initWithFrame:(NSRect)frame
{
	
    if ( self = [super initWithFrame:frame] )
    {
		mouseUpMessagePending = NO;
		interval = 0;
		currentTool = tZoom;
		blendingFactor = 0.5;
		blendingAxial = nil;
		firstTime = YES;
		firstTimeBlending = YES;
		thickSlabMode = 0;
		thickSlab = 2;
		thickSlabGap = 2;
		blendingSliceTransform = nil;
		
		thickSlabCtl = [[ThickSlabController alloc] init];
		
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
				 
		[[NSNotificationCenter defaultCenter] addObserver: self
           selector: @selector(crossMove:)
               name: @"crossMove"
             object: nil];
			 
		[nc addObserver: self
			   selector: @selector(OpacityChanged:)
				   name: @"OpacityChanged"
				 object: nil];

    }
    
	reader = nil;
	
//	long negativeOne = -1;
//	[[self openGLContext] setValues:&negativeOne forParameter:NSOpenGLCPSurfaceOrder];
//	[[self window] setOpaque:NO];
//	[[self window] setAlphaValue:.5f];

//	long swap = 1;
//    [[self openGLContext] setValues:&swap forParameter:NSOpenGLCPSwapInterval];

	slicePt[ 0] = slicePt[ 1] = slicePt[ 2] = 0;
	line = nil;


    return self;
}

-(void)dealloc
{
    NSLog(@"Dealloc MPRView2D");
    [[NSNotificationCenter defaultCenter] removeObserver: self];
		
	[self setBlendingPixSource:nil];
	
	if( reader)
	{
		if( [firstObject isRGB]) free( dataFRGB);
	
		reader->Delete();
	//	outlineData->Delete();
	//	mapOutline->Delete();
	//	outlineRect->Delete();
		
		bwLut->Delete();
//		saggitalColors->Delete();
//		saggital->Delete();
		axialColors->Delete();
		axial->Delete();
//		coronalColors->Delete();
//		coronal->Delete();
		
		rotate->Delete();
		rotatePerpendicular->Delete();
		perpendicularSliceTransform->Delete();
		//changeImageInfo->Delete();
		
		sliceTransform->Delete();
		
		aCamera->Delete();
		
//		aRenderer->Delete();
		[pixList release];
		pixList = nil;
		
		[filesList release];
		filesList = nil;
		
		[perPixList release];
		perPixList = nil;
		
		[finalPixList release];
		finalPixList = nil;
		
		[finalPixListBlending release];
		finalPixListBlending = nil;
		
		[thickSlabCtl release];
		thickSlabCtl = nil;
	}
	
    [super dealloc];
}

/*- (void) mouseDown:(NSEvent *)theEvent
{
    BOOL		keepOn = YES;
    NSPoint		mouseLoc, mouseLocStart;
	short		tool;
	
	tool = currentTool;
	
        if (([theEvent modifierFlags] & NSControlKeyMask))  tool = tZoom;
        if (([theEvent modifierFlags] & NSCommandKeyMask))  tool = tTranslate;
		if (([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tWL;
        if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask))  tool = tRotate;

//	if( tool == tWL)
//	{
//		mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
//		
//		vtkPicker   *picker = vtkPicker::New();
//		if( picker->Pick(mouseLocStart.x, mouseLocStart.y, 0, aRenderer))
//		{
//			long x, y, z;
//			NSLog(@"Yeahh");
//			
//			vtkPoints *points = picker->GetPickedPositions();
//			double *pp = points->GetPoint( 0);
//			
//			slicePt[ 0] = pp[ 0];
//			slicePt[ 1] = pp[ 1];
//			slicePt[ 2] = pp[ 2];
//			
//			line->SetPoint1( slicePt[ 0], slicePt[ 1], slicePt[ 2]);
//			
//			NSLog(@"%0.2f %0.2f %0.2f", slicePt[ 0], slicePt[ 1], slicePt[ 2]);
//		}
//	}
//    else 
	if (tool == tNext)
	{
		short   inc, now, prev, previmage;
		
		do
		{
			NSPoint mouseLocPrev;
			
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
            mouseLoc = mouseLocPrev = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			
			switch ([theEvent type])
            {
				case NSLeftMouseDragged:
					
					if( mouseLoc.x < mouseLocPrev.x) inc = -2;
					else inc = 2;
					
					[self scrollWheelInt: inc];
					
				break;
				
				case NSLeftMouseUp:
					
					keepOn = NO;
				return;
					
				case NSPeriodic:
					
				break;
					
				default:
				
				break;
			}
		}while (keepOn);
	}
	else if( tool == tWL)
    {
        double fdata[2];
        mouseLocStart = [self convertPoint: [theEvent locationInWindow] fromView:nil];
        
        bwLut->GetTableRange( fdata);
        
        do
		{
            theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
            mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
            switch ([theEvent type])
            {
            case NSLeftMouseDragged:
			{
                double newValues[2];
                float   WWAdapter;
				
				WWAdapter  = (fdata[1] - fdata[0]) / 100.0;
				
                newValues[0] = fdata[0]+(mouseLoc.y - mouseLocStart.y + (mouseLocStart.x - mouseLoc.x)) *WWAdapter;
                newValues[1] = fdata[1]+(mouseLoc.y - mouseLocStart.y - (mouseLocStart.x - mouseLoc.x)) *WWAdapter;
                
                if( newValues[0] > newValues[1]) newValues[0] = newValues[1];
                
                bwLut->SetTableRange (newValues[0], newValues[1]);
				
				[[[[self window] windowController] originalView] setWLWW:newValues[0] + (newValues[1] - newValues[0])/2  :newValues[1] - newValues[0]];
				[perpendicularView setWLWW:newValues[0] + (newValues[1] - newValues[0])/2  :newValues[1] - newValues[0]];
				
                [self setNeedsDisplay:YES];
			}
            break;
			
            case NSLeftMouseUp:
                
                keepOn = NO;
                return;
                
            case NSPeriodic:
                
                break;
                
            default:
                break;
            }
        }while (keepOn);
    }
	else if( tool == tRotate)
	{
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		myVTKRenderWindowInteractor->SetEventInformation( (int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			myVTKRenderWindowInteractor->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == t3DRotate)
	{
		int shiftDown = 0;
		int controlDown = 0;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		myVTKRenderWindowInteractor->SetEventInformation( (int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
		myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			myVTKRenderWindowInteractor->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tTranslate)
    {
		int shiftDown = 1;
		int controlDown = 0;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		myVTKRenderWindowInteractor->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			myVTKRenderWindowInteractor->SetEventInformation((int) mouseLoc.x, (int) mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
	else if( tool == tZoom)
    {
		int shiftDown = 0;
		int controlDown = 1;

		mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
		myVTKRenderWindowInteractor->SetEventInformation((int) mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
		myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::RightButtonPressEvent,NULL);
		
		do {
			theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask];
			mouseLoc = [self convertPoint: [theEvent locationInWindow] fromView:nil];
			myVTKRenderWindowInteractor->SetEventInformation((int)mouseLoc.x, (int)mouseLoc.y, controlDown, shiftDown);
			switch ([theEvent type]) {
			case NSLeftMouseDragged:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::MouseMoveEvent, NULL);
				break;
			case NSLeftMouseUp:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::LeftButtonReleaseEvent, NULL);
				keepOn = NO;
				return;
			case NSPeriodic:
				myVTKRenderWindowInteractor->InvokeEvent(vtkCommand::TimerEvent, NULL);
				break;
			default:
				break;
			}
		}while (keepOn);
	}
//    else [super mouseDown:theEvent];
    
    return;
}*/

- (void) drawRect:(NSRect)aRect
{
//			NSRect bounds = [self bounds];
//		[[NSColor clearColor] set];
//		NSRectFill(bounds);
//		
//		NSRect ovalRect = NSMakeRect(0.0, 0.0, 50.0, 50.0);
//		NSBezierPath *aPath = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
//		
//		NSColor *color = [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.3];
//		[color set];
//		
//		[aPath fill];

		[super drawRect:aRect];
		
//	[[self openGLContext] makeCurrentContext];
//	[[self openGLContext] update];
//	
//	 NSRect size = [self frame];
//	 
//    glViewport (0, 0, size.size.width, size.size.height); // set the viewport to cover entire window
//	
////	glClearColor(1.0f, 0.0f, 0.0f, 0.2f);
////	glClear (GL_COLOR_BUFFER_BIT);
//	glMatrixMode( GL_PROJECTION);
//	glPushMatrix();
//	glColorMaterial( GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
//	glEnable( GL_COLOR_MATERIAL );
//	glEnable( GL_LIGHTING);
//	glLoadIdentity();
//	glScalef (2.0f / size.size.width , -2.0f / size.size.height , 1.0f); // scale to port per pixel scale
//	glRotatef (0, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
//	glTranslatef( 0, 0, 0.0f);
//	
//	glColor3f (1.0f, 1.0f, 1.0f);
//	glLineWidth(5.0);
//	glBegin(GL_LINES);
//		glVertex2f( 0, 0);
//		glVertex2f( 200, 100);
//	glEnd();
//	glPopMatrix();
//	
//	glFlush();
//	
//	// Swap buffer to screen
//	[[self openGLContext] flushBuffer];


}

-(PreviewView*) finalView
{
	return finalView;
}

- (void) keyDown:(NSEvent *)event
{
    unichar c = [[event characters] characterAtIndex:0];
	if( c == 27)
	{
		[[[self window] windowController] offFullScreen];
	}
	
	[super keyDown:event];
}

-(void) setBlendingWLWW:(float) wl :(float) ww
{
//    double newValues[2];
//    
//    newValues[0] = wl - ww/2;
//    newValues[1] = wl + ww/2;
//    
//    blendingBwLut->SetTableRange (newValues[0], newValues[1]);

	[finalViewBlending setWLWW: wl :ww];

//    [self setNeedsDisplay:YES];
}

-(void) setBlendingFactor:(float) a
{
	
	blendingFactor = a;
	
	[finalView setBlendingFactor: blendingFactor];
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	
//	if( r)
//	{
//		for( i = 0; i < 256; i++)
//		{
//			RGBA = blendingBwLut->GetTableValue( i);
//			blendingBwLut->SetTableValue(i, r[i] / 255., g[i] / 255., b[i] / 255., RGBA[3]);
//		}
//	}
//	else
//	{
//		for( i = 0; i < 256; i++)
//		{
//			RGBA = blendingBwLut->GetTableValue( i);
//			blendingBwLut->SetTableValue(i,i / 255., i / 255., i / 255., RGBA[3]);
//		}
//	}
	
	[thickSlabCtl setBlendingCLUT:r :g :b];
	
	if( thickSlabMode == 4 || thickSlabMode == 5)
	{
		[finalView setCLUT:nil :nil: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
	}
	else
	{
		[finalViewBlending setCLUT: r :g :b];		[finalViewBlending setIndex:[finalViewBlending curImage]];
	}
}


-(void) setOpacity:(NSArray*) array
{
	[thickSlabCtl setOpacity: array];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

- (void) OpacityChanged: (NSNotification*) note
{
	[thickSlabCtl setOpacity: [[note object] getPoints]];
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{

//	if( r)
//	{
//		for( i = 0; i < 256; i++)
//		{
//			bwLut->SetTableValue(i, r[i] / 255., g[i] / 255., b[i] / 255., 1.0);
//		}
//	}
//	else
//	{
//		for( i = 0; i < 256; i++)
//		{
//			bwLut->SetTableValue(i,i / 255., i / 255., i / 255., 1.0);
//		}
//	}
	
	DCMView		*oView = [[[self window] windowController] originalView];
	
	[oView setCLUT:r :g: b];				[oView setIndex:[oView curImage]];
	[perpendicularView setCLUT:r :g: b];	[perpendicularView setIndex:[perpendicularView curImage]];
	
	if( thickSlabMode == 4 || thickSlabMode == 5)
	{
		[thickSlabCtl setCLUT:r :g :b];
		
		[finalView setCLUT:nil :nil: nil];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
//		[finalView setWLWW: 127 :255];
	}
	else
	{
		[finalView setCLUT:r :g: b];			[finalView setIndex:[finalView curImage]];
	}
}

-(void) setCurrentTool:(short) i
{
    currentTool = i;
	
	[perpendicularView setCurrentTool: i];
	[finalView setCurrentTool: i];
}

- (void) adjustWLWW: (float) iwl :(float) iww :(NSString*) mode
{
	[[[[self window] windowController] originalView] setWLWW:iwl  :iww];
	[perpendicularView setWLWW:iwl  :iww];
	bwLut->SetTableRange (iwl - iww/2, iwl + iww/2);
	
	if( thickSlabMode == 4 || thickSlabMode == 5)
	{
		NSLog( mode);
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:mode forKey:@"action"]];
//		[finalView setWLWW: 127 :255];
	}

	[finalView setWLWW: iwl :iww];
}

- (void) getWLWW:(float*) wl :(float*) ww
{
    double newValues[2];

    bwLut->GetTableRange ( newValues);
    
    *wl = (newValues[0] + (newValues[1] - newValues[0])/2);
    *ww = (newValues[1] - newValues[0]);
}


-(void) setBlendingPixSource:(ViewerController*) bC
{
	
	blendingController = bC;
	
	if( blendingController)
	{
		blendingPixList = [bC pixList];
		[blendingPixList retain];
		
		filesListBlending = [bC fileList];
		[filesListBlending retain];
		
		blendingData = [bC volumePtr];
		
		blendingFirstObject = [blendingPixList objectAtIndex:0];
		
		blendingSliceThickness = [blendingFirstObject sliceInterval];//	[[blendingPixList objectAtIndex:1] sliceLocation] - [blendingFirstObject sliceLocation];
		
		if( blendingSliceThickness == 0)
		{
			NSLog(@"Blending slice interval = slice thickness!");
			blendingSliceThickness = [blendingFirstObject sliceThickness];
		}
		
		// PLAN 
		[blendingFirstObject orientation:blendingVectors];
		
		if( blendingVectors[6] + blendingVectors[7] + blendingVectors[8] < 0)
		{
			NSLog(@"Oposite Vector!");
		//	blendingSliceThickness = -blendingSliceThickness;
		}

		blendingReader = vtkImageImport::New();
		blendingReader->SetWholeExtent( 0, [blendingFirstObject pwidth]-1, 0, [blendingFirstObject pheight]-1, 0, [blendingPixList count]-1);
		blendingReader->SetDataSpacing( [blendingFirstObject pixelSpacingX], [blendingFirstObject pixelSpacingY], blendingSliceThickness);//sliceThickness
		blendingReader->SetDataOrigin(  ([blendingFirstObject originX] ) * blendingVectors[0] + ([blendingFirstObject originY]) * blendingVectors[1] + ([blendingFirstObject originZ] )*blendingVectors[2],
										([blendingFirstObject originX] ) * blendingVectors[3] + ([blendingFirstObject originY]) * blendingVectors[4] + ([blendingFirstObject originZ] )*blendingVectors[5],
										([blendingFirstObject originX] ) * blendingVectors[6] + ([blendingFirstObject originY]) * blendingVectors[7] + ([blendingFirstObject originZ] )*blendingVectors[8]);
//		blendingReader->SetDataOrigin(  [blendingFirstObject originX],[blendingFirstObject originY],[blendingFirstObject originZ]);
		blendingReader->SetDataExtentToWholeExtent();
		blendingReader->SetDataScalarTypeToFloat();
		blendingReader->SetImportVoidPointer(blendingData);
		
		// FINAL IMAGE RESLICE
		
		blendingRotate = vtkImageReslice::New();
		blendingRotate->SetAutoCropOutput( true);
		blendingRotate->SetInformationInput( blendingReader->GetOutput());
		blendingRotate->SetInput( blendingReader->GetOutput());
		blendingRotate->SetOptimization( true);
		
		blendingSliceTransform = vtkTransform::New();
		blendingSliceTransform->Identity();
		
		{
			float temp[ 3];
			
			[self angleBetween: blendingVectors : vectors :blendingAxis :&blendingAngle];
			
			temp[ 0] = blendingAxis[ 0];
			temp[ 1] = blendingAxis[ 1];
			temp[ 2] = blendingAxis[ 2];
			
			blendingAxis[ 0] = temp[ 0]*blendingVectors[0] + temp[ 1]*blendingVectors[1] + temp[ 2]*blendingVectors[2];
			blendingAxis[ 1] = temp[ 0]*blendingVectors[3] + temp[ 1]*blendingVectors[4] + temp[ 2]*blendingVectors[5];
			blendingAxis[ 2] = temp[ 0]*blendingVectors[6] + temp[ 1]*blendingVectors[7] + temp[ 2]*blendingVectors[8];
			
			blendingAngle = blendingAngle / deg2rad;
			
			NSLog(@"axis: %2.2f, %2.2f, %2.2f Angle: %2.2f", blendingAxis[ 0], blendingAxis[ 1], blendingAxis[ 2], blendingAngle);
			
			[self angleBetween: blendingVectors+3 : vectors+3 :blendingAxis2 :&blendingAngle2];
			
			temp[ 0] = blendingAxis2[ 0];
			temp[ 1] = blendingAxis2[ 1];
			temp[ 2] = blendingAxis2[ 2];
			
			blendingAxis2[ 0] = temp[ 0]*blendingVectors[0] + temp[ 1]*blendingVectors[1] + temp[ 2]*blendingVectors[2];
			blendingAxis2[ 1] = temp[ 0]*blendingVectors[3] + temp[ 1]*blendingVectors[4] + temp[ 2]*blendingVectors[5];
			blendingAxis2[ 2] = temp[ 0]*blendingVectors[6] + temp[ 1]*blendingVectors[7] + temp[ 2]*blendingVectors[8];
			
			blendingAngle2 = blendingAngle2 / deg2rad;
			
			NSLog(@"axis: %2.2f, %2.2f, %2.2f Angle: %2.2f", blendingAxis2[ 0], blendingAxis2[ 1], blendingAxis2[ 2], blendingAngle2);
		}
		
		blendingRotate->SetResliceTransform( blendingSliceTransform);
		
	//	blendingRotate->SetTransformInputSampling( false);
		blendingRotate->SetInterpolationModeToLinear();	//SetInterpolationModeToCubic();
		blendingRotate->SetOutputDimensionality( 2);
		blendingRotate->SetBackgroundLevel( -1024);
		blendingRotate->SetOutputExtent( 0, FOV, 0, FOV, 0, 0);
		
		rotate->Update();
		blendingRotate->SetOutputSpacing( rotate->GetOutput()->GetSpacing());
		blendingRotate->SetOutputOrigin( rotate->GetOutput()->GetOrigin());
		blendingRotate->SetOutputExtent( rotate->GetOutput()->GetExtent());
		
		// X - Y - Z planes
		
		blendingBwLut = vtkLookupTable::New();  
		blendingBwLut->SetTableRange (0, 30000);
		blendingBwLut->SetNumberOfTableValues(256);
//		for( i = 0; i < 256; i++)
//		{
//			blendingBwLut->SetTableValue(i, i / 256., i / 256., i / 256., 1);
//		}
		[self setBlendingFactor: blendingFactor];
		
		
		// ******************* SAG
//		slice = vtkImageReslice::New();
//		slice->SetInput( blendingReader->GetOutput());
//		
//		slice->SetResliceAxesDirectionCosines(  blendingVectors[0], blendingVectors[3], blendingVectors[6],
//												blendingVectors[1], blendingVectors[4], blendingVectors[7],
//												blendingVectors[2], blendingVectors[5], blendingVectors[8]);
//		slice->SetInterpolationModeToCubic();		// SetInterpolationModeToNearestNeighbor //SetInterpolationModeToCubic();
//		slice->SetOutputSpacing( rotate->GetOutput()->GetSpacing());
//		slice->SetOutputOrigin( rotate->GetOutput()->GetOrigin());
//		slice->SetOutputExtent( rotate->GetOutput()->GetExtent());
//			
//		
//		//	slice->SetOptimization( false);
//		slice->SetResliceTransform( sliceTransform);
//	//	slice->SetTransformInputSampling( false);
//		slice->SetOutputDimensionality( 2);
//		slice->SetBackgroundLevel( -1024);
//
//		slice->Update();
		
		// *******************
		
		blendingAxialColors = vtkImageMapToColors::New();
		blendingAxialColors->SetInput(blendingRotate->GetOutput());
		blendingAxialColors->SetLookupTable(blendingBwLut);
		
//		slice->Delete();

		// *******************  SAG
		
		vtkImageBlend		*blender;
		
		blender = vtkImageBlend::New();
		blender->SetInput(0, axialColors->GetOutput());				blender->SetOpacity(0, 1.0);
		blender->SetInput(1, blendingAxialColors->GetOutput());		blender->SetOpacity(1, 1.0);

		blendingAxial = vtkImageActor::New();
		blendingAxial->SetInput(blender->GetOutput());  // blender
		
		blender->Delete();
		//
		
//		[[[self window] windowController] sliderAction:self];
		
	//	aRenderer->RemoveActor(axial);
	//	aRenderer->AddActor(blendingAxial);
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
	}
	else
	{
		if( blendingAxial)
		{
			blendingBwLut->Delete();
			blendingAxialColors->Delete();
			blendingAxial->Delete();
			blendingRotate->Delete();
			blendingReader->Delete();
			
			if( blendingSliceTransform) blendingSliceTransform->Delete();
			
			blendingAxial = nil;
			
			[blendingPixList release];
			[filesListBlending release];
		}
	}
}

-(void) movieBlendingChangeSource
{
	if( blendingController)
	{
		blendingData = [blendingController volumePtr];
		blendingReader->SetImportVoidPointer( blendingData);
	}
}

-(void) movieChangeSource:(float*) volumeData
{
	data = volumeData;

	reader->SetImportVoidPointer(data);

	[self movieBlendingChangeSource];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Update" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(void) set3DStateDictionary:(NSDictionary*) dict
{
	float		temp[ 3];
	DCMView		*oView = [[[self window] windowController] originalView];
	
	if( dict)
	{
		[self adjustWLWW: [[dict objectForKey:@"WL"] floatValue] :[[dict objectForKey:@"WW"] floatValue] :@"set"];
		
		[oView setMPRAngle: [[dict objectForKey:@"angle"] floatValue]];
		[perpendicularView setMPRAngle: [[dict objectForKey:@"angle2"] floatValue]];
		
		NSPoint origin;
		origin.x = [[dict objectForKey:@"origin1-x"] floatValue];		origin.y = [[dict objectForKey:@"origin1-y"] floatValue];
		[oView setOrigin: origin];
		[oView setScaleValue: [[dict objectForKey:@"scale1"] floatValue]];
		[oView setRotation: [[dict objectForKey:@"rotation1"] floatValue]];
		[oView setIndex: [[dict objectForKey:@"index"] intValue]];
		[oView sliderAction2DMPR:[dict objectForKey:@"index"]];
		[[[self window] windowController] adjustSlider];
		[oView setCrossCoordinates:[[dict objectForKey:@"cross-x"] intValue] :[[dict objectForKey:@"cross-y"] intValue] :NO];
		
		origin.x = [[dict objectForKey:@"origin2-x"] floatValue];		origin.y = [[dict objectForKey:@"origin2-y"] floatValue];
		[perpendicularView setOrigin: origin];
		[perpendicularView setScaleValue: [[dict objectForKey:@"scale2"] floatValue]];
		[perpendicularView setRotation: [[dict objectForKey:@"rotation2"] floatValue]];

		if( [dict objectForKey:@"origin3-x"])
		{
			origin.x = [[dict objectForKey:@"origin3-x"] floatValue];		origin.y = [[dict objectForKey:@"origin3-y"] floatValue];
			[finalView setOrigin: origin];
			[finalView setScaleValue: [[dict objectForKey:@"scale3"] floatValue]];
			[finalView setRotation: [[dict objectForKey:@"rotation3"] floatValue]];
		}
		
		if( [dict objectForKey:@"pt3Dx"] && [dict objectForKey:@"pt3Dy"] && [dict objectForKey:@"pt3Dz"])
		{
			float s[ 3];
			temp[ 0] = [[dict objectForKey:@"pt3Dx"] floatValue];
			temp[ 1] = [[dict objectForKey:@"pt3Dy"] floatValue];
			temp[ 2] = [[dict objectForKey:@"pt3Dz"] floatValue];
			
			
			NSLog( @"3D cross position: %f %f %f", temp[ 0], temp[ 1], temp[ 2]);
			
			
			float resultPoint[ 3];
			int index = [oView findPlaneAndPoint: temp :resultPoint];
			
			[[pixList objectAtIndex: index] convertDICOMCoords: resultPoint toSliceCoords: s];
			
			s[ 0] /= [firstObject pixelSpacingX];
			s[ 1] /= [firstObject pixelSpacingY];
			s[ 2] /= sliceThickness;
			
			NSLog( @"sliceThickness: %f", sliceThickness);
			
			NSLog( @"2D position: %f %f %d", s[ 0], s[ 1], index);
			
//			int index = s[ 2];
//			
//			[[pixList objectAtIndex: index] convertPixX: s[ 0] pixY: s[ 1] toDICOMCoords: temp];
//			NSLog( @"3D cross position: %f %f %f", temp[ 0], temp[ 1], temp[ 2]);
//			
//			if( index < 0) NSLog( @"index < 0");
//			if( index >= [pixList count]) NSLog( @"index >= [pixList count]");
//			
			NSLog( @"********** FLIPPED DATA: %d", [oView flippedData]);

			if( [oView flippedData]) index = [pixList count] -1 -index;
			
			[oView setIndex: index];
			[oView sliderAction2DMPR: [NSNumber numberWithInt: index]];
			[[[self window] windowController] adjustSlider];
			
			[oView setCrossCoordinates: s[ 0] :-s[ 1] : NO];
			
			NSLog( @"oView.cross.x: %f oView.cross.y: %f", oView.cross.x, oView.cross.y);
		}
		
		if( [dict objectForKey:@"orientation"])
		{
			int previousOrientation = [[dict objectForKey:@"orientation"] intValue];
			int currentOrientation = [[[[self window] windowController] viewerController] currentOrientationTool];
			
			NSLog( @"previousOrientation: %d currentOrientation: %d", previousOrientation, currentOrientation);
			
			if( previousOrientation != currentOrientation)
			{
				[oView setOrigin: NSMakePoint(0, 0)];
				[finalView setOrigin: NSMakePoint(0, 0)];
				[perpendicularView setOrigin: NSMakePoint(0, 0)];
			}
			
			switch( previousOrientation)
			{
				/////////////////////////////////////
				
				case 0:
					switch( currentOrientation)
					{
						case 1:
							[perpendicularView setRotation: 90 + [perpendicularView rotation]];
							[finalView setRotation: 180 + [finalView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] + 180];
						break;
						
						case 2:
							[perpendicularView setRotation: 90 + [perpendicularView rotation]];
							[finalView setRotation: -90 + [finalView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] + 180];
						break;
					}
				break;
				
				/////////////////////////////////////
				
				case 1:
					switch( currentOrientation)
					{
						case 0:
							[perpendicularView setRotation: -90 + [perpendicularView rotation]];
							[finalView setRotation: -180 + [finalView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] - 180];
						break;
						
						case 2:
							[finalView setRotation: -90 + [finalView rotation]];
							[perpendicularView setRotation: 180 + [perpendicularView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] - 180];
							[perpendicularView setMPRAngle: [perpendicularView MPRAngle] - 180];
						break;
					}
				break;
				
				/////////////////////////////////////
				
				case 2:
					switch( currentOrientation)
					{
						case 0:
							[perpendicularView setRotation: -90 + [perpendicularView rotation]];
							[finalView setRotation: 90 + [finalView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] - 180];
						break;
						
						case 1:
							[finalView setRotation: 90 + [finalView rotation]];
							[perpendicularView setRotation: -180 + [perpendicularView rotation]];
							
							[oView setMPRAngle: [oView MPRAngle] + 180];
							[perpendicularView setMPRAngle: [perpendicularView MPRAngle] + 180];
						break;
					}
				break;
			}
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
	}
	else
	{
		[oView setOrigin: NSMakePoint( 0, 0)];
		
		[oView setScaleValue: 1.0];
		[oView setRotation: 0];
		[oView setIndex: [[oView dcmPixList] count] /2];
		[[[self window] windowController] adjustSlider];
		[oView setCrossCoordinates: [firstObject pwidth]/2 : -[firstObject pheight]/2 :NO];
		
		[perpendicularView setOrigin: NSMakePoint( 0, 0)];
		[perpendicularView setScaleValue: 1.0];

		[finalView setOrigin: NSMakePoint( 0, 0)];
		[finalView setScaleValue: 1.0];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
	}
}

-(NSMutableDictionary*) get3DStateDictionary
{
	float		angle, angle2;
	float		temp[3];
	float		xval, yval;
	float		iwl, iww;
	DCMView		*oView = [[[self window] windowController] originalView];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	[perpendicularView getWLWW:&iwl  :&iww];
	
	[dict setObject:[NSNumber numberWithFloat:iwl] forKey:@"WL"];
	[dict setObject:[NSNumber numberWithFloat:iww] forKey:@"WW"];

	angle = [oView angle];
	angle2 = [perpendicularView angle];
	
	[dict setObject:[NSNumber numberWithFloat:angle] forKey:@"angle"];
	[dict setObject:[NSNumber numberWithFloat:angle2] forKey:@"angle2"];
	
	[oView getCrossCoordinates : &xval :&yval];
	[dict setObject:[NSNumber numberWithLong: (long) xval] forKey:@"cross-x"];
	[dict setObject:[NSNumber numberWithLong: (long) yval] forKey:@"cross-y"];
	
	[dict setObject:[NSNumber numberWithFloat:[oView origin].x] forKey:@"origin1-x"];
	[dict setObject:[NSNumber numberWithFloat:[oView origin].y] forKey:@"origin1-y"];
	[dict setObject:[NSNumber numberWithFloat:[oView scaleValue]] forKey:@"scale1"];
	[dict setObject:[NSNumber numberWithFloat:[oView rotation]] forKey:@"rotation1"];
	[dict setObject:[NSNumber numberWithLong:[oView curImage]] forKey:@"index"];
	
	[dict setObject:[NSNumber numberWithFloat:[perpendicularView origin].x] forKey:@"origin2-x"];
	[dict setObject:[NSNumber numberWithFloat:[perpendicularView origin].y] forKey:@"origin2-y"];
	[dict setObject:[NSNumber numberWithFloat:[perpendicularView scaleValue]] forKey:@"scale2"];
	[dict setObject:[NSNumber numberWithFloat:[perpendicularView rotation]] forKey:@"rotation2"];
	
	[dict setObject:[NSNumber numberWithFloat:[finalView origin].x] forKey:@"origin3-x"];
	[dict setObject:[NSNumber numberWithFloat:[finalView origin].y] forKey:@"origin3-y"];
	[dict setObject:[NSNumber numberWithFloat:[finalView scaleValue]] forKey:@"scale3"];
	[dict setObject:[NSNumber numberWithFloat:[finalView rotation]] forKey:@"rotation3"];
	
	int index = [oView curImage];
	
	[[pixList objectAtIndex: index] convertPixX: [oView cross].x pixY: [oView cross].y toDICOMCoords: temp pixelCenter: YES];
	[dict setObject:[NSNumber numberWithFloat: temp[ 0]] forKey:@"pt3Dx"];
	[dict setObject:[NSNumber numberWithFloat: temp[ 1]] forKey:@"pt3Dy"];
	[dict setObject:[NSNumber numberWithFloat: temp[ 2]] forKey:@"pt3Dz"];
	[dict setObject:[NSNumber numberWithInt: [[[[self window] windowController] viewerController] currentOrientationTool]] forKey:@"orientation"];
	
//	NSLog( @"2D position: %f %f %d", [oView cross].x, [oView cross].y, [oView curImage]);
//	NSLog( @"3D cross position: %f %f %f", temp[ 0], temp[ 1], temp[ 2]);
//	
//	float s[ 3];
//	[firstObject convertDICOMCoords: temp toSliceCoords: s];
//	
//	s[ 0] /= [firstObject pixelSpacingX];
//	s[ 1] /= [firstObject pixelSpacingY];
//	s[ 2] /= sliceThickness;
//			
//	NSLog( @"2D position: %f %f %f", s[ 0], s[ 1], s[ 2]);

	return dict;
}


//- (void) moveSlider:(id) sender
//{
//	// Compute displacement on the original image based on the angle
//	DCMView		*oView = [[[self window] windowController] originalView];
//	float angle = [oView angle];
//	
//	float xx, yy;
//	
//	float oX, oY;
//	
//	[oView getCrossCoordinates : &oX :&oY];
//	
//	xx = ( [sender floatValue] * sin( angle*deg2rad)) + ( oX * cos( angle*deg2rad));
//	yy = ( [sender floatValue] * cos( angle*deg2rad)) + ( oY * sin( angle*deg2rad));
//	
////	if( xx < 0) xx = -xx;
////	if( yy < 0) yy = -yy;
//	
//	[oView setCrossCoordinates:xx :yy :YES];
//}

- (void) scrollWheelInt:(float) inc :(long) update
{
	DCMView		*oView = [[[self window] windowController] originalView];
	// Compute displacement on the original image based on the angle
	
	float angle = [oView angle];
	float angle2 = [perpendicularView angle];
	
	float xx, yy, zz;
	
	xx = inc * sin( angle*deg2rad);
	yy = inc * cos( angle*deg2rad);
	
	zz = inc * cos( angle2*deg2rad);
	
	
	//NSLog(@"move: %2.2f | %2.2f", xx, yy);
	
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"mouseUp" forKey:@"action"]];
	
	float oX, oY;
	
	[oView getCrossCoordinates : &oX :&oY];
	
	oX += xx;
	oY += yy;
	
	[oView setCrossCoordinates:oX :oY :update];
	
//	[slider setFloatValue: ( oX*sin( angle*deg2rad) + oY*cos( angle*deg2rad))];
}

-(void) ThickSlabSliderFinished
{
	mouseUpMessagePending = NO;
	
	NSLog(@"finished...");

	[finalView setSlab:[self thickSlab]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(IBAction) setThickSlab:(id) sender
{
	NSLog(@"start");
	
	thickSlab = [sender intValue];
	
	[textThickSlab setFloatValue: thickSlab];
	
	[finalView setSlab:[self thickSlab]];
	[perpendicularView setSlab:[self thickSlab]];
	[[[[self window] windowController] originalView] setSlab:[self thickSlab]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"dragged" forKey:@"action"]];
	
	if (! mouseUpMessagePending)
    {
        [self performSelector :@selector( ThickSlabSliderFinished)
                   withObject :nil
                   afterDelay :0];
        mouseUpMessagePending = YES;
    }
	
	NSLog( @"end");
}

-(IBAction) setThickSlabGap:(id) sender
{
	NSLog(@"start");
	
	thickSlabGap = [[sender selectedItem] tag];
//	[sender setState:NSOnState];
	
	NSLog(@"Gap: %2.2f", thickSlabGap);
	
	[finalView setSlab:[self thickSlab]];
	[perpendicularView setSlab:[self thickSlab]];
	[[[[self window] windowController] originalView] setSlab:[self thickSlab]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];

	NSLog(@"end");
}

-(float) thickSlab
{
	if( thickSlab == 1 || thickSlabMode == 0) return 0;
	else return (float) thickSlab * [firstObject pixelSpacingX] * thickSlabGap;
}

- (IBAction) setThickSlabActivated: (id) sender
{
	if( [activatedThickSlab state] == NSOnState)
	{
		[self setThickSlabMode: thickSlabPopUp];
		[sliderThickSlab setEnabled: YES];
	}
	else
	{
		[self setThickSlabMode: thickSlabPopUp];
		[sliderThickSlab setEnabled: NO];
	}
}

-(IBAction) setThickSlabMode:(id) sender
{
	thickSlabMode = [[thickSlabPopUp selectedItem] tag];
	
	if([activatedThickSlab state] == NSOffState)
		thickSlabMode = 0;
	
	[finalView setSlab:[self thickSlab]];
	[perpendicularView setSlab:[self thickSlab]];
	[[[[self window] windowController] originalView] setSlab:[self thickSlab]];

	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];

	if( thickSlabMode == 4 || thickSlabMode == 5)
	{
		[OpacityPopup setEnabled: YES];
	}
	else
	{
		[OpacityPopup setEnabled: NO];
	}
	unsigned char *r, *g, *b;
	
	[perpendicularView getCLUT: &r : &g : &b];
	[self setCLUT: r : g : b];
}

-(void) rotateX:(float*) v :(float) angle
{
	long i;
	float vv[ 6];
	
	vv[ 0] = v[ 0];
	vv[ 1] = v[ 1] * cos(angle*deg2rad) - v[ 2] * sin(angle*deg2rad);
	vv[ 2] = v[ 2] * cos(angle*deg2rad) + v[ 1] * sin(angle*deg2rad);
	
	vv[ 3] = v[ 3];
	vv[ 4] = v[ 4] * cos(angle*deg2rad) - v[ 5] * sin(angle*deg2rad);
	vv[ 5] = v[ 5] * cos(angle*deg2rad) + v[ 4] * sin(angle*deg2rad);
	
	for( i = 0; i < 6; i++) v[ i] = vv[ i];
}

-(void) rotateY:(float*) v :(float) angle
{
	long i;
	float vv[ 6];
	
	vv[ 0] = v[ 0] * cos(angle*deg2rad) - v[ 2] * sin(angle*deg2rad);
	vv[ 1] = v[ 1];
	vv[ 2] = v[ 2] * cos(angle*deg2rad) + v[ 0] * sin(angle*deg2rad);
	
	vv[ 3] = v[ 3] * cos(angle*deg2rad) - v[ 5] * sin(angle*deg2rad);
	vv[ 4] = v[ 4];
	vv[ 5] = v[ 5] * cos(angle*deg2rad) + v[ 3] * sin(angle*deg2rad);
	
	for( i = 0; i < 6; i++) v[ i] = vv[ i];
}

-(void) rotateZ:(float*) v :(float) angle
{
	long i;
	float vv[ 6];
	
	vv[ 0] = v[ 0] * cos(angle*deg2rad) - v[ 1] * sin(angle*deg2rad);
	vv[ 1] = v[ 1] * cos(angle*deg2rad) + v[ 0] * sin(angle*deg2rad);
	vv[ 2] = v[ 2];
	
	vv[ 3] = v[ 3] * cos(angle*deg2rad) - v[ 4] * sin(angle*deg2rad);
	vv[ 4] = v[ 4] * cos(angle*deg2rad) + v[ 3] * sin(angle*deg2rad);
	vv[ 5] = v[ 5];
	
	for( i = 0; i < 6; i++) v[ i] = vv[ i];
}

-(void) rotateOriginal :(float) angle
{
	DCMView			*oView = [[[self window] windowController] originalView];
	
	angle = [oView angle] + angle;
	
	if( angle > 360)
	{
		angle -= 360;
		NSLog( @"Angle > 360");
	}
	
	[oView setMPRAngle: angle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(void) rotatePerpendicular :(float) angle
{
	angle = [perpendicularView angle] + angle;
	
	if( angle > 360)
	{
		angle -= 360;
		NSLog( @"Angle > 360");
	}
	
	[perpendicularView setMPRAngle: angle];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object: @"Original" userInfo: [NSDictionary dictionaryWithObject:@"set" forKey:@"action"]];
}

-(void) crossStopMoving:(NSString*) stringID
{
	NSLog(stringID);
	[[NSNotificationCenter defaultCenter] postNotificationName: @"crossMove" object:stringID userInfo:  [NSDictionary dictionaryWithObject:@"slider" forKey:@"action"]];
}

-(void) computeFinalViewForSlice:(NSNumber*) numb
{
	// itk output data;
	vtkImageData	*tempIm;
	// original view
	DCMView			*oView = [[[self window] windowController] originalView];
	int				uu = [numb intValue];
	
	// angle or original view
	// angle of perpendicular view
	float angle2 = [perpendicularView angle];
	
	// get output for original slice
	tempIm = rotate->GetOutput();
	tempIm->Update();
	
	if( tempIm)
	{
		int				imExtent[ 6];
		float			swl, sww;
		long			width, height;
		
		tempIm->GetWholeExtent( imExtent);
		//NSLog( @"%d %d %d", imExtent[ 1], imExtent[ 3], imExtent[ 5]);
		
		float *im = (float*) tempIm->GetScalarPointer();
		
		double		space[ 3], origin[ 3];
		
		tempIm->GetSpacing( space);
		tempIm->GetOrigin( origin);
		
		//NSLog(@"Origin: %f %f %f", origin[ 0], origin[ 1], origin[ 2]);
		//NSLog(@"Spcaing: %f %f %f", space[ 0], space[ 1], space[ 2]);
		
		width = imExtent[ 1]-imExtent[ 0]+1;
		height = imExtent[ 3]-imExtent[ 2]+1;
		
		//NSLog(@"width =  %d height = %d", width, height);
		
		// calculations and image creation for Thick Slabs
		// what is uu ??
		if( thickSlabCount > 1 && uu == 0)
		{
			imResult = (float*) malloc( width * height * sizeof(float));
			memcpy( imResult, im, height*width*sizeof(float));
			
			if(thickSlabMode == 4 || thickSlabMode == 5)
			{
				BOOL flip;
						
				fullVolume = (float*) malloc( width * height * sizeof(float) * thickSlabCount);
				memcpy( fullVolume + width * height * uu, im, width * height * sizeof(float));
				
				if( thickSlabMode == 4) flip = YES;
				else flip = NO;
				
				[thickSlabCtl setImageData :width :height :100 :space[0] :space[1] :space[2] :flip];
			}
		}
		else if( thickSlabCount > 1)
		{
			switch( thickSlabMode)
			{
				case 4:
				case 5:
					if( fullVolume != nil)
					{
						memcpy( fullVolume + width * height * uu, im, width * height * sizeof(float));
					}
				break;
				
				case 1:		// Mean
					vDSP_vadd( imResult, 1, im, 1, imResult, 1, height * width);
					
					if( uu == thickSlabCount -1) //The last one!
					{
						float   invCount = 1.0f/(float)thickSlabCount;
						
						vDSP_vsmul( imResult, 1, &invCount, imResult, 1, height * width);
					}
				break;
				
				
				case 2:		// Maximum IP
				case 3:		// Minimum IP
					#if __ppc__ || __ppc64__
					if( Altivec)
					{
						if( thickSlabMode == 2) vmax((vector float*) imResult, (vector float*)im, (vector float*)imResult, height * width);
						else vmin((vector float*)imResult, (vector float*)im, (vector float*)imResult, height * width);
					}
					else
					{
						if( thickSlabMode == 2) vmaxNoAltivec(imResult,im,imResult, height * width);
						else vminNoAltivec(imResult,im,imResult, height * width);
					}
					#else
					if( thickSlabMode == 2) vmaxIntel((vFloat*) imResult, (vFloat*)im, (vFloat*)imResult, height * width);
					else vminIntel((vFloat*)imResult, (vFloat*)im, (vFloat*)imResult, height * width);
					#endif
				break;
			}
			im = imResult;
		}
		
		if( uu == thickSlabCount - 1)
		{
			DCMPix*		mypix;
			// we have a volume and no blending controller thick slab mode 4 or 5
			if( fullVolume != nil && blendingController == nil && (thickSlabMode == 4 || thickSlabMode == 5))
			{
				unsigned char   *rgbaImage;
				
				[thickSlabCtl setImageSource: fullVolume :thickSlabCount];
				
				[oView getWLWW:&swl :&sww];
				[thickSlabCtl setWLWW: swl: sww];
				
				rgbaImage = [thickSlabCtl renderSlab];
				
				free( fullVolume);
				
				mypix = [[DCMPix alloc] initwithdata:(float*) rgbaImage :7 :width :height :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
				[mypix setFixed8bitsWLWW:YES];
				free( rgbaImage);
			}
			else
			{
				mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :width :height :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
				[mypix copySUVfrom: firstObject];
			}
			[finalPixList removeAllObjects];
			[finalPixList addObject: mypix];
			[mypix release];
			
			//NSLog(@"spacing:%2.2f %2.2f", space[0], space[1]);
			// add image to final view
			if( firstTime)
			{
				firstTime = NO;
				[finalView setDCM:finalPixList :filesList :nil :0 :'i' :YES];
				[finalView setStringID:@"FinalView"];
			//	[finalView setRotation: 90];
			
				[self applyOrientation];
				// The FOV is larger than the actual image.  Compensate by subtracting the difference between height and FOV for Perpendicular View. 
				// And difference between width and Fov for The X Axis for the final view and the difference between FOV and FOVP fo the Y axis				
				float pOffset = [perpendicularView scaleValue] * ([firstObject pheight] - FOV)/2 ;
				[perpendicularView setOrigin: NSMakePoint(0.0, pOffset)];
				[finalView setOrigin: NSMakePoint([finalView scaleValue] *(FOV - [firstObject pwidth])/2.0, [finalView scaleValue] * (FOVP - FOV)/2.0)];
			}
			
			float pOffset = [perpendicularView scaleValue] * (FOV - [firstObject pheight])/2.0 ;
			float fvXOffset = [finalView scaleValue] * ([firstObject pwidth] - FOV)/2.0;
			float fvYOffset = [finalView scaleValue] * (FOV - [firstObject pheight])/2.0;
			float angle = [oView angle]   ;
			float pAngle = [perpendicularView angle];
			// I'm not quite sure why, but this works
			float correction = fabs(sinf((angle * 2.0) * deg2rad));
			float fvCorrection =  fabs(sinf((pAngle * 2.0) * deg2rad));
			// correct for change in image size and position when VTK reslices
			[perpendicularView setOriginOffset: NSMakePoint(0.0, pOffset * correction)];
			[finalView setOriginOffset: NSMakePoint(fvXOffset * correction, fvYOffset * fvCorrection)];	
			[finalView setIndex:0];
			[oView getWLWW:&swl :&sww];
			
			[finalView setWLWW:swl :sww];
			
			// COMPUTE NEW COSINES TABLE FOR ORIENTATION INFORMATIONS (H, F, L, R, ...)
			{
				float newOrientation[ 9], newOrigin[ 3];
				long  i;

				for( i=0;i<9;i++) newOrientation[i] = vectors[i];
			
				XYZ v1, v2, v3;
				
				v1.x = newOrientation[ 0];  v1.y = newOrientation[ 1];  v1.z = newOrientation[ 2];
				v2.x = newOrientation[ 3];  v2.y = newOrientation[ 4];  v2.z = newOrientation[ 5];
				v3.x = newOrientation[ 6];  v3.y = newOrientation[ 7];  v3.z = newOrientation[ 8];

				v1 = ArbitraryRotate( v1, 90*deg2rad, v2);
				v3 = ArbitraryRotate( v3, 90*deg2rad, v2);

				v2 = ArbitraryRotate( v2, (270 - angle)*deg2rad, v1);
				v3 = ArbitraryRotate( v3, (270 - angle)*deg2rad, v1);
				
				v1 = ArbitraryRotate( v1, -angle2*deg2rad, v2);
				v3 = ArbitraryRotate( v3, -angle2*deg2rad, v2);

				v1 = ArbitraryRotate( v1, -90*deg2rad, v3);
				v2 = ArbitraryRotate( v2, -90*deg2rad, v3);
				
				newOrientation[ 0] = v1.x;  newOrientation[ 1] = v1.y;  newOrientation[ 2] = v1.z;
				newOrientation[ 3] = v2.x;  newOrientation[ 4] = v2.y;  newOrientation[ 5] = v2.z;
				newOrientation[ 6] = v3.x;  newOrientation[ 7] = v3.y;  newOrientation[ 8] = v3.z;
				
				[(DCMPix*)[finalPixList objectAtIndex:0] setOrientation: newOrientation];
				
				newOrigin[0] = origin[0];	newOrigin[1] = origin[1];	newOrigin[2] = origin[2];
			
			//	newOrigin[0] = temp[ 0];// - newOrigin[0];
			//	newOrigin[1] = temp[ 1];// - newOrigin[1];
			//	newOrigin[2] = temp[ 2];// - newOrigin[2];
			
//				newOrigin[0] = origin[0] * vectors[0] + origin[1] * vectors[1] + origin[2]*vectors[2];
//				newOrigin[1] = origin[0] * vectors[3] + origin[1] * vectors[4] + origin[2]*vectors[5];
//				newOrigin[2] = origin[0] * vectors[6] + origin[1] * vectors[7] + origin[2]*vectors[8];
			
			
				[(DCMPix*)[finalPixList objectAtIndex:0] setOrigin: newOrigin];
			}

		}
		
		// BLENDING VIEW
		if( blendingController == nil)
		{
			[finalView setBlending: nil];
		}
		else
		{
			tempIm = blendingRotate->GetOutput();
			tempIm->Update();
			
			tempIm->GetWholeExtent( imExtent);
		//	NSLog( @"%d %d %d", imExtent[ 1], imExtent[ 3], imExtent[ 5]);
			im = (float*) tempIm->GetScalarPointer();
			
			if( thickSlabCount > 1 && uu == 0)
			{
				imResultBlending = (float*) malloc( width * height * sizeof(float));
				memcpy( imResultBlending, im, height*width*sizeof(float));
				
				if(thickSlabMode == 4 || thickSlabMode == 5)
				{
					BOOL flip;
							
					fullVolumeBlending = (float*) malloc( width * height * sizeof(float) * thickSlabCount);
					memcpy( fullVolumeBlending + width * height * uu, im, width * height * sizeof(float));
					
					if( thickSlabMode == 4) flip = YES;
					else flip = NO;
					
				//	[thickSlabCtl setImageData :width :height :100 :space[0] :space[1] :space[2] :flip];
				}
			}
			else if( thickSlabCount > 1)
			{
				switch( thickSlabMode)
				{
					case 4:
					case 5:
						if( fullVolumeBlending != nil)
						{
							memcpy( im, fullVolumeBlending + width * height * uu, width * height * sizeof(float));
						}
					break;
					
					case 1:		// Mean
						vDSP_vadd( imResultBlending, 1, im, 1, imResultBlending, 1, height * width);
						
						if( uu == thickSlabCount -1) //The last one!
						{
							float   invCount = 1.0f/(float)thickSlabCount;
							
							vDSP_vsmul( imResultBlending, 1, &invCount, imResultBlending, 1, height * width);
						}
					break;
					
					
					case 2:		// Maximum IP
					case 3:		// Minimum IP
						#if __ppc__ || __ppc64__
						if( Altivec)
						{
							if( thickSlabMode == 2) vmax((vector float*) imResultBlending, (vector float*)im, (vector float*)imResultBlending, height * width);
							else vmin((vector float*)imResultBlending, (vector float*)im, (vector float*)imResultBlending, height * width);
						}
						else
						#endif
						{
							if( thickSlabMode == 2) vmaxNoAltivec(imResultBlending,im,imResultBlending, height * width);
							else vminNoAltivec(imResultBlending,im,imResultBlending, height * width);
						}
					break;
				}
				im = imResultBlending;
			}
			
			
			tempIm->GetSpacing( space);
			tempIm->GetOrigin( origin);
	//		NSLog(@"OriginBlending: %f %f %f", origin[ 0], origin[ 1], origin[ 2]);
			
			if( uu == thickSlabCount - 1)
			{
				if( fullVolumeBlending != nil && (thickSlabMode == 4 || thickSlabMode == 5))
				{
					unsigned char   *rgbaImage;
					
					[thickSlabCtl setImageSource: fullVolume :thickSlabCount];
					[thickSlabCtl setImageBlendingSource: fullVolumeBlending];
					
					[[blendingController imageView] getWLWW:&swl :&sww];
					[thickSlabCtl setBlendingWLWW:swl :sww];
					
					[oView getWLWW:&swl :&sww];
					[thickSlabCtl setWLWW: swl: sww];
					
					
					
					rgbaImage = [thickSlabCtl renderSlab];
					
					free( fullVolume);
					free( fullVolumeBlending);
					
					DCMPix* mypix = [[DCMPix alloc] initwithdata:(float*) rgbaImage :7 :width :height :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
					[mypix setFixed8bitsWLWW:YES];
					free( rgbaImage);
					
			//		[(DCMPix*)[finalPixList objectAtIndex:0] setOrientation: newOrientation];
					
					[finalPixList removeAllObjects];
					[finalPixList addObject: mypix];
					[mypix release];
					
					[finalView setBlending: nil];
				//	[finalView setWLWW:swl :sww];
					[finalView setIndex:0];
				}
				else
				{
					DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
					[mypix copySUVfrom: firstObject];
					
					[finalPixListBlending removeAllObjects];
					[finalPixListBlending addObject: mypix];
					[mypix release];
					
					if( firstTimeBlending)
					{
						firstTimeBlending = NO;
						[finalViewBlending setDCM:finalPixListBlending :filesListBlending :nil :0 :'i' :YES];
						[finalViewBlending setStringID:@"FinalViewBlending"];
					//	[finalView setRotation: 90];
					
						[self applyOrientation];
						[finalViewBlending setOrigin: NSMakePoint([finalView scaleValue] *(FOV - [firstObject pwidth])/2.0, [finalView scaleValue] * (FOVP - FOV)/2.0)];

					}
					
					float fvXOffset = [finalView scaleValue] * ([firstObject pwidth] - FOV)/2.0;
					float fvYOffset = [finalView scaleValue] * (FOV - [firstObject pheight])/2.0;
					float angle = [oView angle]   ;
					float pAngle = [perpendicularView angle];
					// I'm not quite sure why, but this works
					float correction = fabs(sinf((angle * 2.0) * deg2rad));
					float fvCorrection =  fabs(sinf((pAngle * 2.0) * deg2rad));
					[finalViewBlending setOriginOffset: NSMakePoint(fvXOffset * correction, fvYOffset * fvCorrection)];	
					[finalViewBlending setIndex:0];
					//[finalViewBlending setCLUT:red :green: blue];
					
					[[blendingController imageView] getWLWW:&swl :&sww];
					[finalViewBlending setWLWW:swl :sww];
					
					[finalView setBlending: finalViewBlending];
					[finalView setIndex:0];
					[finalView blendingPropagate];
				}
			}
		}
	}
}

-(void)performWorkUnits:(NSSet *)workUnits forScheduler:(Scheduler *)scheduler
{
	NSEnumerator *enumerator = [workUnits objectEnumerator];
	NSNumber	*object;
	
	while (object = [enumerator nextObject])
	{
		[self computeFinalViewForSlice : object];
	}
}

-(void) crossMove: (NSNotification*) note
{
	float			oX, oY, oZ;
	float			angle, angle2;
	float			temp[ 3];
	DCMView			*oView = [[[self window] windowController] originalView];
	BOOL			highRes, noPerOffset = NO;
	float			thickSlabLowRes = 1.0;
	long			uu;
//	float			*imResult = nil, *imResultBlending = nil, *fullVolume = nil, *fullVolumeBlending = nil;
	
	if( thickSlabMode == 0) thickSlabCount = 1;
	else thickSlabCount = thickSlab;
	
	[NSObject cancelPreviousPerformRequestsWithTarget :self selector :@selector(crossStopMoving:) object :[note object]];
	
	if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"dragged"] == YES && ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask) == NO && interval > MINIMUMINTERVAL)
	{
		
		rotate->SetInterpolationModeToNearestNeighbor();
		rotatePerpendicular->SetInterpolationModeToNearestNeighbor();
		
//		if( blendingController) blendingRotate->SetInterpolationModeToNearestNeighbor();
//		
//		if( thickSlabCount > 4) thickSlabLowRes = 4;
//		
//		previousCount = thickSlabCount;
//		
//		thickSlabCount /= (long) thickSlabLowRes;
//		
//		thickSlabLowRes = previousCount / thickSlabCount;
//		thickSlabCount++;
//		
//		highRes = NO;
		highRes = YES;
	}
	else
	{
		rotate->SetInterpolationModeToLinear();
		rotatePerpendicular->SetInterpolationModeToLinear();
		
		if( blendingController) blendingRotate->SetInterpolationModeToLinear();
		
		highRes = YES;
	}
	
	
	if( highRes) interval = [NSDate timeIntervalSinceReferenceDate];
	
	if([[note object] isEqualToString:@"Perpendicular"] == YES)  // CROSS MOVING ON PERPENDICULAR VIEW
	{
		angle = [oView angle];
		angle2 = [perpendicularView angle];
		
	//	[oView cross3D : nil :nil :&oZ];
	//	oZ = oZ * sliceThickness;   //[firstObject sliceThickness];
		
		[perpendicularView cross3D : &oX :&oY :nil];  // oZ contains only slice position!!!
		
		//vtkImageData
		vtkImageData*   imData = rotatePerpendicular->GetOutput();
		double			space[ 3], origin[ 3];
		int				imExtent[ 6], sliceIndex;
		
		imData->GetSpacing( space);
		imData->GetOrigin( origin);
		imData->GetWholeExtent( imExtent);
		
//		NSLog(@"Cross: %f %f", oX, oY);
//		NSLog(@"Origin: %f %f", origin[ 0], origin[ 1]);
		
		sliceIndex = (int) (oX / fabs( sliceThickness));
//		NSLog(@"i:%d", sliceIndex);
		if( sliceIndex != [oView curImage])
		{
			if( sliceIndex < 0) sliceIndex = 0;
			if( sliceIndex >= [pixList count]-1) sliceIndex = [pixList count]-1;
			
			if( sliceThickness > 0) sliceIndex = [pixList count]-1 - sliceIndex;
			
			[oView setIndex: sliceIndex];
			[[[self window] windowController] setSliderValue: sliceIndex];
		}
		
		{
			NSPoint cx, cxPrev;
			
			cx = [perpendicularView cross];
			cxPrev = [perpendicularView crossPrev];
			
			if( cx.y != cxPrev.y)
			{
				[self scrollWheelInt: cxPrev.y - cx.y :nil];
				[perpendicularView setCrossPrev: cx];
				
				noPerOffset = YES;
			//	NSLog(@"noPerOffset");
			}
		}
		
		if( imData->GetScalarType() != VTK_FLOAT)
		{
			NSLog(@"Scalar Type Error!");
		}
		
//		if( imData->GetActualMemorySize() > 1000)
		{			
//			if( angle < 0)
//				[oView setCrossCoordinates: oZ / space[0] : -(-sin((angle)*deg2rad)*-oY + cos((angle)*deg2rad)*oX)/space[1] :NO];
//				else
		
			float x, y;
			
			[oView cross3D : &x :&y :&oZ];
			
			x /= [firstObject pixelSpacingX];
			y /= [firstObject pixelSpacingY];
			
			x = x + tan(angle*deg2rad)*y;
			y = 0;
			
			if( x < 0 || x > [firstObject pwidth])
			{
				[oView cross3D : &x :&y :&oZ];
			
				x /= [firstObject pixelSpacingX];
				y /= [firstObject pixelSpacingY];
				
				y = y + tan((90-angle)*deg2rad)*x;
				x = 0;

				oY /= space[ 1];
				
			//	NSLog(@"space 0: %2.2f space 1: %2.2f", space[ 0], space[ 1]);
				
			//	[oView setCrossCoordinates: [firstObject pwidth] + (x - cos((90 - angle)*deg2rad)*oY) :-(y - sin((90 - angle)*deg2rad)*oY) :NO];
			}
			else
			{
				oY /= space[ 1];
				
			//	NSLog(@"space 0: %2.2f space 1: %2.2f", space[ 0], space[ 1]);
				
			//	[oView setCrossCoordinates:  (x - sin(angle*deg2rad)*oY) :-(y + cos(angle*deg2rad)*oY) :NO];
			}
		}
	}

	angle = [oView angle];
	angle2 = [perpendicularView angle];
	
	if([[note object] isEqualToString:@"Original"] || [[note object] isEqualToString:@"Update"] || noPerOffset == YES)  // CROSS MOVING ON ORIGINAL VIEW
	{
		
		[oView cross3D : &oX :&oY :&oZ];  // oZ contains only slice position!!!
		if (sliceThickness < 0) oZ = oZ * -( sliceThickness);
		else oZ = ([pixList count]-1 - oZ) * ( sliceThickness);   //[firstObject sliceThickness];
		
		temp[ 0] = ([firstObject originX] ) * vectors[0] + ([firstObject originY]) * vectors[1] + ([firstObject originZ] )*vectors[2];
		temp[ 1] = ([firstObject originX] ) * vectors[3] + ([firstObject originY]) * vectors[4] + ([firstObject originZ] )*vectors[5];
		temp[ 2] = ([firstObject originX] ) * vectors[6] + ([firstObject originY]) * vectors[7] + ([firstObject originZ] )*vectors[8];
		
		// PERPENDICULAR VIEW
		if( noPerOffset == NO && [[note object] isEqualToString:@"Update"] == NO)
		{
			perpendicularSliceTransform->Identity();
			perpendicularSliceTransform->Translate( oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
			perpendicularSliceTransform->RotateY( 90);
			perpendicularSliceTransform->RotateX( 360 - angle);
		}
		
		rotatePerpendicular->SetResliceAxesOrigin( 0, 0, 0);
		
		vtkImageData*   imData = rotatePerpendicular->GetOutput();
		
		if( noPerOffset == NO)
		{
			imData->Update();
		}
		
		float*			im = (float*) imData->GetScalarPointer();
		double			space[ 3], origin[ 3];
		int				imExtent[ 6];
		
		imData->GetSpacing( space);
		imData->GetOrigin( origin);
		imData->GetWholeExtent( imExtent);
		
		if( noPerOffset == NO)
		{
			[perPixList removeAllObjects];
			
			if( imData->GetScalarType() != VTK_FLOAT)
			{
				NSLog(@"Scalar Type Error!");
			}
			
			DCMPix*			mypix = [[DCMPix alloc] initwithdata:im :32 :imExtent[ 1]+1 :imExtent[ 3]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
			[mypix copySUVfrom: firstObject];
			[perPixList addObject: mypix];
			[mypix release];
			
			if( firstTime)
			{
				//firstTime = NO;
				[perpendicularView setDCM:perPixList :filesList :nil :0 :'i' :YES];
				[perpendicularView setStringID:@"Perpendicular"];
			//	[perpendicularView setRotation: 90];
				
				[self applyOrientation];
				
			}
		}
		
		// COMPUTE NEW COSINES TABLE FOR ORIENTATION INFORMATIONS (H, F, L, R, ...)
		
		{
			float newOrientation[ 9], newOrigin[ 3];
			long  i;

			for( i=0;i<9;i++) newOrientation[i] = vectors[i];
		
			XYZ v1, v2, v3;
			
			v1.x = newOrientation[ 0];  v1.y = newOrientation[ 1];  v1.z = newOrientation[ 2];
			v2.x = newOrientation[ 3];  v2.y = newOrientation[ 4];  v2.z = newOrientation[ 5];
			v3.x = newOrientation[ 6];  v3.y = newOrientation[ 7];  v3.z = newOrientation[ 8];
			
			v1 = ArbitraryRotate( v1, 90*deg2rad, v2);
			v3 = ArbitraryRotate( v3, 90*deg2rad, v2);
			
			v2 = ArbitraryRotate( v2, (360 - angle)*deg2rad, v1);
			v3 = ArbitraryRotate( v3, (360 - angle)*deg2rad, v1);
			
			newOrientation[ 0] = v1.x;  newOrientation[ 1] = v1.y;  newOrientation[ 2] = v1.z;
			newOrientation[ 3] = v2.x;  newOrientation[ 4] = v2.y;  newOrientation[ 5] = v2.z;
			newOrientation[ 6] = v3.x;  newOrientation[ 7] = v3.y;  newOrientation[ 8] = v3.z;
			
			[(DCMPix*)[perPixList objectAtIndex:0] setOrientation: newOrientation];
			
			newOrigin[0] = origin[0];	newOrigin[1] = origin[1];	newOrigin[2] = origin[2];
			[(DCMPix*)[perPixList objectAtIndex:0] setOrigin: newOrigin];
			
		}
		
		
		//NSPoint tt = { -origin[ 0]*[perpendicularView scaleValue]/space[0], -origin[ 1]*[perpendicularView scaleValue]/space[1]};
		
		NSPoint tt = { 0, -origin[ 1]*[perpendicularView scaleValue]/space[1]};
		
		if( noPerOffset == NO)
		{
			float   swl, sww;
		
		// offset  now varies with rotation, not with the crossmove translation
		//	[perpendicularView setOriginOffset: tt];
			
		//	NSLog(@"B");
			
			[perpendicularView setIndex:0];
		
			[oView getWLWW:&swl :&sww];
			[perpendicularView setWLWW:swl :sww];
		}
		else
		{
		//	NSLog(@"A");
			NSPoint oo = [perpendicularView origin];
			NSPoint tt2 = [perpendicularView originOffset];
			
			oo.y += tt2.y - tt.y;
		}
	}
	
	if([[note object] isEqualToString:@"Original"]  || [[note object] isEqualToString:@"Perpendicular"])
	{
		vtkImageData*   imData = rotatePerpendicular->GetOutput();
		angle = [oView angle];
		
		[oView cross3D : &oX :&oY :&oZ];  // oZ contains only slice position!!!
		if (sliceThickness < 0) oZ = oZ * -( sliceThickness);
		else oZ = ([pixList count]-1 - oZ) * ( sliceThickness);   //[firstObject sliceThickness];

		float			tangle = angle;
		double			space[ 3], origin[ 3];
		int				imExtent[ 6];
		
		imData->GetSpacing( space);
		imData->GetOrigin( origin);
		imData->GetWholeExtent( imExtent);
		
		if( tangle < 90)
		{
			oX = [firstObject pwidth]*[firstObject pixelSpacingX] -oX;
			[perpendicularView setCrossCoordinates: oZ / space[0] : -(cos((tangle)*deg2rad)*oY + sin((tangle)*deg2rad)*(oX))/space[1] :NO];  //[firstObject pwidth]*[firstObject pixelSpacingX]
		
		}
		else if ( tangle < 180)
		{
			oX = [firstObject pwidth]*[firstObject pixelSpacingX] -oX;
			oY = [firstObject pheight]*[firstObject pixelSpacingY] -oY;
			[perpendicularView setCrossCoordinates: oZ / space[0] : -(cos((tangle)*deg2rad)*-oY + sin((tangle)*deg2rad)*oX)/space[1] :NO];
		}
		else if ( tangle < 270)
		{
			oY = [firstObject pheight]*[firstObject pixelSpacingY] -oY;
			[perpendicularView setCrossCoordinates: oZ / space[0] : -(cos((tangle)*deg2rad)*-oY + sin((tangle)*deg2rad)*-oX)/space[1] :NO];
		}
		else
		{
			[perpendicularView setCrossCoordinates: oZ / space[0] : -(cos((tangle)*deg2rad)*oY + sin((tangle)*deg2rad)*-oX)/space[1] :NO];
		}
	}
	
	[oView cross3D : &oX :&oY :&oZ];  // oZ contains only slice position!!!
	oZ = oZ * sliceThickness;   //[firstObject sliceThickness];
	
	temp[ 0] = ([firstObject originX] ) * vectors[0] + ([firstObject originY]) * vectors[1] + ([firstObject originZ] )*vectors[2];
	temp[ 1] = ([firstObject originX] ) * vectors[3] + ([firstObject originY]) * vectors[4] + ([firstObject originZ] )*vectors[5];
	temp[ 2] = ([firstObject originX] ) * vectors[6] + ([firstObject originY]) * vectors[7] + ([firstObject originZ] )*vectors[8];
	
	//NSLog( @"%f %f %f", oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
	
	// FINAL VIEW
	sliceTransform->Identity();
	sliceTransform->Translate( oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
//	sliceTransform->Translate( oX, oY, oZ);
	sliceTransform->RotateY( 90);
	sliceTransform->RotateX( 270 - angle);
	sliceTransform->RotateY( -angle2);
	sliceTransform->RotateZ( -90);
	
	rotate->SetResliceAxesOrigin( 0, 0, 0);
//	rotate->SetResliceAxesOrigin( temp[ 0], temp[ 1], temp[ 2]);

//	rotate->SetOutputExtent( 0, FOV, 0, FOV, 0, 0);
	
	if( blendingController)
	{
		blendingSliceTransform->Identity();
		
		
		blendingSliceTransform->RotateWXYZ( blendingAngle2, blendingAxis2[ 0], blendingAxis2[ 1], blendingAxis2[ 2]);
		blendingSliceTransform->RotateWXYZ( blendingAngle, blendingAxis[ 0], blendingAxis[ 1], blendingAxis[ 2]);
	//	blendingSliceTransform->RotateZ( blendingAngle2);
		
		blendingSliceTransform->Translate( oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
		
	//	blendingSliceTransform->Translate( oX, oY, oZ);
		blendingSliceTransform->RotateY( 90);
		blendingSliceTransform->RotateX( 270 - angle);
		blendingSliceTransform->RotateY( -angle2);
		blendingSliceTransform->RotateZ( -90);
		
		
		rotate->Update();
		blendingRotate->SetOutputSpacing( rotate->GetOutput()->GetSpacing());
		blendingRotate->SetOutputOrigin( rotate->GetOutput()->GetOrigin());
		blendingRotate->SetOutputExtent( rotate->GetOutput()->GetExtent());
	}
	
	if( thickSlabCount > 1)
	{
		if( highRes)
		{
			sliceTransform->Translate(0, 0, -(thickSlabCount/2.0)*[firstObject pixelSpacingX]*thickSlabGap);
		}
		else
		{
			sliceTransform->Translate(0, 0, -(thickSlabCount*thickSlabLowRes/2.0)*[firstObject pixelSpacingX]*thickSlabGap);
		}
	}
	
	fullVolume = nil;
	fullVolumeBlending = nil;
	imResult  = nil;
	imResultBlending = nil;
	
	
//	// Create a scheduler
//	id sched = [[StaticScheduler alloc] initForSchedulableObject: self];
//	[sched setDelegate: self];
//	
//	// Create the work units. These can be anything. We will use NSNumbers
//	NSMutableSet *unitsSet = [NSMutableSet set];
//	for( uu = 0; uu < thickSlabCount; uu++)
//	{
//		[unitsSet addObject: [NSNumber numberWithInt:uu]];
//	}
//	// Perform work schedule
//	[sched performScheduleForWorkUnits:unitsSet];

//	
//	while( [sched numberOfDetachedThreads] > 0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//		
//	[sched release];
	
	for( uu = 0; uu < thickSlabCount; uu++)
	{	
		[self computeFinalViewForSlice: [NSNumber numberWithInt:uu]];
		
		if( highRes)
		{
			sliceTransform->Translate(0, 0, [firstObject pixelSpacingX]*thickSlabGap);
		}
		else
		{
			sliceTransform->Translate(0, 0, [firstObject pixelSpacingX]*thickSlabGap*thickSlabLowRes);
		}
	}
	
	if( imResult) free( imResult);
	if( imResultBlending) free( imResultBlending);
	
	if( highRes) interval = [NSDate timeIntervalSinceReferenceDate] - interval;
	else
	{
		[self performSelector :@selector( crossStopMoving:) withObject :[note object] afterDelay :1.0];
	}
	
//	// Cross position in 3D
//	[[pixList objectAtIndex: [oView curImage]] convertPixX: [oView cross].x pixY: [oView cross].y toDICOMCoords: temp];
//	NSLog( @"3D position: %f %f %f", temp[ 0], temp[ 1], temp[ 2]);
//	
//	// Back to 2D
//	float s[ 3];
//	[firstObject convertDICOMCoords: temp toSliceCoords: s];
//	NSLog( @"2D position: %f %f %f", s[ 0]/[firstObject pixelSpacingX], s[ 1]/[firstObject pixelSpacingY], s[ 2]/sliceThickness);
}

//-(void) computeSlice
//{
//	return;
//	
//	// vtkImageReslice - vtkTransform
//	float oX, oY, oZ;
//	float angle, angle2;
//	float temp[ 3];
//	
//	angle = [[[[self window] windowController] originalView] angle];
//	angle2 = [perpendicularView angle];
//	
//	[[[[self window] windowController] originalView] cross3D : &oX :&oY :&oZ];  // oZ contains only slice position!!!
//	oZ = oZ * sliceThickness;   //[firstObject sliceThickness];
//	
//	temp[ 0] = ([firstObject originX] ) * vectors[0] + ([firstObject originY]) * vectors[1] + ([firstObject originZ] )*vectors[2];
//	temp[ 1] = ([firstObject originX] ) * vectors[3] + ([firstObject originY]) * vectors[4] + ([firstObject originZ] )*vectors[5];
//	temp[ 2] = ([firstObject originX] ) * vectors[6] + ([firstObject originY]) * vectors[7] + ([firstObject originZ] )*vectors[8];
//	
//	// PERPENDICULAR VIEW
//	perpendicularSliceTransform->Identity();
//	perpendicularSliceTransform->Translate( oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
//	perpendicularSliceTransform->RotateY( -90);
//	perpendicularSliceTransform->RotateX( angle - 90);
//	
//	rotatePerpendicular->SetResliceAxesOrigin( 0, 0, 0);
//	rotatePerpendicular->SetOutputExtent( 0, FOV, 0, FOV, 0, 0);
//	rotatePerpendicular->Update();
//	
//	//vtkImageData
//	vtkImageData*   imData = rotatePerpendicular->GetOutput();
//	
//	imData->Update();
//	imData->UpdateData();
//	
//	float*			im = (float*) imData->GetScalarPointer();
//	double			space[ 3], origin[ 3];
//	int				imExtent[ 6];
//	
//	imData->GetSpacing( space);
//	imData->GetSpacing( origin);
//	imData->GetWholeExtent( imExtent);
//	
//	[perPixList removeAllObjects];
//	
//	if( imData->GetScalarType() != VTK_FLOAT)
//	{
//		NSLog(@"Scalar Type Error!");
//	}
//	
////	NSLog(@"%d", imData->GetActualMemorySize());
//	
//	if( imData->GetActualMemorySize() > 1000)
//	{
//		DCMPix*			mypix = [[DCMPix alloc] initwithdata:im :32 :imExtent[ 1]+1 :imExtent[ 3]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
//		[perPixList addObject: mypix];
//		[mypix release];
//		
//		if( firstTime)
//		{
//			firstTime = NO;
//			[perpendicularView setDCM:perPixList :filesList :0 :'i' :YES];
//		}
//		
//		[perpendicularView setIndex:0];
//		
//	//	[perpendicularView setCrossCoordinates: oZ : sin(angle*deg2rad)*oY + cos(angle*deg2rad)*oX :NO];
//		
////		NSLog(@"%0.0f", angle2);
////		if( angle < 0)
////			[perpendicularView setCrossCoordinates: oZ / space[0] : -(-sin((-angle)*deg2rad)*-([firstObject pheight]*[firstObject pixelSpacingY] -oY) + cos((-angle)*deg2rad)*(oX))/space[1] :NO];  //[firstObject pwidth]*[firstObject pixelSpacingX]
////		else
////			[perpendicularView setCrossCoordinates: oZ / space[0] : -(-sin((angle)*deg2rad)*-oY + cos((angle)*deg2rad)*oX)/space[1] :NO];
//			
//	//	[perpendicularView setMPRAngle: angle2];
//	}
//	
//	// FINAL VIEW
//	sliceTransform->Identity();
//	sliceTransform->Translate( oX + temp[ 0], oY + temp[ 1], oZ + temp[ 2]);
//	sliceTransform->RotateY( 90);
//	sliceTransform->RotateX( 180 - angle);
//	sliceTransform->RotateY( 90 + angle2);
//	
//	rotate->SetResliceAxesOrigin( 0, 0, 0);
//	rotate->SetOutputExtent( 0, FOV, 0, FOV, 0, 0);
//	rotate->Update();
//}

-(short) setPixSource:(NSMutableArray*)pix :(NSArray*)files :(float*) volumeData
{
    short   error = 0;
	long	i;
    
	perPixList = [[NSMutableArray alloc] initWithCapacity:0];
	finalPixList = [[NSMutableArray alloc] initWithCapacity:0];
	finalPixListBlending = [[NSMutableArray alloc] initWithCapacity:0];
	
	[files retain];
	filesList = files;
	
    [pix retain];
    pixList = pix;
	
	data = volumeData;
	
//	aRenderer = vtkRenderer::New();
//	aRenderer = [self renderer];
	
	firstObject = [pixList objectAtIndex:0];
	sliceThickness = [firstObject sliceInterval];   //[[pixList objectAtIndex:1] sliceLocation] - [firstObject sliceLocation];
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [firstObject sliceThickness];
	}
	// The max FOV should be the SQRT of (x^2 + y^2 + z^2)
	FOVP = ([pixList count] * fabs(sliceThickness) / [firstObject pixelSpacingX]);
	double fov = sqrt(powf([firstObject pwidth], 2) + powf([firstObject pheight], 2)  + FOVP);
	NSLog (@"fov %f", fov);
	FOV = fov / 4;
	FOV = FOV * 4;
	
//	[slider setMaxValue: FOV];
//	[slider setMinValue: -FOV];
	
	// PLAN 
	[firstObject orientation:vectors];

	if( vectors[6] + vectors[7] + vectors[8] < 0)
	{
	//	sliceThickness = -sliceThickness;
		
		negVector = YES;
		
		NSLog(@"Neg Vector");
	}
	else negVector = NO;
	
	if( [firstObject isRGB])
	{
		// Convert RGB to BW... We could add support for RGB later if needed by users....
		
		long	i, size, val;
		unsigned char	*srcPtr = (unsigned char*) data;
		float   *dstPtr;
		
		size = [firstObject pheight] * [pix count];
		size *= [firstObject pwidth];
		size *= sizeof( float);
		
		dataFRGB = (float*) malloc( size);
		
		size /= 4;
		
		dstPtr = dataFRGB;
		for( i = 0 ; i < size; i++)
		{
			srcPtr++;
			val = *srcPtr++;
			val += *srcPtr++;
			val += *srcPtr++;
			*dstPtr++ = val/3;
		}
		
		data = dataFRGB;
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, [firstObject pwidth]-1, 0, [firstObject pheight]-1, 0, [pixList count]-1);
	reader->SetDataSpacing( [firstObject pixelSpacingX], [firstObject pixelSpacingY], sliceThickness);
	reader->SetDataOrigin(  ([firstObject originX] ) * vectors[0] + ([firstObject originY]) * vectors[1] + ([firstObject originZ] )*vectors[2],
							([firstObject originX] ) * vectors[3] + ([firstObject originY]) * vectors[4] + ([firstObject originZ] )*vectors[5],
							([firstObject originX] ) * vectors[6] + ([firstObject originY]) * vectors[7] + ([firstObject originZ] )*vectors[8]);
	//reader->SetDataOrigin(  [firstObject originX],[firstObject originY],[firstObject originZ]);
	reader->SetDataExtentToWholeExtent();
	reader->SetDataScalarTypeToFloat();
	reader->SetImportVoidPointer(data);
	
	// TRANSFORM
	
	sliceTransform = vtkTransform::New();
	sliceTransform->Identity();
	
	perpendicularSliceTransform = vtkTransform::New();
	perpendicularSliceTransform->Identity();
	
//	changeImageInfo = vtkImageChangeInformation::New();
//	changeImageInfo->CenterImageOn();	
//	changeImageInfo->SetInput( reader->GetOutput());
	// FINAL IMAGE RESLICE
	
	rotate = vtkImageReslice::New();
	rotate->SetAutoCropOutput( true);
	rotate->SetInformationInput( reader->GetOutput());
	rotate->SetInput( reader->GetOutput());
	//rotate->SetInformationInput( changeImageInfo->GetOutput());
	//rotate->SetInput( changeImageInfo->GetOutput());
	rotate->SetOptimization( true);
	rotate->SetResliceTransform( sliceTransform);

//	rotate->SetTransformInputSampling( false);
	rotate->SetInterpolationModeToNearestNeighbor();	//SetInterpolationModeToLinear(); //SetInterpolationModeToCubic();	//SetInterpolationModeToCubic();
	rotate->SetOutputDimensionality( 2);
//	rotate->SetOutputOrigin( 0,0,0);
	rotate->SetBackgroundLevel( -1024);
	rotate->SetOutputExtent( 0, FOV, 0, FOV, 0, 0);

	// PERPENDICULAR RESLICE
	
	rotatePerpendicular = vtkImageReslice::New();
	rotatePerpendicular->SetAutoCropOutput( true);
	rotatePerpendicular->SetInformationInput( reader->GetOutput());
	rotatePerpendicular->SetInput( reader->GetOutput());
	rotatePerpendicular->SetOptimization( true);
	rotatePerpendicular->SetResliceTransform( perpendicularSliceTransform);
//	rotatePerpendicular->SetTransformInputSampling( false);
	rotatePerpendicular->SetInterpolationModeToNearestNeighbor(); //SetInterpolationModeToLinear();	//SetInterpolationModeToCubic();	//SetInterpolationModeToCubic();
	rotatePerpendicular->SetOutputDimensionality( 2);
	rotatePerpendicular->SetBackgroundLevel( -1024);
	rotatePerpendicular->SetOutputExtent( 0, FOVP, 0, FOV, 0, 0);
	rotatePerpendicular->Update();
	
	// X - Y - Z planes
	
    bwLut = vtkLookupTable::New();  
    bwLut->SetTableRange (0, 256);
	bwLut->SetNumberOfTableValues(256);
	
	for( i = 0; i < 256; i++)
	{
		bwLut->SetTableValue(i, i / 256., i / 256., i / 256., 1);
	}
    
    axialColors = vtkImageMapToColors::New();
	axialColors->SetInput(rotate->GetOutput());
    axialColors->SetLookupTable(bwLut);


    axial = vtkImageActor::New();
//	axial->SetPickable( true);
    axial->SetInput(axialColors->GetOutput());


	// Links actors to camera & render view
	
    aCamera = vtkCamera::New();
    aCamera->SetViewUp (0, 0, -1);
    aCamera->SetPosition (0, 1, 0);
    aCamera->SetFocalPoint (0, 0, 0);
    aCamera->ComputeViewPlaneNormal();    
    
	
	[[[[self window] windowController] originalView] setMPRAngle: 0.0];
	[perpendicularView setMPRAngle: 0.0];
	
	[self applyOrientation];
	
	[[[[self window] windowController] originalView] setCross: 0 :0 :YES];
	
    return error;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
	return [finalView getRawPixels: width :height :spp :bpp :screenCapture :force8bits];
}
	
-(NSImage*) nsimage:(BOOL) notused
{
	[finalView display];	// Important for Quicktime export with rotation
	
	return [finalView nsimage: notused];
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    NSImage *im;
    
    [pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:self];
    
    im = [self nsimage:NO];
    
    [pb setData: [im TIFFRepresentation] forType:NSTIFFPboardType];
}
@end
