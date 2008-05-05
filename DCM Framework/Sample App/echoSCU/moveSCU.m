//
//  moveSCU.m
//  echoSCU
//
//  Created by Lance Pysher on 1/7/05.
//  Copyright 2005 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>
#import <Osirix/DCMNetworking.h>


int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	 NSLog(@"Hello World");
	 if (argc <= 5) {
		NSLog(@"calledAET hostname port moveDesintation StudyInstanceUID");
	}
	else{
		
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:@"moveSCU" forKey:@"callingAET"];
		[params setObject:[NSString stringWithUTF8String:argv[1]] forKey:@"calledAET"];
		[params setObject:[NSString stringWithUTF8String:argv[2]]  forKey:@"hostname"];
		[params setObject:[NSString stringWithUTF8String:argv[3]]  forKey:@"port"];
		NSString *moveDestination = [NSString stringWithUTF8String:argv[4]];
		[params setObject:moveDestination  forKey:@"moveDestination"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelMove] forKey:@"affectedSOPClassUID"];
		
		DCMObject *moveObject = [DCMObject dcmObject];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[NSString stringWithUTF8String:argv[5]]] forName:@"StudyInstanceUID"];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"Query/RetrieveLevel"];
		
		[params setObject:moveObject forKey:@"moveObject"];
		NSLog(@"move params; %@", [params description]);
		[DCMMoveSCU moveWithParameters:params];
	} 
	[pool release];
	return 0;
}
