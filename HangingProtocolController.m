//
//  HangingProtocolController.m
//  OsiriX
//
//  Created by Lance Pysher on 1/10/07.
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

#import "HangingProtocolController.h"
#import "LayoutWindowController.h";
#import "LayoutArrayController.h"


@implementation HangingProtocolController

- (id)newObject{
	NSLog(@"new Hanging Protocol");
	id hangingProtocol = [super newObject];
	[hangingProtocol setValue:[_layoutWindowController modality] forKey:@"modality"];
	[hangingProtocol setValue:[_layoutWindowController studyDescription] forKey:@"studyDescription"]; 
	[hangingProtocol setObject:[_layoutWindowController institution] forKey:@"institution"]; 
	//[hangingProtocol setValue:[NSArray arrayWithObject:[_layoutArrayController newObject]] forKey:@"layouts"]; 
	[hangingProtocol setValue:[NSArray array] forKey:@"layouts"]; 
	return hangingProtocol;
}

/*
- (void)add:(id)sender{
	[super add:sender];
	//[_layoutArrayController setContent:[[self selection] valueForKey:@"layouts"]];
	//[_layoutArrayController add:self];
}
*/
	
	

@end
