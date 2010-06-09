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


@interface AnonymizationTemplateNamePanelController : NSWindowController {
	IBOutlet NSTextField* nameField;
	IBOutlet NSButton* okButton;
	IBOutlet NSButton* cancelButton;
	NSArray* replaceValues;
}

@property(readonly) NSTextField* nameField;
@property(readonly) NSButton* okButton;
@property(readonly) NSButton* cancelButton;
@property(retain) NSArray* replaceValues;

-(id)initWithReplaceValues:(NSArray*)values;

-(NSString*)value;

-(IBAction)okButtonAction:(id)sender;
-(IBAction)cancelButtonAction:(id)sender;

@end
