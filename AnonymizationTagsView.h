//
//  AnonymizationTagsView.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/25/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DCMAttributeTag, AnonymizationViewController, AnonymizationTagsPopUpButton;

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

-(NSButton*)checkBoxForTag:(DCMAttributeTag*)tag;
-(NSTextField*)textFieldForTag:(DCMAttributeTag*)tag;

@end
