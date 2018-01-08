/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX Project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/

#import "ComparativeCell.h"
#import "NSString+N2.h"
#import "N2Operators.h"
#import "N2Debug.h"
#import "BrowserController.h"

@implementation ComparativeCell

@synthesize rightTextFirstLine = _rightTextFirstLine;
@synthesize rightTextSecondLine = _rightTextSecondLine;
@synthesize leftTextSecondLine = _leftTextSecondLine;
@synthesize leftTextFirstLine = _leftTextFirstLine;
@synthesize textColor = _textColor;

-(id)init
{
    if ((self = [super init]))
    {
        [self setImagePosition:NSImageLeft];
        [self setAlignment:NSLeftTextAlignment];
        [self setHighlightsBy:NSNoCellMask];
        [self setShowsStateBy:NSNoCellMask];
        [self setBordered:NO];
        [self setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [self setButtonType:NSMomentaryChangeButton];
    }
    
    return self;
}

-(void)dealloc
{
    self.textColor = nil;
    self.rightTextFirstLine = nil;
    self.rightTextSecondLine = nil;
    self.leftTextSecondLine = nil;
    self.leftTextFirstLine = nil;
    [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone
{
    ComparativeCell* copy = [super copyWithZone:zone];
    
    copy->_rightTextFirstLine = [self.rightTextFirstLine copyWithZone:zone];
    copy->_rightTextSecondLine = [self.rightTextSecondLine copyWithZone:zone];
    copy->_leftTextSecondLine = [self.leftTextSecondLine copyWithZone:zone];
    copy->_leftTextFirstLine = [self.leftTextFirstLine copyWithZone:zone];
    copy->_textColor = [self.textColor copyWithZone:zone];
    
    return copy;
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView
{
    frame.origin.x += 1;
    
    [super drawImage:image withFrame:frame inView:controlView];
}

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    [[NSColor colorWithCalibratedWhite:0.666 alpha:0.333] setStroke];
    [NSBezierPath setDefaultLineWidth:1];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height+1.5) toPoint:NSMakePoint(frame.origin.x+frame.size.width, frame.origin.y+frame.size.height+1.5)];

    [super drawWithFrame:frame inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    frame.size.width -= 1;
    
    NSRect initialFrame = frame;
    static const CGFloat spacer = 2;

    NSMutableAttributedString* mutableTitle = [[title mutableCopy] autorelease];
    if (self.textColor) [mutableTitle addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.textColor, NSForegroundColorAttributeName, nil] range:mutableTitle.range];
    title = mutableTitle;
    
    if( [BrowserController horizontalHistory])
    {
        NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
        
        NSString* text = self.leftTextFirstLine;
        if (!text.length) {
            NSColor* color = [attributes valueForKey:NSForegroundColorAttributeName];
            text = @"Unnamed";
            [attributes setObject:[color blendedColorWithFraction:0.4 ofColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1]] forKey:NSForegroundColorAttributeName];
        }
        
        if (self.leftTextSecondLine.length)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* leftAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [leftAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
            [leftAlignmentParagraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
            [attributes setObject:leftAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            frame.origin.y += 1;
            [self.leftTextSecondLine drawInRect:frame withAttributes:attributes];
            frame.origin.y -= 1;
        }
        
        frame.origin.x += 80;
        
        NSMutableParagraphStyle* leftAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [leftAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
        [leftAlignmentParagraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
        [attributes setObject:leftAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
        
        frame.origin.y += 1;
        [text drawInRect:frame withAttributes:attributes];
        frame.origin.y -= 1;
        
        frame.origin.x += 330;
        
        if (self.rightTextSecondLine.length)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [rightAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
            [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            frame.origin.y += 1;
            [self.rightTextSecondLine drawInRect:frame withAttributes:attributes];
            frame.origin.y -= 1;
            
//            CGFloat w = [self.rightTextSecondLine sizeWithAttributes:attributes].width;
        }
        
        frame.origin.x += 110;
        
        if (self.rightTextFirstLine)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [rightAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
            [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            frame.origin.y += 1;
            [self.rightTextFirstLine drawInRect:frame withAttributes:attributes];
            frame.origin.y -= 1;
            
//            CGFloat w = [self.rightTextFirstLine sizeWithAttributes:attributes].width;
        }
    }
    else
    {
        // First Line
        if (self.rightTextFirstLine)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [rightAlignmentParagraphStyle setAlignment:NSRightTextAlignment];
            [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];

            frame.origin.y += 1;
            [self.rightTextFirstLine drawInRect:frame withAttributes:attributes];
            frame.origin.y -= 1;
            
            CGFloat w = [self.rightTextFirstLine sizeWithAttributes:attributes].width;
            frame.size.width -= w + spacer;
        }
        
        if (true)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            
            NSString* text = self.leftTextFirstLine;
            if (!text.length) {
                NSColor* color = [attributes valueForKey:NSForegroundColorAttributeName];
                text = @"Unnamed";
                [attributes setObject:[color blendedColorWithFraction:0.4 ofColor:[NSColor colorWithCalibratedWhite:0.5 alpha:1]] forKey:NSForegroundColorAttributeName];
            }
            
            NSMutableParagraphStyle* leftAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [leftAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
            [leftAlignmentParagraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
            [attributes setObject:leftAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            frame.origin.y += 1;
            [text drawInRect:frame withAttributes:attributes];
            frame.origin.y -= 1;
        }
        
        // Second Line
        frame = initialFrame;
        
        if (self.rightTextSecondLine.length)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* rightAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [rightAlignmentParagraphStyle setAlignment:NSRightTextAlignment];
            [attributes setObject:rightAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            initialFrame.origin.y += [[BrowserController currentBrowser] fontSize: @"comparativeLineSpace"];
            [self.rightTextSecondLine drawInRect:initialFrame withAttributes:attributes];
            initialFrame.origin.y -= [[BrowserController currentBrowser] fontSize: @"comparativeLineSpace"];
            
            CGFloat w = [self.rightTextSecondLine sizeWithAttributes:attributes].width;
            frame.size.width -= w + spacer;
        }
        
        if (self.leftTextSecondLine.length)
        {
            NSMutableDictionary* attributes = [[[self.attributedTitle attributesAtIndex:0 effectiveRange:NULL] mutableCopy] autorelease];
            NSMutableParagraphStyle* leftAlignmentParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
            [leftAlignmentParagraphStyle setAlignment:NSLeftTextAlignment];
            [leftAlignmentParagraphStyle setLineBreakMode: NSLineBreakByTruncatingTail];
            [attributes setObject:leftAlignmentParagraphStyle forKey:NSParagraphStyleAttributeName];
            
            frame.origin.y += [[BrowserController currentBrowser] fontSize: @"comparativeLineSpace"];
            [self.leftTextSecondLine drawInRect:frame withAttributes:attributes];
            frame.origin.y -= [[BrowserController currentBrowser] fontSize: @"comparativeLineSpace"];
        }
    }
    
    return initialFrame;
}

- (BOOL)trackMouse:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
    return NO;
}

-(void)setPlaceholderString:(NSString*)str
{
    // this is a dummy function... AppKit calls this, and if we don't implement it, it fails
}

@end
