//
//  DCMCFindResponseDataHandler.h
//  OsiriX
//
//  Created by Lance Pysher on 1/1/05.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

#import <Cocoa/Cocoa.h>
#import "DCMCompositeResponseHandler.h"

@class DCMQueryNode;
@interface DCMCFindResponseDataHandler : DCMCompositeResponseHandler {
	DCMQueryNode *queryNode;

}

+ (id)findHandlerWithDebugLevel:(int)debug  queryNode:(DCMQueryNode *)node;
- (id)initWithDebugLevel:(int)debug  queryNode:(DCMQueryNode *)node;
- (DCMQueryNode *)queryNode;
- (void)setQueryNode:(DCMQueryNode *)node;

@end
