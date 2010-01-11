//
//  CSMailMailClient.m
//  CSMail
//
//  Created by Alastair Houghton on 27/01/2006.
//  Copyright 2006 Coriolis Systems Limited. All rights reserved.
//

#import "CSMailMailClient.h"

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
		OSStatus err = AESendMessage(quitApplicationAppleEventPtr, NULL, kAENoReply, kAEDefaultTimeout) ;
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
      } while (![fileManager createDirectoryAtPath:attachtmp attributes:nil]);
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
  
  NSDictionary* UserHeaders = [[[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.Mail"] objectForKey: @"UserHeaders"] mutableCopy] autorelease];
  
  if( [replyto length])
  {
	NSMutableDictionary* defaults = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.Mail"] mutableCopy] autorelease];
	NSMutableDictionary* MutableUserHeaders = [[[defaults objectForKey: @"UserHeaders"] mutableCopy] autorelease];
	
	if( MutableUserHeaders == nil)
		MutableUserHeaders = [NSMutableDictionary dictionary];
	
	[MutableUserHeaders setValue: replyto forKey: @"Reply-To"];
	
	[defaults setObject: MutableUserHeaders forKey: @"UserHeaders"];
	
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: defaults forName: @"com.apple.Mail"];
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
	NSMutableDictionary* defaults = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.Mail"] mutableCopy] autorelease];
	
	if( UserHeaders)
		[defaults setObject: UserHeaders forKey: @"UserHeaders"];
	else
		[defaults removeObjectForKey: @"UserHeaders"];
		
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: defaults forName: @"com.apple.Mail"];
	[[NSUserDefaults standardUserDefaults] synchronize];
 }
 
  return YES;
}

- (BOOL)deliverMessage:(NSAttributedString *)messageBody
	       headers:(NSDictionary *)messageHeaders
{
  return [self doHandler:@"deliver_message"
	      forMessage:messageBody
		 headers:messageHeaders];
}

- (BOOL)constructMessage:(NSAttributedString *)messageBody
		 headers:(NSDictionary *)messageHeaders
{
  return [self doHandler:@"construct_message"
	      forMessage:messageBody
		 headers:messageHeaders];
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
