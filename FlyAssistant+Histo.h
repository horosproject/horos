//
//  FlyAssistant+Histo.h
//  OsiriX_Lion
//
//  Created by Benoit Deville on 24.05.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "FlyAssistant.h"
#import <vector>

@interface FlyAssistant (Histo)

/**
 Automatically compute the thresholds min and max dependt
 */
- (void) autoComputeThresholdFromValue:(float)v;
- (void) autoComputeThresholdFromPoint:(Point3D*)p;
- (void) computeIntervalThresholdsFrom:(float)pixValue;

/**
 Get the min and max values from input data
 */
- (void) getInputMinMaxValues;

/**
 Compute the greylevel histogram of input data
 */
- (void) computeSimpleHistogram:(std::vector<int> &)histo;

///**
// Compute the greylevel cumulative histogram of input data
// */
//- (void) computeCumulative:(std::vector<int> &)histo;
//
///**
// Compute cumulative histogram from simple histogram.
// Needs the simple histogram.
// */
//- (void) computeCumulativeHistogram:(std::vector<int> &)cumul FromSimpleHistogram:(const std::vector<int> &)histo;
//
///**
// Compute both simple and cumulative histogram
// */
//- (void) computeSimpleHistogram:(std::vector<int> &)histo AndCumulative:(std::vector<int> &)cumul;

/**
 Smooth histogram according to window w
 */
- (void) smooth:(std::vector<int> &)histo withWindow:(const unsigned int)w;

- (void) smoothHistogramWith:(const unsigned int)window;

/**
 Get interval containing peak around value
 */
- (void) determineThresholdIntervalFrom:(int)value On:(const std::vector<int> &)histo WithStep:(const int)delta;

/**
 Roughly find local minima given start, histogram, and step size
 */
- (int) getLocalMinimaFrom:(int)x OnHistogram:(const std::vector<int> &)h WithStep:(const int)delta;

/**
 Roughly find local maxima given start, histogram, and step size
 */
- (int) getLocalMaximaFrom:(int)x OnHistogram:(const std::vector<int> &)h WithStep:(const int)delta;

/**
 Roughly find local minima on histogram given step size and starting value
 */
- (int) getLocalMinimaWith:(const int)step from:(vImagePixelCount)value;

/**
 Roughly find local maxima on histogram given step size and starting value
 */
- (int) getLocalMaximaWith:(const int)step from:(vImagePixelCount)value;

- (void) medianFilter:(vImage_Buffer *) buffer;
- (void) mmOpening : (vImage_Buffer *) buffer :(vImagePixelCount) x : (vImagePixelCount) y;
- (void) mmClosing : (vImage_Buffer *) buffer :(vImagePixelCount) x : (vImagePixelCount) y;
- (void) mmErosion : (vImage_Buffer *) buffer :(vImagePixelCount) x : (vImagePixelCount) y;
- (void) mmDilation: (vImage_Buffer *) buffer :(vImagePixelCount) x : (vImagePixelCount) y;

@end
