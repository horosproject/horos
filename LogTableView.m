//
//  LogTableView.m
//  OsiriX
//
//  Created by Lance Pysher on 6/8/05.

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


#import "LogTableView.h"


@implementation LogTableView

- (void)keyDown:(NSEvent *)theEvent{
	if ([[theEvent characters] characterAtIndex:0] == NSDeleteCharacter)
		[[self target] remove:self];
	else
		[super keyDown:(NSEvent *)theEvent];
	
}


@end
