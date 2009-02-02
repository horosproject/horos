#import "AYDicomPrintPref.h"


@implementation AYDicomPrintPref

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
	
	if( aView == _authView) return;
	
    if( [aView isKindOfClass: [NSControl class]])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }

	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject]) {
        [self checkView:view :OnOff];
    }
}

- (void) enableControls: (BOOL) val
{
	[self checkView: [self mainView] :val];
}

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    [self enableControls: YES];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"]) [self enableControls: NO];
}

- (NSNumber*) editable
{
	if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) return [NSNumber numberWithBool: YES];
	
	return [NSNumber numberWithBool: NO];
}

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
	[_authView setDelegate:self];
	if( [[NSUserDefaults standardUserDefaults] boolForKey:@"AUTHENTICATION"])
	{
		[_authView setString:"com.rossetantoine.osirix.aydicomprint"];
		if( [_authView authorizationState] == SFAuthorizationViewUnlockedState) [self enableControls: YES];
		else [self enableControls: NO];
	}
	else
	{
		[_authView setString:"com.rossetantoine.osirix.preferences.allowalways"];
		[_authView setEnabled: NO];
	}
	[_authView updateStatus:self];
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
	[printer setValue: @"BILINEAR" forKey: @"magnificationType"];
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