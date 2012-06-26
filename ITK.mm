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




#define id Id
	#include "itkImage.h"
	#include "itkImportImageFilter.h"
	//#include "itkResampleImageFilter.h"
#undef id


#import "DCMPix.h"
#import "ITK.h"

//static ImportFilterType::Pointer importFilter;

@implementation ITK

- (void) dealloc
{
	if( importFilter)
		importFilter->UnRegister();
	
	[super dealloc];
}

- (ImportFilterType::Pointer) itkImporter
{
	return importFilter;
}

- (id) initWith :(NSArray*) pix :(float*) volumeData :(long) slice {
	return [self initWithPix :(NSArray*) pix volume:(float*) volumeData sliceCount:(long) slice resampleData:NO];
}

- (id) initWithPix :(NSArray*) pix volume:(float*) volumeData sliceCount:(long) slice resampleData:(BOOL)resampleData
{
    if (self = [super init])
	{
		// init variables
		long height = 0;
		long width = 0;
		long depth = 0;
		
		float originX = 0.0;
		float originY = 0.0;
		float originZ = 0.0;
		
		float voxelSpacingX = 0.0;
		float voxelSpacingY = 0.0;
		float voxelSpacingZ = 0.0;
		
		double origin[ 3 ];
		double spacing[ 3 ];
		
		// init Filiter
		//itk::MultiThreader::SetGlobalDefaultNumberOfThreads( [[NSProcessInfo processInfo] processorCount]ors());
		//importFilter = ImportFilterType::New();
		ImportFilterType::SizeType size;
		//ImportFilterType::IndexType start;
		//ImportFilterType::RegionType region;
		
		
		float	*data;
		NSArray *pixList = pix;
		
		id firstObject = [pixList objectAtIndex:0];
		
		height = [firstObject pheight];
		width =  [firstObject pwidth];
				  
		if( slice == -1 || slice == -2) depth = [pixList count]; // size along Z
		else depth = 1;
		
		originX = [firstObject originX];
		originY = [firstObject originY];
		originZ = [firstObject originZ];
		
		voxelSpacingX  = [firstObject pixelSpacingX]; 
		voxelSpacingY  = [firstObject pixelSpacingY];  
		voxelSpacingZ  = [firstObject sliceInterval]; 
		
		if( voxelSpacingZ == 0 || [pixList count] == 1)
			voxelSpacingZ = 0.1;
		
		if( slice == -2)
			voxelSpacingZ = 1000;
		
		// get data
		if( slice == -1 || slice == -2)
		{
			data = volumeData;
			// resample data decreases the size by 2 if all dimensions
			
			if (resampleData)
			{
				NSLog(@"start data resample");
				
				int sliceSize = height * width;
				float *newData = (float *) malloc(height * width * depth * sizeof(float) / 8);
				int x, y , z;
				int i = 0;
				for (z = 1; z < depth; z += 2) {
					for (y = 1; y < height; y += 2) {
						for ( x = 1;  x < width; x += 2) {
							// should we interpolate or just use the value. Try without interpolation first
							int position = (z * sliceSize) + (y * width) + x;
							newData[i++]  = data[position];
						}
					}
				}
				NSLog(@"end resample data");
				//free(newData);
				data = newData;
				voxelSpacingX *= 2;
				voxelSpacingY *= 2;
				voxelSpacingZ *= 2;
				height /= 2;
				width /= 2;
				depth /= 2;
			}
		}
		else
		{
			data = volumeData;
			data += slice*width*height;
			
			resampleData = NO;
		}
		
		size[0] = width; // size along X
		size[1] = height; // size along Y
		size[2] = depth;
		
		origin[0] = originX; // X coordinate
		origin[1] = originY; // Y coordinate
		origin[2] = originZ; // Z coordinate
	
		spacing[0] = voxelSpacingX; // along X direction
		spacing[1] = voxelSpacingY; // along Y direction
		spacing[2] = voxelSpacingZ; // along Z direction
		
		[self setupImportFilterWithSize:size origin:origin spacing:spacing data:data filterWillOwnBuffer:resampleData];
    }
    return self;
}


- (void)setupImportFilterWithSize:(ImportFilterType::SizeType)size origin:(double[3])origin spacing:(double[3])spacing data:(float *)data filterWillOwnBuffer:(BOOL)filterWillOwnBuffer
{
	itk::MultiThreader::SetGlobalDefaultNumberOfThreads( [[NSProcessInfo processInfo] processorCount]);
	
	importFilter = ImportFilterType::New();
//	importFilter->DebugOn();
	
	importFilter->Register();
	
	//ImportFilterType::SizeType size;
	ImportFilterType::IndexType start;
	ImportFilterType::RegionType region;
	start.Fill( 0 );
	region.SetIndex( start );
	region.SetSize( size );
	
	importFilter->SetRegion( region);
	importFilter->SetOrigin( origin);
	importFilter->SetSpacing( spacing); 
	
	const bool importImageFilterWillOwnTheBuffer = filterWillOwnBuffer;
	importFilter->SetImportPointer( data, size[0] * size[1] * size[2], importImageFilterWillOwnTheBuffer);
}

@end
