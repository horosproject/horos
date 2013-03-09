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
