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

#import "NSMutableDictionary+N2.h"
#import "NSDictionary+N2.h"


@implementation NSMutableDictionary (N2)

-(void)removeObject:(id)obj {
	[self removeObjectForKey:[self keyForObject:obj]];
}

-(void)setBool:(BOOL)b forKey:(NSString*)key {
	[self setObject:[NSNumber numberWithBool:b] forKey:key];
}

@end
