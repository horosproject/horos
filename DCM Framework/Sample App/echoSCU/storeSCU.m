//
//  storeSCU.m
//  echoSCU
//
//  Created by Lance Pysher on 12/21/04.
//  Copyright 2004 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>
#import <Osirix/DCMNetworking.h>

@class DCMStoreSCU;
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
       // insert code here...
	
	if (argc < 5) {
		NSLog(@"calledAET hostname port files....");
	}
	else{
		int i = 4;
		NSMutableArray *files = [NSMutableArray array];
		for (i = 4; i < argc; i++) 
			[files addObject:[NSString stringWithUTF8String:argv[i]]];
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:@"storeSCP" forKey:@"callingAET"];
		[params setObject:[NSString stringWithUTF8String:argv[1]] forKey:@"calledAET"];
		[params setObject:[NSString stringWithUTF8String:argv[2]]  forKey:@"hostname"];
		[params setObject:[NSString stringWithUTF8String:argv[3]]  forKey:@"port"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
		[params setObject:files forKey:@"filesToSend"];
		[DCMStoreSCU sendWithParameters:params];
		}
	
	[pool release];
	return 0;
}


