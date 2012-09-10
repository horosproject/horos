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

@interface OSIGeneralPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSWindow *compressionSettingsWindow;
	NSArray *compressionSettingsCopy, *compressionSettingsLowResCopy;
	IBOutlet NSWindow *mainWindow;
    NSMutableArray *languages;
}

@property (retain) NSMutableArray *languages;

- (IBAction) editCompressionSettings:(id) sender;
- (IBAction) endEditCompressionSettings:(id) sender;
- (IBAction) resetPreferences: (id) sender;
+ (void) applyLanguagesIfNeeded;
@end
