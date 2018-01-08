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
//
//  OnOffSwitchControl.m
//  OnOffSwitchControl
//
//  Created by Peter Hosey on 2010-01-10.
//  Copyright 2010 Peter Hosey. All rights reserved.
//
//  Extended by Dain Kaplan on 2012-01-31.
//  Copyright 2012 Dain Kaplan. All rights reserved.
//

#import "OnOffSwitchControl.h"
#import "OnOffSwitchControlCell.h"

@implementation OnOffSwitchControl

+ (void) initialize {
	[self setCellClass:[OnOffSwitchControlCell class]];
}
- (void) awakeFromNib {
	[[self class] setCellClass:[OnOffSwitchControlCell class]];
}

- (void) keyDown:(NSEvent *)event {
	unichar character = [[event characters] characterAtIndex:0UL];
	switch (character) {
		case NSLeftArrowFunctionKey:
		case NSRightArrowFunctionKey:
			//Do nothing (yet). We'll handle this in keyUp:.
			break;
		default:
			[super keyDown:event];
			break;
	}
}

- (void) keyUp:(NSEvent *)event {
	unichar character = [[event characters] characterAtIndex:0UL];
	switch (character) {
		case NSLeftArrowFunctionKey:
			switch ([self state]) {
				case NSOffState:
					NSBeep();
					break;
				case NSMixedState:
					[self setState:NSOffState];
					break;
				case NSOnState:
					if ([self allowsMixedState])
						[self setState:NSMixedState];
					else
						[self setState:NSOffState];
					break;
			}
			break;
		case NSRightArrowFunctionKey:
			switch ([self state]) {
				case NSOffState:
					if ([self allowsMixedState])
						[self setState:NSMixedState];
					else
						[self setState:NSOnState];
					break;
				case NSMixedState:
					[self setState:NSOnState];
					break;
				case NSOnState:
					NSBeep();
					break;
			}
			break;
		default:
			[super keyUp:event];
			break;
	}
}

@end
