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



#import "sourcesTableView.h"
#import <AppKit/AppKit.h>

//@class DICOMQueryStudyRoot;
@class QueryArrayController;
@class QueryFilter;
@interface QueryController : NSWindowController {

    IBOutlet    NSOutlineView				*outlineView;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSSearchField				*searchFieldName, *searchFieldID;
	
				NSMutableArray				*sourcesArray;
	IBOutlet	sourcesTableView			*sourcesTable;
	IBOutlet	NSTextField					*selectedResultSource;
	
	IBOutlet	NSMatrix					*dateFilterMatrix;
	IBOutlet	NSMatrix					*modalityFilterMatrix;
	IBOutlet	NSTabView					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate, *searchBirth;
    
	NSMutableString							*pressedKeys;
    NSMutableArray							*resultArray;
    NSMutableArray							*queryFilters;
	
	QueryFilter								*dateQueryFilter, *modalityQueryFilter;
	NSString								*currentQueryKey;
	BOOL									echoSuccess;
	NSMutableDictionary						*activeMoves;
	int										checkAndViewTry;
	
	
	QueryArrayController					*queryManager;
}

+ (QueryController*) currentQueryController;

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
- (int)dicomEcho;
- (IBAction)verify:(id)sender;
- (IBAction)abort:(id)sender;
- (IBAction)controlAction:(id)sender;
- (void) refresh: (id) sender;

@end
