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

#import "DCMEncapsulatedPDF.h"
#import "DCM.h"
#import "DCMAbstractSyntaxUID.h"


@implementation  DCMObject (DCMEncapsulatedPDF)

+ (DCMObject*) encapsulatedPDF:(NSData *)pdf
{
    if( pdf == nil)
        return nil;
    
	DCMObject *dcmObject = [DCMObject dcmObject];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMAbstractSyntaxUID pdfStorageClassUID]] forName:@"SOPClassUID"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMAbstractSyntaxUID pdfStorageClassUID]] forName:@"MediaStorageSOPClassUID"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"0001"] forName:@"InstanceNumber"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomDateWithDate:[NSDate date]]] forName:@"ContentDate"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:[DCMCalendarDate dicomTimeWithDate:[NSDate date]]]forName:@"ContentTime"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"NO"] forName:@"BurnedInAnnotation"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"AcquisitionDatetime"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"DocumentTitle"];
    [dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"ISO_IR 192"] forName:@"SpecificCharacterSet"]; // UTF-8
	[dcmObject setCharacterSet:[[[DCMCharacterSet alloc] initWithCode:@"ISO_IR 192"] autorelease]]; // UTF-8
	//Patient Info
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"PatientsName"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"PatientID"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"PatientsBirthDate"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"PatientsSex"];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"PatientsAge"];
	//Referring Physician
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"ReferringPhysiciansName"];
	//other modules
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"AccessionNumber"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"WSD"] forName:@"ConversionType"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"] forName:@"Manufacturer"];
	
	
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"OT"] forName:@"Modality"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"6000"] forName:@"SeriesNumber"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"PDF"] forName:@"SeriesDescription"];
	DCMSequenceAttribute * sequence = [DCMSequenceAttribute sequenceAttributeWithName:@"ConceptNameCodeSequence"];
	[dcmObject setAttribute:sequence];
	[dcmObject setAttributeValues:[NSMutableArray array] forName:@"CodeValue"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"application/pdf"] forName:@"MIMETypeOfEncapsulatedDocument"];
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:pdf] forName:@"EncapsulatedDocument"];

	
	[dcmObject newStudyInstanceUID];
	[dcmObject newSeriesInstanceUID];
	[dcmObject newSOPInstanceUID];
	//NSLog(@"pdf ******** |\n%@", [dcmObject description]);
	return dcmObject;
}

@end
