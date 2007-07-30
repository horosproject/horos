//
//  DCMSeriesQueryNode.m
//  OsiriX
//

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

#import "DCMSeriesQueryNode.h"
#import "DCM.h"
#import "DCMNetworking.h"


@implementation DCMSeriesQueryNode

+ (id)queryNodeWithObject:(DCMObject *)object{
	return [[[DCMSeriesQueryNode alloc] initWithObject:(DCMObject *)object] autorelease];
}


- (DCMObject *)queryPrototype{
	//root will search for Images
	DCMObject *findObject = [DCMObject dcmObject];

	[findObject setAttributeValues:[NSMutableArray array] forName:@"InstanceDate"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"InstanceTime"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"SOPInstanceUID"];
		[findObject setAttributeValues:[NSMutableArray array] forName:@"SeriesInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray array] forName:@"InstanceNumber"];
	// this will be be link to our UID
	[findObject setAttributeValues:[NSMutableArray arrayWithObject:[dcmObject attributeValueWithName:@"SeriesInstanceUID"]] forName:@"SeriesInstanceUID"];
	[findObject setAttributeValues:[NSMutableArray arrayWithObject:@"IMAGE"] forName:@"Query/RetrieveLevel"];
	return findObject;
}

- (void)addChild:(id)child{
	if (!children)
		children = [[NSMutableArray array] retain];
	[children addObject:[DCMImageQueryNode queryNodeWithObject:child]];
}

- (NSString *)uid{
	return [dcmObject attributeValueWithName:@"SeriesInstanceUID"];
}
- (NSString *)theDescription{
	return [dcmObject attributeValueWithName:@"SeriesDescription"];
}
- (NSString *)name{
	return [dcmObject attributeValueWithName:@"SeriesNumber"];
}
- (DCMCalendarDate *)date{
	return [dcmObject attributeValueWithName:@"SeriesDate"];
}
- (DCMCalendarDate *)time{
	return [dcmObject attributeValueWithName:@"SeriesTime"];
}

- (NSString *)modality{
	return nil;
}

- (NSNumber *)numberImages{
	return [NSNumber numberWithInt:[[dcmObject attributeValueWithName:@"NumberofSeriesRelatedInstances"] intValue]];
}

- (void)move:(NSDictionary *)parameters{
	NS_DURING
		//NSLog(@"series move");
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
		[params setObject:[NSNumber numberWithInt:0] forKey:@"debugLevel"];
		if (![params objectForKey:@"moveDestination"])
			[params setObject:[params objectForKey:@"callingAET"]  forKey:@"moveDestination"];
		[params setObject:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] forKey:@"transferSyntax"];
		[params setObject:[DCMAbstractSyntaxUID  studyRootQueryRetrieveInformationModelMove] forKey:@"affectedSOPClassUID"];
		[params setObject:[NSNumber numberWithInt:1000000] forKey:@"timeout"];
		//NSLog(@"move params; %@", [params description]);
		DCMObject *moveObject = [DCMObject dcmObject];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[self uid]] forName:@"SeriesInstanceUID"];
		NSLog(@"dcmObject: %@", [dcmObject description]);
		if ([dcmObject attributeValueWithName:@"StudyInstanceUID"])
			[moveObject setAttributeValues:[NSMutableArray arrayWithObject:[dcmObject attributeValueWithName:@"StudyInstanceUID"]] forName:@"StudyInstanceUID"];
		[moveObject setAttributeValues:[NSMutableArray arrayWithObject:@"SERIES"] forName:@"Query/RetrieveLevel"];
		//NSLog(@"moveObject: %@", moveObject);
		[params setObject:moveObject forKey:@"moveObject"];
		
		[DCMMoveSCU moveWithParameters:params];
	NS_HANDLER
		NSLog(@"Exception performing move: %@", [localException name]);
	NS_ENDHANDLER
}

@end
