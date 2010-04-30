/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

@interface CIALayoutView : NSControl {
	NSArray *placeHolderArray;
	NSString *disabledText;
	NSString *enabledText;
}

- (void)updatePlaceHolderOrigins;
- (void)updatePlaceHolderOriginsInRect:(NSRect)rect;
- (NSArray*)placeHolderArray;
- (void)setDisabledText:(NSString*)text;
- (void)setDefaultDisabledText;
- (void)setDefaultEnabledText;
@end
