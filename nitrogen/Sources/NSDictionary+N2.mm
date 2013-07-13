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

static id copy(id obj)
{
    if ([obj isKindOfClass:[NSArray class]])
    {
        id temp = [obj mutableCopy];
        
        for (int i = 0 ; i < [temp count]; i++)
        {
            id copied = [copy([temp objectAtIndex:i]) autorelease];
            
            [temp replaceObjectAtIndex:i withObject: copied];
        }
        
        return temp;
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        NSMutableDictionary *temp = [obj mutableCopy];
        
        for( int i = 0; i < temp.allKeys.count; i++)
        {
            NSString *key = [temp.allKeys objectAtIndex: i];
            
            [temp setObject:[copy([temp objectForKey: key]) autorelease] forKey: key];
        }
        
        return temp;
    }
    
    return [obj copy];
}

@implementation NSDictionary (N2)

- (id)deepMutableCopy
{
    return (copy(self));
}

-(id)objectForKey:(id)key ofClass:(Class)cl {
	id obj = [self objectForKey:key];
	if (obj && ![obj isKindOfClass:cl])
		[NSException raise:NSGenericException format:@"%@ expected, actually %@", [[NSClassDescription classDescriptionForClass:cl] description], [obj className]];
	return obj;
}

-(id)keyForObject:(id)obj {
	for (id key in self)
		if ([self objectForKey:key] == obj)
			return key;
	return NULL;
}

@end
