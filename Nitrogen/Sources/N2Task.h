/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
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
#include <sys/event.h>

NS_ASSUME_NONNULL_BEGIN

@interface N2Task : NSTask {
	NSString* _launchPath;
	NSArray* _arguments;
	pid_t _pid;
	uid_t _uid;
	NSTimeInterval _launchTime;
	NSDictionary* _environment;
	NSString* _currentDirectoryPath;
	id _standardError, _standardInput, _standardOutput;
}

@property (nullable, copy) NSArray<NSString *> *arguments;
@property (copy) NSString* currentDirectoryPath;
@property (nullable, copy) NSDictionary<NSString *, NSString *> *environment;
@property (nullable, copy) NSString *launchPath;
@property (nullable, retain) id standardError;
@property (nullable, retain) id standardInput;
@property (nullable, retain) id standardOutput;

@property (readonly) NSTimeInterval launchTime;
@property (assign) uid_t uid;


//-(void)setEnv:(NSString*)name to:(NSString*)value;

@end

NS_ASSUME_NONNULL_END
