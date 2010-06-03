//
//  AnonymizationCustomTagPanelController.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCMAttributeTag;

@interface AnonymizationCustomTagPanelController : NSWindowController {
	IBOutlet NSTextField* groupField;
	IBOutlet NSTextField* elementField;
}

-(IBAction)cancelButtonAction:(id)sender;
-(IBAction)okButtonAction:(id)sender;

@property(assign) DCMAttributeTag* attributeTag;

@end
