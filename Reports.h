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
	ComponentInstance myComponent;
	NSMutableString *templateName;
}

+ (NSString*) getUniqueFilename:(id) study;
+ (NSString*) getOldUniqueFilename:(NSManagedObject*) study;

- (NSString*) generateReportSourceData:(NSManagedObject*) study;
- (void) runScript:(NSString *)txt;
- (NSString *) reportScriptBody:(NSManagedObject*) study path:(NSString*) path;
- (BOOL) createNewReport:(NSManagedObject*) study destination:(NSString*) path type:(int) type;

- (void)searchAndReplaceFieldsFromStudy:(NSManagedObject*)aStudy inString:(NSMutableString*)aString;
- (NSString*)generatePagesReportScriptUsingTemplate:(NSString*)aTemplate completeFilePath:(NSString*)aFilePath;
- (BOOL) createNewPagesReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
- (BOOL) createNewOpenDocumentReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
+ (NSMutableArray*)pagesTemplatesList;
- (NSMutableString *)templateName;
- (void)setTemplateName:(NSString *)aName;

@end
