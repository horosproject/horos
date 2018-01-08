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

#import "WADODownload.h"
#import "BrowserController.h"
#import "DicomDatabase.h"
#import "NSThread+N2.h"
#include <libkern/OSAtomic.h>
#import "DicomFile.h"
#import "LogManager.h"
#import "N2Debug.h"
#import "NSString+N2.h"

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation WADODownload

@synthesize _abortAssociation, showErrorMessage, countOfSuccesses, WADOGrandTotal, WADOBaseTotal, baseStatus, receivedData, totalData;

+ (void) errorMessage:(NSArray*) msg
{
    NSString *alertSuppress = @"hideListenerError";
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: alertSuppress] == NO)
        NSRunCriticalAlertPanel( [msg objectAtIndex: 0], @"%@", [msg objectAtIndex: 2], nil, nil, [msg objectAtIndex: 1]) ;
    else
        NSLog( @"*** listener error (not displayed - hideListenerError): %@ %@ %@", [msg objectAtIndex: 0], [msg objectAtIndex: 1], [msg objectAtIndex: 2]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	
	if( [httpResponse statusCode] >= 300)
	{
		NSLog( @"***** WADO http status code error: %d", (int) [httpResponse statusCode]);
		NSLog( @"***** WADO URL : %@", response.URL);
		
		if( firstWadoErrorDisplayed == NO)
		{
			firstWadoErrorDisplayed = YES;
            if( showErrorMessage)
                [WADODownload performSelectorOnMainThread :@selector(errorMessage:) withObject: [NSArray arrayWithObjects: NSLocalizedString(@"WADO Retrieve Failed", nil), [NSString stringWithFormat: @"WADO http status code error: %d", (int) [httpResponse statusCode]], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
		}
		
		[WADODownloadDictionary removeObjectForKey: [NSString stringWithFormat:@"%ld", (long) connection]];
	}
    else
        totalData += [[httpResponse.allHeaderFields valueForKey: @"Content-Length"] longLongValue];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if( connection)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSMutableData *d = [[WADODownloadDictionary objectForKey: [NSString stringWithFormat:@"%ld", (long) connection]] objectForKey: @"data"];
		[d appendData: data];
		
        receivedData += data.length;
        
        if( WADOTotal == 1) // Only one file: display progress in bytes
        {
            if( totalData > 0)
                [[NSThread currentThread] setProgress: (double) receivedData / (double) totalData];
            
            if( firstReceivedTime == 0)
                firstReceivedTime = [NSDate timeIntervalSinceReferenceDate];
            
            if( [NSDate timeIntervalSinceReferenceDate] - lastStatusUpdate > 1 && [NSDate timeIntervalSinceReferenceDate] - firstReceivedTime > 2)
            {
                lastStatusUpdate = [NSDate timeIntervalSinceReferenceDate];
                [NSThread currentThread].status = [NSString stringWithFormat: @"%@ - %@/s", self.baseStatus, [NSString sizeString: (double) receivedData / ([NSDate timeIntervalSinceReferenceDate] - firstReceivedTime)]];
            }
        }
        
		[pool release];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if( connection)
	{
		[WADODownloadDictionary removeObjectForKey: [NSString stringWithFormat:@"%ld", (long) connection]];
		
		NSLog(@"***** WADO Retrieve error: %@", error);
		
		if( firstWadoErrorDisplayed == NO)
		{
			firstWadoErrorDisplayed = YES;
            
            if( showErrorMessage)
                [WADODownload performSelectorOnMainThread :@selector(errorMessage:) withObject: [NSArray arrayWithObjects: NSLocalizedString(@"WADO Retrieve Failed", nil), [NSString stringWithFormat: @"%@", [error localizedDescription]], NSLocalizedString(@"Continue", nil), nil] waitUntilDone:NO];
		}
		
		WADOThreads--;
        
        int error = [[logEntry valueForKey: @"logNumberError"] intValue];
        error++;
        [logEntry setValue:[NSNumber numberWithInt: error] forKey:@"logNumberError"];
	}
    else
        N2LogStackTrace( @"connection == nil");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	//We dont want to store the images in the cache! Caches/BUNDLE_IDENTIFIER/Cache.db
	return nil;
}

- (id) init
{
	self = [super init];
	
	showErrorMessage = YES;
	
    [[NSURLCache sharedURLCache] setDiskCapacity: 0];
    [[NSURLCache sharedURLCache] setMemoryCapacity: 0];
    
#ifdef NONETWORKFUNCTIONS
    return nil;
#endif

	return self;
}

- (void) dealloc
{
    self.baseStatus = nil;
    
    [WADODownloadDictionary release];
    WADODownloadDictionary = nil;
    
    [logEntry release];
    logEntry = nil;
    
    [super dealloc];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if( connection)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
		NSString *path = [[DicomDatabase activeLocalDatabase] incomingDirPath];
        
		NSString *key = [NSString stringWithFormat:@"%ld", (long) connection];
        
		NSMutableData *d = [[WADODownloadDictionary objectForKey: key] objectForKey: @"data"];
		
		NSString *extension = @"dcm";
		
		if( [d length] > 2)
		{
            countOfSuccesses++;
            
			if( [[[[NSString alloc] initWithBytes:d.bytes length:2 encoding:NSUTF8StringEncoding] autorelease] isEqualToString: @"PK"])
				extension = @"osirixzip";
            
            NSString *filename = [[NSString stringWithFormat:@".WADO-%d-%ld", WADOThreads, (long) self] stringByAppendingPathExtension: extension];
        
            [d writeToFile: [path stringByAppendingPathComponent: filename] atomically: YES];
                        
            if( WADOThreads == WADOTotal) // The first file !
            {
                [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
                
                @try
                {
                    if (!logEntry && [DicomFile isDICOMFile: [path stringByAppendingPathComponent: filename]])
                    {
                        DicomFile *dcmFile = [[DicomFile alloc] init: [path stringByAppendingPathComponent: filename]];
                        
                        @try
                        {
                            logEntry = [[NSMutableDictionary dictionary] retain];
                            
                            [logEntry setValue: [NSString stringWithFormat: @"%lf", [[NSDate date] timeIntervalSince1970]] forKey:@"logUID"];
                            [logEntry setValue: [NSDate date] forKey:@"logStartTime"];
                            [logEntry setValue: @"Receive" forKey:@"logType"];
                            [logEntry setValue: [[[WADODownloadDictionary objectForKey: key] objectForKey: @"url"] host] forKey:@"logCallingAET"];
                            
                            if ([dcmFile elementForKey: @"patientName"])
                                [logEntry setValue: [dcmFile elementForKey: @"patientName"] forKey: @"logPatientName"];
                            
                            if ([dcmFile elementForKey: @"studyDescription"])
                                [logEntry setValue:[dcmFile elementForKey: @"studyDescription"] forKey:@"logStudyDescription"];
                            
                            [logEntry setValue:[NSNumber numberWithInt: WADOTotal] forKey:@"logNumberTotal"];
                        }
                        @catch (NSException *e) {
                            N2LogException( e);
                        }
                        [dcmFile release];
                    }
                }
                @catch (NSException *exception) {
                    N2LogException( exception);
                }
            }
            
            [logEntry setValue:[NSNumber numberWithInt: 1 + WADOTotal - WADOThreads] forKey:@"logNumberReceived"];
            
            [logEntry setValue:[NSDate date] forKey:@"logEndTime"];
            [logEntry setValue:@"In Progress" forKey:@"logMessage"];
            
            [[LogManager currentLogManager] addLogLine: logEntry];
            
            if( WADOGrandTotal)
                [[NSThread currentThread] setProgress: (float) ((WADOTotal - WADOThreads) + WADOBaseTotal) / (float) WADOGrandTotal];
            else if( WADOTotal)
                [[NSThread currentThread] setProgress: 1.0 - (float) WADOThreads / (float) WADOTotal];
            
            // To remove the '.'
            [[NSFileManager defaultManager] moveItemAtPath: [path stringByAppendingPathComponent: filename] toPath: [path stringByAppendingPathComponent: [filename substringFromIndex: 1]] error: nil];
        }
        
		[d setLength: 0]; // Free the memory immediately
		[WADODownloadDictionary removeObjectForKey: key];
		
		WADOThreads--;
		
		[pool release];
	}
    else
        N2LogStackTrace( @"connection == nil");
}

- (void) WADODownload: (NSArray*) urlToDownload
{
    if( urlToDownload.count == 0)
    {
        NSLog( @"**** urlToDownload.count == 0 in WADODownload");
        return;
    }
    
    NSMutableArray *connectionsArray = [NSMutableArray array];
    
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    self.baseStatus = [[NSThread currentThread] status];
    
    @try
    {
        if( [urlToDownload count])
            urlToDownload = [[NSSet setWithArray: urlToDownload] allObjects]; // UNIQUE OBJECTS !
        
        if( [urlToDownload count])
        {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#ifndef NDEBUG
            NSLog( @"------ WADO downloading : %d files", (int) [urlToDownload count]);
#endif
            firstWadoErrorDisplayed = NO;
            
            if( showErrorMessage == NO)
                firstWadoErrorDisplayed = YES; // dont show errors
            
            [WADODownloadDictionary release];
            WADODownloadDictionary = [[NSMutableDictionary dictionary] retain];
            
            int WADOMaximumConcurrentDownloads = [[NSUserDefaults standardUserDefaults] integerForKey: @"WADOMaximumConcurrentDownloads"];
            if( WADOMaximumConcurrentDownloads < 1)
                WADOMaximumConcurrentDownloads = 1;
            
            float timeout = [[NSUserDefaults standardUserDefaults] floatForKey: @"WADOTimeout"];
            if( timeout < 240) timeout = 240;
            
#ifndef NDEBUG
            NSLog( @"------ WADO parameters: timeout:%2.2f [secs] / WADOMaximumConcurrentDownloads:%d [URLRequests]", timeout, WADOMaximumConcurrentDownloads);
#endif
            self.countOfSuccesses = 0;
            WADOTotal = WADOThreads = [urlToDownload count];
            
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
                    [WADODownloadDictionary setObject: [NSDictionary dictionaryWithObjectsAndKeys: url, @"url", [NSMutableData data], @"data", nil] forKey: [NSString stringWithFormat:@"%ld", (long) downloadConnection]];
                    [downloadConnection start];
                    [connectionsArray addObject: downloadConnection];
                }
                
                if( downloadConnection == nil)
                    WADOThreads--;
                
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
                
                [[DicomDatabase activeLocalDatabase] initiateImportFilesFromIncomingDirUnlessAlreadyImporting];
            }
            
            if( aborted) [logEntry setValue:@"Incomplete" forKey:@"logMessage"];
            else [logEntry setValue:@"Complete" forKey:@"logMessage"];
            
            [[LogManager currentLogManager] addLogLine: logEntry];
            
            if( aborted)
            {
                for( NSURLConnection *connection in connectionsArray)
                    [connection cancel];
            }
            
            [WADODownloadDictionary release];
            WADODownloadDictionary = nil;
            
            [logEntry release];
            logEntry = nil;
            
            [pool release];
            
#ifndef NDEBUG
            if( aborted)
                NSLog( @"------ WADO downloading ABORTED");
            else
                NSLog( @"------ WADO downloading : %d files - finished (errors: %d / total: %d)", (int) [urlToDownload count], (int) (urlToDownload.count - countOfSuccesses), (int) urlToDownload.count);
#endif
        }
    }
    @catch (NSException *exception) {
        N2LogException( exception);
    }
    @finally {
        [pool release];
    }
}


@end
