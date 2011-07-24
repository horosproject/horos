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




#import <AppKit/AppKit.h>
#import "OSIWindowController.h"

@class ThickSlabVR;


/** \brief Thick Slab window coontroller */
@interface ThickSlabController : NSWindowController <NSWindowDelegate>
{
	IBOutlet	ThickSlabVR		*view;
}

-(id) init;
-(void) setImageData:(long) w :(long) h :(long) c :(float) sX :(float) sY :(float) t :(BOOL) flip;
-(unsigned char*) renderSlab;
-(void) setWLWW: (float) l :(float) w;
-(void) setBlendingWLWW: (float) l :(float) w;
-(void) setImageSource: (float*) i :(long) c;
-(void) setFlip: (BOOL) f;
-(void) setCLUT: (unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b;
- (void) setLowQuality:(BOOL) q;
-(void) setOpacity:(NSArray*) array;
-(void) setImageBlendingSource: (float*) i;
@end
