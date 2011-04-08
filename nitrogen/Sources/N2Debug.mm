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


#import <N2Debug.h>
#import <NSException+N2.h>

@implementation N2Debug

static BOOL _active = NO;

+(BOOL)isActive {
	return _active;
}

+(void)setActive:(BOOL)active {
	_active = active;
}

NSString* RectString(NSRect r) {
	return [NSString stringWithFormat:@"[%f,%f,%f,%f]", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

@end

void _N2LogErrorImpl(const char* pf, const char* fileName, int lineNumber, NSString* format, ...) {
	va_list args;
	va_start(args, format);
	NSString* message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
	va_end(args);
	NSLog(@"Error (in %s): %@ (%s:%d)", pf, message, fileName, lineNumber);
}

void _N2LogExceptionImpl(NSException* e, BOOL logStack, const char* pf) {
	_N2LogExceptionImpl(e, logStack, pf, nil);
}

void _N2LogExceptionVImpl(NSException* e, BOOL logStack, const char* pf, NSString* format, va_list args) {
	NSString* message = format? [[[NSString alloc] initWithFormat:format arguments:args] autorelease] : e.name;
	@synchronized(NSApp) {
		NSLog(@"%@ (in %s): %@", message, pf, e);
		if (logStack)
			[e printStackTrace];
	}
}

void _N2LogExceptionImpl(NSException* e, BOOL logStack, const char* pf, NSString* format, ...) {
	va_list args;
	va_start(args, format);
	_N2LogExceptionVImpl(e, logStack, pf, format, args);
	va_end(args);
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

