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

#import "NSColor+N2.h"


@implementation NSColor (N2)

-(BOOL)isEqualToColor:(NSColor*)color {
	return [self isEqualToColor:color alphaThreshold:0];
}

-(BOOL)isEqualToColor:(NSColor*)color alphaThreshold:(CGFloat)alphaThreshold {
	if (!color) return NO;
	if (color == self) return YES;
	
	NSColor *c1, *c2;
	
	if ([[self colorSpace] isEqual:[color colorSpace]]) {
		c1 = self; c2 = color;
	} else {
		c1 = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		c2 = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	}
	
	NSInteger numberOfComponents = [c1 numberOfComponents];
	CGFloat c1components[numberOfComponents], c2components[numberOfComponents];
	[c1 getComponents:c1components]; [c2 getComponents:c2components];
	
	if (c1components[numberOfComponents-1] <= alphaThreshold || c2components[numberOfComponents-1] <= alphaThreshold)
		return YES;
	
	for (NSInteger i = 0; i < numberOfComponents-1; ++i)
		if (c1components[i] != c2components[i]) {
//			NSLog(@"component %d not equal in [%@] and [%@]", i, [c1 description], [c2 description]);
			return NO;
		}
	
	return YES;
}

@end
