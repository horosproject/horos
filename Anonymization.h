//
//  Anonymization.h
//  OsiriX
//
//  Created by Alessandro Volz on 5/17/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

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

+(NSDictionary*)anonymizeFiles:(NSArray*)files toPath:(NSString*)dirPath withTags:(NSArray*)tags;

@end
