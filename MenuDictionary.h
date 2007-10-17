//
//  MenuDictionary.h
//  Annotation
//
//  Created by ibook on 2006-12-26.
//  Copyright 2006 jacques.fauquex@opendicom.com All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "NSMenu.h"


/** \brief MenuDictionary category used to modify contextual menus */
@interface NSMenu (MenuDictionary)
- (NSMenu*)initWithTitle:(NSString *)aTitle withDictionary:(NSDictionary *)aDictionary forWindowController:(NSWindowController *)aWindowController;

@end
