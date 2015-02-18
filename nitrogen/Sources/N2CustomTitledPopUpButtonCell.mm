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

- (id) copyWithZone:(NSZone *)zone
{
    N2CustomTitledPopUpButtonCell* copy = [[N2CustomTitledPopUpButtonCell allocWithZone:zone] init];
	if (copy == nil) return nil;
	
	copy->displayedTitle = [self.displayedTitle copyWithZone: zone];
    
    return copy;
}

@end
