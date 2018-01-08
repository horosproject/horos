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

#import "QueryController.h"
#import "PreferencesView.h"
#import "N2Debug.h"
#import "NSWindow+N2.h"
#import <Security/Security.h>
#import "PreferencesWindowController.h"
#import "N2AdaptiveBox.h"
#import "AppController.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "DCMView.h"
#import "PluginManagerController.h"
#import <Foundation/NSObjCRuntime.h>
#include <algorithm>

#include "url.h"

//static NSMutableDictionary *paneBundles = nil;

@interface PreferencesWindowController (Dummy)

- (void)enableControls:(id)dummy;

@end

@interface PreferencesFlippedView : NSView

@end

@implementation PreferencesWindowContext

@synthesize title = _title, parentBundle = _parentBundle, resourceName = _resourceName, pane = _pane;

-(id) initWithTitle:(NSString*)title withResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle
{
	self = [super init];
	
	self.title = title;
	self.parentBundle = parentBundle;
	self.resourceName = resourceName;
	
	return self;
}


-(void) dealloc
{
	//NSLog(@"[PreferencesWindowContext dealloc], title %@", self.title);
	self.title = NULL;
	self.parentBundle = NULL;
	self.resourceName = NULL;
	self.pane = NULL;
	[super dealloc];
}

static NSMutableDictionary *prefPanes = nil;

-(NSPreferencePane*)pane
{
    if (!_pane)
	{
		Class builtinPrefPaneClass = NSClassFromString(self.resourceName);
	
		if( builtinPrefPaneClass)
		{
			if( [builtinPrefPaneClass isSubclassOfClass: [NSPreferencePane class]] == NO)
				builtinPrefPaneClass = nil;
		}
        
        if( prefPanes == nil)
            prefPanes = [[NSMutableDictionary alloc] init];
        
        if( [prefPanes objectForKey: self.resourceName])
            return [prefPanes objectForKey: self.resourceName];
        
		if( builtinPrefPaneClass)
		{
			self.pane = [[[builtinPrefPaneClass alloc] initWithBundle:[NSBundle mainBundle]] autorelease];
		}
		else
		{
			NSBundle* bundle = [NSBundle bundleWithPath:[self.parentBundle pathForResource:self.resourceName ofType:@"prefPane"]];
			self.pane = [[[[bundle principalClass] alloc] initWithBundle:bundle] autorelease];
		}
        
        if( _pane)
            [prefPanes setObject: _pane forKey: self.resourceName];
	}
	
	return _pane;
}

@end


@implementation PreferencesWindowController

@synthesize animations, authView;

static const NSMutableArray* pluginPanes = [[NSMutableArray alloc] init];

+ (PreferencesWindowController*) sharedPreferencesWindowController
{
    PreferencesWindowController* prefsController = NULL;
    
    for (NSWindow* window in [NSApp windows])
        if ([window.windowController isKindOfClass:[PreferencesWindowController class]]) {
            prefsController = window.windowController;
            break;
        }
    
    if (!prefsController)
        prefsController = [[PreferencesWindowController alloc] init];
    
    return prefsController;
}


-(id)init
{
//	AuthorizationRef authRef = nil;
//	OSStatus err = AuthorizationCreate(NULL, NULL, 0, &authRef);
//    if( authRef)
//    {
//        if (err == noErr)
//        {
//            char* rightName = (char*)"BUNDLE_IDENTIFIER.preferences.allowalways";
//            if (AuthorizationRightGet(rightName, NULL) == errAuthorizationDenied)
//            {
//                if ((err = AuthorizationRightSet(authRef, rightName, CFSTR(kAuthorizationRuleClassAllow), CFSTR("You are always authorized."), NULL, NULL)) != noErr)
//                {
//                    #ifndef NDEBUG
//                    NSLog(@"Could not create default right (error %d)", (int) err);
//                    #endif
//                }
//            }
//        }
//        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
//	}
    
	self = [super initWithWindowNibName:@"PreferencesWindow"];
	animations = [[NSMutableArray alloc] init];
    
    [self.window setDelegate: self];
    
	return self;
}


-(void)addPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image toGroupWithName:(NSString*)groupName
{
	Class builtinPrefPaneClass = NSClassFromString(resourceName);
	
	if( builtinPrefPaneClass)
	{
		if( [builtinPrefPaneClass isSubclassOfClass: [NSPreferencePane class]] == NO)
			builtinPrefPaneClass = nil;
	}
	
	if (![parentBundle pathForResource:resourceName ofType:@"prefPane"] && !builtinPrefPaneClass) {
		#ifndef OSIRIX_LIGHT
		NSLog(@"Warning: preferences pane %@ not added because resource %@ not found in %@", title, resourceName, [parentBundle resourcePath]);
		#endif
		return;
	}
	
	PreferencesWindowContext* context = [[PreferencesWindowContext alloc] initWithTitle:title withResourceNamed:resourceName inBundle:parentBundle];
	[panesListView addItemWithTitle:title image:image toGroupWithName:groupName context:context];
    [context release];
}


+ (void) addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image
{
	if (!image)
    {
        image = [NSImage imageNamed:@"horosplugin"];
        
        if ([resourceName rangeOfString:@"osirixplugin" options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            image = [NSImage imageNamed:@"horosplugin"];
        }
        else
        {
            image = [NSImage imageNamed:@"osirixplugin"];
        }
    }
    
	[pluginPanes addObject:[NSArray arrayWithObjects:resourceName, parentBundle, title, image, NULL]];
}


+(void) removePluginPaneWithBundle:(NSBundle*)parentBundle
{
    for( NSArray *pluginPane in pluginPanes)
    {
        if( [pluginPane objectAtIndex: 1] == parentBundle)
        {
            [pluginPane retain];
            
            [pluginPanes removeObject: pluginPane];
            return;
        }
    }
}


-(void)view:(NSView*)view recursiveBindEnableToObject:(id)obj withKeyPath:(NSString*)keyPath {
	if ([view isKindOfClass:[NSControl class]]) {
		NSUInteger bki = 0;
		NSString* bk = NULL;
		BOOL doBind = YES;
		
		while (doBind) {
			++bki;
			bk = [NSString stringWithFormat:@"enabled%@", bki==1? @"" : [NSString stringWithFormat:@"%d", (int) bki]];
	
			NSDictionary* b = [view infoForBinding:bk];
			if (!b) break;
			
			if ([b objectForKey:NSObservedObjectKey] == obj && [[b objectForKey:NSObservedKeyPathKey] isEqualToString:keyPath])
				doBind = NO; // already bound
		}
		
		if (doBind)
			@try {
				[view bind:bk toObject:obj withKeyPath:keyPath options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSConditionallySetsEnabledBindingOption]];
				return;
			} @catch (NSException* e) {
				NSLog(@"Warning: %@", e.description);
			}
	}
	
	for (NSView* subview in view.subviews)
		[self view:subview recursiveBindEnableToObject:obj withKeyPath:keyPath];
}


-(void)view:(NSView*)view recursiveUnBindEnableFromObject:(id)obj withKeyPath:(NSString*)keyPath {
	if ([view isKindOfClass:[NSControl class]]) {
		NSUInteger bki = 0;
		NSString* bk = NULL;
		BOOL unbind = NO;
		
		while (!unbind) {
			++bki;
			bk = [NSString stringWithFormat:@"enabled%@", bki==1? @"" : [NSString stringWithFormat:@"%d", (int) bki]];
			
			NSDictionary* b = [view infoForBinding:bk];
			if (!b) break;
			
			if ([b objectForKey:NSObservedObjectKey] == obj && [[b objectForKey:NSObservedKeyPathKey] isEqualToString:keyPath])
				unbind = YES;
		}
		
		if (unbind)
			[view unbind:bk];
		return;
	}
	
	for (NSView* subview in view.subviews)
		[self view:subview recursiveUnBindEnableFromObject:obj withKeyPath:keyPath];
}


-(void)pane:(NSPreferencePane*)pane enable:(BOOL)enable
{
	[self willChangeValueForKey:@"isUnlocked"];
	
	[authButton setImage:[NSImage imageNamed: enable? @"NSLockUnlockedTemplate" : @"NSLockLockedTemplate" ]];
	
	[self didChangeValueForKey:@"isUnlocked"];

//	[self view:pane.mainView recursiveEnable:enable];
	
	if ([pane respondsToSelector:@selector(enableControls:)])
    {
        // retro-compatibility with old preference bundles
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[[pane class] instanceMethodSignatureForSelector:@selector(enableControls:)]];
		[inv setSelector:@selector(enableControls:)];
		[inv setArgument:&enable atIndex:2];
		[inv invokeWithTarget:pane];
	}

}



-(void)authorizationViewDidAuthorize:(SFAuthorizationView*)view
{
    [self pane:currentContext.pane enable:YES];
}


-(void)authorizationViewDidDeauthorize:(SFAuthorizationView*)view
{
    [self pane:currentContext.pane enable:NO];
}

-(BOOL)isUnlocked
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"] || ([authView authorizationState] == SFAuthorizationViewUnlockedState);
}


-(IBAction)authAction:(id)sender
{
    [self->authView buttonPressed:sender];
}


-(void)awakeFromNib
{
	[authView setDelegate:self];

    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[authView setString:"BUNDLE_IDENTIFIER.preferences.database"];
	}
	else
	{
		[authView setString:"BUNDLE_IDENTIFIER.preferences.allowalways"];
		[authView setEnabled:NO];
	}
	
    [authView updateStatus:self];
	
	
    
    NSRect mainScreenFrame = [[NSScreen mainScreen] visibleFrame];
	[[self window] setFrameTopLeftPoint:NSMakePoint(mainScreenFrame.origin.x, mainScreenFrame.origin.y+mainScreenFrame.size.height)];
	
	[panesListView retain];
	[panesListView setButtonActionTarget:self];
	[panesListView setButtonActionSelector:@selector(setCurrentContext:)];
	
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* name;
	
	name = NSLocalizedString(@"Basics", @"Section in preferences window");
	[self addPaneWithResourceNamed:@"OSIGeneralPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"General", @"Panel in preferences window") image:[NSImage imageNamed:@"GeneralPreferences"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIDatabasePreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Database", @"Panel in preferences window") image:[NSImage imageNamed:@"DatabaseIcon"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSICDPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"CD/DVD", @"Panel in preferences window") image:[NSImage imageNamed:@"CD"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIHangingPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Protocols", @"Panel in preferences window") image:[NSImage imageNamed:@"ZoomToFit"] toGroupWithName:name];
    [self addPaneWithResourceNamed:@"OSIHotKeysPref" inBundle:bundle withTitle:NSLocalizedString(@"Hot Keys", @"Panel in preferences window") image:[NSImage imageNamed:@"key"] toGroupWithName:name];
	
    name = NSLocalizedString(@"Display", @"Section in preferences window");
	[self addPaneWithResourceNamed:@"OSIViewerPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Viewers", @"Panel in preferences window") image:[NSImage imageNamed:@"AxialSmall"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSI3DPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"3D", @"Panel in preferences window") image:[NSImage imageNamed:@"VolumeRendering"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIPETPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"PET", @"Panel in preferences window") image:[NSImage imageNamed:@"SUV"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSICustomImageAnnotations" inBundle:bundle withTitle:NSLocalizedString(@"Annotations", @"Panel in preferences window") image:[NSImage imageNamed:@"CustomImageAnnotations"] toGroupWithName:name];
    [self addPaneWithResourceNamed:@"AYDicomPrintPref" inBundle:bundle withTitle:NSLocalizedString(@"DICOM Print", @"Panel in preferences window") image:[NSImage imageNamed:@"Print"] toGroupWithName:name];
	
    name = NSLocalizedString(@"Sharing", @"Section in preferences window");
	[self addPaneWithResourceNamed:@"OSIListenerPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Listener", @"Panel in preferences window") image:[NSImage imageNamed:@"Network"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSILocationsPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Locations", @"Panel in preferences window") image:[NSImage imageNamed:@"AccountPreferences"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIAutoroutingPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Routing", @"Panel in preferences window") image:[NSImage imageNamed:@"route"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIWebSharingPreferencePanePref" inBundle:bundle withTitle:NSLocalizedString(@"Web Server", @"Panel in preferences window") image:[NSImage imageNamed:@"Safari"] toGroupWithName:name];
    [self addPaneWithResourceNamed:@"OSIPACSOnDemandPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"On-Demand", @"Panel in preferences window") image:[NSImage imageNamed:@"Cloud"] toGroupWithName:name];
	
	for (NSArray* pluginPane in pluginPanes)
		[self addPaneWithResourceNamed:[pluginPane objectAtIndex:0]
                              inBundle:[pluginPane objectAtIndex:1]
                             withTitle:[pluginPane objectAtIndex:2]
                                 image:[pluginPane objectAtIndex:3]
                       toGroupWithName:NSLocalizedString(@"Plugins", @"Title of Plugins section in preferences window")];
	
    NSSize initialSize = [panesListView frame].size;
    
    [[self window] setContentView:panesListView];
    
    [self synchronizeSizeWithContent:initialSize];
    
    // If we need to remove a plugin with a custom pref pane
    for (NSWindow* window in [NSApp windows])
    {
        if ([window.windowController isKindOfClass:[PluginManagerController class]])
            [window close];
    }
}


-(void)windowDidLoad
{
	[self showAllAction:NULL];
}


-(BOOL)windowShouldClose:(id)sender
{
	if (currentContext && [currentContext.pane shouldUnselect] == NSUnselectCancel)
		return NO;
    
	return YES;
}


-(void)windowWillClose:(NSNotification *)notification
{
    [self setCurrentContext:NULL];
    
	[[self window] setAcceptsMouseMovedEvents: NO];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)setCurrentContextWithResourceName: (NSString*) name
{
    NSInteger panesCount = [panesListView itemsCount];
	
    for( NSInteger index = 0; index < panesCount; index++)
    {
        if( [[[panesListView contextForItemAtIndex: index] resourceName] isEqualToString: name])
            [self setCurrentContext:[panesListView contextForItemAtIndex:index]];
    }
}


-(void)setCurrentContext:(PreferencesWindowContext*)context
{
	if (context == currentContext)
		return;
	
	if (!currentContext || [currentContext.pane shouldUnselect])
    {
        [self willChangeValueForKey:@"currentContext"];
        
        [self.window setContentView:[[[NSView alloc] initWithFrame:NSZeroRect] autorelease]];
        
        // TODO: NSUnselectNow or NSUnselectLater?
		if (context && !context.pane.mainView)
        {
			@try
            {
				[context.pane loadMainView];
			}
            @catch (NSException* e)
            {
				NSLog(@"Warning: %@", e.description);
				return;
			}
		}
		
        // remove old view
		[currentContext.pane willUnselect];
        [currentContext.pane.mainView.window makeFirstResponder:nil];
        
        if (currentContext) {
            [self view:currentContext.pane.mainView recursiveUnBindEnableFromObject:self withKeyPath:@"isUnlocked"];
        }
        
        // add new view

        NSString* title = NSLocalizedString(@"Horos Preferences", NULL);
        NSSize newSize;

        if (!context) {
            newSize = panesListView.frame.size;
            [self.window setContentView:panesListView];
        } else {
            NSView *cview = context.pane.mainView;
            title = [title stringByAppendingFormat:@"%@%@", NSLocalizedString(@": ", @"Semicolon with space prefix and suffix (example: english ': ', french ' : ')"), context.title];

            [context.pane willSelect];

            [self view:cview recursiveBindEnableToObject:self withKeyPath:@"isUnlocked"];
            
            NSView *fview = [[[PreferencesFlippedView alloc] initWithFrame:cview.frame] autorelease];
            fview.translatesAutoresizingMaskIntoConstraints = NO;
            [fview addSubview:cview];
            [fview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[cview]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(cview)]];
            [fview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cview]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(cview)]];
            
            NSScrollView *sv = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, fview.fittingSize.width, fview.fittingSize.height)];
            sv.documentView = fview;
            
            sv.hasHorizontalScroller = NO;
            sv.borderType = NSNoBorder;
            sv.backgroundColor = [NSColor colorWithCalibratedWhite:237./255 alpha:1];
            sv.drawsBackground = YES;
            sv.horizontalScrollElasticity = NSScrollElasticityNone;
            sv.verticalScrollElasticity = NSScrollElasticityNone;

            [self.window setContentView:sv];
//            [sv.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[sv]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sv)]];
//            [sv.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sv]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(sv)]];
            
            newSize = fview.fittingSize;
        }
		
        [self.window setTitle:title];
        
        [currentContext.pane didUnselect];
        currentContext = context;
        [context.pane didSelect];
        
        [self synchronizeSizeWithContent:newSize];
        
        [self didChangeValueForKey:@"currentContext"];
		
//		[oldview release];
	}

}


-(void)dealloc
{
	[self setCurrentContext:NULL];
	[panesListView release];
	[animations release];
	[super dealloc];
}


- (CGFloat)toolbarHeight
{
    NSToolbar *toolbar = [[self window] toolbar];
    CGFloat toolbarHeight = 0.0;
    NSRect windowFrame;
    
    if (toolbar && [toolbar isVisible])
    {
        windowFrame = [[[self window ] class] contentRectForFrameRect:[[self window] frame]
                                                  styleMask:[[self window] styleMask]];
        
        toolbarHeight = NSHeight(windowFrame) - NSHeight([[[self window] contentView] frame]);
    }
    
    return toolbarHeight;
}


- (void)synchronizeSizeWithContent:(NSSize)newContentSize
{
    NSSize newSize = [[self.window class] frameRectForContentRect:NSMakeRect(0, 0, newContentSize.width, newContentSize.height+self.window.toolbarHeight) styleMask:self.window.styleMask].size;
    
    CGFloat maxHeight = self.window.screen.visibleFrame.size.height;
    if (newSize.height > maxHeight)
        newSize.height = maxHeight;

    NSRect frame = [self.window frame];
    
    NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y+(frame.size.height-newSize.height), newSize.width, newSize.height);
    
    [self.window setFrame:newFrame display:YES animate:YES];
}


-(IBAction)navigationAction:(id)sender
{
	NSInteger index = -1;
	if (currentContext)
		index = [panesListView indexOfItemWithContext:currentContext];
	
	switch ([sender selectedSegment])
    {
		case 0:	--index; break;
		case 1: ++index; break;
	}
	
	NSInteger panesCount = [panesListView itemsCount];
	if (index < 0) index = panesCount-1;
	if (index >= panesCount) index = 0;
	
	[self setCurrentContext:[panesListView contextForItemAtIndex:index]];
}


-(IBAction)showAllAction:(id)sender
{
	[self setCurrentContext:NULL];
}


// ------


-(void)reopenDatabase
{
	[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
	[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
	[[BrowserController currentBrowser] resetToLocalDatabase];
}

@end

@implementation PreferencesFlippedView

- (BOOL)isFlipped {
    return YES;
}

@end
