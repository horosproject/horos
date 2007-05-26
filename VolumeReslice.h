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

#import <Cocoa/Cocoa.h>
#import "ViewerController.h"

@interface VolumeReslice : NSObject
{
	ViewerController	*viewer;
	
	float				orientationReslice[ 9];
}

- (void) initWithViewer:(ViewerController*) v;

@end
