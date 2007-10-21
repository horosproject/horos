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



#import "sourcesTableView.h"
#import <AppKit/AppKit.h>

@class QueryArrayController;
@class QueryFilter;

/** \brief Window Controller for Q/R */
@interface QueryController : NSWindowController {

    IBOutlet    NSOutlineView				*outlineView;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSSearchField				*searchFieldName, *searchFieldID, *searchFieldAN;
	
				NSMutableArray				*sourcesArray;
	IBOutlet	sourcesTableView			*sourcesTable;
	IBOutlet	NSTextField					*selectedResultSource;
	IBOutlet	NSTextField					*numberOfStudies;
	IBOutlet	NSPopUpButton				*presetsPopup;
	
	IBOutlet	NSWindow					*presetWindow;
	IBOutlet	NSTextField					*presetName;
	
	IBOutlet	NSMatrix					*dateFilterMatrix;
	IBOutlet	NSMatrix					*modalityFilterMatrix;
	IBOutlet	NSTabView					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate, *searchBirth;
    IBOutlet	NSPopUpButton				*sendToPopup;
	
	NSMutableString							*pressedKeys;
    NSMutableArray							*resultArray;
    NSMutableArray							*queryFilters;
	
	QueryFilter								*dateQueryFilter, *modalityQueryFilter;
	NSString								*currentQueryKey;
	BOOL									echoSuccess;
	NSMutableDictionary						*activeMoves;
	int										checkAndViewTry;
	
	NSImage									*Realised3, *Realised2;
	
	QueryArrayController					*queryManager;
}

+ (QueryController*) currentQueryController;
+ (BOOL) echo: (NSString*) address port:(int) port AET:(NSString*) aet;
+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer;

- (IBAction) selectUniqueSource:(id) sender;
- (void) refreshSources;
- (IBAction) retrieveAndViewClick: (id) sender;
- (IBAction) retrieveAndView: (id) sender;
- (IBAction) view:(id) sender;
- (void) queryPatientID:(NSString*) ID;
- (void) query:(id)sender;
- (void) retrieve:(id)sender;
- (void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable;
- (void)performQuery:(id)object;
- (void)performRetrieve:(NSArray*) array;
- (void)setDateQuery:(id)sender;
- (void)setModalityQuery:(id)sender;
- (void)clearQuery:(id)sender;
- (int)dicomEcho:(NSDictionary*) aServer;
- (IBAction)verify:(id)sender;
- (IBAction)abort:(id)sender;
- (IBAction)controlAction:(id)sender;
- (void) refresh: (id) sender;
- (IBAction) pressButtons:(id) sender;
- (NSArray*) localStudy:(id) item;
- (IBAction) endAddPreset:(id) sender;
- (void) buildPresetsMenu;
@end
