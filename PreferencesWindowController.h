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
#import <PreferencePanes/NSPreferencePane.h>
#import "SFAuthorizationView+OsiriX.h"


@class PreferencesView, PreferencesWindowContext;


/** \brief Window Controller for Preferences */
@interface PreferencesWindowController : NSWindowController
{
	IBOutlet NSScrollView* scrollView;
	IBOutlet PreferencesView* panesListView;
	IBOutlet NSButton* authButton;
	IBOutlet SFAuthorizationView* authView;
	PreferencesWindowContext* currentContext;
	NSMutableArray* animations;
	IBOutlet NSView* flippedDocumentView;
}

@property(readonly) NSMutableArray* animations;
@property(readonly) SFAuthorizationView* authView;

+(void)addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image;

-(BOOL)isUnlocked;

-(IBAction)showAllAction:(id)sender;
-(IBAction)navigationAction:(id)sender;
-(IBAction)authAction:(id)sender;

-(void)reopenDatabase;


@end
