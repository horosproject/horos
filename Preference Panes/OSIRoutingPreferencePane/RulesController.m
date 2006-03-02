//
//  RulesController.m
//  OSIRoutingPreferencePane
//
//  Created by Lance Pysher on 1/20/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "RulesController.h"


@implementation RulesController

- (void)addObject:(id)object{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[super addObject:dictionary];
}

- (void)setContent:(id)content{
	NSEnumerator *enumerator = [content objectEnumerator];
	NSDictionary *dict;
	NSMutableArray *mutableContent = [NSMutableArray array];
	while (dict = [enumerator nextObject]) {
		[mutableContent addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
	}
	[super setContent:mutableContent];
}

@end
