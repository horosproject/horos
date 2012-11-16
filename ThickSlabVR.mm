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

#import "ThickSlabVR.h"

extern short Altivec;

@implementation ThickSlabVR

-(void) dealloc
{
	NSLog( @"ThickSlabVR");
	
	opacityTransferFunction->Delete();
	
	if( dst8.data) free( dst8.data);
	if( dst8Blending.data) free( dst8Blending.data);
	
	[processorsLock release];
	
	[super dealloc];
}

-(id)initWithFrame:(NSRect)frame
{
	
    if ( self = [super initWithFrame:frame] )
    {
		lowQuality = NO;
		width = 0;
		count = 0;
		height = 0;
		dst8.data = 0;
		dst8Blending.data = 0;
		
		imagePtr = 0;
		imageBlendingPtr = 0;
			
		opacityTransferFunction = vtkPiecewiseFunction::New();
		opacityTransferFunction->AddPoint(0, 0);
		opacityTransferFunction->AddPoint(255, 1);

		[self setCLUT:nil :nil :nil];
		[self setOpacity:[NSArray array]];
	}
	
	return self;
}

-(void) setFlip:(BOOL) f
{
	flipData = f;
}

-(void) setImageBlendingSource: (float*) i
{
	imageBlendingPtr = i;
	
	srcfBlending.height = height * count;
	dst8Blending.height = height * count;
	
	srcfBlending.data = imageBlendingPtr;
	
	if( dst8Blending.data) free( dst8Blending.data);
	dst8Blending.data = (char*) malloc( dst8Blending.height * dst8Blending.width * sizeof(char));
}

-(void) setImageSource: (float*) i :(long) c
{
	imagePtr = i;
	
	srcf.height = height * c;
	dst8.height = height * c;

	if( count != c)
	{
		count = c;
		if( dst8.data) free( dst8.data);
		dst8.data = (char*) malloc( dst8.height * dst8.width * sizeof(char));
	}

	srcf.data = imagePtr;
}

-(void) setImageData:(long) w :(long) h :(long) c :(float) sX :(float) sY :(float) t :(BOOL) flip
{
	flipData = flip;
	
	if( width == w && height == h && count == c) return;
	
	// GLOBALS
	
	imagePtr = nil;
	width = w;
	height = h;
	count = c;
	spaceX = sX;
	spaceY = sY;
	thickness = t;
	
	wl = 0;
	ww = 0;
	
	NSLog( @"Count: %d", (int) count);
	
	// VIMAGE CONVERTER
	
	srcf.height = height * count;
	srcf.width = width;
	srcf.rowBytes = width * sizeof(float);
	srcf.data = imagePtr;

	srcfBlending.height = height * count;
	srcfBlending.width = width;
	srcfBlending.rowBytes = width * sizeof(float);
	srcfBlending.data = nil;

	dst8.height = height * count;
	dst8.width = width;
	dst8.rowBytes = width * sizeof(char);
	
	dst8Blending.height = height * count;
	dst8Blending.width = width;
	dst8Blending.rowBytes = width * sizeof(char);
	
	if( dst8.data) free( dst8.data);
	dst8.data = (char*) malloc( dst8.height * dst8.width * sizeof(char));
	if( dst8.data == nil) return;
	
	flipReader = nil;
	}

-(void) setOpacity:(NSArray*) array
{
	long i;
	NSPoint pt;
	
	NSLog(@"Opacity Table");
	
	opacityTransferFunction->RemoveAllPoints();
	
	if( [array count] > 0)
	{
		pt = NSPointFromString( [array objectAtIndex: 0]);
		pt.x -=1000;
		if(pt.x != 0) opacityTransferFunction->AddPoint(0, 0);
		else NSLog(@"start point");
	}
	else opacityTransferFunction->AddPoint(0, 0);
	
	for( i = 0; i < [array count]; i++)
	{
		pt = NSPointFromString( [array objectAtIndex: i]);
		pt.x -= 1000;
		opacityTransferFunction->AddPoint(pt.x, pt.y);
	}
	
	if( [array count] == 0 || pt.x != 256) opacityTransferFunction->AddPoint(255, 1);
	else
	{
		opacityTransferFunction->AddPoint(255, pt.y);
		NSLog(@"end point");
	}
	
	for( i = 0; i < 256; i++)
	{
		opacityTable[i] = opacityTransferFunction->GetValue(i);
	}
}

-(void) setWLWW: (float) l :(float) w
{
	wl = l;
	ww = w;
	
	vImageConvert_PlanarFtoPlanar8( &srcf, &dst8, wl + ww/2, wl - ww/2, 0);
	
	if( flipData == NO)
	{
		long			i, size;
		unsigned char   *tempPtr = (unsigned char*) malloc( height * width * count);
		
		size = height * width;
		
		for( i=0; i < count; i++)
		{
			memcpy(tempPtr+ (count-i-1)*size,  (unsigned char*) dst8.data + i*size, size);
		}
		free( dst8.data);
		dst8.data = tempPtr;
//		reader->SetImportVoidPointer(dst8.data);
	}
}

-(void) setBlendingWLWW: (float) l :(float) w
{
	if( imageBlendingPtr)
	{
		vImageConvert_PlanarFtoPlanar8( &srcfBlending, &dst8Blending, l + w/2, l - w/2, 0);
		
		if( flipData == NO)
		{
			long			i, size;
			unsigned char   *tempPtr = (unsigned char*) malloc( height * width * count);
			
			size = height * width;
			
			for( i=0; i < count; i++)
			{
				memcpy( tempPtr+ (count-i-1)*size, (unsigned char*) dst8Blending.data + i*size, size);
			}
			free( dst8Blending.data);
			dst8Blending.data = tempPtr;
		}
	}
}

-(void) setBlendingCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;
	
	NSLog(@"CLUT Table");
	
	if( r)
	{
		for( i = 0; i < 256; i++)
		{
			tableBlendingFloatR[i] = r[i];
			tableBlendingFloatG[i] = g[i];
			tableBlendingFloatB[i] = b[i];
		}
	//	colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	else
	{
		for( i = 0; i < 256; i++)
		{
			tableBlendingFloatR[i] = i;
			tableBlendingFloatG[i] = i;
			tableBlendingFloatB[i] = i;
		}
	//	colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
}

-(void) setCLUT:( unsigned char*) r : (unsigned char*) g : (unsigned char*) b
{
	long	i;

	NSLog(@"CLUT Table");
	
	if( r)
	{
		isRGB = YES;
		
		for( i = 0; i < 256; i++)
		{
			tableFloatR[i] = r[i];
			tableFloatG[i] = g[i];
			tableFloatB[i] = b[i];
		}
	//	colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
	else
	{
		isRGB = NO;
		
		for( i = 0; i < 256; i++)
		{
			tableFloatR[i] = i;
			tableFloatG[i] = i;
			tableFloatB[i] = i;
		}
	//	colorTransferFunction->BuildFunctionFromTable( 0, 255, 255, (double*) &table);
	}
}

- (void) setLowQuality:(BOOL) q
{
	lowQuality = q;
}

-(void) subRender:(NSDictionary*) dict
{
	long			x, i, from, to, size, pos, threads, slicesize;
	
	threads = [[NSProcessInfo processInfo] processorCount];
	pos = [[dict valueForKey:@"pos"] intValue];
	slicesize = [[dict valueForKey:@"size"] intValue];

	from = (pos * slicesize) / threads;
	to = ((pos+1) * slicesize) / threads;
	size = to - from;
	
	float			*dstFloatRi = dstFloatR + from, *dstFloatGi = dstFloatG + from, *dstFloatBi = dstFloatB + from;
	
	for( i = from; i < to; i+= 4)
	{
		float dstFloatRv1 = 0, dstFloatGv1 = 0, dstFloatBv1 = 0;
		float dstFloatRv2 = 0, dstFloatGv2 = 0, dstFloatBv2 = 0;
		float dstFloatRv3 = 0, dstFloatGv3 = 0, dstFloatBv3 = 0;
		float dstFloatRv4 = 0, dstFloatGv4 = 0, dstFloatBv4 = 0;
		
		float opacityTotPtr1 = 1, opacityTotPtr2 = 1, opacityTotPtr3 = 1, opacityTotPtr4 = 1;
		float opacityPtr1, opacityPtr2, opacityPtr3, opacityPtr4;
		
		unsigned char   *pixels = ((unsigned char*) dst8.data) +i;
		
		x = count;
		while( x-- > 0)
		{
			unsigned char val1, val2, val3, val4;   //= *pixels;
			long zz=0;
			
			val1 = *(pixels+0);
			opacityPtr1 = opacityTable[ val1];
			
			if( opacityPtr1 > opacityTotPtr1) {opacityPtr1 = opacityTotPtr1;  zz++;}
			opacityTotPtr1 -= opacityPtr1;
			
			val2 = *(pixels+1);
			opacityPtr2 = opacityTable[ val2];
			
			if( opacityPtr2 > opacityTotPtr2) {opacityPtr2 = opacityTotPtr2;  zz++;}
			opacityTotPtr2 -= opacityPtr2;
			
			val3 = *(pixels+2);
			opacityPtr3 = opacityTable[ val3];
			
			if( opacityPtr3 > opacityTotPtr3) {opacityPtr3 = opacityTotPtr3;  zz++;}
			opacityTotPtr3 -= opacityPtr3;
			
			val4 = *(pixels+3);
			opacityPtr4 = opacityTable[ val4];
			
			if( opacityPtr4 > opacityTotPtr4) {opacityPtr4 = opacityTotPtr4;  zz++;}
			opacityTotPtr4 -= opacityPtr4;
			
			if( zz == 4) x = 0;
			
			pixels += slicesize;
			
			dstFloatRv1 += opacityPtr1 * tableFloatR[ val1];
			dstFloatGv1 += opacityPtr1 * tableFloatG[ val1];
			dstFloatBv1 += opacityPtr1 * tableFloatB[ val1];

			dstFloatRv2 += opacityPtr2 * tableFloatR[ val2];
			dstFloatGv2 += opacityPtr2 * tableFloatG[ val2];
			dstFloatBv2 += opacityPtr2 * tableFloatB[ val2];

			dstFloatRv3 += opacityPtr3 * tableFloatR[ val3];
			dstFloatGv3 += opacityPtr3 * tableFloatG[ val3];
			dstFloatBv3 += opacityPtr3 * tableFloatB[ val3];

			dstFloatRv4 += opacityPtr4 * tableFloatR[ val4];
			dstFloatGv4 += opacityPtr4 * tableFloatG[ val4];
			dstFloatBv4 += opacityPtr4 * tableFloatB[ val4];
		}
		
		*dstFloatRi++ = dstFloatRv1;
		*dstFloatGi++ = dstFloatGv1;
		*dstFloatBi++ = dstFloatBv1;

		*dstFloatRi++ = dstFloatRv2;
		*dstFloatGi++ = dstFloatGv2;
		*dstFloatBi++ = dstFloatBv2;

		*dstFloatRi++ = dstFloatRv3;
		*dstFloatGi++ = dstFloatGv3;
		*dstFloatBi++ = dstFloatBv3;

		*dstFloatRi++ = dstFloatRv4;
		*dstFloatGi++ = dstFloatGv4;
		*dstFloatBi++ = dstFloatBv4;
	}
	
	[processorsLock lock];
	numberOfThreadsForCompute--;
	[processorsLock unlock];
}

-(unsigned char*) renderSlab
{
	unsigned char*  dst;
	
//	NSLog(@"IN");
	
//	if( ALTIVECVR)
//	{
		vImage_Buffer src, srcA, destR, destG, destB, dstARGB;
		long	i, x, size;
		
		unsigned char   *dstA, *dstPlan;

//		NSLog(@"IN");
		
		size = height * width;
		
		dst = (unsigned char*) malloc( height * width * 4);
		dstPlan = (unsigned char*) malloc( height * width * 4);
		
		dstFloatR = (float*) malloc( height * width * sizeof(float));		//bzero(dstFloatR, height * width * sizeof(float));
		dstFloatG = (float*) malloc( height * width * sizeof(float));		//bzero(dstFloatG, height * width * sizeof(float));
		dstFloatB = (float*) malloc( height * width * sizeof(float));		//bzero(dstFloatB, height * width * sizeof(float));
		
		dstA	= (unsigned char*) malloc( height * width);					memset(dstA, 255, height * width);
		
		if( imageBlendingPtr)
		{
			i = size;
			while( i-- > 0)
			{
				float			opacityTot = 1.0, opacity, opacityBlending, opacityAdd, dstFloatRv = 0, dstFloatGv = 0, dstFloatBv = 0;
				unsigned char   *pixels, *pixelsBlending;
				
				pixels = ((unsigned char*) dst8.data) +i;
				pixelsBlending = ((unsigned char*) dst8Blending.data) +i;
				
				x = count;
				while( x-- > 0)
				{
					unsigned char val = *pixels;
					unsigned char valBlending = *pixelsBlending;
					
					pixels += size;
					pixelsBlending += size;
					
					opacityBlending = opacityTable[ valBlending];
					opacity = opacityTable[ val];
					
					opacityAdd = opacity + opacityBlending;
					
					if( opacityAdd > opacityTot)
					{
						opacityBlending *= opacityTot/opacityAdd;
						opacity *= opacityTot/opacityAdd;
						
						x = 0;
					}
					else opacityTot -= opacityAdd;
					
					dstFloatRv += tableFloatR[ val]*opacity + tableBlendingFloatR[ valBlending]*opacityBlending;
					dstFloatGv += tableFloatG[ val]*opacity + tableBlendingFloatG[ valBlending]*opacityBlending;
					dstFloatBv += tableFloatB[ val]*opacity + tableBlendingFloatB[ valBlending]*opacityBlending;
				}
				
				dstFloatR[ i] = dstFloatRv;
				dstFloatG[ i] = dstFloatGv;
				dstFloatB[ i] = dstFloatBv;
			}
		}
		else
		{
			if( processorsLock == nil)
				processorsLock = [[NSLock alloc] init];
			
			numberOfThreadsForCompute = [[NSProcessInfo processInfo] processorCount];
			for( i = 0; i < [[NSProcessInfo processInfo] processorCount]-1; i++)
			{
				[NSThread detachNewThreadSelector: @selector(subRender:) toTarget:self withObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: size], @"size", [NSNumber numberWithInt: i], @"pos", nil]];
			}
			
			[self subRender: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: size], @"size", [NSNumber numberWithInt: i], @"pos", nil]];
			
			BOOL done = NO;
			while( done == NO)
			{
				[processorsLock lock];
				if( numberOfThreadsForCompute <= 0) done = YES;
				[processorsLock unlock];
			}
		}
		
		src.height = height;		src.width = width;			src.rowBytes = width*4;		src.data = dstFloatR;
		destR.height = height;		destR.width = width;		destR.rowBytes = width;		destR.data = dstPlan;
		vImageConvert_PlanarFtoPlanar8( &src, &destR, 255., 0., 0);

		src.height = height;		src.width = width;			src.rowBytes = width*4;		src.data = dstFloatG;
		destG.height = height;		destG.width = width;		destG.rowBytes = width;		destG.data = dstPlan + size;
		vImageConvert_PlanarFtoPlanar8( &src, &destG, 255., 0., 0);

		src.height = height;		src.width = width;			src.rowBytes = width*4;		src.data = dstFloatB;
		destB.height = height;		destB.width = width;		destB.rowBytes = width;		destB.data = dstPlan + size*2;
		vImageConvert_PlanarFtoPlanar8( &src, &destB, 255., 0., 0);
		
		srcA.height = height;		srcA.width = width;			srcA.rowBytes = width;		srcA.data = dstA;
		
		dstARGB.height = height;	dstARGB.width = width;		dstARGB.rowBytes = width*4; dstARGB.data = dst;
		vImageConvert_Planar8toARGB8888( &srcA, &destR, &destG, &destB, &dstARGB, 0);
		
		free( dstPlan);
		free( dstFloatR);
		free( dstFloatG);
		free( dstFloatB);
		free( dstA);
//		NSLog(@"OUT");

//	}
//	else
//	{
//		[[self window] orderBack:self];
//
//		if( lowQuality)
//		{
//			volumeMapper->SetMinimumImageSampleDistance( 4.0);
//			volumeProperty->SetInterpolationTypeToNearest();
//		}
//		else
//		{
//			volumeMapper->SetMinimumImageSampleDistance( 1.0);
//			volumeProperty->SetInterpolationTypeToLinear();
//		}
//		
//		[self renderWindow]->Render();
//		
//		rgbaImage = [self renderWindow]->GetRGBACharPixelData( 0, 0, width-1,height-1, 0);
//		
//		dst = (unsigned char*) malloc( height * width * 4);
//		
//		BlockMoveData( rgbaImage, dst, height * width * 4);
//		
//		delete rgbaImage;
//		
//		[[self window] orderOut:self];
//	}
	
	return dst;
}

@end
