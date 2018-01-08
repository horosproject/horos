/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

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
