/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/




#import "FusionDrawer.h"


@implementation FusionDrawer

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
        
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	
}

-(void) new2DViewer:(NSNotification*)note
{
	NSMenu  *menu = [note object];
	long	i, val = 1;
	
	if( menu == [NSApp windowsMenu])
	{
		for( i = 4; i < [menu numberOfItems]; i++)
		{
			if( [[[menu itemAtIndex:i] title] isEqualToString:@"Local DICOM Database"] == NO)
			{
				[[menu itemAtIndex:i] setKeyEquivalent:[[[NSNumber numberWithLong:val] stringValue] retain]];
				[[menu itemAtIndex:i] setKeyEquivalentModifierMask: NSCommandKeyMask];
				val++;
			}
		}
	}
}

@end
