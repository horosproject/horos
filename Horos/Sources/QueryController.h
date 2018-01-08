/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/


#import "QueryOutlineView.h"
#import "sourcesTableView.h"
#import <AppKit/AppKit.h>
#import "SFHorosAuthorizationView.h"

@class QueryArrayController;
@class QueryFilter;
@class DicomStudy;

#define MAXINSTANCE 40

enum
{
    anyDate = 0,
    today = 1,
    yesteday = 2,
    last7Days = 3,
    lastMonth = 4,
    between = 5,
    on = 6,
    last2Days = 7,
    last3Months = 8,
    dayBeforeYesterday = 9,
    todayAM = 10,
    todayPM = 11,
    after = 12,
    last2Months = 13,
    lastYear = 14
};

/** \brief Window Controller for Q/R */
@interface QueryController : NSWindowController <NSWindowDelegate, NSOutlineViewDelegate>
{
    IBOutlet    QueryOutlineView			*outlineView;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSSearchField				*searchFieldName, *searchFieldRefPhysician, *searchFieldID, *searchFieldAN, *searchFieldStudyDescription, *searchFieldComments, *searchInstitutionName, *searchCustomField;
	
    IBOutlet    NSPopUpButton               *dicomFieldsMenu;
                NSArray                     *DICOMFieldsArray;
    
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
    IBOutlet    NSMatrix                    *statusFilterMatrix;
	IBOutlet	NSTabView					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate, *searchBirth;
	IBOutlet	NSTextField					*yearOldBirth;
    IBOutlet	NSPopUpButton				*sendToPopup;
    
    IBOutlet NSView*                        refreshGroup;
	
	int										autoQueryRemainingSecs[ MAXINSTANCE];
	IBOutlet NSTextField					*autoQueryCounter;
	
	BOOL									DatabaseIsEdited;
	IBOutlet NSWindow						*autoRetrieveWindow;
	
	NSMutableString							*pressedKeys;
    NSMutableArray							*resultArray;
    NSMutableArray							*queryFilters;
	
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
    
    NSTimeInterval                          lastTemporaryCFindResultUpdate;
    NSMutableArray                          *temporaryCFindResultArray;
    BOOL                                    firstServerRealtimeResults;
    
    NSMutableArray                          *downloadedStudies;
    
    NSString                                *customDICOMField;
    
    NSMutableArray                          *autoQRInstances;
    int                                     currentAutoQR;
    IBOutlet NSWindow                       *addAutoQRInstanceWindow;
    IBOutlet NSTextField                    *autoQRInstanceName;
    IBOutlet NSSegmentedControl             *autoQRNavigationControl;
    
    IBOutlet SFHorosAuthorizationView       *authView;
    IBOutlet NSButton                       *authButton;
    
    NSMutableSet                            *performingQueryThreads;
}

@property (readonly) NSRecursiveLock *autoQueryLock;
@property (readonly) QueryOutlineView *outlineView;
@property BOOL autoQuery, DatabaseIsEdited;
@property NSInteger autoRefreshQueryResults;
@property (nonatomic) int currentAutoQR;
@property(readonly) SFHorosAuthorizationView* authView;

+ (QueryController*) currentQueryController;
+ (QueryController*) currentAutoQueryController;
+ (NSString*) stringIDForStudy:(id) item;
+ (BOOL) echo: (NSString*) address port:(int) port AET:(NSString*) aet;
+ (BOOL) echoServer:(NSDictionary*)serverParameters;
+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer;
+ (int) queryAndRetrieveAccessionNumber:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors;
+ (void) retrieveStudies:(NSArray*) studies showErrors: (BOOL) showErrors;
+ (void) retrieveStudies:(NSArray*) studies showErrors: (BOOL) showErrors checkForPreviousAutoRetrieve: (BOOL) checkForPreviousAutoRetrieve;
+ (NSMutableArray*) queryStudiesForFilters:(NSDictionary*) filters servers: (NSArray*) serversList showErrors: (BOOL) showErrors;
+ (NSArray*) queryStudiesForPatient:(DicomStudy*) study usePatientID:(BOOL) usePatientID usePatientName:(BOOL) usePatientName usePatientBirthDate: (BOOL) usePatientBirthDate servers: (NSArray*) serversList showErrors: (BOOL) showErrors;
+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer;
+ (NSArray*) queryStudyInstanceUID:(NSString*) an server: (NSDictionary*) aServer showErrors: (BOOL) showErrors;
- (void) autoRetrieveSettings: (id) sender;
- (void) saveSettings;
+ (void) getDateAndTimeQueryFilterWithTag: (int) tag fromDate:(NSDate*) from toDate:(NSDate*) to date: (QueryFilter**) dateQueryFilter time: (QueryFilter**) timeQueryFilter;
- (void) applyPresetDictionary: (NSDictionary *) presets;
- (void) emptyPreset:(id) sender;
- (NSMutableDictionary*) savePresetInDictionaryWithDICOMNodes: (BOOL) includeDICOMNodes;
- (id) initAutoQuery: (BOOL) autoQuery;
- (IBAction) cancel:(id)sender;
- (IBAction) ok:sender;
- (void) refreshAutoQR: (id) sender;
- (void) refreshList: (NSArray*) l;
- (void) setCurrentAutoQR: (int) index;
- (BOOL) queryWithDisplayingErrors:(BOOL) showError;
- (BOOL) queryWithDisplayingErrors:(BOOL) showError instance: (NSMutableDictionary*) instance index: (int) index;
- (IBAction) selectUniqueSource:(id) sender;
- (QueryFilter*) getModalityQueryFilter:(NSArray*) modalityArray;
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
- (void) refresh: (id) sender;
- (IBAction) pressButtons:(id) sender;
- (NSArray*) localSeries:(id) item;
- (NSArray*) localStudy:(id) item;
- (NSArray*) localSeries:(id) item context: (NSManagedObjectContext*) context;
- (NSArray*) localStudy:(id) item context: (NSManagedObjectContext*) context;
- (IBAction) endAddPreset:(id) sender;
- (void) buildPresetsMenu;
- (IBAction) autoQueryTimer:(id) sender;
- (IBAction) switchAutoRetrieving: (id) sender;
- (IBAction) selectModality: (id) sender;
- (void) displayAndRetrieveQueryResults: (NSDictionary*) instance;
- (void) autoQueryThread:(NSDictionary*) d;
- (void) autoQueryTimerFunction:(NSTimer*) t;
- (void) executeRefresh: (id) sender;
- (void)view:(NSView*)view recursiveBindEnableToObject:(id)obj withKeyPath:(NSString*)keyPath;
@end
