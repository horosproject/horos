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

#import "DicomCompressor.h"
#import "NSFileManager+N2.h"
#include <algorithm>

@implementation DicomCompressor

const NSUInteger MaxFilesPassedToDecompress = 200;

+(void)executeDecompressOnFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptionsPath:(NSString*)optionsPlistPath action:(Compression)action {
	if (!dirPath) dirPath = @"sameAsDestination";
	NSMutableArray* args = [NSMutableArray arrayWithObjects: dirPath, NULL];
	
	if (optionsPlistPath) {
		[args addObject:@"SettingsPlist"];
		[args addObject:optionsPlistPath];
	}
	
	NSString* actionString;
	switch (action) {
		case CompressionDecompress: actionString = @"decompressList"; break;
		case CompressionCompress: actionString = @"compress"; break;
		default: [NSException raise:NSGenericException format:@"Invalid action for [DicomCompressorDecompressor executeDecompressOnFiles:toDirectory:withOptionsPath:action:]"];
	}
	[args addObject:actionString];
	
	for (NSUInteger i = 0; i < filePaths.count; i += MaxFilesPassedToDecompress)
    {
		NSMutableArray* iargs = [NSMutableArray arrayWithArray:args];
		[iargs addObjectsFromArray:[filePaths subarrayWithRange:NSMakeRange(i, std::min(MaxFilesPassedToDecompress, (int)filePaths.count-i))]];
		
		NSTask* task = [[NSTask alloc] init];
		[task setArguments:iargs];
		[task setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Decompress"]];
		[task launch];
		
		while ([task isRunning]) [NSThread sleepForTimeInterval:0.01];
		
		[task release];
        
        if ([[NSThread currentThread] isCancelled])
            return;
	}
}

+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath {
	[self decompressFiles:filePaths toDirectory:dirPath withOptions:NULL];
}

+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptions:(NSDictionary*)options {
	NSString* optionsPlistPath = [[NSFileManager defaultManager] tmpFilePathInTmp];
	[options writeToFile:optionsPlistPath atomically:YES];
	[self decompressFiles:filePaths toDirectory:dirPath withOptionsPath:optionsPlistPath];
	[[NSFileManager defaultManager] removeItemAtPath:optionsPlistPath error:NULL];
}

+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptionsPath:(NSString*)optionsPlistPath {
	[self executeDecompressOnFiles:filePaths toDirectory:dirPath withOptionsPath:optionsPlistPath action:CompressionDecompress];
}

+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath {
	[self compressFiles:filePaths toDirectory:dirPath withOptions:NULL];
}

+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptions:(NSDictionary*)options {
	NSString* optionsPlistPath = [[NSFileManager defaultManager] tmpFilePathInTmp];
	[options writeToFile:optionsPlistPath atomically:YES];
	[self compressFiles:filePaths toDirectory:dirPath withOptionsPath:optionsPlistPath];
	[[NSFileManager defaultManager] removeItemAtPath:optionsPlistPath error:NULL];
}

+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptionsPath:(NSString*)optionsPlistPath {
	return [self executeDecompressOnFiles:filePaths toDirectory:dirPath withOptionsPath:optionsPlistPath action:CompressionCompress];
}


@end
