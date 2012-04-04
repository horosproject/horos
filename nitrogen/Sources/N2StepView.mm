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

#import <N2StepView.h>
#import <N2Step.h>
#import <N2Operators.h>

@implementation N2StepView
@synthesize step = _step;

-(id)initWithStep:(N2Step*)step {
	self = [super initWithTitle:[step title] content:[step enclosedView]];
	
	_step = [step retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepDidBecomeActiveInactive:) name:N2StepDidBecomeActiveNotification object:step];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepDidBecomeActiveInactive:) name:N2StepDidBecomeInactiveNotification object:step];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepDidBecomeEnabledDisabled:) name:N2StepDidBecomeEnabledNotification object:step];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepDidBecomeEnabledDisabled:) name:N2StepDidBecomeDisabledNotification object:step];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepTitleDidChange:) name:N2StepTitleDidChangeNotification object:step];
	
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_step release];
	[super dealloc];
}

-(void)stepDidBecomeActiveInactive:(NSNotification*)notification {
	if ([[notification name] isEqualToString:N2StepDidBecomeActiveNotification]) {
	//	[(NSButton*)self.step.enclosedView.nextKeyView setKeyEquivalent:@"\r"];
		[[(NSButton*)self.step.defaultButton cell] setBackgroundColor:[NSColor colorWithCalibratedRed:.5 green:.66 blue:1 alpha:.5]];
		self.fillColor = [NSColor.grayColor colorWithAlphaComponent:0.25];
		[self expand:self];
	} else {
		if (![_step shouldStayVisibleWhenInactive]) [self collapse:self];
	//	[(NSButton*)self.step.enclosedView.nextKeyView setKeyEquivalent:@""];
		[[(NSButton*)self.step.defaultButton cell] setBackgroundColor:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0]];
		self.fillColor = [NSColor.grayColor colorWithAlphaComponent:0];
	}
}

-(void)stepDidBecomeEnabledDisabled:(NSNotification*)notification {
	[self setEnabled:[[notification name] isEqualToString:N2StepDidBecomeEnabledNotification]];
}

-(void)stepTitleDidChange:(NSNotification*)notification {
	[self setTitle:[_step title]];
}

-(void)drawRect:(NSRect)rect {
	[NSGraphicsContext saveGraphicsState];
	
//	NSSize s = -self.contentViewMargins;
	NSRect r = NSInsetRect([self.contentView frame], -3.5, -1);
	r.origin.y -= 1.5;

	[self.fillColor set];
	[[NSBezierPath bezierPathWithRect:r] fill];
	
	[NSGraphicsContext restoreGraphicsState];
	[super drawRect:rect];
}

@end
