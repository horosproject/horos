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

#ifndef FVTIFF_H
#define FVTIFF_H

#import <Foundation/Foundation.h>
#include "tiffio.h"

#define TIFFTAG_FV_MMHEADER		34361
#define TIFFTAG_FV_MMSTAMP		34362
#define TIFFTAG_FV_USERBLOCK	34386

#define FV_IMAGE_NAME_LENGTH   	256
#define FV_SPATIAL_DIMENSION   	10
#define FV_DIMNAME_LENGTH		16
#define FV_UNITS_LENGTH			64

extern void FVTIFFInitialize(void);

typedef unsigned int	FV_MM_HANDLE;						// Size (bytes): 	   4

typedef struct
{
	char			Name[FV_DIMNAME_LENGTH];	//Dimension name e.g. Width		  16
	unsigned int	Size;						//Image width etc				   4
	double			Origin;						//Origin						   8
	double			Resolution;					//Image resolution			  	   8
	char			Units[FV_UNITS_LENGTH];		//Image calibration units		  64

}	FV_MM_DIM_INFO;									// Total Size (bytes):		 100  


static const TIFFFieldInfo FVTiffFieldInfo[] = {
    { TIFFTAG_FV_MMHEADER,	TIFF_VARIABLE, TIFF_VARIABLE, TIFF_BYTE, FIELD_CUSTOM, 1, 1, "FV_MMHEADER"},
    { TIFFTAG_FV_MMSTAMP,	TIFF_VARIABLE, TIFF_VARIABLE, TIFF_BYTE, FIELD_CUSTOM, 1, 1, "FV_MMSTAMP"},
    { TIFFTAG_FV_USERBLOCK,	TIFF_VARIABLE, TIFF_VARIABLE, TIFF_BYTE, FIELD_CUSTOM, 1, 1, "FV_USERBLOCK"},
};

typedef struct // this is from the FV docs, but I think the docs are not quite right on - Joel
{
	short			HeaderFlag;						//Size of header structure				2
	unsigned char	Status;							//image status							1
	unsigned char	ImageType;						//Image Type							1
	char			Name[FV_IMAGE_NAME_LENGTH];		//Image name							256
	FV_MM_HANDLE	Data;							//Handle to the data field				4
	unsigned int	NumberOfColors;					//Number of colors in palette			4
	FV_MM_HANDLE  	MM_256_Colors;					//handle to the palette field			4
	FV_MM_HANDLE  	MM_All_Colors;					//handle to the palette field			4
	unsigned int	CommentSize;					//Size of comments field				4
	FV_MM_HANDLE	Comment;						//handle to the comment field			4
	FV_MM_DIM_INFO	DimInfo[FV_SPATIAL_DIMENSION];		//Dimension Info						1000
	FV_MM_HANDLE	SpatialPosition;				//obsolete???????????					4
	short			MapType;	   					//Display mapping type					2
	short			reserved;						//Display mapping type					2
	double			MapMin;							//Display mapping minimum				8
	double  		MapMax;							//Display mapping maximum				8
	double			MinValue;						//Image histogram minimum				8
	double			MaxValue;						//Image histogram maximum				8
	FV_MM_HANDLE	Map;							//Handle to gray level mapping array	4
	double			Gamma;							//Image gray level correction factor	8
	double			Offset;							//Image gray level correction offset	8
	FV_MM_DIM_INFO	Gray;							//										100
	FV_MM_HANDLE	ThumbNail;						//handle to the ThumbNail field			4
	unsigned int	UserFieldSize;					//Size of Voice field					4
	FV_MM_HANDLE	UserFieldHandle;				//handle to the Voice field				4

}	FV_MM_HEAD;										// Total Size (bytes):					1456

int FV_Read_MM_HEAD(const char* data, FV_MM_HEAD* head);
int FV_Read_DIM_INFO(const char* data, FV_MM_DIM_INFO* info);
NSXMLDocument* XML_from_FVTiff(NSString* srcFile);

void FV_EMPTY_TIFFWarning(const char *module, const char *fmt, ...);

#endif
