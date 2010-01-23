/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <AppKit/AppKit.h>

/** \brief Window Controller for anonymizing */
@interface AnonymizerWindowController : NSWindowController
{
	IBOutlet NSMatrix			*tagMatrixfirstColumn, *tagMatrixsecondColumn;
	IBOutlet NSMatrix			*firstColumnValues, *secondColumnValues;
	IBOutlet NSView				*accessoryView;
	IBOutlet NSPopUpButton		*templatesMenu;
	IBOutlet NSButton			*checkReplace;
	
	IBOutlet NSWindow			*anonymizeWindow;
	IBOutlet NSView				*anonymizeView;
	
	IBOutlet NSWindow			*templateNameWindow;
	IBOutlet NSTextField		*templateName;

	NSOpenPanel					*sPanel;
	NSMutableDictionary			*templates;
	NSArray						*filesToAnonymize, *dcmObjects;
	NSString					*folderPath;
	NSMutableArray				*tags, *producedFiles;
	
	BOOL						cancelled;
}

- (IBAction) selectTemplateMenu:(id) sender;
- (IBAction) addTemplate:(id) sender;
- (IBAction) removeTemplate:(id) sender;
- (IBAction) anonymize:(id) sender;
- (IBAction) matrixAction:(id) sender;
- (void) setFilesToAnonymize:(NSArray *) files :(NSArray*) dcm;
- (NSArray*) tags;
- (NSArray*) producedFiles;
- (IBAction)cancelModal:(id)sender;
- (IBAction)okModal:(id)sender;
- (IBAction) anonymizeToThisPath:(NSString*) path;
- (BOOL) cancelled;
@end
