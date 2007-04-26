//
//  NFHUDWindow.m
//  iLife HUD Window
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.
//

#import "NFHUDWindow.h"
#import "NFHUDFrame.h"

@implementation NFHUDWindow

+ (Class)frameViewClassForStyleMask:(unsigned int)styleMask
{
	return [NFHUDFrame class];
}

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)styleMask 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag
{
	if(self = [super initWithContentRect:contentRect 
                                styleMask:styleMask 
                                  backing:bufferingType 
                                    defer:flag]){
		[self setLevel:NSFloatingWindowLevel];
		return self;
	}
	
	return nil;
}

-(void)awakeFromNib
{
	[self setLevel:NSFloatingWindowLevel];
}

-(BOOL)isOpaque
{
	return NO;
}

@end
