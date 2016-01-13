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


extern NSString* const SMTPServerAddressKey;
extern NSString* const SMTPServerPortsKey;
extern NSString* const SMTPServerTLSModeKey;
extern NSString* const SMTPFromKey;
extern NSString* const SMTPServerAuthFlagKey;
extern NSString* const SMTPServerAuthUsernameKey;
extern NSString* const SMTPServerAuthPasswordKey;
extern NSString* const SMTPToKey;
extern NSString* const SMTPSubjectKey;
extern NSString* const SMTPMessageKey;

enum {
	SMTPClientTLSModeNone = 0,
	SMTPClientTLSModeTLSIfPossible = 1,
	SMTPClientTLSModeTLSOrClose = 2
};
typedef NSInteger SMTPClientTLSMode;

@interface SMTPClient : NSObject {
	NSString* _address;
	NSArray* _ports;
	SMTPClientTLSMode _tlsMode;
	NSString* _authUsername;
	NSString* _authPassword;
}

@property(readonly,retain) NSString* address;
@property(readonly,retain) NSArray* ports;
@property(readonly,assign) SMTPClientTLSMode tlsMode;
@property(readonly,retain) NSString* username;
@property(readonly,retain) NSString* password;

+(void)send:(NSDictionary*)params;

+(SMTPClient*)clientWithServerAddress:(NSString*)address ports:(NSArray*)ports tlsMode:(SMTPClientTLSMode)tlsMode username:(NSString*)authUsername password:(NSString*)authPassword;

+(void)splitAddress:(NSString*)address intoEmail:(NSString**)email description:(NSString**)desc;

-(id)initWithServerAddress:(NSString*)address ports:(NSArray*)ports tlsMode:(SMTPClientTLSMode)tlsMode username:(NSString*)authUsername password:(NSString*)authPassword;

-(void)sendMessage:(NSString*)message withSubject:(NSString*)subject from:(NSString*)from to:(NSString*)to;
-(void)sendMessage:(NSString*)message withSubject:(NSString*)subject from:(NSString*)from to:(NSString*)to headers:(NSDictionary*)headers;

@end
