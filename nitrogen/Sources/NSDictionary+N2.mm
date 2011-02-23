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


#import "NSDictionary+N2.h"


@implementation NSDictionary (N2)

-(id)objectForKey:(id)key ofClass:(Class)cl {
	id obj = [self objectForKey:key];
	if (obj && ![obj isKindOfClass:cl])
		[NSException raise:NSGenericException format:@"%s expected, actually %@", [[NSClassDescription classDescriptionForClass:cl] description], [obj className]];
	return obj;
}

-(id)keyForObject:(id)obj {
	for (id key in self)
		if ([self objectForKey:key] == obj)
			return key;
	return NULL;
}

@end
