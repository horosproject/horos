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

@interface OSIListenerPreferencePanePref : NSPreferencePane 
{
	IBOutlet NSForm *aeForm;
	IBOutlet NSMatrix *deleteFileModeMatrix;
	IBOutlet NSButton *listenerOnOffButton;
	IBOutlet NSFormCell *aeTitleField;
	IBOutlet NSFormCell *portField;
	IBOutlet NSFormCell *ipField;
	IBOutlet NSFormCell *nameField;
	IBOutlet NSButton *listenerOnOffAnonymize;
	IBOutlet NSButton *generateLogsButton;
	IBOutlet NSButton *decompressButton, *compressButton;
	IBOutlet NSTextField *checkIntervalField;
	IBOutlet NSButton *singleProcessButton;
	IBOutlet NSPopUpButton *logDurationPopup;
	
	IBOutlet SFAuthorizationView *_authView;
}

- (void) mainViewDidLoad;
- (IBAction)setAE:(id)sender;
- (IBAction)setDeleteFileMode:(id)sender;
- (IBAction)setListenerOnOff:(id)sender;
- (IBAction)setAnonymizeListenerOnOff:(id)sender;
- (IBAction)setGenerateLogs:(id)sender;
- (IBAction)helpstorescp:(id) sender;
- (IBAction)setSingleProcess:(id)sender;
- (IBAction)setLogDuration:(id)sender;
- (IBAction)setCheckInterval:(id) sender;
- (IBAction)setDecompress:(id)sender;
- (IBAction)setCompress:(id)sender;
@end
