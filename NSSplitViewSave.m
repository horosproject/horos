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

#import "NSSplitViewSave.h"

@implementation NSSplitView(Defaults)

- (void) restoreDefault: (NSString *) defaultName
{
    NSArray *frames = [[NSUserDefaults standardUserDefaults] arrayForKey: defaultName];
    
    if( frames.count == self.subviews.count)
    {
        int i = 0;
        
        for( NSView *v in [self subviews])
            [v setFrame: NSRectFromString( [frames objectAtIndex: i++])];
    }
    
    [self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
    NSMutableArray *frameArray = [NSMutableArray array];
    
    for( NSView *v in [self subviews])
    {
        if( [self isSubviewCollapsed: v])
        {
            NSRect frame = v.frame;
            
            if( [self isVertical])
                frame.size.width = 0;
            else
                frame.size.height = 0;
            
            [frameArray addObject: NSStringFromRect( v.frame)];
        }
        else
            [frameArray addObject: NSStringFromRect( v.frame)];
    }
    [[NSUserDefaults standardUserDefaults] setObject: frameArray forKey: defaultName];
}

@end
