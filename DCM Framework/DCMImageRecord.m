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

#import "DCMImageRecord.h"
#import "DCM.h"


@implementation DCMImageRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject {
	return [dcmObject attributeValueWithName:@"SOPInstanceUID"];
}
+ (id)imageRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	return [[[DCMImageRecord alloc] initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record] autorelease];
}

- (id)initWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	if (self = [super initWithDCMObject:dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record]){
		instanceNumber  = [[dcmObject attributeValueWithName:@"InstanceNumber"] retain];
		contentDate = [[dcmObject attributeValueWithName:@"ContentDate"] retain];
		contentTime = [[dcmObject attributeValueWithName:@"ContentTime"] retain];
		sopInstanceUID = [[dcmObject attributeValueWithName:@"SOPInstanceUID"] retain];
		sopClassUID = [[dcmObject attributeValueWithName:@"SOPClassUID"] retain];
		transferSyntax = [[dcmObject attributeValueWithName:@"TransferSyntaxUID"] retain];
		pathArray = [[path pathComponents] mutableCopy];
		filePath = [path retain];
		[self createBaseObject];
		[self addOffsetTemplate:dcmItem];
		uid = [sopInstanceUID retain];
	}
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	if (self = [super initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record]) {
		//firstRecord in array should be for self.
		DCMObject *dcmObject = [recordSequence objectAtIndex:0];
		instanceNumber  = [[dcmObject attributeValueWithName:@"InstanceNumber"] retain];
		contentDate = [[dcmObject attributeValueWithName:@"ContentDate"] retain];
		contentTime = [[dcmObject attributeValueWithName:@"ContentTime"] retain];
		sopInstanceUID = [[dcmObject attributeValueWithName:@"SOPInstanceUID"] retain];
		sopClassUID = [[dcmObject attributeValueWithName:@"SOPClassUID"] retain];
		transferSyntax = [[dcmObject attributeValueWithName:@"TransferSyntaxUID"] retain];
		filePath = [[dcmObject attributeArrayWithName:@"ReferencedFileID"] componentsJoinedByString:@"/"];

	//	[self parseRecordSequence:(NSArray *)recordSequence recordType:@"IMAGE"];
	}
	return self ;
}

- (void)dealloc{
	[instanceNumber release];
	[contentDate release];
	[contentTime release];
	[sopInstanceUID  release];
	[sopClassUID release];
	[transferSyntax release];

	[super dealloc];
}

- (void)addChildForDCMObject:(DCMObject *)dcmObject{
	//return nil;
}

- (void)newChildForDCMObject:(DCMObject *)dcmObject{
	//return nil;
}

- (void)addRecordType:(DCMObject *)object{
	[object setAttributeValues:[NSMutableArray arrayWithObject:@"IMAGE"] forName:@"DirectoryRecordType"];
}

- (void)createBaseObject{
	[super createBaseObject];
	if (instanceNumber)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:instanceNumber] forName:@"InstanceNumber"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"InstanceNumber"];
		
	if (contentDate)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:contentDate] forName:@"ContentDate"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ContentDate"];
	
	if (contentTime)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:contentTime] forName:@"ContentTime"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ContentTime"];
		
	if (sopInstanceUID) 
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:sopInstanceUID] forName:@"ReferencedSOPInstanceUIDInFile"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ReferencedSOPInstanceUIDInFile"];
		
	if (sopClassUID) 
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:sopClassUID] forName:@"ReferencedSOPClassUIDInFile"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ReferencedSOPClassUIDInFile"];
		
	if (transferSyntax)
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:transferSyntax] forName:@"ReferencedTransferSyntaxUIDInFile"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ReferencedTransferSyntaxUIDInFile"];
		
	if (pathArray)
		[dcmItem setAttributeValues:pathArray forName:@"ReferencedFileID"];
	else
		[dcmItem setAttributeValues:[NSMutableArray array] forName:@"ReferencedFileID"];
	NSLog(@"new Image Item");
}

- (void)relativeFilePathForDICOMDIR:(NSString *)dirPath{
	[super relativeFilePathForDICOMDIR:(NSString *)dirPath];
	[dcmItem setAttributeValues:pathArray forName:@"ReferencedFileID"];
}

- (id)sortValue{
	return instanceNumber;
}

- (NSArray *)allItems{
	return [NSArray arrayWithObject:self];
}

@end
