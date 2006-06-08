//
//  StructuredReportController.h
//  OsiriX
//
//  Created by Lance Pysher on 5/29/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>



@class StructuredReport;


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
	NSToolbar *toolbar;
	NSView *_contentView;
	StructuredReport *_report;
	NSArray *_reports;
	int _exportStyle;
	NSString *_exportExtension;
	
}

- (id)initWithStudy:(id)study;
- (void)setStudy:(id)study;
- (BOOL)createReportForStudy:(id)study;



- (id)report;
- (void)setReport:(id)report;

- (NSView *)contentView;
- (void)setContentView:(NSView *)contentView;

- (void) setupToolbar;
- (NSXMLDocument *)xmlDoc;

- (IBAction)export:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;
- (int)exportStyle;
- (void)setExportStyle:(int)style;
- (BOOL)verified;
- (void)setVerified:(BOOL)verified;
- (IBAction)endVerify:(id)sender;
//- (NSString *)exportExtension;
//- (void)setExportExtension:(NSString *)extension;
@end
