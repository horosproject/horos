//
//  MenuDictionary.m
//  Annotation
//
//  Created by ibook on 2006-12-26.
//  Copyright 2006 jacques.fauquex@opendicom.com All rights reserved.
//

#import "MenuDictionary.h"


@implementation NSMenu (MenuDictionary)

- (NSMenu*)initWithTitle:(NSString *)aTitle withDictionary:(NSDictionary *)aDictionary forWindowController:(NSWindowController *)aWindowController
{
	//NSMenu
	[self initWithTitle:aTitle];
			
	//NSDictionary -> array
	long dictionaryCount =[aDictionary count];
	NSMutableArray *keysListed = [NSMutableArray arrayWithCapacity:dictionaryCount];
	NSEnumerator *keyLister = [aDictionary keyEnumerator];
	id key;
	while ((key = [keyLister nextObject])) { [keysListed addObject:(NSString *)key]; }			
	[keysListed sortUsingSelector:@selector(compare:)];// -> ordered array

	// NSMenuItem obtained by looping NSDictionary
	NSMenuItem *item;
	int i;
			for( i = 0 ; i < dictionaryCount ; i++ )
			{
				//separate prefix, title and sufix
				NSArray *prefixTitle = [[keysListed objectAtIndex:i] componentsSeparatedByString:@"@"];
				//selector requires a valid method of Target. Else, at runtime the menu is grayed out
				item = [[NSMenuItem alloc] initWithTitle:[prefixTitle objectAtIndex:1] action: @selector(contextualMenuEvent:) keyEquivalent:@""];
				[item setTag:(int)[prefixTitle objectAtIndex:0]];
				[item setTarget:aWindowController];
				
// item dictionary (regresive logics)
				if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSDictionary class]])
				{
					if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] count] > 0)
						[item setSubmenu:[[NSMenu alloc] initWithTitle:[prefixTitle objectAtIndex:1] withDictionary:[aDictionary objectForKey:[keysListed objectAtIndex:i]] forWindowController:aWindowController]];
				}
// item array
				else if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSArray class]])
				{

				}
// item string
				else if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSString class]])
				{

				}
// item number
				else if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSNumber class]])
				{

				}
// item date
				else if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSDate class]])
				{

				}
// item data
				else if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSData class]])
				{

				}
				
				[self addItem:item]; //adding the completed submenu, created during regression
				[item release];
			}
	return self;
}

@end
