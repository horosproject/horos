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

@interface OSIWebSharingPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSArrayController *studiesArrayController, *userArrayController;
	
	NSString *TLSAuthenticationCertificate;
	IBOutlet NSButton *TLSChooseCertificateButton, *TLSCertificateButton;
}
@property (retain) NSString *TLSAuthenticationCertificate;

- (void) mainViewDidLoad;
- (IBAction) openKeyChainAccess:(id) sender;
- (IBAction) smartAlbumHelpButton: (id) sender;
- (IBAction) chooseTLSCertificate: (id) sender;
- (IBAction) viewTLSCertificate: (id) sender;
- (IBAction) copyMissingCustomizedFiles: (id) sender;

@end
