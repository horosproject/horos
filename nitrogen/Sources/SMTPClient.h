//
//  SMTPClient.h
//
//  Created by Alessandro Volz on 08.06.11.
//  Copyright 2011 Alessandro Volz. All rights reserved.
//  

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
