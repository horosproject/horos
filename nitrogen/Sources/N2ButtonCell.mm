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

#import <N2ButtonCell.h>
#import <NSString+N2.h>
#import <N2Operators.h>


@implementation N2ButtonCell

-(void)awakeFromNib {
	[self setShowsBorderOnlyWhileMouseInside:NO];
//	_keyEq = [self.keyEquivalent retain];
}

-(void)dealloc {
//	if (_keyEq) [_keyEq release]; _keyEq = NULL;
	[super dealloc];
}

-(void)drawBezelWithFrame:(NSRect)frame inView:(NSButton*)view {
	if (self.backgroundColor) {
		NSGraphicsContext* context = [NSGraphicsContext currentContext];
		[context saveGraphicsState];
		
		[self.backgroundColor setFill]; // [NSColor colorWithCalibratedRed:.5 green:.66 blue:1 alpha:.5]
		NSRect frame2 = NSInsetRect(frame, 0, 2);//frame2.size.height -= 2;
		[[NSBezierPath bezierPathWithRoundedRect:frame2 xRadius:frame2.size.height/2 yRadius:frame2.size.height/2] fill];
		
		[context restoreGraphicsState];
	}
	
	[super drawBezelWithFrame:frame inView:view];
}

//- (void) )copywithzone NEEDED IF LOCAL VARIABLE
//{
//    
//}

@end
