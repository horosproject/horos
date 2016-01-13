/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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

#import "OSIViewerPreferencePanePref.h"
#import "AppController.h"
#import "ViewerController.h"

@implementation OSIViewerPreferencePanePref

static NSString* UserDefaultsObservingContext = @"UserDefaultsObservingContext";

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIViewerPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.ReserveScreenForDB" options:0 context:UserDefaultsObservingContext];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.AUTOTILING" options:0 context:UserDefaultsObservingContext];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.UseFloatingThumbnailsList" options:0 context:UserDefaultsObservingContext];
	}
	
	return self;
}

- (void) dealloc
{
	NSLog(@"dealloc OSIViewerPreferencePanePref");
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ReserveScreenForDB"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.AUTOTILING"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.UseFloatingThumbnailsList"];
    [super dealloc];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != UserDefaultsObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    if( [keyPath isEqualToString: @"values.ReserveScreenForDB"])
    {
        [self willChangeValueForKey:@"screensThumbnail"];
        [self didChangeValueForKey:@"screensThumbnail"];
    }
    
    if( [keyPath isEqualToString: @"values.AUTOTILING"])
    {
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"WINDOWSIZEVIEWER"];
    }
    
    if( [keyPath isEqualToString: @"values.UseFloatingThumbnailsList"])
    {
        [ViewerController closeAllWindows];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"SeriesListVisible"];
    }
}

- (void) willSelect
{
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) mainViewDidLoad
{
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"is12bitPluginAvailable"] == NO)
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"automatic12BitTotoku"];
}

- (AppController*) appController
{
	return [AppController sharedAppController];
}
@end
