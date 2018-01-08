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

#import "OrthogonalMPRController.h"

#import "DCMView.h"

//@class OrthogonalMPRController;

/** \brief View for MPRs
*
* This view displays a cross to show where the 2 orthogonal plane are crossing 
*/

@interface OrthogonalMPRView : DCMView {
	float						crossPositionX, crossPositionY; // coordinate x and Y of the cross
	OrthogonalMPRController		*controller;
	long						displayResliceAxes;
	float						savedScaleValue;
	
	long						thickSlabX, thickSlabY;
	NSString					*curWLWWMenu;
	NSString					*curCLUTMenu;
	NSString					*curOpacityMenu;
}

- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files;
- (void) setPixList: (NSMutableArray*) pix :(NSArray*) files :(NSMutableArray*) rois;
- (NSMutableArray*) pixList;
- (void) setController: (OrthogonalMPRController*) newController;
- (OrthogonalMPRController*) controller;

- (void) convertPixX: (float) x pixY: (float) y toDICOMCoords: (float*) location ;
- (void) getCrossPositionDICOMCoords: (float*) location ;
- (void) setCrossPosition: (float) x : (float) y withNotification:(BOOL) doNotifychange;
- (void) setCrossPosition: (float) x : (float) y;
- (void) setCrossPositionX: (float) x;
- (void) setCrossPositionY: (float) y;
- (float) crossPositionX;
- (float) crossPositionY;

- (void) adjustWLWW:(float) wl :(float) ww;

- (void) subDrawRect: (NSRect) aRect;

- (void) toggleDisplayResliceAxes;

- (void) saveScaleValue;
- (void) restoreScaleValue;
- (void) adjustScaleValue:(float) x;
- (void) displayResliceAxes: (long) boo;
- (void) setThickSlabXY : (long) newThickSlabX : (long) newThickSlabY;
- (void) scrollTool: (long) from : (long) to;

- (void) setCurWLWWMenu:(NSString*) str;
- (NSString*) curWLWWMenu;

- (NSString*) curCLUTMenu;
- (void) setCurCLUTMenu: (NSString*) clut;

- (NSString*) curOpacityMenu;
- (void) setCurOpacityMenu: (NSString*) o;

- (void) setCurRoiList: (NSMutableArray*) rois;

@end
