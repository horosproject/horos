/*
 *  SafeDBRebuild.c
 *  OsiriX
 *
 *  Created by Antoine Rosset on 22.05.06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#include "SafeDBRebuild.h"
#include "DicomFile.h"

NSLock	*PapyrusLock = 0L;
NSMutableDictionary *fileFormatPlugins = 0L;

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool	= [[NSAutoreleasePool alloc] init];
	
	Papy3Init();
	
	if( argv[ 1])
	{
		DicomFile	*curFile = [[DicomFile alloc] init: [NSString stringWithCString:argv[ 1]]];
		
		if( curFile)
		{
			if( [curFile dicomElements]) [[curFile dicomElements] writeToFile:@"curFile.plist" atomically: YES];
		}
		
		[curFile release];
	}
	
	[pool release];
	
	return 0;
}
