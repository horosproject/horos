/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "N2HexadecimalNumberFormatter.h"


@implementation N2HexadecimalNumberFormatter

-(NSString*)stringForObjectValue:(NSNumber*)number {
    if (![number isKindOfClass:[NSNumber class]])
        return NULL;
	
	NSString* format = [NSString stringWithFormat:@"0x%%0%dX", (int) self.formatWidth];
	
    return [NSString stringWithFormat:format, [number intValue]];
}

-(BOOL)getObjectValue:(id*)outNumber forString:(NSString*)string errorDescription:(NSString**)outError {
	NSScanner* scanner = [NSScanner scannerWithString:string];

	unsigned int value;
	BOOL success = [scanner scanHexInt:&value];
	
	if (success)
		*outNumber = [NSNumber numberWithUnsignedInt:value];
	return success;
}

-(NSAttributedString*)attributedStringForObjectValue:(NSNumber*)number withDefaultAttributes:(NSDictionary*)attributes {
	/*if (![number isKindOfClass:[NSNumber class]])
        return NULL;
	
	return [[[NSAttributedString alloc] initWithString:[self stringForObjectValue:number] attributes:attributes] autorelease];*/
	
	return NULL;
}

@end

