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


#import <Foundation/Foundation.h>
#import "Scheduler.h"

/** \brief Static multithreaded  Scheduler */
@interface StaticScheduler : Scheduler {
    @private
    int _numberOfThreadsLeft; // Used to keep track of how many threads already have work
}

-(void)performScheduleForWorkUnits:(NSSet *)workUnits;
-(NSSet *)_workUnitsToExecuteForRemainingUnits:(NSSet *)remainingUnits;

@end