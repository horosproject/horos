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

#import <Cocoa/Cocoa.h>

@interface PSGenerator : NSObject
{
	// Parameters
	NSMutableString		*formatString;
	NSMutableDictionary	*sourceStringsDict;
	unsigned			minLength;
	unsigned			maxLength;
	unsigned			alternativeNum;
	BOOL				shouldMix;
	
	// Temporary Variables
	NSMutableArray  *tempArray;
	NSMutableString *tempString;
	NSString		*sourceString;
	NSString		*tempKey;
	NSMutableString *tempFormatString;
	unsigned		thisLength;
	unsigned		randCharPos;
	unsigned		tempAltNum;
	int				i, j, x, y;
	
}

- (id) initWithFormatString: (NSMutableString *) str
			  sourceStrings: (NSMutableDictionary *) stringDict
				  minLength: (unsigned) min
				  maxLength: (unsigned) max;
- (id) initWithSourceString: (NSString *) str
				  minLength: (unsigned) min
				  maxLength: (unsigned) max;
- (void) dealloc;


- (void) setFormatString: (NSMutableString *) str;
- (void) setStandardFormatString;
- (void) setSourceStrings: (NSMutableDictionary *) stringDict;
- (void) setMinLength: (unsigned) min;
- (void) setMaxLength: (unsigned) max;
- (void) setAlternativeNum: (unsigned) num;

- (NSString *) mainCharacterString;
- (NSString *) altCharacterString;
- (unsigned) minLength;
- (unsigned) maxLength;
- (unsigned) alternativeNum;
 

- (void) addStringToDict: (NSString *) str
				 withKey: (NSString *) key;

- (NSArray *) generate: (unsigned) numPasswords;
- (void) prepareFormatString;
@end

int randomNumberBetween( int low, int high );