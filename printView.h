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
	id						viewer;
	NSDictionary			*settings;
	NSArray					*filesToPrint;
	int						columns;
	int						rows;
	int						ipp;
	float					headerHeight;

}

- (id)initWithViewer:(id) v settings:(NSDictionary*) s files:(NSArray*) f;

@end
