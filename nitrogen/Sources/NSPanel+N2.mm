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
	return [self alertWithTitle:title message:message defaultButton:defaultButton alternateButton:alternateButton icon:icon sheet:NO];
}

+(NSPanel*)alertWithTitle:(NSString*)title message:(NSString*)message defaultButton:(NSString*)defaultButton alternateButton:(NSString*)alternateButton icon:(NSImage*)icon sheet:(BOOL)sheet {
	NSPanel* panel = NSGetAlertPanel(title, @"%@", defaultButton, alternateButton, NULL, message);
	
	if (icon) {
		for (NSImageView* view in [[panel contentView] subviews])
			if ([view isKindOfClass:[NSImageView class]])
				[view setImage:icon];
	}
	
	if (sheet) {
		for (NSButton* button in [[panel contentView] subviews])
			if ([button isKindOfClass:[NSButton class]]) {
//				NSLog(@"button: %@ --- %@ %@ --- %d", button, [button target], NSStringFromSelector([button action]), [button tag]);
				[button setTarget:self];
				[button setAction:@selector(_sheetButtonAction:)];
			}
	}
	
	return [panel autorelease];
}

+(void)_sheetButtonAction:(NSButton*)button {
	[NSApp endSheet:[button window] returnCode:[button tag]];
}

@end
