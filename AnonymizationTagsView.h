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


@class DCMAttributeTag, AnonymizationViewController, AnonymizationTagsPopUpButton, N2TextField;

@interface AnonymizationTagsView : NSView {
	NSMutableArray* viewGroups;
	NSSize intercellSpacing, cellSize;
	IBOutlet AnonymizationViewController* anonymizationViewController;
	AnonymizationTagsPopUpButton* dcmTagsPopUpButton;
	NSButton* dcmTagAddButton;
}

-(void)addTag:(DCMAttributeTag*)tag;
-(void)removeTag:(DCMAttributeTag*)tag;
-(NSSize)idealSize;

-(NSButton*)checkBoxForObject:(id)object;
-(N2TextField*)textFieldForObject:(id)object;

@end
