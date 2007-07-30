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




#import <Cocoa/Cocoa.h>



@interface QueryArrayController : NSObject {
	id rootNode;
	NSMutableDictionary *filters;
	NSString *callingAET;
	NSString *calledAET;
	NSString *hostname;
	NSString *port;
	NSArray *queries;
	NSNetService *_netService;
	NSLock *queryLock;
}

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort netService:(NSNetService *)netService;


- (id)rootNode;
- (NSArray *)queries;

- (void)addFilter:(id)filter forDescription:(NSString *)description;
- (void)sortArray:(NSArray *)sortDesc;
- (void)performQuery;
- (NSDictionary *)parameters;


@end
