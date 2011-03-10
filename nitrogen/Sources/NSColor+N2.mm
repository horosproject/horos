/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

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
