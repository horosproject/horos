//
//  NFIButton.m
//  iLife Button
//
//  Created by Sean Patrick O'Brien on 9/25/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.

#import "NFIButton.h"
#import "NFIButtonCell.h"

@implementation NFIButton

+ (Class)cellClass
{
	return [NFIButtonCell class];
}

- initWithCoder: (NSCoder *)origCoder
{
	if(![origCoder isKindOfClass: [NSKeyedUnarchiver class]]){
		self = [super initWithCoder: origCoder]; 
	} else {
		NSKeyedUnarchiver *coder = (id)origCoder;
		
		NSString *oldClassName = [[[self superclass] cellClass] className];
		Class oldClass = [coder classForClassName: oldClassName];
		if(!oldClass)
			oldClass = [[super superclass] cellClass];
		[coder setClass: [[self class] cellClass] forClassName: oldClassName];
		self = [super initWithCoder: coder];
		[coder setClass: oldClass forClassName: oldClassName];
		[self setFont:[NSFont boldSystemFontOfSize:11.5]];
	}
	
	return self;
}

@end
