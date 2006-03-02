//
//  RoutingArrayController.m
//  OSIRoutingPreferencePane
//
//  Created by Lance Pysher on 1/18/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "RoutingArrayController.h"


@implementation RoutingArrayController



- (void)awakeFromNib{
	NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:@"RoutingRules"];
	NSEnumerator *enumerator = [array objectEnumerator];
	NSDictionary *dict;
	NSMutableArray *content = [NSMutableArray array];
	while (dict = [enumerator nextObject]) {
		[content addObject:[NSMutableDictionary dictionaryWithDictionary:dict]];
	}
	[self setContent:content];
	[routingTable setDoubleAction:@selector(editRoute:)];
	[routingTable setTarget:self];
}

- (IBAction)newRoute:(id)sender{
	[self add:sender];
	[ruleWindow makeKeyAndOrderFront:sender];
}


- (void)addObject:(id)object{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:@"route Name" forKey:@"name"];
	[dictionary setValue:@"Server Description" forKey:@"Description"];
	[dictionary setValue:[NSMutableArray array] forKey:@"rules"];
	[super addObject:dictionary];

}

- (IBAction)editRoute:(id)sender{
	[ruleWindow makeKeyAndOrderFront:sender];
}

@end
