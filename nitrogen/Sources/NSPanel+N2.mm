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

#import "NSPanel+N2.h"


@implementation NSPanel (N2)

+(NSPanel*)alertWithTitle:(NSString*)title message:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton icon:(NSImage*)icon {
	NSPanel* panel = NSGetAlertPanel(title, message, defaultButton, alternateButton, NULL);
	
	if (icon)
		for (NSImageView* view in [[panel contentView] subviews])
			if ([view isKindOfClass:[NSImageView class]])
				[view setImage:icon];
	
	return [panel autorelease];
}

@end
