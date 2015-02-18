/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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

#import "options.h"

#import "OSI3DPreferencePane.h"

#ifndef OSIRIX_LIGHT
#import "VTKViewOSIRIX.h"
#endif

@implementation OSI3DPreferencePanePref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSI3DPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath: @"values.MAPPERMODEVR" options:NSKeyValueObservingOptionNew context:NULL];
	}
	
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	if (object == [NSUserDefaultsController sharedUserDefaultsController])
    {
		if ([keyPath isEqualToString: @"values.MAPPERMODEVR"])
        {
            if( [[NSUserDefaults standardUserDefaults] boolForKey: @"MAPPERMODEVR"])
            {
    #ifndef OSIRIX_LIGHT
                long vramMB = [VTKView VRAMSizeForDisplayID: [[[[mainWindow screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
                
                //vram /= 1024*1024;
                
                if( vramMB <= 512)
                {
                    NSRunCriticalAlertPanel( NSLocalizedString(@"GPU Rendering", nil), NSLocalizedString( @"Your graphic board has only %d MB of VRAM. Performances will be very limited with large dataset.", nil), NSLocalizedString( @"OK", nil), nil, nil, vramMB);
                }
    #endif
            }
        }
    }
}

- (void) dealloc
{
	NSLog(@"dealloc OSI3DPreferencePanePref");
	
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath: @"values.MAPPERMODEVR"];
    
	[super dealloc];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
    
}

- (void) mainViewDidLoad
{
}

@end
