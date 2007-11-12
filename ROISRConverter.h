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
/** \brief Converts between SR and ROI */
@interface ROISRConverter : NSObject

/** Extracts ROI as NSData from a DICOM SR
* @param path File path
*/
+ (NSData *) roiFromDICOM:(NSString *)path;

/** Creates a DICOM SR from an array of ROIs
* @param rois Array of ROI to archive
* @param path Path to file 
* @param image the image related to the ROI array
*/
+ (NSString*) archiveROIsAsDICOM:(NSArray *)rois toPath:(NSString *)path  forImage:(id)image;

@end
