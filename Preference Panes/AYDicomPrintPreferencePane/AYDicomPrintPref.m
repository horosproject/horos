/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import "AYDicomPrintPref.h"
#import <SecurityInterface/SFAuthorizationView.h>
#import "AYDicomPrintWindowController.h"

@implementation AYDicomPrintPref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"AYDicomPrintPref" bundle: nil] autorelease];
		[nib instantiateWithOwner:self topLevelObjects:&_tlos];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

- (void) dealloc
{
	[m_PrinterDefaults release];

    [_tlos release]; _tlos = nil;
    
	[super dealloc];
}

- (void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) awakeFromNib
{
	[AYDicomPrintWindowController updateAllPreferencesFormat];
	
	// select default printer
	NSArray *printer = [m_PrinterController arrangedObjects];

	int i;
	NSDictionary *printerDict;
	for (i = 0; i < [printer count]; i++)
	{
		printerDict = [printer objectAtIndex: i];

		if ([[printerDict valueForKey: @"defaultPrinter"] isEqualToString: @"1"])
		{
			[m_PrinterController setSelectionIndex: i];
			break;
		}
	}

	// set printer defaults for undo
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"AYDicomPrinter"])
	{
		m_PrinterDefaults = [[NSArray arrayWithArray: [[NSUserDefaults standardUserDefaults] objectForKey: @"AYDicomPrinter"]] retain];
	}
}

- (IBAction) saveList: (id) sender
{
	NSSavePanel	*panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[@"plist"];
    panel.nameFieldStringValue = NSLocalizedString(@"DICOMPrinters.plist", nil);
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;
        
        [[m_PrinterController arrangedObjects] writeToURL:panel.URL atomically:YES];
    }];
}

- (IBAction) loadList: (id) sender
{
	NSOpenPanel	*panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"plist"];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton)
            return;

        NSArray	*r = [NSArray arrayWithContentsOfURL:panel.URL];
        if (r)
        {
            if( NSRunInformationalAlertPanel(NSLocalizedString(@"Load printers", nil), NSLocalizedString(@"Should I add or replace the printer list? If you choose 'replace', the current list will be deleted.", nil), NSLocalizedString(@"Add", nil), NSLocalizedString(@"Replace", nil), nil) == NSAlertDefaultReturn)
            {
                
            }
            else [m_PrinterController removeObjects: [m_PrinterController arrangedObjects]];
            
            [m_PrinterController addObjects: r];
            
            int i, x;
            
            for( i = 0; i < [[m_PrinterController arrangedObjects] count]; i++)
            {
                NSDictionary	*server = [[m_PrinterController arrangedObjects] objectAtIndex: i];
                
                for( x = 0; x < [[m_PrinterController arrangedObjects] count]; x++)
                {
                    NSDictionary	*c = [[m_PrinterController arrangedObjects] objectAtIndex: x];
                    
                    if( c != server)
                    {
                        if( [[server valueForKey:@"host"] isEqualToString: [c valueForKey:@"host"]] &&
                           [[server valueForKey:@"port"] isEqualToString: [c valueForKey:@"port"]])
                        {
                            [m_PrinterController removeObjectAtArrangedObjectIndex: i];
                            i--;
                            x = [[m_PrinterController arrangedObjects] count];
                        }
                    }
                }
            }
        }
    }];
}

- (IBAction) addPrinter: (id) sender
{
	int printerCount = [[m_PrinterController arrangedObjects] count] + 1;
	NSMutableDictionary *printer = [NSMutableDictionary dictionary];

	// add default printer with default values
	[printer setValue: [NSString stringWithFormat: @"Printer %d", printerCount] forKey: @"printerName"];
	[printer setValue: @"localhost" forKey: @"host"];
	[printer setValue: @"4080" forKey: @"port"];
	[printer setValue: [NSString stringWithFormat: @"Printer_%d", printerCount] forKey: @"aeTitle"];
	
	[printer setValue: @"0" forKey: @"imageDisplayFormatTag"];
	[printer setValue: @"0" forKey: @"borderDensityTag"];
	[printer setValue: @"0" forKey: @"emptyImageDensityTag"];
	[printer setValue: @"0" forKey: @"filmOrientationTag"];
	[printer setValue: @"0" forKey: @"filmDestinationTag"];
	[printer setValue: @"0" forKey: @"magnificationTypeTag"];
	[printer setValue: @"0" forKey: @"trimTag"];
	[printer setValue: @"0" forKey: @"filmSizeTag"];
	[printer setValue: @"" forKey: @"configurationInformation"];
	[printer setValue: @"0" forKey: @"priorityTag"];
	[printer setValue: @"0" forKey: @"mediumTag"];
	[printer setValue: @"1" forKey: @"copies"];
	
	// add new printer & select it
	[m_PrinterController addObject: printer];
	[m_PrinterController setSelectedObjects: [NSArray arrayWithObject: printer]];

	// if it is the first printer added, set it as default
	if ([[m_PrinterController arrangedObjects] count] == 1)
		[self setDefaultPrinter: nil];
}

- (IBAction) setDefaultPrinter: (id) sender
{
	// set new default printer
	NSArray *printer = [m_PrinterController arrangedObjects];

	int i;
	NSMutableDictionary *printerDict;
	for (i = 0; i < [printer count]; i++)
	{
		printerDict = [printer objectAtIndex: i];
		[printerDict removeObjectForKey: @"defaultPrinter"];
	}

	printerDict = [m_PrinterController selection];
	[printerDict setValue: @"1" forKey: @"defaultPrinter"];
}

@end
