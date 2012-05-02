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


@interface DicomDatabase (Scan)

-(BOOL)scanAtPath:(NSString*)path;
+(NSString*)_findDicomdirIn:(NSArray*)allpaths;

@end
