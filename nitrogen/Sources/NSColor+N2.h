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

#import <Cocoa/Cocoa.h>


@interface NSColor (N2)

-(BOOL)isEqualToColor:(NSColor*)color;
-(BOOL)isEqualToColor:(NSColor*)color alphaThreshold:(CGFloat)alphaThreshold;

@end
