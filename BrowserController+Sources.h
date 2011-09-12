//
//  BrowserController+Sources.h
//  OsiriX
//
//  Created by Alessandro Volz on 06.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "browserController.h"

@class BrowserSource, DicomDatabase;

@interface BrowserController (Sources)

-(void)awakeSources;
-(void)deallocSources;

-(void)redrawSources;

-(BrowserSource*)sourceAtRow:(int)row;
-(int)rowForDatabase:(DicomDatabase*)database;
-(BrowserSource*)sourceForDatabase:(DicomDatabase*)database;
-(void)selectCurrentDatabaseSource;

-(long)currentBonjourService __deprecated;
-(void)setCurrentBonjourService:(int)index __deprecated;
-(int)findDBPath:(NSString*)path dbFolder:(NSString*)DBFolderLocation __deprecated;

@end
