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

#import "OSIViewerPreferencePanePref.h"
#import "AppController.h"

@implementation OSIViewerPreferencePanePref

static NSString* UserDefaultsObservingContext = @"UserDefaultsObservingContext";

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIViewerPreferencePanePref" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.ReserveScreenForDB" options:0 context:UserDefaultsObservingContext];
	}
	
	return self;
}

-(void)dealloc {
	NSLog(@"dealloc OSIViewerPreferencePanePref");
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.ReserveScreenForDB"];
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != UserDefaultsObservingContext) {
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    [self willChangeValueForKey:@"screensThumbnail"];
    [self didChangeValueForKey:@"screensThumbnail"];
}


- (void) enableControls: (BOOL) val
{
//	if( val == YES)
//	{
//		[[NSUserDefaults standardUserDefaults] setBool:[[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"] forKey: @"AUTOTILING"];
//		[totoku12Bit setEnabled: [[NSUserDefaults standardUserDefaults] boolForKey:@"is12bitPluginAvailable"]]; // DONE THRU BINDINGS
//	}
//	NSLog(@"%@", totoku12Bit);
//	[characterSetPopup setEnabled: val];
//	[addServerDICOM setEnabled: val];
//	[addServerSharing setEnabled: val];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
	
	[[NSUserDefaults standardUserDefaults] setObject:[iPhotoAlbumName stringValue] forKey: @"ALBUMNAME"];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[totoku12Bit setEnabled: [[NSUserDefaults standardUserDefaults] boolForKey:@"is12bitPluginAvailable"]];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"is12bitPluginAvailable"] == NO)
	{
		[[NSUserDefaults standardUserDefaults] setBool: NO forKey:@"automatic12BitTotoku"];
	}

	[sizeMatrix selectCellWithTag: [defaults boolForKey: @"ORIGINALSIZE"]];
	
	[openViewerCheck setState: [defaults boolForKey: @"OPENVIEWER"]];
	[reverseScrollWheelCheck setState: [defaults boolForKey: @"Scroll Wheel Reversed"]];
	[iPhotoAlbumName setStringValue: [defaults stringForKey: @"ALBUMNAME"]];
	[toolbarPanelMatrix selectCellWithTag:[defaults boolForKey: @"USEALWAYSTOOLBARPANEL2"]];
	[autoHideMatrix setState: [defaults boolForKey: @"AUTOHIDEMATRIX"]];
	[tilingCheck setState: [defaults boolForKey: @"AUTOTILING"]];
	
	[windowSizeMatrix selectCellWithTag: [defaults integerForKey: @"WINDOWSIZEVIEWER"]];
	
	int i = [defaults integerForKey: @"MAX3DTEXTURE"], x = 1;
	
	while( i > 32)
	{
		i /= 2;
		x++;
	}
}

-(AppController*)appController {
	return [AppController sharedAppController];
}

- (IBAction) setAutoTiling: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"AUTOTILING"];
	
	if( [sender state])
	{
		[[NSUserDefaults standardUserDefaults] setInteger:0 forKey: @"WINDOWSIZEVIEWER"];
		[windowSizeMatrix selectCellWithTag: 0];
	}
}

- (IBAction) setWindowSizeViewer: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[[sender selectedCell] tag] forKey: @"WINDOWSIZEVIEWER"];
}

- (IBAction) setToolbarMatrix: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"USEALWAYSTOOLBARPANEL2"];
}

- (IBAction) setAutoHideMatrixState: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"AUTOHIDEMATRIX"];
}

- (IBAction) setExportSize: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[[sender selectedCell] tag] forKey: @"ORIGINALSIZE"];
}

- (IBAction) setReverseScrollWheel: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"Scroll Wheel Reversed"];
}

- (IBAction) setOpenViewerBut: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey: @"OPENVIEWER"];
}

- (IBAction) setAlbumName: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[iPhotoAlbumName stringValue] forKey: @"ALBUMNAME"];
}

@end
























