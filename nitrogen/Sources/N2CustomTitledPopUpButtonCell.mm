//
//  N2CustomTitledPopUpButtonCell.mm
//  OsiriX
//
//  Created by Alessandro Volz on 5/25/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "N2CustomTitledPopUpButtonCell.h"


@implementation N2CustomTitledPopUpButtonCell

@synthesize displayedTitle;

-(void)dealloc {
	self.displayedTitle = NULL;
	[super dealloc];
}

-(NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
	NSString* t = displayedTitle? displayedTitle : @"";
	
	[t drawInRect:frame withAttributes:[title attributesAtIndex:0 effectiveRange:NULL]];
	
	return frame;
}

@end
