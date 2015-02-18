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




#import "ThickSlabVR.h"
#import "ThickSlabController.h"

@implementation ThickSlabController

-(id) init
{
	self = [super initWithWindowNibName:@"ThickSlab"];
	[[self window] setDelegate:self];
	[[self window] orderOut:self];
	return self;
}

-(void) setImageData:(long) w :(long) h :(long) c :(float) sX :(float) sY :(float) t :(BOOL) flip
{
	[view setImageData:w :h :c :sX :sY :t :flip];
}

-(unsigned char*) renderSlab
{
	return [view renderSlab];
}

-(void) setBlendingWLWW: (float) l :(float) w
{
	[view setBlendingWLWW:l:w];
}

-(void) setWLWW: (float) l :(float) w
{
	[view setWLWW:l:w];
}

-(void) setImageSource: (float*) i :(long) c
{
	[view setImageSource: i :c];
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	[view setBlendingCLUT: r :g :b];
}

-(void) setCLUT: (unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	[view setCLUT: r :g :b];
}

-(void) setFlip: (BOOL) f
{
	[view setFlip: f];
}

- (void) setLowQuality:(BOOL) q
{
	[view setLowQuality:q];
}

-(void) setOpacity:(NSArray*) array
{
	[view setOpacity:array];
}

-(void) setImageBlendingSource: (float*) i
{
	[view setImageBlendingSource: i];
}
@end
