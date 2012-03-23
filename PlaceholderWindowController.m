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


#import "PlaceholderWindowController.h"


@implementation PlaceholderWindowController

- (id)init {
	if (self = [super initWithWindowNibName:@"Placeholder"]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAllWindows:) name:@"Close All Viewers" object:nil];
	}
	return self;
}
- (void)windowDidLoad{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[self window]];
}

- (NSManagedObject *)currentStudy{
	return nil;
}
- (NSManagedObject *)currentSeries{
	return nil;
}

- (NSManagedObject *)currentImage{
	return nil;
}

-(float)curWW{
	return 0.0;
}

-(float)curWL{
	return 0.0;
}


- (void)windowWillClose:(NSNotification *)notification{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[self autorelease];
}

- (void)closeAllWindows:(NSNotification *)note{
	[[self window] performClose:self];
}


@end
