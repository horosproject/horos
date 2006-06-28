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

#undef verify

#include "osconfig.h"
#include "dcfilefo.h"
#include "dcdeftag.h"
#include "ofstd.h"

extern NSLock	*PapyrusLock;


@implementation DicomFile (DicomFileDCMTKCategory)

+ (BOOL) isDICOMFileDCMTK:(NSString *) file{
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([file UTF8String]);
	if (status.good())
		return YES;
	return NO;
}

-(short) getDicomFileDCMTK{
	int					itemType;
	long				cardiacTime = -1;
	short				x, theErr;
	PapyShort           fileNb, imageNb;
	PapyULong           nbVal;
	UValue_T            *val;
	SElement			*theGroupP;
	NSString			*converted = 0L;
	NSStringEncoding	encoding;//NSStringEncoding
	NSString *echoTime = nil;
	const char *string = NULL;
	
	DcmFileFormat fileformat;
	[PapyrusLock lock];
	OFCondition status = fileformat.loadFile([filePath UTF8String]);
	[PapyrusLock unlock];
	if (status.good()){
		NSString *characterSet = 0L;
		fileType = [[NSString stringWithString:@"DICOM"] retain];
		[dicomElements setObject:fileType forKey:@"fileType"];
		encoding = NSISOLatin1StringEncoding;
		DcmDataset *dataset = fileformat.getDataset();
		
		if ([self autoFillComments]  == YES ||[self checkForLAVIM] == YES)
		{
			if( [self autoFillComments])
			{
				NSString	*commentsField;
				DcmTagKey key = DcmTagKey([self commentsGroup], [self commentsElement]);
				if (dataset->findAndGetString(key, string, OFFalse).good()){
					commentsField = [NSString stringWithCString:string];
					[dicomElements setObject:commentsField forKey:@"commentsAutoFill"];

				}
			}
			
			if([self checkForLAVIM] )
			{
				NSString	*album = 0L;
				if (dataset->findAndGetString(DCM_ImageComments, string, OFFalse).good()){
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
				if (dataset->findAndGetString(albumKey, string, OFFalse).good()){
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
				 if (dataset->findAndGetString(albumKey, string, OFFalse).good()){
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
		if (dataset->findAndGetString(DCM_SOPClassUID, string, OFFalse).good()){
			[dicomElements setObject:[NSString stringWithCString:string] forKey:@"SOPClassUID"];
		}
		
		//Character Set
		if (dataset->findAndGetString(DCM_SpecificCharacterSet, string, OFFalse).good()){
			characterSet = [NSString stringWithCString:string];
			encoding = [NSString encodingForDICOMCharacterSet:characterSet];
		}
		
		//Image Type
		if (dataset->findAndGetString(DCM_ImageType, string, OFFalse).good()){
			imageType = [NSString stringWithCString:string];
		}
		else
			imageType = nil;
		if( imageType) [dicomElements setObject:imageType forKey:@"imageType"];
		
		//SOPInstanceUID
		if (dataset->findAndGetString(DCM_SOPInstanceUID, string, OFFalse).good()){
			SOPUID = [NSString stringWithCString:string];
		}
		else
			SOPUID = nil;
		if (SOPUID) [dicomElements setObject:SOPUID forKey:@"SOPUID"];
		
		//Study Description
		if (dataset->findAndGetString(DCM_StudyDescription, string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			study  = [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
		}
		else
			study = [[NSString alloc] initWithString:@"unnamed"];
		[dicomElements setObject:study forKey:@"studyDescription"];
		
		//Modality
		if (dataset->findAndGetString(DCM_StudyDescription, string, OFFalse).good()){
			Modality = [[NSString alloc] initWithCString:string];
		}
		else
			Modality = [[NSString alloc] initWithString:@"OT"];
		[dicomElements setObject:Modality forKey:@"modality"];
		
		//Acquistion Date
		if (dataset->findAndGetString(DCM_AcquisitionDate, string, OFFalse).good()){
			NSString	*studyDate = [[NSString alloc] initWithCString:string];
			if (dataset->findAndGetString(DCM_AcquisitionTime, string, OFFalse).good()){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithCString:string length:6];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		else if (dataset->findAndGetString(DCM_SeriesDate, string, OFFalse).good()){
			NSString	*studyDate = [[NSString alloc] initWithCString:string];
			if (dataset->findAndGetString(DCM_SeriesTime, string, OFFalse).good()){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithCString:string length:6];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		else if (dataset->findAndGetString(DCM_StudyDate, string, OFFalse).good()){
			NSString	*studyDate = [[NSString alloc] initWithCString:string];
			if (dataset->findAndGetString(DCM_StudyTime, string, OFFalse).good()){
				NSString*   completeDate;
				NSString*   studyTime = [[NSString alloc] initWithCString:string length:6];
				completeDate = [studyDate stringByAppendingString:studyTime];
				date = [[NSCalendarDate alloc] initWithString:completeDate calendarFormat:@"%Y%m%d%H%M%S"];
				[studyTime release];
			}
			else date = [[NSCalendarDate alloc] initWithString:studyDate calendarFormat:@"%Y%m%d"];
				
			[studyDate release];
		}
		else date = [[[[NSFileManager defaultManager] fileAttributesAtPath:filePath traverseLink:NO ] fileCreationDate] retain];
		if( date) [dicomElements setObject:date forKey:@"studyDate"];
		
		//Series Description
		if (dataset->findAndGetString(DCM_SeriesDescription, string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			serie  = [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
		}
		else
			serie = [[NSString alloc] initWithString:@"unnamed"];
		[dicomElements setObject:serie forKey:@"seriesDescription"];
		
		//Institution Name
		if (dataset->findAndGetString(DCM_InstitutionName,  string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			NSString *institution =  [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
			[dicomElements setObject:institution forKey:@"institutionName"];
			[institution release];
		}
		
		//Referring Physician
		if (dataset->findAndGetString(DCM_ReferringPhysiciansName,  string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			NSString *referringPhysiciansName =  [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
			[dicomElements setObject:referringPhysiciansName forKey:@"institutionName"];
			[referringPhysiciansName release];
		}
		
		//Performing Physician
		if (dataset->findAndGetString(DCM_PerformingPhysiciansName,  string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			NSString *performingPhysiciansName =  [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
			[dicomElements setObject:performingPhysiciansName forKey:@"institutionName"];
			[performingPhysiciansName release];
		}
		
		//Accession Number
		if (dataset->findAndGetString(DCM_AccessionNumber,  string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			NSString *accessionNumber =  [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
			[dicomElements setObject:accessionNumber forKey:@"institutionName"];
			[accessionNumber release];
		}
		
		//Patients Name
		if (dataset->findAndGetString(DCM_PatientsName, string, OFFalse).good()){
			char *s = [DicomFile replaceBadCharacter:(char *)string encoding: encoding];
			name  = [[NSString alloc] initWithBytes: s length: strlen(s) encoding:encoding];
			if(name == 0L) name = [[NSString alloc] initWithCString: string];
		}
		else
			name = [[NSString alloc] initWithString:@"No name"];
		[dicomElements setObject:name forKey:@"patientName"];
		
		//Patient ID
		if (dataset->findAndGetString(DCM_PatientID, string, OFFalse).good()){
			patientID  = [[NSString alloc] initWithCString:string];
			[dicomElements setObject:patientID forKey:@"patientID"];
		}
		
		//Patients Age
		if (dataset->findAndGetString(DCM_PatientsAge, string, OFFalse).good()){
			NSString *patientAge  = [[NSString alloc] initWithCString:string];
			[dicomElements setObject:patientAge forKey:@"patientAge"];	
			[patientAge  release];
		}
		
		//Patients BD
		if (dataset->findAndGetString(DCM_PatientsBirthDate, string, OFFalse).good()){
			NSString		*patientDOB =  [[[NSString alloc] initWithCString:string] autorelease];
			NSCalendarDate	*DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
			if( DOB) [dicomElements setObject:DOB forKey:@"patientBirthDate"];
		}
		
		//Patients Sex
		if (dataset->findAndGetString(DCM_PatientsAge, string, OFFalse).good()){
			NSString *patientSex  = [[NSString alloc] initWithCString:string];
			[dicomElements setObject:patientSex forKey:@"patientSex"];	
			[patientSex  release];
		}
		
		//Cardiac Time
		if (dataset->findAndGetString(DCM_ScanOptions, string, OFFalse).good()){
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
		if (dataset->findAndGetString(DCM_ProtocolName, string, OFFalse).good()){
			NSString *protocol  = [[NSString alloc] initWithCString:string];
			[dicomElements setObject:protocol  forKey:@"protocolName"];	
			[protocol   release];
		}
		
		//Echo Time
		if (dataset->findAndGetString(DCM_EchoTime, string, OFFalse).good()){
			echoTime = [[[NSString alloc] initWithCString:string] autorelease];		
		}
		
		//Image Number
		if (dataset->findAndGetString(DCM_InstanceNumber, string, OFFalse).good()){
			imageID = [[NSString alloc] initWithCString:string];
			int val = [imageID intValue];
			[imageID release];
			imageID = [[NSString alloc] initWithFormat:@"%5d", val];
		}
		else imageID = [[NSString alloc] initWithFormat:@"%5d", 1];
		[dicomElements setObject:[NSNumber numberWithLong: [imageID intValue]] forKey:@"imageID"];
		
		// Compute slice location
				
		float		orientation[ 9];
		float		origin[ 3];
		float		location = 0;
		UValue_T    *tmp;
		
		origin[0] = origin[1] = origin[2] = 0;
		
		if (dataset->findAndGetString(DCM_ImagePositionPatient, string, OFFalse).good()){
			
		}



		
		
	}
	
	if (status.good())
		return YES;
	return NO;
}

@end
