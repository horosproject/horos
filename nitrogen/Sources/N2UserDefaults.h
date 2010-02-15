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


@interface N2UserDefaults : NSObject {
	NSMutableDictionary* _dictionary;
	NSString* _identifier;
	BOOL _autosave, _needsAutosave;
}

@property(readonly, retain) NSString* identifier;
@property BOOL autosave;

+(N2UserDefaults*)defaultsForObject:(id)o;
+(N2UserDefaults*)defaultsForClass:(Class)c;
+(N2UserDefaults*)defaultsForIdentifier:(NSString*)identifier;

-(id)initWithIdentifier:(NSString*)identifier;

-(id)objectForKey:(NSString*)key;
-(BOOL)hasObjectForKey:(NSString*)key;
-(void)setObject:(id)obj forKey:(NSString*)key;

-(id)unarchiveObjectForKey:(NSString*)key default:(id)def class:(Class)c;
-(void)archiveAndSetObject:(id)value forKey:(NSString*)key;
	
-(NSInteger)integerForKey:(NSString*)key default:(NSInteger)def;
-(void)setInteger:(NSInteger)value forKey:(NSString*)key;

-(float)floatForKey:(NSString*)key default:(float)def;
-(void)setFloat:(float)value forKey:(NSString*)key;

-(double)doubleForKey:(NSString*)key default:(double)def;
-(void)setDouble:(double)value forKey:(NSString*)key;

-(BOOL)boolForKey:(NSString*)key default:(BOOL)def;
-(void)setBool:(BOOL)value forKey:(NSString*)key;

-(NSColor*)colorForKey:(NSString*)key default:(NSColor*)def;
-(void)setColor:(NSColor*)value forKey:(NSString*)key;

-(NSRect)rectForKey:(NSString*)key default:(NSRect)def;
-(void)setRect:(NSRect)value forKey:(NSString*)key;

@end
