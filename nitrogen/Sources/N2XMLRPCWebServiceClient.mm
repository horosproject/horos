//
//  N2XMLRPCWebServiceClient.mm
//  Nitrogen
//
//  Created by Alessandro Volz on 8/11/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "N2XMLRPCWebServiceClient.h"
#import "N2XMLRPC.h"


@implementation N2XMLRPCWebServiceClient


-(id)execute:(NSString*)methodName arguments:(NSArray*)args {
	NSMutableString* request = [NSMutableString stringWithCapacity:1024];
	
	[request appendFormat:@"<?xml version='1.0' encoding='utf-8' ?>\n\n"];
	[request appendFormat:@"<methodCall>"];
	[request appendFormat:@"<methodName>%@</methodName>", methodName];
	[request appendFormat:@"<params>"];
	
	for (id arg in args)
		[request appendFormat:@"<param><value>%@</value></param>", [N2XMLRPC FormatElement:arg]];
	
	[request appendFormat:@"</params>"];
	[request appendFormat:@"</methodCall>"];
	
	NSData* result = [self postWithContent:[request dataUsingEncoding:NSISOLatin1StringEncoding]];
	
	NSError* error = NULL;
	NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithData:result options:0 error:&error] autorelease];
	if (error) [NSException raise:NSGenericException format:error.description];
	
	NSArray* errs = [doc objectsForXQuery:@"/methodResponse/fault/value" error:NULL];
	if (errs.count)
		[NSException raise:NSGenericException format:@"[N2XMLRPCWebServiceClient execute:arguments:] fault: ", [N2XMLRPC ParseElement:[errs objectAtIndex:0]]];
	
	NSArray* vals = [doc objectsForXQuery:@"/methodResponse/params/param/value" error:NULL];
	if (vals.count != 1) [NSException raise:NSGenericException format:@"[N2XMLRPCWebServiceClient execute:arguments:] received %d return values", vals.count];
	
	return [N2XMLRPC ParseElement:[vals objectAtIndex:0]];
}

/*-(BOOL)validateResult:(NSData*)result {
	return YES;
}*/

@end
