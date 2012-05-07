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
