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
#import "Papyrus3/Papyrus3.h"
#import "NSFont_OpenGL.h"

#include "QuickTime/QuickTime.h"

#ifndef OSIRIX_LIGHT
#include "FVTiff.h"
#endif

int main(int argc, const char *argv[])
{
	#ifdef OSIRIX_LIGHT
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSFileManager defaultManager] removeItemAtPath: @"/tmp/OsiriXLightResources" error: nil];
	[[NSFileManager defaultManager] createDirectoryAtPath: @"/tmp/OsiriXLightResources" attributes: nil];
	
	// unzip the file Resources
	NSTask *unzipTask = [[NSTask alloc] init];
	[unzipTask setLaunchPath: @"/usr/bin/unzip"];
	[unzipTask setCurrentDirectoryPath: @"/tmp/OsiriXLightResources/"];
	[unzipTask setArguments: [NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Contents/Resources.zip"], nil]]; // -o to override existing report w/ same name
	[unzipTask launch];
	[unzipTask waitUntilExit];
	[unzipTask release];
	
	[pool release];
	#endif
	
	#if !__LP64__
    EnterMovies();
    #endif
	
    Papy3Init();
	
	#ifndef OSIRIX_LIGHT
    FVTIFFInitialize();
	#endif
	
    return NSApplicationMain(argc, argv);
}
