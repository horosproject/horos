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

#import "OrthogonalReslice.h"
#import "WaitRendering.h"
#import "N2Debug.h"

#include <Accelerate/Accelerate.h>

@interface ResliceOperation: NSOperation
{
    NSDictionary *dict;
}

- (id) initWithDict:(NSDictionary *) d;

@end

@implementation ResliceOperation

- (id) initWithDict:(NSDictionary *) d
{
    self = [super init];
    dict = [d retain];
    
    return self;
}

- (void) main
{
    @autoreleasepool
    {
        NSLog( @"+");
        
        NSArray *originalDCMPixList = [dict objectForKey: @"DCMPixArray"];
        DCMPix *fPix = [originalDCMPixList objectAtIndex: 0];
        float *Ycache = [[dict objectForKey: @"Ycache"] pointerValue];
        
        int	z;
        const register int maxY = [fPix pheight];
        const register int maxX = [fPix pwidth];
        
        z = [[dict objectForKey:@"zValue"] intValue];
        
        register float *basedstPtr = Ycache + z*maxY*maxX;
        register float *basesrcPtr = [[originalDCMPixList objectAtIndex: z] fImage];
        register int x = maxX;
        while (x-->0)
        {
            register float *dstPtr = basedstPtr;
            register float *srcPtr = basesrcPtr;
            
            basedstPtr += maxY;
            basesrcPtr++;
            
            register int yy = maxY;
            while (yy-->0)
            {
                *dstPtr++ = *srcPtr;
                srcPtr += maxX;
            }
        }
    }
}

- (void) dealloc
{
    [dict release];
    [super dealloc];
}

@end


@implementation OrthogonalReslice

- (id) init
{
	if (self = [super init])
	{
		xReslicedDCMPixList = [[NSMutableArray alloc] initWithCapacity:0];
		yReslicedDCMPixList = [[NSMutableArray alloc] initWithCapacity:0];
		
		newPixListX = [[NSMutableArray alloc] initWithCapacity: 0];
		newPixListY = [[NSMutableArray alloc] initWithCapacity: 0];
		
		thickSlab = 1;
		Ycache = nil;
		useYcache = YES;
	}
	return self;
}

- (id) initWithOriginalDCMPixList: (NSMutableArray*) pixList
{
	self = [self init];

	[self setOriginalDCMPixList:pixList];
	
	float sliceInterval;
	
	if ([[pixList objectAtIndex:0] sliceInterval]==0)
	{
		sliceInterval = [[pixList objectAtIndex: 1] sliceLocation]-[[pixList objectAtIndex:0] sliceLocation];
	}
	else
	{
		sliceInterval = [[pixList objectAtIndex:0] sliceInterval];
	}
	
	sign = (sliceInterval > 0)? 1.0 : -1.0;
	
	return self;
}

- (void) setOriginalDCMPixList: (NSMutableArray*) pixList
{
	originalDCMPixList = pixList;
}

-(void) dealloc
{
    while( yCacheQueue.operationCount > 0)
        [NSThread sleepForTimeInterval: 0.1];
    [yCacheQueue release];
	if( Ycache) free( Ycache);
	
	[processorsLock release];
	[xReslicedDCMPixList release];
	[yReslicedDCMPixList release];
	[newPixListX release];
	[newPixListY release];
	[super dealloc];
}


- (void) xReslice: (long) x
{
 	[self axeReslice:0: x];
}

- (void) xResliceThread: (NSNumber*) xNum
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	@try 
	{
		[self xReslice: [xNum intValue]];
	
	}
	@catch (NSException * e) 
	{
		N2LogExceptionWithStackTrace(e);
	}
 	
//	[resliceLock unlockWithCondition: 1];
	
	[pool release];
}

- (void) yReslice: (long) y
{
	[self axeReslice:1:y];
}

// processors
- (void) reslice : (long) x : (long) y
{
//	resliceLock = [[NSConditionLock alloc] initWithCondition: 0];
//	
//	[NSThread detachNewThreadSelector:@selector(xResliceThread:) toTarget:self withObject: [NSNumber numberWithInt: y]];
//	[self yReslice:x];
//	[resliceLock lockWhenCondition: 1];
//	[resliceLock release];
	
	[self yReslice:x];
	[self xReslice:y];
}

- (void) subReslice:(NSNumber*) posNumber
{
	int i, x, y, stack, pos = [posNumber intValue];
	int threads = [[NSProcessInfo processInfo] processorCount];
	int from, to;
	
	from = (pos * newY) / threads;
	to = ((pos+1) * newY) / threads;
	
	for( i = minI, stack = 0 ; i < maxI ; i++, stack++)
	{
		if( i < 0) i = 0;
		if( i >= newTotal) i = newTotal-1;
		
		if( currentAxe == 0)		// X - RESLICE
		{
			
			DCMPix *curPix = [newPixListX objectAtIndex: stack];
			
			if( sign > 0)
			{
				float *srcP, *dstP, *curPixfImage = [curPix fImage];
				
				for( y = from; y < to; y++)
				{
					srcP = [[originalDCMPixList objectAtIndex: y] fImage] + i * newX;
						
					dstP = curPixfImage + (newY-y-1) * newX;

					memcpy(	dstP, srcP, newX *sizeof(float));
				}
			}
			else
			{
				float *srcP, *curPixfImage = [curPix fImage];
				
				for( y = from; y < to; y++)
				{
					srcP = [[originalDCMPixList objectAtIndex: y] fImage] + i * [firstPix pwidth];
						
					memcpy(	curPixfImage + y * newX, srcP, newX *sizeof(float));
				}
			}
		}
		else									// Y - RESLICE
		{
			register float	*srcPtr;
			register float	*dstPtr;
			register long	rowBytes = [firstPix pwidth];
			
			DCMPix *curPix = [newPixListY objectAtIndex: stack];
			
			if( Ycache && yCacheQueue.operationCount == 0)
			{
//				BlockMoveData(	Ycache + newY*newX*i,
//								[curPix fImage],
//								newX * newY *sizeof(float));


				if( sign > 0)
				{
					float		*srcP, *dstP, *curPixfImage = [curPix fImage];
					DCMPix		*srcPix = [originalDCMPixList objectAtIndex: 0];
					long		w = [srcPix pheight];
					
					for( y = from; y < to; y++)
					{
						srcP = Ycache + y*newTotal*newX + i * w;
						dstP = curPixfImage + (newY-y-1) * newX;
						
						memcpy(	dstP, srcP, newX *sizeof(float));
					}
				}
				else
				{
					float *srcP, *curPixfImage = [curPix fImage];
					
					for( y = from; y < to; y++)
					{
						srcP = Ycache + y*newTotal*newX + i * newTotal;
						
						memcpy(	curPixfImage + y * newX, srcP, newX *sizeof(float));
					}
				}
			}
			else
			{
				for(x = from; x < to; x++)
				{
					if( sign > 0)
					{
						srcPtr = [[originalDCMPixList objectAtIndex: newY-x-1] fImage] + i;
					}
					else
					{
						srcPtr = [[originalDCMPixList objectAtIndex: x] fImage] + i;
					}
					dstPtr = [curPix fImage] + x * newX;
					
					register long yy = newX;
					while (yy-->0)
					{
						*dstPtr++ = *srcPtr;
						srcPtr += rowBytes;
					}
				}
			}
		}
	}
	
	[processorsLock lock];
	numberOfThreadsForCompute--;
	[processorsLock unlock];
}

- (void) axeReslice: (short) axe : (long) sliceNumber
{
	firstPix = [originalDCMPixList objectAtIndex: 0];
	
	DCMPix				*lastPix = [originalDCMPixList lastObject];
	long				i, x;
	float				orientation[ 9], newXSpace, newYSpace, origin[ 3], sliceInterval;
	BOOL                isRGB = firstPix.isRGB;
	
	currentAxe = axe;

	if ([firstPix sliceInterval]==0)
	{
		sliceInterval = [[originalDCMPixList objectAtIndex: 1] sliceLocation]-[firstPix sliceLocation];
	}
	else
	{
		sliceInterval = [firstPix sliceInterval];
	}
    
	// Get Values
	if( axe == 0)		// X - RESLICE
	{
		newTotal = [firstPix pheight];
		newX = [firstPix pwidth];
		newXSpace = [firstPix pixelSpacingX];
		newYSpace = fabs(sliceInterval);
		newY = [originalDCMPixList count];
	}
	else				// Y - RESLICE
	{
		newTotal = [firstPix pwidth];
		newX = [firstPix pheight];
		newY = [originalDCMPixList count];
		newXSpace = [firstPix pixelSpacingY];
		newYSpace = fabs(sliceInterval);
	}
	
//	size = sizeof(float) * newX * newY;	// image weight in bytes
	
	// CREATE A NEW SERIES WITH *ONE* IMAGE !
	
	DCMPix	*curPix;
	long	stack = 0;
	
	if( thickSlab <= 1)
	{
		thickSlab = 1;
		minI = sliceNumber;
		maxI = minI+1;
		if( maxI > newTotal-1)
		{
			maxI = newTotal-1;
			minI = maxI-1;
		}
	}
	else
	{
		thickSlab = (thickSlab==0) ? 1 : thickSlab ;
		minI = sliceNumber-floor((float)thickSlab/2.0);
		maxI = sliceNumber+ceil((float)thickSlab/2.0);
		
		if( maxI > newTotal-1)
		{
			maxI = newTotal-1;
			if( minI == maxI) minI = maxI-1;
		}
	}
						
	// Y - CACHE activated only if thick slab and if enough memory is available
	if( axe != 0)
	{
		if( thickSlab > 1 && Ycache == nil)
		{
			if(useYcache)
				Ycache = malloc( newTotal*newY*newX*sizeof(float));
			
			if( Ycache)
			{
				NSLog( @"start YCache");
				
                yCacheQueue = [[NSOperationQueue alloc] init];
                
                for ( x = 0; x < newY; x ++)
                {
                    ResliceOperation *op = [[[ResliceOperation alloc] initWithDict: [NSDictionary dictionaryWithObjectsAndKeys: [NSValue valueWithPointer: Ycache], @"Ycache", [NSNumber numberWithInt:x], @"zValue", originalDCMPixList, @"DCMPixArray", nil]] autorelease];
                    
                    [yCacheQueue addOperation: op];
                }
			}
		}
	}
	
	if( axe == 0)		// X - RESLICE
	{
		if( sign > 0)
				[lastPix orientation: orientation];
		else
				[firstPix orientation: orientation];
		
		if( sign > 0)
		{
			// Y Vector = Normal Vector
			orientation[ 3] = orientation[ 6] * -sign;
			orientation[ 4] = orientation[ 7] * -sign;
			orientation[ 5] = orientation[ 8] * -sign;
		}
		else
		{
			// Y Vector = Normal Vector
			orientation[ 3] = orientation[ 6] * sign;
			orientation[ 4] = orientation[ 7] * sign;
			orientation[ 5] = orientation[ 8] * sign;
		}
	}
	else
	{
		if( sign > 0)
				[lastPix orientation: orientation];
		else
				[firstPix orientation: orientation];
		
		// Y Vector = Normal Vector
		orientation[ 0] = orientation[ 3];
		orientation[ 1] = orientation[ 4];
		orientation[ 2] = orientation[ 5];
		
		if( sign > 0)
		{
			orientation[ 3] = orientation[ 6] * -sign;
			orientation[ 4] = orientation[ 7] * -sign;
			orientation[ 5] = orientation[ 8] * -sign;
		}
		else
		{
			orientation[ 3] = orientation[ 6] * sign;
			orientation[ 4] = orientation[ 7] * sign;
			orientation[ 5] = orientation[ 8] * sign;
		}
	}
	
    int bits = 32;
    if( isRGB) bits = 8;
    
	for( i = minI, stack = 0 ; i < maxI ; i++, stack++)
	{
		if( i < 0) i = 0;
		
		if( axe == 0)		// X - RESLICE
		{
			if( stack >= [newPixListX count])
			{
				curPix = [[DCMPix alloc] initWithData: nil :bits :newX :newY :1 :1 :0 :0 :0 :NO];
				[curPix copySUVfrom: firstPix];
				curPix.frameofReferenceUID = firstPix.frameofReferenceUID;
				[newPixListX addObject: curPix];
				[curPix release];
			}
			else curPix = [newPixListX objectAtIndex: stack];
		}
		else
		{
			if( stack  >= [newPixListY count])
			{
				curPix = [[DCMPix alloc] initWithData: nil :bits :newX :newY :1 :1 :0 :0 :0 :NO];
				[curPix copySUVfrom: firstPix];
				curPix.frameofReferenceUID = firstPix.frameofReferenceUID;
				[newPixListY addObject: curPix];
				[curPix release];
			}
			else curPix = [newPixListY objectAtIndex: stack];
		}
		
		[curPix fImage];	// <- Force CheckLoad
		
		[curPix setTot: 0];
		[curPix setFrameNo: 0];
		[curPix setID: 0];
		
		if( axe == 0)		// X - RESLICE
		{
			[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
			
			[curPix setPixelSpacingX: newXSpace];
			[curPix setPixelSpacingY: newYSpace];
			
			[curPix setPixelRatio:  newYSpace / newXSpace];
			
			[curPix orientation: orientation];
			
			if( sign > 0)
			{
				origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * sign;
				origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * sign;
				origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * sign;
			}
			else
			{
				origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * -sign;
				origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * -sign;
				origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * -sign;
			}
			
            [curPix setOrigin: origin];
            [curPix computeSliceLocation];
            
			[curPix setSliceThickness: [firstPix pixelSpacingY]];
			[curPix setSliceInterval: [firstPix pixelSpacingY]];
		}
		else
		{
			[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
			
			[curPix setPixelSpacingX: newXSpace];
			[curPix setPixelSpacingY: newYSpace];
			
			[curPix setPixelRatio:  newYSpace / newXSpace];
			
			[curPix orientation: orientation];
			if( sign > 0)
			{
				origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * -sign;
				origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * -sign;
				origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * -sign;
			}
			else
			{
				origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * sign;
				origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * sign;
				origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * sign;
			}
			[curPix setOrigin: origin];
			[curPix computeSliceLocation];
            
			[curPix setSliceThickness: [firstPix pixelSpacingX]];
			[curPix setSliceInterval: [firstPix pixelSpacingY]];
		}
	}
	
	if( axe == 0)		// X - RESLICE
	{
		if( [newPixListX count] > stack)
			[newPixListX removeObjectsInRange: NSMakeRange( stack, [newPixListX count]-stack)];
	}
	else
	{
		if( [newPixListY count] > stack)
			[newPixListY removeObjectsInRange: NSMakeRange( stack, [newPixListY count]-stack)];
	}
	
	if( processorsLock == nil)
		processorsLock = [[NSLock alloc] init];
	
	numberOfThreadsForCompute = [[NSProcessInfo processInfo] processorCount];
	for( i = 0; i < [[NSProcessInfo processInfo] processorCount]-1; i++)
	{
		[NSThread detachNewThreadSelector: @selector(subReslice:) toTarget:self withObject: [NSNumber numberWithInt: i]];
	}
	
	[self subReslice: [NSNumber numberWithInt: i]];
	
	BOOL done = NO;
	while( done == NO)
	{
		[processorsLock lock];
		if( numberOfThreadsForCompute <= 0) done = YES;
		[processorsLock unlock];
	}
				
	if (axe == 0)
	{
		[xReslicedDCMPixList setArray:newPixListX];
	}
	else
	{
		[yReslicedDCMPixList setArray:newPixListY];
	}

}

// accessors
- (NSMutableArray*) originalDCMPixList
{
	return originalDCMPixList;
}

- (NSMutableArray*) xReslicedDCMPixList
{
	return xReslicedDCMPixList;
}

- (NSMutableArray*) yReslicedDCMPixList
{
	return yReslicedDCMPixList;
}

// thickSlab
- (short) thickSlab
{
	return thickSlab;
}

- (void) setThickSlab : (short) newThickSlab
{
	thickSlab = newThickSlab;
}

- (void) flipVolume
{
	sign = -sign;
} 

- (void)freeYCache;
{
	if(Ycache) free(Ycache);
	Ycache = nil;
}

- (BOOL)useYcache;
{
	return useYcache;
}

- (void)setUseYcache:(BOOL)boo;
{
	useYcache = boo;
	if(!boo)
		[self freeYCache];
}

@end
