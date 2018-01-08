/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, Êversion 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE. ÊSee the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos. ÊIf not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program: Ê OsiriX
 ÊCopyright (c) OsiriX Team
 ÊAll rights reserved.
 ÊDistributed under GNU - LGPL
 Ê
 ÊSee http://www.osirix-viewer.com/copyright.html for details.
 Ê Ê This software is distributed WITHOUT ANY WARRANTY; without even
 Ê Ê the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 Ê Ê PURPOSE.
 ============================================================================*/




#import "Photos.h"
#import "NSAppleScript+N2.h"



// if you want check point log info, define CHECK to the next line, uncommented:
#define CHECK NSLog(@"Applescript result code = %d", ok);

//// This converts an AEDesc into a corresponding NSValue.
//
//static id aedesc_to_id(AEDesc *desc)
//{
//	OSErr ok;
//
//	if (desc->descriptorType == typeChar)
//	{
//		NSMutableData *outBytes;
//		NSString *txt;
//
//		outBytes = [[NSMutableData alloc] initWithLength:AEGetDescDataSize(desc)];
//		ok = AEGetDescData(desc, [outBytes mutableBytes], [outBytes length]);
//		CHECK;
//
//		txt = [[NSString alloc] initWithData:outBytes encoding: NSUTF8StringEncoding];
//		[outBytes release];
//		[txt autorelease];
//
//		return txt;
//	}
//
//	if (desc->descriptorType == typeSInt16)
//	{
//		SInt16 buf;
//		
//		AEGetDescData(desc, &buf, sizeof(buf));
//		
//		return [NSNumber numberWithShort:buf];
//	}
//
//	return [NSString stringWithFormat:@"[unconverted AEDesc, type=\"%c%c%c%c\"]", ((char *)&(desc->descriptorType))[0], ((char *)&(desc->descriptorType))[1], ((char *)&(desc->descriptorType))[2], ((char *)&(desc->descriptorType))[3]];
//}

@implementation Photos

- (NSString *) scriptBody:(NSArray*) files
{
	NSString *albumNameStr	= [[NSUserDefaults standardUserDefaults] stringForKey: @"ALBUMNAME"];
	
	
	NSMutableString *s = [NSMutableString stringWithCapacity:1000];
	
    [s appendString:@"tell application \"Photos\"\n"];
//	[s appendString:@"activate\n"];
	
    [s appendString:[NSString stringWithFormat:@"if not (exists album \"%@\") then \n", albumNameStr]];
    [s appendString:[NSString stringWithFormat:@"make new album named \"%@\" \n", albumNameStr]];
    [s appendString:@"end if \n"];
    [s appendString:[NSString stringWithFormat:@"set this_album to album \"%@\" \n", albumNameStr]];
//    [s appendString:@"select this_album \n"]; // not supported in Photos.app
    
    for (id loopItem in files)
        [s appendString:[NSString stringWithFormat:@"import (POSIX file \"%@\" as alias) into this_album skip check duplicates yes \n", loopItem]];
    
    [s appendString:@"end tell \n"];

return s;
}


- (BOOL)importInPhotos: (NSArray*) files
{
	[self runScript:[self scriptBody:files]];
	return YES;
}


// initialize it in your init method:

- (id)init
{
	self = [super init];
	if (self)
	{
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
