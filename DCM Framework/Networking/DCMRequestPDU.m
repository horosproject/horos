/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/


#import "DCMRequestPDU.h"


@implementation DCMRequestPDU

+ (id)requestWithData:(NSData *)data{
	return [[[DCMRequestPDU alloc] initWithData:data] autorelease];
}

+ (id)requestWithParameters:(NSDictionary *)params{
	return [[(DCMRequestPDU *)[DCMRequestPDU alloc] initWithParameters:params] autorelease];
}

- (id)initWithParameters:(NSDictionary *)params{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
	[parameters setObject:[NSNumber numberWithChar:0x01] forKey:@"pduType"];
	if (self = [super initWithParameters:parameters]) {
	}
	return self;
}

- (id)initWithData:(NSMutableData *)data{
	if (self = [super initWithData:data]){
		if (pduType != 0x01)
			NSLog(@"Unexpected PDU type 0x%x when expecting A-ASSOCIATE-RQ", pduType);
	}
	return self;
}

@end
