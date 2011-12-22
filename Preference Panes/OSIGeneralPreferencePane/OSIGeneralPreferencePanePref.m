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
#import <OsiriXAPI/NSPreferencePane+OsiriX.h>
#import <OsiriXAPI/AppController.h>

@interface IsQualityEnabled: NSValueTransformer {}
@end
@implementation IsQualityEnabled
+ (Class)transformedValueClass { return [NSNumber class]; }
+ (BOOL)allowsReverseTransformation { return NO; }
- (id)transformedValue:(id)item {
   if( [item intValue] == 3 || [item intValue] == 4)
		return [NSNumber numberWithBool: YES];
	else
		return [NSNumber numberWithBool: NO];
}
@end

@implementation OSIGeneralPreferencePanePref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIGeneralPreferencePanePref" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

- (NSUInteger) kakaduAvailable
{
	return [AppController isKDUEngineAvailable];
}

- (NSUInteger) JP2KWriter
{
	return [[NSUserDefaults standardUserDefaults] boolForKey: @"useDCMTKForJP2K"];
}

- (void) setJP2KWriter:(NSUInteger) v
{
	[[NSUserDefaults standardUserDefaults] setBool: v forKey: @"useDCMTKForJP2K"];
	
	[self willChangeValueForKey: @"JP2KWriter"];
	[self didChangeValueForKey: @"JP2KWriter"];
	
	[self willChangeValueForKey: @"JP2KEngine"];
	[self didChangeValueForKey: @"JP2KEngine"];
}

- (void) setJP2KEngine: (NSUInteger) val;
{	
	if( val == 1) // Kakadu
	{
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseKDUForJPEG2000"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseOpenJpegForJPEG2000"];
	}
	
	if( val == 0) // OpenJPEG
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"UseKDUForJPEG2000"];
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"UseOpenJpegForJPEG2000"];
	}
	
	[self willChangeValueForKey: @"JP2KWriter"];
	[self didChangeValueForKey: @"JP2KWriter"];
	
	[self willChangeValueForKey: @"JP2KEngine"];
	[self didChangeValueForKey: @"JP2KEngine"];
}

- (NSUInteger) JP2KEngine
{
	if( [AppController isKDUEngineAvailable] == 1 && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseKDUForJPEG2000"])
	{
		return 1; // Kakadu
	}
	
	if( [AppController isKDUEngineAvailable] == 0 && [[NSUserDefaults standardUserDefaults] boolForKey: @"UseKDUForJPEG2000"])
	{
		return 0; // OpenJPEG
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseOpenJpegForJPEG2000"])
	{
		return 0; // OpenJPEG
	}
	
	return 0; // OpenJPEG
}

- (IBAction) resetPreferences: (id) sender
{
	NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Reset Preferences", nil), NSLocalizedString(@"Are you sure you want to reset ALL preferences of OsiriX? All the preferences will be reseted to their default values.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
	
	if( result == NSAlertAlternateReturn)
	{
		for( NSString *k in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
			[[NSUserDefaults standardUserDefaults] removeObjectForKey: k];
		
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

+ (void)initialize
{
	IsQualityEnabled *a = [[[IsQualityEnabled alloc] init] autorelease];
	
	[NSValueTransformer setValueTransformer:a forName:@"IsQualityEnabled"];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIGeneralPreferencePanePref");
	
	[super dealloc];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
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
