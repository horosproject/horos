/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/


#import "MenuDictionary.h"


@implementation NSMenu (MenuDictionary)

- (NSMenu*)initWithTitle:(NSString *)aTitle withDictionary:(NSDictionary *)aDictionary forWindowController:(NSWindowController *)aWindowController
{
	//NSMenu
	self = [self initWithTitle:aTitle];
			
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
				item = [[[NSMenuItem alloc] initWithTitle:[prefixTitle objectAtIndex:1] action: @selector(contextualMenuEvent:) keyEquivalent:@""] autorelease];
				[item setTag: (NSInteger) [prefixTitle objectAtIndex:0]];
				[item setTarget:aWindowController];
				
// item dictionary (regresive logics)
				if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] isKindOfClass:[NSDictionary class]])
				{
					if ([[aDictionary objectForKey:[keysListed objectAtIndex:i]] count] > 0)
						[item setSubmenu: [[[NSMenu alloc] initWithTitle:[prefixTitle objectAtIndex:1] withDictionary:[aDictionary objectForKey:[keysListed objectAtIndex:i]] forWindowController:aWindowController] autorelease]];
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
			}
	return self;
}

@end
