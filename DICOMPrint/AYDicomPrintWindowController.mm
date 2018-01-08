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
- (void) _createPrintjob: (id) object;
- (void) _sendPrintjob: (NSString *) xmlPath;
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
	
	[self _createPrintjob: nil];
	
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

- (void) _createPrintjob: (id) object
{
    // show progress sheet
	[self _setProgressMessage: nil];
	[NSApp beginSheet: m_ProgressSheet modalForWindow: [self window] modalDelegate: self didEndSelector: nil contextInfo: nil];

	// dictionary for selected printer
	NSDictionary *dict = [[m_PrinterController selectedObjects] objectAtIndex: 0];

	// printjob
	NSXMLElement *printjob = [NSXMLElement elementWithName: @"printjob"];
	NSXMLDocument *document = [NSXMLDocument documentWithRootElement: printjob];
	[document setVersion: @"1.0"];
	[document setCharacterEncoding: @"ISO-8859-1"];
	[document setStandalone: YES];

	// association
	NSXMLElement *association = [NSXMLElement elementWithName: @"association"];
	[association addAttribute: [NSXMLNode attributeWithName: @"host" stringValue: [dict valueForKey: @"host"]]];
	[association addAttribute: [NSXMLNode attributeWithName: @"port" stringValue: [dict valueForKey: @"port"]]];
	NSString *aeTitle = [NSUserDefaults defaultAETitle];
	if (!aeTitle)
		aeTitle = @"OSIRIX_DICOM_PRINT";
	[association addAttribute: [NSXMLNode attributeWithName: @"aetitle_sender" stringValue: aeTitle]];
	[association addAttribute: [NSXMLNode attributeWithName: @"aetitle_receiver" stringValue: [dict valueForKey: @"aeTitle"]]];
	if ([[dict valueForKey: @"colorPrint"] boolValue])
		[association addAttribute: [NSXMLNode attributeWithName: @"colorprint" stringValue: @"YES"]];
	[printjob addChild: association];

	// filmsession
	NSXMLElement *filmsession = [NSXMLElement elementWithName: @"filmsession"];
	NSString *copies = [NSString stringWithFormat: @"%d", [[dict valueForKey: @"copies"] intValue]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"number_of_copies" stringValue: copies]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"print_priority" stringValue: priorityTag[ [[dict valueForKey: @"priorityTag"] intValue]]]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"medium_type" stringValue: [mediumTag[ [[dict valueForKey: @"mediumTag"] intValue]] uppercaseString]]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"film_destination" stringValue: [filmDestinationTag[[[dict valueForKey: @"filmDestinationTag"] intValue]] uppercaseString]]];
	[association addChild: filmsession];

	// filmbox
	
	// show alert, if displayFormat is invalid
	if ([[formatPopUp menu] itemWithTag: [[dict valueForKey: @"imageDisplayFormatTag"] intValue]] == nil)
		[self _setProgressMessage: NSLocalizedString( @"The Format you selected is not valid.", nil)];
	else
    {
        NSMutableString *imageDisplayFormat = [NSMutableString stringWithString: imageDisplayFormatTag[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]]];
        [imageDisplayFormat replaceOccurrencesOfString: @" " withString: @"\\" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [imageDisplayFormat length])];
        
        int ipp = imageDisplayFormatNumbers[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
        int rows = imageDisplayFormatRows[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
        int columns = imageDisplayFormatColumns[[[dict valueForKey: @"imageDisplayFormatTag"] intValue]];
        
        NSString *destPath = @"/tmp/dicomPrint/";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // remove destination directory
        if ([fileManager fileExistsAtPath: destPath])
            [fileManager removeItemAtPath: destPath error:NULL];
        
        // create destination directory
        if ([fileManager fileExistsAtPath: destPath] || ![fileManager createDirectoryAtPath: destPath withIntermediateDirectories:YES attributes:nil error:NULL])
            [self _setProgressMessage: NSLocalizedString( @"Can't write to temporary directory.", nil)];
        else
        {
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
            
            // collect images for printing
            AYNSImageToDicom *dicomConverter = [[[AYNSImageToDicom alloc] init] autorelease];
            NSArray *images = [dicomConverter dicomFileListForViewer: m_CurrentViewer destinationPath: destPath options: options asColorPrint: [[dict valueForKey: @"colorPrint"] intValue] withAnnotations: NO];
            
            // check, if images were collected
            if ([images count] == 0)
                [self _setProgressMessage: NSLocalizedString( @"There are no images selected.", nil)];
            else
            {
                for( int i = 0; i <= ([images count] - 1) / ipp; i++)
                {
                    NSXMLElement *filmbox = [NSXMLElement elementWithName: @"filmbox"];
                    
                    NSMutableString *filmSize = [NSMutableString stringWithString: filmSizeTag[[[dict valueForKey: @"filmSizeTag"] intValue]]];
                    [filmSize replaceOccurrencesOfString: @" " withString: @"" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [filmSize length])];
                    [filmSize replaceOccurrencesOfString: @"." withString: @"_" options:NSCaseInsensitiveSearch range: NSMakeRange(0, [filmSize length])];

                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"image_display_format" stringValue: [imageDisplayFormat uppercaseString]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"film_orientation" stringValue: [filmOrientationTag[[[dict valueForKey: @"filmOrientationTag"] intValue]] uppercaseString]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"film_size_id" stringValue: [filmSize uppercaseString]]];

                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"border_density" stringValue: borderDensityTag[ [[dict valueForKey: @"borderDensityTag"] intValue]]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"empty_image_density" stringValue: emptyImageDensityTag[ [[dict valueForKey: @"emptyImageDensityTag"] intValue]]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"requested_resolution_id" stringValue: [dict valueForKey: @"requestedResolution"]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"magnification_type" stringValue: magnificationTypeTag[[[dict valueForKey: @"magnificationTypeTag"] intValue]]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"trim" stringValue: trimTag[[[dict valueForKey: @"trimTag"] intValue]]]];
                    [filmbox addAttribute: [NSXMLNode attributeWithName: @"configuration_information" stringValue: [dict valueForKey: @"configurationInformation"]]];

                    // imagebox
                    int j, k = 1;
                    for (j = i * ipp; j < MIN(i * ipp + ipp, [images count]); j++)
                    {
                        NSXMLElement *imagebox = [NSXMLElement elementWithName: @"imagebox"];
                        
                        [imagebox addAttribute: [NSXMLNode attributeWithName: @"image_file" stringValue: [images objectAtIndex: j]]];
                        [imagebox addAttribute: [NSXMLNode attributeWithName: @"image_position" stringValue: [NSString stringWithFormat: @"%d", k++]]];
                        
                        if( [[images objectAtIndex: j] length] > 0)
                            [filmbox addChild: imagebox];
                    }

                    [filmsession addChild: filmbox];
                }

                NSString *xmlPath = [NSString stringWithFormat: @"%@/printjob-%@.xml", destPath, [[NSDate date] description]];
                
                if (![[document XMLData] writeToFile: xmlPath atomically: YES])
                    [self _setProgressMessage: NSLocalizedString( @"Can't write to temporary directory.", nil)];
                else
                {
                    // send printjob
                    
                    NSThread* t = [[[NSThread alloc] initWithTarget:self selector:@selector(_sendPrintjob:) object: xmlPath] autorelease];
                    t.name = NSLocalizedString( @"DICOM Printing...", nil);
                    [[ThreadsManager defaultManager] addThreadAndStart: t];
                }
            }
        }
    }
    
    [self closeSheet: self];
}

- (void) errorMessage:(NSArray*) msg
{
	NSRunCriticalAlertPanel( [msg objectAtIndex: 0], @"%@", [msg objectAtIndex: 2], nil, nil, [msg objectAtIndex: 1]) ;
}

- (void) _sendPrintjob: (NSString *) xmlPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[xmlPath retain];
	
	[printing lock];
	
	@try 
	{
		// dicom log path & basename
		NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/AYDicomPrint"];
		NSString *baseName = @"AYDicomPrint";

		// create log directory, if it does not exist
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager fileExistsAtPath: logPath])
			[fileManager createDirectoryAtPath: logPath withIntermediateDirectories:YES attributes:nil error:NULL];
		
		NSTask *theTask = [[NSTask alloc] init];
		
		[theTask setArguments: [NSArray arrayWithObjects: logPath, baseName, xmlPath, nil]];
		[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/DICOMPrint"]];
		[theTask launch];
		while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
	//	[theTask waitUntilExit];	<- The problem with this: it calls the current running loop.... problems with current Lock !
		
		int status = [theTask terminationStatus];
		[theTask release];

		if (status != 0)
		{
			[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString(@"Couldn't print images.", nil), NSLocalizedString(@"OK", nil), nil] waitUntilDone:NO];
		}

		// remove temporary files
		[[NSFileManager defaultManager] removeItemAtPath: [xmlPath stringByDeletingLastPathComponent] error:NULL];
		
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	[printing unlock];
	
	[xmlPath release];
	
	[pool release];
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
