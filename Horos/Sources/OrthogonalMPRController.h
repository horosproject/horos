/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"
#import "OrthogonalReslice.h"
#import "DCMView.h"
@class OrthogonalMPRView;

/** \brief  Controller for Orthogonal MPR */

@interface OrthogonalMPRController : NSObject { //NSWindowController {
	NSMutableArray				*originalDCMPixList, *xReslicedDCMPixList, *yReslicedDCMPixList, *originalDCMFilesList, *originalROIList;
	OrthogonalReslice			*reslicer;
	float						sign;
	
	float						originalCrossPositionX, originalCrossPositionY, xReslicedCrossPositionX, xReslicedCrossPositionY, yReslicedCrossPositionX, yReslicedCrossPositionY;
	long						orientationVector;
    
	IBOutlet OrthogonalMPRView	*originalView, *xReslicedView, *yReslicedView;

	id							viewer;
	NSRect						originalViewFrame, xReslicedViewFrame, yReslicedViewFrame;
	
	short						thickSlabMode, thickSlab;
	
	NSData						*transferFunction;
	
	ViewerController			*viewerController;
}

@property long orientationVector;
 
- (id) initWithPixList: (NSArray*) pixList :(NSArray*) filesList :(NSData*) vData :(ViewerController*) vC :(ViewerController*) bC :(id) newViewer;
- (void) setPixList: (NSArray*)pix :(NSArray*)files :(ViewerController*)vC;

- (void) reslice: (long) x : (long) y : (OrthogonalMPRView*) sender;
- (void) flipVolume;

- (void) ApplyCLUTString:(NSString*) str;
- (void) ApplyOpacityString:(NSString*) str;

- (void) setWLWW:(float) iwl :(float) iww;
- (void) setCurWLWWMenu:(NSString*) str;
- (void) setFusion;

- (short) thickSlabMode;
- (void) setThickSlabMode : (short) newThickSlabMode;
- (short) thickSlab;
- (long) maxThickSlab;
- (float) thickSlabDistance;
- (void) setThickSlab : (short) newThickSlab;

- (void) showViews:(id)sender;
- (void) setTransferFunction:(NSData*) tf;

- (OrthogonalReslice*) reslicer;
- (void)setReslicer:(OrthogonalReslice*)newReslicer;
- (OrthogonalMPRView*) originalView;
- (OrthogonalMPRView*) xReslicedView;
- (OrthogonalMPRView*) yReslicedView;
- (NSMutableArray*) originalDCMFilesList;
- (void) setCrossPosition: (float) x : (float) y : (id) sender;
- (void) setBlendingFactor:(float) f;
- (id) viewer;
- (float) sign;

- (void) notifyPositionChange;
- (void) moveToRelativePosition:(NSArray*) relativeDicomLocation;
- (void) moveToAbsolutePosition:(NSArray*) newDicomLocation;

// Tools Selection
- (void) setCurrentTool:(ToolMode) newTool;
- (int) currentTool;

- (void) saveViewsFrame;
- (void) saveScaleValue;
- (void) displayResliceAxes: (long) boo;
- (void) restoreScaleValue;
- (void) restoreViewsFrame;
- (void) toggleDisplayResliceAxes: (id) sender;
- (void) resetImage;

- (NSMutableArray*) originalDCMPixList;
- (void) scaleToFit : (id) destination;
- (void) scaleToFit;
- (void) setScaleValue:(float) x;
- (void) fullWindowView: (id) sender;
- (void) saveCrossPositions;
- (void) restoreCrossPositions;
- (void) scrollTool: (long) from : (long) to : (id) sender;
- (void) doubleClick:(NSEvent *)event :(id) sender;
-(void) refreshViews;

- (void) blendingPropagateOriginal:(OrthogonalMPRView*) sender;
- (void) blendingPropagateX:(OrthogonalMPRView*) sender;
- (void) blendingPropagateY:(OrthogonalMPRView*) sender;
- (void) blendingPropagate:(OrthogonalMPRView*) sender;

- (void) loadROIonXReslicedView: (long) y;
- (void) loadROIonYReslicedView: (long) x;
- (void) loadROIonReslicedViews: (long) x : (long) y;

- (NSMutableArray*) pointsROIAtX: (long) x;
- (NSMutableArray*) pointsROIAtY: (long) y;

- (NSMenu *)contextualMenu;
- (DCMPix*) firtsDCMPixInOriginalDCMPixList;
- (IBAction) flipVertical: (id)sender;
- (IBAction) flipHorizontal: (id)sender;

@end
