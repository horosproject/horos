//
//  OSIHotKeysPref.h
//  OSIHotKeys
//
//  Created by Lance Pysher on 11/28/06.
//  Copyright (c) 2006 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface OSIHotKeysPref : NSPreferencePane 
{
	NSArray *actions;
	NSArray *keys;
}

- (void) mainViewDidLoad;

@end
