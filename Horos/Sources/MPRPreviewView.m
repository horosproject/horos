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

#import "MPRPreviewView.h"
#import "DefaultsOsiriX.h"
#import "MPR2DController.h"
#import "MPR2DView.h"

@implementation MPRPreviewView

#pragma mark -
#pragma mark Hot Keys.
//Hot key action
-(BOOL)actionForHotKey:(NSString *)hotKey
{
	BOOL returnedVal = YES;
	if ([hotKey length] > 0)
	{
		NSDictionary *wlwwDict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"WLWW3"];
		NSArray *wwwlValues = [[wlwwDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
		hotKey = [hotKey lowercaseString];
		unichar key = [hotKey characterAtIndex:0];

		if( [[DCMView hotKeyDictionary] objectForKey:hotKey])
		{
			key = [[[DCMView hotKeyDictionary] objectForKey:hotKey] intValue];
			MPR2DController *windowController = (MPR2DController *)[self  windowController];
			NSString *wwwlMenuString;
		
			
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
						
				case Preset1WWWLHotKeyAction:																	// 1 - 9 will be presets WW/WL
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
				if( [ViewerController getToolEquivalentToHotKey: key] >= 0)
					{
						[windowController setCurrentTool: [ViewerController getToolEquivalentToHotKey: key]];
					}
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
	long  width;
	long height;
	width = [[[curDCM imageObj] valueForKey:@"width"] floatValue];
	height = [[[curDCM imageObj] valueForKey:@"height"] floatValue];
	float ratio;
	// for some reason checking the height and width here and then calling the super
	// create correct scaling
	
	//try again with pwidth and pheight
	if (width ==  0.0 ||  height == 0.0) {
		width = [curDCM pwidth];
		height = [curDCM pheight];
	}
	//NSLog(@"curDCM: %@", curDCM);
	//NSLog(@"width: %d  height: %d", width, height);
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

- (void)mouseDraggedBlending:(NSEvent *)event{
	[super mouseDraggedBlending:event];
	[[[[self windowController] blendingController] imageView] setWLWW :[[blendingView curDCM] wl] :[[blendingView curDCM] ww]];
	[(MPR2DView*) [[self windowController] MPR2Dview] adjustWLWW: curWL :curWW :@"dragged"];
}
@end
