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

//#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>

#import "CIALayoutController.h"
#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "RWTokenField.h"

@class CIALayoutController;

@interface OSICustomImageAnnotations : NSPreferencePane {
	
	CIALayoutController *layoutController;
	IBOutlet NSWindow *window;
	IBOutlet NSPopUpButton *modalitiesPopUpButton;
	IBOutlet NSButton *sameAsDefaultButton, *resetDefaultButton;
	
	IBOutlet NSButton *orientationWidgetButton;
	
	IBOutlet NSButton *addAnnotationButton, *removeAnnotationButton;
	
	IBOutlet NSSegmentedControl *loadsaveButton;
	
	IBOutlet CIALayoutView *layoutView;
	IBOutlet NSTextField *titleLabelTextField, *titleTextField, *contentLabeltextField;
	IBOutlet NSTokenField *contentTokenField;
//	IBOutlet NSTokenField *dicomNameTokenField;
	IBOutlet NSTextField *dicomGroupTextField, *dicomElementTextField, *dicomNameTokenField;
	IBOutlet NSTextField *groupLabel, *elementLabel, *nameLabel;
	IBOutlet NSButton *addCustomDICOMFieldButton, *addDICOMFieldButton, *addDatabaseFieldButton, *addSpecialFieldButton;
	IBOutlet NSPopUpButton *DICOMFieldsPopUpButton, *databaseFieldsPopUpButton, *specialFieldsPopUpButton;
	IBOutlet NSBox *contentBox;
	IBOutlet NSWindow *mainWindow;
}

- (IBAction)addAnnotation:(id)sender;
- (IBAction)removeAnnotation:(id)sender;
- (IBAction)setTitle:(id)sender;
- (IBAction)addFieldToken:(id)sender;
- (IBAction)validateTokenTextField:(id)sender;
- (IBAction)saveAnnotationLayout:(id)sender;
- (IBAction)switchModality:(id)sender;
- (IBAction)switchModality:(id)sender save:(BOOL) save;
- (IBAction)setSameAsDefault:(id)sender;
- (IBAction)toggleOrientationWidget:(id)sender;
- (IBAction)loadsave:(id)sender;
- (IBAction)reset:(id)sender;

- (CIALayoutController*)layoutController;
- (NSArray*) prepareDICOMFieldsArrays;

- (NSTextField*)titleTextField;
- (NSTokenField*)contentTokenField;
- (NSTextField*)dicomNameTokenField;
- (NSTextField*)dicomGroupTextField;
- (NSTextField*)dicomElementTextField;
- (NSTextField*)groupLabel;
- (NSTextField*)elementLabel;
- (NSTextField*)nameLabel;
- (NSButton*)addCustomDICOMFieldButton;
- (NSButton*)addDICOMFieldButton;
- (NSButton*)addDatabaseFieldButton;
- (NSButton*)addSpecialFieldButton;
- (NSPopUpButton*)DICOMFieldsPopUpButton;
- (NSPopUpButton*)databaseFieldsPopUpButton;
- (NSPopUpButton*)specialFieldsPopUpButton;
- (NSBox*)contentBox;
- (NSButton*)sameAsDefaultButton;
- (NSButton*)resetDefaultButton;
- (NSButton*)orientationWidgetButton;
- (NSPopUpButton*)modalitiesPopUpButton;

@end
