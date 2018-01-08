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
 OsiriX Project.
 
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

#import "DDRange.h"
#import "DDNumber.h"

DDRange DDUnionRange(DDRange range1, DDRange range2)
{
	DDRange result;
	
	result.location = MIN(range1.location, range2.location);
	result.length   = MAX(DDMaxRange(range1), DDMaxRange(range2)) - result.location;
	
	return result;
}

DDRange DDIntersectionRange(DDRange range1, DDRange range2)
{
	DDRange result;
	
	if((DDMaxRange(range1) < range2.location) || (DDMaxRange(range2) < range1.location))
	{
		return DDMakeRange(0, 0);
	}
	
	result.location = MAX(range1.location, range2.location);
	result.length   = MIN(DDMaxRange(range1), DDMaxRange(range2)) - result.location;
	
	return result;
}

NSString *DDStringFromRange(DDRange range)
{
	return [NSString stringWithFormat:@"{%qu, %qu}", range.location, range.length];
}

DDRange DDRangeFromString(NSString *aString)
{
	DDRange result = DDMakeRange(0, 0);
	
	// NSRange will ignore '-' characters, but not '+' characters
	NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"+0123456789"];
	
	NSScanner *scanner = [NSScanner scannerWithString:aString];
	[scanner setCharactersToBeSkipped:[cset invertedSet]];
	
	NSString *str1 = nil;
	NSString *str2 = nil;
	
	BOOL found1 = [scanner scanCharactersFromSet:cset intoString:&str1];
	BOOL found2 = [scanner scanCharactersFromSet:cset intoString:&str2];
	
	if(found1) [NSNumber parseString:str1 intoUInt64:&result.location];
	if(found2) [NSNumber parseString:str2 intoUInt64:&result.length];
	
	return result;
}

NSInteger DDRangeCompare(DDRangePointer pDDRange1, DDRangePointer pDDRange2)
{
	// Comparison basis:
	// Which range would you encouter first if you started at zero, and began walking towards infinity.
	// If you encouter both ranges at the same time, which range would end first.
	
	if(pDDRange1->location < pDDRange2->location)
	{
		return NSOrderedAscending;
	}
	if(pDDRange1->location > pDDRange2->location)
	{
		return NSOrderedDescending;
	}
	if(pDDRange1->length < pDDRange2->length)
	{
		return NSOrderedAscending;
	}
	if(pDDRange1->length > pDDRange2->length)
	{
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

@implementation NSValue (NSValueDDRangeExtensions)

+ (NSValue *)valueWithDDRange:(DDRange)range
{
	return [NSValue valueWithBytes:&range objCType:@encode(DDRange)];
}

- (DDRange)ddrangeValue
{
	DDRange result;
	[self getValue:&result];
	return result;
}

- (NSInteger)ddrangeCompare:(NSValue *)other
{
	DDRange r1 = [self ddrangeValue];
	DDRange r2 = [other ddrangeValue];
	
	return DDRangeCompare(&r1, &r2);
}

@end
