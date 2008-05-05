//
//  storeSCP.m
//  echoSCU
//
//  Created by Lance Pysher on 12/25/04.
//  Copyright 2004 OsiriX. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>
#import <Osirix/DCMNetworking.h>

@class DCMStoreSCPListener;
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

       // insert code here...
   // NSLog(@"Hello, World argc:%d", argc);
	if (argc <= 1) {
		NSLog(@"calledAET  port folder");
	}
	else if (argc == 2  && [[NSString stringWithUTF8String:argv[1]] isEqualToString:@"-osirix"]){
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		NSString *prefsPath = [@"~/Library/Preferences/com.rossetantoine.osiriX.plist" stringByExpandingTildeInPath];
		NSDictionary *osirixPrefs= [NSDictionary dictionaryWithContentsOfFile:prefsPath];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:[osirixPrefs objectForKey:@"AETITLE"] forKey:@"calledAET"];
		[params setObject:[osirixPrefs objectForKey:@"AEPORT"] forKey:@"port"];
		[params setObject:[NSString stringWithFormat:@"%@/INCOMING", [osirixPrefs objectForKey:@"DATABASELOCATIONURL"]] forKey:@"folder"];
		[DCMStoreSCPListener listenWithParameters:params];
	}
	else{
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		//[params setObject:@"ECHOSCU" forKey:@"callingAET"];
		[params setObject:[NSString stringWithUTF8String:argv[1]] forKey:@"calledAET"];
		[params setObject:[NSString stringWithUTF8String:argv[2]]  forKey:@"port"];
		[params setObject:[NSString stringWithUTF8String:argv[3]]  forKey:@"folder"];
		[DCMStoreSCPListener listenWithParameters:params];
	}
	
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	[loop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
	[loop run];
	/*
	while (YES){
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
	}
	*/
	[pool release];
	return 0;
}



