/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




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

typedef struct {
   float x,y,z;
} XYZ;

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
	[newPixList release];
	[newDcmList release];
	[newPixListPer release];
	[newDcmListPer release];
	
	NSLog(@"Curved MPR Controller released");
	
	[super dealloc];
 }

-(float) lengthPoints:(NSPoint) mesureA :(NSPoint) mesureB :(float) ratio
{
	long yT, xT;
	float mesureLength;
	
	if( mesureA.x > mesureB.x) { yT = mesureA.y;  xT = mesureA.x;}
	else {yT = mesureB.y;   xT = mesureB.x;}
	
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

- (void) compute
{
	DCMPix		*firstObject = [pixList objectAtIndex:0];
	float		*emptyData, *curData,  length;
	long		size, newX, newY, i, x, y, z, xInc, noOfPoints, thick;
	NSData		*newData;
	NSArray		*pts = [selectedROI points];
	
	// Compute size of the curved MPR image
	
	newY = [pixList count];
	
	length = 0;
	for( i = 0; i < [pts count]-1; i++)
	{
		length += [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
	}
	newX = length + 4;
	newX /=4;
	newX *=4;
	
	size = newX * newY * sizeof( float);
	
	[newPixList removeAllObjects];
	[newDcmList removeAllObjects];
	
	// Allocate data for curved MPR image
	emptyData = (float*) malloc( size * thickSlab);
	if( emptyData)
	{
		newData = [NSData dataWithBytesNoCopy:emptyData length: size*thickSlab freeWhenDone:YES];
		
		for( thick = 0; thick < thickSlab; thick++)
		{
			// *** *** *** *** Create Image Data
			
			curData = emptyData + thick * newX * newY;
			
			xInc = 0;
			
			for( i = 0; i < [pts count]-1; i++)
			{
				float	xPos, yPos;
				float	sideX, sideY, startX, startY;
				float	angle, perAngle;
				long	pos;
				
				length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
				
				sideX = [[pts objectAtIndex:i] x] - [[pts objectAtIndex:i+1] x];
				sideY = [[pts objectAtIndex:i] y] - [[pts objectAtIndex:i+1] y];
				
				startX = [[pts objectAtIndex:i] x];
				startY = [[pts objectAtIndex:i] y];
				
				angle = atan( sideY / sideX);
				
				perAngle = 90*deg2rad - angle;
				
				if( sideX < 0)
				{
					startX += 1.5 * cos( perAngle) * (float) (thick - (thickSlab-1)/2);
					startY -= 1.5 * sin (perAngle) * (float) (thick - (thickSlab-1)/2);
				}
				else
				{
					startX -= 1.5 * cos( perAngle) * (float) (thick - (thickSlab-1)/2);
					startY += 1.5 * sin (perAngle) * (float) (thick - (thickSlab-1)/2);
				}
				
				noOfPoints = length;
				for( x = 0; x < noOfPoints; x++)
				{
					float	rightLeftX, rightLeftY;
					float	X1, X2, Y1, Y2;
					long	xInt, yInt, width, height;
					
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
					
					xInt = xPos;
					yInt = yPos;
					
					rightLeftX = xPos - (float) xInt;
					rightLeftY = yPos - (float) yInt;
					
					width = [[pixList objectAtIndex: 0] pwidth];
					height = [[pixList objectAtIndex: 0] pheight];
					
					if( yInt >= 0 && yInt < height-1 && xInt >= 0 && xInt < width+1)
					{
						long maxY = [pixList count];
						long yx1 = yInt * width + xInt+1;
						long yx = yInt * width + xInt;
						long y1x1 =  (yInt+1) * width + xInt+1;
						long y1x = (yInt+1) * width + xInt;
						float rightLeftXInv = 1.0 - rightLeftX;
						float rightLeftYInv = 1.0 - rightLeftY;
					
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
					else
					{
						for( y = 0; y < [pixList count] ; y++)
						{
							*(curData + x + xInc + newX*y) = -1000;
						}
					}
				}
				
				xInc += noOfPoints;
			}
			
			DCMPix	*pix = [[DCMPix alloc] initwithdata:curData :32 :newX :newY :[firstObject pixelSpacingX] :fabs( [firstObject sliceInterval]) :0 :0 :0 :YES];
			[pix changeWLWW: [[roiViewer imageView] curWL] : [[roiViewer imageView] curWW]];
			
			[pix setTot: thickSlab];
			[pix setFrameNo: thick];
			[pix setID: thick];
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
			viewerController = [[ViewerController alloc] viewCinit:newPixList :newDcmList :newData];
			
			[viewerController showWindowTransition];
			[viewerController startLoadImageThread]; // Start async reading of all images
			[viewerController setCurvedController: self];
			
			[appController tileWindows: self];
		}
		else
		{
			[viewerController changeImageData: newPixList :newDcmList :newData :NO];
		}
		
		[viewerController setImageIndex: (thickSlab-1)/2];
	}
}

- (void) computePerpendicular
{
	DCMPix		*firstObject = [pixList objectAtIndex:0];
	float		*emptyData, *curData,  length;
	long		size, newX, newY, i, x, y, z, xInc, noOfPoints, imageCounter = 0;
	NSData		*newData;
	NSArray		*pts = [selectedROI points];
	
	// Compute size of the curved MPR image
	
	newY = [pixList count];
	
	length = 0;
	xInc = 0;
	imageCounter = 0;
	for( i = 0; i < [pts count]-1; i++)
	{
		length += [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
		
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
		newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
		
	//	for( imNo = 0; imNo < length; imNo++)
		{
			
			xInc = 0;
			imageCounter = 0;
			
			for( i = 0; i < [pts count]-1; i++)
			{
				float	xPos, yPos, xPosA, yPosA, xPosB, yPosB;
				float	sideX, sideY, startX, startY;
				float	angle, perAngle;
				long	pos, imNo;
				
				length = [self lengthPoints: [[pts objectAtIndex:i] point]  :[[pts objectAtIndex:i+1] point] :[firstObject pixelRatio]];
				
				sideX = [[pts objectAtIndex:i] x] - [[pts objectAtIndex:i+1] x];
				sideY = [[pts objectAtIndex:i] y] - [[pts objectAtIndex:i+1] y];
				
				startX = [[pts objectAtIndex:i] x];
				startY = [[pts objectAtIndex:i] y];
				
				angle = atan( sideY / sideX);
				
				perAngle = 90*deg2rad - angle;
				
				noOfPoints = length;
				for( x = 0; x < noOfPoints; x++)
				{
					float	rightLeftX, rightLeftY;
					float	X1, X2, Y1, Y2, sideXPer;
					long	xInt, yInt, width, height;
					
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
							xPosA = xPos + cos( perAngle) * (float) (newX/2);
							yPosA = yPos - sin (perAngle) * (float) (newX/2);
							
							xPosB = xPos - cos( perAngle) * (float) (newX/2);
							yPosB = yPos + sin (perAngle) * (float) (newX/2);
						}
						else
						{
							xPosA = xPos - cos( perAngle) * (float) (newX/2);
							yPosA = yPos + sin (perAngle) * (float) (newX/2);
							
							xPosB = xPos + cos( perAngle) * (float) (newX/2);
							yPosB = yPos + sin (perAngle) * (float) (newX/2);
						}
						
						sideXPer = xPosB - xPosA;
						
						for( z = 0; z < newX; z++)
						{
							float	rightLeftX, rightLeftY;
							float	X1, X2, Y1, Y2;
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
							
							rightLeftX = xPos - (float) xInt;
							rightLeftY = yPos - (float) yInt;
							
							width = [[pixList objectAtIndex: 0] pwidth];
							height = [[pixList objectAtIndex: 0] pheight];
							
							if( yInt >= 0 && yInt < height-1 && xInt >= 0 && xInt < width+1)
							{
								long maxY = [pixList count];
								long yx1 = yInt * width + xInt+1;
								long yx = yInt * width + xInt;
								long y1x1 =  (yInt+1) * width + xInt+1;
								long y1x = (yInt+1) * width + xInt;
								float rightLeftXInv = 1.0 - rightLeftX;
								float rightLeftYInv = 1.0 - rightLeftY;
								
								
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
									*(curData + z + newX*y) = -1000;
								}
							}
						}

						DCMPix	*pix = [[DCMPix alloc] initwithdata:curData :32 :newX :newY :[firstObject pixelSpacingX] :fabs( [firstObject sliceInterval]) :0 :0 :0 :YES];
						[pix changeWLWW: [[roiViewer imageView] curWL] : [[roiViewer imageView] curWW]];
						
					//	[pix setTot: thickSlab];
						[pix setFrameNo: imageCounter];
						[pix setID: imageCounter];
						
						// Set Origin & Orientation
						float location[ 3 ];
						[[pixList objectAtIndex: 0] convertPixX: xPosA pixY: yPosA toDICOMCoords: location];
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
			viewerController = [[ViewerController alloc] viewCinit:newPixListPer :newDcmListPer :newData];
			
			[viewerController showWindowTransition];
			[viewerController startLoadImageThread];			// Start async reading of all images
			[viewerController setCurvedController: self];
			
			[appController tileWindows: self];
		}
		else
		{
			[viewerController changeImageData: newPixListPer :newDcmListPer :newData :NO];
		}
	}
}


- (id) initWithObjects:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) t
{
	long i;
	
	self = [super init];
	
	firstTime = YES;
	perPendicular = NO;
	
	thickSlab = t;

	roiViewer = roiV;

	fileList = files;
	[fileList retain];
	
	pixList = pix;
	[pixList retain];
	
	volumeData = vData;
	[volumeData retain];
	
	selectedROI = roi;
	[selectedROI retain];
	
	newPixList = [[NSMutableArray arrayWithCapacity: 0] retain];
	newDcmList = [[NSMutableArray arrayWithCapacity: 0] retain];
	newPixListPer = [[NSMutableArray arrayWithCapacity: 0] retain];
	newDcmListPer = [[NSMutableArray arrayWithCapacity: 0] retain];
	
	// Compute
	[self compute];
}

- (id) initWithObjectsPer:(NSMutableArray*) pix :(NSArray*) files :(NSData*) vData :(ROI*) roi :(ViewerController*) roiV :(long) i :(long) s
{
	self = [super init];
	
	firstTime = YES;
	perPendicular = YES;
	
	perSize = s;
	perInterval = i;

	roiViewer = roiV;

	fileList = files;
	[fileList retain];
	
	pixList = pix;
	[pixList retain];
	
	volumeData = vData;
	[volumeData retain];
	
	selectedROI = roi;
	[selectedROI retain];
	
	newPixList = [[NSMutableArray arrayWithCapacity: 0] retain];
	newDcmList = [[NSMutableArray arrayWithCapacity: 0] retain];
	newPixListPer = [[NSMutableArray arrayWithCapacity: 0] retain];
	newDcmListPer = [[NSMutableArray arrayWithCapacity: 0] retain];
	
	// Compute
	[self computePerpendicular];
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
