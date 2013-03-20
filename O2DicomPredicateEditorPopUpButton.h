//
//  O2DicomPredicateEditorPopUpButtonCell.h
//  Predicator
//
//  Created by Alessandro Volz on 13.12.12.
//  Copyright (c) 2012 Alessandro Volz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface O2DicomPredicateEditorPopUpButton : NSPopUpButton {
    NSMenu* _contextualMenu;
	NSString* _noSelectionLabel;
    NSWindow* _menuWindow;
    BOOL _n2mode;
}

@property(retain) NSMenu* contextualMenu;
@property(retain,nonatomic) NSString* noSelectionLabel;
@property BOOL n2mode;

@end
