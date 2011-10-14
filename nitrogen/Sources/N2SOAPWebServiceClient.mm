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

#import "N2SOAPWebServiceClient.h"
#import "N2WSDL.h"

@implementation N2SOAPWebServiceClient
@synthesize wsdl = _wsdl;

-(id)initWithWSDL:(N2WSDL*)wsdl {
	self = [super init];
	_wsdl = [wsdl retain];
	return self;
}

-(void)dealloc {
	if (_wsdl) [_wsdl release]; _wsdl = NULL;
	[super dealloc];
}

-(id)execute:(NSString*)method {
	[self execute:method params:NULL];
	return NULL;
}

-(id)execute:(NSString*)function params:(NSArray*)params {
	[NSException raise:NSGenericException format:@"NOT IMPLEMENTED"]; // TODO: this
	
/*	NSMutableString* request = [NSMutableString stringWithCapacity:1024];
	
	[request appendFormat:@"<?xml version=\"1.0\"?>\n\n"];
	[request appendFormat:@"<soap:Envelope xmlns:soap=\"http://www.w3.org/2001/12/soap-envelope\" soap:encodingStyle=\"http://www.w3.org/2001/12/soap-encoding\">"];

//	if (...) {
//		[request appendFormat:@"<soap:Header>"];
//		
//		// mustUnderstand
//		// actor
//		// encodingStyle
//		
//		[request appendFormat:@"</soap:Header>"];
//	}
	
	[request appendFormat:@"<soap:Body>"];
	[request appendFormat:@"</soap:Body>"];

	[request appendFormat:@"</soap:Envelope>"];
	
	
	<soap:Fault>
	...
	</soap:Fault>
	
	*/
	
	return NULL;
}

@end
