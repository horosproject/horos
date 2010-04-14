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

#import <Cocoa/Cocoa.h>


/** \brief Used for html export for disk burning*/
@interface QTExportHTMLSummary : NSObject
{
	NSString *patientsListTemplate, *examsListTemplate, *seriesTemplate; // whole template
	NSDictionary *patientsDictionary;
	NSMutableDictionary* imagePathsDictionary;
	NSString *rootPath, *footerString;
	int uniqueSeriesID;
	NSDateFormatter	*dateFormat, *timeFormat;
}

@property(retain) NSMutableDictionary* imagePathsDictionary;

+(NSString*)nonNilString:(NSString*)aString;
+ (void) getMovieWidth: (int*) width height: (int*) height imagesArray: (NSArray*) imagesArray;

+(NSString*)kindOfPath:(NSString*)path forSeriesId:(int)seriesId inSeriesPaths:(NSDictionary*)seriesPaths;

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
