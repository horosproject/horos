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


#import "NSHost+N2.h"

@implementation NSHost (N2)

+(NSHost*)hostWithAddressOrName:(NSString*)str {
    if (![str rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length)
        return [NSHost hostWithAddress:str];
	else return [NSHost hostWithName:str];
}

@end
