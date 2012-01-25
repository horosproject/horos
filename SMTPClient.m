//
//  SMTPClient.mm
//
//  Created by Alessandro Volz on 08.06.11.
//  Copyright 2011 Alessandro Volz. All rights reserved.
//

#import "SMTPClient.h"
#import <iconv.h>
#include <CommonCrypto/CommonDigest.h>

NSString* const SMTPServerAddressKey = @"SMTPServerAddress";
NSString* const SMTPServerPortsKey = @"SMTPServerPorts";
NSString* const SMTPServerTLSModeKey = @"SMTPServerTLSMode";
NSString* const SMTPFromKey = @"SMTPFrom";
NSString* const SMTPServerAuthFlagKey = @"SMTPServerAuthFlag";
NSString* const SMTPServerAuthUsernameKey = @"SMTPServerAuthUsername";
NSString* const SMTPServerAuthPasswordKey = @"SMTPServerAuthPassword";
NSString* const SMTPToKey = @"SMTPTo";
NSString* const SMTPSubjectKey = @"SMTPSubject";
NSString* const SMTPMessageKey = @"SMTPMessage";

@interface SMTPClient ()

@property(readwrite,retain) NSString* address;
@property(readwrite,retain) NSArray* ports;
@property(readwrite,assign) SMTPClientTLSMode tlsMode;
@property(readwrite,retain) NSString* username;
@property(readwrite,retain) NSString* password;

@end

@interface _SMTPConnector : NSConnection<NSStreamDelegate> {
    // setup
    SMTPClient* _client;
    NSString* _message;
	NSString* _subject;
	NSString* _from;
	NSString* _fromDescription;
	NSArray* _to;
    // connection
	NSInputStream* _istream;
    NSOutputStream* _ostream;
    NSUInteger _handleOpenCompleted;
    NSInteger _connectionStatus;
    NSMutableData* _ibuffer;
    NSMutableData* _obuffer;
    BOOL _isTLS;
    // smtp
	NSInteger _smtpStatus;
	NSInteger _smtpSubstatus;
	NSArray* _authModes;
	NSTimer* _dataTimeoutTimer;
    NSTimer* _openTimeoutTimer;
	NSInteger _rcptToCount;
	BOOL _canStartTLS;
    BOOL _success;
}

@property(retain) SMTPClient* client;
@property(retain) NSString* message;
@property(retain) NSString* subject;
@property(retain) NSString* from;
@property(retain) NSString* fromDescription;
@property(retain) NSArray* to;

-(void)start;

@end

@interface NSDictionary (SMTP)

-(id)objectForKey:(id)key ofClass:(Class)cl;    

@end

@interface NSData (SMTP)

-(NSData*)md5;
-(NSString*)hex;
-(NSString*)base64;
+(NSData*)dataWithBase64:(NSString*)base64;
-(NSData*)initWithBase64:(NSString*)base64;

@end

@implementation SMTPClient

@synthesize address = _address;
@synthesize ports = _ports;
@synthesize tlsMode = _tlsMode;
@synthesize username = _authUsername;
@synthesize password = _authPassword;

+(void)send:(NSDictionary*)params {
	NSString* serverAddress = [params objectForKey:SMTPServerAddressKey ofClass:NSString.class];
	NSArray* serverPorts = [params objectForKey:SMTPServerPortsKey ofClass:NSArray.class];
	NSNumber* serverTlsMode = [params objectForKey:SMTPServerTLSModeKey ofClass:NSNumber.class];
	NSNumber* serverAuthFlag = [params objectForKey:SMTPServerAuthFlagKey ofClass:NSNumber.class];
	NSString* serverUsername = [params objectForKey:SMTPServerAuthUsernameKey ofClass:NSString.class];
	NSString* serverPassword = [params objectForKey:SMTPServerAuthPasswordKey ofClass:NSString.class];
	NSString* from = [params objectForKey:SMTPFromKey ofClass:NSString.class];
	NSString* to = [params objectForKey:SMTPToKey ofClass:NSString.class];
	NSString* subject = [params objectForKey:SMTPSubjectKey ofClass:NSString.class];
	NSString* message = [params objectForKey:SMTPMessageKey ofClass:NSString.class];
	
	BOOL auth = [serverAuthFlag boolValue];
	
	[[[self class] clientWithServerAddress:serverAddress ports:serverPorts tlsMode:[serverTlsMode integerValue] username: auth? serverUsername : nil password: auth? serverPassword : nil ] sendMessage:message withSubject:subject from:from to:to];
}

+(SMTPClient*)clientWithServerAddress:(NSString*)address ports:(NSArray*)ports tlsMode:(SMTPClientTLSMode)tlsMode username:(NSString*)authUsername password:(NSString*)authPassword {
	return [[[[self class] alloc] initWithServerAddress:address ports:ports tlsMode:tlsMode username:authUsername password:authPassword] autorelease];
}

-(id)initWithServerAddress:(NSString*)address ports:(NSArray*)ports tlsMode:(SMTPClientTLSMode)tlsMode username:(NSString*)authUsername password:(NSString*)authPassword {
	if ((self = [super init])) {
		if (!address.length) [NSException raise:NSInvalidArgumentException format:@"Invalid server address"];
		self.address = address;
		if (ports.count) self.ports = ports;
		else self.ports = [NSArray arrayWithObjects: [NSNumber numberWithInteger:25], [NSNumber numberWithInteger:465], [NSNumber numberWithInteger:587], NULL];
		self.tlsMode = tlsMode;
		self.username = authUsername;
		self.password = authPassword;
	}
	
	return self;
}

-(void)dealloc {
//  NSLog(@"SMTPClient dealloc");
	self.address = nil;
	self.ports = nil;
	self.username = nil;
	self.password = nil;
	[super dealloc];
}

+(void)splitAddress:(NSString*)address intoEmail:(NSString**)email description:(NSString**)desc {
	NSInteger lti = [address rangeOfString:@"<" options:0].location;
	NSInteger gti = [address rangeOfString:@">" options:NSBackwardsSearch].location;
	if (lti != NSNotFound) {
		if (gti != NSNotFound) {
			if (lti < gti) {
				if (email) *email = [[address substringWithRange:NSMakeRange(lti+1, gti-lti-1)] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
				if (desc) *desc = [[address substringToIndex:MAX(0,lti-1)] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
			} else [NSException raise:NSInvalidArgumentException format:@"Invalid sender email address"];
		} else [NSException raise:NSInvalidArgumentException format:@"Invalid sender email address"];
	} else {
		if (gti != NSNotFound)
			[NSException raise:NSInvalidArgumentException format:@"Invalid sender email address"];
		else {
			if (email) *email = address;
			if (desc) *desc = nil;
		}
	}
}

-(void)sendMessage:(NSString*)message withSubject:(NSString*)subject from:(NSString*)from to:(NSString*)toAddresses {
	if (!from.length) [NSException raise:NSInvalidArgumentException format:@"Empty sender email address"];
	if (!toAddresses.length) [NSException raise:NSInvalidArgumentException format:@"Empty destination email address"];
	
	NSHost* host = [NSHost hostWithName:self.address];
	if (!host) [NSException raise:NSInvalidArgumentException format:@"Invalid server address"];
		
	_SMTPConnector* connector = [[_SMTPConnector new] autorelease]; // TODO: release
    connector.client = self;
	connector.message = message;
	connector.subject = subject;
	
	NSString* tempAddress;
	NSString* tempLabel;
	
	[[self class] splitAddress:from intoEmail:&tempAddress description:&tempLabel];
	connector.from = tempAddress;
	connector.fromDescription = tempLabel;
	
	NSMutableArray* to = [NSMutableArray array];
	for (NSString* ito in [toAddresses componentsSeparatedByString:@","]) {
		ito = [ito stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
		[[self class] splitAddress:ito intoEmail:&tempAddress description:&tempLabel];
		[to addObject:[NSArray arrayWithObjects: tempAddress, tempLabel, nil]];
	}
	
	connector.to = to;
	
	[connector performSelectorInBackground:@selector(start) withObject:nil];
}

@end

@interface NSString (SMTP)

-(NSData*)UTF7Data;
-(void)splitStringAtCharacterFromSet:(NSCharacterSet*)charset intoChunks:(NSString**)part1 :(NSString**)part2 separator:(unichar*)separator;

@end

@interface _SMTPConnector ()

@property(retain) NSInputStream* istream;
@property(retain) NSOutputStream* ostream;
@property NSInteger connectionStatus;

@property(nonatomic) NSInteger smtpStatus;
@property NSInteger smtpSubstatus;
@property(retain) NSArray* authModes;
@property BOOL canStartTLS;
@property NSInteger rcptToCount;
@property(retain) NSTimer* dataTimeoutTimer;
@property(retain) NSTimer* openTimeoutTimer;

+(NSString*)CramMD5:(NSString*)challengeString key:(NSString*)secretString;

-(void)handleData:(NSMutableData*)data;
-(void)handleLine:(NSString*)line;
-(void)writeData:(NSData*)data;
-(void)trySendingDataNow;

-(void)startTLS;
-(void)reset;

@end

@implementation _SMTPConnector

@synthesize client = _client;
@synthesize message = _message;
@synthesize subject = _subject;
@synthesize from = _from;
@synthesize fromDescription = _fromDescription;
@synthesize to = _to;

@synthesize istream = _istream;
@synthesize ostream = _ostream;
@synthesize connectionStatus = _connectionStatus;

@synthesize smtpStatus = _smtpStatus;
@synthesize smtpSubstatus = _smtpSubstatus;
@synthesize authModes = _authModes;
@synthesize canStartTLS = _canStartTLS;
@synthesize rcptToCount = _rcptToCount;
@synthesize dataTimeoutTimer = _dataTimeoutTimer;
@synthesize openTimeoutTimer = _openTimeoutTimer;

enum {
    ConnectionStatusClosed = 0, ConnectionStatusConnecting, ConnectionStatusOk
};

-(id)init {
    if ((self = [super init])) {
        _ibuffer = [[NSMutableData alloc] init];
        _obuffer = [[NSMutableData alloc] init];
    }
    
    return self;
}

-(void)start {
    NSException* exception = nil;
	for (NSNumber* port in self.client.ports) {
		@try {
            [self reset];
            
            self.connectionStatus = ConnectionStatusConnecting;
            [NSStream getStreamsToHost:[NSHost hostWithName:self.client.address] port:port.integerValue inputStream:&_istream outputStream:&_ostream];
            [_istream retain];
            [_ostream retain];
            [_istream setDelegate:self];
            [_ostream setDelegate:self];
            [_istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [_ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

            self.openTimeoutTimer = [[[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:10] interval:0 target:self selector:@selector(_openTimeoutCallback:) userInfo:nil repeats:NO] autorelease];
            [[NSRunLoop currentRunLoop] addTimer:self.openTimeoutTimer forMode:NSDefaultRunLoopMode];

            [_istream open];
            [_ostream open];
            
            while (self.connectionStatus != ConnectionStatusClosed/* && !_launchThread.isCancelled*/) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                // [NSThread sleepForTimeInterval:0.01];
            }
			
            if (!_istream.streamError && !_ostream.streamError && _success) {
                exception = nil;
                break;
            }
		} @catch (NSException* e) {
			NSLog(@"SMTP Exception: %@", e.reason);
            exception = e;
		}
	}
    
    if (exception)
		NSLog( @"******* SMTPClient exception: %@", exception);
}

-(void)startTLS {
//  NSLog(@"StartTLS with %@", self.client.address);
    NSMutableDictionary* settings = [NSMutableDictionary dictionary];
    self.connectionStatus = ConnectionStatusConnecting;
    [settings setObject:NSStreamSocketSecurityLevelNegotiatedSSL forKey:(NSString*)kCFStreamSSLLevel];
    [settings setObject:self.client.address forKey:(NSString*)kCFStreamSSLPeerName];
    [_istream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
    [_ostream setProperty:settings forKey:(NSString*)kCFStreamPropertySSLSettings];
    [_istream open];
    [_ostream open];
    _isTLS = YES;
}

-(void)_openTimeoutCallback:(NSTimer*)timer {
    [self reset];
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)event {
	//#ifdef DEBUG
//    	NSString* NSEventName[] = {@"NSStreamEventNone", @"NSStreamEventOpenCompleted", @"NSStreamEventHasBytesAvailable", @"NSStreamEventHasSpaceAvailable", @"NSStreamEventErrorOccurred", @"NSStreamEventEndEncountered"};
//    	NSLog(@"%@ stream:handleEvent:%@", NSEventName[(int)log2(event)+1], [stream className]);
	//#endif
	
	if (event == NSStreamEventOpenCompleted)
		if (++_handleOpenCompleted == 2) {
            [self.openTimeoutTimer invalidate];
            self.openTimeoutTimer = nil;
            
			self.connectionStatus = ConnectionStatusOk;
            
            self.dataTimeoutTimer = [[[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:1] interval:0 target:self selector:@selector(_dataTimeoutCallback:) userInfo:nil repeats:NO] autorelease];
            [[NSRunLoop currentRunLoop] addTimer:self.dataTimeoutTimer forMode:NSDefaultRunLoopMode];
		}
	
	if (stream == _istream && event == NSStreamEventHasBytesAvailable) {
		// DLog(@"%@ has bytes available", self);
		while (YES) {
			NSUInteger maxLength = 2048;
			uint8_t buffer[maxLength];
			NSInteger length = [_istream read:buffer maxLength:maxLength];
			
			if (length > 0) {
//				NSLog(@"Read %d bytes", length);
				//				std::cerr << [[NSString stringWithFormat:@"%@ Read %d Bytes", self, length] UTF8String] << ": ";
				//				for (int i = 0; i < length; ++i)
				//					std::cerr << (int)buffer[i] << " ";
				//				std::cerr << std::endl;
				[_ibuffer appendBytes:buffer length:length];
                
                [self handleData:_ibuffer];
                
                if (length < maxLength)
                    break;
			} else
				break;
		}
		
	}
	
	if (stream == _ostream && event == NSStreamEventHasSpaceAvailable && [_obuffer length]) {
		if (_isTLS && self.connectionStatus == ConnectionStatusConnecting)
            self.connectionStatus = ConnectionStatusOk;
        [self performSelector:@selector(trySendingDataNow) withObject:nil afterDelay:0];
    }
	
	if (event == NSStreamEventEndEncountered) {
		[stream close];
        self.connectionStatus = ConnectionStatusClosed;
    }
	
	if (event == NSStreamEventErrorOccurred) {
		NSLog(@"Stream error: %@", stream.streamError.localizedDescription);
        self.connectionStatus = ConnectionStatusClosed;
	}
}

-(void)handleData:(NSMutableData*)data {
	if (self.dataTimeoutTimer) {
		[self.dataTimeoutTimer invalidate];
		self.dataTimeoutTimer = nil;
	}
	
	char* datap = (char*)data.bytes;
	NSInteger datal = data.length, datalused = 0;
	
	while (datal > 0) {
		char* p = strnstr(datap, "\r\n", datal);
		if (!p) break;
		size_t l = p-datap;
		
		if (l) {
			NSString* line = [[NSString alloc] initWithBytesNoCopy:datap length:l encoding:NSUTF8StringEncoding freeWhenDone:NO];
			[self handleLine:line];
			[line release];
		}
		
		l += 2;
		datap += l;
		datal -= l;
		datalused += l;
	}
    
    if (datalused)
        [data replaceBytesInRange:NSMakeRange(0, datalused) withBytes:nil length:0];
}

-(void)writeData:(NSData*)data {
	[_obuffer appendData:data];
	if (self.connectionStatus == ConnectionStatusOk)	
		[self trySendingDataNow];
}

-(void)trySendingDataNow {
	NSUInteger length = _obuffer.length;
	if (length && self.connectionStatus == ConnectionStatusOk) {
		NSUInteger sentLength = [_ostream write:(uint8_t*)_obuffer.bytes maxLength:length];
		if (sentLength != -1) {
			[_obuffer replaceBytesInRange:NSMakeRange(0,sentLength) withBytes:nil length:0];
//            NSLog(@"Sent %d bytes", sentLength);
		} else
			NSLog(@"%@ Send error: %@", self, _ostream.streamError.localizedDescription);
	}
}

-(void)dealloc {
//  NSLog(@"_SMTPConnector dealloc");
    
    [self reset];
    
    self.client = nil;
	self.message = nil;
	self.subject = nil;
	self.from = nil;
	self.fromDescription = nil;
	self.to = nil;
    
    [_ibuffer release];
    [_obuffer release];
	[super dealloc];
}

#pragma mark SMTP

enum SMTPStatuses {
	InitialStatus = 0,
	StatusHELO,
	StatusEHLO,
	StatusSTARTTLS,
	StatusAUTH,
	StatusMAIL,
	StatusRCPT,
	StatusDATA,
	StatusQUIT
};

enum SMTPSubstatuses {
	PlainAUTH = 1,
	LoginAUTH,
	CramMD5AUTH
};

-(void)reset {
    [self.openTimeoutTimer invalidate];
	self.openTimeoutTimer = nil;
    
    [self.dataTimeoutTimer invalidate];
	self.dataTimeoutTimer = nil;
    
    [self.ostream close];
    [self.istream close];
    [self.ostream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.istream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.ostream = nil;
    self.istream = nil;
    
    _handleOpenCompleted = 0;
    self.connectionStatus = ConnectionStatusClosed;
    [_ibuffer setLength:0];
    [_obuffer setLength:0];
    _isTLS = NO;
    
    self.smtpStatus = InitialStatus;
    self.authModes = nil;
    self.canStartTLS = NO;
    self.rcptToCount = 0;
}

+(NSString*)CramMD5:(NSString*)challengeString key:(NSString*)secretString {
	unsigned char ipad[64], opad[64];
	
	NSData* secretData = [secretString dataUsingEncoding:NSUTF8StringEncoding];
	if (secretData.length > 64)
		secretData = [secretData md5];
	[secretData getBytes:ipad];
	memset(&ipad[secretData.length], 0, 64-secretData.length);
	memcpy(opad, ipad, 64);
	for (NSInteger i = 0; i < 64; ++i) {
		ipad[i] ^= 0x36;
		opad[i] ^= 0x5c;
	}
	
	// MD5(opad, MD5(ipad, challenge))
	NSMutableData* r1 = [NSMutableData dataWithBytes:opad length:64];
	NSMutableData* r2 = [NSMutableData dataWithBytes:ipad length:64];
	[r2 appendData:[challengeString dataUsingEncoding:NSUTF8StringEncoding]];
	[r1 appendData:[r2 md5]];
	return [[r1 md5] hex];
}

+(NSString*)_hostname {
	char hostname[128];
	gethostname(hostname, 127);
	hostname[127] = 0;
	NSString* string = [NSString stringWithCString:hostname encoding:NSUTF8StringEncoding];
    if (![string rangeOfString:@"."].length) string = [string stringByAppendingString:@".local"];
    return string;
}

-(void)writeLine:(id)line {
//  NSLog(@"-> %@", line);
    if ([line isKindOfClass:[NSString class]])
        line = [line dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData* data = [[line mutableCopy] autorelease];
    [data appendBytes:"\r\n" length:2];
    
	[self writeData:data];
}

-(void)setSmtpStatus:(NSInteger)smtpStatus {
	_smtpStatus = smtpStatus;
	self.smtpSubstatus = 0;
}

-(void)_ehlo {
	[self writeLine:[@"EHLO " stringByAppendingString:[[self class] _hostname]]];
	self.smtpStatus = StatusEHLO;
}

-(void)_mail {
	NSString* from = [NSString stringWithFormat:@"<%@>", self.from];
	[self writeLine:[@"MAIL FROM: " stringByAppendingString:from]];
	self.smtpStatus = StatusMAIL;
}

-(void)_auth {
	if (self.client.username && self.client.password) {
		if ([self.authModes containsObject:@"CRAM-MD5"]) {
			[self writeLine:@"AUTH CRAM-MD5"];
			self.smtpStatus = StatusAUTH;
			self.smtpSubstatus = CramMD5AUTH;
		}
		else if ([self.authModes containsObject:@"PLAIN"]) {
			[self writeLine:[@"AUTH PLAIN " stringByAppendingString:[[[NSString stringWithFormat:@"%@\0%@\0%@", self.client.username, self.client.username, self.client.password] dataUsingEncoding:NSUTF8StringEncoding] base64]]];
			self.smtpStatus = StatusAUTH;
			self.smtpSubstatus = PlainAUTH;
		}
		else if ([self.authModes containsObject:@"LOGIN"]) {
			[self writeLine:@"AUTH LOGIN"];
			self.smtpStatus = StatusAUTH;
			self.smtpSubstatus = LoginAUTH;
		}
		else [NSException raise:NSGenericException format:@"The server doesn't allow any authentication techniques supported by this client."];
	} else
		[self _mail];
}

-(void)handleCode:(NSInteger)code withMessage:(NSString*)message separator:(unichar)separator {
    //	NSLog(@"HANDLE: [Status %d] Handling %d with %@", context.status, code, message);
	
	if (code >= 500)
		[NSException raise:NSGenericException format:@"Error %d: %@", code, message];
	
	switch (self.smtpStatus) {
		case InitialStatus: {
			switch (code) {
				case 220:
					if ((!_isTLS && self.client.tlsMode) || (self.client.username && self.client.password)) {
						[self _ehlo];
						return;
					} else {
						[self writeLine:[@"HELO " stringByAppendingString:[[self class] _hostname]]];
						self.smtpStatus = StatusHELO;
						return;
					}
			}
		} break;
		case StatusHELO:
		case StatusEHLO: {
			switch (code) {
				case 250:
					if (separator == '-') {
						NSString* name;
						NSString* value;
						[message splitStringAtCharacterFromSet:NSCharacterSet.whitespaceCharacterSet intoChunks:&name:&value separator:NULL];
						
						if ([name isEqualToString:@"AUTH"])
							self.authModes = [value componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
						if ([name isEqualToString:@"STARTTLS"])
							self.canStartTLS = YES;
					} else
						if (!_isTLS && self.client.tlsMode) {
							if (self.canStartTLS) {
								[self writeLine:@"STARTTLS"];
								self.smtpStatus = StatusSTARTTLS;
							} else if (self.client.tlsMode == SMTPClientTLSModeTLSOrClose)
								[NSException raise:NSGenericException format:@"Server doesn't support STARTTLS"];
							else { // TLSIfPossible, not possible...
								[self _auth];
							}
						} else
							[self _auth];
					return;
			}
		} break;
		case StatusSTARTTLS: {
			if (code == 220) {
				[self startTLS];
				[self _ehlo];
				return;
			}
		} break;
		case StatusAUTH: {
			switch (self.smtpSubstatus) {
				case PlainAUTH:
					switch (code) {
						case 235:
							[self _mail];
							return;
					} break;
				case LoginAUTH:
					switch (code) {
						case 334:
							message = [[[NSString alloc] initWithData:[NSData dataWithBase64:message] encoding:NSUTF8StringEncoding] autorelease];
							if ([message isEqualToString:@"Username:"]) {
								[self writeLine:[[self.client.username dataUsingEncoding:NSUTF8StringEncoding] base64]];
								return;
							} else if ([message isEqualToString:@"Password:"]) {
								[self writeLine:[[self.client.password dataUsingEncoding:NSUTF8StringEncoding] base64]];
								return;
							}
						case 235:
							[self _mail];
							return;
					} break;
				case CramMD5AUTH:
					switch (code) {
						case 334: {
							message = [[[NSString alloc] initWithData:[NSData dataWithBase64:message] encoding:NSUTF8StringEncoding] autorelease];
							NSString* temp = [NSString stringWithFormat:@"%@ %@", self.client.username, [[self class] CramMD5:message key:self.client.password]];
							[self writeLine:[[temp dataUsingEncoding:NSUTF8StringEncoding] base64]];
							return;
						} break;
						case 235:
							[self _mail];
							return;
					} break;
                    
			}
		} break;
		case StatusMAIL: {
			switch (code) {
				case 250:
					for (NSArray* ito in self.to) {
						NSString* to = [ito objectAtIndex:0];
						if ([to rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]].location == NSNotFound)
							to = [NSString stringWithFormat:@"<%@>", to];
						[self writeLine:[@"RCPT TO: " stringByAppendingString:to]];
						self.rcptToCount += 1;
					}
					self.smtpStatus = StatusRCPT;
					return;
			}
		} break;
		case StatusRCPT: {
			switch (code) {
				case 250: {
					self.rcptToCount -= 1;
					if (self.rcptToCount == 0) {
						[self writeLine:@"DATA"];
						self.smtpStatus = StatusDATA;
					}
					return;
				}
			}
		} break;
		case StatusDATA: {
			switch (code) {
				case 0: // disconnection
				case 250:
                    _success = YES;
					[self writeLine:@"QUIT"];
					self.smtpStatus = StatusQUIT;
					if (code == 0)
						[self reset];
					return;
				case 354:
					if (self.fromDescription)
						[self writeLine:[NSString stringWithFormat:@"From: =?UTF-8?B?%@?= <%@>", [[self.fromDescription dataUsingEncoding:NSUTF8StringEncoding] base64], self.from]];
					else [self writeLine:[NSString stringWithFormat:@"From: %@", self.from]];
					
					NSMutableString* to = [NSMutableString string];
					for (NSArray* ito in self.to) {
						if (to.length)
							[to appendString:@", "];
						if (ito.count > 1)
							[to appendFormat:@"=?UTF-8?B?%@?= <%@>", [[[ito objectAtIndex:1] dataUsingEncoding:NSUTF8StringEncoding] base64], [ito objectAtIndex:0]];
						else [to appendFormat:@"%@", [ito objectAtIndex:0]];
					}
					[self writeLine:[NSString stringWithFormat:@"To: %@", to]];
					
					[self writeLine:[NSString stringWithFormat:@"Subject: =?UTF-8?B?%@?=", [[self.subject dataUsingEncoding:NSUTF8StringEncoding] base64]]];
					[self writeLine:@"Mime-Version: 1.0"];
					[self writeLine:@"Content-Type: text/html; charset=\"UTF-8\""];
					[self writeLine:@"Content-Transfer-Encoding: base64"];
					
//					[self writeLine:[NSString stringWithFormat:@"Subject: =?UTF-8?B?%@?=", [[self.subject dataUsingEncoding:NSUTF8StringEncoding] base64]]];
//					[self writeLine:@"Mime-Version: 1.0"];
//					[self writeLine:@"Content-Type: text/html; charset=utf-8"];
//					[self writeLine:@"Content-Transfer-Encoding: 8bit"];
                    
					[self writeLine:@""];
					
					NSString* message = [self.message stringByReplacingOccurrencesOfString:@"\r\n." withString:@"\r\n.."];
                    
                    [self writeLine: [[message dataUsingEncoding:NSUTF8StringEncoding] base64]];
					
					[self writeLine:@"."];
                    
					return;
			}
		} break;
		case StatusQUIT: {
			switch (code) {
				case 0: // disconnection
				case 221:
					return;
			}
		} break;
	}
	
	[NSException raise:NSGenericException format:@"Don't know how to act with status %d, code %d", self.smtpStatus, code];
}

-(void)handleLine:(NSString*)line {
//  NSLog(@"<- %@", line);
	
	NSInteger code = 0;
	NSString* message = nil;
	NSString* temp = nil;
	unichar separator = 0;
	
	[line splitStringAtCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" -"] intoChunks:&temp:&message separator:&separator];
	code = [temp integerValue];
	
	if (code) {
		[self handleCode:code withMessage:message separator:separator];
	} else [NSException raise:NSGenericException format:@"Couldn't parse line"];
}

-(void)_dataTimeoutCallback:(NSTimer*)timer {
	if (self.client.tlsMode) {
        [self startTLS];
    } else [NSException raise:NSGenericException format:@"Connection stalled, probably wants TLS handshake, user said no TLS"];
}

@end

@implementation NSString (SMTP)




-(NSData*)UTF7Data
{
    CFDataRef data = CFStringCreateExternalRepresentation (NULL, (CFStringRef) self, kCFStringEncodingUTF7, 0);
    
	return [(NSData*)data autorelease];
}

-(void)splitStringAtCharacterFromSet:(NSCharacterSet*)charset intoChunks:(NSString**)part1 :(NSString**)part2 separator:(unichar*)separator {
	NSInteger i = [self rangeOfCharacterFromSet:charset].location;
	if (i != NSNotFound) {
		if (part1) *part1 = [self substringToIndex:i];
		if (separator) *separator = [self characterAtIndex:i];
		if (part2) *part2 = [self substringFromIndex:i+1];
	} else {
		if (part1) *part1 = self;
		if (separator) *separator = 0;
		if (part2) *part2 = nil;
	}
}

@end

@implementation NSDictionary (SMTP)

-(id)objectForKey:(id)key ofClass:(Class)cl {
	id obj = [self objectForKey:key];
	if (obj && ![obj isKindOfClass:cl])
		return nil;
	return obj;
}

@end

@implementation NSData (SMTP)

-(NSData*)md5 {
    NSMutableData* hash = [NSMutableData dataWithLength:16];
    CC_MD5(self.bytes, self.length, (unsigned char*)hash.mutableBytes);
    return hash;
}

-(NSString*)hex {
	NSMutableString* stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
	const unsigned char* dataBuffer = (unsigned char*)[self bytes];
	for (int i = 0; i < [self length]; ++i)
		[stringBuffer appendFormat:@"%02X", (unsigned long)dataBuffer[i]];
	return [[stringBuffer copy] autorelease];
}

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

-(NSString*)base64 {
	if ([self length] == 0)
		return @"";
	
    char *characters = (char*)malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';	
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];	
}

+(NSData*)dataWithBase64:(NSString*)base64 {
	if (!base64) return NULL;
	return [[[NSData alloc] initWithBase64:base64] autorelease];
}

-(NSData*)initWithBase64:(NSString*)base64 {
	if ([base64 length] == 0)
		return [[NSData data] retain];
	
	static char *decodingTable = NULL;
	if (decodingTable == NULL)
	{
		decodingTable = (char*)malloc(256);
		if (decodingTable == NULL)
			return nil;
		memset(decodingTable, CHAR_MAX, 256);
		NSUInteger i;
		for (i = 0; i < 64; i++)
			decodingTable[(short)base64EncodingTable[i]] = i;
	}
	
	const char *characters = [base64 cStringUsingEncoding:NSASCIIStringEncoding];
	if (characters == NULL)     //  Not an ASCII string!
		return nil;
	char *bytes = (char*)malloc((([base64 length] + 3) / 4) * 3);
	if (bytes == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (YES)
	{
		char buffer[4];
		short bufferLength;
		for (bufferLength = 0; bufferLength < 4; i++)
		{
			if (characters[i] == '\0')
				break;
			if (isspace(characters[i]) || characters[i] == '=')
				continue;
			buffer[bufferLength] = decodingTable[(short)characters[i]];
			if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
			{
				free(bytes);
				return nil;
			}
		}
		
		if (bufferLength == 0)
			break;
		if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
		{
			free(bytes);
			return nil;
		}
		
		//  Decode the characters in the buffer to bytes.
		bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
		if (bufferLength > 2)
			bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
		if (bufferLength > 3)
			bytes[length++] = (buffer[2] << 6) | buffer[3];
	}
	
	realloc(bytes, length);
	return [self initWithBytesNoCopy:bytes length:length];
}

@end












