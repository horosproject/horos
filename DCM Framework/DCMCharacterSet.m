/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DCMCharacterSet.h"

char* DCMreplaceInvalidCharacter( char* str ) {
	long i = strlen( str);
	
	while( i-- >0 )	{
		if( str[i] == '/') str[i] = '-';
		if( str[i] == '^') str[i] = ' ';
	}
	
	i = strlen( str);
	while( --i > 0 ) {
		if( str[i] ==' ') str[i] = 0;
		else i = 0;
	}
	
	return str;
}

@implementation DCMCharacterSet

@synthesize encoding, encodings, characterSet = _characterSet, description = _characterSet;

+ (NSString*) NSreplaceBadCharacter: (NSString*) str
{
	if( str == nil) return nil;
	
	NSMutableString	*mutable = [NSMutableString stringWithString: str];
	
//	[mutable replaceOccurrencesOfString:@"^" withString:@" " options:0 range:NSMakeRange(0, [mutable length])]; 
//	[mutable replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\"" withString:@"'" options:0 range:NSMakeRange(0, [mutable length])];
	
	int i = [mutable length];
	while( --i > 0)
	{
		if( [mutable characterAtIndex: i]==' ') [mutable deleteCharactersInRange: NSMakeRange( i, 1)];
		else i = 0;
	}
	
	return mutable;
}

+ (NSString *) stringWithBytes:(char *) str length:(unsigned) length encodings: (NSStringEncoding*) encodings
{
	if( str == nil) return nil;
	
	char c;
	int i, x, from, index;
	
	NSMutableString *result = [NSMutableString string];
	
	for( i = 0, from = 0, index = 0; i < length; i++)
	{
		c = str[ i];
		
		if( c == 0x1b || i == length-1)
		{
			if( i == length-1) i = length;
			
			NSString	*s = [[NSString alloc] initWithBytes: str+from length:i-from encoding:encodings[ index]];
			
			if( s)
			{
				[result appendString: s];
				
				if( encodings[ index] == -2147481280)	// Korean support
				{
					[result replaceOccurrencesOfString:@"$)C" withString:@"" options:0 range:NSMakeRange(0, [result length])];
				}
				
				[s release];
			}
			
			from = i;
			index = 1;
		}
	}
	
	return [DCMCharacterSet NSreplaceBadCharacter: result];
}

+ (NSStringEncoding)encodingForDICOMCharacterSet:(NSString *)characterSet
{
	NSStringEncoding	encoding = NSISOLatin1StringEncoding;
	
	if( characterSet == nil) return encoding;
	if( [characterSet isEqualToString:@""]) return encoding;
	
	if ( [characterSet isEqualToString:@"ISO_IR 100"]) encoding = NSISOLatin1StringEncoding; 	
	else if( [characterSet isEqualToString:@"ISO_IR 127"]) encoding = -2147483130;	//[characterSet numberFromLocalizedStringEncodingName :@"Arabic (ISO 8859-6)"];
	else if( [characterSet isEqualToString:@"ISO_IR 101"]) encoding = NSISOLatin2StringEncoding;
	else if( [characterSet isEqualToString:@"ISO_IR 109"]) encoding = -2147483133;	//[characterSet numberFromLocalizedStringEncodingName :@"Western (ISO Latin 3)"];
	else if( [characterSet isEqualToString:@"ISO_IR 110"]) encoding = -2147483132;	//[characterSet numberFromLocalizedStringEncodingName :@"Central European (ISO Latin 4)"];
	else if( [characterSet isEqualToString:@"ISO_IR 144"]) encoding = -2147483131;	//[characterSet numberFromLocalizedStringEncodingName :@"Cyrillic (ISO 8859-5)"];
	else if( [characterSet isEqualToString:@"ISO_IR 126"]) encoding = -2147483129;	//[characterSet numberFromLocalizedStringEncodingName :@"Greek (ISO 8859-7)"];
	else if( [characterSet isEqualToString:@"ISO_IR 138"]) encoding = -2147483128;	//[characterSet numberFromLocalizedStringEncodingName :@"Hebrew (ISO 8859-8)"];
	else if( [characterSet isEqualToString:@"GB18030"]) encoding = -2147482062;	//[characterSet numberFromLocalizedStringEncodingName :@"Chinese (GB 18030)"];
	else if( [characterSet isEqualToString:@"ISO_IR 192"]) encoding = NSUTF8StringEncoding;
	else if( [characterSet isEqualToString:@"ISO 2022 IR 149"]) encoding = -2147481280;	//-2147482590 -2147481536 -2147481280[characterSet numberFromLocalizedStringEncodingName :@"Korean (Mac OS)"];
	else if( [characterSet isEqualToString:@"ISO 2022 IR 13"]) encoding = -2147483647;	//21 //[characterSet numberFromLocalizedStringEncodingName :@"Japanese (ISO 2022-JP)"];	//
	else if( [characterSet isEqualToString:@"ISO_IR 13"]) encoding = -2147483647;	//[characterSet numberFromLocalizedStringEncodingName :@"Japanese (Mac OS)"];
	else if( [characterSet isEqualToString:@"ISO 2022 IR 87"]) encoding = NSISO2022JPStringEncoding;
	else if( [characterSet isEqualToString:@"ISO_IR 166"]) encoding = -2147483125;	//[characterSet numberFromLocalizedStringEncodingName :@"Thai (ISO 8859-11)"];
	else if( [characterSet isEqualToString:@"ISO_2022_IR_6"])	encoding = NSISOLatin1StringEncoding;
	else if( [characterSet isEqualToString:@"UTF-8"])	encoding = NSUTF8StringEncoding;
	else
	{
		NSLog(@"** encoding not found: %@", characterSet);
	}
	return encoding;

}

- (id)initWithCode:(NSString *)characterSet
{
	if (self = [super init])
	{
		_characterSet = [characterSet retain];
		encoding = NSISOLatin1StringEncoding;
		
		if( encodings == nil)
			encodings = (NSStringEncoding*) malloc( 10 * sizeof( NSStringEncoding));
		
		for( int i = 0; i < 10; i++) encodings[ i] = NSISOLatin1StringEncoding;
		
		NSArray *e = [characterSet componentsSeparatedByString: @"//"];
		
		for( int z = 0; z < [e count] ; z++)
		{
			if( z < 10)
				encodings[ z] = [DCMCharacterSet encodingForDICOMCharacterSet: [e objectAtIndex: z]];
			else
				NSLog( @"Encoding number >= 10 ???");
		}
	}
	return self;
}

- (id)initWithCharacterSet:(DCMCharacterSet *)characterSet
{
	return [self initWithCode:[characterSet characterSet]];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[DCMCharacterSet allocWithZone:zone] initWithCharacterSet:self];
}

- (void)dealloc
{
	if( encodings) free( encodings);
	[_characterSet release];
	[super dealloc];
}

@end
