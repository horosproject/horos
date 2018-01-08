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

#import <N2CellDescriptor.h>
#import "NSView+N2.h"
#import "N2Operators.h"

@implementation N2CellDescriptor
@synthesize view = _view, alignment = _alignment, widthConstraints = _widthConstraints, /*rowSpan = _rowSpan, */colSpan = _colSpan, invasivity = _invasivity, filled = _filled;

+(N2CellDescriptor*)descriptor {
	return [[[[self alloc] init] autorelease] colSpan:1];
}

+(N2CellDescriptor*)descriptorWithView:(NSView*)view {
	return [[self descriptor] view:view];
}

+(N2CellDescriptor*)descriptorWithWidthConstraints:(const N2MinMax&)widthConstraints {
	return [[self descriptor] widthConstraints:widthConstraints];
}

+(N2CellDescriptor*)descriptorWithWidthConstraints:(const N2MinMax&)widthConstraints alignment:(N2Alignment)alignment {
	return [[self descriptorWithWidthConstraints:widthConstraints] alignment:alignment];
}

-(id)init {
	self = [super init];
	[self setWidthConstraints:N2MakeMinMax()];
	[self setAlignment:N2Left];
	[self setFilled:YES];
	return self;
}

-(void)dealloc {
	[_view release];
	[super dealloc];
}

-(id)copyWithZone:(NSZone*)zone {
	N2CellDescriptor* copy = [[N2CellDescriptor allocWithZone:zone] initWithWidthConstraints:_widthConstraints alignment:_alignment];
	if (copy == nil) return nil;
	
	[copy setView:_view];
	[copy setAlignment:_alignment];
	[copy setWidthConstraints:_widthConstraints];
	[copy setInvasivity:_invasivity];
	[copy setColSpan:_colSpan];
	[copy setFilled:_filled];
	return copy;
}

-(N2CellDescriptor*)view:(NSView*)view {
	[self setView:view];
	return self;
}

-(N2CellDescriptor*)alignment:(N2Alignment)alignment {
	[self setAlignment:alignment];
	return self;
}

-(N2CellDescriptor*)widthConstraints:(const N2MinMax&)widthConstraints {
	[self setWidthConstraints:widthConstraints];
	return self;
}

/*-(N2CellDescriptor*)rowSpan:(NSUInteger)rowSpan {
	[self setRowSpan:rowSpan];
	return self;
}*/

-(N2CellDescriptor*)colSpan:(NSUInteger)colSpan {
	[self setColSpan:colSpan];
	return self;
}

-(N2CellDescriptor*)invasivity:(CGFloat)invasivity {
	[self setInvasivity:invasivity];
	return self;
}

-(N2CellDescriptor*)filled:(BOOL)filled {
	[self setFilled:filled];
	return self;
}

-(NSSize)optimalSize {
	if ([_view respondsToSelector:@selector(optimalSize)])
		return n2::ceil([(id<OptimalSize>)_view optimalSize]);
	else return [_view frame].size;	
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	if ([_view respondsToSelector:@selector(optimalSizeForWidth:)])
		return n2::ceil([(id<OptimalSize>)_view optimalSizeForWidth:width]);
	else return n2::ceil([_view frame].size);
}

-(NSRect)sizeAdjust {
	return [_view sizeAdjust];
}

#pragma mark Deprecated

-(N2CellDescriptor*)initWithWidthConstraints:(const N2MinMax&)widthConstraints alignment:(N2Alignment)alignment {
	self = [super init];
	[self setWidthConstraints:widthConstraints];
	[self setAlignment:alignment];
	return self;
}

@end

@implementation N2ColumnDescriptor
@end
