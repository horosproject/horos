/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

extern NSString* asciiString (NSString* name);

@interface QTExportHTMLSummary : NSObject {
	NSString *patientsListTemplate, *examsListTemplate, *seriesTemplate; // whole template
	NSDictionary *patientsDictionary;
	NSString *rootPath, *footerString;
}

+(NSString*)nonNilString:(NSString*)aString;

#pragma mark-
#pragma mark HTML template
- (void)readTemplates;
- (NSString*)fillPatientsListTemplates;
- (NSString*)fillStudiesListTemplatesForSeries:(NSArray*) series;
- (NSString*)fillSeriesTemplatesForSeries:(NSManagedObject*)series numberOfImages:(int)imagesCount;

#pragma mark-
#pragma mark HTML file creation
- (void)createHTMLfiles;
- (void)createHTMLPatientsList;
- (void)createHTMLStudiesList;
- (void)createHTMLExtraDirectory;
- (void)createHTMLSeriesPage:(NSManagedObject*)series numberOfImages:(int)imagesCount outPutFileName:(NSString*)fileName;

#pragma mark-
#pragma mark setters
- (void)setPath:(NSString*)path;
- (void)setPatientsDictionary:(NSDictionary*)dictionary;

@end
