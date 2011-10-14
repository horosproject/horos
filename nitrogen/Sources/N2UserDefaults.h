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
@property(nonatomic) BOOL autosave;

+(N2UserDefaults*)defaultsForObject:(id)o __deprecated;
+(N2UserDefaults*)defaultsForClass:(Class)c __deprecated;
+(N2UserDefaults*)defaultsForIdentifier:(NSString*)identifier __deprecated;

-(id)initWithIdentifier:(NSString*)identifier __deprecated;

-(id)objectForKey:(NSString*)key __deprecated;
-(BOOL)hasObjectForKey:(NSString*)key __deprecated;
-(void)setObject:(id)obj forKey:(NSString*)key __deprecated;

-(id)unarchiveObjectForKey:(NSString*)key default:(id)def class:(Class)c __deprecated;
-(void)archiveAndSetObject:(id)value forKey:(NSString*)key __deprecated;
	
-(NSInteger)integerForKey:(NSString*)key default:(NSInteger)def __deprecated;
-(void)setInteger:(NSInteger)value forKey:(NSString*)key __deprecated;

-(float)floatForKey:(NSString*)key default:(float)def __deprecated;
-(void)setFloat:(float)value forKey:(NSString*)key __deprecated;

-(double)doubleForKey:(NSString*)key default:(double)def __deprecated;
-(void)setDouble:(double)value forKey:(NSString*)key __deprecated;

-(BOOL)boolForKey:(NSString*)key default:(BOOL)def __deprecated;
-(void)setBool:(BOOL)value forKey:(NSString*)key __deprecated;

-(NSColor*)colorForKey:(NSString*)key default:(NSColor*)def __deprecated;
-(void)setColor:(NSColor*)value forKey:(NSString*)key __deprecated;

-(NSRect)rectForKey:(NSString*)key default:(NSRect)def __deprecated;
-(void)setRect:(NSRect)value forKey:(NSString*)key __deprecated;

@end
