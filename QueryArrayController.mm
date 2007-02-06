/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "QueryArrayController.h"
#import <OsiriX/DCM.h>
#import <OsiriX/DCMNetworking.h>
#import <OsiriX/DCMNetServiceDelegate.h>

#import "DCMTKRootQueryNode.h"
#import "DCMTKStudyQueryNode.h"
#import "DCMTKSeriesQueryNode.h"
#import "DCMTKImageQueryNode.h"

@implementation QueryArrayController

- (id)initWithCallingAET:(NSString *)myAET calledAET:(NSString *)theirAET  hostName:(NSString *)host  port:(NSString *)tcpPort netService:(NSNetService *)netService;
{
	if (self = [super init]){		
		rootNode = nil;
		filters = [[NSMutableDictionary dictionary] retain];
		callingAET = [myAET retain];
		calledAET = [theirAET retain];
		hostname = [host retain];
		port = [tcpPort retain];
		queries = nil;
		_netService = [netService retain];
		//NSLog(@"init Query Manager");
		
	}
	return self;
}
	


- (id)rootNode{
	return rootNode;
}

- (void)dealloc{
	[rootNode release];
	[filters release];
	[calledAET release];
	[callingAET release];
	[hostname release];
	[port release];
	[queries release];
	[_netService release];
	[super dealloc];
}

- (void)addFilter:(id)filter forDescription:(NSString *)description{
	NSLog(@"Filter: %@", [filter description]);
	if ([description rangeOfString:@"Date"].location != NSNotFound)
		filter = [DCMCalendarDate queryDate:filter];
	else if ([description rangeOfString:@"Time"].location != NSNotFound)
		filter = [DCMCalendarDate queryDate:filter];
	NSLog(@"add filter:%@ class:%@ description:%@", [filter description], [filter class], [description description]);
	[filters setObject:filter forKey:description];
}

- (NSArray *)queries{
	return queries;
}

- (void)sortArray:(NSArray *)sortDesc{
	NSArray *newQueries = [queries sortedArrayUsingDescriptors:sortDesc];
	[queries release];
	queries = [newQueries retain];
}

- (void)performQuery{
	NS_DURING
	//NSLog(@"query");
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
	[params setObject:callingAET forKey:@"callingAET"];
	[params setObject:calledAET forKey:@"calledAET"];
	/*
	if (_netService) {
		hostname = [_netService hostName];
		[port release];
		port = [[NSString stringWithFormat:@"%d", [[DCMNetServiceDelegate sharedNetServiceDelegate] portForNetService:_netService]] retain];
		[params setObject:_netService  forKey:@"netService"];
	}
	else {
		[params setObject:hostname  forKey:@"hostname"];
		[params setObject:port forKey:@"port"];
	}
	*/
	[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
	[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelFind] forKey:@"affectedSOPClassUID"];
	
	[rootNode release];
	rootNode = [[DCMTKRootQueryNode queryNodeWithDataset:nil
									callingAET:callingAET
									calledAET:calledAET 
									hostname:hostname
									port:[port intValue]
									transferSyntax:0L		//EXS_LittleEndianExplicit
									compression: nil
									extraParameters:nil] retain];
	NSMutableArray *filterArray = [NSMutableArray array];
	NSEnumerator *enumerator = [filters keyEnumerator];
	NSString *key;
	while (key = [enumerator nextObject]) {
		if ([filters objectForKey:key]) {
			NSDictionary *filter = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[filters objectForKey:key], key, nil] forKeys:[NSArray arrayWithObjects:@"value",  @"name", nil]];
			[filterArray addObject:filter];
		}
	}
			
	[rootNode queryWithValues:filterArray];
	
	[queries release];
	queries = [[rootNode children] retain];
	
	NS_HANDLER
		NSAlert *alert = [NSAlert alertWithMessageText:@"Query Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Query Failed"];
		NSLog(@"performQuery exception: %@", [localException name]);
		[alert runModal];
	NS_ENDHANDLER
}

- (NSDictionary *)parameters{	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NS_DURING
		
		[params setObject:[NSNumber numberWithInt:1] forKey:@"debugLevel"];
		[params setObject:callingAET forKey:@"callingAET"];
		[params setObject:calledAET forKey:@"calledAET"];
		if (_netService)
			[params setObject:_netService  forKey:@"netService"];
		else {
			[params setObject:hostname  forKey:@"hostname"];
			[params setObject:port forKey:@"port"];
		}

		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];		//
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelFind] forKey:@"affectedSOPClassUID"];
	NS_HANDLER
		NSAlert *alert = [NSAlert alertWithMessageText:@"Query Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Unable to perform Q/R. There was a missing parameter. Make sure you have AE Titles, IP addresses and ports for the queried computer"];
	
		[alert runModal];
		NSLog(@"Missing parameter for Query/retrieve: %@", [localException name]);
		params = nil;
	NS_ENDHANDLER
	return params;
}
@end
