/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/


#import <Cocoa/Cocoa.h>

@class ViewerController;

/** \brief Window Controller for DICOM printing */
@interface AYDicomPrintWindowController : NSWindowController <NSWindowDelegate>
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
	
	IBOutlet NSPopUpButton	*formatPopUp;
	IBOutlet NSTextField	*m_VersionNumberTextField;
	
	NSLock					*printing;
    
    NSRect windowFrameToRestore;
    BOOL scaleFitToRestore;

}
+ (void) updateAllPreferencesFormat;

- (IBAction) cancel: (id) sender;
- (IBAction) printImages: (id) sender;
- (IBAction) verifyConnection: (id) sender;
- (IBAction) closeSheet: (id) sender;
- (IBAction) setExportMode:(id) sender;
- (IBAction) exportDICOMSlider:(id) sender;
- (IBAction) setPages:(id) sender;

@end