//
//  SRAnnotation.h
//  OsiriX
//
//  Created by joris on 06/09/06.
//  Copyright 2006 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "dsrdoc.h"

#import "ROI.h"

@interface SRAnnotation : NSObject {
	DSRDocument *document;
}

- (void)addROIs:(NSArray *)someROIs;
- (void)addROI:(ROI *)aROI;
- (BOOL)save;

@end
