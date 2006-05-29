//
//  StructuredReportController.mm
//  OsiriX
//
//  Created by Lance Pysher on 5/29/06.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "StructuredReportController.h"

#import "browserController.h"
#import "AddressBook/AddressBook.h"

#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"


@implementation StructuredReportController

- (id)initWithStudy:(id)study{
	if (self = [super initWithWindowNibName:@"StructuredReport"]) {
		[self createReportForStudy:study];
	}
	return self;
}

- (void)dealloc{
	[_findings release];
	[_conclusions release];
	[_physician release];
	[_study release];
	[super dealloc];
}

- (BOOL)createReportForStudy:(id)study{
	ABPerson *me = [[ABAddressBook sharedAddressBook] me];
	[self setPhysician:[NSString stringWithFormat: @"%@^%@", [me valueForProperty:kABLastNameProperty] ,[me valueForProperty:kABFirstNameProperty]]]; 

	//[_window  makeKeyAndOrderFront:self];
	[NSApp beginSheet:[self window] 
		modalForWindow:[[BrowserController currentBrowser] window]
		modalDelegate:self 
		didEndSelector:nil
		contextInfo:nil];
	_study = [study retain];
	return YES;
}

-(IBAction)endSheet:(id)sender{	
	if ([sender tag] == 0)
		[self createReportExportHTML:NO];
	else if ([sender tag] == 2)
		[self createReportExportHTML:YES];
	[NSApp endSheet:[self window]];
	[[self window] close];
}

- (void)createReportExportHTML:(BOOL)html{
	NSLog(@"Create report");
	NSString *patientID = [_study valueForKey:@"patientID"];
	DSRDocument *doc = new DSRDocument();
	NSLog(@"study: %@", [_study description]);
	doc->createNewDocument(DSRTypes::DT_BasicTextSR);
	doc->setSpecificCharacterSet("ISO_IR 192"); //UTF 8 string encoding
	doc->createNewSeriesInStudy([[_study valueForKey:@"studyInstanceUID"] UTF8String]);
	
	if ([_study valueForKey:@"studyName"])
		doc->setStudyDescription([[_study valueForKey:@"studyName"] UTF8String]);
	doc->setSeriesDescription("OsiriX Structured Report");
	if ([_study valueForKey:@"name"] )
		doc->setPatientsName([[_study valueForKey:@"name"] UTF8String]);
	if ([_study valueForKey:@"dateOfBirth"])
		doc->setPatientsBirthDate([[[_study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
	if ([_study valueForKey:@"patientSex"])
		doc->setPatientsSex([[_study valueForKey:@"patientSex"] UTF8String]);
	if ([patientID UTF8String])
		doc->setPatientID([patientID UTF8String]);
	if ([_study valueForKey:@"referringPhysician"])
		doc->setReferringPhysiciansName([[_study valueForKey:@"referringPhysician"] UTF8String]);
	
	doc->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("DT.01", OFFIS_CODING_SCHEME_DESIGNATOR, "Radiology Report"));
	if (_physician) {
		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_PName, DSRTypes::AM_belowCurrent);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.04", OFFIS_CODING_SCHEME_DESIGNATOR, "Observer Name"));
		doc->getTree().getCurrentContentItem().setStringValue([_physician UTF8String]);
	}
	
	if ([_study valueForKey:@"institutionName"]) {
		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Text);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IHE.05", OFFIS_CODING_SCHEME_DESIGNATOR, "Observer Organization Name"));
		doc->getTree().getCurrentContentItem().setStringValue([[_study valueForKey:@"institutionName"] UTF8String]);
	}
	
	if (_history) {
		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("RE.01", OFFIS_CODING_SCHEME_DESIGNATOR, "History"));
		doc->getTree().getCurrentContentItem().setStringValue([_history UTF8String]);
	}
	
	if ([_findings count] > 0) {
	    doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("SH.06", OFFIS_CODING_SCHEME_DESIGNATOR, "Findings"));
		NSEnumerator *enumerator = [_findings objectEnumerator];
		NSDictionary *dict;
		BOOL first = YES;
		NSLog(@"findings: %@", [_findings description]);
		
		while (dict = [enumerator nextObject]) {
			NSString *finding = [dict objectForKey:@"finding"];
			NSLog(@"finding: %@", finding);
			if (finding){
				if (first) {
					// go down one level if first Finding
					doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
					first = NO;
				}
				else
					doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
				doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("RE.05", OFFIS_CODING_SCHEME_DESIGNATOR, "Finding"));
				doc->getTree().getCurrentContentItem().setStringValue([finding UTF8String]);
			}
		}
		
	}
	
		//go back up in tree
		doc->getTree().goUp();
		
	if ([_conclusions count] > 0) {
		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
		//SH.07 is probably wrong. I'm not sure how to get the right values here.
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("SH.07", OFFIS_CODING_SCHEME_DESIGNATOR, "Conclusions"));
		NSEnumerator *enumerator = [_conclusions objectEnumerator];
		NSDictionary *dict;
		BOOL first = YES;
		
		while (dict = [enumerator nextObject]) {
			if (first) {
				// go down one level if first Finding
				doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text, DSRTypes::AM_belowCurrent);
				first = NO;
			}
			else
				doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
			NSString *conclusion = [dict objectForKey:@"conclusion"];			
			doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("RE.08", OFFIS_CODING_SCHEME_DESIGNATOR, "Conclusion"));
			doc->getTree().getCurrentContentItem().setStringValue([conclusion UTF8String]);
		}
		
	}
	
	//go back up in tree
	doc->getTree().goUp();
	
	/***** Exmaple of code to add a reference image **************
	doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image);
    doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("IR.02", OFFIS_CODING_SCHEME_DESIGNATOR, "Best illustration of finding"));
    doc->getTree().getCurrentContentItem().setImageReference(DSRImageReferenceValue(SOPClassUID, SOPInstanceUID));
    doc->getCurrentRequestedProcedureEvidence().addItem(const OFString &studyUID, const OFString &seriesUID, const OFString &sopClassUID, const OFString &instanceUID);
	*/

	// write out SR
	NSString *dbPath = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingPathComponent:@"REPORTS"];
	DcmFileFormat fileformat;
	
	if (!html) {
		OFCondition status = doc->write(*fileformat.getDataset());
		NSString *path = [[dbPath stringByAppendingPathComponent:[_study valueForKey:@"studyInstanceUID"]] stringByAppendingPathExtension:@"dcm"];
		status = fileformat.saveFile([path UTF8String], EXS_LittleEndianExplicit);
	}
	else{
		size_t renderFlags = DSRTypes::HF_renderDcmtkFootnote;
		NSString *path = [[dbPath stringByAppendingPathComponent:[_study valueForKey:@"studyInstanceUID"]] stringByAppendingPathExtension:@"html"];		
				ofstream stream([path UTF8String]);
		doc->renderHTML(stream, renderFlags, NULL);
	}

	delete doc;
}

- (NSArray *)findings{
	
	if (!_findings)
		_findings = [[NSArray alloc] init];
	return _findings;
}
- (void)setFindings:(NSArray *)findings{
	//NSLog(@"setFindings: %@", [findings description]);
	[_findings release];
	_findings = [findings retain];
}

- (NSArray *)conclusions{
	if (!_conclusions)
		_conclusions = [[NSArray alloc] init];
	return _conclusions;
}
- (void)setConclusions:(NSArray *)conclusions{
	//NSLog(@"setConclusions: %@", [conclusions description]);
	[_conclusions release];
	_conclusions = [conclusions retain];
}

- (NSString *)physician{
	return _physician;
}
- (void)setPhysician:(NSString *)physician{
	[_physician release];
	_physician = [physician retain];
}

- (NSString *)history{
	return _history;
}

- (void)setHistory:(NSString *)history{
	[_history release];
	_history = [history retain];
}


@end
