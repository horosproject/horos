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

#import "N2DisclosureBox.h"
@class N2Step;

@interface N2StepView : N2DisclosureBox {
	N2Step* _step;
}

@property(readonly) N2Step* step;

-(id)initWithStep:(N2Step*)step;

@end
