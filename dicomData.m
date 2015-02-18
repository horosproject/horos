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


#import <dicomData.h>

@implementation dicomData

-(id) init
{
	self = [super init];
	
	group = Nil;
	name = Nil;
	tagName = Nil;
	content = Nil;
	parent = Nil;
	child = Nil;
	parentData = Nil;
	
	return self;
}

- (dicomData*) parentData
{
	return parentData;
}

- (void) setParentData:(dicomData*) p
{
	parentData = p;
}

- (NSMutableArray*) parent
{
    return parent;
}

- (void) setParent:(NSMutableArray*) p
{
    parent = p;
}

- (NSMutableArray*) child
{
    return child;
}

- (void) setChild:(NSMutableArray*) p
{
    child = p;
}

- (NSString*) group
{
    return group;
}

- (void) setGroup:(NSString *) s
{
    [s retain];
    [group release];
    group = s;
}

- (NSString*) name
{
    return name;
}

- (void) setName:(NSString *) s
{
    [s retain];
    [name release];
    name = s;
}

- (NSString*) tagName
{
    return tagName;
}

- (void) setTagName:(NSString *) s
{
    [s retain];
    [tagName release];
    tagName = s;
}

- (NSString*) content
{
    return content;
}

- (void) setContent:(NSString *) s
{
    [s retain];
    [content release];
    content = s;
}
@end