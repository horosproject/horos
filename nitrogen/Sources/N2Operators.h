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

#ifdef __cplusplus
extern "C" {
#endif

extern NSString* N2LinesDontInterceptException;

CGFloat NSSign(const CGFloat f);
CGFloat NSLimit(const CGFloat v, const CGFloat min, const CGFloat max);

extern const NSNumber* const N2Yes;
extern const NSNumber* const N2No;

NSSize NSRoundSize(NSSize s) DEPRECATED_ATTRIBUTE;
NSSize N2ProportionallyScaleSize(NSSize s, NSSize t);
    
NSRect N2FlipRect(NSRect frame, NSRect bounds);

#ifdef __cplusplus
}

namespace n2 {
	NSSize floor(const NSSize& s);
	NSSize ceil(const NSSize& s);
	NSSize round(const NSSize& s);
}

NSSize NSMakeSize(CGFloat wh);
NSSize operator-(const NSSize& s);						// -[x,y] = [-x,-y]
NSSize operator+(const NSSize& s1, const NSSize& s2);	// [x,y]+[X,Y] = [x+X,y+Y]
NSSize operator+=(NSSize& s1, const NSSize& s2);
NSSize operator-(const NSSize& s1, const NSSize& s2);	// [x,y]-[X,Y] = -[X,Y]+[x,y] = [x-X,y-Y]
NSSize operator-=(NSSize& s1, const NSSize& s2);
NSSize operator*(const NSSize& s1, const NSSize& s2);
NSSize operator*=(NSSize& s1, const NSSize& s2);
NSSize operator/(const NSSize& s1, const NSSize& s2);
NSSize operator/=(NSSize& s1, const NSSize& s2);
BOOL operator==(const NSSize& s1, const NSSize& s2);
BOOL operator!=(const NSSize& s1, const NSSize& s2);

NSSize operator+(const NSSize& s, const CGFloat f);
NSSize operator+=(NSSize& s, const CGFloat f);
NSSize operator-(const NSSize& s, const CGFloat f);
NSSize operator-=(NSSize& s, const CGFloat f);
NSSize operator*(const CGFloat f, const NSSize& s);		// [x,y]*d = [x*d,y*d]
NSSize operator/(const CGFloat f, const NSSize& s);
NSSize operator*(const NSSize& s, const CGFloat f);
NSSize operator*=(NSSize& s, const CGFloat f);
NSSize operator/(const NSSize& s, const CGFloat f);
NSSize operator/=(NSSize& s, const CGFloat f);

NSPoint operator-(const NSPoint& p);						// -[x,y] = [-x,-y]
NSPoint operator+(const NSPoint& p1, const NSPoint& p2);	// [x,y]+[X,Y] = [x+X,y+Y]
NSPoint operator+=(NSPoint& p1, const NSPoint& p2);
NSPoint operator-(const NSPoint& p1, const NSPoint& p2);	// [x,y]-[X,Y] = -[X,Y]+[x,y] = [x-X,y-Y]
NSPoint operator-=(NSPoint& p1, const NSPoint& p2);
NSPoint operator*(const NSPoint& p1, const NSPoint& p2);
NSPoint operator*=(NSPoint& p1, const NSPoint& p2);
NSPoint operator/(const NSPoint& p1, const NSPoint& p2);
NSPoint operator/=(NSPoint& p1, const NSPoint& p2);
BOOL operator==(const NSPoint& p1, const NSPoint& p2);
BOOL operator!=(const NSPoint& p1, const NSPoint& p2);

NSPoint operator+(const NSPoint& p, const CGFloat f);
NSPoint operator+=(NSPoint& p, const CGFloat f);
NSPoint operator-(const NSPoint& p, const CGFloat f);
NSPoint operator-=(NSPoint& p, const CGFloat f);
NSPoint operator*(const CGFloat f, const NSPoint& p);
NSPoint operator/(const CGFloat f, const NSPoint& p);
NSPoint operator*(const NSPoint& p, const CGFloat f);		// [x,y]*d = [x*d,y*d]
NSPoint operator*=(NSPoint& p, const CGFloat f);
NSPoint operator/(const NSPoint& p, const CGFloat f);		// [x,y]/d = [x/d,y/d]
NSPoint operator/=(NSPoint& p, const CGFloat f);

NSPoint NSMakePoint(const NSSize& s);
NSSize operator+(const NSSize& s, const NSPoint& p);
NSSize operator+=(NSSize& s, const NSPoint& p);
NSPoint operator+(const NSPoint& p, const NSSize& s);
NSPoint operator+=(NSPoint& p, const NSSize& s);
NSSize operator-(const NSSize& s, const NSPoint& p);
NSPoint operator-(const NSPoint& p, const NSSize& s);
NSSize operator*(const NSSize& s, const NSPoint& p);
NSPoint operator*(const NSPoint& p, const NSSize& s);
NSSize operator/(const NSSize& s, const NSPoint& p);
NSPoint operator/(const NSPoint& p, const NSSize& s);

CGFloat NSDistance(const NSPoint& p1, const NSPoint& p2);
CGFloat NSAngle(const NSPoint& p1, const NSPoint& p2);
NSPoint NSMiddle(const NSPoint& p1, const NSPoint& p2);

typedef struct _NSVector : NSPoint {
} NSVector;

NSVector NSMakeVector(CGFloat x, CGFloat y);
NSVector NSMakeVector(const NSPoint& from, const NSPoint& to);
NSVector NSMakeVector(const NSPoint& p);
NSPoint NSMakePoint(const NSVector& p);

NSVector operator!(const NSVector& v);

CGFloat NSLength(const NSVector& v);
CGFloat NSAngle(const NSVector& v);

typedef struct _NSLine {
    NSPoint origin;
	NSVector direction;
} NSLine;

NSLine NSMakeLine(const NSPoint& origin, const NSVector& direction);
NSLine NSMakeLine(const NSPoint& p1, const NSPoint& p2);

CGFloat NSAngle(const NSLine& l);
BOOL NSParallel(const NSLine& l1, const NSLine& l2);
CGFloat NSLineInterceptionValue(const NSLine& l1, const NSLine& l2);
NSPoint NSLineAtValue(const NSLine& l, CGFloat u);
NSPoint operator*(const NSLine& l1, const NSLine& l2);		// intersection of lines
CGFloat NSLineYAtX(const NSLine& l1, CGFloat x);

NSRect NSMakeRect(const NSPoint& o, const NSSize& s);
NSRect NSInsetRect(const NSRect& r, const NSSize& s);
NSRect operator+(const NSRect& r, const NSSize& s);
NSRect operator-(const NSRect& r, const NSSize& s);
BOOL operator==(const NSRect& r1, const NSRect& r2);
BOOL operator!=(const NSRect& r1, const NSRect& r2);
NSPoint RectBR(const NSRect& r);

#endif

