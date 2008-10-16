/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "SRAnnotation.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "browserController.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

@implementation SRAnnotation

+ (NSString*) getImageRefSOPInstanceUID:(NSString*) path;
{
	NSString	*result = 0L;
	DSRDocument	*document = new DSRDocument();
	
	OFCondition status;
	
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
			}
		}
	}
	
	delete document;
	
	return result;
}

+ (NSString*) getFilenameFromSR:(NSString*) path;
{
	NSString	*result = 0L;
	DSRDocument	*document = new DSRDocument();
	
	OFCondition status;
	
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


#pragma mark -
#pragma mark basics

- (id)init
{
	if (![super init]) return nil;

	document = new DSRDocument();
	//document->createNewDocument(DSRTypes::DT_BasicTextSR);
	document->createNewDocument(DSRTypes::DT_ComprehensiveSR);
				
	document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	//document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("11528-7", "LN", "Radiology Report")); // to do : find a correct concept name
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
	_seriesInstanceUID = nil;
	_newSR = YES;
	return self;
}

- (id)initWithROIs:(NSArray *)ROIs  path:(NSString *)path forImage:(NSManagedObject*) im
{
	if (self = [super init])
	{
		_seriesInstanceUID = nil;
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status;
		
		// load old ROI SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath:path])
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
		if (![[NSFileManager defaultManager] fileExistsAtPath: path] || !status.good()) {
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_BasicTextSR);	
		}
			
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
		
		image = [im retain];
		
		[self addROIs:ROIs];
		
		
		//////
		
//		DSRDocument *doc = new DSRDocument();
//		
//		OFString studyUID_ki;
//		
//		doc->createNewDocument(DSRTypes::DT_BasicTextSR);
////		doc->getStudyInstanceUID(studyUID_ki);
////		doc->setStudyDescription("OFFIS Structured Reporting Templates");
////		doc->setSeriesDescription("IHE Year 2 - Key Image Note");
////		doc->setSpecificCharacterSetType(DSRTypes::CS_Latin1);
////
////		doc->setPatientsName("Last Name^First Name");
////		doc->setPatientsSex("O");
////		doc->setManufacturer("Kuratorium OFFIS e.V.");
////		doc->setReferringPhysiciansName("Last Name^First Name");
//
//		doc->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.01", OFFIS_CODING_SCHEME_DESIGNATOR, "Document Title"));
//
//		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_UIDRef, DSRTypes::AM_belowCurrent);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.02", OFFIS_CODING_SCHEME_DESIGNATOR, "Observation Context Mode"));
////		doc->getTree().getCurrentContentItem().setCodeValue(DSRCodedEntryValue("IHE.03", OFFIS_CODING_SCHEME_DESIGNATOR, "DIRECT"));
//		
////		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_PName);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.04", OFFIS_CODING_SCHEME_DESIGNATOR, "Recording Observer's Name"));
////		doc->getTree().getCurrentContentItem().setStringValue("Enter text");
////		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Text);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.05", OFFIS_CODING_SCHEME_DESIGNATOR, "Recording Observer's Organization Name"));
////		doc->getTree().getCurrentContentItem().setStringValue("Enter text");
////		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Code);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.06", OFFIS_CODING_SCHEME_DESIGNATOR, "Observation Context Mode"));
////		doc->getTree().getCurrentContentItem().setCodeValue(DSRCodedEntryValue("IHE.07", OFFIS_CODING_SCHEME_DESIGNATOR, "PATIENT"));
////
////		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.11", OFFIS_CODING_SCHEME_DESIGNATOR, "Key Image Description"));
////		doc->getTree().getCurrentContentItem().setStringValue("Enter text");
//
//		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image);
////		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.10", OFFIS_CODING_SCHEME_DESIGNATOR, "Image Reference"));
//		doc->getTree().getCurrentContentItem().setImageReference(DSRImageReferenceValue("989898", "989898"));
//
//		DcmFileFormat *fileformat = new DcmFileFormat();
//		DcmDataset *dataset = NULL;
//		if (fileformat != NULL)
//			dataset = fileformat->getDataset();
//		if (dataset != NULL)
//		{
//			doc->getCodingSchemeIdentification().addPrivateDcmtkCodingScheme();
//			if (doc->write(*dataset).good())
//			{
//				OFString filename = "report_test";
//				filename += ".dcm";
//				fileformat->saveFile(filename.c_str(), EXS_LittleEndianExplicit);
//			}
//		}
//		delete fileformat
	}
	return self;
}

- (id) initWithContentsOfFile:(NSString *)path{
	if (self = [super init]) {
		document = new DSRDocument();
		OFCondition status;
		// load old ROI SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
				
			const Uint8 *buffer;
			unsigned int length;
			NSData *archiveData;
			if (fileformat.getDataset()->findAndGetUint8Array(DCM_EncapsulatedDocument, buffer, &length, OFFalse).good())	//DCM_OsirixROI
			{
				NSLog(@"Unarchive from SR - SRAnnotation");
				@try
				{
					archiveData = [NSData dataWithBytes:buffer length:(unsigned)length];
					_rois = [[NSUnarchiver unarchiveObjectWithData:archiveData] retain];
				}
				
				@catch( NSException *ne)
				{
					NSLog(@"SRAnnotation exception: %@", [ne description]);
				}
			}
				
		}
	}
	return self;
}

- (void)dealloc
{
	delete document;
	[image release];
	[_rois release];
	[_seriesInstanceUID release];
	[super dealloc];
}

#pragma mark -
#pragma mark ROIs

- (void)addROIs:(NSArray *)someROIs;
{
	NSEnumerator *roisEnumerator = [someROIs objectEnumerator];
	ROI *aROI;
	
	if (!_rois)
		_rois = [[NSArray alloc] init];
	
	while (aROI = [roisEnumerator nextObject])
	{
		NSEnumerator *enumerator = [_rois objectEnumerator];
		BOOL newROI = YES;
		ROI *roi;
		NSData *newROIData = [aROI data];
		
		while ((roi = [enumerator nextObject]) && newROI)
		{
			if ([newROIData isEqualToData:[roi data]])
				newROI = NO;
		}
		
		if (newROI)
			[self addROI:aROI];
	}
	
	NSArray *newROIs = [_rois arrayByAddingObjectsFromArray:someROIs];
	[_rois release];
	_rois = [newROIs retain];
}

- (void)addROI:(ROI *)aROI;
{
//	NSLog(@"+++ add a ROI : %@", [aROI name]);
//	// add the region to the SR
//	document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_SCoord, DSRTypes::AM_belowCurrent);
//	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("111030", "DCM", "Image Region"));
//	
//	// set the type of the region
//	DSRTypes::E_GraphicType graphicType;
//	
//	switch([aROI type])
//	{
//		case tMesure:
//		case tArrow:
//		case tAngle:
//		case tCPolygon:
//		case tOPolygon:
//		case tPlain:
//		case tPencil:
//			graphicType = DSRTypes::GT_Multipoint;
//		break;
//		
//		case t2DPoint:
//		case tText:
//			graphicType = DSRTypes::GT_Point;
//		break;
//		
//		case tOval:
//			graphicType = DSRTypes::GT_Ellipse;
//		break;
//		
//		case tROI: // (rectangle)
//			graphicType = DSRTypes::GT_Polyline;
//		break;
//	}
//	
//	// set coordinates of the points
//	DSRSpatialCoordinatesValue *coordinates = new DSRSpatialCoordinatesValue(graphicType);
//
//	DSRGraphicDataList *dsrPointsList = &coordinates->getGraphicDataList();
//
//	NSMutableArray *roiPointsList = [aROI points];
//	NSEnumerator *roiPointsListEnumerator = [roiPointsList objectEnumerator];
//	id aPoint;
//
//	while (aPoint = [roiPointsListEnumerator nextObject])
//	{
//		NSPoint aNSPoint = [aPoint point];
//		dsrPointsList->addItem(aNSPoint.x,aNSPoint.y);
//	}
//	
////	dsrPointsList.print(cout, 0, '/', '\n');
////	coordinates->print(cout, 0);
//	
//	document->getTree().getCurrentContentItem().setSpatialCoordinates(*coordinates);
//
//	document->getTree().goUp(); // go up to the root element
	
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

- (NSArray *)ROIs{
	return _rois;
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
			
		//Series Description
		document->setSeriesDescription("OsiriX ROI SR");
		
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
		
		if ([study valueForKey:@"id"]) {
			NSString *studyID = [study valueForKey:@"id"];
			document->setStudyID([studyID UTF8String]);
		}
		
		if ([study valueForKey:@"accessionNumber"])
			document->setAccessionNumber([[study valueForKey:@"accessionNumber"] UTF8String]);
		
		//Series Number
		document->setSeriesNumber("5002");
		document->setManufacturer("OsiriX");
	}
	
	OFCondition status;
	DcmFileFormat *fileformat = new DcmFileFormat();
	DcmDataset *dataset = NULL;
	if (fileformat != NULL)
		dataset = fileformat->getDataset();
	
	if (dataset != NULL)
	{
		//This adds the archived ROI Array  to the SR		
		ROI *roi = [_rois objectAtIndex:0];
		NSData *data = nil;
		data = [ NSArchiver archivedDataWithRootObject:_rois];
		const Uint8 *buffer =  (const Uint8 *)[data bytes];
//		DcmTag tag(0x0071, 0x0011, DcmVR("OB"));			//By using DCM_EncapsulatedDocument, instead of our 0x0071, 0x0011 field, we can support implicit transfers...
		status = dataset->putAndInsertUint8Array(DCM_EncapsulatedDocument , buffer, [data length] , OFTrue);
		
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

- (NSString *)seriesInstanceUID{
	if (!_seriesInstanceUID)
		_seriesInstanceUID =  [[NSString stringWithUTF8String:document->getSeriesInstanceUID()] retain];
	return _seriesInstanceUID;
}

- (void)setSeriesInstanceUID: (NSString *)seriesInstanceUID{
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

- (int)frameIndex{
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
