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

@interface ITKTransform : NSObject {
	ITK		*itkImage;
	DCMPix	*originalPix, *resultPix;
}

- (id) initWithDCMPix: (DCMPix *) pix;
- (void) computeAffineTransformWithRotation: (double*)aRotation translation: (double*)aTranslation;
- (void) computeAffineTransformWithParameters: (double*)theParameters;

@end
