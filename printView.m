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

#import "printView.h"
#import "DCMView.h"
#import "DCMPix.h"
#import "BrowserController.h"

@implementation printView

//-----------------------------------------------------------------------
// called from ViewerController endPrint:
//-----------------------------------------------------------------------

- (id)initWithViewer:(id) v settings:(NSDictionary*) s files:(NSArray*) f printInfo:(NSPrintInfo*) pi
{
	//imageablePageBounds gives the NSRect that is authorized for printing in a specific paper size for a specific printer. It respects custom margins of custom papersize as well.
	NSRect imageablePageBounds = [pi imageablePageBounds];
	NSLog(@"imageablePageBounds origin.x=%f origin.y=%f size.width=%f size.height=%f",imageablePageBounds.origin.x, imageablePageBounds.origin.y, imageablePageBounds.size.width, imageablePageBounds.size.height);

    self = [super initWithFrame: [pi imageablePageBounds]];
	
    if (self)
	{
		viewer = [v retain];
		settings = [s retain];
		filesToPrint = [f retain];
		columns = [[settings objectForKey: @"columns"] intValue];
		rows = [[settings objectForKey: @"rows"] intValue];
		ipp = columns * rows;
    }
    return self;
}

//-----------------------------------------------------------------------
// Accessors, mainly used for unit tests
//-----------------------------------------------------------------------

- (int)columns { return columns; }
- (int)rows { return rows; }
- (int)ipp { return ipp; }


//-----------------------------------------------------------------------

- (void)drawPageBorderWithSize:(NSSize)borderSize
{
	[super drawPageBorderWithSize:borderSize];
	
	if( [self frame].size.width > 0 && [self frame].size.height > 0)
	{
		[self lockFocus];
		
		NSManagedObject	*file = [[viewer fileList] objectAtIndex: 0];
		NSString *string2draw = @"";
		headerHeight = 13; //leaves in all cases a white line at the end of the header
		
		
		NSRange	range;
		[self knowsPageRange: &range];	
		if( [settings valueForKey:@"comments"]) 
		{
			headerHeight += 13;
			string2draw = [string2draw stringByAppendingFormat:@"%@   (%d/%d)\r", [settings valueForKey:@"comments"], (int) [[NSPrintOperation currentOperation] currentPage], (int) range.length];
		}
		
				
		if( [settings valueForKey:@"patientInfo"])
		{
			headerHeight += 13;
			string2draw = [string2draw stringByAppendingFormat:@"Patient: "];
			if([file valueForKeyPath:@"series.study.name"]) string2draw = [string2draw stringByAppendingFormat:@"%@", [file valueForKeyPath:@"series.study.name"]];
			if([file valueForKeyPath:@"series.study.patientID"]) string2draw = [string2draw stringByAppendingFormat:@"  [%@]", [file valueForKeyPath:@"series.study.patientID"]];
			if( [file valueForKeyPath:@"series.study.dateOfBirth"]) string2draw = [string2draw stringByAppendingFormat:@"  %@", [BrowserController DateOfBirthFormat: [file valueForKeyPath:@"series.study.dateOfBirth"]]];
			string2draw = [string2draw stringByAppendingFormat:@"\r"];
		}	
		
		
		if( [settings valueForKey:@"studyInfo"])
		{
			headerHeight += 13;
			string2draw = [string2draw stringByAppendingFormat:@"Study: "];

			NSCalendarDate  *date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[file valueForKey:@"date"] timeIntervalSinceReferenceDate]];
			if( date && [date yearOfCommonEra] != 3000)
			{
				NSString *tempString = [BrowserController DateOfBirthFormat: date];
				string2draw = [string2draw stringByAppendingFormat:@"%@", tempString];
			
				DCMPix *curDCM = [[viewer pixList] objectAtIndex: 0];
				
				if( [curDCM acquisitionTime]) date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [[curDCM acquisitionTime] timeIntervalSinceReferenceDate]];
				if( date && [date yearOfCommonEra] != 3000)
				{
					tempString = [BrowserController TimeFormat: date];
					string2draw = [string2draw stringByAppendingFormat:@" - %@    ", tempString];
				}
			}

			if([file valueForKeyPath:@"series.study.studyName"] && !([[file valueForKeyPath:@"series.study.studyName"] isEqualToString:@"unnamed"])) string2draw = [string2draw stringByAppendingFormat:@"%@  ", [file valueForKeyPath:@"series.study.studyName"]];
			if([file valueForKeyPath:@"series.name"] && !([[file valueForKeyPath:@"series.name"] isEqualToString:@"unnamed"])) string2draw = [string2draw stringByAppendingFormat:@"%@  ", [file valueForKeyPath:@"series.name"]];
			string2draw = [string2draw stringByAppendingFormat:@"\r"];
		}
		
		NSMutableDictionary *attribs = [NSMutableDictionary dictionary];  
		[attribs setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
		//
		NSPoint where2draw = NSMakePoint(20, borderSize.height - (headerHeight+15));
		[string2draw drawAtPoint: where2draw withAttributes:attribs]; //only invoke this method when an NSView object has focus
		[self unlockFocus];
	}
}

//---------------------------------------------------------------------------

- (BOOL)knowsPageRange:(NSRangePointer)range 
{
	//To provide a completely custom pagination scheme that does not use NSView’s built-in pagination support, 
	//a view must override the knowsPageRange: method to return YES. It should also return by reference the page 
	//range for the document. 
    range->location = 1;
	range->length = ([filesToPrint count] + ipp - 1) / ipp;
    return YES;
}

//---------------------------------------------------------------------------
 
- (NSRect)rectForPage:(NSInteger)page
{
	//Before printing each page, the pagination machinery sends the view a rectForPage: message. 
	//Your implementation of rectForPage: should use the supplied page number and the current printing information to 
	//calculate an appropriate drawing rectangle in the view’s coordinate system.
    return [self bounds];
}
	
//-----------------------------------------------------------------------

- (void)drawRect:(NSRect)rect
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	
	NSSize frameSize = [self frame].size;
	
	int page = [[NSPrintOperation currentOperation] currentPage];
	
    
	[NSColor blackColor];
	
	int x, y;
	
	if( [[settings valueForKey: @"backgroundColor"] boolValue])
	{
		[[NSColor colorWithDeviceRed: [[settings valueForKey: @"backgroundColorR"] floatValue] green: [[settings valueForKey: @"backgroundColorG"] floatValue] blue: [[settings valueForKey: @"backgroundColorB"] floatValue] alpha: 1.0] set];
		NSRectFill( NSMakeRect(0, 0, frameSize.width, frameSize.height - headerHeight));
	}
	
	for( y = 0 ; y < rows ; y ++)
	{
		for( x = 0 ; x < columns ; x ++)
		{
			int index = (page - 1) * ipp + y*columns + x;
			
			NSRect rect = NSMakeRect( x * frameSize.width / columns,  (rows-1-y) * (frameSize.height - headerHeight) / rows , frameSize.width / columns, (frameSize.height - headerHeight) / rows);
			
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
				
				//NSZeroRect = complete image
				//NSInsetRect(dstRect, 1, 1) leaves one pixel border separation around the image
				[im drawInRect: NSInsetRect(dstRect, 1, 1)  fromRect:NSZeroRect operation:NSCompositeCopy fraction: 1.0];
				
				[im release];
			}
		}
	}
	
	[pool release];
}

//----------------------------------------------------------------

- (void) dealloc
{
	[viewer release];
	[settings release];
	[filesToPrint release];
	
	[super dealloc];
}

@end
