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


#import "DCMCalendarScript.h"

@implementation DCMCalendarScript

- (id)initWithCalendar:(NSString *)calendar{
	if (self = [super init]) {
		NSString *rootScript = [[[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"iCal script" ofType:@"applescript"]] autorelease];
		NSString *script = [NSString stringWithFormat:@"set the source_calendar to \"%@\"\n%@", calendar, rootScript];
		compiledScript = [[NSAppleScript alloc] initWithSource:script];
		
		
		//Important:  You should access NSAppleScript only from the main thread.
		[compiledScript performSelectorOnMainThread:@selector(compileAndReturnError:) withObject:nil waitUntilDone: YES];
//		[compiledScript compileAndReturnError:nil];
	}
	return self;
}

- (void)dealloc{
	[compiledScript  release];
	[super dealloc];
}

- (void) routingDestination: (NSMutableArray*) routingDestination
{
	NSAppleEventDescriptor *description  = [compiledScript executeAndReturnError:nil];
	NSString *route = [description stringValue];
	if (route && ![route isEqualToString: @""]) {
		NSArray *routes = [route componentsSeparatedByString:@"/"];
		NSString *nextRoute;
		for (nextRoute in routes) {
			NSMutableArray *routeParams = [NSMutableArray arrayWithArray:[nextRoute componentsSeparatedByString:@":"]];
			[routingDestination addObject:routeParams];
		}
	}
}

- (NSMutableArray *)routingDestination
{
	NSMutableArray *routingDestination = [NSMutableArray array];
	
	//Important:  You should access NSAppleScript only from the main thread.
	[self performSelectorOnMainThread:@selector(routingDestination:) withObject:routingDestination waitUntilDone: YES];
	
	if( [routingDestination count] > 0) return routingDestination;
	else return nil;
}

@end
