//
//  OSIHotKeysPref.m
//  OSIHotKeys
//
//  Created by Lance Pysher on 11/28/06.
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

#import "OSIHotKeysPref.h"


@implementation OSIHotKeysPref

- (void)dealloc{
	[_actions release];
	[_keys release];
	[super dealloc];
}

- (void) mainViewDidLoad
{
	_actions = [[NSArray arrayWithObjects:	NSLocalizedString(@"Default WW/WL", nil), 
											NSLocalizedString(@"Full Dynamic WW/WL", nil),
											NSLocalizedString(@"1st WW/WL preset", nil),
											NSLocalizedString(@"2nd WW/WL preset", nil),
											NSLocalizedString(@"3rd WW/WL preset", nil),
											NSLocalizedString(@"4th WW/WL preset", nil),
											NSLocalizedString(@"5th WW/WL preset", nil),
											NSLocalizedString(@"6th WW/WL preset", nil),
											NSLocalizedString(@"7th WW/WL preset", nil),
											NSLocalizedString(@"8th WW/WL preset", nil),
											NSLocalizedString(@"9th WW/WL preset", nil),
											NSLocalizedString(@"Flip Vertical", nil),
											NSLocalizedString(@"Flip Horizontal", nil),
											NSLocalizedString(@"Select WW/WL Tool", nil),
											NSLocalizedString(@"Select Move Tool", nil),
											NSLocalizedString(@"Select Zoom Tool", nil),
											NSLocalizedString(@"Select Rotate Tool", nil),
											NSLocalizedString(@"Select Scroll Tool", nil),
											NSLocalizedString(@"Select Measure Length Tool", nil),
											NSLocalizedString(@"Select Measure Angle Tool", nil),
											NSLocalizedString(@"Select Rectangle ROI Tool", nil),
											NSLocalizedString(@"Select Oval ROI Tool", nil),
											NSLocalizedString(@"Select Text Tool", nil),
											NSLocalizedString(@"Select Arrow Tool", nil),
											NSLocalizedString(@"Select Open Polygon Tool", nil),
											NSLocalizedString(@"Select Closed Polygon Tool", nil),
											NSLocalizedString(@"Select Pencil Tool", nil),
											NSLocalizedString(@"Select 3D Point Tool", nil),
											NSLocalizedString(@"Select Plain Tool", nil),
											NSLocalizedString(@"Select Bone Removal Tool", nil),
											nil] retain];
	_keys = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"] allKeys] retain];
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.listener"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self setEnableControls: YES];
		else [self setEnableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];
											
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self setEnableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self setEnableControls: NO];
}

- (void) setEnableControls: (BOOL) val
{
	_enableControls = val;
}

- (BOOL)enableControls{
	return _enableControls;
}

- (NSArray *)actions{
	return _actions;
}
- (void)setActions:(NSArray *)actions{
	[_actions release];
	_actions = [actions retain];
}

- (NSArray *)keys{
	return _keys;
}
- (void)setKeys:(NSArray *)keys{
	[_keys release];
	_keys = [keys retain];
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	int count = [_keys count];
	int i = 0;
	for (i = 0; i < count; i++)
		[dict setObject:[NSNumber numberWithInt:i] forKey:[_keys objectAtIndex:i]];
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"HOTKEYS"];
	
}

@end
