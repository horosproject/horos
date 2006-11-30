//
//  OSIHotKeysPref.h
//  OSIHotKeys
//
//  Created by Lance Pysher on 11/28/06.
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

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>


@interface OSIHotKeysPref : NSPreferencePane 
{
	NSArray *_actions;
	IBOutlet SFAuthorizationView *_authView;
	IBOutlet NSTextFieldCell *keyTextFieldCell;
	BOOL _enableControls;
	IBOutlet NSArrayController *arrayController;
}

- (void) mainViewDidLoad;
- (NSArray *)actions;
- (void)setActions:(NSArray *)actions;

- (void) setEnableControls: (BOOL) val;
- (BOOL)enableControls;



@end
