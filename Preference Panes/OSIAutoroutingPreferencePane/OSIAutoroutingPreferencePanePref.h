/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

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
    IBOutlet NSDatePicker* delayTime;
    IBOutlet NSDatePicker* startTime;
    IBOutlet NSDatePicker* endTime;
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
