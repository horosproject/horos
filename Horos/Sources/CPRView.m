/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
//
//  CPRView.m
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/5/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "CPRView.h"
#import "CPRStraightenedView.h"
#import "CPRStretchedView.h"

@implementation CPRView

@synthesize reformationType = _reformationType;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _straightenedView = [[CPRStraightenedView alloc] initWithFrame:[self bounds]];
        _stretchedView = [[CPRStretchedView alloc] initWithFrame:[self bounds]];

        [self addSubview:_straightenedView];
    }
    return self;
}

- (void)dealloc
{
    [_straightenedView release];
    _straightenedView = nil;
    [_stretchedView release];
    _stretchedView = nil;
    
    [super dealloc];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    
    NSDisableScreenUpdates();
    [_straightenedView setFrame:[self bounds]];
    [_stretchedView setFrame:[self bounds]];
    
    NSEnableScreenUpdates();
}

- (void)setReformationType:(CPRViewReformationType)reformationType
{
    assert(reformationType == CPRViewStraightenedReformationType || reformationType == CPRViewStretchedReformationType);
    
    if (reformationType != _reformationType) {
        if (_reformationType == CPRViewStraightenedReformationType) { // going from straightened to stretched
            [_straightenedView removeFromSuperview];
            _stretchedView.curvedPath = _straightenedView.curvedPath;
            _stretchedView.displayInfo = _straightenedView.displayInfo;
            [self addSubview:_stretchedView];
        } else {
            [_stretchedView removeFromSuperview];
            _straightenedView.curvedPath = _stretchedView.curvedPath;
            _straightenedView.displayInfo = _stretchedView.displayInfo;
            [self addSubview:_straightenedView];
        }
        _reformationType = reformationType;
    }
}

- (id)reformationView // returns the actual view that does the reformation. I expect hacky calls that do and do screen grabs and such will need this
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return _straightenedView;
    } else
    {
        return _stretchedView;
    }
}

- (void) _setNeedsNewRequest
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        [self->_straightenedView _setNeedsNewRequest];
    }
    else
    {
        [self->_stretchedView _setNeedsNewRequest];
    }
}

- (void)waitUntilPixUpdate // returns once the reformation view's DCM pix object has been updated to reflect any changes made to the view.
{
    [[self reformationView] waitUntilPixUpdate];
}


#pragma mark DCMView-like methods

- (void)setWLWW:(float)wl :(float) ww
{
    [_straightenedView setWLWW:wl :ww];
    [_stretchedView setWLWW:wl :ww];
}

- (void)getWLWW:(float*)wl :(float*)ww
{
    [[self reformationView] getWLWW:wl :ww];
}

- (void)setCLUT:(unsigned char*)r :(unsigned char*)g :(unsigned char*)b
{
    [_straightenedView setCLUT:r :g :b];
    [_stretchedView setCLUT:r :g :b];
}

- (DCMPix *)curDCM
{
    return [[self reformationView] curDCM];
}

- (short)curImage
{
    return [[self reformationView] curImage];
}

- (void)setIndex:(short)index
{
    [_straightenedView setIndex:index];
    [_stretchedView setIndex:index];
}

-(void)setCurrentTool:(ToolMode)i
{
    [_straightenedView setCurrentTool:i];
    [_stretchedView setCurrentTool:i];
}

-(NSImage*) nsimage
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView nsimage];
    } else {
        return [_stretchedView nsimage];
    }
}

-(NSImage*) nsimage:(BOOL) bo
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView nsimage: bo];
    } else {
        return [_stretchedView nsimage: bo];
    }
}

-(NSImage*) nsimage:(BOOL) bo allViewers: (BOOL) all
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView nsimage: bo allViewers: all];
    } else {
        return [_stretchedView nsimage: bo allViewers: all];
    }
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView getRawPixels: width : height : spp : bpp : screenCapture : force8bits];
    } else {
        return [_stretchedView getRawPixels: width : height : spp : bpp : screenCapture : force8bits];
    }
}

- (unsigned char*) getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView getRawPixelsWidth: width height: height spp: spp bpp: bpp screenCapture: screenCapture force8bits: force8bits removeGraphical: removeGraphical squarePixels: squarePixels allTiles: allTiles allowSmartCropping: allowSmartCropping origin: imOrigin spacing: imSpacing];
    } else {
        return [_stretchedView getRawPixelsWidth: width height: height spp: spp bpp: bpp screenCapture: screenCapture force8bits: force8bits removeGraphical: removeGraphical squarePixels: squarePixels allTiles: allTiles allowSmartCropping: allowSmartCropping origin: imOrigin spacing: imSpacing];
    }
}

- (unsigned char*) getRawPixelsWidth:(long*) width height:(long*) height spp:(long*) spp bpp:(long*) bpp screenCapture:(BOOL) screenCapture force8bits:(BOOL) force8bits removeGraphical:(BOOL) removeGraphical squarePixels:(BOOL) squarePixels allTiles:(BOOL) allTiles allowSmartCropping:(BOOL) allowSmartCropping origin:(float*) imOrigin spacing:(float*) imSpacing offset:(int*) offset isSigned:(BOOL*) isSigned
{
    if (_reformationType == CPRViewStraightenedReformationType)
    {
        return [_straightenedView getRawPixelsWidth: width height: height spp: spp bpp: bpp screenCapture: screenCapture force8bits: force8bits removeGraphical: removeGraphical squarePixels: squarePixels allTiles: allTiles allowSmartCropping: allowSmartCropping origin: imOrigin spacing: imSpacing offset: offset isSigned: isSigned];
    } else {
        return [_stretchedView getRawPixelsWidth: width height: height spp: spp bpp: bpp screenCapture: screenCapture force8bits: force8bits removeGraphical: removeGraphical squarePixels: squarePixels allTiles: allTiles allowSmartCropping: allowSmartCropping origin: imOrigin spacing: imSpacing offset: offset isSigned: isSigned];
    }
}

#pragma mark standard CPRView Methods

- (id<CPRViewDelegate>)delegate
{
    return [[self reformationView] delegate];
}

- (void)setDelegate:(id <CPRViewDelegate>)delegate
{
    _straightenedView.delegate = delegate;
    _stretchedView.delegate = delegate;
}

- (CPRVolumeData *)volumeData
{
    return [(CPRStraightenedView *)[self reformationView] volumeData]; // cast to make sure the compiler picks the right return type for the method
}

- (void)setVolumeData:(CPRVolumeData *)volumeData
{
    _straightenedView.volumeData = volumeData;
    _stretchedView.volumeData = volumeData;
}

- (CPRCurvedPath *)curvedPath
{
    return [[self reformationView] curvedPath];
}

- (void)setCurvedPath:(CPRCurvedPath *)curvedPath
{
    _straightenedView.curvedPath = curvedPath;
    _stretchedView.curvedPath = curvedPath;
}

- (CPRDisplayInfo *)displayInfo
{
    return [[self reformationView] displayInfo];
}

- (void)setDisplayInfo:(CPRDisplayInfo *)displayInfo
{
    _straightenedView.displayInfo = displayInfo;
    _stretchedView.displayInfo = displayInfo;
}

- (CPRViewClippingRangeMode)clippingRangeMode
{
    return [[self reformationView] clippingRangeMode];
}

- (void)setClippingRangeMode:(CPRViewClippingRangeMode)clippingRangeMode
{
    _straightenedView.clippingRangeMode = clippingRangeMode;
    _stretchedView.clippingRangeMode = clippingRangeMode;
}

// BOGUS implementations until the stretched CPR View can handle these
- (N3Plane)orangePlane
{
    return [[self reformationView] orangePlane];
}

- (void)setOrangePlane:(N3Plane)orangePlane
{
    [_straightenedView setOrangePlane:orangePlane];
    [_stretchedView setOrangePlane:orangePlane];
}

- (N3Plane)purplePlane
{
    return [[self reformationView] purplePlane];
}

- (void)setPurplePlane:(N3Plane)purplePlane
{
    [_straightenedView setPurplePlane:purplePlane];
    [_stretchedView setPurplePlane:purplePlane];
}

- (N3Plane)bluePlane
{
    return [[self reformationView] bluePlane];
}

- (void)setBluePlane:(N3Plane)bluePlane
{
    [_straightenedView setBluePlane:bluePlane];
    [_stretchedView setBluePlane:bluePlane];
}


- (CGFloat)orangeSlabThickness
{
    return [[self reformationView] orangeSlabThickness];
}

- (void)setOrangeSlabThickness:(CGFloat)orangeSlabThickness
{
    [_straightenedView setOrangeSlabThickness:orangeSlabThickness];
    [_stretchedView setOrangeSlabThickness:orangeSlabThickness];
}

- (CGFloat)purpleSlabThickness
{
    return [[self reformationView] purpleSlabThickness];
}

- (void)setPurpleSlabThickness:(CGFloat)purpleSlabThickness
{
    [_straightenedView setPurpleSlabThickness:purpleSlabThickness];
    [_stretchedView setPurpleSlabThickness:purpleSlabThickness];
}

- (CGFloat)blueSlabThickness
{
    return [[self reformationView] blueSlabThickness];
}

- (void)setBlueSlabThickness:(CGFloat)blueSlabThickness
{
    [_straightenedView setBlueSlabThickness:blueSlabThickness];
    [_stretchedView setBlueSlabThickness:blueSlabThickness];
}


- (NSColor *)orangePlaneColor
{
    return [[self reformationView] orangePlaneColor];
}

- (void)setOrangePlaneColor:(NSColor *)orangePlaneColor
{
    [_straightenedView setOrangePlaneColor:orangePlaneColor];
    [_stretchedView setOrangePlaneColor:orangePlaneColor];
}

- (NSColor *)purplePlaneColor
{
    return [[self reformationView] purplePlaneColor];
}

- (void)setPurplePlaneColor:(NSColor *)purplePlaneColor
{
    [_straightenedView setPurplePlaneColor:purplePlaneColor];
    [_stretchedView setPurplePlaneColor:purplePlaneColor];
}

- (NSColor *)bluePlaneColor
{
    return [[self reformationView] bluePlaneColor];
}

- (void)setBluePlaneColor:(NSColor *)bluePlaneColor
{
    [_straightenedView setBluePlaneColor:bluePlaneColor];
    [_stretchedView setBluePlaneColor:bluePlaneColor];
}

- (CPRVolumeData *)curvedVolumeData
{
    return [[self reformationView] curvedVolumeData];
}

- (CGFloat)generatedHeight
{
    return [[self reformationView] generatedHeight];
}

- (BOOL)displayTransverseLines
{
    return _straightenedView.displayTransverseLines;
}

- (void)setDisplayTransverseLines:(BOOL)displayTransverseLines
{
    _straightenedView.displayTransverseLines = displayTransverseLines;
}

- (BOOL)displayCrossLines
{
    return [[self reformationView] displayCrossLines];
}

- (void)setDisplayCrossLines:(BOOL)displayCrossLines
{
    [_straightenedView setDisplayCrossLines:displayCrossLines];
    [_stretchedView setDisplayCrossLines:displayCrossLines];
}

- (void)setRotation: (float) rotation
{
    [_straightenedView setRotation: rotation];
    [_stretchedView setRotation: rotation];
}

- (float)rotation
{
    return [(DCMView *)[self reformationView] rotation];
}

- (void)setScaleValue: (float) scaleValue
{
    [_straightenedView setScaleValue: scaleValue];
    [_stretchedView setScaleValue: scaleValue];
}

- (float)scaleValue
{
    return [[self reformationView] scaleValue];
}
@end
