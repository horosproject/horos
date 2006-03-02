/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <dicomData.h>

@implementation dicomData

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