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
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import "OSIGeneralPreferencePanePref.h"
#import "NSPreferencePane+OsiriX.h"
#import "AppController.h"
#import "DefaultsOsiriX.h"
#import "N2Debug.h"

static NSArray *languagesToMoveWhenQuitting = nil;

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
            {
                NSString *name = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value: [file stringByDeletingPathExtension]];
                
                if( name.length == 0)
                    name = [file stringByDeletingPathExtension];
                
                [languages addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [file stringByDeletingPathExtension], @"foldername", name, @"language", [NSNumber numberWithBool: YES], @"active", nil]];
            }
        }
        
        for( NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath: [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Resources Disabled"] error: nil])
        {
            if( [[file pathExtension] isEqualToString: @"lproj"])
            {
                NSString *name = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value: [file stringByDeletingPathExtension]];
                
                if( name.length == 0)
                    name = [file stringByDeletingPathExtension];
                
                [languages addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: [file stringByDeletingPathExtension], @"foldername", name, @"language", [NSNumber numberWithBool: NO], @"active", nil]];
            }
        }
        
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIGeneralPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
        
        [compressionSettingsWindow retain];
		
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
	NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Reset Preferences", nil), NSLocalizedString(@"Are you sure you want to reset ALL preferences of Horos? All the preferences will be reseted to their default values.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
	
	if( result == NSAlertAlternateReturn)
	{
		for( NSString *k in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
			[[NSUserDefaults standardUserDefaults] removeObjectForKey: k];
		
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (IBAction) savePreferences: (id) sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSSavePanel *save = [NSSavePanel savePanel];
    
    [save setAllowedFileTypes: [NSArray arrayWithObject: @"plist"]];
    [save setNameFieldStringValue: @"Horos-Preferences.plist"];
    
    if( [save runModal] == NSFileHandlingPanelOKButton)
	{
        NSDictionary *defaultsPreferences = [DefaultsOsiriX getDefaults];
        NSMutableDictionary *customizedPreferences = [NSMutableDictionary dictionary];
        
        for( NSString *k in [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys])
        {
            if( [defaultsPreferences objectForKey: k] == nil || [[[NSUserDefaults standardUserDefaults] objectForKey: k] isEqual: [defaultsPreferences objectForKey: k]] == NO)
                [customizedPreferences setObject: [[NSUserDefaults standardUserDefaults] objectForKey: k] forKey: k];
        }
        
		[customizedPreferences writeToURL: save.URL atomically: YES];
	}
}

+ (void) errorMessage:(NSURL*) url
{
    NSRunAlertPanel( NSLocalizedString( @"Preferences", nil), NSLocalizedString( @"Failed to download and synchronize preferences from this URL: %@", nil), NSLocalizedString( @"OK", nil), nil, nil, url.absoluteString);
}

+ (void) addPreferencesFromURL: (NSURL*) url
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    BOOL succeed = NO;
    
    if( url)
    {
        NSLog( @"--- loading preferences from URL: %@", url);
        
        @try {
            BOOL activated = NO;
            if( [NSThread isMainThread] == NO)
                activated = [[NSUserDefaults standardUserDefaults] boolForKey: @"SyncPreferencesFromURL"];
            
            NSDictionary *customizedPreferences = [NSDictionary dictionaryWithContentsOfURL: url];
            
            if( customizedPreferences)
            {
                for( NSString *key in customizedPreferences)
                    [[NSUserDefaults standardUserDefaults] setObject: [customizedPreferences objectForKey: key] forKey: key];
                
                succeed = YES;
                
                if( [NSThread isMainThread] == NO)
                {
                    [[NSUserDefaults standardUserDefaults] setObject: url.absoluteString forKey: @"SyncPreferencesURL"];
                    [[NSUserDefaults standardUserDefaults] setBool: activated forKey: @"SyncPreferencesFromURL"];
                }
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        NSLog( @"--- loading preferences from URL: %@ - DONE", url);
    }
    
    if( succeed == NO)
        [[OSIGeneralPreferencePanePref class] performSelectorOnMainThread: @selector( errorMessage:) withObject: url waitUntilDone: NO];
    
    [pool release];
}

- (IBAction) refreshPreferencesURLSync:(id)sender
{
    [[[self mainView] window] makeFirstResponder: nil];
    
    if( [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"SyncPreferencesURL"]] == nil)
        NSRunInformationalAlertPanel( NSLocalizedString(@"Sync Preferences", nil), NSLocalizedString(@"The provided URL doesn't seem correct. Check it's validity.", nil), NSLocalizedString(@"OK",nil), nil,  nil);
    else
    {
        NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Sync Preferences", nil), NSLocalizedString(@"Are you sure you want to replace  current preferences with the preferences stored at this URL? You cannot undo this operation.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
        
        if( result == NSAlertAlternateReturn)
            [NSThread detachNewThreadSelector: @selector( addPreferencesFromURL:) toTarget: [OSIGeneralPreferencePanePref class] withObject: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"SyncPreferencesURL"]]];
    }
}

- (IBAction) loadPreferences: (id) sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSOpenPanel *open = [NSOpenPanel openPanel];
    
    open.canChooseFiles = YES;
	open.canChooseDirectories = NO;
	open.canCreateDirectories = NO;
	open.allowsMultipleSelection = NO;
	open.message = NSLocalizedString(@"Select the preferences file (plist) to load:", nil);
	
    if( [open runModal] == NSFileHandlingPanelOKButton)
    {
        NSInteger result = NSRunInformationalAlertPanel( NSLocalizedString(@"Load Preferences", nil), NSLocalizedString(@"Are you sure you want to replace  current preferences with the preferences stored in this file? You cannot undo this operation.", nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"OK",nil),  nil);
        
        if( result == NSAlertAlternateReturn)
            [OSIGeneralPreferencePanePref addPreferencesFromURL: open.URL];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    
    [compressionSettingsWindow release];
    
    [_tlos release]; _tlos = nil;
    
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
    
    [languagesToMoveWhenQuitting release];
    languagesToMoveWhenQuitting = [languages copy];
}

+ (void) applyLanguagesIfNeeded
{
    NSString *activePath = [[NSBundle mainBundle] resourcePath];
    NSString *inactivePath = [[activePath stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"Resources Disabled"];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: inactivePath] == NO)
        [[NSFileManager defaultManager] createDirectoryAtPath: inactivePath withIntermediateDirectories: NO attributes: nil error: nil];
    
    for( NSDictionary *d in languagesToMoveWhenQuitting)
    {
        NSString *language = [[d valueForKey: @"foldername"] stringByAppendingPathExtension: @"lproj"];
        
        if( [[d valueForKey: @"active"] boolValue])
        {
            if( [[NSFileManager defaultManager] fileExistsAtPath: [inactivePath stringByAppendingPathComponent: language]])
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath: [activePath stringByAppendingPathComponent: language] error: nil];
                if( [[NSFileManager defaultManager] moveItemAtPath: [inactivePath stringByAppendingPathComponent: language] toPath: [activePath stringByAppendingPathComponent: language] error: &error] == NO)
                    NSLog( @"*********** applyLanguagesIfNeeded failed: %@ %@", language, error);
            }
        }
        else
        {
            if( [[NSFileManager defaultManager] fileExistsAtPath: [activePath stringByAppendingPathComponent: language]])
            {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath: [inactivePath stringByAppendingPathComponent: language] error: nil];
                if( [[NSFileManager defaultManager] moveItemAtPath: [activePath stringByAppendingPathComponent: language] toPath: [inactivePath stringByAppendingPathComponent: language] error: &error] == NO)
                    NSLog( @"*********** applyLanguagesIfNeeded failed: %@ %@", language, error);
            }
        }
    }
    
    [languagesToMoveWhenQuitting release];
    languagesToMoveWhenQuitting = nil;
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
    if( [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] count] < 14)
    {
        NSLog( @"*** reset compression settings");
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"CompressionSettings"];
    }
    
    if( [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] count] < 14)
    {
        NSLog( @"*** reset compression settings");
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"CompressionSettingsLowRes"];
    }
    
    compressionSettingsCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettings"] copy];
    compressionSettingsLowResCopy = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"CompressionSettingsLowRes"] copy];
    
    [NSApp beginSheet: compressionSettingsWindow modalForWindow: [[self mainView] window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

@end
