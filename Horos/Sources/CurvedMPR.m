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

#import "WaitRendering.h"
#import "CurvedMPR.h"

#import "ROI.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ViewerController.h"
#import "AppController.h"

#define CROSS(dest,v1,v2) \
          dest[0]=v1[1]*v2[2]-v1[2]*v2[1]; \
          dest[1]=v1[2]*v2[0]-v1[0]*v2[2]; \
          dest[2]=v1[0]*v2[1]-v1[1]*v2[0];


extern  AppController			*appController;

static		float					deg2rad = 3.14159265358979/180.0; 

/*
   Rotate a point p by angle theta around an arbitrary axis r
   Return the rotated point.
   Positive angles are anticlockwise looking down the axis
   towards the origin.
   Assume right hand coordinate system.
*/

XYZ ArbitraryRotateCurvedMPR(XYZ p,double theta,XYZ r)
{
   XYZ q = {0.0,0.0,0.0};
   float costheta,sintheta;

//   Normalise(&r);
   costheta = cos(theta);
   sintheta = sin(theta);

   q.x += (costheta + (1 - costheta) * r.x * r.x) * p.x;
   q.x += ((1 - costheta) * r.x * r.y - r.z * sintheta) * p.y;
   q.x += ((1 - costheta) * r.x * r.z + r.y * sintheta) * p.z;

   q.y += ((1 - costheta) * r.x * r.y + r.z * sintheta) * p.x;
   q.y += (costheta + (1 - costheta) * r.y * r.y) * p.y;
   q.y += ((1 - costheta) * r.y * r.z - r.x * sintheta) * p.z;

   q.z += ((1 - costheta) * r.x * r.z - r.y * sintheta) * p.x;
   q.z += ((1 - costheta) * r.y * r.z + r.x * sintheta) * p.y;
   q.z += (costheta + (1 - costheta) * r.z * r.z) * p.z;

   return(q);
}


@implementation CurvedMPR

 - (void) dealloc
 {
 	[fileList release];
	[pixList release];
	[volumeData release];
	[selectedROI release];
	
	NSLog(@"Curved MPR Controller released");
	
	[super dealloc];
 }
 
-(double) lengthPoints:(NSPoint) mesureA :(NSPoint) mesureB :(double) ratio
{
	long yT, xT;
	double mesureLength;
	
	if( mesureA.x > mesureB.x)
	{
		yT = mesureA.y;
		xT = mesureA.x;
	}
	else
	{
		yT = mesureB.y;
		xT = mesureB.x;
	}
	
	{
		double coteA, coteB;
		
		coteA = fabs(mesureA.x - mesureB.x);
		coteB = fabs(mesureA.y - mesureB.y) * ratio;
		
		if( coteA == 0) mesureLength = coteB;
		else if( coteB == 0) mesureLength = coteA;
		else mesureLength = coteB / (sin (atan( coteB / coteA)));
	}
	
	return mesureLength;
}

- (ROI*) roi
{
	return selectedROI;
}

//- (void) compute
//{
//	DCMPix		*firstObject = [pixList objectAtIndex:0];
//	float		*emptyData, *curData;
//	double		length;
//	long		size, newX, newY, i, x, y, z, xInc, noOfPoints, thick;
//	NSData		*newData;
//	//NSArray		*pts = [selectedROI points];
//	NSArray		*pts = [selectedROI splinePoints];
//	NSLog(@"[pts count] : %d", [pts count]);
//	// Compute size of the curved MPR image
//	
//	newY = [pixList count];
//	
//	length = 0;
//	for( i = 0; i < [pts count]-1; i++)
//	{
//		length += [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
//	}
//	newX = length + 4;
//	newX /=4;
//	newX *=4;
//	
//	size = newX * newY * sizeof( float);
//	
//	[newPixList removeAllObjects];
//	[newDcmList removeAllObjects];
//	
//	// Allocate data for curved MPR image
//	emptyData = (float*) malloc( size * thickSlab);
//	if( emptyData)
//	{
//		newData = [NSData dataWithBytesNoCopy:emptyData length:size*thickSlab freeWhenDone:YES];
//		
//		for( thick = 0; thick < thickSlab; thick++)
//		{
//			// *** *** *** *** Create Image Data
//			
//			curData = emptyData + thick * newX * newY;
//			
//			xInc = 0;
//			
//			for( i = 0; i < [pts count]-1; i++)
//			{
//				double	xPos, yPos;
//				double	sideX, sideY, startX, startY;
//				double	angle, perAngle;
//				long	pos;
//				
//				length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
//				
//				sideX = [[pts objectAtIndex:i] x] - [[pts objectAtIndex:i+1] x];
//				sideY = [[pts objectAtIndex:i] y] - [[pts objectAtIndex:i+1] y];
//				
//				startX = [[pts objectAtIndex:i] x];
//				startY = [[pts objectAtIndex:i] y];
//				
//				angle = atan( sideY / sideX);
//				
//				perAngle = 90*deg2rad - angle;
//				
//				if( sideX < 0)
//				{
//					startX += 1.5 * cos( perAngle) * (float) (thick - (thickSlab-1)/2);
//					startY -= 1.5 * sin (perAngle) * (float) (thick - (thickSlab-1)/2);
//				}
//				else
//				{
//					startX -= 1.5 * cos( perAngle) * (float) (thick - (thickSlab-1)/2);
//					startY += 1.5 * sin (perAngle) * (float) (thick - (thickSlab-1)/2);
//				}
//				
//				noOfPoints = length;
//				for( x = 0; x < noOfPoints; x++)
//				{
//					double	rightLeftX, rightLeftY;
//					double	X1, X2, Y1, Y2;
//					long	xInt, yInt, width, height;
//					
//					if( sideX >= 0)
//					{
//						xPos = startX - x * cos( angle);
//						yPos = startY - x * sin( angle);
//					}
//					else
//					{
//						xPos = startX + x * cos( angle);
//						yPos = startY + x * sin( angle);
//					}
//					
//					xInt = xPos;
//					yInt = yPos;
//					
//					rightLeftX = xPos - (double) xInt;
//					rightLeftY = yPos - (double) yInt;
//					
//					width = [[pixList objectAtIndex: 0] pwidth];
//					height = [[pixList objectAtIndex: 0] pheight];
//					
//					if( yInt >= 0 && yInt < height-1 && xInt >= 0 && xInt < width+1)
//					{
//						long maxY = [pixList count];
//						long yx1 = yInt * width + xInt+1;
//						long yx = yInt * width + xInt;
//						long y1x1 =  (yInt+1) * width + xInt+1;
//						long y1x = (yInt+1) * width + xInt;
//						double rightLeftXInv = 1.0 - rightLeftX;
//						double rightLeftYInv = 1.0 - rightLeftY;
//					
//						if( [firstObject sliceInterval] > 0)
//						{
//							for( y = 0; y < maxY ; y++)
//							{
//								float *srcIm = [[pixList objectAtIndex: y] fImage];
//								
//								*(curData + x + xInc + newX*(maxY-y-1)) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
//							}
//						}
//						else
//						{
//							for( y = 0; y < maxY ; y++)
//							{
//								float *srcIm = [[pixList objectAtIndex: y] fImage];
//								
//								*(curData + x + xInc + newX*y) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
//							}
//						}
//					}
//					else
//					{
//						for( y = 0; y < [pixList count] ; y++)
//						{
//							*(curData + x + xInc + newX*y) = -1000.0;
//						}
//					}
//				}
//				
//				xInc += noOfPoints;
//			}
//			
//			DCMPix	*pix = [[DCMPix alloc] initWithData:curData :32 :newX :newY :[firstObject pixelSpacingX] :fabs( [firstObject sliceInterval]) :0 :0 :0 :YES];
//			[pix changeWLWW: [[roiViewer imageView] curWL] : [[roiViewer imageView] curWW]];
//			
//			[pix setTot: thickSlab];
//			[pix setFrameNo: thick];
//			[pix setID: thick];
//			[pix copySUVfrom: firstObject];
//			
//		//	[pix setSliceLocation: thick * [firstObject pixelSpacingX]];
//			
//			float newVector[ 9];
//			for( i = 0; i < 9; i++) newVector[ i] = 0;
//			[pix setOrientation: newVector];
//			
//			[newPixList addObject: pix];
//			[newDcmList addObject: [fileList objectAtIndex: 0]];
//			
//			[pix release];
//		}
//		
//		if( firstTime == YES)
//		{
//			firstTime = NO;
//			
//			// CREATE A SERIES
//			viewerController = [[ViewerController alloc] initWithPix:newPixList withFiles:newDcmList withVolume:newData];
//			
//			[viewerController showWindowTransition];
//			[viewerController startLoadImageThread]; // Start async reading of all images
//			[viewerController setCurvedController: self];
//			
//			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
//				[appController tileWindows: nil];
//			else
//				[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
//		}
//		else
//		{
//			[viewerController changeImageData: newPixList :newDcmList :newData :NO];
//		}
//		
//		[viewerController setImageIndex: (thickSlab-1)/2];
//	}
//}

- (void) computePerpendicular
{
	NSMutableArray			*newDcmList, *newPixList;
	NSMutableArray			*newDcmListPer, *newPixListPer;

	newPixList = [NSMutableArray array];
	newDcmList = [NSMutableArray array];
	newPixListPer = [NSMutableArray array];
	newDcmListPer = [NSMutableArray array];

	DCMPix		*firstObject = [pixList objectAtIndex:0];
	float		*emptyData, *curData;
	double		length;
	long long	size;
	long		newX, newY, i, x, y, z, xInc, noOfPoints, imageCounter = 0;
	NSData		*newData;
	NSArray		*pts = [selectedROI splinePoints];
	
	// Compute size of the curved MPR image
	
	newY = [pixList count];
	
	length = 0;
	xInc = 0;
	imageCounter = 0;
	for( i = 0; i < [pts count]-1; i++)
	{
		length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
		
		for( x = 0; x < length; x++)
		{
			if( xInc % perInterval == 0)
			{
				imageCounter++;
			}
			xInc++;
		}
	}
	newX = perSize;
	newX /=4;
	newX *=4;
	
	newY /= 2;
	newY *= 2;
	
	size = newX * newY * sizeof( float) * imageCounter;
	
	[newPixListPer removeAllObjects];
	[newDcmListPer removeAllObjects];
	
	// Allocate data for curved MPR image
	emptyData = (float*) malloc( size);
	if( emptyData)
	{
		memset(emptyData, -1000.0, size);
		newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
		
	//	for( imNo = 0; imNo < length; imNo++)
		{
			
			xInc = 0;
			imageCounter = 0;
			
			for( i = 0; i < [pts count]-1; i++)
			{
				double	xPos, yPos, xPosA, yPosA, xPosB, yPosB;
				double	sideX, sideY, startX, startY;
				double	angle, perAngle;
				
				// joris
				length = 0;
				long j = 0;
				while (length < 1 && i+j<[pts count]-1)
				{
					j++;
					length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+j] point] :[firstObject pixelRatio]];
				}
				i = i+j-1;
				
				sideX = [[pts objectAtIndex:i] x] - [[pts objectAtIndex:i+1] x];
				sideY = [[pts objectAtIndex:i] y] - [[pts objectAtIndex:i+1] y];
				
				startX = [[pts objectAtIndex:i] x];
				startY = [[pts objectAtIndex:i] y];
				
				angle = atan( sideY / sideX);
				
				perAngle = 90*deg2rad - angle;
				
				noOfPoints = length;
				for( x = 0; x < noOfPoints; x++)
				{
					double	sideXPer;
					
					if( xInc % perInterval == 0)
					{
						if( sideX >= 0)
						{
							xPos = startX - x * cos( angle);
							yPos = startY - x * sin( angle);
						}
						else
						{
							xPos = startX + x * cos( angle);
							yPos = startY + x * sin( angle);
						}
						
						curData = emptyData + imageCounter * newX * newY;
						
						if( sideX < 0)
						{
							xPosA = xPos + cos( perAngle) * (double) (newX/2);
							yPosA = yPos - sin (perAngle) * (double) (newX/2);
							
							xPosB = xPos - cos( perAngle) * (double) (newX/2);
							yPosB = yPos + sin (perAngle) * (double) (newX/2);
						}
						else
						{
							xPosA = xPos - cos( perAngle) * (double) (newX/2);
							yPosA = yPos + sin (perAngle) * (double) (newX/2);
							
							xPosB = xPos + cos( perAngle) * (double) (newX/2);
							yPosB = yPos + sin (perAngle) * (double) (newX/2);
						}
						
						sideXPer = xPosB - xPosA;
						
						for( z = 0; z < newX; z++)
						{
							double	rightLeftX, rightLeftY;
							
							long	xInt, yInt, width, height;
							
							if( sideX >= 0)
							{
								xPos = xPosA + z * cos( perAngle);
								yPos = yPosA - z * sin( perAngle);
							}
							else
							{
								xPos = xPosA - z * cos( perAngle);
								yPos = yPosA + z * sin( perAngle);
							}
							
							xInt = xPos;
							yInt = yPos;
							
							rightLeftX = xPos - (double) xInt;
							rightLeftY = yPos - (double) yInt;
							
							width = [[pixList objectAtIndex: 0] pwidth];
							height = [[pixList objectAtIndex: 0] pheight];
							
							if( yInt >= 0 && yInt < height-1 && xInt >= 0 && xInt < width+1)
							{
								long maxY = [pixList count];
								long yx1 = yInt * width + xInt+1;
								long yx = yInt * width + xInt;
								long y1x1 =  (yInt+1) * width + xInt+1;
								long y1x = (yInt+1) * width + xInt;
								double rightLeftXInv = 1.0 - rightLeftX;
								double rightLeftYInv = 1.0 - rightLeftY;
								
								
								if( [firstObject sliceInterval] > 0)
								{
									for( y = 0; y < maxY ; y++)
									{
										float *srcIm = [[pixList objectAtIndex: y] fImage];
										
										*(curData + z + newX*(maxY-y-1)) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
									}
								}
								else
								{
									for( y = 0; y < maxY ; y++)
									{
										float *srcIm = [[pixList objectAtIndex: y] fImage];
										
										*(curData + z + newX*y) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
									}
								}
							}
							else
							{
								for( y = 0; y < [pixList count] ; y++)
								{
									*(curData + z + newX*y) = -1000.0;
								}
							}
						}

						DCMPix	*pix = [[DCMPix alloc] initWithData:curData :32 :newX :newY :[firstObject pixelSpacingX] :fabs( [firstObject sliceInterval]) :0 :0 :0 :YES];
						[pix changeWLWW: [[roiViewer imageView] curWL] : [[roiViewer imageView] curWW]];
						
					//	[pix setTot: thickSlab];
						[pix setFrameNo: imageCounter];
						[pix setID: imageCounter];
						[pix copySUVfrom: firstObject];
						[pix setSourceFile: [firstObject sourceFile]];
						[pix setImageObj: [firstObject imageObj]];
						[pix reloadAnnotations];
			
						// Set Origin & Orientation
						float location[ 3 ];
						[[pixList objectAtIndex: [pixList count]-1] convertPixX: xPosA pixY: yPosA toDICOMCoords: location pixelCenter: NO];
						[pix setOrigin: location];
						
						float vector[ 9];
						float newVector[ 9];
						
						[[pixList objectAtIndex: 0] orientation: vector];
						
						CROSS( (newVector+6), vector, (vector+6));
						newVector[ 0] = vector[ 0];
						newVector[ 1] = vector[ 1];
						newVector[ 2] = vector[ 2];
						CROSS( (newVector+3), newVector, (newVector+6));
						
						XYZ vN, vO, r;
						
						vN.x = newVector[ 6];		vN.y = newVector[ 7];		vN.z = newVector[ 8];
						vO.x = vector[ 6];			vO.y = vector[ 7];			vO.z = vector[ 8];
						
						r = ArbitraryRotateCurvedMPR( vN, angle + 90*deg2rad, vO);
						
						newVector[ 6] = r.x;
						newVector[ 7] = r.y;
						newVector[ 8] = r.z;
						
						vN.x = newVector[ 0];		vN.y = newVector[ 1];		vN.z = newVector[ 2];
						vO.x = vector[ 6];			vO.y = vector[ 7];			vO.z = vector[ 8];
						
						r = ArbitraryRotateCurvedMPR( vN, angle + 90*deg2rad, vO);
						
						newVector[ 0] = r.x;
						newVector[ 1] = r.y;
						newVector[ 2] = r.z;
						
						vN.x = newVector[ 3];		vN.y = newVector[ 4];		vN.z = newVector[ 5];
						vO.x = vector[ 6];			vO.y = vector[ 7];			vO.z = vector[ 8];
						
						r = ArbitraryRotateCurvedMPR( vN, angle + 90*deg2rad, vO);
						
						newVector[ 3] = r.x;
						newVector[ 4] = r.y;
						newVector[ 5] = r.z;

						
						[pix setOrientation: newVector];
						[pix setSliceLocation: imageCounter * [firstObject pixelSpacingX]];
					
						[newPixListPer addObject: pix];
						[newDcmListPer addObject: [fileList objectAtIndex: 0]];
						[pix release];
						
						imageCounter++;
					}
					
					xInc++;
				}
				
				//xInc += noOfPoints;
			}
		}
		
		for( i = 0; i < [newPixListPer count]; i++)
		{
			[[newPixListPer objectAtIndex: i] setTot: imageCounter];
		}
		
		if( firstTime == YES)
		{
			firstTime = NO;
			
			// CREATE A SERIES
			viewerController = [[ViewerController alloc] initWithPix:newPixListPer withFiles:newDcmListPer withVolume:newData];
			
			[viewerController showWindowTransition];
			[viewerController startLoadImageThread];			// Start async reading of all images
			[viewerController setCurvedController: self];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
				[appController tileWindows: nil];
			else
				[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
		}
		else
		{
			[viewerController changeImageData: newPixListPer :newDcmListPer :newData :YES];
		}
	}
}


- (void) computeForView:(short)view
{
	NSMutableArray			*newDcmList, *newPixList;
	NSMutableArray			*newDcmListPer, *newPixListPer;
	
	NSLog(@"computeForView : %d", view);
	/*
		values for 'view':
		0 - axial
		1 - coronal
		2 - sagittal
	*/

	newPixList = [NSMutableArray array];
	newDcmList = [NSMutableArray array];
	newPixListPer = [NSMutableArray array];
	newDcmListPer = [NSMutableArray array];

	DCMPix		*firstObject = [pixList objectAtIndex:0];
	float		*emptyData, *curData;
	double		length;
	long		size, newX, newY, i, j, x, y, xInc, noOfPoints, thick;
	NSData		*newData;
	NSArray		*pts = [selectedROI splinePoints];
	
	// Compute size of the curved MPR image
	length = 0;
	if(view==0)
	{
		newY = [pixList count];
		for( i = 0; i < [pts count]-1; i++)
		{
			length += [self lengthPoints:[[pts objectAtIndex:i] point] :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
		}
	}
	else if(view==1) // coronal
	{
		pts = [selectedROI points];
		newY = [firstObject pheight];
		for(i=0; i<[pts count]-1; i++)
		{
			NSPoint ptA = [[pts objectAtIndex:i] point];
			NSPoint ptB = [[pts objectAtIndex:i+1] point];
			NSPoint newPtA = NSMakePoint(ptA.x,[[[selectedROI zPositions] objectAtIndex:i] floatValue]);
			NSPoint newPtB = NSMakePoint(ptB.x,[[[selectedROI zPositions] objectAtIndex:i+1] floatValue]);
			//float newRatio = [[selectedROI pix] sliceInterval] / [[selectedROI pix] pixelSpacingX];
			double newRatio = [firstObject pixelRatio];
			length += [self lengthPoints:newPtA :newPtB :newRatio];
		}
	}
	else if(view==2) // sagittal
	{
		pts = [selectedROI points];
		newY = [firstObject pwidth];
		for(i=0; i<[pts count]-1; i++)
		{
			NSPoint ptA = [[pts objectAtIndex:i] point];
			NSPoint ptB = [[pts objectAtIndex:i+1] point];
			NSPoint newPtA = NSMakePoint(ptA.y,[[[selectedROI zPositions] objectAtIndex:i] floatValue]);
			NSPoint newPtB = NSMakePoint(ptB.y,[[[selectedROI zPositions] objectAtIndex:i+1] floatValue]);
			//float newRatio = [[selectedROI pix] sliceInterval] / [[selectedROI pix] pixelSpacingY];
			double newRatio = [firstObject pixelRatio];
			length += [self lengthPoints:newPtA :newPtB :newRatio];
		}	
	}
	
	newX = length + 4;
	newX /=4;
	newX *=4;
	
	size = newX * newY * sizeof( float);
	
	[newPixList removeAllObjects];
	[newDcmList removeAllObjects];
	
	// Allocate data for curved MPR image
	emptyData = (float*) malloc( size * thickSlab);
	if(emptyData)
	{
		int pixs = newX * newY * thickSlab;
		float minPix = [[pixList objectAtIndex: 0] minValueOfSeries];
		
		for( i = 0; i < pixs; i++)
		{
			emptyData[ i] = minPix;
		}
		
		newData = [NSData dataWithBytesNoCopy:emptyData length:size*thickSlab freeWhenDone:YES];
		
		for(thick=0; thick<thickSlab; thick++)
		{
			// *** *** *** *** Create Image Data
			
			curData = emptyData + thick * newX * newY;
			
			xInc = 0;
			
			double remainingLength = 0.0;
			
			for( i = 0; i < [pts count]-1; i++)
			{
				double xPos, yPos;
				double sideX, sideY, startX, startY;
				double angle, perAngle;
				long  width, height;
				long maxY;
				
				length = 0;
				j = 0;
				while (length < 2 && i+j<[pts count]-1)
				{
					j++;
					if(view==0)
					{
						length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+j] point] :[firstObject pixelRatio]];
						
						sideX = [[pts objectAtIndex:i] x] - [[pts objectAtIndex:i+j] x];
						sideY = [[pts objectAtIndex:i] y] - [[pts objectAtIndex:i+j] y];
						
						startX = [[pts objectAtIndex:i] x];
						startY = [[pts objectAtIndex:i] y];
						
						width = [[pixList objectAtIndex: 0] pwidth];
						height = [[pixList objectAtIndex: 0] pheight];

						maxY = [pixList count];
					}
					else
					{
						NSPoint ptA, ptB, newPtA, newPtB;
						double newRatio;
						if(view==1) // coronal
						{
							pts = [selectedROI points];
							ptA = [[pts objectAtIndex:i] point];
							ptB = [[pts objectAtIndex:i+j] point];
							newPtA = NSMakePoint(ptA.x,[[[selectedROI zPositions] objectAtIndex:i] floatValue]);
							newPtB = NSMakePoint(ptB.x,[[[selectedROI zPositions] objectAtIndex:i+j] floatValue]);
							//newRatio = [[selectedROI pix] sliceInterval] / [[selectedROI pix] pixelSpacingX];
							newRatio = [firstObject pixelRatio];				
							width = [[pixList objectAtIndex: 0] pwidth];
							maxY = [[pixList objectAtIndex: 0] pheight];
						}
						else if(view==2) // sagittal
						{
							pts = [selectedROI points];
							ptA = [[pts objectAtIndex:i] point];
							ptB = [[pts objectAtIndex:i+j] point];
							newPtA = NSMakePoint(ptA.y,[[[selectedROI zPositions] objectAtIndex:i] floatValue]);
							newPtB = NSMakePoint(ptB.y,[[[selectedROI zPositions] objectAtIndex:i+j] floatValue]);
							//newRatio = [[selectedROI pix] sliceInterval] / [[selectedROI pix] pixelSpacingY];
							newRatio = [firstObject pixelRatio];
							width = [[pixList objectAtIndex: 0] pheight];
							maxY = [[pixList objectAtIndex: 0] pwidth];
						}
						height = [pixList count];
						
						length = [self lengthPoints:newPtA :newPtB :newRatio];
						
						sideX = newPtA.x - newPtB.x;
						sideY = newPtA.y - newPtB.y;
						
						startX = newPtA.x;
						startY = newPtA.y;
					}
				}
				i = i+j-1;
				
				angle = atan( sideY / sideX);
				perAngle = 90*deg2rad - angle;
								
				if( sideX < 0)
				{
					startX += 1.5 * cos(perAngle) * (double) (thick - (thickSlab-1)/2);
					startY -= 1.5 * sin(perAngle) * (double) (thick - (thickSlab-1)/2);
				}
				else
				{
					startX -= 1.5 * cos(perAngle) * (double) (thick - (thickSlab-1)/2);
					startY += 1.5 * sin(perAngle) * (double) (thick - (thickSlab-1)/2);
				}
				
				double reallength = length;
				
				length += remainingLength;
				noOfPoints = length;
				double nextPixel = reallength / (double) noOfPoints;
				remainingLength = length - (double)noOfPoints;
				
				for(x=0; x<noOfPoints; x++)
				{
					double rightLeftX, rightLeftY;
					long xInt, yInt;
					
					if( sideX >= 0)
					{
						xPos = startX - x*nextPixel * cos( angle);
						yPos = startY - x*nextPixel * sin( angle);
					}
					else
					{
						xPos = startX + x*nextPixel * cos( angle);
						yPos = startY + x*nextPixel * sin( angle);
					}
					
					xInt = xPos;
					yInt = yPos;

					rightLeftX = xPos - (double) xInt;
					rightLeftY = yPos - (double) yInt;
					
					if( yInt >= 0 && yInt < height-1 && xInt >= 0 && xInt < width+1)
					{
						long yx1 = yInt * width + xInt+1;
						long yx = yInt * width + xInt;
						long y1x1 =  (yInt+1) * width + xInt+1;
						long y1x = (yInt+1) * width + xInt;
						
						double rightLeftXInv = 1.0 - rightLeftX;
						double rightLeftYInv = 1.0 - rightLeftY;
						
						if(view==0)
						{
							if( [firstObject sliceInterval] > 0)
							{
								for( y = 0; y < maxY ; y++)
								{
									float *srcIm = [[pixList objectAtIndex: y] fImage];
									
									*(curData + x + xInc + newX*(maxY-y-1)) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
								}
							}
							else
							{
								for( y = 0; y < maxY ; y++)
								{
									float *srcIm = [[pixList objectAtIndex: y] fImage];
									
									*(curData + x + xInc + newX*y) = (*(srcIm + y1x1) * rightLeftX + *(srcIm + y1x) * rightLeftXInv) * rightLeftY  + (*(srcIm + yx1) * rightLeftX + *(srcIm + yx) * rightLeftXInv) * rightLeftYInv;
								}
							}
						}
						else if(view==1) // coronal
						{
							float *srcIm = nil, *srcIm1 = nil;
							
							if( [[roiViewer imageView] flippedData])
							{
								srcIm = [[pixList objectAtIndex: height-yInt-1] fImage];
								srcIm1 = [[pixList objectAtIndex: height-yInt-2] fImage];							
							}
							else
							{
								srcIm = [[pixList objectAtIndex: yInt] fImage];
								srcIm1 = [[pixList objectAtIndex: yInt+1] fImage];

							}
							
							for( y = 0; y < maxY ; y++)
							{
								*(curData + x + xInc + newX*y) = (*(srcIm1 + xInt + 1 + y * width) * rightLeftX + *(srcIm1 + xInt + y * width) * rightLeftXInv) * rightLeftY  + (*(srcIm + xInt + 1 + y * width) * rightLeftX + *(srcIm + xInt + y * width) * rightLeftXInv) * rightLeftYInv;
							}
						}
						else if(view==2) // sagittal
						{
							float *srcIm = nil, *srcIm1 = nil;
							
							if( [[roiViewer imageView] flippedData])
							{
								srcIm = [[pixList objectAtIndex: height-yInt-1] fImage];
								srcIm1 = [[pixList objectAtIndex: height-yInt-2] fImage];							
							}
							else
							{
								srcIm = [[pixList objectAtIndex: yInt] fImage];
								srcIm1 = [[pixList objectAtIndex: yInt+1] fImage];

							}
							
							for( y = 0; y < maxY ; y++)
							{
								*(curData + x + xInc + newX*y) = (*(srcIm1 + (xInt + 1) * width + y) * rightLeftX + *(srcIm1 + xInt * width + y) * rightLeftXInv) * rightLeftY  + (*(srcIm + (xInt + 1) * width + y) * rightLeftX + *(srcIm + xInt * width + y) * rightLeftXInv) * rightLeftYInv;
							}
						}
					}
					else
					{
						if(view==0)
						{
							for( y = 0; y < [pixList count] ; y++)
							{
								*(curData + x + xInc + newX*y) = [[pixList objectAtIndex: 0] minValueOfSeries];
							}
						}
						else if(view==1) // coronal
						{
							for( y = 0; y < newY ; y++)
							{
								*(curData + x + xInc + newX*y) = [[pixList objectAtIndex: 0] minValueOfSeries];
							}
						}
						else if(view==2) // sagittal
						{
							for( y = 0; y < newY ; y++)
							{
								*(curData + x + xInc + newX*y) = [[pixList objectAtIndex: 0] minValueOfSeries];
							}
						}
					}
				}
				
				xInc += noOfPoints;
			}
			
			float xSpace, ySpace;
			if(view==0)
			{
				xSpace = [firstObject pixelSpacingX];
				ySpace = fabs([firstObject sliceInterval]);
			}
			else if(view==1) // coronal
			{
				xSpace = fabs([firstObject sliceInterval]);
				ySpace = [firstObject pixelSpacingX];
			}
			else if(view==2) // sagittal
			{
				xSpace = fabs([firstObject sliceInterval]);
				ySpace = [firstObject pixelSpacingX];
			}
			
			DCMPix	*pix = [[DCMPix alloc] initWithData:curData :32 :newX :newY :xSpace :ySpace :0 :0 :0 :YES];
			[pix changeWLWW: [[roiViewer imageView] curWL] : [[roiViewer imageView] curWW]];
			
			[pix copySUVfrom: firstObject];
			[pix setTot: thickSlab];
			[pix setFrameNo: thick];
			[pix setID: thick];
			[pix setSourceFile: [firstObject sourceFile]];
			[pix setImageObj: [firstObject imageObj]];
			[pix reloadAnnotations];
		//	[pix setSliceLocation: thick * [firstObject pixelSpacingX]];
			
			float newVector[ 9];
			for( i = 0; i < 9; i++) newVector[ i] = 0;
			[pix setOrientation: newVector];
			
			[newPixList addObject: pix];
			[newDcmList addObject: [fileList objectAtIndex: 0]];
			
			[pix release];
		}
		
		if( firstTime == YES)
		{
			firstTime = NO;
			
			// CREATE A SERIES
			viewerController = [[ViewerController alloc] initWithPix:newPixList withFiles:newDcmList withVolume:newData];
			
			[viewerController showWindowTransition];
			[viewerController startLoadImageThread]; // Start async reading of all images
			[viewerController setCurvedController: self];
			[viewerController checkEverythingLoaded];
			if(view==1 || view==2)
				[[viewerController imageView] setRotation:90];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"])
				[appController tileWindows: nil];
			else
				[[AppController sharedAppController] checkAllWindowsAreVisible: self makeKey: YES];
		}
		else
		{
			[viewerController changeImageData: newPixList :newDcmList :newData :YES];
		}
		
		[viewerController setImageIndex: (thickSlab-1)/2];
	}
}

- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t
{
	return [self initWithObjects:pix :files :vData :roi :roiV :t forAxial:YES forCoronal:YES forSagittal:YES];
}

- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t forView:(short)view
{
	if(view==0)
		return [self initWithObjects:pix :files :vData :roi :roiV :t forAxial:YES forCoronal:NO forSagittal:NO];
	else if(view==1)
		return [self initWithObjects:pix :files :vData :roi :roiV :t forAxial:NO forCoronal:YES forSagittal:NO];
	else if(view==2)
		return [self initWithObjects:pix :files :vData :roi :roiV :t forAxial:NO forCoronal:NO forSagittal:YES];
	
	return nil;
}

- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t forAxial:(BOOL)axial forCoronal:(BOOL)coronal forSagittal:(BOOL)sagittal
{
	
	self = [super init];
	
	WaitRendering *wait = [[WaitRendering alloc] init: NSLocalizedString(@"Processing curved-MPR...", nil)];
	[wait showWindow:self];
	
	firstTime = YES;
	perPendicular = NO;
	
	thickSlab = t;
	
	roiViewer = roiV;

	fileList = [NSMutableArray array];
	pixList = [NSMutableArray array];
	volumeData = nil;

	float factor = 0.5;
	while ( ![ViewerController resampleDataFromPixArray:pix fileArray:files inPixArray:pixList fileArray:fileList data:&volumeData withXFactor:factor yFactor:factor zFactor:1.0] && factor<=0.8)
	{
		factor += 0.1;
	}
	
	BOOL didResample = YES;
	if(factor > 0.8) didResample = NO;
	
	if(!didResample)
	{
		fileList = [NSMutableArray arrayWithArray:files];
		pixList = pix;
		volumeData = vData;
	}
	else
	{
		[[pixList objectAtIndex:0] setSliceInterval: [[pix objectAtIndex: 0] sliceInterval]];
		NSLog(@"factor : %f", factor);
	}
	[fileList retain];	
	[pixList retain];
	[volumeData retain];

	selectedROI = [NSUnarchiver unarchiveObjectWithData: [NSArchiver archivedDataWithRootObject: roi]];
	
	[selectedROI setOriginAndSpacing:[[pixList objectAtIndex:0] pixelSpacingX] : [[pixList objectAtIndex:0] pixelSpacingY] :[roi imageOrigin]];
	
	[selectedROI retain];
	
	// Compute
	if(axial)
		[self computeForView:0];
	firstTime = YES;
	if(coronal)
		[self computeForView:1];
	firstTime = YES;
	if(sagittal)
		[self computeForView:2];
	//firstTime = YES;

	[wait close];
	[wait release];


	return self;
}

- (id) initWithObjectsPer:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) i :(long) s
{
	self = [super init];
	
	firstTime = YES;
	perPendicular = YES;
	
	perSize = s;
	perInterval = i;

	roiViewer = roiV;

	fileList = [NSMutableArray arrayWithArray:files];
	[fileList retain];
	
	pixList = pix;
	[pixList retain];
	
	volumeData = vData;
	[volumeData retain];
	
	selectedROI = roi;
	[selectedROI retain];
	
	// Compute
	[self computePerpendicular];
	
	return self;
}

- (void) recompute
{
//	if( perPendicular)
//	{
//		[self computePerpendicular];
//	}
//	else
//	{
//		[self compute];
//	}
}

@end
