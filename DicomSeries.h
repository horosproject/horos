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
#import "DicomSeries.h"

/** \brief  Core Data Entity for a Series */

@interface DicomSeries : NSManagedObject
{
	NSNumber	*dicomTime;
	
//	BOOL		mxOffset;
//	BOOL		myOffset;
//	BOOL		mscale;
//	BOOL		mrotationAngle;
//	BOOL		mdisplayStyle;
//	BOOL		mwindowLevel;
//	BOOL		mwindowWidth;
//	BOOL		myFlipped, mxFlipped;
//	
//	NSNumber	*xOffset;
//	NSNumber	*yOffset;
//	NSNumber	*scale;
//	NSNumber	*rotationAngle;
//	NSNumber	*displayStyle;
//	NSNumber	*windowLevel;
//	NSNumber	*windowWidth;
//	NSNumber	*yFlipped, *xFlipped;
}

- (NSSet *)paths;
- (NSSet *)keyImages;
- (NSArray *)sortedImages;
- (NSString *)dicomSeriesInstanceUID;
- (NSDictionary *)dictionary;
- (NSComparisonResult)compareName:(DicomSeries*)series;

@end
