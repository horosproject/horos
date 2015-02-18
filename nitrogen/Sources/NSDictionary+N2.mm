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
