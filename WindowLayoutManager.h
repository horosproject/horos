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

/*
The WindowLayoutManager class manages the various placement of the Viewers
primarily by use of hanging proctols and Advanced hanging protocols
and keeps track of the Viewer Related Window Controllers
It is a shared class.
 */

#import <Cocoa/Cocoa.h>

@class OSIWindowController;
//@class LayoutWindowController;
@interface WindowLayoutManager : NSObject
{
	NSDictionary *_currentHangingProtocol;
}

@property( retain) NSDictionary *currentHangingProtocol;

+ (WindowLayoutManager*)sharedWindowLayoutManager;
+ (int) windowsRowsForHangingProtocol:(NSDictionary*) protocol;
+ (int) windowsColumnsForHangingProtocol:(NSDictionary*) protocol;
+ (int) imagesRowsForHangingProtocol:(NSDictionary*) protocol;
+ (int) imagesColumnsForHangingProtocol:(NSDictionary*) protocol;
- (int) windowsRows;
- (int) windowsColumns;
- (int) imagesRows;
- (int) imagesColumns;

#pragma mark-
#pragma mark hanging protocol setters and getters

+ (NSArray*) hangingProtocolsForModality: (NSString*) modality;
+ (NSDictionary*) hangingProtocolForModality: (NSString*) modalities description: (NSString *) description;
- (void) setCurrentHangingProtocolForModality: (NSString*) modality description: (NSString*) description;
- (NSDictionary*) currentHangingProtocol;

@end
