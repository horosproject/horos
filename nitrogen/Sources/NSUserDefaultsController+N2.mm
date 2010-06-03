//
//  NSUserDefaultsController+N2.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/17/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSUserDefaultsController+N2.h"


@implementation NSUserDefaultsController (N2)

-(NSString*)stringForKey:(NSString*)key {
	id obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSString class]]) return NULL;
	return obj;
}

-(NSArray*)arrayForKey:(NSString*)key {
	id obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSArray class]]) return NULL;
	return obj;
}

-(NSDictionary*)dictionaryForKey:(NSString*)key {
	id obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSDictionary class]]) return NULL;
	return obj;
}

-(NSData*)dataForKey:(NSString*)key {
	id obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSData class]]) return NULL;
	return obj;
}

-(NSInteger)integerForKey:(NSString*)key {
	NSNumber* obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSNumber class]]) return 0;
	return [obj integerValue];
}

-(float)floatForKey:(NSString*)key {
	NSNumber* obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSNumber class]]) return 0;
	return [obj floatValue];
}

-(double)doubleForKey:(NSString*)key {
	NSNumber* obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSNumber class]]) return 0;
	return [obj doubleValue];
}

-(BOOL)boolForKey:(NSString*)key {
	NSNumber* obj = [self valueForValuesKey:key];
	if (![obj isKindOfClass:[NSNumber class]]) return NO;
	return [obj boolValue];
}


@end


@implementation NSObject (DiscPublishing)

NSString* valuesKeyPath(NSString* key) {
	return [NSString stringWithFormat:@"values.%@", key];
}

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
	[self removeObserver:observer forKeyPath:valuesKeyPath(key)];
}

@end

