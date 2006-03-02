//
//  DCMImageQueryNode.m
//  OsiriX

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
//

#import "DCMImageQueryNode.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMImageQueryNode

+ (id)queryNodeWithObject:(DCMObject *)object{
	return [[[DCMImageQueryNode alloc] initWithObject:(DCMObject *)object] autorelease];
}


- (id)initWithObject:(DCMObject *)object{
	if (self = [super initWithObject:(DCMObject *)object])
		children = [[NSMutableArray array] retain];
	return self;
}

- (DCMObject *)queryPrototype{
	return nil;
}

- (void)addChild:(id)child{
 // no children
}

- (NSString *)uid{
	return [dcmObject attributeValueWithName:@"SOPInstanceUID"];
}
- (NSString *)theDescription{
	return nil;
}
- (NSString *)name{
	return [dcmObject attributeValueWithName:@"InstanceNumber"];
}
- (DCMCalendarDate *)date{
	return [dcmObject attributeValueWithName:@"InstanceDate"];
}
- (DCMCalendarDate *)time{
	return [dcmObject attributeValueWithName:@"InstanceTime"];
}

- (NSString *)modality{
	return nil;
}

- (void)move:(NSDictionary *)parameters{
		NSLog(@"image Move");
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
		[params setObject:[NSNumber numberWithInt:0] forKey:@"debugLevel"];
		if (![params objectForKey:@"moveDestination"])
			[params setObject:[params objectForKey:@"callingAET"]  forKey:@"moveDestination"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelMove] forKey:@"affectedSOPClassUID"];
		[params setObject:[NSNumber numberWithInt:1000000] forKey:@"timeout"];
		
		DCMObject *moveObject = [DCMObject dcmObject];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[self uid]] forName:@"SOPInstanceUID"];
		if ([dcmObject attributeValueWithName:@"SeriesInstanceUID"])
			[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[dcmObject attributeValueWithName:@"SeriesInstanceUID"]] forName:@"SeriesInstanceUID"];
		if ([dcmObject attributeValueWithName:@"StudyInstanceUID"])
			[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[dcmObject attributeValueWithName:@"StudyInstanceUID"]] forName:@"StudyInstanceUID"];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:@"IMAGE"] forName:@"Query/RetrieveLevel"];
		
		[params setObject:moveObject forKey:@"moveObject"];
		//NSLog(@"move params; %@", [params description]);
		[DCMMoveSCU moveWithParameters:params];
}

@end
