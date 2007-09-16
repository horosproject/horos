//
//  DCMDirectory.m
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

#import "DCMDirectory.h"
#import "DCMRecord.h"
//#import "DCMAbstractSyntaxUID.h"
#import "DCMRootRecord.h"
#import "DCM.h"
#import "DCMNetworking.h"

@implementation DCMDirectory

@synthesize root;

+ (id)directory{
	return [[[DCMDirectory alloc] init] autorelease];
}

+ (id)directoryWithDICOMDIR:(NSString *)dicomdir {
	return [[[DCMDirectory alloc] initWithDICOMDIR:dicomdir] autorelease];
}

+ (id)filePathsFromDICOMDIR:(NSString *)dicomdir {
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:dicomdir decodingPixelData:NO];
	DCMSequenceAttribute *recordSequenceAttr = (DCMSequenceAttribute *)[dcmObject attributeWithName:@"DirectoryRecordSequence"] ;
	NSArray *recordSequence = [recordSequenceAttr sequence];
	NSMutableSet *paths = [NSMutableSet set];
	NSString *rootdir = [dicomdir stringByDeletingLastPathComponent];
	for ( DCMObject *record in recordSequence ) {
		//NSLog(@"record: %@", [record description]);
		NSString *filePath = [[record attributeArrayWithName:@"ReferencedFileID"] componentsJoinedByString:@"/"]; 
		NSString *path = [rootdir stringByAppendingPathComponent:filePath];
		[paths addObject:path];
		//NSLog(@"path: %@", path);
	}
	return [paths allObjects];
}

- (id)init {
	if (self = [super init]){
		[self setAttributeValues:[NSMutableArray arrayWithObject:[DCMAbstractSyntaxUID mediaStorageDirectoryStorage]] forName:@"MediaStorageSOPClassUID"];	

		[self newSOPInstanceUID];
		[[self attributes] removeObjectForKey:@"0008,0018"];
		[self setAttributeValues:[NSMutableArray arrayWithObject:@"OSIRIX_CD"] forName:@"FileSetID"];
		[self setAttributeValues:[NSMutableArray array] forName:@"OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity"];
		[self setAttributeValues:[NSMutableArray array] forName:@"OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity"];	
		[self setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:0x0000]] forName:@"FileSetConsistencyFlag"];
		//[self setAttributeValues:[NSMutableArray arrayWithObject:@"ISO_IR 100"] forName:@"SpecificCharacterSet"];
		[self updateMetaInformationWithTransferSyntax: [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] aet:nil];
		
		DCMDataContainer *container = [DCMDataContainer dataContainer];
		[self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:[DCMTransferSyntax  ExplicitVRLittleEndianTransferSyntax]
			quality:DCMLosslessQuality 
			asDICOM3:NO
			AET:nil
			strippingGroupLengthLength:NO];
		NSLog(@"%@ \n Length: %d", [self description], [[container dicomData] length]);
		
		
		root = [[DCMRootRecord rootRecord] retain];
	}
	return self;
}

- (id)initWithDICOMDIR:(NSString *)dicomdir{
	 if (self = [super initWithContentsOfFile:(NSString *)dicomdir decodingPixelData:NO]) {
		
		DCMSequenceAttribute *recordSequenceAttr = [self attributeValueWithName:@"DirectoryRecordSequence"] ;
		NSArray *recordSequence = [recordSequenceAttr sequenceItems];		
		root = [[DCMRootRecord rootRecordWithRecordSequence:(NSArray *)recordSequence] retain];

			
	 }
	 return self;
}

- (void)dealloc{
	[root release];
	[dirPath release];
	[super dealloc];
}




- (void)addObjectAtPath:(NSString *)path{
	DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:path decodingPixelData:NO];
	// add object if DICOM
	if (dcmObject)
		[root addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path];
}
	
- (void)buildSequence{	
	NSArray *array = [root allItems];
	for ( DCMRecord *record in array )
		[record relativeFilePathForDICOMDIR:dirPath];
	int startingOffset = 128; 
	
	DCMDataContainer *container = [DCMDataContainer dataContainer];
	[self writeToDataContainer:(DCMDataContainer *)container 
			withTransferSyntax:[DCMTransferSyntax  ExplicitVRLittleEndianTransferSyntax]
			quality:DCMLosslessQuality 
			asDICOM3:YES
			AET:nil
			strippingGroupLengthLength:NO];
	startingOffset = [[container dicomData] length] + 20;
	NSLog(@"offset: %d", startingOffset);

	[root setOffsets:startingOffset];
	int firstOffset = [[[root children] objectAtIndex:0] offset];
	int lastOffset = [[[root children] lastObject] offset];
	[self addAttributeValue:[NSNumber numberWithInt:firstOffset] forName:@"OffsetOfTheFirstDirectoryRecordOfTheRootDirectoryEntity"];
	[self addAttributeValue:[NSNumber numberWithInt:lastOffset] forName:@"OffsetOfTheLastDirectoryRecordOfTheRootDirectoryEntity"];
	
	DCMAttributeTag *tag = [DCMAttributeTag  tagWithName:@"DirectoryRecordSequence"];
	DCMSequenceAttribute *attr = [[[DCMSequenceAttribute alloc] initWithAttributeTag:(DCMAttributeTag *)tag] autorelease];
	[self setAttribute:attr];
	for ( DCMRecord *record in array ) {
		[attr addItem:[record item]  offset:[record offset]];
	}
	//NSLog(@"Dicomdir \n%@", [self description]);
	NSLog(@"build sequence");
	
}



- (BOOL)writeToFile:(NSString *)path {
	dirPath = [path retain];
	[self buildSequence];
	DCMDataContainer *container = [[[DCMDataContainer alloc] init] autorelease];
	//if ([self  writeToDataContainer:container withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality asDICOM3:YES])
	if ([self writeToDataContainer:(DCMDataContainer *)container 
				withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]
				quality:DCMLosslessQuality
				asDICOM3:YES
				AET:nil
				strippingGroupLengthLength:YES]) 
		return [[container  dicomData] writeToFile:path atomically:YES];
	return NO;
}

@end
