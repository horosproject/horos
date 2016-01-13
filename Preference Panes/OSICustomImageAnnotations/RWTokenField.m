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

#import "RWTokenField.h"


@interface NSTokenFieldCell (UndocumentedMethods)

- (void)_string:(id)fp8 tokenizeIndex:(int)fp12 inTextStorage:(id)fp16;

@end

@interface RWTokenFieldCell: NSTokenFieldCell
@end


//***************************************************************************

@implementation RWTokenFieldCell
//
//+ (void) load
//{
//	[RWTokenFieldCell poseAsClass:[NSTokenFieldCell class]];
//}
//
//- (void)_string:(id)fp8 tokenizeIndex:(int)fp12 inTextStorage:(id)fp16
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	[super _string:fp8 tokenizeIndex:fp12 inTextStorage:fp16];
//
//	if(![[self controlView] respondsToSelector:@selector(tokenFieldCellDidTokenizeString)]) return;
//	
//	[[self controlView] performSelector:@selector(tokenFieldCellDidTokenizeString) withObject:self];
//}
//
//- (void) setObjectValue:(id<NSCopying>)object
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	[super setObjectValue:object];
//	
//	if(![[self controlView] respondsToSelector:@selector(tokenFieldCellDidTokenizeString)]) return;
//	
//	[[self controlView] performSelector:@selector(tokenFieldCellDidTokenizeString) withObject:self];
//}

@end

//***************************************************************************

@implementation RWTokenField

//+ (void) load
//{
//	[RWTokenField poseAsClass:[NSTokenField class]];
//}
//
//- (void) tokenFieldCellDidTokenizeString:(NSTokenFieldCell*)tokenFieldCell
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	NSDictionary* valueBindingInformation = [self infoForBinding:@"value"];
//	if(valueBindingInformation != nil)
//	{
//		id valueBindingObject = [valueBindingInformation objectForKey:NSObservedObjectKey];
//		NSString* valueBindingKeyPath = [valueBindingInformation objectForKey:NSObservedKeyPathKey];
//		
//		[valueBindingObject setValue:[self objectValue] forKeyPath:valueBindingKeyPath];
//	}
//	
//	[self sendAction:[self action] to:[self target]];
//
//	if([[self delegate] respondsToSelector:@selector(tokenFieldDidTokenizeString:)])
//	{
//		[[self delegate] performSelector:@selector(tokenFieldDidTokenizeString:) withObject:self];
//	}
//}
//
//- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	NSLog(@"concludeDragOperation");
//	[super concludeDragOperation:sender];
//}
//
//- (void)draggingEnded:(id <NSDraggingInfo>)sender
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	NSLog(@"draggingEnded");
//	[super draggingEnded:sender];
//}
//
//- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
//{
//	NSLog( @"*********** unsupported on 64-bit");
//	
//	NSLog(@"performDragOperation");
//	return [super performDragOperation:sender];
//}


@end