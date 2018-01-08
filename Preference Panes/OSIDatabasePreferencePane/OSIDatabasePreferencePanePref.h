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

#import <PreferencePanes/PreferencePanes.h>

@interface OSIDatabasePreferencePanePref : NSPreferencePane 
{
	IBOutlet NSMatrix		*locationMatrix;
	IBOutlet NSPathControl	*locationPathField;
	IBOutlet NSMatrix		*seriesOrderMatrix;
	IBOutlet NSPopUpButton	*reportsMode;
	
	NSArray					*DICOMFieldsArray;
	IBOutlet NSPopUpButton	*dicomFieldsMenu;
	
	IBOutlet NSMatrix		*commentsDeleteMatrix;
	IBOutlet NSTextField	*commentsDeleteText;
	
	IBOutlet NSTextField	*commentsGroup, *commentsElement;
    
    int currentCommentsAutoFill, currentCommentsField;
	
	// Auto-Cleaning

	IBOutlet NSButton		*older, *deleteOriginal;
	IBOutlet NSMatrix		*olderType;
	IBOutlet NSPopUpButton	*olderThanProduced, *olderThanOpened;
	
	IBOutlet NSWindow *mainWindow;
    
    BOOL newUsePatientIDForUID, newUsePatientBirthDateForUID, newUsePatientNameForUID;
    
    id _tlos;
}

@property (nonatomic) int currentCommentsAutoFill, currentCommentsField;
@property BOOL newUsePatientIDForUID, newUsePatientBirthDateForUID, newUsePatientNameForUID;

- (void) mainViewDidLoad;
- (IBAction)setLocation:(id)sender;
- (IBAction)setLocationURL:(id)sender;
- (IBAction)databaseCleaning:(id)sender;
- (IBAction)setSeriesOrder:(id)sender;
- (IBAction)setAutoComments:(id) sender;
- (IBAction)regenerateAutoComments:(id) sender;
- (IBAction)setReportMode:(id) sender;
- (IBAction) resetDate:(id) sender;
- (IBAction) resetDateOfBirth:(id) sender;
- (IBAction) setDICOMFieldMenu: (id) sender;
- (BOOL)useSeriesDescription;
- (void)setUseSeriesDescription:(BOOL)value;
- (BOOL)splitMultiEchoMR;
- (void)setSplitMultiEchoMR:(BOOL)value;
@end
