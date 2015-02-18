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

#import <Cocoa/Cocoa.h>
#import "DCMObject.h"

/** DCMObject category for dealing with Presentation States */
@interface   DCMObject (DCMPresentationState) 

- (BOOL)isPresentationState;

//- (NSArray *)referencedImageSequenceForObject:(DCMObject *)object;

- (NSArray *)graphicObjectSequence;
- (NSArray *)displayedAreaSelectionSequence;
- (NSArray *)graphicLayerSequence;
- (NSArray *)softcopyVOILUTSequence;
- (int)imageRotation;
- (BOOL)horizontalFlip;

// anchor Point
- (NSPoint)anchorPointForGraphicsObject:(DCMObject *)object;
- (BOOL)anchorPointVisibiltyForGraphicsObject:(DCMObject *)object;
- (BOOL)anchorPointAnnotationUnitsIsPixelForGraphicsObject:(DCMObject *)object;

//BoundingBox
- (NSPoint)boundingBoxTopLeftHandCornerForObject:(DCMObject *)object;
- (NSPoint)boundingBoxBottomRightHandCornerForObject:(DCMObject *)object;

/**Justification Values
*	LEFT
*	RIGHT
*	CENTER
*/
- (NSString *)boundingBoxTextHorizontalJustificationForObject:(DCMObject *)object;


//** graphic annotation sequence info */
- (NSArray *)graphicAnnotationSequence;
- (NSArray *)textObjectSequenceForObject:(DCMObject *)object;
- (NSArray *)graphicObjectSequenceForObject:(DCMObject *)object;
- (NSString *)unformattedTextValueForObject:(DCMObject *)object;
- (int)numberOfGraphicPointsForGraphicsObject:(DCMObject *)object;
- (NSArray *)graphicDataForGraphicsObject:(DCMObject *)object;

//graphic layer module attributes
// do nothing for now.

/** DICOM graphic types
* POINT 
* POLYLINE 
* INTERPOLATED 
* CIRCLE 
* ELLIPSE 
*/
- (NSString *)graphicTypeForGraphicsObject:(DCMObject *)object;
- (BOOL)graphicFilledForGraphicsObject:(DCMObject *)object;

//MODALITY LUT MODULE ATTRIBUTES 
/*
rescaleSlope
rescaleintercpet
LUT Data
Modality LUT Type
*/

//VOI LUT module 
/*
LUT Descriptor 
LUTData
windowCenter
windowWidth
*/





@end
