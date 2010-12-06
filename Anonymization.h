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


@class DCMAttributeTag, AnonymizationPanelController, AnonymizationSavePanelController;

@interface Anonymization : NSObject

+(DCMAttributeTag*)tagFromString:(NSString*)k;
+(NSArray*)tagsValuesArrayFromDictionary:(NSDictionary*)dic;
+(NSDictionary*)tagsValuesDictionaryFromArray:(NSArray*)arr;
+(NSArray*)tagsArrayFromStringsArray:(NSArray*)strings;

+(AnonymizationPanelController*)showPanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject;
+(AnonymizationSavePanelController*)showSavePanelForDefaultsKey:(NSString*)defaultsKey modalForWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)sel representedObject:(id)representedObject;

+(BOOL)tagsValues:(NSArray*)a1 isEqualTo:(NSArray*)a2;

+(NSDictionary*)anonymizeFiles:(NSArray*)files dicomImages: (NSArray*) dicomImages toPath:(NSString*)dirPath withTags:(NSArray*)intags;

+(NSString*) templateDicomFile;

@end
