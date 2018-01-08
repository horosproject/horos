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

@end
