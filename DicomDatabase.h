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

#import "N2ManagedDatabase.h"

/*
 This class currently only does 1/1000 of what it is planned to do later.
 This will be a BrowserController's backbone.
 */
@interface DicomDatabase : N2ManagedDatabase {
}

+(DicomDatabase*)defaultDatabase;

extern const NSString* const DicomDatabaseImageEntityName;
extern const NSString* const DicomDatabaseSeriesEntityName;
extern const NSString* const DicomDatabaseStudyEntityName;
extern const NSString* const DicomDatabaseAlbumEntityName;
extern const NSString* const DicomDatabaseLogEntryEntityName;

-(NSEntityDescription*)imageEntity;
-(NSEntityDescription*)seriesEntity;
-(NSEntityDescription*)studyEntity;
-(NSEntityDescription*)albumEntity;
-(NSEntityDescription*)logEntryEntity;

-(NSArray*)albums;

+(NSPredicate*)predicateForSmartAlbumFilter:(NSString*)string;

@end
