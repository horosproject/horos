//
//  HotKeyArrayController.m
//  OSIHotKeysPreferencePane
//
//  Created by joris on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HotKeyArrayController.h"


@implementation HotKeyArrayController

//- (void)setContent:(id)content
//{
//	NSLog(@"OLA content : %@", content);
//	[super setContent:content];
//}
//
//- (void)setValue:(id)value forKey:(NSString *)key
//{
//	NSLog(@"setValue:%@ forKey:%@", value, key);
//	[super setValue:value forKey:key];
//}


- (void)didChangeValueForKey:(NSString *)key
{
	if( [key isEqualToString: @"isEditing"] && self.isEditing == NO)
	{
		NSArray *a = [self content];
		
		for( NSMutableDictionary *d in a)
		{
			for( NSMutableDictionary *c in a)
			{
				if( c != d)
				{
					if( [[c valueForKey:@"key"] isEqualToString: [d valueForKey:@"key"]])
					{
						NSMutableDictionary *e;
						if( [[self selectedObjects] containsObject: c])
							e = d;
						else
							e = c;
						[e setValue:@"" forKey:@"key"];
					}
				}
			}
		}
	}
	
	[super didChangeValueForKey:(NSString *)key];
}

- (id)arrangedObjects
{
	
	return [super arrangedObjects];
}

@end
