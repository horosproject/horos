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

extern NSString* const SessionUsernameKey; // NSString
extern NSString* const SessionCookieName;
extern NSString* const SessionLastActivityDateKey; // NSDate
extern NSString* const SessionUserIDKey;

@interface WebPortalSession : NSObject {
@private
	NSMutableDictionary* dict;
	NSString* sid;
	NSLock* dictLock;
}

@property(readonly) NSString* sid;
@property(readonly) NSMutableDictionary* dict;

-(id)initWithId:(NSString*)isid;

-(void)setObject:(id)o forKey:(NSString*)k;
-(id)objectForKey:(NSString*)k;

-(NSString*)createToken;
-(BOOL)consumeToken:(NSString*)token;
-(BOOL)containsToken:(NSString*)token;
-(NSString*)newChallenge;
-(NSString*)challenge;
-(void)deleteChallenge;

@end

