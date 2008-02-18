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


/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMPDataPDU.h"
#import "DCMPresentationDataValue.h"

@implementation DCMPDataPDU

@synthesize pdvList;

+ (id)pDataPDUWithPDVs:(NSMutableArray *)pdvs{
	return [[[DCMPDataPDU alloc] initPDVs:pdvs] autorelease];
}

+ (id)pDataPDUWithData:(NSData *)data{
	return [[[DCMPDataPDU alloc] initWithData:(NSData *)data] autorelease];
}

- (id)initPDVs:(NSMutableArray *)pdvs{
	unsigned char zero = 0x00;
	if (self = [super init]) {
		pduType = 0x04;
		pdvList = [pdvs retain];
		pdu = [[NSMutableData data] retain];
		[pdu appendBytes:&pduType length:1];
		[pdu appendBytes:&zero  length:1];
		[pdu appendBytes:&zero  length:1];
		[pdu appendBytes:&zero  length:1];
		[pdu appendBytes:&zero  length:1];
		[pdu appendBytes:&zero  length:1];
		for (DCMPresentationDataValue *pdv in pdvList ) {
			[pdu appendData:[pdv pdv]];
		}
		pduLength = NSSwapHostIntToBig([pdu length] - 6);
		//length is big endian int
		[pdu replaceBytesInRange:NSMakeRange(2,4) withBytes:&pduLength];
	}
	return self;
}

- (id)initWithData:(NSData *)data{
	if (self = [super init]){
		pdvList = [[NSMutableArray array] retain];
		pdu = [data retain];
		[pdu getBytes:&pduType range:NSMakeRange(0,1)];
		//NSLog(@"pduType:%d", pduType);
		[pdu getBytes:&pduLength range:NSMakeRange(2,4)];
		pduLength = NSSwapBigIntToHost(pduLength);
		//NSLog(@"pduLength:%d", pduLength);
		int offset = 6;
		//int offset = 0;
		while (offset < [pdu length]){
			int pdvLength;
			[pdu getBytes:&pdvLength  range:NSMakeRange(offset,4)];
			pdvLength = NSSwapBigIntToHost(pdvLength);
			if (pdvLength > 0) {
				//NSLog(@"Add pdv length:%d offset:%d, data length:%d", pdvLength, offset, [data length]);
				[pdvList addObject:[DCMPresentationDataValue pdvWithData:[data subdataWithRange:NSMakeRange(offset, pdvLength + 4)]]];
			}
			offset += pdvLength + 4;
		}
		
	}
	return self;
}

- (void)dealloc{
	[pdvList release];
	[super dealloc];
}

- (BOOL)containsLastCommandFragment{
	BOOL found = NO;
	if ([pdvList count] > 0){
		NSEnumerator *enumerator = [pdvList objectEnumerator];
		DCMPresentationDataValue *pdv;
		for ( DCMPresentationDataValue *pdv in pdvList ) {
			if ([pdv isLastFragment] && [pdv isCommand]) {
				found = YES;
				break;
			}
		}
	}
	return found;
}

- (BOOL)containsLastDataFragment{
	BOOL found = NO;
	if ([pdvList count] > 0){
		for ( DCMPresentationDataValue *pdv in pdvList ) {
			if ([pdv isLastFragment] && ![pdv isCommand]) {
				found = YES;
				break;
			}
		}
	}
	return found;
}

@end
