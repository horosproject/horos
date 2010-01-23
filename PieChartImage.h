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

//  Inspired by the LittleYellowGuy Project
//
//  Created by Daniel Jalkut on 11/10/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.

#import <Cocoa/Cocoa.h>


@interface NSImage (PieChartImage)

+ (NSImage*) pieChartImageWithPercentage:(float)percentage;
+ (NSImage*) pieChartImageWithPercentage:(float)percentage borderColor:(NSColor*)borderColor insideColor:(NSColor*)insideColor fullColor:(NSColor*)fullColor;

@end

@interface NSBezierPath (RSPieChartUtilities)

+ (NSBezierPath*) bezierPathForPieInRect:(NSRect)containerRect withWedgeRemovedFromStartingAngle:(float)startAngle toEndingAngle:(float)endAngle;

@end
