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

@interface ComparativeCell : NSButtonCell
{
    NSString *_rightTextFirstLine, *_rightTextSecondLine, *_leftTextSecondLine, *_leftTextFirstLine;
    NSColor *_textColor;
}

@property(retain) NSString *rightTextFirstLine, *rightTextSecondLine, *leftTextSecondLine, *leftTextFirstLine;
@property(retain) NSColor *textColor;

@end
