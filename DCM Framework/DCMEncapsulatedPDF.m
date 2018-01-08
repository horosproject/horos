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
	[dcmObject setAttributeValues:[NSMutableArray arrayWithObject:@"Horos"] forName:@"Manufacturer"];
	
	
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
