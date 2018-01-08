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

#import "HTTPAsyncFileResponse.h"
#import "HTTPConnection.h"


@implementation HTTPAsyncFileResponse

static NSOperationQueue *operationQueue;

/**
 * The runtime sends initialize to each class in a program exactly one time just before the class,
 * or any class that inherits from it, is sent its first message from within the program. (Thus the
 * method may never be invoked if the class is not used.) The runtime sends the initialize message to
 * classes in a thread-safe manner. Superclasses receive this message before their subclasses.
 *
 * This method may also be called directly (assumably by accident), hence the safety mechanism.
**/
+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		
		operationQueue = [[NSOperationQueue alloc] init];
	}
}

// A quick overview of how this class works:
// 
// The HTTPConnection will request data from us via the readDataOfLength method.
// The first time this method is called, we won't have any data available.
// So we'll start a background operation to read data from the file, and then return nil.
// The HTTPConnection, upon receiving a nil response, will then wait for us to inform it of available data.
// 
// Once the background read operation completes, the fileHandleDidReadData method will be called.
// We then inform the HTTPConnection that we have the requested data by
// calling HTTPConnection's responseHasAvailableData.
// The HTTPConnection will then request our data via the readDataOfLength method.

- (id)initWithFilePath:(NSString *)fpath forConnection:(HTTPConnection *)parent runLoopModes:(NSArray *)modes
{
	if((self = [super init]))
	{
		connection = parent; // Parents retain children, children do NOT retain parents
		
		connectionThread = [[NSThread currentThread] retain];
		connectionRunLoopModes = [modes copy];
		
		filePath = [fpath copy];
		fileHandle = [[NSFileHandle fileHandleForReadingAtPath:filePath] retain];
		
		if(fileHandle == nil)
		{
			[self autorelease];
			return nil;
		}
		
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
		NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
		fileLength = (UInt64)[fileSize unsignedLongLongValue];
		
		fileReadOffset = 0;
		connectionReadOffset = 0;
		
		data = nil;
		
		asyncReadInProgress = NO;
	}
	return self;
}

- (void)dealloc
{
	[connectionThread release];
	[connectionRunLoopModes release];
	[filePath release];
	[fileHandle closeFile];
	[fileHandle release];
	[data release];
	[super dealloc];
}

- (UInt64)contentLength
{
	return fileLength;
}

- (UInt64)offset
{
	return connectionReadOffset;
}

- (void)setOffset:(UInt64)offset
{
	[fileHandle seekToFileOffset:offset];
	
	fileReadOffset = offset;
	connectionReadOffset = offset;
	
	// Note: fileHandle is not thread safe, but we don't have to worry about that here.
	// The HTTPConnection won't ever change our offset when we're in the middle of a read.
	// It will request data, and won't move forward from that point until it has received the data.
}

- (NSData *)readDataOfLength:(unsigned int)length
{
	if(data == nil)
	{
		if (!asyncReadInProgress)
		{
			NSInvocationOperation *operation;
			operation = [[NSInvocationOperation alloc] initWithTarget:self
															 selector:@selector(readDataInBackground:)
															   object:[NSNumber numberWithUnsignedInt:length]];
			
			[operationQueue addOperation:operation];
			[operation release];
		}
		
		return nil;
	}
	
	connectionReadOffset += [data length];
	
	NSData *result = [[data retain] autorelease];
	
	[data release];
	data = nil;
	
	return result;
}

- (BOOL)isDone
{
	return (connectionReadOffset == fileLength);
}

- (NSString *)filePath
{
	return filePath;
}

- (BOOL)isAsynchronous
{
	return YES;
}

- (void)connectionDidClose
{
	// Prevent any further calls to the connection
	connection = nil;
}

- (void)readDataInBackground:(NSNumber *)lengthNumber
{
	unsigned int length = [lengthNumber unsignedIntValue];
	
	NSData *readData = [fileHandle readDataOfLength:length];
	
	[self performSelector:@selector(fileHandleDidReadData:)
				 onThread:connectionThread
			   withObject:readData
			waitUntilDone:NO
					modes:connectionRunLoopModes];
}

- (void)fileHandleDidReadData:(NSData *)readData
{
	data = [readData retain];
	
	fileReadOffset += [data length];
	
	asyncReadInProgress = NO;
	
	[connection responseHasAvailableData];
}

@end
