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

extern NSString* N2StepDidBecomeActiveNotification;
extern NSString* N2StepDidBecomeInactiveNotification;
extern NSString* N2StepDidBecomeEnabledNotification;
extern NSString* N2StepDidBecomeDisabledNotification;
extern NSString* N2StepTitleDidChangeNotification;

@interface N2Step : NSObject {
	NSString* _title;
	NSView* _enclosedView;
	NSButton* defaultButton;
	BOOL _necessary, _active, _enabled, _done, _shouldStayVisibleWhenInactive;
}

@property(nonatomic, retain) NSString* title;
@property(readonly) NSView* enclosedView;
@property(retain) NSButton* defaultButton;
@property(getter=isNecessary) BOOL necessary;
@property(nonatomic, getter=isActive) BOOL active;
@property(nonatomic, getter=isEnabled) BOOL enabled;
@property(getter=isDone) BOOL done;
@property BOOL shouldStayVisibleWhenInactive;

-(id)initWithTitle:(NSString*)title enclosedView:(NSView*)view;

@end
