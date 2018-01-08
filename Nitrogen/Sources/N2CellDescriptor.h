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

#import <Cocoa/Cocoa.h>
#import "N2MinMax.h"
#import "N2Alignment.h"

__deprecated
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

__deprecated
@interface N2ColumnDescriptor : N2CellDescriptor
@end
