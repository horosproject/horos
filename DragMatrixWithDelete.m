//
//  DragMatrixWithDelete.m
//  OsiriX
//
//  Created by Lance Pysher on 8/21/06.
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


#import "DragMatrixWithDelete.h"


@implementation DragMatrixWithDelete

- (void)keyDown:(NSEvent *)theEvent{
	if ([[theEvent characters] characterAtIndex:0] == NSDeleteCharacter)
		[arrayController remove:self];
	else
		[super keyDown:(NSEvent *)theEvent];
	
}

@end
