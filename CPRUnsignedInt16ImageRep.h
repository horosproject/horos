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


@interface CPRUnsignedInt16ImageRep : NSImageRep {
    uint16_t *_unsignedInt16Data;
    
    CGFloat _offset;
    CGFloat _slope;
    
    CGFloat _windowWidth;
    CGFloat _windowLevel;
    CGFloat _pixelSpacingX;
    CGFloat _pixelSpacingY;
    CGFloat _sliceThickness;
    
    BOOL _freeWhenDone;
}

@property (nonatomic, readwrite, assign) CGFloat windowWidth; // these will affect how this rep will draw when part of an NSImage
@property (nonatomic, readwrite, assign) CGFloat windowLevel;


- (id)initWithData:(uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh;

- (uint16_t *)unsignedInt16Data;
@property (nonatomic, readwrite, assign) CGFloat offset;
@property (nonatomic, readwrite, assign) CGFloat slope;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingX;
@property (nonatomic, readwrite, assign) CGFloat pixelSpacingY;
@property (nonatomic, readwrite, assign) CGFloat sliceThickness;

@end
