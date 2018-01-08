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
