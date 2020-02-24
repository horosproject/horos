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

#import "QueryController.h"
#import "AYDicomPrintWindowController.h"
#import "AYDicomPrintPref.h"
#import "NSFont_OpenGL.h"
#import "AYNSImageToDicom.h"
#import "Notifications.h"
#import "OSIWindow.h"
#import "ThreadsManager.h"
#import "NSUserDefaults+OsiriX.h"
#import "N2Debug.h"
#import "AppController.h"

// Template for DCMTK presentation state command-line applications (sample .cfg files in DCMTK source under dcmpstat/etc)
//
static NSString* const DCMTK_PRINTER_CONFIG_TEMPLATE = @"\n\
[[GENERAL]]\n\
\n\
[DATABASE]\n\
Directory = database\n\
\n\
[NETWORK]\n\
aetitle = {{HOROS_AETITLE}}\n\
\n\
[[COMMUNICATION]]\n\
\n\
[PRINTSCP]\n\
Aetitle = {{PRINTER_AETITLE}}\n\
Description = DICOM Printer\n\
Hostname = {{HOST}}\n\
Port = {{PORT}}\n\
Type = LOCALPRINTER\n\
DisableNewVRs = true\n\
DisplayFormat={{COLUMNS}},{{ROWS}}\n\
FilmDestination = {{FILM_DESTINATION}}\n\
FilmSizeID = {{FILM_SIZE}}\n\
ImplicitOnly = true\n\
MagnificationType = {{MAGNIFICATION_TYPE}}\n\
MaxDensity = 320\n\
MaxPDU = 16384\n\
MediumType = {{MEDIUM_TYPE}}\n\
OmitSOPClassUIDFromCreateResponse = true\n\
PresentationLUTMatchRequired = true\n\
PresentationLUTinFilmSession = false\n\
Supports12Bit = false\n\
SupportsPresentationLUT = false";

static NSString* const DCMTK_LOGGER_CONFIG_TEMPLATE = @"log4cplus.rootLogger = INFO, logfile\n\
log4cplus.appender.logfile = log4cplus::FileAppender\n\
log4cplus.appender.logfile.File = {{LOG_DIRECTORY}}/print.log\n\
log4cplus.appender.logfile.Append = true\n\
log4cplus.appender.logfile.ImmediateFlush = true";

#define VERSIONNUMBERSTRING	@"v1.00.000"
#define ECHOTIMEOUT 5

NSString *filmOrientationTag[] = {@"Portrait", @"Landscape"};
NSString *filmDestinationTag[] = {@"Processor", @"Magazine"};
NSString *filmSizeTag[] = {@"8 IN x 10 IN", @"8.5 IN x 11 IN", @"10 IN x 12 IN", @"10 IN x 14 IN", @"11 IN x 14 IN", @"11 IN x 17 IN", @"14 IN x 14 IN", @"14 IN x 17 IN", @"24 CM x  24 CM", @"24 CM x  30 CM", @"A4", @"A3"};
NSString *magnificationTypeTag[] = {@"NONE", @"BILINEAR", @"CUBIC", @"REPLICATE"};
NSString *trimTag[] = {@"NO", @"YES"};
NSString *imageDisplayFormatTag[] = {@"Standard 1,1",@"Standard 1,2",@"Standard 2,1",@"Standard 2,2",@"Standard 2,3",@"Standard 2,4",@"Standard 3,3",@"Standard 3,4",@"Standard 3,5",@"Standard 4,4",@"Standard 4,5",@"Standard 4,6",@"Standard 5,6",@"Standard 5,7"};
int imageDisplayFormatNumbers[] = {1,2,2,4,6,8,9,12,15,16,20,24,30,35};
int imageDisplayFormatRows[] =    {1,1,2,2,2,2,3, 3, 3, 4, 4, 4, 5, 5};
int imageDisplayFormatColumns[] = {1,2,1,2,3,4,3, 4, 5, 4, 5, 6, 6, 7};
NSString *borderDensityTag[] = {@"BLACK", @"WHITE"};
NSString *emptyImageDensityTag[] = {@"BLACK", @"WHITE"};
NSString *priorityTag[] = {@"HIGH", @"MED", @"LOW"};
NSString *mediumTag[] = {@"Blue Film", @"Clear Film", @"Paper"};


@interface AYDicomPrintWindowController (Private)
- (void) _createPrintjob: (id) object __attribute__((deprecated));
- (void) _sendPrintjob: (NSString *) xmlPath __attribute__((deprecated));
- (void) _createPrintjobDCMTK: (id) object;
- (void) _sendPrintjobDCMTK: (NSString *) printJobDir;
- (BOOL) _verifyConnection: (NSDictionary *) dict;
- (void) _verifyConnections: (id) object;
- (void) _setProgressMessage: (NSString *) message;
- (ViewerController *) _currentViewer;
@end

@implementation AYDicomPrintWindowController

#define NUM_OF(x) (sizeof (x) / sizeof *(x))

+ (NSString*) tagForKey: (NSString*) v array: (NSString *[]) array size: (int) size
{
	for( int i = 0 ; i < size; i++)
	{
		if( [array[ i] isEqualToString: v])
			return [NSString stringWithFormat: @"%d", i];
	}
	
	NSLog( @"*** not found updateAllPreferencesFormat : %@", v);
	
	return @"0";
}

+ (void) updateAllPreferencesFormat
{
	BOOL updated = NO;
	NSMutableArray *printers = [[[[NSUserDefaults standardUserDefaults] arrayForKey: @"AYDicomPrinter"] mutableCopy] autorelease];
	
	for( int i = 0 ; i < [printers count] ; i++)
	{
		NSDictionary *dict = [printers objectAtIndex: i];
		
		if( [dict valueForKey: @"imageDisplayFormatTag"] == nil)
		{
			NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary: dict];
			
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"filmOrientation"] array: filmOrientationTag size: NUM_OF(filmOrientationTag)] forKey: @"filmOrientationTag"];
             
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"filmDestination"] array: filmDestinationTag size: NUM_OF(filmDestinationTag)] forKey: @"filmDestinationTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"filmSize"] array: filmSizeTag size: NUM_OF(filmSizeTag)] forKey: @"filmSizeTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"magnificationType"] array: magnificationTypeTag size: NUM_OF(magnificationTypeTag)] forKey: @"magnificationTypeTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"trim"] array: trimTag size: NUM_OF(trimTag)] forKey: @"trimTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"imageDisplayFormat"] array: imageDisplayFormatTag size: NUM_OF(imageDisplayFormatTag)] forKey: @"imageDisplayFormatTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"borderDensity"] array: borderDensityTag size: NUM_OF(borderDensityTag)] forKey: @"borderDensityTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"emptyImageDensity"] array: emptyImageDensityTag size: NUM_OF(emptyImageDensityTag)] forKey: @"emptyImageDensityTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"priority"] array: priorityTag size: NUM_OF(priorityTag)] forKey: @"priorityTag"];
			[mDict setObject: [AYDicomPrintWindowController tagForKey: [dict valueForKey: @"medium"] array: mediumTag size: NUM_OF(mediumTag)] forKey: @"mediumTag"];
			
			[printers replaceObjectAtIndex: i withObject: mDict];
			
			updated = YES;
		}
	}
	
	if( updated)
	{
		[[NSUserDefaults standardUserDefaults] setObject: printers forKey: @"AYDicomPrinter"];
	}
}

- (id) init
{
	if (self = [super init])
	{
		[AYDicomPrintWindowController updateAllPreferencesFormat];
		
		// fetch current viewer
		m_CurrentViewer = [self _currentViewer];
        
		// initialize printer state images
		m_PrinterOnImage = [[NSImage imageNamed: @"available"] retain];
		m_PrinterOffImage = [[NSImage imageNamed: @"away"] retain];
		
		printing = [[NSLock alloc] init];
        
        windowFrameToRestore = NSMakeRect(0, 0, 0, 0);
        scaleFitToRestore = m_CurrentViewer.imageView.isScaledFit;
        
        if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SquareWindowForPrinting"])
        {
            int AlwaysScaleToFit = [[NSUserDefaults standardUserDefaults] integerForKey: @"AlwaysScaleToFit"];
            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"AlwaysScaleToFit"];
            
            windowFrameToRestore = m_CurrentViewer.window.frame;
            NSRect newFrame = [AppController usefullRectForScreen: m_CurrentViewer.window.screen];
            
            if( newFrame.size.width < newFrame.size.height) newFrame.size.height = newFrame.size.width;
            else newFrame.size.width = newFrame.size.height;
            
            [AppController resizeWindowWithAnimation: m_CurrentViewer.window newSize: newFrame];
            if( scaleFitToRestore) [m_CurrentViewer.imageView scaleToFit];
            
            [[NSUserDefaults standardUserDefaults] setInteger: AlwaysScaleToFit forKey: @"AlwaysScaleToFit"];
        }
        
        for( ViewerController *v in [ViewerController getDisplayed2DViewers])
        {
            if( v != m_CurrentViewer)
                [v.window orderOut: self];
        }
        
        [[self window] center];
	}

	return self;
}
//
//- (void) windowWillClose: (NSNotification*) n
//{
//    if( NSIsEmptyRect( windowFrameToRestore) == NO)
//        [AppController resizeWindowWithAnimation: m_CurrentViewer.window newSize: windowFrameToRestore];
//}

- (void) dealloc
{
	[printing release];
	[m_PrinterOnImage release];
	[m_PrinterOffImage release];
	
	[super dealloc];
}

- (NSString *) windowNibName
{
	return @"AYDicomPrint";
}

- (void) awakeFromNib
{
	NSArray *printers = [m_PrinterController arrangedObjects];

	// show dialog if no printers are configured OR open modal print dialog
	if ([printers count] == 0)
	{
		NSRunAlertPanel(NSLocalizedString(@"DICOM Print", nil), NSLocalizedString(@"No DICOM printers were found, please add a dicom printer in the preferences.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		[self close];
		return;
	}

	// set default printer & printer state to off
	int i;
	NSMutableDictionary *printerDict;
	for (i = 0; i < [printers count]; i++)
	{
		printerDict = [printers objectAtIndex: i];
		[printerDict setValue: m_PrinterOffImage forKey: @"state"];

		if ([[printerDict valueForKey: @"defaultPrinter"] isEqualTo: @"1"])
			[m_PrinterController setSelectionIndex: i];
	}

	[m_ProgressIndicator setUsesThreadedAnimation: YES];
	[m_ProgressIndicator startAnimation: self];
	[m_VersionNumberTextField setStringValue: VERSIONNUMBERSTRING];
    
	[NSThread detachNewThreadSelector: @selector(_verifyConnections:) toTarget: self withObject: [m_PrinterController arrangedObjects]];
	
	[entireSeriesFrom setMaxValue: [[m_CurrentViewer pixList] count]];
	[entireSeriesTo setMaxValue: [[m_CurrentViewer pixList] count]];
	
	[entireSeriesFrom setNumberOfTickMarks: [[m_CurrentViewer pixList] count]];
	[entireSeriesTo setNumberOfTickMarks: [[m_CurrentViewer pixList] count]];
	
	if( [[m_CurrentViewer pixList] count] < 20)
	{
		[entireSeriesFrom setIntValue: 1];
		[entireSeriesTo setIntValue: [[m_CurrentViewer pixList] count]];
		[entireSeriesInterval setIntValue: 1];
	}
	else
	{
		if( [[m_CurrentViewer imageView] flippedData]) [entireSeriesFrom setIntValue: [[m_CurrentViewer pixList] count] - [[m_CurrentViewer imageView] curImage]];
		else [entireSeriesFrom setIntValue: 1+ [[m_CurrentViewer imageView] curImage]];
		[entireSeriesTo setIntValue: [[m_CurrentViewer pixList] count]];
	}
	
	[entireSeriesToText setIntValue: [entireSeriesTo intValue]];
	[entireSeriesFromText setIntValue: [entireSeriesFrom intValue]];
	[entireSeriesIntervalText setIntValue: [entireSeriesInterval intValue]];
	
	[self setPages: self];
	
	[NSApp runModalForWindow: [self window]];
}

- (IBAction) cancel: (id) sender
{
	[NSApp stopModal];
	
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"SquareWindowForPrinting"] && NSIsEmptyRect( windowFrameToRestore) == NO)
    {
        int AlwaysScaleToFit = [[NSUserDefaults standardUserDefaults] integerForKey: @"AlwaysScaleToFit"];
        [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"AlwaysScaleToFit"];
        
        [AppController resizeWindowWithAnimation: m_CurrentViewer.window newSize: windowFrameToRestore];
        
        if( scaleFitToRestore) [m_CurrentViewer.imageView scaleToFit];
        
        [[NSUserDefaults standardUserDefaults] setInteger: AlwaysScaleToFit forKey: @"AlwaysScaleToFit"];
    }
    
    for( ViewerController *v in [ViewerController get2DViewers])
        [v.window orderFront: self];
    
    [m_CurrentViewer.window makeKeyAndOrderFront: self];
    
    [self close];
}

- (IBAction) printImages: (id) sender
{
	if( [m_pages intValue] > 10 && [[m_ImageSelection selectedCell] tag] == eAllImages)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Print", nil), NSLocalizedString(@"Are you really sure you want to print %d pages?", nil) , NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), nil, [m_pages intValue]) != NSAlertDefaultReturn) return;
	}
	
	[sender setEnabled: NO];
    
    [self _createPrintjobDCMTK];
	
	[self cancel: self];
}

- (IBAction) verifyConnection: (id) sender
{
	[NSThread detachNewThreadSelector: @selector(_verifyConnections:) toTarget: self withObject: [m_PrinterController selectedObjects]];
}

- (IBAction) closeSheet: (id) sender
{
	[NSApp endSheet: m_ProgressSheet];
	[m_ProgressSheet orderOut: self];
	[m_PrintButton setEnabled: YES];
	[m_PrintButton setNeedsDisplay: YES];
}

- (void)checkView:(NSView *)aView :(BOOL) OnOff
{
    id view;
    NSEnumerator *enumerator;
  
    if ([aView isKindOfClass: [NSControl class] ])
	{
       [(NSControl*) aView setEnabled: OnOff];
	   return;
    }
	
	// Recursively check all the subviews in the view
    enumerator = [ [aView subviews] objectEnumerator];
    while (view = [enumerator nextObject])
	{
        [self checkView:view :OnOff];
    }
}

- (IBAction) exportDICOMSlider:(id) sender
{
	if( [[m_ImageSelection selectedCell] tag] == eAllImages)
	{
		[entireSeriesFromText takeIntValueFrom: entireSeriesFrom];
		[entireSeriesToText takeIntValueFrom: entireSeriesTo];
		
		if( [[m_CurrentViewer imageView] flippedData]) [[m_CurrentViewer imageView] setIndex: [[m_CurrentViewer pixList] count] - [sender intValue]];
		else [[m_CurrentViewer imageView] setIndex:  [sender intValue]-1];
		
		[[m_CurrentViewer imageView] sendSyncMessage:0];
		
		[m_CurrentViewer adjustSlider];
		
		[self setPages: self];
	}
}

- (IBAction) setPages:(id) sender
{
	int no_of_images = 0;
	
	NSDictionary *dict = [[m_PrinterController selectedObjects] objectAtIndex: 0];
	
	if ([[formatPopUp menu] itemWithTag: [[dict valueForKey: @"imageDisplayFormatTag"] intValue]] == nil)
	{
		[[[m_PrinterController selectedObjects] objectAtIndex: 0] setObject: @"0" forKey:@"imageDisplayFormat"];
	}
	
	int ipp = imageDisplayFormatNumbers[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
	
	if( [[m_ImageSelection selectedCell] tag] == eAllImages)
	{
		if( sender == entireSeriesTo) [entireSeriesToText setIntValue: [entireSeriesTo intValue]];
		if( sender == entireSeriesFrom) [entireSeriesFromText setIntValue: [entireSeriesFrom intValue]];
		
		if( sender == entireSeriesToText) [entireSeriesTo setIntValue: [entireSeriesToText intValue]];
		if( sender == entireSeriesFromText) [entireSeriesFrom setIntValue: [entireSeriesFromText intValue]];
		
		int from = [entireSeriesFrom intValue]-1;
		int to = [entireSeriesTo intValue];
		
		if( from >= to)
		{
			to = [entireSeriesFrom intValue];
			from = [entireSeriesTo intValue]-1;
		}
		
		for( int i = from; i < to; i += [entireSeriesInterval intValue])
		{
			no_of_images++;
		}
		
//		no_of_images = (to - from) / [entireSeriesInterval intValue];
	}
	else if( [[m_ImageSelection selectedCell] tag] == eCurrentImage) no_of_images = 1;
	else if( [[m_ImageSelection selectedCell] tag] == eKeyImages)
	{
		int i;
		
		NSArray *fileList = [m_CurrentViewer fileList];
        NSArray *roiList = [m_CurrentViewer roiList];
		
		no_of_images = 0;
		for (i = 0; i < [fileList count]; i++)
		{
			if ([[[fileList objectAtIndex: i] valueForKey: @"isKeyImage"] boolValue] || [[roiList objectAtIndex: i] count]) no_of_images++;
		}
	}
	
	if( [[NSUserDefaults standardUserDefaults] boolForKey: @"autoAdjustPrintingFormat"])
	{
		NSInteger index = 0, no;
		do
		{
			no = imageDisplayFormatNumbers[[[[formatPopUp menu] itemAtIndex: index] tag]];
			index++;
		}
		while( no_of_images > no && index < [[formatPopUp menu] numberOfItems]);
		
		NSMutableDictionary *currentPrinter = [[m_PrinterController selectedObjects] objectAtIndex: 0];
		
		if( no == 2)
		{
			if( [[filmOrientationTag[[[dict valueForKey: @"filmOrientationTag"] intValue]] uppercaseString] isEqualToString: @"PORTRAIT"])
				[currentPrinter setObject: @"1" forKey:@"imageDisplayFormatTag"];
			else
				[currentPrinter setObject: @"2" forKey:@"imageDisplayFormatTag"];
		}
		else
		{
			[currentPrinter setObject: [NSString stringWithFormat: @"%d", (int) index-1]  forKey:@"imageDisplayFormatTag"];
			ipp = imageDisplayFormatNumbers[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
		}
	}
	
	if( no_of_images == 0) [m_pages setIntValue: 1];
	else if( no_of_images % ipp == 0)  [m_pages setIntValue: no_of_images / ipp];
	else [m_pages setIntValue: 1 + (no_of_images / ipp)];
}

- (IBAction) setExportMode:(id) sender
{
	if( [[sender selectedCell] tag] == eAllImages) [self checkView: entireSeriesBox :YES];
	else [self checkView: entireSeriesBox :NO];
	
	[self setPages: self];
}

- (ViewerController *) _currentViewer
{
	NSArray *windows = [NSApp windows];

	int i;
	for(i = 0; i < [windows count]; i++)
	{
		if([[[windows objectAtIndex: i] windowController] isKindOfClass: [ViewerController class]] &&
			[[windows objectAtIndex: i] isMainWindow])
		{
			return [[windows objectAtIndex: i] windowController];
			break;
		}
	}

	return nil;
}

// HOROS-532: using DCMTK commands to create print objects and sent to printer to replace legacy 32-bit aycan binaries.
//
- (void) _createPrintjobDCMTK
{
    // show progress sheet
    [self _setProgressMessage: nil];
    [NSApp beginSheet: m_ProgressSheet modalForWindow: [self window] modalDelegate: self didEndSelector: nil contextInfo: nil];
    
    // dictionary for selected printer
    NSDictionary *dict = [[m_PrinterController selectedObjects] objectAtIndex: 0];
    
    // show alert, if displayFormat is invalid
    if ([[formatPopUp menu] itemWithTag: [[dict valueForKey: @"imageDisplayFormatTag"] intValue]] == nil)
    {
        NSLog( @"_createPrintjobDCMTK invalid format" );
        [self _setProgressMessage: NSLocalizedString( @"The Format you selected is not valid.", nil)];
        [self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString( @"The Format you selected is not valid.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
    }
    else
    {
        // Create directory for print log, if it doesn't already exist.
        //
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/HorosDicomPrint"];
        if (![fileManager fileExistsAtPath: logPath])
        {
            if (![fileManager createDirectoryAtPath: logPath withIntermediateDirectories:YES attributes:nil error:NULL])
            {
                NSLog( @"_createPrintjobDCMTK failed to create log directory for print job." );
                logPath = @"log"; // default to subdirectory in temp area
            }
        }
        
        // Create temporary directory for print job files
        //
        NSMutableString* printJobID = [NSMutableString stringWithString: [[NSDate date] description]];
        [printJobID replaceOccurrencesOfString: @" " withString: @"-" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printJobID length])];
        NSString *printJobDir = [NSString stringWithFormat: @"/tmp/dicomPrint-%@", printJobID];
        
        // remove destination directory
        if ([fileManager fileExistsAtPath: printJobDir])
        {
            [fileManager removeItemAtPath: printJobDir error:NULL];
        }
        
        // create destination directory
        //
        if ([fileManager fileExistsAtPath: printJobDir] || ![fileManager createDirectoryAtPath: printJobDir withIntermediateDirectories:YES attributes:nil error:NULL])
        {
            NSLog( @"_createPrintjobDCMTK create directory error" );
            [self _setProgressMessage: NSLocalizedString( @"Can't write to temporary directory.", nil)];
            [self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString( @"Can't write to temporary directory.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
        }
        else
        {
            // HOROS-532: replacing aycan 32-bit print binaries with calls to DCMTK command-line applications.
            //
            // Create a printer configuration file with the neccessary values.
            //
            NSString *loggerConfigPath = [NSString stringWithFormat: @"%@/logger.cfg", printJobDir];
            NSString *printConfigPath = [NSString stringWithFormat: @"%@/print.cfg", printJobDir];
            NSString *printScriptPath = [NSString stringWithFormat: @"%@/print.sh", printJobDir];
            int copies = [[dict valueForKey: @"copies"] intValue];
            int rows = imageDisplayFormatRows[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
            int columns = imageDisplayFormatColumns[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
            NSMutableString *filmSize = [NSMutableString stringWithString: filmSizeTag[[[dict valueForKey: @"filmSizeTag"] intValue]]];
            [filmSize replaceOccurrencesOfString: @" " withString: @"" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [filmSize length])];
            [filmSize replaceOccurrencesOfString: @"." withString: @"_" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [filmSize length])];
            NSString *aeTitle = [NSUserDefaults defaultAETitle];
            if (!aeTitle)
            {
                aeTitle = @"HOROS_DICOM_PRINT";
            }
            
            NSMutableString* printConfig = [NSMutableString stringWithString: DCMTK_PRINTER_CONFIG_TEMPLATE];
            [printConfig replaceOccurrencesOfString:@"{{PRINTER_AETITLE}}" withString:[dict valueForKey: @"aeTitle"] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{HOST}}" withString:[dict valueForKey: @"host"] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{PORT}}" withString:[dict valueForKey: @"port"] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{HOROS_AETITLE}}" withString:aeTitle options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{COLUMNS}}" withString:[NSString stringWithFormat: @"%d", columns] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{ROWS}}" withString:[NSString stringWithFormat: @"%d", rows] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{FILM_DESTINATION}}" withString:[filmDestinationTag[[[dict valueForKey: @"filmDestinationTag"] intValue]] uppercaseString] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{FILM_SIZE}}" withString:[filmSize uppercaseString] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{MEDIUM_TYPE}}" withString:[mediumTag[[[dict valueForKey: @"mediumTag"] intValue]] uppercaseString] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            [printConfig replaceOccurrencesOfString:@"{{MAGNIFICATION_TYPE}}" withString:magnificationTypeTag[[[dict valueForKey: @"magnificationTypeTag"] intValue]] options:NSCaseInsensitiveSearch range: NSMakeRange(0, [printConfig length])];
            
            NSMutableString* loggerConfig = [NSMutableString stringWithString: DCMTK_LOGGER_CONFIG_TEMPLATE];
            [loggerConfig replaceOccurrencesOfString:@"{{LOG_DIRECTORY}}" withString:logPath options:NSCaseInsensitiveSearch range: NSMakeRange(0, [loggerConfig length])];
            
            // Create script for this print job.
            //
            NSMutableString* printScript = [[[NSMutableString alloc] init] autorelease];
            [printScript appendFormat: @"export DCMDICTPATH=\"%@/dicom.dic\"\n", [[NSBundle mainBundle] resourcePath]];
            [printScript appendFormat: @"cd \"%@\"\n", printJobDir];
            [printScript appendFormat: @"mkdir \"%@/log\"\n", printJobDir]; // backup dir for log
            [printScript appendFormat: @"mkdir \"%@/database\" 2>&1 >> \"%@/print.log\"\n", printJobDir, logPath];
            [printScript appendFormat: @"echo \"`date`: Starting print job %@\" >> \"%@/print.log\"\n", printJobID, logPath];
            
            int ipp = imageDisplayFormatNumbers[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
            
            int from = [entireSeriesFrom intValue]-1;
            int to = [entireSeriesTo intValue];
            
            if( to < from)
            {
                to = [entireSeriesFrom intValue];
                from = [entireSeriesTo intValue]-1;
            }
            
            if( from < 0) from = 0;
            if( to == from) to = from+1;
            
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: columns], @"columns", [NSNumber numberWithInt: rows], @"rows", [NSNumber numberWithInt: [[m_ImageSelection selectedCell] tag]], @"mode", [NSNumber numberWithInt: from], @"from", [NSNumber numberWithInt: to], @"to", [NSNumber numberWithInt: [entireSeriesInterval intValue]], @"interval", nil];
            
            // DCMTK command-line apps only support grayscale. +TODO+ add support for color, requires extending DCMTK commands.
            //
            BOOL colorPrint = [[dict valueForKey: @"colorPrint"] intValue];
            if (colorPrint)
            {
                colorPrint = NO;
            }
            
            // Collect images for printing
            //
            AYNSImageToDicom *dicomConverter = [[[AYNSImageToDicom alloc] init] autorelease];
            dicomConverter.prepareForDCMTK = YES;
            NSArray *images = [dicomConverter dicomFileListForViewer: m_CurrentViewer destinationPath: printJobDir options: options asColorPrint: colorPrint withAnnotations: NO];
            
            // check, if images were collected
            if ([images count] == 0)
            {
                [self _setProgressMessage: NSLocalizedString( @"There are no images selected.", nil)];
                [self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString( @"There are no images selected.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
            }
            else
            {
                for( int i = 0; i <= ([images count] - 1) / ipp; i++)
                {
                    // Format command to create the presentation state for the page ("filmbox").
                    // DCMTK command-line seems to only handle setting up one page printing, so creating one for each "filmbox".
                    //
                    [printScript appendFormat: @"\"%@/dcmpsprt\" -c \"%@\" -lc \"%@\" --printer PRINTSCP --layout %d %d --filmsize %@ --magnification %@ --configinfo \"%@\" --border %@ --empty-image %@ ",
                     [[NSBundle mainBundle] resourcePath],
                     printConfigPath,
                     loggerConfigPath,
                     columns,
                     rows,
                     [filmSize uppercaseString],
                     magnificationTypeTag[[[dict valueForKey: @"magnificationTypeTag"] intValue]],
                     [dict valueForKey: @"configurationInformation"],
                     borderDensityTag[[[dict valueForKey: @"borderDensityTag"] intValue]],
                     emptyImageDensityTag[[[dict valueForKey: @"emptyImageDensityTag"] intValue]]];
                    if ([[dict valueForKey: @"trimTag"] intValue] == 0)
                    {
                        [printScript appendString: @"--no-trim "];
                    }
                    else
                    {
                        [printScript appendString: @"--trim "];
                    }
                    if ([[dict valueForKey: @"filmOrientationTag"] intValue] == 0)
                    {
                        [printScript appendString: @"--portrait "];
                    }
                    else
                    {
                        [printScript appendString: @"--landscape "];
                    }
                    [printScript appendString: @"\\\n"];
                    
                    // Add DICOM file to command ("imagebox")
                    //
                    for (int j = i * ipp; j < MIN(i * ipp + ipp, [images count]); j++)
                    {
                        if( [[images objectAtIndex: j] length] > 0)
                        {
                            [printScript appendFormat: @" \"%@\"\\\n", [images objectAtIndex: j]];
                        }
                    }
                    [printScript appendString: @"\n"];
                }
                
                // Format command to send the presentation states to the printer.
                //
                [printScript appendFormat: @"\"%@/dcmprscu\" -c \"%@\" -lc \"%@\" --printer PRINTSCP --copies %d --priority %@ --destination %@ --medium-type %@ %@/database/SP_*\n",
                 [[NSBundle mainBundle] resourcePath],
                 printConfigPath,
                 loggerConfigPath,
                 copies,
                 priorityTag[[[dict valueForKey: @"priorityTag"] intValue]],
                 [filmDestinationTag[[[dict valueForKey: @"filmDestinationTag"] intValue]] uppercaseString],
                 [mediumTag[[[dict valueForKey: @"mediumTag"] intValue]] uppercaseString],
                 printJobDir];
                
                [printScript appendFormat: @"echo \"`date`: End print job %@ [status=$?]\" >> \"%@/print.log\"\n", printJobID, logPath];
                
                if (![loggerConfig writeToFile:loggerConfigPath atomically:YES encoding:NSWindowsCP1250StringEncoding error:NULL] ||
                    ![printConfig writeToFile:printConfigPath atomically:YES encoding:NSWindowsCP1250StringEncoding error:NULL] ||
                    ![printScript writeToFile:printScriptPath atomically:YES encoding:NSWindowsCP1250StringEncoding error:NULL])
                {
                    NSLog( @"_createPrintjobDCMTK unable to create files in temp dir" );
                    [self _setProgressMessage: NSLocalizedString( @"Can't write to temporary directory.", nil)];
                    [self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString( @"Can't write to temporary directory.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
                    [[NSFileManager defaultManager] removeItemAtPath: printJobDir error:NULL];
                }
                else
                {
                    // Send printjob to printer
                    //
                    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(_sendPrintjobDCMTK:) object: printJobDir] autorelease];
                    t.name = NSLocalizedString( @"DICOM Printing...", nil);
                    [[ThreadsManager defaultManager] addThreadAndStart: t];
                }
            }
        }
    }
    
    [self closeSheet: self];
}

- (void) _sendPrintjobDCMTK: (NSString *) printJobDir
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [printJobDir retain];
    
    [printing lock];
    
    NSTask* theTask = nil;
    
    @try
    {
        theTask = [[NSTask alloc] init];

        NSString* printScriptPath = [NSString stringWithFormat: @"%@/print.sh", printJobDir];
        [theTask setArguments: [NSArray arrayWithObjects: printScriptPath, nil]];
        [theTask setLaunchPath:@"/bin/bash"];
        [theTask launch];
        while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];

        int status = [theTask terminationStatus];

        if (status != 0)
        {
            [self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString(@"Couldn't print images.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
        }
    }
    @catch (NSException * e)
    {
        N2LogExceptionWithStackTrace(e);
    }
    @finally
    {
        // remove temporary files
        [[NSFileManager defaultManager] removeItemAtPath: printJobDir error:NULL];
        [theTask release];
    }
    
    [printing unlock];
    
    [printJobDir release];
    
    [pool release];
}

- (void) errorMessage:(NSArray*) msg
{
	NSRunCriticalAlertPanel( [msg objectAtIndex: 0], @"%@", [msg objectAtIndex: 2], nil, nil, [msg objectAtIndex: 1]) ;
}

- (void) _setProgressMessage: (NSString *) message
{
	[m_ProgressMessage setStringValue: @""];
	[m_ProgressMessage setNeedsDisplay: YES];

	if (!message)
	{
		[m_ProgressTabView selectFirstTabViewItem: self];
		[m_ProgressMessage setStringValue: NSLocalizedString( @"Printing images...", nil)];
	}
	else
	{
		[m_ProgressTabView selectLastTabViewItem: self];
		[m_ProgressMessage setStringValue: message];
	}

	[m_ProgressMessage setNeedsDisplay: YES];
}

-(void) setVerifyButton: (NSNumber*) enabled
{
    [m_VerifyConnectionButton setEnabled: enabled.boolValue];
}

-(void) setPrinterStateOn: (NSMutableDictionary*) printer
{
    [printer setValue: m_PrinterOnImage forKey: @"state"];
}

-(void) setPrinterStateOff: (NSMutableDictionary*) printer
{
    [printer setValue: m_PrinterOffImage forKey: @"state"];
}

- (void) _verifyConnections: (NSArray *) printers
{
	@autoreleasepool
    {
        [self retain];
        
        @try
        {
            [self performSelectorOnMainThread: @selector( setVerifyButton:) withObject: @NO waitUntilDone: YES];
            
            for( NSMutableDictionary *printer in printers)
            {
                if( [self _verifyConnection: printer])
                    [self performSelectorOnMainThread: @selector( setPrinterStateOn:) withObject: printer waitUntilDone: NO];
                else
                    [self performSelectorOnMainThread: @selector( setPrinterStateOff:) withObject: printer waitUntilDone: NO];
            }
        }
        @catch (NSException *exception) {
            N2LogException( exception);
        }
        [self performSelectorOnMainThread: @selector( setVerifyButton:) withObject: @YES waitUntilDone: YES];
        
        [NSThread sleepForTimeInterval: 5];
        
        [self autorelease];
	}
}

- (BOOL) _verifyConnection: (NSDictionary *) dict
{
	return [QueryController echo: [dict valueForKey: @"host"] port: [[dict valueForKey: @"port"] intValue] AET:[dict valueForKey: @"aeTitle"]];
}

- (void) drawerDidOpen: (NSNotification *) notification
{
	[m_ToggleDrawerButton setTitle: NSLocalizedString(@"Hide Printers...", nil)];
}

- (void) drawerDidClose: (NSNotification *) notification
{
	[m_ToggleDrawerButton setTitle: NSLocalizedString(@"Show Printers...", nil)];
}

@end
