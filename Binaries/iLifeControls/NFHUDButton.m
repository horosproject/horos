/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Portions of the Horos Project were originally licensed under the GNU GPL license.
 However, all authors of that software have agreed to modify the license to the
 GNU LGPL.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
 Program:   OsiriX
  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ============================================================================*/
//
//  NFHUDButton.m
//  iLife HUD Button
//
//  Created by Sean Patrick O'Brien on 9/23/06.
//  Copyright 2006 Sean Patrick O'Brien. All rights reserved.

#import "NFHUDButton.h"
#import "NFHUDButtonCell.h"

@implementation NFHUDButton

+ (Class)cellClass
{
	return [NFHUDButtonCell class];
}

- initWithCoder: (NSCoder *)origCoder
{
	if(![origCoder isKindOfClass: [NSKeyedUnarchiver class]]){
		self = [super initWithCoder: origCoder]; 
	} else {
		NSKeyedUnarchiver *coder = (id)origCoder;
		
		NSString *oldClassName = [[[self superclass] cellClass] className];
		Class oldClass = [coder classForClassName: oldClassName];
		if(!oldClass)
			oldClass = [[super superclass] cellClass];
		[coder setClass: [[self class] cellClass] forClassName: oldClassName];
		self = [super initWithCoder: coder];
		[coder setClass: oldClass forClassName: oldClassName];
		
		NSMutableDictionary *attrs = [[NSMutableDictionary alloc] init];
		[attrs addEntriesFromDictionary:[[self attributedTitle] attributesAtIndex:0 effectiveRange:NULL]];
		[attrs setObject:[NSColor whiteColor]forKey:NSForegroundColorAttributeName];
		NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[self title] attributes:attrs];
		[self setAttributedTitle:attrStr];
		[attrStr release];
		[attrs release];
	}
	
	return self;
}

@end
