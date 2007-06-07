//
//  OSIPoint3D.h
//  OsiriX
//
//  Created by Lance Pysher on 4/26/07.
/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

// This class represents a 3D point;

#import <Cocoa/Cocoa.h>


@interface OSIPoint3D : NSObject {
	float _x;
	float _y;
	float _z;
	NSNumber *_value;
	
	NSMutableSet *_connections;
}

- (float)x;
- (float)y;
- (float)z;

- (void)setX:(float)x;
- (void)setY:(float)y;
- (void)setZ:(float)z;

- (NSNumber *)value;
- (void)setValue:(NSNumber *)value;

// init with x, y, and z
- (id)initWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
// init with the point and the slice
- (id)initWithPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;;

+ (id)pointWithX:(float)x  y:(float)y  z:(float)z value:(NSNumber *)value;
+ (id)pointWithNSPoint:(NSPoint)point  slice:(long)slice value:(NSNumber *)value;

- (NSMutableSet *)connections;
- (void)setConnections:(NSMutableSet *)connections;
- (void)addConnection:(OSIPoint3D *)connection;
- (void)removeConnection:(OSIPoint3D *)connection;
- (BOOL)isEndNode;
- (BOOL)isBranchNode;

@end
