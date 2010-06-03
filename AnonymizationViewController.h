//
//  AnonymizationWindowController.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class N2AdaptiveBox, AnonymizationTagsView, DCMAttributeTag;

@interface AnonymizationViewController : NSViewController {
	IBOutlet N2AdaptiveBox* annotationsBox;
	IBOutlet NSPopUpButton* templatesPopup;
	IBOutlet AnonymizationTagsView* tagsView;
	IBOutlet NSButton* saveTemplateButton;
	IBOutlet NSButton* deleteTemplateButton;
	NSMutableArray* tags;
}

@property(readonly) N2AdaptiveBox* annotationsBox;
@property(readonly) NSPopUpButton* templatesPopup;
@property(readonly) AnonymizationTagsView* tagsView;
@property(readonly,retain) NSMutableArray* tags; // do not add elements directly! use addTag and removeTag

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values;

-(void)adaptBoxToAnnotations;
-(void)addTag:(DCMAttributeTag*)tag;
-(void)removeTag:(DCMAttributeTag*)tag;

-(NSArray*)tagsValues;
-(void)setTagsValues:(NSArray*)t;

-(IBAction)saveTemplateAction:(id)sender;
-(IBAction)deleteTemplateAction:(id)sender;

@end
