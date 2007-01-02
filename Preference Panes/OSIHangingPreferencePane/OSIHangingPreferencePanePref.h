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

@interface OSIHangingPreferencePanePref : NSPreferencePane 
{
	NSMutableDictionary *hangingProtocols;
	IBOutlet NSTableView *hangingProtocolTableView;
	IBOutlet NSButton *newHangingProtocolButton;
	NSString *modalityForHangingProtocols;
	IBOutlet NSArrayController		*bodyRegionController;
	BOOL _controlsAuthorized;
	IBOutlet SFAuthorizationView			*_authView;
}

- (void) mainViewDidLoad;
- (void) deleteSelectedRow:(id)sender;
- (IBAction)setModalityForHangingProtocols:(id)sender;
- (IBAction)newHangingProtocol:(id)sender;
- (BOOL)controlsAuthorized;
- (void)setControlsAuthorized:(BOOL)authorized;


@end
