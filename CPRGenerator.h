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

@protocol CPRGeneratorDelegate;

@interface CPRGenerator : NSObject {
    NSOperationQueue *_generatorQueue;
    NSMutableSet *_observedOperations;
    NSMutableArray *_finishedOperations;
    id <CPRGeneratorDelegate> _delegate;
    
    NSMutableArray *_generatedFrameTimes;
    
    CPRVolumeData *_volumeData;
}

@property (nonatomic, readwrite, assign) id <CPRGeneratorDelegate> delegate;
@property (readonly) CPRVolumeData *volumeData;

+ (CPRVolumeData *)synchronousRequestVolume:(CPRGeneratorRequest *)request volumeData:(CPRVolumeData *)volumeData;

- (id)initWithVolumeData:(CPRVolumeData *)volumeData;

- (void)requestVolume:(CPRGeneratorRequest *)request;

- (void)runUntilAllRequestsAreFinished; // must be called on the main thread. Delegate callbacks will happen, but this method will not return until all outstanding requests have been processed

- (CGFloat)frameRate;

@end


@protocol CPRGeneratorDelegate <NSObject>
@required
- (void)generator:(CPRGenerator *)generator didGenerateVolume:(CPRVolumeData *)volume request:(CPRGeneratorRequest *)request;
@optional
- (void)generator:(CPRGenerator *)generator didAbandonRequest:(CPRGeneratorRequest *)request;
@end



