/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/


#import "N2Shell.h"
#import <IOKit/IOTypes.h>
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
	while( [task isRunning])
        [NSThread sleepForTimeInterval: 0.1];
    
    //[aTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
	
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
	
	NSString* chaddrPrefix = @"chaddr = ";
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
	
	/*
	 
	 NSString* str = @"00:00:00:00:00:00";
	 
	 CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
	 if (matchingDict) {
	 CFMutableDictionaryRef propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	 if (propertyMatchDict) {
	 CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue); 
	 CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
	 NSLog(@"R1");
	 CFRelease(propertyMatchDict);
	 }
	 
	 io_iterator_t matchingServices;
	 if (IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) == KERN_SUCCESS) {
	 io_object_t intfService;
	 while (intfService = IOIteratorNext(matchingServices)) {
	 io_object_t controllerService;
	 if (IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService)) {
	 CFTypeRef MACAddressAsCFData = IORegistryEntryCreateCFProperty(controllerService, CFSTR(kIOMACAddress), kCFAllocatorDefault, 0);
	 if (MACAddressAsCFData) {
	 const uint8* p = CFDataGetBytePtr((CFDataRef)MACAddressAsCFData);
	 str = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", p[0], p[1], p[2], p[3], p[4], p[5]];
	 NSLog(@"R2");
	 CFRelease(MACAddressAsCFData);
	 }
	 
	 NSLog(@"R3");
	 IOObjectRelease(controllerService);
	 }
	 }
	 
	 NSLog(@"R4");
	 IOObjectRelease(matchingServices);
	 }
	 
	 NSLog(@"R5");
	 CFRelease(matchingDict);
	 }
	 
	 NSLog(@"MAC Addr is %@", str);
	 
	 return str;
	 
	 
	 */
}

+(NSString*)serialNumber {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
    if (platformExpert) {
        NSString* serialNumber = [(NSString*)IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0) autorelease];
        IOObjectRelease(platformExpert);
        return serialNumber;
    }
    
    return nil;
}

+(int)userId {
	return getuid();
}

@end
