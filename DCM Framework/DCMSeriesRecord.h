//
//  DCMSeriesRecord.h
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

#import <Cocoa/Cocoa.h>
#import "DCMRecord.h"

@class  DCMCalendarDate;

@interface DCMSeriesRecord : DCMRecord {
	NSString *seriesInstanceUID;
	NSString *seriesNumber;
	NSString *seriesDescription;
	DCMCalendarDate *seriesDate;
	DCMCalendarDate *seriesTime;
	NSString *modality;

}

+ (id)seriesRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record;
+ (id)seriesRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record;

@end
