//
//  DCMAcceptRequestPDU.m
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


#import "DCMAcceptRequestPDU.h"
#import "DCMPresentationContext.h"
#import "DCMPresentationContextItem.h"
#import "DCMSOPClassExtendedNegotiationUserInformationSubItem.h"
#import "DCMImplementationVersionNameUserInformationSubItem.h"
#import "DCMImplementationClassUIDUserInformationSubItem.h"
#import "DCMMaximumLengthReceivedUserInformationSubItem.h"
#import "DCMUserInformationSubItem.h"
#import "DCMUserInformationItem.h"
#import "DCMApplicationContextItem.h"
#import "DCMAssociationItem.h"
#import "DCMTransferSyntax.h"

static unsigned char zero = 0x00;
static unsigned char one = 0x01;
static unsigned short four = 0x0004;
static unsigned char ten = 0x10;
static unsigned char fifty = 0x50;
static unsigned char fiftyone = 0x51;
static unsigned char fiftytwo = 0x52;
static unsigned char fiftyfive = 0x55;

@implementation DCMAcceptRequestPDU

@synthesize calledAET, callingAET, maximumLengthReceived;

- (id)initWithParameters:(NSDictionary *)params{
	if (self = [super init]) {
	 /********************
		PDU bytes
	0		PDU Type
	1		0x00 reserved
	2-5		PDU length big endian int
	6-7		Protocol version unsigned short big endian
	8		0x00	reserved
	9		0x00 reserved
	10-25	Called AE Title 16 byte string
	26-41	Calling AE Title 16 byte string
	42-73	Reserved 0x00 
	74-xx	variable portion
	*************************/

		calledAET = [[params objectForKey:@"calledAET"] retain];
		callingAET = [[params objectForKey:@"callingAET"] retain];
		implementationClassUID = [[params objectForKey:@"implementationClassUID"] retain];
		implementationVersionName = [[params objectForKey:@"implementationVersionName"] retain];
		maximumLengthReceived = [[params objectForKey:@"ourMaximumLengthReceived"] intValue];	//the maximum PDU length that we will offer to receive
		presentationContexts = [[params objectForKey:@"presentationContexts"] retain];
		pduType = [[params objectForKey:@"pduType"] charValue];
		pdu = [[NSMutableData data] retain];
		
		[pdu appendBytes:&pduType length:1]; // 0 A-ASSOC-RQ PDU Type
		[pdu appendBytes:&zero length:1];	// 1 reserved
		[pdu appendBytes:&zero length:1];	//2-5 length
		[pdu appendBytes:&zero length:1]; 
		[pdu appendBytes:&zero length:1]; 
		[pdu appendBytes:&zero length:1];  // will fill in length here later
		[pdu appendBytes:&zero length:1]; 
		[pdu appendBytes:&one  length:1]; 	// protocol version 1 (big endian)
		[pdu appendBytes:&zero length:1]; 
		[pdu appendBytes:&zero length:1];	// reserved
		
		[pdu appendData:[self dataForAET:calledAET withName:@"Called"]];
		[pdu appendData:[self dataForAET:callingAET withName:@"Calling"]];
		[pdu appendData:[NSMutableData dataWithLength:32]];
			
		// encode variable length part ...
		itemList = [[NSMutableArray array] retain];
		
		// one Application Context Item ...
		
		[pdu appendBytes:&ten length:1];		// Application Context Item Type
		[pdu appendBytes:&zero length:1];		// reserved
		NSString *applicationContextNameUID = @"1.2.840.10008.3.1.1.1";
		NSData *acn = [applicationContextNameUID dataUsingEncoding:NSASCIIStringEncoding];
		unsigned short lacn = [acn length];
		//const char *acn = [applicationContextNameUID cString];
		//unsigned short lacn = [applicationContextNameUID length];
		
		unsigned short	bigs = NSSwapHostShortToBig(lacn);
		[pdu appendBytes:&bigs length:2];		// length (short big endian)
		[pdu appendData:acn];		
		
		DCMApplicationContextItem *applicationContextItem = [DCMApplicationContextItem applicationContextItemWithType:0x10 length:lacn  name:applicationContextNameUID];
		[itemList addObject:applicationContextItem];
		
		// one or more Presentation Context Items ...

		for ( DCMPresentationContext *pc in presentationContexts ) {
			unsigned char itemType = (pduType == 0x01 ? 0x20 : 0x21);
			NSMutableData *pcData = [self dataForPresentationContext:pc ofType:itemType];
			[pdu appendData:pcData];	
			
			DCMPresentationContextItem *presentationContextItem = [DCMPresentationContextItem presentationContextItemWithType:itemType length:[pcData length] presentationContext:pc];
			[itemList addObject:presentationContextItem];			
		}
		
		// one User Information Item ...
		//const char *icuid = [implementationClassUID UTF8String];
		NSData *icuid = [implementationClassUID  dataUsingEncoding:NSASCIIStringEncoding];
		unsigned short licuid = [icuid length];
		//const char *ivn = [implementationVersionName UTF8String];
		NSData *ivn = [implementationVersionName dataUsingEncoding:NSASCIIStringEncoding];
		unsigned short livn = [ivn length];
		
		// User Information Item Type
		[pdu appendBytes:&fifty length:1];	
		[pdu appendBytes:&zero  length:1];	//reserved
		unsigned short luii = 8 + 4 +licuid + 4 + livn; //max length subitem length  + class UID sub itme length + version Name subItme length
		bigs = NSSwapHostShortToBig(luii);
		[pdu appendBytes:&bigs length:2];
		
		
			// Maximum Length Received User Information Sub Item  Type
			[pdu appendBytes:&fiftyone length:1];	
			[pdu appendBytes:&zero  length:1];	//reserved
			//[pdu appendBytes:&zero  length:1];
			bigs = NSSwapHostShortToBig(four);
			[pdu appendBytes:&bigs  length:2]; // 2-byte (short big endian) sub-item length is fixed at 4
			long bigl = NSSwapHostLongToBig(maximumLengthReceived);
			[pdu appendBytes:&bigl length:4]; // big-endian ourMaximumLengthReceived is 4 byte value
			
			// Implementation Class UID User Information Sub Item Type length 4 + licuid
			[pdu appendBytes:&fiftytwo length:1]; 
			[pdu appendBytes:&zero  length:1]; //reserved
			unsigned short blicuid = NSSwapHostShortToBig(licuid);
			[pdu appendBytes:&blicuid length:2]; // length (big endian)
			//[pdu appendBytes:icuid length:licuid];
			[pdu appendData:icuid];
			

			// Implementation Class UID User Information Sub Item Type
			[pdu appendBytes:&fiftyfive length:1]; 
			[pdu appendBytes:&zero  length:1]; //reserved
			unsigned short blivn = NSSwapHostShortToBig(livn);
			[pdu appendBytes:&blivn length:2]; // length (short big endian)
			//[pdu appendBytes:ivn length:livn];
			[pdu appendData:ivn];
			
		
		DCMUserInformationItem *userInformationItem = [DCMUserInformationItem userInformationItemWithType:fifty length:luii];
		[itemList addObject:userInformationItem];
		
		DCMMaximumLengthReceivedUserInformationSubItem *maxLengthInfoSubItem = [DCMMaximumLengthReceivedUserInformationSubItem maximumLengthReceivedUserInformationSubItemWithType:fiftyone length:4  maxLengthReceived:maximumLengthReceived];
		[itemList addObject:maxLengthInfoSubItem];
		
		DCMImplementationClassUIDUserInformationSubItem *icuiduisi = [DCMImplementationClassUIDUserInformationSubItem implementationClassUIDUserInformationSubItemWithType:fiftytwo length:licuid implementationClassUID:implementationClassUID];
		[itemList addObject:icuiduisi];
		
		DCMImplementationVersionNameUserInformationSubItem *ivnuisi = [DCMImplementationVersionNameUserInformationSubItem implementationVersionNameUserInformationSubItemWithType:fiftyfive length:livn implementationVersionName:implementationVersionName];
		[itemList addObject:ivnuisi];
		
		// compute size and fill in length field ...
		pduLength = NSSwapHostIntToBig([pdu length] - 6);
		[pdu replaceBytesInRange:NSMakeRange(2, 4) withBytes:&pduLength];
		//NSLog(@"PDU Length: %d", pduLength);
		

	}
	return self;
}

- (id)initWithData:(NSMutableData *)data{
	if (self = [super init]) {
		BOOL debug = 0;
		pdu = [data retain];
		[pdu getBytes:&pduType range:NSMakeRange(0,1)];
		if (debug)
			NSLog(@"pduType: %d", pduType);
			
		[pdu getBytes:&pduLength range:NSMakeRange(2,4)];
		pduLength = NSSwapBigIntToHost(pduLength);
		if (debug)
			NSLog(@"pduType: %d", pduLength);
			
		[pdu getBytes:&protocolVersion range:NSMakeRange(6,2)];
		protocolVersion = NSSwapBigShortToHost(protocolVersion);
		if (debug)
			NSLog(@"protocol version: %d", protocolVersion);
			
		NSData *calledAETitle = [pdu subdataWithRange:NSMakeRange(10,16)];
		NSData *callingAETitle =   [pdu subdataWithRange:NSMakeRange(26,16)];
		NSString *calledAet = [[[NSString alloc] initWithData:calledAETitle encoding:NSASCIIStringEncoding] autorelease];
		calledAET = [[calledAet stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
		if (debug)
			NSLog(@"called AET: %@", calledAET);
		NSString *callingAet = [[[NSString alloc] initWithData:callingAETitle encoding:NSASCIIStringEncoding] autorelease];
		callingAET = [[callingAet stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
		if (debug)
			NSLog(@"calling AET: %@", callingAET);
		itemList = [[NSMutableArray array] retain];
		int offset = 74;
		while (offset + 3 < [pdu length]) {
			//if (debug)
			//	NSLog(@"Parsing PDU offset:%d pdu Length: %d", offset, [pdu length]);
			unsigned char itemType;
			[pdu getBytes:&itemType range:NSMakeRange(offset++,1)];
			//	if (debug)
			//		NSLog(@"item type: 0x%x", itemType);
			offset++; //reserved
			unsigned short length;
			[pdu getBytes:&length range:NSMakeRange(offset,2)];
			length = NSSwapBigShortToHost(length);
			offset += 2;
			if (itemType == 0x10) {
				NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset,length)];
				NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
				NSString *name = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				offset += length;
				DCMApplicationContextItem *item = [DCMApplicationContextItem applicationContextItemWithType:itemType length:length  name:name];
				[itemList addObject:item];
			}
			else if (itemType == 0x20 || itemType == 0x21) {		// Presentation Context Item (request or accept)
				unsigned char contextID;
				[pdu getBytes:&contextID range:NSMakeRange(offset++,1)];
				offset++; //reserved
				length -= 2; // ID and 1 reserved bytes
				
				unsigned char resultReason;
				[pdu getBytes:&resultReason range:NSMakeRange(offset++,1)];
				offset++;
				length -= 2; // result/reason and 1 reserved bytes
				
				DCMPresentationContextItem *item = [DCMPresentationContextItem presentationContextItemWithType:itemType length:length contextID:contextID  reason:resultReason];
				[itemList addObject:item];
				DCMPresentationContext *context = [item context];
				while (length > 0) {
					unsigned char subItemType;
					[pdu getBytes:&subItemType range:NSMakeRange(offset++,1)];
					length--;
					
					offset++; //reserved
					length--;
					
					unsigned short subItemLength;
					[pdu getBytes:&subItemLength range:NSMakeRange(offset,2)];
					subItemLength = NSSwapBigShortToHost(subItemLength);
					offset += 2;
					length -= 2;
					
					if (subItemType == 0x30) { //abstract Syntax UID
						NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset, subItemLength)];
						NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
						NSString *abstractSyntax = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						//if (debug)
						//	NSLog(@"Abstract Syntax:%@", abstractSyntax);
						[context setAbstractSyntax:abstractSyntax];
					}
					else if (subItemType == 0x40) { // transfer syntax UID
						NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset, subItemLength)];
						NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
						NSString *ts = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						DCMTransferSyntax *syntax = [[[DCMTransferSyntax alloc] initWithTS:ts] autorelease];
						//if (debug)
						//	NSLog(@"Transfer Syntax:%@", [syntax description]);
						[context addTransferSyntax:syntax];	
					}
					else
						NSLog(@"Unknown subitem type: 0x%x in Presentation Context Item", subItemType);
					offset+= subItemLength; length-= subItemLength;
				} //while
			}  //sub item
			else if (itemType == 0x50) {		// User Information Item
				DCMUserInformationItem *item = [DCMUserInformationItem userInformationItemWithType:itemType length:length];
				[itemList addObject:item];
				while (length > 0) {
					unsigned char subItemType;
					[pdu getBytes:&subItemType range:NSMakeRange(offset++,1)];
					length--;
					
					//reserved
					offset++;
					length--;
					
					unsigned short subItemLength;
					[pdu getBytes:&subItemLength range:NSMakeRange(offset,2)];
					subItemLength = NSSwapBigShortToHost(subItemLength);
					offset += 2;
					length -= 2;
					
					if (subItemType == 0x51){
						if (subItemLength == 4) {
							[pdu getBytes:&maximumLengthReceived range:NSMakeRange(offset,4)];
							maximumLengthReceived = NSSwapBigIntToHost(maximumLengthReceived);
						}	
						else
							NSLog(@"Maximum length sub-item wrong length: %d", subItemLength);
						DCMMaximumLengthReceivedUserInformationSubItem *subItem = [DCMMaximumLengthReceivedUserInformationSubItem maximumLengthReceivedUserInformationSubItemWithType:subItemType length:subItemLength  maxLengthReceived:maximumLengthReceived];
						[item addSubItem:subItem];
					}
					else if (subItemType == 0x52) {
						//char *string = nil;
						//[pdu getBytes:string range:NSMakeRange(offset,subItemLength)];
						NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset,subItemLength)];
						NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
						NSString *implementationClass = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
						DCMImplementationClassUIDUserInformationSubItem *subItem = [DCMImplementationClassUIDUserInformationSubItem implementationClassUIDUserInformationSubItemWithType:subItemType length:subItemLength implementationClassUID:implementationClass];
						[item addSubItem:subItem];												
					}
					else if (subItemType == 0x55) {		
						//char *string = nil;
						//[pdu getBytes:string range:NSMakeRange(offset,subItemLength)];
						//NSString *implementationVersion = [NSString stringWithUTF8String:string];
						NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset,subItemLength)];
						NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
						NSString *implementationVersion = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

						DCMImplementationVersionNameUserInformationSubItem *subItem = [DCMImplementationVersionNameUserInformationSubItem implementationVersionNameUserInformationSubItemWithType:subItemType length:subItemLength implementationVersionName:implementationVersion];
						[item addSubItem:subItem];					
					}
					else if (subItemType == 0x56) {
						unsigned short sopClassUIDLength;
						[pdu getBytes:&sopClassUIDLength range:NSMakeRange(offset,2)];
						sopClassUIDLength = NSSwapBigShortToHost(sopClassUIDLength);
						//char *string = nil;
						//[pdu getBytes:string range:NSMakeRange(offset + 2, sopClassUIDLength)];
						//NSString *sopClassUID = [NSString stringWithUTF8String:string];
						NSData *stringData = [pdu subdataWithRange:NSMakeRange(offset + 2,sopClassUIDLength)];
						NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSASCIIStringEncoding] autorelease];				
						NSString *sopClassUID = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

						NSData *data = [pdu subdataWithRange:NSMakeRange(offset+2+sopClassUIDLength, subItemLength - 2 - sopClassUIDLength)];
						DCMSOPClassExtendedNegotiationUserInformationSubItem *subItem = [DCMSOPClassExtendedNegotiationUserInformationSubItem sopClassExtendedNegotiationUserInformationSubItemWithType:subItemType length:subItemLength  sopClassLength:sopClassUIDLength  sopClassUID:sopClassUID  info:data];
						[item addSubItem:subItem];	
					}
					else{
						NSLog(@"Unknown subitem type 0x%x  for User Info", subItemType);
						
					}
					offset += subItemLength;
					length -= subItemLength;
				} //while
				
			} //sub item
			else {
				offset += length;
				NSLog(@"Unknown Item");
			}
		//NSLog(@"done Parsing PDU: %@", [self description]);		
		}
	}
	return self;
}

- (void)dealloc{
	[itemList release];
	[calledAET release];
	[callingAET release];
	[implementationClassUID release];
	[implementationVersionName release];
	[presentationContexts release];
	[super dealloc];
}

- (NSMutableData *)dataForAET:(NSString *)aet withName:(NSString *)name{
//- (void)writeAET:(NSString *)aet withName:(NSString *)name toData:(NSMutableData *)buffer atIndex:(int)index length:(int *)rangeLength{
	NSMutableData *buffer = [NSMutableData dataWithLength:16];
	const char *string = [aet UTF8String];
	//NSData *string = [aet dataUsingEncoding:NSASCIIStringEncoding];
	int rangeLength = [aet length];
	if (rangeLength > 16) {
		string = [[aet substringToIndex:16] UTF8String];
		rangeLength = 16;
	}
	[buffer replaceBytesInRange:NSMakeRange(0, rangeLength) withBytes:string];
	int index = rangeLength;
	unsigned char twenty = 0x20;
	while (index < 16)
		[buffer replaceBytesInRange:NSMakeRange(index++, 1) withBytes:&twenty];
	return buffer;
}


- (NSMutableData *)dataForSyntaxSubItem:(unsigned char)subItemType  name:(NSString *)name{
	NSMutableData *buffer = [NSMutableData data];
	[buffer appendBytes:&subItemType length:1];
	[buffer appendBytes:&zero length:1];	
	NSData *string = [name dataUsingEncoding:NSASCIIStringEncoding];
	unsigned short length = NSSwapHostShortToBig([string length]);
	[buffer appendBytes:&length length:2];
	[buffer appendData:string];
	
	return buffer;
}

- (NSMutableData *)dataForPresentationContext:(DCMPresentationContext *)context ofType:(unsigned char)type  {

	/***************
	byte structure
	0	0x21 or 0x21		itemType
	1	0x00				reserved
	2-3	item length big endian short
	4	Presentation Context ID
	5	0x00				reserved
	6	0x00				reserved
	7	0x00				reserved
	8-x	Abstract/TransferSyntax subitems
	
	
	
	***************/
	
	NSMutableData *buffer = [NSMutableData data];
	[buffer appendBytes:&type length: 1];	// 0 type
	[buffer appendBytes:&zero length: 1];	// 1 reserved
	[buffer appendBytes:&zero length: 1];	
	[buffer appendBytes:&zero length: 1];	// 2-3 will fill in length here later
	unsigned char contextID = [context contextID];
	[buffer appendBytes:&contextID length:1];	// 4 Presentation Context ID
	//bo.write(pc.getIdentifier()&0xff);	java mathod for context ID			
	[buffer appendBytes:&zero length: 1];	//  5 reserved
	// 6 Result/reason only for accept, else reserved
	if (type == 0x20)
		[buffer appendBytes:&zero length: 1];
	else {
		unsigned char reason = [context reason];
		[buffer appendBytes:&reason length:1];
	}
	[buffer appendBytes:&zero length: 1]; // 7 reserved
	
	//variable portion
	NSString *abstractSyntaxUID = [context abstractSyntax];
	// Acceptance PDU has no Abstract Syntax sub-item
	if (abstractSyntaxUID  && [abstractSyntaxUID length] > 0) {
		[buffer appendData:[self dataForSyntaxSubItem:0x30 name:abstractSyntaxUID]];
		//NSLog(@"Abstract Syntax: %@", 	abstractSyntaxUID);
	}

	for ( DCMTransferSyntax *syntax in [context transferSyntaxes] ) {
		[buffer appendData:[self dataForSyntaxSubItem:0x40 name:[syntax transferSyntax]]];
		
	}
	// compute size and fill in length field ...
	unsigned short  n = [buffer length] - 4;
	n = NSSwapHostShortToBig(n);
	[buffer replaceBytesInRange:NSMakeRange(2, 2) withBytes:&n];
	//NSLog(@"data for Presentation Context id:%d  length:%d, ", contextID, n);
	return buffer;
	
}

-(NSArray *)acceptedPresentationContextsWithAbstractSyntaxIncludedFromRequest:(NSArray *)request{
	NSMutableArray *contexts = [NSMutableArray array];
	for ( DCMAssociationItem *item in itemList ){
		if ([item type] == 0x21) {	// Presentation Context Item (accept)
			DCMPresentationContext *context = [(DCMPresentationContextItem *)item context];
			if ([context reason] == 0) {	//acceptance not rejection
				unsigned char contextID = [context contextID];
				NSString *abstractSyntaxUID = nil;
				for ( DCMPresentationContext *requestContext in request ) {
					if ([requestContext contextID] == contextID) {
						abstractSyntaxUID = [requestContext abstractSyntax];
						break;
					}
				}
				if (abstractSyntaxUID == nil) 
					NSLog(@"Accepted Presentation Context ID 0x%x was not requested", contextID);
				else {
					DCMPresentationContext *newContext = [[[DCMPresentationContext alloc] initWithID:contextID] autorelease];
					[newContext setAbstractSyntax:abstractSyntaxUID];
					[newContext addTransferSyntax:[[context transferSyntaxes] objectAtIndex:0]];
					[contexts addObject:newContext];
				}
				
			}
		}
	}

	return contexts;
}

- (NSArray *)requestedPresentationContexts{
	NSMutableArray *contexts = [NSMutableArray array];
	for ( DCMAssociationItem *item in itemList ) {
		if ([item type] == 0x20)  {		// Presentation Context Item (request)
			DCMPresentationContext *context = [(DCMPresentationContextItem *)item context];
			[contexts addObject:context];
		}
	}		
	return contexts;
}

- (NSString *)description{
	NSMutableString *string =[NSMutableString stringWithFormat:@"calledAET:%@\ncallingAET:%@\nimplementationClassUID:%@\nimplementationVersionName:%@\n", calledAET, callingAET, implementationClassUID, implementationVersionName];
	if (presentationContexts)
		[string appendString:[presentationContexts description]];

	return string;
}
	
@end
