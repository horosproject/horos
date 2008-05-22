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




#import "NSSplitViewSave.h"

@implementation NSSplitView(Defaults)

- (void) restoreDefault: (NSString *) defaultName
{
	NSString * string = [[NSUserDefaults standardUserDefaults] objectForKey: defaultName];

	if (string == nil)
			return;         // there was no saved default
	
	NSScanner* scanner = [NSScanner scannerWithString: string];
	NSRect r0, r1;
	
	float a,b,c,d,e,f,g,h,i,j;

	BOOL didScan =
			[scanner scanFloat: &a]             &&
			[scanner scanFloat: &b]             &&
			[scanner scanFloat: &c]				&&
			[scanner scanFloat: &d]				&&
			[scanner scanFloat: &e]             &&
			[scanner scanFloat: &f]             &&
			[scanner scanFloat: &g]				&&
			[scanner scanFloat: &h];

	r0.origin.x = a;
	r0.origin.y = b;
	r0.size.width = c;
	r0.size.height = d;
	r1.origin.x = e;
	r1.origin.y = f;
	r1.size.width = g;
	r1.size.height = h;

	if (didScan == NO)
			return; // probably should throw an exception at this point
	
	if( [[self subviews] count] > 1)
	{
		[[[self subviews] objectAtIndex: 0] setFrame: r0];
		[[[self subviews] objectAtIndex: 1] setFrame: r1];
	}
	
	[self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
	if( [[self subviews] count] > 1)
	{
		NSRect r0 = [[[self subviews] objectAtIndex: 0] frame];
		NSRect r1 = [[[self subviews] objectAtIndex: 1] frame];

		NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f",
				r0.origin.x, r0.origin.y, r0.size.width, r0.size.height,
				r1.origin.x, r1.origin.y, r1.size.width, r1.size.height];
		
		[[NSUserDefaults standardUserDefaults] setObject: string forKey: defaultName];
	}
}

@end
