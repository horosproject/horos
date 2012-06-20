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
    float pixVal = input[position];
    [self autoComputeThresholdFromValue:input[position]];
}

- (void) computeIntervalThresholdsFrom:(float)pixValue;
{
    NSLog(@"Compute Interval");
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

- (void) computeCumulative:(std::vector<int> &)histogram
{
    std::vector<int> simple;
    [self getInputMinMaxValues];
    simple.reserve( (int)( inputMaxValue - inputMinValue ) );
    [self computeSimpleHistogram:simple];
    [self computeCumulativeHistogram:histogram FromSimpleHistogram:simple];
}

- (void) computeCumulativeHistogram:(std::vector<int> &)cumulative FromSimpleHistogram:(const std::vector<int> &)simple
{
    cumulative[ 0 ] = simple [ 0 ];
    for (unsigned int i = 1; i < cumulative.size(); ++i)
    {
        cumulative[ i ] = cumulative[ i-1 ] + simple[ i ];
    }
}

- (void) computeSimpleHistogram:(std::vector<int> &)simple AndCumulative:(std::vector<int> &)cumulative
{
    [self computeSimpleHistogram:simple];
    [self computeCumulativeHistogram:cumulative FromSimpleHistogram:simple];
}

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
    int limit = histoSize;
    int size = limit + 2 * window;
    vImagePixelCount * original = (vImagePixelCount *)malloc( size * sizeof(vImagePixelCount) );

    // body copy
    for (unsigned int i = 0; i < limit; ++i)
    {
        original[ i + window ] = inputHisto[ i ];
    }
    
    // border copy
    for (unsigned int i = 0; i < window; ++i)
    {
        original[ i ] = inputHisto[ 0 ];
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
    
    free(original);
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
    } while ( value < maxi && inputHisto[xprev] >= inputHisto[value] && abs(inputHisto[xprev] - inputHisto[value]) > epsilon);
    
    return xprev;
}

- (int) getLocalMaximaWith:(const int)step from:(vImagePixelCount)value;
{
    int maxi = histoSize;
    int epsilon = maxi >> 4;
    int xprev;
    
    do
    {
        xprev = value;
        value += step;
    } while ( value < maxi && inputHisto[xprev] <= inputHisto[value] );
    
    return xprev;
}

int compareFloats(const void * a, const void * b)
{
    float* arg1 = (float*) a;
    float* arg2 = (float*) b;
    if( *arg1 < *arg2 ) return -1;
    else if( *arg1 == *arg2 ) return 0;
    else return 1;
}

- (void) medianFilter;
{
    NSLog(@"Median filter");
    float * original = (float *)malloc( inputVolumeSize * sizeof(float) );
    if (!original) {
        NSLog(@"Not enough memory.");
        return;
    }
    
    // body copy
    //    original = (float *)memcpy(original, input, inputVolumeSize * sizeof(float));
    for (unsigned int i = 0; i < inputVolumeSize; ++i)
    {
        original[ i ] = input[ i ];
    }
    
    float * sorted = new float[7];
    unsigned int zmax = inputDepth - 1;
    unsigned int ymax = inputWidth - 1;
    unsigned int xmax = inputHeight - 1;
    for (unsigned int z = 1; z < zmax; ++z) {
        for (unsigned int y = 1; y < ymax; ++y) {
            for (unsigned int x = 1; x < xmax; ++x) {
                unsigned int index = x + y*inputWidth+ z*inputImageSize;
                sorted[0] = original[index];
                sorted[1] = original[index + 1];
                sorted[2] = original[index - 1];
                sorted[3] = original[index + inputWidth];
                sorted[4] = original[index - inputWidth];
                sorted[5] = original[index + inputImageSize];
                sorted[6] = original[index - inputImageSize];
                //                for (int i = -1; i < 2; ++i) {
                //                    for (int j = -1; j < 2; ++j) {
                //                        for (int k = -1; k < 2; ++k) {
                //                            //index = x+i + (y+j)*inputWidth+ (z+j)*inputImageSize
                //                            sorted.push_back(original[index + i + j*inputWidth + k*inputImageSize]);
                //                        }
                //                    }
                //                }
                qsort(sorted, 7, sizeof(float), compareFloats);
                input[index] = sorted[4];
            }
        }
    }
    
    free(original);
    delete sorted;
    NSLog(@"done");
}

- (void) mmOpening;
{
    
}

- (void) mmClosing;
{
    
}

- (void) mmErosion;
{
    
}

- (void) mmDilation;
{
    
}

@end
