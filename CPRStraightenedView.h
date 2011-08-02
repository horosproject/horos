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
#import "DCMView.h"
#import "CPRMPRDCMView.h"
#import "CPRGenerator.h"
#import "CPRProjectionOperation.h"

@class CPRVolumeData;
@class CPRCurvedPath;
@class CPRDisplayInfo;
@class CPRStraightenedGeneratorRequest;
@class StringTexture;

@interface CPRStraightenedView : DCMView <CPRGeneratorDelegate>
{
    id<CPRViewDelegate> _delegate;
    
    CPRVolumeData *_volumeData;
    CPRGenerator *_generator;
    
    CPRCurvedPath *_curvedPath;
    CPRDisplayInfo *_displayInfo;
	
    NSMutableDictionary *_planes;
    NSMutableDictionary *_slabThicknesses;
    NSMutableDictionary *_verticalLines;
    NSMutableDictionary *_planeRuns;
    NSMutableDictionary *_planeColors;
    	
    CPRViewClippingRangeMode _clippingRangeMode;
    
    CPRVolumeData *_curvedVolumeData;
    
    CPRStraightenedGeneratorRequest *_lastRequest;
    CGFloat _generatedHeight;
    
    BOOL _draggingTransverse;
    BOOL _draggingTransverseSpacing;
	BOOL _clickedNode;
	NSMutableDictionary *_mousePlanePointsInPix; // The display info stores on what
	//	plane and where in 3D the mouse position dots are, but we want to cache where the dots should be drawn in this view.
	
	NSInteger _editingCurvedPathCount;
    
    BOOL _drawAllNodes;
    
    BOOL _processingRequest; // synchronous new image requests are generated in drawRect, but code that handles the new image calls' setNeedsDisplay,
                            // so this variable is used to short circuit setNeedsDisplay while the image is being generated.
    BOOL _needsNewRequest;
	
	BOOL _displayCrossLines;
	BOOL _displayTransverseLines;
	
	NSMutableDictionary *stanStringAttrib;
	StringTexture *stringTexA, *stringTexB, *stringTexC;
}

@property (nonatomic, readwrite, assign) id<CPRViewDelegate> delegate;

@property (nonatomic, readwrite, retain) CPRVolumeData *volumeData; // the volume data of the original data
@property (nonatomic, readwrite, copy) CPRCurvedPath *curvedPath;
@property (nonatomic, readwrite, copy) CPRDisplayInfo *displayInfo;
@property (nonatomic, readwrite, assign) CPRViewClippingRangeMode clippingRangeMode;

@property (nonatomic, readwrite, assign) N3Plane orangePlane; // set these to N3PlaneInvalid to keep the plane from appearing
@property (nonatomic, readwrite, assign) N3Plane purplePlane;
@property (nonatomic, readwrite, assign) N3Plane bluePlane;

@property (nonatomic, readwrite, assign) CGFloat orangeSlabThickness;
@property (nonatomic, readwrite, assign) CGFloat purpleSlabThickness;
@property (nonatomic, readwrite, assign) CGFloat blueSlabThickness;

@property (nonatomic, readwrite, retain) NSColor *orangePlaneColor;
@property (nonatomic, readwrite, retain) NSColor *purplePlaneColor;
@property (nonatomic, readwrite, retain) NSColor *bluePlaneColor;

@property (nonatomic, readonly, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readonly, assign) CGFloat generatedHeight; // height of the image that is generated in mm. kinda hack sends CPRViewDidChangeGeneratedHeight to the delegate when this value changes

@property (nonatomic, readwrite, assign) BOOL displayTransverseLines;
@property (nonatomic, readwrite, assign) BOOL displayCrossLines;

- (void)waitUntilPixUpdate; // returns once this view's DCM pix object has been updated to reflect any changes made to the view. 

@end





