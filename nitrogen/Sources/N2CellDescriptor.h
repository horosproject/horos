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

#import <Cocoa/Cocoa.h>
#import "N2MinMax.h"
#import "N2Alignment.h"

@interface N2CellDescriptor : NSObject {
	NSView* _view;
	N2Alignment _alignment;
	N2MinMax _widthConstraints;
	CGFloat _invasivity;
//	NSUInteger _rowSpan;
	NSUInteger _colSpan;
	BOOL _filled;
}

@property(retain) NSView* view;
@property N2Alignment alignment;
@property N2MinMax widthConstraints;
//@property NSUInteger rowSpan;
@property NSUInteger colSpan;
@property CGFloat invasivity;
@property BOOL filled;

+(N2CellDescriptor*)descriptor;
+(N2CellDescriptor*)descriptorWithView:(NSView*)view;
+(N2CellDescriptor*)descriptorWithWidthConstraints:(const N2MinMax&)widthConstraints;
+(N2CellDescriptor*)descriptorWithWidthConstraints:(const N2MinMax&)widthConstraints alignment:(N2Alignment)alignment;

-(N2CellDescriptor*)view:(NSView*)view;
-(N2CellDescriptor*)alignment:(N2Alignment)alignment;
-(N2CellDescriptor*)widthConstraints:(const N2MinMax&)widthConstraints;
//-(N2CellDescriptor*)rowSpan:(NSUInteger)rowSpan;
-(N2CellDescriptor*)colSpan:(NSUInteger)colSpan;
-(N2CellDescriptor*)invasivity:(CGFloat)invasivity;
-(N2CellDescriptor*)filled:(BOOL)filled;

-(NSSize)optimalSize;
-(NSSize)optimalSizeForWidth:(CGFloat)width;
-(NSRect)sizeAdjust;

#pragma mark Deprecated
-(N2CellDescriptor*)initWithWidthConstraints:(const N2MinMax&)widthConstraints alignment:(N2Alignment)alignment DEPRECATED_ATTRIBUTE;

@end

@interface N2ColumnDescriptor : N2CellDescriptor
@end
