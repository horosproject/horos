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


@interface N2MutableUInteger : NSObject {
	NSUInteger _value;
}

+(id)mutableUIntegerWithUInteger:(NSUInteger)value;

@property NSUInteger unsignedIntegerValue;

-(id)initWithUInteger:(NSUInteger)value;

-(void)increment;
-(void)decrement;

@end
