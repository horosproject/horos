/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Cocoa/Cocoa.h>

@class DCMTKRootQueryNode;

/** \brief Controller for performing query */
@interface QueryArrayController : NSObject
{
	DCMTKRootQueryNode *rootNode;
	NSMutableDictionary *filters;
	NSString *callingAET;
	NSString *calledAET;
	NSString *hostname;
	NSString *port;
	NSArray *queries;
	NSDictionary *distantServer;
	NSLock *queryLock;
	int retrieveMode;
}

- (id)initWithCallingAET:(NSString *) myAET distantServer: (NSDictionary*) ds;

- (id)rootNode;
- (NSArray *)queries;
- (NSMutableDictionary*) filters;
- (void)addFilter:(id)filter forDescription:(NSString *)description;
- (void)sortArray:(NSArray *)sortDesc;
- (void)performQuery;
- (NSDictionary *)parameters;
- (void)performQuery: (BOOL) showError;

@end
