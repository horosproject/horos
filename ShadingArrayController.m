//
//  ShadingArrayController.m
//  OsiriX
//
//  Created by Lance Pysher on 4/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ShadingArrayController.h"


@implementation ShadingArrayController

- (IBAction)add:(id)sender{
	[self setEnableEditing:YES];
	[super add:sender];
}

- (IBAction)remove:(id)sender{
	[super remove:sender];
	
	if( [[self content] count] == 0) [self add: self];
	
	[self setSelectionIndex: 0];
}

- (void)addObject:(id)object
{
	NSDictionary *previous = [[self selectedObjects] lastObject];
	NSLog(@"previous Shading settings:\n%@", previous);
	int count = [[self content] count];
	
	if( count > 0)
	{
		[object setValue: [NSString stringWithFormat:  @"%@ %d", NSLocalizedString(@"Preset", nil), count + 1] forKey: @"name"];
		[object setValue: [previous valueForKey:@"ambient"] forKey: @"ambient"];
		[object setValue: [previous valueForKey:@"diffuse"] forKey: @"diffuse"];
		[object setValue: [previous valueForKey:@"specular"] forKey: @"specular"];
		[object setValue: [previous valueForKey:@"specularPower"] forKey: @"specularPower"];
	}
	else
	{
		[object setValue: NSLocalizedString(@"Default", nil) forKey: @"name"];
		[object setValue: @"0.15" forKey: @"ambient"];
		[object setValue: @"0.9" forKey: @"diffuse"];
		[object setValue: @"0.3" forKey: @"specular"];
		[object setValue: @"15" forKey: @"specularPower"];
	}
	
	[super addObject:object];
	
	[self setSelectionIndex:[[self arrangedObjects] indexOfObject:object]];
}

- (void)setWindowController:(NSWindowController*) ctrl;
{
	winController = ctrl;
}

- (BOOL)enableEditing{
	return _enableEditing;
}

- (void)setEnableEditing:(BOOL)enable{
	_enableEditing = enable;
}

- (BOOL)setSelectionIndex:(unsigned int)index
{	
	BOOL v = [super setSelectionIndex:(unsigned int)index];
	[winController applyShading: self];
	return v;
}

- (void) prepareContent
{
	NSMutableArray	*array = [NSMutableArray array];
	NSArray			*src = [[NSUserDefaults standardUserDefaults] arrayForKey:@"shadingsPresets"];
	
	int i;
	for( i = 0 ; i < [src count] ; i++) [array addObject: [[[src objectAtIndex:i] mutableCopy] autorelease]];

	[self setContent: array];
}

- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] setObject: [self content] forKey:@"shadingsPresets"];
	
	[super dealloc];
}

@end
