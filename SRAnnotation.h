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
	NSArray *_rois;
	BOOL  _newSR;
	NSString *_seriesInstanceUID;
}

- (id)initWithROIs:(NSArray *)ROIs  path:(NSString *)path;
- (id)initWithContentsOfFile:(NSString *)path;

- (void)addROIs:(NSArray *)someROIs;
- (void)addROI:(ROI *)aROI;
- (NSArray *)ROIs;
- (void)mergeWithSR:(SRAnnotation *)sr;


- (BOOL)writeToFileAtPath:(NSString *)path;
- (BOOL)save;
- (void)saveAsHTML;

- (NSString *)seriesInstanceUID;
- (void)setSeriesInstanceUID: (NSString *)seriesInstanceUID;
- (NSString *)sopInstanceUID;
- (NSString *)sopClassUID;
- (NSString *)seriesDescription;
- (NSString *)seriesNumber;
- (int)frameIndex;

@end
