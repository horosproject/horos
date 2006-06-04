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
	NSToolbar *toolbar;
	NSView *_contentView;
	StructuredReport *_report;
	
	
	
	
}

- (id)initWithStudy:(id)study;
- (void)setStudy:(id)study;
- (BOOL)createReportForStudy:(id)study;
//-(IBAction)endSheet:(id)sender;
- (void)createReportExportHTML:(BOOL)html;

- (NSArray *)findings;
- (void)setFindings:(NSArray *)findings;
- (NSArray *)conclusions;
- (void)setConclusions:(NSArray *)conclusions;
- (NSString *)physician;
- (void)setPhysician:(NSString *)physician;
- (NSString *)history;
- (void)setHistory:(NSString *)history;
- (id)report;
- (void)setReport:(id)report;

- (NSView *)contentView;
- (void)setContentView:(NSView *)contentView;

- (void) setupToolbar;
- (NSXMLDocument *)xmlDoc;

- (IBAction)export:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;
@end
