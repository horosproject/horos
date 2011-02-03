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

enum _CPRProjectionMode {
    CPRProjectionModeVR, // don't use this, it is not implemented
    CPRProjectionModeMIP,
    CPRProjectionModeMinIP,
    CPRProjectionModeMean,
	
	CPRProjectionModeNone = 0xFFFFFF,
};
typedef NSInteger CPRProjectionMode;

@class CPRVolumeData;

// give this operation a volumeData at the start, when the operation is finished, if everything went well, generated volume will be the projection through the Z (depth) direction

@interface CPRProjectionOperation : NSOperation {
    CPRVolumeData *_volumeData;
    CPRVolumeData *_generatedVolume;
    
    CPRProjectionMode _projectionMode;
}

@property (nonatomic, readwrite, retain) CPRVolumeData *volumeData;
@property (nonatomic, readonly, retain) CPRVolumeData *generatedVolume;

@property (nonatomic, readwrite, assign) CPRProjectionMode projectionMode;

@end
