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

#import "StructuredReport.h"
#import "browserController.h"
#import <AddressBook/AddressBook.h>
#import "DicomImage.h"
#import "DICOMToNSString.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */
#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"
#include "dsrtypes.h"
#include "dsrimgtn.h"
#include "dsrdoctr.h"

@implementation StructuredReport

- (id)initWithStudy:(id)study{
	return [self initWithStudy:(id)study contentsOfFile:nil];
}

- (id)initWithStudy:(id)study contentsOfFile:(NSString *)file{
	if (self = [super init]){
		_doc = new DSRDocument();
		_study = [study retain];
		_reportHasChanged = NO;
		_isEditable = YES;
		_path = [file retain];

		if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
			_reportHasChanged = NO;			
			DcmFileFormat fileformat;
			OFCondition status = fileformat.loadFile([file UTF8String]);
			if (status.good())
				status = _doc->read(*fileformat.getDataset());

			// If we are the manfacturer we can edit.
			const char *manf = _doc->getManufacturer();
			//_doc->print(cout, NULL);
			if (manf != NULL && strcmp("OsiriX", manf) == 0){
				
				//completion flag
				if (_doc->getCompletionFlag() == DSRTypes::CF_Complete)
					[self setComplete:YES];
				else
					[self setComplete:NO];
					
				//Verification Flag
				if (_doc->getVerificationFlag()  == DSRTypes::VF_Verified)
					[self setVerified:YES];
				else
					[self setVerified:NO];
					
				//go to physician/observer		
				DSRCodedEntryValue codedEntryValue = DSRCodedEntryValue("121008", "DCM", "Person Observer Name");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0 ){
					OFString observer = _doc->getTree().getCurrentContentItem().getStringValue();
					[self setPhysician:[NSString stringWithCString:observer.c_str() encoding:NSUTF8StringEncoding]];
				}
				//go to observer / Institution
				codedEntryValue = DSRCodedEntryValue("121009", "DCM", "Person Observer's Organization Name");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0 ){
					OFString institution = _doc->getTree().getCurrentContentItem().getStringValue();
					[self setInstitution:[NSString stringWithCString:institution.c_str() encoding:NSUTF8StringEncoding]];
				}
				
				//go to history
				codedEntryValue = DSRCodedEntryValue("121060", "DCM", "History");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0){
					OFString observer = _doc->getTree().getCurrentContentItem().getStringValue();
					[self setHistory:[NSString stringWithCString:observer.c_str() encoding:NSUTF8StringEncoding]];
				}
				
				//Request
				codedEntryValue = DSRCodedEntryValue("121062", "DCM", "Request");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0){
					OFString request = _doc->getTree().getCurrentContentItem().getStringValue();
					[self setRequest:[NSString stringWithCString:request.c_str() encoding:NSUTF8StringEncoding]];
				}
				
				//Procedure
				codedEntryValue = DSRCodedEntryValue("121064", "DCM", "Current Procedure Descriptions");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0){
					codedEntryValue = DSRCodedEntryValue("121065", "DCM", "Procedure Description");
					if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0){
						OFString procedureDescription = _doc->getTree().getCurrentContentItem().getStringValue();
						[self setProcedureDescription:[NSString stringWithCString:procedureDescription.c_str() encoding:NSUTF8StringEncoding]];
					}
				}
				
				//findings
				codedEntryValue = DSRCodedEntryValue("121070", "DCM", "Findings");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0) {
					NSMutableArray *findings = [NSMutableArray array];
					//get all the findings
					codedEntryValue = DSRCodedEntryValue("121071", "DCM", "Finding");
					if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0) {
						OFString finding = _doc->getTree().getCurrentContentItem().getStringValue();
						[findings addObject: [NSDictionary dictionaryWithObject:[NSString stringWithCString:finding.c_str() encoding:NSUTF8StringEncoding]
								forKey:@"finding"]];
						// get the rest. Need a loop here
						while(_doc->getTree().gotoNextNamedNode (codedEntryValue, OFFalse) > 0) {
							finding = _doc->getTree().getCurrentContentItem().getStringValue();
							[findings addObject: [NSDictionary dictionaryWithObject:[NSString stringWithCString:finding.c_str() encoding:NSUTF8StringEncoding]
								forKey:@"finding"]];
						}
					}
					//[self setFindings:findings];
					_findings = [findings retain];
				}
				
				//Impressions
				codedEntryValue = DSRCodedEntryValue("121072", "DCM", "Impressions");
				if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0) {
					NSMutableArray *impressions = [NSMutableArray array];
					//get all the impressions
					codedEntryValue = DSRCodedEntryValue("121073", "DCM", "Impression");
					if (_doc->getTree().gotoNamedNode (codedEntryValue, OFTrue, OFTrue) > 0) {
						OFString impression = _doc->getTree().getCurrentContentItem().getStringValue();
						[impressions addObject: [NSDictionary dictionaryWithObject:[NSString stringWithCString:impression.c_str() encoding:NSUTF8StringEncoding]
								forKey:@"conclusion"]];
						// get the rest. Need a loop here
						while(_doc->getTree().gotoNextNamedNode (codedEntryValue, OFFalse) > 0) {
							impression = _doc->getTree().getCurrentContentItem().getStringValue();
							[impressions addObject: [NSDictionary dictionaryWithObject:[NSString stringWithCString:impression.c_str() encoding:NSUTF8StringEncoding]
								forKey:@"conclusion"]];
							
						}

					}
					//[self setConclusions:impressions];
					_conclusions = [impressions retain];
				}
				
				//get key Images. If none load from study
				// get KeyImages
				_keyImages = [[self referencedObjects] retain];
			}
			else {
				_isEditable = NO;
			}

		}
		else {
			ABPerson *me = [[ABAddressBook sharedAddressBook] me];
			[self setPhysician:[NSString stringWithFormat: @"%@^%@", [me valueForProperty:kABLastNameProperty] ,[me valueForProperty:kABFirstNameProperty]]];
			[self setInstitution:[_study valueForKey:@"institutionName"]];
			[self setRequest:[NSString stringWithFormat:@"%@ %@", [_study valueForKey:@"modality"], [_study valueForKey:@"studyName"]]];
			//Not sure what to suggest for history and technique
			   
			_doc->createNewDocument(DSRTypes::DT_BasicTextSR);
			_doc->setSpecificCharacterSet("ISO_IR 192"); //UTF 8 string encoding
			_doc->createNewSeriesInStudy([[_study valueForKey:@"studyInstanceUID"] UTF8String]);
			//Study Description
			if ([_study valueForKey:@"studyName"])
				_doc->setStudyDescription([[_study valueForKey:@"studyName"] UTF8String]);
			//Series Description
			_doc->setSeriesDescription("OsiriX Structured Report");
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
			_doc->setSeriesNumber("5001");
			
			_doc->setManufacturer("OsiriX");
			
			// get KeyImages
			//_keyImages = [[[_study keyImages] allObjects] retain];
			
		}	
	}
	return self;
}

- (void)dealloc{
	delete _doc;
	[_study release];
	[_findings release];
	[_conclusions release];
	[_physician release];
	[_history release];
	[_xmlDoc release];
	[_sopInstanceUID release];
	[_request release];
	[_procedureDescription release];
	[_institution release];
	[_verifyOberverOrganization release];
	[_verifyOberverName release];
	[_keyImages release];
	[_path release];
	[super dealloc];
}


- (NSArray *)findings{	
	if (!_findings)
		_findings = [[NSArray alloc] init];
	return _findings;
}

- (void)setFindings:(NSMutableArray *)findings{
	[_findings release];
	_findings = [findings retain];
	_reportHasChanged = YES;
}

- (NSArray *)conclusions{
	if (!_conclusions)
		_conclusions = [[NSMutableArray alloc] init];
	return _conclusions;
}

- (void)setConclusions:(NSMutableArray *)conclusions{
	[_conclusions release];
	_conclusions = [conclusions retain];
	_reportHasChanged = YES;
}

- (NSString *)physician{
	return _physician;
}
- (void)setPhysician:(NSString *)physician{
	[_physician release];
	_physician = [physician retain];
	_reportHasChanged = YES;
}

- (NSString *)history{
	return _history;
}

- (void)setHistory:(NSString *)history{
	[_history release];
	_history = [history retain];
	_reportHasChanged = YES;
}

- (NSString *)request{
	return _request;
}
- (void)setRequest:(NSString *)request{
	[_request release];
	_request = [request retain];
	_reportHasChanged = YES;
}

- (NSString *)procedureDescription{
	return _procedureDescription;
}

- (void)setProcedureDescription:(NSString *)procedureDescription{
	[_procedureDescription release];
	_procedureDescription = [procedureDescription retain];
	_reportHasChanged = YES;
}
	
- (NSString *)institution{
	return _institution;
}

- (void)setInstitution:(NSString *)institution{
	[_institution release];
	_institution = [institution retain];
	_reportHasChanged = YES;
}

- (NSString *)verifyOberverName{
	return _verifyOberverName;
}

- (void)setVerifyOberverName:(NSString *)verifyOberverName{
	[_verifyOberverName release];
	_verifyOberverName = [verifyOberverName retain];
}

- (NSString *)verifyOberverOrganization{
	return _verifyOberverOrganization;
}

- (void)setVerifyOberverOrganization:(NSString *)verifyOberverOrganization{
	[_verifyOberverOrganization release];
	_verifyOberverOrganization = [verifyOberverOrganization retain];
}

- (BOOL)complete{
	return _complete;
}

- (void)setComplete:(BOOL)complete{
	if (_complete == YES && complete == NO) {
		[_path release];
		_path = nil;
	}
	_complete = complete;
	_reportHasChanged = YES;
	if (_complete == NO)
		[self setVerified:NO];
}

- (BOOL)verified{
	return _verified;
}

- (void)setVerified:(BOOL)verified{
	if (_verified == YES && verified == NO) {
		[_path release];
		_path = nil;
	}
	_verified = verified;
	_reportHasChanged = YES;
	if (_verified == YES)
		[self setComplete:YES];
}

- (NSArray *)keyImages{
	if (!_keyImages)
		_keyImages = [[NSArray alloc] init];
	return _keyImages;
}

- (void)setKeyImages:(NSArray *)keyImages{
	[_keyImages release];
	_keyImages = [keyImages retain];
	_reportHasChanged = YES;
	[self setComplete:NO];
}

- (NSDate *)contentDate{
	NSDate *date = nil;
	const char *contentDate = _doc->getContentDate();
	if (contentDate != NULL) {
		NSString *dateString = [NSString stringWithUTF8String:contentDate];
		date = [NSCalendarDate dateWithString:dateString calendarFormat:@"%Y%m%d"];
	}
	
	return date;
}

- (void)setContentDate:(NSDate *)date{
}

- (NSString *)title{
	NSString *title = nil;
	const char *seriesDescription = _doc->getSeriesDescription();
	if (seriesDescription != NULL)
		title = [NSString stringWithUTF8String:seriesDescription];
	return title;
}

- (void)setTitle:(NSString *)title{

}
	
- (BOOL)fileExists{
	if ([_study valueForKey:@"reportURL"] && [[NSFileManager defaultManager] fileExistsAtPath:[_study valueForKey:@"reportURL"]])
		return YES;
	return NO;
}

- (BOOL)isEditable{
	// if the verify flags are both verified we cannot edit
	if (_verified && _doc->getVerificationFlag() == DSRTypes::VF_Verified)
		return NO;
	return _isEditable;
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

- (void)createReport{
	if ([self isEditable]) {
			//set Completion flag
		// new a new reference if changing from complete to partial
		if (_doc->getCompletionFlag() == DSRTypes::CF_Complete && !_complete) {
			_doc->createRevisedVersion(OFTrue);
		}		
		else if (_complete){
			_doc->completeDocument("COMPLETE");
		}
		
		if (_verified && _doc->getVerificationFlag() != DSRTypes::VF_Verified) {
			//Need to add verification
			const OFString von = OFString([_verifyOberverName UTF8String]);
			const OFString voo = OFString([_verifyOberverOrganization UTF8String]);
			_doc->verifyDocument(von, voo);
			
		}
		else if (!_verified && _doc->getVerificationFlag()  == DSRTypes::VF_Verified) 
			_doc->createRevisedVersion(OFFalse);

		//clear old content	
		_doc->getTree().clear();
				
		_doc->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
		_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("11528-7", "LN", "Radiology Report"));
		if (_physician) {
			_doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_PName, DSRTypes::AM_belowCurrent);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121008", "DCM", "Person Observer Name"));
			_doc->getTree().getCurrentContentItem().setStringValue([_physician UTF8String]);
		}
		
		if (_institution) {
			_doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Text);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121009", "DCM", "Person Observer's Organization Name"));
			_doc->getTree().getCurrentContentItem().setStringValue([_institution UTF8String]);
		}
		
		if (_history) {
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121060", "DCM", "History"));
			_doc->getTree().getCurrentContentItem().setStringValue([_history UTF8String]);
		}
		
		if (_request){
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121062", "DCM", "Request"));
			_doc->getTree().getCurrentContentItem().setStringValue([_request UTF8String]);
		}
		
		if (_procedureDescription){
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121064", "DCM", "Current Procedure Descriptions"));
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121065", "DCM", "Procedure Description"));
			_doc->getTree().getCurrentContentItem().setStringValue([_procedureDescription UTF8String]);
			//go back up in tree
			_doc->getTree().goUp();
			
		}
		
		if ([_findings count] > 0) {
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121070", "DCM", "Findings"));
			NSEnumerator *enumerator = [_findings objectEnumerator];
			NSDictionary *dict;
			BOOL first = YES;
			
			while (dict = [enumerator nextObject]) {
				NSString *finding = [dict objectForKey:@"finding"];
				if (finding){
					if (first) {
						// go down one level if first Finding
						_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
						first = NO;
					}
					else
						_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
					_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121071", "DCM", "Finding"));
					_doc->getTree().getCurrentContentItem().setStringValue([finding UTF8String]);
				}
			}
			//go back up in tree
			_doc->getTree().goUp();
		}
			
		if ([_conclusions count] > 0) {
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);			
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121072", "DCM", "Impressions"));
			NSEnumerator *enumerator = [_conclusions objectEnumerator];
			NSDictionary *dict;
			BOOL first = YES;
			
			while (dict = [enumerator nextObject]) {
				if (first) {
					// go down one level if first Finding
					_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
					first = NO;
				}
				else
					_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
				NSString *conclusion = [dict objectForKey:@"conclusion"];			
				_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121073", "DCM", "Impression"));
				_doc->getTree().getCurrentContentItem().setStringValue([conclusion UTF8String]);
			}
			//go back up in tree
			_doc->getTree().goUp();
		}
		
		// add keyImages
		if ([_keyImages count] > 0){
			NSLog(@"Add key Images to report");
			_doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
			_doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121180"," DCM", "Key Images"));
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
				
		_reportHasChanged = NO;
	}
}

- (void)save
{
	if (_reportHasChanged)
		[self createReport];
	DcmFileFormat fileformat;	
	OFCondition status = _doc->write(*fileformat.getDataset());
	if (status.good()) 
		status = fileformat.saveFile([[self srPath] UTF8String], EXS_LittleEndianExplicit);
		
	if (status.good())
	{
		NSLog(@"Report saved: %@", [self srPath]);
		
		[[BrowserController currentBrowser] checkIncoming: self];
	}
	else
		NSLog(@"Report not saved: %@", [self srPath]);
}

- (void)export:(NSString *)path{
	if (_reportHasChanged)
		[self createReport];
	NSString *extension = [path pathExtension];
	if ([extension isEqualToString:@"dcm"]) {
		DcmFileFormat fileformat;	
		OFCondition status = _doc->write(*fileformat.getDataset());
		if (status.good()) 
			status = fileformat.saveFile([path UTF8String], EXS_LittleEndianExplicit);
	}
	else if ([extension isEqualToString:@"xml"]){
		size_t writeFlags = 0;		
		[self checkCharacterSet];
		ofstream stream([path UTF8String]);
		_doc->writeXML(stream, writeFlags);
	}
	else if ([extension isEqualToString:@"htm"] || [extension isEqualToString:@"html"]){
		[self checkCharacterSet];
		size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;		
		ofstream stream([path UTF8String]);
		_doc->renderHTML(stream, renderFlags, NULL);
	}
}

- (void)convertXMLToSR{
	if (_doc)
		delete _doc;
	_doc = new DSRDocument();
	_doc->readXML([[self xmlPath] UTF8String], nil);
}

- (void)writeHTML{
	if (_reportHasChanged) {
		[self createReport];
	}
	[self checkCharacterSet];
	size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;		
	ofstream stream([[self htmlPath] UTF8String]);
	_doc->renderHTML(stream, renderFlags, NULL);	
}

- (void)writeXML{
	size_t writeFlags = 0;		
	[self checkCharacterSet];
	ofstream stream([[self xmlPath] UTF8String]);
	_doc->writeXML(stream, writeFlags);
}

- (void)readXML{
	[_xmlDoc release];
	NSURL *url = [NSURL fileURLWithPath:[self xmlPath]]; 
	NSError *error;
	_xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:(NSURL *)url options:nil error:(NSError **)error];
}

- (NSString *)xmlPath{
	NSString *tempPath = @"/tmp";
	NSString *path = [[tempPath stringByAppendingPathComponent:[_study valueForKey:@"studyInstanceUID"]] stringByAppendingPathExtension:@"xml"];
	return path;
}
- (NSString *)htmlPath{
 	NSString *tempPath = @"/tmp";
	NSString *path = [[tempPath stringByAppendingPathComponent:[_study valueForKey:@"studyInstanceUID"]] stringByAppendingPathExtension:@"html"];
	return path;
}
- (NSString *)srPath{
	if (_path)
		return _path;

	NSString *dbPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"INCOMING.noindex"];
	NSString *path = [[dbPath stringByAppendingPathComponent:[_study valueForKey:@"studyInstanceUID"]] stringByAppendingPathExtension:@"dcm"];
	return path;

}

//- (NSMXLDocument *)xmlDoc{
//	return _xmlDoc;
//}

- (NSArray *)referencedObjects{
	NSMutableArray *references = [NSMutableArray array];
	NSArray *imagesArray = nil;
	NS_DURING
	DSRDocumentTreeNode *node = NULL; 
	//_doc->getTree().print(cout, 0);
	_doc->getTree().gotoRoot ();
		/* iterate over all nodes */ 
	do { 
		node = OFstatic_cast(DSRDocumentTreeNode *, _doc->getTree().getNode());			
		if (node != NULL && node->getValueType() == DSRTypes::VT_Image) {
			//image node get SOPCInstance
			DSRImageTreeNode *imageNode = OFstatic_cast(DSRImageTreeNode *, node);
			OFString sopInstance = imageNode->getSOPInstanceUID();
			if (!sopInstance.empty()) {
				NSString *uid = [NSString stringWithUTF8String:sopInstance.c_str()];
				if (uid)
					[references addObject:uid];
			}			
		}
	} while (_doc->getTree().iterate()); 
	NSManagedObjectModel	*model = [[BrowserController currentBrowser] managedObjectModel];
	NSManagedObjectContext	*context = [[BrowserController currentBrowser] managedObjectContext];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[model entitiesByName] objectForKey:@"Image"]];
	NSPredicate *predicate = [NSPredicate predicateWithValue:NO];
	NSError *error = nil;
	
	NSEnumerator *enumerator = [references objectEnumerator];
	id reference;
	while (reference = [enumerator nextObject])
	{
		NSPredicate	*p = [NSComparisonPredicate predicateWithLeftExpression: [NSExpression expressionForKeyPath: @"compressedSopInstanceUID"] rightExpression: [NSExpression expressionForConstantValue: [DicomImage sopInstanceUIDEncodeString: reference]] customSelector: @selector( isEqualToSopInstanceUID:)];
		predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, p, nil]]; 
	}
	[dbRequest setPredicate: [NSPredicate predicateWithFormat:@"compressedSopInstanceUID != NIL"]];
	imagesArray = [context executeFetchRequest:dbRequest error:&error];
	imagesArray = [[imagesArray filteredArrayUsingPredicate: predicate] retain];
	
	NS_HANDLER
	NS_ENDHANDLER
	return imagesArray;
}

@end
