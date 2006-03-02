//
//  OrthogonalMIPPETViewer.m
//  OsiriX
//
//  Created by joris on 10/28/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "OrthogonalMIPPETViewer.h"


@implementation OrthogonalMIPPETViewer

- (id) initWithPixList: (NSMutableArray*) pix
{
NSLog( @"OrthogonalMIPPETViewer initWithPixList");
	self = [super initWithWindowNibName:@"MIPPET"];
	[[self window] setDelegate:self];
	[[self window] setShowsResizeIndicator:YES];
	
	// initialisations
	mip = [[OrthogonalMIPPET alloc] initWithPixList: pix];
	NSLog( @"[mip initWithPixList: pix]");
	[mipView setPixList: [mip result]];
	NSLog( @"[mipView setPixList: [mip result]]");

	return self;
}

- (void) dealloc {
	[mip release];
	[super dealloc];
}

#pragma mark-
#pragma mark MIP methods
- (IBAction) setAlpha : (id) sender
{
	[angleTextField setStringValue:[NSString stringWithFormat:@"alpha = %0.0f%", (float) [sender intValue]]];
	[mip setAlphaDegres : [sender intValue]];
	[betaTextField setStringValue:[NSString stringWithFormat:@"beta = %0.0f%", (float) [mip beta]]];
	[mipView setPixList: [mip result]];
}

#pragma mark-
#pragma mark NSWindow related methods

- (IBAction) showWindow:(id)sender
{
	[mipView setPixList: [mip result]];
	[super showWindow:sender];
}

- (void) windowWillClose:(NSNotification *)notification
{
    [[self window] setDelegate:nil];
    [self release];
}

#pragma mark-
#pragma mark OsiriX Viewer methods

- (BOOL) is2DViewer
{
	return NO;
}

@end
