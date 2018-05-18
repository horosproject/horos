/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "Scripting_Additions.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
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
