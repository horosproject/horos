//
//  DCMCharacterSet.m
//  OsiriX
//
//  Created by Lance Pysher on Fri Jun 11 2004.

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMCharacterSet.h"

char* DCMreplaceInvalidCharacter (char* str) 
{
	long i = strlen( str);
	
	while( i-- >0)
	{
		if( str[i] == '/') str[i] = '-';
		if( str[i] == '^') str[i] = ' ';
	}
	
	i = strlen( str);
	while( --i > 0)
	{
		if( str[i] ==' ') str[i] = 0;
		else i = 0;
	}
	
	return str;
}


//@implementation NSString(DCM_encodings)
//- (NSArray*)allAvailableEncodings
//{
//    NSMutableArray*     array = [[NSMutableArray array] retain];
//    const NSStringEncoding*     encoding = [NSString availableStringEncodings];
//
//    while (*encoding) {
//        NSMutableArray* row = [NSMutableArray arrayWithCapacity:2];
//
//        [row addObject:[NSString localizedNameOfStringEncoding:*encoding]];
//        [row addObject:[NSNumber numberWithInt:*encoding]];
//        encoding++;
//
//        [array addObject:row];
//
//    }
//
//    return [array autorelease];
//}
//
//- (int)numberFromLocalizedStringEncodingName:(NSString*)aName
//{
//    NSArray *encodings = [[self allAvailableEncodings] retain];
//    NSEnumerator *en = [encodings objectEnumerator];
//    NSArray *encPair = [NSArray array];
//    int searchedNumber = 0;
//
//    while (encPair = [en nextObject])
//    {
//        if ([[encPair objectAtIndex:0] isEqualTo:aName])
//            searchedNumber = [[encPair objectAtIndex:1] intValue];
//    }
//
//    [encodings release];
//    return searchedNumber;
//}
//@end



@implementation DCMCharacterSet

- (id)initWithCode:(NSString *)characterSet{
	_characterSet = [characterSet retain];
	encoding = NSISOLatin1StringEncoding;
	if (self = [super init]) {
	
		if( [characterSet isEqualToString:@"ISO_IR 127"])		encoding = -2147483130;	//[characterSet numberFromLocalizedStringEncodingName :@"Arabic (ISO 8859-6)"];
		if( [characterSet isEqualToString:@"ISO_IR 101"])		encoding = NSISOLatin2StringEncoding;
		if( [characterSet isEqualToString:@"ISO_IR 109"])		encoding = -2147483133;	//[characterSet numberFromLocalizedStringEncodingName :@"Western (ISO Latin 3)"];
		if( [characterSet isEqualToString:@"ISO_IR 110"])		encoding = -2147483132;	//[characterSet numberFromLocalizedStringEncodingName :@"Central European (ISO Latin 4)"];
		if( [characterSet isEqualToString:@"ISO_IR 144"])		encoding = -2147483131;	//[characterSet numberFromLocalizedStringEncodingName :@"Cyrillic (ISO 8859-5)"];
		if( [characterSet isEqualToString:@"ISO_IR 126"])		encoding = -2147483129;	//[characterSet numberFromLocalizedStringEncodingName :@"Greek (ISO 8859-7)"];
		if( [characterSet isEqualToString:@"ISO_IR 138"])		encoding = -2147483128;	//[characterSet numberFromLocalizedStringEncodingName :@"Hebrew (ISO 8859-8)"];
		if( [characterSet isEqualToString:@"GB18030"])			encoding = -2147482062;	//[characterSet numberFromLocalizedStringEncodingName :@"Chinese (GB 18030)"];
		if( [characterSet isEqualToString:@"ISO_IR 192"])		encoding = NSUTF8StringEncoding;
		if( [characterSet isEqualToString:@"ISO 2022 IR 149"])	encoding = -2147481280;	//-2147481536 [characterSet numberFromLocalizedStringEncodingName :@"Korean (Mac OS)"];
		if( [characterSet isEqualToString:@"ISO 2022 IR 13"])	encoding = -2147483647;	//[characterSet numberFromLocalizedStringEncodingName :@"Japanese (ISO 2022-JP)"];	//
		if( [characterSet isEqualToString:@"ISO_IR 13"])		encoding = -2147483647;	//[characterSet numberFromLocalizedStringEncodingName :@"Japanese (Mac OS)"];
		if( [characterSet isEqualToString:@"ISO 2022 IR 87"])	encoding = NSISO2022JPStringEncoding;	//[characterSet numberFromLocalizedStringEncodingName :@"Japanese (ISO 2022-JP)"];
		if( [characterSet isEqualToString:@"ISO_IR 166"])		encoding = -2147483125;	//[characterSet numberFromLocalizedStringEncodingName :@"Thai (ISO 8859-11)"];
	}
	return self;
}

- (id)initWithCharacterSet:(DCMCharacterSet *)characterSet{
	return [self initWithCode:[characterSet characterSet]];
}

- (id)copyWithZone:(NSZone *)zone{
	return [[DCMCharacterSet allocWithZone:zone] initWithCharacterSet:self];
}

- (void)dealloc {
	[_characterSet release];
	[super dealloc];
}

- (NSStringEncoding)encoding{
	return encoding;
}

- (NSString *)characterSet{
	 return _characterSet;
}

- (NSString *)description{
	return _characterSet;
}

@end
