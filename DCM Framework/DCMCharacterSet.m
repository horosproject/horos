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

@synthesize encoding, encodings, characterSet = _characterSet;

+ (NSString*) NSreplaceBadCharacter: (NSString*) str
{
	if( str == nil) return nil;
	
	NSMutableString	*mutable = [NSMutableString stringWithString: str];
	
//	[mutable replaceOccurrencesOfString:@"^" withString:@" " options:0 range:NSMakeRange(0, [mutable length])]; 
//	[mutable replaceOccurrencesOfString:@"/" withString:@"-" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [mutable length])]; 
	[mutable replaceOccurrencesOfString:@"\"" withString:@"'" options:0 range:NSMakeRange(0, [mutable length])];
	
	int i = (int)[mutable length];
	while( --i > 0)
	{
		if( [mutable characterAtIndex: i]==' ') [mutable deleteCharactersInRange: NSMakeRange( i, 1)];
		else i = 0;
	}
	
	return mutable;
}

// Based on dcmtk 3.6 convertString function

+ (NSString *) stringWithBytes:(char *) str length:(unsigned) length encodings: (NSStringEncoding*) encodings
{
	if( str == nil) return nil;
    
    int	fromLength;
    
    if( length > 0)
        fromLength = length;
	else
    {
        NSLog( @"***** warning DCMCharacterSet stringWithBytes, length == 0, use C String length");
        fromLength = (int)strlen(str);
    }
    
	NSMutableString	*result = [NSMutableString string];
    BOOL checkPNDelimiters = YES;
    NSStringEncoding currentEncoding = encodings[ 0];
	int pos = 0;
    char *firstChar = str;
    char *currentChar = str;
    BOOL isFirstGroup = NO; // if delimiters contains '=' -> patient name
    int escLength = 0;
    
	while(pos < fromLength)
	{
		char c0 = *currentChar++;
        BOOL isEscape = (c0 == '\033');
        BOOL isDelimiter = (c0 == '\012') || (c0 == '\014') || (c0 == '\015') || (((c0 == '^') || (c0 == '=')) && (((c0 != '^') && (c0 != '=')) || checkPNDelimiters));
        
        if (isEscape || isDelimiter)
        {
            int convertLength = (int)(currentChar-firstChar) - 1;
			
            if( convertLength - (escLength+1) >= 0)
            {
                NSString *s = nil;
                
                s = [[[NSString alloc] initWithBytes: firstChar length:convertLength encoding: currentEncoding] autorelease];
                
                if( s)
                    [result appendString: s];
            }
            
            // check whether this was the first component group of a PN value
            if (isDelimiter && (c0 == '='))
                isFirstGroup = NO;
        }
        
        if (isEscape)
        {
            // report a warning as this is a violation of DICOM PS 3.5 Section 6.2.1
            if (isFirstGroup)
            {
                NSLog( @"DcmSpecificCharacterSet: Escape sequences shall not be used in the first component group of a Person Name (PN), using them anyway)");
            }
            
            // we need at least two more characters to determine the new character set
            escLength = 2;
            if (pos + escLength < fromLength)
            {
                NSString *key = nil;
                char c1 = *currentChar++;
                char c2 = *currentChar++;
                char c3 = '\0';
                if ((c1 == 0x28) && (c2 == 0x42))       // ASCII
                    key = @"ISO 2022 IR 6";
                else if ((c1 == 0x2d) && (c2 == 0x41))  // Latin alphabet No. 1
                    key = @"ISO 2022 IR 100";
                else if ((c1 == 0x2d) && (c2 == 0x42))  // Latin alphabet No. 2
                    key = @"ISO 2022 IR 101";
                else if ((c1 == 0x2d) && (c2 == 0x43))  // Latin alphabet No. 3
                    key = @"ISO 2022 IR 109";
                else if ((c1 == 0x2d) && (c2 == 0x44))  // Latin alphabet No. 4
                    key = @"ISO 2022 IR 110";
                else if ((c1 == 0x2d) && (c2 == 0x4c))  // Cyrillic
                    key = @"ISO 2022 IR 144";
                else if ((c1 == 0x2d) && (c2 == 0x47))  // Arabic
                    key = @"ISO 2022 IR 127";
                else if ((c1 == 0x2d) && (c2 == 0x46))  // Greek
                    key = @"ISO 2022 IR 126";
                else if ((c1 == 0x2d) && (c2 == 0x48))  // Hebrew
                    key = @"ISO 2022 IR 138";
                else if ((c1 == 0x2d) && (c2 == 0x4d))  // Latin alphabet No. 5
                    key = @"ISO 2022 IR 148";
                else if ((c1 == 0x29) && (c2 == 0x49))  // Japanese
                    key = @"ISO 2022 IR 13";
                else if ((c1 == 0x28) && (c2 == 0x4a))  // Japanese - is this really correct?
                    key = @"ISO 2022 IR 13";
                else if ((c1 == 0x2d) && (c2 == 0x54))  // Thai
                    key = @"ISO 2022 IR 166";
                else if ((c1 == 0x24) && (c2 == 0x42))  // Japanese (multi-byte)
                    key = @"ISO 2022 IR 87";
                else if ((c1 == 0x24) && (c2 == 0x28))  // Japanese (multi-byte)
                {
                    escLength = 3;
                    // do we still have another character in the string?
                    if (pos + escLength < fromLength)
                    {
                        c3 = *currentChar++;
                        if (c3 == 0x44)
                            key = @"ISO 2022 IR 159";
                    }
                }
                else if ((c1 == 0x24) && (c2 == 0x29)) // Korean (multi-byte)
                {
                    escLength = 3;
                    // do we still have another character in the string?
                    if (pos + escLength < fromLength)
                    {
                        c3 = *currentChar++;
                        if (c3 == 0x43)                 // Korean (multi-byte)
                            key = @"ISO 2022 IR 149";
                        else if (c3 == 0x41)            // Simplified Chinese (multi-byte)
                            key = @"ISO 2022 IR 58";
                    }
                }
                
                if( key == nil)
                    NSLog( @"*** key == nil");
                else
                {
                    currentEncoding = [DCMCharacterSet encodingForDICOMCharacterSet: key];
                    
                    BOOL found = NO;
                    for( int x = 0; x < 10; x++)
                    {
                        if( currentEncoding == encodings[ x])
                            found = YES;
                    }
                    
                    if( found == NO)
                        NSLog( @"*** encoding not found in declared SpecificCharacterSet (0008,0005)");
                    
                    checkPNDelimiters = ([key isEqualToString: @"ISO 2022 IR 87"] == NO) && ([key isEqualToString: @"ISO 2022 IR 159"] == NO);
                    
                    if( checkPNDelimiters)
                        firstChar = currentChar;
                    else
                        firstChar = currentChar - (escLength+1);
                    
                }
                
                pos += escLength;
                
                if( checkPNDelimiters)
                    escLength = 0;
            }
            
            if(pos >= fromLength)
                NSLog( @"incomplete sequence");
        }
        else if (isDelimiter)
        {
            [result appendFormat: @"%c", c0];
            
            if (currentEncoding != encodings[ 0])
            {
                currentEncoding = encodings[ 0];
                checkPNDelimiters = YES;
            }
            firstChar = currentChar;
        }
        ++pos;
	}
	
    // convert any remaining characters from the input string
    {
        int convertLength = (int)(currentChar - firstChar);
        if (convertLength > 0)
        {
            int convertLength = (int)(currentChar - firstChar);
            
            if( firstChar + convertLength <= str + fromLength && ( convertLength - (escLength+1) >= 0))
            {
                NSString *s = [[[NSString alloc] initWithBytes: firstChar length:convertLength encoding: currentEncoding] autorelease];
                
                if( s)
                    [result appendString: s];
            }
        }
	}
    
    return result;
}

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
                return [DCMCharacterSet encodingForDICOMCharacterSet: [multipleEncoding objectAtIndex: 0]];
            }
        }
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
		
		for( int i = 0; i < 10; i++) encodings[ i] = 0;
		encodings[ 0] = NSISOLatin1StringEncoding;
		
		NSArray *e = [characterSet componentsSeparatedByString: @"\\"];
		
		for( int z = 0; z < [e count] ; z++)
		{
			if( z < 10)
				encodings[ z] = [DCMCharacterSet encodingForDICOMCharacterSet: [e objectAtIndex: z]];
			else
				NSLog( @"Encoding number >= 10 ???");
		}
		encoding = encodings[ 0];
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

- (NSString*) description
{
	return _characterSet;
}
@end
