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


#import "NSURL+N2.h"


@implementation N2URLParts
@synthesize protocol = _protocol, address = _address, port = _port, path = _path, params = _params;

-(NSString*)pathAndParams {
	return [NSString stringWithFormat:@"%@%@", _path, _params? _params : @""];
}

@end


@implementation NSURL (N2)

-(N2URLParts*)parts {
	N2URLParts* parts = [[N2URLParts alloc] init];
	
	NSString* url = [self absoluteString];
	NSInteger l = 0, length = [url length];
	
	NSRange range = [url rangeOfString:@"://" options:NSLiteralSearch range:NSMakeRange(l,length-l)];

	if (range.location != NSNotFound) {
		[parts setProtocol:[url substringWithRange:NSMakeRange(l,range.location-l)]];
		l = range.location+range.length;
	}
	
	while (l < length && [url characterAtIndex:l] == '/') ++l;
	
	range = [url rangeOfString:@"/" options:NSLiteralSearch range:NSMakeRange(l,length-l)];
	if (range.location == NSNotFound)
		range = NSMakeRange(length,0);
	
	NSString* addressAndPort = [url substringWithRange:NSMakeRange(l,range.location-l)];
	l = range.location;
	
	range = [addressAndPort rangeOfString:@":" options:NSLiteralSearch];
	if (range.location == NSNotFound)
		[parts setAddress:addressAndPort];
	else {
		[parts setAddress:[addressAndPort substringToIndex:range.location]];
		[parts setPort:[addressAndPort substringFromIndex:range.location+1]];
	}
	
	if (l < length) {
		range = [url rangeOfString:@"?" options:NSLiteralSearch range:NSMakeRange(l,length-l)];
		if (range.location == NSNotFound)
			[parts setPath:[url substringFromIndex:l]];
		else {
			[parts setPath:[url substringWithRange:NSMakeRange(l,range.location-l)]];
			[parts setParams:[url substringFromIndex:range.location+1]];
		}
	}
	
	return [parts autorelease];
}

+(NSURL*)URLWithParts:(N2URLParts*)parts {
	NSMutableString* url = [NSMutableString stringWithCapacity:512];
	
	if ([parts protocol]) [url appendString:[parts protocol]];
	[url appendString:@"://"];
	if ([parts address]) [url appendString:[parts address]];
	if ([parts port]) [url appendFormat:@":%@", [parts port]];
	if ([parts path]) [url appendString:[parts path]];
	if ([parts params]) [url appendFormat:@"?%@", [parts params]];
	
	return [NSURL URLWithString:url];
}

@end
