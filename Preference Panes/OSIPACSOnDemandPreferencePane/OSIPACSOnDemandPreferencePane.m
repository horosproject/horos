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

#import "OSIPACSOnDemandPreferencePane.h"

@implementation OSIPACSOnDemandPreferencePane

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIPACSOnDemand" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}


- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) dealloc
{
	NSLog(@"dealloc OSIPACSOnDemandPreferencePane");
	
	[super dealloc];
}

- (void) mainViewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
}
@end
