//
//  printView.m
//  OsiriX
//
//  Created by Antoine Rosset on 29.10.06.
//  Copyright 2006 OsiriX. All rights reserved.
//

#import "printView.h"
#import "DCMView.h"

@implementation printView

- (void)drawPageBorderWithSize:(NSSize)borderSize
{
	[super drawPageBorderWithSize:borderSize];

	NSRect frame = [self frame];

	[self setFrame:NSMakeRect(0.0, 0.0, borderSize.width, borderSize.height)];
	
	[self lockFocus];
	
	int page = [[NSPrintOperation currentOperation] currentPage];
	
	NSManagedObject	*file = [[viewer fileList] objectAtIndex: 0];
	
	NSString *string2draw = [NSString stringWithFormat:@"%@ - %@\r%@", [file valueForKeyPath:@"series.study.name"], [file valueForKeyPath:@"series.study.patientID"], [file valueForKeyPath:@"series.study.studyName"], [file valueForKeyPath:@"series.name"]];
	
	NSMutableDictionary *attribs = [NSMutableDictionary dictionary];  
	[attribs setObject:[NSFont systemFontOfSize:14] forKey:NSFontAttributeName];
	NSSize pageNumberSize = [string2draw sizeWithAttributes:attribs];
	
	float bottomMargin = [[[NSPrintOperation currentOperation] printInfo] bottomMargin];
	NSPoint pageNumberPoint = NSMakePoint((borderSize.width - pageNumberSize.width) / 2.0,
	borderSize.height - (bottomMargin + pageNumberSize.height) / 2.0);
	
	[string2draw drawAtPoint: pageNumberPoint withAttributes:attribs];
	
	[self unlockFocus];

	[self setFrame:frame];
}

- (BOOL)knowsPageRange:(NSRangePointer)range 
{
    NSRect bounds = [self bounds];

	int	columns = [[settings objectForKey: @"columns"] intValue];
	int	rows = [[settings objectForKey: @"rows"] intValue];
	int ipp = columns * rows;
	int pages;
	
	if( [[viewer pixList] count] % ipp == 0) pages = [[viewer pixList] count] / ipp;
	else pages = 1 + [[viewer pixList] count] / ipp;
	
    range->location = 1;
    range->length = pages;
    return YES;
}
 
// Return the drawing rectangle for a particular page number
- (NSRect)rectForPage:(int)page
{
    NSRect bounds = [self bounds];
    return bounds;
}

- (void) dealloc
{
	[viewer release];
	[settings release];
	
	[super dealloc];
}

- (id)initWithViewer:(ViewerController*) v settings:(NSDictionary*) s
{
	NSPrintInfo	*pi = [NSPrintInfo sharedPrintInfo];
	NSSize size = [pi paperSize];
	
    self = [super initWithFrame: NSMakeRect( [pi leftMargin], [pi topMargin], size.width - [pi leftMargin] - [pi rightMargin], size.height - [pi topMargin] - [pi bottomMargin])];
    if (self)
	{
		viewer = [v retain];
		settings = [s retain];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	NSSize size = [self frame].size;
	
	int	columns = [[settings objectForKey: @"columns"] intValue];
	int	rows = [[settings objectForKey: @"rows"] intValue];
	int ipp = columns * rows;
	int page = [[NSPrintOperation currentOperation] currentPage];
	
	[NSColor blackColor];
	
	int x, y;
	
	for( y = 0 ; y < rows ; y ++)
	{
		for( x = 0 ; x < columns ; x ++)
		{
			int index = (page - 1) * ipp + y*columns + x;
			
			NSRect rect = NSMakeRect( x * size.width / columns,  (rows-1-y) * size.height / rows , size.width / columns, size.height / rows);
			NSRectFill( rect);
			if( index < [[viewer pixList] count])
			{
				NSLog( @"%d", index);
			
				[viewer setImageIndex: index];
				[[viewer imageView] display];
				NSImage *im = [[viewer imageView] nsimage: YES];
				
				NSRect dstRect;
				
				if( rect.size.width/rect.size.height > [im size].width/[im size].height)
				{
					float ratio = rect.size.height / [im size].height;
					dstRect = NSMakeRect( rect.origin.x + (rect.size.width - [im size].width * ratio) / 2, rect.origin.y, [im size].width * ratio, rect.size.height);
				}
				else
				{
					float ratio = rect.size.width / [im size].width;
					dstRect = NSMakeRect( rect.origin.x, rect.origin.y  + (rect.size.height - [im size].height * ratio) / 2, rect.size.width, [im size].height * ratio);
				}
				
				[im drawInRect: dstRect fromRect:NSZeroRect operation:NSCompositeCopy fraction: 1.0];
				
				[im release];
			}
		}
	}
}

@end
