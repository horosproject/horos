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

#import "stringNumericCompare.h"
#import <Foundation/Foundation.h>

@implementation NSString (stringNumericCompare)

-(NSComparisonResult)numericCompare:(NSString *)aString
{
    return [self compare:aString options:NSNumericSearch | NSCaseInsensitiveSearch];
}

@end
