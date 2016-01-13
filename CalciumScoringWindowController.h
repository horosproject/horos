/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/

/*************************************************************
Manages the Window for creating Calcium Scoring ROIs
***************************************************************/

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"

@class ViewerController;

/** \brief Manages the Window for creating Calcium Scoring ROIs*/

@interface CalciumScoringWindowController : NSWindowController <NSWindowDelegate>
{
	ViewerController		*_viewer, *_resultsViewer;
	int						_ctType;
	int						_lowerThreshold;
	int						_upperThreshold;
	NSMutableSet			*_rois;
	NSString				*_roiName;
	
	NSString				*_startingPointPixelPosition;
	NSString				*_startingPointWorldPosition;
	NSString				*_startingPointValue;
	
	NSPoint					_startingPoint;
	
	float					_totalCalciumScore;
	float					_totalCalciumMass;
	float					_totalCalciumVolume;
		
	NSArray					*_vessels;
	NSArray					*_vesselNames;
	
	IBOutlet	NSView		*_printView;
}

- (int)ctType;
- (void)setCtType:(int)ctType;
- (int)lowerThreshold;
- (void)setLowerThreshold:(int)lowerThreshold;
- (int)upperThreshold;
- (void)setUpperThreshold:(int)upperThreshold;
- (NSMutableSet *)rois;
- (void)setRois:(NSMutableSet *)rois;
- (NSString *)roiName;
- (void)setRoiName:(NSString *)roiName;
- (id)initWithViewer:(ViewerController *)viewer;

-(NSString *)startingPointPixelPosition;
- (void)setStartingPointPixelPosition:(NSString *)position;
-(NSString *)startingPointWorldPosition;
- (void)setStartingPointWorldPosition:(NSString *)position;
-(NSString *)startingPointValue;
- (void)setStartingPointValue:(NSString *)value;

- (IBAction)preview: (id)sender;
- (IBAction)compute: (id)sender;
- (IBAction)saveDocument: (id)sender;
- (void)print:(id)sender;
- (void)computeROIsWithName:(NSString *)name addROIs:(BOOL)addROIs;

- (void)updateTotals;

- (float)totalCalciumScore;
- (float)totalCalciumMass;
- (float)totalCalciumVolume;

- (void)setTotalCalciumScore: (float)score;
- (void)setTotalCalciumMass: (float)mass;
- (void)setTotalCalciumVolume: (float)volume;

- (NSArray *)vessels;
- (void)setVessels:(NSArray *)vessels;

- (NSArray *)vesselNames;
- (void)setVesselNames:(NSArray *)name;

- (NSString *)institution;
- (NSString *)patientID;
- (NSDate *)studyDate;
- (NSString *)patientsName;
- (NSString *)patientsSex;
- (NSString *)patientsAge;
- (NSDate *)patientsDOB;






@end
