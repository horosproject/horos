/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "AppController.h"
#import "SRAnnotation.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "BrowserController.h"
#import "DicomFile.h"
#import "DCMCalendarDate.h"
#import "DicomStudy.h"
#import "DicomSeries.h"
#import "N2Debug.h"
#import "DICOMToNSString.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

@implementation SRAnnotation

+ (NSData *)roiFromDICOM:(NSString *)path
{
	if( path == nil)
		return nil;
	NSData *archiveData = nil;
	DcmFileFormat fileformat;
	OFCondition status = fileformat.loadFile([path UTF8String]);
	if( status != EC_Normal) return nil;
	
	OFString name;
	const Uint8 *buffer = nil;
	unsigned int length;
	
	if (fileformat.getDataset()->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good()) //DCM_EncapsulatedDocument
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	else if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good())	//DCM_EncapsulatedDocument
	{
		archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
	}
	
	return archiveData;
}

//All the ROIs for an image are archived as an NSArray.  We will need to extract all the necessary ROI info to create the basic SR before adding archived data. 
+ (NSString*) archiveROIsAsDICOM: (NSArray *) rois toPath: (NSString *) path forImage: (id) image
{
	SRAnnotation *sr = [[[SRAnnotation alloc] initWithROIs:rois path:path forImage:image] autorelease];
	id study = [image valueForKeyPath:@"series.study"];
	
	NSManagedObject *roiSRSeries = [study roiSRSeries];
	
	NSString *seriesInstanceUID = [roiSRSeries valueForKey:@"seriesDICOMUID"];
	
	if( seriesInstanceUID)
		[sr setSeriesInstanceUID: seriesInstanceUID];
	
	[sr writeToFileAtPath: path];
	
	return nil;
}

+ (NSString*) getImageRefSOPInstanceUID:(NSString*) path;
{
	NSString	*result = nil;
	DSRDocument	*document = new DSRDocument();
	
	OFCondition status = EC_Normal;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{			
		DcmFileFormat fileformat;
		status  = fileformat.loadFile([path UTF8String]);
		if (status.good())
		{
			status = document->read(*fileformat.getDataset());
			
			int instanceNumber = [[NSString stringWithFormat:@"%s", document->getInstanceNumber()] intValue];
			
			DSRCodedEntryValue codedEntryValue = DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference");
			if (document->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0 )
			{
				DSRImageReferenceValue imageRef = document->getTree().getCurrentContentItem().getImageReference();
				result = [NSString stringWithFormat:@"%s", imageRef.getSOPInstanceUID().c_str()];
				
				if( [result length] > 0)
					result = [result stringByAppendingFormat: @"-%d", instanceNumber];
				else result = nil;
			}
		}
	}
	
	delete document;
	
	return result;
}

+ (NSString*) getReportFilenameFromSR:(NSString*) path;
{
	NSString	*result = nil;
	DSRDocument	*document = new DSRDocument();
	
	OFCondition status = EC_Normal;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{			
		DcmFileFormat fileformat;
		status  = fileformat.loadFile([path UTF8String]);
		if (status.good())
		{
			status = document->read(*fileformat.getDataset());
			// See DicomFile.m
//			int frameNumber = [[NSString stringWithFormat:@"%s", document->getInstanceNumber()] intValue];
			NSString *accessionNumber = [NSString stringWithFormat:@"%s", document->getAccessionNumber()];
			NSString *studyInstanceUID = [NSString stringWithFormat:@"%s", document->getStudyInstanceUID()];
			NSString *patientName = [NSString stringWithFormat:@"%s", document->getPatientsName()];
			NSString *patientID = [NSString stringWithFormat:@"%s", document->getPatientID()];
			NSString *patientDOB =  [NSString stringWithFormat:@"%s", document->getPatientsBirthDate()];
			NSCalendarDate *DOB = [NSCalendarDate dateWithString: patientDOB calendarFormat:@"%Y%m%d"];
			
			if( accessionNumber == nil)
				accessionNumber = @"";
			
			if( patientID == nil)
				patientID = @"";
			
			if( patientID == nil)
				patientID = @"";
			
			if( patientName == nil)
				patientName = @"No name";
			
			if( studyInstanceUID == nil)
				studyInstanceUID = patientName;
			
			result = [DicomFile patientUID: [NSDictionary dictionaryWithObjectsAndKeys: patientName, @"patientName", accessionNumber, @"accessionNumber", patientID, @"patientID", studyInstanceUID, @"studyInstanceUID", DOB, @"patientBirthDate", nil]];
		}
	}
	
	delete document;
	
	return result;
}


#pragma mark -
#pragma mark basics

- (id)init
{
	self = [super init];

	document = new DSRDocument();
	document->createNewDocument(DSRTypes::DT_ComprehensiveSR);
				
	document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
	_seriesInstanceUID = nil;
	_newSR = YES;
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *) dict path:(NSString *) path forImage: (DicomImage*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX Annotations SR";
		_DICOMSeriesNumber = @"5004";
		
		[_DICOMSRDescription retain];
		[_DICOMSeriesNumber retain];
		
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status = EC_Normal;
		
		// load old SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good()) 
				document->getTree().clear();
		}
		
		// create new Doc 
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good())
		{
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);	
		}
			
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
		
		document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
		document->getTree().getCurrentContentItem().setConceptName( DSRCodedEntryValue("CODE_01", OFFIS_CODING_SCHEME_DESIGNATOR, "Description"));
		document->getTree().getCurrentContentItem().setStringValue( [[NSString stringWithFormat: @"%@", dict] UTF8String]);
		
		image = [im retain];
		
		_dataEncapsulated = [[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription: nil] retain];
	}
	
	return self;
}

- (id)initWithWindowsState:(NSData *) dict path:(NSString *) path forImage: (DicomImage*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX WindowsState SR";
		_DICOMSeriesNumber = @"5006";
		
		[_DICOMSRDescription retain];
		[_DICOMSeriesNumber retain];
		
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status = EC_Normal;
		
		// load old SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good())
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good())
				document->getTree().clear();
		}
		
		// create new Doc
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good())
		{
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);
		}
        
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Windows State"));
		
		document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
		document->getTree().getCurrentContentItem().setConceptName( DSRCodedEntryValue("CODE_01", OFFIS_CODING_SCHEME_DESIGNATOR, "Description"));
		
		image = [im retain];
		
		_dataEncapsulated = [dict retain];
	}
	
	return self;
}

- (id)initWithFileReport:(NSString *) file path:(NSString *) path forImage: (DicomImage*) im contentDate: (NSDate*) d
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX Report SR";
		_DICOMSeriesNumber = @"5003";
		
		if( file)
		{
			_dataEncapsulated = [[NSData dataWithContentsOfFile: file] retain];
			_contentDate = [d retain];
		}
		
		[_DICOMSRDescription retain];
		[_DICOMSeriesNumber retain];
		
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status = EC_Normal;
		
		// load old SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good()) 
				document->getTree().clear();
		}
		
		// create new Doc 
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good())
		{
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);	
		}
			
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", [[NSString stringWithFormat: @"Study Report - %@ File Format", [file pathExtension]] UTF8String]));
		
		image = [im retain];
	}
	
	return self;
}

- (id)initWithROIs:(NSArray *)ROIs path:(NSString *) path forImage: (DicomImage*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX ROI SR";
		_DICOMSeriesNumber = @"5002";
		
		[_DICOMSRDescription retain];
		[_DICOMSeriesNumber retain];
		
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status = EC_Normal;
		
		// load old ROI SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good()) 
				document->getTree().clear();
		}
		
		// create new Doc 
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good())
		{
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);	
		}
		
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "ROI Annotations"));
		
		image = [im retain];
		
		[self addROIs: ROIs];
	}
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path
{
    if( path == nil)
    {
        N2LogStackTrace( @"SRAnnotation initWithContentsOfFile, path == nil", path);
        return nil;
    }
    
	if (self = [super init])
	{
		document = new DSRDocument();
		OFCondition status = EC_Normal;
		
		// load data
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		{
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
				
			const Uint8 *buffer;
			unsigned int length;
			if (fileformat.getDataset()->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good())
			{
				@try
				{
					if( buffer)
						_dataEncapsulated = [[NSData dataWithBytes: buffer length: length] retain];
					else
						_dataEncapsulated = [[NSData data] retain];
				}
				
				@catch( NSException *ne)
				{
					NSLog( @"******* SRAnnotation exception: %@", [ne description]);
				}
			}
			
			_reportURL = [NSString stringWithUTF8String: document->getTree().getCurrentContentItem().getConceptName().getCodeMeaning().c_str()];
			
			NSString *prefix = @"URL:";
			
			if( [_reportURL hasPrefix: prefix])
				_reportURL = [[_reportURL substringFromIndex: [prefix length]] retain];
			else
				_reportURL = nil;
		}
	}
	return self;
}

- (NSDictionary*) annotations
{
	NSDictionary *dict = nil;
	
	@try
	{
        dict = [NSPropertyListSerialization propertyListFromData: _dataEncapsulated  mutabilityOption: NSPropertyListImmutable format: nil errorDescription: nil];
	}
	@catch( NSException *e)
	{
		N2LogExceptionWithStackTrace(e);
	}
	
	return dict;
}

- (NSString*) reportURL
{
	return _reportURL;
}

- (id)initWithURLReport:(NSString *) s path:(NSString *) path forImage: (DicomImage*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX Report SR";
		_DICOMSeriesNumber = @"5003";
		
		[_DICOMSRDescription retain];
		[_DICOMSeriesNumber retain];
		
		_contentDate = [[NSDate date] retain];
		
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status = EC_Normal;
		
		// load old SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath: path])
		{			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good()) 
				document->getTree().clear();
		}
		
		// create new Doc 
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good())
		{
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);	
		}
			
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", [[NSString stringWithFormat: @"URL:%@", s] UTF8String]));
		
		image = [im retain];
	}
	
	return self;
}

- (void)dealloc
{
	delete document;
	[_DICOMSRDescription release];
	[_contentDate release];
	[_DICOMSeriesNumber release];
	[image release];
	[_dataEncapsulated release];
	[_seriesInstanceUID release];
	[super dealloc];
}

- (NSData*) dataEncapsulated
{
	return _dataEncapsulated;
}

#pragma mark -
#pragma mark ROIs

- (void) addROIs: (NSArray *) someROIs;
{
	if( !_dataEncapsulated)
		_dataEncapsulated = [[NSArchiver archivedDataWithRootObject: [NSArray array]] retain];
		
	NSArray *preExistingROIs = [NSUnarchiver unarchiveObjectWithData: _dataEncapsulated];
	
//	for( ROI *aROI in someROIs)
//	{
//		NSData *newROIData = [aROI data];
//		
//		BOOL newROI = YES;
//		for( ROI *roi in preExistingROIs)
//		{
//			if ([newROIData isEqualToData: [roi data]])
//			{
//				newROI = NO;
//				break;
//			}
//		}
//	}
	
	NSArray *newROIs = [preExistingROIs arrayByAddingObjectsFromArray: someROIs];
	
	[_dataEncapsulated release];
	_dataEncapsulated = [[NSArchiver archivedDataWithRootObject: newROIs] retain];
}

- (NSArray *) ROIs
{
	return [NSUnarchiver unarchiveObjectWithData: _dataEncapsulated];
}

#pragma mark -
#pragma mark DICOM write

- (BOOL)writeToFileAtPath:(NSString *)path
{
	id study = [image valueForKeyPath:@"series.study"];
	
	//	Don't want to UIDs if already created
	if( _newSR)
	{
		//add to Study
		document->createNewSeriesInStudy([[study valueForKey:@"studyInstanceUID"] UTF8String]);
	}
	
	NSNumber *v = [NSNumber numberWithInt: [[image valueForKey:@"frameID"] intValue]];
	
	document->setInstanceNumber( [[v stringValue] UTF8String]);
	
	// Add metadata for DICOM
    
    // We want the original patient's name
    if( [[NSFileManager defaultManager] fileExistsAtPath: image.completePath])
    {
        DcmFileFormat fileformat;
        OFCondition status  = fileformat.loadFile( image.completePath.fileSystemRepresentation);
        if (status.good())
        {
            NSArray *encodingArray = nil;
            const char *string = nil;
            if (fileformat.getDataset()->findAndGetString( DCM_SpecificCharacterSet, string, OFFalse).good() && string != NULL)
            {
                document->setSpecificCharacterSet( string);
                encodingArray = [[NSString stringWithCString:string encoding: NSISOLatin1StringEncoding] componentsSeparatedByString:@"\\"];
            }
        
            if( encodingArray == nil)
                encodingArray = [NSArray arrayWithObject: @"ISO_IR 100"];
            
            NSStringEncoding encoding = [NSString encodingForDICOMCharacterSet: [encodingArray objectAtIndex: 0]];
            
            string = nil;
            status = fileformat.getDataset()->findAndGetString( DCM_PatientsName, string, OFFalse);
            if (status.good() && string)
                document->setPatientsName( string);
            
            string = nil;
            status = fileformat.getDataset()->findAndGetString( DCM_ReferringPhysiciansName, string, OFFalse);
            if (status.good() && string)
                document->setReferringPhysiciansName( string);
            
            string = nil;
            status = fileformat.getDataset()->findAndGetString( DCM_StudyDescription, string, OFFalse);
            if (status.good() && string)
                document->setStudyDescription( string);
            
            if( _DICOMSRDescription.length)
            {
                NSMutableData *data = [NSMutableData dataWithData: [_DICOMSRDescription dataUsingEncoding:encoding allowLossyConversion: YES]];
                unsigned char zeroByte = 0;
                [data appendBytes:&zeroByte length:1];
                
                if( [data bytes])
                    document->setSeriesDescription( (char*) [data bytes]);
            }
            
//            if ([[study valueForKey:@"studyName"] length])
//            {
//                NSMutableData *data = [NSMutableData dataWithData: [[study valueForKey:@"studyName"] dataUsingEncoding:encoding allowLossyConversion: YES]];
//                unsigned char zeroByte = 0;
//                [data appendBytes:&zeroByte length:1];
//                
//                if( [data bytes])
//                    document->setStudyDescription( (char*) [data bytes]);
//            }
        }
    }
    else
    {
        document->setSpecificCharacterSet( "ISO_IR 192"); // UTF-8
        
        if( [study valueForKey:@"name"])
            document->setPatientsName([[study valueForKey:@"name"] UTF8String]);
        
        if ([study valueForKey:@"referringPhysician"])
            document->setReferringPhysiciansName([[study valueForKey:@"referringPhysician"] UTF8String]);
        
        if( _DICOMSRDescription)
            document->setSeriesDescription( [_DICOMSRDescription UTF8String]);
        
        if ([study valueForKey:@"studyName"])
            document->setStudyDescription([[study valueForKey:@"studyName"] UTF8String]);
    }
    
	if ([study valueForKey:@"dateOfBirth"])
		document->setPatientsBirthDate([[[study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
		
	if ([study valueForKey:@"patientSex"])
		document->setPatientsSex([[study valueForKey:@"patientSex"] UTF8String]);
		
	NSString *patientID = [study valueForKey:@"patientID"];
	
	if (patientID)
		document->setPatientID([patientID UTF8String]);
	
	if ([study valueForKey:@"id"])
	{
		NSString *studyID = [study valueForKey:@"id"];
		document->setStudyID([studyID UTF8String]);
	}
	
	if ([study valueForKey:@"accessionNumber"])
		document->setAccessionNumber( [[study valueForKey:@"accessionNumber"] UTF8String]);
	
	document->setManufacturer( [@"Horos" UTF8String]);
	
	if( _DICOMSeriesNumber)
		document->setSeriesNumber( [_DICOMSeriesNumber UTF8String]);
	
	if( _contentDate)
	{
		document->setContentDate( [[[DCMCalendarDate dicomDateWithDate: _contentDate] dateString] UTF8String]);
		document->setContentTime( [[[DCMCalendarDate dicomTimeWithDate: _contentDate] timeString] UTF8String]);
	}
	else
	{
		if( [_DICOMSRDescription isEqualToString: @"OsiriX Report SR"] == NO)
		{
			document->setContentDate( [[[DCMCalendarDate date] dateString] UTF8String]);
			document->setContentTime( [[[DCMCalendarDate date] timeString] UTF8String]);
		}
		else if( [_dataEncapsulated length] > 0)
			NSLog( @"********** no date for Report SR ?");
	}
	
	// Image Reference
	OFString refsopClassUID = OFString([[image valueForKeyPath:@"series.seriesSOPClassUID"] UTF8String]);
	OFString refsopInstanceUID = OFString([[image valueForKey:@"sopInstanceUID"] UTF8String]);
	
	document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image, DSRTypes::AM_belowCurrent);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference"));

	DSRImageReferenceValue imageRef( refsopClassUID, refsopInstanceUID);
	
	// add frame reference
	imageRef.getFrameList().putString([[[image valueForKey: @"frameID"] stringValue] UTF8String]);
	document->getTree().getCurrentContentItem().setImageReference( imageRef);
	document->getTree().goUp(); // go up to the root element
	
	OFCondition status = EC_Normal;
	DcmFileFormat *fileformat = new DcmFileFormat();
	DcmDataset *dataset = NULL;
	
	if (fileformat != NULL)
		dataset = fileformat->getDataset();
	
	if (dataset != NULL)
	{
		//This adds the data to the SR
		if( _dataEncapsulated)
		{
			const Uint8 *buffer =  (const Uint8 *) [_dataEncapsulated bytes];
			
			if( buffer)
				status = dataset->putAndInsertUint8Array(DCM_EncapsulatedDocument , buffer, [_dataEncapsulated length] , OFTrue);
		}
		
		document->getCodingSchemeIdentification().addPrivateDcmtkCodingScheme();
		if (document->write(*dataset).good())
		{
			if( _seriesInstanceUID)
				status = dataset->putAndInsertString(DCM_SeriesInstanceUID, [_seriesInstanceUID UTF8String], OFTrue);
				
			OFCondition cond = fileformat->saveFile( path.fileSystemRepresentation, EXS_LittleEndianExplicit);
            if( cond.good())
            {
                
            }
            else
                NSLog( @"failed to write file : %@ : %s", path, cond.text());
		}
	}
	
	if( fileformat)
		delete fileformat;
	
	return YES;
}

- (NSString *)seriesInstanceUID
{
	if (!_seriesInstanceUID)
		_seriesInstanceUID =  [[NSString stringWithUTF8String:document->getSeriesInstanceUID()] retain];
	return _seriesInstanceUID;
}

- (void)setSeriesInstanceUID: (NSString *)seriesInstanceUID
{
	[_seriesInstanceUID release];
	_seriesInstanceUID = [seriesInstanceUID retain];
}

- (NSString *)sopInstanceUID{
	return [NSString stringWithUTF8String:document->getSOPInstanceUID()];
}

- (NSString *)sopClassUID{
	return [NSString stringWithUTF8String:document->getSOPClassUID()];
}

- (NSString *)seriesDescription{

	const char* seriesDescription = document->getSeriesDescription();
	if( seriesDescription) return [NSString stringWithUTF8String:seriesDescription];
	else return @"";
}

- (NSString *)seriesNumber{
	const char* seriesNumber = document->getSeriesNumber();
	if( seriesNumber) return [NSString stringWithUTF8String:seriesNumber];
	else return @"";
}
@end
