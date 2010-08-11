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

#import "N2RedundantWebServiceClient.h"

@class N2WSDL;

@interface N2SOAPWebServiceClient : N2RedundantWebServiceClient {
	N2WSDL* _wsdl;
}

@property(readonly) N2WSDL* wsdl;

-(id)initWithWSDL:(N2WSDL*)wsdl;
-(id)execute:(NSString*)method;
-(id)execute:(NSString*)function params:(NSArray*)params;

@end
