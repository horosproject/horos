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

#import "PreviewView.h"
#import "NSFont_OpenGL.h"

@implementation PreviewView

- (void) changeGLFontNotification:(NSNotification*) note
{
	if( [note object] == self)
	{
		[[self openGLContext] makeCurrentContext];
		
		CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
        if( cgl_ctx == nil)
            return;
        
		if( fontListGL)
			glDeleteLists (fontListGL, 150);
		fontListGL = glGenLists (150);
		
		[fontGL release];
		fontGL = [[NSFont systemFontOfSize: 12] retain];
		
		[fontGL makeGLDisplayListFirst:' ' count:150 base: fontListGL :fontListGLSize :1 :self.window.backingScaleFactor];
		stringSize = [self convertSizeToBacking: [DCMView sizeOfString:@"B" forFont:fontGL]];
		
		[DCMView purgeStringTextureCache];
		[stringTextureCache release];
		stringTextureCache = nil;
		
		[self setNeedsDisplay:YES];
	}
}


- (BOOL)is2DViewer
{
	return NO;
}

-(BOOL)actionForHotKey:(NSString *)hotKey
{
	NSLog(@"preview Hot Key");
	return [super actionForHotKey:(NSString *)hotKey];
}

@end
