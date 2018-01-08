/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
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

#import <Cocoa/Cocoa.h>

enum burnerDestination
{
    CDDVD = 0,
    USBKey = 1,
    DMGFile = 2
};

@class DRTrack;
@class DicomDatabase;

/** \brief Window Controller for DICOM disk burning */
@interface BurnerWindowController : NSWindowController <NSWindowDelegate>
{
	volatile BOOL burning;
	NSMutableArray *files, *anonymizedFiles, *dbObjectsID, *originalDbObjectsID;
	float burnSize;
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *sizeField, *finalSizeField;
	IBOutlet NSMatrix	 *compressionMode;
	IBOutlet NSButton *burnButton;
	IBOutlet NSButton *anonymizedCheckButton;
	NSString *cdName;
	NSTimer *burnAnimationTimer;
	volatile BOOL runBurnAnimation, isExtracting, isSettingUpBurn, isThrobbing, windowWillClose;
	NSArray *filesToBurn;
	BOOL _multiplePatients;
	BOOL cancelled;
    NSString *writeDMGPath, *writeVolumePath;
    NSUInteger selectedUSB;
	NSArray *anonymizationTags;
    int sizeInMb;
	NSString *password;
	IBOutlet NSWindow *passwordWindow;
	
	BOOL buttonsDisabled;
	BOOL burnSuppFolder, burnOsiriX, burnHtml, burnWeasis;
    
	int burnAnimationIndex;
    int irisAnimationIndex;
    NSTimer *irisAnimationTimer;
}

@property BOOL buttonsDisabled;
@property NSUInteger selectedUSB;
@property (retain) NSString *password;

- (NSArray*) volumes;
- (IBAction) ok:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) setAnonymizedCheck: (id) sender;
- (id) initWithFiles:(NSArray *)theFiles;
- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects;
- (IBAction)burn:(id)sender;
- (void)setCDTitle: (NSString *)title;
- (IBAction)setCDName:(id)sender;
- (NSString *)folderToBurn;
- (void)setFilesToBurn:(NSArray *)theFiles;
- (void)burnCD:(id)object;
- (NSArray *)extractFileNames:(NSArray *)filenames;
- (void)importFiles:(NSArray *)fileNames;
- (void)setup:(id)sender;
- (void) prepareCDContent: (NSMutableArray*) dbObjects :(NSMutableArray*) originalDbObjects;
- (IBAction)estimateFolderSize:(id)object;
- (void)performBurn:(id)object;
- (void)irisAnimation:(NSTimer*)object;
- (NSNumber*)getSizeOfDirectory:(NSString*)path;
- (NSString*) defaultTitle;
- (void)saveOnVolume;
@end
