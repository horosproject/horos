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