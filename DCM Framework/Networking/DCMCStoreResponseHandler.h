//
//  DCMCStoreResponseHandler.h
//  OsiriX
//
//  Created by Lance Pysher on 12/20/04.

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
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import <Cocoa/Cocoa.h>
#import "DCMCompositeResponseHandler.h"

@class DCMObject;
@interface DCMCStoreResponseHandler : DCMCompositeResponseHandler {
	DCMObject *currentObject;
	int numberOfFiles;
	int numberSent;
	int numberErrors;
	id moveHandler;
}

- (void)setCurrentObject:(DCMObject *)object;
- (DCMObject *)currentObject;
- (void)setNumberOfFiles:(int)number;
- (int)numberOfFiles;
- (int)numberSent;
- (int)numberErrors;

- (void)setMoveHandler:(id)handler;



@end
