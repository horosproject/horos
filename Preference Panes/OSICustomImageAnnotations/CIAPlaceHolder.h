/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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

@class CIAAnnotation;

typedef enum {CIAPlaceHolderAlignLeft, CIAPlaceHolderAlignCenter, CIAPlaceHolderAlignRight} CIAPlaceHolderAlignement;
typedef enum {CIAPlaceHolderOrientationWidgetTop, CIAPlaceHolderOrientationWidgetBottom} CIAPlaceHolderOrientationWidgetPosition;

@interface CIAPlaceHolder : NSView  {
	BOOL hasFocus;
	NSMutableArray *annotationsArray;
	NSSize animatedFrameSize;
	CIAPlaceHolderAlignement align;
	CIAPlaceHolderOrientationWidgetPosition orientationWidgetPosition;
}

+ (NSSize)defaultSize;
- (BOOL)hasFocus;
- (void)setHasFocus:(BOOL)boo;
- (BOOL)hasAnnotations;
- (void)removeAnnotation:(CIAAnnotation*)anAnnotation;
- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index animate:(BOOL)animate;
- (void)insertAnnotation:(CIAAnnotation*)anAnnotation atIndex:(int)index;
- (void)addAnnotation:(CIAAnnotation*)anAnnotation animate:(BOOL)animate;
- (void)addAnnotation:(CIAAnnotation*)anAnnotation;
- (BOOL)containsAnnotation:(CIAAnnotation*)anAnnotation;
- (NSMutableArray*)annotationsArray;
- (void)alignAnnotations;
- (void)alignAnnotationsWithAnimation:(BOOL)animate;
- (void)updateFrameAroundAnnotations;
- (void)updateFrameAroundAnnotationsWithAnimation:(BOOL)animate;
- (void)setAnimatedFrameSize:(NSSize)size;
- (void)setAlignment:(CIAPlaceHolderAlignement)alignement;
- (void)setOrientationWidgetPosition:(CIAPlaceHolderOrientationWidgetPosition)pos;

@end
