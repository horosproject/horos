/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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
////////////////////////////////////////////
//
//	Matt Brewer
//	December 1, 2009
//
//	matt@matt-brewer.com
//	http://www.matt-brewer.com
//
//
//	This code is released as is
//	with NO warranty, implied or otherwise.
//
////////////////////////////////////////////

#import "NSApplication-Dock.h"
@implementation NSApplication (Dock)


#pragma mark Application Assumed

////////////////////////////////////////////
//
//	Adds the currently running application
//	to the user's Dock
//
////////////////////////////////////////////

- (BOOL) addApplicationToDock {
	
	if ( ![self applicationExistsInDock] ) {
		return [self addApplicationToDock:[[NSBundle mainBundle] bundlePath]];
	} else return NO;
	
}


////////////////////////////////////////////
//
//	YES/NO if current application is in Dock
//
////////////////////////////////////////////

- (BOOL) applicationExistsInDock {
	return [self applicationExistsInDock:[[NSBundle mainBundle] bundlePath]];
}





#pragma mark Application Specified

////////////////////////////////////////////
//
//	Adds the specified path to the Dock
//	Doesn't check to see if is app or if
//	file even exists
//
////////////////////////////////////////////

- (BOOL) addApplicationToDock:(NSString*)path {
	
	BOOL success = YES;
	
	// Add the application to the Dock
	NSArray* args = [NSArray arrayWithObjects:@"write", @"com.apple.Dock",@"persistent-apps",@"-array-add",[NSString stringWithFormat:@"<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>%@</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>", path], nil];
	NSTask* t = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/defaults" arguments:args];
	[t waitUntilExit];
	if ( ![t isRunning] && [t terminationStatus] > 0 ) {
		NSLog(@"%d - %d", [t terminationStatus], (int) [t terminationReason]);
		success = NO;
	}
	
	// Now restart the Dock
	t = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObjects:@"-HUP", @"Dock", nil]];
	[t waitUntilExit];
	if ( ![t isRunning] && [t terminationStatus] > 0 ) {
		NSLog(@"%d - %d", [t terminationStatus], (int) [t terminationReason]);
		success = NO;
	}
	
	return success;
}


////////////////////////////////////////////
//
//	YES/NO if application is in Dock
//
////////////////////////////////////////////

- (BOOL) applicationExistsInDock:(NSString*)path
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"com.apple.Dock"];

	NSArray* apps = [defaults objectForKey:@"persistent-apps"];
	NSDictionary* d = nil;
	NSEnumerator* e = [apps objectEnumerator];
	NSString* app = nil;
    
	while ( d = [e nextObject])
    {
		app = [[[d objectForKey:@"tile-data"] objectForKey:@"file-data"] objectForKey:@"_CFURLString"];
        
		if( app.length > 0 && [app rangeOfString: path].location != NSNotFound)
        {
            NSLog( @"Already in Dock: %@", app);
			return YES;
		}
	} 

    return NO;
}

@end
