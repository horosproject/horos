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


#import "N2Debug.h"
#import "NSException+N2.h"

@implementation N2Debug

static BOOL _active = NO;

+(BOOL)isActive {
	return _active;
}

+(void)setActive:(BOOL)active {
	_active = active;
}

@end

extern "C" {

NSString* RectString(NSRect r) {
	return [NSString stringWithFormat:@"[%f,%f,%f,%f]", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

NSString* PointString(NSPoint p) {
	return [NSString stringWithFormat:@"[%f,%f]", p.x, p.y];
}
	
void _N2LogErrorImpl(const char* pf, const char* fileName, int lineNumber, id arg, ...) {
	va_list args;
	va_start(args, arg);
	
	NSString* message = @"no details";
	if ([arg isKindOfClass:[NSString class]])
		message = [[[NSString alloc] initWithFormat:arg arguments:args] autorelease];
	if ([arg isKindOfClass:[NSError class] ])
		message = [(NSError*)arg description];
	
	va_end(args);
	NSLog(@"Error (in %s): %@ (%s:%d)", pf, message, fileName, lineNumber);
}

void _N2LogExceptionVImpl(NSException* e, BOOL logStack, const char* pf, NSString* format, va_list args) {
	NSString* message = format? [[[NSString alloc] initWithFormat:format arguments:args] autorelease] : e.name;
	@synchronized(NSApp) {
		NSLog(@"%@ (in %s): %@%@", message, pf, e, logStack? [NSString stringWithFormat:@"\n%@", e.stackTrace] : @"");
	}
}
	
void _N2LogExceptionImpl(NSException* e, BOOL logStack, const char* pf) {
	_N2LogExceptionVImpl(e, logStack, pf, nil, nil);
}

extern void N2LogStackTrace(NSString* format, ...) {
	va_list args;
	va_start(args, format);
	
	@try {
		[NSException raise:NSGenericException format:@""];
	} @catch (NSException* e) {
		_N2LogExceptionVImpl(e, YES, "", format, args);
	}

	va_end(args);
}

}
