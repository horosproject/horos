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

#import <Foundation/Foundation.h>


@protocol HTTPResponse

// Returns the length of the data in bytes.
// If you don't know the length in advance, implement the iChunked method and have it return YES.
- (UInt64)contentLength;

- (UInt64)offset;
- (void)setOffset:(UInt64)offset;

- (NSData *)readDataOfLength:(unsigned int)length;

// Should only return YES after the HTTPConnection has read all available data.
- (BOOL)isDone;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5

@optional

// If you want to add any extra HTTP headers to the response,
// simply return them in a dictionary in this method.
- (NSDictionary *)httpHeaders;

// If you want to generate your response asynchronously (e.g. in a background thread),
// implement this method in your custom response class and return YES.
// As you generate the data, call HTTPConnection's responseHasAvailableData method.
// 
// Important: You should read the discussion at the bottom of this header.
- (BOOL)isAsynchronous;

// This method is called from the HTTPConnection when the connection is closed,
// or when the connection is finished with the response.
// If your response is asynchronous, you should implement this method so you can be sure not to
// invoke HTTPConnection's responseHasAvailableData method after this method is called.
- (void)connectionDidClose;

// If you don't know the content-length in advance,
// implement this method in your custom response class and return YES.
// 
// Important: You should read the discussion at the bottom of this header.
- (BOOL)isChunked;

- (int)statusCode;

#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPFileResponse : NSObject <HTTPResponse>
{
	NSString *filePath;
	NSFileHandle *fileHandle;
	
	UInt64 fileLength;
}

- (id)initWithFilePath:(NSString *)filePath;
- (NSString *)filePath;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	unsigned offset;
	NSData *data;
}

- (id)initWithData:(NSData *)data;

@end

// Important notice to those implementing custom asynchronous and/or chunked responses:
// 
// HTTPConnection supports asynchronous responses.  All you have to do in your custom response class is
// asynchronously generate the response, and invoke HTTPConnection's responseHasAvailableData method.
// You don't have to wait until you have all of the response ready to invoke this method.  For example, if you
// generate the response in incremental chunks, you could call responseHasAvailableData after generating
// each chunk.  You MUST invoke the responseHasAvailableData method on the proper thread/runloop.  That is,
// the thread/runloop that the HTTPConnection is operating in.  Please see the HTTPAsyncFileResponse class
// for an example of how to properly do this.
// 
// The normal flow of events for an HTTPConnection while responding to a request is like this:
// - Get data from response via readDataOfLength method.
// - Add data to asyncSocket's write queue.
// - Wait for asyncSocket to notify it that the data has been sent.
// - Get more data from response via readDataOfLength method.
// ... continue this cycle until it has sent the entire response.
// 
// With an asynchronous response, the flow is a little different.  When HTTPConnection calls your
// readDataOfLength method, you may or may not have any available data.  If you don't, then simply return nil.
// You should later invoke HTTPConnection's responseHasAvailableData when you have data to send.
// 
// You don't have to keep track of when you return nil in the readDataOfLength method, or how many times you've invoked
// responseHasAvailableData. Just simply call responseHasAvailableData whenever you've generated new data, and
// return nil in your readDataOfLength whenever you don't have any available data in the requested range.
// HTTPConnection will automatically detect when it should be requesting new data and will act appropriately.
// 
// It's important that you also keep in mind that the HTTP server supports range requests.
// The setOffset method is mandatory, and should not be ignored.
// Make sure you take into account the offset within the readDataOfLength method.
// You should also be aware that the HTTPConnection automatically sorts any range requests.
// So if your setOffset method is called with a value of 100, then you can safely release bytes 0-98.
// 
// HTTPConnection can also help you keep your memory footprint small.
// Imagine you're dynamically generating a 10 MB response.  You probably don't want to load all this data into
// RAM, and sit around waiting for HTTPConnection to slowly send it out over the network.  All you need to do
// is pay attention to when HTTPConnection requests more data via readDataOfLength.  This is because HTTPConnection
// will never allow asyncSocket's write queue to get much bigger than READ_CHUNKSIZE bytes.  You should
// consider how you might be able to take advantage of this fact to generate your asynchronous response on demand,
// while at the same time keeping your memory footprint small, and your application lightning fast.
// 
// If you don't know the content-length in advanced, you should also implement the isChunked method.
// This means the response will not include a Content-Length header, and will instead use "Transfer-Encoding: chunked".
// There's a good chance that if your response is asynchronous, it's also chunked.
