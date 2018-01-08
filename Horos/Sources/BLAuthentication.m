/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/
//  ====================================================================== 	//
//  BLAuthentication.h														//
//  																		//
//  Last Modified on Tuesday April 24 2001									//
//  Copyright 2001 Ben Lachman												//
//																			//
//	Thanks to Brian R. Hill <http://personalpages.tds.net/~brian_hill/>		//
//  ====================================================================== 	//

#import "BLAuthentication.h"
#import <Security/AuthorizationTags.h>
#include <sys/stat.h>

OSStatus AuthorizationExecuteWithPrivilegesStdErrAndPid (
                                                         AuthorizationRef authorization, 
                                                         const char *pathToTool, 
                                                         AuthorizationFlags options, 
                                                         char * const *arguments, 
                                                         FILE **communicationsPipe,
                                                         FILE **errPipe,
                                                         pid_t* processid
                                                         )
{
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: @"/tmp/"];
    
    char stderrpath[] = "/tmp/AuthorizationExecuteWithPrivilegesStdErrXXXXXXX.err" ;
	const char* commandtemplate = "echo $$; \"$@\" 2>%s" ;
    if (communicationsPipe == errPipe) {
        commandtemplate = "echo $$; \"$@\" 2>1";
    } else if (errPipe == 0) {
        commandtemplate = "echo $$; \"$@\"";
    }
	char command[1024];
	char ** args = nil;
	OSStatus result;
	int argcount = 0;
	int i;
	int stderrfd = 0;
	FILE* commPipe = 0;
	
	/* Create temporary file for stderr */
    
    if (errPipe) {
        stderrfd = mkstemps (stderrpath, strlen(".err")); 
        
        /* create a pipe on that path */ 
        close(stderrfd); unlink(stderrpath);
        if (mkfifo(stderrpath,S_IRWXU | S_IRWXG) != 0) {
            fprintf(stderr,"Error mkfifo:%d\n",errno);
            return errAuthorizationInternal;
        }
        
        if (stderrfd < 0)
            return errAuthorizationInternal;
    }
    
	/* Create command to be executed */
    if( arguments)
        for (argcount = 0; arguments[argcount] != 0; ++argcount) {}	
	args = (char**)malloc (sizeof(char*)*(argcount + 5));
	args[0] = "-c";
	snprintf (command, sizeof (command), commandtemplate, stderrpath);
	args[1] = command;
	args[2] = "";
	args[3] = (char*)pathToTool;
	for (i = 0; i < argcount; ++i) {
		args[i+4] = arguments[i];
	}
	args[argcount+4] = 0;
    
    /* for debugging: log the executed command */
	/* printf ("Exec:\n%s", "/bin/sh"); for (i = 0; args[i] != 0; ++i) { printf (" \"%s\"", args[i]); } printf ("\n"); */
    
	/* Execute command */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	result = AuthorizationExecuteWithPrivileges(authorization, "/bin/sh",  options, args, &commPipe );
#pragma clang diagnostic pop
	if (result != noErr) {
		unlink (stderrpath);
        free( args);
		return result;
	}
	
    [NSThread sleepForTimeInterval: 0.2];
    
	/* Read the first line of stdout => it's the pid */
	{
		int stdoutfd = fileno (commPipe);
		char pidnum[1024];
		pid_t pid = 0;
		int i = 0;
		char ch = 0;
		while ((read(stdoutfd, &ch, sizeof(ch)) == 1) && (ch != '\n') && (i < sizeof(pidnum))) {
			pidnum[i++] = ch;
		}
		pidnum[i] = 0;
		if (ch != '\n') {
			// we shouldn't get there
			unlink (stderrpath);
			return errAuthorizationInternal;
		}
		sscanf(pidnum, "%d", &pid);
		if (processid) {
			*processid = pid;
		}
	}
	
	if (errPipe) {
        stderrfd = open(stderrpath, O_RDONLY, 0);
        *errPipe = fdopen(stderrfd, "r");
        /* Now it's safe to unlink the stderr file, as the opened handle will be still valid */
        unlink (stderrpath);
	} else {
		unlink(stderrpath);
	}
	if (communicationsPipe) {
		*communicationsPipe = commPipe;
	} else {
		fclose (commPipe);
	}
    
    [[NSFileManager defaultManager] removeItemAtPath: [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent: @"1"] error: nil];
    
    if( args)
        free( args);
    
	return noErr;
}


@implementation BLAuthentication

// returns an instace of itself, creating one if needed
+ sharedInstance {
    static id sharedTask = nil;
    if(sharedTask==nil) {
        sharedTask = [[BLAuthentication alloc] init];
    }
    return sharedTask;
}

// initializes the super class and sets authorizationRef to NULL 
- (id)init {
    self = [super init];
    authorizationRef = NULL;
    return self;
}

// deauthenticates the user and deallocates memory
- (void)dealloc {
    [self deauthenticate];
    
    [super dealloc];
}

//============================================================================
//	- (BOOL)isAuthenticated:(NSArray *)forCommands
//============================================================================
// Find outs if the user has the appropriate authorization rights for the 
// commands listed in (NSArray *)forCommands.
// This should be called each time you need to know whether the user
// is authorized, since the AuthorizationRef can be invalidated elsewhere, or
// may expire after a short period of time.
//
- (BOOL)isAuthenticated:(NSArray *)forCommands {
	AuthorizationRights rights;
	AuthorizationRights *authorizedRights;
	AuthorizationFlags flags;
	
	int numItems = [forCommands count];
	AuthorizationItem *items = malloc( sizeof(AuthorizationItem) * numItems );
	char paths[20][128]; // only handles upto 20 commands with paths upto 128 characters in length
	
	OSStatus err = 0;
	BOOL authorized = NO;
	int i = 0;

	if(authorizationRef==NULL) {
		rights.count=0;
		rights.items = NULL;
		
		flags = kAuthorizationFlagDefaults;
		
		err = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authorizationRef);
	}
    	
	if( numItems < 1 )
    {
        free( items);
		return authorized;
	}

	while( i < numItems && i < 20 ) {
		 [[forCommands objectAtIndex:i] getCString:paths[i] maxLength:128 encoding:NSUTF8StringEncoding];
		
		items[i].name = kAuthorizationRightExecute;
		items[i].value = paths[i];
		items[i].valueLength = strlen(paths[i]);
		items[i].flags = 0;
		
		i++;
	}
	
    rights.count = numItems;
    rights.items = items;
    
    flags = kAuthorizationFlagExtendRights;
    
    err = AuthorizationCopyRights(authorizationRef, &rights, kAuthorizationEmptyEnvironment, flags, &authorizedRights);

    authorized = (errAuthorizationSuccess==err);

	if(authorized)
		AuthorizationFreeItemSet(authorizedRights);
	
    if( items)
        free(items);
	
    return authorized;
}

//============================================================================
//	- (void)deauthenticate
//============================================================================
// Deauthenticates the user by freeing their authorization.
//
- (void)deauthenticate {
    if(authorizationRef) {
        AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
        authorizationRef = NULL;
        [[NSNotificationCenter defaultCenter]postNotificationName:BLDeauthenticatedNotification object:self];
    }
}

//============================================================================
//	- (BOOL)fetchPassword:(NSArray *)forCommands
//============================================================================
// Adds rights for commands specified in (NSArray *)forCommands.
// Commands should be passed as a NSString comtaining the path to the executable. 
// Returns YES if rights were gained
//
- (BOOL)fetchPassword:(NSArray *)forCommands {
	AuthorizationRights rights;
	AuthorizationRights *authorizedRights;
	AuthorizationFlags flags;
	
	int numItems = [forCommands count];
	AuthorizationItem *items = malloc( sizeof(AuthorizationItem) * numItems );
	char paths[20][128];
	
	OSStatus err = 0;
	BOOL authorized = NO;
	int i = 0;
	
	if( numItems < 1 )
    {
        free( items);
		return authorized;
	}
    
	while( i < numItems && i < 20 ) {
		[[forCommands objectAtIndex:i] getCString:paths[i] maxLength:128 encoding:NSUTF8StringEncoding];
		
		items[i].name = kAuthorizationRightExecute;
		items[i].value = paths[i];
		items[i].valueLength = strlen(paths[i]);
		items[i].flags = 0;
		
		i++;
	}
	
	rights.count = numItems;
	rights.items = items;
	
	flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	err = AuthorizationCopyRights(authorizationRef, &rights, kAuthorizationEmptyEnvironment, flags, &authorizedRights);
	
	authorized = (errAuthorizationSuccess == err);
	
	if(authorized) {
		AuthorizationFreeItemSet(authorizedRights);
		[[NSNotificationCenter defaultCenter] postNotificationName:BLAuthenticatedNotification object:self];
	}                                                    

	free(items);
	
	return authorized;
}

//============================================================================
//	- (BOOL)authenticate:(NSArray *)forCommands
//============================================================================
// Authenticates the commands in the array (NSArray *)forCommands by calling 
// fetchPassword.
//
- (BOOL)authenticate:(NSArray *)forCommands {
	if( ![self isAuthenticated:forCommands] ) {
        [self fetchPassword:forCommands];
	}
	
	return [self isAuthenticated:forCommands];
}


//============================================================================
//	- (int)getPID:(NSString *)forProcess
//============================================================================
// Retrieves the PID (process ID) for the process specified in 
// (NSString *)forProcess.
// The more specific forProcess is the better your accuracy will be, esp. when 
// multiple versions of the process exist. 
//
- (int)getPID:(NSString *)forProcess {
	FILE* outpipe = NULL;
	NSMutableData* outputData = [NSMutableData data];
	
	NSString *commandOutput = nil;
	NSString *scannerOutput = nil;
	NSString *popenArgs = [[NSString alloc] initWithFormat:@"/bin/ps -axwwopid,command | grep \"%@\"",forProcess];
	NSScanner *outputScanner = nil;
	NSScanner *intScanner = nil;
	int pid = 0;
	int len = 0;
    
    outpipe = popen([popenArgs UTF8String],"r");

	[popenArgs release];

	if(!outpipe) {
        NSLog(@"Error opening pipe: %@",forProcess);
        NSBeep();
        return 0;
    }
	
	NSMutableData* tempData = [[NSMutableData alloc] initWithLength:512];
	
	do {
        [tempData setLength:512];
        len = fread([tempData mutableBytes],1,512,outpipe);
        if( len > 0 ) {
            [tempData setLength:len];
            [outputData appendData:tempData];        
		}
	} while(len==512);
    
	[tempData release];

	pclose(outpipe);
	
	commandOutput = [[NSString alloc] initWithData:outputData encoding:NSASCIIStringEncoding];    
	
	if( [commandOutput length] > 0 ) {
		outputScanner = [NSScanner scannerWithString:commandOutput];
		
		[commandOutput release];
		
		[outputScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[outputScanner scanUpToString:forProcess intoString:&scannerOutput];
		
		if( [scannerOutput rangeOfString:@"grep"].length != 0 ) {
			return 0;
		}
		
		intScanner = [NSScanner scannerWithString:scannerOutput];
		
		[intScanner scanInt:&pid];
		
		if( pid ) {
			return pid;
		}
		else {
			return 0;
		}
	}
	else {
		[commandOutput release];

		return 0;
	}
}


//============================================================================
//	-(void)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments
//============================================================================
// Executes command in (NSString *)pathToCommand with the arguments listed in
// (NSArray *)arguments as root.
// pathToCommand should be a string contain the path to the command 
// (eg., /usr/bin/more), arguments should be an array of strings each containing
// a single argument.
//
-(BOOL)executeCommand:(NSString *)pathToCommand withArgs:(NSArray *)arguments
{
    #ifdef MACAPPSTORE
    NSTask *task = [NSTask launchedTaskWithLaunchPath: pathToCommand arguments: arguments];
    [task waitUntilExit];
    return YES;
    #else
	char* args[30]; // can only handle 30 arguments to a given command
	OSStatus err = 0;
	int i = 0;
	pid_t processid;
    
	if(![self authenticate:[NSArray arrayWithObject:pathToCommand]])
		return NO;
	
	if( arguments == nil || [arguments count] < 1)
    {
        err = AuthorizationExecuteWithPrivilegesStdErrAndPid(   authorizationRef, 
                                                             [pathToCommand UTF8String], 
                                                             kAuthorizationFlagDefaults, 
                                                             nil, 
                                                             nil,
                                                             nil,
                                                             &processid);
        
//		err = AuthorizationExecuteWithPrivileges(authorizationRef, [pathToCommand UTF8String], 0, NULL, NULL);
	}
	else
	{
		while( i < [arguments count] && i < 19)
		{
			args[i] = (char*)[[arguments objectAtIndex:i] UTF8String];
			i++;
		}
		args[i] = NULL;
        
        err = AuthorizationExecuteWithPrivilegesStdErrAndPid(   authorizationRef, 
                                                             [pathToCommand UTF8String], 
                                                             kAuthorizationFlagDefaults, 
                                                             args, 
                                                             nil,
                                                             nil,
                                                             &processid);
        
//		err = AuthorizationExecuteWithPrivileges(authorizationRef,
//												[pathToCommand UTF8String],
//												0, args, NULL);
	}
	
    if( err != 0)
	{
		NSBeep();
		NSLog(@"Error %d in AuthorizationExecuteWithPrivileges",(int)err);
		return NO;
	}
	else
	{
        pid_t waitResult;
		int junkStatus;
        
        do
        {
			waitResult = waitpid( processid, &junkStatus, 0);
		}
        while((waitResult < 0) && (errno == EINTR));
        
		return YES;
	}
    #endif
}


//============================================================================
//	- (void)killProcess:(NSString *)commandFromPS
//============================================================================
// Finds and kills the process specified in (NSString *)commandFromPS using ps 
// and kill. (by pid)
// The more specific (ie., closer to matching the actual listing in ps) 
// commandFromPS is the better your accuracy will be, esp. when multiple 
// versions of the process exist.
//
- (BOOL)killProcess:(NSString *)commandFromPS {
	NSString *pid;

	if( ![self isAuthenticated:[NSArray arrayWithObject:commandFromPS]] ) {
		[self authenticate:[NSArray arrayWithObject:commandFromPS]];
	}
	
	pid = [NSString stringWithFormat:@"%d",[self getPID:commandFromPS]];
	
	if( [pid intValue] > 0 ) {
		[self executeCommand:@"/bin/kill" withArgs:[NSArray arrayWithObject:pid]];
		return YES;
	}
	else {
		NSBeep();
		NSLog(@"Error killing process %@, invalid PID.",pid);
		return NO;
	}
}	
@end

// BLAuthentication sends these notifications are sent when the user  
// becomes authenticated or deauthenticated.

// Sample notification observer:
/*
    [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(userAuthenticated:)
                                        name:BLAuthenticatedNotification
                                        object:[BLAuthentication sharedInstance]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                        selector:@selector(userDeauthenticated:)
                                        name:BLDeauthenticatedNotification
                                        object:[BLAuthentication sharedInstance]];
*/




