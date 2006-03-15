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




#define id Id
#include "itkImage.h"
#include "itkImportImageFilter.h"
#undef id

#import "DCMPix.h"
#import "ITK.h"

@implementation ITK

- (void) dealloc
{
	NSLog(@"ITK Image dealloc");
	
	[pixList release];
	
	[super dealloc];
}

- (ImportFilterType::Pointer) itkImporter
{
	return importFilter;
}

- (id) initWith :(NSMutableArray*) pix :(float*) volumeData :(long) slice
{
    if (self = [super init])
	{
		itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
		
		pixList = pix;
		[pixList retain];
		
		firstObject = [pixList objectAtIndex:0];
		
		if( slice == -1) data = volumeData;
		else
		{
			data = volumeData;
			data += slice*[firstObject pwidth]*[firstObject pheight];
		}
		
		importFilter = ImportFilterType::New();
		
		ImportFilterType::SizeType size;
		size[0] = [firstObject pwidth]; // size along X
		size[1] = [firstObject pheight]; // size along Y
		
		if( slice == -1) size[2] = [pixList count]; // size along Z
		else size[2] = 1;
		
		ImportFilterType::IndexType start;
		start.Fill( 0 );
		
		ImportFilterType::RegionType region;
		region.SetIndex( start );
		region.SetSize( size );
		importFilter->SetRegion( region );
		
		double origin[ 3 ];
		origin[0] = [firstObject originX]; // X coordinate
		origin[1] = [firstObject originY]; // Y coordinate
		origin[2] = [firstObject originZ]; // Z coordinate
		importFilter->SetOrigin( origin );
		
		double spacing[ 3 ];
		spacing[0] = [firstObject pixelSpacingX]; // along X direction
		spacing[1] = [firstObject pixelSpacingY]; // along Y direction
		spacing[2] = [firstObject sliceInterval]; // along Z direction
		importFilter->SetSpacing( spacing ); 
		
		const bool importImageFilterWillOwnTheBuffer = false;
		importFilter->SetImportPointer( data, size[0] * size[1] * size[2], importImageFilterWillOwnTheBuffer);
		NSLog(@"ITK Image allocated");
    }
    return self;
}

@end
