/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/


#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import "SFAuthorizationView+OsiriX.h"


@class PreferencesView, PreferencesWindowContext;


/** \brief Window Controller for Preferences */
@interface PreferencesWindowController : NSWindowController <NSWindowDelegate>
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

+ (PreferencesWindowController*) sharedPreferencesWindowController;
+(void) addPluginPaneWithResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle withTitle:(NSString*)title image:(NSImage*)image;
+(void) removePluginPaneWithBundle:(NSBundle*)parentBundle;

-(BOOL)isUnlocked;

-(IBAction)showAllAction:(id)sender;
-(IBAction)navigationAction:(id)sender;
-(IBAction)authAction:(id)sender;

-(void)reopenDatabase;
-(void)setCurrentContextWithResourceName: (NSString*) name;
-(void)setCurrentContext:(PreferencesWindowContext*)context;
@end


@interface PreferencesWindowContext : NSObject {
	NSString* _title;
	NSBundle* _parentBundle;
	NSString* _resourceName;
	NSPreferencePane* _pane;
}

@property(retain) NSString* title;
@property(retain) NSBundle* parentBundle;
@property(retain) NSString* resourceName;
@property(nonatomic, retain) NSPreferencePane* pane;

-(id)initWithTitle:(NSString*)title withResourceNamed:(NSString*)resourceName inBundle:(NSBundle*)parentBundle;

@end
