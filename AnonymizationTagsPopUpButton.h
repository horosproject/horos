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

#import <Cocoa/Cocoa.h>


@class DCMAttributeTag;

@interface AnonymizationTagsPopUpButton : NSPopUpButton {
	DCMAttributeTag* selectedTag;
}

+(NSMenu*)tagsMenu;
+(NSMenu*)tagsMenuWithTarget:(id)obj action:(SEL)action;

@property(retain,nonatomic) DCMAttributeTag* selectedTag;

@end
