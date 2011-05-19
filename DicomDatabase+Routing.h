//
//  DicomDatabase+Routing.h
//  OsiriX
//
//  Created by Alessandro Volz on 18.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"


@interface DicomDatabase (Routing)

-(void)initRouting;
-(void)deallocRouting;

-(void)addImages:(NSArray*)_dicomImages toSendQueueForRoutingRule:(NSDictionary*)routingRule;
-(void)applyRoutingRules:(NSArray*)routingRules toImages:(NSArray*)images;
-(void)initiateRoutingUnlessAlreadyRouting;
-(void)routing;

@end
