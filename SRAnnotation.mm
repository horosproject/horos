//
//  SRAnnotation.mm
//  OsiriX
//
//  Created by joris on 06/09/06.
//  Copyright 2006 OsiriX Team. All rights reserved.
//

#import "SRAnnotation.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "browserController.h"
#import "DCMObject.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

@implementation SRAnnotation

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

- (id)initWithROIs:(NSArray *)ROIs  path:(NSString *)path{
	if (self = [super init]) {
		_seriesInstanceUID = nil;
		document = new DSRDocument();
		_newSR = NO;
		OFCondition status;
		// load old ROI SR and replace as needed
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {			
			DcmFileFormat fileformat;
			status  = fileformat.loadFile([path UTF8String]);
			if (status.good()) 				
				status = document->read(*fileformat.getDataset());
			
			//clear old content	Don't want to UIDs if already created
			if (status.good()) 
				document->getTree().clear();

				
		}
		// create new Doc 
		if (![[NSFileManager defaultManager] fileExistsAtPath:path] || !status.good()) {
			_newSR = YES;
			document->createNewDocument(DSRTypes::DT_ComprehensiveSR);	
		}
			
		document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("1", "99HUG", "Annotations"));
		
		[self addROIs:ROIs];
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
			unsigned long length;
			NSData *archiveData;
			if (fileformat.getDataset()->findAndGetUint8Array(DCM_OsirixROI, buffer, &length, OFFalse).good())
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
	//[rois release];
	if (!_rois)
		_rois = [[NSArray alloc] init];
	NSArray *newROIs = [_rois arrayByAddingObjectsFromArray:someROIs];
	[_rois release];
	_rois = [newROIs retain];
	while (aROI = [roisEnumerator nextObject])
	{
		NSEnumerator *enumerator = [_rois objectEnumerator];
		BOOL newROI = YES;
		ROI *roi;
		NSData *newROIData = [aROI data];
		while ((roi = [enumerator nextObject]) && newROI){
			if ([newROIData isEqualToData:[roi data]]) {
				newROI = NO;
			}
		}
		if (newROI) {
			[self addROI:aROI];
			image = [[aROI pix] imageObj];
		}
	}		
}

- (void)mergeWithSR:(SRAnnotation *)sr{
	NSArray *rois = [sr ROIs];
	[self addROIs:rois];
}

- (void)addROI:(ROI *)aROI;
{
//	NSLog(@"+++ add a ROI : %@", [aROI name]);

	// add the region to the SR
	document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_SCoord, DSRTypes::AM_belowCurrent);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("111030", "DCM", "Image Region"));
	
	// set the type of the region
	DSRTypes::E_GraphicType graphicType;
	
	switch([aROI type])
	{
		case tMesure:
		case tArrow:
		case tAngle:
		case tCPolygon:
		case tOPolygon:
		case tPlain:
		case tPencil:
			graphicType = DSRTypes::GT_Multipoint;
		break;
		
		case t2DPoint:
		case tText:
			graphicType = DSRTypes::GT_Point;
		break;
		
		case tOval:
			graphicType = DSRTypes::GT_Ellipse;
		break;
		
		case tROI: // (rectangle)
			graphicType = DSRTypes::GT_Polyline;
		break;
	}

	// set coordinates of the points
	DSRSpatialCoordinatesValue *coordinates = new DSRSpatialCoordinatesValue(graphicType);

	DSRGraphicDataList *dsrPointsList = &coordinates->getGraphicDataList();

	NSMutableArray *roiPointsList = [aROI points];
	NSEnumerator *roiPointsListEnumerator = [roiPointsList objectEnumerator];
	id aPoint;

	while (aPoint = [roiPointsListEnumerator nextObject])
	{
		NSPoint aNSPoint = [aPoint point];
		dsrPointsList->addItem(aNSPoint.x,aNSPoint.y);
		//NSLog(@"add a point : %f, %f", aNSPoint.x,aNSPoint.y);
	}
	
//	dsrPointsList.print(cout, 0, '/', '\n');
//	coordinates->print(cout, 0);
	
	document->getTree().getCurrentContentItem().setSpatialCoordinates(*coordinates);
	
	// image reference
	DCMObject *dcmObject;
	OFString refsopClassUID;
	OFString refsopInstanceUID;
	dcmObject = [DCMObject objectWithContentsOfFile:[[aROI pix] srcFile] decodingPixelData:NO];
	if (![aROI referencedSOPClassUID]) {
		NSString *uid = [dcmObject attributeValueWithName:@"SOPClassUID"];
		refsopClassUID = OFString([uid UTF8String]);
		[aROI setReferencedSOPClassUID:uid];
	}
		else refsopClassUID = OFString([[aROI referencedSOPClassUID]  UTF8String]);
		
	if (![aROI referencedSOPInstanceUID]) {
		NSString *uid = [[[aROI pix] imageObj] valueForKey:@"sopInstanceUID"];
		refsopInstanceUID = OFString([uid UTF8String]);
		[aROI setReferencedSOPInstanceUID:uid];
	}
	else
		refsopInstanceUID = OFString([[aROI referencedSOPInstanceUID]  UTF8String]);
	
	NSNumber *frameIndex = [[[aROI pix] imageObj] valueForKey:@"frameNo"];
	document->getTree().addContentItem(DSRTypes::RT_selectedFrom, DSRTypes::VT_Image);
	DSRImageReferenceValue imageRef(refsopClassUID, refsopInstanceUID);
	// add frame reference
	imageRef.getFrameList().putString([[frameIndex stringValue] UTF8String]);
	document->getTree().getCurrentContentItem().setImageReference(imageRef);
	document->getTree().goUp(); // go up to the SCOORD element
	
	document->getTree().goUp(); // go up to the root element
}

- (NSArray *)ROIs{
	return _rois;
}

#pragma mark -
#pragma mark DICOM write
			
- (BOOL)save{
	//NSString *dbPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"INCOMING"];
	NSString *dbPath = [[BrowserController currentBrowser] documentsDirectory];
	// to do : find a correct output file name
	NSString *path = [[dbPath stringByAppendingPathComponent:@"tmp"] stringByAppendingPathExtension:@"dcm"];
	return [self writeToFileAtPath:path];
}


- (BOOL)writeToFileAtPath:(NSString *)path
{	
		//	Don't want to UIDs if already created
		if (_newSR) {
			id study = [image valueForKeyPath:@"series.study"];
			//add to Study
			document->createNewSeriesInStudy([[study valueForKey:@"studyInstanceUID"] UTF8String]);
			// Add metadata for DICOM
				//Study Description
			if ([study valueForKey:@"studyName"])
				document->setStudyDescription([[study valueForKey:@"studyName"] UTF8String]);
			//Series Description
			document->setSeriesDescription("OsiriX ROI SR");
			//Patient Name
			if ([study valueForKey:@"name"] )
				document->setPatientsName([[study valueForKey:@"name"] UTF8String]);
			// Patient DOB
			if ([study valueForKey:@"dateOfBirth"])
				document->setPatientsBirthDate([[[study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
			//Patient Sex
			if ([study valueForKey:@"patientSex"])
				document->setPatientsSex([[study valueForKey:@"patientSex"] UTF8String]);
			//Patient ID
			NSString *patientID = [study valueForKey:@"patientID"];
			if (patientID)
				document->setPatientID([patientID UTF8String]);
			//Referring Physician
			if ([study valueForKey:@"referringPhysician"])
				document->setReferringPhysiciansName([[study valueForKey:@"referringPhysician"] UTF8String]);
			//StudyID	
			if ([study valueForKey:@"id"]) {
				NSString *studyID = [study valueForKey:@"id"];
				document->setStudyID([studyID UTF8String]);
			}
			//Accession Number
			if ([study valueForKey:@"accessionNumber"])
				document->setAccessionNumber([[study valueForKey:@"accessionNumber"] UTF8String]);
			//Series Number
			document->setSeriesNumber("5002");
			
			document->setManufacturer("OsiriX");
		}
	
		DcmFileFormat fileformat;
		OFCondition status;
		status = document->write(*fileformat.getDataset());
		
		//This adds the archived ROI Array  to the SR		
			ROI *roi = [_rois objectAtIndex:0];
			NSData *data = nil;
			data = [ NSArchiver archivedDataWithRootObject:_rois];
			const Uint8 *buffer =  (const Uint8 *)[data bytes];
			DcmDataset *dataset = fileformat.getDataset();
			DcmTag tag(0x0071, 0x0011, DcmVR("OB"));
			status = dataset->putAndInsertUint8Array(tag , buffer, [data length] , OFTrue);
			
			//use seriesInstanceUID if we have one
			if (_seriesInstanceUID)
				status = dataset->putAndInsertString(DCM_SeriesInstanceUID, [_seriesInstanceUID UTF8String], OFTrue);

		//NSLog(@"error code: %s", status.text());
		//status = document->write(*fileformat.getDataset());



	if (status.good())
		status = fileformat.saveFile([path UTF8String], EXS_LittleEndianExplicit);
	
	if (status.good())
	{
		NSLog(@"Report saved: %@", path);
		return YES;
	}
	else
	{
		NSLog(@"Report not saved: %@", path);
		return NO;
	}
}

- (void)saveAsHTML;
{
	NSString *dbPath = [[BrowserController currentBrowser] documentsDirectory];
	NSString *path = [[dbPath stringByAppendingPathComponent:@"tmp"] stringByAppendingPathExtension:@"html"];
	
	size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;		
	ofstream stream([path UTF8String]);
	document->renderHTML(stream, renderFlags, NULL);
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
