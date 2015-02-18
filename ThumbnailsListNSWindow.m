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

#import "ThumbnailsListNSWindow.h"
#import "ThumbnailsListPanel.h"
#import "ViewerController.h"
#import "N2Debug.h"
#import "AppController.h"

@implementation ThumbnailsListNSWindow

- (BOOL) canBecomeMainWindow
{
	return NO;
}

- (BOOL) canBecomeKeyWindow
{
	return NO;
}

- (void) orderOut:(id)sender
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SeriesListVisible"] == NO)
    {
        [super orderOut:sender];
        return;
    }
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"UseFloatingThumbnailsList"])
    {
        NSDisableScreenUpdates();
        
        ViewerController *v = [ViewerController frontMostDisplayed2DViewerForScreen: self.screen];
        if( v)
        {
            [self.windowController setThumbnailsView: v.previewMatrixScrollView viewer: v];
            
            if( v.window.windowNumber > 0)
                [self orderWindow: NSWindowBelow relativeTo: v.window.windowNumber];
        }
        else
        {
            [super orderOut:sender];
            [self.windowController setThumbnailsView: nil viewer: nil];
        }
        
        NSEnableScreenUpdates();
    }
    else
        [super orderOut:sender];
}

-(NSTimeInterval)animationResizeTime:(NSRect)newFrame {
	return 0;
}

-(NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen*)screen {
	return frameRect; // not movable, and OsiriX knows where to place toolbars ;)
}

@end
