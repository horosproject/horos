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

#import "QueryController.h"

#include <Security/Security.h>

static OSStatus SetupRight(
    AuthorizationRef    authRef, 
    const char *        rightName, 
    CFStringRef         rightRule, 
    CFStringRef         rightPrompt
)
{
    OSStatus err;
	
    err = AuthorizationRightGet(rightName, NULL);
    if (err == noErr)
	{
	
    }
	else if (err == errAuthorizationDenied)
	{
        err = AuthorizationRightSet(
            authRef,                // authRef
            rightName,              // rightName
            rightRule,              // rightDefinition
            rightPrompt,            // descriptionKey
            NULL,                   // bundle, NULL indicates main
            NULL                    // localeTableName, 
        );                          // NULL indicates
                                    // "Localizable.strings"
		
        if (err != noErr) {
            #if ! defined(NDEBUG)
                fprintf(
                    stderr, 
                    "Could not create default right (%d)\n", 
                    (int) err
                );
            #endif
            err = noErr;
        }
    }

    return err;
}

extern OSStatus SetupAuthorization(void)
{
    OSStatus err;
	AuthorizationRef gAuthorization;
	
    // Connect to Authorization Services.

    err = AuthorizationCreate(NULL, NULL, 0, &gAuthorization);

    // Set up our rights.
	
    if (err == noErr)
	{
        err = SetupRight(
            gAuthorization, 
            "com.rossetantoine.osirix.preferences.allowalways", 
            CFSTR(kAuthorizationRuleClassAllow), 
            CFSTR("You are always authorized.")
        );
    }
    return err;
}

#import "PreferencePaneController.h"
#import "AppController.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "DCMView.h"

#define DATAFILEPATH @"/Database.dat"

@implementation PreferencePaneController

-(id) init
{
	SetupAuthorization();

    if (self = [super initWithWindowNibName:@"PreferencePanesViewer"])
	{
	}
	return self;
}

- (void) awakeFromNib
{
	[[self window] setFrameTopLeftPoint: NSMakePoint( [[NSScreen mainScreen] visibleFrame].origin.x, [[NSScreen mainScreen] visibleFrame].origin.y+[[NSScreen mainScreen] visibleFrame].size.height)];
}

- (BOOL)windowShouldClose:(id)sender
{
	if(pane)
	{
		NSPreferencePaneUnselectReply shouldUnselect = [pane shouldUnselect];
		if(shouldUnselect==NSUnselectCancel) return NO;
	}
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[pane willUnselect];
	[[pane mainView] removeFromSuperview];
	[pane didUnselect];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	//[pane release];
	[self release];
}

- (void) reopenDatabase
{
	[[NSUserDefaults standardUserDefaults] setInteger: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULT_DATABASELOCATION"] forKey: @"DATABASELOCATION"];
	[[NSUserDefaults standardUserDefaults] setObject: [[NSUserDefaults standardUserDefaults] stringForKey: @"DEFAULT_DATABASELOCATIONURL"] forKey: @"DATABASELOCATIONURL"];
	
	[[BrowserController currentBrowser] resetToLocalDatabase];
}

- (void) windowDidLoad
{
	[[self window] setDelegate:self];
	[self showAll:nil];
}

- (void) dealloc
{
	NSLog(@"PreferencePaneController released !");
	[pane shouldUnselect];
	[pane willUnselect];
	[[pane mainView] removeFromSuperview];
	[pane didUnselect];
	[pane release];
	[bundles release];
	[super dealloc];
}

//Pane management
- (void) setPane: (NSPreferencePane *) aPane
{
	if ([aPane loadMainView] ) {
		//NSLog(@"load Main View");
		if ([pane shouldUnselect] || !pane) {
			NSLog(@"pane added");
			
			[aPane willSelect];
			/* Add view to window */
			float y, x, newX, newY, deltaH, deltaW;
			NSRect frameRect = [[self window] frame];
			NSRect contentFrame = [[self window] contentRectForFrameRect:frameRect];
			NSRect newRect = NSMakeRect(contentFrame.origin.x, contentFrame.origin.y, [[aPane mainView] frame].size.width, [[aPane mainView] frame].size.height + 30);
			NSRect newWindowFrame = [[self window] frameRectForContentRect:newRect];
			y = frameRect.origin.y;
			deltaH = newWindowFrame.size.height - frameRect.size.height;
			newY = y - deltaH;
			newWindowFrame.origin.y = newY;
			
			/*
			NSLog(@"pane origin x:%f  y:%f   width:%f height %f", [[aPane mainView] frame].origin.x, [[aPane mainView] frame].origin.y, [[aPane mainView] frame].size.width,[[aPane mainView] frame].size.height);
			NSLog(@"old origin x:%f  y:%f   width:%f height %f", frameRect.origin.x, frameRect.origin.y, frameRect.size.width,frameRect.size.height);
			NSLog(@"new origin x:%f  y:%f   width:%f height %f",  newWindowFrame.origin.x,  newWindowFrame.origin.y,  newWindowFrame.size.width, newWindowFrame.size.height);
			*/
			[pane willUnselect];
			[[pane mainView] removeFromSuperview];
			[allView removeFromSuperview];
			
		//	[[[self window] contentView] addSubview:[aPane mainView]];

			[[aPane mainView] setAutoresizesSubviews: YES];
			[[aPane mainView] setAutoresizingMask: NSViewWidthSizable + NSViewHeightSizable];
			
			[[self window] setContentMinSize: newRect.size];
			[AppController resizeWindowWithAnimation: [self window] newSize: newWindowFrame];
			
			
			[destView addSubview:[aPane mainView]];
			[aPane didSelect];
			[pane didUnselect];
			[[aPane mainView] setNeedsDisplay:YES];
			[pane release];
			pane = [aPane retain];
			
			[[self window] setContentMinSize: NSMakeSize(0 , 0)];
			
//			NSRect	finalFrame = [[self window] frame];
//			
//			if( [[NSScreen mainScreen] visibleFrame].size.height <= finalFrame.size.height)
//			{
//				long diff= finalFrame.size.height - [[NSScreen mainScreen] visibleFrame].size.height;
//				
//				finalFrame.size.height -= diff;
//				finalFrame.origin.y += diff;
//				
//				[[self window] setFrame:finalFrame display:YES animate:NO];
//				
//				if( [[[[aPane mainView] subviews] objectAtIndex: 0] isKindOfClass: [NSScrollView class]])
//				{
//					NSScrollView	*scrollView = [[[aPane mainView] subviews] objectAtIndex: 0];
//					[[scrollView contentView] scrollToPoint:NSMakePoint(0, [[[scrollView contentView] documentView] frame].size.height - [[scrollView contentView] documentVisibleRect].size.height) ];
//					[scrollView reflectScrolledClipView: [scrollView contentView]];
//				}
//			}
		}
	}

//	showRestartNeeded = YES;
}

- (NSPreferencePane *)pane{
	return pane;
}

- (IBAction)nextAndPrevPane:(id)sender
{
	if( curPaneIndex == -1) curPaneIndex = 0;
	else
	{
		switch ([sender selectedSegment])
		{
			case 0:	// Previous
					curPaneIndex--;
			break;
			
			case 1: // Next
					curPaneIndex++;
			break;
		}
	}
	
	if( curPaneIndex < 0) curPaneIndex = 12;
	if( curPaneIndex > 12) curPaneIndex = 0;
	
	[self selectPaneIndex: curPaneIndex];
}

- (void)selectPaneIndex:(int) index
{
	curPaneIndex = index;
	
	NSString *pathToPrefPaneBundle;
	NSBundle *prefBundle;
	Class prefPaneClass;
	
	switch ( index) {
		case 0:
		default:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIGeneralPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"General", nil)];
			break;
		case 4:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIViewerPreferencePane" ofType: @"prefPane"];	
			[[self window] setTitle: NSLocalizedString( @"Viewers", nil)];
			break;
		case 2:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSICDPreferencePane" ofType: @"prefPane"];	
			[[self window] setTitle: NSLocalizedString( @"CD/DVD", nil)];
			break;
		case 1:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIDatabasePreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Database", nil)];
			break;
		case 9:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIListenerPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Listener", nil)];
			break;
		case 10:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSILocationsPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Locations", nil)];
			break;
		case 12:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"AYDicomPrint" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"DICOM Print", nil)];
			break;
		case 3:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIHangingPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Protocols", nil)];	
			break;
		case 5:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSI3DPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"3D", nil)];
			break;
		case 6:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIPETPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"PET", nil)];
			break;
		case 11:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIAutoroutingPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Routing", nil)];
			break;
		case 7:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIHotKeys" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Hot Keys", nil)];
			break;
		case 8:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSICustomImageAnnotations" ofType: @"prefPane"];
			[[self window] setTitle: NSLocalizedString( @"Annotations", nil)];
			break;

	}
	[[self window] setRepresentedFilename: pathToPrefPaneBundle];
	
	if( bundles == nil) bundles = [[NSMutableDictionary dictionary] retain];
	
	if( [bundles objectForKey: pathToPrefPaneBundle] == nil)
	{
		prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
		[bundles setObject: prefBundle forKey: pathToPrefPaneBundle];
	}
	
	prefBundle = [bundles objectForKey: pathToPrefPaneBundle];
	
	prefPaneClass = [prefBundle principalClass];
	NSPreferencePane *aPane = [[[prefPaneClass alloc] initWithBundle:prefBundle] autorelease];
	[self setPane:aPane];
}

- (IBAction)selectPane:(id)sender
{
	[self selectPaneIndex: [[sender selectedCell] tag]];
}

- (IBAction)showAll:(id)sender
{			
	/* Add view to window */
	float y, newY, deltaH;
	NSRect frameRect = [[self window] frame];
	NSRect contentFrame = [[self window] contentRectForFrameRect:frameRect];
	NSRect newRect = NSMakeRect(contentFrame.origin.x, contentFrame.origin.y, [allView frame].size.width, [allView frame].size.height + 30.0);
	NSRect newWindowFrame = [[self window] frameRectForContentRect:newRect];
	y = frameRect.origin.y;
	deltaH = newWindowFrame.size.height - frameRect.size.height;
	newY = y - deltaH;
	newWindowFrame.origin.y = newY;
	
	NSPreferencePaneUnselectReply shouldUnselect = [pane shouldUnselect];
	if(shouldUnselect==NSUnselectCancel && sender!=nil) return; // we need to test the sender, because shawAll: is needed for initialization (with sender=nil)
	
	[[pane mainView] removeFromSuperview];
	
	[[self window] setContentMinSize: newRect.size];
	
	[AppController resizeWindowWithAnimation: [self window] newSize: newWindowFrame];

	[destView addSubview:allView];
	[allView setNeedsDisplay:YES];

	[pane willUnselect];
	[pane didUnselect];

	[pane release];
	pane = nil;
	
	
	
	[[self window] setContentMinSize: NSMakeSize(0 , 0)];
	
	NSRect	finalFrame = [[self window] frame];
	
	[[self window] setTitle:NSLocalizedString( @"Preferences", nil)];
	[[self window] setRepresentedFilename: @""];
	
//	if( [[NSScreen mainScreen] visibleFrame].size.height <= finalFrame.size.height)
//	{
//		long diff= finalFrame.size.height - [[NSScreen mainScreen] visibleFrame].size.height;
//		
//		finalFrame.size.height -= diff;
//		finalFrame.origin.y += diff;
//		
//		[[self window] setFrame:finalFrame display:YES animate:NO];
//		
//		if( [[[allView subviews] objectAtIndex: 0] isKindOfClass: [NSScrollView class]])
//		{
//			NSScrollView	*scrollView = [[allView subviews] objectAtIndex: 0];
//			[[scrollView contentView] scrollToPoint:NSMakePoint(0, [[[scrollView contentView] documentView] frame].size.height - [[scrollView contentView] documentVisibleRect].size.height) ];
//			[scrollView reflectScrolledClipView: [scrollView contentView]];
//		}
//	}
	
	curPaneIndex = -1;
}

//TableViews Data source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	return nil;
}
@end
