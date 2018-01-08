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

#import "N2Task.h"


@implementation N2Task
@synthesize launchTime = _launchTime, uid = _uid;

static void sigchld(int signum) {
	@try {
		int sl = 0;
		waitpid(0, &sl, WNOHANG);
	} @catch (...) {
	}
}

+(void)initialize {
	@try {
		struct sigaction sa;
		sa.sa_handler = sigchld;
		sigemptyset(&sa.sa_mask);
		sa.sa_flags = SA_RESTART;
		sigaction(SIGCHLD, &sa, NULL);		
	} @catch (...) {
	}
}

-(void)dealloc {
	self.arguments = NULL;
	self.launchPath = NULL;
	self.environment = NULL;
    [_currentDirectoryPath release]; _currentDirectoryPath = nil;
	self.standardInput = NULL;
	self.standardOutput = NULL;
	self.standardError = NULL;
	[super dealloc];
}

static int getfd(id object, BOOL read, int def) { // http://www.quantum-step.com/download/sources/mySTEP/Foundation/Sources/NSTask.m
	if (!object)
		return def; // default value
	if ([object isKindOfClass:[NSFileHandle class]])
		return [object fileDescriptor];
	if ([object isKindOfClass:[NSPipe class]])
		return [(read?[object fileHandleForReading]:[object fileHandleForWriting]) fileDescriptor];
	if ([object isKindOfClass:[NSNumber class]])
		return [object intValue];
	[NSException raise: NSInvalidArgumentException format: @"N2Task has invalid file descriptor %@", object];
	return -1;
}

-(void)launch {
	if (_pid) [self terminate];
	
	int	idesc = getfd(self.standardInput, YES, STDIN_FILENO);
	int	odesc = getfd(self.standardOutput, NO, STDOUT_FILENO);
	int	edesc = getfd(self.standardError, NO, STDERR_FILENO);
	
	const char* exec = self.launchPath.fileSystemRepresentation;
	
	const char* argv[self.arguments.count+2];
	argv[0] = self.launchPath.UTF8String;
	for (int i = 0; i < self.arguments.count; ++i)
		argv[i+1] = [[self.arguments objectAtIndex:i] UTF8String];
	argv[self.arguments.count+1] = NULL;
	
	const char* wd = self.currentDirectoryPath.fileSystemRepresentation;
	
	_launchTime = [NSDate timeIntervalSinceReferenceDate];
	
	const char* env[self.environment.count+1];
	env[self.environment.count] = NULL;
	int ienv = 0;
	for (NSString* kenv in self.environment) {
		NSString* venv = [self.environment objectForKey:kenv], *aenv;
		if (venv) aenv = [NSString stringWithFormat:@"%@=%@", kenv, venv];
		else aenv = [NSString stringWithFormat:@"%@=", kenv];
		env[ienv++] = aenv.UTF8String;
	}
	
//	NSLog(@"Executing %@ with %@", _launchPath, _arguments);
	
	_pid = fork();
	switch (_pid) {
		case -1: {
			[NSException raise:NSInvalidArgumentException format:@"N2Task failed to create child process"];
		}
		
		case 0: {
            if (idesc != 0)	{
                dup2(idesc, STDIN_FILENO);
                close(idesc);
            }
			if ([self.standardInput isKindOfClass:[NSPipe class]])
				[[self.standardInput fileHandleForWriting] closeFile];
            if (odesc != 1) {
                dup2(odesc, STDOUT_FILENO);
                close(odesc);
            }
			if ([self.standardOutput isKindOfClass:[NSPipe class]])
				[[self.standardOutput fileHandleForReading] closeFile];
            if (edesc != 2) {
                dup2(edesc, STDERR_FILENO);
                close(edesc);
            }
			if ([self.standardError isKindOfClass:[NSPipe class]])
				[[self.standardError fileHandleForReading] closeFile];
				
			if (_uid) setuid(_uid);
			if (wd) chdir(wd);
				
			execve(exec, (char* const*)argv, (char* const*)env);
			exit(127);
		}
		
		default: {
			if ([self.standardInput isKindOfClass:[NSPipe class]])
				[[self.standardInput fileHandleForReading] closeFile];
			if ([self.standardOutput isKindOfClass:[NSPipe class]])
				[[self.standardOutput fileHandleForWriting] closeFile];
			if ([self.standardError isKindOfClass:[NSPipe class]])
				[[self.standardError fileHandleForWriting] closeFile];
		}
	}
}

-(void)terminate {
	kill(_pid, SIGTERM);
	_pid = 0;
}

-(void)interrupt {
	kill(_pid, SIGINT);
	_pid = 0;
}

/*-(BOOL)suspend {
	signal(_pid, SIGSTOP);
	return YES;
}

-(BOOL)resume {
	signal(_pid, SIGCONT);
	return YES;
 }*/

-(void)waitUntilExit {
	while (self.isRunning)
		[NSThread sleepForTimeInterval:0.01];
}


-(BOOL)isRunning {
	if (_pid < 1) return NO;
	// return YES;
	int status;
	pid_t ret = waitpid(_pid, &status, WNOHANG);
	if (!ret) return YES;
	if (ret == -1) return NO;
	return !(WIFEXITED(status) || WIFSIGNALED(status));
}

-(NSArray*)arguments {
	return _arguments;
}

-(void)setArguments:(NSArray*)arguments {
	[_arguments release];
	_arguments = [arguments retain];
}

-(NSString*)currentDirectoryPath {
	return _currentDirectoryPath;
}

-(void)setCurrentDirectoryPath:(NSString*)currentDirectoryPath {
	[_currentDirectoryPath release];
	_currentDirectoryPath = [currentDirectoryPath retain];
}

-(NSDictionary*)environment {
	return _environment;
}

-(void)setEnvironment:(NSDictionary*)environment {
	[_environment release];
	_environment = [environment retain];
}

-(NSString*)launchPath {
	return _launchPath;
}

-(void)setLaunchPath:(NSString*)launchPath {
	[_launchPath release];
	_launchPath = [launchPath retain];
}

-(int)processIdentifier {
	return _pid;
}

-(id)standardError {
	return _standardError;
}

-(void)setStandardError:(id)standardError {
	[_standardError release];
	_standardError = [standardError retain];
}

-(id)standardInput {
	return _standardInput;
}

-(void)setStandardInput:(id)standardInput {
	[_standardInput release];
	_standardInput = [standardInput retain];
}

-(id)standardOutput {
	return _standardOutput;
}

-(void)setStandardOutput:(id)standardOutput {
	[_standardOutput release];
	_standardOutput = [standardOutput retain];
}

@end

