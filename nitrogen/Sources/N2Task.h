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
#include <sys/event.h>

@interface N2Task : NSTask {
	NSString* _launchPath;
	NSArray* _arguments;
	pid_t _pid;
	uid_t _uid;
	NSTimeInterval _launchTime;
	NSDictionary* _environment;
	NSString* _currentDirectoryPath;
	id _standardError, _standardInput, _standardOutput;
}

@property(retain) NSArray* arguments;
@property(retain) NSString* currentDirectoryPath;
@property(retain) NSDictionary* environment;
@property(retain) NSString* launchPath;
@property(retain) id standardError;
@property(retain) id standardInput;
@property(retain) id standardOutput;

@property(readonly) NSTimeInterval launchTime;
@property(assign) uid_t uid;


//-(void)setEnv:(NSString*)name to:(NSString*)value;

@end
