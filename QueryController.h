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




#import <AppKit/AppKit.h>

//@class DICOMQueryStudyRoot;
@class QueryArrayController;
@class QueryFilter;
@interface QueryController : NSWindowController {

    IBOutlet    NSOutlineView				*outlineView;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSSearchField				*searchFieldName, *searchFieldID;
	IBOutlet	NSWindow					*advancedQueryWindow;   
	IBOutlet	NSBox						*filterBox;
	
	IBOutlet	NSComboBox					*servers;
	IBOutlet	NSMatrix					*dateFilterMatrix;
	IBOutlet	NSMatrix					*modalityFilterMatrix;
	IBOutlet	NSTabView					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate, *searchBirth;
    
	NSMutableString					*pressedKeys;
    NSMutableArray                  *result;
    NSMutableArray					*queryFilters;
	NSMutableArray					*advancedQuerySubviews;
	QueryFilter						*dateQueryFilter, *modalityQueryFilter;
	NSString						*currentQueryKey;
	BOOL							echoSuccess;
	NSMutableDictionary				*activeMoves;
	
	//DICOMQueryStudyRoot
	QueryArrayController *queryManager;
}

- (void) queryPatientID:(NSString*) ID;
-(void) query:(id)sender;
-(void) advancedQuery:(id)sender;
-(void) retrieve:(id)sender;
- (void)performQuery:(id)object;
- (void)performRetrieve:(NSArray*) array;
- (void)setDateQuery:(id)sender;
- (void)setModalityQuery:(id)sender;
- (void)openAdvancedQuery:(id)sender;
- (void)clearQuery:(id)sender;

- (void)addQuerySubview:(id)sender;
- (void)removeQuerySubview:(id)sender;
- (void)chooseFilter:(id)sender;
- (void)drawQuerySubviews;
- (void)updateRemoveButtons;
- (BOOL)dicomEcho;
- (IBAction)verify:(id)sender;
- (IBAction)abort:(id)sender;
- (IBAction)controlAction:(id)sender;
- (void) refresh: (id) sender;
- (NSArray *)serversList;

@end
