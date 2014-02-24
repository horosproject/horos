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

#import "NSBitmapImageRep+N2.h"
#import <Accelerate/Accelerate.h>
#include <algorithm>
#include <stack>

@implementation NSBitmapImageRep (N2)

-(size_t)_spp {
	size_t spp = [self hasAlpha]? 1 : 0;
	
    NSString* colorSpaceName = [self colorSpaceName];
	if ([colorSpaceName isEqualToString:NSCalibratedWhiteColorSpace] ||
        [colorSpaceName isEqualToString:NSCalibratedBlackColorSpace] ||
        [colorSpaceName isEqualToString:NSDeviceWhiteColorSpace] ||
        [colorSpaceName isEqualToString:NSDeviceBlackColorSpace])
		spp += 1;
	else if ([colorSpaceName isEqualToString:NSCalibratedRGBColorSpace] ||
             [colorSpaceName isEqualToString:NSDeviceRGBColorSpace])
		spp += 3;
	else if ([colorSpaceName isEqualToString:NSDeviceCMYKColorSpace])
		spp += 4;
	else
		[NSException raise:NSInvalidArgumentException format:@"invalid color space"];
    
    return spp;
}

-(void)setColor:(NSColor*)color { // _deprecated
    NSColorSpace* colorSpace = [self colorSpace];
    size_t spp = [self samplesPerPixel];
    NSUInteger samples[spp];
    CGFloat fsamples[spp];
	for (int y = self.pixelsHigh-1; y >= 0; --y)
		for (int x = self.pixelsWide-1; x >= 0; --x) {
			[self getPixel:samples atX:x y:y];
            for (int i = 0; i < spp; ++i)
                fsamples[i] = samples[i]*1.0/255;
            
            NSColor* xycolor = [NSColor colorWithColorSpace:colorSpace components:fsamples count:spp];
            
            CGFloat brightness, alpha;
            [[xycolor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getHue:NULL saturation:NULL brightness:&brightness alpha:&alpha];
            NSColor* fixedColor = [NSColor colorWithDeviceHue:[color hueComponent] saturation:[color saturationComponent] brightness:std::max((CGFloat).75, brightness) alpha:alpha];
            
            xycolor = [fixedColor colorUsingColorSpace:colorSpace];
            [color getComponents:fsamples];
            if (self.hasAlpha)
                fsamples[spp-1] = alpha;
            
            for (int i = 0; i < spp; ++i)
                samples[i] = floor(fsamples[i]*255);
            
            [self setPixel:samples atX:x y:y];
		}
}

-(NSImage*)image {
	NSImage* image = [[NSImage alloc] initWithSize:[self size]];
	[image addRepresentation:[[self copy] autorelease]];
	return [image autorelease];
}

-(NSBitmapImageRep*)repUsingColorSpaceName:(NSString*)colorSpaceName {
	if ([[self colorSpaceName] isEqualToString:colorSpaceName])
		return self;
	
	NSInteger spp = [self _spp];
	
	NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:[self pixelsWide] pixelsHigh:[self pixelsHigh] bitsPerSample:8 samplesPerPixel:spp hasAlpha:[self hasAlpha] isPlanar:NO colorSpaceName:colorSpaceName bytesPerRow:0 bitsPerPixel:0];
	for (int y = [self pixelsHigh]-1; y >= 0; --y)
		for (int x = [self pixelsWide]-1; x >= 0; --x)
			[rep setColor:[[self colorAtX:x y:y] colorUsingColorSpaceName:colorSpaceName] atX:x y:y];
	
	return [rep autorelease];
}

struct P {
	int x, y;
	P(int x, int y) : x(x), y(y) {}
};

-(void)ATMask:(float)level { // this method is deprecated
	NSSize size = [self size];
	int width = size.width, height = size.height;
	float v[width][height];
	
	unsigned char* bitmapData = [self bitmapData];
	size_t bpp = [self bytesPerPlane], bpr = [self bytesPerRow];
	assert(bpp = 4);
	NSLog(@"time1!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
//#pragma omp parallel for default(shared)
	for (int x = 0; x < width; ++x)
		for (int y = 0; y < height; ++y)
			v[x][y] = bitmapData[y*bpr+x*bpp+3];
	//v[x][y] = [[self colorAtX:x y:y] alphaComponent];
	
	NSLog(@"time2!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
	BOOL mask[width][height];
	memset(mask, YES, sizeof(mask));
	BOOL visited[width][height];
	memset(visited, NO, sizeof(visited));
	
	NSLog(@"time3!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
	std::stack<P> ps;
	for (int x = 0; x < width; ++x) {
		ps.push(P(x, 0));
		ps.push(P(x, height-1));
	} for (int y = 1; y < height-1; ++y) {
		ps.push(P(0, y));
		ps.push(P(width-1, y));
	}
	
	NSLog(@"time4!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
	while (!ps.empty()) {
		P p = ps.top();
		ps.pop();
		
		if (visited[p.x][p.y]) continue;
		visited[p.x][p.y] = YES;
		
		if (!v[p.x][p.y]) {
			mask[p.x][p.y] = NO;
			if (p.x > 0 && !visited[p.x-1][p.y]) ps.push(P(p.x-1, p.y));
			if (p.y > 0 && !visited[p.x][p.y-1]) ps.push(P(p.x, p.y-1));
			if (p.x < width-1 && !visited[p.x+1][p.y]) ps.push(P(p.x+1, p.y));
			if (p.y < height-1 && !visited[p.x][p.y+1]) ps.push(P(p.x, p.y+1));
		}
	}
	
	NSLog(@"time5!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
	for (int y = 0; y < height/2; ++y)
		for (int x = 0; x < width; ++x)
			if (mask[x][y])
				bitmapData[y*bpr+x*bpp+3] = std::max(v[x][y], level);
	NSLog(@"time6!!!!!! %f", [NSDate timeIntervalSinceReferenceDate]);
}



-(NSBitmapImageRep*)smoothen:(NSUInteger)kernelSize {
	return self;;
	
	assert(kernelSize%2 == 1 && [self bitsPerSample] == 8 && [self samplesPerPixel] == 4);
	
	NSSize selfSize = [self size];
	vImage_Buffer selfBuff = {[self bitmapData], (unsigned long)selfSize.width, (unsigned long)selfSize.height, static_cast<size_t>([self bytesPerRow])};
	
	NSSize outputSize = selfSize;
	NSBitmapImageRep* outputBitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:outputSize.width pixelsHigh:outputSize.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:outputSize.width*4 bitsPerPixel:32];
	vImage_Buffer outputBuff = {[outputBitmap bitmapData], (unsigned long)outputSize.width, (unsigned long)outputSize.height, static_cast<size_t>([outputBitmap bytesPerRow])};
	
	Pixel_8888 backgroundColor = {0,0,0,0};
	vImageBoxConvolve_ARGB8888(&selfBuff, &outputBuff, NULL, 0, 0, kernelSize, kernelSize, backgroundColor, kvImageBackgroundColorFill);
	
	return outputBitmap;
}

/*-(NSBitmapImageRep*)convolveWithFilter:(const boost::numeric::ublas::matrix<float>&)filter fillPixel:(NSUInteger[])fillPixel {
 const NSSize filterSize = NSMakeSize(filter.size1(), filter.size2());
 assert(int(filterSize.width)%2 == 1 && int(filterSize.height)%2 == 1); // only for odd sizes
 const int offsetX = (filterSize.width-1)/2, offsetY = (filterSize.height-1)/2;
 const NSSize originalSize = [self size], size = NSMakeSize(originalSize.width+filterSize.width-1, originalSize.height+filterSize.height-1);
 
 const NSUInteger spp = [self samplesPerPixel];
 NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:[self bitsPerSample] samplesPerPixel:spp hasAlpha:[self hasAlpha] isPlanar:[self isPlanar] colorSpaceName:[self colorSpaceName] bitmapFormat:[self bitmapFormat] bytesPerRow:0 bitsPerPixel:[self bitsPerPixel]];
 
 for (unsigned x = 0; x < size.width; ++x)
 for (unsigned y = 0; y < size.height; ++y) {
 double pixeld[spp]; memset(pixeld, 0, sizeof(double)*spp);
 for (unsigned xi = 0; xi < filterSize.width; ++xi)
 for (unsigned yi = 0; yi < filterSize.height; ++yi) {
 const float filterValue = filter(xi,yi);
 const int xo = int(x)-offsetX+xi, yo = int(y)-offsetY+yi;
 NSUInteger pixel[spp], *pixelp = pixel;
 if (xo >= 0 && yo >= 0 && xo < originalSize.width && yo < originalSize.height)
 [self getPixel:pixel atX:xo y:yo];
 else pixelp = fillPixel;
 for (unsigned s = 0; s < spp; ++s)
 pixeld[s] += filterValue*pixelp[s];
 }
 
 NSUInteger pixel[spp];
 for (unsigned s = 0; s < spp; ++s)
 pixel[s] = pixeld[s];
 [bitmap setPixel:pixel atX:x y:y];
 }
 
 return [bitmap autorelease];
 }
 
 -(NSBitmapImageRep*)fftConvolveWithFilter:(const boost::numeric::ublas::matrix<float>&)filter fillPixel:(NSUInteger[])fillPixel {
 const NSSize filterSize = NSMakeSize(filter.size1(), filter.size2());
 assert(int(filterSize.width)%2 == 1 && int(filterSize.height)%2 == 1); // only for odd sizes
 const int offsetX = (filterSize.width-1)/2, offsetY = (filterSize.height-1)/2;
 const NSSize originalSize = [self size], size = NSMakeSize(originalSize.width+filterSize.width-1, originalSize.height+filterSize.height-1);
 
 const NSUInteger spp = [self samplesPerPixel];
 boost::numeric::ublas::matrix<float> layers[spp];
 for (unsigned s = 0; s < spp; ++s)
 layers[s].resize(size.width, size.height);
 boost::numeric::ublas::matrix<float> filterPadded(filter);
 filterPadded.resize(size.width, size.height, YES);
 for (unsigned x = 0; x < size.width; ++x)
 for (unsigned y = 0; y < size.height; ++y) {
 const int xo = int(x)-offsetX, yo = int(y)-offsetY;
 NSUInteger pixel[spp], *pixelp = pixel;
 if (xo >= 0 && yo >= 0 && xo < originalSize.width && yo < originalSize.height) {
 [self getPixel:pixel atX:x y:y];
 } else pixelp = fillPixel;
 for (unsigned s = 0; s < spp; ++s)
 layers[s](x,y) = pixelp[s];
 if (x >= filterSize.width || y >= filterSize.height)
 filterPadded(x,y) = 0;
 }
 
 boost::numeric::ublas::matrix< std::complex<float> > filterPaddedFreq(size.width, size.height), layersFreq[spp];
 fftwf_plan plan = fftwf_plan_dft_r2c_2d(size.width, size.height, &filterPadded(0,0), (float(*)[2])&filterPaddedFreq(0,0), FFTW_ESTIMATE);
 fftwf_execute(plan);
 fftwf_destroy_plan(plan);
 for (unsigned s = 0; s < spp; ++s) {
 layersFreq[s].resize(size.width, size.height);
 plan = fftwf_plan_dft_r2c_2d(size.width, size.height, &layers[s](0,0), (float(*)[2])&layersFreq[s](0,0), FFTW_ESTIMATE);
 fftwf_execute(plan);
 fftwf_destroy_plan(plan);
 }
 
 for (unsigned x = 0; x < size.width; ++x)
 for (unsigned y = 0; y < size.height; ++y) {
 std::complex<float> f = filterPaddedFreq(x,y);
 for (unsigned s = 0; s < spp; ++s)
 layersFreq[s](x,y) *= f;
 }
 
 for (unsigned s = 0; s < spp; ++s) {
 plan = fftwf_plan_dft_c2r_2d(size.width, size.height, (float(*)[2])&layersFreq[s](0,0), &layers[s](0,0), FFTW_ESTIMATE);
 fftwf_execute(plan);
 fftwf_destroy_plan(plan);
 // normalize
 layers[s] /= size.width*size.height;
 }
 
 NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:[self bitsPerSample] samplesPerPixel:spp hasAlpha:[self hasAlpha] isPlanar:[self isPlanar] colorSpaceName:[self colorSpaceName] bitmapFormat:[self bitmapFormat] bytesPerRow:0 bitsPerPixel:[self bitsPerPixel]];
 for (unsigned x = 0; x < size.width; ++x)
 for (unsigned y = 0; y < size.height; ++y) {
 NSUInteger pixel[spp];
 for (unsigned s = 0; s < spp; ++s)
 pixel[s] = layers[s](x,y);
 [bitmap setPixel:pixel atX:x y:y];
 }
 
 return bitmap;
 }*/


@end
