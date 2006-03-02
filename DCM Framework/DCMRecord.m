//
//  DCMRecord.m
//  OsiriX
//
//  Created by Lance Pysher on 2/21/05.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMRecord.h"
#import "DCM.h"

// static int recordHeaderLength = 36; //Three unsigned long explicit VR attrs

@implementation DCMRecord

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject parent:(DCMRecord *)record{
	return nil;
}

+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject{
	return nil;
}

+ (id)recordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	return [[[DCMRecord alloc] initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record] autorelease];
}

- (id)initWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record{
	if (self = [super init]) {
		children = [[NSMutableSet alloc] init];
		uid = nil;
		parent = record;
		specificCharacterSet = [[dcmObject attributeValueWithName:@"SpecificCharacterSet"] retain];
		if (dcmObject)
			[self newChildForDCMObject:dcmObject  atPath:(NSString *)path];
	}
	return self;
}

- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record{
	if (self = [super init]) {
		children = [[NSMutableSet alloc] init];
		uid = nil;
		parent = record;
	}
	return self;
	
}

- (void)dealloc{
	[uid release];
	[children release];
	[sortedArray release];
	[dcmItem release];
	[filePath release];
	[pathArray release];
	[specificCharacterSet release];
	[super dealloc];
}

- (NSString *)uid{
	return uid;
}

- (BOOL)isLeaf{
	return [self numberOfChildren];
}
- (int)numberOfChildren{
	return [children count];
}
- (NSEnumerator *)childEnumerator{
	return [children objectEnumerator];
}

- (NSEnumerator *)sortedChildEnumerator{
	NSArray *array = [children allObjects];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sortValue" ascending:YES] autorelease];
	[sortedArray release];
	sortedArray = [[array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] retain];
	NSEnumerator *enumerator = [sortedArray objectEnumerator];
	return enumerator;
}

- (NSArray *)children{
	NSArray *array = [children allObjects];
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sortValue" ascending:YES] autorelease];
	[sortedArray release];
	sortedArray = [[array sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] retain];
	return sortedArray;
}
	

- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{

}

- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path{
	//return nil;
}

- (void)removeChild:(DCMRecord *)child{
	[children removeObject:child];
}

- (id)childForUID:(NSString *)aUID{
	NSEnumerator *enumerator = [self childEnumerator];
	id child;
	while (child = [enumerator nextObject]){
		if ([[child uid] isEqualToString:aUID])
			return child;
	}
	return nil;
}

- (id)sortValue{
	return nil;
}

- (int)recordLength{
	//add 16 for our item tag and delimiter tag;
	DCMDataContainer *container = [DCMDataContainer dataContainer];
	if ([dcmItem writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax]
			quality:DCMLosslessQuality 
			asDICOM3:NO
			AET:nil
			strippingGroupLengthLength:NO])
		return [[container dicomData] length] + 24;
	return 0;
}

- (int)childrenLength{
	int length = 0;
	NSEnumerator *enumerator = [self childEnumerator]; 
	DCMRecord *child;
	while (child = [enumerator nextObject])
		length +=  [child totalLength];
	
	return length;
}

- (int)totalLength{
	return [self childrenLength] + [self recordLength];
}

- (int)setOffsets:(int)startingOffset{
	offset = startingOffset;
	int newOffset = startingOffset + [self recordLength];
	if ([self numberOfChildren]) {
		[dcmItem addAttributeValue:[NSNumber numberWithInt:newOffset] forName:@"OffsetOfReferencedLowerLevelDirectoryEntity"];
		NSEnumerator *enumerator = [self sortedChildEnumerator];
		DCMRecord *child;
		while (child = [enumerator nextObject])
			newOffset= [child setOffsets:newOffset];
	}
	else 
		[dcmItem addAttributeValue:[NSNumber numberWithInt:0] forName:@"OffsetOfReferencedLowerLevelDirectoryEntity"];
		
		
	if ([self isLastObject]	)
		[dcmItem addAttributeValue:[NSNumber numberWithInt:0] forName:@"OffsetOfTheNextDirectoryRecord"];
	else
		[dcmItem addAttributeValue:[NSNumber numberWithInt:newOffset] forName:@"OffsetOfTheNextDirectoryRecord"];
	
		
	return newOffset;
}

- (void)addOffsetTemplate:(DCMObject *)object{
	[object setAttributeValues:[NSMutableArray array] forName:@"OffsetOfTheNextDirectoryRecord"];
	[object setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:0xFFFF]] forName:@"RecordInUseFlag"];
	[object setAttributeValues:[NSMutableArray array] forName:@"OffsetOfReferencedLowerLevelDirectoryEntity"];
}

- (int)offset{
	return offset;
}

- (void)addRecordType:(DCMObject *)object{
}

- (void)createBaseObject{
	dcmItem = [[DCMObject alloc] init];
	[self addRecordType:dcmItem];
	// unless root Record	
	if (specificCharacterSet && ![self isKindOfClass:[DCMRootRecord class]]) {
		[dcmItem setAttributeValues:[NSMutableArray arrayWithObject:specificCharacterSet] forName:@"SpecificCharacterSet"];
	}
}

- (NSArray *)allItems{
	NSMutableArray *array = [NSMutableArray arrayWithObject:self];
	NSEnumerator *enumerator = [self sortedChildEnumerator];
	DCMRecord *child;
	while (child = [enumerator nextObject]) 
		[array addObjectsFromArray:[child allItems]];
	return array;
}

- (void)relativeFilePathForDICOMDIR:(NSString *)dirPath{
	NSString *newPath;
	[pathArray release];

	NSRange range = [filePath rangeOfString:[dirPath stringByDeletingLastPathComponent]];
	//add 1 to skip first /
	if (range.location != NSNotFound)
		newPath = [filePath substringFromIndex:range.location + range.length + 1];
	else
		newPath = nil;
	[filePath release];
	filePath = [newPath retain];
	pathArray = [[filePath pathComponents] retain];
}

- (DCMObject *)item{
	return dcmItem;
}

- (BOOL)isLastObject{
	if ([[[parent children] lastObject] isEqual:self])
		return YES;
	return NO;
}

- (void)parseRecordSequence:(NSArray *)recordSequence recordType:(NSString *)recordType{
	int i = 0;
	int index, nextIndex;
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	for (i = 0; i < [recordSequence count]; i++) {
		DCMObject *record = [recordSequence objectAtIndex:i];
		// get indexes for child records
		if ([[record attributeValueWithName:@"DirectoryRecordType"] isEqualToString:recordType]){
			[indexSet addIndex:i];
		}
	}
	index = [indexSet firstIndex];
	while (index != NSNotFound) {
		int length;
		nextIndex = [indexSet indexGreaterThanIndex:index];
		if (nextIndex != NSNotFound) 
			length = nextIndex - index;
		else
			length = [recordSequence count] - index;
		NSRange range = NSMakeRange(index, length);
		NSArray *subRecords = [recordSequence subarrayWithRange:range];
		[self subRecordWithSubSequence:subRecords];
		index = nextIndex;
	}			
}

- (void)subRecordWithSubSequence:(NSArray *)subSequence{
	
	
}

@end
