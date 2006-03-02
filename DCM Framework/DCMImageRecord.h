//
//  DCMImageRecord.h
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


@class DCMCalendarDate;

@interface DCMImageRecord : DCMRecord {
	NSString *sopInstanceUID;
	NSString *instanceNumber;
	DCMCalendarDate *contentDate;
	DCMCalendarDate *contentTime;
	NSString *sopClassUID;
	NSString *transferSyntax;


}

+ (id)imageRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record;

@end
