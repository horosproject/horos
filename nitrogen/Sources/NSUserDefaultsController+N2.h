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


@interface NSUserDefaultsController (N2)

-(NSString*)stringForKey:(NSString*)defaultName;
-(NSArray*)arrayForKey:(NSString*)defaultName;
-(NSDictionary*)dictionaryForKey:(NSString*)defaultName;
-(NSData*)dataForKey:(NSString*)defaultName;
//-(NSArray*)stringArrayForKey:(NSString*)defaultName;
-(NSInteger)integerForKey:(NSString*)defaultName;
-(float)floatForKey:(NSString*)defaultName;
-(double)doubleForKey:(NSString*)defaultName;
-(BOOL)boolForKey:(NSString*)defaultName;

@end


@interface NSObject (DiscPublishing)

// we often need to compose the string constants declared earlier in this file with a values key path - these functions/methods make that easier
extern NSString* valuesKeyPath(NSString* key);
-(id)valueForValuesKey:(NSString*)keyPath;
-(void)setValue:(id)value forValuesKey:(NSString*)keyPath;
-(void)bind:(NSString*)binding toObject:(id)observable withValuesKey:(NSString*)key options:(NSDictionary*)options;
-(void)addObserver:(NSObject*)observer forValuesKey:(NSString*)key options:(NSKeyValueObservingOptions)options context:(void*)context;
-(void)removeObserver:(NSObject*)observer forValuesKey:(NSString*)key;

@end;

