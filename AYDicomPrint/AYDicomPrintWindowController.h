//
//  AYDicomPrintWindowController.h
//  AYDicomPrint
//
//  Created by Tobias Hoehmann on 10.06.06.
//  Copyright 2006 aycan digitalsysteme gmbh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ViewerController.h"


@interface AYDicomPrintWindowController : NSWindowController
{
	NSImage *m_PrinterOnImage;
	NSImage *m_PrinterOffImage;
	ViewerController *m_CurrentViewer;

	IBOutlet NSMatrix *m_ImageSelection;
	IBOutlet NSArrayController *m_PrinterController;

	IBOutlet NSPanel *m_ProgressSheet;
	IBOutlet NSTextField *m_ProgressMessage;
	IBOutlet NSTabView *m_ProgressTabView;
	IBOutlet NSButton *m_ProgressOKButton;
	IBOutlet NSProgressIndicator *m_ProgressIndicator;

	IBOutlet NSButton		*m_PrintButton;
	IBOutlet NSButton		*m_ToggleDrawerButton;
	IBOutlet NSButton		*m_VerifyConnectionButton;
	
	IBOutlet NSBox			*entireSeriesBox;
	IBOutlet NSSlider		*entireSeriesInterval, *entireSeriesFrom, *entireSeriesTo;
	IBOutlet NSTextField	*entireSeriesIntervalText, *entireSeriesFromText, *entireSeriesToText;
	IBOutlet NSTextField	*m_pages;
	
	// masu 2006-08-15
	IBOutlet NSTextField	*m_VersionNumberTextField;
}

- (IBAction) cancel: (id) sender;
- (IBAction) printImages: (id) sender;
- (IBAction) verifyConnection: (id) sender;
- (IBAction) closeSheet: (id) sender;
- (IBAction) setExportMode:(id) sender;
- (IBAction) exportDICOMSlider:(id) sender;
- (IBAction) setPages:(id) sender;

@end