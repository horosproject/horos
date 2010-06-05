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
	NSString* replaceValue;
}

@property(readonly) NSTextField* nameField;
@property(readonly) NSButton* okButton;
@property(readonly) NSButton* cancelButton;
@property(retain) NSString* replaceValue;

-(id)initWithReplaceValue:(NSString*)value;

-(NSString*)value;

-(IBAction)okButtonAction:(id)sender;
-(IBAction)cancelButtonAction:(id)sender;

@end
