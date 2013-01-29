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


@class N2AdaptiveBox, AnonymizationTagsView, DCMAttributeTag;

@interface AnonymizationViewController : NSViewController {
	IBOutlet N2AdaptiveBox* annotationsBox;
	IBOutlet NSPopUpButton* templatesPopup;
	IBOutlet AnonymizationTagsView* tagsView;
	IBOutlet NSButton* saveTemplateButton;
	IBOutlet NSButton* deleteTemplateButton;
	NSMutableArray* tags;
	BOOL formatsAreOk;
}

@property(readonly) N2AdaptiveBox* annotationsBox;
@property(readonly) NSPopUpButton* templatesPopup;
@property(readonly) AnonymizationTagsView* tagsView;
@property(readonly,retain) NSMutableArray* tags; // do not add elements directly! use addTag and removeTag
@property(readonly,nonatomic) BOOL formatsAreOk;

-(id)initWithTags:(NSArray*)shownDcmTags values:(NSArray*)values;

-(void)adaptBoxToAnnotations;
-(void)addTag:(DCMAttributeTag*)tag;
-(void)removeTag:(DCMAttributeTag*)tag;

-(NSArray*)tagsValues;
-(void)setTagsValues:(NSArray*)t;

-(IBAction)saveTemplateAction:(id)sender;
-(IBAction)deleteTemplateAction:(id)sender;

@end
