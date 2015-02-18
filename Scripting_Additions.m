/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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