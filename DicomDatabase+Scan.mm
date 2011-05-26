//
//  DicomDatabase+Scan.mm
//  OsiriX
//
//  Created by Alessandro Volz on 25.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DicomDatabase+Scan.h"
#import "NSThread+N2.h"


@implementation DicomDatabase (Scan)

-(void)scanAtPath:(NSString*)path {
	NSThread* thread = [NSThread currentThread];
	[thread enterOperation];
	
	for (int i = 0; i < 200; ++i) {
		thread.status = [NSString stringWithFormat:@"Iteration %d.", i];
		[NSThread sleepForTimeInterval:0.1];
	}
	
	[thread exitOperation];
	
	
	
}

@end
