/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import "MutableArrayCategory.h"

NSInteger sortByAddress(id roi1, id roi2, void *context)
{
   if( roi1 > roi2) return NSOrderedDescending;
   else if( roi1 < roi2) return NSOrderedAscending;
   else return NSOrderedSame;
}

@implementation NSArray (ArrayCategory)

#define ExperimentalShuffle

#ifdef ExperimentalShuffle

- (NSArray*)shuffledArray {
    NSArray* finalArray;
    int i, count=[self count];
    id* buff=malloc(count*sizeof(id));
    if (!buff) return nil;
    [self getObjects:buff];
    for (i=count-1; i > 0; i--) {
        int newPos=(rand() / (RAND_MAX / i + 1));
        id temp=buff[i];
        buff[i]=buff[newPos];
        buff[newPos]=temp;
    }
    finalArray=[NSArray arrayWithObjects:buff count:count];
    free(buff);
    return finalArray;
}
#else
- (NSArray*)shuffledArray {
    NSArray* finalArray;
    int i, count=[self count];
    id* buff=malloc(count*sizeof(id));
    if (!buff) return nil;
    [self getObjects:buff];
    for (i=0; i < count; i++) {
        int newPos=(rand() / (RAND_MAX / count + 1));
        id temp=buff[i];
        buff[i]=buff[newPos];
        buff[newPos]=temp;
    }
    finalArray=[NSArray arrayWithObjects:buff count:count];
    free(buff);
    return finalArray;
}
#endif


@end

@implementation NSMutableArray (MutableArrayCategory) 

- (void)mergeWithArray:(NSArray*)array {
    NSRange searchRange=NSMakeRange(0, [self count]);
    for (id object in array) {
        NSInteger index=[self indexOfObject:object inRange:searchRange];
        if (index == NSNotFound) [self addObject:object];
    }
}

- (void) removeDuplicatedObjects
{
    @autoreleasepool {
        NSArray *a = [self sortedArrayUsingFunction: sortByAddress context: 0];
        
        id lastObject = nil;
        
        for( id s in a)
        {
            if( s == lastObject)
                [self removeObjectAtIndex: [self indexOfObject: s]];
            else lastObject = s;
        }
    }
}

- (void) removeDuplicatedStrings
{
    @autoreleasepool {
        NSArray *a = [self sortedArrayUsingSelector: @selector(compare:)];
        
        NSString *lastString = nil;
        
        for( NSString *s in a)
        {
            if( [s isKindOfClass:[NSString class]] && [s isEqualToString: lastString])
                [self removeObjectAtIndex: [self indexOfObject: s]];
            else lastString = s;
        }
    }
}

- (void) removeDuplicatedStringsInSyncWithThisArray: (NSMutableArray*) otherArray
{
	NSArray *a = [self sortedArrayUsingSelector: @selector(compare:)];
	
	NSString *lastString = nil;
	
	for( NSString *s in a)
	{
		if( [s isKindOfClass:[NSString class]] && [s isEqualToString: lastString])
		{
			NSUInteger index = [self indexOfObject: s];
            if( index != NSNotFound)
            {
                [self removeObjectAtIndex: index];
                [otherArray removeObjectAtIndex: index];
            }
		}
		else lastString = s;
	}
}

- (BOOL)containsString:(NSString *)string
{
	for( id object in self)
	{
		if ([object isKindOfClass:[NSString class]] && [object isEqualToString:string])
				return YES;
	}

	return NO;
}

#ifdef ExperimentalShuffle

- (void)shuffle {
    int i, max=[self count];
    for (i=max-1; i > 0; i--) {
        int newPos=(rand() / (RAND_MAX / i + 1));
        id temp=[[self objectAtIndex:i] retain];
        [self replaceObjectAtIndex:i withObject:[self objectAtIndex:newPos]];
        [self replaceObjectAtIndex:newPos withObject:temp];
        [temp release];
    }
}
#else

- (void)shuffle {
    int i, count=[self count];
    for (i=0; i < count; i++) {
        int newPos=(rand() / (RAND_MAX / count + 1));
        id temp=[[self objectAtIndex:i] retain];
        [self replaceObjectAtIndex:i withObject:[self objectAtIndex:newPos]];
        [self replaceObjectAtIndex:newPos withObject:temp];
        [temp release];
    }
}

#endif

@end
