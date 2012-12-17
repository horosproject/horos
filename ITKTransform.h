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

@class ViewerController;
@class DCMPix;


#ifdef __cplusplus
#import "ITK.h"
#else
@class ITK;
#endif

#ifdef id
#define redefineID
#undef id
#endif


/** /brief  ITK based affine transform */

@interface ITKTransform : NSObject {
	ITK						*itkImage;
	ViewerController		*originalViewer, *resultViewer;
}

- (id) initWithViewer: (ViewerController *) viewer;
- (ViewerController*) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer;
- (ViewerController*) createNewViewerWithBuffer:(float*)aBuffer length: (long) length resampleOnViewer:(ViewerController*)referenceViewer;
- (ViewerController*) createNewViewerWithBuffer:(float*)fVolumePtr length: (long) length resampleOnViewer:(ViewerController*)referenceViewer rescale: (BOOL) rescale;

+ (float*) resampleWithParameters: (double*)theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*)  firstObjectOriginal noOfImages: (int) noOfImages length: (long*) length itkImage: (ITK*) itkImage;
+ (float*) resampleWithParameters: (double*)theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*)  firstObjectOriginal noOfImages: (int) noOfImages length: (long*) length itkImage: (ITK*) itkImage rescale: (BOOL) rescale;
+ (float*) reorient2Dimage: (double*) theParameters firstObject: (DCMPix*) firstObject firstObjectOriginal: (DCMPix*) firstObjectOriginal length: (long*) length;

#ifdef redefineID
#define id Id
#undef redefineID
#endif

@end
