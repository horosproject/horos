/*=========================================================================
 This file is part of the Horos Project (www.horosproject.org)
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 The Horos Project was based originally upon the OsiriX Project which at the time of
 the code fork was licensed as a LGPL project.  However, not all of the the source-code
 was properly documented and file headers were not all updated with the appropriate
 license terms. The Horos Project, originally was licensed under the  GNU GPL license.
 However, contributors to the software since that time have agreed to modify the license
 to the GNU LGPL in order to be conform to the changes previously made to the
 OsiriX project.
 
 Horos is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY EXPRESS OR IMPLIED, INCLUDING ANY WARRANTY OF
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE OR USE.  See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with Horos.  If not, see http://www.gnu.org/licenses/lgpl.html
 
 Prior versions of this file were published by the OsiriX team pursuant to
 the below notice and licensing protocol.
 ============================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "BodyRegionArrayController.h"


@implementation BodyRegionArrayController

- (void)setContent:(id)content{
	NSMutableArray *newContent = [NSMutableArray array];
	NSDictionary *dict;
	NSEnumerator *enumerator = [content objectEnumerator];
	while (dict = [enumerator nextObject]){
		NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:dict];
		NSEnumerator *enumerator2 = [[newDict objectForKey:@"keywords"] objectEnumerator];
		NSDictionary *keywords;
		NSMutableArray *childArray = [NSMutableArray array];
		while (keywords = [enumerator2 nextObject]) {
			NSMutableDictionary *newKeywords  = [NSMutableDictionary dictionaryWithDictionary:keywords];
			[childArray addObject:newKeywords];
		}
		[newDict setObject:childArray forKey:@"keywords"];		
		[newContent addObject:newDict];
	}
	[super setContent:newContent];
}

- (IBAction)addOrRemove:(id)sender{
	if ([sender selectedSegment] == 0)
		[self add:sender];
	else
		[self remove:sender];
}
	

@end
