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
	IBOutlet	NSSearchField				*searchField;
	IBOutlet	NSWindow					*advancedQueryWindow;   
	IBOutlet	NSBox						*filterBox;
	
	IBOutlet	NSComboBox					*servers;
	IBOutlet	NSMatrix					*dateFilterMatrix;
	IBOutlet	NSMatrix					*modalityFilterMatrix;
	IBOutlet	NSMatrix					*PatientModeMatrix;
	IBOutlet	NSDatePicker				*fromDate, *toDate;
    
    NSMutableArray                  *result;
    NSMutableArray					*queryFilters;
	NSMutableArray					*advancedQuerySubviews;
	QueryFilter						*dateQueryFilter;
	NSString						*currentQueryKey;
	NSString						*logString;
	BOOL							echoSuccess;
	NSMutableDictionary				*activeMoves;
	
	//DICOMQueryStudyRoot
	QueryArrayController *queryManager;
}

-(void) query:(id)sender;
-(void) advancedQuery:(id)sender;
-(void) retrieve:(id)sender;
- (void)performQuery:(id)object;
- (void)performRetrieve:(id)object;
- (void)setCurrentQueryKey:(id)sender;
- (void)setDateQuery:(id)sender;
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

- (NSArray *)serversList;

@end
