//
//  KeyObjectPopupController.mm
//  OsiriX
//
//  Created by Lance Pysher on 7/16/06.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "KeyObjectPopupController.h"
#import "KeyObjectReport.h"
#import "browserController.h"
#import "DicomStudy.h"
#import "DicomImageDCMTKCategory.h"
#import "ViewerController.h"


@implementation KeyObjectPopupController

- (id)initWithViewerController:(ViewerController *)controller popup:(NSPopUpButton *)popupButton{
	if (self = [super init]) {
		//don't retain Viewer. It retains us
		_popupButton = [popupButton retain];
		[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(willPopUp:) name:NSPopUpButtonCellWillPopUpNotification object:[_popupButton cell]];
	}
	return self;
}

- (void)dealloc{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_reports release];
	[_menu release];
	//[_viewerController release];
	[_popupButton release];
	[super dealloc];
}

- (NSArray *)reports{
	return _reports;
}

- (void)setReports:(NSArray *)reports{
	[_reports release];
	_reports = [reports retain];
}

- (NSMenu *)menu{
	return _menu;
}

- (void)setMenu:(NSMenu *)menu{
		[_menu release];
	_reports = [menu retain];
}

- (void)willPopup:(NSNotification *)note{
	//update menu
	NSLog(@"will Popup");
}

@end
