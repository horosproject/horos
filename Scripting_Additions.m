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

	if (hfsStyle = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle))
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
		
        if( [[BrowserController currentBrowser] addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString:url]]] == NO)
        {
            NSLog( @"XML-RPC DownloadURLFile: failed to download URL");
        }
	}
	
	if( [command isEqualToString:@"OpenViewerForSelected"]) [[BrowserController currentBrowser] viewerDICOM: self];
	if( [command isEqualToString:@"DeleteSelected"]) [[BrowserController currentBrowser] delItem: self];
	
    /*
     * Code added by Kanteron Systems
     */
	if ([command isEqualToString:@"invoke XMLPRC method"]) {
		NSLog(@"invoke XMLPRC method");
		// We extact the arguments if any 
		NSDictionary *paramDict = nil;
		if  ([[self arguments] objectForKey:@"XMLRPCParams"])
			paramDict = [NSDictionary dictionaryWithDictionary:[[[self arguments] objectForKey:@"XMLRPCParams"] objectAtIndex:0]];
		
		// The XMLRPC method is the direct parameter in AppleScript 
		NSString *xmlrpcMethodName = [self directParameter];
		NSMutableDictionary *httpServerMessage = [[NSMutableDictionary alloc] initWithCapacity:2];
		[httpServerMessage setValue:[NSNumber numberWithBool:NO] forKey:@"Processed"];
        
		[[[AppController sharedAppController] XMLRPCServer] processXMLRPCMessage:xmlrpcMethodName httpServerMessage:httpServerMessage HTTPServerRequest:nil version:(NSString*)kCFHTTPVersion1_0 paramDict:paramDict encoding:@"UTF-8"];
		// Check if the XMLRPC Method added some result for AppleScript. If not, the reply to AppleScript will be nil.
		ASReply = [httpServerMessage valueForKey:@"ASResponse"];
		
		// We have to make sure the server message gets released once the results are passed to AppleScript:
		[httpServerMessage autorelease];	
	}	
    return ASReply;
}

@end