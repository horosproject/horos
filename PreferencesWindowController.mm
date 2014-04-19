/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "QueryController.h"
#import "PreferencesView.h"
#import "N2Debug.h"
#import "NSWindow+N2.h"
#import <Security/Security.h>
#import "PreferencesWindowController.h"
#import "N2AdaptiveBox.h"
#import "SFAuthorizationView+OsiriX.h"
#import "AppController.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "DCMView.h"
#import "PluginManagerController.h"
#import <Foundation/NSObjCRuntime.h>
#include <algorithm>

//static NSMutableDictionary *paneBundles = nil;

//#define DATAFILEPATH @"/Database.dat"

@implementation PreferencesWindowContext

@synthesize title = _title, parentBundle = _parentBundle, resourceName = _resourceName, pane = _pane;

-(id)initWithTitle:(NSString*)title withResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle {
	self = [super init];
	
	self.title = title;
	self.parentBundle = parentBundle;
	self.resourceName = resourceName;
	
	return self;
}

-(void)dealloc {
	//NSLog(@"[PreferencesWindowContext dealloc], title %@", self.title);
	self.title = NULL;
	self.parentBundle = NULL;
	self.resourceName = NULL;
	self.pane = NULL;
	[super dealloc];
}

static NSMutableDictionary *prefPanes = nil;

-(NSPreferencePane*)pane {
	if (!_pane)
	{
		Class builtinPrefPaneClass = NSClassFromString( self.resourceName);
	
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
			self.pane = [[[builtinPrefPaneClass alloc] initWithBundle: nil] autorelease];
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
//            char* rightName = (char*)"com.rossetantoine.osirix.preferences.allowalways";
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

+(void) addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image
{
	if (!image)
		image = [NSImage imageNamed:@"osirixplugin"];
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

-(void)pane:(NSPreferencePane*)pane enable:(BOOL)enable {
	[self willChangeValueForKey:@"isUnlocked"];
	
	[authButton setImage:[NSImage imageNamed: enable? @"NSLockUnlockedTemplate" : @"NSLockLockedTemplate" ]];
	
	[self didChangeValueForKey:@"isUnlocked"];

//	[self view:pane.mainView recursiveEnable:enable];
	
	if ([pane respondsToSelector:@selector(enableControls:)]) { // retro-compatibility with old preference bundles
		NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[[pane class] instanceMethodSignatureForSelector:@selector(enableControls:)]];
		[inv setSelector:@selector(enableControls:)];
		[inv setArgument:&enable atIndex:2];
		[inv invokeWithTarget:pane];
	}

}

-(void)awakeFromNib {
	[authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[authView setString:"com.rossetantoine.osirix.preferences.database"];
	}
	else
	{
		[authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[authView setEnabled:NO];
	}
	[authView updateStatus:self];
	
	NSRect mainScreenFrame = [[NSScreen mainScreen] visibleFrame];
	[[self window] setFrameTopLeftPoint:NSMakePoint(mainScreenFrame.origin.x, mainScreenFrame.origin.y+mainScreenFrame.size.height)];
	
	[panesListView retain];
	[panesListView setButtonActionTarget:self];
	[panesListView setButtonActionSelector:@selector(setCurrentContext:)];
	
	[scrollView setBackgroundColor:[NSColor colorWithCalibratedWhite:237./255 alpha:1]];
	[scrollView setDrawsBackground:YES];
	
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
		[self addPaneWithResourceNamed:[pluginPane objectAtIndex:0] inBundle:[pluginPane objectAtIndex:1] withTitle:[pluginPane objectAtIndex:2] image:[pluginPane objectAtIndex:3] toGroupWithName:NSLocalizedString(@"Plugins", @"Title of Plugins section in preferences window")];
	
    flippedDocumentView.translatesAutoresizingMaskIntoConstraints = YES;
    panesListView.translatesAutoresizingMaskIntoConstraints = YES;
    
	[flippedDocumentView setFrameSize:panesListView.frame.size];
	[panesListView setFrameSize:flippedDocumentView.frame.size];
	
	[self synchronizeSizeWithContent];
    
    
    // If we need to remove a plugin with a custom pref pane
    for (NSWindow* window in [NSApp windows])
    {
        if ([window.windowController isKindOfClass:[PluginManagerController class]])
            [window close];
    }
}

-(void)windowDidLoad {
	[self showAllAction:NULL];
}

-(BOOL)windowShouldClose:(id)sender {
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

-(BOOL)isUnlocked {
	return ![[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"] || ([authView authorizationState] == SFAuthorizationViewUnlockedState);
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

-(void)setCurrentContext:(PreferencesWindowContext*)context {
	if (context == currentContext)
		return;
	
	if (!currentContext || [currentContext.pane shouldUnselect]) { // TODO: NSUnselectNow or NSUnselectLater?
		[self willChangeValueForKey:@"currentContext"];
		
		if (context && !context.pane.mainView) {
			@try {
				[context.pane loadMainView];
			} @catch (NSException* e) {
				NSLog(@"Warning: %@", e.description);
				return;
			}
		}
		
		//[self pane:context.pane enable: [authView authorizationState] == SFAuthorizationViewUnlockedState];
		
		[animations removeAllObjects];
		
		// remove old view
		[currentContext.pane willUnselect];
        [currentContext.pane.mainView.window makeFirstResponder: nil];
		NSView* oldview = currentContext? currentContext.pane.mainView : panesListView;
		[oldview retain];
		[oldview removeFromSuperview];

		[self view:oldview recursiveUnBindEnableFromObject:self withKeyPath:@"isUnlocked"];
		// add new view
		[self view:context.pane.mainView recursiveBindEnableToObject:self withKeyPath:@"isUnlocked"];
		
		NSView* view = context? context.pane.mainView : panesListView;
		
        NSString* title = NSLocalizedString(@"OsiriX Preferences", NULL);
        if (context)
            title = [title stringByAppendingFormat:@"%@%@", NSLocalizedString(@": ", @"Semicolon with space prefix and suffix (example: english ': ', french ' : ')"), context.title];
		[self.window setTitle:title];
		
		[context.pane willSelect];
		[flippedDocumentView setFrameSize:view.frame.size];
		[flippedDocumentView addSubview:view];
        [animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							       view, NSViewAnimationTargetKey,
							       NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
							   NULL]];
		[context.pane didSelect];

		[currentContext.pane didUnselect];
		currentContext = context;
		
		[self didChangeValueForKey:@"currentContext"];
		
		[self synchronizeSizeWithContent];
		
		[oldview release];
	}

}

-(void)dealloc {
	[self setCurrentContext:NULL];
	[panesListView release];
	[animations release];
	[super dealloc];
}

-(void)authorizationViewDidAuthorize:(SFAuthorizationView*)view {
	[self pane:currentContext.pane enable:YES];
}

-(void)authorizationViewDidDeauthorize:(SFAuthorizationView*)view {    
	[self pane:currentContext.pane enable:NO];
}

-(NSAnimation*)synchronizeSizeWithContent {
	NSRect paneFrame = [[scrollView documentView] frame];
	for (NSDictionary* animation in animations)
		if ([animation objectForKey:NSViewAnimationTargetKey] == [scrollView documentView] && [animation objectForKey:NSViewAnimationEndFrameKey])
			paneFrame = [[animation objectForKey:NSViewAnimationEndFrameKey] rectValue];
	
	NSRect initframe = [self.window frame];
	NSRect sizeframe = [self.window frameRectForContentRect:paneFrame];
	NSRect frame = initframe;
	frame.origin.y += frame.size.height-sizeframe.size.height;
	frame.size = sizeframe.size;
	
	NSRect idealFrame = frame;
	// if window doesn't fit in screen, then resize it
	NSRect screenFrame = self.window.screen.visibleFrame;
	frame.size.width = std::min(frame.size.width, screenFrame.size.width);
	if (frame.size.height > screenFrame.size.height) {
		frame.origin.y += frame.size.height-screenFrame.size.height;
		frame.size.height = screenFrame.size.height;
	}
	
	NSRect tempFrame = frame;
	// the resizing makes scrollers appear, give them space
	if (tempFrame.size.height < idealFrame.size.height)
		if (tempFrame.size.width < screenFrame.size.width)
			frame.size.width = std::min(frame.size.width+scrollView.horizontalScroller.frame.size.height, screenFrame.size.width);
	if (tempFrame.size.width < idealFrame.size.width)
		if (tempFrame.size.height < screenFrame.size.height)
			frame.size.height = std::min(frame.size.height+scrollView.verticalScroller.frame.size.width, screenFrame.size.height);
	
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setHasVerticalScroller:NO];
	
	[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						       self.window, NSViewAnimationTargetKey,
						       [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
						   NULL]];
	
	// scroll to topleft
/*	CGFloat vp = [scrollView.documentView frame].size.height-initframe.size.height;
	if (vp > 0) {
		[scrollView.contentView scrollToPoint:NSMakePoint(0, vp)];
		[scrollView reflectScrolledClipView:scrollView.contentView];
	}*/
	
	NSViewAnimation* animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
	@try {
		[animation setAnimationBlockingMode:NSAnimationBlocking];
		[animation setDuration:0.2];
		[animation setAnimationCurve:NSAnimationEaseInOut];
		[animation startAnimation];
	} @catch (...) {
	}
	
	[animation release];
	[animations removeAllObjects];
	
	NSSize windowMaxSize = idealFrame.size;
	if (tempFrame.size.height < idealFrame.size.height)
		windowMaxSize.width += scrollView.verticalScroller.frame.size.width;
	if (tempFrame.size.width < idealFrame.size.width)
		windowMaxSize.height += scrollView.horizontalScroller.frame.size.height;
	windowMaxSize.height -= self.window.toolbarHeight;
	self.window.maxSize = windowMaxSize;
	
	[scrollView setHasHorizontalScroller:YES];
	[scrollView setHasVerticalScroller:YES];
	
	return animation;
}

-(IBAction)navigationAction:(id)sender {
	NSInteger index = -1;
	if (currentContext)
		index = [panesListView indexOfItemWithContext:currentContext];
	
	switch ([sender selectedSegment]){
		case 0:	--index; break;
		case 1: ++index; break;
	}
	
	NSInteger panesCount = [panesListView itemsCount];
	if (index < 0) index = panesCount-1;
	if (index >= panesCount) index = 0;
	
	[self setCurrentContext:[panesListView contextForItemAtIndex:index]];
}

-(IBAction)showAllAction:(id)sender {
	[self setCurrentContext:NULL];
}

-(IBAction)authAction:(id)sender {
	[authView buttonPressed:NULL];
}

// ------

-(void)reopenDatabase {
	[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
	[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
	[[BrowserController currentBrowser] resetToLocalDatabase];
}

@end
