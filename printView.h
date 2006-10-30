//
//  printView.h
//  OsiriX
//
//  Created by Antoine Rosset on 29.10.06.
//  Copyright 2006 OsiriX. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"

@interface printView : NSView
{
	ViewerController		*viewer;
	NSDictionary			*settings;
	NSArray					*filesToPrint;
}

- (id)initWithViewer:(ViewerController*) v settings:(NSDictionary*) s files:(NSArray*) f;

@end
