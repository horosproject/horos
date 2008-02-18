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
#import "ViewerController.h"
#import "DCMView.h"
#import "DCMPix.h"

enum
{
	eCurrentImage = 0,
	eKeyImages = 1,
	eAllImages = 2,
};

struct rawData
{
	unsigned char *imageData;
	long bytesWritten;
};


/** \brief Creates DICOM print images */
@interface AYNSImageToDicom : NSObject
{
	NSMutableData	*m_ImageDataBytes;
}

- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath options: (NSDictionary*) options asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;
- (NSArray *) dicomFileListForViewer: (ViewerController *) currentViewer destinationPath: (NSString *) destPath fileList: (NSArray *) fileList asColorPrint: (BOOL) colorPrint withAnnotations: (BOOL) annotations;

@end
