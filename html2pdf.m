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

#import "html2pdf.h"

@implementation html2pdf

+ (NSData*) pdfFromFile
{
	WebView *webView = [[[WebView alloc] initWithFrame: NSMakeRect(0,0,1,1) frameName: @"myFrame" groupName: @"myGroup"] autorelease];
	WebPreferences *webPrefs = [WebPreferences standardPreferences];
	
	[webPrefs setLoadsImagesAutomatically: NO];
	[webPrefs setAllowsAnimatedImages: YES];
	[webPrefs setAllowsAnimatedImageLooping: NO];
	[webPrefs setJavaEnabled: NO];
	[webPrefs setPlugInsEnabled: NO];
	[webPrefs setJavaScriptEnabled: YES];
	[webPrefs setJavaScriptCanOpenWindowsAutomatically: NO];
	[webPrefs setShouldPrintBackgrounds: YES];

	html2pdf *controller = [[[html2pdf alloc] initWithWebView: webView] autorelease];
	[webView setFrameLoadDelegate: controller];
	[webView setResourceLoadDelegate: controller];
	[webView setApplicationNameForUserAgent: @"OsiriX"];
	[webView setPreferences: webPrefs];
	[webView setMaintainsBackForwardList: NO];

	// **************************
	
//	NSPrintInfo *printInfo;
//	NSPrintInfo *sharedInfo;
//	NSPrintOperation *printOp;
//	NSMutableDictionary *printInfoDict;
//	NSMutableDictionary *sharedDict;
//
//	sharedInfo = [NSPrintInfo sharedPrintInfo];
//	sharedDict = [sharedInfo dictionary];
//	printInfoDict = [NSMutableDictionary dictionaryWithDictionary: sharedDict];
//	
//	[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
//	[printInfoDict setObject:@"/tmp/test.pdf" forKey:NSPrintSavePath];
//
//     printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
//
//	[printInfo setHorizontalPagination: NSAutoPagination];
//	[printInfo setVerticalPagination: NSAutoPagination];
//	[printInfo setVerticallyCentered:NO];
//			
//	printOp = [NSPrintOperation printOperationWithView:textView  printInfo:printInfo];
//	[printOp setShowPanels:NO];
//	[printOp runOperation];

	return nil;
}

- (id) initWithWebView: (WebView *) v
{
    self = [super init];
	
    webView = v;
    
	return self;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *) frame
{
    if( frame.parentFrame)
		return ; // sub-frame on page, page not fully loaded yet
	
//    if p.saveDelay <= 0 then
//      makePDF(nil)
//      return
//    end

//    @saveTimer.invalidate unless @saveTimer.nil?
//    @saveTimer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
//      p.saveDelay, self, :makePDF_, @saveTimer, false)
//    makePDF(nil)

	[self makePaginatedPDF];
}

- (void) makePaginatedPDF
{
	NSPrintInfo *sharedInfo = [NSPrintInfo sharedPrintInfo];
	NSMutableDictionary *sharedDict = [sharedInfo dictionary];
	NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary: sharedDict];
	
	[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
	[printInfoDict setObject:@"/tmp/test.pdf" forKey:NSPrintSavePath];

    NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];

	[printInfo setHorizontalPagination: NSAutoPagination];
	[printInfo setVerticalPagination: NSAutoPagination];
	[printInfo setVerticallyCentered:NO];
	
    NSView *viewToPrint = [[[webView mainFrame] frameView] documentView];
    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView: viewToPrint printInfo: printInfo];
    [printOp setShowPanels: NO];
    [printOp runOperation];
}

@end
