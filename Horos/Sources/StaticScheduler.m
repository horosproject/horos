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


#import "StaticScheduler.h"

@implementation StaticScheduler

-(void)performScheduleForWorkUnits:(NSSet *)workUnits {
    _numberOfThreadsLeft = [self numberOfThreads];
    [super performScheduleForWorkUnits:workUnits];
}

// Divide units as equally as possible between threads. 
-(NSSet *)_workUnitsToExecuteForRemainingUnits:(NSSet *)remainingUnits {
    int numUnitsLeft = [remainingUnits count];
	int numUnitsThisThread;
	if( _numberOfThreadsLeft == 0)
	{
		numUnitsThisThread = 0;
	}
	else
	{
	int div = _numberOfThreadsLeft + ( 0 != numUnitsLeft % _numberOfThreadsLeft ? 1 : 0 );
	if( div == 0) numUnitsThisThread = 0;
	else numUnitsThisThread = numUnitsLeft / div; // Add 1 if doesn't divide exactly
     }
	 _numberOfThreadsLeft--;
   
	
	return [NSSet setWithArray:
        [[remainingUnits allObjects] subarrayWithRange:NSMakeRange(0, numUnitsThisThread)]];
}


@end