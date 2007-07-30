//
//  DCMQueryNode.m
//  OsiriX
//
//  Created by Lance Pysher on 1/4/05.

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
//

#import "DCMQueryNode.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMQueryNode

+ (id)queryNodeWithObject:(DCMObject *)object{
	return [[[DCMQueryNode alloc] initWithObject:(DCMObject *)object] autorelease];
}

- (id)initWithObject:(DCMObject *)object{
	if (self = [super init])
		dcmObject = [object retain];
	return self;
}

- (void)dealloc{
	[dcmObject release];
	[children release];
	[super dealloc];
}

- (NSString *)uid{
	return nil;
}

- (NSString *)theDescription{
	return nil;
}


- (NSString *)name{
	return nil;
}

- (NSString *)patientID{
	return nil;
}


- (DCMCalendarDate *)date{
	return nil;
}


- (DCMCalendarDate *)time{
	return nil;
}


- (NSString *)modality{
	return nil;
}

- (NSNumber *)numberImages{
	return nil;
}


- (NSMutableArray *)children{
	return children;
}

- (void)addChild:(id)child{
	if (!children)
		children = [[NSMutableArray array] retain];
	//[children addObject:child];
}

- (DCMObject *)queryPrototype{
	return nil;
}

- (void)queryWithValues:(NSArray *)values parameters:(NSDictionary *)parameters{
	DCMCFindResponseDataHandler *dataHandler = [DCMCFindResponseDataHandler findHandlerWithDebugLevel:0 queryNode:self];
	DCMObject *findObject = [self queryPrototype];
	NSEnumerator *enumerator = [values objectEnumerator];
	NSDictionary *value;
	while (value = [enumerator nextObject])
		[findObject addAttributeValue:[value objectForKey:@"value"]  forName:[value objectForKey:@"name"]];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
	[params setObject:[NSNumber numberWithInt:0] forKey:@"debugLevel"];
	NSLog(@"dataHandler %@", dataHandler);
	[params setObject:dataHandler  forKey:@"receivedDataHandler"];
	[params setObject:findObject forKey:@"findObject"];
	//[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelFind] forKey:@"affectedSOPClassUID"];
	[DCMFindSCU findWithParameters:params];
}

- (void)move:(NSDictionary *)parameters{
}

- (NSString *)description{
	return [NSString stringWithFormat:@"QueryNode:\n%@\n%@", [dcmObject description], [children description]];
}


@end
