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

+ (NSString*) pdfFromURL: (NSString*) url
{
	@try
	{
		WebView *webView = [[[WebView alloc] initWithFrame: NSMakeRect(0,0,1,1) frameName: @"myFrame" groupName: @"myGroup"] autorelease];
		WebPreferences *webPrefs = [WebPreferences standardPreferences];
		
		[webPrefs setLoadsImagesAutomatically: YES];
		[webPrefs setAllowsAnimatedImages: YES];
		[webPrefs setAllowsAnimatedImageLooping: NO];
		[webPrefs setJavaEnabled: NO];
		[webPrefs setPlugInsEnabled: NO];
		[webPrefs setJavaScriptEnabled: YES];
		[webPrefs setJavaScriptCanOpenWindowsAutomatically: NO];
		[webPrefs setShouldPrintBackgrounds: YES];
		
		[webView setApplicationNameForUserAgent: @"OsiriX"];
		[webView setPreferences: webPrefs];
		[webView setMaintainsBackForwardList: NO];
		
		NSURL *theURL = [NSURL fileURLWithPath: url];
		NSURLRequest *request = [NSURLRequest requestWithURL: theURL];
		
		[[webView mainFrame] loadRequest: request];
		
		while( [[webView mainFrame] dataSource] == nil || [[[webView mainFrame] dataSource] isLoading] == YES || [[[webView mainFrame] provisionalDataSource] isLoading] == YES)
		{
			[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
		}
		
		NSPrintInfo *sharedInfo = [NSPrintInfo sharedPrintInfo];
		NSMutableDictionary *sharedDict = [sharedInfo dictionary];
		NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary: sharedDict];
		
		[printInfoDict setObject: NSPrintSaveJob forKey: NSPrintJobDisposition];
		[printInfoDict setObject: [url stringByAppendingPathExtension: @"pdf"] forKey: NSPrintSavePath];
		
		NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
		
		[printInfo setHorizontalPagination: NSAutoPagination];
		[printInfo setVerticalPagination: NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		
		NSView *viewToPrint = [[[webView mainFrame] frameView] documentView];
		NSPrintOperation *printOp = [NSPrintOperation printOperationWithView: viewToPrint printInfo: printInfo];
		[printOp setShowPanels: NO];
		[printOp runOperation];
	}
	@catch (NSException * e)
	{
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	return [url stringByAppendingPathExtension: @"pdf"];
}
@end
