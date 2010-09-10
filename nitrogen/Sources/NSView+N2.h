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


@interface NSView (N2)

// Shortcut to [NSView initWithFrame:NSMakeRect(NSZeroPoint, size)]
-(id)initWithSize:(NSSize)size;
-(NSRect)sizeAdjust;
-(NSImage *) screenshotByCreatingPDF;

@end

@protocol OptimalSize

-(NSSize)optimalSize;
-(NSSize)optimalSizeForWidth:(CGFloat)width;

@end
