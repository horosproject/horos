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
#import "SFAuthorizationView+OsiriX.h"
#import "AppController.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "DCMView.h"
#import <Foundation/NSObjCRuntime.h>
#include <algorithm>

//static NSMutableDictionary *paneBundles = nil;

//#define DATAFILEPATH @"/Database.dat"


@interface PreferencesWindowContext : NSObject {
	NSString* _title;
	NSBundle* _parentBundle;
	NSString* _resourceName;
	NSPreferencePane* _pane;
}

@property(retain) NSString* title;
@property(retain) NSBundle* parentBundle;
@property(retain) NSString* resourceName;
@property(retain) NSPreferencePane* pane;

-(id)initWithTitle:(NSString*)title withResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle;

@end
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

-(NSPreferencePane*)pane {
	if (!_pane) {
		NSBundle* bundle = [NSBundle bundleWithPath:[self.parentBundle pathForResource:self.resourceName ofType:@"prefPane"]];
		self.pane = [[[[bundle principalClass] alloc] initWithBundle:bundle] autorelease];
		// NSLog(@"Preference pane %@ bundle loaded", title);
	}
	
	return _pane;
}

@end


@implementation PreferencesWindowController

@synthesize animations, authView;

static const NSMutableArray* pluginPanes = [[NSMutableArray alloc] init];

-(id)init {
	AuthorizationRef authRef;
	OSStatus err = AuthorizationCreate(NULL, NULL, 0, &authRef);
	if (err == noErr) {
		char* rightName = (char*)"com.rossetantoine.osirix.preferences.allowalways";
		if (AuthorizationRightGet(rightName, NULL) == errAuthorizationDenied)
			if ((err = AuthorizationRightSet(authRef, rightName, CFSTR(kAuthorizationRuleClassAllow), CFSTR("You are always authorized."), NULL, NULL)) != noErr) {
				#ifndef NDEBUG
				NSLog(@"Could not create default right (error %d)", err);
				#endif
			}
	}
	AuthorizationFree(authRef, kAuthorizationFlagDefaults);
	
	self = [super initWithWindowNibName:@"PreferencesWindow"];
	animations = [[NSMutableArray alloc] init];
	return self;
}

-(void)addPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image toGroupWithName:(NSString*)groupName {
	if (![parentBundle pathForResource:resourceName ofType:@"prefPane"]) {
		#ifndef OSIRIX_LIGHT
		NSLog(@"Warning: preferences pane %@ not added because resource %@ not found in %@", title, resourceName, [parentBundle resourcePath]);
		#endif
		return;
	}
	
	PreferencesWindowContext* context = [[[PreferencesWindowContext alloc] initWithTitle:title withResourceNamed:resourceName inBundle:parentBundle] autorelease];
	[panesListView addItemWithTitle:title image:image toGroupWithName:groupName context:context];
}

+(void)addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image {
	if (!image)
		image = [NSImage imageNamed:@"osirixplugin"];
	[pluginPanes addObject:[NSArray arrayWithObjects:resourceName, parentBundle, title, image, NULL]];
}

-(void)view:(NSView*)view recursiveEnable:(BOOL)enable {
	if ([view isKindOfClass:[NSControl class]])
		[(NSControl*)view setEnabled:enable];
	else for (NSView* subview in view.subviews)
		[self view:subview recursiveEnable:enable];
}

-(void)pane:(NSPreferencePane*)pane enable:(BOOL)enable {
	[authButton setImage:[NSImage imageNamed: enable? @"NSLockUnlockedTemplate" : @"NSLockLockedTemplate" ]];
	
	[self view:pane.mainView recursiveEnable:enable];
	
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
	[[self window] setDelegate:self];
	
	[panesListView retain];
	[panesListView setButtonActionTarget:self];
	[panesListView setButtonActionSelector:@selector(setCurrentContext:)];
	
	[scrollView setBackgroundColor:[NSColor colorWithCalibratedWhite:237./255 alpha:1]];
	[scrollView setDrawsBackground:YES];
	
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* name;
	
	name = NSLocalizedString(@"Basics", @"Title of Basic section in preferences window");
	[self addPaneWithResourceNamed:@"OSIGeneralPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"General", NULL) image:[NSImage imageNamed:@"GeneralPreferences"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIDatabasePreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Database", NULL) image:[NSImage imageNamed:@"StartupDisk"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSICDPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"CD/DVD", NULL) image:[NSImage imageNamed:@"CD"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIHangingPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Protocols", NULL) image:[NSImage imageNamed:@"ZoomToFit"] toGroupWithName:name];
	name = NSLocalizedString(@"Display", @"Title of Display section in preferences window");
	[self addPaneWithResourceNamed:@"OSIViewerPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Viewers", NULL) image:[NSImage imageNamed:@"MPR3D"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSI3DPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"3D", NULL) image:[NSImage imageNamed:@"VolumeRendering"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIPETPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"PET", NULL) image:[NSImage imageNamed:@"SUV"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIHotKeys" inBundle:bundle withTitle:NSLocalizedString(@"Hot Keys", NULL) image:[NSImage imageNamed:@"key"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSICustomImageAnnotations" inBundle:bundle withTitle:NSLocalizedString(@"Annotations", NULL) image:[NSImage imageNamed:@"CustomImageAnnotations"] toGroupWithName:name];
	name = NSLocalizedString(@"Sharing", @"Title of Sharing section in preferences window");
	[self addPaneWithResourceNamed:@"OSIListenerPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Listener", NULL) image:[NSImage imageNamed:@"Network"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSILocationsPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Locations", NULL) image:[NSImage imageNamed:@"AccountPreferences"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIAutoroutingPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Routing", NULL) image:[NSImage imageNamed:@"route"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"AYDicomPrint" inBundle:bundle withTitle:NSLocalizedString(@"DICOM Print", NULL) image:[NSImage imageNamed:@"SmallPrinter"] toGroupWithName:name];
	[self addPaneWithResourceNamed:@"OSIWebSharingPreferencePane" inBundle:bundle withTitle:NSLocalizedString(@"Web Server", NULL) image:[NSImage imageNamed:@"Safari"] toGroupWithName:name];
	
	for (NSArray* pluginPane in pluginPanes)
		[self addPaneWithResourceNamed:[pluginPane objectAtIndex:0] inBundle:[pluginPane objectAtIndex:1] withTitle:[pluginPane objectAtIndex:2] image:[pluginPane objectAtIndex:3] toGroupWithName:NSLocalizedString(@"Plugins", @"Title of Plugins section in preferences window")];
	
	[self synchronizeSizeWithContent];
}

-(void)windowDidLoad {
	[self showAllAction:NULL];
}

-(BOOL)windowShouldClose:(id)sender {
	if (currentContext && [currentContext.pane shouldUnselect] == NSUnselectCancel)
		return NO;
	return YES;
}

-(void)windowWillClose:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self release];
}

-(void)setCurrentContext:(PreferencesWindowContext*)context {
	if (context == currentContext)
		return;
	
	if (!currentContext || [currentContext.pane shouldUnselect]) { // TODO: NSUnselectNow or NSUnselectLater?
		[self willChangeValueForKey:@"currentContext"];

		[context.pane loadMainView];
		[self pane:context.pane enable: [authView authorizationState] == SFAuthorizationViewUnlockedState];
		
		[animations removeAllObjects];
		
		// remove old view
		
		[currentContext.pane willUnselect];
		NSView* oldview = currentContext? currentContext.pane.mainView : panesListView;
		[oldview retain];
		[oldview removeFromSuperview];

		// add new view
		
		NSView* view = context? context.pane.mainView : panesListView;
		NSString* title = context? context.title : NSLocalizedString(@"OsiriX Preferences", NULL);
		
		[self.window setTitle:title];

		[context.pane willSelect];
		[scrollView setDocumentView:view];
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

-(void)synchronizeSizeWithContent {
	NSRect paneFrame = [[scrollView documentView] frame];
	NSRect frame = [self.window frame];
	NSRect sizeframe = [self.window frameRectForContentRect:paneFrame];
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
	
//	frame.size.height += 15;
//	frame.size.width += 15;
	
	[scrollView setHasHorizontalScroller: NO];
	[scrollView setHasVerticalScroller: NO];
	
	[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						       self.window, NSViewAnimationTargetKey,
						       [NSValue valueWithRect:frame], NSViewAnimationEndFrameKey,
						   NULL]];
	
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
	windowMaxSize.height -= self.window.toolbarHeight;
	self.window.maxSize = windowMaxSize;
	
	[scrollView setHasHorizontalScroller:YES];
	[scrollView setHasVerticalScroller:YES];
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

@implementation NSWindowController (OsiriX)

-(void)synchronizeSizeWithContent {
}

@end

