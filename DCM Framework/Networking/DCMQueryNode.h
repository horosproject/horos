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

@class DCMObject;
@class DCMCalendarDate;

@interface DCMQueryNode : NSObject {

	NSMutableArray *children;
	DCMObject *dcmObject;

}

@property(readonly) NSMutableArray *children;

+ (id)queryNodeWithObject:(DCMObject *)object;
- (id)initWithObject:(DCMObject *)object;
- (NSString *)uid;
- (NSString *)theDescription;
- (NSString *)name;
- (NSString *)patientID;
- (DCMCalendarDate *)date;
- (DCMCalendarDate *)time;
- (NSString *)modality;
- (NSNumber *)numberImages;
- (void)addChild:(id)child;
- (DCMObject *)queryPrototype;
// values are a NSDictionary the key for the value is @"value" key for the name is @"name"  name is the tag descriptor from the tag dictionary
- (void)queryWithValues:(NSArray *)values parameters:(NSDictionary *)parameters;
- (void)move:(NSDictionary *)parameters;

@end
