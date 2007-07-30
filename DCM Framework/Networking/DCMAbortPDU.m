//
//  DCMAbortPDU.m
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


#import "DCMAbortPDU.h"


@implementation DCMAbortPDU

 + (id)abortWithSource:(unsigned char)aSource  reason:(unsigned char)aReason{
	return [[[DCMAbortPDU alloc] initWithSource:aSource  reason:aReason] autorelease];
}

 + (id)abortWithData:(NSData *)data{
	return [[[DCMAbortPDU alloc] initWithData:data] autorelease];
}

- (id)initWithSource:(unsigned char)aSource  reason:(unsigned char)aReason{
	if (self = [super init]){
		pduType = 0x07;
		source = aSource;
		reason = aReason;
		pduLength = 4;
		pdu = [[NSMutableData alloc] initWithLength:10];
		unsigned char *b = (unsigned char *)[pdu mutableBytes];
		
		b[0]=(unsigned char)pduType;						// A-ABORT PDU Type
		b[1]=0x00;							// reserved
		pduLength = 4;
		b[2]=(unsigned char)(pduLength>>24);					// big endian
		b[3]=(unsigned char)(pduLength>>16);
		b[4]=(unsigned char)(pduLength>>8);
		b[5]=(unsigned char)pduLength;
		b[6]=0x00;							// reserved
		b[7]=0x00;							// reserved
		b[8]=(unsigned char)source;
		b[9]=(unsigned char)reason;

	}
	return self;
}

- (id)initWithData:(NSData *)data{
	if (self = [super init]) {
		pdu = [data retain];
		[pdu getBytes:&pduType range:NSMakeRange(0,1)];
		[pdu getBytes:&pduLength range:NSMakeRange(2,4)];
		pduLength = NSSwapBigIntToHost(pduLength);
		[pdu getBytes:&source range:NSMakeRange(8,1)];
		[pdu getBytes:&reason range:NSMakeRange(9,1)];
	}
	return self;
}




- (NSString *)info{
	NSMutableString *info = [NSMutableString stringWithString:@"Aborted"];
	if     (source == 0) 
		[info appendString:@" by DICOM UL Service User"];
	else if (source == 2) 
		[info appendString:@"by DICOM UL Service Provider"];
		
	if (source == 2) {
			if      (reason == 0) {
				[info appendString:@", reason not specified"];
			}
			else if (reason == 1) {
				[info appendString:@", unrecognized PDU"];
			}
			else if (reason == 2) {
				[info appendString:@", unexpected PDU"];
			}
			else if (reason == 4) {
				[info appendString:@", unrecognized PDU parameter"];
			}
			else if (reason == 5) {
				[info appendString:@", unexpected PDU parameter"];
			}
			else if (reason == 6) {
				[info appendString:@", invalid PDU parameter value"];
			}
		}
		
	return info;	
}

- (NSString *)description{
	return [self info];
}

@end
