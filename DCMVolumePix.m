//
//  DCMVolumePix.m
//  OsiriX
//
//  Created by Lance Pysher on 3/15/07.

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


#import "DCMVolumePix.h"


@implementation DCMVolumePix

- (long) pwidth {
	return width;
}

- (long) pheight {
	return height;
}

@end
