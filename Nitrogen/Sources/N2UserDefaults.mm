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

#import "N2UserDefaults.h"


@implementation N2UserDefaults
@synthesize identifier = _identifier, autosave = _autosave;

+(N2UserDefaults*)defaultsForObject:(id)o {
	return [self defaultsForClass:[o class]];
}

+(N2UserDefaults*)defaultsForClass:(Class)c {
	return [self defaultsForIdentifier:[[NSBundle bundleForClass:c] bundleIdentifier]];
}

+(N2UserDefaults*)defaultsForIdentifier:(NSString*)identifier {
	static NSMutableDictionary* Defaults = [[NSMutableDictionary alloc] initWithCapacity:4];

	N2UserDefaults* defaults = [Defaults objectForKey:identifier];
	if (defaults) return defaults;
	
	defaults = [[N2UserDefaults alloc] initWithIdentifier:identifier];
	[Defaults setObject:defaults forKey:identifier];
	[defaults release];
	return defaults;
}

-(id)initWithIdentifier:(NSString*)identifier {
	self = [super init];
	_identifier = [identifier retain];
	_dictionary = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:identifier] mutableCopy];
	if (!_dictionary) _dictionary = [[NSMutableDictionary alloc] init];
	_needsAutosave = NO;
	[self setAutosave:YES];
	return self;
}

-(void)dealloc {
	[_identifier release];
	[_dictionary release];
	[super dealloc];
}

-(void)save {
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:_dictionary forName:_identifier];
}

-(void)setAutosave:(BOOL)autosave {
	_autosave = autosave;
	if (_autosave && _needsAutosave)
		[self save];
	_needsAutosave = NO;
}

-(id)objectForKey:(NSString*)key {
	return [_dictionary objectForKey:key];
}

-(BOOL)hasObjectForKey:(NSString*)key {
	return [self objectForKey:key] != NULL;
}

-(void)setObject:(id)obj forKey:(NSString*)key {
	[_dictionary setObject:obj forKey:key];
	if (_autosave) [self save];
	else _needsAutosave = YES;
}

-(NSInteger)integerForKey:(NSString*)key default:(NSInteger)def {
	NSNumber* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSNumber class]]) return [value integerValue];
	return def;
}

-(void)setInteger:(NSInteger)value forKey:(NSString*)key {
	[self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

-(float)floatForKey:(NSString*)key default:(float)def {
	NSNumber* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSNumber class]]) return [value floatValue];
	return def;
}

-(void)setFloat:(float)value forKey:(NSString*)key {
	[self setObject:[NSNumber numberWithFloat:value] forKey:key];
}

-(double)doubleForKey:(NSString*)key default:(double)def {
	NSNumber* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSNumber class]]) return [value doubleValue];
	return def;
}

-(void)setDouble:(double)value forKey:(NSString*)key {
	[self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

-(BOOL)boolForKey:(NSString*)key default:(BOOL)def {
	NSNumber* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSNumber class]]) return [value boolValue];
	return def;
}

-(void)setBool:(BOOL)value forKey:(NSString*)key {
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}

-(id)unarchiveObjectForKey:(NSString*)key default:(id)def class:(Class)c {
	NSData* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSData class]]) {
		id unarchivedValue = [NSUnarchiver unarchiveObjectWithData:value];
		if ([unarchivedValue isKindOfClass:c])
			return unarchivedValue;
	} return def;
}

-(void)archiveAndSetObject:(id)value forKey:(NSString*)key {
	[self setObject:[NSArchiver archivedDataWithRootObject:value] forKey:key];
}

-(NSColor*)colorForKey:(NSString*)key default:(NSColor*)def {
	return [self unarchiveObjectForKey:key default:def class:[NSColor class]];
}

-(void)setColor:(NSColor*)value forKey:(NSString*)key {
	[self archiveAndSetObject:value forKey:key];
}

-(NSRect)rectForKey:(NSString*)key default:(NSRect)def {
	NSValue* value = [self objectForKey:key];
	if ([value isKindOfClass:[NSValue class]]) return [value rectValue];
	return def;
}

-(void)setRect:(NSRect)value forKey:(NSString*)key {
	[self setObject:[NSValue valueWithRect:value] forKey:key];
}

@end
