//
//  NSImage+FrameworkImage.m
//  iLifeControls
//
//  Created by Sean Patrick O'Brien on 9/25/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NSImage+FrameworkImage.h"

@class NFIWindow;

@implementation NSImage(FrameworkImageAdditions)

+ (id)frameworkImageNamed:(NSString *)name
{
//	if([NSImage imageNamed:name])
//		return [NSImage imageNamed:name];
		
//	NSBundle *bundle = [NSBundle bundleForClass: [NFIWindow class]];
	NSBundle *bundle = [NSBundle mainBundle];
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:name]] autorelease];
	if(!image)
		return nil;
	[image setName:name];
	
	return image;
}

@end
