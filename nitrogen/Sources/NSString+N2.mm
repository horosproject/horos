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

#import "NSString+N2.h"
#include <cmath>


@implementation NSString (N2)

-(NSString*)markedString {
	NSString* str = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
	str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
	return str;
}

+(NSString*)sizeString:(unsigned long long)size { // From http://snippets.dzone.com/posts/show/3038 with slight modifications
    if (size<1023)
        return [NSString stringWithFormat:@"%i octets", size];
    float floatSize = float(size) / 1024;
    if (floatSize<1023)
        return [NSString stringWithFormat:@"%1.1f KO", floatSize];
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return [NSString stringWithFormat:@"%1.1f MO", floatSize];
    floatSize = floatSize / 1024;
    return [NSString stringWithFormat:@"%1.1f GO", floatSize];
}

+(NSString*)timeString:(NSTimeInterval)time {
	NSString* unit; unsigned value;
	if (time < 60-1) {
		unit = @"seconde"; value = std::ceil(time);
	} else if (time < 3600-1) {
		unit = @"minute"; value = std::ceil(time/60);
	} else {
		unit = @"heure"; value = std::ceil(time/3600);
	}
	
	return [NSString stringWithFormat:@"%d %@%@", value, unit, value==1? @"" : @"s"];
}

+(NSString*)dateString:(NSTimeInterval)date {
	return [[NSDate dateWithTimeIntervalSinceReferenceDate:date] descriptionWithCalendarFormat:@"le %d.%m.%Y à %Hh%M" timeZone:NULL locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

-(NSString*)stringByTrimmingStartAndEnd {
	NSCharacterSet* whitespaceAndNewline = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	unsigned i;
	for (i = 0; i < [self length] && [whitespaceAndNewline characterIsMember:[self characterAtIndex:i]]; ++i);
	if (i == [self length]) return @"";
	unsigned start = i;
	for (i = [self length]-1; i > start && [whitespaceAndNewline characterIsMember:[self characterAtIndex:i]]; --i);
	return [self substringWithRange:NSMakeRange(start, i-start+1)];
}

-(NSString*)urlEncodedString {
	static const NSDictionary* chars = [[NSDictionary dictionaryWithObjectsAndKeys:
											@"%3B", @";",
											@"%2F", @"/",
											@"%3F", @"?",
											@"%3A", @":",
											@"%40", @"@",
											@"%26", @"&",
											@"%3D", @"=",
											@"%2B", @"+",
											@"%24", @"$",
											@"%2C", @",",
											@"%5B", @"[",
											@"%5D", @"]",
											@"%23", @"#",
											@"%21", @"!",
											@"%27", @"'",
											@"%28", @"(",
											@"%29", @")",
											@"%2A", @"*",
										NULL] retain];
	
	NSMutableString* temp = [self mutableCopy];
	for (NSString* k in chars)
		[temp replaceOccurrencesOfString:k withString:[chars objectForKey:k] options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
	return [NSString stringWithString: temp];
}

-(NSString*)xmlEscapedString:(BOOL)unescape {
	static const NSDictionary* chars = [[NSDictionary dictionaryWithObjectsAndKeys:
										 @"&lt;", @"<",
										 @"&gt;", @">",
										 @"&amp;", @"&",
										 @"&apos;", @"'",
										 @"&quot;", @"\"",
										 NULL] retain];
	
	NSMutableString* temp = [self mutableCopy];
	for (NSString* k in chars)
		if (!unescape)
			[temp replaceOccurrencesOfString:k withString:[chars objectForKey:k] options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		else [temp replaceOccurrencesOfString:[chars objectForKey:k] withString:k options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
	
	return [NSString stringWithString:temp];
}

-(NSString*)xmlEscapedString {
	return [self xmlEscapedString:NO];
}

-(NSString*)xmlUnescapedString {
	return [self xmlEscapedString:YES];
}

-(NSString*)ASCIIString {
	return [[[NSString alloc] initWithData:[self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding] autorelease];
}

@end
