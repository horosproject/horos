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





#import <Cocoa/Cocoa.h>

typedef float itkPixelType;
//typedef itk::RGBPixel<unsigned char> itkPixelType;
typedef itk::Image< itkPixelType, 3 > ImageType;
typedef itk::ImportImageFilter< itkPixelType, 3 > ImportFilterType;


/** \brief Creates an itkImageImportFilter
*/

@interface ITK : NSObject {
	
	// ITK objects	
	ImportFilterType::Pointer importFilter;
}

#ifdef id
#define redefineID
#undef id
#endif


- (id) initWith :(NSArray*) pix :(float*) srcPtr :(long) slice;
- (id) initWithPix :(NSArray*) pix volume:(float*) volumeData sliceCount:(long) slice resampleData:(BOOL)resampleData;

#ifdef redefineID
#define id Id
#undef redefineID
#endif

- (ImportFilterType::Pointer) itkImporter;
- (void)setupImportFilterWithSize:(ImportFilterType::SizeType)size  
	origin:(double[3])origin 
	spacing:(double[3])spacing 
	data:(float *)data
	filterWillOwnBuffer:(BOOL)filterWillOwnBuffer;


@end
