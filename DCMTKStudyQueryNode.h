/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "DCMTKQueryNode.h"

/** \brief Study level DCMTKQueryNode */
@interface DCMTKStudyQueryNode : DCMTKQueryNode {
    BOOL _sortChildren;
}

- (NSString*) studyInstanceUID;// Match DicomStudy
- (NSString*) studyName;// Match DicomStudy
- (NSNumber*) numberOfImages;// Match DicomStudy
- (NSDate*) dateOfBirth; // Match DicomStudy
- (NSNumber*) noFiles; // Match DicomStudy
@end
