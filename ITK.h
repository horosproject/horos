/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>

//@class DCMPix;

typedef float itkPixelType;
//typedef itk::RGBPixel<unsigned char> itkPixelType;
typedef itk::Image< itkPixelType, 3 > ImageType;
typedef itk::ImportImageFilter< itkPixelType, 3 > ImportFilterType;



@interface ITK : NSObject {
	
	// ITK objects	
	ImportFilterType::Pointer importFilter;
}


- (id) initWith :(NSMutableArray*) pix :(float*) srcPtr :(long) slice;
- (id) initWithPix :(NSMutableArray*) pix volume:(float*) volumeData sliceCount:(long) slice resampleData:(BOOL)resampleData;

- (ImportFilterType::Pointer) itkImporter;
- (void)setupImportFilterWithSize:(ImportFilterType::SizeType)size  
	origin:(double[3])origin 
	spacing:(double[3])spacing 
	data:(float *)data
	filterWillOwnBuffer:(BOOL)filterWillOwnBuffer;


@end
