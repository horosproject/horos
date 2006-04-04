//
//  DCMTKQueryNode.h
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

#import <Cocoa/Cocoa.h>


#undef verify
#include "dcdatset.h"

@class DCMCalendarDate;

@interface DCMTKQueryNode : NSObject {
	NSMutableArray *_children;
	NSString *_uid;
	NSString *_theDescription;
	NSString *_name;
	NSString *_patientID;
	DCMCalendarDate *_date;
	DCMCalendarDate *_time;
	NSString *_modality;
	NSNumber *_numberImages;
	NSString *_specificCharacterSet;
	
}

+ (id)queryNodeWithDataset:(DcmDataset *)dataset;
- (id)initWithDataset:(DcmDataset *)dataset;
- (NSString *)uid;
- (NSString *)theDescription;
- (NSString *)name;
- (NSString *)patientID;
- (DCMCalendarDate *)date;
- (DCMCalendarDate *)time;
- (NSString *)modality;
- (NSNumber *)numberImages;
- (NSMutableArray *)children;
- (void)addChild:(DcmDataset *)dataset;
- (DcmDataset *)queryPrototype;
// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
- (void)queryWithValues:(NSArray *)values parameters:(NSDictionary *)parameters;
- (void)move:(NSDictionary *)parameters;

@end
