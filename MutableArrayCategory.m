/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import "MutableArrayCategory.h"
//#import "iRad.h"
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

- (BOOL)containsString:(NSString *)string{

	NSEnumerator *enumerator = [self objectEnumerator];
	id object;
	while (object = [enumerator nextObject]) {
		if ([object isKindOfClass:[NSString class]]) {
			if ([object isEqualToString:string])
				return YES;
		}
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
