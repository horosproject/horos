/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <AppKit/AppKit.h>

@class AppController;
@interface PreferenceController : NSWindowController {

    IBOutlet    NSTableView     *tableView, *hangingProtocolTableView;
    IBOutlet    NSForm          *form;
    IBOutlet    NSButton        *ListenerOnOff, *DcmTkJpegOnOff, *tickSoundOnOff, *characterSetPopup, *PatientNameOnOff;
	IBOutlet    NSButton        *CheckUpdatesOnOff, *MountOnOff, *UnmountOnOff, *CheckSaveLoadROI, *LocalizerOnOff,  *TransitionOnOff, *newHangingProtocolButton;
	IBOutlet    NSMatrix        *TransferOptions, *stillMovieOptions;
	IBOutlet    NSButton        *CopyDatabaseOnOff;
	IBOutlet    NSMatrix        *CopyDatabaseMode, *dicomInDatabase;
	IBOutlet    NSMatrix        *TextureMatrix, *SizeMatrix;
	IBOutlet    NSMatrix        *DICOMDIRMode;
	IBOutlet    NSPopUpButton   *TransitionType;
	IBOutlet	NSMatrix		*Location, *storageMatrix;
	IBOutlet	NSTextField		*LocationURL;
	IBOutlet	NSBox			*transferSyntaxBox;
	IBOutlet	NSMatrix		*DeleteFileMode;
	
	NSString	*previousPath;
	AppController *sharedAppController;
	//NSMutableDictionary *hangingProtocols;
	NSString *modalityForHangingProtocols;
}

- (void) newServer:(id)sender;
- (void) switchAction:(id) sender;
- (IBAction) chooseURL:(id) sender;
- (IBAction)setModalityForHangingProtocols:(id)sender;
- (IBAction)newHangingProtocol:(id)sender;
- (IBAction)setStorageTool:(id)sender;

@end
