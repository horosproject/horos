//
//  AnonymizationTemplateNamePanelController.mm
//  OsiriX
//
//  Created by Alessandro Volz on 5/20/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "AnonymizationTemplateNamePanelController.h"


@implementation AnonymizationTemplateNamePanelController

@synthesize nameField;
@synthesize okButton;
@synthesize cancelButton;
@synthesize replaceValue;

-(void)observeTextDidChangeNotification:(NSNotification*)notif {
	if ([self.nameField.stringValue isEqual:self.replaceValue])
		self.okButton.title = NSLocalizedString(@"Replace", NULL);
	else self.okButton.title = NSLocalizedString(@"Save", NULL);
}

-(id)initWithReplaceValue:(NSString*)value {
	self = [super initWithWindowNibName:@"AnonymizationTemplateNamePanel"];
	self.window; // load
	
	self.replaceValue = value;
	if (value) [self.nameField setStringValue:value];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeTextDidChangeNotification:) name:NSControlTextDidChangeNotification object:self.nameField];
	[self observeTextDidChangeNotification:NULL];
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.nameField];
	self.replaceValue = NULL;
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
