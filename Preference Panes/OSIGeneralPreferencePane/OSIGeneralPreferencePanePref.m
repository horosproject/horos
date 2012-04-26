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

@synthesize languages;

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
        // Scan for available languages
        self.languages = [NSMutableArray array];
        for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [[NSBundle mainBundle] resourcePath] error: nil])
        {
            if( [[file pathExtension] isEqualToString: @"lproj"])
                [languages addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [file stringByDeletingPathExtension], @"language", [NSNumber numberWithBool: YES], @"active", nil]];
        }
        
        for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Resources Disabled"] error: nil])
        {
            if( [[file pathExtension] isEqualToString: @"lproj"])
                [languages addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [file stringByDeletingPathExtension], @"language", [NSNumber numberWithBool: NO], @"active", nil]];
        }
        
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
	
    [languages release];
    
	[super dealloc];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
    BOOL enabled = NO;
    
    for( NSDictionary *d in languages)
    {
        if( [[d valueForKey: @"active"] boolValue])
            enabled = YES;
    }
    
    // At least one language must be active !
    if( enabled == NO)
        [[languages objectAtIndex: 0] setValue: [NSNumber numberWithBool: YES] forKey: @"active"];
    
    NSString *activePath = [[NSBundle mainBundle] resourcePath];
    NSString *inactivePath = [[activePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Resources Disabled"];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: inactivePath] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath: inactivePath withIntermediateDirectories: NO attributes: nil error: nil];
    
    for( NSDictionary *d in languages)
    {
        NSString *language = [[d valueForKey: @"language"] stringByAppendingPathExtension: @"lproj"];
        
        if( [[d valueForKey: @"active"] boolValue])
        {
            [[NSFileManager defaultManager] moveItemAtPath: [inactivePath stringByAppendingPathComponent: language] toPath: [activePath stringByAppendingPathComponent: language] error: nil];
        }
        else
        {
            [[NSFileManager defaultManager] moveItemAtPath: [activePath stringByAppendingPathComponent: language] toPath: [inactivePath stringByAppendingPathComponent: language] error: nil];
        }
    }
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
