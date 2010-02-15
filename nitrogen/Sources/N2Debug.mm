/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <N2Debug.h>

@implementation N2Debug

static BOOL _active = NO;

+(BOOL)isActive {
	return _active;
}

+(void)setActive:(BOOL)active {
	_active = active;
}

@end