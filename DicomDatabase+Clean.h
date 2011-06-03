//
//  DicomDatabase+Cleaning.h
//  OsiriX
//
//  Created by Alessandro Volz on 19.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"


@interface DicomDatabase (Clean)

-(void)initClean;
-(void)deallocClean;

-(void)initiateCleanUnlessAlreadyCleaning;

-(void)cleanOldStuff;
-(void)cleanForFreeSpace;
-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested; // so we can allow timed "deep clean"

@end
