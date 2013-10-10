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
#import "N2Debug.h"
#import "NSFileManager+N2.h"

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@implementation QuicktimeExport

- (id) initWithSelector:(id) o :(SEL) s :(long) f
{
	self = [super init];
	
	[NSBundle loadNibNamed:@"QuicktimeExport" owner:self];
	
	object = [o retain];
	selector = s;
	numberOfFrames = f;
	
	return self;
}

- (void) dealloc
{
    [object release];
    
    [super dealloc];
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
        NSLog(@"******** CVPixelBufferFromNSImage : could not create context");
        CGColorSpaceRelease(cs);
        return NULL;
    }
    
    // draw
    NSGraphicsContext *nsctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsctxt];
    [image drawAtPoint:NSMakePoint(0.0, 0.0) fromRect: NSZeroRect operation:NSCompositeCopy fraction: 1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    CFRelease(ctxt);
    CGColorSpaceRelease(cs);
    return buffer;
}

- (NSString*) createMovieQTKit:(BOOL) openIt :(BOOL) produceFiles :(NSString*) name :(NSInteger)fps
{
    if (fps <= 0)
        fps = [[NSUserDefaults standardUserDefaults] integerForKey: @"quicktimeExportRateValue"];
    if (fps <= 0)
        fps = 10;
    
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
    
    [[NSFileManager defaultManager] removeItemAtPath: fileName error: nil];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath: fileName])
        [[NSFileManager defaultManager] moveItemAtPathToTrash: fileName];
    
    @try
    {
        if( result == NSFileHandlingPanelOKButton)
        {
            CMTimeValue timeValue = 600 / [[NSUserDefaults standardUserDefaults] integerForKey:@"quicktimeExportRateValue"];
            CMTime frameDuration = CMTimeMake( timeValue, 600);
            
            NSError *error = nil;
            BOOL aborted = NO;
            
            AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath: fileName] fileType: AVFileTypeQuickTimeMovie error:&error];
            if (!error)
            {
                Wait *wait = [[[Wait alloc] initWithString: NSLocalizedString( @"Movie Export", nil)] autorelease];
                [wait showWindow:self];
                [wait setCancel:YES];
                [[wait progress] setMaxValue: numberOfFrames];
                
                AVAssetWriterInput *writerInput = nil;
                AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = nil;
                CMTime nextPresentationTimeStamp = kCMTimeZero;
                
                for( int curSample = 0; curSample < numberOfFrames; curSample++)
                {
                    NSAutoreleasePool *pool = [NSAutoreleasePool new];
                    
                    @try
                    {
                        CVPixelBufferRef buffer = nil;
                        
                        NSDisableScreenUpdates();
                        NSImage	*im = [object performSelector: selector withObject: [NSNumber numberWithLong: curSample] withObject:[NSNumber numberWithLong: numberOfFrames]];    
                        NSEnableScreenUpdates();
                        
                        if( im)
                        {
                            if( writerInput == nil)
                            {
                                // Define video settings to be passed to the AVAssetWriterInput instance
                                
                                NSString *c = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedMenuAVFoundationExport"];
                                
                                NSDictionary *videoSettings = nil;
                                
                                if( [c isEqualToString: AVVideoCodecH264])
                                {
                                    double bitsPerSecond = im.size.width * im.size.height * fps * 4; //Maximum bit rate for best quality
                                    
                                    if( bitsPerSecond > 0)
                                        videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     c, AVVideoCodecKey,
                                                     [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithDouble: bitsPerSecond], AVVideoAverageBitRateKey,
                                                      [NSNumber numberWithInteger: 1], AVVideoMaxKeyFrameIntervalKey,
                                                      nil], AVVideoCompressionPropertiesKey,
                                                     [NSNumber numberWithInt: im.size.width], AVVideoWidthKey,
                                                     [NSNumber numberWithInt: im.size.height], AVVideoHeightKey, nil];
                                    else
                                        N2LogStackTrace( @"********** bitsPerSecond == 0");
                                }
                                else if( [c isEqualToString: AVVideoCodecJPEG])
                                {
                                    videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     c, AVVideoCodecKey,
                                                     [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat: 0.9], AVVideoQualityKey, nil] ,AVVideoCompressionPropertiesKey,
                                                     [NSNumber numberWithInt: im.size.width], AVVideoWidthKey,
                                                     [NSNumber numberWithInt: im.size.height], AVVideoHeightKey, nil];
                                }
                                
                                if( videoSettings)
                                {
                                    writerInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings] retain];
                                    
                                    if( writerInput == nil)
                                        N2LogStackTrace( @"**** writerInput == nil : %@", videoSettings);
                                    
                                    pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil] retain];
                                    
                                    [writer addInput:writerInput];
                                    [writer startWriting];
                                    [writer startSessionAtSourceTime:nextPresentationTimeStamp];
                                }
                            }
                            
                            buffer = [QuicktimeExport CVPixelBufferFromNSImage: im];
                        }
                        
                        if( buffer)
                        {
                            CVPixelBufferLockBaseAddress(buffer, 0);
                            while( writerInput && [writerInput isReadyForMoreMediaData] == NO)
                                [NSThread sleepForTimeInterval: 0.1];
                            [pixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:nextPresentationTimeStamp];
                            CVPixelBufferUnlockBaseAddress(buffer, 0);
                            CVPixelBufferRelease(buffer);
                            buffer = nil;
                            
                            nextPresentationTimeStamp = CMTimeAdd(nextPresentationTimeStamp, frameDuration);
                            
                            CVPixelBufferRelease(buffer);
                        }
                        
                        [wait incrementBy: 1];
                        if( [wait aborted])
                        {
                            curSample = numberOfFrames;
                            aborted = YES;
                        }
                    }
                    @catch (NSException *e) {
                        N2LogExceptionWithStackTrace( e);
                    }
                    [pool release];
                }
                [writerInput markAsFinished];
                [writer finishWriting];
                
                [object performSelector: selector withObject: [NSNumber numberWithLong: 0] withObject:[NSNumber numberWithLong: numberOfFrames]];
                
                [wait close];
                
                [writerInput release];
                [pixelBufferAdaptor release];
                
                if( openIt && aborted == NO)
                {
                    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
                    [ws openFile:fileName];
                }
            }
            
            [writer release];
            
            if( aborted == NO)
                return fileName;
        }
    }
    @catch (NSException *e) {
        N2LogExceptionWithStackTrace(e);
    }
    
	return nil;
}

@end
