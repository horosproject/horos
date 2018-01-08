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

@interface OSIAutoroutingPreferencePanePref : NSPreferencePane <NSTableViewDelegate>
{
	IBOutlet NSWindow					*newRoute;
	IBOutlet NSTableView				*routesTable;
	
	IBOutlet NSTextField				*newName, *addressAndPort, *newFilter, *newDescription;
	IBOutlet NSPopUpButton				*serverPopup;
	
	IBOutlet NSPopUpButton				*previousPopup;
	IBOutlet NSButton					*previousModality;
	IBOutlet NSButton					*previousDescription;
	IBOutlet NSButton					*cfindTest;
	
	IBOutlet NSPopUpButton				*failurePopup;
	
	NSMutableArray						*routesArray;
	NSArray								*serversArray;
	int filterType;
    BOOL imagesOnly;
	
	IBOutlet NSWindow *mainWindow;
    
    
    BOOL deleteAfterTransference;
    
    //Schedule attributes
    
    int scheduleType;
    IBOutlet NSTextField* delayTime;
    IBOutlet NSDatePicker* fromTimePicker;
    IBOutlet NSDatePicker* toTimePicker;
    
    id _tlos;
}

@property int filterType;
@property BOOL imagesOnly;

- (void) mainViewDidLoad;
- (IBAction) endNewRoute:(id) sender;
- (IBAction) newRoute:(id) sender;
- (IBAction) syntaxHelpButtons:(id) sender;
- (void) deleteSelectedRow:(id)sender;
- (IBAction) selectServer:(id) sender;
- (IBAction) selectPrevious:(id) sender;

@property BOOL deleteAfterTransference;

@property int scheduleType;

@end
