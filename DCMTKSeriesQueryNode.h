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
#import "DCMTKStudyQueryNode.h"

/** \brief Series level DCMTKQueryNode */
@interface DCMTKSeriesQueryNode : DCMTKQueryNode
{
	NSString *_studyInstanceUID;
    DCMTKStudyQueryNode *study;
}

@property (assign) DCMTKStudyQueryNode *study;

- (NSString*) studyInstanceUID;
- (NSString*) seriesInstanceUID;

@end
