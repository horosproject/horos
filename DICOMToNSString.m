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

#import "DICOMToNSString.h"

@implementation NSString (DICOMToNSString)

- (id) initWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding
{
	NSStringEncoding stringEncoding = [NSString encodingForDICOMCharacterSet: encoding];
	
	return [self initWithCString:cString  encoding:stringEncoding];
}

+ (id) stringWithCString:(const char *)cString  DICOMEncoding:(NSString *)encoding
{
	return [[[NSString alloc] initWithCString: cString  DICOMEncoding: encoding] autorelease];
}

//+ (NSArray *)allAvailableEncodings
//{
//	static NSArray *cachedArray = nil;
//	NSMutableArray *array;
//	const NSStringEncoding *encoding;
//	
//	if (cachedArray != nil)
//		return cachedArray;
//	
//	array = [[NSMutableArray alloc] initWithCapacity:0x40];
//	encoding = [NSString availableStringEncodings];
//    
//    while (*encoding) {
//		NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:2];
//		
//        [row addObject:[NSString localizedNameOfStringEncoding:*encoding]];
//        [row addObject:[NSNumber numberWithInt:*encoding]];
//        encoding++;
//        
//        [array addObject:row];
//        [row release];
//    }
//    
//	cachedArray = [array copy];
//	[array retain];
//    return cachedArray;
//}

+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet
{
	NSStringEncoding encoding = NSISOLatin1StringEncoding;
	
	if( characterSet == nil) return encoding;
	if( [characterSet isEqualToString:@""]) return encoding;
	
	characterSet = [characterSet stringByReplacingOccurrencesOfString:@"-" withString:@" "];
	characterSet = [characterSet stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    characterSet = [characterSet stringByReplacingOccurrencesOfString:@"ISO 2022" withString:@"ISO"];
	
	if	   ( [characterSet isEqualToString:@"ISO IR 100"]) encoding = NSISOLatin1StringEncoding;
	else if( [characterSet isEqualToString:@"ISO IR 127"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinArabic);
    else if( [characterSet isEqualToString:@"ISO IR 148"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin5);
	else if( [characterSet isEqualToString:@"ISO IR 101"]) encoding = NSISOLatin2StringEncoding;
	else if( [characterSet isEqualToString:@"ISO IR 109"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin3);
	else if( [characterSet isEqualToString:@"ISO IR 110"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatin4);
	else if( [characterSet isEqualToString:@"ISO IR 144"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinCyrillic);
	else if( [characterSet isEqualToString:@"ISO IR 126"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinGreek);
	else if( [characterSet isEqualToString:@"ISO IR 138"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinHebrew);
    else if( [characterSet isEqualToString:@"ISO IR 166"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISOLatinThai);
	else if( [characterSet isEqualToString:@"GB18030"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingGB_18030_2000);
	else if( [characterSet isEqualToString:@"ISO IR 192"]) encoding = NSUTF8StringEncoding;
	else if( [characterSet isEqualToString:@"ISO IR 13"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingMacJapanese);
	else if( [characterSet isEqualToString:@"ISO IR 6"])	encoding = NSISOLatin1StringEncoding;
    else if( [characterSet isEqualToString:@"ISO IR 13"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingMacJapanese);
    else if( [characterSet isEqualToString:@"ISO IR 58"])	encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingISO_2022_CN);
    else if( [characterSet isEqualToString:@"ISO IR 87"]) encoding = NSISO2022JPStringEncoding;
    else if( [characterSet isEqualToString:@"ISO IR 100"]) encoding = NSISOLatin1StringEncoding;
    else if( [characterSet isEqualToString:@"ISO IR 149"]) encoding = CFStringConvertEncodingToNSStringEncoding( kCFStringEncodingEUC_KR);
    else if( [characterSet isEqualToString:@"ISO IR 6"])	encoding = NSISOLatin1StringEncoding;
	else if( [characterSet isEqualToString:@"UTF 8"])	encoding = NSUTF8StringEncoding;
	else
	{
		NSLog(@"** DICOMTONSString encoding not found: %@", characterSet);
		
        if( characterSet.length < 50)
        {
            NSArray *multipleEncoding = [characterSet componentsSeparatedByString:@"\\"];
            if( [multipleEncoding count] > 1)
            {
                NSLog( @"**** error: multiple encoding in %s : %@", __PRETTY_FUNCTION__, characterSet);
                return [NSString encodingForDICOMCharacterSet: [multipleEncoding objectAtIndex: 0]];
            }
        }
	}
	return encoding;

}

@end
