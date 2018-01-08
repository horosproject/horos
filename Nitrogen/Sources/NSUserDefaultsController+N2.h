/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

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

-(void)setString:(NSString*)str forKey:(NSString*)defaultName;
-(void)setArray:(NSArray*)arr forKey:(NSString*)defaultName;
-(void)setDictionary:(NSDictionary*)dic forKey:(NSString*)defaultName;
-(void)setData:(NSData*)dat forKey:(NSString*)defaultName;
//-(void)setStringArray:(NSArray*)arr forKey:(NSString*)defaultName;
-(void)setInteger:(NSInteger)i forKey:(NSString*)defaultName;
-(void)setFloat:(float)f forKey:(NSString*)defaultName;
-(void)setDouble:(double)d forKey:(NSString*)defaultName;
-(void)setBool:(BOOL)flag forKey:(NSString*)defaultName;


@end

CF_EXTERN_C_BEGIN
// we often need to compose the string constants declared earlier in this file with a values key path - these functions/methods make that easier
extern NSString* valuesKeyPath(NSString* key);
CF_EXTERN_C_END
		
@interface NSObject (N2ValuesBinding)

-(id)valueForValuesKey:(NSString*)keyPath;
-(void)setValue:(id)value forValuesKey:(NSString*)keyPath;
-(void)bind:(NSString*)binding toObject:(id)observable withValuesKey:(NSString*)key options:(NSDictionary*)options;
-(void)addObserver:(NSObject*)observer forValuesKey:(NSString*)key options:(NSKeyValueObservingOptions)options context:(void*)context;
-(void)removeObserver:(NSObject*)observer forValuesKey:(NSString*)key;

@end;

