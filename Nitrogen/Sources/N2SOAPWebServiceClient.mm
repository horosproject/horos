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
