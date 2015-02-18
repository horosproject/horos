/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

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
