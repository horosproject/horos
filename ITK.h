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




#import <Cocoa/Cocoa.h>

@class DCMPix;

typedef float itkPixelType;
//typedef itk::RGBPixel<unsigned char> itkPixelType;
typedef itk::Image< itkPixelType, 3 > ImageType;
typedef itk::ImportImageFilter< itkPixelType, 3 > ImportFilterType;

@interface ITK : NSObject {

	// OsiriX images

	NSMutableArray				*pixList;
	float						*data;
	DCMPix						*firstObject;
	
	// ITK objects
	
	ImportFilterType::Pointer importFilter;
}

- (id) initWith :(NSMutableArray*) pix :(float*) srcPtr :(long) slice;
- (ImportFilterType::Pointer) itkImporter;

@end
