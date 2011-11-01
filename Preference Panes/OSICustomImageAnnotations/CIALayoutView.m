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

#import "CIALayoutView.h"
#import "CIAPlaceHolder.h"
#import "CIAAnnotation.h"
#import "OSICustomImageAnnotations.h"

@implementation CIALayoutView

#define FRAME_MARGIN 10

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
	{	
		[self setDefaultDisabledText];
		[self setDefaultEnabledText];
		
		// The layout view contains 8 place holders for Annotations. They are labeled as follow:
		//  +-------+
		//	| 5 6 7 |
		//	| 3   4 |
		//	| 0 1 2 |
		//	+-------+
	
		// Frames Origins (x, y) of the place holders in the layout view
		float x[8], y[8];
		x[0] = 0.0 + FRAME_MARGIN;
		x[3] = x[5] = x[0];
		x[1] = frame.size.width / 2.0 - [CIAPlaceHolder defaultSize].width / 2.0;
		x[6] = x[1];
		x[2] = frame.size.width - [CIAPlaceHolder defaultSize].width - FRAME_MARGIN;
		x[4] = x[7] = x[2];

		y[0] = 0.0 + FRAME_MARGIN;
		y[1] = y[2] = y[0];
		y[3] = frame.size.height / 2.0 - [CIAPlaceHolder defaultSize].height / 2.0;
		y[4] = y[3];
		y[5] = frame.size.height - [CIAPlaceHolder defaultSize].height - FRAME_MARGIN;
		y[6] = y[7] = y[5];
		
		int align[8];
		align[0] = CIAPlaceHolderAlignLeft;
		align[3] = CIAPlaceHolderAlignLeft;
		align[5] = CIAPlaceHolderAlignLeft;
		align[1] = CIAPlaceHolderAlignCenter;
		align[6] = CIAPlaceHolderAlignCenter;
		align[2] = CIAPlaceHolderAlignRight;
		align[4] = CIAPlaceHolderAlignRight;
		align[7] = CIAPlaceHolderAlignRight;
		
		NSMutableArray *placeHolderMutableArray = [NSMutableArray arrayWithCapacity:8];
        int i;
		for (i=0; i<8; i++)
		{
			CIAPlaceHolder *aPlaceHolder = [[CIAPlaceHolder alloc] initWithFrame: NSMakeRect(x[i], y[i], [CIAPlaceHolder defaultSize].width, [CIAPlaceHolder defaultSize].height)];
			[aPlaceHolder setAlignment:align[i]];
			if(i==1) [aPlaceHolder setOrientationWidgetPosition:CIAPlaceHolderOrientationWidgetBottom];
			[self addSubview:aPlaceHolder];
			[placeHolderMutableArray addObject:aPlaceHolder];
			[aPlaceHolder release];
		}
		placeHolderArray = [[NSArray arrayWithArray:placeHolderMutableArray] retain];
    }
    return self;
}

- (void)dealloc
{
	[placeHolderArray release];
	[disabledText release];
	[enabledText release];
	[super dealloc];
}

- (void)updatePlaceHolderOrigins;
{
	//return;
	[self updatePlaceHolderOriginsInRect:[self bounds]];
}

- (void)updatePlaceHolderOriginsInRect:(NSRect)rect;
{
	//return;
	if([placeHolderArray count]<8) return;
	// The layout view contains 8 place holders for Annotations. They are labeled as follow:
	//  +-------+
	//	| 5 6 7 |
	//	| 3   4 |
	//	| 0 1 2 |
	//	+-------+

	// Frames Origins (x, y) of the place holders in the layout view
	float x[8], y[8];
	x[0] = 0.0 + FRAME_MARGIN;
	x[3] = x[5] = x[0];
	x[1] = rect.size.width / 2.0 - [[placeHolderArray objectAtIndex:1] frame].size.width / 2.0;
	x[6] = rect.size.width / 2.0 - [[placeHolderArray objectAtIndex:6] frame].size.width / 2.0;
	x[2] = rect.size.width - [[placeHolderArray objectAtIndex:2] frame].size.width - FRAME_MARGIN;
	x[4] = rect.size.width - [[placeHolderArray objectAtIndex:4] frame].size.width - FRAME_MARGIN;
	x[7] = rect.size.width - [[placeHolderArray objectAtIndex:7] frame].size.width - FRAME_MARGIN;

	y[0] = 0.0 + FRAME_MARGIN;
	y[1] = y[2] = y[0];
	y[3] = rect.size.height / 2.0 - [[placeHolderArray objectAtIndex:3] frame].size.height / 2.0;
	y[4] = rect.size.height / 2.0 - [[placeHolderArray objectAtIndex:4] frame].size.height / 2.0;
	y[5] = rect.size.height - [[placeHolderArray objectAtIndex:5] frame].size.height - FRAME_MARGIN;
	y[6] = rect.size.height - [[placeHolderArray objectAtIndex:6] frame].size.height - FRAME_MARGIN;
	y[7] = rect.size.height - [[placeHolderArray objectAtIndex:7] frame].size.height - FRAME_MARGIN;
	
	int i;
	for (i=0; i<8; i++)
	{
		[[placeHolderArray objectAtIndex:i] setFrameOrigin:NSMakePoint(x[i], y[i])];
		[[placeHolderArray objectAtIndex:i] setNeedsDisplay:YES];
	}
}

- (void)drawRect:(NSRect)updateRect
{
	NSRect rect = [self bounds];
	
	[self updatePlaceHolderOriginsInRect: rect];

	NSBezierPath *borderFrame = [NSBezierPath bezierPathWithRect: rect];
	
	[[NSColor whiteColor] set];
	[borderFrame fill];
	
	[borderFrame setLineWidth:2.0];
	[[NSColor grayColor] set];
	[borderFrame stroke];
	
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attrsDictionary setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[paragraphStyle release];

	NSFont *font = [NSFont systemFontOfSize:20.0];
	[attrsDictionary setObject:font forKey:NSFontAttributeName];
	
	NSAttributedString *contentText;
	float textWidth, textHeight;
	if([self isEnabled])
	{
		contentText = [[[NSAttributedString alloc] initWithString:enabledText attributes:attrsDictionary] autorelease];
		textWidth = [contentText size].width/2.0;//rect.size.width / 2.0;
		textHeight = [contentText size].height*3.0;//rect.size.height / 2.0;
	}
	else
	{
		contentText = [[[NSAttributedString alloc] initWithString:disabledText attributes:attrsDictionary] autorelease];

		textWidth = rect.size.width / 2.0;
		textHeight = [contentText size].height*3.0;
	}

	NSRect textRect = NSMakeRect(rect.origin.x+rect.size.width/2.0-textWidth/2.0, rect.origin.y+rect.size.height/2.0-textHeight/2.0, textWidth, textHeight);
	[contentText drawInRect:textRect];
}

- (NSArray*) placeHolderArray;
{
	return placeHolderArray;
}

- (void)setEnabled:(BOOL)enabled;
{
	[super setEnabled:enabled];
//	int i;
//	for (i=0; i<8; i++)
//		[[placeHolderArray objectAtIndex:i] setEnabled:enabled];
}

- (void)setDisabledText:(NSString*)text;
{
	[disabledText release];
	disabledText = [text retain];
}

- (void)setDefaultEnabledText;
{
	[enabledText release];
	enabledText = NSLocalizedString( @"Drag Annotations in the place holders", nil);
	[enabledText retain];
}

- (void)setDefaultDisabledText;
{
	[disabledText release];
	disabledText = NSLocalizedString(@"Same as Default Settings...", nil);
	[disabledText retain];
}

@end
