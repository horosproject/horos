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


#import "OSIGeneralPreferencePanePref.h"
#import <OsiriX Headers/NSPreferencePane+OsiriX.h>

@interface IsQualityEnabled: NSValueTransformer {}
@end
@implementation IsQualityEnabled
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)item {
   if( [item intValue] == 3)
		return [NSNumber numberWithBool: YES];
	else
		return [NSNumber numberWithBool: NO];
}
@end

@implementation OSIGeneralPreferencePanePref

+ (void)initialize
{
	IsQualityEnabled *a = [[[IsQualityEnabled alloc] init] autorelease];	[NSValueTransformer setValueTransformer:a forName:@"IsQualityEnabled"];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
	[super dealloc];
}

- (IBAction) setAuthentication: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:@"AUTHENTICATION"];
	
	// Reload our view !
	//[[[[self mainView] window] windowController] selectPaneIndex: 0];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	
	//setup GUI
	[securityOnOff setState:[defaults boolForKey:@"AUTHENTICATION"]];
}

- (IBAction) endEditCompressionSettings:(id) sender
{
	[compressionSettingsWindow orderOut:sender];
	[NSApp endSheet: compressionSettingsWindow returnCode:[sender tag]];
	
	if( [sender tag] == 1)
	{
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setObject: compressionSettingsCopy forKey: @"CompressionSettings"];
		[[NSUserDefaults standardUserDefaults] setObject: compressionSettingsLowResCopy forKey: @"CompressionSettingsLowRes"];
	}
	
	[compressionSettingsCopy autorelease];
	[compressionSettingsLowResCopy autorelease];
}

- (IBAction) editCompressionSettings:(id) sender
{
	if ([self isUnlocked])
	{
		compressionSettingsCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] copy];
		compressionSettingsLowResCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] copy];
		
		[NSApp beginSheet: compressionSettingsWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
}

@end
