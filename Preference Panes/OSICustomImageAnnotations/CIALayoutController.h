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