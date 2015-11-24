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


#import "N2Layout.h"


@interface N2ColumnLayout : N2Layout {
	NSArray* _columnDescriptors;
	NSMutableArray* _rows;
}

-(id)initForView:(N2View*)view columnDescriptors:(NSArray*)columnDescriptors controlSize:(NSControlSize)controlSize;

-(NSArray*)rowAtIndex:(NSUInteger)index;
-(NSUInteger)appendRow:(NSArray*)row;
-(void)insertRow:(NSArray*)row atIndex:(NSUInteger)index;
-(void)removeRowAtIndex:(NSUInteger)index;
-(void)removeAllRows;

#pragma mark Deprecated

-(NSArray*)lineAtIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(NSUInteger)appendLine:(NSArray*)line DEPRECATED_ATTRIBUTE;
-(void)insertLine:(NSArray*)line atIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(void)removeLineAtIndex:(NSUInteger)index DEPRECATED_ATTRIBUTE;
-(void)removeAllLines DEPRECATED_ATTRIBUTE;

@end
