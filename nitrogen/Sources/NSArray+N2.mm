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

#import "NSArray+N2.h"

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

@implementation NSArray (N2)

- (id)deepMutableCopy
{
    return (copy(self));
}

-(NSArray*)splitArrayIntoArraysOfMinSize:(NSUInteger)minSize maxArrays:(NSUInteger)maxArrays {
	NSMutableArray* chunks = [NSMutableArray array];
	
	for (NSValue* rangeValue in [self splitArrayIntoChunksOfMinSize:minSize maxChunks:maxArrays]) 
        [chunks addObject:[self subarrayWithRange:[rangeValue rangeValue]]];
	
	return chunks;
}

-(NSArray*)splitArrayIntoChunksOfMinSize:(NSUInteger)minSize maxChunks:(NSUInteger)maxChunks {
	NSUInteger count = self.count, size = maxChunks? MAX(minSize, round(float(count)/maxChunks)) : minSize;
	
	NSMutableArray* chunks = [NSMutableArray array];
	
	NSRange range = NSMakeRange(0, size);
	NSUInteger i = 0;
	do {
		if (++i == maxChunks)
			range.length = count-range.location;
		else if (range.location+range.length > count)
            range.length = count-range.location;
		[chunks addObject:[NSValue valueWithRange:range]];
        range.location += range.length;
	} while (range.location < count);
	
	return chunks;
}

@end

@implementation NSMutableArray (N2)

-(void)addUniqueObjectsFromArray:(NSArray*)array {
    for (id obj in array)
        if (![self containsObject:obj])
            [self addObject:obj];
}

@end