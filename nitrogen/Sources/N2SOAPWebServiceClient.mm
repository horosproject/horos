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
#import "N2WSDL.h";

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
	return NULL;
}

@end
