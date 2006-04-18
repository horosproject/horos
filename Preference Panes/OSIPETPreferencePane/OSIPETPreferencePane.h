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


@interface OSIPETPreferencePane : NSPreferencePane 
{
	IBOutlet NSButton						*convertPETtoSUVCheck,
											*preferWonBforPET3D;
}

- (void) mainViewDidLoad;
- (IBAction) setPETCLUTfor3DMIP: (id) sender;
- (IBAction) setConvertPETtoSUVautomatically: (id) sender;
@end
