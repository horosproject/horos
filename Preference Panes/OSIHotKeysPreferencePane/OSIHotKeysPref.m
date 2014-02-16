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
		NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"OSIHotKeysPref" bundle: nil] autorelease];
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

- (void) setKey:(NSString*) key
{
    NSMutableDictionary *dict = [[arrayController selectedObjects] lastObject];
	[dict setObject: key forKey:@"key"];
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

- (IBAction) specialKeyButton:(id)sender
{
//    NSLog( @"special key button tag: %d", [sender tag]);
    
    NSString *key = nil;
    
    switch ( [sender tag]) {
        case 0: //dbl click
            key = @"dbl-click";
            break;
        
        case 1: //dbl click + alt
            key = @"dbl-click + alt";
            break;
    
        case 2:
            key = @"dbl-click + cmd";
            break;
    
        default:
            break;
    }
    
    if( key)
        [self setKey: key];
}

- (void) keyDown:(NSEvent *)theEvent
{
    [self setKey: [NSString stringWithFormat: @"%c", [[[theEvent charactersIgnoringModifiers] lowercaseString] characterAtIndex: 0]]];
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
		NSArray *actions = [NSArray arrayWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:	NSLocalizedString(@"Default WW/WL", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Full Dynamic WW/WL", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"1st WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"2nd WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3rd WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"4th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"5th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"6th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"7th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"8th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"9th WW/WL preset", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Flip Vertical", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Flip Horizontal", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"WW/WL Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Move Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Zoom Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Rotate Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Scroll Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Measure Length Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Measure Angle Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Rectangle ROI Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Oval ROI Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Text Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Arrow Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Open Polygon Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Closed Polygon Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Pencil Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3D Point Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Brush Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Bone Removal Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3D Rotate Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Camera Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Scissors Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Repulsor Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Selector Tool", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mark Status as Empty", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mark Status as Unread", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mark Status as Reviewed", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mark Status as Dictated", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Mark Status as Validated", nil), @"action", nil],
											[NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Ortho MPR Cross Tool", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"1st Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"2nd Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3rd Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"4th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"5th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"6th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"7th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"8th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"9th Opacity preset", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Full screen", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"3D Position", nil), @"action", nil],
                                            [NSMutableDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Set Key Image", nil), @"action", nil],
											nil];
	
	NSDictionary *keys = [[NSUserDefaults standardUserDefaults] objectForKey:@"HOTKEYS"];
	
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
