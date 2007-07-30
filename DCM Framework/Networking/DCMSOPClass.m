//
//  DCMSOPClass.m
//  OsiriX
//
//  Created by Lance Pysher on 12/13/04.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
//

/*************
The networking code of the DCMFramework is predominantly a port of the 11/4/04 version of the java pixelmed toolkit by David Clunie.
htt://www.pixelmed.com   
**************/

#import "DCMSOPClass.h"
#import "DCMAssociation.h"


@implementation DCMSOPClass

- (void)dealloc{
	[association release];
	[super dealloc];
}

- (void)associationAborted{
	NSLog(@"delegate associationAborted");
	[association abort];
	[association release];
	association = nil;
}

- (void)associationReleased{
	//[association releaseAssociation];
	NSLog(@"delegate association released");
	[association release];
	association = nil;
}

- (void)abort{
	[association abort];
}

@end
