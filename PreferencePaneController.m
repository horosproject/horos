/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

/***************************************** Modifications *********************************************

Version 2.3
	20060109	LP	Fixed Infinite Loop in preferencesUpdated:
	20060110	DDP	Reducing the variable duplication of userDefault objects (work in progress).
	
*****************************************************************************************************/

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
                    "Could not create default right (%ld)\n", 
                    err
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

extern NSString * documentsDirectory();

extern AppController		*appController;
extern BrowserController	*browserWindow;

@implementation PreferencePaneController

-(id) init
{
	SetupAuthorization();

    if (self = [super initWithWindowNibName:@"PreferencePanesViewer"])
	{
		previousDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	}
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[pane shouldUnselect];
	[pane willUnselect];
	[[pane mainView] removeFromSuperview];
	[pane didUnselect];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	//[pane release];
	[self release];
}

- (void) reopenDatabase
{
	[browserWindow openDatabaseIn: [documentsDirectory() stringByAppendingString:@"/Database.sql"] Bonjour: NO];
}

- (void) preferencesUpdated: (NSNotification*) note
{
	BOOL				restartListener = NO;
	BOOL				refreshDatabase = NO;
	BOOL				refreshColumns = NO;
	BOOL				recomputePETBlending = NO;
	
	NS_DURING
	
	if ([[previousDefaults valueForKey: @"PET Blending CLUT"]		isEqualToString:	[[note object] stringForKey: @"PET Blending CLUT"]] == NO) 
	{
		recomputePETBlending = YES;
	}
	
	if( [[previousDefaults valueForKey: @"DBDateFormat"]			isEqualToString:	[[note object] stringForKey: @"DBDateFormat"]] == NO) refreshDatabase = YES;
	if( [[previousDefaults valueForKey: @"DBDateOfBirthFormat"]			isEqualToString:	[[note object] stringForKey: @"DBDateOfBirthFormat"]] == NO) refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"DICOMTimeout"]intValue]		!=		[[note object] integerForKey: @"DICOMTimeout"]) restartListener = YES;
	if ([[previousDefaults valueForKey: @"LISTENERCHECKINTERVAL"]intValue]		!=		[[note object] integerForKey: @"LISTENERCHECKINTERVAL"]) restartListener = YES;
	if ([[previousDefaults valueForKey: @"SINGLEPROCESS"]intValue]				!=		[[note object] integerForKey: @"SINGLEPROCESS"]) restartListener = YES;
	if ([[previousDefaults valueForKey: @"AETITLE"]					isEqualToString:	[[note object] stringForKey: @"AETITLE"]] == NO) restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCPEXTRA"]			isEqualToString:	[[note object] stringForKey: @"STORESCPEXTRA"]] == NO) restartListener = YES;
	if ([[previousDefaults valueForKey: @"AEPORT"]					isEqualToString:	[[note object] stringForKey: @"AEPORT"]] == NO) restartListener = YES;
	if ([[previousDefaults valueForKey: @"AETransferSyntax"]		isEqualToString:	[[note object] stringForKey: @"AETransferSyntax"]] == NO) restartListener = YES;
	if ([[previousDefaults valueForKey: @"STORESCP"] intValue]					!=		[[note object] integerForKey: @"STORESCP"]) restartListener = YES;
	if ([[previousDefaults valueForKey: @"USESTORESCP"] intValue]				!=		[[note object] integerForKey: @"USESTORESCP"]) restartListener = YES;
	if ([[previousDefaults valueForKey: @"HIDEPATIENTNAME"] intValue]			!=		[[note object] integerForKey: @"HIDEPATIENTNAME"]) refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"COLUMNSDATABASE"]			isEqualToDictionary:[[note object] objectForKey: @"COLUMNSDATABASE"]] == NO) refreshColumns = YES;	
	if ([[previousDefaults valueForKey: @"SERIESORDER"]intValue]				!=		[[note object] integerForKey: @"SERIESORDER"]) refreshDatabase = YES;
	if ([[previousDefaults valueForKey: @"KeepStudiesOfSamePatientTogether"]intValue]				!=		[[note object] integerForKey: @"KeepStudiesOfSamePatientTogether"]) refreshDatabase = YES;
	
	[previousDefaults release];
	previousDefaults = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
	
	if (refreshDatabase)
	{
		[browserWindow setDBDate];
		[browserWindow outlineViewRefresh];
	}
		
	if (restartListener)
	{
		if( showRestartNeeded == YES)
		{
			showRestartNeeded = NO;
			NSRunAlertPanel( NSLocalizedString( @"DICOM Listener", 0L), NSLocalizedString( @"Restart OsiriX to apply these changes.", 0L), NSLocalizedString( @"OK", 0L), nil, nil);
		}
	}
		
	if (refreshColumns)	
		[browserWindow refreshColumns];
	
	if( recomputePETBlending)
		[DCMView computePETBlendingCLUT];
	
	if( [[note object] boolForKey: @"updateServers"])
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"updateServers"];
		[[QueryController currentQueryController] refreshSources];
	}
	
	[[BrowserController currentBrowser] setNetworkLogs];
	
	[DicomFile resetDefaults];
	[DicomFile setDefaults];
		
	NS_HANDLER
		NSLog(@"Exception updating prefs: %@", [localException description]);
	NS_ENDHANDLER
	
}

- (void) windowDidLoad
{
	//need to load panes
	//inDirectory: @"PreferencePanes"
	NSString *pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIGeneralPreferencePane" ofType: @"prefPane"];
	NSBundle *prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
	Class prefPaneClass = [prefBundle principalClass];
	NSPreferencePane *aPane = [[prefPaneClass alloc] initWithBundle:prefBundle];
	//[self setPane:aPane];
	[aPane release];

	[[NSNotificationCenter defaultCenter]	addObserver: self
											   selector: @selector(preferencesUpdated:)
												   name: NSUserDefaultsDidChangeNotification
												 object: nil];
	
	[[self window] setDelegate:self];
	[self showAll:nil];
}

- (void) dealloc
{
	NSLog(@"PreferencePaneController released !");
	// In+case Pne does anyting on closing
	[pane shouldUnselect];
	[pane willUnselect];
	[[pane mainView] removeFromSuperview];
	[pane didUnselect];
	[pane release];
	[previousDefaults release];
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
		//	[[self window] setFrame:newWindowFrame display:YES animate:YES];
		
			[pane willUnselect];
			[[pane mainView] removeFromSuperview];
			[allView removeFromSuperview];
			
		//	[[[self window] contentView] addSubview:[aPane mainView]];

			[[aPane mainView] setAutoresizesSubviews: YES];
			[[aPane mainView] setAutoresizingMask: NSViewWidthSizable + NSViewHeightSizable];
			
			[[self window] setFrame:newWindowFrame display:YES animate:YES];
			
			[[self window] setContentMinSize: newRect.size];
			[[self window] setFrame:newWindowFrame display:YES animate:YES];
			
			
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

	showRestartNeeded = YES;
}

- (NSPreferencePane *)pane{
	return pane;
}

- (void) selectFirstPane
{
	NSString *pathToPrefPaneBundle;
	NSBundle *prefBundle;
	Class prefPaneClass;
	
	pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIGeneralPreferencePane" ofType: @"prefPane"];
	
	prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
	prefPaneClass = [prefBundle principalClass];
	NSPreferencePane *aPane = [[prefPaneClass alloc] initWithBundle:prefBundle];	
	[self setPane:aPane];
	[pane release];
}

- (IBAction)nextAndPrevPane:(id)sender
{
	if( curPaneIndex == -1) curPaneIndex = 0;
	else
	{
		switch ([[sender selectedCell] tag])
		{
			case 0:	// Previous
				curPaneIndex--;
			break;
			
			case 1: // Next
				curPaneIndex++;
			break;
		}
	}
	
	if( curPaneIndex < 0) curPaneIndex = 11;
	if( curPaneIndex > 11) curPaneIndex = 0;
	
	[self selectPaneIndex: curPaneIndex];
}

- (void)selectPaneIndex:(int) index
{
	NSString *pathToPrefPaneBundle;
	NSBundle *prefBundle;
	Class prefPaneClass;
	
	switch ( index) {
		case 0:
		default:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIGeneralPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"General"];
			break;
		case 4:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIViewerPreferencePane" ofType: @"prefPane"];	
			[[self window] setTitle:@"Viewers"];
			break;
		case 2:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSICDPreferencePane" ofType: @"prefPane"];	
			[[self window] setTitle:@"CD/DVD"];
			break;
		case 1:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIDatabasePreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"Database"];
			break;
		case 8:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIListenerPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"Listener"];
			break;
		case 9:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSILocationsPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"Locations"];
			break;
		case 11:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"AYDicomPrint" ofType: @"prefPane"];
			[[self window] setTitle:@"DICOM Print"];
			break;
		case 3:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIHangingPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"Protocols"];	
			break;
		case 5:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSI3DPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"3D"];
			break;
		case 6:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIPETPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"PET"];
			break;
		case 10:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIAutoroutingPreferencePane" ofType: @"prefPane"];
			[[self window] setTitle:@"Routing"];
			break;
		case 7:
			pathToPrefPaneBundle = [[NSBundle mainBundle] pathForResource: @"OSIHotKeys" ofType: @"prefPane"];
			[[self window] setTitle:@"Hot Keys"];
			break;
	}
	prefBundle = [NSBundle bundleWithPath: pathToPrefPaneBundle];
	prefPaneClass = [prefBundle principalClass];
	NSPreferencePane *aPane = [[prefPaneClass alloc] initWithBundle:prefBundle];	
	[self setPane:aPane];
	[pane release];
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
	[pane shouldUnselect];		
	[pane willUnselect];
	[pane didUnselect];
	[[pane mainView] removeFromSuperview];			
	
	[[self window] setFrame:newWindowFrame display:YES animate:YES];
	
	[[self window] setContentMinSize: newRect.size];
	[[self window] setFrame:newWindowFrame display:YES animate:YES];
				
	[destView addSubview:allView];
	[allView setNeedsDisplay:YES];
	[pane release];
	pane = nil;
	
	[[self window] setContentMinSize: NSMakeSize(0 , 0)];
	
	NSRect	finalFrame = [[self window] frame];
	
	[[self window] setTitle:@"Preferences"];
	
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
- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	return nil;
}
@end
