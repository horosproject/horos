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
#import "DNDArrayController.h"

@interface OSILocationsPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSPopUpButton			*characterSetPopup;
	IBOutlet NSButton				*addServerDICOM, *addServerSharing, *searchDICOMBonjourNodes, *verifyPing, *addLocalPath, *loadNodes;
	NSString						*stringEncoding;
	IBOutlet NSProgressIndicator	*progress;
	
	IBOutlet DNDArrayController		*localPaths, *osiriXServers, *dicomNodes;
	
	IBOutlet SFAuthorizationView	*_authView;
}

- (void) mainViewDidLoad;
- (IBAction) newServer:(id)sender;
- (IBAction) osirixNewServer:(id)sender;
- (IBAction) setStringEncoding:(id)sender;
- (IBAction)setTransferSyntax:(id)sender;
- (IBAction) test:(id) sender;
- (void) resetTest;
- (IBAction) saveAs:(id) sender;
- (IBAction) loadFrom:(id) sender;
- (IBAction) addPath:(id) sender;

@end
