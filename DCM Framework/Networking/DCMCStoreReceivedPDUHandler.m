//
//  DCMCStoreReceivedPDUHandler.m
//  OsiriX
//
//  Created by Lance Pysher on 12/23/04.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMCStoreReceivedPDUHandler.h"
#import "DCM.h"
#import "DCMNetworking.h"
//#import "DCMCEchoResponse.h"
//#import "DCMCStoreResponse.h"
//#import "DCMCEchoRequest.h"
//#import "DCMCStoreRequest.h"
//#import "DCMPresentationDataValue.h"
//#import	"DCMPDataPDU.h"
//#import "DCMAssociation.h"


@implementation DCMCStoreReceivedPDUHandler

+ (id)cStoreDataHanderWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug{
	return [[[DCMCStoreReceivedPDUHandler alloc] initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug] autorelease];
}
- (id)initWithDestinationFolder:(NSString *)destination  debugLevel:(int)debug{
	if (debug)
		NSLog(@"init DCMCStoreReceivedPDUHandler");
	if (self = [super initWithDebugLevel:debug]){
		folder = [destination retain];
		echoRequest = nil;
		storeRequest = nil;
		numberReceived = 0;
		errorCount = 0;
		patientName = nil;
		studyDescription = nil;
		studyID= nil;
	} 
	return self;
}

- (void)dealloc{
	//NSLog(@"Release receive dataHandler");
	NSMutableDictionary  *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@"Complete" forKey:@"Message"];
	[userInfo setObject:[NSNumber numberWithInt:numberReceived] forKey:@"NumberReceived"];
	[userInfo setObject:[NSNumber numberWithInt:errorCount] forKey:@"ErrorCount"];
	if (date)
		[userInfo setObject:date forKey:@"Time"];
	if (callingAET)
		[userInfo setObject:callingAET forKey:@"CallingAET"];		
	if (patientName)
		[userInfo setObject:patientName forKey:@"PatientName"];		
	if (studyDescription)
		[userInfo setObject:studyDescription forKey:@"StudyDescription"];	
	else if (studyID)
		[userInfo setObject:studyID forKey:@"StudyDescription"];
	else
		[userInfo setObject:@"unknown" forKey:@"StudyDescription"];
	if (studyID)
		[userInfo setObject:studyID forKey:@"StudyID"];
	if (date)
		[userInfo setObject:date forKey:@"Time"];

				
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMReceiveStatus" object:self userInfo:userInfo];

	[folder release];
	[dcmObject release];
	[echoRequest release];
	[storeRequest release];
	[findRequest release];
	[moveRequest release];
	[response release];
	[fileName release];
	[responseMessage release];
	[patientName release];
	[studyDescription release];
	[studyID release];
	[callingAET release];
	[super dealloc];
}

- (void)cEchoResponse{
	DCMCEchoResponse *echoResponse = [DCMCEchoResponse echoResponseWithAffectedClassUID:[echoRequest affectedSOPClassUID] messageIDBeingRespondedTo:[echoRequest messageID]  status:0x0000];
	NSLog(@"Echo response:\n%@" , [echoResponse description]);
	[response release];
	response = [[echoResponse data] retain];
	[responseMessage release];
	responseMessage = [echoResponse retain];

}
- (void)cStoreResponse{
	DCMCStoreResponse *storeResponse = [DCMCStoreResponse cStoreResponseWithAffectedSOPClassUID:[storeRequest affectedSOPClassUID]  
		affectedSOPInstanceUID:[storeRequest affectedSOPInstanceUID]  
		messageIDBeingRespondedTo:[storeRequest messageID] status:0x0000];
	//NSLog(@"cStore response:\n%@" , [storeResponse description]);
	[response release];
	response = [[storeResponse data] retain];
	[responseMessage release];
	responseMessage = [storeResponse retain];
}

- (void)cMoveResponse{
	[responseMessage release];
	response = nil;

}
- (void)cFindResponse{
	[responseMessage release];
	response = nil;	
	DCMCFindResponse *findResponse = [DCMCFindResponse cFindResponseWithAffectedSOPClassUID:[findRequest affectedSOPClassUID]  
		priority:[findRequest priority]
		messageIDBeingRespondedTo:[findRequest messageIDBeingRespondedTo]
		remainingSuboperations:0x0000
		completedSuboperations:0x0000
		failedSuboperations:0x0000
		warningSuboperations:0x0000
		status:0x0000];
	response = [[findResponse data] retain];
	[responseMessage release];
	responseMessage = [findResponse retain];
	isDone = YES;
	
}


- (void)sendPDataIndication:(DCMPDataPDU *)pdu   association:(DCMAssociation *)association{
	
	NSEnumerator *enumerator =  [[pdu pdvList] objectEnumerator];
	DCMPresentationDataValue *pdv;
	DCMTransferSyntax *transferSyntax; 
	while (pdv = [enumerator nextObject]){
		if ([pdv isCommand]){
			[commandReceived appendData:[pdv value]];
			if ([pdv isLastFragment]){
				presentationContextID = [pdv presentationContextID];
				transferSyntax = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
				
				[dcmObject release];
				dcmObject = [[self objectFromCommandOrData:commandReceived withTransferSyntax:transferSyntax] retain];
				if (debugLevel)
					NSLog(@"Command %@", [dcmObject description]);
				int command = [[dcmObject attributeValueWithName:@"CommandField"] intValue];
				commandType =  command;
				
				
				// C Echo request
				if (command == 0x0030){
					[echoRequest release];
					echoRequest = nil;
					echoRequest = [[DCMCEchoRequest alloc] initWithObject:dcmObject];
					NSLog(@"Echo Request:\n%@", [echoRequest description]);
					[self cEchoResponse];
					isDone = YES;
				}
				//c Store request
				else if (command == 0x0001){
					isDone = NO;
					[storeRequest release];
					storeRequest = nil;
					storeRequest = [[DCMCStoreRequest alloc] initWithObject:dcmObject];
					//NSLog(@"C Store Request:\n%@", [storeRequest description]);
					[self cStoreResponse];
					
				} 
				
				// c Find request
				else if (command == 0x0020) {
					isDone = NO;
					[findRequest release];
					findRequest = nil;
					findRequest = [[DCMCFindRequest alloc] initWithObject:dcmObject];
					//NSLog(@"Find Request:\n%@", [findRequest description]);
					[self cFindResponse];
					
				}
				
				// c Move request
				else if(command == 0x0021) {
					[moveRequest release];
					moveRequest = nil;
					moveRequest = [[DCMCMoveRequest alloc] initWithObject:dcmObject];
					//NSLog(@"Move Request:\n%@", [moveRequest description]);
					[self cMoveResponse];
					isDone = NO;
				}
				
				else
					NSLog(@"Unexpected Command");
				[commandReceived release];
				commandReceived = [[NSMutableData data] retain];
			}
		}
		else{				
			[dataReceived appendData:[pdv value]];
			
			if ([pdv isLastFragment]){
				presentationContextID = [pdv presentationContextID];
				transferSyntax = [association transferSyntaxForPresentationContextID:presentationContextID];
				[dcmObject release];
				dcmObject = [[self objectFromCommandOrData:dataReceived withTransferSyntax:transferSyntax] retain];
				//add metaheader first
				if (commandType == 0x0001){
					[dcmObject setAttributeValues:[NSArray arrayWithObject:[[storeRequest dcmObject] attributeValueWithName:@"AffectedSOPInstanceUID"]] forName:@"MediaStorageSOPInstanceUID"];
					[dcmObject setAttributeValues:[NSArray arrayWithObject:[[storeRequest dcmObject] attributeValueWithName:@"AffectedSOPClassUID"]] forName:@"MediaStorageSOPClassUID"];

					DCMAttributeTag *tsTag = [DCMAttributeTag tagWithName:@"TransferSyntax"];
					DCMAttribute *tsAttr = [DCMAttribute attributeWithAttributeTag:tsTag];
					[tsAttr addValue:[transferSyntax transferSyntax]]; 
					[dcmObject setAttribute:tsAttr];
					
					DCMAttributeTag *aetTag = [DCMAttributeTag tagWithName:@"SourceApplicationEntityTitle"];
					DCMAttribute *aetAttr = [DCMAttribute attributeWithAttributeTag:aetTag];
					[aetAttr addValue:[association callingAET]];
					[dcmObject setAttribute:aetAttr];
					//  TS, callingAET
					fileName = [[dcmObject attributeValueWithName:@"SOPInstanceUID"] retain];
				}
				else if (commandType == 0x0020) {
					//[dcmObject setAttributeValues:[NSArray arrayWithObject:[[findRequest dcmObject] attributeValueWithName:@"AffectedSOPInstanceUID"]] forName:@"MediaStorageSOPInstanceUID"];
				}
				else if (commandType == 0x0021) {
					//[dcmObject setAttributeValues:[NSArray arrayWithObject:[[moveRequest dcmObject] attributeValueWithName:@"AffectedSOPInstanceUID"]] forName:@"MediaStorageSOPInstanceUID"];
				}
				[self makeUseOfDataSet:dcmObject];
				[dataReceived release];
				dataReceived = [[NSMutableData data] retain];
				isDone = YES;
				
				[patientName release];
				[studyDescription release];
				[studyID release];
				patientName = nil;
				studyDescription = nil;
				studyID= nil;
				patientName = [[dcmObject attributeValueWithName:@"PatientsName"] retain];
				studyDescription = [[dcmObject attributeValueWithName:@"StudyDescription"] retain];
				studyID = [[dcmObject attributeValueWithName:@"studyID"] retain];
					
				NSMutableDictionary  *userInfo = [NSMutableDictionary dictionary];
				//[userInfo setObject:[NSNumber numberWithInt:numberOfFiles] forKey:@"SendTotal"];
				[userInfo setObject:[NSNumber numberWithInt:++numberReceived] forKey:@"NumberReceived"];
				[userInfo setObject:[NSNumber numberWithInt:errorCount] forKey:@"ErrorCount"];
				[userInfo setObject:@"In Progress" forKey:@"Message"];
					
				if (callingAET)
					[userInfo setObject:callingAET forKey:@"CallingAET"];		
				if (patientName)
					[userInfo setObject:patientName forKey:@"PatientName"];		
				if (studyDescription)
					[userInfo setObject:studyDescription forKey:@"StudyDescription"];	
				else if (studyID)
					[userInfo setObject:studyID forKey:@"StudyDescription"];
				else
					[userInfo setObject:@"unknown" forKey:@"StudyDescription"];
				if (studyID)
					[userInfo setObject:studyID forKey:@"StudyID"];
				if (date)
					[userInfo setObject:date forKey:@"Time"];

				[self 	updateReceiveStatus:userInfo];		
				[[NSNotificationCenter defaultCenter] postNotificationName:@"DCMReceiveStatus" object:self userInfo:userInfo];
				
			}
		}
	}	
		
}
- (void)updateReceiveStatus:(NSDictionary *)userInfo{
}

- (void)evaluateStatusAndSetSuccess:(DCMObject *)object{
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:calledAET forKey:@"CalledAET"];
		[userInfo setObject:date forKey:@"Time"];
		[super evaluateStatusAndSetSuccess:object];
	}


- (NSData *)response{

	return response;
}

- (void) makeUseOfDataSet:(DCMObject *)object{
	NSString *filename = [[dcmObject attributeValueWithName:@"SOPInstanceUID"] retain];
	NSString *destination = [NSString stringWithFormat:@"%@/%@", folder, filename];
	[object writeToFile:destination withTransferSyntax:nil quality:nil atomically:YES];
}

- (DCMObject *)dicomObject{
	return dcmObject;
}

- (unsigned char)presentationContextID{
	return presentationContextID;
}

- (DCMCommandMessage *)responseMessage{
	return responseMessage;
}

- (void)reset{
	isDone = NO;
	[response release];
	response= nil;
	[responseMessage release];
	responseMessage = nil;
	[dcmObject release];
	dcmObject = nil;
	[echoRequest release];
	echoRequest = nil;
	[storeRequest release];
	storeRequest = nil;
}

- (NSString *)callingAET{
	return callingAET;
}
- (void)setCallingAET:(NSString *)aet{
	[callingAET release];
	callingAET = [aet retain];
}

- (void)setSCPDelegate:(id)delegate{
	scpDelegate = delegate;
}

- (int)commandType{
	return commandType;
}



@end
