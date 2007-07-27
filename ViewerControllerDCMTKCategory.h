//
//  ViewerControllerDCMTK Category.h
//  OsiriX
//
//  Created by Lance Pysher on 10/18/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"


@interface ViewerController (ViewerControllerDCMTKCategory)

- (NSData *)roiFromDICOM:(NSString *)path;
- (NSString*) archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path  forImage:(id)image;
@end
