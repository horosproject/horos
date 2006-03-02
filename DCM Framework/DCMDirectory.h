//
//  DCMDirectory.h
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
#import "DCMObject.h"

@class DCMRecord;
@interface DCMDirectory : DCMObject {
	DCMRecord *root;
	NSString *dirPath;
}

+ (id)directory;
+ (id)directoryWithDICOMDIR:(NSString *)dicomdir;
+ (id)filePathsFromDICOMDIR:(NSString *)dicomdir;
- (id)initWithDICOMDIR:(NSString *)dicomdir;
- (DCMRecord *)root;
- (void)addObjectAtPath:(NSString *)path;
- (void)buildSequence;
- (BOOL)writeToFile:(NSString *)path;





@end
