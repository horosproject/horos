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


#import "N2View.h"
@class N2Steps, N2Step, N2StepView, N2ColumnLayout;

@interface N2StepsView : N2View {
	IBOutlet N2Steps* _steps;
}

-(void)stepsDidAddStep:(NSNotification*)notification;
-(N2StepView*)stepViewForStep:(N2Step*)step;
-(void)layOut;

@end
