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
	NSLog(@"dealloc Hot Key Pref PAne");
	[_actions release];
	[super dealloc];
}

- (void) mainViewDidLoad
{
	// create array of MutableDictionaries containing names of actions
		NSArray *actions = [NSArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:	NSLocalizedString(@"Default WW/WL", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Full Dynamic WW/WL", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"1st WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"2nd WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3rd WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"4th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"5th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"6th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"7th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"8th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"9th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Flip Vertical", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Flip Horizontal", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select WW/WL Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Move Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Zoom Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Rotate Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Scroll Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Measure Length Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Measure Angle Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Rectangle ROI Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Oval ROI Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Text Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Arrow Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Open Polygon Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Closed Polygon Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Pencil Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select 3D Point Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Plain Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Select Bone Removal Tool", nil), @"action", nil],
											nil];
	
	NSDictionary *keys = [[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"];
	NSEnumerator *enumerator = [keys objectEnumerator];
	id index;
	// the indes will be the position in the Actions Array. The key is the hotkey.
	while (index = [enumerator nextObject]) {
		NSArray *allKeys = [keys allKeysForObject:index];
		if ([allKeys count] > 0) {
			NSString *key = [allKeys objectAtIndex:0];
			[[actions objectAtIndex:[index intValue]] setObject:key forKey:@"key"];
		}
	}
	[self setActions:actions];
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
	//NSLog(@"MainViewDidLoad arrayController: %@", [arrayController description]);
											
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
	//NSLog(@"action: %@", [_actions description]);
	return _actions;
}

- (void)setActions:(NSArray *)actions{
	[_actions release];
	_actions = [actions retain];	

	
}

- (NSPreferencePaneUnselectReply)shouldUnselect{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	int count = [_actions count];
	int i;
	for (i = 0; i < count; i++)
		[dict setObject:[NSNumber numberWithInt:i] forKey:[[_actions objectAtIndex:i] objectForKey:@"key"]];
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"HOTKEYS"];
	return [super shouldUnselect];
}

- (void)didUnselect{
}



@end
