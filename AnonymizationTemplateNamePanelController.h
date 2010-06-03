//
//  AnonymizationTemplateNamePanelController.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/20/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

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
