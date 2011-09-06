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


@implementation N2RedundantWebServiceClient
@synthesize urls = _urls;

-(void)dealloc {
	[self setUrls:NULL];
	[super dealloc];
}

-(NSData*)requestWithMethod:(HTTPMethod)method content:(NSData*)content headers:(NSDictionary*)headers context:(id)context {
	NSException* exception = NULL;
	
	if (self.urls.count)
		for (NSURL* url in [self urls]) 
			@try {
				[self setUrl:url];
				NSData* result = [super requestWithMethod:method content:content headers:headers context:context];
//				if (result) // on peut aussi vouloir retourner nil
				return result;
			} @catch (NSException* e) {
				exception = e; // ignore, just try the next
			}
	else if (self.url)
		return [super requestWithMethod:method content:content headers:headers context:context];
	else
		[NSException raise:NSGenericException format:@"[N2RedundantWebServiceClient requestWithMethod:parameters:content:headers:contex:] has no URLs"];
	
	if (exception) [exception raise];
	[NSException raise:NSGenericException format:@"[N2RedundantWebServiceClient requestWithMethod:parameters:content:headers:contex:] is giving up after trying with all the available URLs"];
	return NULL; // will raise last exception, never return
}

@end
