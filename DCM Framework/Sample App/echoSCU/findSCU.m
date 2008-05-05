//
//  findSCU.m
//  echoSCU
//
//  Created by Lance Pysher on 1/1/05.
//  Copyright 2005 OsiriX. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Osirix/DCM.h>
#import <Osirix/DCMNetworking.h>

@class DCMStoreSCU;
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
       // insert code here...
	if (argc <= 3) {
		NSLog(@"calledAET hostname port");
	}
	else{
	
		DCMObject *findObject = [DCMObject dcmObject];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
		[findObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate date]] forName:@"StudyDate"];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyTime"];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
		[findObject setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"Query/RetrieveLevel"];
		
		
		NSMutableDictionary *params = [NSMutableDictionary dictionary];
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:@"storeSCU" forKey:@"callingAET"];
		[params setObject:[NSString stringWithUTF8String:argv[1]] forKey:@"calledAET"];
		[params setObject:[NSString stringWithUTF8String:argv[2]]  forKey:@"hostname"];
		[params setObject:[NSString stringWithUTF8String:argv[3]]  forKey:@"port"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
		[params setObject:findObject forKey:@"findObject"];
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelFind] forKey:@"affectedSOPClassUID"];
		[DCMFindSCU findWithParameters:params];
		/*
		DCMRootQueryNode *node = [DCMRootQueryNode queryNodeWithObject:nil];
		[node queryWithValues:nil parameters:params];
		NSEnumerator *enumerator = [[node children] objectEnumerator];
		DCMStudyQueryNode *studyNode;
		while (studyNode = [enumerator nextObject])
			[studyNode queryWithValues:nil parameters:params];
		NSLog(@"Node:\n%@", [node description]);
		*/
		}
	
	[pool release];
	return 0;
}
