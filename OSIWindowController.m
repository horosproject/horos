//
//  OSIWindowController.m
//  OsiriX
//
//  Created by Lance Pysher on 12/11/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "OSIWindowController.h"
#import "WindowLayoutManager.h"

@implementation OSIWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName{
	if (self = [super initWithWindowNibName:(NSString *)windowNibName]) {
		// Register with WindowLayoutManager
		[[WindowLayoutManager sharedWindowLayoutManager] registerWindowController:self];
	 // do what OsiriX needs to do for window Controllers
	 
	}
	return self;
}

- (void)dealloc{
	[super dealloc];
}

- (NSMutableArray*) pixList{
	// let subclasses handle it for now
	return nil;
}

- (void)windowWillClose:(NSNotification *)notification{
	[[WindowLayoutManager sharedWindowLayoutManager] unregisterWindowController:self];
}

- (int)blendingType{
	return _blendingType;
}

@end
