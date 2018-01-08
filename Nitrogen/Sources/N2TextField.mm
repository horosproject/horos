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

#import "N2TextField.h"


@interface N2TextField ()

@property(nonatomic, readwrite) BOOL formatIsOk;

@end


@implementation N2TextField

//@synthesize invalidContentBackgroundColor;
@synthesize formatIsOk;

-(id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	formatIsOk = YES;
	return self;
}

/*-(void)dealloc {
	self.invalidContentBackgroundColor = NULL;
	[super dealloc];
}*/

-(void)updateFormatIsOk {
	if (self.formatter) {
		id obj = NULL;
		
		// ok if filled and respects format
		// also ok if NOT filled and placeholder string defined
		if (self.stringValue.length)
			self.formatIsOk = [self.formatter getObjectValue:&obj forString:self.stringValue errorDescription:NULL];
		else {
			if ([[self cell] placeholderString])
				self.formatIsOk = YES;
			else self.formatIsOk = NO;
		}
		
	/*	if (invalidContentBackgroundColor) {
			[self setBackgroundColor: self.formatIsOk? [NSColor whiteColor] : invalidContentBackgroundColor ];
			[self setNeedsDisplay:YES];
		}*/
	}
}

-(void)setFormatter:(NSFormatter*)newFormatter {
	[super setFormatter:newFormatter];
	[self updateFormatIsOk];
}

-(void)setFormatIsOk:(BOOL)flag {
	if (formatIsOk == flag)
		return;
	formatIsOk = flag;
	[self didChangeValueForKey:@"formatIsOk"];
}

/*-(void)setInvalidContentBackgroundColor:(NSColor*)color {
	[invalidContentBackgroundColor release];
	invalidContentBackgroundColor = [color retain];
	[self checkFormat];
}*/

-(void)keyDown:(NSEvent*)event {
	[super keyDown:event];
	[self updateFormatIsOk];
}

-(void)textDidChange:(NSNotification*)notif {
	[super textDidChange:notif];
	[self updateFormatIsOk];
}

-(void)setObjectValue:(id)value {
	[super setObjectValue:value];
	[self updateFormatIsOk];
}

-(void)setStringValue:(id)value {
	[super setStringValue:value];
	[self updateFormatIsOk];
}

@end
