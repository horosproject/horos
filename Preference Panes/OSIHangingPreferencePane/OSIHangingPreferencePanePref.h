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
