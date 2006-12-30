//
//  AYDicomPrintWindowController.m
//  AYDicomPrint
//
//  Created by Tobias Hoehmann on 10.06.06.
//  Copyright 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import "QueryController.h"
#include "AYDicomPrintWindowController.h"
//#include "AYDcmPrintSCU.h"
#include "AYNSImageToDicom.h"


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

		[[self window] center];
	}

	return self;
}

- (void) dealloc
{
	[m_PrinterOnImage release];
	m_PrinterOnImage = nil;

	[m_PrinterOffImage release];
	m_PrinterOffImage = nil;

	// masu 2006-10-04
	//[m_CurrentViewer release];
	//m_CurrentViewer = nil;

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
	
	if( [[m_CurrentViewer imageView] flippedData]) [entireSeriesFrom setIntValue: [[m_CurrentViewer pixList] count] - [[m_CurrentViewer imageView] curImage]];
	else [entireSeriesFrom setIntValue: 1+ [[m_CurrentViewer imageView] curImage]];
	[entireSeriesTo setIntValue: [[m_CurrentViewer pixList] count]];
	
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
	//[NSThread detachNewThreadSelector: @selector(_createPrintjob:) toTarget: self withObject: nil];
	[self _createPrintjob: nil];
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
    while (view = [enumerator nextObject]) {
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
		
		[[m_CurrentViewer imageView] sendSyncMessage:1];
		
		[m_CurrentViewer adjustSlider];
		
		[self setPages: self];
	}
}

- (IBAction) setPages:(id) sender
{
	if( sender == entireSeriesTo) [entireSeriesToText setIntValue: [entireSeriesTo intValue]];
	if( sender == entireSeriesFrom) [entireSeriesFromText setIntValue: [entireSeriesFrom intValue]];
	
	if( sender == entireSeriesToText) [entireSeriesTo setIntValue: [entireSeriesToText intValue]];
	if( sender == entireSeriesFromText) [entireSeriesFrom setIntValue: [entireSeriesFromText intValue]];

	NSDictionary *dict = [[m_PrinterController selectedObjects] objectAtIndex: 0];
	
	NSMutableString *imageDisplayFormat = [NSMutableString stringWithString: [dict valueForKey: @"imageDisplayFormat"]];
	[imageDisplayFormat replaceOccurrencesOfString: @" " withString: @"\\" options: nil range: NSMakeRange(0, [imageDisplayFormat length])];

	// show alert, if displayFormat is invalid
	if ([imageDisplayFormat length] < 3)
	{
		[m_pages setIntValue: 0];
		return;
	}

	int rows = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 1, 1)] intValue];
	int columns = [[imageDisplayFormat substringWithRange: NSMakeRange([imageDisplayFormat length] - 3, 1)] intValue];
	int ipp = rows * columns;
	
	int from = [entireSeriesFrom intValue]-1;
	int to = [entireSeriesTo intValue];
	
	if( from >= to)
	{
		to = [entireSeriesFrom intValue];
		from = [entireSeriesTo intValue]-1;
	}
	
	int no_of_images = (to - from) / [entireSeriesInterval intValue];
	
	if( no_of_images == 0) [m_pages setIntValue: 1];
	else if( no_of_images % ipp == 0)  [m_pages setIntValue: no_of_images / ipp];
	else [m_pages setIntValue: 1 + no_of_images / ipp];	
}

- (IBAction) setExportMode:(id) sender
{
	if( [[sender selectedCell] tag] == eAllImages) [self checkView: entireSeriesBox :YES];
	else [self checkView: entireSeriesBox :NO];
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

	int from = [entireSeriesFrom intValue];
	int to = [entireSeriesTo intValue];
	
	if( to == from) to = from+1;
	if( to < from)
	{
		to = [entireSeriesFrom intValue];
		from = [entireSeriesTo intValue];
	}

	NSDictionary	*options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: [[m_ImageSelection selectedCell] tag]], @"mode", [NSNumber numberWithInt: from], @"from", [NSNumber numberWithInt: to], @"to", entireSeriesInterval, @"interval", 0L];
	
	// collect images for printing
	AYNSImageToDicom *dicomConverter = [[AYNSImageToDicom alloc] init];
	NSArray *images = [dicomConverter dicomFileListForViewer: m_CurrentViewer destinationPath: destPath options: options asColorPrint: [[dict valueForKey: @"colorPrint"] intValue] withAnnotations: NO];
	[images retain];
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

	NSString *xmlPath = [NSString stringWithFormat: @"%@/printjob.xml", destPath];
	if (![[document XMLData] writeToFile: xmlPath atomically: YES])
	{
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Can't write to temporary directory." waitUntilDone: NO];
		[images release];
		[pool release];
		return;
	}

	// send printjob
	[self _sendPrintjob: xmlPath];
	[images release];
	// remove temporary files
	[[NSFileManager defaultManager] removeFileAtPath: [xmlPath stringByDeletingLastPathComponent] handler: nil];
	// masu 2006-10-16 this release wasn't there!!!!!!!!!
	[dicomConverter release];
	[pool release];
}

- (void) _sendPrintjob: (NSString *) xmlPath
{
	// dicom log path & basename
	NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/AYDicomPrint"];
	NSString *baseName = [NSString stringWithString: @"AYDicomPrint"];

	// create log directory, if it does not exist
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath: logPath])
		[fileManager createDirectoryAtPath: logPath attributes: nil];

	NSTask *theTask = [[NSTask alloc] init];
	
	[theTask setArguments: [NSArray arrayWithObjects: logPath, baseName, xmlPath, 0L]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/DICOMPrint"]];
	[theTask launch];
	while( [theTask isRunning]) [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
//	[theTask waitUntilExit];	<- The problem with this: it calls the current running loop.... problems with current Lock !
	
	int status = [theTask terminationStatus];
	[theTask release];

	if (status != 0)
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Couldn't print images." waitUntilDone: NO];
	else
		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Images were printed successfully." waitUntilDone: NO];

//	// send printjob
//	AYDcmPrintSCU printSCU = AYDcmPrintSCU([logPath UTF8String], 0, [baseName UTF8String]);
//	NSLog(@"Sending Printjob");
//	int status = printSCU.sendPrintjob([xmlPath UTF8String]);
//
//	// show status
//	if (status != 0)
//		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Couldn't print images." waitUntilDone: NO];
//	else
//		[self performSelectorOnMainThread: @selector(_setProgressMessage:) withObject: @"Images were printed successfully." waitUntilDone: NO];
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

// DICOM standard transfer syntaxes
// used to verify dicom printer availability
//static const char* transferSyntaxes[] = {
//      UID_LittleEndianImplicitTransferSyntax,
//      UID_LittleEndianExplicitTransferSyntax,
//      UID_BigEndianExplicitTransferSyntax,
//      UID_JPEGProcess1TransferSyntax,
//      UID_JPEGProcess2_4TransferSyntax,
//      UID_JPEGProcess3_5TransferSyntax,
//      UID_JPEGProcess6_8TransferSyntax,
//      UID_JPEGProcess7_9TransferSyntax,
//      UID_JPEGProcess10_12TransferSyntax,
//      UID_JPEGProcess11_13TransferSyntax,
//      UID_JPEGProcess14TransferSyntax,
//      UID_JPEGProcess15TransferSyntax,
//      UID_JPEGProcess16_18TransferSyntax,
//      UID_JPEGProcess17_19TransferSyntax,
//      UID_JPEGProcess20_22TransferSyntax,
//      UID_JPEGProcess21_23TransferSyntax,
//      UID_JPEGProcess24_26TransferSyntax,
//      UID_JPEGProcess25_27TransferSyntax,
//      UID_JPEGProcess28TransferSyntax,
//      UID_JPEGProcess29TransferSyntax,
//      UID_JPEGProcess14SV1TransferSyntax,
//      UID_RLELosslessTransferSyntax,
//      UID_JPEGLSLosslessTransferSyntax,
//      UID_JPEGLSLossyTransferSyntax,
//      UID_DeflatedExplicitVRLittleEndianTransferSyntax,
//      UID_JPEG2000LosslessOnlyTransferSyntax,
//      UID_JPEG2000TransferSyntax,
//      UID_MPEG2MainProfileAtMainLevelTransferSyntax,
//      UID_JPEG2000Part2MulticomponentImageCompressionLosslessOnlyTransferSyntax,
//      UID_JPEG2000Part2MulticomponentImageCompressionTransferSyntax
//};

//- (BOOL) _verifyConnection: (NSDictionary *) dict
//{
//	// en-/disable debug messages
//	BOOL debug = YES;
//
//	T_ASC_Association *assoc;
//	T_ASC_Network *net;
//	OFCondition cond;
//
//    DIC_US status;
//	T_DIMSE_BlockingMode blockMode;
//    DcmDataset *statusDetail = NULL;
//    T_ASC_Parameters *params;
//
//	// check if dicom.dic is available
//    if (!dcmDataDict.isDictionaryLoaded())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't find dicom.dic");
//		}
//		return NO;
//    }
//
//    // initialize network connection
//    cond = ASC_initializeNetwork(NET_REQUESTOR, 0, ECHOTIMEOUT, &net);
//    if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't initialize network connection");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//    }
//
//    // initialize association parameters
//    cond = ASC_createAssociationParameters(&params, ASC_DEFAULTMAXPDU);
//    if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't create association parameters");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//    }
//
//	// set our/peer aeTitle
//	NSString *aeTitle = [[NSUserDefaults standardUserDefaults] valueForKey: @"AETITLE"];
//	if (!aeTitle)
//		aeTitle = [NSString stringWithString: @"OSIRIX_DICOM_PRINT"];
//    ASC_setAPTitles(params, [aeTitle UTF8String], [[dict valueForKey: @"aeTitle"] UTF8String], NULL);
//
//    // set transport layer type
//    cond = ASC_setTransportLayerType(params, OFFalse);
//    if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't set transport layer type");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//    }
//
//    // set presentation addresses
//	const char *localHost = [[[NSProcessInfo processInfo] hostName] UTF8String];
//	const char *peerHost = [[NSString stringWithFormat: @"%@:%@", [dict valueForKey: @"host"], [dict valueForKey: @"port"]] UTF8String];
//    ASC_setPresentationAddresses(params, localHost, peerHost);
//
//    // add presentation context
//	cond = ASC_addPresentationContext(params, 1, UID_VerificationSOPClass, transferSyntaxes, 1);
//	if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't add presentation context");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//	}
//
//    // create association
//    cond = ASC_requestAssociation(net, params, &assoc);
//    if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't request association");
//
//			if (cond == DUL_ASSOCIATIONREJECTED)
//			{
//				T_ASC_RejectParameters rej;
//				ASC_getRejectParameters(params, &rej);
//				ASC_printRejectParameters(stderr, &rej);
//			}
//			else
//			{
//				DimseCondition::dump(cond);
//			}
//		}
//		return NO;
//    }
//
//    // verification sop class
//    const char *sopClass = UID_VerificationSOPClass;
//
//    // find presentation context for verification sop class
//    T_ASC_PresentationContextID presID = ASC_findAcceptedPresentationContextID(assoc, sopClass);
//    if (presID == 0)
//    {
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't find presentation context for verification sop class");
//		}
//        return NO;
//    }
//
//	// zero request, response messages
//	T_DIMSE_Message req, rsp;
//    bzero((char*)&req, sizeof(req));
//    bzero((char*)&rsp, sizeof(rsp));
//
//	DIC_US msgId = assoc->nextMsgID++;
//    req.CommandField = DIMSE_C_ECHO_RQ;
//    req.msg.CEchoRQ.MessageID = msgId;
//    req.msg.CEchoRQ.DataSetType = DIMSE_DATASET_NULL;
//    strcpy(req.msg.CEchoRQ.AffectedSOPClassUID, sopClass);
//
//	// send dimse message
//    cond = DIMSE_sendMessageUsingMemoryData(assoc, presID, &req, NULL, NULL, NULL, NULL);
//    if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't send dimse message");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//	}
//
//	// receive dimse response
//    cond = DIMSE_receiveCommand(assoc, blockMode, ECHOTIMEOUT, &presID, &rsp, &statusDetail);
//    if (cond == EC_Normal)
//	{
//		ASC_releaseAssociation(assoc);
//	}
//	else
//	{
//		ASC_abortAssociation(assoc);
//	}
//
//	// free association
//	cond = ASC_destroyAssociation(&assoc);
//	if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't destroy association");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//	}
//
//	// drop network connection
//	cond = ASC_dropNetwork(&net);
//	if (cond.bad())
//	{
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Couldn't drop network connection");
//			DimseCondition::dump(cond);
//		}
//		return NO;
//	}
//
//	// check if answers are right
//    if (rsp.CommandField != DIMSE_C_ECHO_RSP)
//    {
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Unexpected response command field");
//			// rsp.CommandField
//		}
//		return NO;
//    }
//
//    if (rsp.msg.CEchoRSP.MessageIDBeingRespondedTo != msgId)
//    {
//		if (debug)
//		{
//			NSLog(@"AYDicomPrint: Unexpected response msgId");
//			// rsp.msg.CEchoRSP.MessageIDBeingRespondedTo (is), msgId (expected)
//		}
//		return NO;
//    }
//
//    status = rsp.msg.CEchoRSP.DimseStatus;
//	return YES;
//}

- (void) drawerDidOpen: (NSNotification *) notification
{
	[m_ToggleDrawerButton setTitle: NSLocalizedString(@"Hide Printers...", nil)];
}

- (void) drawerDidClose: (NSNotification *) notification
{
	[m_ToggleDrawerButton setTitle: NSLocalizedString(@"Show Printers...", nil)];
}

@end