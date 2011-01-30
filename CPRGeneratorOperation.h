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

@class CPRGeneratorRequest;
@class CPRVolumeData;

@interface CPRGeneratorOperation : NSOperation {
    CPRVolumeData *_volumeData;
    CPRGeneratorRequest *_request;
    CPRVolumeData *_generatedVolume;
}

- (id)initWithRequest:(CPRGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

@property (readonly) CPRGeneratorRequest *request;
@property (readonly) CPRVolumeData *volumeData;
@property (readonly) BOOL didFail;
@property (readwrite, retain) CPRVolumeData *generatedVolume;

@end

