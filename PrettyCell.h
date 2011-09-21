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

#import <AppKit/AppKit.h>

@interface PrettyCell : NSButtonCell {
    NSString* _rightText;
    NSMutableArray* _rightSubviews;
    NSColor* _textColor;
}

@property(retain) NSString* rightText;
@property(readonly,retain) NSMutableArray* rightSubviews;
@property(retain) NSColor* textColor;

@end
