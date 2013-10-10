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


@interface NSWindow (N2)

-(NSSize)contentSizeForFrameSize:(NSSize)frameSize;
-(NSSize)frameSizeForContentSize:(NSSize)contentSize;

-(CGFloat)toolbarHeight;

-(void)safelySetMovable:(BOOL)flag;
//-(void)safelySetUsesLightBottomGradient:(BOOL)flag;

@end
