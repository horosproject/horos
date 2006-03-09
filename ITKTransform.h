//
//  ITKTransform.h
//  OsiriX
//
//  Created by joris on 08/03/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#import "ITK.h"
#else
@class ITK;
#endif

#import "ViewerController.h"

@interface ITKTransform : NSObject {
	ITK						*itkImage;
	ViewerController		*originalViewer, *resultViewer;
}

- (id) initWithViewer: (ViewerController *) viewer;
- (void) computeAffineTransformWithRotation: (double*)aRotation translation: (double*)aTranslation resampleOnViewer:(ViewerController*)referenceViewer;
- (void) computeAffineTransformWithParameters: (double*)theParameters resampleOnViewer:(ViewerController*)referenceViewer;
- (void) createNewViewerWithBuffer:(float*)aBuffer resampleOnViewer:(ViewerController*)referenceViewer;

@end
