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


#import "NSUserDefaultsController+N2.h"
#import "N2Debug.h"

@implementation NSUserDefaultsController (N2)

-(NSString*)stringForKey:(NSString*)key {
	id obj = [self.values valueForKey:key];
	if (![obj isKindOfClass:[NSString class]]) return NULL;
	return obj;
}

-(NSArray*)arrayForKey:(NSString*)key {
	id obj = [self.values valueForKey:key];
	if (![obj isKindOfClass:[NSArray class]]) return NULL;
	return obj;
}

-(NSDictionary*)dictionaryForKey:(NSString*)key {
	id obj = [self.values valueForKey:key];
	if (![obj isKindOfClass:[NSDictionary class]]) return NULL;
	return obj;
}

-(NSData*)dataForKey:(NSString*)key {
	id obj = [self.values valueForKey:key];
	if (![obj isKindOfClass:[NSData class]]) return NULL;
	return obj;
}

-(NSInteger)integerForKey:(NSString*)key {
	NSNumber* obj = [self.values valueForKey:key];
	if (![obj respondsToSelector:@selector(integerValue)]) return 0;
	return [obj integerValue];
}

-(float)floatForKey:(NSString*)key {
	NSNumber* obj = [self.values valueForKey:key];
	if (![obj respondsToSelector:@selector(floatValue)]) return 0;
	return [obj floatValue];
}

-(double)doubleForKey:(NSString*)key {
	NSNumber* obj = [self.values valueForKey:key];
	if (![obj respondsToSelector:@selector(doubleValue)]) return 0;
	return [obj doubleValue];
}

-(BOOL)boolForKey:(NSString*)key {
	NSNumber* obj = [self.values valueForKey:key];
	if (![obj respondsToSelector:@selector(boolValue)]) return NO;
	return [obj boolValue];
}

-(void)setString:(NSString*)value forKey:(NSString*)defaultName {
	if (![value isKindOfClass:[NSString class]])
		[NSException raise:NSInvalidArgumentException format:@"Value must be of class NSString"];
	[self.values setValue:value forKey:defaultName];
}

-(void)setArray:(NSArray*)value forKey:(NSString*)defaultName {
	if (![value isKindOfClass:[NSArray class]])
		[NSException raise:NSInvalidArgumentException format:@"Value must be of class NSArray"];
	[self.values setValue:value forKey:defaultName];
}

-(void)setDictionary:(NSDictionary*)value forKey:(NSString*)defaultName {
	if (![value isKindOfClass:[NSDictionary class]])
		[NSException raise:NSInvalidArgumentException format:@"Value must be of class NSDictionary"];
	[self.values setValue:value forKey:defaultName];
}

-(void)setData:(NSData*)value forKey:(NSString*)defaultName {
	if (![value isKindOfClass:[NSData class]])
		[NSException raise:NSInvalidArgumentException format:@"Value must be of class NSData"];
	[self.values setValue:value forKey:defaultName];
}

//-(void)setStringArray:(NSArray*)value forKey(NSString*)defaultName 

-(void)setInteger:(NSInteger)value forKey:(NSString*)defaultName {
	[self.values setValue:[NSNumber numberWithInteger:value] forKey:defaultName];
}

-(void)setFloat:(float)value forKey:(NSString*)defaultName {
	[self.values setValue:[NSNumber numberWithFloat:value] forKey:defaultName];
}

-(void)setDouble:(double)value forKey:(NSString*)defaultName {
	[self.values setValue:[NSNumber numberWithDouble:value] forKey:defaultName];
}

-(void)setBool:(BOOL)value forKey:(NSString*)defaultName {
	[self.values setValue:[NSNumber numberWithBool:value] forKey:defaultName];
}

@end

CF_EXTERN_C_BEGIN

NSString* valuesKeyPath(NSString* key) {
	return [@"values." stringByAppendingString:key];
}

CF_EXTERN_C_END

@implementation NSObject (N2ValuesBinding)

-(id)valueForValuesKey:(NSString*)keyPath {
	return [self valueForKeyPath:valuesKeyPath(keyPath)];
}

-(void)setValue:(id)value forValuesKey:(NSString*)keyPath {
	[self setValue:value forKeyPath:valuesKeyPath(keyPath)];
}

-(void)bind:(NSString*)binding toObject:(id)observable withValuesKey:(NSString*)key options:(NSDictionary*)options {
	[self bind:binding toObject:observable withKeyPath:valuesKeyPath(key) options:options];
}

-(void)addObserver:(NSObject*)observer forValuesKey:(NSString*)key options:(NSKeyValueObservingOptions)options context:(void*)context {
	[self addObserver:observer forKeyPath:valuesKeyPath(key) options:options context:context];
}

-(void)removeObserver:(NSObject*)observer forValuesKey:(NSString*)key {
    
    @try {
        [self removeObserver:observer forKeyPath:valuesKeyPath(key)];
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
}

@end

