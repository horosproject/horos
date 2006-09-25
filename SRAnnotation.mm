//
//  SRAnnotation.mm
//  OsiriX
//
//  Created by joris on 06/09/06.
//  Copyright 2006 OsiriX Team. All rights reserved.
//

#import "SRAnnotation.h"
#import "DCMVIew.h"
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
	
	return self;
}

- (void)dealloc
{
	delete document;
	[super dealloc];
}

#pragma mark -
#pragma mark ROIs

- (void)addROIs:(NSArray *)someROIs;
{
	NSEnumerator *roisEnumerator = [someROIs objectEnumerator];
	ROI *aROI;
 
	while (aROI = [roisEnumerator nextObject])
	{
		[self addROI:aROI];
	}
}

- (void)addROI:(ROI *)aROI;
{
	NSLog(@"+++ add a ROI : %@", [aROI name]);

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
	dcmObject = [DCMObject objectWithContentsOfFile:[[aROI pix] srcFile] decodingPixelData:NO];
	OFString sopClassUID = OFString([[dcmObject attributeValueWithName:@"SOPClassUID"] UTF8String]);
	OFString sopInstanceUID = OFString([[[[aROI pix] imageObj] valueForKey:@"sopInstanceUID"] UTF8String]);

	document->getTree().addContentItem(DSRTypes::RT_selectedFrom, DSRTypes::VT_Image);
	document->getTree().getCurrentContentItem().setImageReference(DSRImageReferenceValue(sopClassUID, sopInstanceUID));
	document->getTree().goUp(); // go up to the SCOORD element
	
	document->getTree().goUp(); // go up to the root element
}

#pragma mark -
#pragma mark DICOM write
			
- (BOOL)save;
{
	DcmFileFormat fileformat;
	OFCondition status = document->write(*fileformat.getDataset());

	//NSString *dbPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"INCOMING"];
	NSString *dbPath = [[BrowserController currentBrowser] documentsDirectory];
	// to do : find a correct output file name
	NSString *path = [[dbPath stringByAppendingPathComponent:@"tmp"] stringByAppendingPathExtension:@"dcm"];

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

@end
