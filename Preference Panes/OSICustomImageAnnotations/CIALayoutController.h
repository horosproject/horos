//
//  CIALayoutController.h
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "RWTokenField.h"

@class OSICustomImageAnnotations;

@interface CIALayoutController : NSWindowController
{
	OSICustomImageAnnotations *prefPane;
	
	CIALayoutView *layoutView;
		
	NSMutableArray *annotationsArray;
	CIAAnnotation *selectedAnnotation;
	
	NSMutableArray *DICOMFieldsArray, *DICOMFieldsTitlesArray;
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
- (void)setCustomDICOMFieldEditingEnable:(BOOL)boo;

- (BOOL)checkAnnotations;
- (BOOL)checkAnnotationContent:(CIAAnnotation*)annotation;
- (void)saveAnnotationLayout;
- (void)saveAnnotationLayoutForModality:(NSString*)modality;

- (IBAction)switchModality:(id)sender;
- (void)loadAnnotationLayoutForModality:(NSString*)modality;
- (void)removeAllAnnotations;

- (void)setLayoutView:(CIALayoutView*)view;
- (void)setPrefPane:(OSICustomImageAnnotations*)aPrefPane;

- (void)setOrientationWidgetEnabled:(BOOL)enabled;

- (BOOL)checkAnnotationsContent;
@end