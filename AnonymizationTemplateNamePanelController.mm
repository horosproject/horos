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

#import "AnonymizationTemplateNamePanelController.h"


@implementation AnonymizationTemplateNamePanelController

@synthesize nameField;
@synthesize okButton;
@synthesize cancelButton;
@synthesize replaceValues;

-(void)observeTextDidChangeNotification:(NSNotification*)notif {
	if ([self.replaceValues containsObject:self.nameField.stringValue])
		self.okButton.title = NSLocalizedString(@"Replace", NULL);
	else self.okButton.title = NSLocalizedString(@"Save", NULL);
	[self.okButton setEnabled:self.nameField.stringValue.length > 0 ];
}

-(id)initWithReplaceValues:(NSArray*)values {
	self = [super initWithWindowNibName:@"AnonymizationTemplateNamePanel"];
	[self window]; // load
	
	self.replaceValues = values;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTextDidChangeNotification:) name:NSControlTextDidChangeNotification object:self.nameField];
	[self observeTextDidChangeNotification:NULL];
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.nameField];
	self.replaceValues = NULL;
	[super dealloc];
}

-(NSString*)value {
	return self.nameField.stringValue;
}

-(IBAction)okButtonAction:(id)sender {
	[NSApp endSheet:self.window];
}

-(IBAction)cancelButtonAction:(id)sender {
	[NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

@end
