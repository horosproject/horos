/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

 

 
 ---------------------------------------------------------------------------
 
 This file is part of the Horos Project.
 
 Current contributors to the project include Alex Bettarini and Danny Weissman.
 
 Horos is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation,  version 3 of the License.
 
 Horos is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Horos.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "JPEGExif.h"

@implementation JPEGExif

+ (void) addExif:(NSURL*) url properties:(NSDictionary*) exifDict format: (NSString*) format;
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if (source)
    {
		
		NSString *type = nil;
		
		if( [format isEqualToString:@"tiff"]) type = @"public.tiff";
		if( [format isEqualToString:@"jpeg"]) type = @"public.jpeg";
		
		CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef) url, (CFStringRef) type, 1, nil);
		if ( dest)
		{
			NSMutableDictionary *newProps = [NSMutableDictionary dictionary];

			[newProps setObject: exifDict forKey: (NSString*) kCGImagePropertyExifDictionary];
			CGImageDestinationAddImageFromSource(dest, source, 0, (CFDictionaryRef) newProps);
			
			CFRelease( dest);
		}
		
		CFRelease( source);
	}
}

@end
