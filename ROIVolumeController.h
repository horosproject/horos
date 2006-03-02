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
#import "DCMPix.h"
#import "ViewerController.h"
#import "Window3DController.h"

@class ROIVolumeView;

@interface ROIVolumeController : Window3DController
{
    IBOutlet ROIVolumeView			*view;
	IBOutlet NSTextField			*volumeField;
	
	ViewerController				*viewer;
}

-(id) initWithPoints:(NSMutableArray*) pts :(float) volume :(ViewerController*) iviewer;
@end
