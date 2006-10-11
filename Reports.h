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

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface Reports : NSObject
{

	ComponentInstance myComponent;
}

+ (NSString*) getUniqueFilename:(NSManagedObject*) study;

- (NSString*) generateReportSourceData:(NSManagedObject*) study;
- (void) runScript:(NSString *)txt;
- (NSString *) reportScriptBody:(NSManagedObject*) study;
- (BOOL) createNewReport:(NSManagedObject*) study destination:(NSString*) path type:(int) type;

- (void)searchAndReplaceFieldsFromStudy:(NSManagedObject*)aStudy inString:(NSMutableString*)aString;
- (NSString*)generatePagesReportScriptUsingTemplate:(NSString*)aTemplate completeFilePath:(NSString*)aFilePath;
- (BOOL)createNewPagesReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;

@end
