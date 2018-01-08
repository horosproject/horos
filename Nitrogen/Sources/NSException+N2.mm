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

#import "NSException+N2.h"
#include <execinfo.h>


NSString* const N2ErrorDomain = @"N2";


@implementation NSException (N2)

-(NSString*)stackTrace {
	NSMutableString* stackTrace = [NSMutableString string];
	
	@try {
		NSArray* addresses = [self callStackReturnAddresses];
		if (addresses.count) {
			void* backtrace_frames[addresses.count];
			for (NSInteger i = (long)addresses.count-1; i >= 0; --i)
				backtrace_frames[i] = (void *)[[addresses objectAtIndex:i] unsignedLongValue];
			
			char** frameStrings = backtrace_symbols(backtrace_frames, (int)addresses.count);
			if (frameStrings) {
				for (int x = 0; x < addresses.count; ++x) {
					if (x) [stackTrace appendString:@"\r"];
					[stackTrace appendString:[NSString stringWithUTF8String:frameStrings[x]]];
				}
				free(frameStrings);
			}
		}
	} @catch (NSException* e)  {
		NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
	}
	
	return stackTrace;	
}

-(NSString*)printStackTrace {
	NSString* stackTrace = [self stackTrace];
	NSLog(@"%@", stackTrace);
	return stackTrace;
}

@end
