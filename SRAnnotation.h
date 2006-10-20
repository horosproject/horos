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
	id image;
	NSArray *rois;
	BOOL  newSR;
}

- (id)initWithROIs:(NSArray *)ROIs  path:(NSString *)path;

- (void)addROIs:(NSArray *)someROIs;
- (void)addROI:(ROI *)aROI;


- (BOOL)writeToFileAtPath:(NSString *)path;
- (BOOL)save;
- (void)saveAsHTML;

@end
