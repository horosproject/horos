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

#import "DCMPatientRecord.h"
#import "DCMStudyRecord.h"
#import "DCM.h"


@implementation DCMPatientRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject{
		NSString *name = [dcmObject attributeValueWithName:@"PatientsName"];
		NSString *pid = [dcmObject attributeValueWithName:@"PatientID"];
		return [NSString stringWithFormat:@"%@ %@", name, pid];
}

+ (id)patientRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	return [[[DCMPatientRecord alloc] initWithDCMObject:dcmObject atPath:(NSString *)path parent:(DCMRecord *)record] autorelease];
}

+ (id)patientRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	return [[[DCMPatientRecord alloc] initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record] autorelease];
}

- (id)initWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	if (self = [super initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record]){
		patientsName = [[dcmObject attributeValueWithName:@"PatientsName"] retain];
		patientID = [[dcmObject attributeValueWithName:@"PatientID"] retain];
		uid = [[NSString stringWithFormat:@"%@ %@", patientsName, patientID] retain];
		[self createBaseObject];
		[self addOffsetTemplate:dcmItem];
	}
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	if (self = [super initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record]) {
		//firstRecord in array should be for self.
		DCMObject *dcmObject = [recordSequence objectAtIndex:0];
		patientsName = [[dcmObject attributeValueWithName:@"PatientsName"] retain];
		patientID = [[dcmObject attributeValueWithName:@"PatientID"] retain];
		uid = [[NSString stringWithFormat:@"%@ %@", patientsName, patientID] retain];

		[self parseRecordSequence:(NSArray *)recordSequence recordType:@"STUDY"];
	}
	return self ;
}

- (void)dealloc{
	[patientsName release];
	[patientID release];
	[super dealloc];
}

- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child = [self childForUID:[DCMStudyRecord recordUIDForDCMObject:dcmObject]];
	if (child)
		[child addChildForDCMObject:dcmObject  atPath:(NSString *)path];
	else
		[self newChildForDCMObject:dcmObject  atPath:(NSString *)path];
		

}

- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	DCMRecord *child = [DCMStudyRecord studyRecordWithDCMObject:dcmObject  atPath:(NSString *)path parent:self];
	[children addObject:child];		
}

- (void)addRecordType:(DCMObject *)object{
	[object setAttributeValues:[NSMutableArray arrayWithObject:@"PATIENT"] forName:@"DirectoryRecordType"];
}

- (void)createBaseObject{
	[super createBaseObject];
	if (patientsName)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:patientsName] forName:@"PatientsName"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
		
	if (patientID)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:patientID] forName:@"PatientID"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
		
		
	NSLog(@"new Patient Item:");
}

- (id)sortValue{
	return patientsName;
}

- (void)subRecordWithSubSequence:(NSArray *)subSequence{
	[children addObject:[DCMStudyRecord studyRecordWithRecordSequence:(NSArray *)subSequence parent:(DCMRecord *)self]];
}
		

@end
