/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
