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




#import "DICOMLogger.h"


@implementation DICOMLogger
static DICOMLogger *sharedLogger = nil;

- (id)initWithLog:(NSString *)info atPath:(NSString *)path{
	if (self = [super init]) 
		[self addLog:info atPath:path];
	
	return self;
}

- (void)addLog:(NSString *)info atPath:(NSString *)path{
	NSString *log;
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:path]) 
		log = [[NSString stringWithContentsOfFile:path] retain];
	else
		log = [[path lastPathComponent] retain];
		

	NSString *appendedLog = [[NSString stringWithFormat:@"%@\n%@",log,info] retain];	
	[appendedLog writeToFile:path atomically:YES];
	//NSLog(@"log %@", appendedLog);
	[appendedLog release];
	[log release];
	
}

+(DICOMLogger *)sharedLogger {
    return sharedLogger ? sharedLogger : [[self alloc] init];
}

+(void)log:(NSString *)info atPath:(NSString *)path{
	[[self sharedLogger] addLog:info atPath:path];
}

- (void)dealloc {
    if (self != sharedLogger) [super dealloc];	// Don't free the shared instance
}


@end
