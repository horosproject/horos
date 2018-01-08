/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/



#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

/** \brief  Parses files for importing into the database */

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
    NSDate              *date;
	
	long				width, height;
	long				NoOfFrames;
	long				NoOfSeries;
    
	NSMutableDictionary *dicomElements;
}

@property (retain) NSString *serieID;

// file functions
+ (BOOL) isTiffFile:(NSString *) file; /**< Test for TIFF file format */
+ (BOOL) isFVTiffFile:(NSString *) file; /**< Test for FV TIFF file format */
+ (BOOL) isDICOMFile:(NSString *) file; /**< Test for DICOM file format */
+ (BOOL) isDICOMFile:(NSString *) file compressed:(BOOL*) compressed; /**< Test for DICOM file format, returns YES for compressed BOOL if Transfer syntax is compressed. */
+ (BOOL) isDICOMFile:(NSString *) file compressed:(BOOL*) compressed image:(BOOL*) image;
+ (BOOL) isXMLDescriptedFile:(NSString *) file; /**< Test for XML descripted  file format */
+ (BOOL) isXMLDescriptorFile:(NSString *) file; /**< Test for XML descriptor file format. Fake DICOM for other files with XML descriptor*/
+ (void) setFilesAreFromCDMedia: (BOOL) f; /**< Set flag for filesAreFromCDMedia */
+ (void) setDefaults;  /**< Set DEFAULTSSET flag to NO */
+ (void) resetDefaults; /**< Resets to user defaults */
/**  Return string with invalid characters replaced
* replaces @"^" with @" "
* replaces @"/" with @"-"
* replaces @"\r" with @""
* replaces @"\n" with @""
* @":" withString:@"-"
* removes empty space at end of strings
*/
+ (NSString*) NSreplaceBadCharacter: (NSString*) str; 
+ (char *) replaceBadCharacter:(char *) str encoding: (NSStringEncoding) encoding; /**< Same as NSreplaceBadCharacter, but using char* and encodings */
+ (NSString *) stringWithBytes:(char *) str encodings: (NSStringEncoding*) encoding; /**< Convert char* str with NSStringEncoding* encoding to NSString */ 
+ (NSString *) stringWithBytes:(char *) str encodings: (NSStringEncoding*) encoding replaceBadCharacters: (BOOL) replace; /**< Convert char* str with NSStringEncoding* encoding to NSString */ 

- (NSPDFImageRep*) PDFImageRep; /**< Get a PDFImageRep from DICOM SR file */
- (long) NoOfFrames; /**< Number of frames in the file */
- (long) getWidth; /**<  Returns image width */
- (long) getHeight; /**< Return image Height */
- (long) NoOfSeries; /**< Returns number of seris in the file */
- (id) init:(NSString*) f; /**< Init with file at location NSString* f */
- (id) init:(NSString*) f DICOMOnly:(BOOL) DICOMOnly; /**< init with file at location NSString* f DICOM files only if DICOMOnly = YES */
- (id) initRandom; /**< Inits and returns an empty dicomFile */
//- (id) initWithXMLDescriptor: (NSString*)pathToXMLDescriptor path:(NSString*) f; /**< Init with XMLDescriptor for information and f for image data */
- (NSString*) patientUID; /**< Returns the patientUID */
+ (NSString*) patientUID: (id) src; /**< Returns the patientUID */

/** Returns a dictionary of the elements used to import into the database
* Keys:
* @"studyComment", @"studyID", @"studyDescription", @"studyDate", @"modality", @"patientID", @"patientName",
* @"patientUID", @"fileType", @"commentsAutoFill", @"album", @"SOPClassUID", @"SOPUID", @"institutionName",
* @"referringPhysiciansName", @"performingPhysiciansName", @"accessionNumber", @"patientAge", @"patientBirthDate", 
* @"patientSex", @"cardiacTime", @"protocolName", @"sliceLocation", @"imageID", @"seriesNumber", @"seriesDICOMUID",
* @"studyNumber", @"seriesID", @"hasDICOM"
* */

- (NSMutableDictionary *)dicomElements;  
- (id)elementForKey:(id)key;  /**< Returns the dicomElement for the key */
- (short)getPluginFile;  /**< Looks for a plugin to decode the file. If one is found decodes the file */
/** Parses the fileName to get the Series/Study/Image numbers
*  Used for files that don't have the information embedded such as TIFFs and jpegs
*  In these cases the files are sorted based on the file name.
*  Numbers at the end become the image number. The remainder of the file becomes the Series and Study ID 
*/
- (void)extractSeriesStudyImageNumbersFromFileName:(NSString *)tempString;  

-(short) getDicomFile;  /**< Decode DICOM.  Returns -1 for failure 0 for success */

#ifndef DECOMPRESS_APP
-(short) getNIfTI; /**< Decode NIfTI  Returns -1 for failure 0 for success */
+(NSXMLDocument *) getNIfTIXML : (NSString *) file; /**< Converts NIfTI to XML */
+ (BOOL) isNIfTIFile:(NSString *) file; /**< Test for Nifti file format */
#endif

/** Returns the COMMENTSAUTOFILL default. 
* If Yes, comments will be filled from the DICOM tag  commentsGroup/commentsElement
*/
- (BOOL) commentsFromDICOMFiles;
- (BOOL) autoFillComments; 
- (BOOL) splitMultiEchoMR; /**< Returns the splitMultiEchoMR default If YES, splits multi echo series into separate series by Echo number. */
- (BOOL) useSeriesDescription; /**< Returns the useSeriesDescription default. */
- (BOOL) noLocalizer; /**< Returns the NOLOCALIZER default. */
- (BOOL) combineProjectionSeries; /**< Returns the combineProjectionSeries default.  If YES, combines are projection Modalities: CR, DR into one series. */
- (BOOL) oneFileOnSeriesForUS; /**< Returns the oneFileOnSeriesForUS default */
- (BOOL) combineProjectionSeriesMode; /**< Returns the combineProjectionSeriesMode default. */
//- (BOOL) checkForLAVIM; /**< Returns the CHECKFORLAVIM default. */
- (BOOL) separateCardiac4D; /**< Returns the SEPARATECARDIAC4D default. If YES separates cardiac studies into separate gated series. */
- (int) commentsGroup; /**< Returns the commentsGroup default. The DICOM group to get comments from. */
- (int) commentsElement; /**< Returns the commentsGroup default.  The DICOM  element to get get comments from. */
- (int) commentsGroup2; /**< Returns the commentsGroup default. The DICOM group to get comments from. */
- (int) commentsElement2; /**< Returns the commentsGroup default.  The DICOM  element to get get comments from. */
- (int) commentsGroup3; /**< Returns the commentsGroup default. The DICOM group to get comments from. */
- (int) commentsElement3; /**< Returns the commentsGroup default.  The DICOM  element to get get comments from. */
- (int) commentsGroup4; /**< Returns the commentsGroup default. The DICOM group to get comments from. */
- (int) commentsElement4; /**< Returns the commentsGroup default.  The DICOM  element to get get comments from. */
- (BOOL) containsString: (NSString*) s inArray: (NSArray*) a;
- (BOOL) containsLocalizerInString: (NSString*) str;
@end


