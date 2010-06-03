//
//  AnonymizationTagsPopUpButton.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/25/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DCMAttributeTag;

@interface AnonymizationTagsPopUpButton : NSPopUpButton {
	DCMAttributeTag* selectedTag;
}

+(NSMenu*)tagsMenu;
+(NSMenu*)tagsMenuWithTarget:(id)obj action:(SEL)action;

@property(retain) DCMAttributeTag* selectedTag;

@end
