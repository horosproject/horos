//
//  ShadingArrayController.h
//  OsiriX
//
//  Created by Lance Pysher on 4/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ShadingArrayController : NSArrayController {
	BOOL _enableEditing;
}

- (BOOL)enableEditing;
- (void)setEnableEditing:(BOOL)enable;

@end
