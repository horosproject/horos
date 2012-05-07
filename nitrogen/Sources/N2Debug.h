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

#import <Cocoa/Cocoa.h>

@interface N2Debug : NSObject {
}

+(BOOL)isActive;
+(void)setActive:(BOOL)active;

@end

#ifdef DEBUG
#define DLog NSLog
#else
#define DLog(args...) { if ([N2Debug isActive]) NSLog(args); }
#endif

#ifdef __cplusplus
extern "C" {
#endif
	
extern NSString* RectString(NSRect r) __deprecated; // use NSStringFromRect
extern NSString* PointString(NSPoint p) __deprecated; // use NSStringFromPoint

extern void _N2LogErrorImpl(const char* pf, const char* fileName, int lineNumber, id arg, ...);
extern void _N2LogExceptionImpl(NSException* e, BOOL logStack, const char* pf);

#define N2LogError(...) _N2LogErrorImpl(__PRETTY_FUNCTION__, __FILE__, __LINE__, __VA_ARGS__)
#define N2LogDeprecatedCall(...) _N2LogErrorImpl(__PRETTY_FUNCTION__, __FILE__, __LINE__, @"deprecated API usage")
#define N2LogException(e, ...) _N2LogExceptionImpl(e, NO, __PRETTY_FUNCTION__, ## __VA_ARGS__)
#define N2LogExceptionWithStackTrace(e, ...) _N2LogExceptionImpl(e, YES, __PRETTY_FUNCTION__, ## __VA_ARGS__)

extern void N2LogStackTrace(NSString* format, ...);

#ifdef __cplusplus
}
#endif
