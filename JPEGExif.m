//
//  JPEGExif.m
//  OsiriX
//
//  Created by Antoine Rosset on 25.06.07.
//  Copyright 2007 OsiriX. All rights reserved.
//

#import "JPEGExif.h"

@implementation JPEGExif

+ (void) addExif:(NSURL*) url
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if (source)
    {
        // get image properties (height, width, depth, metadata etc.) for display
        NSDictionary* props = (NSDictionary*) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
		
		NSLog( [props description]);
		
		NSURL *newUrl = [NSURL fileURLWithPath: [[url path] stringByAppendingString:@"test.jpeg"]];
		
		// Create an image destination writing to `url'
		CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef) newUrl, (CFStringRef)@"public.jpeg", 1, nil);
		if ( dest)
		{
			// Set the image in the image destination to be `image' with
			// optional properties specified in saved properties dict.
			
			// ********** CGImageProperties.h
			//kCGImagePropertyExifDictionary
			//kCGImagePropertyTIFFDateTime
			//kCGImagePropertyExifDateTimeOriginal
			
			NSMutableDictionary *newProps = [NSMutableDictionary dictionaryWithDictionary: props];
			
//			NSMutableDictionary *
//			
//			[newProps setValue:@"hello" forKey:@"testalpha"];
			
			CGImageDestinationAddImageFromSource(dest, source, 0, (CFDictionaryRef) newProps);
			
			BOOL status = CGImageDestinationFinalize(dest);
			
			CFRelease( dest);
		}
		
		CFRelease( source);
	}
}

@end
