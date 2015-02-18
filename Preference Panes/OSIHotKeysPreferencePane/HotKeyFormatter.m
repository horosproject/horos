/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
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


#import "HotKeyFormatter.h"


@implementation HotKeyFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error{
	if ([partialString length] > 1)
		return NO;
	return YES;
}

- (NSString *)stringForObjectValue:(id)anObject{
    
    if( [anObject isEqualToString: @"dbl-click"])
        return NSLocalizedString( @"dbl-click", @"keep it short !");
    
    if( [anObject isEqualToString: @"dbl-click + alt"])
        return NSLocalizedString( @"dbl-click + alt", @"keep it short ! dbl-click + alt = double-click + alternate key");
    
    if( [anObject isEqualToString: @"dbl-click + cmd"])
        return NSLocalizedString( @"dbl-click + cmd", @"keep it short ! double-click + command key");
    
	 return [anObject uppercaseString];
}

- (NSString *)editingStringForObjectValue:(id)anObject{
	return anObject;
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error{
	*anObject = [[string copy] autorelease];
	return YES;
}




@end
