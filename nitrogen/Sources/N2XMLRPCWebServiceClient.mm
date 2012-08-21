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

#import "N2XMLRPCWebServiceClient.h"
#import "N2XMLRPC.h"


@implementation N2XMLRPCWebServiceClient

-(id)execute:(NSString*)methodName arguments:(NSArray*)args {
    NSString* request = [N2XMLRPC requestWithMethodName:methodName arguments:args];
    
	NSData* result = [self postWithContent:[request dataUsingEncoding:NSISOLatin1StringEncoding]];
	
	NSError* error = NULL;
	NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithData:result options:0 error:&error] autorelease];
	if (error) [NSException raise:NSGenericException format:@"%@", error.description];
	
	NSArray* errs = [doc objectsForXQuery:@"/methodResponse/fault/value" error:NULL];
	if (errs.count)
		[NSException raise:NSGenericException format:@"[N2XMLRPCWebServiceClient execute:arguments:] fault: %@", [N2XMLRPC ParseElement:[errs objectAtIndex:0]]];
	
	NSArray* vals = [doc objectsForXQuery:@"/methodResponse/params/param/value" error:NULL];
	if (vals.count != 1) [NSException raise:NSGenericException format:@"[N2XMLRPCWebServiceClient execute:arguments:] received %d return values", (int) vals.count];
	
	return [N2XMLRPC ParseElement:[vals objectAtIndex:0]];
}

/*-(BOOL)validateResult:(NSData*)result {
	return YES;
}*/

@end
