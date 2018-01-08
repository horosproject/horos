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


#import <N2Operators.h>
#include <cmath>

#ifdef __cplusplus
extern "C" {
#endif

NSString* N2LinesDontInterceptException = @"N2LinesDontInterceptException";

// CGFloat

CGFloat NSSign(CGFloat f) {
	return f<0? -1 : 1;
}

CGFloat NSLimit(const CGFloat v, const CGFloat min, const CGFloat max) {
	if (v < min) return min;
	if (v > max) return max;
	return v;
}

const NSNumber* const N2Yes = [[NSNumber alloc] initWithBool:YES];
const NSNumber* const N2No = [[NSNumber alloc] initWithBool:NO];

NSSize NSRoundSize(NSSize s) {
    return n2::round(s);
}

NSSize N2ProportionallyScaleSize(NSSize s, NSSize t) {
    if (NSEqualSizes(s, t))
        return t;
    return s * MIN(t.width/s.width, t.height/s.height);
}
    
NSRect N2FlipRect(NSRect frame, NSRect bounds) {
    frame.origin.y = bounds.size.height-frame.origin.y-frame.size.height;
    return frame;
}

#ifdef __cplusplus
}
#endif
    
/// NSSize

namespace n2 {
	
	NSSize floor(const NSSize& s) {
		return NSMakeSize(std::floor(s.width), std::floor(s.height));
	}
	
	NSSize ceil(const NSSize& s) {
		return NSMakeSize(std::ceil(s.width), std::ceil(s.height));
	}
	
	NSSize round(const NSSize& s) {
		return floor(s+0.5);
	}
	
}

NSSize NSMakeSize(CGFloat wh) {
	return NSMakeSize(wh, wh);
}

NSSize operator-(const NSSize& s) {
	return NSMakeSize(-s.width, -s.height);
}

NSSize operator+(const NSSize& s1, const NSSize& s2) {
	return NSMakeSize(s2.width+s1.width, s2.height+s1.height);
}

NSSize operator+=(NSSize& s1, const NSSize& s2) {
	return s1 = s1+s2;
}

NSSize operator-(const NSSize& s1, const NSSize& s2) {
	return s1+(-s2);
}

NSSize operator-=(NSSize& s1, const NSSize& s2) {
	return s1 = s1-s2;
}

NSSize operator*(const NSSize& s1, const NSSize& s2) {
	return NSMakeSize(s1.width*s2.width, s1.height*s2.height);
}

NSSize operator*=(NSSize& s1, const NSSize& s2) {
	return s1 = s1*s2;
}

NSSize operator/(const NSSize& s1, const NSSize& s2) {
	return s1*(1/s2);
}

NSSize operator/=(NSSize& s1, const NSSize& s2) {
	return s1 = s1/s2;
}

BOOL operator==(const NSSize& s1, const NSSize& s2) {
	return (s1.width==s2.width) && (s1.height==s2.height);
}

BOOL operator!=(const NSSize& s1, const NSSize& s2) {
	return !(s1==s2);
}

// NSSize & CGFloat

NSSize operator+(const NSSize& s, const CGFloat f) {
	return NSMakeSize(s.width+f, s.height+f);
}

NSSize operator+=(NSSize& s, const CGFloat f) {
	return s = s+f;
}

NSSize operator-(const NSSize& s, const CGFloat f) {
	return s+(-f);
}

NSSize operator-=(NSSize& s, const CGFloat f) {
	return s = s-f;
}

NSSize operator*(const CGFloat f, const NSSize& s) {
	return NSMakeSize(f*s.width, f*s.height);
}

NSSize operator/(const CGFloat f, const NSSize& s) {
	return NSMakeSize(f/s.width, f/s.height);
}

NSSize operator*(const NSSize& s, const CGFloat f) {
	return f*s;
}

NSSize operator*=(NSSize& s, const CGFloat f) {
	return s = s*f;
}

NSSize operator/(const NSSize& s, const CGFloat f) {
	return s*(1/f);
}

NSSize operator/=(NSSize& s, const CGFloat f) {
	return s = s/f;
}


/// NSPoint

NSPoint operator-(const NSPoint& p) {
	return NSMakePoint(-p.x, -p.y);
}

NSPoint operator+(const NSPoint& p1, const NSPoint& p2) {
	return NSMakePoint(p2.x+p1.x, p2.y+p1.y);
}

NSPoint operator+=(NSPoint& p1, const NSPoint& p2) {
	return p1 = p1+p2;
}

NSPoint operator-(const NSPoint& p1, const NSPoint& p2) {
	return p1+(-p2);
}

NSPoint operator-=(NSPoint& p1, const NSPoint& p2) {
	return p1 = p1-p2;
}

NSPoint operator*(const NSPoint& p1, const NSPoint& p2) {
	return NSMakePoint(p1.x*p2.x, p1.y*p2.y);
}

NSPoint operator*=(NSPoint& p1, const NSPoint& p2) {
	return p1 = p1*p2;
}

NSPoint operator/(const NSPoint& p1, const NSPoint& p2) {
	return p1*(1/p2);
}

NSPoint operator/=(NSPoint& p1, const NSPoint& p2) {
	return p1 = p1/p2;
}

BOOL operator==(const NSPoint& p1, const NSPoint& p2) {
	return (p1.x==p2.x) && (p1.y==p2.y);
}

BOOL operator!=(const NSPoint& p1, const NSPoint& p2) {
	return !(p1==p2);
}

// NSPoint & CGFloat

NSPoint operator+(const NSPoint& p, const CGFloat f) {
	return NSMakePoint(p.x+f, p.y+f);
}

NSPoint operator+=(NSPoint& p, const CGFloat f) {
	return p = p+f;
}

NSPoint operator-(const NSPoint& p, const CGFloat f) {
	return p+(-f);
}

NSPoint operator-=(NSPoint& p, const CGFloat f) {
	return p = p-f;
}

NSPoint operator*(const CGFloat f, const NSPoint& p) {
	return NSMakePoint(f*p.x, f*p.y);
}

NSPoint operator/(const CGFloat f, const NSPoint& p) {
	return NSMakePoint(f/p.x, f/p.y);
}

NSPoint operator*(const NSPoint& p, const CGFloat f) {
	return f*p;
}

NSPoint operator*=(NSPoint& p, const CGFloat f) {
	return p = p*f;
}

NSPoint operator/(const NSPoint& p, const CGFloat f) {
	return p*(1/f);
}

NSPoint operator/=(NSPoint& p, const CGFloat f) {
	return p = p/f;
}

// NSPoint & NSSize

NSPoint NSMakePoint(const NSSize& s) {
	return NSMakePoint(s.width, s.height);
}

NSSize operator+(const NSSize& s, const NSPoint& p) {
	return NSMakeSize(p.x+s.width, p.y+s.height);
}

NSSize operator+=(NSSize& s, const NSPoint& p) {
	return s = s+p;
}

NSPoint operator+(const NSPoint& p, const NSSize& s) {
	return NSMakePoint(p.x+s.width, p.y+s.height);
}

NSPoint operator+=(NSPoint& p, const NSSize& s) {
	return p = p+s;
}

NSSize operator-(const NSSize& s, const NSPoint& p) {
	return s+(-p);
}

NSPoint operator-(const NSPoint& p, const NSSize& s) {
	return p+(-s);
}

NSSize operator*(const NSSize& s, const NSPoint& p) {
	return NSMakeSize(p.x*s.width, p.y*s.height);
}

NSPoint operator*(const NSPoint& p, const NSSize& s) {
	return NSMakePoint(p.x*s.width, p.y*s.height);
}

NSSize operator/(const NSSize& s, const NSPoint& p) {
	return s*(1/p);
}

NSPoint operator/(const NSPoint& p, const NSSize& s) {
	return p*(1/s);
}


/// NSVector

NSVector NSMakeVector(CGFloat x, CGFloat y) {
	NSVector vector;
	vector.x = x;
	vector.y = y;
	return vector;
}

NSVector NSMakeVector(const NSPoint& p1, const NSPoint& p2) {
	return NSMakeVector(p2.x-p1.x, p2.y-p1.y);
}

NSVector NSMakeVector(const NSPoint& p) {
	return NSMakeVector(p.x, p.y);
}

NSPoint NSMakePoint(const NSVector& v) {
	return NSMakePoint(v.x, v.y);
}

NSVector operator!(const NSVector& v) {
	return NSMakeVector(-v.y, v.x);
}

CGFloat NSAngle(const NSVector& v) {
//	if (v.x == 0)
//		return -pi/2*NSSign(v.y);
	return atan2f(v.y, v.x);
}

CGFloat NSLength(const NSVector& v) {
	return std::sqrt(std::pow(v.x, 2)+std::pow(v.y, 2));
}

// other

CGFloat NSDistance(const NSPoint& p1, const NSPoint& p2) {
	return NSLength(NSMakeVector(p1, p2));
}

CGFloat NSAngle(const NSPoint& p1, const NSPoint& p2) {
	return NSAngle(NSMakeVector(p1, p2));
}

NSPoint NSMiddle(const NSPoint& p1, const NSPoint& p2) {
	return (p1+p2)/2;
}

// NSLine

NSLine NSMakeLine(const NSPoint& origin, const NSVector& direction) {
	NSLine line;
	line.origin = origin;
	line.direction = direction;
	return line;
}

NSLine NSMakeLine(const NSPoint& p1, const NSPoint& p2) {
	return NSMakeLine(p1, NSMakeVector(p1, p2));
}

CGFloat NSAngle(const NSLine& l) {
	return NSAngle(l.direction);
}

BOOL NSParallel(const NSLine& l1, const NSLine& l2) {
	return NSAngle(l1) == NSAngle(l2);
}

CGFloat NSLineInterceptionValue(const NSLine& l1, const NSLine& l2) {
	if (NSParallel(l1, l2))
		[NSException raise:N2LinesDontInterceptException format:@"The two lines are parallel and therefore have no interception."];
	return (l2.direction.x*(l1.origin.y-l2.origin.y)-l2.direction.y*(l1.origin.x-l2.origin.x))/(l2.direction.y*l1.direction.x-l2.direction.x*l1.direction.y);
}

NSPoint NSLineAtValue(const NSLine& l, CGFloat u) {
	return NSMakePoint(l.origin.x+u*l.direction.x, l.origin.y+u*l.direction.y);
}

NSPoint operator*(const NSLine& l1, const NSLine& l2) {
	return NSLineAtValue(l1, NSLineInterceptionValue(l1, l2));
}

CGFloat NSLineYAtX(const NSLine& l, CGFloat x) {
	if (l.direction.x)
		return l.origin.y+l.direction.y/l.direction.x*x;
	else return l.origin.y; // TODO: return NAN or exception
}

// NSRect

NSRect NSMakeRect(const NSPoint& o, const NSSize& s) {
	return NSMakeRect(o.x, o.y, s.width, s.height);
}

NSRect NSInsetRect(const NSRect& r, const NSSize& s) {
	return NSInsetRect(r, s.width, s.height);
}

NSRect operator+(const NSRect& r, const NSSize& s) {
	return NSMakeRect(r.origin, r.size+s);
}

NSRect operator-(const NSRect& r, const NSSize& s) {
	return NSMakeRect(r.origin, r.size-s);
}

BOOL operator==(const NSRect& r1, const NSRect& r2) {
	return (r1.origin==r2.origin) && (r1.size==r2.size);
}

BOOL operator!=(const NSRect& r1, const NSRect& r2) {
	return !(r1==r2);
}

NSPoint RectBR(const NSRect& r) {
	return r.origin+r.size;
}

