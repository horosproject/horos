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

#import "OSIHotKeysPref.h"

static OSIHotKeysPref *currentKeysPref = 0L;

@implementation OSIHotKeysPref

- (id) initWithBundle:(NSBundle *)bundle
{
	if( self = [super init])
	{
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"OSIHotKeysPref" bundle: nil];
		[nib instantiateNibWithOwner:self topLevelObjects: nil];
		
		[self setMainView: [mainWindow contentView]];
		[self mainViewDidLoad];
	}
	
	return self;
}

+ (OSIHotKeysPref*) currentKeysPref
{
	return currentKeysPref;
}

- (void) keyDown:(NSEvent *)theEvent
{
	NSMutableDictionary *dict = [[arrayController selectedObjects] lastObject];
	[dict setObject: [NSString stringWithFormat: @"%c", [[[theEvent charactersIgnoringModifiers] lowercaseString] characterAtIndex: 0]] forKey:@"key"];
//	[dict setObject: [NSNumber numberWithInt: [theEvent modifierFlags]] forKey:@"modifiers"];

	NSArray *a = [arrayController content];
	
	for( NSMutableDictionary *d in a)
	{
		for( NSMutableDictionary *c in a)
		{
			if( c != d)
			{
				if( [[c valueForKey:@"key"] isEqualToString: [d valueForKey:@"key"]])
				{
					NSMutableDictionary *e;
					if( [[arrayController selectedObjects] containsObject: c])
						e = d;
					else
						e = c;
					[e setValue:@"" forKey:@"key"];
				}
			}
		}
	}
}

- (void)dealloc{	
	NSLog(@"dealloc Hot Key Pref PAne");
	[_actions release];
	[super dealloc];
}

-(void) willUnselect
{
	[[[self mainView] window] makeFirstResponder: nil];
}

- (void) mainViewDidLoad
{
	currentKeysPref = self;
	
	// create array of MutableDictionaries containing names of actions
		NSArray *actions = [NSArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:	NSLocalizedStringFromTableInBundle(@"Default WW/WL", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Full Dynamic WW/WL", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"1st WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"2nd WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"3rd WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"4th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"5th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"6th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"7th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"8th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"9th WW/WL preset", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Flip Vertical", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Flip Horizontal", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"WW/WL Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Move Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Zoom Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Rotate Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Scroll Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Measure Length Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Measure Angle Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Rectangle ROI Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Oval ROI Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Text Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Arrow Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Open Polygon Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Closed Polygon Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Pencil Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"3D Point Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Brush Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Bone Removal Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"3D Rotate Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Camera Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Scissors Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Repulsor Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Selector Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Mark Status as Empty", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Mark Status as Unread", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Mark Status as Reviewed", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Mark Status as Dictated", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedStringFromTableInBundle(@"Ortho MPR Cross Tool", nil, [NSBundle bundleForClass: [OSIHotKeysPref class]], nil), @"action", nil],
											nil];
	
	NSDictionary *keys = [[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"];
//	NSDictionary *keysModifiers = [[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYSMODIFIERS"];
	
	NSEnumerator *enumerator = [keys objectEnumerator];
	id index;
	// the indes will be the position in the Actions Array. The key is the hotkey.
	while (index = [enumerator nextObject])
	{
		NSArray *allKeys = [keys allKeysForObject:index];
		if ([allKeys count] > 0)
		{
			NSString *key = [allKeys objectAtIndex: 0];
			
			if( [index intValue] < [actions count])
				[[actions objectAtIndex:[index intValue]] setObject: key forKey:@"key"];
		}
	}
	[self setActions:actions];

	//NSLog(@"MainViewDidLoad arrayController: %@", [arrayController description]);
											
}

- (NSArray *)actions{
	//NSLog(@"action: %@", [_actions description]);
	return _actions;
}

- (void)setActions:(NSArray *)actions{
	[_actions release];
	_actions = [actions retain];
}

- (NSPreferencePaneUnselectReply)shouldUnselect
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	for(int i = 0; i < [_actions count]; i++)
	{
		if( [[_actions objectAtIndex:i] objectForKey:@"key"])
		{
			[dict setObject:[NSNumber numberWithInt:i] forKey:[[_actions objectAtIndex:i] objectForKey:@"key"]];
		}
	}
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"HOTKEYS"];
	
	return [super shouldUnselect];
}

- (void)didUnselect
{
}
@end
