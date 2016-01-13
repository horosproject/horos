/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, �version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. �See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. �If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: � OsiriX
 �Copyright (c) OsiriX Team
 �All rights reserved.
 �Distributed under GNU - LGPL
 �
 �See http://www.osirix-viewer.com/copyright.html for details.
 � � This software is distributed WITHOUT ANY WARRANTY; without even
 � � the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 � � PURPOSE.
 ============================================================================*/

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
