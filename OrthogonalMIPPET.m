//
//  OrthogonalMIPPET.m
//  OsiriX
//
//  Created by joris on 10/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OrthogonalMIPPET.h"

@implementation OrthogonalMIPPET

#pragma mark-
#pragma mark setup

- (id) initWithPixList : (NSArray*) newPixList{
	self = [super init];
	if (self != nil) {
		pixList = newPixList;
		line = 0L;
		imageWidth = [[pixList objectAtIndex:0] pwidth];
		imageHeight = [[pixList objectAtIndex:0] pwidth];
		generatedPixList = [[NSMutableArray alloc] initWithCapacity: 0];
		[self setAlpha:0.0];
	}
	return self;
}

- (void) dealloc {
	free(line);
	[super dealloc];
}

- (void) setAlphaDegres : (float) newAlpha
{
	float newAlphaRadian = newAlpha ;// 360.0 * (2.0*pi);
	[self setAlpha: newAlphaRadian];
}

- (void) setAlpha : (float) newAlpha
{

NSLog( @"alpha : %f", newAlpha);

	// angle defined by user
	alpha = newAlpha;
	//alpha += (alpha < 0)? 2.0*pi : 0 ;
	//alpha = (alpha >= pi)? alpha - pi : alpha;
//NSLog( @"alpha2 : %f", alpha);	
	// orthogonal angle : direction of the MIP
	//float sign = (alpha >= pi/2.0)? -1 : 1;
	//beta = alpha + sign * pi/2.0;
//	beta = alpha + pi/2.0;
//	beta += (beta < 0)? 2.0*pi : 0 ;
//	beta -= (beta > 2.0*pi)? 2.0*pi : 0 ;
//	beta = (beta >= pi)? beta - pi : beta;

	beta = alpha + 90;
	beta += (beta < 0)? 360 : 0 ;
	beta -= (beta > 360)? 360 : 0 ;
	beta = (beta >= 180)? beta - 180 : beta;
	
NSLog( @"beta : %f", beta);	
	if (beta == 0)
	{
		// y = 0
		lineLength = imageWidth;
		lineSlope = 0;
		fx = 1;
		fy = 0;
	}
	else if (beta == 90)
	{
		// x = 0
		lineLength = imageHeight;
		lineSlope = 0;
		fx = 0;
		fy = 1;
	}
	else if (beta<=45 || beta>=135)
	{
		// y = f(x) = lineSlope * x
		lineLength = imageWidth;
		//beta = beta / 360.0 * (2.0*pi);
		NSLog( @"tan(beta) : %f", tan( beta / 360.0 * (2.0*pi)));
		lineSlope = -tan( (float)beta / 360.0 * (2.0*pi));
		fx = 1;
		fy = 0;
	}
	else if (beta>45 && beta<135)
	{
		// x = f(y) = lineSlope * y
		//beta = (beta<=90)? 90-beta : 270 - beta;
		beta = 90-beta;
		NSLog( @"beta : %f", beta);
		//beta = beta / 360.0 * (2.0*pi);
		//NSLog( @"beta : %f", beta);
		lineLength = imageHeight;
		NSLog( @"tan(beta) : %f", tan( beta / 360.0 * (2.0*pi)));
		//lineSlope = -1.0/tan(beta);
		lineSlope = -tan((float)beta / 360.0 * (2.0*pi));
		fx = 0;
		fy = 1;
	}
	
	//NSLog( @"lineLength : %d", lineLength);	
	NSLog( @"lineSlope : %f", lineSlope);	
	NSLog( @"fx : %d", fx);	
	NSLog( @"fy : %d", fy);	

	if (line != 0L) free(line);
	line = (long*) malloc(lineLength * sizeof(long));
	[self computeLine];
	[self computeMIP];
}

#pragma mark-
#pragma mark shift line

- (long) lineEquation : (double) a
{
	// b(a) = s*a;
	return lineSlope * a;
}

- (void) computeLine
{
	long i;
	for (i=0; i<lineLength; i++)
	{
		line[i] = [self lineEquation:i];
	}
}

- (long) maxLine
{
	// max of f(x) = ax + b in [c;d] is : f(c) if a<0, f(d) if a>0
	return (lineSlope<0)? line[0] : line[lineLength-1];
}

- (void) shiftLineToStartPosition
{
	[self shiftLine:-[self maxLine]];
}

- (void) shiftLine : (long) shift
{	
	long i;
	for (i=0; i<lineLength; i++)
	{
		line[i] = line[i] + shift;
	}
}

#pragma mark -
#pragma mark MIP

- (void) computeMIP
{
NSLog( @"computeMIP");
	DCMPix		*firstPix = [pixList objectAtIndex: 0];
	DCMPix		*lastPix = [pixList lastObject];
	float		orientation[ 9], newXSpace, newYSpace, origin[ 3];
	// loop variables
	long shift, slice, i;
	
	// move the line to the start position
	long initialShift = abs(line[0]-line[lineLength-1]);
	NSLog(@"initialShift : %d", initialShift);
	//if (lineSlope>0) 
	[self shiftLine:(-1.0*initialShift)];
	NSLog(@"line[0] : %d", line[0]);
		
	// create the output image
	long newWidth = fy*imageWidth+fx*imageHeight+initialShift;
	NSLog(@"new image width : %d", newWidth);
	long MIPImageSize = sizeof(float) * newWidth * [pixList count]; // image weight in bytes
	NSLog(@"MIPImageSize : %d", MIPImageSize);
	unsigned char		*emptyData;
	emptyData = malloc(MIPImageSize);
	float sign = ([firstPix sliceInterval] > 0)? 1.0 : -1.0;
		
	if(emptyData)
	{
	
		[generatedPixList removeAllObjects];
	
		DCMPix	*generatedDCMPix;
//		if( [generatedPixList count] == 0)
//		{
			generatedDCMPix = [[[DCMPix alloc] initwithdata: (float*) emptyData :32 :newWidth :[pixList count] :1 :1 :0 :0 :0 :NO] autorelease];
			free(emptyData);
			[generatedPixList addObject: generatedDCMPix];
//		}
//		else generatedDCMPix = [generatedPixList objectAtIndex:0];
		
		[generatedDCMPix setTot: 0];
		[generatedDCMPix setFrameNo: 0];
		[generatedDCMPix setID: 0];
		
		// dimensions
		[generatedDCMPix setPwidth: newWidth];
		[generatedDCMPix setPheight: [pixList count]];
				
		// move the line on the whole axial plan.		
		for(shift=0 ; shift < newWidth ; shift++)
		{
			// take this line on each slice
			for(slice=0 ; slice < [pixList count] ; slice++)
			{
				DCMPix	*srcPix = [pixList objectAtIndex: slice];
				// retrieve the pixels of the image corresponding to the line
				// and compute MIP on this line of pixel
				float *srcP; //, *dstP[lineLength];
				float max = -1024.0;
				for(i=0; i<lineLength ; i++)
				{
					if ( line[i]>=0 && line[i]<(fy*imageWidth+fx*imageHeight))
					{
						srcP = [srcPix fImage] + (i*fy+line[i]*fx) * imageWidth + (line[i]*fy+i*fx); // ptrToPointXY = ptrToImageOrigin + y * w + x
						//*(dstP[i]) = *srcP;
						max = (*srcP>max)? *srcP : max ; //MIP
					}
				}
					//NSLog(@"max : %f", max);

				float *dest;
				if( sign < 0)
				{
					dest = [generatedDCMPix fImage] + slice * newWidth + shift;
				}
				else
				{
					dest = [generatedDCMPix fImage] + ([pixList count]-1-slice) * newWidth + shift;
				}
				
				*dest = max;
			}
			
			[self shiftLine:1]; // shift the line on 1 pixel for next iteration
		}
		// new pixel spacing
		float newXSpace, newYSpace;
		if(lineSlope!=0)
		{
			newXSpace = sqrt(pow((-fx+fy/lineSlope)/(lineSlope+1.0/lineSlope)*[firstPix pixelSpacingX],2) + pow((-fy+fx/lineSlope)/(lineSlope+1.0/lineSlope)*[firstPix pixelSpacingY],2));
		}
		else
		{
			newXSpace = fx * [firstPix pixelSpacingY] + fy * [firstPix pixelSpacingX];
		}
		newYSpace = fabs( [firstPix sliceInterval]);
		
		[generatedDCMPix setPixelSpacingX: newXSpace];
		[generatedDCMPix setPixelSpacingY: newYSpace];
		[generatedDCMPix setPixelRatio:  newYSpace / newXSpace];
	
		[generatedDCMPix setSliceLocation: 0];
		[generatedDCMPix setSliceThickness: 0];
		[generatedDCMPix setSliceInterval: 0];	
	}
	NSLog( @"computeMIP DONE !");
}

- (NSMutableArray*) result
{
	return generatedPixList;
}

#pragma mark -
#pragma mark accessors

- (float) alpha
{
	return alpha;
}

- (float) beta
{
	return beta;
}

@end
