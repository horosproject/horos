//
//  RoutingArrayController.h
//  OSIRoutingPreferencePane
//
//  Created by Lance Pysher on 1/18/06.

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

#import <Cocoa/Cocoa.h>


@interface RoutingArrayController : NSArrayController {
	 IBOutlet NSWindow *ruleWindow;
	 IBOutlet NSTableView *routingTable;
}

- (IBAction)newRoute: (id)sender;
- (IBAction)editRoute:(id)sender;

@end
