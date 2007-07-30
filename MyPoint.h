/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import <Foundation/Foundation.h>


@interface MyPoint : NSObject  <NSCoding>
{
	NSPoint pt;
}

+ (MyPoint*) point: (NSPoint) a;

- (id) initWithPoint:(NSPoint) a;
- (void) setPoint:(NSPoint) a;
- (float) y;
- (float) x;
- (NSPoint) point;
- (BOOL) isEqualToPoint:(NSPoint) a;
- (BOOL) isNearToPoint:(NSPoint) a :(float) scale :(float) ratio;
- (void) move:(float) x :(float) y;

@end
