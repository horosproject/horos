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

#import "ThumbnailCell.h"
#import "O2ViewerThumbnailsMatrix.h"

#define FULLSIZEHEIGHT 120
#define HALFSIZEHEIGHT 60
#define SIZEWIDTH 100

@implementation ThumbnailCell

@synthesize rightClick;

+ (float) thumbnailCellWidth
{
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1:   return SIZEWIDTH * 0.8; break;
        case 0:    return SIZEWIDTH; break;
        case 1:    return SIZEWIDTH * 1.3; break;

    }
    return SIZEWIDTH;
}

- (NSMenu *)menuForEvent:(NSEvent *)anEvent inRect:(NSRect)cellFrame ofView:(NSView *)aView
{
    [self retain];
    
	rightClick = YES;
	[self performClick: self];
	rightClick = NO;
	
    [self autorelease];
    
	return nil;
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    [super drawBezelWithFrame:frame inView:controlView];
    if (self.backgroundColor) {
        
        if( !invertedSet)
            invertedColors = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.CoreGraphics"] objectForKey: @"DisplayUseInvertedPolarity"] boolValue];
        
        NSColor *backc = [[self.backgroundColor copy] autorelease];
        
        if( invertedColors)
            backc = [NSColor colorWithCalibratedRed: 1.0-backc.redComponent green: 1.0-backc.greenComponent blue: 1.0-backc.blueComponent alpha: backc.alphaComponent];
        
        [NSGraphicsContext saveGraphicsState];
        [[backc colorWithAlphaComponent:0.75] setFill];
        [NSBezierPath fillRect:NSInsetRect(frame, 1, 1)];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
    return [super drawTitle:title withFrame:NSInsetRect(frame, -2,0) inView:controlView]; // very precioussss 4px/pt
}

- (NSSize)cellSize
{
    O2ViewerThumbnailsMatrixRepresentedObject* oro = [self representedObject];
    
    float h = 0;
    
    if ([oro.object isKindOfClass:[NSManagedObject class]] || oro.children.count || oro == nil)
        h = FULLSIZEHEIGHT;
    else
        h = HALFSIZEHEIGHT;
    
    switch( [[NSUserDefaults standardUserDefaults] integerForKey: @"dbFontSize"])
    {
        case -1:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h * 0.8); break;
        case 0:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h); break;
        case 1:    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h * 1.3); break;
    }

    return NSMakeSize( [ThumbnailCell thumbnailCellWidth], h);
}

@end
