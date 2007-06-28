//
//  JPEGExif.m
//  OsiriX
//
//  Created by Antoine Rosset on 25.06.07.
//  Copyright 2007 OsiriX. All rights reserved.
//

#import "JPEGExif.h"

@implementation JPEGExif

+ (void) addExif:(NSURL*) url properties:(NSDictionary*) exifDict format: (NSString*) format
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if (source)
    {
        NSDictionary* props = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
		
		NSString *type = 0L;
		
		if( [format isEqualToString:@"tiff"]) type = @"public.tiff";
		if( [format isEqualToString:@"jpeg"]) type = @"public.jpeg";
		
		CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef) url, (CFStringRef) type, 1, nil);
		if ( dest)
		{
			NSMutableDictionary *newProps = [NSMutableDictionary dictionary];

			[newProps setObject: exifDict forKey: (NSString*) kCGImagePropertyExifDictionary];
			CGImageDestinationAddImageFromSource(dest, source, 0, (CFDictionaryRef) newProps);
			
			BOOL status = CGImageDestinationFinalize(dest);
			
			CFRelease( dest);
		}
		
		CFRelease( source);
	}
}

@end
