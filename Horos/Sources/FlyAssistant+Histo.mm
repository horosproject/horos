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
//  FlyAssistant+Histo.mm
//  OsiriX_Lion
//
//  Created by Benoit Deville on 24.05.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "FlyAssistant+Histo.h"
#import <vector>
#import <iterator>
#import <Accelerate/Accelerate.h>
#import <QuartzCore/QuartzCore.h>
#import <iostream>

@implementation FlyAssistant (Histo)

- (void) autoComputeThresholdFromValue:(float)v;
{    
    [self getInputMinMaxValues];
    std::vector<int> histogram( (int)( inputMaxValue - inputMinValue ), 0 );
    
    [self computeSimpleHistogram:histogram];
    
    [self smooth:histogram withWindow:5];
    
    if( v == inputMinValue )
        v++;
    else if (v == histogram.size() - 1 - inputMinValue)
        v--;
    [self determineThresholdIntervalFrom:(int)v-inputMinValue On:histogram WithStep:10];
}

- (void) autoComputeThresholdFromPoint:(Point3D*)p
{
    int position = (int)p.z*inputWidth*inputHeight+(int)p.y*inputWidth+(int)p.x;
//    float pixVal = input[position];
    [self autoComputeThresholdFromValue:input[position]];
}

- (void) computeIntervalThresholdsFrom:(float)pixValue;
{
    if (!inputHisto) {
        [self computeHistogram];
        [self smoothHistogramWith:5]; // \todo{Trouver une meilleure définition ?}
    }
    
    const int delta = 10; // \todo{Trouver une meilleure définition ?}
    int value;
    if( pixValue == inputMinValue )
        value = delta << 1;
    else if ( pixValue == inputMaxValue )
        value = histoSize - ( delta << 1 );
    else  value = pixValue - inputMinValue;

    int x = inputHisto[value];
    int prev = inputHisto[value-delta];
    int next = inputHisto[value+delta];
    
    // get out of peak if local maxima
    while (prev <= x && next <= x)
    {
        value += delta;
        prev = x;
        x = next;
        next = inputHisto[value];
    }
    
    if (prev <= x)
        thresholdA = [self getLocalMinimaWith:-delta from:value-delta];
    else
        thresholdA = [self getLocalMinimaWith:-delta from:[self getLocalMaximaWith:-delta from:value-delta]]; 
    
    if (next <= x)
        thresholdB = [self getLocalMinimaWith:delta from:value+delta];
    else
        thresholdB = [self getLocalMinimaWith:delta from:[self getLocalMaximaWith:delta from:value+delta]];
    
    thresholdA += inputMinValue;
    thresholdB += inputMinValue;
}

-(void) getInputMinMaxValues
{
    inputMinValue = FLT_MAX;
    inputMaxValue = FLT_MIN;
    
    for (unsigned int i = 0; i < inputVolumeSize; ++i)
    {
        if (input[ i ] < inputMinValue)
            inputMinValue = input[ i ];
        if (input[ i ] > inputMaxValue)
            inputMaxValue = input[ i ];
    }
}

- (void) computeSimpleHistogram:(std::vector<int> &)histogram
{
    for (unsigned int i = 0; i < inputVolumeSize; ++i)
    {
        ++histogram[ (int)( input[ i ] - inputMinValue ) ];
    }
}

//- (void) computeCumulative:(std::vector<int> &)histogram
//{
//    std::vector<int> simple;
//    [self getInputMinMaxValues];
//    simple.reserve( (int)( inputMaxValue - inputMinValue ) );
//    [self computeSimpleHistogram:simple];
//    [self computeCumulativeHistogram:histogram FromSimpleHistogram:simple];
//}
//
//- (void) computeCumulativeHistogram:(std::vector<int> &)cumulative FromSimpleHistogram:(const std::vector<int> &)simple
//{
//    cumulative[ 0 ] = simple [ 0 ];
//    for (unsigned int i = 1; i < cumulative.size(); ++i)
//    {
//        cumulative[ i ] = cumulative[ i-1 ] + simple[ i ];
//    }
//}
//
//- (void) computeSimpleHistogram:(std::vector<int> &)simple AndCumulative:(std::vector<int> &)cumulative
//{
//    [self computeSimpleHistogram:simple];
//    [self computeCumulativeHistogram:cumulative FromSimpleHistogram:simple];
//}

- (void) smooth:(std::vector<int> &)histo withWindow:(const unsigned int)w
{
    int limit = histo.size();
    std::vector<int> original( limit + 2 * w );
    // body copy
    for (unsigned int i = 0; i < limit; ++i)
    {
        original[ i + w ] = histo[ i ];
    }
    // border copy
    for (unsigned int i = 0; i < w; ++i)
    {
        original[ i ] = histo[ 0 ];
        original[ original.size() - i ] = histo[ limit - i ];
    }
    
    // smooth histogram = convolution with basic 1-D kernel 1 2 4 8 ... 8 4 2 1 / sum
    int weight = 0;
    for (unsigned int i = w; i < limit; ++i)
    {
        histo[i] = original[i] << w;
        weight = 1 << w;
        for (unsigned int j = 1; j <= w; ++j)
        {
            histo[i] += ((original[j+i] << j) + (original[i-j] << j) );
            weight += 1 << (j+1);
        }
        histo[i] /= weight;
    }
}

- (void) smoothHistogramWith:(const unsigned int)window;
{
    if( inputHisto == nil)
        return;
    
    int limit = histoSize;
    int size = limit + 2 * window;
    vImagePixelCount original[size];// = (vImagePixelCount *)malloc(  * sizeof(vImagePixelCount) );
    
    if( window > limit)
        return;
    
    // body copy
    for (int i = 0; i < limit; ++i)
    {
        original[ i + window ] = inputHisto[ i ];
    }
    
    // border copy
    for (int i = 0; i < window; ++i)
    {
        original[ i ] = inputHisto[ 0 ];
        
        if( size - i >= 0 && limit - i >= 0 && limit - i < histoSize)
            original[ size - i ] = inputHisto[ limit - i ];
    }
    
    // smooth histogram = convolution with basic 1-D kernel 1 2 4 8 ... 8 4 2 1 / sum
    int weight = 0;
    for (unsigned int i = window; i < limit; ++i)
    {
        inputHisto[i] = original[i] << window;
        weight = 1 << window;
        for (unsigned int j = 1; j <= window; ++j)
        {
            inputHisto[i] += ((original[j+i] << j) + (original[i-j] << j) );
            weight += 1 << (j+1);
        }
        inputHisto[i] /= weight;
    }
    
//    free(original);
}

- (void) determineThresholdIntervalFrom:(int)value On:(const std::vector<int> &)histo WithStep:(const int)delta
{
    int x = histo[value];
    int prev = histo[value-delta];
    int next = histo[value+delta];

    // get out of peak if local maxima
    while (prev <= x && next <= x)
    {
        prev = value;
        value = next;
        next = histo[value+delta];
    }

    if (prev <= x)
        thresholdA = [self getLocalMinimaFrom:value-delta OnHistogram:histo WithStep:-delta];
    else
        thresholdA = [self getLocalMinimaFrom:[self getLocalMaximaFrom:value-delta OnHistogram:histo WithStep:-delta] OnHistogram:histo WithStep:-delta];
    
    if (next <= x)
        thresholdB = [self getLocalMinimaFrom:value+delta OnHistogram:histo WithStep:delta];
    else
        thresholdB = [self getLocalMinimaFrom:[self getLocalMaximaFrom:value+delta OnHistogram:histo WithStep:delta] OnHistogram:histo WithStep:delta];
    
    thresholdA += inputMinValue;
    thresholdB += inputMinValue;
}

- (int) getLocalMinimaFrom:(int)x OnHistogram:(const std::vector<int> &)h WithStep:(const int)delta
{
    int maxi = h.size();
    int epsilon = maxi >> 4;
    int xprev;
 
    do
    {
        xprev = x;
        x += delta;
    } while ( x < maxi && x >= 0 && h[xprev] >= h[x] && abs(h[xprev] - h[x]) > epsilon);

    return xprev;
}

- (int) getLocalMaximaFrom:(int)x OnHistogram:(const std::vector<int> &)h WithStep:(const int)delta
{
    int maxi = h.size();
    int xprev;
    
    do
    {
        xprev = x;
        x += delta;
    } while ( x < maxi && x >= 0 && h[xprev] <= h[x] );
    
    return xprev;
}

- (int) getLocalMinimaWith:(const int)step from:(vImagePixelCount)value;
{
    int maxi = histoSize;
    int epsilon = maxi >> 4;
    int xprev;
    
    do
    {
        xprev = value;
        value += step;
    } while ( value < maxi && inputHisto[xprev] >= inputHisto[value] && abs((int)inputHisto[xprev] - (int)inputHisto[value]) > epsilon);
    
    return xprev;
}

- (int) getLocalMaximaWith:(const int)step from:(vImagePixelCount)value;
{
    int maxi = histoSize;
    int xprev;
    
    do
    {
        xprev = value;
        value += step;
    } while ( value < maxi && inputHisto[xprev] <= inputHisto[value] );
    
    return xprev;
}

- (void) medianFilter:(vImage_Buffer *) buffer
{
//    vImage_Buffer * imageFromHisto;
//    CIImage *bitmap/* = [[CIImage alloc] initWithCVImageBuffer:imageFromHisto]*/;
    CIFilter * medianFilter = [CIFilter filterWithName:@"CIMedianFilter"];
    [medianFilter setDefaults];
}

- (void) mmError:(vImage_Error) err
{
    if (err != kvImageNoError) {
        switch (err) {
            case kvImageRoiLargerThanInputBuffer:
                NSLog(@"kvImageRoiLargerThanInputBuffer");
                break;
            case kvImageInvalidKernelSize:
                NSLog(@"kvImageInvalidKernelSize");
                break;
            case kvImageInvalidEdgeStyle:
                NSLog(@"kvImageInvalidEdgeStyle");
                break;
            case kvImageInvalidOffset_X:
                NSLog(@"kvImageInvalidOffset_X");
                break;
            case kvImageInvalidOffset_Y:
                NSLog(@"kvImageInvalidOffset_Y");
                break;
            case kvImageMemoryAllocationError:
                NSLog(@"kvImageMemoryAllocationError");
                break;
            case kvImageNullPointerArgument:
                NSLog(@"kvImageNullPointerArgument");
                break;
            case kvImageInvalidParameter:
                NSLog(@"kvImageInvalidParameter");
                break;
            case kvImageBufferSizeMismatch:
                NSLog(@"kvImageBufferSizeMismatch");
                break;
            case kvImageUnknownFlagsBit:
                NSLog(@"kvImageUnknownFlagsBit");
                break;
        }
    }
}

- (void) mmOpening:(vImage_Buffer *) buffer :(vImagePixelCount) x :(vImagePixelCount) y
{
    vImage_Buffer tmpResult;
    tmpResult.width     = buffer->width;
    tmpResult.height    = buffer->height;
    tmpResult.rowBytes  = buffer->rowBytes;
    tmpResult.data      = (float *)malloc(tmpResult.rowBytes*tmpResult.height);
    
    if( tmpResult.data)
    {
        float kernel[x*y];
        for (unsigned int i = 0; i < x * y; ++i) {
            kernel[i] = 1;
        }
        memset(kernel, 1, x*y*sizeof(float));
        
        if (buffer->data) {
            vImage_Error err;
            err = vImageErode_PlanarF(buffer, &tmpResult, 0, 0, kernel, x, y, kvImageNoFlags );
            if (err != kvImageNoError) {
                [self mmError:err];
                return;
            }
            err = vImageDilate_PlanarF(&tmpResult, buffer, 0, 0, kernel, x, y, kvImageNoFlags );
            if (err != kvImageNoError) {
                [self mmError:err];
                return;
            }
        }
        free(tmpResult.data);
    }
}

- (void) mmClosing:(vImage_Buffer *) buffer :(vImagePixelCount) x :(vImagePixelCount) y
{
    vImage_Buffer tmpResult;//, result;
    tmpResult.width     = buffer->width;
    tmpResult.height    = buffer->height;
    tmpResult.rowBytes  = buffer->rowBytes;
    tmpResult.data      = (float *)malloc(tmpResult.rowBytes*tmpResult.height);
    
    if( tmpResult.data)
    {
        float kernel[x*y];
        for (unsigned int i = 0; i < x * y; ++i) {
            kernel[i] = 1;
        }
            
        if (buffer->data) {
            vImage_Error err;
            err = vImageDilate_PlanarF(buffer, &tmpResult, 0, 0, kernel, x, y, kvImageNoFlags);
            if (err != kvImageNoError) {
                [self mmError:err];
                return;
            }
            err = vImageErode_PlanarF(&tmpResult, buffer, 0, 0, kernel, x, y, kvImageNoFlags);
            if (err != kvImageNoError) {
                [self mmError:err];
                return;
            }
        }
        free(tmpResult.data);
    }
}

//- (void) mmErosion:(vImage_Buffer *) buffer :(vImagePixelCount) x :(vImagePixelCount) y
//{
//    vImage_Buffer tmpResult;
//    tmpResult.width     = buffer->width;
//    tmpResult.height    = buffer->height;
//    tmpResult.rowBytes  = buffer->rowBytes;
//    tmpResult.data      = (float *)malloc(tmpResult.rowBytes*tmpResult.height);
//    
//    if( tmpResult.data)
//    {
//        float kernel[x*y];
//        for (unsigned int i = 0; i < x * y; ++i) {
//            kernel[i] = 1;
//        }
//        
//        if (buffer->data) {
//            vImage_Error err = vImageErode_PlanarF(&tmpResult, buffer, 0, 0, kernel, x, y, kvImageNoFlags);
//            if (err != kvImageNoError) {
//                [self mmError:err];
//                return;
//            }
//            memccpy(buffer->data, tmpResult.data, tmpResult.height*tmpResult.width, tmpResult.rowBytes);
//        }
//        free(tmpResult.data);
//    }
//}
//
//- (void) mmDilation:(vImage_Buffer *) buffer :(vImagePixelCount) x :(vImagePixelCount) y
//{
//    vImage_Buffer tmpResult;
//    tmpResult.width     = buffer->width;
//    tmpResult.height    = buffer->height;
//    tmpResult.rowBytes  = buffer->rowBytes;
//    tmpResult.data      = (float *)malloc(tmpResult.rowBytes*tmpResult.height);
//    
//    if( tmpResult.data)
//    {
//        float kernel[x*y];
//        for (unsigned int i = 0; i < x * y; ++i) {
//            kernel[i] = 1;
//        }
//        
//        if (buffer->data) {
//            vImage_Error err = vImageDilate_PlanarF(&tmpResult, buffer, 0, 0, kernel, x, y, kvImageNoFlags);
//            if (err != kvImageNoError) {
//                [self mmError:err];
//                return;
//            }
//            memccpy(buffer->data, tmpResult.data, tmpResult.height*tmpResult.width, tmpResult.rowBytes*tmpResult.height);
//        }
//        free(tmpResult.data);
//    }
//}

@end
