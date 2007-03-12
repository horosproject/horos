//
//  printView.m
//  OsiriX
//
//  Created by Antoine Rosset on 29.10.06.
//  Copyright 2006 OsiriX. All rights reserved.
//

#import "printView.h"
#import "DCMView.h"
#import "DCMPix.h"

@implementation printView

- (void)drawPageBorderWithSize:(NSSize)borderSize
{
	[super drawPageBorderWithSize:borderSize];

	NSRect frame = [self frame];

	[self setFrame:NSMakeRect(0.0, 0.0, borderSize.width, borderSize.height)];
	
	[self lockFocus];
	
	NSManagedObject	*file = [[viewer fileList] objectAtIndex: 0];
	
	NSString *string2draw = @"";
	
	NSString *shortDateString = [[NSUserDefaults standardUserDefaults] stringForKey: NSShortDateFormatString];
	NSDictionary *localeDictionnary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	
	// TOP HEADER
	
	if( [settings valueForKey:@"patientInfo"])
	{
		string2draw = [string2draw stringByAppendingFormat:@"Name: "];
		if([file valueForKeyPath:@"series.study.name"]) string2draw = [string2draw stringByAppendingFormat:@"%@", [file valueForKeyPath:@"series.study.name"]];
		if([file valueForKeyPath:@"series.study.patientID"]) string2draw = [string2draw stringByAppendingFormat:@" (%@)", [file valueForKeyPath:@"series.study.patientID"]];
		if( [file valueForKeyPath:@"series.study.dateOfBirth"]) string2draw = [string2draw stringByAppendingFormat:@" - %@", [[file valueForKeyPath:@"series.study.dateOfBirth"] descriptionWithCalendarFormat:shortDateString timeZone:0L locale:localeDictionnary]];
		
		string2draw = [string2draw stringByAppendingFormat:@"\r"];
	}
	
	if( [settings valueForKey:@"studyInfo"])
	{
		string2draw = [string2draw stringByAppendingFormat:@"Study: "];
		if([file valueForKeyPath:@"series.study.studyName"]) string2draw = [string2draw stringByAppendingFormat:@"%@", [file valueForKeyPath:@"series.study.studyName"]];
		if([file valueForKeyPath:@"series.name"]) string2draw = [string2draw stringByAppendingFormat:@"%@", [file valueForKeyPath:@"series.name"]];

		NSCalendarDate  *date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[file valueForKey:@"date"] timeIntervalSinceReferenceDate]];
		if( date && [date yearOfCommonEra] != 3000)
		{
			NSString *tempString = [date descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] objectForKey: NSShortDateFormatString]];
			string2draw = [string2draw stringByAppendingFormat:@"\rDate: %@", tempString];
		
			DCMPix *curDCM = [[viewer pixList] objectAtIndex: 0];
			
			if( [curDCM acquisitionTime]) date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[curDCM acquisitionTime] timeIntervalSinceReferenceDate]];
			if( date && [date yearOfCommonEra] != 3000)
			{
				tempString = [date descriptionWithCalendarFormat: [[NSUserDefaults standardUserDefaults] objectForKey: NSTimeFormatString]];
				string2draw = [string2draw stringByAppendingFormat:@" - %@", tempString];
			}
		}
	}
	
	if( [settings valueForKey:@"comments"]) string2draw = [string2draw stringByAppendingFormat:@"\r%@", [settings valueForKey:@"comments"]];
	
	NSMutableDictionary *attribs = [NSMutableDictionary dictionary];  
	[attribs setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	NSSize pageNumberSize = [string2draw sizeWithAttributes:attribs];
	
	float bottomMargin = [[[NSPrintOperation currentOperation] printInfo] bottomMargin];
	NSPoint pageNumberPoint = NSMakePoint((borderSize.width - pageNumberSize.width) / 2.0, borderSize.height - (bottomMargin + pageNumberSize.height) / 2.0);
	[string2draw drawAtPoint: pageNumberPoint withAttributes:attribs];
	
	// BOTTOM HEADER
	
	int page = [[NSPrintOperation currentOperation] currentPage];
	
	NSRange	range;
	[self knowsPageRange: &range];
	string2draw = [NSString stringWithFormat:@"Page: %d of %d", page, range.length];

	pageNumberSize = [string2draw sizeWithAttributes:attribs];
	
	float topMargin = [[[NSPrintOperation currentOperation] printInfo] topMargin];
	pageNumberPoint = NSMakePoint((borderSize.width - pageNumberSize.width) / 2.0, 0 + (topMargin - pageNumberSize.height) / 2.0);
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
	
	if( [filesToPrint count] % ipp == 0) pages = [filesToPrint count] / ipp;
	else pages = 1 + [filesToPrint count] / ipp;
	
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
	[filesToPrint release];
	
	[super dealloc];
}

/*
- (void)finalize {
	//nothing to do does not need to be called
}
*/

- (id)initWithViewer:(id) v settings:(NSDictionary*) s files:(NSArray*) f
{
	NSPrintInfo	*pi = [NSPrintInfo sharedPrintInfo];
	NSSize size = [pi paperSize];
	
    self = [super initWithFrame: NSMakeRect( [pi leftMargin], [pi topMargin], size.width - [pi leftMargin] - [pi rightMargin], size.height - [pi topMargin] - [pi bottomMargin])];
    if (self)
	{
		viewer = [v retain];
		settings = [s retain];
		filesToPrint = [f retain];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	
	NSSize size = [self frame].size;
	
	int	columns = [[settings objectForKey: @"columns"] intValue];
	int	rows = [[settings objectForKey: @"rows"] intValue];
	int ipp = columns * rows;
	int page = [[NSPrintOperation currentOperation] currentPage];
	
	[NSColor blackColor];
	
	int x, y;
	
	if( [settings valueForKey: @"backgroundColor"])
	{
		[[NSColor colorWithDeviceRed: [[settings valueForKey: @"backgroundColorR"] floatValue] green: [[settings valueForKey: @"backgroundColorG"] floatValue] blue: [[settings valueForKey: @"backgroundColorB"] floatValue] alpha: 1.0] set];
		NSRectFill( NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height));
	}
	
	for( y = 0 ; y < rows ; y ++)
	{
		for( x = 0 ; x < columns ; x ++)
		{
			int index = (page - 1) * ipp + y*columns + x;
			
			NSRect rect = NSMakeRect( x * size.width / columns,  (rows-1-y) * size.height / rows , size.width / columns, size.height / rows);
			
			if( index < [filesToPrint count])
			{
				NSImage *im = [[NSImage alloc] initWithContentsOfFile: [filesToPrint objectAtIndex: index]];
				
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
				
				[im drawInRect: NSInsetRect(dstRect, 2, 2)  fromRect:NSZeroRect operation:NSCompositeCopy fraction: 1.0];
				
				[im release];
			}
		}
	}
	
	[pool release];
}

@end
