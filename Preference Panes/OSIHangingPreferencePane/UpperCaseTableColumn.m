//
//  UpperCaseTableColumn.m
//  OSIHangingPreferencePane
//
//  Created by Lance Pysher on 1/3/07.
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
#import "UpperCaseTableColumn.h"
#import "UpperCaseStringFormatter.h"


@implementation UpperCaseTableColumn

- (id)initWithCoder:(NSCoder *)decoder{
	if (self = [super initWithCoder:(NSCoder *)decoder])
		[[self dataCell] setFormatter:[[[UpperCaseStringFormatter alloc] init] autorelease]];		
	return self;
}

@end
