/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <PreferencePanes/PreferencePanes.h>

@class AppController;

@interface OSIViewerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSWindow *mainWindow;
}

- (AppController*) appController;
- (void) mainViewDidLoad;

@end
