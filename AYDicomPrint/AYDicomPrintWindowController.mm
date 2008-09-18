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


#import "QueryController.h"
#import "AYDicomPrintWindowController.h"
#import "NSFont_OpenGL.h"
#import "AYNSImageToDicom.h"

#define VERSIONNUMBERSTRING	@"v1.00.000"
#define ECHOTIMEOUT 5


@interface AYDicomPrintWindowController (Private)
- (void) _createPrintjob: (id) object;
- (void) _sendPrintjob: (NSString *) xmlPath;
- (BOOL) _verifyConnection: (NSDictionary *) dict;
- (void) _verifyConnections: (id) object;
- (void) _setProgressMessage: (NSString *) message;
- (ViewerController *) _currentViewer;
@end

@implementation AYDicomPrintWindowController

- (id) init
{
	if (self = [super init])
	{
		// fetch current viewer
		m_CurrentViewer = [self _currentViewer];

		// initialize printer state images
		m_PrinterOnImage = [[NSImage imageNamed: @"available"] retain];
		m_PrinterOffImage = [[NSImage imageNamed: @"away"] retain];
		
		printing = [[NSLock alloc] init];
		
		[[self window] center];
	}

	return self;
}

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

	[NSThread detachNewThreadSelector: @selector(_verifyConnections:) toTarget: self withObject: self];
	
	[entireSeriesFrom setMaxValue: [[m_CurrentViewer pixList] count]];
	[entireSeriesTo setMaxValue: [[m_CurrentViewer pixList] count]];
	
	[entireSeriesFrom setNumberOfTickMarks: [[m_CurrentViewer pixList] count]];
	[entireSeriesTo setNumberOfTickMarks: [[m_CurrentViewer pixList] count]];
	
	if( [[m_CurrentViewer pixList] count] < 20)
	{
		[entireSeriesFrom setIntValue: 1];
		[entireSeriesTo setIntValue: [[m_CurrentViewer pixList] count]];
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
	[self close];
}

- (IBAction) printImages: (id) sender
{
	if( [m_pages intValue] > 10 && [[m_ImageSelection selectedCell] tag] == eAllImages)
	{
		if( NSRunInformationalAlertPanel( NSLocalizedString(@"DICOM Print", nil), [NSString stringWithFormat: NSLocalizedString(@"Are you really sure you want to print %d pages?", nil), [m_pages intValue]] , NSLocalizedString(@"OK", nil), NSLocalizedString(@"Cancel", nil), 0L) != NSAlertDefaultReturn) return;
	}
	
	[sender setEnabled: NO];
	
	[self _createPrintjob: nil];
	
	[self cancel: self];
}

- (IBAction) verifyConnection: (id) sender
{
	[NSThread detachNewThreadSelector: @selector(_verifyConnections:) toTarget: self withObject: nil];
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
	NSMutableString *imageDisplayFormat = [NSMutableString stringWithString: [dict valueForKey: @"imageDisplayFormat"]];
	[imageDisplayFormat replaceOccurrencesOfString: @" " withString: @"\\" options: nil range: NSMakeRange(0, [imageDisplayFormat length])];

	int rows = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 1, 1)] intValue];
	int columns = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 3, 1)] intValue];
	int ipp = rows * columns;

	// show alert, if displayFormat is invalid
	if ([imageDisplayFormat length] < 3)
	{
		[m_pages setIntValue: 0];
		return;
	}
	
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
		
		no_of_images = (to - from) / [entireSeriesInterval intValue];
	}
	else if( [[m_ImageSelection selectedCell] tag] == eCurrentImage) no_of_images = 1;
	else if( [[m_ImageSelection selectedCell] tag] == eKeyImages)
	{
		int i;
		
		NSArray *fileList = [m_CurrentViewer fileList];
		
		no_of_images = 0;
		for (i = 0; i < [fileList count]; i++)
		{
			if ([[[fileList objectAtIndex: i] valueForKey: @"isKeyImage"] boolValue]) no_of_images++;
		}
	}
	
	if( no_of_images == 0) [m_pages setIntValue: 1];
	else if( no_of_images % ipp == 0)  [m_pages setIntValue: no_of_images / ipp];
	else [m_pages setIntValue: 1 + no_of_images / ipp];	
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// show progress sheet
	[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: nil waitUntilDone: NO];
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
	NSString *aeTitle = [[NSUserDefaults standardUserDefaults] valueForKey: @"AETITLE"];
	if (!aeTitle)
		aeTitle = [NSString stringWithString: @"OSIRIX_DICOM_PRINT"];
	[association addAttribute: [NSXMLNode attributeWithName: @"aetitle_sender" stringValue: aeTitle]];
	[association addAttribute: [NSXMLNode attributeWithName: @"aetitle_receiver" stringValue: [dict valueForKey: @"aeTitle"]]];
	if ([[dict valueForKey: @"colorPrint"] boolValue])
		[association addAttribute: [NSXMLNode attributeWithName: @"colorprint" stringValue: @"YES"]];
	[printjob addChild: association];

	// filmsession
	NSXMLElement *filmsession = [NSXMLElement elementWithName: @"filmsession"];
	NSString *copies = [NSString stringWithFormat: @"%d", [[dict valueForKey: @"copies"] intValue]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"number_of_copies" stringValue: copies]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"print_priority" stringValue: [dict valueForKey: @"priority"]]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"medium_type" stringValue: [[dict valueForKey: @"medium"] uppercaseString]]];
	[filmsession addAttribute: [NSXMLNode attributeWithName: @"film_destination" stringValue: [[dict valueForKey: @"filmDestination"] uppercaseString]]];
	[association addChild: filmsession];

	// filmbox
	NSMutableString *imageDisplayFormat = [NSMutableString stringWithString: [dict valueForKey: @"imageDisplayFormat"]];
	[imageDisplayFormat replaceOccurrencesOfString: @" " withString: @"\\" options: nil range: NSMakeRange(0, [imageDisplayFormat length])];

	// show alert, if displayFormat is invalid
	if ([imageDisplayFormat length] < 3)
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"The Format you selected is not valid." waitUntilDone: NO];
		[pool release];
		return;
	}

	int rows = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 1, 1)] intValue];
	int columns = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 3, 1)] intValue];
	int ipp = rows * columns;
	
	// create temporary directory
	if (!NSTemporaryDirectory())
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Can't write to temporary directory." waitUntilDone: NO];
		[pool release];
		return;
	}
	
	NSString *destPath = [NSString stringWithFormat: @"%@/dicomPrint", NSTemporaryDirectory()];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// remove destination directory
	if ([fileManager fileExistsAtPath: destPath])
		[fileManager removeFileAtPath: destPath handler: nil];
	
	// create destination directory
	if ([fileManager fileExistsAtPath: destPath] || ![fileManager createDirectoryAtPath: destPath attributes: nil])
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Can't write to temporary directory." waitUntilDone: NO];
		[pool release];
		return;
	}

	int from = [entireSeriesFrom intValue]-1;
	int to = [entireSeriesTo intValue];

	if( to < from)
	{
		to = [entireSeriesFrom intValue];
		from = [entireSeriesTo intValue]-1;
	}

	if( from < 0) from = 0;
	if( to == from) to = from+1;

	NSDictionary	*options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [[m_ImageSelection selectedCell] tag]], @"mode", [NSNumber numberWithInt: from], @"from", [NSNumber numberWithInt: to], @"to", [NSNumber numberWithInt: [entireSeriesInterval intValue]], @"interval", 0L];
	
	NSLog( [options description]);
	
	float fontSizeCopy = [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"];
		
	if( columns != 1)
	{
		float inc = (1 + ((columns - 1) * 0.35));
		if( inc > 2.5) inc = 2.5;
		
		[[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy * inc forKey: @"FONTSIZE"];
		[NSFont resetFont: NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"changeGLFontNotification" object: self];
	}
	
	// collect images for printing
	AYNSImageToDicom *dicomConverter = [[AYNSImageToDicom alloc] init];
	NSArray *images = [dicomConverter dicomFileListForViewer: m_CurrentViewer destinationPath: destPath options: options asColorPrint: [[dict valueForKey: @"colorPrint"] intValue] withAnnotations: NO];
	[images retain];
	
	if( fontSizeCopy != [[NSUserDefaults standardUserDefaults] floatForKey: @"FONTSIZE"])
	{
		[[NSUserDefaults standardUserDefaults] setFloat: fontSizeCopy forKey: @"FONTSIZE"];
		[NSFont resetFont: NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"changeGLFontNotification" object: self];
	}
	
	// check, if images were collected
	if ([images count] == 0)
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"There are no images selected." waitUntilDone: NO];
		[images release];
		[pool release];
		return;
	}

	int i;
	for (i = 0; i <= ([images count] - 1) / ipp; i++)
	{
		NSXMLElement *filmbox = [NSXMLElement elementWithName: @"filmbox"];
		NSLog(@"Creating Filmbox for image nr %d", i);
		NSMutableString *filmSize = [NSMutableString stringWithString: [dict valueForKey: @"filmSize"]];
		[filmSize replaceOccurrencesOfString: @" " withString: @"" options: nil range: NSMakeRange(0, [filmSize length])];
		[filmSize replaceOccurrencesOfString: @"." withString: @"_" options: nil range: NSMakeRange(0, [filmSize length])];

		[filmbox addAttribute: [NSXMLNode attributeWithName: @"image_display_format" stringValue: [imageDisplayFormat uppercaseString]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"film_orientation" stringValue: [[dict valueForKey: @"filmOrientation"] uppercaseString]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"film_size_id" stringValue: [filmSize uppercaseString]]];

		[filmbox addAttribute: [NSXMLNode attributeWithName: @"border_density" stringValue: [dict valueForKey: @"borderDensity"]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"empty_image_density" stringValue: [dict valueForKey: @"emptyImageDensity"]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"requested_resolution_id" stringValue: [dict valueForKey: @"requestedResolution"]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"magnification_type" stringValue: [dict valueForKey: @"magnificationType"]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"trim" stringValue: [dict valueForKey: @"trim"]]];
		[filmbox addAttribute: [NSXMLNode attributeWithName: @"configuration_information" stringValue: [dict valueForKey: @"configurationInformation"]]];

		// imagebox
		int j, k = 1;
		for (j = i * ipp; j < MIN(i * ipp + ipp, [images count]); j++)
		{
			NSXMLElement *imagebox = [NSXMLElement elementWithName: @"imagebox"];

			[imagebox addAttribute: [NSXMLNode attributeWithName: @"image_file" stringValue: [images objectAtIndex: j]]];
			[imagebox addAttribute: [NSXMLNode attributeWithName: @"image_position" stringValue: [NSString stringWithFormat: @"%d", k++]]];

			[filmbox addChild: imagebox];
		}

		[filmsession addChild: filmbox];
	}

	NSString *xmlPath = [NSString stringWithFormat: @"%@/printjob-%@.xml", destPath, [[NSDate date] description]];
	NSLog( xmlPath);
	if (![[document XMLData] writeToFile: xmlPath atomically: YES])
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Can't write to temporary directory." waitUntilDone: NO];
		[images release];
		[pool release];
		return;
	}
	
	[images release];
	[dicomConverter release];
	
	[self closeSheet: self];
	
	// send printjob
	[NSThread detachNewThreadSelector:@selector( _sendPrintjob:) toTarget:self withObject: xmlPath];
//	[self _sendPrintjob: xmlPath];	
		
	[pool release];
}

- (void) errorMessage:(NSArray*) msg
{
	NSRunCriticalAlertPanel( [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2], nil, nil) ;
}

- (void) _sendPrintjob: (NSString *) xmlPath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[xmlPath retain];
	
	[printing lock];
	
	// dicom log path & basename
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/AYDicomPrint"];
	NSString *baseName = [NSString stringWithString: @"AYDicomPrint"];

	// create log directory, if it does not exist
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath: logPath])
		[fileManager createDirectoryAtPath: logPath attributes: nil];

	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects: logPath, baseName, xmlPath, 0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/DICOMPrint"]];
	[theTask launch];
	while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
//	[theTask waitUntilExit];	<- The problem with this: it calls the current running loop.... problems with current Lock !
	
	int status = [theTask terminationStatus];
	[theTask release];

	if (status != 0)
	{
		[self performSelectorOnMainThread:@selector(errorMessage:) withObject:[NSArray arrayWithObjects: NSLocalizedString(@"Print failed", nil), NSLocalizedString(@"Couldn't print images.", nil), NSLocalizedString(@"OK", nil), 0L] waitUntilDone:YES];
	}

	// remove temporary files
	[[NSFileManager defaultManager] removeFileAtPath: [xmlPath stringByDeletingLastPathComponent] handler: nil];
	
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
		[m_ProgressMessage setStringValue: NSLocalizedString(@"Printing images...", nil)];
	}
	else
	{
		[m_ProgressTabView selectLastTabViewItem: self];
		[m_ProgressMessage setStringValue: message];
	}

	[m_ProgressMessage setNeedsDisplay: YES];
}

- (void) _verifyConnections: (id) object
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[m_VerifyConnectionButton setEnabled: NO];

	// if object == nil, only verify currently selected printer
	// (used by (IBAction) verifyConnection:)
	NSArray *printers;
	if (!object)
		printers = [m_PrinterController selectedObjects];
	else
		printers = [m_PrinterController arrangedObjects];

	NSMutableDictionary *printer;
	int i;
	for (i = 0; i < [printers count]; i++)
	{
		printer = [printers objectAtIndex: i];
		if ([self _verifyConnection: printer])
			[printer setValue: m_PrinterOnImage forKey: @"state"];
		else
			[printer setValue: m_PrinterOffImage forKey: @"state"];
	}

	[m_VerifyConnectionButton setEnabled: YES];
	[m_VerifyConnectionButton setNeedsDisplay: YES];

	[pool release];
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