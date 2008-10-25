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

#import "DCMPresentationDataValue.h"


@implementation DCMPresentationDataValue

+ (id)pdvWithParameters:(NSDictionary *)params{
	return [[[DCMPresentationDataValue alloc] initWithParameters:params] autorelease];
}

+ (id) pdvWithData:(NSData *)data offset:(int)offset  length:(int)aLength{
	return [[[DCMPresentationDataValue alloc] initWithData:(NSData *)data offset:(int)offset  length:(int)aLength] autorelease];
}

+ (id) pdvWithData:(NSData *)data {
	return [[[DCMPresentationDataValue alloc] initWithData:(NSData *)data] autorelease];
}

+ (id)pdvWithBytes:(unsigned char*)bytes  
			length:(int)length  
			isCommand:(BOOL)isCommand 
			isLastFragment:(BOOL)isLastFragment  
			contextID:(unsigned char)contextID{
	
	return [[[DCMPresentationDataValue alloc]initWithBytes:(unsigned char*)bytes  
			length:(int)length    
			isCommand:(BOOL)isCommand 
			isLastFragment:(BOOL)isLastFragment  
			contextID:(unsigned char)contextID] autorelease];
}

- (id)initWithBytes:(unsigned char *)bytes  
			length:(int)aLength
			isCommand:(BOOL)isCommand 
			isLastFragment:(BOOL)isLastFragment  
			contextID:(unsigned char)contextID{
	
	if (self = [super init]) {
		presentationContextID = contextID;
		//value = [data retain];
		value = nil;
		messageControlHeader = (unsigned char)(((isLastFragment ? 1 : 0) << 1) | (isCommand ? 1 : 0));
		pdv = [[NSMutableData alloc] init];
		//NSLog(@"PDV length:%d  isCommand:%d, isLastFragment:%d, messageControlHeader:%d", [value length], isCommand, isLastFragment, messageControlHeader);
		length = aLength + 2;
		long bigl = NSSwapHostLongToBig(length);
		[pdv appendBytes:&bigl length:4];
		[pdv appendBytes:&presentationContextID length:1];
		[pdv appendBytes:&messageControlHeader length:1];
		[pdv appendBytes:bytes length:aLength];
	}
	return self;
}

- (id)initWithParameters:(NSDictionary *)params{

	return [self initWithBytes:(unsigned char *)[[params objectForKey:@"value"] bytes]
			length:(int)[[params objectForKey:@"value"] length]
			isCommand:[[params objectForKey:@"isCommand"] boolValue]
			isLastFragment:[[params objectForKey:@"isLastFragment"] boolValue]  
			contextID:[[params objectForKey:@"contextID"] charValue]];
	/*
	if (self = [super init]) {
		presentationContextID = [[params objectForKey:@"contextID"] charValue];
		value = [[params objectForKey:@"value"] retain];
		BOOL isCommand = [[params objectForKey:@"isCommand"] boolValue];
		BOOL isLastFragment = [[params objectForKey:@"isLastFragment"] boolValue];
		
		messageControlHeader = (unsigned char)(((isLastFragment ? 1 : 0) << 1) | (isCommand ? 1 : 0));
		pdv = [[NSMutableData data] retain];
		//NSLog(@"PDV length:%d  isCommand:%d, isLastFragment:%d, messageControlHeader:%d", [value length], isCommand, isLastFragment, messageControlHeader);
		length = [value length] + 2;
		[pdv appendBytes:&length length:4];
		[pdv appendBytes:&presentationContextID length:1];
		[pdv appendBytes:&messageControlHeader length:1];
		[pdv appendData:value];
	}
	return self;
	*/
}

- (id)initWithData:(NSData *)data offset:(int)offset  length:(int)aLength{
	if (self = [super init]) {
		length = aLength;
		//NSLog(@"offset:%d  length:%d", offset, length);
		pdv = [[data subdataWithRange:NSMakeRange(offset, length + 4)] mutableCopy];
		[pdv getBytes:&presentationContextID  range:NSMakeRange(4,1)];
		[pdv getBytes:&messageControlHeader  range:NSMakeRange(5,1)];
		//NSLog(@"contextID: %d  messageControlHeader: %d", presentationContextID, messageControlHeader);
		if (length > 2) 
			value = [[data subdataWithRange:NSMakeRange(offset + 6, length - 2)] retain];
		else
			value = nil;
 
		
	}
	return self;
}

- (id)initWithData:(NSData *)data{
	if (self = [super init]) {
		length = [data length];
		pdv = [data mutableCopy];
		[pdv getBytes:&presentationContextID  range:NSMakeRange(4,1)];
		[pdv getBytes:&messageControlHeader  range:NSMakeRange(5,1)];
		//NSLog(@"presentationContextID:0x%x  messageControlHeader:0x%x", presentationContextID, messageControlHeader);
		if (length > 6) 
			value = [[data subdataWithRange:NSMakeRange(6, length - 6)] retain];
		else
			value = nil;
	} 
	return self;
	
}

- (void)dealloc{
	[pdv release];
	[value release];
	[super dealloc];
}

- (NSData *)pdv{
	return (NSData *)pdv;
}

- (NSData *)value{
	return (NSData *)value;
}

- (unsigned char)presentationContextID{
	return presentationContextID;
}

- (BOOL)isLastFragment{
//	NSLog(@"messageControlHeader:0x %x  &0x02:0x%x", messageControlHeader, messageControlHeader & 0x02);
	return (messageControlHeader & 0x02) != 0; 
}

- (BOOL) isCommand{
//	NSLog(@"messageControlHeader:0x %x  &0x01:0x%x", messageControlHeader, messageControlHeader & 0x01);
	return (messageControlHeader & 0x01) != 0;
}

@end
