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
