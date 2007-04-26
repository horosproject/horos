//
//  NFHUDPopUpButton.m
//  iLife HUD PopUpButton
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDPopUpButton.h"
#import "NFHUDPopUpButtonCell.h"

@implementation NFHUDPopUpButton

+ (Class)cellClass
{
	return [NFHUDPopUpButtonCell class];
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
	}
	
	return self;
}

@end
