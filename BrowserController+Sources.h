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

#import "browserController.h"

@class BrowserSourceIdentifier, DicomDatabase;

@interface BrowserController (Sources)

-(void)awakeSources;
-(void)deallocSources;

-(void)redrawSources;

-(BrowserSourceIdentifier*)sourceIdentifierAtRow:(int)row;
-(int)rowForDatabase:(DicomDatabase*)database;
-(BrowserSourceIdentifier*)sourceIdentifierForDatabase:(DicomDatabase*)database;
-(void)selectCurrentDatabaseSource;

-(long)currentBonjourService __deprecated;
-(void)setCurrentBonjourService:(int)index __deprecated;
-(int)findDBPath:(NSString*)path dbFolder:(NSString*)DBFolderLocation __deprecated;

@end
