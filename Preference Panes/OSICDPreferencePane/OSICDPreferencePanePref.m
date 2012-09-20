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

#import "OSICDPreferencePanePref.h"

@implementation OSICDPreferencePanePref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSICDPreferencePanePref" bundle: nil] autorelease];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
        
        if( [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"].length <= 1)
            [[NSUserDefaults standardUserDefaults] setObject:@"/~Documents/FolderToBurn" forKey:@"SupplementaryBurnPath"];
        
        if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] stringByExpandingTildeInPath]] == NO)
            [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
	}
	
	return self;
}


- (void) dealloc
{
	NSLog(@"dealloc OSICDPreferencePanePref");
	
	[super dealloc];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (IBAction)chooseSupplementaryBurnPath: (id)sender
{
	NSOpenPanel				*openPanel;
	NSString				*filename;
	BOOL					result;
	
	openPanel=[NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: YES];
	[openPanel setCanChooseFiles: NO];
	result=[openPanel runModalForDirectory: Nil file: Nil types: Nil];
	if (result)
	{
		filename = [[[openPanel filenames] objectAtIndex: 0] stringByAbbreviatingWithTildeInPath];
		[[NSUserDefaults standardUserDefaults] setObject: filename forKey:@"SupplementaryBurnPath"];
	}
}

@end
