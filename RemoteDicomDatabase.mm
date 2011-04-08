//
//  RemoteDicomDatabase.mm
//  OsiriX
//
//  Created by Alessandro Volz on 04.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "RemoteDicomDatabase.h"


@implementation RemoteDicomDatabase

-(BOOL)isLocal {
	return NO;
}

-(NSString*)name {
	return [NSString stringWithFormat:NSLocalizedString(@"Remote Database (%@)", nil), self.basePath.lastPathComponent];
}

-(void)rebuild:(BOOL)complete {
	// do nothing
}

@end
