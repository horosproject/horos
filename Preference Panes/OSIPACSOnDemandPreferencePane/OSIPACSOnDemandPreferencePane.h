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
#import "sourcesTableView.h"

@interface OSIPACSOnDemandPreferencePane : NSPreferencePane 
{

	IBOutlet NSWindow *mainWindow;
    
    NSMutableArray *sourcesArray;
    IBOutlet sourcesTableView *sourcesTable;
    
    NSMutableArray *smartAlbumsArray;
    IBOutlet NSTableView *smartAlbumsTable;
    
    NSArray *albumDBArray;
    
    IBOutlet NSWindow *smartAlbumsEditWindow;
    IBOutlet NSMatrix *dateMatrix;
    NSMutableArray *smartAlbumModality;
    NSString *smartAlbumFilter;
    int smartAlbumDate;
}

@property (retain) NSMutableArray *smartAlbumsArray, *smartAlbumModality;
@property (retain) NSString *smartAlbumFilter;
@property int smartAlbumDate;

- (void) mainViewDidLoad;
@end
