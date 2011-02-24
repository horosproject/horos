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


static float a,b,c,d,e,f,g,h;

#import "NSSplitViewSave.h"

@implementation NSSplitView(Defaults)

+ (void) saveSplitView
{
	NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f",
						 a, b, c, d,
						 e, f, g, h];
	
	[[NSUserDefaults standardUserDefaults] setObject: string forKey: @"SPLITVIEWER"];
}

+ (void) loadSplitView
{
	NSString * string = [[NSUserDefaults standardUserDefaults] objectForKey: @"SPLITVIEWER"];
	
	if (string == nil)
	{
		a=b=c=d=e=f=g=h=-1;
		return;
	}
	
	NSScanner* scanner = [NSScanner scannerWithString: string];
	
	BOOL didScan =
	[scanner scanFloat: &a]             &&
	[scanner scanFloat: &b]             &&
	[scanner scanFloat: &c]				&&
	[scanner scanFloat: &d]				&&
	[scanner scanFloat: &e]             &&
	[scanner scanFloat: &f]             &&
	[scanner scanFloat: &g]				&&
	[scanner scanFloat: &h];
	
	if (didScan == NO)
	{
		a=b=c=d=e=f=g=h=-1;
	}
}

- (void) restoreDefault: (NSString *) defaultName
{
	NSRect r0, r1, r2;
	
	if( [defaultName isEqualToString: @"SPLITVIEWER"])
	{
		if( a == -1 && c == -1) return;
		
		r0.origin.x = a;
		r0.origin.y = b;
		r0.size.width = c;
		r0.size.height = d;
		r1.origin.x = e;
		r1.origin.y = f;
		r1.size.width = g;
		r1.size.height = h;
		
		if( [[self subviews] count] > 1)
		{
			[[[self subviews] objectAtIndex: 0] setFrame: r0];
			[[[self subviews] objectAtIndex: 1] setFrame: r1];
		}
	}
	else
	{
		NSString * string = [[NSUserDefaults standardUserDefaults] objectForKey: defaultName];
		if (string == nil) return;
		
		NSScanner* scanner = [NSScanner scannerWithString: string];
		
		if( [[self subviews] count] > 2)
		{
			float aa,bb,cc,dd,ee,ff,gg,hh, ii, jj, kk, ll;
			
			BOOL didScan =
			[scanner scanFloat: &aa]            &&
			[scanner scanFloat: &bb]            &&
			[scanner scanFloat: &cc]			&&
			[scanner scanFloat: &dd]			&&
			[scanner scanFloat: &ee]            &&
			[scanner scanFloat: &ff]            &&
			[scanner scanFloat: &gg]			&&
			[scanner scanFloat: &hh]			&&
			[scanner scanFloat: &ii]			&&
			[scanner scanFloat: &jj]			&&
			[scanner scanFloat: &kk]			&&
			[scanner scanFloat: &ll];
			
			if (didScan == NO) return;
			
			r0.origin.x = aa;
			r0.origin.y = bb;
			r0.size.width = cc;
			r0.size.height = dd;
			r1.origin.x = ee;
			r1.origin.y = ff;
			r1.size.width = gg;
			r1.size.height = hh;
			r2.origin.x = ii;
			r2.origin.y = jj;
			r2.size.width = kk;
			r2.size.height = ll;
		
			[[[self subviews] objectAtIndex: 0] setFrame: r0];
			[[[self subviews] objectAtIndex: 1] setFrame: r1];
			[[[self subviews] objectAtIndex: 2] setFrame: r2];
		}
		else if( [[self subviews] count] > 1)
		{
			float aa,bb,cc,dd,ee,ff,gg,hh;
			
			BOOL didScan =
			[scanner scanFloat: &aa]            &&
			[scanner scanFloat: &bb]            &&
			[scanner scanFloat: &cc]			&&
			[scanner scanFloat: &dd]			&&
			[scanner scanFloat: &ee]            &&
			[scanner scanFloat: &ff]            &&
			[scanner scanFloat: &gg]			&&
			[scanner scanFloat: &hh];
			
			if (didScan == NO) return;
			
			r0.origin.x = aa;
			r0.origin.y = bb;
			r0.size.width = cc;
			r0.size.height = dd;
			r1.origin.x = ee;
			r1.origin.y = ff;
			r1.size.width = gg;
			r1.size.height = hh;
		
			[[[self subviews] objectAtIndex: 0] setFrame: r0];
			[[[self subviews] objectAtIndex: 1] setFrame: r1];
		}
	}
	
	
	
	[self adjustSubviews];
}

- (void) saveDefault: (NSString *) defaultName
{
	if( [[self subviews] count] > 2)
	{
		NSRect r0 = [[[self subviews] objectAtIndex: 0] frame];
		NSRect r1 = [[[self subviews] objectAtIndex: 1] frame];
		NSRect r2 = [[[self subviews] objectAtIndex: 2] frame];
		
		NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f %f %f %f %f",
				r0.origin.x, r0.origin.y, r0.size.width, r0.size.height,
				r1.origin.x, r1.origin.y, r1.size.width, r1.size.height,
				r2.origin.x, r2.origin.y, r2.size.width, r2.size.height];
			
		[[NSUserDefaults standardUserDefaults] setObject: string forKey: defaultName];
	}
	else if( [[self subviews] count] > 1)
	{
		NSRect r0 = [[[self subviews] objectAtIndex: 0] frame];
		NSRect r1 = [[[self subviews] objectAtIndex: 1] frame];
		
		if( [defaultName isEqualToString: @"SPLITVIEWER"])
		{
			a = r0.origin.x;
			b = r0.origin.y;
			c = r0.size.width;
			d = r0.size.height;
			e = r1.origin.x;
			f = r1.origin.y;
			g = r1.size.width;
			h = r1.size.height;
		}
		else
		{
			NSString * string = [NSString stringWithFormat: @"%f %f %f %f %f %f %f %f",
					r0.origin.x, r0.origin.y, r0.size.width, r0.size.height,
					r1.origin.x, r1.origin.y, r1.size.width, r1.size.height];
			
			[[NSUserDefaults standardUserDefaults] setObject: string forKey: defaultName];
		}
	}
}

@end
