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
#import "DCMPix.h"

#import "Schedulable.h"
#import "Scheduler.h"
#import "StaticScheduler.h"

/** \brief Reslcie volume sagittally and Coronally */

@interface OrthogonalReslice : NSObject  <Schedulable> {
	NSMutableArray		*originalDCMPixList, *xReslicedDCMPixList, *yReslicedDCMPixList;
	NSMutableArray		*newPixListX, *newPixListY;
	short				thickSlab;
	float				sign;
	
	BOOL				useYcache;
	float				*Ycache;
	
	NSConditionLock		*resliceLock;
	
	long				minI, maxI, newX, newY, newTotal, currentAxe;
	DCMPix				*firstPix;
	
	NSLock				*processorsLock, *yCacheComputation;
	volatile int		numberOfThreadsForCompute;
}

// init
- (id) initWithOriginalDCMPixList: (NSMutableArray*) pixList;
- (void) setOriginalDCMPixList: (NSMutableArray*) pixList;

// processors
- (void) reslice: (long) x: (long) y;
- (void) xReslice: (long) x;
- (void) yReslice: (long) y;

- (void) axeReslice: (short) axe : (long) sliceNumber;

// accessors
- (NSMutableArray*) originalDCMPixList;
- (NSMutableArray*) xReslicedDCMPixList;
- (NSMutableArray*) yReslicedDCMPixList;

// thickSlab
- (short) thickSlab;
- (void) setThickSlab : (short) newThickSlab;

- (void) flipVolume;
- (void)freeYCache;

- (BOOL)useYcache;
- (void)setUseYcache:(BOOL)boo;

@end
