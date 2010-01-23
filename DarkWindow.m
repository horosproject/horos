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

#import "DarkWindow.h"

@implementation DarkWindow
//
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
//	// darker settings
//	//[metalPatternBitmapImageRep colorizeByMappingGray:0.4 toColor:[NSColor blackColor] blackMapping:[NSColor blackColor] whiteMapping:[NSColor lightGrayColor]];
//
//	NSSize metalPatternSize = [metalPatternBitmapImageRep size];
//	NSImage *newPattern = [[NSImage alloc] initWithSize:metalPatternSize];
//	[newPattern addRepresentation:metalPatternBitmapImageRep];
//
//	return [NSColor colorWithPatternImage:newPattern];
//}
//
@end
