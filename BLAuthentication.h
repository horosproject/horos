/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/
//  ====================================================================== 	//
//  BLAuthentication.h														//
//  																		//
//  Last Modified on Tuesday April 24 2001									//
//  Copyright 2001 Ben Lachman												//
//																			//
//	Thanks to Brian R. Hill <http://personalpages.tds.net/~brian_hill/>		//
//  ====================================================================== 	//

#import <Cocoa/Cocoa.h>
#import <Security/Authorization.h>

/** \brief authentication and authorization */
@interface BLAuthentication : NSObject 
{
	AuthorizationRef authorizationRef; 
}
// returns a shared instance of the class
+ sharedInstance;
// checks if user is authentcated forCommands
- (BOOL)isAuthenticated:(NSArray *)forCommands;
// authenticates user forCommands
- (BOOL)authenticate:(NSArray *)forCommands;
// deauthenticates user
- (void)deauthenticate;
// gets the pid forProcess
- (int)getPID:(NSString *)forProcess;
// executes pathToCommand with privileges
- (BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments;
// kills the process specified by commandFromPS
- (BOOL)killProcess:(NSString *)commandFromPS;
@end

// strings for notification center
extern NSString* const BLAuthenticatedNotification;
extern NSString* const BLDeauthenticatedNotification;




