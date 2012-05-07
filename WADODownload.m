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

#import "WADODownload.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#include <libkern/OSAtomic.h>

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation WADODownload

@synthesize _abortAssociation, showErrorMessage;

- (void) errorMessage:(NSArray*) msg
{
	if( showErrorMessage)
	{
		NSString *alertSuppress = @"hideListenerError";
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
			NSRunCriticalAlertPanel( [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2], nil, nil) ;
		else
			NSLog( @"*** listener error (not displayed - hideListenerError): %@ %@ %@", [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2]);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	
	if( [httpResponse statusCode] >= 300)
	{
		NSLog( @"***** WADO http status code error: %d", (int) [httpResponse statusCode]);
		NSLog( @"***** WADO URL : %@", connection);
		
		if( firstWadoErrorDisplayed == NO)
		{
			firstWadoErrorDisplayed = YES;
			[self performSelectorOnMainThread :@selector(errorMessage:) withObject: [NSArray arrayWithObjects: NSLocalizedString(@"WADO Retrieve Failed", nil), [NSString stringWithFormat: @"WADO http status code error: %d", [httpResponse statusCode]], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
		}
		
		[WADODownloadDictionary removeObjectForKey: [NSString stringWithFormat:@"%ld", connection]];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if( connection)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSMutableData *d = [WADODownloadDictionary objectForKey: [NSString stringWithFormat:@"%ld", connection]];
		[d appendData: data];
		
		[pool release];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if( connection)
	{
		[WADODownloadDictionary removeObjectForKey: [NSString stringWithFormat:@"%ld", connection]];
		
		NSLog(@"***** WADO Retrieve error: %@", error);
		
		if( firstWadoErrorDisplayed == NO)
		{
			firstWadoErrorDisplayed = YES;
			[self performSelectorOnMainThread :@selector(errorMessage:) withObject: [NSArray arrayWithObjects: NSLocalizedString(@"WADO Retrieve Failed", nil), [NSString stringWithFormat: @"%@", [error localizedDescription]], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
		}
		
		OSAtomicDecrement32Barrier( &WADOThreads);
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//We dont want to store the images in the cache! Caches/com.rossetantoine.osirix/Cache.db
	return nil;
}

- (id) init
{
	self = [super init];
	
	showErrorMessage = YES;
	
	return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if( connection)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
		NSString *path = [[DicomDatabase defaultDatabase] incomingDirPath];
        
		NSString *key = [NSString stringWithFormat:@"%ld", connection];
		NSMutableData *d = [WADODownloadDictionary objectForKey: key];
		
		NSString *extension = @"dcm";
		
		if( [d length] > 2)
		{
			if( [[NSString stringWithCString: [d bytes] length: 2] isEqualToString: @"PK"])
				extension = @"osirixzip";
            
            NSString *filename = [[NSString stringWithFormat:@".WADO-%d-%ld", WADOThreads, self] stringByAppendingPathExtension: extension];
        
            [d writeToFile: [path stringByAppendingPathComponent: filename] atomically: YES];
            
            // To remove the '.'
            [[NSFileManager defaultManager] moveItemAtPath: [path stringByAppendingPathComponent: filename] toPath: [path stringByAppendingPathComponent: [filename substringFromIndex: 1]] error: nil];
        }
        
		[d setLength: 0]; // Free the memory immediately
		[WADODownloadDictionary removeObjectForKey: key];
		
		OSAtomicDecrement32Barrier( &WADOThreads);
		
		[pool release];
	}
}

- (void) WADODownload: (NSArray*) urlToDownload
{
    if( [urlToDownload count])
        urlToDownload = [[NSSet setWithArray: urlToDownload] allObjects]; // UNIQUE OBJECTS !
	
	if( [urlToDownload count])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSLog( @"------ WADO downloading : %d files", (int) [urlToDownload count]);
		
		firstWadoErrorDisplayed = NO;
		
		if( showErrorMessage == NO)
			firstWadoErrorDisplayed = YES; // dont show errors
		
		WADODownloadDictionary = [NSMutableDictionary dictionary];
		
		int WADOMaximumConcurrentDownloads = [[NSUserDefaults standardUserDefaults] integerForKey: @"WADOMaximumConcurrentDownloads"];
		if( WADOMaximumConcurrentDownloads < 10)
			WADOMaximumConcurrentDownloads = 10;
		
		float timeout = [[NSUserDefaults standardUserDefaults] floatForKey: @"WADOTimeout"];
		if( timeout < 240) timeout = 240;
		
		NSLog( @"------ WADO parameters: timeout:%2.2f [secs] / WADOMaximumConcurrentDownloads:%d [URLRequests]", timeout, WADOMaximumConcurrentDownloads);
		
		WADOThreads = [urlToDownload count];
		
		NSMutableArray *connectionsArray = [NSMutableArray array];
		
		NSTimeInterval retrieveStartingDate = [NSDate timeIntervalSinceReferenceDate];
		
		BOOL aborted = NO;
		for( NSURL *url in urlToDownload)
		{
			while( [WADODownloadDictionary count] > WADOMaximumConcurrentDownloads) //Dont download more than XXX images at the same time
			{
				[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
				
				if( _abortAssociation || [NSThread currentThread].isCancelled || [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] || [NSDate timeIntervalSinceReferenceDate] - retrieveStartingDate > timeout)
				{
					aborted = YES;
					break;
				}
			}
			retrieveStartingDate = [NSDate timeIntervalSinceReferenceDate];
			
            @try
            {
                if( [[url scheme] isEqualToString: @"https"])
                    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
            }
            @catch (NSException *e)
            {
                NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
            }
            
			NSURLConnection *downloadConnection = [NSURLConnection connectionWithRequest: [NSURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: timeout] delegate: self];
			
            if( downloadConnection)
            {
                [WADODownloadDictionary setObject: [NSMutableData data] forKey: [NSString stringWithFormat:@"%ld", downloadConnection]];
                [downloadConnection start];
                [connectionsArray addObject: downloadConnection];
			}
            
			if( downloadConnection == nil)
				OSAtomicDecrement32Barrier( &WADOThreads);
			
			if( _abortAssociation || [NSThread currentThread].isCancelled || [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"] || [NSDate timeIntervalSinceReferenceDate] - retrieveStartingDate > timeout)
			{
				aborted = YES;
				break;
			}
		}
		
		if( aborted == NO)
		{
			while( WADOThreads > 0)
			{
				[[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
				
				if( _abortAssociation || [NSThread currentThread].isCancelled || [[NSFileManager defaultManager] fileExistsAtPath: @"/tmp/kill_all_storescu"]  || [NSDate timeIntervalSinceReferenceDate] - retrieveStartingDate > timeout)
				{
					aborted = YES;
					break;
				}
			}
			
			if( aborted == NO && [[WADODownloadDictionary allKeys] count] > 0)
				NSLog( @"**** [[WADODownloadDictionary allKeys] count] > 0");
		}
		
		if( aborted)
		{
			for( NSURLConnection *connection in connectionsArray)
				[connection cancel];
		}
		
		[WADODownloadDictionary removeAllObjects];
		WADODownloadDictionary = nil;
		
		[pool release];
		
		if( aborted)
			NSLog( @"------ WADO downloading ABORTED");
		else
			NSLog( @"------ WADO downloading : %d files - finished", (int) [urlToDownload count]);
	}	
}


@end
