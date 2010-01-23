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


#import <Cocoa/Cocoa.h>
#import "PathForImage.h"
#import "browserController.h"


const char *pathToJPEG(const char *sopInstanceUID){
	NSString *path = [[[BrowserController currentBrowser]  fixedDocumentsDirectory] stringByAppendingPathComponent:@"REPORTS"];
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	BOOL isDir;
	//CHECK FOR REPORTS FOLDER
	if (!([defaultManager	fileExistsAtPath:path isDirectory:&isDir] && isDir))
		[defaultManager createDirectoryAtPath:path attributes:nil];
	//CHECK AND CREATE JPEGS SUBFOLDER
	path = [path stringByAppendingPathComponent:@"JPEGS"];
	if (!([defaultManager	fileExistsAtPath:path isDirectory:&isDir] && isDir))
		[defaultManager createDirectoryAtPath:path attributes:nil];
	//CREATE JPEG FOR HTML VIEWING
	NSString *imageUID = [NSString stringWithFormat:@"%s", sopInstanceUID];
	path = [path stringByAppendingPathComponent:imageUID];
	NSURL *url = [NSURL fileURLWithPath:path];
	return [[url absoluteString] UTF8String];
}
