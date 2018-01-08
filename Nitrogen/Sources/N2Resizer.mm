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
