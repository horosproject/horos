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

#import "AppController.h"
#import "SRAnnotation.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "browserController.h"
#import "DicomFile.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

@implementation SRAnnotation

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
			
			
			DSRCodedEntryValue codedEntryValue = DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference");
			if (document->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0 )
			{
				DSRImageReferenceValue imageRef = document->getTree().getCurrentContentItem().getImageReference();
				result = [NSString stringWithFormat:@"%s", imageRef.getSOPInstanceUID().c_str()];
			}
		}
	}
	
	delete document;
	
	return result;
}

+ (NSString*) getROIFilenameFromSR:(NSString*) path;
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
				result = [NSString stringWithFormat:@"%s %d-%d.dcm", imageRef.getSOPInstanceUID().c_str(), instanceNumber, 0];
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
			int instanceNumber = [[NSString stringWithFormat:@"%s", document->getInstanceNumber()] intValue];
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
	if (![super init]) return nil;

	document = new DSRDocument();
	document->createNewDocument(DSRTypes::DT_ComprehensiveSR);
				
	document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
	_seriesInstanceUID = nil;
	_newSR = YES;
	
	return self;
}

- (id)initWithDictionary:(NSDictionary *) dict path:(NSString *) path forImage: (NSManagedObject*) im
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


- (id)initWithFileReport:(NSString *) file path:(NSString *) path forImage: (NSManagedObject*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX Report SR";
		_DICOMSeriesNumber = @"5003";
		_dataEncapsulated = [[NSData dataWithContentsOfFile: file] retain];
		
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

- (id)initWithROIs:(NSArray *)ROIs path:(NSString *) path forImage: (NSManagedObject*) im
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
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	return dict;
}

- (NSString*) reportURL
{
	return _reportURL;
}

- (id)initWithURLReport:(NSString *) s path:(NSString *) path forImage: (NSManagedObject*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		_DICOMSRDescription =  @"OsiriX Report SR";
		_DICOMSeriesNumber = @"5003";
		
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
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", [[NSString stringWithFormat: @"URL:%@", s] UTF8String]));
		
		image = [im retain];
	}
	
	return self;
}

- (void)dealloc
{
	delete document;
	[_DICOMSRDescription release];
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
	
	for( ROI *aROI in someROIs)
	{
		NSData *newROIData = [aROI data];
		
		BOOL newROI = YES;
		for( ROI *roi in preExistingROIs)
		{
			if ([newROIData isEqualToData: [roi data]])
			{
				newROI = NO;
				break;
			}
		}
		
		if( newROI)
			[self addROI: aROI];
	}
	
	NSArray *newROIs = [preExistingROIs arrayByAddingObjectsFromArray: someROIs];
	
	[_dataEncapsulated release];
	_dataEncapsulated = [[NSArchiver archivedDataWithRootObject: newROIs] retain];
}

- (void)addROI: (ROI *)aROI;
{
	// image reference
	OFString refsopClassUID = OFString([[image valueForKeyPath:@"series.seriesSOPClassUID"] UTF8String]);
	OFString refsopInstanceUID = OFString([[image valueForKey:@"sopInstanceUID"] UTF8String]);
	
	document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image, DSRTypes::AM_belowCurrent);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.10", "99HUG", "Image Reference"));

	DSRImageReferenceValue imageRef( refsopClassUID, refsopInstanceUID);
	
	// add frame reference
	NSNumber *frameIndex = [NSNumber numberWithInt: [[aROI pix] frameNo]];
	imageRef.getFrameList().putString([[frameIndex stringValue] UTF8String]);
	
	document->getTree().getCurrentContentItem().setImageReference( imageRef);
	document->getTree().goUp(); // go up to the root element
}

- (NSArray *) ROIs
{
	return [NSUnarchiver unarchiveObjectWithData: _dataEncapsulated];
}

#pragma mark -
#pragma mark DICOM write

- (BOOL)writeToFileAtPath:(NSString *)path
{
	//	Don't want to UIDs if already created
	if (_newSR)
	{
		id study = [image valueForKeyPath:@"series.study"];
		
		//add to Study
		document->createNewSeriesInStudy([[study valueForKey:@"studyInstanceUID"] UTF8String]);
		
		document->setInstanceNumber([[[image valueForKey:@"instanceNumber"] stringValue] UTF8String]);
		
		// Add metadata for DICOM
		//Study Description
		if ([study valueForKey:@"studyName"])
			document->setStudyDescription([[study valueForKey:@"studyName"] UTF8String]);
		
		document->setSpecificCharacterSet( "ISO_IR 192"); // UTF-8
		
		if ([study valueForKey:@"name"] )
			document->setPatientsName([[study valueForKey:@"name"] UTF8String]);
			
		if ([study valueForKey:@"dateOfBirth"])
			document->setPatientsBirthDate([[[study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
			
		if ([study valueForKey:@"patientSex"])
			document->setPatientsSex([[study valueForKey:@"patientSex"] UTF8String]);
			
		NSString *patientID = [study valueForKey:@"patientID"];
		
		if (patientID)
			document->setPatientID([patientID UTF8String]);
		
		if ([study valueForKey:@"referringPhysician"])
			document->setReferringPhysiciansName([[study valueForKey:@"referringPhysician"] UTF8String]);
		
		if ([study valueForKey:@"id"])
		{
			NSString *studyID = [study valueForKey:@"id"];
			document->setStudyID([studyID UTF8String]);
		}
		
		if ([study valueForKey:@"accessionNumber"])
			document->setAccessionNumber( [[study valueForKey:@"accessionNumber"] UTF8String]);
		
		if( _DICOMSRDescription)
			document->setSeriesDescription( [_DICOMSRDescription UTF8String]);
		
		document->setManufacturer( [@"OsiriX" UTF8String]);
		
		if( _DICOMSeriesNumber)
			document->setSeriesNumber( [_DICOMSeriesNumber UTF8String]);
	}
	
	OFCondition status = EC_Normal;
	DcmFileFormat *fileformat = new DcmFileFormat();
	DcmDataset *dataset = NULL;
	
	if (fileformat != NULL)
		dataset = fileformat->getDataset();
	
	if (dataset != NULL)
	{
		//This adds the data to the SR
		const Uint8 *buffer =  (const Uint8 *) [_dataEncapsulated bytes];
		status = dataset->putAndInsertUint8Array(DCM_EncapsulatedDocument , buffer, [_dataEncapsulated length] , OFTrue);
		
		document->getCodingSchemeIdentification().addPrivateDcmtkCodingScheme();
		if (document->write(*dataset).good())
		{
			if( _seriesInstanceUID)
				status = dataset->putAndInsertString(DCM_SeriesInstanceUID, [_seriesInstanceUID UTF8String], OFTrue);
				
			fileformat->saveFile( [path UTF8String], EXS_LittleEndianExplicit);
		}
	}
	
	if( fileformat)
		delete fileformat;
	
	return YES;
}

- (void)saveAsHTML;
{
	#ifdef OSIRIX_VIEWER
	NSString *dbPath = [[BrowserController currentBrowser] documentsDirectory];
	NSString *path = [[dbPath stringByAppendingPathComponent:@"tmp"] stringByAppendingPathExtension:@"html"];
	
	size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;		
	ofstream stream([path UTF8String]);
	document->renderHTML(stream, renderFlags, NULL);
	#endif
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

- (int)frameIndex
{
	DSRDocumentTreeNode *node = NULL; 
	//_doc->getTree().print(cout, 0);
	document->getTree().gotoRoot ();
		/* iterate over all nodes */ 
	do { 
		node = OFstatic_cast(DSRDocumentTreeNode *, document->getTree().getNode());			
		if (node != NULL && node->getValueType() == DSRTypes::VT_Image) {
			//image node get SOPCInstance
			DSRImageReferenceValue *imagePtr = document->getTree().getCurrentContentItem().getImageReferencePtr();
			DSRImageFrameList frameList = imagePtr->getFrameList ();
			NSLog(@"got image node");
			int i;
			for (i = 0; i < 1000; i++) {
				if (imagePtr->appliesToFrame(i) == OFTrue)
					return i;
			}			
		}
	} while (document->getTree().iterate()); 
	return 0;
}


@end
