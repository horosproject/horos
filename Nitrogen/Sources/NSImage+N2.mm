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

#import "NSImage+N2.h"
#include <algorithm>
#import <Accelerate/Accelerate.h>
#import "N2Operators.h"
#import "NSColor+N2.h"
#import "N2Debug.h"
#import <QuartzCore/QuartzCore.h>

@implementation N2Image
@synthesize inchSize = _inchSize, portion = _portion;

-(id)initWithContentsOfFile:(NSString*)path {
	self = [super initWithContentsOfFile:path];
	NSSize size = [self size];
	_inchSize = NSMakeSize(size.width/72, size.height/72);
	_portion.size = NSMakeSize(1,1);
	return self;
}

-(id)initWithSize:(NSSize)size inches:(NSSize)inches {
	self = [super initWithSize:size];
	_inchSize = inches;
	return self;
}

-(id)initWithSize:(NSSize)size inches:(NSSize)inches portion:(NSRect)portion {
	self = [self initWithSize:size inches:inches];
	_portion = portion;
	return self;
}

-(NSSize)originalInchSize {
	return _inchSize/_portion.size;
}

-(NSPoint)convertPointFromPageInches:(NSPoint)p {
	return (p-_portion.origin*[self originalInchSize])*[self resolution];
}

-(void)setSize:(NSSize)size {
	NSSize oldSize = [self size];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (![self scalesWhenResized])
#pragma clang diagnostic pop
		_inchSize = NSMakeSize(_inchSize.width/oldSize.width*size.width, _inchSize.height/oldSize.height*size.height);
	[super setSize:size];
}

-(N2Image*)crop:(NSRect)cropRect {
	NSSize size = [self size];
	
	NSRect portion;
	portion.size = _portion.size*(cropRect.size/size);// NSMakeSize(_portion.size.width*(cropRect.size.width/size.width), _portion.size.height*(cropRect.size.height/size.height));
	portion.origin = _portion.origin+_portion.size*(cropRect.origin/size);//, _portion.origin.y+_portion.size.height*(cropRect.origin.y/size.height));
	
	N2Image* croppedImage = [[N2Image alloc] initWithSize:cropRect.size inches:NSMakeSize(_inchSize.width/size.width*cropRect.size.width, _inchSize.height/size.height*cropRect.size.height) portion:portion];
	
	[croppedImage lockFocus];
    [self drawAtPoint:NSZeroPoint fromRect:cropRect operation:NSCompositeSourceOver fraction:0];
    [croppedImage unlockFocus];
	
	return [croppedImage autorelease];
}

-(float)resolution {
	NSSize size = [self size];
	return (size.width+size.height)/(_inchSize.width+_inchSize.height);
}

@end


@implementation NSImage (N2)

-(NSImage*)shadowImage
{
	NSImage* dark = [[NSImage alloc] initWithSize:[self size]];
	[dark lockFocus];
	[self drawInRect: NSMakeRect( 0, 0, self.size.width, self.size.height) fromRect: NSMakeRect( 0, 0, self.size.width, self.size.height) operation: NSCompositeSourceOver fraction: 1.0];
    [[NSColor colorWithCalibratedWhite: 0 alpha: 0.5] set];
    NSRectFillUsingOperation( NSMakeRect( 0, 0, self.size.width, self.size.height), NSCompositeSourceAtop);
	[dark unlockFocus];
    
	return [dark autorelease];
}

- (void)flipImageHorizontally {
	// bitmap init
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
	// flip
	vImage_Buffer src, dest;
	src.height = dest.height = bitmap.pixelsHigh;
	src.width = dest.width = bitmap.pixelsWide;
	src.rowBytes = dest.rowBytes = [bitmap bytesPerRow];
	src.data = dest.data = [bitmap bitmapData];
	vImageHorizontalReflect_ARGB8888(&src, &dest, 0L);
	// draw
	[self lockFocus];
	[bitmap draw];
	[self unlockFocus];
	// release
	[bitmap release];
}

-(NSRect)boundingBoxSkippingColor:(NSColor*)color inRect:(NSRect)box {
	if (box.size.width < 0) {
		box.origin.x += box.size.width;
		box.size.width = -box.size.width;
	}
	if (box.size.height < 0) {
		box.origin.y += box.size.height;
		box.size.height = -box.size.height;
	}
	
	NSSize size = [self size];
	
	if (box.origin.x < 0) {
		box.size.width += box.origin.x;
		box.origin.x = 0;
	}
	if (box.origin.y < 0) {
		box.size.height += box.origin.y;
		box.origin.y = 0;
	}
	if (box.origin.x+box.size.width > size.width)
		box.size.width = size.width-box.origin.x;
	if (box.origin.y+box.size.height > size.height)
		box.size.height = size.height-box.origin.y;
	
//	if (![self isFlipped])
		box.origin.y = size.height-box.origin.y-box.size.height;
	
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
	uint8* data = [bitmap bitmapData];
	
	if ([color colorSpaceName] != NSCalibratedRGBColorSpace)
		color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSInteger componentsCount = [color numberOfComponents];
	CGFloat components[componentsCount];
	[color getComponents:components];
	
	const size_t rowBytes = [bitmap bytesPerRow], pixelBytes = [bitmap bitsPerPixel]/8;
#define P(x,y) (y*rowBytes+x*pixelBytes)

	int x, y;
#define Match(x,y) ( (data[P(x,y)] == data[P(x,y)+3]*components[0]) && (data[P(x,y)+1] == data[P(x,y)+3]*components[1]) && (data[P(x,y)+2] == data[P(x,y)+3]*components[2]) )
	
	// change origin.x
	for (x = box.origin.x; x < box.origin.x+box.size.width; ++x)
		for (y = box.origin.y; y <= box.origin.y+box.size.height; ++y)
			if (!Match(x,y))
				goto end_origin_x;
end_origin_x:
	if (x < box.origin.x+box.size.width) {
		box.size.width -= x-box.origin.x;
		box.origin.x = x;
	}
	
	// change origin.y
	for (y = box.origin.y; y < box.origin.y+box.size.height; ++y)
		for (x = box.origin.x; x <= box.origin.x+box.size.width; ++x)
			if (!Match(x,y))
				goto end_origin_y;
end_origin_y:
	if (y < box.origin.y+box.size.height) {
		box.size.height -= y-box.origin.y;
		box.origin.y = y;
	}
	
	// change size.width
	for (x = box.origin.x+box.size.width-1; x >= box.origin.x; --x)
		for (y = box.origin.y; y <= box.origin.y+box.size.height; ++y)
			if (!Match(x,y))
				goto end_size_x;
end_size_x:
	if (x >= box.origin.x)
		box.size.width = x-box.origin.x+1;
	
	// change size.height
	for (y = box.origin.y+box.size.height-1; y >= box.origin.y; --y)
		for (x = box.origin.x; x <= box.origin.x+box.size.width; ++x)
			if (!Match(x,y))
				goto end_size_y;
end_size_y:
	if (y >= box.origin.y)
		box.size.height = y-box.origin.y+1;
	
	[bitmap release];
	
	//if (![self isFlipped])
		box.origin.y = size.height-box.origin.y-box.size.height;
	
	return box;
	
#undef Match
#undef P
}

-(NSRect)boundingBoxSkippingColor:(NSColor*)color {
	NSSize imageSize = [self size];
	return [self boundingBoxSkippingColor:color inRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)];
}

-(NSImage*)imageWithHue:(CGFloat)hue {
	NSImageRep *rep = [NSCIImageRep imageRepWithCIImage: [[CIFilter filterWithName:@"CIHueAdjust" keysAndValues:@"inputAngle", [NSNumber numberWithFloat: hue*2*M_PI] , @"inputImage", [CIImage imageWithData:[self TIFFRepresentation]], nil] valueForKey:@"outputImage"]];
	NSImage *image = [[NSImage alloc] initWithSize:[rep size]];
	[image addRepresentation:rep];
	return [image autorelease];
}

-(NSImage*)imageInverted {
    CIFilter *invert = [CIFilter filterWithName: @"CIColorMatrix"];
    
    [invert setDefaults];
    [invert setValue: [CIImage imageWithData:[self TIFFRepresentation]] forKey: kCIInputImageKey];
    [invert setValue: [CIVector vectorWithX: -1 Y:0 Z:0] forKey: @"inputRVector"];
    [invert setValue: [CIVector vectorWithX: 0 Y:-1 Z:0] forKey: @"inputGVector"];
    [invert setValue: [CIVector vectorWithX: 0 Y:0 Z:-1] forKey: @"inputBVector"];
    [invert setValue: [CIVector vectorWithX: 0.9 Y:0.9 Z:0.9] forKey:@"inputBiasVector"];
    
	NSImageRep *rep = [NSCIImageRep imageRepWithCIImage: [invert valueForKey:@"outputImage"]];
	NSImage *image = [[NSImage alloc] initWithSize:[rep size]];
	[image addRepresentation:rep];
	return [image autorelease];
}

-(NSSize)sizeByScalingProportionallyToSize:(NSSize)targetSize {
    return N2ProportionallyScaleSize(self.size, targetSize);
}

-(NSSize)sizeByScalingDownProportionallyToSize:(NSSize)targetSize {
    NSSize imageSize = self.size;
	NSSize outSize = [self sizeByScalingProportionallyToSize:targetSize];
    return outSize.width < imageSize.width? outSize : imageSize;
}

- (NSImage*)imageByScalingProportionallyUsingNSImage:(float)ratio
{
    return [self imageByScalingProportionallyToSizeUsingNSImage: NSMakeSize( self.size.width*ratio, self.size.height*ratio)];
}

- (NSImage*)imageByScalingProportionallyToSizeUsingNSImage:(NSSize)targetSize
{
    @try {
        NSImage *newImage = [[[NSImage alloc] initWithSize: targetSize] autorelease];

        if( [newImage size].width > 0 && [newImage size].height > 0)
        {
            [newImage lockFocus];

            [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
            
            NSPoint thumbnailPoint = NSZeroPoint;
            
            NSSize imageSize = [self size];
            float width  = imageSize.width;
            float height = imageSize.height;
            float targetWidth  = targetSize.width;
            float targetHeight = targetSize.height;
            float scaledWidth  = targetWidth;
            float scaledHeight = targetHeight;
            
            if( NSEqualSizes( imageSize, targetSize) == NO)
            {
                float widthFactor  = targetWidth / width;
                float heightFactor = targetHeight / height;
                float scaleFactor  = 0.0;
                
                
                if ( widthFactor < heightFactor )
                    scaleFactor = widthFactor;
                else
                    scaleFactor = heightFactor;
                
                scaledWidth  = width  * scaleFactor;
                scaledHeight = height * scaleFactor;
                
                if ( widthFactor < heightFactor )
                    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
                
                else if ( widthFactor > heightFactor )
                    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
            
            NSRect thumbnailRect;
            thumbnailRect.origin = thumbnailPoint;
            thumbnailRect.size.width = scaledWidth;
            thumbnailRect.size.height = scaledHeight;

            [self drawInRect: thumbnailRect
                           fromRect: NSZeroRect
                          operation: NSCompositeCopy
                           fraction: 1.0];

            [newImage unlockFocus];
            
            return newImage;
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    return self;
}

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSImage* sourceImage = self;
	NSImage* newImage = nil;
	
	@synchronized( [NSImage class])
	{
		if( [sourceImage isValid])
		{
			NSSize imageSize = [sourceImage size];
			float width  = imageSize.width;
			float height = imageSize.height;
			
			if( width <= 0 || height <= 0)
				NSLog( @"***** imageByScalingProportionallyToSize : width == 0 || height == 0");
			
			float targetWidth  = targetSize.width;
			float targetHeight = targetSize.height;
			
			if( targetWidth <= 0 || targetHeight <= 0)
				NSLog( @"***** imageByScalingProportionallyToSize : targetWidth == 0 || targetHeight == 0");
			
			float scaleFactor  = 0.0;

			
			NSPoint thumbnailPoint = NSZeroPoint;
			
			if( NSEqualSizes( imageSize, targetSize) == NO)
			{
                float scaledWidth  = targetWidth;
                float scaledHeight = targetHeight;
				float widthFactor  = targetWidth / width;
				float heightFactor = targetHeight / height;
				
				if ( widthFactor < heightFactor )
					scaleFactor = widthFactor;
				else
					scaleFactor = heightFactor;
				
				scaledWidth  = width  * scaleFactor;
				scaledHeight = height * scaleFactor;
				
				if ( widthFactor < heightFactor )
					thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
				
				else if ( widthFactor > heightFactor )
					thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
			
			//***** QuartzCore
			
			//if( thumbnailPoint.x < 1 && thumbnailPoint.y < 1)
			{
				NSSize size = [sourceImage size];
				
				[sourceImage lockFocus];
				
				NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0, 0, size.width, size.height)];
				CIImage *bitmap = [[CIImage alloc] initWithBitmapImageRep: rep];
				
				CIFilter *scaleTransformFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
				
				[scaleTransformFilter setDefaults];
				[scaleTransformFilter setValue: bitmap forKey:@"inputImage"];
				[scaleTransformFilter setValue:[NSNumber numberWithFloat: scaleFactor / [[NSScreen mainScreen] backingScaleFactor]] forKey:@"inputScale"];
				
				CIImage *outputCIImage = [scaleTransformFilter valueForKey:@"outputImage"];
				
				CGRect extent = [outputCIImage extent];
				if (CGRectIsInfinite(extent))
				{
					NSLog( @"****** imageByScalingProportionallyToSize : OUTPUT IMAGE HAS INFINITE EXTENT");
				}
				else
				{
					newImage = [[[NSImage alloc] initWithSize: targetSize] autorelease];
					
					if( [newImage size].width > 0 && [newImage size].height > 0)
					{
						[newImage lockFocus];
						
						[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
						
						NSRect thumbnailRect;
						thumbnailRect.origin = thumbnailPoint;
						thumbnailRect.size.width = extent.size.width;
						thumbnailRect.size.height = extent.size.height;
						
						[outputCIImage drawInRect: thumbnailRect
										 fromRect: NSMakeRect( extent.origin.x , extent.origin.y, extent.size.width, extent.size.height)
										operation: NSCompositeCopy
										 fraction: 1.0];
						
						[newImage unlockFocus];
					}
				}
				
				[sourceImage unlockFocus];
				
				[rep release];
				[bitmap release];
			}
			//		else
			//
			////		***** NSImage
			//		{
			//			newImage = [[[NSImage alloc] initWithSize: targetSize] autorelease];
			//			
			//			if( [newImage size].width > 0 && [newImage size].height > 0)
			//			{
			//				[newImage lockFocus];
			//				
			//				[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
			//				
			//				NSRect thumbnailRect;
			//				thumbnailRect.origin = thumbnailPoint;
			//				thumbnailRect.size.width = scaledWidth;
			//				thumbnailRect.size.height = scaledHeight;
			//				
			//				[sourceImage drawInRect: thumbnailRect
			//							   fromRect: NSZeroRect
			//							  operation: NSCompositeCopy
			//							   fraction: 1.0];
			//				
			//				[newImage unlockFocus];
			//			}
			//		}
		}
	}
	
	NSImage *returnImage = nil;
	
	if( newImage)
		returnImage = [[NSImage alloc] initWithData: [newImage TIFFRepresentation]];
	
	[pool release];
	
		
	return [returnImage autorelease];
}

@end
