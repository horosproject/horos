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
