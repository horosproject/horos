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


#import <Foundation/Foundation.h>


/** \brief Tree node for xml */
@interface dicomData: NSObject {
    NSString        *group;
    NSString        *name;
    NSString        *tagName;
    NSString        *content;
    
    NSMutableArray  *parent;
    NSMutableArray  *child;
	dicomData		*parentData;
}

- (dicomData*) parentData;
- (void) setParentData:(dicomData*) p;

- (NSMutableArray*) parent;
- (void) setParent:(NSMutableArray*) p;

- (NSMutableArray*) child;
- (void) setChild:(NSMutableArray*) p;

- (NSString*) group;
- (void) setGroup:(NSString *) s;

- (NSString*) name;
- (void) setName:(NSString *) s;

- (NSString*) tagName;
- (void) setTagName:(NSString *) s;

- (NSString*) content;
- (void) setContent:(NSString *) s;

@end