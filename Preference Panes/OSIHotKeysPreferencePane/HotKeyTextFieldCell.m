//
//  HotKeyTextField.m
//  OSIHotKeysPreferencePane
//
//  Created by Lance Pysher on 11/30/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "HotKeyTextFieldCell.h"
#import "HotKeyFormatter.h"


@implementation HotKeyTextFieldCell


- (void)awakeFromNib{
	HotKeyFormatter *formatter = [[[HotKeyFormatter alloc] init] autorelease];
	[self setFormatter:formatter];
}


@end
