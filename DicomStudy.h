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
#import "DicomStudy.h"

/** \brief  Core Data Entity for a Study */
@interface DicomStudy : NSManagedObject
{
	BOOL		isHidden;
	NSNumber	*dicomTime;
}

- (NSNumber *) noFiles;
- (NSSet *) paths;
- (NSSet *) keyImages;
- (NSArray *)imageSeries;
- (NSArray *)reportSeries;
- (NSArray *)structuredReports;
- (NSArray *)keyObjectSeries;
- (NSArray *)keyObjects;
- (NSArray *)presentationStateSeries;
- (NSArray *)waveFormSeries;
- (NSManagedObject *)roiSRSeries;
- (NSDictionary *)dictionary;
- (BOOL) isHidden;
- (void) setHidden: (BOOL) h;

- (NSComparisonResult)compareName:(DicomStudy*)study;

@end
