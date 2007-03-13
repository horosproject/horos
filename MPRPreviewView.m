//
//  MPRPreviewView.m
//  OsiriX
//
//  Created by Lance Pysher on 12/28/06.

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

#import "MPRPreviewView.h"
#import "DefaultsOsiriX.h"
#import "MPR2DController.h"


@implementation MPRPreviewView

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
			MPR2DController *windowController = (MPR2DController *)[self  windowController];
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



- (void) scaleToFit {
	NSRect  sizeView = [self bounds];	
	//Need ratio of image Size to view size to scale.
	float  width;
	float height;
	width = [[[curDCM imageObj] valueForKey:@"width"] floatValue];
	height = [[[curDCM imageObj] valueForKey:@"height"] floatValue];
	float ratio;
	// for some reason checking the height and width here and then calling the super
	// create correct scaling
	NSLog(@"ratio: %f", ratio);
	if (width > 0.0 ||  height > 0.0) {
		if( sizeView.size.width/width < sizeView.size.height/height)
			ratio = sizeView.size.width/width; 
		else
			ratio = sizeView.size.height/height;
		// scale better if multiplied by 1.5 
		[self setScaleValue: ratio * 1.5];
		[self setNeedsDisplay:YES];
	}
	//DCMPixs for MPRs don't scale correctly. Need to address MPR Views still
	else [super scaleToFit];
}



@end
