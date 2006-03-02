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
	NSString			*sliceLocation;
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

- (long) NoOfFrames;
- (long) getWidth;
- (long) getHeight;
- (long) NoOfSeries;
- (id) init:(NSString*) f;
- (NSString*) patientUID;
- (NSMutableDictionary *)dicomElements;
- (id)elementForKey:(id)key;
- (short)getPluginFile;
- (void)extractSeriesStudyImageNumbersFromFileName:(NSString *)tempString;
- (short) decodeDICOMFileWithDCMFramework;

- (id) initWithXMLDescriptor: (NSString*)pathToXMLDescriptor path:(NSString*) f;

@end
