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

-(BOOL)isUnlocked {
	return [[(PreferencesWindowController*)[[[self mainView] window] windowController] authView] authorizationState] == SFAuthorizationViewUnlockedState;
}

-(NSNumber*)editable {
	return [NSNumber numberWithBool:[self isUnlocked]];
}

@end
