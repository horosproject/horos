/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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
    
    id _tlos;
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
