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
#import <sys/stat.h>

@implementation NSFileManager (N2)

- (void)moveItemAtPathToTrash: (NSString*) path
{
	NSString *trashPath = [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent:[path lastPathComponent]];
	NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath: trashPath error: nil];
    NSString *originalTrashPath = trashPath;
    int i = 2;
    while( [[NSFileManager defaultManager] fileExistsAtPath: trashPath])
        trashPath = [originalTrashPath stringByAppendingFormat: @" %d", i++];
        
    [[NSFileManager defaultManager] moveItemAtPath:path toPath:trashPath error:&error];
}

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
	NSString* prefix = [NSString stringWithFormat:@"%@_%@_%u_%lu_", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey], [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S" timeZone:NULL locale:NULL], getpid(), (long) [NSThread currentThread]];
	char* path = tempnam(dirPath.UTF8String, prefix.UTF8String);
	NSString* nsPath = [NSString stringWithUTF8String:path];
	free(path);
	return nsPath;
}

-(NSString*)tmpDirPath {
    NSString* path = [NSString stringWithFormat:@"/tmp/%@_%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey], NSUserName()];
    [self confirmDirectoryAtPath:path];
    return path;
}

-(NSString*)tmpFilePathInTmp {
	return [self tmpFilePathInDir:[self tmpDirPath]];
}

-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath subDirectory: (BOOL) subDirectory
{
	if( dirPath == nil) return nil;
	NSString* parentDirPath = [dirPath stringByDeletingLastPathComponent];
    
	if (![dirPath isEqualToString:parentDirPath])
		[self confirmDirectoryAtPath:parentDirPath subDirectory: YES];
    
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
    
    if( subDirectory == NO && [self isWritableFileAtPath: dirPath] == NO)
        NSLog( @"-------- confirmDirectoryAtPath %@ is writable == NO", dirPath);
    
	return dirPath;
}

-(NSString*)confirmDirectoryAtPath:(NSString*)dirPath
{
    return [self confirmDirectoryAtPath: dirPath subDirectory: NO];
}

-(NSString*)confirmNoIndexDirectoryAtPath:(NSString*)path {
	NSString* pathWithExt;
	NSString* pathWithoutExt;
	NSString* const ext = @".noindex";
	
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
		
		NSString* srcPathRes = [srcPath stringByExpandingTildeInPath];	//[srcPath resolvedPathString];
		NSString* dstPathRes = [dstPath stringByExpandingTildeInPath];	//[dstPath resolvedPathString];
		if (!dstPathRes)
			dstPathRes = [[dstPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[dstPath lastPathComponent]];
		
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

-(BOOL)applyFileModeOfParentToItemAtPath:(NSString*)path {
    struct stat st;
    if (stat([[path stringByDeletingLastPathComponent] fileSystemRepresentation], &st) == -1)
        return NO;
    
    if (chmod(path.fileSystemRepresentation, st.st_mode&0777) == -1)
        return NO;
        
    return YES;
}

-(NSString*)destinationOfAliasAtPath:(NSString*)inPath {
    if (inPath == nil)
        return nil;
    
	CFStringRef resolvedPath = nil;
    
	CFURLRef url = CFURLCreateWithFileSystemPath(nil /*allocator*/, (CFStringRef)inPath, kCFURLPOSIXPathStyle, NO /*isDirectory*/);
	if (url != nil) {
		FSRef fsRef;
		if (CFURLGetFSRef(url, &fsRef))
		{
			Boolean targetIsFolder, wasAliased;
			if (FSResolveAliasFile (&fsRef, true /*resolveAliasChains*/, &targetIsFolder, &wasAliased) == noErr && wasAliased)
			{
				CFURLRef resolvedurl = CFURLCreateFromFSRef(nil /*allocator*/, &fsRef);
				if (resolvedurl != nil)
				{
					resolvedPath = CFURLCopyFileSystemPath(resolvedurl, kCFURLPOSIXPathStyle);
					CFRelease(resolvedurl);
				}
			}
		}
		CFRelease(url);
	}
    
	return [(NSString*)resolvedPath autorelease];	
}

-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path {
	return [self destinationOfAliasOrSymlinkAtPath:path resolved:NULL];
}

-(NSString*)destinationOfAliasOrSymlinkAtPath:(NSString*)path resolved:(BOOL*)r {
	//if (![self fileExistsAtPath:path]) {
		NSString* temp = [self destinationOfAliasAtPath:path];
		if (temp) {
			if (r) *r = YES;
			return temp;
		}
		
	//	if (r) *r = NO;
	//	return path;
	//}
	
	NSDictionary* attrs = [self attributesOfItemAtPath:path error:NULL];
	if ([[attrs objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink]) {
		if (r) *r = YES;
		return [self destinationOfSymbolicLinkAtPath:path error:NULL];
	}
	
	if (r) *r = NO;
	return path;
}

-(NSDirectoryEnumerator*)enumeratorAtPath:(NSString*)path limitTo:(NSInteger)maxNumberOfFiles {
	return [[[N2DirectoryEnumerator alloc] initWithPath:path maxNumberOfFiles:maxNumberOfFiles] autorelease];
}

-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly {
	return [self enumeratorAtPath:path filesOnly:filesOnly recursive:YES];
}


-(N2DirectoryEnumerator*)enumeratorAtPath:(NSString*)path filesOnly:(BOOL)filesOnly recursive:(BOOL)recursive {
	N2DirectoryEnumerator* de = [[[N2DirectoryEnumerator alloc] initWithPath:path maxNumberOfFiles:-1] autorelease];
	de.filesOnly = filesOnly;
	de.recursive = recursive;
	return de;
}


@end
