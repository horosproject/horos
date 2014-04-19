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

#import "OSI3DPreferencePane.h"

#ifndef OSIRIX_LIGHT
#import "VTKView.h"
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
                long vram = [VTKView VRAMSizeForDisplayID: [[[[mainWindow screen] deviceDescription] objectForKey: @"NSScreenNumber"] intValue]];
                
                vram /= 1024*1024;
                
                if( vram <= 512)
                {
                    NSRunCriticalAlertPanel( NSLocalizedString(@"GPU Rendering", nil), NSLocalizedString( @"Your graphic board has only %d MB of VRAM. Performances will be very limited with large dataset.", nil), NSLocalizedString( @"OK", nil), nil, nil, vram);
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
