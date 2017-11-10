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
#import "DCMPix.h"
#import "DCMView.h"

@interface LLSubtraction : NSObject {

}

+ (void)subtractBuffer:(float*)bufferB to:(float*)bufferA withWidth:(long)width height:(long)height minValueA:(int)minA maxValueA:(int)maxA minValueB:(int)minB maxValueB:(int)maxB minValueSubtraction:(int)minS maxValueSubtraction:(int)maxS displayBones:(BOOL)displayBones bonesThreshold:(int)bonesThreshold;
+ (void)subtractBuffer:(float*)bufferB to:(float*)bufferA withWidth:(long)width height:(long)height;
+ (void)subtractDCMPix:(DCMPix*)pixB to:(DCMPix*)pixA minValueA:(int)minA maxValueA:(int)maxA minValueB:(int)minB maxValueB:(int)maxB minValueSubtraction:(int)minS maxValueSubtraction:(int)maxS displayBones:(BOOL)displayBones bonesThreshold:(int)bonesThreshold;
+ (void)subtractDCMPix:(DCMPix*)pixB to:(DCMPix*)pixA;
+ (void)subtractDCMView:(DCMView*)viewB to:(DCMView*)viewA;

+ (void)removeSmallConnectedPartInBuffer:(float*)buffer withWidth:(long)width height:(long)height;
+ (void)removeSmallConnectedPartDCMPix:(DCMPix*)pix;

+ (void)erodeBuffer:(unsigned char*)buffer withWidth:(int)width height:(int)height structuringElementRadius:(int)structuringElementRadius;
+ (void)dilateBuffer:(unsigned char*)buffer withWidth:(int)width height:(int)height structuringElementRadius:(int)structuringElementRadius;
+ (void)erode:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;
+ (void)dilate:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;
+ (void)close:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;

+ (void)lowPassFilterOnBuffer:(float*)buffer withWidth:(int)width height:(int)height structuringElementSize:(int)structuringElementSize;
+ (void)convolveBuffer:(float*)buffer withWidth:(int)width height:(int)height withKernel:(float*)kernel kernelSize:(int)kernelSize;

@end
