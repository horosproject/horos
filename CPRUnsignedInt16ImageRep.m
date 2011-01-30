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

#import "CPRUnsignedInt16ImageRep.h"


@implementation CPRUnsignedInt16ImageRep

@synthesize windowWidth = _windowWidth;
@synthesize windowLevel = _windowLevel;

@synthesize offset = _offset;
@synthesize slope = _slope;
@synthesize pixelSpacingX = _pixelSpacingX;
@synthesize pixelSpacingY = _pixelSpacingY;
@synthesize sliceThickness = _sliceThickness;

- (id)initWithData:(uint16_t *)data pixelsWide:(NSUInteger)pixelsWide pixelsHigh:(NSUInteger)pixelsHigh
{
    if ( (self = [super init]) ) {
        if (data == NULL) {
            _unsignedInt16Data = malloc(sizeof(uint16_t) * pixelsWide * pixelsHigh);
            _freeWhenDone = YES;
            if (_unsignedInt16Data == NULL) {
                [self release];
                return nil;
            }
        } else {
            _unsignedInt16Data = data;
        }
        
        [self setPixelsWide:pixelsWide];
        [self setPixelsHigh:pixelsHigh];
        [self setSize:NSMakeSize(pixelsWide, pixelsHigh)];
        _offset = 0;
        _slope = 1;
    }
    
    return self;
}

- (void)dealloc
{
    if (_freeWhenDone) {
        free(_unsignedInt16Data);
    }
    
    [super dealloc];
}

-(BOOL)draw
{
    assert(false); // one day it would be cool if this could actually be used as an image rep in an NSImage
    return NO;
}

- (uint16_t *)unsignedInt16Data
{
    return _unsignedInt16Data;
}

@end
