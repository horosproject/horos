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
