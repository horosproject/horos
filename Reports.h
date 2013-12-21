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

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/** \brief reports */
@interface Reports : NSObject
{
	NSMutableString *templateName;
}

+ (NSString*) getUniqueFilename:(id) study;
+ (NSString*) getOldUniqueFilename:(NSManagedObject*) study;

- (BOOL)createNewReport:(NSManagedObject*)study destination:(NSString*)path type:(int)type;

+(NSString*)databaseWordTemplatesDirPath;
+(NSString*)resolvedDatabaseWordTemplatesDirPath;

- (void)searchAndReplaceFieldsFromStudy:(NSManagedObject*)aStudy inString:(NSMutableString*)aString;
- (BOOL) createNewPagesReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
- (BOOL) createNewOpenDocumentReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
+ (NSMutableArray*)pagesTemplatesList;
+ (NSMutableArray*)wordTemplatesList;
- (NSMutableString *)templateName;
- (void)setTemplateName:(NSString *)aName;
+ (int) Pages5orHigher;
+ (void)checkForPagesTemplate;
+ (void)checkForWordTemplates;

@end
