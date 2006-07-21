//
//  StructuredReportController.mm
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

#import "StructuredReportController.h"

#import "browserController.h"
#import "StructuredReport.h"
#import "DicomStudy.h"
#import"ViewerController.h"
#import "AppController.h"

extern AppController *appController;


#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"

static NSString *ViewControlToolbarItem = @"viewControl";
static NSString *SRToolbarIdentifier = @"SRWindowToolbar";
static NSString *keyImagesToolbarIdentifier = @"smallKey.tif";
static NSString *addKeyImagesToolbarIdentifier = @"smallKeyPlus.tif";


@implementation StructuredReportController

- (id)initWithStudy:(id)study{
	if (self = [super initWithWindowNibName:@"StructuredReport"]) {	
		_study = [study retain];
		
		NSEnumerator *enumerator = [[study valueForKey:@"reportSeries"] objectEnumerator];
		id  series;
		NSMutableSet *set = [NSMutableSet set];
		while (series = [enumerator nextObject]){
			NSSet *children = [series valueForKey:@"images"];
			if (children)
				[set unionSet:children];
		}
		NSArray *reports = [set allObjects];
		enumerator = [reports objectEnumerator];
		id report;
		NSMutableArray *reportsArray = [NSMutableArray array];
		while (report = [enumerator nextObject]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjects: 
				[NSArray arrayWithObjects:study, [report valueForKey:@"date"], [report valueForKey:@"completePath"], nil] 
			forKeys:[NSArray arrayWithObjects: @"study", @"report", @"path", nil]];
			[reportsArray  addObject:dict];
		}
		[self setReports: reportsArray];
		if ([reportsArray count] > 0) {
			_reportIndex = 	[[NSIndexSet indexSetWithIndex:0] retain];
			id sr =  [self createReportForStudy:[[_reports objectAtIndex:0] objectForKey:@"study"] path:[[_reports objectAtIndex:0] objectForKey:@"path"]];
			[self setReport:sr];
		}		
		else
			[self setReport:[self createReportForStudy:study]];
		
		[[self window]  makeKeyAndOrderFront:self];
	}
	return self;
}

- (void)setStudy:(id)study{
		[self setReport:[self createReportForStudy:study]];
		[_study release];
		_study = [study retain];	
		[_reports release];
		_reports = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:study, [study valueForKey:@"name"], nil] forKeys:[NSArray arrayWithObjects: @"study", @"report", nil]];
	
}

- (void)windowDidLoad{
	[self setupToolbar];
	if ([_report fileExists])
		[self setTabIndex:0];
	else
		[self setTabIndex:1];
	

}

- (void)dealloc{
	[_reportIndex release];
	[_report release];
	[_reports release];
	[_study release];
	[super dealloc];
}

- (StructuredReport *)createReportForStudy:(id)study{
	return [self createReportForStudy:(id)study path:nil];
}

- (StructuredReport *)createReportForStudy:(id)study path:(NSString *)path{
	StructuredReport *report;
	//NSLog(@"createReport at Path: %@", path);
	if (path) 
		report = [[[StructuredReport alloc] initWithStudy:study contentsOfFile:path] autorelease];
	else
		report = [[[StructuredReport alloc] initWithStudy:study] autorelease];
	return report;
}

- (id)report{
	return _report;
}
- (void)setReport:(id)report{
	[_report release];
	_report = [report retain];
	if ([_report fileExists])
		[self setTabIndex:0];
	else
		[self setTabIndex:1];

}

- (NSView *)contentView{
	return _contentView;
}


- (NSXMLDocument *)xmlDoc{
	return nil;
}

#pragma mark-
#pragma mark Toolbar functions

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
	toolbar = [[NSToolbar alloc] initWithIdentifier:SRToolbarIdentifier];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setVisible:YES];
	[[self window] setToolbar:toolbar];
	[[self window] setShowsToolbarButton:NO];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	if ([itemIdent isEqualToString: ViewControlToolbarItem]) {
		[toolbarItem setLabel: NSLocalizedString(@"View Report", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Report Style", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"View Report as html, xml, DICOM", nil)];
		[toolbarItem setView:viewControl];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([viewControl frame]), NSHeight([viewControl frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([viewControl frame]), NSHeight([viewControl frame]))];
	}
	else if ([itemIdent isEqualToString: keyImagesToolbarIdentifier]) {
		[toolbarItem setImage:[NSImage imageNamed:keyImagesToolbarIdentifier]];
		[toolbarItem setLabel: NSLocalizedString(@"Key Images", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Key Images Button", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"View Key Images", nil)];
		[toolbarItem setAction:@selector(showKeyImages:)];
	}
		else if ([itemIdent isEqualToString: addKeyImagesToolbarIdentifier]) {
		[toolbarItem setImage:[NSImage imageNamed:addKeyImagesToolbarIdentifier]];
		[toolbarItem setLabel: NSLocalizedString(@"Add Key Images", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Add Key Images Button", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"Add Key Images", nil)];
		[toolbarItem setAction:@selector(addKeyImages:)];
	}
	
	return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
	return [NSArray arrayWithObjects:ViewControlToolbarItem, NSToolbarPrintItemIdentifier, keyImagesToolbarIdentifier,addKeyImagesToolbarIdentifier, nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
	return [NSArray arrayWithObjects:ViewControlToolbarItem, NSToolbarPrintItemIdentifier, keyImagesToolbarIdentifier, addKeyImagesToolbarIdentifier, nil];
}

- (IBAction)export:(id)sender{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"dcm", @"xml", @"htm", nil]];
	[savePanel setAllowsOtherFileTypes:NO];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setCanSelectHiddenExtension:YES];
	[savePanel setExtensionHidden:YES];
	[savePanel setTitle:NSLocalizedString(@"Export Report", nil)];
	[savePanel setAccessoryView:accessoryView];
	if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
		NSString *filename = [[savePanel filename] stringByDeletingPathExtension];
		NSString *extension;
		switch (_exportStyle) {
			case 0: extension = @"dcm";
					break;
			case 1: extension = @"htm";
					break;
			case 2: extension = @"xml";
					break;
			default: extension = @"dcm";
		}
		filename = [filename stringByAppendingPathExtension:extension];
		[_report export:filename];
	}
}

- (int)exportStyle{
	return _exportStyle;
}

- (void)setExportStyle:(int)style{
	_exportStyle = style;
}


- (IBAction)save:(id)sender{
	[_report save];
	[[self window] close];
}

- (IBAction)cancel:(id)sender{
	[[self window] close];
}

- (IBAction)showKeyImages:(id)sender{
	BrowserController *browser = [BrowserController currentBrowser];
	[appController setCurrentHangingProtocolForModality:nil description:nil];
	NSArray *images = [NSMutableArray arrayWithObject:[_report keyImages]];
	[browser openViewerFromImages :images movie: nil viewer :nil keyImagesOnly:NO];	
	[NSApp sendAction: @selector(tileWindows:) to:0L from: browser];
}

- (IBAction)addKeyImages:(id)sender{
	[_report setKeyImages:[(NSSet *)[_study keyImages] allObjects]];
}

- (IBAction)printDocument:(id)sender{
	[webView print:sender];
}

- (BOOL)verified{
	return [_report verified];	
}
- (void)setVerified:(BOOL)verified{
	if (verified == YES) 
		//run verifyPanel
		[NSApp beginSheet:verifyPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	else
		[_report setVerified:(BOOL)verified];
}

- (IBAction) endVerify:(id)sender{
	[NSApp endSheet:verifyPanel];
	[verifyPanel close];
	if ([sender tag] == 0)
		[_report setVerified:YES];
}

- (int)tabIndex{
	return _tabIndex;
}
- (void)setTabIndex:(int)tabIndex{
	_tabIndex = tabIndex;
	if (_tabIndex == 0) {
		[_report writeHTML];
		NSLog(@"Report for xml: %@", [_report description]);
		NSURL *url = [NSURL fileURLWithPath:[_report htmlPath]];
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	}
	
}

- (NSArray *)reports{
	//NSLog(@"reports: %@", [_reports description]);
	return _reports;
}
- (void)setReports:(NSArray *)reports{
	[_reports release];
	_reports = [reports retain];
}

- (NSIndexSet *)reportIndex{
	return _reportIndex;
}

- (void)setReportIndex:(NSIndexSet *)indexSet{
	int index = [indexSet firstIndex];
	id report = [self createReportForStudy:[[_reports objectAtIndex:index] objectForKey:@"study"] path:[[_reports objectAtIndex:index] objectForKey:@"path"]];
	[self setReport:report];
	[_reportIndex release];
	_reportIndex = [indexSet retain];
}
		

@end
