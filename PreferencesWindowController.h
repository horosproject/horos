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


@class PreferencesView, PreferencesWindowContext;


/** \brief Window Controller for Preferences */
@interface PreferencesWindowController : NSWindowController
{
	IBOutlet NSScrollView* scrollView;
	IBOutlet PreferencesView* panesListView;
	PreferencesWindowContext* currentContext;
	NSMutableArray* animations;
}

@property(readonly) NSMutableArray* animations;

+(void)addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image;

-(IBAction)showAllAction:(id)sender;
-(IBAction)navigationAction:(id)sender;

-(void)reopenDatabase;

@end

@interface NSWindowController (OsiriX)

-(void)synchronizeSizeWithContent;

@end
