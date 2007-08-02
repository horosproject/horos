//
//  CIAAnnotation.h
//  ImageAnnotations
//
//  Created by joris on 25/06/07.
//  Copyright 2007 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CIAPlaceHolder;

@interface CIAAnnotation : NSView {
	BOOL isSelected, isEnabled;
	NSPoint mouseDownLocation;
	CIAPlaceHolder *placeHolder;
	NSColor *color, *backgroundColor;
	NSString *title;
	NSMutableArray *content;
	BOOL isOrientationWidget;
}

+ (NSSize)defaultSize;

- (void)setIsSelected:(BOOL)boo;
- (CIAPlaceHolder*)placeHolder;
- (void)setPlaceHolder:(CIAPlaceHolder*)aPlaceHolder;
- (NSString*)title;
- (void)setTitle:(NSString*)aTitle;
- (NSMutableArray*)content;
- (void)setContent:(NSArray*)newContent;
- (int)countOfContent;
- (NSString*)objectInContentAtIndex:(unsigned)index;
- (void)getContent:(NSString **)strings range:(NSRange)inRange;
- (void)insertObject:(NSString *)string inContentAtIndex:(unsigned int)index;
- (void)removeObjectFromContentAtIndex:(unsigned int)index;

- (NSPoint)mouseDownLocation;
- (void)setMouseDownLocation:(NSPoint)newLocation;
- (void)recomputeMouseDownLocation;

- (void)setEnabled:(BOOL)enabled;
- (BOOL)isOrientationWidget;
- (void)setIsOrientationWidget:(BOOL)boo;

@end
