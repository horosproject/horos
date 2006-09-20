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


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>



@interface DicomFile: NSObject
{
    NSString            *name;
    NSString            *study;
    NSString            *serie;
    NSString            *filePath, *fileType;
    NSString            *Modality;
	NSString			*SOPUID;
	NSString			*imageType;
    
    NSString            *studyID;
    NSString            *serieID;
    NSString            *imageID;
	NSString			*patientID;
	NSString			*studyIDs;
	NSString			*seriesNo;
    NSCalendarDate		*date;
	
	long				width, height;
	long				NoOfFrames;
	long				NoOfSeries;
    
	NSMutableDictionary *dicomElements;
	
}
// file functions
+ (BOOL) isTiffFile:(NSString *) file;
+ (BOOL) isFVTiffFile:(NSString *) file;
+ (BOOL) isDICOMFile:(NSString *) file;
+ (BOOL) isXMLDescriptedFile:(NSString *) file;
+ (BOOL) isXMLDescriptorFile:(NSString *) file;

+ (void) setDefaults;
+ (void) resetDefaults;
+ (NSString*) NSreplaceBadCharacter: (NSString*) str;
+ (char *) replaceBadCharacter:(char *) str encoding: (NSStringEncoding) encoding;

- (long) NoOfFrames;
- (long) getWidth;
- (long) getHeight;
- (long) NoOfSeries;
- (id) init:(NSString*) f;
- (id) init:(NSString*) f DICOMOnly:(BOOL) DICOMOnly;
- (id) initRandom;
- (NSString*) patientUID;
- (NSMutableDictionary *)dicomElements;
- (id)elementForKey:(id)key;
- (short)getPluginFile;
- (void)extractSeriesStudyImageNumbersFromFileName:(NSString *)tempString;
- (short) decodeDICOMFileWithDCMFramework;

- (id) initWithXMLDescriptor: (NSString*)pathToXMLDescriptor path:(NSString*) f;
-(short) getDicomFile;
- (BOOL)autoFillComments;
- (BOOL)splitMultiEchoMR;
- (BOOL)useSeriesDescription;
- (BOOL) noLocalizer;
- (BOOL)combineProjectionSeries;
- (BOOL)checkForLAVIM;
- (int)commentsGroup ;
- (int)commentsElement ;
@end


