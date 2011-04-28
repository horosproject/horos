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
#include <libkern/OSAtomic.h>

@implementation WADODownload

@synthesize _abortAssociation;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	
	if( [httpResponse statusCode] >= 300)
	{
		NSLog( @"***** WADO http status code error: %d", [httpResponse statusCode]);
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
		
		[connection release];
		OSAtomicDecrement32Barrier( &WADOThreads);
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//We dont want to store the images in the cache! Caches/com.rossetantoine.osirix/Cache.db
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if( connection)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString *path = [[BrowserController currentBrowser] INCOMINGPATH];
		
		NSString *key = [NSString stringWithFormat:@"%ld", connection];
		NSMutableData *d = [WADODownloadDictionary objectForKey: key];
		[d writeToFile: [path stringByAppendingPathComponent: [NSString stringWithFormat:@"WADO-%d-%ld.dcm", WADOThreads, self]] atomically: YES];
		[d setLength: 0]; // Free the memory immediately
		[WADODownloadDictionary removeObjectForKey: key];
		
		[connection release];
		
		OSAtomicDecrement32Barrier( &WADOThreads);
		
		[pool release];
	}
}

- (void) WADODownload: (NSArray*) urlToDownload
{
	if( [urlToDownload count])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSLog( @"------ WADO downloading : %d files", [urlToDownload count]);
		
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
			
			NSURLConnection *downloadConnection = [[NSURLConnection connectionWithRequest: [NSURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: timeout] delegate: self] retain];
			
			[WADODownloadDictionary setObject: [NSMutableData data] forKey: [NSString stringWithFormat:@"%ld", downloadConnection]];
			
			[downloadConnection start];
			
			[connectionsArray addObject: downloadConnection];
			
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
			NSLog( @"------ WADO downloading : %d files - finished", [urlToDownload count]);
	}	
}


@end
