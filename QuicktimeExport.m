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

#import "QuicktimeExport.h"
#import "Wait.h"
#import "WaitRendering.h"
#import "BrowserController.h"
#import "DicomDatabase.h"

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@implementation QuicktimeExport

- (id) initWithSelector:(id) o :(SEL) s :(long) f
{
	self = [super init];
	
	[NSBundle loadNibNamed:@"QuicktimeExport" owner:self];
	
	object = o;
	selector = s;
	numberOfFrames = f;
	
	return self;
}

- (NSArray *) availableComponents
{
    NSMutableArray *compressors = [NSMutableArray array];
    
    [compressors addObject: [NSDictionary dictionaryWithObjectsAndKeys: AVVideoCodecJPEG, @"videoCodec", @"JPEG Quicktime Movie", @"name", @"mov", @"extension", nil]];
    [compressors addObject: [NSDictionary dictionaryWithObjectsAndKeys: AVVideoCodecH264, @"videoCodec", @"H264 Movie", @"name", @"mp4", @"extension", nil]];
    
    return compressors;
}

- (IBAction) changeExportType:(id) sender
{
	if( [exportTypes count])
	{
		NSInteger indexOfSelectedItem = [type indexOfSelectedItem];
        
        [panel setRequiredFileType: [[exportTypes objectAtIndex: indexOfSelectedItem] valueForKey:@"extension"]];
        
		[[NSUserDefaults standardUserDefaults] setObject: [[exportTypes objectAtIndex: indexOfSelectedItem] valueForKey:@"videoCodec"] forKey:@"selectedMenuAVFoundationExport"];
	}
}

- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name
{
    return [self createMovieQTKit:openIt :produceFiles :name :0];
}

+ (CVPixelBufferRef) CVPixelBufferFromNSImage:(NSImage *)image
{
    CVPixelBufferRef buffer = NULL;
    
    // config
    size_t width = [image size].width;
    size_t height = [image size].height;
    size_t bitsPerComponent = 8;
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGBitmapInfo bi = kCGImageAlphaNoneSkipFirst;
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    
    // create pixel buffer
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, k32ARGBPixelFormat, (CFDictionaryRef)d, &buffer);
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *rasterData = CVPixelBufferGetBaseAddress(buffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    // context to draw in, set to pixel buffer's address
    CGContextRef ctxt = CGBitmapContextCreate(rasterData, width, height, bitsPerComponent, bytesPerRow, cs, bi);
    if(ctxt == NULL)
    {
        NSLog(@"could not create context");
        return NULL;
    }
    
    // draw
    NSGraphicsContext *nsctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsctxt];
    [image compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
    [NSGraphicsContext restoreGraphicsState];
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    CFRelease(ctxt);
    
    return buffer;
}

- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name :(NSInteger)fps
{
    if (fps > 0)
        [[NSUserDefaults standardUserDefaults] setInteger:fps forKey:@"quicktimeExportRateValue"];

	NSString *fileName;
	long result;

	exportTypes = [self availableComponents];
	
	panel = [NSSavePanel savePanel];
	
    [[NSFileManager defaultManager] createDirectoryAtPath: [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingFormat:@"/TEMP.noindex/"]  withIntermediateDirectories: YES attributes: nil error: nil];
    
	if( produceFiles)
	{
		result = NSFileHandlingPanelOKButton;
		
		[[NSFileManager defaultManager] removeFileAtPath: [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"IPHOTO"] handler: nil];
		[[NSFileManager defaultManager] createDirectoryAtPath: [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"IPHOTO"] withIntermediateDirectories: YES attributes: nil error: nil];
		
		fileName = [[[[BrowserController currentBrowser] database] tempDirPath] stringByAppendingPathComponent:@"OsiriXMovie.mov"];
	}
	else
	{
		[panel setCanSelectHiddenExtension: YES];
		[panel setAccessoryView: view];
		[type removeAllItems];
		
		if( [exportTypes count])
			[type addItemsWithTitles: [exportTypes valueForKey: @"name"]];
		
        int index = 0;
        
        for( NSDictionary *d in exportTypes)
        {
            if( [[d objectForKey: @"videoCodec"] isEqualToString: [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedMenuAVFoundationExport"]])
                index = [exportTypes indexOfObject: d];
        }
        
		[type selectItemAtIndex: index];
		[self changeExportType: self];
		
		result = [panel runModalForDirectory:nil file:name];
		
		fileName = [panel filename];
	}
	
	if( result == NSFileHandlingPanelOKButton)
    {
        CMTimeValue timeValue = 600 / [[NSUserDefaults standardUserDefaults] integerForKey:@"quicktimeExportRateValue"];
        CMTime frameDuration = CMTimeMake( timeValue, 600);
        
        NSError *error = nil;
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath: fileName] fileType: AVFileTypeQuickTimeMovie error:&error];
        if (!error)
        {
            NSImage	*firstImage = [object performSelector: selector withObject: [NSNumber numberWithLong: 0] withObject:[NSNumber numberWithLong: numberOfFrames]]; 
            
            // Define video settings to be passed to the AVAssetWriterInput instance
            
            NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedMenuAVFoundationExport"];
            
            NSDictionary *videoSettings = nil;
            
            if( [c isEqualToString: AVVideoCodecH264])
            {
                double bitsPerSecond = firstImage.size.width * firstImage.size.height * fps * 4; //Maximum bit rate for best quality
                
                videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                           c, AVVideoCodecKey, 
                                           [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithDouble: bitsPerSecond], AVVideoAverageBitRateKey,
                                            [NSNumber numberWithInteger: 1], AVVideoMaxKeyFrameIntervalKey,
                                            nil], AVVideoCompressionPropertiesKey,
                                           [NSNumber numberWithInt: firstImage.size.width], AVVideoWidthKey, 
                                           [NSNumber numberWithInt: firstImage.size.height], AVVideoHeightKey, nil];
            }
            else if( [c isEqualToString: AVVideoCodecJPEG])
            {
                videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                 c, AVVideoCodecKey,
                                 [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat: 0.9], AVVideoQualityKey, nil] ,AVVideoCompressionPropertiesKey,
                                 [NSNumber numberWithInt: firstImage.size.width], AVVideoWidthKey, 
                                 [NSNumber numberWithInt: firstImage.size.height], AVVideoHeightKey, nil];
            }
            
            // Instanciate the AVAssetWriterInput
            AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
            // Instanciate the AVAssetWriterInputPixelBufferAdaptor to be connected to the writer input
            AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
            // Add the writer input to the writer and begin writing
            [writer addInput:writerInput];
            [writer startWriting];
            
            BOOL aborted = NO;
            CMTime nextPresentationTimeStamp;
            
            nextPresentationTimeStamp = kCMTimeZero;
            
            [writer startSessionAtSourceTime:nextPresentationTimeStamp];
            
            Wait *wait = [[[Wait alloc] initWithString: NSLocalizedString( @"Movie Export", nil)] autorelease];
            [wait showWindow:self];
            [wait setCancel:YES];
            [[wait progress] setMaxValue: numberOfFrames];
            
            for( int curSample = 0; curSample < numberOfFrames; curSample++)
            {
                NSAutoreleasePool *pool = [NSAutoreleasePool new];
                
                CVPixelBufferRef buffer = nil;
                
                if( curSample < numberOfFrames)
                {
                    NSDisableScreenUpdates();
                    NSImage	*im = [object performSelector: selector withObject: [NSNumber numberWithLong: curSample] withObject:[NSNumber numberWithLong: numberOfFrames]];    
                    
                    buffer = [QuicktimeExport CVPixelBufferFromNSImage: im];
                    NSEnableScreenUpdates();
                }
                
                [pool release];
                
                if( buffer)
                {
                    CVPixelBufferLockBaseAddress(buffer, 0);
                    while( ![writerInput isReadyForMoreMediaData])
                        [NSThread sleepForTimeInterval: 0.1];
                    [pixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:nextPresentationTimeStamp];
                    CVPixelBufferUnlockBaseAddress(buffer, 0);
                    CVPixelBufferRelease(buffer);
                    buffer = nil;
                    
                    nextPresentationTimeStamp = CMTimeAdd(nextPresentationTimeStamp, frameDuration);
                    
                    CVPixelBufferRelease(buffer);                    
                    
                    [wait incrementBy: 1];
                    if( [wait aborted])
                    {
                        curSample = numberOfFrames;
                        aborted = YES;
                    }
                }
                else
                {
                    curSample = numberOfFrames;
                    break;
                }
            }
            [writerInput markAsFinished];
            [writer finishWriting];
            
            [object performSelector: selector withObject: [NSNumber numberWithLong: 0] withObject:[NSNumber numberWithLong: numberOfFrames]];
            
            [wait close];
            
            if( openIt && aborted == NO)
            {
                NSWorkspace *ws = [NSWorkspace sharedWorkspace];
                [ws openFile:fileName];
            }
            
            if( aborted == NO)
                return fileName;
        }
    }
	
	return nil;
}

@end
