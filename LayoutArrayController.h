//
//  LayoutArrayController.h
//  OsiriX
//
//  Created by Lance Pysher on 1/10/07.
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


// LayoutArrayController manages the Layout sets in the hanging Protocol

#import <Cocoa/Cocoa.h>

@class LayoutWindowController;

@interface LayoutArrayController : NSArrayController {
	LayoutWindowController *layoutWindowController;
	IBOutlet NSTableView *layoutTableView;
}

- (IBAction)addDeleteAction:( id)sender;
- (NSArray *)viewers;
- (IBOutlet)openLayout:(id)sender;


@end
