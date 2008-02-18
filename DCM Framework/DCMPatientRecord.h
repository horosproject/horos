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

@interface DCMPatientRecord : DCMRecord {
	NSString *patientID;
	NSString *patientsName;
}

+ (id)patientRecordWithDCMObject:(DCMObject *)dcmObject  atPath:(NSString *)path parent:(DCMRecord *)record;
+ (id)patientRecordWithRecordSequence:(NSArray *)recordSequence parent:(DCMRecord *)record;

@end
