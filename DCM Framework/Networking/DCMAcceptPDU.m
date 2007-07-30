//
//  DCMAcceptPDU.m
//  OsiriX
//
//  Created by Lance Pysher on 11/28/04.

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


#import "DCMAcceptPDU.h"
#import "DCMPresentationContext.h"
#import "DCMTransferSyntax.h"

	/**
	 * @param	calledAETitle
	 * @param	callingAETitle
	 * @param	implementationClassUID
	 * @param	implementationVersionName
	 * @param	ourMaximumLengthReceived	the maximum PDU length that we will offer to receive
	 * @param	presentationContexts
	 * @exception	DicomNetworkException
	 */
	 
@implementation DCMAcceptPDU

+ (id)acceptPDUWithParameters:(NSDictionary *)params{
	return [[[DCMAcceptPDU alloc] initWithParameters:params] autorelease];
}

+ (id)acceptPDUWithData:(NSData *)data{
	NSMutableData *dataCopy = [NSMutableData dataWithData:data];
	return [[(DCMAcceptPDU *)[DCMAcceptPDU alloc] initWithData:dataCopy] autorelease];
}

- (id)initWithParameters:(NSDictionary *)params{
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
	[parameters setObject:[NSNumber numberWithChar:0x02] forKey:@"pduType"];
	return [super initWithParameters:parameters];
	

}

- (NSArray *)sanitizePresentationContextsForAcceptance{
	NSMutableArray *newContexts =  [NSMutableArray array];
	NSEnumerator *enumerator = [presentationContexts objectEnumerator];
	DCMPresentationContext *presentationContext;
	DCMPresentationContext *newContext;
	while (presentationContext = [enumerator nextObject]) {
		newContext = [DCMPresentationContext contextWithID:[presentationContext contextID]]; 
		if ([[presentationContext transferSyntaxes] count] > 0) 
			[newContext addTransferSyntax:[[presentationContext transferSyntaxes] objectAtIndex:0]];
		else
			[newContext addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
		//if ([[presentationContext transferSyntaxes] count] < 1) 
		//	[presentationContext addTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]];
			//no Abstract Syntax for Acceptance
		//[presentationContext setAbstractSyntax:nil];
	}
	return newContexts;
}

			
- (id)initWithData:(NSMutableData *)data{
	if (self = [super initWithData:data]){
		if (pduType != 0x02)
			NSLog(@"Unexpected PDU type 0x%x when expecting A-ASSOCIATE-AC", pduType);
	}
	return self;
}
	






@end
