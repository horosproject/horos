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
