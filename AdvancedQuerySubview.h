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




#import <AppKit/AppKit.h>


@interface AdvancedQuerySubview : NSView {
	IBOutlet NSPopUpButton  *filterKeyPopup;
	IBOutlet NSPopUpButton  *searchTypePopup;
	IBOutlet NSTextField	*valueField;
	IBOutlet NSButton		*addButton;
	IBOutlet NSButton		*removeButton;
	IBOutlet NSPopUpButton  *dateRangePopup;
	IBOutlet NSPopUpButton  *modalityPopup;
	IBOutlet NSDatePicker	*datePicker;

}

- (id) filterKeyPopup;
- (id) searchTypePopup;
- (id) valueField;
- (id) addButton;
- (id) removeButton;
- (id) dateRangePopup;
- (id) modalityPopup;
- (id) datePicker;

- (IBAction) showSearchTypePopup: (id) sender;
- (IBAction) showValueField: (id) sender;
- (IBAction) showModalityPopup: (id) sender;


@end
