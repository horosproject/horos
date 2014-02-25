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




#import "Mailer.h"
#import "NSAppleScript+N2.h"

// if you want check point log info, define CHECK to the next line, uncommented:
#define CHECK NSLog(@"Applescript result code = %d", ok);

// This converts an AEDesc into a corresponding NSValue.

//static id aedesc_to_id(AEDesc *desc)
//{
//OSErr ok;
//
//if (desc->descriptorType == typeChar)
//{
//NSMutableData *outBytes;
//NSString *txt;
//
//outBytes = [[NSMutableData alloc] initWithLength:AEGetDescDataSize(desc)];
//ok = AEGetDescData(desc, [outBytes mutableBytes], [outBytes length]);
//CHECK;
//
//txt = [[NSString alloc] initWithData:outBytes encoding: NSUTF8StringEncoding];
//[outBytes release];
//[txt autorelease];
//
//return txt;
//}
//
//if (desc->descriptorType == typeSInt16)
//{
//SInt16 buf;
//
//AEGetDescData(desc, &buf, sizeof(buf));
//
//return [NSNumber numberWithShort:buf];
//}
//
//return [NSString stringWithFormat:@"[unconverted AEDesc, type=\"%c%c%c%c\"]", ((char *)&(desc->descriptorType))[0], ((char *)&(desc->descriptorType))[1], ((char *)&(desc->descriptorType))[2], ((char *)&(desc->descriptorType))[3]];
//
//}

@implementation Mailer


- (NSString *)mailScriptBody:(NSString *)body to:(NSString *)to subject:(NSString *)subject isMIME:(BOOL)isMIME name:(NSString *)clientName sendNow:(BOOL)sendWithoutUserReview image:(NSString*) imagePath
{
NSMutableString *s = [NSMutableString stringWithCapacity:1000];

[s appendString:@"tell application \"Mail\"\n"];
	[s appendString:@"activate\n"];

	[s appendString:@"set composeMessage to make new outgoing message with properties {visible:true}\n"];

	[s appendString:@"tell composeMessage\n"];
	 
	if (isMIME && imagePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:imagePath])
	{
		[s appendString:[NSString stringWithFormat:@"set aFile to \"%@\"\n",imagePath]];
		[s appendString:@"tell content\n"];
			[s appendString:@"make new attachment with properties {file name:aFile}\n"];
		[s appendString:@"end tell\n"];
	}
	[s appendString:@"end tell\n"];
[s appendString:@"end tell\n"];

NSLog( @"%@", s);

return s;
}


- (BOOL)sendMail:(NSString *)richBody to:(NSString *)to subject:(NSString *)subject isMIME:(BOOL)isMIME name:(NSString *)client sendNow:(BOOL)sendWithoutUserReview image:(NSString*) imagePath
{
	[self runScript:[self mailScriptBody:richBody to:to subject:subject isMIME:isMIME name:client sendNow: sendWithoutUserReview image:imagePath]];
	return YES;
}


// initialize it in your init method:

- (id)init {
self = [super init];
if (self) {
//myComponent = OpenDefaultComponent(kOSAComponentType, kOSAGenericScriptingComponentSubtype);
// other initialization code here
}
return self;
}

// do the grunge work -

// the sweetly wrapped method is all we need to know:

- (void)runScript:(NSString *)txt
{
    NSAppleScript* as = [[[NSAppleScript alloc] initWithSource:txt] autorelease];
    NSDictionary* errs = nil;
    [as runWithArguments:nil error:&errs];
    if ([errs count])
        NSLog(@"Error: AppleScript execution failed: %@", errs);
}

@end
