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

#import "OSIEnvironment.h"
#import "OSIEnvironment+Private.h"
#import "OSIVolumeWindow.h"
#import "OSIVolumeWindow+Private.h"
#import "ViewerController.h"
#import "DCMView.h"

NSString* const OSIEnvironmentOpenVolumeWindowsDidUpdateNotification = @"OSIEnvironmentOpenVolumeWindowsDidUpdateNotification";

static OSIEnvironment *sharedEnvironment = nil;

@implementation OSIEnvironment

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"openVolumeWindows"]) {
		return NO;
	}
	
	return [super automaticallyNotifiesObserversForKey:key];
}

+ (OSIEnvironment*)sharedEnvironment
{
//    return nil; // because this is too slow on remote DBs, sorry... you're forcing us to load the complete series' DCMPix before showing the window :(
    
	@synchronized (self) {
		if (sharedEnvironment == nil)
        {
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"OSIEnvironmentActivated"])
                sharedEnvironment = [[super allocWithZone:NULL] init];
		}
	}
    return sharedEnvironment;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedEnvironment] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (id)init
{
	if ( (self = [super init]) ) {
		_volumeWindows = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (OSIVolumeWindow *)volumeWindowForViewerController:(ViewerController *)viewerController
{
	return [_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]];
}

- (NSArray *)openVolumeWindows
{
	return [_volumeWindows allValues];
}

- (OSIVolumeWindow *)frontmostVolumeWindow
{
	NSArray *windows;
	NSWindow *window;
	NSWindowController *windowController;
	ViewerController *viewerController;
	OSIVolumeWindow *volumeWindow;
	
	windows = [NSApp orderedWindows];
	
	for (window in windows) {
		windowController = [window windowController];
		if ([windowController isKindOfClass:[ViewerController class]]) {
			viewerController = (ViewerController *)windowController;
			volumeWindow = [self volumeWindowForViewerController:viewerController];
			if (volumeWindow) {
				return volumeWindow;
			}
		}
	}
	
	return nil;
}

@end


@implementation OSIEnvironment (Private)

- (void)addViewerController:(ViewerController *)viewerController
{
	OSIVolumeWindow *volumeWindow;
	
	assert([_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]] == NO); // already added this viewerController!
	
	volumeWindow = [[OSIVolumeWindow alloc] initWithViewerController:viewerController];
	[self willChangeValueForKey:@"openVolumeWindows"];
	[_volumeWindows setObject:volumeWindow forKey:[NSValue valueWithPointer:viewerController]];
	[self didChangeValueForKey:@"openVolumeWindows"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OSIEnvironmentOpenVolumeWindowsDidUpdateNotification object:nil];
	[volumeWindow release];
}

- (void)removeViewerController:(ViewerController *)viewerController
{
	OSIVolumeWindow *volumeWindow;
	
	assert([_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]]); // make sure this one was added!
	
	volumeWindow = [_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]];
	assert([volumeWindow isKindOfClass:[OSIVolumeWindow class]]);
	
	[volumeWindow viewerControllerDidClose];
	
	[self willChangeValueForKey:@"openVolumeWindows"];
	[_volumeWindows removeObjectForKey:[NSValue valueWithPointer:viewerController]];
	[self didChangeValueForKey:@"openVolumeWindows"];
	[[NSNotificationCenter defaultCenter] postNotificationName:OSIEnvironmentOpenVolumeWindowsDidUpdateNotification object:nil];
}



- (void)viewerControllerWillChangeData:(ViewerController *)viewerController
{
    OSIVolumeWindow *volumeWindow;
	
    // only do this if the volume window is already properly attached, this assumes that the first time the viewerController is initialized it will not have been added,
    // and therefore we will not send this notification for the original init
    if ([_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]]) {
        volumeWindow = [_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]];
        assert([volumeWindow isKindOfClass:[OSIVolumeWindow class]]);

        [volumeWindow viewerControllerWillChangeData];
    }
}

- (void)viewerControllerDidChangeData:(ViewerController *)viewerController
{
    OSIVolumeWindow *volumeWindow;
	
    // only do this if the volume window is already properly attached, this assumes that the first time the viewerController is initialized it will not have been added,
    // and therefore we will not send this notification for the original init
    if ([_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]]) {
        volumeWindow = [_volumeWindows objectForKey:[NSValue valueWithPointer:viewerController]];
        assert([volumeWindow isKindOfClass:[OSIVolumeWindow class]]);
        
        [volumeWindow viewerControllerDidChangeData];
    }
}

- (void)drawDCMView:(DCMView *)dcmView
{
    ViewerController *viewerController =  (ViewerController *)[dcmView windowController];
    if (([viewerController isKindOfClass:[ViewerController class]]) ) {
        OSIVolumeWindow *volumeWindow = [self volumeWindowForViewerController:viewerController];
        [volumeWindow drawInDCMView:dcmView];
    }
}

@end























