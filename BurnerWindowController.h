/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Cocoa/Cocoa.h>

@class DRTrack;
/** \brief Window Controller for DICOM disk burning */
@interface BurnerWindowController : NSWindowController
{
	volatile BOOL burning, isIrisAnimation;
	NSMutableArray *nodeArray;
	NSMutableArray *files, *anonymizedFiles, *dbObjects, *originalDbObjects;
	float burnSize;
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *sizeField, *finalSizeField;
	IBOutlet NSMatrix	 *compressionMode;
	IBOutlet NSButton *burnButton;
	IBOutlet NSButton *anonymizedCheckButton;
	NSString *cdName;
	NSString *folderSize;
	NSTimer *burnAnimationTimer;
	int burnAnimationIndex;
	volatile BOOL runBurnAnimation;
	volatile BOOL isExtracting;
	volatile BOOL isSettingUpBurn;
	volatile BOOL isThrobbing;
	NSArray *filesToBurn;
	BOOL _multiplePatients;
	BOOL writeDMG;
	int sizeInMb;
	NSString *password;
	IBOutlet NSWindow *passwordWindow;
	
	BOOL buttonsDisabled;
	BOOL burnSuppFolder, burnOsiriX, burnHtml;
}

@property BOOL buttonsDisabled;
@property (retain) NSString *password;

- (IBAction) ok:(id)sender;
- (IBAction) cancel:(id)sender;

- (IBAction) setAnonymizedCheck: (id) sender;
- (id) initWithFiles:(NSArray *)theFiles;
- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects;
- (DRTrack*) createTrack;
-(IBAction)burn:(id)sender;
- (void)setCDTitle: (NSString *)title;
-(IBAction)setCDName:(id)sender;
-(NSString *)folderToBurn;
- (void)setFilesToBurn:(NSArray *)theFiles;
- (void)burnCD:(id)object;
- (NSArray *)extractFileNames:(NSArray *)filenames;
- (BOOL)dicomCheck:(NSString *)filename;
- (void)importFiles:(NSArray *)fileNames;
- (void)setup:(id)sender;
- (void)addDICOMDIRUsingDCMTK;
- (void)addDicomdir;
- (void)estimateFolderSize:(id)object;
- (void)performBurn:(id)object;
//- (void)reloadData:(id)object;
- (void)irisAnimation:(id)object;
- (void)throbAnimation:(id)object;
- (NSNumber*)getSizeOfDirectory:(NSString*)path;
- (NSString*) defaultTitle;
- (IBAction) estimateFolderSize: (id) sender;
@end
