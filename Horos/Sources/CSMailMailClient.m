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
//
//  CSMailMailClient.m
//  CSMail
//
//  Created by Alastair Houghton on 27/01/2006.
//  Copyright 2006 Coriolis Systems Limited. All rights reserved.
//

#import "CSMailMailClient.h"
#import "SMTPClient.h"
#import <ApplicationServices/ApplicationServices.h>
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

void QuitAndSleep(NSString* bundleIdentifier, float seconds)
{
	const char* identifier = [bundleIdentifier UTF8String] ;
	NSAppleEventDescriptor *as = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID bytes:identifier length:strlen(identifier)]; 
	NSAppleEventDescriptor *ae = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass  eventID:kAEQuitApplication  targetDescriptor:as returnID:kAutoGenerateReturnID  transactionID:kAnyTransactionID];
	
	AppleEvent *quitApplicationAppleEventPtr = (AEDesc*)[ae aeDesc];
	if (quitApplicationAppleEventPtr)
	{
		/*OSStatus err =*/ AESendMessage(quitApplicationAppleEventPtr, NULL, kAENoReply, kAEDefaultTimeout) ;
	}
	[NSThread sleepForTimeInterval: seconds];
}

@implementation CSMailMailClient

- (NSAppleEventDescriptor *)recipientListFromString:(NSString *)string
{
  NSAppleEventDescriptor *list = [NSAppleEventDescriptor listDescriptor];
  
  if (string) {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *interestingSet 
      = [NSCharacterSet characterSetWithCharactersInString:@"<,"];
    NSString *name = @"", *addr = @"";
    unsigned numRecs = 0;
    
    while (![scanner isAtEnd]) {
      NSString *tmp;
      
      if ([scanner scanUpToCharactersFromSet:interestingSet intoString:&tmp])
	  {
		  if ([scanner scanString:@"<" intoString:NULL])
		  {
			name = tmp;
			  [scanner scanUpToString:@">" intoString:&tmp];
			  [scanner scanString:@">" intoString:NULL];
			  addr = tmp;
		  }
		  else
		  {
			  addr = tmp;
		  }
        
	if ([scanner scanString:@"," intoString:NULL])
	{
	  if ([addr length])
	  {
	    NSAppleEventDescriptor *record
              = [NSAppleEventDescriptor listDescriptor];
	    NSAppleEventDescriptor *userRecord 
              = [NSAppleEventDescriptor recordDescriptor];
            
	    [record insertDescriptor:
             [NSAppleEventDescriptor descriptorWithString:@"name"] 
			     atIndex:1];
	    [record insertDescriptor:
             [NSAppleEventDescriptor descriptorWithString:name] 
			     atIndex:2];
	    [record insertDescriptor:
             [NSAppleEventDescriptor descriptorWithString:@"address"] 
			     atIndex:3];
	    [record insertDescriptor:
             [NSAppleEventDescriptor descriptorWithString:addr]
			     atIndex:4];
	    [userRecord setDescriptor:record forKeyword:keyASUserRecordFields];
            
	    [list insertDescriptor:userRecord atIndex:numRecs++];
	  }
          
	  name = @"";
	  addr = @"";
	}
      }
    }
    
    if ([addr length]) {
      NSAppleEventDescriptor *record 
        = [NSAppleEventDescriptor listDescriptor];
      NSAppleEventDescriptor *userRecord 
        = [NSAppleEventDescriptor recordDescriptor];
      
      [record insertDescriptor:
       [NSAppleEventDescriptor descriptorWithString:@"name"] 
		       atIndex:1];
      [record insertDescriptor:
       [NSAppleEventDescriptor descriptorWithString:name] 
		       atIndex:2];
      [record insertDescriptor:
       [NSAppleEventDescriptor descriptorWithString:@"address"] 
		       atIndex:3];
      [record insertDescriptor:
       [NSAppleEventDescriptor descriptorWithString:addr]
		       atIndex:4];
      [userRecord setDescriptor:record forKeyword:keyASUserRecordFields];
      
      // Static Analyser false positive
      [list insertDescriptor:userRecord atIndex:numRecs++];
    }
  }
  
  return list;
}

+ (id)mailClient
{
  return [[[CSMailMailClient alloc] init] autorelease];
}

- (id)init
{
    self = [super init];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey: @"WebServerUseMailAppForEmails"] == NO)
    {
        if (!defaultSMTPAccount)
        {
            defaultSMTPAccount = [[self defaultSMTPAccountFromMail] retain];
            if (!defaultSMTPAccount)
            {
                //We can't do anything without an account.
                NSLog( @"**** MailMe: No suitable SMTP account found");
            }
        }
    }
    return self;
}

- (NSAppleScript *)script
{
  if (script)
    return script;
  
  NSDictionary *errorInfo = nil;

  /* This AppleScript code is here to communicate with Mail.app */
  NSString *ourScript =
    @"on build_message(sendr, recip, subj, ccrec, bccrec, msgbody,"
    @"                 attachfiles)\n"
    @"  tell application \"Mail\"\n"
    @"    set mailversion to version as string\n"
    @"    set msg to make new outgoing message at beginning of"
    @"      outgoing messages\n"
    @"    tell msg\n"
    @"      set the subject to subj\n"
    @"      set the content to msgbody\n"
    @"      if (sendr is not equal to \"\") then\n"
    @"        set sender to sendr\n"
    @"      end if\n"
    @"      repeat with rec in recip\n"
    @"        make new to recipient at end of to recipients with properties {"
    @"          name: |name| of rec, address: |address| of rec }\n"
    @"      end repeat\n"
    @"      repeat with rec in ccrec\n"
    @"        make new to recipient at end of cc recipients with properties {"
    @"          name: |name| of rec, address: |address| of rec }\n"
    @"      end repeat\n"
    @"      repeat with rec in bccrec\n"
    @"        make new to recipient at end of bcc recipients with properties {"
    @"          name: |name| of rec, address: |address| of rec }\n"
    @"      end repeat\n"
    @"      tell content\n"
    @"        repeat with attch in attachfiles\n"
    @"          make new attachment with properties { file name: attch } at "
    @"            after the last paragraph\n"
    @"        end repeat\n"
    @"      end tell\n"
    @"    end tell\n"
    @"    return msg\n"
    @"  end tell\n"
    @"end build_message\n"
    @"\n"
    @"on deliver_message(sendr, recip, subj, ccrec, bccrec, msgbody,"
    @"                   attachfiles)\n"
	@"tell application \"Mail\" to activate\n"
    @"  set msg to build_message(sendr, recip, subj, ccrec, bccrec, msgbody,"
    @"                           attachfiles)\n"
    @"  tell application \"Mail\"\n"
    @"    send msg\n"
    @"  end tell\n"
    @"end deliver_message\n"
    @"\n"
    @"on construct_message(sendr, recip, subj, ccrec, bccrec, msgbody,"
    @"                     attachfiles)\n"
    @"  set msg to build_message(sendr, recip, subj, ccrec, bccrec, msgbody,"
    @"                           attachfiles)\n"
    @"  tell application \"Mail\"\n"
    @"    tell msg\n"
    @"      set visible to true\n"
    @"      activate\n"
    @"    end tell\n"
    @"  end tell\n"
    @"end construct_message\n";
  
  script = [[NSAppleScript alloc] initWithSource: ourScript];
  
  if (![script compileAndReturnError:&errorInfo]) {
    NSLog (@"Unable to compile script: %@", errorInfo);
    [script release];
    script = nil;
  }
  
  return script;
}

- (void)dealloc
{
    [defaultSMTPAccount release];
    [script release];
    [super dealloc];
}

- (NSString *)name
{
  return @"Mail.app Plugin";
}

- (NSString *)applicationName
{
  return @"Mail.app";
}

- (NSString *)version
{
  return @"1.0.0";
}

- (BOOL)applicationIsInstalled
{
  OSStatus ret = LSFindApplicationForInfo (kLSUnknownCreator,
					   CFSTR ("com.apple.mail"),
					   NULL,
					   NULL,
					   NULL);

  return ret == noErr ? YES : NO;
}

- (NSImage *)applicationIcon
{
  CFURLRef url = NULL;
  OSStatus ret = LSFindApplicationForInfo (kLSUnknownCreator,
					   CFSTR ("com.apple.mail"),
					   NULL,
					   NULL,
					   &url);

  if (ret != noErr)
    return nil;
  else {
    NSString *path = [(NSURL *)url path];
    [(NSURL *)url autorelease];

    return [[NSWorkspace sharedWorkspace] iconForFile:path];
  }
}

- (NSDictionary *) defaultSMTPAccountFromMail
{
	NSMutableDictionary *viableAccount = nil, *selectedAccount = nil;
    BOOL found = NO;
    NSArray *deliveryAccounts = nil, *mailAccounts = nil;
    
    NSString *LionPath = [@"~/Library/Mail/V2/MailData/Accounts.plist" stringByExpandingTildeInPath];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: LionPath])
    {
        deliveryAccounts = [[NSDictionary dictionaryWithContentsOfFile: LionPath] objectForKey: @"DeliveryAccounts"];
        mailAccounts = [[NSDictionary dictionaryWithContentsOfFile: LionPath] objectForKey: @"MailAccounts"];
    }
    else
        NSLog( @"***** File NOT found: %@", LionPath);
    
	if (!deliveryAccounts)
        deliveryAccounts = [NSMakeCollectable(CFPreferencesCopyAppValue(CFSTR("DeliveryAccounts"), CFSTR("com.apple.Mail"))) autorelease];
    
    if (!deliveryAccounts)
    {
        NSLog( @"***** No DeliveryAccounts found");
		return viableAccount;
    }
    
    if (!mailAccounts)
        mailAccounts = [NSMakeCollectable(CFPreferencesCopyAppValue(CFSTR("MailAccounts"), CFSTR("com.apple.Mail"))) autorelease];
    
	if (!mailAccounts)
    {
        NSLog( @"***** No MailAccounts found");
		return viableAccount;
    }
    
	NSMutableDictionary *deliveryAccountsBySMTPIdentifier = [NSMutableDictionary dictionaryWithCapacity:[deliveryAccounts count]];
	for (NSDictionary *account in deliveryAccounts)
    {
		NSString *identifier = nil;
        
        if( [account objectForKey:@"Username"])
            identifier = [NSString stringWithFormat:@"%@:%@", [account objectForKey:@"Hostname"], [account objectForKey:@"Username"]];
        else
            identifier = [NSString stringWithFormat:@"%@", [account objectForKey:@"Hostname"]];
        
		[deliveryAccountsBySMTPIdentifier setObject:account forKey:identifier];
	}
    
	for (NSDictionary *account in mailAccounts)
    {
		NSString *identifier = [account objectForKey:@"SMTPIdentifier"];
		if (!identifier)
			continue;
        
		viableAccount = [[[deliveryAccountsBySMTPIdentifier objectForKey:identifier] mutableCopy] autorelease];
		if( viableAccount && (found == NO || [[[account objectForKey:@"EmailAddresses"] objectAtIndex: 0] isEqualToString: [[NSUserDefaults standardUserDefaults] objectForKey: @"notificationsEmailsSender"]]))
        {
			NSString *bareAddress = [[account objectForKey:@"EmailAddresses"] objectAtIndex:0UL];
			NSString *name = [account objectForKey:@"FullUserName"];
            [fromAddress release];
			fromAddress = [(name ? [NSString stringWithFormat:@"%@ <%@>", name, bareAddress] : bareAddress) copy];
			if (!fromAddress) {
				viableAccount = nil;
			}
            
            if( [[viableAccount objectForKey: @"UseDefaultPorts"] boolValue])
				[viableAccount removeObjectForKey: @"PortNumber"];
            
            if (viableAccount)
            {
                NSString *hostname = [viableAccount valueForKey: @"Hostname"];
                NSString *username = [viableAccount valueForKey: @"Username"];
                NSString *port = [viableAccount valueForKey: @"PortNumber"];
                
                if( port == nil)
                    port = @"0";
                
                OSStatus err = noErr;
                UInt32 passwordLength = 0U;
                void *passwordBytes = NULL;
                
                if( username.length) // Do we need to retrieve a password?
                {
                    @try
                    {
                        err = SecKeychainFindInternetPassword(/*keychainOrArray*/ NULL,
                                                          (UInt32)[hostname length], [hostname UTF8String],
                                                          /*securityDomainLength*/ 0U, /*securityDomain*/ NULL,
                                                          (UInt32)[username length], [username UTF8String],
                                                          /*pathLength*/ 0U, /*path*/ NULL,
                                                          (UInt16)[port integerValue],
                                                          kSecProtocolTypeSMTP, kSecAuthenticationTypeAny,
                                                          &passwordLength, &passwordBytes,
                                                          /*itemRef*/ NULL);
                    }
                    @catch (NSException *e)
                    {
                        NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
                    }
                }
                
                if (err != noErr)
                {
                    //Try looking it up as a MobileMe account.
                    NSMutableArray *usernameComponents = [[[username componentsSeparatedByString:@"@"] mutableCopy] autorelease];
                    [usernameComponents removeLastObject];
                    username = [usernameComponents componentsJoinedByString:@"@"];
                    
                    NSString *serviceName = @"iTools";
                    
                    err = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
                                                         (UInt32)[serviceName length], [serviceName UTF8String],
                                                         (UInt32)[username length],    [username UTF8String],
                                                         &passwordLength,              &passwordBytes,
                                                         /*itemRef*/ NULL);
                    
                    if (err != noErr)
                    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        NSLog(@"**** MailMe: Could not get password for SMTP account %@: %i/%s", username, (int)err, GetMacOSStatusCommentString(err));
#pragma clang diagnostic pop
                    }
                }
                
                //If we successfully got either a regular SMTP password or a MobileMe password…
                if (err == noErr)
                {
                    //…then let's proceed with sending the message.
                    NSData *passwordData = nil;
                    
                    NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionaryWithDictionary: viableAccount];
                    
                    if( passwordBytes)
                    {
                        passwordData = [NSData dataWithBytesNoCopy:passwordBytes length:passwordLength freeWhenDone:NO];
                        [tempDictionary setValue: [[[NSString alloc] initWithData: passwordData encoding: NSUTF8StringEncoding] autorelease] forKey: @"Password"];
                    }
                    
                    selectedAccount = tempDictionary;
                    
                    SecKeychainItemFreeContent(/*attrList*/ NULL, passwordBytes);
                }
            }
            
			if (selectedAccount)
				found = YES;
		}
	}
//    NSLog( @"SMTP Account selected: %@ %@", [selectedAccount valueForKey: @"Hostname"], [selectedAccount valueForKey: @"Username"]);
	return selectedAccount;
}

- (NSAppleEventDescriptor *)descriptorForThisProcess
{
  ProcessSerialNumber thePSN = { 0, kCurrentProcess };
  
  return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
							bytes:&thePSN
						       length:sizeof (thePSN)];
}

- (BOOL)doHandler:(NSString *)handler
       forMessage:(NSAttributedString *)messageBody
	  headers:(NSDictionary *)messageHeaders
{
  NSMutableString *body = [NSMutableString string];
  NSDictionary *errorInfo = nil;
  NSAppleEventDescriptor *target = [self descriptorForThisProcess];
  NSAppleEventDescriptor *event
    = [NSAppleEventDescriptor appleEventWithEventClass:'ascr'
					       eventID:kASSubroutineEvent
				      targetDescriptor:target
					      returnID:kAutoGenerateReturnID
					 transactionID:kAnyTransactionID];
  NSAppleEventDescriptor *params = [NSAppleEventDescriptor listDescriptor];
  NSAppleEventDescriptor *files = [NSAppleEventDescriptor listDescriptor];
  NSString *tmpdir = NSTemporaryDirectory ();
  NSString *attachtmp = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *sendr = @"", *subj = @"", *replyto = @"";
  NSAppleEventDescriptor *recip
    = [self recipientListFromString:[messageHeaders objectForKey:@"To"]];
  NSAppleEventDescriptor *ccrec
    = [self recipientListFromString:[messageHeaders objectForKey:@"Cc"]];
  NSAppleEventDescriptor *bccrec
    = [self recipientListFromString:[messageHeaders objectForKey:@"Bcc"]];
  unsigned numFiles = 0;
  unsigned length = [messageBody length];
  unsigned pos = 0;
  NSRange range;

  if ([messageHeaders objectForKey:@"Subject"])
    subj = [messageHeaders objectForKey:@"Subject"];
  if ([messageHeaders objectForKey:@"ReplyTo"])
    replyto = [messageHeaders objectForKey:@"ReplyTo"];	
  if ([messageHeaders objectForKey:@"Sender"])
    sendr = [messageHeaders objectForKey:@"Sender"];

  /* Find all the attachments and replace them with placeholder text */
  while (pos < length) {
    NSDictionary *attributes = [messageBody attributesAtIndex:pos
					       effectiveRange:&range];
    NSTextAttachment *attachment
      = [attributes objectForKey:NSAttachmentAttributeName];

    if (attachment && !attachtmp) {
      /* Create a temporary directory to hold the attachments (we have to do this
	 because we can't get the full path from the NSFileWrapper) */
      do {
	attachtmp = [tmpdir stringByAppendingPathComponent:
			      [NSString stringWithFormat:@"csmail-%08lx",
					random ()]];
      } while (![fileManager createDirectoryAtPath:attachtmp withIntermediateDirectories:YES attributes:nil error:NULL]);
    }

    if (attachment) {
      NSFileWrapper *fileWrapper = [attachment fileWrapper];
      NSString *filename = [attachtmp stringByAppendingPathComponent:
			     [fileWrapper preferredFilename]];
      [fileWrapper writeToFile:filename atomically:NO
	       updateFilenames:NO];
      [body appendFormat:@"<%@>\n", [fileWrapper preferredFilename]];

      [files insertDescriptor:
	[NSAppleEventDescriptor descriptorWithString:filename]
		      atIndex:++numFiles];

      pos = range.location + range.length;

      continue;
    }

    [body appendString:[[messageBody string] substringWithRange:range]];

    pos = range.location + range.length;
  }

  /* Replace any CF/LF pairs with just LF; also replace CRs with LFs */
  [body replaceOccurrencesOfString:@"\r\n" withString:@"\n"
	options:NSLiteralSearch range:NSMakeRange (0, [body length])];
  [body replaceOccurrencesOfString:@"\r" withString:@"\n"
	options:NSLiteralSearch range:NSMakeRange (0, [body length])];

  [event setParamDescriptor:
    [NSAppleEventDescriptor descriptorWithString:handler]
		 forKeyword:keyASSubroutineName];
  [params insertDescriptor:
    [NSAppleEventDescriptor descriptorWithString:sendr]
		   atIndex:1];
  [params insertDescriptor:recip atIndex:2];
  [params insertDescriptor:
    [NSAppleEventDescriptor descriptorWithString:subj]
		   atIndex:3];
  [params insertDescriptor:ccrec atIndex:4];
  [params insertDescriptor:bccrec atIndex:5];
  [params insertDescriptor:
    [NSAppleEventDescriptor descriptorWithString:body]
		   atIndex:6];
  [params insertDescriptor:files atIndex:7];

  [event setParamDescriptor:params forKeyword:keyDirectObject];
  
  NSDictionary* UserHeaders = [[[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.mail"] objectForKey: @"UserHeaders"] mutableCopy] autorelease];
  
  if( [replyto length])
  {
	NSMutableDictionary* defaults = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.mail"] mutableCopy] autorelease];
	NSMutableDictionary* MutableUserHeaders = [[[defaults objectForKey: @"UserHeaders"] mutableCopy] autorelease];
	
	if( MutableUserHeaders == nil)
		MutableUserHeaders = [NSMutableDictionary dictionary];
	
	[MutableUserHeaders setValue: replyto forKey: @"Reply-To"];
	
	[defaults setObject: MutableUserHeaders forKey: @"UserHeaders"];
	
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: defaults forName: @"com.apple.mail"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	QuitAndSleep( @"com.apple.mail", 0.5);
  }

  if (![[self script] executeAppleEvent:event error:&errorInfo])
  {
    NSLog (@"Unable to communicate with Mail.app.  Error was %@.\n",
	   errorInfo);
    return NO;
  }

 if( [replyto length])
 {
	NSMutableDictionary* defaults = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.mail"] mutableCopy] autorelease];
	
	if( UserHeaders)
		[defaults setObject: UserHeaders forKey: @"UserHeaders"];
	else
		[defaults removeObjectForKey: @"UserHeaders"];
		
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: defaults forName: @"com.apple.mail"];
	[[NSUserDefaults standardUserDefaults] synchronize];
 }
 
  return YES;
}


- (BOOL)deliverMessage:(NSString *)messageBody
               headers:(NSDictionary *)messageHeaders
{
    BOOL useMail = [[NSUserDefaults standardUserDefaults] boolForKey: @"WebServerUseMailAppForEmails"];
    
    return [self deliverMessage: messageBody headers: messageHeaders withMailApp: useMail];
}

- (BOOL)deliverMessage:(NSString *)messageBody
               headers:(NSDictionary *)messageHeaders
           withMailApp:(BOOL) mailApp
{
    if( mailApp)
    {
        NSAttributedString* m = [[[NSAttributedString alloc] initWithHTML:[messageBody dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL] autorelease]; // This function is NOT thread safe !
        
        if( [NSThread isMainThread] == NO)
            NSLog( @"************** This function is NOT thread safe : [[NSAttributedString alloc] initWithHTML");
        
        return [self doHandler:@"deliver_message"
                    forMessage:m
                       headers:messageHeaders];
    }
    else
    {
        if (!defaultSMTPAccount)
        {
            defaultSMTPAccount = [[self defaultSMTPAccountFromMail] retain];
            if (!defaultSMTPAccount)
            {
                //We can't do anything without an account.
                NSLog( @"**** MailMe: No suitable SMTP account found");
                return NO;
            }
        }
        
        int mode = SMTPClientTLSModeNone;
        
        if( [[defaultSMTPAccount valueForKey: @"SSLEnabled"] boolValue])
            mode = SMTPClientTLSModeTLSIfPossible;
        
        NSString *fromEmail;
        
        if( [messageHeaders objectForKey:@"Sender"])
            fromEmail = [messageHeaders objectForKey:@"Sender"];
        else
            fromEmail = fromAddress;
        
        NSArray *ports = nil;
        
        if( [defaultSMTPAccount valueForKey: @"PortNumber"])
            ports = [NSArray arrayWithObject: [defaultSMTPAccount valueForKey: @"PortNumber"]];
        else
            ports = [NSArray arrayWithObjects: [NSNumber numberWithInteger:25], [NSNumber numberWithInteger:465], [NSNumber numberWithInteger:587], nil];
            
        [[SMTPClient clientWithServerAddress: [defaultSMTPAccount valueForKey: @"Hostname"]
                                       ports: ports
                                     tlsMode: mode
                                    username: [defaultSMTPAccount valueForKey: @"Username"]
                                    password: [defaultSMTPAccount valueForKey: @"Password"]]
         sendMessage: messageBody
         withSubject: [messageHeaders objectForKey:@"Subject"]
         from: [messageHeaders objectForKey:@"Sender"]
         to: [messageHeaders objectForKey:@"To"]];
        
        return YES;
    }
    
//    {
//        NSString *pathToMailSenderProgram = [[NSBundle bundleForClass:[self class]] pathForResource:@"simple-mailer" ofType:@"py"];
//        
//        NSString *destAddress = [messageHeaders objectForKey:@"To"];
//        
//        [NSMakeCollectable(destAddress) autorelease];
//        
//        if (destAddress)
//        {
//            if([destAddress length])
//            {
//                NSString *title = [messageHeaders objectForKey:@"Subject"];
//                
//                if (!defaultSMTPAccount)
//                {
//                    defaultSMTPAccount = [[self defaultSMTPAccountFromMail] retain];
//                    if (!defaultSMTPAccount) {
//                        //We can't do anything without an account.
//                        NSLog( @"**** MailMe: No suitable SMTP account found");
//                        return NO;
//                    }
//                }
//                
//                BOOL useTLS = [[defaultSMTPAccount objectForKey:@"SSLEnabled"] boolValue];
//                NSString *username = [defaultSMTPAccount objectForKey:@"Username"];
//                NSString *hostname = [defaultSMTPAccount objectForKey:@"Hostname"];
//                NSNumber *port = [defaultSMTPAccount objectForKey:@"PortNumber"];
//                NSString *userAtHostPort = [NSString stringWithFormat:
//                                            (port != nil) ? @"%@@%@:%@" : @"%@@%@",
//                                            username, hostname, port];
//                
//                BOOL success = NO;
//                
//                OSStatus err;
//                UInt32 passwordLength = 0U;
//                void *passwordBytes = NULL;
//                err = SecKeychainFindInternetPassword(/*keychainOrArray*/ NULL,
//                                                      (UInt32)[hostname length], [hostname UTF8String],
//                                                      /*securityDomainLength*/ 0U, /*securityDomain*/ NULL,
//                                                      (UInt32)[username length], [username UTF8String],
//                                                      /*pathLength*/ 0U, /*path*/ NULL,
//                                                      (UInt16)[port integerValue],
//                                                      kSecProtocolTypeSMTP, kSecAuthenticationTypeAny,
//                                                      &passwordLength, &passwordBytes,
//                                                      /*itemRef*/ NULL);
//                
//                if (err != noErr) {
//                    //Try looking it up as a MobileMe account.
//                    NSMutableArray *usernameComponents = [[[username componentsSeparatedByString:@"@"] mutableCopy] autorelease];
//                    [usernameComponents removeLastObject];
//                    username = [usernameComponents componentsJoinedByString:@"@"];
//                    
//                    NSString *serviceName = @"iTools";
//                    
//                    err = SecKeychainFindGenericPassword(/*keychainOrArray*/ NULL,
//                                                         (UInt32)[serviceName length], [serviceName UTF8String],
//                                                         (UInt32)[username length],    [username UTF8String],
//                                                         &passwordLength,              &passwordBytes,
//                                                         /*itemRef*/ NULL);
//                    
//                    if (err != noErr) {
//                        NSLog(@"**** MailMe: Could not get password for SMTP account %@: %i/%s", userAtHostPort, (int)err, GetMacOSStatusCommentString(err));
//                    }
//                }
//                
//                //If we successfully got either a regular SMTP password or a MobileMe password…
//                if (err == noErr) {
//                    //…then let's proceed with sending the message.
//                    NSData *passwordData = [NSData dataWithBytesNoCopy:passwordBytes length:passwordLength freeWhenDone:NO];
//                    
//                    //Use only stock Python and matching modules.
//                    NSDictionary *environment = [NSDictionary dictionaryWithObjectsAndKeys:
//                                                 @"", @"PYTHONPATH",
//                                                 @"/bin:/usr/bin:/usr/local/bin", @"PATH",
//                                                 nil];
//                    NSTask *task = [[[NSTask alloc] init] autorelease];
//                    [task setEnvironment:environment];
//                    [task setLaunchPath:@"/usr/bin/python"];
//                    
//                    [task setArguments:[NSArray arrayWithObjects:
//                                        pathToMailSenderProgram,
//                                        [@"--user-agent=" stringByAppendingFormat:@"OsiriX/%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]],
//                                        useTLS ? @"--tls" : @"--no-tls",
//                                        userAtHostPort,
//                                        fromAddress,
//                                        destAddress,
//                                        /*subject*/ title,
//                                        nil]];
//                    NSPipe *stdinPipe = [NSPipe pipe];
//                    [task setStandardInput:stdinPipe];
//                    
//                    [task launch];
//                    
//                    [[stdinPipe fileHandleForReading] closeFile];
//                    NSFileHandle *stdinFH = [stdinPipe fileHandleForWriting];
//                    [stdinFH writeData:passwordData];
//                    [stdinFH writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
//                    [stdinFH writeData:[[messageBody string] dataUsingEncoding:NSUTF8StringEncoding]];
//                    [stdinFH closeFile];
//                    
//                    [task waitUntilExit];
//                    int status = [task terminationStatus];
//                    success = (status == 0);
//                    if (!success) 
//                        NSLog(@"*****(MailMe) WARNING: Could not send message using simple-mailer; it returned exit status %d.", status);
//                    
//                    SecKeychainItemFreeContent(/*attrList*/ NULL, passwordBytes);
//                }
//                
//                if (!success) {
//                    NSLog(@"***** (MailMe) WARNING: Could not send email message \"%@\" to address %@", title, destAddress);
//                } else
//                    NSLog(@"***** (MailMe) Successfully sent message \"%@\" to address %@", title, destAddress);
//            } else {
//                NSLog(@"***** (MailMe) WARNING: No destination address set");
//            }
//        } else {
//            NSLog(@"***** (MailMe) WARNING: No destination address set");
//        }
//    }
}

- (int)features
{
  return (kCSMCMessageDispatchFeature
	  | kCSMCMessageConstructionFeature);
}

- (NSString *)applicationBundleIdentifier
{
  return @"com.apple.mail";
}
@end
