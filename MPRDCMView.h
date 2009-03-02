//
//  MPRDCMView.h
//  OsiriX
//
//  Created by joris on 2/26/09.
//  Copyright 2009 The OsiriX Foundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DCMView.h"

@interface MPRDCMView : DCMView {
}

- (void)setDCMPixList:(NSMutableArray*)pix filesList:(NSArray*)files volumeData:(NSData*)volume roiList:(NSMutableArray*)rois firstImage:(short)firstImage type:(char)type reset:(BOOL)reset;

@end
