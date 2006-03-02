//
//  PluginFileFormatDecoder.h
//  OsiriX
//
//  Created by Lance Pysher on 10/2/05.

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


@interface PluginFileFormatDecoder : NSObject {

	NSNumber *_height;
	NSNumber *_width;
	float *_fImage;
	NSNumber * _rowBytes;
	NSNumber *_windowWidth;
	NSNumber *_windowLevel;
	BOOL _isRGB;
	
	NSString *_patientName;
	NSString *_patientID;
	NSString *_studyID;
	NSString *_seriesID;
	NSString *_imageID;
	NSString *_studyDescription;
	NSString *_seriesDescription;
}
// not used currently
+ (float *)decodedDataAtPath:(NSString *)path;

/*
	This is the main method to get the fImage float pointer used by DCMPix to create an image.  
	If the data is RGB the pointe should be to unsigned char with the format ARGB
	Grayscale data is a float pointer
*/

- (float *)checkLoadAtPath:(NSString *)path;

//returns values needed by DCMPix
- (NSNumber *)height;
- (NSNumber *)width;
- (NSNumber *)rowBytes;
- (NSNumber *)windowWidth; //optional
- (NSNumber *)windowLevel; //optional
- (BOOL)isRGB; //default is YES

// Optional values for loading into the DB.
- (NSString *)patientName;
- (NSString *)patientID;
- (NSString *)studyID;
- (NSString *)seriesID;
- (NSString *)imageID;
- (NSString *)studyDescription;
- (NSString *)seriesDescription;


@end
