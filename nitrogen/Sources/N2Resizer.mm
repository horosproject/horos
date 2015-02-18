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

#import "N2Resizer.h"
#import "N2View.h"
#import "N2Operators.h"


@implementation N2Resizer
@synthesize observed = _observed, affected = _affected;

-(id)initByObservingView:(NSView*)observed affecting:(NSView*)affected {
	self = [super init];
	[self setObserved:observed];
	[self setAffected:affected];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observedBoundsSizeDidChange:) name:N2ViewBoundsSizeDidChangeNotification object:observed];
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setObserved:NULL];
	[self setAffected:NULL];
	[super dealloc];
}

-(void)observedBoundsSizeDidChange:(NSNotification*)notification {
	if (_resizing) return;
	_resizing = YES;
	
	NSValue* value = [[notification userInfo] objectForKey:N2ViewBoundsSizeDidChangeNotificationOldBoundsSize];
	NSSize oldBoundsSize = [value sizeValue], currBoundsSize = [_observed bounds].size;
	if (currBoundsSize != oldBoundsSize)
		[_affected setFrameSize:[_affected frame].size+(currBoundsSize-oldBoundsSize)];
	[_observed setFrameSize:currBoundsSize];
	
	_resizing = NO;
}

@end
