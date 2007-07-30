//
//  DCMRejecttPDU.m
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

#import "DCMRejectPDU.h"


@implementation DCMRejectPDU

+ (id)rejectWithData:(NSData *)data{
	return [[[DCMRejectPDU alloc] initWithData:data] autorelease];
}

+ (id)rejectWithSource:(unsigned char)aSource  reason:(unsigned char)aReason  result:(unsigned char)aResult{
	return [[[DCMRejectPDU alloc] initWithSource:(unsigned char)aSource  reason:(unsigned char)aReason  result:(unsigned char)aResult] autorelease];
}

- (id)initWithSource:(unsigned char)aSource  reason:(unsigned char)aReason  result:(unsigned char)aResult{
	if (self = [super init]){
		pduType = 0x03;
		source = aSource;
		reason = aReason;
		result = aResult;
		pduLength = 4;
		pdu = [[NSMutableData alloc] initWithLength:10];
		unsigned char *b = (unsigned char *)[pdu mutableBytes];
		
		b[0]=(unsigned char)pduType;						
		b[1]=0x00;							// reserved
		pduLength = 4;
		b[2]=0x00;					// big endian
		b[3]=0x00;
		b[4]=0x00;
		b[5]=(unsigned char)pduLength;
		b[6]=0x00;							// reserved
		b[7]=(unsigned char)result;						
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
		[pdu getBytes:&result range:NSMakeRange(7,1)];
		[pdu getBytes:&source range:NSMakeRange(8,1)];
		[pdu getBytes:&reason range:NSMakeRange(9,1)];
	}
	return self;
}

	

- (NSString *)info{
	NSMutableString *info = [NSMutableString stringWithString:@"rejected-"];
	if     (result == 1) 
		[info appendString:@"-permanent"];
	else if (result == 2) 
		[info appendString:@"-transient"];
		
	if      (source == 1) [info appendString:@" by DICOM UL Service User"];
	else if (source == 2) [info appendString:@" by DICOM UL Service Provider (ACSE related function)"];
	else if (source == 3) [info appendString:@" by DICOM UL Service Provider (Presentation related function)"];
		
	if      (source == 1) {
			if      (reason == 1) {
				[info appendString:@", no reason given"];
			}
			else if (reason == 2) {
				[info appendString:@", application context name not supported"];
			}
			else if (reason == 3) {
				[info appendString:@", calling AE Title not recognized"];
			}
			else if (reason == 7) {
				[info appendString:@", called AE Title not recognized"];
			}
		}
		else if (source == 2) {
			if      (reason == 1) {
				[info appendString:@", no reason given"];
			}
			else if (reason == 2) {
				[info appendString:@", protocol version not supported"];
			}
		}
		else if (source == 3) {
			if      (reason == 1) {
				[info appendString:@", temporary congestion"];
			}
			else if (reason == 2) {
				[info appendString:@", local limit exceeded"];
			}
		}

		
	return info;	
}

- (NSString *)description{
	return [self info];
}

@end
