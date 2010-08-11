//
//  N2XMLRPCWebServiceClient.h
//  Nitrogen
//
//  Created by Alessandro Volz on 8/11/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "N2RedundantWebServiceClient.h"


@interface N2XMLRPCWebServiceClient : N2RedundantWebServiceClient {
}

-(id)execute:(NSString*)methodName arguments:(NSArray*)args;

@end
