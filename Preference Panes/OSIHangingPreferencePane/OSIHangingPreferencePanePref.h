/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import <PreferencePanes/PreferencePanes.h>

@interface OSIHangingPreferencePanePref : NSPreferencePane 
{
	NSMutableDictionary *hangingProtocols;
	NSString *modalityForHangingProtocols;
	IBOutlet NSWindow *mainWindow;
    IBOutlet NSMenu *windowsTilingPopup;
    IBOutlet NSMenu *imageTilingPopup;
    IBOutlet NSMenu *WLWWPopup;
    IBOutlet NSArrayController *arrayController;
    
    IBOutlet NSWindow *addWLWWWindow;
    NSString *WLWWNewName;
    NSNumber *WLnew, *WWnew;
    NSMutableDictionary *currentWLWWProtocol;
}

@property (retain, nonatomic) NSString *modalityForHangingProtocols;
@property (retain) NSString *WLWWNewName;
@property (retain) NSNumber *WLnew, *WWnew;

- (void) mainViewDidLoad;
- (void) deleteSelectedRow:(id)sender;
- (IBAction)newHangingProtocol:(id)sender;


@end
