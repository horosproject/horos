//
//  WindowLayoutManager.h
//  OsiriX
//
//  Created by Lance Pysher on 12/11/06.

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

/*
The WindowLayoutManager class manages the various placement of the Viewers
primarily by use of hanging proctols and Advanced hanging protocols
and keeps track of the Viewer Related Window Controllers
It is a shared class.
 */

#import <Cocoa/Cocoa.h>

@class OSIWindowController;
//@class LayoutWindowController;
@interface WindowLayoutManager : NSObject
{
//	BOOL					_xFlipped, _yFlipped;  // Dependent on current DCMView settings.
	NSMutableDictionary		*_currentHangingProtocol;
//	NSDictionary			*_advancedHangingProtocol;
//	BOOL					_hangingProtocolInUse;
//	BOOL					_useToolbarPanel;
//	NSMutableArray			*_windowControllers;	<- Major memory leak !
//	NSManagedObject			*_currentStudy;
//	NSArray					*_seriesSets;
//	int						_seriesSetIndex;
//	NSArray					*_relatedStudies;
//	NSMutableDictionary		*_hangingProtocol;
//	LayoutWindowController	*_layoutWindowController;
//	OSIWindowController		*_currentViewer;
	
	int						IMAGEROWS, IMAGECOLUMNS;
}

+ (id)sharedWindowLayoutManager;

#pragma mark-
#pragma mark WindowController registration

//- (void)registerWindowController:(OSIWindowController *)controller;
//- (void)unregisterWindowController:(OSIWindowController *)controller;
//
//
//- (id) findViewerWithNibNamed:(NSString*) nib andPixList:(NSMutableArray*) pixList;
//- (NSArray*)findRelatedViewersForPixList:(NSMutableArray*) pixList;

- (int) IMAGEROWS;
- (int) IMAGECOLUMNS;

#pragma mark-
#pragma mark hanging protocol setters and getters

- (void) setCurrentHangingProtocolForModality: (NSString*) modality description: (NSString*) description;
- (NSDictionary*) currentHangingProtocol;


//#pragma mark-
//#pragma mark Advanced Hanging
//-(BOOL)hangStudy:(id)study;
//- (NSDictionary *)hangingProtocol;
//- (void)setHangingProtocol:(NSMutableDictionary *)hangingProtocol;
//
//
//#pragma mark-
//#pragma mark Moving Through Series Sets
//- (void)nextSeriesSet;
//- (void)previousSeriesSet;
//- (void)hangSet:(NSDictionary *)seriesSet;
//- (BOOL)hangingProtocolInUse;
//
//#pragma mark-
//#pragma mark Subarrays of Window Controllers
//- (NSArray *)viewers2D;
//- (NSArray *)viewers3D;
//- (NSArray *)viewers;
//- (NSArray *)placeholderWindowControllers;
//
//
//#pragma mark-
//#pragma mark Comparisons
//- (NSArray *)relatedStudies;
//- (void)setRelatedStudies:(NSArray *)relatedStudies;
//- (id)comparionStudy;
//- (NSArray *)comparisonStudies;
//- (id)comparisonStudyForModality:(NSString *)modality studyDescription:(NSString *)studyDescription;
//
//#pragma mark-
//#pragma mark Layout Window
//- (IBAction)openLayoutWindow:(id)sender;
//
//- (id)currentStudy;
//- (void)setCurrentStudy:(id)study;
//- (NSArray *)seriesSets;
//- (void)setSeriesSetIndex: (int)seriesSetIndex;
//- (int)seriesSetIndex;
//
//- (NSWindowController	*)currentViewer;









@end
