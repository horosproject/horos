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

#import "DarkPanel.h"


@implementation DarkPanel

//- (void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animationFlag
//{
//	[super setFrame:frameRect display:displayFlag animate:animationFlag];
//	[self setBackgroundColor: [self darkBackgroundColor]];
//	[self display];
//}
//
//- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
//{
//	[super setFrame:frameRect display:flag];
//	[self setBackgroundColor: [self darkBackgroundColor]];
//	[self display];
//}
//
//- (NSColor *)darkBackgroundColor
//{
//	NSColor *metalPatternColor = [self _generateMetalBackground];
//	NSImage *metalPatternImage = [metalPatternColor patternImage];
//	NSBitmapImageRep *metalPatternBitmapImageRep = [NSBitmapImageRep imageRepWithData:[metalPatternImage TIFFRepresentation]];
//
//	[metalPatternBitmapImageRep colorizeByMappingGray:0.2 toColor:[NSColor blackColor] blackMapping:[NSColor blackColor] whiteMapping:[NSColor lightGrayColor]];
//
//	NSSize metalPatternSize = [metalPatternBitmapImageRep size];
//	NSImage *newPattern = [[NSImage alloc] initWithSize:metalPatternSize];
//	[newPattern addRepresentation:metalPatternBitmapImageRep];
//
//	return [NSColor colorWithPatternImage:newPattern];
//}

@end
