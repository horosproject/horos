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

@class ViewerController;

/** \brief  Control for KeyObjectReport popup button*/
@interface KeyObjectPopupController : NSObject {
	NSArray *_reports;
	NSMenu *_menu;
	ViewerController *_viewerController;
	NSPopUpButton *_popupButton;
	id series;
}

- (id)initWithViewerController:(ViewerController *)controller popup:(NSPopUpButton *)popupButton;
- (NSArray *)reports;
- (void)setReports:(NSArray *)reports;
- (NSMenu *)menu;
- (void)setMenu:(NSMenu *)menu;
- (void)willPopUp:(NSNotification *)note;
- (IBAction)useKeyObjectNote:(id)sender;



@end
