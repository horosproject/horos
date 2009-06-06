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

#import "HotKeyTextFieldCell.h"
#import "HotKeyFormatter.h"


@implementation HotKeyTextFieldCell


- (void)awakeFromNib{
	HotKeyFormatter *formatter = [[[HotKeyFormatter alloc] init] autorelease];
	[self setFormatter:formatter];
}


@end
