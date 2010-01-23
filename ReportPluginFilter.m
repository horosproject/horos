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

#import "ReportPluginFilter.h"


@implementation ReportPluginFilter

- (BOOL)createReportForStudy:(id)study{
	return NO;
}
- (BOOL)deleteReportForStudy:(id)study{
	return NO;
}
- (NSDate *)reportDateForStudy:(id)study{
	return nil;
}

@end
