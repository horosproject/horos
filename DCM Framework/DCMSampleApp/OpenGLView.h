//
//  OpenGLView.h
//  DCMSampleApp
//
//  Created by Lance Pysher on Tue Aug 03 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Accelerate/Accelerate.h>

@class DCMObject;
@interface OpenGLView : NSOpenGLView {
	DCMObject *dcmObject;
	int width;
	int height;
	int pixelDepth;
	int spp;
}

- (void)setDDCMObject:(DCMObject *)object;
- (void)glErrorCheck;

@end
