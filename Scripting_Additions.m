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

#import "Scripting_Additions.h"
#import "BrowserController.h"
#import "AppController.h"
#import "XMLRPCMethods.h"

@implementation OsiriXScripts

- (NSString*) posixStylePathFromHfsPath:(NSString*) s isDirectory:(Boolean)isDirectory
{
	CFStringRef hfsStyle;
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef) s, kCFURLHFSPathStyle, isDirectory);

	if (url == NULL)
	{
		printf("Can't get URL.\n");
		return(nil);
	}

	if ((hfsStyle = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle)))
	{
		CFRelease(url);
		return  [((NSString*) hfsStyle) autorelease];
	}
	
	CFRelease(url);
	return nil;
}

- (id)performDefaultImplementation
{
	id ASReply = nil;
	NSString *command = [[self commandDescription] commandName];
    
	NSLog( @"%@", command);
    
	if( [command isEqualToString:@"SelectImageFile"])
	{
		NSString	*convertedPath = [self posixStylePathFromHfsPath:[[self arguments] objectForKey:@"FileName"] isDirectory: FALSE];
		
		if( convertedPath)
		{
			NSLog( @"%@", convertedPath);
			
			[[BrowserController currentBrowser] addFilesAndFolderToDatabase: [NSArray arrayWithObject: convertedPath]];
			
			if( [[BrowserController currentBrowser] findAndSelectFile: convertedPath image: nil shouldExpand :YES])
			{
				NSLog(@"done!");
			}
		}
	}
	
	if( [command isEqualToString:@"DownloadURLFile"])
	{
		NSString	*url = [[self arguments] objectForKey:@"URL"];
		
		NSArray	*files = [[BrowserController currentBrowser] addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString:url]]];
		
		if( [[BrowserController currentBrowser] findAndSelectFile: [[files objectAtIndex:0] valueForKey:@"completePath"] image: nil shouldExpand: NO])
		{
			NSLog(@"done!");
		}
	}
	
	if( [command isEqualToString:@"OpenViewerForSelected"]) [[BrowserController currentBrowser] viewerDICOM: self];
	if( [command isEqualToString:@"DeleteSelected"]) [[BrowserController currentBrowser] delItem: self];
	
    /*
     * Code added by Kanteron Systems
     */
	if ([command isEqualToString:@"invoke XMLRPC method"]) {
		NSLog(@"invoke XMLRPC method");
		// We extact the arguments if any 
		NSDictionary *paramDict = nil;
		if  ([[self arguments] objectForKey:@"XMLRPCParams"])
			paramDict = [NSDictionary dictionaryWithDictionary:[[[self arguments] objectForKey:@"XMLRPCParams"] objectAtIndex:0]];
		
		// The XMLRPC method is the direct parameter in AppleScript 
		NSString *xmlrpcMethodName = [self directParameter];
        
		ASReply = [[[AppController sharedAppController] XMLRPCServer] methodCall:xmlrpcMethodName parameters:paramDict error:NULL];
	}	
    return ASReply;
}

@end