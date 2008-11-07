/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "DCMPix.h"

#import "OrthogonalMPRViewer.h"
#import "ROI.h"
#import "DefaultsOsiriX.h"
#import "ThickSlabController.h"

@implementation OrthogonalMPRView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	[self setStringID:@"OrthogonalMPRVIEW"];
	displayResliceAxes = 1;
	controller = nil;
	
	// thick slab axes distance
	thickSlabX = 0;
	thickSlabY = 0;
	
	crossPositionX = 0;
	crossPositionY = 0;
	
	curWLWWMenu = [NSLocalizedString(@"Other", nil) retain];
	curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
	curOpacityMenu = [NSLocalizedString(@"Linear Table", nil) retain];
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(addROI:)
											name: @"addROI"
											object: nil];
	
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(removeROI:)
											name: @"removeROI"
											object: nil];
											
	[[NSNotificationCenter defaultCenter]	addObserver: self
											selector: @selector(roiRemovedFromArray:)
											name: @"roiRemovedFromArray"
											object: nil];
	
	return self;
}

- (void) dealloc
{
	[controller release];
	[curWLWWMenu release];
	[curCLUTMenu release];
	[curOpacityMenu release];
	
	[super dealloc];
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files :(NSMutableArray*) rois
{
	long i, index;
	
	[self setDCM:pix :files :rois :0 :'i' :NO];
	
	//if( [[[[self window] windowController] windowNibName] isEqualToString:@"OrthogonalMPR"])
	if(![[[[self window] windowController] windowNibName] isEqualToString:@"PETCT"])
	{
		// Prepare pixList for image thick slab - DO IT ONLY FOR NON - PET-CT VIEWER !!!!!!! ROI CRASH - Antoine
		for( i = 0; i < [pix count]; i++)
		{
			[[pix objectAtIndex: i] setArrayPix: pix :i];
		}
	}
	
	[self setIndex:0];
	
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files
{
	[self setPixList: pix : files : nil];
}

- (NSMutableArray*) pixList
{
	return dcmPixList;
}

- (NSMutableArray*) curRoiList
{
	return curRoiList;
}

// overwrite method in DCMView
-(void) becomeMainWindow
{
}

- (void) setCurRoiList: (NSMutableArray*) rois
{
//	NSMutableArray	*previousParents = [NSMutableArray	array];
//	NSMutableArray	*previousMode = [NSMutableArray	array];
//	
//	if( curRoiList)
//	{
//		for( i = 0 ; i < [curRoiList count]; i++)
//		{
//			if( [[curRoiList objectAtIndex: i] parentROI])
//			{
//				[previousParents addObject: [[curRoiList objectAtIndex: i] parentROI]];
//				[previousMode addObject: [NSNumber numberWithInt:[[curRoiList objectAtIndex: i] ROImode]]];
//			}
//		}
//	}
	
	[curRoiList release];
	
	curRoiList = [rois retain];
	
	for(id loopItem in curRoiList)
	{
		[self roiSet:loopItem];
	}
	
//	for( i = 0 ; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex: i] parentROI])
//		{
//			if( [previousParents containsObject: [[curRoiList objectAtIndex: i] parentROI]])
//			{
//				NSInteger index = [previousParents indexOfObject: [[curRoiList objectAtIndex: i] parentROI]];
//				
//				[[curRoiList objectAtIndex: i] setROIMode: [[previousMode objectAtIndex: index] intValue]];
//			}
//		}
//	}

}

- (NSMutableArray*) dcmRoiList
{
	return dcmRoiList;
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

- (void) setCrossPosition: (float) x: (float) y
{
//	cx = (x<0)? 0 : x;
//	x = (x>=[[self curDCM] pwidth])? [[self curDCM] pwidth]-1 : x;
//	crossPositionX = x;
	[self setCrossPositionX: x];
//	y = (y<0)? 0 : y;
//	y = (y>=[[self curDCM] pheight])? [[self curDCM] pheight]-1 : y;
//	crossPositionY = y;
	[self setCrossPositionY: y];
	
	[controller reslice: x:  y: self];
}

- (void) setCrossPositionX: (float) x
{
	if(crossPositionX == x)
		return;
	x = (x<0)? 0 : x;
	x = (x>=[[self curDCM] pwidth])? [[self curDCM] pwidth]-1 : x;
	crossPositionX = x;
}

- (void) setCrossPositionY: (float) y
{
	if(crossPositionY == y)
		return;
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
    [self setNeedsDisplay:YES];
}

- (void) getWLWW:(float*) wl :(float*) ww
{
	if( curDCM == nil) NSLog(@"curDCM nil");
	else
	{
		if(wl) *wl = [curDCM wl];
		if(ww) *ww = [curDCM ww];
	}
}

- (void) setScaleValue:(float) x
{
	if( [self pixelSpacingX] != 0 && [[controller originalView] pixelSpacingX] != 0)
	{
		if( [controller originalView] == self) [[self controller] setScaleValue: x ];
		else if( [controller yReslicedView] == self) [[self controller] setScaleValue: x  * [[controller originalView] pixelSpacingX] / [self pixelSpacingX]];
		else if( [controller xReslicedView] == self) [[self controller] setScaleValue: x  * [[controller originalView] pixelSpacingX] / [self pixelSpacingX]];
	}
	else
	{
		[[self controller] setScaleValue :x];
	}
}

- (void) adjustScaleValue:(float) x
{
	[super setScaleValueCentered:x];
}

- (float) crossPositionX
{
	return crossPositionX;
}

- (float) crossPositionY
{
	return crossPositionY;
}

- (void) subDrawRect:(NSRect)aRect
{	
	if (displayResliceAxes)
	{
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
		glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
		glEnable(GL_BLEND);
		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
	
		float xCrossCenter,yCrossCenter;
		xCrossCenter = (crossPositionX  - [[self curDCM] pwidth]/2) * scaleValue;
		yCrossCenter = (crossPositionY  - [[self curDCM] pheight]/2) * scaleValue;
		
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
		glVertex2f(xCrossCenter,yCrossCenter -50.0/curDCM.pixelRatio);
	
		if (displayResliceAxes == 2)
		{
			glVertex2f(xCrossCenter,yCrossCenter -10.0/curDCM.pixelRatio);
			glVertex2f(xCrossCenter,yCrossCenter +10.0/curDCM.pixelRatio);
		}
		
		glColor3f (0.0f, 1.0f, 0.0f);
		glVertex2f(xCrossCenter,yCrossCenter +50.0/curDCM.pixelRatio);
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
			glVertex2f(xCrossCenter-shift,yCrossCenter -50.0/curDCM.pixelRatio);
			
			glVertex2f(xCrossCenter-shift,yCrossCenter +50.0/curDCM.pixelRatio);
			glVertex2f(xCrossCenter-shift,4000);
			
			glVertex2f(xCrossCenter+shift,-4000);
			glVertex2f(xCrossCenter+shift,yCrossCenter -50.0/curDCM.pixelRatio);
			
			glVertex2f(xCrossCenter+shift,yCrossCenter +50.0/curDCM.pixelRatio);
			glVertex2f(xCrossCenter+shift,4000);
		}
		
		if (thickSlabY>0)
		{
			shift =  (float)thickSlabY / 2.0 * scaleValue;
			glColor3f (0.0f, 0.0f, 1.0f);
			glVertex2f(-4000,yCrossCenter-shift);
			glVertex2f(xCrossCenter-50.0,yCrossCenter-shift);
			
			glVertex2f(xCrossCenter+50.0,yCrossCenter-shift);
			glVertex2f(4000,yCrossCenter-shift);
			
			
			glVertex2f(-4000,yCrossCenter+shift);
			glVertex2f(xCrossCenter-50.0,yCrossCenter+shift);
			
			glVertex2f(xCrossCenter+50.0,yCrossCenter+shift);
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
		[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMViewDidBecomeFirstResponder" object:self];
	}
}

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

- (NSString*) curCLUTMenu
{
	return curCLUTMenu;
}

- (void) setCurCLUTMenu: (NSString*) clut
{
	if(curCLUTMenu == clut) return;
	
	[curCLUTMenu release];
	curCLUTMenu = [clut retain];
}

- (void) setCurWLWWMenu:(NSString*) str
{
	if( str != curWLWWMenu)
	{
		[curWLWWMenu release];
		curWLWWMenu = [str retain];
	}
}

- (NSString*) curWLWWMenu
{
	return curWLWWMenu;
}

- (void) setCurOpacityMenu:(NSString*) o
{
	if( o != curOpacityMenu)
	{
		[curOpacityMenu release];
		curOpacityMenu = [o retain];
	}
}

- (NSString*) curOpacityMenu
{
	return curOpacityMenu;
}

// overwrite the DCMView method:
- (void) addROI:(NSNotification*)note
{
	DCMView *sender = [note object];
	ROI *addedROI = [[note userInfo] objectForKey:@"ROI"];
	int sliceNumber = [[[note userInfo] objectForKey:@"sliceNumber"] intValue];
	
	if( [addedROI type] != t2DPoint) return;
	
	if (![self isEqualTo:sender])// && ![self isEqualTo:[controller xReslicedView]] && ![self isEqualTo:[controller yReslicedView]])
	{
		if (([[controller xReslicedView] isEqualTo:sender] || [[controller yReslicedView] isEqualTo:sender]) && [[controller originalView] isEqualTo:self])
		{
			if([addedROI type]==t2DPoint)
			{
				ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[[controller originalView] pixelSpacingX] :[[controller originalView] pixelSpacingY] :NSMakePoint( [[controller originalView] origin].x, [[controller originalView] origin].y)] autorelease];

				NSRect irect;
				if([[controller xReslicedView] isEqualTo:sender])
				{
					irect.origin.x = [[[addedROI points] objectAtIndex:0] x];
					irect.origin.y = [[controller originalView] crossPositionY];
				}
				else
				{
					irect.origin.x = [[controller originalView] crossPositionX];
					irect.origin.y = [[[addedROI points] objectAtIndex:0] x];
				}			
				irect.size.width = irect.size.height = 0;
				[new2DPointROI setROIRect:irect];
		
				[[controller originalView] roiSet:new2DPointROI];
				
				for(id loopItem in curRoiList)
				{
					[loopItem setROIMode:ROI_sleep];
				}
				
				// copy the state
				[new2DPointROI setROIMode:ROI_selected];
				
				// name		
				NSString *finalName, *roiName = [NSString stringWithString:@"Point "];
				int counter = 1;
				BOOL existsAlready = YES;
				while (existsAlready)
				{
					existsAlready = NO;
					finalName = [roiName stringByAppendingFormat:@"%d", counter++];
					for( int i = 0; i < [[[controller originalView] dcmRoiList] count]; i++)
					{
						for( int x = 0; x < [[[[controller originalView] dcmRoiList] objectAtIndex: i] count]; x++)
						{
							if([[[[[[controller originalView] dcmRoiList] objectAtIndex:i] objectAtIndex:x] name] isEqualToString:finalName])
								existsAlready = YES;
						}
					}
				}
				[addedROI setName:finalName];
				[new2DPointROI setName:finalName];
					
				// add the 2D Point ROI to the ROI list
				long slice = ([controller sign]>0)? [[[controller originalView] dcmPixList] count]-1 -[[[addedROI points] objectAtIndex:0] y] : [[[addedROI points] objectAtIndex:0] y];
				
				if( slice < 0) slice = 0;
				if( slice >= [[[controller originalView] dcmRoiList] count]) slice = [[[controller originalView] dcmRoiList] count]-1;
				
				[[[[controller originalView] dcmRoiList] objectAtIndex: slice] addObject: new2DPointROI];
			}
			[controller loadROIonReslicedViews: [[controller originalView] crossPositionX] : [[controller originalView] crossPositionY]];
		}
	}
}

-(void) roiChange:(NSNotification*)note
{
	ROI *roi = [note object];
	
	[super roiChange:note];
	
	if( [roi type] != t2DPoint) return;
	
	if( [[[note userInfo] valueForKey:@"action"] isEqualToString:@"mouseUp"] && [[self window] firstResponder] == self)
	{
		if([roi parentROI])
		{
			int		reslicedview = 0;
			
			// the ROI has a parent. Thus it is on a resliced view. Which one?
			NSLog(@"roi is 2D Point and has parent");
			NSRect irect;
			if([[[controller xReslicedView] curRoiList] containsObject:roi])
			{
				reslicedview = 1;
				
				NSLog(@"this Point belongs to xReslicedView");
				irect.origin.x = [[[roi points] objectAtIndex:0] x];
				irect.origin.y = [[controller originalView] crossPositionY];
			}
			else if([[[controller yReslicedView] curRoiList] containsObject:roi])
			{
				reslicedview = 2;
				
				NSLog(@"this Point belongs to yReslicedView");
				irect.origin.x = [[controller originalView] crossPositionX];
				irect.origin.y = [[[roi points] objectAtIndex:0] x];
			}
			else
			{
				NSLog(@"nobody contains this Point");
				return;
			}

			ROI *new2DPointROI = [[[ROI alloc] initWithType: t2DPoint :[[controller originalView] pixelSpacingX] :[[controller originalView] pixelSpacingY] :NSMakePoint( [[controller originalView] origin].x, [[controller originalView] origin].y)] autorelease];

			// remove the parent ROI on original view. (will be replaced by the new one)
			int i;
			for(i=0; i<[[[controller originalView] dcmRoiList] count]; i++)
			{
				if([[[[controller originalView] dcmRoiList] objectAtIndex:i] containsObject:[roi parentROI]])
				{
					NSLog(@"Point removed in originalView");
					[[[[controller originalView] dcmRoiList] objectAtIndex:i] removeObject:[roi parentROI]];
				}
			}
			
			// create the new ROI
			irect.size.width = irect.size.height = 0;
			[new2DPointROI setROIRect:irect];
			[[controller originalView] roiSet:new2DPointROI];
			
			// copy the name
			[new2DPointROI setName:[roi name]];
			
			// add the 2D Point ROI to the ROI list
			long slice = ([controller sign]>0)? [[[controller originalView] dcmPixList] count]-1 -[[[roi points] objectAtIndex:0] y] : [[[roi points] objectAtIndex:0] y];
			
			if( slice < 0) slice = 0;
			if( slice >= [[[controller originalView] dcmRoiList] count]) slice = [[[controller originalView] dcmRoiList] count]-1;
			
			NSLog(@"slice : %d", slice);
			
			[[[[controller originalView] dcmRoiList] objectAtIndex: slice] addObject: new2DPointROI];
			[[controller originalView] setNeedsDisplay:YES];
			
			// This is my new father
			[roi setParentROI: new2DPointROI];
			
			switch( reslicedview)
			{
				case 2:	[controller loadROIonXReslicedView: [[controller originalView] crossPositionY]];	break;
				case 1:	[controller loadROIonYReslicedView: [[controller originalView] crossPositionX]];	break;
			}
		}
		else
		{
			[controller loadROIonXReslicedView: [[controller originalView] crossPositionY]];
			[controller loadROIonYReslicedView: [[controller originalView] crossPositionX]];
		}
	}
}

- (void) removeROI: (NSNotification*) note
{
	if( [[self window] firstResponder] == self)
	{
		ROI *roi = [note object];
		
		if( [roi parentROI])
		{
			int i;
			for(i=0; i<[[[controller originalView] dcmRoiList] count]; i++)
			{
				if([[[[controller originalView] dcmRoiList] objectAtIndex:i] containsObject:[roi parentROI]])
				{
					NSLog(@"parent of removed ROI is on original view");
					[[[[controller originalView] dcmRoiList] objectAtIndex:i] removeObject:[roi parentROI]];
				}
			}
		}
	}
}

- (void) roiRemovedFromArray :(NSNotification*) note
{
	if( [controller yReslicedView] == self) [controller loadROIonYReslicedView: [[controller originalView] crossPositionX]];
	if( [controller xReslicedView] == self) [controller loadROIonXReslicedView: [[controller originalView] crossPositionY]];
	if( [controller originalView] == self) [[controller originalView] setNeedsDisplay:YES];
}

- (BOOL)is2DViewer{
	return NO;
}

#pragma mark -
#pragma mark Hot Keys.
//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
	BOOL returnedVal = YES;
	if ([hotKey length] > 0)
	{
		NSDictionary *userInfo = nil;
		NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"];
		NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
		NSArray *wwwl = nil;
		unichar key = [hotKey characterAtIndex:0];
		if( [[DCMView hotKeyDictionary] objectForKey:hotKey])
		{
			key = [[[DCMView hotKeyDictionary] objectForKey:hotKey] intValue];
			OrthogonalMPRViewer *windowController = (OrthogonalMPRViewer *)[self  windowController];
			NSString *wwwlMenuString;
		
			
			int index = 1;
			switch (key){
			
				case DefaultWWWLHotKeyAction:	// default WW/WL
						wwwlMenuString = NSLocalizedString(@"Default WL & WW", nil);	// default WW/WL
						[windowController applyWLWWForString:wwwlMenuString];
						[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: nil];
						break;
				case FullDynamicWWWLHotKeyAction:											// full dynamic WW/WL
						wwwlMenuString = NSLocalizedString(@"Full dynamic", nil);	
						[windowController applyWLWWForString:wwwlMenuString];	
						[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: nil];		
						break;
				
				case Preset1WWWLHotKeyAction:			// 1 - 9 will be presets WW/WL
				case Preset2WWWLHotKeyAction:
				case Preset3WWWLHotKeyAction:
				case Preset4WWWLHotKeyAction:
				case Preset5WWWLHotKeyAction:
				case Preset6WWWLHotKeyAction:
				case Preset7WWWLHotKeyAction:
				case Preset8WWWLHotKeyAction:
				case Preset9WWWLHotKeyAction:
					if([wwwlValues count] > key-Preset1WWWLHotKeyAction)
					{
						wwwlMenuString = [wwwlValues objectAtIndex:key-Preset1WWWLHotKeyAction];
						[windowController applyWLWWForString:wwwlMenuString];
						[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: nil];
					}	
					break;
				
				// Flip
				case FlipVerticalHotKeyAction: [self flipVertical:nil];
						break;
				case  FlipHorizontalHotKeyAction: [self flipHorizontal:nil];
						break;
				// mouse functions
				case WWWLToolHotKeyAction:		
				case MoveHotKeyAction:
				case ZoomHotKeyAction:
				case RotateHotKeyAction:
				case ScrollHotKeyAction:
				case LengthHotKeyAction:
				case OvalHotKeyAction:
				case AngleHotKeyAction:
				case ThreeDPointHotKeyAction:
				case OrthoMPRCrossHotKeyAction:
					if( [ViewerController getToolEquivalentToHotKey: key] >= 0)
					{
						[windowController setCurrentTool: [ViewerController getToolEquivalentToHotKey: key]];
					}
				break;

				//tCross
				default:
					returnedVal = NO;
				break;
			}
		}
		else returnedVal = NO;
	}
	else returnedVal = NO;
	
	return returnedVal;
}

- (void)mouseDraggedCrosshair:(NSEvent *)event {
	NSRect  frame = [self frame];
	NSPoint current = [self currentPointInView:event];
	NSPoint   eventLocation = [event locationInWindow];
	if ( [event type] != NSRightMouseDown)
	{
		eventLocation = [self convertPoint:eventLocation fromView: nil];
		eventLocation = [self ConvertFromNSView2GL:eventLocation];
		
		if ( [self isKindOfClass: [OrthogonalMPRView class]] ) {
			[(OrthogonalMPRView*)self setCrossPosition:(float)eventLocation.x : (float)eventLocation.y];
		}
		
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDraggedImageScroll:(NSEvent *) event {
	short   inc, now, prev, previmage;
	BOOL	movie4Dmove = NO;
	NSPoint current = [self currentPointInView:event];
	if( scrollMode == 0)
	{
		if( fabs( start.x - current.x) < fabs( start.y - current.y))
		{
			prev = start.y/2;
			now = current.y/2;
			if( fabs( start.y - current.y) > 3) scrollMode = 1;
		}
		else if( fabs( start.x - current.x) >= fabs( start.y - current.y))
		{
			prev = start.x/2;
			now = current.x/2;
			if( fabs( start.x - current.x) > 3) scrollMode = 2;
		}
		
	//	NSLog(@"scrollMode : %d", scrollMode);
	}


 if( movie4Dmove == NO)
	{
		long from, to, startLocation;
		if( scrollMode == 2)
		{
			from = current.x;
			to = start.x;
		}
		else if( scrollMode == 1)
		{
			from = start.y;
			to = current.y;
		}
		else
		{
			from = 0;
			to = 0;
		}
		
		if ( fabs( from-to ) >= 1) {
			[self scrollTool: from : to];
		}
	}
}

- (void)mouseDraggedBlending:(NSEvent *)event{
	[super mouseDraggedBlending:event];
	[self setWLWW: curWL :curWW];
	[blendingView setWLWW:[[blendingView curDCM] wl] :[[blendingView curDCM] ww]];
}


- (void)mouseDraggedWindowLevel: (NSEvent *)event {
	NSPoint current = [self currentPointInView:event];

	if( blendingView == nil)
	{
		float WWAdapter = startWW / 100.0;

		if( WWAdapter < 0.001) WWAdapter = 0.001;
		
		if( [self is2DViewer] == YES)
		{
			[[[self windowController] thickSlabController] setLowQuality: YES];
		}
		
		if( [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"PT"] || ([[NSUserDefaults standardUserDefaults] boolForKey:@"mouseWindowingNM"] == YES && [[[dcmFilesList objectAtIndex:0] valueForKey:@"modality"] isEqualToString:@"NM"] == YES))
		{
			float startlevel;
			float endlevel;
			
			float eWW, eWL;
			
			switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"PETWindowingMode"])
			{
				case 0:
					eWL = startWL + (current.y -  start.y)*WWAdapter;
					eWW = startWW + (current.x -  start.x)*WWAdapter;
					
					if( eWW < 0.1) eWW = 0.1;
				break;
				
				case 1:
					endlevel = startMax + (current.y -  start.y) * WWAdapter ;
					
					eWL = (endlevel - startMin) / 2 + [[NSUserDefaults standardUserDefaults] integerForKey: @"PETMinimumValue"];
					eWW = endlevel - startMin;
					
					if( eWW < 0.1) eWW = 0.1;
					if( eWL - eWW/2 < 0) eWL = eWW/2;
				break;
				
				case 2:
					endlevel = startMax + (current.y -  start.y) * WWAdapter ;
					startlevel = startMin + (current.x -  start.x) * WWAdapter ;
					
					if( startlevel < 0) startlevel = 0;
					
					eWL = startlevel + (endlevel - startlevel) / 2;
					eWW = endlevel - startlevel;
					
					if( eWW < 0.1) eWW = 0.1;
					if( eWL - eWW/2 < 0) eWL = eWW/2;
				break;
			}
			
			[curDCM changeWLWW :eWL  :eWW];
		}
		else
		{
			[curDCM changeWLWW : startWL + (current.y -  start.y)*WWAdapter :startWW + (current.x -  start.x)*WWAdapter];
		}
		
		curWW = [curDCM ww];
		curWL = [curDCM wl];
		
		if( [self is2DViewer] == YES)
		{
			[[self windowController] setCurWLWWMenu: [DCMView findWLWWPreset: curWL :curWW :curDCM]];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: [DCMView findWLWWPreset: curWL :curWW :curDCM] userInfo: nil];
		

		// change Window level
		[self setWLWW: curWL :curWW];

		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"changeWLWW" object: curDCM userInfo:nil];
		
		if( [curDCM SUVConverted] == NO)
		{
			//set value for Series Object Presentation State
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW] forKey:@"windowWidth"];
			[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL] forKey:@"windowLevel"];
		}
		else
		{
			if( [self is2DViewer] == YES)
			{
				[[self seriesObj] setValue:[NSNumber numberWithFloat:curWW / [[self windowController] factorPET2SUV]] forKey:@"windowWidth"];
				[[self seriesObj] setValue:[NSNumber numberWithFloat:curWL / [[self windowController] factorPET2SUV]] forKey:@"windowLevel"];
			}
		}
	}
	//Blending and OrthogonalMPRVIEW
	
	else
	{
		// change blending value
		blendingFactor = blendingFactorStart + (current.x - start.x);
			
		if( blendingFactor < -256.0) blendingFactor = -256.0;
		if( blendingFactor > 256.0) blendingFactor = 256.0;
		
		[self setBlendingFactor: blendingFactor];
	}
	
}

- (IBAction) flipVertical: (id)sender{
	[super flipVertical: (id)sender];
	[controller flipVertical: self];
}

- (IBAction) flipHorizontal: (id)sender{
	[super  flipHorizontal: (id)sender];
	[controller  flipHorizontal: self];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


@end
