//
//  dicomDump.m
//  echoSCU
//
//  Created by Lance Pysher on 1/7/05.
//  Copyright 2005 OsiriXOsiriX. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>
#import <Osirix/DCMNetworking.h>


int main (int argc, const char * argv[]) {
	 NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (argc <=1)
		NSLog(@"dicomDump usage: file");
	else{
		DCMObject *dcmObject =[DCMObject objectWithContentsOfFile:[NSString stringWithUTF8String:argv[1]] decodingPixelData:NO];
		NSLog([dcmObject description]);
	}
   
	[pool release];
	return 0;
}

