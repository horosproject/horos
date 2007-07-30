//
//  DCMStudyRecord.m
//  OsiriX
//
//  Created by Lance Pysher on 2/21/05.

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

#import "DCMStudyRecord.h"
#import "DCMSeriesRecord.h"
#import "DCMImageRecord.h"
#import "DCM.h"


@implementation DCMStudyRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject{
	return [dcmObject attributeValueWithName:@"StudyInstanceUID"];
}

+ (id)studyRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	return [[[DCMStudyRecord alloc] initWithDCMObject:dcmObject atPath:(NSString *)path parent:(DCMRecord *)record] autorelease];
}

+ (id)studyRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	return [[[DCMStudyRecord alloc] initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record] autorelease];
}

- (id)initWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	if (self = [super initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record]){
		studyID  = [[dcmObject attributeValueWithName:@"StudyID"] retain];
		studyDescription = [[dcmObject attributeValueWithName:@"StudyDescription"] retain];
		studyDate = [[dcmObject attributeValueWithName:@"StudyDate"] retain];
		studyTime = [[dcmObject attributeValueWithName:@"StudyTime"] retain];
		studyInstanceUID = [[dcmObject attributeValueWithName:@"StudyInstanceUID"] retain];
		accessionNumber = [[dcmObject attributeValueWithName:@"AccessionNumber"] retain];
		uid = [studyInstanceUID retain];
		[self createBaseObject];
		[self addOffsetTemplate:dcmItem];
	}
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	if (self = [super initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record]) {
		//firstRecord in array should be for self.
		DCMObject *dcmObject = [recordSequence objectAtIndex:0];
		studyID  = [[dcmObject attributeValueWithName:@"StudyID"] retain];
		studyDescription = [[dcmObject attributeValueWithName:@"StudyDescription"] retain];
		studyDate = [[dcmObject attributeValueWithName:@"StudyDate"] retain];
		studyTime = [[dcmObject attributeValueWithName:@"StudyTime"] retain];
		studyInstanceUID = [[dcmObject attributeValueWithName:@"StudyInstanceUID"] retain];
		accessionNumber = [[dcmObject attributeValueWithName:@"AccessionNumber"] retain];
		[self parseRecordSequence:(NSArray *)recordSequence recordType:@"SERIES"];
	}
	return self ;
}

- (void)dealloc{
	[studyID release];
	[studyDescription release];
	[studyDate release];
	[studyTime release];
	[studyInstanceUID  release];
	[accessionNumber release];
	[super dealloc];
}

- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child;
	if ([DCMSeriesRecord recordUIDForDCMObject:dcmObject])
		child = [self childForUID:[DCMSeriesRecord recordUIDForDCMObject:dcmObject]];
	else
		child = [self childForUID:[DCMImageRecord recordUIDForDCMObject:dcmObject]];
		
	if (child)
		[child addChildForDCMObject:dcmObject  atPath:(NSString *)path];
	else
		[self newChildForDCMObject:dcmObject  atPath:(NSString *)path];
		

}

- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child;
	if ([DCMSeriesRecord recordUIDForDCMObject:dcmObject])
		child = [DCMSeriesRecord seriesRecordWithDCMObject:dcmObject  atPath:(NSString *)path parent:self];
	else
		child = [DCMImageRecord imageRecordWithDCMObject:dcmObject  atPath:(NSString *)path parent:self];
	[children addObject:child];		
}

- (void)addRecordType:(DCMObject *)object{
	[object setAttributeValues:[NSMutableArray arrayWithObject:@"STUDY"] forName:@"DirectoryRecordType"];
}

- (void)createBaseObject{
	[super createBaseObject];
	if (studyID)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:studyID] forName:@"StudyID"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"StudyID"];
		
	if (studyDate)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:studyDate] forName:@"StudyDate"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"StudyDate"];
		
	if (studyTime)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:studyTime] forName:@"StudyTime"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"StudyTime"];
	
	if (studyDescription)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:studyDescription] forName:@"StudyDescription"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"StudyDescription"];
		
	if (studyInstanceUID)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:studyInstanceUID] forName:@"StudyInstanceUID"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"StudyInstanceUID"];
		
	if (accessionNumber)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:accessionNumber] forName:@"AccessionNumber"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"AccessionNumber"];
	NSLog(@"new Study Item");
}

- (id)sortValue{
	return studyID;
}

- (void)subRecordWithSubSequence:(NSArray *)subSequence{
	[children addObject:[DCMSeriesRecord seriesRecordWithRecordSequence:(NSArray *)subSequence parent:(DCMRecord *)self]];
}
	

@end
