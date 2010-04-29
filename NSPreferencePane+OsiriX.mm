//
//  NSPreferencePane+OsiriX.mm
//  OsiriX
//
//  Created by Alessandro Volz on 4/29/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSPreferencePane+OsiriX.h"
#import "PreferencesWindowController.h"
#import <SecurityInterface/SFAuthorizationView.h>


@implementation NSPreferencePane (OsiriX)

-(NSNumber*)editable {
	if ([[(PreferencesWindowController*)[[[self mainView] window] windowController] authView] authorizationState] == SFAuthorizationViewUnlockedState)
		return [NSNumber numberWithBool:YES];
	return [NSNumber numberWithBool:NO];
}

@end
