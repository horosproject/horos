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

@interface DCMRecord : NSObject {
	DCMRecord *parent;
	NSString *uid;
	NSMutableSet *children;
	NSArray *sortedArray;
	DCMObject *dcmItem;
	NSNumber *offsetNextDirectoryRecord;
	NSNumber *offsetLowerLevelDirectory;
	int itemLength;
	NSNumber *lengthToNextObject;
	int offset;	
	NSString *filePath;
	NSMutableArray *pathArray;
	NSString *specificCharacterSet;

	
}
+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject parent:(DCMRecord *)record;
+ (NSString *)recordUIDForDCMObject:(DCMObject *)dcmObject;
+ (id)recordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record;
- (id)initWithDCMObject:(DCMObject *)dcmObject atPath:(NSString *)path parent:(DCMRecord *)record;
- (id)initWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record;
- (NSString *)uid;
- (BOOL)isLeaf;
- (int)numberOfChildren;
- (NSEnumerator *)childEnumerator;
- (NSEnumerator *)sortedChildEnumerator;
- (NSArray *)children;
- (void)addChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path;
- (void)newChildForDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path;
- (void)removeChild:(DCMRecord *)child;
- (id)childForUID:(NSString *)aUID;
- (id)sortValue;
- (int)recordLength;
- (int)childrenLength;
- (int)totalLength;
- (int)offset;

- (void)addOffsetTemplate:(DCMObject *)object;
- (void)addRecordType:(DCMObject *)object;
- (void)createBaseObject;
- (int)setOffsets:(int)startingOffset;
- (NSArray *)allItems;
- (DCMObject *)item;

- (void)relativeFilePathForDICOMDIR:(NSString *)dirPath;

- (BOOL)isLastObject;
- (void)parseRecordSequence:(NSArray *)recordSequence recordType:(NSString *)recordType;
//empty need to subclass 
- (void)subRecordWithSubSequence:(NSArray *)subSequence;



@end
