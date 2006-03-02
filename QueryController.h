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
    IBOutlet    NSTableView					*servers;
	IBOutlet	NSProgressIndicator			*progressIndicator;
	IBOutlet	NSTextField					*statusField;
	IBOutlet	NSSearchField				*searchField;
	IBOutlet	NSTextField					*queryKeyField;
	IBOutlet	NSTextField					*queryDateField;
	IBOutlet	NSWindow					*advancedQueryWindow;   
	IBOutlet	NSBox						*filterBox;
	IBOutlet	NSTextView					*logView;
	IBOutlet	NSTableView					*logTable;
	IBOutlet	NSTableColumn				*statusTableColumn;
	IBOutlet	NSScrollView				*logScrollView;
    
    NSMutableArray                  *result;
    NSMutableArray					*queryFilters;
	NSMutableArray					*advancedQuerySubviews;
	QueryFilter						*dateQueryFilter;
	NSString						*currentQueryKey;
	NSString						*logString;
	BOOL							echoSuccess;
	NSMutableDictionary				*activeMoves;
	NSMutableArray					*moveLog;
	int								currentEchoRow;
	NSImage							*echoImage;

	
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
