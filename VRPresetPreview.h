/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>
#import "VRView.h"
#import "SelectionView.h"

@interface VRPresetPreview : VRView {
	BOOL isEmpty, isSelected;
	IBOutlet SelectionView	*selectionView;
	
	IBOutlet VRController	*presetController;
	int presetIndex;
}

- (void)setIsEmpty:(BOOL)empty;
- (BOOL)isEmpty;
- (void)setSelected;
- (void)setIndex:(int)index;
- (int)index;

@end
