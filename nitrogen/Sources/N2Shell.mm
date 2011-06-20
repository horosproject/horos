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


#import "N2Shell.h"
#include <netdb.h>
#include <arpa/inet.h>


@implementation N2Shell

+(NSString*)execute:(NSString*)path {
	return [N2Shell execute:path arguments:NULL];
}

+(NSString*)execute:(NSString*)path arguments:(NSArray*)arguments {
	return [N2Shell execute:path arguments:arguments expectedStatus:0];
}

+(NSString*)execute:(NSString*)path arguments:(NSArray*)arguments outStatus:(int*)outStatus {
	if (!arguments) arguments = [NSArray array];
	
//	int r = random();
//	NSLog(@"%d [N2Shell execute:] %@ %@", r, path, [arguments componentsJoinedByString:@" "]);
	
	NSTask* task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:path];
	[task setArguments:arguments];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError:[NSPipe pipe]];
	
	[task launch];
	[task waitUntilExit];
	
	NSString* stdout = [[[[NSString alloc] initWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//	NSString* stderr = [[[[NSString alloc] initWithData:[[[task standardError] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
//	
//	NSLog(@"%d STDOUT:\n\n%@\n\n", r, stdout);
//	NSLog(@"%d STDERR:\n\n%@\n\n", r, stderr);
	
	if (outStatus)
		*outStatus = [task terminationStatus];
	
	return stdout;
}

+(NSString*)execute:(NSString*)path arguments:(NSArray*)arguments expectedStatus:(int)expectedStatus {
	int status;
	NSString* r = [self execute:path arguments:arguments outStatus:&status];
	
	if (status != expectedStatus)
		[NSException raise:NSGenericException format:@"Task %@ exited with status %d", path, status];
	
	return r;
}

+(NSString*)hostname {
	char hostname[128];
	gethostname(hostname, 127);
	hostname[127] = 0;
	return [NSString stringWithCString:hostname encoding:NSUTF8StringEncoding];
}

+(NSString*)ip {
	char hostname[128];
	gethostname(hostname, 127);
	hostname[127] = 0;
	
	struct hostent* he = gethostbyname(hostname);
	return [NSString stringWithCString: he? (char*)inet_ntoa(*((struct in_addr*)he->h_addr)) : hostname encoding:NSUTF8StringEncoding];
}

+(NSString*)hostnameAwareOfSlowness:(BOOL)aware {
	if (!aware) NSLog( @"****** WARNING [[NSHost currentHost] name] can be VERY slow on some network configurations/settings - AVOID TO CALL THIS FUNCTION.");
	NSString* host = [[NSHost currentHost] name];
	NSRange r = [host rangeOfString:@"."];
	host = r.location!=NSNotFound? [host substringToIndex:r.location] : host;
	return host;
	// [N2Shell execute:@"/bin/hostname" arguments:[NSArray arrayWithObject:@"-s"]];
}

+(NSString*)mac {
	NSString* temp = [N2Shell execute:@"/usr/sbin/ipconfig" arguments:[NSArray arrayWithObjects:@"getpacket", @"en0", NULL] outStatus:NULL];
	NSArray* lines = [temp componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	const NSString* const chaddrPrefix = @"chaddr = ";
	for (NSString* line in lines) {
		if ([line hasPrefix:chaddrPrefix]) {
			NSMutableArray* pieces = [[[[line substringFromIndex:[chaddrPrefix length]] componentsSeparatedByString:@":"] mutableCopy] autorelease];
			for (NSUInteger i = 0; i < [pieces count]; ++i)
				if ([[pieces objectAtIndex:i] length] < 2)
					[pieces replaceObjectAtIndex:i withObject:[NSString stringWithFormat:@"0%@", [pieces objectAtIndex:i]]];
			return [pieces componentsJoinedByString:@":"];
		}
	}
	
	return @"00:00:00:00:00:00";
}

+(int)userId {
	return [[N2Shell execute:@"/usr/bin/id" arguments:[NSArray arrayWithObject:@"-u"]] intValue];
}

@end
