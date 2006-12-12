//
//  WindowLayoutManager.h
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

/*
The WindowLayoutManager class manages the various placement of the Viewers
primarily by use of hanging proctols and Advanced hanging protocols
and keeps track of the Viewer Related Window Controllers
It is a shared class.
 */

#import <Cocoa/Cocoa.h>

@class OSIWindowController;
@interface WindowLayoutManager : NSObject {
	BOOL				_xFlipped, _yFlipped;  // Dependent on current DCMView settings.
	NSMutableDictionary *_currentHangingProtocol;
	BOOL				_useToolbarPanel;
	NSMutableArray		*_windowControllers;
}

+ (id)sharedWindowLayoutManager;

#pragma mark-
#pragma mark WindowController registration

- (void)registerWindowController:(OSIWindowController *)controller;
- (void)unregisterWindowController:(OSIWindowController *)controller;


- (id) findViewerWithNibNamed:(NSString*) nib andPixList:(NSMutableArray*) pixList;
- (NSArray*)findRelatedViewersForPixList:(NSMutableArray*) pixList;





#pragma mark-
#pragma mark hanging protocol setters and getters

- (void) setCurrentHangingProtocolForModality: (NSString*) modality description: (NSString*) description;
- (NSDictionary*) currentHangingProtocol;


/*
- (BOOL) xFlipped;
- (void) setXFlipped: (BOOL) v;
- (BOOL) yFlipped;
- (void) setYFlipped: (BOOL) v;
*/



@end
