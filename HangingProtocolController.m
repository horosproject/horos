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
	id hangingProtocol = [super newObject];
	NSLog(@"new Object");
	[hangingProtocol setValue:[_layoutWindowController modality] forKey:@"modality"];
	[hangingProtocol setValue:[_layoutWindowController studyDescription] forKey:@"studyDescription"]; 
	[hangingProtocol setValue:[_layoutWindowController institution] forKey:@"institution"];
	NSLog(@"get Layout"); 
	id layout = [[_layoutArrayController newObject] autorelease];
	NSLog(@"new Layout: %@", layout);
	[hangingProtocol setValue:[NSArray arrayWithObject:layout] forKey:@"layouts"]; 
	NSLog(@"new Hanging Protocol: %@", hangingProtocol);
	return hangingProtocol;
}


	
	

@end
