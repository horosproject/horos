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




#import "Survey.h"
#import <Message/NSMailDelivery.h>


@implementation Survey

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog( @"Survey closing");
	
	[self release];
}

//-(IBAction) done : (id) sender
//{
//	if( [sender tag] == 1)
//	{
//		BOOL result;
//		long i;
//		NSString *recipient = @"rossetantoine@mac.com";
//		NSString *subject = @"OsiriX survey";
//		
//		NSString *message = [NSString stringWithFormat:@"Who:%d - Where:%d - Usage:%d - Plugin:%d - RSNA:0 - Comments:%@",
//							[[who selectedCell] tag],
//							[[where selectedCell] tag],
//							[[usage selectedCell] tag],
//							[[plugin selectedCell] tag],
//							[comments stringValue]];
//		
//		for( i = 0; i < 6; i++)
//		{
//			if( [[what cellWithTag: i] state] == NSOnState)
//				message = [message stringByAppendingFormat:@" - What:%d", [[what cellWithTag: i] tag]];
//		}
//		
//		result = [NSMailDelivery deliverMessage:message subject:subject to:recipient];
//		
//		if ( result == NO )
//		{
//			NSString* mailtoLink = [NSString stringWithFormat:@"mailto:rossetantoine@mac.com?subject=OsiriX survey&body=Thanks for answering this survey!\n\nYou can now simply send this email and go back to OsiriX!\n\n%@\n\n",message];
//			
//			NSURL *url = [NSURL URLWithString:[(NSString*) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)mailtoLink, NULL, NULL, kCFStringEncodingUTF8) autorelease]];
//			
//			[[NSWorkspace sharedWorkspace] openURL:url];
//		}
//		
//		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"SURVEYDONE3"];
//	}
//	
//	[[self window] orderOut: self];
//}

-(IBAction) dontShowAgain : (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"SURVEYDONE3"];
}

-(IBAction) done : (id) sender
{
	if( [sender tag] == 2) [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://homepage.mac.com/rossetantoine/osirix/RSNA2005.html"]];
	
	[[self window] orderOut: self];
}

@end
