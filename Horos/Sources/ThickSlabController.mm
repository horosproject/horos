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
