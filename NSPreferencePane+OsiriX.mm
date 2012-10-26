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


#import "NSPreferencePane+OsiriX.h"
#import "PreferencesWindowController.h"
#import <SecurityInterface/SFAuthorizationView.h>


@implementation NSPreferencePane (OsiriX)

-(BOOL)isUnlocked {
	return ![[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"] || [[(PreferencesWindowController*)[[[self mainView] window] windowController] authView] authorizationState] == SFAuthorizationViewUnlockedState;
}

-(NSNumber*)editable {
	return [NSNumber numberWithBool:[self isUnlocked]];
}

@end
