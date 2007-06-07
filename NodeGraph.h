//
//  NodeGraph.h
//  OsiriX
//
//  Created by Lance Pysher on 6/7/07.
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


@interface NodeGraph : NSObject {
	NSMutableSet *_nodes;
}

- (void)mergeGraphs: (NodeGraph *)graph;
- (void)pruneBranchAtNode:(id)node;

@end
