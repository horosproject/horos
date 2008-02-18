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

#import "DCMSeriesRecord.h"
#import "DCMImageRecord.h"
#import "DCM.h"


@implementation DCMSeriesRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject{
	return [dcmObject attributeValueWithName:@"SeriesInstanceUID"];
}

+ (id)seriesRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	return [[[DCMSeriesRecord alloc] initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record] autorelease];
}

+ (id)seriesRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	return [[[DCMSeriesRecord alloc] initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record] autorelease];
}

- (id)initWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	if (self = [super initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record]){
		seriesNumber  = [[dcmObject attributeValueWithName:@"SeriesNumber"] retain];
		seriesDescription = [[dcmObject attributeValueWithName:@"SeriesDescription"] retain];
		seriesDate = [[dcmObject attributeValueWithName:@"SeriesDate"] retain];
		seriesTime = [[dcmObject attributeValueWithName:@"SeriesTime"] retain];
		seriesInstanceUID = [[dcmObject attributeValueWithName:@"SeriesInstanceUID"] retain];
		modality = [[dcmObject attributeValueWithName:@"Modality"] retain];
		uid = [seriesInstanceUID retain];
		[self createBaseObject];
		[self addOffsetTemplate:dcmItem];
	}
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	if (self = [super initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record]) {
		//firstRecord in array should be for self.
		DCMObject *dcmObject = [recordSequence objectAtIndex:0];
		seriesNumber  = [[dcmObject attributeValueWithName:@"SeriesNumber"] retain];
		seriesDescription = [[dcmObject attributeValueWithName:@"SeriesDescription"] retain];
		seriesDate = [[dcmObject attributeValueWithName:@"SeriesDate"] retain];
		seriesTime = [[dcmObject attributeValueWithName:@"SeriesTime"] retain];
		seriesInstanceUID = [[dcmObject attributeValueWithName:@"SeriesInstanceUID"] retain];
		modality = [[dcmObject attributeValueWithName:@"Modality"] retain];
\

		[self parseRecordSequence:(NSArray *)recordSequence recordType:@"IMAGE"];
	}
	return self ;
}

- (void)dealloc{
	[seriesNumber release];
	[seriesDescription release];
	[seriesDate release];
	[seriesTime release];
	[seriesInstanceUID  release];
	[modality release];
	[super dealloc];
}


- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child = [self childForUID:[DCMImageRecord recordUIDForDCMObject:dcmObject]];
	if (child)
		[child addChildForDCMObject:dcmObject  atPath:(NSString *)path];
	else
		[self newChildForDCMObject:dcmObject  atPath:(NSString *)path];
		

}

- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child = [DCMImageRecord imageRecordWithDCMObject:dcmObject  atPath:(NSString *)path parent:self];
	[children addObject:child];		
}

- (void)addRecordType:(DCMObject *)object{
	[object setAttributeValues:[NSMutableArray arrayWithObject:@"SERIES"] forName:@"DirectoryRecordType"];
}

- (void)createBaseObject{
	[super createBaseObject];
	if (seriesNumber)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:seriesNumber] forName:@"SeriesNumber"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"SeriesNumber"];
		
	if (seriesDate)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:seriesDate] forName:@"SeriesDate"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"SeriesDate"];
		
		
	if (seriesTime)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:seriesTime] forName:@"SeriesTime"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"SeriesTime"];

	if (modality)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:modality] forName:@"Modality"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"Modality"];
		
		
	if (seriesDescription)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:seriesDescription] forName:@"SeriesDescription"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"SeriesDescription"];
		
	if (seriesInstanceUID)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:seriesInstanceUID] forName:@"SeriesInstanceUID"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"SeriesInstanceUID"];
	NSLog(@"new Series Item");
}

- (id)sortValue{
	return seriesNumber;
}

- (void)subRecordWithSubSequence:(NSArray *)subSequence{
	//[children addObject:[DCMImageRecord imageRecordWithRecordSequence:(NSArray *)subSequence parent:(DCMRecord *)self]];
}

@end
