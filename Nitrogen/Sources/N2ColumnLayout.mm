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


#import "N2ColumnLayout.h"
#import "N2CellDescriptor.h"
#import "NSView+N2.h"
#import "N2Operators.h"
#include <algorithm>
#include <cmath>

#include "N2ColorWell.h"

@implementation N2ColumnLayout

-(id)initForView:(N2View*)view columnDescriptors:(NSArray*)columnDescriptors controlSize:(NSControlSize)controlSize {
	self = [super initWithView:view controlSize:controlSize];
	
	_columnDescriptors = [columnDescriptors retain];
	_rows = [[NSMutableArray alloc] initWithCapacity:8];
	
	return self;
}

-(id)initForView:(N2View*)view controlSize:(NSControlSize)controlSize {
	return [self initForView:view columnDescriptors:NULL controlSize:controlSize];
}

-(void)dealloc {
	[_rows release];
	[_columnDescriptors release];
	[super dealloc];
}

-(NSArray*)rowAtIndex:(NSUInteger)index {
	return [_rows objectAtIndex:index];
}

-(NSUInteger)appendRow:(NSArray*)row {
	NSUInteger i = [_rows count];
	[self insertRow:row atIndex:i];
	return i;
}

-(void)insertRow:(NSArray*)row atIndex:(NSUInteger)index {
//	if (_columnDescriptors)
//		if ([line count] != [_columnDescriptors count])
//			[NSException raise:NSGenericException format:@"The number of views in a line must match the number of columns"];
//		else if ([_lines count] && [[_lines lastObject] count] != [line count])
//			[NSException raise:NSGenericException format:@"The number of views in a line must match the number of views in all other lines"];
	
	NSUInteger colNumber = 0;
	NSMutableArray* cells = [NSMutableArray arrayWithCapacity:[row count]];
	for (id cell in row) {
		if ([cell isKindOfClass:[NSView class]])
			cell = [(_columnDescriptors? [[[_columnDescriptors objectAtIndex:colNumber] copy] autorelease] : [N2CellDescriptor descriptor]) view:cell];
		[cells addObject:cell];
		colNumber += [cell colSpan];
		[_view addSubview:[cell view]];
	}

	[_rows insertObject:cells atIndex:index];
	
	[self layOut];
}

-(void)removeRowAtIndex:(NSUInteger)index {
	for (N2CellDescriptor* cell in [_rows objectAtIndex:index])
		[[cell view] removeFromSuperview];
	[_rows removeObjectAtIndex:index];
}

-(void)removeAllRows {
	for (int i = (long)[_rows count]-1; i >= 0; --i)
		[self removeRowAtIndex:i];
}

typedef struct ConstrainedFloat {
	CGFloat value;
	N2MinMax constraint;
} ConstrainedFloat;

-(NSArray*)computeSizesForWidth:(CGFloat)widthWithMarginAndSeparations {
	NSUInteger rowsCount = [_rows count];
	NSUInteger colsCount = [_columnDescriptors count];
	
	if (!rowsCount)
		return NULL;
	
	ConstrainedFloat widths[colsCount][colsCount];
	for (NSUInteger i = 0; i < colsCount; ++i)
		for (NSUInteger j = 0; j < colsCount; ++j) {
			widths[j][i].value = 0;
			widths[j][i].constraint = N2MakeMinMax();
		}
	for (NSArray* row in _rows) {
		NSUInteger colNumber = 0;
		for (N2CellDescriptor* cell in row) {
			NSUInteger span = [cell colSpan];
			
			widths[span-1][colNumber].constraint = N2ComposeMinMax(widths[span-1][colNumber].constraint, [cell widthConstraints]);
			widths[span-1][colNumber].value = std::max(widths[span-1][colNumber].value, [cell optimalSize].width);
			
			colNumber += span;
		}
	}
	
	CGFloat widthWithSeparations = widthWithMarginAndSeparations - _margin.size.width;
	
	if (!_forcesSuperviewWidth && widthWithMarginAndSeparations != CGFLOAT_MAX) {
		widths[colsCount-1][0].constraint = N2MakeMinMax(widthWithSeparations);
		widths[colsCount-1][0].value = widthWithSeparations;
	}
	
	for (NSUInteger span = 1; span <= colsCount; ++span)
		for (NSUInteger from = 0; from <= colsCount-span; ++from)
			if (widths[span-1][from].value) {
				while (true) {
					// targetWidth is the sum of span 1 widths
					ConstrainedFloat targetWidth = {-_separation.width, N2MakeMinMax(-_separation.width)};
					for (NSUInteger i = from; i < from+span; ++i) {
						targetWidth.value += widths[0][i].value + _separation.width;
						targetWidth.constraint = targetWidth.constraint + widths[0][i].constraint + _separation.width;
					}
					
					CGFloat currentWidth = targetWidth.value;

					targetWidth.value = std::max(widths[span-1][from].value, targetWidth.value);
					targetWidth.constraint = N2ComposeMinMax(widths[span-1][from].constraint, targetWidth.constraint);
					targetWidth.value = N2MinMaxConstrainedValue(targetWidth.constraint, targetWidth.value);
					widths[span-1][from] = targetWidth;
					
					if (span == 1) break;
					
				//	if (colsCount == 2 && widthWithMarginAndBorder > 1000) {
				//	std::cout << "it " << [[NSString stringWithFormat:@"%@", self] UTF8String] << std::endl;
				//	for (int i = 0; i < colsCount; ++i) {
				//		std::cout << i;
				//		for (int j = 0; j < colsCount; ++j)
				//			std::cout << " [" << widths[i][j].constraint.min << "≤" << widths[i][j].value << "≤" << widths[i][j].constraint.max << "]";
				//		std::cout << std::endl;
				//	} std::cout << std::endl;
				//	}
					
					if (std::floor(currentWidth+0.5) == std::floor(targetWidth.value+0.5) || targetWidth.value <= 0)
						break;
					
					CGFloat deltaWidth = targetWidth.value-currentWidth; // if (deltaWidth > 0) increase
					if (deltaWidth*deltaWidth < 0.7)
						break;
					
					BOOL colFixed[colsCount];
					int unfixedColsCount = 0;
					CGFloat unfixedRefWidth = 0, unfixedInvasivity = 0;
					for (NSUInteger i = from; i < from+span; ++i)
						if (!(colFixed[i] = !((deltaWidth > 0 && widths[0][i].value < widths[0][i].constraint.max) || (deltaWidth < 0 && widths[0][i].value > widths[0][i].constraint.min))))
                        {
							++unfixedColsCount;
							unfixedRefWidth += widths[0][i].value;
							unfixedInvasivity += [[_columnDescriptors objectAtIndex:i] invasivity];
						}
					
					if (!unfixedColsCount || unfixedRefWidth < 1)
						break;
					
					for (NSUInteger i = from; i < from+span; ++i)
                    {
						if (!colFixed[i])
                        {
							if (unfixedInvasivity == 0)
								widths[0][i].value *= 1+deltaWidth/unfixedRefWidth;
							else widths[0][i].value += deltaWidth*([[_columnDescriptors objectAtIndex:i] invasivity]/unfixedInvasivity);
                        }
                    }
				}
			}
	
	// views are as wide as the cells
//	for (NSUInteger span = 1; span <= colsCount; ++span)
//		for (NSUInteger from = 0; from <= colsCount-span; ++from) {
//			ConstrainedFloat subWidth = {0, N2MakeMinMax()};
//			for (NSUInteger i = from; i < from+span; ++i) {
//				subWidth.value = subWidth.value + widths[0][i].value;
//				subWidth.constraint = subWidth.constraint + widths[0][i].constraint;
//			}
//			
//			widths[span-1][from].value = std::max(widths[span-1][from].value, subWidth.value);
//			widths[span-1][from].constraint = N2ComposeMinMax(widths[span-1][from].constraint, subWidth.constraint);
//		}
	
	// get cell sizes and row heights
	NSSize sizes[rowsCount][colsCount];
	memset(sizes, 0, sizeof(NSSize)*rowsCount*colsCount);
//	CGFloat rowHeights[rowsCount];
	for (NSUInteger r = 0; r < rowsCount; ++r) {
		NSArray* row = [_rows objectAtIndex:r];
		NSUInteger colNumber = 0;
//		rowHeights[l] = 0;
		CGFloat rowHeight = 0;
		for (N2CellDescriptor* cell in row) {
			NSUInteger span = [cell colSpan];
			
			CGFloat spannedWidth = -_separation.width;
			for (NSUInteger i = colNumber; i < colNumber+span; ++i)
				spannedWidth += widths[0][i].value + _separation.width;
			
			sizes[r][colNumber] = [cell filled]? NSMakeSize(spannedWidth, [cell optimalSizeForWidth:spannedWidth+[cell sizeAdjust].size.width].height) : [cell optimalSizeForWidth:spannedWidth+[cell sizeAdjust].size.width];
			rowHeight = std::max(rowHeight, sizes[r][colNumber].height);
//			rowHeights[l] = std::max(rowHeights[l], sizes[l][i].height);
	//		NSSize test = sizes[r][colNumber];
			
			colNumber += span;
		}
		colNumber = 0;
		for (N2CellDescriptor* cell in row) {
			NSUInteger span = [cell colSpan];
			if ([cell filled])
				sizes[r][colNumber].height = rowHeight;
			colNumber += span;
		}
				
	}
	
//	std::cout << "end" << std::endl;
//	for (NSUInteger r = 0; r < rowsCount; ++r) {
//		std::cout << r;
//		for (NSUInteger i = 0; i < colsCount; ++i)
//			std::cout << " [" << sizes[r][i].width << "," << sizes[r][i].height << "]";
//		std::cout << std::endl;
//	} std::cout << std::endl;
	
	NSMutableArray* resultSizes = [NSMutableArray arrayWithCapacity:rowsCount];
	for (NSUInteger r = 0; r < rowsCount; ++r) {
		NSMutableArray* resultRowSizes = [NSMutableArray arrayWithCapacity:colsCount];
		for (NSUInteger i = 0; i < colsCount; ++i)
			[resultRowSizes addObject:[NSValue valueWithSize:sizes[r][i]]];
		[resultSizes addObject:resultRowSizes];
	}
	NSMutableArray* resultColWidths = [NSMutableArray arrayWithCapacity:colsCount];
	for (NSUInteger i = 0; i < colsCount; ++i)
		[resultColWidths addObject:[NSNumber numberWithFloat:widths[0][i].value]];
	return [NSArray arrayWithObjects: resultColWidths, resultSizes, NULL];
}

-(NSArray*)computeSizesForSize:(NSSize)sizeWithMarginAndSeparations {
	NSSize size = [self optimalSizeForWidth:sizeWithMarginAndSeparations.width];
	if (!_forcesSuperviewHeight && size.height > sizeWithMarginAndSeparations.height) {
		NSUInteger step = std::max(NSUInteger(size.width/10), NSUInteger(1));
		size.width += step;
		do { // "decrease width until its height fits the height"
			size.width -= step;
			size = [self optimalSizeForWidth:size.width];
			if (size.height <= sizeWithMarginAndSeparations.height && step > 1) {
				size.width += step;
				step = std::max(step/10, NSUInteger(1));
				size.height = sizeWithMarginAndSeparations.height+1;
			}
		} while (size.height > sizeWithMarginAndSeparations.height && size.width > 20);
	}
	
	return [self computeSizesForWidth:size.width];
}

-(void)layOutImpl {
	NSUInteger rowsCount = [_rows count];
	NSUInteger colsCount = [_columnDescriptors count];

	NSSize size = [_view frame].size;
	
	NSArray* sizesData = [self computeSizesForSize:size];
	CGFloat colWidth[colsCount];
	for (NSUInteger i = 0; i < colsCount; ++i)
		colWidth[i] = [[[sizesData objectAtIndex:0] objectAtIndex:i] floatValue];
	NSSize sizes[rowsCount][colsCount];
	CGFloat rowHeights[rowsCount];
	for (NSUInteger r = 0; r < rowsCount; ++r) {
		NSArray* rowsizes = [[sizesData objectAtIndex:1] objectAtIndex:r];
		rowHeights[r] = 0;
		for (NSUInteger i = 0; i < colsCount; ++i) {
			sizes[r][i] = [[rowsizes objectAtIndex:i] sizeValue];
			rowHeights[r] = std::max(rowHeights[r], sizes[r][i].height);
		}
	}
		
	// apply computed column widths
	
	CGFloat y = _margin.origin.y;
	CGFloat x0 = _margin.origin.x;
	
	CGFloat maxX = 0;
	for (NSInteger r = rowsCount-1; r >= 0; --r) {
		NSArray* row = [_rows objectAtIndex:r];
		
		CGFloat x = x0;
		NSUInteger colNumber = 0;
		for (N2CellDescriptor* cell in row) {
			NSUInteger span = [cell colSpan];
			CGFloat spannedWidth = -_separation.width;
			for (NSUInteger i = colNumber; i < colNumber+span; ++i)
				spannedWidth += colWidth[i]+_separation.width;
			
			NSPoint origin = NSMakePoint(x, y);
			NSSize size = sizes[r][colNumber];
			
			if ([cell filled])
				size.width = spannedWidth;
			size = n2::ceil(size);
			
			NSSize extraSpace = NSMakeSize(spannedWidth, rowHeights[r]) - size;
			N2Alignment alignment = [cell alignment];
			if (alignment&N2Top)
				origin.y += extraSpace.height;
			else if (alignment&N2Bottom)
				origin.y += 0;
			else
				origin.y += extraSpace.height/2;
			if (alignment&N2Right)
				origin.x += extraSpace.width;
			else if (alignment&N2Left)
				origin.x += 0;
			else
				origin.x += extraSpace.width/2;
			
			NSRect sizeAdjust = [[cell view] sizeAdjust];
			[[cell view] setFrame:NSMakeRect(origin+sizeAdjust.origin, size+sizeAdjust.size)];
			
			x += spannedWidth+_separation.width;
			colNumber += span;
		}
		x += _margin.size.width-_margin.origin.x - _separation.width;
		
		maxX = std::max(maxX, x);
		y += rowHeights[r]+_separation.height;
	}
	y += _margin.size.height-_margin.origin.y - _separation.height;
	
	NSRect bounds = [_view frame];
	if (!_forcesSuperviewWidth)
		bounds.origin.x = -(bounds.size.width-maxX)/2;
	if (!_forcesSuperviewHeight)
		bounds.origin.y = -(bounds.size.height-y)/2;
	[_view setBounds:bounds];
	
	// superview size
	if (_forcesSuperviewWidth || _forcesSuperviewHeight) {
		// compute
		NSSize newSize = size;
		if (_forcesSuperviewWidth)
			newSize.width = maxX;
		if (_forcesSuperviewHeight)
			newSize.height = y;
		// apply
		NSWindow* window = [_view window];
		if (_view == (id)[window contentView]) {
			NSRect frame = [window frame];
			NSSize oldFrameSize = frame.size;
			frame.size = [window frameRectForContentRect:NSMakeRect(NSZeroPoint, newSize)].size;
			frame.origin = frame.origin - (frame.size - oldFrameSize);
			[window setFrame:frame display:YES];
		} else
			[_view setFrameSize:newSize];
	}
}

-(NSSize)optimalSizeForWidth:(CGFloat)widthWithMarginAndBorder {
	if (!_enabled) return [_view frame].size;
	
	NSUInteger rowsCount = [_rows count];
	NSUInteger colsCount = [_columnDescriptors count];
	
	if ([self forcesSuperviewWidth] && widthWithMarginAndBorder != CGFLOAT_MAX) {
		NSSize optimalSize = [self optimalSize];
		widthWithMarginAndBorder = optimalSize.width;
		if ([self forcesSuperviewHeight])
			return optimalSize;
	}
		
	NSArray* sizesData = [self computeSizesForWidth:widthWithMarginAndBorder];
	CGFloat colWidth[colsCount];
	for (NSUInteger i = 0; i < colsCount; ++i)
		colWidth[i] = [[[sizesData objectAtIndex:0] objectAtIndex:i] floatValue];
	NSSize sizes[rowsCount][colsCount];
	CGFloat rowHeights[rowsCount];
	for (NSUInteger r = 0; r < rowsCount; ++r) {
		NSArray* rowsizes = [[sizesData objectAtIndex:1] objectAtIndex:r];
		rowHeights[r] = 0;
		for (NSUInteger i = 0; i < colsCount; ++i) {
			sizes[r][i] = [[rowsizes objectAtIndex:i] sizeValue];
			rowHeights[r] = std::max(rowHeights[r], sizes[r][i].height);
		}
	}
	
	// sum up sizes
	
	CGFloat y = _margin.origin.y;
	CGFloat maxX = 0;
	for (NSInteger r = rowsCount-1; r >= 0; --r) {
		NSArray* row = [_rows objectAtIndex:r];
		
		CGFloat x = _margin.origin.x;
		NSUInteger colNumber = 0;
		for (N2CellDescriptor* cell in row) {
			NSUInteger span = [cell colSpan];
			CGFloat spannedWidth = -_separation.width;
			for (NSUInteger i = colNumber; i < colNumber+span; ++i)
				spannedWidth += colWidth[i]+_separation.width;

			x += spannedWidth+_separation.width;
			colNumber += span;
		}
		x += _margin.size.width-_margin.origin.x - _separation.width;
		
		maxX = std::max(maxX, x);
		y += rowHeights[r]+_separation.height;
	}
	y += _margin.size.height-_margin.origin.y - _separation.height;	
	
	return n2::ceil(NSMakeSize(maxX, y));
}

-(NSSize)optimalSize {
	return [self optimalSizeForWidth:CGFLOAT_MAX];
}

#pragma mark Deprecated

-(NSArray*)lineAtIndex:(NSUInteger)index {
	return [self rowAtIndex:index];
}

-(NSUInteger)appendLine:(NSArray*)line {
	return [self appendRow:line];
}

-(void)insertLine:(NSArray*)line atIndex:(NSUInteger)index {
	[self insertRow:line atIndex:index];
}

-(void)removeLineAtIndex:(NSUInteger)index {
	[self removeRowAtIndex:index];
}

-(void)removeAllLines {
	[self removeAllRows];
}

@end
