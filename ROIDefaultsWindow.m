/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "ROIDefaultsWindow.h"
#import "ViewerController.h"

@implementation ROIDefaultsWindow

- (NSArray*) generateROINamesArray
{
	NSArray *viewers = [ViewerController getDisplayed2DViewers];
	NSMutableArray *names = [NSMutableArray array];
	
	for( ViewerController *v in viewers)
	{
		NSArray *vNames = [v generateROINamesArray];
		
		for( NSString *vName in vNames)
		{
			BOOL found = NO;
			
			for( NSString *name in names)
			{
				if( [name isEqualToString: vName]) found = YES;
			}
			
			if( found == NO)
			{
				[names addObject: vName];
			}
		}
	}
	
	return names;
}

- (void)comboBoxWillPopUp:(NSNotification *)notification
{
	[roiNames release];
	roiNames = [[self generateROINamesArray] retain];
	[[notification object] setDataSource: self];
	
	[[notification object] noteNumberOfItemsChanged];
	[[notification object] reloadData];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	if( roiNames == nil) roiNames = [[self generateROINamesArray] retain];
	
	long i;
	
	for(i = 0; i < [roiNames count]; i++)
	{
		if( [[roiNames objectAtIndex: i] isEqualToString: aString]) return i;
	}
	
	return NSNotFound;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if( roiNames == nil) roiNames = [[self generateROINamesArray] retain];
	return [roiNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    if ( index > -1 )
    {
		if( roiNames == nil) roiNames = [[self generateROINamesArray] retain];
		
		return [roiNames objectAtIndex: index];
    }
    
    return nil;
}

- (id) initWithController: (ViewerController*) c
{
	self = [super initWithWindowNibName:@"ROIDefaults"];
	
	return self;
}

- (void) dealloc
{
	[roiNames release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[self window] setAcceptsMouseMovedEvents: NO];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[self autorelease];
}

- (IBAction)setDefaultName: (id)sender
{
	[[self window] close];
}

- (IBAction)unsetDefaultName: (id)sender
{
	[ROI setDefaultName: nil];
}

@end
