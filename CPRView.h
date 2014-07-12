//
//  CPRView.h
//  OsiriX
//
//  Created by Joël Spaltenstein on 6/5/11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "N3Geometry.h"
#import "CPRMPRDCMView.h"

@class CPRStraightenedView;
@class CPRStretchedView;
@class CPRVolumeData;
@class CPRCurvedPath;
@class CPRDisplayInfo;
@class DCMPix;

@protocol CPRViewDelegate;

enum _CPRViewReformationType { 
    CPRViewStraightenedReformationType = 0,
    CPRViewStretchedReformationType = 1,
};
typedef NSInteger CPRViewReformationType;


@interface CPRView : NSView
{
    CPRViewReformationType _reformationType;
        
    CPRStraightenedView *_straightenedView;
    CPRStretchedView *_stretchedView;
}

@property (nonatomic, readwrite, assign) CPRViewReformationType reformationType;

- (id)reformationView; // returns the actual view that does the reformation. I expect hacky calls that do and do screen grabs and such will need this
- (void)waitUntilPixUpdate; // returns once the refomration view's DCM pix object has been updated to reflect any changes made to the view. 


// DCMView-like methods
- (void)setWLWW:(float)wl :(float) ww;
- (void)getWLWW:(float*)wl :(float*)ww;
- (void)setCLUT:(unsigned char*)r :(unsigned char*)g :(unsigned char*)b;
@property(readonly) DCMPix *curDCM;
@property(readonly) short curImage;
- (void)setIndex:(short)index;
- (void)setCurrentTool:(ToolMode)i;

// methods 

@property (nonatomic, readwrite, assign) id<CPRViewDelegate> delegate; // as an implementation detail, the sender that will call the delegate will actually be the reformation view

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

@property (nonatomic) BOOL displayTransverseLines;
@property (nonatomic, readwrite, assign) BOOL displayCrossLines;

@property (nonatomic, readwrite, assign) float rotation, scaleValue;


@end
