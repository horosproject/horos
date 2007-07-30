//
//  DCMReleasePDU.m
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


#import "DCMReleasePDU.h"


@implementation DCMReleasePDU

+ (id)releasePDUWithType:(unsigned char)type{
	return [[[DCMReleasePDU alloc] initWithType:type] autorelease];
}

- (id)initWithType:(unsigned char)type{
	if (self = [super init]){
		// 0x05 for -RQ, 0x06 for -RP
		pduType = type;
		pduLength = 4;
		pdu = [[NSMutableData alloc] initWithLength:10];
		unsigned char *b = (unsigned char *)[pdu mutableBytes];
		
				// encode fixed length part ...

		b[0]=(unsigned char)pduType;						// A-RELEASE-xx PDU Type
		b[1]=0x00;							// reserved
		pduLength = 4;
		b[2]=(unsigned char)(pduLength>>24);					// big endian
		b[3]=(unsigned char)(pduLength>>16);
		b[4]=(unsigned char)(pduLength>>8);
		b[5]=(unsigned char)pduLength;
		b[6]=0x00;							// reserved
		b[7]=0x00;							// reserved
		b[8]=0x00;							// reserved
		b[9]=0x00;							// reserved
	}
	return self; 
}

- (id)initWithData:(NSMutableData *)data{
	if (self = [super init]) {
		pdu = [data retain];
		[pduType getBytes:&pduType range:NSMakeRange(0,1)];
		[pdu getBytes:&pduLength range:NSMakeRange(2,4)];
		pduLength = NSSwapBigIntToHost(pduLength);
	}
	return self;
	
}


- (NSString *)info{
	NSMutableString *info = [NSMutableString stringWithFormat:@"PDU Type: 0x%X", pduType];
	if (pduType == 0x05 )
		[info appendString:@" (A-RELEASE-RQ)"];
	else if (pduType == 0x06)
		[info appendString:@" (A-RELEASE-RP)"];
	else
		[info appendString:@" unrecognized"];
	
	
			
	return info;	
}

	

@end
