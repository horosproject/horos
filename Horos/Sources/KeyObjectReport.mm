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

#import "KeyObjectReport.h"
#import "DicomStudy.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"
#include "dsrtypes.h"

@implementation KeyObjectReport

- (id) initWithStudy:(id)study title:(int)title description:(NSString *)keyDescription seriesUID:(NSString *)seriesUID
{
	if (self = [super init]){
		_study = [study retain];
		_keyDescription = [keyDescription retain];
		_title = title;
		_seriesUID = [seriesUID retain];
		[self createKO];
	}
	return self;
}

- (void)createKO{
	//NSLog(@"create KO");
	_doc = new DSRDocument(DSRTypes::DT_KeyObjectDoc);
	_doc->setSpecificCharacterSet("ISO_IR 192"); //UTF 8 string encoding
	_doc->createNewSeriesInStudy([[_study valueForKey:@"studyInstanceUID"] UTF8String]);

	//Study Description
	if ([_study valueForKey:@"studyName"])
		_doc->setStudyDescription([[_study valueForKey:@"studyName"] UTF8String]);
	//Series Description
	_doc->setSeriesDescription("OsiriX Key Object Report");
	//Patient Name
	if ([_study valueForKey:@"name"] )
		_doc->setPatientsName([[_study valueForKey:@"name"] UTF8String]);
	// Patient DOB
	if ([_study valueForKey:@"dateOfBirth"])
		_doc->setPatientsBirthDate([[[_study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
	//Patient Sex
	if ([_study valueForKey:@"patientSex"])
		_doc->setPatientsSex([[_study valueForKey:@"patientSex"] UTF8String]);
	//Patient ID
	NSString *patientID = [_study valueForKey:@"patientID"];
	if (patientID)
		_doc->setPatientID([patientID UTF8String]);
	//Referring Physician
	if ([_study valueForKey:@"referringPhysician"])
		_doc->setReferringPhysiciansName([[_study valueForKey:@"referringPhysician"] UTF8String]);
	//StudyID	
	if ([_study valueForKey:@"id"]) {
		NSString *studyID = [_study valueForKey:@"id"];
		_doc->setStudyID([studyID UTF8String]);
	}
	//Accession Number
	if ([_study valueForKey:@"accessionNumber"])
		_doc->setAccessionNumber([[_study valueForKey:@"accessionNumber"] UTF8String]);
	//Series Number
	_doc->setSeriesNumber("5002");
	
	_doc->setManufacturer("OsiriX");
	
	// get KeyImages
	_keyImages = [[(DicomStudy *)_study keyImages] retain];
		
	const char *codeMeaning;
	const char *codeValue;
	switch (_title){
		case 113000:	codeMeaning = "Of Interest";
						codeValue = "113000";
			break;
		case 113001:	codeMeaning = "Rejected for Quality Reasons";
						codeValue = "113001";
			break;
		case 113002:	codeMeaning = "For Referring Provider";
						codeValue = "113002";
			break;
		case 113003:	codeMeaning = "For Surgery";
						codeValue = "113003";
			break;
		case 113004:	codeMeaning = "For Teaching";
						codeValue = "113004";
			break;
		case 113005:	codeMeaning = "For Conference";
						codeValue = "113005";
			break;
		case 113006:	codeMeaning = "For Therapy";
						codeValue = "113006";
			break;
		case 113007:	codeMeaning = "For Patient";
						codeValue = "113007";
			break;
		case 113008:	codeMeaning = "For Peer Review";
						codeValue = "113008";
			break;
		case 113009:	codeMeaning = "For Research";
						codeValue = "113009";
			break;
		case 113010:	codeMeaning = "Quality Issue";
						codeValue = "113010";
			break;
		case 113013:	codeMeaning = "Best In Set";
						codeValue = "113013";
			break;
		case 113018:	codeMeaning = "For Printing";
						codeValue = "113018";
			break;
		case 113020:	codeMeaning = "For Report Attachment";
						codeValue = "113020";
			break;
	}
	

	_doc->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);

	_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue(codeValue, "DCM", codeMeaning));

	// Description
	if (_keyDescription) {
		_doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
		_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("113012", "DCM", "Key Object Description"));
		_doc->getTree().getCurrentContentItem().setStringValue([_keyDescription UTF8String]);
		_doc->getTree().goUp();
	}
	
	if ([_keyImages count] > 0){
		//NSLog(@"Add key Images");
		NSEnumerator *enumerator = [_keyImages objectEnumerator];
		id image;
		BOOL first = YES;
		while (image = [enumerator nextObject]){
			//NSLog(@"key image %@", [image description]);
			OFString studyUID = OFString([[_study valueForKey:@"studyInstanceUID"] UTF8String]);
			OFString seriesUID = OFString([[image valueForKeyPath:@"series.seriesDICOMUID"]  UTF8String]);
			OFString instanceUID = OFString([[image valueForKey:@"sopInstanceUID"] UTF8String]);
			DcmFileFormat fileformat;
			OFCondition status = fileformat.loadFile([[image valueForKey:@"completePath"] UTF8String]);
			OFString sopClassUID;
			if (status.good()){
				fileformat.getDataset()->findAndGetOFString(DCM_SOPClassUID, sopClassUID).good();
			}
			
			if (first) {
				_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image, DSRTypes::AM_belowCurrent);
				first = NO;
			}
			else{				
				_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image);
			}
			
			_doc->getTree().getCurrentContentItem().setImageReference(DSRImageReferenceValue(sopClassUID, instanceUID));
			_doc->getCurrentRequestedProcedureEvidence().addItem(studyUID, seriesUID, sopClassUID, instanceUID);
		}
		//go back up in tree
		_doc->getTree().goUp();
		
	}

	//NSLog(@"end createKO");	
	//_doc->print(cout, nil);
}

 
 - (void)checkCharacterSet
{ // check extended character set
	const char *defaultCharset = "latin-1";
	const char *charset = _doc->getSpecificCharacterSet();
	if ((charset == NULL || strlen(charset) == 0) && _doc->containsExtendedCharacters())
	{
	  // we have an unspecified extended character set
		OFString charset(defaultCharset);
		if (charset == "latin-1") _doc->setSpecificCharacterSetType(DSRTypes::CS_Latin1);
		else if (charset == "latin-2") _doc->setSpecificCharacterSetType(DSRTypes::CS_Latin2);
		else if (charset == "latin-3") _doc->setSpecificCharacterSetType(DSRTypes::CS_Latin3);
		else if (charset == "latin-4") _doc->setSpecificCharacterSetType(DSRTypes::CS_Latin4);
		else if (charset == "latin-5") _doc->setSpecificCharacterSetType(DSRTypes::CS_Latin5);
		else if (charset == "cyrillic") _doc->setSpecificCharacterSetType(DSRTypes::CS_Cyrillic);
		else if (charset == "arabic") _doc->setSpecificCharacterSetType(DSRTypes::CS_Arabic);
		else if (charset == "greek") _doc->setSpecificCharacterSetType(DSRTypes::CS_Greek);
		else if (charset == "hebrew") _doc->setSpecificCharacterSetType(DSRTypes::CS_Hebrew);

	}
}
 
 - (void)dealloc{
	
	delete _doc;
	[_study release];
	[_keyImages release];
	[_keyDescription release];
	[_seriesUID release];
	[super dealloc];
	
}
	
- (BOOL)writeFileAtPath:(NSString *)path{
	//NSLog(@"Write file at Path: %@", path);
	//if (_doc == NULL)
	//	NSLog(@"ko doc does not exist");
	DcmFileFormat fileformat;	
	OFCondition status = _doc->write(*fileformat.getDataset());
	if (status.good())  {
		//NSLog(@"have dcmdataset");
		//Set SeriesUID
		if (_seriesUID)
			fileformat.getDataset()->putAndInsertString	(DCM_SeriesInstanceUID,
									[_seriesUID UTF8String],
									OFTrue);
		status = fileformat.saveFile([path UTF8String], EXS_LittleEndianExplicit);
	}
	else {
		 _doc->print(cout, nil);
		NSLog(@"could not covert to dataset");
	}
	
	if (status.good()) {
		//NSLog(@"Wrote File");
		return YES;
	}
	else
		NSLog(@"KO Write failed");
	
	return NO;
}

- (BOOL)writeHTMLAtPath:(NSString *)path{
		size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;		
	ofstream stream([path UTF8String]);
	if ( _doc->renderHTML(stream, renderFlags, NULL).good())	
		return YES;	
	return NO;
}

 - (NSString *)sopInstanceUID{		
	const char *sop = _doc->getStudyInstanceUID();
	NSString *sopInstanceUID = nil;
	if (sop != NULL)
	 sopInstanceUID = [NSString stringWithUTF8String:sop];
	NSLog(@"sop: %@", sopInstanceUID);
	return sopInstanceUID;
}

@end
