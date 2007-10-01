//
//  NFHUDButton.m
//  iLife HUD Button
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.

#import "NFHUDButton.h"
#import "NFHUDButtonCell.h"

@implementation NFHUDButton

+ (Class)cellClass
{
	return [NFHUDButtonCell class];
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
		
		NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
		[attrs addEntriesFromDictionary:[[self attributedTitle] attributesAtIndex:0 effectiveRange:NULL]];
		[attrs setObject:[NSColor whiteColor]forKey:NSForegroundColorAttributeName];
		NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[self title] attributes:attrs];
		[self setAttributedTitle:attrStr];
		[attrStr release];
		[attrs release];
	}
	
	return self;
}

@end
