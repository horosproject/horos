//
//  LogWindowController.m
//  OsiriX
//
//  Created by Lance Pysher on 9/20/05.

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


#import "LogWindowController.h"
#import "browserController.h"


@implementation LogWindowController

-(id) init
{
  return  [super initWithWindowNibName:@"LogWindow"];
}

- (NSManagedObjectContext *)managedObjectContext{
}
	
-(void) awakeFromNib
{
	[[self window] setFrameAutosaveName:@"LogWindow"];
}

@end
