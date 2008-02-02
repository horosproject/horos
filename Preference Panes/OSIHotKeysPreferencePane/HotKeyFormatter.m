/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import "HotKeyFormatter.h"


@implementation HotKeyFormatter

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error{
	if ([partialString length] > 1)
		return NO;
	return YES;
}

- (NSString *)stringForObjectValue:(id)anObject{
	 return [anObject  uppercaseString];
}

- (NSString *)editingStringForObjectValue:(id)anObject{
	return anObject;
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error{
	*anObject = [string copy];
	return YES;
}




@end
