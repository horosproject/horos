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

#import "BrowserController.h"
#import "Window3DController.h"
#import "Mailer.h"
#import <Accelerate/Accelerate.h>
#import "DCMPix.h"
#import "VRController.h"
#import "printView.h"
#import "VRView.h"
#import "Notifications.h"
#import "NSUserDefaultsController+OsiriX.h"
#import "DicomDatabase.h"

@interface Window3DController (Dummy)

- (void)noAction:(id)dummy;

@end

@implementation Window3DController

#ifndef OSIRIX_LIGHT
- (void) mprViewer:(id) sender
{
	[[self viewer] mprViewer: sender];
}

- (void) cprViewer:(id) sender
{
	[[self viewer] cprViewer: sender];
}

- (void) endoscopyViewer:(id) sender
{
	[[self viewer] endoscopyViewer: sender];
}

- (void) VRViewer:(id) sender
{
	[[self viewer] VRViewer: sender];
}

- (void) SRViewer:(id) sender
{
	[[self viewer] SRViewer: sender];
}
#endif
- (void) orthogonalMPRViewer:(id) sender
{
	[[self viewer] orthogonalMPRViewer: sender];
}

- (ViewerController*) viewer
{
	return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	BOOL valid = NO;
	
	if( [item action] == @selector(ApplyCLUT:))
	{
		valid = YES;
		
		if( [[item title] isEqualToString: curCLUTMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
//	else if( [item action] == @selector(ApplyConv:))
//	{
//		valid = YES;
//		
//		if( [[item title] isEqualToString: curConvMenu]) [item setState:NSOnState];
//		else [item setState:NSOffState];
//	}
	else if( [item action] == @selector(ApplyOpacity:))
	{
		valid = YES;
		
		if( [[item title] isEqualToString: curOpacityMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
	else if( [item action] == @selector(ApplyWLWW:))
	{
		valid = YES;
		
		NSString	*str = nil;
		
		@try
		{
			str = [[item title] substringFromIndex: 4];
		}
		
		@catch (NSException * e) {}
		
		if( [str isEqualToString: curWLWWMenu] || [[item title] isEqualToString: curWLWWMenu]) [item setState:NSOnState];
		else [item setState:NSOffState];
	}
	else  if( [item action] == @selector(showCLUTOpacityPanel:))
	{
		if([[[self pixList] objectAtIndex:0] isRGB] == NO) valid = YES;
	}
	else if( [item action] == @selector(loadAdvancedCLUTOpacity:))
	{
		if([[[self pixList] objectAtIndex:0] isRGB] == NO) valid = YES;
	}
	else if( [item action] == @selector(noAction:))
	{
		valid = NO;
	}
	else
	{
		valid = YES;
	}
	
    return valid;
}

- (int) syncSeriesState
{
    return 0;
}

- (NSArray*) pixList
{
	return nil;
}

- (NSArray*) fileList
{
	return nil;
}

- (void)printOperationDidRun:(NSPrintOperation *)printOperation
                success:(BOOL)success
                contextInfo:(void*)info
{
    if (success)
	{
	
    }
	
	NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];
	
	[[NSFileManager defaultManager] removeItemAtPath: tmpFolder error:NULL];
}

- (void) print:(id) sender
{
	NSMutableDictionary	*settings = [NSMutableDictionary dictionaryWithDictionary: [[NSUserDefaults standardUserDefaults] objectForKey: @"previousPrintSettings"]];
	
	[settings setObject: [NSNumber numberWithInt: 1] forKey: @"columns"];
	[settings setObject: [NSNumber numberWithInt: 1] forKey: @"rows"];
		
	// ************
	NSString	*tmpFolder = [NSString stringWithFormat:@"/tmp/print"];
	
	NSMutableArray	*files = [NSMutableArray array];

	[[NSFileManager defaultManager] removeItemAtPath: tmpFolder error:NULL];
	[[NSFileManager defaultManager] createDirectoryAtPath:tmpFolder withIntermediateDirectories:YES attributes:nil error:NULL];

	NSImage *im = ( [[self view] respondsToSelector: @selector(nsimageQuicktime:)] ) ?
		[(VRView*) [self view] nsimageQuicktime] : nil;
	
	NSData *imageData = [im  TIFFRepresentation];
	NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
	NSData *bitmapData = [imageRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	
	[files addObject: [tmpFolder stringByAppendingFormat:@"/%d", 1]];
	
	[bitmapData writeToFile: [files lastObject] atomically:YES];

	// ************
	
	printView	*pV = [[[printView alloc] initWithViewer: self settings: settings files: files printInfo: [NSPrintInfo sharedPrintInfo]] autorelease];
			
	NSPrintOperation * printOperation = [NSPrintOperation printOperationWithView: pV];
	
	[printOperation setCanSpawnSeparateThread: YES];
	
	[printOperation runOperationModalForWindow:[self window]
		delegate:self
		didRunSelector: @selector(printOperationDidRun:success:contextInfo:)
		contextInfo:nil];
}

//====================================================================================================================================================================================================================

- (BOOL)is4D;
{
	return NO;
}

- (void) sendMailImage: (NSImage*) im
{
	Mailer		*email;
	
	NSArray *representations;
	NSData *bitmapData;

	representations = [im representations];

	bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];

	[bitmapData writeToFile:[[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"Horos.jpg"] atomically:YES];
				
	email = [[Mailer alloc] init];
	
	[email sendMail:@"--" to:@"--" subject:@"" isMIME:YES name:@"--" sendNow:NO image: [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"Horos.jpg"]];
	
	[email release];
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (ViewerController*) blendingController
{
	return nil;
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (id) view
{
	return nil;
}

-(long) movieFrames { return 1;}

- (void) setMovieFrame: (long) l
{
	
}

- (BOOL) windowWillClose
{
	return windowWillClose;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self];
    
	windowWillClose = YES;
	
	NSLog(@"Window3DController dealloc");
	
	[curCLUTMenu release];
	[curWLWWMenu release];
	[curOpacityMenu release];
	
	[super dealloc];
}

- (void) hideROIVolume: (ROIVolume*) v
{
// Override
	NSLog(@"Error: inherited [Window3DController hideROIVolume] should not be called");
}

- (void) displayROIVolume: (ROIVolume*) v
{
// Override
	NSLog(@"Error: inherited [Window3DController displayROIVolume] should not be called");
}

- (NSArray*) roiVolumes
{
// Override
	NSLog(@"Error: inherited [Window3DController roiVolumes] should not be called");
	
	return nil;
}

//====================================================================================================================================================================================================================
#pragma mark-
#pragma mark Common WL/WW Functions

- (void) setWLWW: (float) wl : (float) ww
{
// Override
	NSLog(@"Error: inherited [Window3DController setWLWW] should not be called");
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) getWLWW: (float*) wl : (float*) ww
{
// Override
	NSLog(@"Error: inherited [Window3DController getWLWW] should not be called");
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

static float oldsetww, oldsetwl;

- (IBAction) updateSetWLWW:(id) sender
{
	if( [sender tag] == 0)
	{
		[self setWLWW: [wlset floatValue] :[wwset floatValue]];
		
		[fromset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] - [wwset floatValue]/2]];
		[toset setStringValue: [NSString stringWithFormat:@"%.3f", [wlset floatValue] + [wwset floatValue]/2]];
	}
	else
	{
		[self setWLWW: [fromset floatValue] + ([toset floatValue] - [fromset floatValue])/2 :[toset floatValue] - [fromset floatValue]];
		[wlset setStringValue: [NSString stringWithFormat:@"%.3f", [fromset floatValue] + ([toset floatValue] - [fromset floatValue])/2]];
		[wwset setStringValue: [NSString stringWithFormat:@"%.3f", [toset floatValue] - [fromset floatValue]]];
	}
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) SetWLWW: (id) sender
{
	float iwl = 2, iww = 2;
	
    [self getWLWW:&iwl :&iww];
    
	oldsetww = iww;
	oldsetwl = iwl;
	
    [wlset setStringValue:[NSString stringWithFormat:@"%.3f", iwl ]];
    [wwset setStringValue:[NSString stringWithFormat:@"%.3f", iww ]];
	
	[fromset setStringValue:[NSString stringWithFormat:@"%.3f", [wlset floatValue] - [wwset floatValue]/2]];
	[toset setStringValue:[NSString stringWithFormat:@"%.3f", [wlset floatValue] + [wwset floatValue]/2]];
	
    [NSApp beginSheet: setWLWWWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) endSetWLWW: (id) sender
{
	[wlset selectText: self];
		
    [setWLWWWindow orderOut: sender];
    
    [NSApp endSheet: setWLWWWindow returnCode: [sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		[self setWLWW: [wlset floatValue] :[wwset floatValue] ];
    }
	else
	{
		[self setWLWW: oldsetwl : oldsetww ];
	}
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) endNameWLWW: (id) sender
{
	float					iww, iwl;
	
    NSLog(@"endNameWLWW");
    
    iwl = [wl floatValue];
    iww = [ww floatValue];
    if (iww == 0) iww = 1;

    [addWLWWWindow orderOut: sender];
    
    [NSApp endSheet:addWLWWWindow returnCode: [sender tag]];
    
    if( [sender tag])					//User clicks OK Button
    {
		NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
        [presetsDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:iwl], [NSNumber numberWithFloat:iww], nil] forKey:[newName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
		
		if( curWLWWMenu != [newName stringValue])
		{
			[curWLWWMenu release];
			curWLWWMenu = [[newName stringValue] retain];
		}
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) deleteWLWW: (NSWindow *) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo
{
	NSString	*name = (id) contextInfo;
	
    if( returnCode == 1)
    {
		NSMutableDictionary *presetsDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"WLWW3"] mutableCopy] autorelease];
        [presetsDict removeObjectForKey: name];
		[[NSUserDefaults standardUserDefaults] setObject: presetsDict forKey:@"WLWW3"];
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
    }
	
	[name release];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (NSPopUpButton*) wlwwPopup
{
	return wlwwPopup;
}


//====================================================================================================================================================================================================================
#pragma mark-
#pragma mark Common CLUT Functions

- (IBAction) AddCLUT: (id) sender
{
	[self clutAction: self];
	[clutName setStringValue: NSLocalizedString(@"Unnamed", Nil)];
	
    [NSApp beginSheet: addCLUTWindow modalForWindow: [self window] modalDelegate: self didEndSelector: Nil contextInfo: Nil];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) clutAction: (id) sender
{

//	[view setCLUT:matrix :[[sizeMatrix selectedCell] tag] :[matrixNorm intValue]];
//	[imageView setIndex:[imageView curImage]];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) endCLUT: (id) sender
{
    [addCLUTWindow orderOut:sender];
    
    [NSApp endSheet:addCLUTWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableDictionary *clutDict		= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
		unsigned char		red[256], green[256], blue[256];
		long				i;
		
		[clutView ConvertCLUT: red: green: blue];
		
		NSMutableArray		*rArray = [NSMutableArray array];
		NSMutableArray		*gArray = [NSMutableArray array];
		NSMutableArray		*bArray = [NSMutableArray array];
		for( i = 0; i < 256; i++) [rArray addObject: [NSNumber numberWithLong: red[ i]]];
		for( i = 0; i < 256; i++) [gArray addObject: [NSNumber numberWithLong: green[ i]]];
		for( i = 0; i < 256; i++) [bArray addObject: [NSNumber numberWithLong: blue[ i]]];
		
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		[aCLUTFilter setObject:[NSArray arrayWithArray:[[[clutView getPoints] copy] autorelease]] forKey:@"Points"];
		[aCLUTFilter setObject:[NSArray arrayWithArray:[[[clutView getColors] copy] autorelease]] forKey:@"Colors"];

		
		[clutDict setObject: aCLUTFilter forKey:[clutName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];
		
		// Apply it!
		if( curCLUTMenu != [clutName stringValue])
		{
			[curCLUTMenu release];
			curCLUTMenu = [[clutName stringValue] retain];
        }
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
		
		[self ApplyCLUTString: curCLUTMenu];
    }
	else
	{
		[self ApplyCLUTString: curCLUTMenu];
	}
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) ApplyCLUT: (id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Remove a Color Look Up Table", nil), NSLocalizedString(@"Delete", nil), NSLocalizedString(@"Cancel", nil), nil, [self window],
		  self, @selector(deleteCLUT:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString( @"Are you sure you want to delete this CLUT : '%@'", nil), [sender title]);
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
	}
	else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSAlternateKeyMask)
    {
		NSDictionary		*aCLUT;
		
		[self ApplyCLUTString: [sender title]];
		
		aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
		if (aCLUT)
		{
			if( [aCLUT objectForKey:@"Points"] != nil)
			{
				[self clutAction:self];
				[clutName setStringValue: [sender title]];
				
				NSMutableArray	*pts = [clutView getPoints];
				NSMutableArray	*cols = [clutView getColors];
				
				[pts removeAllObjects];
				[cols removeAllObjects];
				
				[pts addObjectsFromArray: [aCLUT objectForKey: @"Points"]];
				[cols addObjectsFromArray: [aCLUT objectForKey: @"Colors"]];
				
				[NSApp beginSheet: addCLUTWindow modalForWindow: [self window] modalDelegate: self didEndSelector: Nil contextInfo: Nil];
				
				[clutView setNeedsDisplay: YES];
			}
			else
			{
				NSRunAlertPanel(NSLocalizedString(@"Error", nil), NSLocalizedString(@"Only CLUT created in OsiriX 1.3.1 or higher can be edited...", nil), nil, nil, nil);
			}
		}
	}
    else
    {
		[self ApplyCLUTString: [sender title]];
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) load3DState
{
//	Override.
	NSLog(@"Error: inherited [Window3DController load3DState] should not be called");
}

- (void) ApplyCLUTString: (NSString*) str
{
//	Override.
	NSLog(@"Error: inherited [Window3DController ApplyCLUTString] should not be called");
}

- (void) ApplyOpacityString: (NSString*) str
{
//	Override.
	NSLog(@"Error: inherited [Window3DController ApplyOpacityString] should not be called");
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) deleteCLUT: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo
{
    if (returnCode==1)
    {
		NSMutableDictionary *clutDict	= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
		[clutDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];

		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) UpdateCLUTMenu: (NSNotification*) note
{
    //*** Build the menu
    short							i;
    NSArray							*keys;
    NSArray							*sortedKeys;

    // Presets VIEWER Menu
	
	keys = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] allKeys];
    sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
    [[clutPopup menu] removeAllItems];
	
	[[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:nil keyEquivalent:@""];
    [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"No CLUT", nil) action:@selector (ApplyCLUT:) keyEquivalent:@""];
	[[clutPopup menu] addItem: [NSMenuItem separatorItem]];
	
    for( i = 0; i < [sortedKeys count]; i++)
    {
        [[clutPopup menu] addItemWithTitle:[sortedKeys objectAtIndex:i] action:@selector (ApplyCLUT:) keyEquivalent:@""];
    }
    [[clutPopup menu] addItem: [NSMenuItem separatorItem]];
    [[clutPopup menu] addItemWithTitle:NSLocalizedString(@"8-bit CLUT Editor", nil) action:@selector (AddCLUT:) keyEquivalent:@""];

	[[[clutPopup menu] itemAtIndex:0] setTitle:curCLUTMenu];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) CLUTChanged: (NSNotification*) note
{
	unsigned char   r[256], g[256], b[256];

	
	[[note object] ConvertCLUT: r : g : b];
	[[self view] setCLUT: r : g : b];
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (NSPopUpButton*) clutPopup
{
	return clutPopup;
}


//====================================================================================================================================================================================================================
#pragma mark-
#pragma mark Common Opacity Functions


- (void) ApplyOpacity: (id) sender
{
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSShiftKeyMask)
    {
        NSBeginAlertSheet(NSLocalizedString(@"Remove an Opacity Table",nil), NSLocalizedString(@"Delete",nil), NSLocalizedString(@"Cancel", nil), nil, [self window], self, @selector(deleteOpacity:returnCode:contextInfo:), NULL, [sender title], NSLocalizedString(@"Are you sure you want to delete this Opacity Table : '%@'?", Nil), [sender title]);
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
	}
	else if ([[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
    {
		NSDictionary		*aOpacity, *aCLUT;
		NSArray				*array;
		long				i;
		unsigned char		red[256], green[256], blue[256];
		
		[self ApplyOpacityString: [sender title]];
		
		aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: curOpacityMenu];
		if( aOpacity)
		{
			aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: curCLUTMenu];
			if( aCLUT)
			{
				array = [aCLUT objectForKey:@"Red"];
				for( i = 0; i < 256; i++)
				{
					red[i] = [[array objectAtIndex: i] longValue];
				}
				
				array = [aCLUT objectForKey:@"Green"];
				for( i = 0; i < 256; i++)
				{
					green[i] = [[array objectAtIndex: i] longValue];
				}
				
				array = [aCLUT objectForKey:@"Blue"];
				for( i = 0; i < 256; i++)
				{
					blue[i] = [[array objectAtIndex: i] longValue];
				}
				
				[OpacityView setCurrentCLUT:red :green: blue];
			}
	
			if( [aOpacity objectForKey:@"Points"] != nil)
			{
				[OpacityName setStringValue: curOpacityMenu];
				
				NSMutableArray	*pts = [OpacityView getPoints];
				
				[pts removeAllObjects];
				
				[pts addObjectsFromArray: [aOpacity objectForKey:@"Points"]];
				
				[NSApp beginSheet: addOpacityWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
				
				[OpacityView setNeedsDisplay:YES];
			}
		}
	}
    else
    {
		[self ApplyOpacityString:[sender title]];
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) endOpacity: (id) sender
{
    [addOpacityWindow orderOut: sender];
    
    [NSApp endSheet: addOpacityWindow returnCode: [sender tag]];
    
    if ([sender tag])						//User clicks OK Button
    {
		NSMutableDictionary		*opacityDict		= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy] autorelease];
		NSMutableDictionary		*aOpacityFilter		= [NSMutableDictionary dictionary];
		
		[aOpacityFilter setObject: [[[OpacityView getPoints] copy] autorelease] forKey: @"Points"];
		[opacityDict setObject: aOpacityFilter forKey: [OpacityName stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: opacityDict forKey: @"OPACITY"];
		
		// Apply it!
		
		[self ApplyOpacityString: [OpacityName stringValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
    }
	else
	{
		[self ApplyOpacityString: curOpacityMenu];
	}
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void) deleteOpacity: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo
{
    if (returnCode == 1)
    {
		NSMutableDictionary *opacityDict = [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] mutableCopy] autorelease];
		[opacityDict removeObjectForKey: (id) contextInfo];
		[[NSUserDefaults standardUserDefaults] setObject: opacityDict forKey: @"OPACITY"];
        
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
    }
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (NSPopUpButton*) OpacityPopup
{
	return OpacityPopup;
}


//====================================================================================================================================================================================================================
#pragma mark-
#pragma mark Common Full Screen Functions

- (void) fullWindowView: (id) sender
{
}

- (void) offFullScreen
{
	if (FullScreenOn)
		[self fullScreenMenu: self];
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) fullScreenMenu: (id) sender
{
    if( FullScreenOn == YES )									// we need to go back to non-full screen
    {
        [StartingWindow setContentView: contentView];
//		[FullScreenWindow setContentView: nil];
    
        [FullScreenWindow setDelegate:nil];
        [FullScreenWindow close];
        [FullScreenWindow release];
        
//		[contentView release];
        
        [StartingWindow makeKeyAndOrderFront: self];
//		[StartingWindow makeFirstResponder: self];
        FullScreenOn = NO;
    }
    else														// FullScreenOn == NO
    {
        unsigned int windowStyle;
        NSRect       contentRect;
        
        
        StartingWindow = [self window];
        windowStyle    = NSBorderlessWindowMask; 
        contentRect    = [[NSScreen mainScreen] frame];
        FullScreenWindow = [[NSFullScreenWindow alloc] initWithContentRect:contentRect styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
        if(FullScreenWindow != nil)
        {
            NSLog(@"Window was created");			
            [FullScreenWindow setTitle: @"myWindow"];			
            [FullScreenWindow setReleasedWhenClosed: NO];
            [FullScreenWindow setLevel: NSScreenSaverWindowLevel - 1];
            [FullScreenWindow setBackgroundColor:[NSColor blackColor]];
            
            
            
            contentView = [[self window] contentView];
            [FullScreenWindow setContentView: contentView];
            
            [FullScreenWindow makeKeyAndOrderFront: self];
            [FullScreenWindow makeFirstResponder: [self view]];
            
            [FullScreenWindow setDelegate: self];
            [FullScreenWindow setWindowController: self];
            
            FullScreenOn = YES;
        }
    }
}



@end
