//
//  N2PopUpMenu.h
//  Predicator
//
//  Created by Alessandro Volz on 06.02.13.
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface N2PopUpMenu : NSObject

// when popping up menus using this method, you should make sure the clicked vied forwards mouseup and mousedragged events to the returned NSWindow, as done in O2DicomPredicateEditorPopUpButton.m
+ (NSWindow*)popUpContextMenu:(NSMenu*)menu withEvent:(NSEvent*)event forView:(NSPopUpButton*)view withFont:(NSFont*)font;

@end
