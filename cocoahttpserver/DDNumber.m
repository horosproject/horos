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

#import "DDNumber.h"


@implementation NSNumber (DDNumber)

+ (BOOL)parseString:(NSString *)str intoSInt64:(SInt64 *)pNum
{
	if(str == nil)
	{
		*pNum = 0;
		return NO;
	}
	
	errno = 0;
	
	// On both 32-bit and 64-bit machines, long long = 64 bit
	
	*pNum = strtoll([str UTF8String], NULL, 10);
	
	if(errno != 0)
		return NO;
	else
		return YES;
}

+ (BOOL)parseString:(NSString *)str intoUInt64:(UInt64 *)pNum
{
	if(str == nil)
	{
		*pNum = 0;
		return NO;
	}
	
	errno = 0;
	
	// On both 32-bit and 64-bit machines, unsigned long long = 64 bit
	
	*pNum = strtoull([str UTF8String], NULL, 10);
	
	if(errno != 0)
		return NO;
	else
		return YES;
}

+ (BOOL)parseString:(NSString *)str intoNSInteger:(NSInteger *)pNum
{
	if(str == nil)
	{
		*pNum = 0;
		return NO;
	}
	
	errno = 0;
	
	// On LP64, NSInteger = long = 64 bit
	// Otherwise, NSInteger = int = long = 32 bit
	
	*pNum = strtol([str UTF8String], NULL, 10);
	
	if(errno != 0)
		return NO;
	else
		return YES;
}

+ (BOOL)parseString:(NSString *)str intoNSUInteger:(NSUInteger *)pNum
{
	if(str == nil)
	{
		*pNum = 0;
		return NO;
	}
	
	errno = 0;
	
	// On LP64, NSUInteger = unsigned long = 64 bit
	// Otherwise, NSUInteger = unsigned int = unsigned long = 32 bit
	
	*pNum = strtoul([str UTF8String], NULL, 10);
	
	if(errno != 0)
		return NO;
	else
		return YES;
}

@end
