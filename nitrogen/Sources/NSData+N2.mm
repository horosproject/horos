/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "NSData+N2.h"
#include <CommonCrypto/CommonDigest.h>

char hexchar2dec(char hex) {
	if (hex >= '0' && hex <= '9')
		return hex-'0';
	if (hex >= 'A' && hex <= 'F')
		return hex-'A'+10;
	if (hex >= 'a' && hex <= 'f')
		return hex-'a'+10;
	return -1;
}

char hex2char(const char* hex) {
	return (hexchar2dec(hex[0])<<4)+hexchar2dec(hex[1]);
}


@implementation NSData (N2)

+(NSData*)dataWithHex:(NSString*)hex {
	if (!hex) return NULL;
	return [[[NSData alloc] initWithHex:hex] autorelease];
}

-(NSData*)initWithHex:(NSString*)hex {
	NSUInteger length = [hex length]/2;
	char* buffer = (char*)malloc(length);
	const char* utf8 = [hex UTF8String];
	
	//#pragma omp parallel for
	for (int i = 0; i < (int)length; ++i)
		buffer[i] = hex2char(&utf8[i*2]);
	
	return [self initWithBytesNoCopy:buffer length:length];
}

// base64 code from http://www.cocoadev.com/index.pl?BaseSixtyFour by MiloBird

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

+(NSData*)dataWithBase64:(NSString*)base64 {
	if (!base64) return NULL;
	return [[[NSData alloc] initWithBase64:base64] autorelease];
}

-(NSData*)initWithBase64:(NSString*)base64 {
	if ([base64 length] == 0)
		return [[NSData data] retain];
	
	static char *decodingTable = NULL;
	if (decodingTable == NULL)
	{
		decodingTable = (char*)malloc(256);
		if (decodingTable == NULL)
			return nil;
		memset(decodingTable, CHAR_MAX, 256);
		NSUInteger i;
		for (i = 0; i < 64; i++)
			decodingTable[(short)base64EncodingTable[i]] = i;
	}
	
	const char *characters = [base64 cStringUsingEncoding:NSASCIIStringEncoding];
	if (characters == NULL)     //  Not an ASCII string!
		return nil;
	char *bytes = (char*)malloc((([base64 length] + 3) / 4) * 3);
	if (bytes == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (YES)
	{
		char buffer[4];
		short bufferLength;
		for (bufferLength = 0; bufferLength < 4; i++)
		{
			if (characters[i] == '\0')
				break;
			if (isspace(characters[i]) || characters[i] == '=')
				continue;
			buffer[bufferLength] = decodingTable[(short)characters[i]];
			if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
			{
				free(bytes);
				return nil;
			}
		}
		
		if (bufferLength == 0)
			break;
		if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
		{
			free(bytes);
			return nil;
		}
		
		//  Decode the characters in the buffer to bytes.
		bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
		if (bufferLength > 2)
			bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
		if (bufferLength > 3)
			bytes[length++] = (buffer[2] << 6) | buffer[3];
	}
	
	realloc(bytes, length);
	return [self initWithBytesNoCopy:bytes length:length];
}

-(NSString*)base64 {
	if ([self length] == 0)
		return @"";
	
    char *characters = (char*)malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';	
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];	
}

-(NSString*)hex {
	NSMutableString* stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
	const unsigned char* dataBuffer = (unsigned char*)[self bytes];
	for (int i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02X", (unsigned int) dataBuffer[i]];
	return [[stringBuffer copy] autorelease];
}

-(NSData*)md5 {
    NSMutableData* hash = [NSMutableData dataWithLength:16];
    CC_MD5(self.bytes, self.length, (unsigned char*)hash.mutableBytes);
    return hash;
} 


@end
