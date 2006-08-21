//
//  PathForImage.m
//  OsiriX
//
//  Created by Lance Pysher on 8/21/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//


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
