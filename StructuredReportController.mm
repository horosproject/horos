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
#import "StructuredReport.h"


#undef verify

#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "ofstream.h"
#include "dsrdoc.h"
#include "dcuid.h"
#include "dcfilefo.h"

static NSString *ViewControlToolbarItem = @"viewControl";
static NSString *SRToolbarIdentifier = @"SRWindowToolbar";


@implementation StructuredReportController

- (id)initWithStudy:(id)study{
	if (self = [super initWithWindowNibName:@"StructuredReport"]) {	
		NSLog(@"init SR Controller");
		[self createReportForStudy:study];
	}
	return self;
}

- (void)setStudy:(id)study{
	[self createReportForStudy:study];
}

- (void)windowDidLoad{
	NSLog(@"SR Window did load");
	[self setupToolbar];
}

- (void)dealloc{
	[_findings release];
	[_conclusions release];
	[_physician release];
	[_study release];
	[_report release];
	[super dealloc];
}

- (BOOL)createReportForStudy:(id)study{
	NSLog(@"create report");
	ABPerson *me = [[ABAddressBook sharedAddressBook] me];
	[self setPhysician:[NSString stringWithFormat: @"%@^%@", [me valueForProperty:kABLastNameProperty] ,[me valueForProperty:kABFirstNameProperty]]]; 

	[[self window]  makeKeyAndOrderFront:self];
	[self setFindings:nil];
	[self setConclusions:nil];
	
	[_report release];
	_report = [[StructuredReport alloc] initWithStudy:_study];
	/*
	[NSApp beginSheet:[self window] 
		modalForWindow:[[BrowserController currentBrowser] window]
		modalDelegate:self 
		didEndSelector:nil
		contextInfo:nil];
	*/
	if ([_report fileExists])
		[self setContentView:htmlView];
	else
		[self setContentView:srView];
	_study = [study retain];	
	return YES;
}



- (void)createReportExportHTML:(BOOL)html{
	NSLog(@"Create report");
	
	DSRDocument *doc = new DSRDocument();
	NSLog(@"study: %@", [_study description]);
	doc->createNewDocument(DSRTypes::DT_BasicTextSR);
	doc->setSpecificCharacterSet("ISO_IR 192"); //UTF 8 string encoding
	doc->createNewSeriesInStudy([[_study valueForKey:@"studyInstanceUID"] UTF8String]);
	//Study Description
	if ([_study valueForKey:@"studyName"])
		doc->setStudyDescription([[_study valueForKey:@"studyName"] UTF8String]);
	//Series Description
	doc->setSeriesDescription("OsiriX Structured Report");
	//Patient Name
	if ([_study valueForKey:@"name"] )
		doc->setPatientsName([[_study valueForKey:@"name"] UTF8String]);
	// Patient DOB
	if ([_study valueForKey:@"dateOfBirth"])
		doc->setPatientsBirthDate([[[_study valueForKey:@"dateOfBirth"] descriptionWithCalendarFormat:@"%Y%m%d" timeZone:nil locale:nil] UTF8String]);
	//Patient Sex
	if ([_study valueForKey:@"patientSex"])
		doc->setPatientsSex([[_study valueForKey:@"patientSex"] UTF8String]);
	//Patient ID
	NSString *patientID = [_study valueForKey:@"patientID"];
	if ([patientID UTF8String])
		doc->setPatientID([patientID UTF8String]);
	//Referring Physician
	if ([_study valueForKey:@"referringPhysician"])
		doc->setReferringPhysiciansName([[_study valueForKey:@"referringPhysician"] UTF8String]);
	//StudyID	
	if ([_study valueForKey:@"id"]) {
		NSString *studyID = [(NSNumber *)[_study valueForKey:@"id"] stringValue];
		doc->setStudyID([studyID UTF8String]);
	}
	//Accession Number
	if ([_study valueForKey:@"accessionNumber"])
		doc->setAccessionNumber([[_study valueForKey:@"accessionNumber"] UTF8String]);
	//Series Number
	doc->setSeriesNumber("5001");
	
	doc->getTree().addContentItem(DSRTypes::RT_isRoot, DSRTypes::VT_Container);
	doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("11528-7", "LN", "Radiology Report"));
	if (_physician) {
		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_PName, DSRTypes::AM_belowCurrent);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121008", "DCM", "Person Observer Name"));
		doc->getTree().getCurrentContentItem().setStringValue([_physician UTF8String]);
	}
	
	if ([_study valueForKey:@"institutionName"]) {
		doc->getTree().addContentItem(DSRTypes::RT_hasObsContext, DSRTypes::VT_Text);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121009", "DCM", "Person Observer's Organization Name"));
		doc->getTree().getCurrentContentItem().setStringValue([[_study valueForKey:@"institutionName"] UTF8String]);
	}
	
	if (_history) {
		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Text);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121060", "DCM", "History"));
		doc->getTree().getCurrentContentItem().setStringValue([_history UTF8String]);
	}
	
	if ([_findings count] > 0) {
	    doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121070", "DCM", "Findings"));
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
				doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121071", "DCM", "Finding"));
				doc->getTree().getCurrentContentItem().setStringValue([finding UTF8String]);
			}
		}
		
	}
	
		//go back up in tree
		doc->getTree().goUp();
		
	if ([_conclusions count] > 0) {
		doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Container);
		//SH.07 is probably wrong. I'm not sure how to get the right values here.
		doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121072", "DCM", "Impressions"));
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
			doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121073", "DCM", "Impression"));
			doc->getTree().getCurrentContentItem().setStringValue([conclusion UTF8String]);
		}
		
	}
	
	//go back up in tree
	doc->getTree().goUp();
	
	/***** Exmaple of code to add a reference image **************
	doc->getTree().addContentItem(DSRTypes::RT_contains, DSRTypes::VT_Image);
    doc->getTree().getCurrentContentItem().setConceptName(DSRCodedEntryValue("121180", DCM, "Key Images"));
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

- (NSView *)contentView{
	return _contentView;
}

- (void)setContentView:(NSView *)contentView{
	_contentView = contentView;
}

-(IBAction)setView:(id)sender{
	switch ([sender selectedSegment]){
		case 0: [self setContentView:htmlView];
			break;
		case 1: [self setContentView:srView];
			break;
		case 2: [self setContentView:xmlView];
			break;
		default: [self setContentView:htmlView];
	}
	[[self window] setContentView:_contentView];
}

#pragma mark-
#pragma mark Toolbar functions

// ============================================================
// NSToolbar Related Methods
// ============================================================

- (void) setupToolbar {
	NSLog(@"Setup Toolbar");
	toolbar = [[NSToolbar alloc] initWithIdentifier:SRToolbarIdentifier];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setVisible:YES];
	[[self window] setToolbar:toolbar];
	[[self window] setShowsToolbarButton:NO];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
	if ([itemIdent isEqualToString: ViewControlToolbarItem]) {
		[toolbarItem setLabel: NSLocalizedString(@"View Report", nil)];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Report Style", nil)];
		[toolbarItem setToolTip: NSLocalizedString(@"View Report as html, xml, DICOM", nil)];
		[toolbarItem setView:viewControl];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([viewControl frame]), NSHeight([viewControl frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([viewControl frame]), NSHeight([viewControl frame]))];
	}
	return [toolbarItem autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
	return [NSArray arrayWithObject:ViewControlToolbarItem];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
	return [NSArray arrayWithObject:ViewControlToolbarItem];
}

@end
