/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "ROIDefaultsWindow.h"
#import "ViewerController.h"

static ViewerController		*curController;

@implementation ROIDefaultsWindow


- (void)comboBoxWillPopUp:(NSNotification *)notification
{
	NSLog(@"will display...");
	roiNames = [curController generateROINamesArray];
	[[notification object] setDataSource: self];
	
	[[notification object] noteNumberOfItemsChanged];
	[[notification object] reloadData];
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	if( roiNames == 0L) roiNames = [curController generateROINamesArray];
	
	long i;
	
	for(i = 0; i < [roiNames count]; i++)
	{
		if( [[roiNames objectAtIndex: i] isEqualToString: aString]) return i;
	}
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	if( roiNames == 0L) roiNames = [curController generateROINamesArray];
	return [roiNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    if ( index > -1 )
    {
		if( roiNames == 0L) roiNames = [curController generateROINamesArray];
		return [roiNames objectAtIndex: index];
    }
    
    return nil;
}


- (id) initWithController: (ViewerController*) c {
	self = [super initWithWindowNibName:@"ROIDefaults"];
	
	curController = c;

	return self;
}


- (void)windowWillClose:(NSNotification *)notification {	
	[self release];
}

- (IBAction)setDefaultName: (id)sender {
	[self close];
}

- (IBAction)unsetDefaultName: (id)sender {
	[ROI setDefaultName: nil];
}

@end
