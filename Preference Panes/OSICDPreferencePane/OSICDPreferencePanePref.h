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

@interface OSICDPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSWindow *mainWindow;
}

- (IBAction)chooseSupplementaryBurnPath:(id)sender;

@end
