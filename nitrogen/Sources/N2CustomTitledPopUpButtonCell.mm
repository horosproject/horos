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
