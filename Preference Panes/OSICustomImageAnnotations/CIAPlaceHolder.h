/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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
