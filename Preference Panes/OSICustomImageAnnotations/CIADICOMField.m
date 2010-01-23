/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "CIADICOMField.h"


@implementation CIADICOMField

- (id)initWithGroup:(int)g element:(int)e name:(NSString*)n;
{
	self = [self init];
	group = g;
	element = e;
	name = [n retain];
	return self;
}

- (void)dealloc
{
	[name release];
	[super dealloc];
}

- (int)group;
{
	return group;
}

- (int)element;
{
	return element;
}

- (NSString*)name;
{
	return name;
}

- (NSString*)title;
{
	return [NSString stringWithFormat:@"(0x%04x,0x%04x) %@", group, element, name];
}

- (NSString *)description;
{
	return [self title];
}

@end
