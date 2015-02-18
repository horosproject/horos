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

#import <N2Step.h>

NSString* N2StepDidBecomeActiveNotification = @"N2StepDidBecomeActiveNotification";
NSString* N2StepDidBecomeInactiveNotification = @"N2StepDidBecomeInactiveNotification";
NSString* N2StepDidBecomeEnabledNotification = @"N2StepDidBecomeEnabledNotification";
NSString* N2StepDidBecomeDisabledNotification = @"N2StepDidBecomeDisabledNotification";
NSString* N2StepTitleDidChangeNotification = @"N2StepTitleDidChangeNotification";

@implementation N2Step
@synthesize enclosedView = _enclosedView, title = _title, active = _active, necessary = _necessary, done = _done, enabled = _enabled, shouldStayVisibleWhenInactive = _shouldStayVisibleWhenInactive;
@synthesize defaultButton;

-(id)initWithTitle:(NSString*)aTitle enclosedView:(NSView*)aView {
	_enclosedView = [aView retain];
	_title = [aTitle retain];
	
	_necessary = YES;
	_active = NO;
	_enabled = YES;
	_done = NO;
	
	return self;
}

-(void)dealloc {
	[_enclosedView release];
	[_title release];
	self.defaultButton = NULL;
	[super dealloc];
}

-(void)setActive:(BOOL)active {
	//if (_active != active) {
		_active = active;
		[[NSNotificationCenter defaultCenter] postNotificationName:(active ?N2StepDidBecomeActiveNotification :N2StepDidBecomeInactiveNotification) object:self];
	//}
}

-(void)setEnabled:(BOOL)enabled {
	//if (_enabled != enabled) {
		if (!enabled && _active)
			[self setActive:NO];
		_enabled = enabled;
		[[NSNotificationCenter defaultCenter] postNotificationName:(enabled ?N2StepDidBecomeEnabledNotification :N2StepDidBecomeDisabledNotification) object:self];
	//}
}

-(void)setTitle:(NSString*)title {
	[_title release];
	_title = [title retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:N2StepTitleDidChangeNotification object:self];
}

@end
