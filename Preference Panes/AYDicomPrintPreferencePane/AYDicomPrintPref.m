//
//  AYDicomPrintPref.m
//  AYDicomPrint
//
//  Created by Tobias Hoehmann on 12.06.06.
//  Copyright (c) 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import "AYDicomPrintPref.h"


@implementation AYDicomPrintPref

- (id) init
{
	if (self = [super init])
	{
	}

	return self;
}

- (void) dealloc
{
	[m_PrinterDefaults release];
	m_PrinterDefaults = nil;

	[super dealloc];
}

- (void) mainViewDidLoad
{
}

- (void) awakeFromNib
{
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

- (IBAction) addPrinter: (id) sender
{
	int printerCount = [[m_PrinterController arrangedObjects] count] + 1;
	NSMutableDictionary *printer = [NSMutableDictionary dictionary];

	// add default printer with default values
	[printer setValue: [NSString stringWithFormat: @"Printer %d", printerCount] forKey: @"printerName"];
	[printer setValue: @"localhost" forKey: @"host"];
	[printer setValue: @"4080" forKey: @"port"];
	[printer setValue: [NSString stringWithFormat: @"Printer_%d", printerCount] forKey: @"aeTitle"];
	[printer setValue: @"Standard 1,1" forKey: @"imageDisplayFormat"];
	[printer setValue: @"BLACK" forKey: @"borderDensity"];
	[printer setValue: @"BLACK" forKey: @"emptyImageDensity"];
	[printer setValue: @"Portrait" forKey: @"filmOrientation"];
	[printer setValue: @"Processor" forKey: @"filmDestination"];
	[printer setValue: @"NONE" forKey: @"magnificationType"];
	[printer setValue: @"NO" forKey: @"trim"];
	[printer setValue: @"8 IN x 10 IN" forKey: @"filmSize"];
	[printer setValue: @"" forKey: @"configurationInformation"];
	[printer setValue: @"MED" forKey: @"priority"];
	[printer setValue: @"Blue Film" forKey: @"medium"];
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

/* not needed by now
- (IBAction) applyChanges: (id) sender
{
	// synchronize changes
	[[NSUserDefaults standardUserDefaults] synchronize];

	// set printer defaults for undo
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"AYDicomPrinter"])
	{
		if (m_PrinterDefaults)
			[m_PrinterDefaults release];
		m_PrinterDefaults = [[NSArray arrayWithArray: [[NSUserDefaults standardUserDefaults] objectForKey: @"AYDicomPrinter"]] retain];
	}
}

- (IBAction) restoreChanges: (id) sender
{
	// restore changes
	[[NSUserDefaults standardUserDefaults] setObject: m_PrinterDefaults forKey: @"AYDicomPrinter"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
*/
@end