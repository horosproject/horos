//
//  DCMTKQueryNode.mm
//  OsiriX
//
//  Created by Lance Pysher on 4/4/06.

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

#import "DCMTKQueryNode.h"
#import <OsiriX/DCMCalendarDate.h>
 


@implementation DCMTKQueryNode

+ (id)queryNodeWithDataset:(DcmDataset *)dataset{
	return [[[DCMTKQueryNode alloc] initWithDataset:(DcmDataset *)dataset] autorelease];
}
- (id)initWithDataset:(DcmDataset *)dataset{
	if (self = [super init])
		_children = [[NSMutableArray alloc] init];
	return self;
}
- (void)dealloc{
	[_children release];
	[_uid release];
	[_theDescription release];
	[_name release];
	[_patientID release];
	[_date release];
	[_time release];
	[_modality release];
	[_numberImages release];
	[_specificCharacterSet release];
	[super dealloc];
}

- (NSString *)uid{
	return _uid;
}
- (NSString *)theDescription{
	return _theDescription;
}
- (NSString *)name{
	return _name;
}
- (NSString *)patientID{
	return _patientID;
}
- (DCMCalendarDate *)date{
	return _date;
}
- (DCMCalendarDate *)time{
	return _time;
}
- (NSString *)modality{
	return _modality;
}
- (NSNumber *)numberImages{
	return _numberImages;
}
- (NSMutableArray *)children{
	return _children;
}
- (void)addChild:(DcmDataset *)dataset{

}
- (DcmDataset *)queryPrototype{
	return nil;
}

// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
- (void)queryWithValues:(NSArray *)values parameters:(NSDictionary *)parameters{
}

- (void)move:(NSDictionary *)parameters{
}

@end
