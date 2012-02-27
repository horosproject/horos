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


#import "LLSubtraction.h"
#include <Accelerate/Accelerate.h>

@implementation LLSubtraction

#pragma mark-
#pragma mark Subtraction

+ (void)subtractBuffer:(float*)bufferB to:(float*)bufferA withWidth:(long)width height:(long)height minValueA:(int)minA maxValueA:(int)maxA minValueB:(int)minB maxValueB:(int)maxB minValueSubtraction:(int)minS maxValueSubtraction:(int)maxS displayBones:(BOOL)displayBones bonesThreshold:(int)bonesThreshold;
{
	long x, y, curPixel;
	float pixelA, pixelB;
	BOOL result;		
	for(y = 0; y < height; y++)
	{
		for(x = 0; x < width; x++)
		{
			curPixel = width * y + x;
			pixelA = bufferA[curPixel];
			pixelB = bufferB[curPixel];
			
			result = (pixelA >= minA) && (pixelA <= maxA) && (pixelB >= minB) && (pixelB <= maxB);
			
			pixelA -= pixelB;
			
			result = result && (pixelA >= minS) && (pixelA <= maxS);

			if(result) bufferA[curPixel] = pixelA;
			else bufferA[curPixel] = -1000;	//AIR
			
			if(displayBones && bufferA[curPixel]<=-1000 && pixelB>bonesThreshold)
				bufferA[curPixel] = pixelB+500; // BONE
		}
	}
}

+ (void)subtractBuffer:(float*)bufferB to:(float*)bufferA withWidth:(long)width height:(long)height;
{
	[LLSubtraction subtractBuffer:bufferB to:bufferA withWidth:width height:height minValueA:10 maxValueA:500 minValueB:0 maxValueB:100 minValueSubtraction:20 maxValueSubtraction:500 displayBones:NO bonesThreshold:0];
}

+ (void)subtractDCMPix:(DCMPix*)pixB to:(DCMPix*)pixA minValueA:(int)minA maxValueA:(int)maxA minValueB:(int)minB maxValueB:(int)maxB minValueSubtraction:(int)minS maxValueSubtraction:(int)maxS displayBones:(BOOL)displayBones bonesThreshold:(int)bonesThreshold;
{	
	float *fImageA, *fImageB;
	fImageA = [pixA fImage];
	fImageB = [pixB fImage];

	long width = ([pixA pwidth]<[pixB pwidth])? [pixA pwidth] : [pixB pwidth];
	long height = ([pixA pheight]<[pixB pheight])? [pixA pheight] : [pixB pheight];
	[LLSubtraction subtractBuffer:fImageB to:fImageA withWidth:width height:height minValueA:minA maxValueA:maxA minValueB:minB maxValueB:maxB minValueSubtraction:minS maxValueSubtraction:maxS displayBones:displayBones bonesThreshold:bonesThreshold];
}

+ (void)subtractDCMPix:(DCMPix*)pixB to:(DCMPix*)pixA;
{	
	float *fImageA, *fImageB;
	fImageA = [pixA fImage];
	fImageB = [pixB fImage];

	long width = ([pixA pwidth]<[pixB pwidth])? [pixA pwidth] : [pixB pwidth] ;
	long height = ([pixA pheight]<[pixB pheight])? [pixA pheight] : [pixB pheight] ;
	[LLSubtraction subtractBuffer: fImageB to: fImageA withWidth: width height: height];
}

+ (void)subtractDCMView:(DCMView*)viewB to:(DCMView*)viewA;
{
	NSArray *pixListA = [viewA dcmPixList];
	NSArray *pixListB = [viewB dcmPixList];
	DCMPix *curPixA, *curPixB;
	int i;
	for(i = 0; i < [pixListA count]; i++)
	{
		curPixA = [pixListA objectAtIndex: i];
		curPixB = [pixListB objectAtIndex: i];
		[LLSubtraction subtractDCMPix: curPixB to: curPixA];
	}
}

#pragma mark-
#pragma mark Small part removal

+ (void)removeSmallConnectedPartInBuffer:(float*)buffer withWidth:(long)width height:(long)height;
{
	long x, y, maxIndex, curPixel, northNeighbor, southNeighbor, eastNeighbor, westNeighbor;
	float curValue, northValue, southValue, eastValue, westValue;
	BOOL connected;
	
	maxIndex = height * width - 1;
	
	for(y = 0; y < height; y++)
	{
		for(x = 0; x < width; x++)
		{
			curPixel = width * y + x;
			northNeighbor = curPixel - width;
			southNeighbor = curPixel + width;
			eastNeighbor = curPixel + 1;
			westNeighbor = curPixel - 1;
			
			curValue = buffer[curPixel];
			// set all the outside pixels to -1000
			northValue = (northNeighbor>=0 && northNeighbor<=maxIndex) ? buffer[northNeighbor] : -1000;
			southValue = (southNeighbor>=0 && southNeighbor<=maxIndex) ? buffer[southNeighbor] : -1000;
			eastValue = (eastNeighbor>=0 && eastNeighbor<=maxIndex) ? buffer[eastNeighbor] : -1000;
			westValue = (westNeighbor>=0 && westNeighbor<=maxIndex) ? buffer[westNeighbor] : -1000;
			
			connected = (northValue > -1000) || (southValue > -1000) || (eastValue > -1000) || (westValue > -1000);

			if(!connected) buffer[curPixel] = -1000;
		}
	}
}

+ (void)removeSmallConnectedPartDCMPix:(DCMPix*)pix;
{
	float *fImage;
	fImage = [pix fImage];

	long width = [pix pwidth];
	long height = [pix pheight];
	[LLSubtraction removeSmallConnectedPartInBuffer:fImage withWidth:width height:height];
}

#pragma mark-
#pragma mark Math Morphology

void draw_filled_circle(unsigned char *buf, int width, unsigned char val)
{
	int		x,y;
	int		xsqr;
	int		inw = width-1;
	int		radsqr = (inw*inw)/4;
	int		rad = width/2;
	
	for(x = 0; x < rad; x++)
	{
		xsqr = x*x;
		for( y = 0 ; y < rad; y++)
		{
			if((xsqr + y*y) < radsqr)
			{
				buf[ rad+x + (rad+y)*width] = val;
				buf[ rad-x + (rad+y)*width] = val;
				buf[ rad+x + (rad-y)*width] = val;
				buf[ rad-x + (rad-y)*width] = val;
			}
		}
	}
	
//	for(x = 0; x < width; x++)
//	{
//		for( y = 0 ; y < width; y++)
//		{
//			if(buf[x+y*width]==0x0)
//				printf("0 ");
//			else if(buf[x+y*width]==0xFF)
//				printf("1 ");
//		}
//		printf("\n");
//	}
}

+ (void)erodeBuffer:(unsigned char*)buffer withWidth:(int)width height:(int)height structuringElementRadius:(int)structuringElementRadius;
{
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc( structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	draw_filled_circle(kernel, structuringElementRadius, 0xFF);	
	
	vImage_Buffer	srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buffer;
	dstBuf.data = malloc( height * width);
	dstBuf.height = srcbuf.height = height;
	dstBuf.width = srcbuf.width = width;
	dstBuf.rowBytes = srcbuf.rowBytes = width;
	err = vImageErode_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
	if( err) NSLog(@"%d", (int) err);
	memcpy(buffer,dstBuf.data,width*height);
	free( dstBuf.data);
	free( kernel);
}

+ (void)dilateBuffer:(unsigned char*)buffer withWidth:(int)width height:(int)height structuringElementRadius:(int)structuringElementRadius;
{	
	// add a margin to avoid border effects!!
	// [aROI addMarginToBuffer: structuringElementRadius*2];
	
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc(structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	memset(kernel,0xff,structuringElementRadius*structuringElementRadius);
	draw_filled_circle(kernel, structuringElementRadius, 0x0);
	
	vImage_Buffer srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buffer;
	dstBuf.data = malloc(width*height);
	dstBuf.height = srcbuf.height = height;
	dstBuf.width = srcbuf.width = width;
	dstBuf.rowBytes = srcbuf.rowBytes = width;
	err = vImageDilate_Planar8(&srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
	if(err) NSLog(@"%d", (int) err);
	
	memcpy(buffer, dstBuf.data, width*height);
	free(dstBuf.data);
	free(kernel);
}

+ (void)erode:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;
{
	if(structuringElementRadius==0) return;
	
	unsigned char* binaryBuffer;
	binaryBuffer = (unsigned char*)malloc(height*width);
	int i;
	for(i=0; i<height*width; i++)
		binaryBuffer[i] = (buffer[i]>-1000)? 0xFF : 0x0;
		
	[LLSubtraction erodeBuffer:binaryBuffer withWidth:width height:height structuringElementRadius:structuringElementRadius];
	
	for(i=0; i<height*width; i++)
		if(binaryBuffer[i]==0x0)
			buffer[i] = -1000.0;
	
	free(binaryBuffer);
}

+ (void)dilate:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;
{
	if(structuringElementRadius==0) return;
	
	unsigned char* binaryBuffer;
	binaryBuffer = (unsigned char*)malloc(height*width);
	int i;
	for(i=0; i<height*width; i++)
		binaryBuffer[i] = (buffer[i]<=-1000)? 0xFF : 0x0;
		
	[LLSubtraction dilateBuffer:binaryBuffer withWidth:width height:height structuringElementRadius:structuringElementRadius];
	
	for(i=0; i<height*width; i++)
		if(binaryBuffer[i]==0xFF && buffer[i]<1000)
			buffer[i] = -1000.0;
	
	free(binaryBuffer);
}

+ (void)close:(float*)buffer withWidth:(long)width height:(long)height structuringElementRadius:(int)structuringElementRadius;
{
	if(structuringElementRadius==0) return;
	
	unsigned char* binaryBuffer;
	binaryBuffer = (unsigned char*)malloc(height*width);
	int i;
	for(i=0; i<height*width; i++)
		binaryBuffer[i] = (buffer[i]<=-1000)? 0xFF : 0x0;
		
	[LLSubtraction dilateBuffer:binaryBuffer withWidth:width height:height structuringElementRadius:structuringElementRadius];
	[LLSubtraction erodeBuffer:binaryBuffer withWidth:width height:height structuringElementRadius:structuringElementRadius];
	
	for(i=0; i<height*width; i++)
		if(binaryBuffer[i]==0xFF && buffer[i]<1000)
			buffer[i] = -1000.0;
	
	free(binaryBuffer);
}

#pragma mark-
#pragma mark Filtering

+ (void)lowPassFilterOnBuffer:(float*)buffer withWidth:(int)width height:(int)height structuringElementSize:(int)structuringElementSize;
{
	if(width==0 || height==0 || structuringElementSize==0) return;
	
	structuringElementSize /= 2;
	structuringElementSize *= 2;
	structuringElementSize += 1;
	
	float kernel[structuringElementSize*structuringElementSize];
	
	int x,y;
		
	float divisor = (float) structuringElementSize * structuringElementSize;
	float val = 1.0/divisor;
	
	for(x = 0; x < structuringElementSize; x++)
	{
		for( y = 0 ; y < structuringElementSize; y++)
		{
			kernel[ x + y*structuringElementSize] = val;
		}
	}
	
	vImage_Buffer srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buffer;
	
	dstBuf.data = malloc(height * width * sizeof(float));
	if( dstBuf.data)
	{
		dstBuf.height = srcbuf.height = height;
		dstBuf.width = srcbuf.width = width;
		dstBuf.rowBytes = srcbuf.rowBytes = width * sizeof(float);

		err = vImageConvolve_PlanarF( &srcbuf, &dstBuf, 0, 0, 0, kernel, structuringElementSize, structuringElementSize, 0, kvImageEdgeExtend);
		if( err) NSLog(@"convolve error : %d", (int)err);
		memcpy(buffer,dstBuf.data,width * height * sizeof(float));
		free(dstBuf.data);
	}
}

+ (void)convolveBuffer:(float*)buffer withWidth:(int)width height:(int)height withKernel:(float*)kernel kernelSize:(int)kernelSize;
{
	if(width==0 || height==0) return;
	
	vImage_Buffer srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buffer;
		
	dstBuf.data = malloc(height * width * sizeof(float));
	if( dstBuf.data)
	{
		dstBuf.height = srcbuf.height = height;
		dstBuf.width = srcbuf.width = width;
		dstBuf.rowBytes = srcbuf.rowBytes = width * sizeof(float);

		err = vImageConvolve_PlanarF( &srcbuf, &dstBuf, 0, 0, 0, kernel, kernelSize, kernelSize, 0, kvImageEdgeExtend);
		if( err) NSLog(@"convolve error : %d", (int) err);
		memcpy(buffer,dstBuf.data,width * height * sizeof(float));
		free(dstBuf.data);
	}
}

/*
#pragma mark-
#pragma mark Filtering

+ (void)erodeVolumeInZ:(float*)fVolume withWidth:(int)width height:(int)height maxZ:(int)maxZ structuringElementRadius:(int)structuringElementRadius;
{
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc( structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	draw_filled_circle(kernel, structuringElementRadius, 0xFF);	
	
	int y;
	for(y=0; y<height; y++)
	{
		vImage_Buffer srcbuf, dstBuf;
		vImage_Error err;
		srcbuf.data = fVolume;
		dstBuf.data = malloc(width * maxZ);
		dstBuf.height = srcbuf.height = height;
		dstBuf.width = srcbuf.width = width;
		dstBuf.rowBytes = srcbuf.rowBytes = width * height;
		err = vImageErode_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
		if( err) NSLog(@"%d", err);
		memcpy(buffer,dstBuf.data,width*height);
		free( dstBuf.data);
	}
	free( kernel);
}
*/
/*
+ (void)dilateBuffer:(unsigned char*)buffer withWidth:(int)width height:(int)height structuringElementRadius:(int)structuringElementRadius;
{	
	// add a margin to avoid border effects!!
	// [aROI addMarginToBuffer: structuringElementRadius*2];
	
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc(structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	memset(kernel,0xff,structuringElementRadius*structuringElementRadius);
	draw_filled_circle(kernel, structuringElementRadius, 0x0);
	
	vImage_Buffer srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buffer;
	dstBuf.data = malloc(width*height);
	dstBuf.height = srcbuf.height = height;
	dstBuf.width = srcbuf.width = width;
	dstBuf.rowBytes = srcbuf.rowBytes = width;
	err = vImageDilate_Planar8(&srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
	if(err) NSLog(@"%d", err);
	
	memcpy(buffer, dstBuf.data, width*height);
	free(dstBuf.data);
	free(kernel);
}
*/
@end
