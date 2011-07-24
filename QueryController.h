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


#import "QueryOutlineView.h"
#import "sourcesTableView.h"
#import <AppKit/AppKit.h>

@class QueryArrayController;
@class QueryFilter;

/** \brief Window Controller for Q/R */
@interface QueryController : NSWindowController <NSWindowDelegate, NSOutlineViewDelegate>
{
    IBOutlet    QueryOutlineView			*outlineView;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSSearchField				*searchFieldName, *searchFieldRefPhysician, *searchFieldID, *searchFieldAN, *searchFieldStudyDescription, *searchFieldComments, *searchInstitutionName;
	
				NSMutableArray				*sourcesArray;
	IBOutlet	sourcesTableView			*sourcesTable;
	IBOutlet	NSTextField					*selectedResultSource;
	IBOutlet	NSTextField					*numberOfStudies;
	IBOutlet	NSPopUpButton				*presetsPopup;
	
	IBOutlet	NSWindow					*presetWindow;
	IBOutlet	NSTextField					*presetName;
	
	IBOutlet	NSMatrix					*birthdateFilterMatrix;
	IBOutlet	NSMatrix					*dateFilterMatrix;
	IBOutlet	NSMatrix					*modalityFilterMatrix;
	IBOutlet	NSTabView					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate, *searchBirth;
	IBOutlet	NSTextField					*yearOldBirth;
    IBOutlet	NSPopUpButton				*sendToPopup;
	
	int										autoQueryRemainingSecs;
	IBOutlet NSTextField					*autoQueryCounter;
	
	
	BOOL									DatabaseIsEdited;
	IBOutlet NSWindow						*autoRetrieveWindow;
	
	NSMutableString							*pressedKeys;
    NSMutableArray							*resultArray;
    NSMutableArray							*queryFilters;
	NSMutableDictionary						*previousAutoRetrieve;
	
	QueryFilter								*dateQueryFilter, *timeQueryFilter, *modalityQueryFilter;
	NSString								*currentQueryKey, *queryArrayPrefs;
	int										checkAndViewTry;
	
	NSImage									*Realised3, *Realised2;
	NSTimer									*QueryTimer;
	IBOutlet NSImageView					*alreadyInDatabase, *partiallyInDatabase;
	
	QueryArrayController					*queryManager;
	
	BOOL									autoQuery, queryButtonPressed, performingCFind, avoidQueryControllerDeallocReentry;
	
	NSInteger								autoRefreshQueryResults;
	NSRecursiveLock							*autoQueryLock;
	
	NSInteger								numberOfRunningRetrieve;
}

@property (readonly) NSRecursiveLock *autoQueryLock;
@property (readonly) QueryOutlineView *outlineView;
@property BOOL autoQuery, DatabaseIsEdited;
@property NSInteger autoRefreshQueryResults;

+ (QueryController*) currentQueryController;
+ (QueryController*) currentAutoQueryController;
+ (BOOL) echo: (NSString*) address port:(int) port AET:(NSString*) aet;
+ (BOOL) echoServer:(NSDictionary*)serverParameters;
+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer;
+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors;
+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer;
+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors;
- (void) autoRetrieveSettings: (id) sender;
- (void) saveSettings;
- (id) initAutoQuery: (BOOL) autoQuery;
- (IBAction) cancel:(id)sender;
- (IBAction) ok:sender;
- (void) refreshAutoQR: (id) sender;
- (void) refreshList: (NSArray*) l;
- (BOOL) queryWithDisplayingErrors:(BOOL) showError;
- (IBAction) selectUniqueSource:(id) sender;
- (void) refreshSources;
- (IBAction) retrieveAndViewClick: (id) sender;
- (IBAction) retrieveAndView: (id) sender;
- (IBAction) view:(id) sender;
- (IBAction) setBirthDate:(id) sender;
- (NSArray*) queryPatientID:(NSString*) ID;
- (void) query:(id)sender;
- (void) retrieve:(id)sender;
- (void) retrieve:(id)sender onlyIfNotAvailable:(BOOL) onlyIfNotAvailable;
- (void) performQuery:(NSNumber*) showErrors;
- (void) performRetrieve:(NSArray*) array;
- (void) setDateQuery:(id)sender;
- (void) setModalityQuery:(id)sender;
- (void) clearQuery:(id)sender;
- (int) dicomEcho:(NSDictionary*) aServer;
- (IBAction) verify:(id)sender;
- (IBAction) abort:(id)sender;
- (IBAction) controlAction:(id)sender;
- (void) refresh: (id) sender;
- (IBAction) pressButtons:(id) sender;
- (NSArray*) localSeries:(id) item;
- (NSArray*) localStudy:(id) item;
- (IBAction) endAddPreset:(id) sender;
- (void) buildPresetsMenu;
- (IBAction) autoQueryTimer:(id) sender;
- (IBAction) switchAutoRetrieving: (id) sender;
- (IBAction) selectModality: (id) sender;
- (void) displayAndRetrieveQueryResults;
- (void) autoQueryThread;
- (void) autoQueryTimerFunction:(NSTimer*) t;
- (void) executeRefresh: (id) sender;
@end
