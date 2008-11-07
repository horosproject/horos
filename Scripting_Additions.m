/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "Scripting_Additions.h"
#import "BrowserController.h"

extern		BrowserController  *browserWindow;

@implementation OsiriXScripts

- (NSString*) posixStylePathFromHfsPath:(NSString*) s isDirectory:(Boolean)isDirectory
{
	OSErr myErr;
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
	NSString *command = [[self commandDescription] commandName];

	NSLog( command);

	if( [command isEqualToString:@"SelectImageFile"])
	{
		NSString	*convertedPath = [self posixStylePathFromHfsPath:[[self arguments] objectForKey:@"FileName"] isDirectory: FALSE];
		
		if( convertedPath)
		{
			NSLog( convertedPath);
			
			[browserWindow addFilesAndFolderToDatabase: [NSArray arrayWithObject: convertedPath]];
			
			if( [browserWindow findAndSelectFile: convertedPath image: nil shouldExpand :YES])
			{
				NSLog(@"done!");
			}
		}
	}
	
	if( [command isEqualToString:@"DownloadURLFile"])
	{
		NSString	*url = [[self arguments] objectForKey:@"URL"];
		
		NSArray	*files = [browserWindow addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString:url]]];
		
		if( [browserWindow findAndSelectFile: [[files objectAtIndex:0] valueForKey:@"completePath"] image: nil shouldExpand: NO])
		{
			NSLog(@"done!");
		}
	}
	
	if( [command isEqualToString:@"OpenViewerForSelected"]) [browserWindow viewerDICOM: self];
	if( [command isEqualToString:@"DeleteSelected"]) [browserWindow delItem: self];
	
    return nil;
}

@end