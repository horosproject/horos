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
#import "NSMutableString+N2.h"
#include <cmath>
#include <sys/stat.h>


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

-(NSString*)urlEncodedString /* deprecated */ {
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
		[temp replaceOccurrencesOfString:k withString:[chars objectForKey:k] options:NSLiteralSearch range:temp.range];
	return [NSString stringWithString: temp];
}

-(NSString*)xmlEscapedString:(BOOL)unescape {
	static const NSDictionary* chars = [[NSDictionary dictionaryWithObjectsAndKeys:
										 @"&lt;", @"<",
										 @"&gt;", @">",
									/*	 @"&amp;", @"&",	*/
										 @"&apos;", @"'",
										 @"&quot;", @"\"",
										 NULL] retain];
	
	NSMutableString* temp = [self mutableCopy];
	// apmp first!!
	if (!unescape)
		[temp replaceOccurrencesOfString:@"&" withString:@"&amp;"];
	else [temp replaceOccurrencesOfString:@"&amp;" withString:@"&"];
	// other chars
	for (NSString* k in chars)
		if (!unescape)
			[temp replaceOccurrencesOfString:k withString:[chars objectForKey:k]];
		else [temp replaceOccurrencesOfString:[chars objectForKey:k] withString:k];
	
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

-(BOOL)contains:(NSString*)str {
	return [self rangeOfString:str options:NSLiteralSearch].location != NSNotFound;
}

-(NSString*)stringByPrefixingLinesWithString:(NSString*)prefix {
	NSMutableArray* lines = [[[self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy] autorelease];
	if ([[lines lastObject] isEqual:@""]) [lines removeLastObject];	
	return [NSString stringWithFormat:@"%@%@\n", prefix, [lines componentsJoinedByString:[NSString stringWithFormat:@"\n%@", prefix]]];
}

+(NSString*)stringByRepeatingString:(NSString*)string times:(NSUInteger)times {
	NSMutableString* ret = [[NSMutableString alloc] initWithCapacity:[string length]*times];
	for (NSUInteger i = 0; i < times; ++i)
		[ret appendString:string];
	return [ret autorelease];
}

-(NSString*)suspendedString {
	NSUInteger dotsCount = 0;
	for (NSInteger i = [self length]-1; i >= 0; --i)
		if ([self characterAtIndex:i] == '.')
			++dotsCount;
		else break;
	if (dotsCount >= 3) return self;
	return [self stringByAppendingString:[NSString stringByRepeatingString:@"." times:3-dotsCount]];
}

-(NSRange)range {
	return NSMakeRange(0, self.length);
}

#pragma mark SymLinksAndAliases
// from http://cocoawithlove.com/2010/02/resolving-path-containing-mixture-of.html

- (NSString *)stringByConditionallyResolvingSymlink
{
    // Get the path that the symlink points to
    NSString *symlinkPath =
	[[NSFileManager defaultManager]
	 destinationOfSymbolicLinkAtPath:self
	 error:NULL];
    if (!symlinkPath)
    {
        return nil;
    }
    if (![symlinkPath hasPrefix:@"/"])
    {
        // For relative path symlinks (common case), resolve the relative
        // components
        symlinkPath =
		[[self stringByDeletingLastPathComponent]
		 stringByAppendingPathComponent:symlinkPath];
        symlinkPath = [symlinkPath stringByStandardizingPath];
    }
    return symlinkPath;
}

- (NSString *)stringByConditionallyResolvingAlias
{
	NSString *resolvedPath = nil;
	
	CFURLRef url = CFURLCreateWithFileSystemPath
	(kCFAllocatorDefault, (CFStringRef)self, kCFURLPOSIXPathStyle, NO);
	if (url != NULL)
	{
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
		{
			Boolean targetIsFolder, wasAliased;
			OSErr err = FSResolveAliasFileWithMountFlags(
														 &fsRef, false, &targetIsFolder, &wasAliased, kResolveAliasFileNoUI);
			if ((err == noErr) && wasAliased)
			{
				CFURLRef resolvedUrl = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
				if (resolvedUrl != NULL)
				{
					resolvedPath =
					[(id)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle)
					 autorelease];
					CFRelease(resolvedUrl);
				}
			}
		}
		CFRelease(url);
	}
	
	return resolvedPath;
}

- (NSString *)stringByIterativelyResolvingSymlinkOrAlias
{
    NSString *path = self;
    NSString *aliasTarget = nil;
    struct stat fileInfo;
    
    // Use lstat to determine if the file is a directory or symlink
    if (lstat([[NSFileManager defaultManager]
			   fileSystemRepresentationWithPath:path], &fileInfo) < 0)
    {
        return nil;
    }
    
    // While the file is a symlink or resolves as an alias, keep iterating.
    while (S_ISLNK(fileInfo.st_mode) ||
		   (!S_ISDIR(fileInfo.st_mode) &&
            (aliasTarget = [path stringByConditionallyResolvingAlias]) != nil))
    {
        if (S_ISLNK(fileInfo.st_mode))
        {
            // Resolve the symlink component in the path
            NSString *symlinkPath = [path stringByConditionallyResolvingSymlink];
            if (!symlinkPath)
            {
                return nil;
            }
            path = symlinkPath;
        }
        else
        {
            // Or use the resolved alias result
            path = aliasTarget;
        }
		
        // Use lstat again to prepare for the next iteration
        if (lstat([[NSFileManager defaultManager]
				   fileSystemRepresentationWithPath:path], &fileInfo) < 0)
        {
            path = nil;
            continue;
        }
    }
    
    return path;
}

-(NSString*)resolvedPathString {
	NSString* path = [self stringByExpandingTildeInPath];
	
	// Break into components.
	NSArray *pathComponents = [path pathComponents];
	
	// First component ("/") needs no resolution; we only need to handle subsequent components.
	NSString *resolvedPath = [pathComponents objectAtIndex:0];
	pathComponents = [pathComponents subarrayWithRange:NSMakeRange(1, [pathComponents count] - 1)];
	
	// Process all remaining components.
	for (NSString *component in pathComponents)
	{
		resolvedPath = [resolvedPath stringByAppendingPathComponent:component];
		resolvedPath = [resolvedPath stringByIterativelyResolvingSymlinkOrAlias];
		if (!resolvedPath) {
			return nil;
		}
	}
	
	return resolvedPath;
}

@end

@implementation NSAttributedString (N2)

-(NSRange)range {
	return NSMakeRange(0, self.length);
}

@end
