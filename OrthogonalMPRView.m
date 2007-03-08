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

#import "OrthogonalMPRController.h"
#import "OrthogonalMPRView.h"
#import "DCMPix.h"

#import "OrthogonalMPRViewer.h"
#import "ROI.h"
#import "DefaultsOsiriX.h"

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
	
	curWLWWMenu = [NSLocalizedString(@"Other", 0L) retain];
	
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
	long i;
	[controller release];
	[curWLWWMenu release];
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
	[self setPixList: pix : files : 0L];
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
	long	i;
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
	
	for(i=0; i<[curRoiList count]; i++)
	{
		[self roiSet:[curRoiList objectAtIndex:i]];
	}
	
//	for( i = 0 ; i < [curRoiList count]; i++)
//	{
//		if( [[curRoiList objectAtIndex: i] parentROI])
//		{
//			if( [previousParents containsObject: [[curRoiList objectAtIndex: i] parentROI]])
//			{
//				int index = [previousParents indexOfObject: [[curRoiList objectAtIndex: i] parentROI]];
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

// overwrite the DCMView method:
- (void) addROI:(NSNotification*)note
{
	NSLog(@"addROI:(NSNotification*)note [overwrited]");
	DCMView *sender = [note object];
	ROI *addedROI = [[note userInfo] objectForKey:@"ROI"];
	int sliceNumber = [[[note userInfo] objectForKey:@"sliceNumber"] intValue];
	
	if( [addedROI type] != t2DPoint) return;
	
	if (![self isEqualTo:sender])// && ![self isEqualTo:[controller xReslicedView]] && ![self isEqualTo:[controller yReslicedView]])
	{
		if (([[controller xReslicedView] isEqualTo:sender] || [[controller yReslicedView] isEqualTo:sender]) && [[controller originalView] isEqualTo:self])
		{
			NSLog(@"sender is xReslicedView OR yReslicedView");
			if([addedROI type]==t2DPoint)
			{
				NSLog(@"ROI is a Point");
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
				
				int i;
				for(i=0; i<[curRoiList count]; i++)
				{
					[[curRoiList objectAtIndex:i] setROIMode:ROI_sleep];
				}
				
				// copy the state
				[new2DPointROI setROIMode:ROI_selected];
				// copy the name
				[new2DPointROI setName:[addedROI name]];
					
				// add the 2D Point ROI to the ROI list
				long slice = ([controller sign]>0)? [[[controller originalView] dcmPixList] count]-1 -[[[addedROI points] objectAtIndex:0] y] : [[[addedROI points] objectAtIndex:0] y];
				
				if( slice < 0) slice = 0;
				if( slice >= [[[controller originalView] dcmRoiList] count]) slice = [[[controller originalView] dcmRoiList] count]-1;

				NSLog(@"slice : %d", slice);
				
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
		if( [_hotKeyDictionary objectForKey:hotKey])
		{
			key = [[_hotKeyDictionary objectForKey:hotKey] intValue];
			OrthogonalMPRViewer *windowController = (OrthogonalMPRViewer *)[self  windowController];
			NSString *wwwlMenuString;
		
			
			int index = 1;
			switch (key){
			
				case DefaultWWWLHotKeyAction:	// default WW/WL
						wwwlMenuString = NSLocalizedString(@"Default WL & WW", 0L);	// default WW/WL
						[windowController applyWLWWForString:wwwlMenuString];
						[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
						break;
				case FullDynamicWWWLHotKeyAction:											// full dynamic WW/WL
						wwwlMenuString = NSLocalizedString(@"Full dynamic", 0L);	
						[windowController applyWLWWForString:wwwlMenuString];	
						[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];		
						break;
																						// 1 - 9 will be presets WW/WL
				case Preset1WWWLHotKeyAction: if([wwwlValues count] >= 1)  {
								wwwlMenuString = [wwwlValues objectAtIndex:0];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset2WWWLHotKeyAction: if([wwwlValues count] >= 2) {
								wwwlMenuString = [wwwlValues objectAtIndex:1];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset3WWWLHotKeyAction: if([wwwlValues count] >= 3) {
								wwwlMenuString = [wwwlValues objectAtIndex:2];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset4WWWLHotKeyAction: if([wwwlValues count] >= 4) {
								wwwlMenuString = [wwwlValues objectAtIndex:3];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset5WWWLHotKeyAction: if([wwwlValues count] >= 5) {
								wwwlMenuString = [wwwlValues objectAtIndex:4];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset6WWWLHotKeyAction: if([wwwlValues count] >= 6) {
								wwwlMenuString = [wwwlValues objectAtIndex:5];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset7WWWLHotKeyAction: if([wwwlValues count] >= 7) {
								wwwlMenuString = [wwwlValues objectAtIndex:6];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset8WWWLHotKeyAction: if([wwwlValues count] >= 8) {
								wwwlMenuString = [wwwlValues objectAtIndex:7];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
				case Preset9WWWLHotKeyAction: if([wwwlValues count] >= 9) {
								wwwlMenuString = [wwwlValues objectAtIndex:8];
								[windowController applyWLWWForString:wwwlMenuString];
								[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateWLWWMenu" object: wwwlMenuString userInfo: 0L];
							}
						break;
		
				// Flip
				case FlipVerticalHotKeyAction: [self flipVertical:nil];
						break;
				case  FlipHorizontalHotKeyAction: [self flipHorizontal:nil];
						break;
				// mouse functions
				case WWWLToolHotKeyAction:		
					[windowController setCurrentTool:tWL];
					break;
				case MoveHotKeyAction:		
					[windowController setCurrentTool:tTranslate];
					break;
				case ZoomHotKeyAction:		
					[windowController setCurrentTool:tZoom];
					break;
				case RotateHotKeyAction:		
					[windowController setCurrentTool:tRotate];
					break;
				case ScrollHotKeyAction:		
					[windowController setCurrentTool:tNext];
					break;
				case LengthHotKeyAction:		
					[windowController setCurrentTool:tMesure];
					break;
				case OvalHotKeyAction:		
					[windowController setCurrentTool:tOval];
					break;
				case AngleHotKeyAction:		
					[windowController setCurrentTool:tAngle];
					break;
				case ThreeDPointHotKeyAction:		
					[windowController setCurrentTool:t3Dpoint];
					break;
				case PlainToolHotKeyAction:		
					[windowController setCurrentTool:tPlain];
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


@end
