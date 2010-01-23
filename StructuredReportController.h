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

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>



@class StructuredReport;
@class AllKeyImagesArrayController;

/** \brief  Window Controller for StructuredReport management */

@interface StructuredReportController : NSWindowController {

	id _study;
	NSURL *_url;
	NSXMLDocument *_xml;

	//DSRDocument *_doc;
	IBOutlet NSSegmentedControl *viewControl;
	IBOutlet NSView *srView;
	IBOutlet NSView *xmlView;
	IBOutlet NSView *htmlView;
	IBOutlet NSView *buttonView;
	IBOutlet WebView *webView;
	IBOutlet NSOutlineView *xmlOutlineView;
	IBOutlet NSView *accessoryView;
	IBOutlet NSPanel *verifyPanel;
	IBOutlet NSToolbarItem *printItem;
	NSToolbar *toolbar;
	NSView *_contentView;
	StructuredReport *_report;
	NSArray *_reports;
	int _exportStyle;
	NSString *_exportExtension;
	int _tabIndex;
	NSIndexSet *_reportIndex;
	NSArray *_keyImagesInStudy;
	BOOL _waitingToPrint;
	IBOutlet AllKeyImagesArrayController *allKeyObjectsArrayController;
	
}

- (id)initWithStudy:(id)study;
- (void)setStudy:(id)study;
- (StructuredReport *)createReportForStudy:(id)study;
- (StructuredReport *)createReportForStudy:(id)study path:(NSString *)path;



- (id)report;
- (void)setReport:(id)report;

- (NSView *)contentView;


- (void) setupToolbar;
- (NSXMLDocument *)xmlDoc;

- (IBAction)export:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)showKeyImages:(id)sender;
- (IBAction)addKeyImages:(id)sender;
- (IBAction)printDocument:(id)sender;

- (int)exportStyle;
- (void)setExportStyle:(int)style;
- (BOOL)verified;
- (void)setVerified:(BOOL)verified;
- (IBAction)endVerify:(id)sender;
- (int)tabIndex;
- (void)setTabIndex:(int)tabIndex;
- (NSArray *)reports;
- (void)setReports:(NSArray *)reports;
- (NSIndexSet *)reportIndex;
- (void)setReportIndex:(NSIndexSet *)indexSet;

- (NSArray *) keyImagesInStudy;
- (void)setKeyImagesInStudy:(NSArray *)images;

- (NSArray *) keyImages;
- (void) setKeyImages:(NSArray *)keyImages;

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;



@end
