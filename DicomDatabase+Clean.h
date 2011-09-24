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

#import "DicomDatabase.h"


@interface DicomDatabase (Clean)

-(void)initClean;
-(void)deallocClean;

-(void)initiateCleanUnlessAlreadyCleaning;

-(void)cleanOldStuff;
-(void)cleanForFreeSpace;
-(void)cleanForFreeSpaceMB:(NSInteger)freeMemoryRequested; // so we can allow timed "deep clean"

@end
