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

#import "DCMPresentationState.h"
#import "DCMAbstractSyntaxUID.h"
#import "DCM.h"


@implementation  DCMObject (DCMPresentationState) 

- (BOOL)isPresentationState{
	return [DCMAbstractSyntaxUID isPresentationState:[self attributeValueWithName:@"SOPClassUID"]];
}

- (NSArray *)graphicAnnotationSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"GraphicAnnotationSequence"] sequenceItems];
}

- (NSArray *)graphicObjectSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"GraphicObjectSequence"] sequenceItems];
}

- (NSArray *)displayedAreaSelectionSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"DisplayedAreaSelectionSequence"] sequenceItems];
}

- (NSArray *)graphicLayerSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"GraphicLayerSequence"] sequenceItems];
}

- (NSArray *)softcopyVOILUTSequence{
	return [(DCMSequenceAttribute *)[self attributeWithName:@"SoftcopyVOILUTSequence"] sequenceItems];
}

- (int)imageRotation{
	return [[self attributeValueWithName:@"ImageRotation"] intValue];
}

- (BOOL)horizontalFlip{
	return [[self attributeValueWithName:@"ImageHorizontalFlip"] isEqualToString:@"Y"];
}

// anchor Point
- (NSPoint)anchorPointForGraphicsObject:(DCMObject *)object{
	// should be two floating point values
	NSArray *point = [[object attributeWithName:@"AnchorPoint"] values];
	if ([point count] == 2)
		return NSMakePoint([[point objectAtIndex:0] floatValue],[[point objectAtIndex:1] floatValue]);
	return NSMakePoint(0.0, 0.0);
}

- (BOOL)anchorPointVisibiltyForGraphicsObject:(DCMObject *)object{
	return [[object attributeValueWithName:@"AnchorPointVisibility"] isEqualToString:@"Y"];
}

- (BOOL)anchorPointAnnotationUnitsIsPixelForGraphicsObject:(DCMObject *)object{
	return [[object attributeValueWithName:@"AnchorPointAnnotationUnits"] isEqualToString:@"PIXEL"];
}

//BoundingBox
- (NSPoint)boundingBoxTopLeftHandCornerForObject:(DCMObject *)object{
	NSArray *point = [[object attributeWithName:@"BoundingBoxTopLeftHandCorner"] values];
	if ([point count] == 2)
		return NSMakePoint([[point objectAtIndex:0] floatValue],[[point objectAtIndex:1] floatValue]);
	return NSMakePoint(0.0, 0.0);
}

- (NSPoint)boundingBoxBottomRightHandCornerForObject:(DCMObject *)object{
	NSArray *point = [[object attributeWithName:@"BoundingBoxBottomRightHandCorner"] values];
	if ([point count] == 2)
		return NSMakePoint([[point objectAtIndex:0] floatValue],[[point objectAtIndex:1] floatValue]);
	return NSMakePoint(0.0, 0.0);
}

- (NSString *)boundingBoxTextHorizontalJustificationForObject:(DCMObject *)object{
	return [object attributeValueWithName:@"BoundingBoxTextHorizontalJustification"];
}

//graphic annotation sequence info

- (NSArray *)textObjectSequenceForObject:(DCMObject *)object{
	return [(DCMSequenceAttribute *)[object attributeWithName:@"TextObjectSequence"] sequenceItems];
}

- (NSArray *)graphicObjectSequenceForObject:(DCMObject *)object{
	return [(DCMSequenceAttribute *)[object attributeWithName:@"GraphicObjectSequence"] sequenceItems];
}

- (NSString *)unformattedTextValueForObject:(DCMObject *)object{	
	return [object attributeValueWithName:@"UnformattedTextValue"];
}

- (int)numberOfGraphicPointsForGraphicsObject:(DCMObject *)object{
	return [[object attributeValueWithName:@"NumberofGraphicPoints"] intValue];
}

- (NSArray *)graphicDataForGraphicsObject:(DCMObject *)object{
	return [[object attributeWithName:@"GraphicData"] values];
}

- (NSString *)graphicTypeForGraphicsObject:(DCMObject *)object{
	return [object attributeValueWithName:@"GraphicType"];
}

- (BOOL)graphicFilledForGraphicsObject:(DCMObject *)object{
	return [[object attributeValueWithName:@"GraphicFilled"] isEqualToString:@"Y"];
}


@end
