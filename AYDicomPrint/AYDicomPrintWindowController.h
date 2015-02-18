/*=========================================================================
  Program:   OsiriX

  Copyright (c) Horos Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/


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