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

#import "options.h"

//#import "Centerline.h"
#import "MyPoint.h"
#import "Notifications.h"


//#define id Id

#include <itkMultiThreader.h>
#include <itkImage.h>
#include <itkMesh.h>
#include <itkImportImageFilter.h>
#include <itkConnectedThresholdImageFilter.h>
#include <itkNeighborhoodConnectedImageFilter.h>
#include <itkConfidenceConnectedImageFilter.h>
#include <itkCurvatureFlowImageFilter.h>
#include <itkCastImageFilter.h>
#include <itkBinaryMaskToNarrowBandPointSetFilter.h>
//#include <itkBinaryMask3DMeshSource.h>
#include <itkGrayscaleDilateImageFilter.h>
#include <itkBinaryBallStructuringElement.h>

#include <itkAffineTransform.h>
#include <itkNearestNeighborInterpolateImageFunction.h>
#include <itkResampleImageFilter.h>

#include <vtkImageImport.h>
#include <vtkMarchingSquares.h>
#include <vtkPolyData.h>
#include <vtkCleanPolyData.h>
#include <vtkPolyDataConnectivityFilter.h>
#include <vtkCell.h>
#include <vtkContourFilter.h>
#include <vtkImageData.h>
#include <vtkDecimatePro.h>
#include <vtkSmoothPolyDataFilter.h>
//#include "vtkPowerCrustSurfaceReconstruction.h"
#include <vtkMarchingCubes.h>

//#undef id

#import "ViewerController.h"
#import "WaitRendering.h"
#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#import "MyPoint.h"
#import "OSIVoxel.h"
#import "AppController.h"
#import "ITKSegmentation3D.h"

@implementation ITKSegmentation3D

+ (NSArray*) fastGrowingRegionWithVolume: (float*) volume width:(long) w height:(long) h depth:(long) depth seedPoint:(long*) seed from:(float) from pixList:(NSArray*) pixList
{
	BOOL					found = YES, foundPlane = YES;
	long					minX, minY, minZ, maxX, maxY, maxZ;
	long					nminX, nminY, nminZ, nmaxX, nmaxY, nmaxZ;
	long					x, y, z, zz, s = w*h;
	float					*srcPtrZ, *srcPtrY, *srcPtrX;
	unsigned char			*rPtr, *rPtrZ, *rPtrY, *rPtrX;
	NSMutableArray			*roiList = [NSMutableArray array];
	
	if( seed[ 0] <= 1) seed[ 0] = 2;	if( seed[ 0] >= w - 2)		seed[ 0] = w - 3;
	if( seed[ 1] <= 1) seed[ 1] = 2;	if( seed[ 1] >= h - 2)		seed[ 1] = h - 3;
	if( seed[ 2] <= 1) seed[ 2] = 2;	if( seed[ 2] >= depth - 2)	seed[ 2] = depth - 3;
	
	minX = seed[ 0]-1;		maxX = seed[ 0]+2;
	minY = seed[ 1]-1;		maxY = seed[ 1]+2;
	minZ = seed[ 2];		maxZ = seed[ 2]+1;

	rPtr = (unsigned char*) calloc( w*h*depth, sizeof(unsigned char));
	if( rPtr)
	{
		rPtr[ seed[ 0]+1 + seed[ 1]*w + seed[ 2]*s] = 0xFE;
		
		while( found)
		{
			found = NO;
			
			if( minX <= 0) minX = 1;	if( maxX >= w - 1)		maxX = w - 1;
			if( minY <= 0) minY = 1;	if( maxY >= h - 1)		maxY = h - 1;
			if( minZ <= 0) minZ = 1;	if( maxZ >= depth - 1)	maxZ = depth - 1;
			
//			srcPtrZ = volume + minZ*s;
//			rPtrZ = rPtr + minZ*s;
			
			long addZ = maxZ-minZ-1;
			if( addZ == 0) addZ++;
			
			for( z = minZ; z < maxZ; z += addZ)
			{
				foundPlane = YES;
				while( foundPlane)
				{
					if( minX <= 0) minX = 1;	if( maxX >= w - 1)		maxX = w - 1;
					if( minY <= 0) minY = 1;	if( maxY >= h - 1)		maxY = h - 1;
					if( minZ <= 0) minZ = 1;	if( maxZ >= depth - 1)	maxZ = depth - 1;
					
					rPtrZ = rPtr + z*s;
					srcPtrZ = volume + z*s;

					foundPlane = NO;
					srcPtrY = srcPtrZ + minY*w  + minX;
					rPtrY = rPtrZ + minY*w  + minX;
					y = maxY-minY;
					while( y-- > 0)
					{
						srcPtrX = srcPtrY;
						rPtrX = rPtrY;
						
						x = maxX-minX;
						while( x-- > 0)
						{
							if( *rPtrX == 0xFE)
							{
								*rPtrX = 0xFF;
								
								if( *(rPtrX+1) == 0) {if( *(srcPtrX+1) > from) {	*(rPtrX+1) = 0xFE;}	else *(rPtrX+1) = 2;}
								if( *(rPtrX-1) == 0) {if( *(srcPtrX-1) > from) {	*(rPtrX-1) = 0xFE;}	else *(rPtrX-1) = 2;}
								if( *(rPtrX+w) == 0) {if(*(srcPtrX+w) > from) {	*(rPtrX+w) = 0xFE;}	else *(rPtrX+w) = 2;}
								if( *(rPtrX-w) == 0) {if(*(srcPtrX-w) > from) {	*(rPtrX-w) = 0xFE;}	else *(rPtrX-w) = 2;}
								
								foundPlane = YES;
							}
							rPtrX++;
							srcPtrX++;
						}
						
						srcPtrY+= w;
						rPtrY += w;
					}
					
					// Should we grow the box?
					if( foundPlane)
					{
						found = YES;
						
						nminX	=	minX;		nmaxX	=	maxX;
						nminY	=	minY;		nmaxY	=	maxY;
						
						// X plane
						
						rPtrZ = rPtr + minX + minZ*s;
						for( zz = minZ; zz < maxZ; zz++, rPtrZ += s)
						{
							for( y = minY; y < maxY; y++)
							{
								if( rPtrZ[ y*w])
								{
									nminX = minX -1;
									zz = maxZ;
								}
							}
						}
						
						rPtrZ = rPtr + maxX-1  + minZ*s;
						for( zz = minZ; zz < maxZ; zz++, rPtrZ += s)
						{
							for( y = minY; y < maxY; y++)
							{
								if( rPtrZ[ y*w])
								{
									nmaxX = maxX + 1;
									zz = maxZ;
								}
							}
						}
						
						// Y plane
						
						rPtrZ = rPtr + minY*w + minZ*s;
						for( zz = minZ; zz < maxZ; zz++, rPtrZ += s)
						{
							for( x = minX; x < maxX; x++)
							{
								if( rPtrZ[ x])
								{
									nminY = minY - 1;
									zz = maxZ;
								}
							}
						}
						
						rPtrZ = rPtr + (maxY-1)*w  + minZ*s;
						for( zz = minZ; zz < maxZ; zz++, rPtrZ += s)
						{
							for( x = minX; x < maxX; x++)
							{
								if( rPtrZ[ x])
								{
									nmaxY = maxY + 1;
									zz = maxZ;
								}
							}
						}
						
						minX	=	nminX;		maxX	=	nmaxX;
						minY	=	nminY;		maxY	=	nmaxY;
					}
				}
				
				rPtrZ = rPtr + z*s;
				srcPtrZ = volume + z*s;

				srcPtrY = srcPtrZ + minY*w + minX;
				rPtrY = rPtrZ + minY*w + minX;
				y = maxY-minY;
				while( y-- > 0)
				{
					srcPtrX = srcPtrY;
					rPtrX = rPtrY;
					
					x = maxX-minX;
					while( x-- > 0)
					{
						if( *rPtrX == 0xFF)
						{
							if( *(rPtrX-s) == 0) {if(	*(srcPtrX-s) > from) {	*(rPtrX-s) = 0xFE;}	else *(rPtrX-s) = 2;}
							if( *(rPtrX+s) == 0) {if(	*(srcPtrX+s) > from) {	*(rPtrX+s) = 0xFE;}	else *(rPtrX+s) = 2;}
						}
						rPtrX++;
						srcPtrX++;
					}
					
					srcPtrY += w;
					rPtrY += w;
				}
			}
			
			if( found)
			{
				nminZ	=	minZ;		nmaxZ	=	maxZ;

				// Z plane
				rPtrZ = rPtr + minZ*s + minY*w;
				for( y = minY; y < maxY; y++, rPtrZ += w)
				{
					for( x = minX; x < maxX; x++)
					{
						if( rPtrZ[ x])
						{
							nminZ = minZ-1;
							y = maxY;
						}
					}
				}
				
				rPtrZ = rPtr + (maxZ-1)*s + minY*w;
				for( y = minY; y < maxY; y++, rPtrZ += w)
				{
					for( x = minX; x < maxX; x++)
					{
						if( rPtrZ[ x])
						{
							nmaxZ = maxZ +1;
							y = maxY;
						}
					}
				}
				
				minZ	=	nminZ;		maxZ	=	nmaxZ;
			}
		}

		long i;
		
		
		rPtrZ = rPtr;
		for( i = 0; i < [pixList count]; i++)
		{
			
			ROI *theNewROI = [[ROI alloc]	initWithTexture:rPtrZ
											textWidth:w
											textHeight:h
											textName: @"BoneRemovalAlgorithmROIUniqueName"
											positionX:0
											positionY:0
											spacingX:[[pixList objectAtIndex: i] pixelSpacingX]
											spacingY:[[pixList objectAtIndex: i] pixelSpacingY]
											imageOrigin:NSMakePoint([[pixList objectAtIndex: i] originX], [[pixList objectAtIndex: i] originY])];
			if( [theNewROI reduceTextureIfPossible] == NO)	// NO means that the ROI is NOT empty
			{
				[roiList addObject: [NSDictionary dictionaryWithObjectsAndKeys: theNewROI, @"roi", [pixList objectAtIndex: i], @"curPix", nil]];
//				[[roiList objectAtIndex:i] addObject:theNewROI];		// roiList
//				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];	
//				[theNewROI setROIMode: ROI_selected];
//				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object:theNewROI userInfo: nil];
			}
			[theNewROI release];
			
			rPtrZ+= w*h;
		}
		
		free( rPtr);
	}
	
	return roiList;
}

+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints
{
	return [ITKSegmentation3D extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints largestRegion: YES];
}

+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height numPoints:(long) numPoints largestRegion:(BOOL) largestRegion
{
	itk::MultiThreader::SetGlobalDefaultNumberOfThreads( [[NSProcessInfo processInfo] processorCount]);
	
	NSMutableArray	*tempArray = [NSMutableArray array];
	int				dataExtent[ 6];
	
	vtkImageImport*	image2D = vtkImageImport::New();
	image2D->SetWholeExtent(0, width-1, 0, height-1, 0, 0);
	image2D->SetDataExtentToWholeExtent();
	image2D->SetDataScalarTypeToUnsignedChar();
	image2D->SetImportVoidPointer(map);
	image2D->Update();
	
	vtkMarchingSquares*		isoContour = vtkMarchingSquares::New();
	
	isoContour->SetValue(0, 1);
	isoContour->SetInputConnection( image2D->GetOutputPort());
	isoContour->Update();

	image2D->GetDataExtent( dataExtent);
				
	vtkPolyDataConnectivityFilter	*filter = vtkPolyDataConnectivityFilter::New();
	filter->SetColorRegions( 1);
	if( largestRegion) filter->SetExtractionModeToLargestRegion();
	else filter->SetExtractionModeToAllRegions();
	filter->SetInputConnection( isoContour->GetOutputPort());
	filter->Update();

	vtkPolyDataConnectivityFilter	*filter2 = vtkPolyDataConnectivityFilter::New();
	filter2->SetColorRegions( 1);
	if( largestRegion) filter2->SetExtractionModeToLargestRegion();
	else filter2->SetExtractionModeToAllRegions();
	filter2->SetInputConnection( filter->GetOutputPort());
	filter2->Update();

	vtkPolyData *output = filter2->GetOutput();
	//output->Update();
	
//	NSLog( @"Extracted region: %d", filter2->GetNumberOfExtractedRegions());
//	NSLog( @"Lines: %d Polys: %d, Points: %d", output->GetNumberOfLines(), output->GetNumberOfPolys(), output->GetNumberOfPoints());
	
	if( output->GetNumberOfLines() > 3)
	{
		long	ii;
		
		//NSLog( @"points: %d", output->GetNumberOfLines());
		
		for( ii = 0; ii < output->GetNumberOfLines(); ii+=2)
		{
			double p[ 3];
			output->GetPoint(ii, p);
			[tempArray addObject: [MyPoint point: NSMakePoint(p[0], p[1])]];		//[srcViewer newPoint: p[0]  : p[1] ]];
		}
		
		ii--;
		
		if(ii>= output->GetNumberOfLines()) ii-=2;
		
		for( ; ii >= 0; ii-=2)
		{
			double p[ 3];
			output->GetPoint(ii, p);
			[tempArray addObject: [MyPoint point: NSMakePoint(p[0], p[1])]];
		}
		
		long roiResolution = 1;
		
		if( [tempArray count] > numPoints)
		{
			long newroiResolution = [tempArray count] / numPoints;
			
			newroiResolution++;
			
			if( newroiResolution >  roiResolution) roiResolution = newroiResolution;
		}
		
		if( roiResolution != 1)
		{
			long tot = [tempArray count];
			long zz;
			
			for( ii = tot-1; ii >= 0; ii -= roiResolution)
			{
				for( zz = 0; zz < roiResolution-1; zz++)
				{
					if( [tempArray count] > 3 && ii-zz >= 0) [tempArray removeObjectAtIndex: ii-zz];
				}
			}
		}
	}
	
	isoContour->Delete();
	filter->Delete();
	filter2->Delete();
	image2D->Delete();
	
	return tempArray;
}

+ (NSMutableArray*) extractContour:(unsigned char*) map width:(long) width height:(long) height
{
   return [self extractContour:map width:width height:height numPoints: 100];
}

-(void) dealloc
{
	[itkImage release];
	
	[super dealloc];
}

- (id) initWith :(NSMutableArray*) pix :(float*) volumeData :(long) slice {
	return [self initWithPix :(NSMutableArray*) pix volume:(float*) volumeData  slice:(long) slice resampleData:NO];
}

- (id) initWithPix :(NSMutableArray*) pix volume:(float*) volumeData  slice:(long) slice resampleData:(BOOL)resampleData
{
    if (self = [super init])
	{
		itk::MultiThreader::SetGlobalDefaultNumberOfThreads( [[NSProcessInfo processInfo] processorCount]);
		_resampledData = resampleData;
		NSLog(@"slice ID: %d", (int) slice);
		itkImage = [[ITK alloc] initWithPix :(NSMutableArray*) pix volume:(float*) volumeData sliceCount:(long) slice resampleData:(BOOL)resampleData];
		//itkImage = [[ITK alloc] initWith: pix :volumeData :slice];
    }
    return self;
}

- (void) regionGrowing3D:(ViewerController*) srcViewer :(ViewerController*) destViewer :(long) slice :(NSPoint) startingPoint :(int) algorithmNumber :(NSArray*) parameters :(BOOL) setIn :(float) inValue :(BOOL) setOut :(float) outValue :(ToolMode) roiType :(long) roiResolution :(NSString*) newname :(BOOL) mergeWithExistingROIs;
{
	NSLog(@"ITK max number of threads: %d", itk::MultiThreader::GetGlobalDefaultNumberOfThreads());
	
	// Input image
	typedef float InternalPixelType;
	typedef itk::Image< InternalPixelType, 3 > InternalImageType; 
	// Char Output image
	typedef unsigned char OutputPixelType;
	typedef itk::Image< OutputPixelType, 3 > OutputImageType;
	// Type Caster
	typedef itk::CastImageFilter< InternalImageType, OutputImageType > CastingFilterType;
	CastingFilterType::Pointer caster = CastingFilterType::New();
	
	// STARTING POINT
	InternalImageType::IndexType  index;
	index[0] = (long) startingPoint.x;
	index[1] = (long) startingPoint.y;
	if( slice == -1) index[2] = [[srcViewer imageView] curImage];
	else index[2] = 0;

	//FILTERS
	typedef itk::ConnectedThresholdImageFilter< InternalImageType, InternalImageType > ConnectedThresholdFilterType;
	typedef itk::NeighborhoodConnectedImageFilter< InternalImageType, InternalImageType > NeighborhoodConnectedFilterType;
	typedef itk::ConfidenceConnectedImageFilter< InternalImageType, InternalImageType > ConfidenceConnectedFilterType;
	
	ConnectedThresholdFilterType::Pointer thresholdFilter = nil;
	NeighborhoodConnectedFilterType::Pointer neighborhoodFilter = nil;
	ConfidenceConnectedFilterType::Pointer confidenceFilter = nil;
	// connected threshold filter
	if (algorithmNumber==0 || algorithmNumber==1)
	{
		thresholdFilter = ConnectedThresholdFilterType::New();
		
		float loV, upV;
		if (algorithmNumber==0)
		{
			long xpx, ypx;
			xpx = (long)startingPoint.x;
			ypx = (long)startingPoint.y;
			float mouseValue = [[[srcViewer imageView] curDCM] getPixelValueX:(long)startingPoint.x Y:(long)startingPoint.y];
			float interval = [[parameters objectAtIndex:0] floatValue];
			loV = mouseValue - interval/2.0;
			upV = mouseValue + interval/2.0;
		}
		else
		{
			loV = [[parameters objectAtIndex:0] floatValue];
			upV = [[parameters objectAtIndex:1] floatValue];
		}
		
		thresholdFilter->SetLower(loV);
		thresholdFilter->SetUpper(upV);
		thresholdFilter->SetReplaceValue(255);
	
		thresholdFilter->SetSeed(index);

		[itkImage itkImporter]->Update();
		thresholdFilter->SetInput([itkImage itkImporter]->GetOutput());

		caster->SetInput(thresholdFilter->GetOutput());	// <- FLOAT TO CHAR
	}
	// Neighbor Connected filter
	else if (algorithmNumber==2)
	{
		neighborhoodFilter = NeighborhoodConnectedFilterType::New();
		
		float loV, upV;
		loV = [[parameters objectAtIndex:0] floatValue];
		upV = [[parameters objectAtIndex:1] floatValue];
		neighborhoodFilter->SetLower(loV);
		neighborhoodFilter->SetUpper(upV);
		
		InternalImageType::SizeType radius;
		radius[0] = [[parameters objectAtIndex:2] intValue];
		radius[1] = [[parameters objectAtIndex:2] intValue];
		radius[2] = [[parameters objectAtIndex:2] intValue];
		neighborhoodFilter->SetRadius(radius);
		
		neighborhoodFilter->SetReplaceValue(255);
		neighborhoodFilter->SetSeed(index);

		[itkImage itkImporter]->Update();
		neighborhoodFilter->SetInput([itkImage itkImporter]->GetOutput());

		caster->SetInput(neighborhoodFilter->GetOutput());	// <- FLOAT TO CHAR
	}
	// Confidence Connected filter
	else if (algorithmNumber==3)
	{
		confidenceFilter = ConfidenceConnectedFilterType::New();
		
		float multiplier = [[parameters objectAtIndex:0] floatValue];
		confidenceFilter->SetMultiplier(multiplier);
		int numberOfIterations = [[parameters objectAtIndex:1] intValue];
		confidenceFilter->SetNumberOfIterations(numberOfIterations);
		int radius = [[parameters objectAtIndex:2] intValue];
		confidenceFilter->SetInitialNeighborhoodRadius(radius);
		
		confidenceFilter->SetReplaceValue(255);
		confidenceFilter->SetSeed(index);
		[itkImage itkImporter]->Update();
		confidenceFilter->SetInput([itkImage itkImporter]->GetOutput());

		caster->SetInput(confidenceFilter->GetOutput());	// <- FLOAT TO CHAR
	}

	WaitRendering	*wait = nil;
	
	if( slice == -1) wait = [[WaitRendering alloc] init: NSLocalizedString(@"Propagating Region...", nil)];
	[wait showWindow:self];
	
	NSLog(@"RegionGrowing starts...");
	
    BOOL succeed = NO;
    
	try
	{
		caster->Update();
        succeed = YES;
	}
	catch( itk::ExceptionObject & excep )
	{
		NSLog(@"RegionGrowing failed...");
	}
	
	NSLog(@"Done...");
	
    unsigned char *buff = caster->GetOutput()->GetBufferPointer();
    
    if( succeed && caster->GetOutput() && buff)
    { 
        [wait setString: NSLocalizedString(@"Preparing Results...",@"Preparing Results...")];
        // PRODUCE A NEW SERIES
        if( destViewer)
        {
            long	i, x, y;
            float	*dstImage, *srcImage;
            long	startSlice, endSlice;
            
            if( slice == -1)
            {
                startSlice = 0;
                endSlice = [[destViewer pixList] count];
            }
            else
            {
                startSlice = slice;
                endSlice = startSlice+1;
            }
            
            for( i = startSlice; i < endSlice; i++)
            {
                ImageType::IndexType pixelIndex; 
                DCMPix	*curPix = [[destViewer pixList] objectAtIndex: i];
                dstImage = [curPix fImage];
                srcImage = [[[srcViewer pixList] objectAtIndex: i] fImage];
                
                if(slice == -1) pixelIndex[2] = i; // z position
                else pixelIndex[2] = 0; // z position
                
                for( y = 0; y < [curPix pheight]; y++) 
                {
                    pixelIndex[1] = y; // y position
                    for( x = 0; x < [curPix pwidth]; x++) 
                    {
                        pixelIndex[0] = x; // x position
                        
                        if( caster->GetOutput()->GetPixel( pixelIndex) == 255)
                        {
                            if( setIn)
                            {
                                *dstImage = inValue;
                            }
                            else
                            {
                                *dstImage = *srcImage;
                            }
                        }
                        
                        dstImage++;
                        srcImage++;
                    }
                }
            }
        }
        // PRODUCE A ROI ON THE ORIGINAL SERIES
        // ROI type = tPlain
        else if (roiType == 0)
        {
            if( slice == -1)
            {			
                unsigned char *buff = caster->GetOutput()->GetBufferPointer();
                
                if( buff)
                {
                    for( int i = 0; i < [[srcViewer pixList] count]; i++)
                    {
                        int buffHeight = [[[srcViewer pixList] objectAtIndex: i] pheight];
                        int buffWidth = [[[srcViewer pixList] objectAtIndex: i] pwidth];
                        
                        if( memchr( buff, 255, buffWidth * buffHeight))
                        {
                            ROI *theNewROI = [[ROI alloc]	initWithTexture:buff
                                                            textWidth:buffWidth
                                                            textHeight:buffHeight
                                                            textName:newname
                                                            positionX:0
                                                            positionY:0
                                                            spacingX:[[[srcViewer imageView] curDCM] pixelSpacingX]
                                                            spacingY:[[[srcViewer imageView] curDCM] pixelSpacingY]
                                                            imageOrigin: [DCMPix originCorrectedAccordingToOrientation: [[srcViewer imageView] curDCM]]];
                            
                            [[[srcViewer roiList] objectAtIndex:i] addObject:theNewROI];
                            
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:theNewROI, @"ROI",
                                                      [NSNumber numberWithInt:i], @"sliceNumber",
                                                      nil];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: self userInfo:userInfo];

                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];	
                            
                            if( [newname isEqualToString: NSLocalizedString( @"Segmentation Preview", nil)])
                            {
                                RGBColor color;
                                
                                color.red = 0.67*65535.;
                                color.green = 0.90*65535.;
                                color.blue = 0.58*65535.;
                                
                                [theNewROI setColor: color];
                            }
                            
                            [theNewROI setROIMode: ROI_selected];
                            [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object:theNewROI userInfo: nil];
                            
                            [theNewROI setSliceThickness:[[[srcViewer imageView] curDCM] sliceThickness]];
                            [theNewROI release];
                        }
                        
                        buff+= buffHeight*buffWidth;
                    }
                
                    if( mergeWithExistingROIs)
                    {
                        int currentImageIndex = [[srcViewer imageView] curImage];
                        
                        for( NSMutableArray *rois in [srcViewer roiList])
                        {
                            [srcViewer mergeBrushROI: self ROIs: rois ROIList: rois];
                        }
                        
                        [[srcViewer imageView] setIndex: currentImageIndex];
                        [[srcViewer imageView] sendSyncMessage:0];
                        [srcViewer adjustSlider];
                    }
                }
                else
                {
                    if( NSRunAlertPanel( NSLocalizedString(@"32-bit",nil), NSLocalizedString( @"Upgrade to Horos 64-bit to solve this issue.",nil), NSLocalizedString(@"OK", nil), NSLocalizedString(@"Horos 64-bit", nil), nil) == NSAlertAlternateReturn)
                        [[AppController sharedAppController] osirix64bit: self];	
                }
            }
            else
            {
                // result of the segmentation will only contain one slice.
                
                int buffHeight = [[[srcViewer pixList] objectAtIndex: 0] pheight];
                int buffWidth = [[[srcViewer pixList] objectAtIndex: 0] pwidth];

                ROI *theNewROI = [[ROI alloc]	initWithTexture:buff
                                                textWidth:buffWidth
                                                textHeight:buffHeight
                                                textName:newname
                                                positionX:0
                                                positionY:0
                                                spacingX:[[[srcViewer imageView] curDCM] pixelSpacingX]
                                                spacingY:[[[srcViewer imageView] curDCM] pixelSpacingY]
                                                imageOrigin:[DCMPix originCorrectedAccordingToOrientation: [[srcViewer imageView] curDCM]]];
                [theNewROI reduceTextureIfPossible];
                [theNewROI setSliceThickness:[[[srcViewer imageView] curDCM] sliceThickness]];
                [[[srcViewer roiList] objectAtIndex:slice] addObject:theNewROI];
                [[srcViewer imageView] roiSet];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:theNewROI, @"ROI",
                                          [NSNumber numberWithInt:slice], @"sliceNumber",
                                          nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixAddROINotification object: self userInfo:userInfo];
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];
                
                if( [newname isEqualToString: NSLocalizedString( @"Segmentation Preview", nil)])
                {
                    RGBColor color;
                    
                    color.red = 0.67*65535.;
                    color.green = 0.90*65535.;
                    color.blue = 0.58*65535.;
                    
                    [theNewROI setColor: color];
                }
                else if( mergeWithExistingROIs)
                {
                    [[srcViewer imageView] selectAll: self];
                    [srcViewer mergeBrushROI: self];
                }
                
                [theNewROI setROIMode: ROI_selected];
                [[NSNotificationCenter defaultCenter] postNotificationName: OsirixROISelectedNotification object:theNewROI userInfo: nil];
                
                [theNewROI release];
            }
            [srcViewer needsDisplayUpdate];
        }
        // PRODUCE A ROI ON THE ORIGINAL SERIES
        // ROI type = tPolygon
        else
        {
            long	i, x;
            long	startSlice, endSlice;
            
            if( slice == -1)
            {
                startSlice = 0;
                endSlice = [[srcViewer pixList] count];
            }
            else
            {
                startSlice = slice;
                endSlice = startSlice+1;
            }

            //------------------------------------------------------------------------
            // ITK to VTK
            //------------------------------------------------------------------------
        
            int dataExtent[ 6] = {
                (int)caster->GetOutput()->GetLargestPossibleRegion().GetIndex(0), (int)caster->GetOutput()->GetLargestPossibleRegion().GetSize(0),
                (int)caster->GetOutput()->GetLargestPossibleRegion().GetIndex(1), (int)caster->GetOutput()->GetLargestPossibleRegion().GetSize(1),
                (int)caster->GetOutput()->GetLargestPossibleRegion().GetIndex(2), (int)caster->GetOutput()->GetLargestPossibleRegion().GetSize(2),
            };
            
            for( i = startSlice; i < endSlice; i++)
            {
                long			imageSize = dataExtent[1] * dataExtent[3];    //  before: (dataExtent[ 1]+1) * (dataExtent[ 3]+1);
                unsigned char	*image2Ddata = (unsigned char*) malloc(imageSize), *tempPtr;
                vtkImageImport	*image2D;
                DCMPix			*curPix = [[srcViewer pixList] objectAtIndex: i];
                
                int buffHeight = [[[srcViewer pixList] objectAtIndex: i] pheight];
                int buffWidth = [[[srcViewer pixList] objectAtIndex: i] pwidth];
                
                memcpy( image2Ddata, buff, imageSize);
                
                image2D = vtkImageImport::New();
                image2D->SetWholeExtent(0, dataExtent[1] - 1, 0, dataExtent[3] - 1, 0, 0);  //  before: (0, dataExtent[1], 0, dataExtent[3], 0, 0)
                image2D->SetDataExtentToWholeExtent();
                image2D->SetDataScalarTypeToUnsignedChar();
                image2D->SetImportVoidPointer(image2Ddata);		
                
                tempPtr = image2Ddata;
                for( x = 0; x < [curPix pwidth]; x++) 
                {
                    tempPtr[ x] = 0;
                }
                tempPtr = image2Ddata + ([curPix pwidth]) * ([curPix pheight]-1);
                for( x = 0; x < [curPix pwidth]; x++) 
                {
                    tempPtr[ x] = 0;
                }
                tempPtr = image2Ddata;
                for( x = 0; x < [curPix pheight]; x++) 
                {
                    *tempPtr = 0;
                    tempPtr += [curPix pwidth];
                }
                tempPtr = image2Ddata + [curPix pwidth]-1;
                for( x = 0; x < [curPix pheight]; x++) 
                {
                    *tempPtr = 0;
                    tempPtr += [curPix pwidth];
                }
                
                {
                    //------------------------------------------------------------------------
                    // VTK MARCHING SQUARE
                    //------------------------------------------------------------------------
                    
                //	NSLog(@"%d, %d, %d, %d", dataExtent[0], dataExtent[1], dataExtent[2], dataExtent[3]);
                    
    //				if( slice == -1)
    //				{
    //					isoContour->SetImageRange(dataExtent[0], dataExtent[1], dataExtent[2], dataExtent[3], i, i);
    //				}
                    
                    vtkContourFilter*		isoContour = vtkContourFilter::New();
                //	vtkMarchingSquares*		isoContour = vtkMarchingSquares::New();
                    
                    isoContour->SetValue(0, 1);
                    isoContour->SetInputConnection( image2D->GetOutputPort());
                   
                    vtkPolyDataConnectivityFilter	*filter = vtkPolyDataConnectivityFilter::New();
                    filter->SetColorRegions( 1);
                    filter->SetExtractionModeToLargestRegion();
                    filter->SetInputConnection( isoContour->GetOutputPort());
                    
                    vtkPolyDataConnectivityFilter	*filter2 = vtkPolyDataConnectivityFilter::New();
                    filter2->SetColorRegions( 1);
                    filter2->SetExtractionModeToLargestRegion();
                    filter2->SetInputConnection( filter->GetOutputPort());
                    
                    filter2->Update();
                    
                    vtkPolyData *output = filter2->GetOutput();
                    
        //			filter->SetExtractionModeToAllRegions();
        //			filter->Update();
        //			filter->SetExtractionModeToSpecifiedRegions();
        //
        //			for (int i=0; i<filter->GetNumberOfExtractedRegions(); i++)
        //			{
        //				filter->AddSpecifiedRegion(i);
        //				filter->Update();
        //				
        //				output = filter->GetOutput();
        //				NSLog( @"%d", filter->GetOutput()->GetNumberOfPolys());
        ////				NSLog( @"Region 0: %d", cells->GetNumberOfPoints());
        //				NSLog( @"Lines: %d Polys: %d, Points: %d, Cells: %d - %d - %d", output->GetNumberOfLines(), output->GetNumberOfPolys(), output->GetNumberOfPoints(), output->GetNumberOfCells(), output->GetNumberOfStrips(), output->GetNumberOfVerts());
        //
        //				// if region shall be dropped
        //				filter->DeleteSpecifiedRegion(i);
        //			}
                    
                    //output->Update();
                    
    //				NSLog( @"Extracted region: %d", filter->GetNumberOfExtractedRegions());				
    //				NSLog( @"Lines: %d Polys: %d, Points: %d", output->GetNumberOfLines(), output->GetNumberOfPolys(), output->GetNumberOfPoints());
                    
                    if( output->GetNumberOfLines() > 3)
                    {
                        long			ii;
                        ROI				*newROI = [srcViewer newROI: tCPolygon];
                        NSMutableArray  *points = [newROI points];
                        
                        for( ii = 0; ii < output->GetNumberOfLines(); ii+=2)
                        {
                            double p[ 3];
                            output->GetPoint(ii, p);
                            [points addObject: [srcViewer newPoint: p[0]  : p[1] ]];
                        }
                        ii--;
                        if(ii>= output->GetNumberOfLines()) ii-=2;
                        for( ; ii >= 0; ii-=2)
                        {
                            double p[ 3];
                            output->GetPoint(ii, p);
                            [points addObject: [srcViewer newPoint: p[0]  : p[1] ]];
                        }
                        
                        #define MAXPOINTS 200
                        
                        if( [points count] > MAXPOINTS)
                        {
                            long newroiResolution = [points count] / MAXPOINTS;
                            
                            newroiResolution++;
                            
                            if( newroiResolution >  roiResolution) roiResolution = newroiResolution;
                        }
                        
                        if( roiResolution != 1 && roiResolution > 0)
                        {
                            long tot = [points count];
                            long zz;
                            
                            for( ii = tot-1; ii >= 0; ii -= roiResolution)
                            {
                                for( zz = 0; zz < roiResolution-1; zz++)
                                {
                                    if( [points count] > 3 && ii-zz >= 0) [points removeObjectAtIndex: ii-zz];
                                }
                            }
                        }
        
                        {
                            NSMutableArray  *roiSeriesList;
                            NSMutableArray  *roiImageList;

                            roiSeriesList = [srcViewer roiList];
                            
                            if( slice == -1) roiImageList = [roiSeriesList objectAtIndex: i];
                            else roiImageList = [roiSeriesList objectAtIndex: [[srcViewer imageView] curImage]];
                            
                            [newROI setName: newname];
                            [roiImageList addObject: newROI];
                            [[srcViewer imageView] roiSet];
                            [srcViewer needsDisplayUpdate];
                        }
                    }
                    
                    isoContour->Delete();
                    filter->Delete();
                    filter2->Delete();
                }
                
                image2D->Delete();
                free( image2Ddata);
                
                buff += buffHeight*buffWidth;
            }
        }
    }
    
	[wait close];
	[wait autorelease];
}


//- (NSArray *)endoscopySegmentationForViewer:(ViewerController*) srcViewer seeds:(NSArray *)seeds {
//	// Setup 
//	//#define UseApproximateSignedDistanceMapImageFilter
//	DCMPix *curPix = [[srcViewer imageView] curDCM];
//	
//	
//	long width = (int)[curPix pwidth];
//	long height = (int)[curPix pheight];
//	long depth = (int)[[srcViewer pixList] count];
//	
//	if (_resampledData) {
//		width /=2;
//		height/=2;
//		depth /=2;
//	}
//		
//	NSLog(@"width %d height %d depth: %d", width,height,depth);
//	const unsigned int Dimension = 3; 
//
//		// Float Pixel Type
//	typedef float FloatPixelType;
//	typedef itk::Image< FloatPixelType, Dimension > FloatImageType; 
//	// Char Output image
//	typedef unsigned char CharPixelType;
//	typedef itk::Image< CharPixelType, Dimension > CharImageType;
//	// signed Char Output image
//	typedef signed char SignedCharPixelType;
//	typedef itk::Image< SignedCharPixelType, Dimension > SignedCharImageType;
//	//Short image type
//	typedef signed short SSPixelType;
//	typedef itk::Image< SSPixelType, Dimension > SSImageType;
//	// Type distance Filter
//
//
//	//Segmentation Filter
//	typedef itk::ConnectedThresholdImageFilter<FloatImageType, CharImageType > ConnectedThresholdFilterType;	
//	ConnectedThresholdFilterType::Pointer thresholdFilter = nil;
//	thresholdFilter = ConnectedThresholdFilterType::New();
//			
//	thresholdFilter->SetLower(-2000.0);
//	thresholdFilter->SetUpper(-800.0);
//	thresholdFilter->SetReplaceValue(255.0);
//	
//	typedef itk::ResampleImageFilter<FloatImageType, FloatImageType > ResampleFilterType;
//	ResampleFilterType::Pointer resampleFilter = ResampleFilterType::New();
//	typedef itk::AffineTransform< double, 3 > TransformType;
//	TransformType::Pointer transform = TransformType::New(); 
//	resampleFilter->SetTransform( transform );
//	typedef itk::NearestNeighborInterpolateImageFunction< FloatImageType, double > InterpolatorType; 
//
//	InterpolatorType::Pointer interpolator = InterpolatorType::New(); 
//	resampleFilter->SetInterpolator( interpolator );
//	
//	double resampleX = 2.0;
//	double resampleY = 2.0;
//	double resampleZ = 2.0;
//	const double *spacing = [itkImage itkImporter]->GetSpacing();
//	double newSpacing[Dimension];
//	newSpacing[0] = spacing[0] * resampleX; // pixel spacing in millimeters along X 
//	newSpacing[1] = spacing[1] * resampleY; // pixel spacing in millimeters along Y 
//	newSpacing[2] = spacing[2] * resampleZ; // pixel spacing in millimeters along Z
//	resampleFilter->SetOutputSpacing( newSpacing );
//	
//	CharImageType::SizeType size; 
//	size[0] = width/resampleX; // number of pixels along X 
//	size[1] = height/resampleY; // number of pixels along Y 
//	size[2] = depth/resampleZ;// number of pixels along Z
//	resampleFilter->SetSize( size );
//	
//	const double *origin = [itkImage itkImporter]->GetOrigin(); 
//	resampleFilter->SetOutputOrigin(origin);
//	
//	
//	/*
//	typedef itk::BinaryBallStructuringElement<CharPixelType, Dimension > StructuringElementType;
//	StructuringElementType structuringElement; 
//	structuringElement.SetRadius( 1 ); // 3x3 structuring element 
//	structuringElement.CreateStructuringElement();  
//
//	typedef itk::GrayscaleDilateImageFilter<CharImageType, CharImageType, StructuringElementType > DilateFilterType; 
//	DilateFilterType::Pointer dilateFilter =  DilateFilterType::New();
//	dilateFilter->SetKernel( structuringElement ); 
//	*/
//	
//	//id seed;
//	//Add seed points. Can use more than 1
//	
//	for (OSIVoxel *seed in seeds) {
//		FloatImageType::IndexType  index;
//		index[0] = (long) [seed x] / resampleX;
//		index[1] = (long) [seed y] / resampleY;
//		index[2] = (long) [seed z] / resampleZ;
//		thresholdFilter->AddSeed(index);
//	}
//	
//	// make connections Inputs and outputs
//	// resample then threshold
//	thresholdFilter->SetInput(resampleFilter->GetOutput());
//	resampleFilter->SetInput([itkImage itkImporter]->GetOutput());
//
//	
//	
//	WaitRendering	*wait = nil;
//	
//	wait = [[WaitRendering alloc] init: NSLocalizedString(@"Propagating Region...", nil)];
//	[wait showWindow:self];
//	
//
//
//	try
//	{
//		thresholdFilter->Update();
//	
//	}
//	catch( itk::ExceptionObject & excep )
//	{
//		NSLog(@"Segmentation failed...");
//		std::cerr << excep.GetDescription() << std::endl;
//		//return;
//	}
//
//
//	//------------------------------------------------------------------------
//	// ITK to VTK pipeline connection.
//	//------------------------------------------------------------------------
//	unsigned char *buff = thresholdFilter->GetOutput()->GetBufferPointer();
//	vtkImageImport*	image3D = vtkImageImport::New();
//	image3D->SetWholeExtent(0, size[0] - 1, 0, size[1] - 1, 0, size[2]- 1);
//	image3D->SetDataExtentToWholeExtent();
//	image3D->SetDataScalarTypeToUnsignedChar();
//	image3D->SetImportVoidPointer(buff);
//	 
//	vtkMarchingCubes*		isoContour = vtkMarchingCubes::New();
//	
//	isoContour->SetValue(0, 255);
//	isoContour->SetInput( (vtkDataObject*) image3D->GetOutput());
//	isoContour->Update();
//	
//	vtkPolyData *contour = isoContour->GetOutput();
//	[wait setString:NSLocalizedString(@"Finding Centerline Points", nil)];
//	Centerline *centerline = [[Centerline alloc] init];
//	centerline.wait = wait;
//	OSIVoxel *endingPoint = nil;
//	// Get starting point and Ending POints
//	if ([seeds count] > 2)
//		endingPoint = [seeds objectAtIndex:1];
//	OSIVoxel *firstPoint = [seeds objectAtIndex:0];
//	OSIVoxel *endPoint = nil;
//	if (endingPoint) {
//		endPoint = [OSIVoxel pointWithX:[endingPoint x] / resampleX  y:endingPoint.y / resampleY  z:endingPoint.z / resampleZ value:nil];
//		endPoint.voxelWidth = newSpacing[0];
//		endPoint.voxelHeight = newSpacing[1];
//		endPoint.voxelDepth = newSpacing[2];
//	}
//	OSIVoxel *startingPoint = [OSIVoxel pointWithX:firstPoint.x / resampleX  y:firstPoint.y / resampleY  z:firstPoint.z / resampleZ value:nil];
//	startingPoint.voxelWidth = newSpacing[0];
//	startingPoint.voxelHeight = newSpacing[1];
//	startingPoint.voxelDepth = newSpacing[2];
//	// Get array of centerline Points
//	NSArray *centerlinePoints = [centerline generateCenterline:contour startingPoint:startingPoint  endingPoint:endPoint];
//	isoContour->Delete();
//	
//	// Create Point2D ROIs for now. Need to create pipeline to Flythrough.
//	
//	for (OSIVoxel *point3D in centerlinePoints) {
//	/*
//			NSPoint point = NSMakePoint(point3D.x * resampleX, point3D.y * resampleY);
//			ROI *theNewROI  = [srcViewer newROI: t2DPoint];
//			NSMutableArray *pointArray = [theNewROI splinePoints];
//			[theNewROI setName: @"Centerline"];
//			roiImageList = [roiSeriesList objectAtIndex:point3D.z * resampleZ];
//			[roiImageList addObject: theNewROI];
//			[theNewROI mouseRoiDown:point :(int)(point3D.z * resampleZ) :1.0];
//			[theNewROI mouseRoiUp:point scaleValue: scaleValue];	
//	*/
//			point3D.x *= resampleX;
//			point3D.y *= resampleY;
//			point3D.z *= resampleZ;
//	}
//
//
//	[centerline release];
//	[wait close];
//	[wait autorelease];
//	
//	[srcViewer needsDisplayUpdate];
//	
//	return centerlinePoints;
//}


@end
