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

#import <Cocoa/Cocoa.h>

#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "RWTokenField.h"

@class OSICustomImageAnnotations;

@interface CIALayoutController : NSWindowController <NSTokenFieldDelegate>
{
	OSICustomImageAnnotations *prefPane;
	
	CIALayoutView *layoutView;
		
	NSMutableArray *annotationsArray;
	CIAAnnotation *selectedAnnotation;
	
	NSMutableArray *DICOMFieldsArray;
	NSMutableArray *databaseStudyFieldsArray, *databaseSeriesFieldsArray, *databaseImageFieldsArray;
	
	int annotationNumber;
	
	NSMutableDictionary *annotationsLayoutDictionary;
	NSString *currentModality;
	
	BOOL skipTextViewDidChangeSelectionNotification;
}

- (IBAction)addAnnotation:(id)sender;
- (IBAction)removeAnnotation:(id)sender;
- (IBAction)setTitle:(id)sender;
- (void)highlightPlaceHolderForAnnotation:(CIAAnnotation*)anAnnotation;
- (void)selectAnnotation:(CIAAnnotation*)anAnnotation;
- (CIAAnnotation*)selectedAnnotation;

- (void)resizeTokenField;
- (IBAction)addFieldToken:(id)sender;
- (IBAction)validateTokenTextField:(id)sender;

- (void)prepareDatabaseFields;
- (NSMutableArray*)specialFieldsTitles;
- (NSMutableArray*)specialFieldsLocalizedTitles;
- (void)setCustomDICOMFieldEditingEnable:(BOOL)boo;

- (BOOL)checkAnnotations;
- (BOOL)checkAnnotationContent:(CIAAnnotation*)annotation;
- (void)saveAnnotationLayout;
- (void)saveAnnotationLayoutForModality:(NSString*)modality;

- (IBAction)switchModality:(id)sender;
- (IBAction)switchModality:(id)sender save:(BOOL) save;
- (void)loadAnnotationLayoutForModality:(NSString*)modality;
- (void)removeAllAnnotations;

- (void)setLayoutView:(CIALayoutView*)view;
- (void)setPrefPane:(OSICustomImageAnnotations*)aPrefPane;

- (void)setOrientationWidgetEnabled:(BOOL)enabled;

- (void)reloadLayoutDictionary;
- (BOOL)checkAnnotationsContent;
- (NSDictionary*) curDictionary;
- (NSMutableDictionary*) annotationsLayoutDictionary;
- (NSString*) currentModality;
@end
