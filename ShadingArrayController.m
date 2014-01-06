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



#import "N2Debug.h"
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

- (void)setWindowController:(OSIWindowController*) ctrl;
{
	winController = ctrl;
}

- (BOOL)enableEditing{
	return _enableEditing;
}

- (void)setEnableEditing:(BOOL)enable{
	_enableEditing = enable;
}

- (BOOL)setSelectionIndex:(NSUInteger)index
{	
	BOOL v = [super setSelectionIndex:(unsigned int)index];
    
    if( winController == nil)
        N2LogStackTrace( @"winController == nil in shadingArrayController");
    
	[winController applyShading: self];
	return v;
}

- (void) prepareContent
{
	NSMutableArray	*array = [NSMutableArray array];
	NSArray			*src = [[NSUserDefaults standardUserDefaults] arrayForKey:@"shadingsPresets"];
	
	for( id loopItem in src) [array addObject: [[loopItem mutableCopy] autorelease]];

	[self setContent: array];
}

- (void) dealloc
{
	[[NSUserDefaults standardUserDefaults] setObject: [self content] forKey:@"shadingsPresets"];
	
	[super dealloc];
}

@end
