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
#import "DicomStudy.h"


@interface DicomStudy : NSManagedObject
{
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


@end
