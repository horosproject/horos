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

#import <Cocoa/Cocoa.h>


@interface NSWindow (N2)

-(NSSize)contentSizeForFrameSize:(NSSize)frameSize;
-(NSSize)frameSizeForContentSize:(NSSize)contentSize;

-(CGFloat)toolbarHeight;

-(void)safelySetMovable:(BOOL)flag;
-(void)safelySetUsesLightBottomGradient:(BOOL)flag;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
enum {
    NSWindowAnimationBehaviorDefault = 0,       // let AppKit infer animation behavior for this window
    NSWindowAnimationBehaviorNone = 2,          // suppress inferred animations (don't animate)
    NSWindowAnimationBehaviorDocumentWindow = 3,
    NSWindowAnimationBehaviorUtilityWindow = 4,
    NSWindowAnimationBehaviorAlertPanel = 5
};
typedef NSInteger NSWindowAnimationBehavior;

@interface NSWindow (SetAnimationBehaviorHackForOldSDKs)
- (void)setAnimationBehavior:(NSWindowAnimationBehavior)newAnimationBehavior;
@end
#endif
