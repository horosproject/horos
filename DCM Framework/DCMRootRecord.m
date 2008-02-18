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

#import "DCMRootRecord.h"
#import "DCMPatientRecord.h"
#import "DCM.h"


@implementation DCMRootRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject {
	return nil;
}

+ (id)rootRecord{
	return [[[DCMRootRecord alloc] init] autorelease];
}

+ (id)rootRecordWithRecordSequence:(NSArray *)recordSequence {
	return [[[DCMRootRecord alloc] initWithRecordSequence:(NSArray *)recordSequence parent:nil] autorelease];
}

- (id)init {
	NSLog(@"init Root record");
	self =  [super initWithDCMObject:nil  atPath:nil parent:nil];
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record {
	if (self = [super initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record]) {
		[self parseRecordSequence:(NSArray *)recordSequence recordType:@"PATIENT"];
	}
	return self ;
}

- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path {
	DCMRecord *child = [self childForUID:[DCMPatientRecord recordUIDForDCMObject:dcmObject]];
	if (child)
		[child addChildForDCMObject:dcmObject  atPath:(NSString *)path];
	else
		[self newChildForDCMObject:dcmObject  atPath:(NSString *)path];
		

}

- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMPatientRecord *child = [DCMPatientRecord patientRecordWithDCMObject:dcmObject  atPath:(NSString *)path parent:self];
	[children addObject:child];		
}

- (NSArray *)allItems {
	NSMutableArray *array = [NSMutableArray array];
	NSEnumerator *enumerator = [self sortedChildEnumerator];
	DCMRecord *child;
	while ( child == [enumerator nextObject] ) 
		[array addObjectsFromArray:[child allItems]];
	return array;
}

- (void)subRecordWithSubSequence:(NSArray *)subSequence {
	[children addObject:[DCMPatientRecord patientRecordWithRecordSequence:(NSArray *)subSequence parent:(DCMRecord *)self]];
}

@end
