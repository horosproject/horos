/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "Mailer.h"


// if you want check point log info, define CHECK to the next line, uncommented:
#define CHECK NSLog(@"result code = %d", ok);

// This converts an AEDesc into a corresponding NSValue.

static id aedesc_to_id(AEDesc *desc)
{
OSErr ok;

if (desc->descriptorType == typeChar)
{
NSMutableData *outBytes;
NSString *txt;

outBytes = [[NSMutableData alloc] initWithLength:AEGetDescDataSize(desc)];
ok = AEGetDescData(desc, [outBytes mutableBytes], [outBytes length]);
CHECK;

txt = [[NSString alloc] initWithData:outBytes encoding:[NSString defaultCStringEncoding]];
[outBytes release];
[txt autorelease];

return txt;
}

if (desc->descriptorType == typeSInt16)
{
SInt16 buf;

AEGetDescData(desc, &buf, sizeof(buf));

return [NSNumber numberWithShort:buf];
}

return [NSString stringWithFormat:@"[unconverted AEDesc, type=\"%c%c%c%c\"]", ((char *)&(desc->descriptorType))[0], ((char *)&(desc->descriptorType))[1], ((char *)&(desc->descriptorType))[2], ((char *)&(desc->descriptorType))[3]];

}

@implementation Mailer


- (NSString *)mailScriptBody:(NSString *)body to:(NSString *)to subject:(NSString *)subject isMIME:(BOOL)isMIME name:(NSString *)clientName sendNow:(BOOL)sendWithoutUserReview image:(NSString*) imagePath
{
NSMutableString *s = [NSMutableString stringWithCapacity:1000];

[s appendString:@"tell application \"Mail\"\n"];
	[s appendString:@"activate\n"];

	[s appendString:@"set composeMessage to make new outgoing message with properties {visible:true}\n"];

	[s appendString:@"tell composeMessage\n"];
	 
	if (isMIME && imagePath != 0L && [[NSFileManager defaultManager] fileExistsAtPath:imagePath])
	{
		[s appendString:[NSString stringWithFormat:@"set aFile to \"%@\"\n",imagePath]];
		[s appendString:@"tell content\n"];
			[s appendString:@"make new attachment with properties {file name:aFile}\n"];
		[s appendString:@"end tell\n"];
	}
	[s appendString:@"end tell\n"];
[s appendString:@"end tell\n"];

NSLog(s);

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
myComponent = OpenDefaultComponent(kOSAComponentType, kOSAGenericScriptingComponentSubtype);
// other initialization code here
}
return self;
}

// do the grunge work -

// the sweetly wrapped method is all we need to know:

- (void)runScript:(NSString *)txt
{
#if __LP64__
	NSTask *theTask = [[NSTask alloc] init];
	
	[[NSFileManager defaultManager] removeFileAtPath: @"/tmp/osascript" handler:0L];
	[txt writeToFile:@"/tmp/osascript" atomically:YES];
	[theTask setArguments: [NSArray arrayWithObjects: @"OSAScript", @"/tmp/osascript", 0L]];
	[theTask setLaunchPath: [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"/32-bit shell.app/Contents/MacOS/32-bit shell"]];
	[theTask launch];
	[theTask waitUntilExit];
	[theTask release];
	return;
#else
NSData *scriptChars = [txt dataUsingEncoding:[NSString defaultCStringEncoding]];
AEDesc source, resultText;
OSAID scriptId, resultId;
OSErr ok;

// Convert the source string into an AEDesc of string type.
ok = AECreateDesc(typeChar, [scriptChars bytes], [scriptChars length], &source);
CHECK;

// Compile the source into a script.
scriptId = kOSANullScript;
ok = OSACompile(myComponent, &source, kOSAModeNull, &scriptId);
AEDisposeDesc(&source);
CHECK;


// Execute the script, using defaults for everything.
resultId = 0;
ok = OSAExecute(myComponent, scriptId, kOSANullScript, kOSAModeNull, &resultId);
CHECK;

if (ok == errOSAScriptError) {
AEDesc ernum, erstr;
id ernumobj, erstrobj;

// Extract the error number and error message from our scripting component.
ok = OSAScriptError(myComponent, kOSAErrorNumber, typeSInt16, &ernum);
CHECK;
ok = OSAScriptError(myComponent, kOSAErrorMessage, typeChar, &erstr);
CHECK;

// Convert them to ObjC types.
ernumobj = aedesc_to_id(&ernum);
AEDisposeDesc(&ernum);
erstrobj = aedesc_to_id(&erstr);
AEDisposeDesc(&erstr);

txt = [NSString stringWithFormat:@"Error, number=%@, message=%@", ernumobj, erstrobj];
} else {
// If no error, extract the result, and convert it to a string for display

if (resultId != 0) { // apple doesn't mention that this can be 0?
ok = OSADisplay(myComponent, resultId, typeChar, kOSAModeNull, &resultText);
CHECK;

//NSLog(@"result thingy type = \"%c%c%c%c\"", ((char *)&(resultText.descriptorType))[0], ((char *)&(resultText.descriptorType))[1], ((char *)&(resultText.descriptorType))[2], ((char *)&(resultText.descriptorType))[3]);

txt = aedesc_to_id(&resultText);
AEDisposeDesc(&resultText);
} else {
txt = @"[no value returned]";
}
OSADispose(myComponent, resultId);
}

ok = OSADispose(myComponent, scriptId);
CHECK;
#endif
}

@end
