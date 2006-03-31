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

#import "OrthogonalMPRView.h"
#import "DCMPix.h"
#import "OrthogonalMPRController.h"

@implementation OrthogonalMPRView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setStringID:@"OrthogonalMPRVIEW"];
	displayResliceAxes = 1;
	controller = 0L;
	
	// thick slab axes distance
	thickSlabX = 0;
	thickSlabY = 0;
	
	crossPositionX = 0;
	crossPositionY = 0;
	
	curWLWWMenu = NSLocalizedString(@"Other", 0L);
	
	return self;
}

- (void) dealloc {
	long i;
	[controller release];
	[super dealloc];
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files
{
	long i, index;
	
	[self setDCM:pix :files :nil :0 :'i' :NO];

	// Prepare pixList for image thick slab
	for( i = 0; i < [pix count]; i++) [[pix objectAtIndex: i] setArrayPix: pix :i];
	
	[self setIndex:0];
	
}

- (NSMutableArray*) pixList
{
	return dcmPixList;
}

- (void) setController: (OrthogonalMPRController*) newController
{
	if( controller != newController)
	{
		[controller release];
		controller = [newController retain];
	}
}

- (OrthogonalMPRController*) controller
{
	return controller;
}

- (void) setCrossPosition: (long) x: (long) y
{
	x = (x<0)? 0 : x;
	x = (x>=[[self curDCM] pwidth])? [[self curDCM] pwidth]-1 : x;
	crossPositionX = x;
	
	y = (y<0)? 0 : y;
	y = (y>=[[self curDCM] pheight])? [[self curDCM] pheight]-1 : y;
	crossPositionY = y;
	
	[controller reslice: x:  y: self];
}

- (void) setCrossPositionX: (long) x
{
	x = (x<0)? 0 : x;
	x = (x>=[[self curDCM] pwidth])? [[self curDCM] pwidth]-1 : x;
	crossPositionX = x;
}

- (void) setCrossPositionY: (long) y
{
	y = (y<0)? 0 : y;
	y = (y>=[[self curDCM] pheight])? [[self curDCM] pheight]-1 : y;
	crossPositionY = y;
}

- (void) setCLUT:( unsigned char*) r :(unsigned char*) g :(unsigned char*) b
{
	[super setCLUT:r :g :b];
	[self setIndex:[self curImage]];
}

- (void) setWLWW:(float) wl :(float) ww
{
	[[self controller] setWLWW :wl :ww];
}

- (void) adjustWLWW:(float) wl :(float) ww
{
	[curDCM changeWLWW :wl : ww];
    
    curWW = [curDCM ww];
    curWL = [curDCM wl];
	
    [self loadTextures];
//	[self display];
    [self setNeedsDisplay:YES];
}

- (void) getWLWW:(float*) wl :(float*) ww
{
	if( curDCM == 0L) NSLog(@"curDCM 0L");
	else
	{
		if(wl) *wl = [curDCM wl];
		if(ww) *ww = [curDCM ww];
	}
}

- (void) setScaleValue:(float) x
{
	[[self controller] setScaleValue :x];
}

- (void) adjustScaleValue:(float) x
{
	[super setScaleValueCentered:x];
}

- (long) crossPositionX
{
	return crossPositionX;
}

- (long) crossPositionY
{
	return crossPositionY;
}

- (void) subDrawRect:(NSRect)aRect
{	
	if (displayResliceAxes)
	{
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
		glEnable(GL_BLEND);
		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
	
		float xCrossCenter,yCrossCenter;
		xCrossCenter = (crossPositionX +0.5 -[[self curDCM] pwidth]/2) * scaleValue;
		yCrossCenter = (crossPositionY +0.5 -[[self curDCM] pheight]/2) * scaleValue;
		
		//NSLog(@"subdraw thickslab:%f pixelSpacingY:%f", [controller thickSlabDistance], [[self curDCM] pixelSpacingY]);
		//yCrossCenter = yCrossCenter - ([controller thickSlabDistance]*(float)[controller thickSlab]   / 2.0);
		
	//	NSRect size = [self frame];
	//	float viewportSizeX, viewportSizeY;
	//	viewportSizeX = size.size.width;
	//	viewportSizeY = size.size.height / [curDCM pixelRatio];

	//	float xAxeLength, yAxeLength;
	//	xAxeLength = viewportSizeX;
	//	yAxeLength = viewportSizeY;
		
		glColor3f (0.0f, 1.0f, 0.0f);
		glLineWidth(1.0);
		glBegin(GL_LINES);
		// vertical axis
		glVertex2f(xCrossCenter,-4000);
		glVertex2f(xCrossCenter,yCrossCenter -50.0*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
	
		if (displayResliceAxes == 2)
		{
			glVertex2f(xCrossCenter,yCrossCenter -10.0*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
			glVertex2f(xCrossCenter,yCrossCenter +10.0*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
		}
		
		glColor3f (0.0f, 1.0f, 0.0f);
		glVertex2f(xCrossCenter,yCrossCenter +50.0*[curDCM pixelSpacingX]/[curDCM pixelSpacingY]);
		glVertex2f(xCrossCenter,4000);
		
		// horizontal axis
		glVertex2f(-4000,yCrossCenter);
		glVertex2f(xCrossCenter-50.0,yCrossCenter);
	
		if (displayResliceAxes == 2)
		{
			glVertex2f(xCrossCenter-10.0,yCrossCenter);
			glVertex2f(xCrossCenter+10.0,yCrossCenter);
		}
		
		glColor3f (0.0f, 1.0f, 0.0f);
		glVertex2f(xCrossCenter+50.0,yCrossCenter);
		glVertex2f(4000,yCrossCenter);
		
		float shift;
		if (thickSlabX>0)
		{
			shift =  (float)thickSlabX / 2.0 * scaleValue;
			glColor3f (0.0f, 0.0f, 1.0f);
			glVertex2f(xCrossCenter-shift,-4000);
			glVertex2f(xCrossCenter-shift,4000);
			glVertex2f(xCrossCenter+shift,-4000);
			glVertex2f(xCrossCenter+shift,4000);
		}
		if (thickSlabY>0)
		{
			shift =  (float)thickSlabY / 2.0 * scaleValue;
			glColor3f (0.0f, 0.0f, 1.0f);
			glVertex2f(-4000,yCrossCenter-shift);
			glVertex2f(4000,yCrossCenter-shift);
			glVertex2f(-4000,yCrossCenter+shift);
			glVertex2f(4000,yCrossCenter+shift);
		}
		
		glEnd();
		
		glDisable(GL_LINE_SMOOTH);
		glDisable(GL_POLYGON_SMOOTH);
		glDisable(GL_POINT_SMOOTH);
		glDisable(GL_BLEND);
	}
}

- (void) blendingPropagate
{
	[controller blendingPropagate:self];
}

- (void) keyDown:(NSEvent *)event
{
	unichar	c = [[event characters] characterAtIndex:0];	
	if( c == ' ')
	{
		[controller toggleDisplayResliceAxes: self];
	}
	else if (c == NSEnterCharacter || c == NSCarriageReturnCharacter || c == 27) // 27 : escape
	{
		[controller fullWindowView: self];
	}
	else if (c == NSLeftArrowFunctionKey)
	{
		[controller saveCrossPositions];
		[self scrollTool: 0 : -1];
		[controller saveCrossPositions];
		[self blendingPropagate];
	}
	else if(c ==  NSRightArrowFunctionKey)
	{
		[controller saveCrossPositions];
		[self scrollTool: 0 : 1];
		[controller saveCrossPositions];
		[self blendingPropagate];
	}
	else if (c == NSUpArrowFunctionKey)
	{
		[self setScaleValue:(scaleValue+1./50.)];
		[self blendingPropagate];
	}
	else if(c ==  NSDownArrowFunctionKey)
	{
		[self setScaleValue:(scaleValue-1./50.)];
		[self blendingPropagate];
	}
	else
	{
		[super keyDown:event];
	}
	[self setNeedsDisplay:YES];
}

- (void) toggleDisplayResliceAxes
{
	displayResliceAxes++;
	if( displayResliceAxes >= 3) displayResliceAxes = 0;
	[self setNeedsDisplay:YES];
}

- (void) displayResliceAxes: (long) boo
{
	displayResliceAxes = boo;
	[self setNeedsDisplay:YES];
}

- (void) mouseDown:(NSEvent *)event
{
	if ([event clickCount] == 2)
	{
		[controller restoreCrossPositions];
		[controller doubleClick:event:self];
	}
	else
	{
		[controller saveCrossPositions];
		[super mouseDown:event];
	}
}

//- (void) mouseUp:(NSEvent *)event
//{
//	if ([event clickCount] != 2)
//	{
//		[super mouseUp:event];
//	}
//	else
//	{
//		[controller doubleClickOn: self];
//	}
//}

- (void) scrollTool: (long) from : (long) to
{
	[controller scrollTool: from : to : self];
}

- (void) saveScaleValue
{
	savedScaleValue = scaleValue;
}

- (void) restoreScaleValue
{
	[self adjustScaleValue: savedScaleValue];
}

- (void)reshape{}

- (void) setThickSlabXY : (long) newThickSlabX : (long) newThickSlabY
{
	thickSlabX = newThickSlabX;
	thickSlabY = newThickSlabY;
}

- (void) setCurWLWWMenu:(NSString*) str
{
	curWLWWMenu = str;
}
- (NSString*) curWLWWMenu
{
	return curWLWWMenu;
}

@end
