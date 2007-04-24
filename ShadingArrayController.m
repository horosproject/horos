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
		if( count == 0) [object setValue: NSLocalizedString(@"Default", nil) forKey: @"name"];
		else [object setValue: [NSString stringWithFormat: @"%@ %d", NSLocalizedString(@"Preset", nil), count + 1] forKey: @"name"];
		[object setValue: @"0.15" forKey: @"ambient"];
		[object setValue: @"0.9" forKey: @"diffuse"];
		[object setValue: @"0.3" forKey: @"specular"];
		[object setValue: @"15" forKey: @"specularPower"];
	}
	
	[super addObject:object];
	[self setSelectionIndex:[[self arrangedObjects] indexOfObject:object]];
		
}

- (BOOL)enableEditing{
	return _enableEditing;
}

- (void)setEnableEditing:(BOOL)enable{
	_enableEditing = enable;
}

- (BOOL)setSelectionIndex:(unsigned int)index{
	NSLog(@"selection index: %d", index);
	return [super setSelectionIndex:(unsigned int)index];
}

@end
