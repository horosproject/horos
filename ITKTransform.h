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

#ifdef __cplusplus
#import "ITK.h"
#else
@class ITK;
#endif

#import "ViewerController.h"
#import "DCMPix.h"

/** /brief  ITK based affine transform */

@interface ITKTransform : NSObject {
	ITK						*itkImage;
	ViewerController		*originalViewer, *resultViewer;
}

- (id) initWithViewer: (ViewerController *) viewer;
- (ViewerController*) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer;
- (ViewerController*) createNewViewerWithBuffer:(float*)aBuffer length: (long) length resampleOnViewer:(ViewerController*)referenceViewer;

+ (float*) resampleWithParameters: (double*)theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*)  firstObjectOriginal noOfImages: (int) noOfImages length: (long*) length itkImage: (ITK*) itkImage;
+ (float*) reorient2Dimage: (double*) theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*) firstObjectOriginal length: (long*) length;

@end
