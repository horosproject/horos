//
//  DicomDatabase+Scan.h
//  OsiriX
//
//  Created by Alessandro Volz on 25.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase.h"


@interface DicomDatabase (Scan)

-(void)scanAtPath:(NSString*)path;

@end
