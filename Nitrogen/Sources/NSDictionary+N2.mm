/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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
