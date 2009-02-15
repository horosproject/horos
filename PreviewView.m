/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "PreviewView.h"
#import "NSFont_OpenGL.h"

@implementation PreviewView

- (void) initFont
{
	fontListGL = glGenLists (150);
	fontGL = [NSFont systemFontOfSize: 12];
	[fontGL makeGLDisplayListFirst:' ' count:150 base: fontListGL :fontListGLSize :1];
	stringSize = [DCMView sizeOfString:@"B" forFont:fontGL];
}

- (void) changeGLFontNotification:(NSNotification*) note
{

}

- (BOOL)is2DViewer{
	return NO;
}

-(BOOL)actionForHotKey:(NSString *)hotKey{
	NSLog(@"preview Hot Key");
	return [super actionForHotKey:(NSString *)hotKey];
}

@end
