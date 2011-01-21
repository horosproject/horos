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


#import "NSFileManager+N2.h"
#import "NSString+N2.h"


@implementation NSFileManager (N2)

-(NSString*)findSystemFolderOfType:(int)folderType forDomain:(int)domain {
    FSRef folder;
    NSString* result = NULL;
	
    OSErr err = FSFindFolder(domain, folderType, kCreateFolder, &folder);
    if (err == noErr) {
        CFURLRef url = CFURLCreateFromFSRef(kCFAllocatorDefault, &folder);
        result = [(NSURL*)url path];
		CFRelease(url);
    } else [NSException raise:NSGenericException format:@"FSFindFolder error %d", err];
	
    return result;
}

-(NSString*)userApplicationSupportFolderForApp {
	NSString* path = [[self findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]];
	[self confirmDirectoryAtPath:path];
	return path;

}

-(NSString*)tmpFilePathInDir:(NSString*)dirPath {
	NSString* prefix = [NSString stringWithFormat:@"%@_%@_%u_%x_", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey], [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:NULL locale:NULL], getpid(), [NSThread currentThread]];
	char* path = tempnam(dirPath.UTF8String, prefix.UTF8String);
	NSString* nsPath = [NSString stringWithUTF8String:path];
	free(path);
	return nsPath;
}

-(NSString*)tmpFilePathInTmp {
	return [self tmpFilePathInDir:@"/tmp"];
}

-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath {
	if( dirPath == nil) return nil;
	NSString* parentDirPath = [dirPath stringByDeletingLastPathComponent];
	if (![dirPath isEqual:parentDirPath])
		[self confirmDirectoryAtPath:parentDirPath];
	
	BOOL isDir, create = NO;
	NSError* error = NULL;
	
	if (![self fileExistsAtPath:dirPath isDirectory:&isDir])
		create = YES;
	else if (!isDir) {
		[self removeItemAtPath:dirPath error:&error];
		if (error) [NSException raise:NSGenericException format:@"Couldn't unlink file: %@", [error localizedDescription]];
		create = YES;
	}
	
	if (create) {
		[self createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:NULL error:&error];
		if (error) [NSException raise:NSGenericException format:@"Couldn't create directory: %@", [error localizedDescription]];
	}
	
	return dirPath;
}

-(NSString*)confirmNoIndexDirectoryAtPath:(NSString*)path {
	NSString* pathWithExt;
	NSString* pathWithoutExt;
	const NSString* const ext = @".noindex";
	
	if ([path hasSuffix:ext]) {
		pathWithExt = path;
		pathWithoutExt = [path stringByAppendingString:ext];
	} else {
		pathWithoutExt = path;
		pathWithExt = [path substringToIndex:path.length-ext.length];
	}
	
	BOOL pathWithoutExtIsDir = YES, pathWithoutExtExists = [self fileExistsAtPath:pathWithoutExt isDirectory:&pathWithoutExtIsDir];
	BOOL pathWithExtIsDir = YES, pathWithExtExists = [self fileExistsAtPath:pathWithExt isDirectory:&pathWithExtIsDir];
	
	if (pathWithExtExists && !pathWithExtIsDir) {
		[self removeItemAtPath:pathWithExt error:NULL];
		pathWithExtExists = [self fileExistsAtPath:pathWithExt isDirectory:&pathWithExtIsDir];
		if (pathWithExtExists) [NSException raise:NSGenericException format:@"Could not delete file at %@", pathWithExt];
	}
	
	if (!pathWithExtExists && pathWithoutExtExists && pathWithoutExtIsDir) {
		[self moveItemAtPath:pathWithoutExt toPath:pathWithExt error:NULL];
		pathWithoutExtExists = [self fileExistsAtPath:pathWithoutExt isDirectory:&pathWithoutExtIsDir];
		pathWithExtExists = [self fileExistsAtPath:pathWithExt isDirectory:&pathWithExtIsDir];
		if (!pathWithExtExists) [NSException raise:NSGenericException format:@"Could not rename directory at %@ to %@", pathWithoutExt, pathWithExt];
	}
	
	return [self confirmDirectoryAtPath:pathWithExt];
}

-(NSUInteger)sizeAtPath:(NSString*)path {
	FSRef fsRef;
	CFURLGetFSRef((CFURLRef)[NSURL fileURLWithPath:path], &fsRef);
	return [self sizeAtFSRef:&fsRef];
}

-(NSUInteger)sizeAtFSRef:(FSRef*)theFileRef {
	FSIterator thisDirEnum = NULL;
	NSUInteger totalSize = 0;
	
	NSMutableArray* fsRefs = [NSMutableArray arrayWithCapacity:1];
	[fsRefs addObject:[NSData dataWithBytes:theFileRef length:sizeof(FSRef)]];

	@try {
		while (fsRefs.count) {
			NSData* d = [[fsRefs objectAtIndex:0] retain];
			[fsRefs removeObjectAtIndex:0];
			FSRef currFsRef;
			[d getBytes:&currFsRef length:sizeof(FSRef)];
			[d release];
			
			FSCatalogInfo fetchedInfos;
			//HFSUniStr255 outName;
			OSErr fsErr = FSGetCatalogInfo(&currFsRef, kFSCatInfoDataSizes|kFSCatInfoRsrcSizes|kFSCatInfoNodeFlags, &fetchedInfos, NULL, NULL, NULL);
			//NSLog(@"ok for %@", [NSString stringWithCharacters:outName.unicode length:outName.length]);
			
			if (fsErr == noErr)
				if (fetchedInfos.nodeFlags&kFSNodeIsDirectoryMask) {
					if (FSOpenIterator(&currFsRef, kFSIterateFlat, &thisDirEnum) == noErr) {
						const ItemCount kMaxEntriesPerFetch = 256;
						ItemCount actualFetched;
						FSRef fetchedRefs[kMaxEntriesPerFetch];
						FSCatalogInfo fetchedInfos[kMaxEntriesPerFetch];
						
						OSErr fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched, NULL, kFSCatInfoDataSizes|kFSCatInfoRsrcSizes|kFSCatInfoNodeFlags, fetchedInfos, fetchedRefs, NULL, NULL);
						while ((fsErr == noErr) || (fsErr == errFSNoMoreItems)) {
							for (ItemCount thisIndex = 0; thisIndex < actualFetched; ++thisIndex)
								[fsRefs addObject:[NSData dataWithBytes:&fetchedRefs[thisIndex] length:sizeof(FSRef)]];
							if (fsErr == errFSNoMoreItems)
								break;
							fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched, NULL, kFSCatInfoDataSizes|kFSCatInfoRsrcSizes|kFSCatInfoNodeFlags, fetchedInfos, fetchedRefs, NULL, NULL);
						}
						
						FSCloseIterator(thisDirEnum);
					}
				} else {
					totalSize += fetchedInfos.dataLogicalSize;
					totalSize += fetchedInfos.rsrcLogicalSize;
				}
			else
				NSLog(@"[NSFileManager sizeAtFSRef:] error: %d", fsErr);
		}
		
	} @catch (NSException* e) {
		NSLog(@"[NSFileManager sizeAtFSRef:] error: %@", e.description);
	}

	return totalSize;
}

-(BOOL)copyItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath byReplacingExisting:(BOOL)replace error:(NSError**)err {
	BOOL success = YES;
	NSMutableArray* pairs = [NSMutableArray arrayWithObject:[NSArray arrayWithObjects: srcPath, dstPath, NULL]];
	
	while (pairs.count) {
		NSArray* pair = [pairs objectAtIndex:0];
		[pairs removeObjectAtIndex:0];
		srcPath = [pair objectAtIndex:0];
		dstPath = [pair objectAtIndex:1];
		
		NSString* srcPathRes = [srcPath resolvedPathString];
		NSString* dstPathRes = [dstPath resolvedPathString];
		if (!dstPathRes)
			dstPathRes = [[[dstPath stringByDeletingLastPathComponent] resolvedPathString] stringByAppendingPathComponent:[dstPath lastPathComponent]];
		
		/*BOOL srcPathIsDir, srcPathExists = [self fileExistsAtPath:srcPathRes isDirectory:&srcPathIsDir]*/;
		BOOL dstPathIsDir, dstPathExists = [self fileExistsAtPath:dstPathRes isDirectory:&dstPathIsDir];
		
		if (dstPathExists && replace) {
			[self removeItemAtPath:dstPath error:NULL];
			dstPathRes = dstPath;
			dstPathExists = [self fileExistsAtPath:dstPathRes isDirectory:&dstPathIsDir];
		}
	
		if (!dstPathExists)
			success = [self copyItemAtPath:srcPathRes toPath:dstPathRes error:err] && success;
		else if (dstPathIsDir)
			for (NSString* subPath in [self contentsOfDirectoryAtPath:srcPathRes error:NULL])
				[pairs addObject:[NSArray arrayWithObjects: [srcPath stringByAppendingPathComponent:subPath], [dstPath stringByAppendingPathComponent:subPath], NULL]];
	}

	return success;
}









@end
