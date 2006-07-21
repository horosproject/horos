//
//  QTExportHTMLSummary.h
//  OsiriX
//
//  Created by joris on 17/07/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* asciiString (NSString* name);

@interface QTExportHTMLSummary : NSObject {
	NSString *patientsListTemplate, *examsListTemplate; // whole template
	NSDictionary *patientsDictionary;
	NSString *rootPath, *footerString;
}

+(NSString*)nonNilString:(NSString*)aString;

#pragma mark-
#pragma mark HTML template
- (void)readTemplates;
- (NSString*)fillPatientsListTemplates;
- (NSString*)fillStudiesListTemplatesForSeries:(NSArray*) series;

#pragma mark-
#pragma mark HTML file creation
- (void)createHTMLfiles;
- (void)createHTMLPatientsList;
- (void)createHTMLStudiesList;
- (void)createHTMLExtraDirectory;

#pragma mark-
#pragma mark setters
- (void)setPath:(NSString*)path;
- (void)setPatientsDictionary:(NSDictionary*)dictionary;

@end
