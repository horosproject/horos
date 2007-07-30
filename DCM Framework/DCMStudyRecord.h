//
//  DCMStudyRecord.h
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

#import <Cocoa/Cocoa.h>
#import "DCMRecord.h"

@class DCMCalendarDate;

@interface DCMStudyRecord : DCMRecord {
	NSString *studyInstanceUID;
	NSString *studyID;
	NSString *studyDescription;
	DCMCalendarDate *studyDate;
	DCMCalendarDate *studyTime;
	NSString *accessionNumber;
}

+ (id)studyRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record;
+ (id)studyRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record;

@end
