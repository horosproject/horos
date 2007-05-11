//
//  VRPresetPreview.h
//  OsiriX
//
//  Created by joris on 08/05/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

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
