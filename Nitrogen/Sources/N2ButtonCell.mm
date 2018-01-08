/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
