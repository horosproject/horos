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
