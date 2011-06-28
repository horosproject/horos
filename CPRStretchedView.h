//
//  CPRStraightenedView.h
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/4/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "CPRMPRDCMView.h"
#import "CPRGenerator.h"
#import "CPRProjectionOperation.h"

@class CPRVolumeData;
@class CPRCurvedPath;
@class CPRDisplayInfo;
@class CPRStretchedGeneratorRequest;
@class StringTexture;
@class N3BezierPath;

@interface CPRStretchedView : DCMView <CPRGeneratorDelegate> {
    id<CPRViewDelegate> _delegate;
    
    CPRVolumeData *_volumeData;
    CPRGenerator *_generator;
    
    CPRCurvedPath *_curvedPath;
    CPRDisplayInfo *_displayInfo;
	    
    CPRViewClippingRangeMode _clippingRangeMode;
    
    CPRVolumeData *_curvedVolumeData;
    
    CPRStretchedGeneratorRequest *_lastRequest;
    CGFloat _generatedHeight;

    NSInteger _editingCurvedPathCount;
    
    BOOL _processingRequest; // synchronous new image requests are generated in drawRect, but code that handles the new image calls' setNeedsDisplay,
                            // so this variable is used to short circuit setNeedsDisplay while the image is being generated.
    BOOL _needsNewRequest;
    
    N3BezierPath *_centerlinePath;
    CGFloat _centerlineProjectedLength;
}

@property (nonatomic, readwrite, assign) id<CPRViewDelegate> delegate;

@property (nonatomic, readwrite, retain) CPRVolumeData *volumeData; // the volume data of the original data
@property (nonatomic, readwrite, copy) CPRCurvedPath *curvedPath;
@property (nonatomic, readwrite, copy) CPRDisplayInfo *displayInfo;
@property (nonatomic, readwrite, assign) CPRViewClippingRangeMode clippingRangeMode;

@property (nonatomic, readonly, retain) CPRVolumeData *curvedVolumeData; // the volume data that was generated
@property (nonatomic, readonly, assign) CGFloat generatedHeight; // height of the image that is generated in mm. kinda hack sends CPRViewDidChangeGeneratedHeight to the delegate when this value changes

- (void)waitUntilPixUpdate; // returns once this view's DCM pix object has been updated to reflect any changes made to the view. 


@end

