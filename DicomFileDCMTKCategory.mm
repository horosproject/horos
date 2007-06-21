//
//  DicomFileDCMTKCategory.mm
//  OsiriX
//
//  Created by Lance Pysher on 6/27/06.

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

#import "DicomFileDCMTKCategory.h"
#import "Papyrus3/Papyrus3.h"
#import "DICOMToNSString.h"
//#import "browserController.h"
//#import "SRAnnotation.h"

// #undef verify

#include "osconfig.h"
#include "dcfilefo.h"
#include "dcdeftag.h"
#include "ofstd.h"

#include "dctk.h"
#include "dcdebug.h"
#include "cmdlnarg.h"
#include "ofconapp.h"
#include "dcuid.h"       /* for dcmtk version name */
#include "djdecode.h"    /* for dcmjpeg decoders */
#include "dipijpeg.h"    /* for dcmimage JPEG plugin */

extern NSLock	*PapyrusLock;


@implementation DicomFile (DicomFileDCMTKCategory)

+ (BOOL) isDICOMFileDCMTK:(NSString *) file{
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([file UTF8String]);
	if (status.good())
		return YES;
	return NO;
}

-(short) getDicomFileDCMTK
{
	int					itemType, i;
	long				cardiacTime = -1;
	short				x, theErr;
	PapyShort           fileNb, imageNb;
	PapyULong           nbVal;
	UValue_T            *val;
	SElement			*theGroupP;
	NSString			*converted = 0L;
	NSStringEncoding	encoding[ 10];
	NSString *echoTime = nil;
	const char *string = NULL;
	
	DcmFileFormat fileformat;
	[PapyrusLock lock];
//	OFCondition status = fileformat.loadFile([filePath UTF8String],  EXS_Unknown, EGL_noChange, DCM_MaxReadLength, ERM_autoDetect);
	OFCondition status = fileformat.loadFile([filePath UTF8String],  EXS_Unknown, EGL_noChange, DCM_MaxReadLength, ERM_autoDetect);
	[PapyrusLock unlock];
	if (status.good())
	{
		NSString *characterSet = 0L;
		for( i = 0; i < 10; i++) encoding[ i] = NSISOLatin1StringEncoding;
		
		DcmDataset *dataset = fileformat.getDataset();
		
		//TransferSyntax
		if (fileformat.getMetaInfo()->findAndGetString(DCM_TransferSyntaxUID, string, OFFalse).good() && string != NULL)
		{
			if( [[NSString stringWithCString:string] isEqualToString:@"1.2.840.10008.1.2.4.100"])
			{
				fileType = [[NSString stringWithString:@"DICOMMPEG2"] retain];
				[dicomElements setObject:fileType forKey:@"fileType"];
			}
			else
			{
				fileType = [[NSString stringWithString:@"DICOM"] retain];
				[dicomElements setObject:fileType forKey:@"fileType"];
			}
		}
		else
		{
			fileType = [[NSString stringWithString:@"DICOM"] retain];
			[dicomElements setObject:fileType forKey:@"fileType"];
		}
		
		if ([self autoFillComments]  == YES ||[self checkForLAVIM] == YES)
		{
			if( [self autoFillComments])
			{
				NSString	*commentsField;
				DcmTagKey key = DcmTagKey([self commentsGroup], [self commentsElement]);
				if (dataset->findAndGetString(key, string, OFFalse).good() && string != NULL){
					commentsField = [NSString stringWithCString:string];
					[dicomElements setObject:commentsField forKey:@"commentsAutoFill"];

				}
			}
			
			if([self checkForLAVIM] )
			{
				NSString	*album = 0L;
				if (dataset->findAndGetString(DCM_ImageComments, string, OFFalse).good() && string != NULL){
					album = [NSString stringWithCString:string];					
					if( [album length] >= 2)
					{
						if( [[album substringToIndex:2] isEqualToString: @"LV"])
						{
							album = [album substringFromIndex:2];
							[dicomElements setObject:album forKey:@"album"];
						}
					}
				}
				
				DcmTagKey albumKey = DcmTagKey(0x0040, 0x0280); 
				if (dataset->findAndGetString(albumKey, string, OFFalse).good() && string != NULL){
					album = [NSString stringWithCString:string];					
					if( [album length] >= 2)
					{
						if( [[album substringToIndex:2] isEqualToString: @"LV"])
						{
							album = [album substringFromIndex:2];
							[dicomElements setObject:album forKey:@"album"];
						}
					}
				} 
				
				 albumKey = DcmTagKey(0x0040, 0x1400); 
				 if (dataset->findAndGetString(albumKey, string, OFFalse).good() && string != NULL){
					album = [NSString stringWithCString:string];					
					if( [album length] >= 2)
					{
						if( [[album substringToIndex:2] isEqualToString: @"LV"])
						{
							album = [album substringFromIndex:2];
							[dicomElements setObject:album forKey:@"album"];
						}
					}
				} 
			}  //ckeck LAVIN
		} //check autofill and album
		
		//SOPClass
		if (dataset->findAndGetString(DCM_SOPClassUID, string, OFFalse).good() && string != NULL){
			[dicomElements setObject:[NSString stringWithCString:string] forKey:@"SOPClassUID"];
		}
		
		//Character Set
		if (dataset->findAndGetString(DCM_SpecificCharacterSet, string, OFFalse).good() && string != NULL)
		{
			NSArray	*c = [[NSString stringWithCString:string] componentsSeparatedByString:@"\\"];
			
			if( [c count] >= 10) NSLog( @"Encoding number >= 10 ???");
			
			if( [c count] < 10)
			{
				for( i = 0; i < [c count]; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c objectAtIndex: i]];
				for( i = [c count]; i < 10; i++) encoding[ i] = [NSString encodingForDICOMCharacterSet: [c lastObject]];
			}
		}
		
		//Image Type
		if (dataset->findAndGetString(DCM_ImageType, string, OFFalse).good() && string != NULL){
			imageType = [[NSString stringWithCString:string] retain];
		}
		else
			imageType = nil;
		
		if( imageType) [dicomElements setObject:imageType forKey:@"imageType"];
		
		//SOPInstanceUID
		if (dataset->findAndGetString(DCM_SOPInstanceUID, string, OFFalse).good() && string != NULL){
			SOPUID = [[NSString stringWithCString:string] retain];
		}
		else
			SOPUID = nil;
		if (SOPUID) [dicomElements setObject:SOPUID forKey:@"SOPUID"];
		
		//Study Description
		if (dataset->findAndGetString(DCM_StudyDescription, string, OFFalse).good() && string != NULL)
		{
			study = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
		}
		else
			study = [[NSString alloc] initWithString:@"unnamed"];
		[dicomElements setObject:study forKey:@"studyDescription"];
		
		//Modality
		if (dataset->findAndGetString(DCM_Modality, string, OFFalse).good() && string != NULL){
			Modality = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
		}
		else
			Modality = [[NSString alloc] initWithString:@"OT"];
		[dicomElements setObject:Modality forKey:@"modality"];
		
		
		//Acquistion Date
		if (dataset->findAndGetString(DCM_AcquisitionDate, string, OFFalse).good() && string != NULL){
			NSString	*studyDate = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			if (dataset->findAndGetString(DCM_AcquisitionTime, string, OFFalse).good() && string != NULL){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithBytes:string length:6 encoding: NSASCIIStringEncoding];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		else if (dataset->findAndGetString(DCM_SeriesDate, string, OFFalse).good() && string != NULL){
			NSString	*studyDate = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			if (dataset->findAndGetString(DCM_SeriesTime, string, OFFalse).good() && string != NULL){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithBytes:string length:6 encoding: NSASCIIStringEncoding];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		
		else if (dataset->findAndGetString(DCM_StudyDate, string, OFFalse).good() && string != NULL){
			NSString	*studyDate = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			if (dataset->findAndGetString(DCM_StudyTime, string, OFFalse).good() && string != NULL){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithBytes:string length:6 encoding: NSASCIIStringEncoding];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		else date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:0L] retain];
		if( date) [dicomElements setObject:date forKey:@"studyDate"];
		
		//Series Description
		if (dataset->findAndGetString(DCM_SeriesDescription, string, OFFalse).good() && string != NULL)
		{
			serie = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
		}
		else
			serie = [[NSString alloc] initWithString:@"unnamed"];
		[dicomElements setObject:serie forKey:@"seriesDescription"];
		
		//Institution Name
		if (dataset->findAndGetString(DCM_InstitutionName,  string, OFFalse).good() && string != NULL)
		{
			NSString *institution = [DicomFile stringWithBytes: (char*) string encodings:encoding];
			[dicomElements setObject:institution forKey:@"institutionName"];
		}
		
		//Referring Physician
		if (dataset->findAndGetString(DCM_ReferringPhysiciansName,  string, OFFalse).good() && string != NULL)
		{
			NSString *referringPhysiciansName = [DicomFile stringWithBytes: (char*) string encodings:encoding];
			[dicomElements setObject:referringPhysiciansName forKey:@"referringPhysiciansName"];
		}
		
		//Performing Physician
		if (dataset->findAndGetString(DCM_PerformingPhysiciansName,  string, OFFalse).good() && string != NULL){
			NSString *performingPhysiciansName = [DicomFile stringWithBytes: (char*) string encodings:encoding];
			[dicomElements setObject:performingPhysiciansName forKey:@"performingPhysiciansName"];
		}
		
		//Accession Number
		if (dataset->findAndGetString(DCM_AccessionNumber,  string, OFFalse).good() && string != NULL)
		{
			NSString *accessionNumber = [DicomFile stringWithBytes: (char*) string encodings:encoding];
			[dicomElements setObject:accessionNumber forKey:@"accessionNumber"];
		}
		
		//Patients Name
		if (dataset->findAndGetString(DCM_PatientsName, string, OFFalse).good() && string != NULL)
		{
			name = [[DicomFile stringWithBytes: (char*) string encodings:encoding] retain];
			if(name == 0L) name = [[NSString alloc] initWithCString: string encoding: encoding[ 0]];
		}
		else
			name = [[NSString alloc] initWithString:@"No name"];
		
		[dicomElements setObject:name forKey:@"patientName"];
		
		//Patient ID
		if (dataset->findAndGetString(DCM_PatientID, string, OFFalse).good() && string != NULL){
			patientID  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			[dicomElements setObject:patientID forKey:@"patientID"];
		}
		
		//Patients Age
		if (dataset->findAndGetString(DCM_PatientsAge, string, OFFalse).good() && string != NULL){
			NSString *patientAge  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			[dicomElements setObject:patientAge forKey:@"patientAge"];	
			[patientAge  release];
		}
		
		//Patients BD
		if (dataset->findAndGetString(DCM_PatientsBirthDate, string, OFFalse).good() && string != NULL){
			NSString		*patientDOB =  [[[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding] autorelease];
			NSCalendarDate	*DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
			if( DOB) [dicomElements setObject:DOB forKey:@"patientBirthDate"];
		}
		
		//Patients Sex
		if (dataset->findAndGetString(DCM_PatientsSex, string, OFFalse).good() && string != NULL){
			NSString *patientSex  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			[dicomElements setObject:patientSex forKey:@"patientSex"];	
			[patientSex  release];
		}
		
		
		//Cardiac Time
		if (dataset->findAndGetString(DCM_ScanOptions, string, OFFalse).good() && string != NULL){
			if( strlen( string) >= 4)
			{
				if( string[ 0] == 'T' && string[ 1] == 'P')
				{
					if( string[ 2] >= '0' && string[ 2] <= '9')
					{
						if( string[ 3] >= '0' && string[ 3] <= '9')
						{
							cardiacTime = (string[ 2] - '0')*10;
							cardiacTime += string[ 3] - '0';
						}
						else
						{
							cardiacTime = string[ 2] - '0';
						}
					}
				}
			}
			[dicomElements setObject:[NSNumber numberWithLong: cardiacTime] forKey:@"cardiacTime"];
		}
		
		//Protocol Name
		if (dataset->findAndGetString(DCM_ProtocolName, string, OFFalse).good() && string != NULL){
			NSString *protocol  = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			[dicomElements setObject:protocol  forKey:@"protocolName"];	
			[protocol   release];
		}
		
		//Echo Time
		if (dataset->findAndGetString(DCM_EchoTime, string, OFFalse).good() && string != NULL){
			echoTime = [[[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding] autorelease];		
		}
		
		//Image Number
		if (dataset->findAndGetString(DCM_InstanceNumber, string, OFFalse).good() && string != NULL){
			imageID = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			int val = [imageID intValue];
			[imageID release];
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];
		}
		else imageID = 0L;
		
		// Compute slice location
			
		Float64		orientation[9];
		Float64		origin[ 3];
		Float64		location = 0;
		UValue_T    *tmp;
		int count = 0;
		
		origin[0] = origin[1] = origin[2] = 0;
		
		while (count < 3 && dataset->findAndGetFloat64(DCM_ImagePositionPatient, origin[count], count, OFFalse).good())
			count++;
		
		orientation[ 0] = 1;	orientation[ 1] = 0;		orientation[ 2] = 0;
		orientation[ 3] = 0;	orientation[ 4] = 1;		orientation[ 5] = 0;
		
		count = 0;
		while (count < 6 && dataset->findAndGetFloat64(DCM_ImageOrientationPatient, orientation[count], count, OFFalse).good())
			count++;

				// Compute normal vector
		orientation[6] = orientation[1]*orientation[5] - orientation[2]*orientation[4];
		orientation[7] = orientation[2]*orientation[3] - orientation[0]*orientation[5];
		orientation[8] = orientation[0]*orientation[4] - orientation[1]*orientation[3];
		
		if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8])) location = origin[ 0];
		if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8])) location = origin[ 1];
		if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7])) location = origin[ 2];
		
		[dicomElements setObject:[NSNumber numberWithDouble: (double)location] forKey:@"sliceLocation"];
		
		if( imageID == 0L)
		{
			int val = 10000 + location*10.;
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];
		}
		[dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
		
		//Series Number
		if (dataset->findAndGetString(DCM_SeriesNumber, string, OFFalse).good() && string != NULL){
			seriesNo = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
		}
		else
			seriesNo = [[NSString alloc] initWithString: @"0"];
		if( seriesNo) [dicomElements setObject:[NSNumber numberWithInt:[seriesNo intValue]]  forKey:@"seriesNumber"];
		
		//Series Instance UID		
		if (dataset->findAndGetString(DCM_SeriesInstanceUID, string, OFFalse).good() && string != NULL){
			serieID = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
			[dicomElements setObject:serieID forKey:@"seriesDICOMUID"];
		}
		else
			serieID = [[NSString alloc] initWithString:name];
						
		//Series ID
		
		if( cardiacTime != -1 && [self separateCardiac4D] == YES)  // For new Cardiac-CT Siemens series
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ %2.2d", serieID , cardiacTime];
			[serieID release];
			serieID = n;
		}
		
		if( seriesNo)
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%8.8d %@", [seriesNo intValue] , serieID];
			[serieID release];
			serieID = n;
		}
		
		if( imageType != 0 && [self useSeriesDescription])
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , imageType];
			[serieID release];
			serieID = n;
		}
		
		if( serie != 0L && [self useSeriesDescription])
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ %@", serieID , serie];
			[serieID release];
			serieID = n;
		}
		
		//Segregate by TE  values
		if( echoTime != nil && [self splitMultiEchoMR])
		{
			NSString	*n;
			
			n = [[NSString alloc] initWithFormat:@"%@ TE-%@", serieID , echoTime];
			[serieID release];
			serieID = n;
		}
		
		//Study Instance UID
		if (dataset->findAndGetString(DCM_StudyInstanceUID, string, OFFalse).good() && string != NULL){
			studyID = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
		}
		else
			studyID = [[NSString alloc] initWithString:name];
		[dicomElements setObject:studyID forKey:@"studyID"];
			
		//StudyID
		if (dataset->findAndGetString(DCM_StudyID, string, OFFalse).good() && string != NULL){
			studyIDs = [[NSString alloc] initWithCString:string encoding: NSASCIIStringEncoding];
		}
		else
			studyIDs = [[NSString alloc] initWithString:@"0"];
		if( studyIDs) [dicomElements setObject:studyIDs forKey:@"studyNumber"];
		
		//Rows
		unsigned short rows = 0;
		if (dataset->findAndGetUint16(DCM_Rows, rows, OFFalse).good()){
			height = rows;
			height /=2;
			height *=2;
		}
		
		//Columns
		
		unsigned short columns = 0;
		if (dataset->findAndGetUint16(DCM_Columns, columns, OFFalse).good()){
			width = columns/2;
			width *=2;
		}
		
		//Number of Frames
		if (dataset->findAndGetString(DCM_NumberOfFrames, string, OFFalse).good() && string != NULL){
			NoOfFrames = atoi(string);
		}
		
		NoOfSeries = 1;
			
		if( patientID == 0L) patientID = [[NSString alloc] initWithString:@""];
		
		if( NoOfFrames > 1) // SERIE ID MUST BE UNIQUE!!!!!
		{
			NSString *newSerieID = [[NSString alloc] initWithFormat:@"%@-%@-%@", serieID, imageID, [filePath lastPathComponent]];
			[serieID release];
			serieID = newSerieID;
		}
		
		if ([self noLocalizer])
		{
			NSRange range = [serie rangeOfString:@"localizer" options:NSCaseInsensitiveSearch];
			if( range.location != NSNotFound)
			{
				return -1;
			}
		}
		
		[dicomElements setObject:[self patientUID] forKey:@"patientUID"];
		
		if( serieID == 0L) serieID = [[NSString alloc] initWithString:name];
		
		if (([Modality isEqualToString:@"CR"] || [Modality isEqualToString:@"DR"] || [Modality isEqualToString:@"DX"] || [Modality  isEqualToString:@"RF"]) && [self combineProjectionSeries])
		{
			if( [self combineProjectionSeriesMode] == 0)		// *******Combine all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject:studyID forKey:@"seriesID"];
				[dicomElements setObject:[NSNumber numberWithLong: [serieID intValue] * 1000 + [imageID intValue]] forKey:@"imageID"];
			}
			else if( [self combineProjectionSeriesMode] == 1)	// *******Split all CR and DR Modality series in a study into one series
			{
				[dicomElements setObject: [serieID stringByAppendingString: imageID] forKey:@"seriesID"];
			}
			else NSLog( @"ARG! ERROR !? Unknown combineProjectionSeriesMode");
		}
		else
			[dicomElements setObject:serieID forKey:@"seriesID"];
		
		if( studyID == 0L)
		{
			studyID = [[NSString alloc] initWithString:name];
			[dicomElements setObject:studyID forKey:@"studyID"];
		}
		
		if( imageID == 0L)
		{
			imageID = [[NSString alloc] initWithString:name];
			[dicomElements setObject:imageID forKey:@"SOPUID"];
		}
	
		if( date == 0L)
		{
			date = [[NSCalendarDate dateWithYear:1901 month:1 day:1 hour:0 minute:0 second:0 timeZone:0L] retain];
			[dicomElements setObject:date forKey:@"studyDate"];
		}
		
		[dicomElements setObject:[NSNumber numberWithBool:YES] forKey:@"hasDICOM"];
		
		//NSLog(@"DicomElements:  %@ %@" ,NSStringFromClass([dicomElements class]) ,[dicomElements description]);
		
		if( name != 0L && studyID != 0L && serieID != 0L && imageID != 0L && width != 0 && height != 0)
		{
			return 0;   // success
		}
	}
	
	return-1;
}

// SRAnnotation and BrowserController cause many problems for SafeDB Rebuild need a work around ????
- (BOOL) checkForROISR:(NSDictionary *)dicomInfo{
/*
	if ([[dicomInfo objectForKey:@"seriesID"] isEqualToString:@"5002"] &&
		[[dicomInfo objectForKey:@"seriesID"] isEqualToString:@"OsiriX ROI SR"] &&
		//Comprehensive SR Class uid
		[[dicomInfo objectForKey:@"SOPClassUID"] isEqualToString:@"1.2.840.10008.5.1.4.1.1.88.33"]) {
			NSLog(@"have SR Roi");
			int frameNumber = 0;
			SRAnnotation *sr = [[[SRAnnotation alloc] initWithContentsOfFile: filePath] autorelease];
			NSString *path = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"ROIs"];
			NSString *seriesNumber = @"1";   // should be one for DICOM I hope.
			NSMutableString *uniquePath = [[[NSString stringWithFormat:@"%@ %@",[dicomInfo objectForKey:@"SOPUID"],
											[dicomInfo objectForKey:@"imageID"]] 
											mutableCopy] autorelease];
			[uniquePath replaceOccurrencesOfString:@"/" withString:@"-" options:NSLiteralSearch range:NSMakeRange(0, [uniquePath length])];
			NSString *str = [path stringByAppendingFormat: @"%@-%d", uniquePath , frameNumber];
			//Need to move to roi folder and merge with any previous ROI for image
		}
*/		
}

@end
