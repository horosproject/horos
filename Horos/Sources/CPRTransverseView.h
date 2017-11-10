/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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

#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "CPRMPRDCMView.h"

enum _CPRTransverseViewReformationDisplayStyle { 
    CPRTransverseViewStraightenedReformationDisplayStyle = 0,
    CPRTransverseViewStretchedReformationDisplayStyle = 1,
};
typedef NSInteger CPRTransverseViewReformationDisplayStyle;

// horrible name! rename me!
enum _CPRTransverseViewSectionType { 
    CPRTransverseViewNoneSectionType = -1,
    CPRTransverseViewCenterSectionType = 0,
    CPRTransverseViewLeftSectionType,
    CPRTransverseViewRightSectionType
};
typedef NSInteger CPRTransverseViewSection;

@class CPRCurvedPath;
@class CPRDisplayInfo;
@class CPRVolumeData;
@class CPRObliqueSliceGeneratorRequest;
@class StringTexture;

@interface CPRTransverseView : DCMView {
    id<CPRViewDelegate> _delegate;

    CPRCurvedPath *_curvedPath;
    CPRDisplayInfo *_displayInfo;
    CPRTransverseViewSection _sectionType;
    CGFloat _sectionWidth;
    
    CPRVolumeData *_volumeData;
    CPRVolumeData *_generatedVolumeData;
    
    CPRObliqueSliceGeneratorRequest *_lastRequest;
    BOOL _processingRequest;
    BOOL _needsNewRequest;
	
	BOOL displayCrossLines;
	CPRTransverseViewReformationDisplayStyle _reformationDisplayStyle;
    
	CGFloat _renderingScale;
	
	float previousScale;
	
	NSMutableDictionary *stanStringAttrib;
	StringTexture *stringTex;
}

@property (nonatomic, readwrite, assign) id<CPRViewDelegate> delegate;
@property (nonatomic, readwrite, copy) CPRCurvedPath* curvedPath;
@property (nonatomic, readwrite, copy) CPRDisplayInfo *displayInfo;
@property (nonatomic, readwrite, assign) CPRTransverseViewSection sectionType;
@property (nonatomic, readwrite, assign) CGFloat sectionWidth; // the width to be displayed in mm
@property (nonatomic, readwrite, retain) CPRVolumeData *volumeData;
@property (nonatomic, readwrite, assign) CGFloat renderingScale;
@property (nonatomic, readwrite, assign) BOOL displayCrossLines;

@property (nonatomic, readwrite, assign) CPRTransverseViewReformationDisplayStyle reformationDisplayStyle;

- (float) pixelsPerMm;

- (void)_setNeedsNewRequest;

@end
