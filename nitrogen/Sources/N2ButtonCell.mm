/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
