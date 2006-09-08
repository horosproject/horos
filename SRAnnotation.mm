//
//  SRAnnotation.mm
//  OsiriX
//
//  Created by joris on 06/09/06.
//  Copyright 2006 OsiriX Team. All rights reserved.
//

#import "SRAnnotation.h"
#import "ROI.h"
#import "DCMVIew.h"

#include "osconfig.h"   /* make sure OS specific configuration is included first */
#include "dsrtypes.h"

@implementation SRAnnotation

#pragma mark -
#pragma mark basics

- (id)init
{
	if (![super init]) return nil;

	document = new DSRDocument();
	document->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	document->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("111030", "DCM", "Image Region")); // to do : find a correct concept name
	
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
		document->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_SCoord);
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

		DSRGraphicDataList dsrPointsList = coordinates->getGraphicDataList();

		NSMutableArray *roiPointsList = [aROI points];
		NSEnumerator *roiPointsListEnumerator = [roiPointsList objectEnumerator];
		id aPoint;

		while (aPoint = [roiPointsListEnumerator nextObject])
		{
			NSPoint aNSPoint = [aPoint point];
			dsrPointsList.addItem(aNSPoint.x,aNSPoint.y);
		}

		// to do : add a reference to the image

		// add the region to the SR
		document->getTree().getCurrentContentItem().setSpatialCoordinates(*coordinates);
	}		
}

@end
