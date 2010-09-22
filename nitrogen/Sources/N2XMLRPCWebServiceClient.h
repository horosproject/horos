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


@interface N2XMLRPCWebServiceClient : N2RedundantWebServiceClient {
}

-(id)execute:(NSString*)methodName arguments:(NSArray*)args;

@end
